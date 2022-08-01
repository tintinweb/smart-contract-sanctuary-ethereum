// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interface/IHashtagNFTCollectiveResolver.sol";
import "./ERC2771Config.sol";

contract HashtagNFTCollectiveResolver is
    Initializable,
    IHashtagNFTCollectiveResolver,
    ERC2771Config
{
    mapping(uint256 => address) private managerMap;

    address private factoryProxy;

    function initialize() external initializer {
        __ERC2771Config_init();
    }

    function _tokenize(string calldata uri) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(uri)));
    }

    function _recordExists(string calldata uri) internal view returns (bool) {
        return managerMap[_tokenize(uri)] != address(0x0);
    }

    function AddNftURIRecord(string calldata nftURI, address contractAddress)
        external
        override
    {
        require(
            _recordExists(nftURI) == false,
            "failure: Hashtag already taken"
        );
        uint256 tokenId = _tokenize(nftURI);
        managerMap[tokenId] = contractAddress;
        emit HashtagNFTCollectiveRecord(nftURI, contractAddress, tokenId);
    }

    function ResolveURI(string calldata nftURI)
        external
        view
        override
        returns (address)
    {
        return managerMap[_tokenize(nftURI)];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IHashtagNFTCollectiveResolver {
    event HashtagNFTCollectiveRecord(
        string indexed uri,
        address contractAddr,
        uint256 tokenId
    );

    function AddNftURIRecord(string calldata nftURI, address contractAddress)
        external;

    function ResolveURI(string calldata nftURI) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

contract ERC2771Config is ERC2771ContextUpgradeable{

    address MOONRIVER_FWD;

    function __ERC2771Config_init() internal{
        MOONRIVER_FWD = 0x64CD353384109423a966dCd3Aa30D884C9b2E057;
        __ERC2771Context_init(MOONRIVER_FWD);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}