// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./RoyalERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title Illuvium ERC1155 NFT
 *
 * @dev This is the deployed smart contract that represents Illuvium's Promotional
 *      NFTs collection using the multi-token standard (ERC1155)
 *
 * @dev UUPSUpgradeable (EIP1822) is used for upgradeability
 */

contract IlluviumNFT is Initializable, RoyalERC1155 {
    using StringsUpgradeable for uint256;

    /**
     * @dev Collection name
     */
    string public constant name = "Illuvium Promo NFTs";
    /**
     * @dev Collection token ticker (symbol)
     */
    string public constant symbol = "ILV-NFT";

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     *
     * @param uri_ collection uri (ERC1155)
     * @param _owner smart contract owner having full privileges
     */
    function initialize(string memory uri_, address _owner) external initializer {
        __RoyalERC1155_init(uri_, _owner);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(exists(_id), "URI query for nonexistent token");

        string memory baseUri = super.uri(0);
        return string(abi.encodePacked(baseUri, _id.toString()));
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interfaces/IEIP2981.sol";
import "./UpgradeableERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Royal ERC1155
 *
 * @dev Supports EIP-2981 royalties on NFT secondary sales
 *      Supports OpenSea contract metadata royalties
 *      Introduces fake "owner" to support OpenSea collections
 *
 */
abstract contract RoyalERC1155 is Initializable, IEIP2981, UpgradeableERC1155 {
    /**
     * @dev OpenSea expects NFTs to be "Ownable", that is having an "owner",
     *      we introduce a fake "owner" here with no authority
     */
    address public owner;

    /**
     * @notice Address to receive EIP-2981 royalties from secondary sales
     *         see https://eips.ethereum.org/EIPS/eip-2981
     */
    address public royaltyReceiver;

    /**
     * @notice Percentage of token sale price to be used for EIP-2981 royalties from secondary sales
     *         see https://eips.ethereum.org/EIPS/eip-2981
     *
     * @dev Has 2 decimal precision. E.g. a value of 500 would result in a 5% royalty fee
     */
    uint16 public royaltyPercentage; // default OpenSea value is 750

    /**
     * @notice Contract level metadata to define collection name, description, and royalty fees.
     *         see https://docs.opensea.io/docs/contract-level-metadata
     *
     * @dev Should be overwritten by inheriting contracts. By default only includes royalty information
     */
    string public contractURI;

    /**
     * @notice Royalty manager is responsible for managing the EIP2981 royalty info
     *
     * @dev Role ROLE_ROYALTY_MANAGER allows updating the royalty information
     *      (executing `setRoyaltyInfo` function)
     */
    uint32 public constant ROLE_ROYALTY_MANAGER = 0x0010_0000;

    /**
     * @notice Owner manager is responsible for setting/updating an "owner" field
     *
     * @dev Role ROLE_OWNER_MANAGER allows updating the "owner" field
     *      (executing `setOwner` function)
     */
    uint32 public constant ROLE_OWNER_MANAGER = 0x0020_0000;

    /**
     * @dev Fired in setContractURI()
     *
     * @param _by an address which executed update
     * @param _value new contractURI value
     */
    event ContractURIUpdated(address indexed _by, string _value);

    /**
     * @dev Fired in setRoyaltyInfo()
     *
     * @param _by an address which executed update
     * @param _receiver new royaltyReceiver value
     * @param _percentage new royaltyPercentage value
     */
    event RoyaltyInfoUpdated(address indexed _by, address indexed _receiver, uint16 _percentage);

    /**
     * @dev Fired in setOwner()
     *
     * @param _by an address which set the new "owner"
     * @param _oldVal previous "owner" address
     * @param _newVal new "owner" address
     */
    event OwnerUpdated(address indexed _by, address indexed _oldVal, address indexed _newVal);

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     *
     * @param uri_ collection uri (ERC1155)
     * @param _owner smart contract owner having full privileges
     */
    function __RoyalERC1155_init(string memory uri_, address _owner) internal initializer {
        // execute all parent initializers in cascade
        __UpgradeableERC1155_init(uri_, _owner);

        // initialize the "owner" as a deployer account
        owner = msg.sender;
    }

    /**
     * @dev Restricted access function which updates the contract URI
     *
     * @dev Requires executor to have ROLE_URI_MANAGER permission
     *
     * @param _contractURI new contract URI to set
     */
    function setContractURI(string memory _contractURI) public virtual {
        // verify the access permission
        require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

        // update the contract URI
        contractURI = _contractURI;

        // emit an event first
        emit ContractURIUpdated(msg.sender, _contractURI);
    }

    /**
     * @notice EIP-2981 function to calculate royalties for sales in secondary marketplaces.
     *         see https://eips.ethereum.org/EIPS/eip-2981
     *
     * @param _salePrice the price (in any unit, .e.g wei, ERC20 token, et.c.) of the token to be sold
     *
     * @return receiver the royalty receiver
     * @return royaltyAmount royalty amount in the same unit as _salePrice
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // simply calculate the values and return the result
        return (royaltyReceiver, (_salePrice * royaltyPercentage) / 100_00);
    }

    /**
     * @dev Restricted access function which updates the royalty info
     *
     * @dev Requires executor to have ROLE_ROYALTY_MANAGER permission
     *
     * @param _royaltyReceiver new royalty receiver to set
     * @param _royaltyPercentage new royalty percentage to set
     */
    function setRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyPercentage) public virtual {
        // verify the access permission
        require(isSenderInRole(ROLE_ROYALTY_MANAGER), "access denied");

        // verify royalty percentage is zero if receiver is also zero
        require(_royaltyReceiver != address(0) || _royaltyPercentage == 0, "invalid receiver");

        // update the values
        royaltyReceiver = _royaltyReceiver;
        royaltyPercentage = _royaltyPercentage;

        // emit an event first
        emit RoyaltyInfoUpdated(msg.sender, _royaltyReceiver, _royaltyPercentage);
    }

    /**
     * @notice Checks if the address supplied is an "owner" of the smart contract
     *      Note: an "owner" doesn't have any authority on the smart contract and is "nominal"
     *
     * @return true if the caller is the current owner.
     */
    function isOwner(address _addr) public view virtual returns (bool) {
        // just evaluate and return the result
        return _addr == owner;
    }

    /**
     * @dev Restricted access function to set smart contract "owner"
     *      Note: an "owner" set doesn't have any authority, and cannot even update "owner"
     *
     * @dev Requires executor to have ROLE_OWNER_MANAGER permission
     *
     * @param _owner new "owner" of the smart contract
     */
    function transferOwnership(address _owner) public virtual {
        // verify the access permission
        require(isSenderInRole(ROLE_OWNER_MANAGER), "access denied");

        // emit an event first - to log both old and new values
        emit OwnerUpdated(msg.sender, owner, _owner);

        // update "owner"
        owner = _owner;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, UpgradeableERC1155)
        returns (bool)
    {
        // construct the interface support from EIP-2981 and super interfaces
        return interfaceId == type(IEIP2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IEIP2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interfaces/IERC20.sol";
import "./utils/UpgradeableAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Upgradeable ERC1155 Implementation
 *
 * @dev Open Zeppelin based ERC1155 implementation, supporting burning, minting
 *      and total supply tracking per token id
 *
 * @dev Based on Open Zeppelin ERC1155BurnableUpgradeable and ERC1155SupplyUpgradeable
 */
abstract contract UpgradeableERC1155 is Initializable, ERC1155SupplyUpgradeable, UpgradeableAccessControl {
    /**
     * @notice Enables ERC1155 transfers of the tokens
     *      (transfer by the token owner himself)
     * @dev Feature FEATURE_TRANSFERS must be enabled in order for
     *      `transferFrom()` function to succeed when executed by token owner
     */
    uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

    /**
     * @notice Enables ERC1155 transfers on behalf
     *      (transfer by someone else on behalf of token owner)
     * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
     *      `transferFrom()` function to succeed whe executed by approved operator
     * @dev Token owner must call `approve()` or `setApprovalForAll()`
     *      first to authorize the transfer on behalf
     */
    uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

    /**
     * @notice Enables token owners to burn their own tokens
     *
     * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
     *      `burn()` function to succeed when called by token owner
     */
    uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

    /**
     * @notice Enables approved operators to burn tokens on behalf of their owners
     *
     * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
     *      `burn()` function to succeed when called by approved operator
     */
    uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

    /**
     * @notice Token creator is responsible for creating (minting)
     *      tokens to an arbitrary address
     * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
     *      (calling `mint` function)
     */
    uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

    /**
     * @notice Token destroyer is responsible for destroying (burning)
     *      tokens owned by an arbitrary address
     * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
     *      (calling `burn` function)
     */
    uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

    /**
     * @notice URI manager is responsible for managing base URI
     *      part of the token URI ERC1155Metadata interface
     *
     * @dev Role ROLE_URI_MANAGER allows updating the base URI
     *      (executing `setBaseURI` function)
     */
    uint32 public constant ROLE_URI_MANAGER = 0x0004_0000;

    /**
     * @notice People do mistakes and may send ERC20 tokens by mistake; since
     *      NFT smart contract is not designed to accept and hold any ERC20 tokens,
     *      it allows the rescue manager to "rescue" such lost tokens
     *
     * @notice Rescue manager is responsible for "rescuing" ERC20 tokens accidentally
     *      sent to the smart contract
     *
     * @dev Role ROLE_RESCUE_MANAGER allows withdrawing any ERC20 tokens stored
     *      on the smart contract balance
     */
    uint32 public constant ROLE_RESCUE_MANAGER = 0x0008_0000;

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     *
     * @param uri_ collection uri (ERC1155)
     * @param _owner smart contract owner having full privileges
     */
    function __UpgradeableERC1155_init(string memory uri_, address _owner) internal initializer {
        // execute all parent initializers in cascade
        __ERC1155_init(uri_);
        __ERC1155Supply_init_unchained();
        __AccessControl_init(_owner);
    }

    /**
     * @inheritdoc IERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Restricted access function which updates base URI used to construct
     *      IERC1155MetadataURIUpgradeable.uri
     *
     * @dev Requires executor to have ROLE_URI_MANAGER permission
     *
     * @param newuri new URI to set
     */
    function setURI(string memory newuri) public virtual {
        // verify the access permission
        require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

        _setURI(newuri);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `ROLE_TOKEN_CREATOR`.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual {
        // check if caller has sufficient permissions to mint tokens
        require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

        // mint token - delegate to `_mint`
        _mint(_to, _id, _amount, _data);
    }

    /**
     * @dev Destroys the token with token ID specified
     *
     * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
     *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
     *
     * @dev Can be disabled by the contract creator forever by disabling
     *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
     *      its own roles to burn tokens and to enable burning features
     *
     * @param _from address to burn the token from
     * @param _id ID of the token to burn
     * @param _amount number of tokens to burn
     */
    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) public virtual {
        // check if caller has sufficient permissions to burn tokens
        // and if not - check for possibility to burn own tokens or to burn on behalf
        if (!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
            // if `_from` is equal to sender, require own burns feature to be enabled
            // otherwise require burns on behalf feature to be enabled
            require(
                (_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)) ||
                    (_from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF)),
                _from == msg.sender ? "burns are disabled" : "burns on behalf are disabled"
            );

            // verify sender is either token owner, or approved by the token owner to burn tokens
            require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "access denied");
        }
        // delegate to the super implementation
        super._burn(_from, _id, _amount);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        super._beforeTokenTransfer(_operator, _from, _to, _ids, _amounts, _data);
        // for transfers only - verify if transfers are enabled
        require(
            _from == address(0) ||
                _to == address(0) || // won't affect minting/burning
                (_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)) ||
                (_from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF)),
            _from == msg.sender ? "transfers are disabled" : "transfers on behalf are disabled"
        );
    }

    /**
     * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
     *      the tokens are rescued via `transfer` function call on the
     *      contract address specified and with the parameters specified:
     *      `_contract.transfer(_to, _value)`
     *
     * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
     *
     * @param _contract smart contract address to execute `transfer` function on
     * @param _to to address in `transfer(_to, _value)`
     * @param _value value to transfer in `transfer(_to, _value)`
     */
    function rescueErc20(
        address _contract,
        address _to,
        uint256 _value
    ) public {
        // verify the access permission
        require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

        // perform the transfer as requested, without any checks
        IERC20(_contract).transfer(_to, _value);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    /**
     * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
     *
     * @param from an address tokens were consumed from
     * @param to an address tokens were sent to
     * @param value number of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Fired in approve() to indicate an approval event happened
     *
     * @param owner an address which granted a permission to transfer
     *      tokens on its behalf
     * @param spender an address which received a permission to transfer
     *      tokens on behalf of the owner `_owner`
     * @param value amount of tokens granted to transfer on behalf
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @return name of the token (ex.: USD Coin)
     */
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    // function name() external view returns (string memory);

    /**
     * @return symbol of the token (ex.: USDC)
     */
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    // function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     *      For example, if `decimals` equals `2`, a balance of `505` tokens should
     *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * @dev Tokens usually opt for a value of 18, imitating the relationship between
     *      Ether and Wei. This is the value {ERC20} uses, unless this function is
     *      overridden;
     *
     * @dev NOTE: This information is only used for _display_ purposes: it in
     *      no way affects any of the arithmetic of the contract, including
     *      {IERC20-balanceOf} and {IERC20-transfer}.
     *
     * @return token decimals
     */
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    // function decimals() external view returns (uint8);

    /**
     * @return the amount of tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of a particular address
     *
     * @param _owner the address to query the the balance for
     * @return balance an amount of tokens owned by the address specified
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @notice Transfers some tokens to an external address or a smart contract
     *
     * @dev Called by token owner (an address which has a
     *      positive token balance tracked by this smart contract)
     * @dev Throws on any error like
     *      * insufficient token balance or
     *      * incorrect `_to` address:
     *          * zero address or
     *          * self address or
     *          * smart contract which doesn't support ERC20
     *
     * @param _to an address to transfer tokens to,
     *      must be either an external address or a smart contract,
     *      compliant with the ERC20 standard
     * @param _value amount of tokens to be transferred,, zero
     *      value is allowed
     * @return success true on success, throws otherwise
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice Transfers some tokens on behalf of address `_from' (token owner)
     *      to some other address `_to`
     *
     * @dev Called by token owner on his own or approved address,
     *      an address approved earlier by token owner to
     *      transfer some amount of tokens on its behalf
     * @dev Throws on any error like
     *      * insufficient token balance or
     *      * incorrect `_to` address:
     *          * zero address or
     *          * same as `_from` address (self transfer)
     *          * smart contract which doesn't support ERC20
     *
     * @param _from token owner which approved caller (transaction sender)
     *      to transfer `_value` of tokens on its behalf
     * @param _to an address to transfer tokens to,
     *      must be either an external address or a smart contract,
     *      compliant with the ERC20 standard
     * @param _value amount of tokens to be transferred,, zero
     *      value is allowed
     * @return success true on success, throws otherwise
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /**
     * @notice Approves address called `_spender` to transfer some amount
     *      of tokens on behalf of the owner (transaction sender)
     *
     * @dev Transaction sender must not necessarily own any tokens to grant the permission
     *
     * @param _spender an address approved by the caller (token owner)
     *      to spend some tokens on its behalf
     * @param _value an amount of tokens spender `_spender` is allowed to
     *      transfer on behalf of the token owner
     * @return success true on success, throws otherwise
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
     *
     * @dev A function to check an amount of tokens owner approved
     *      to transfer on its behalf by some other address called "spender"
     *
     * @param _owner an address which approves transferring some tokens on its behalf
     * @param _spender an address approved to transfer some tokens on behalf
     * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
     *      of token owner `_owner`
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title Upgradeable Access Control List // ERC1967Proxy
 *
 * @notice Access control smart contract provides an API to check
 *      if a specific operation is permitted globally and/or
 *      if a particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable public functions
 *      of the smart contract (used by a wide audience).
 * @notice User roles are designed to control the access to restricted functions
 *      of the smart contract (used by a limited set of maintainers).
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @dev This is an upgradeable version of the ACL, based on Zeppelin implementation for ERC1967,
 *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
 *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
 *      see https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
 *
 * @author Basil Gorin
 */
abstract contract UpgradeableAccessControl is UUPSUpgradeable {
    /**
     * @notice Access manager is responsible for assigning the roles to users,
     *      enabling/disabling global features of the smart contract
     * @notice Access manager can add, remove and update user roles,
     *      remove and update global features
     *
     * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
     * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
     */
    uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @notice Upgrade manager is responsible for smart contract upgrades,
     *      see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable
     *      see https://docs.openzeppelin.com/contracts/4.x/upgradeable
     *
     * @dev Role ROLE_UPGRADE_MANAGER allows passing the _authorizeUpgrade() check
     * @dev Role ROLE_UPGRADE_MANAGER has single bit at position 254 enabled
     */
    uint256 public constant ROLE_UPGRADE_MANAGER = 0x4000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @dev Bitmask representing all the possible permissions (super admin role)
     * @dev Has all the bits are enabled (2^256 - 1 value)
     */
    uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

    /**
     * @notice Privileged addresses with defined roles/permissions
     * @notice In the context of ERC20/ERC721 tokens these can be permissions to
     *      allow minting or burning tokens, transferring on behalf and so on
     *
     * @dev Maps user address to the permissions bitmask (role), where each bit
     *      represents a permission
     * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
     *      represents all possible permissions
     * @dev 'This' address mapping represents global features of the smart contract
     */
    mapping(address => uint256) public userRoles;

    /**
     * @dev Fired in updateRole() and updateFeatures()
     *
     * @param _by operator which called the function
     * @param _to address which was granted/revoked permissions
     * @param _requested permissions requested
     * @param _actual permissions effectively set
     */
    event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

    /**
     * @dev UUPS initializer, sets the contract owner to have full privileges
     *
     * @param _owner smart contract owner having full privileges
     */
    function __AccessControl_init(address _owner) internal virtual initializer {
        // grant owner full privileges
        userRoles[_owner] = FULL_PRIVILEGES_MASK;
    }

    /**
     * @notice Returns an address of the implementation smart contract,
     *      see ERC1967Upgrade._getImplementation()
     *
     * @return the current implementation address
     */
    function getImplementation() public view virtual returns (address) {
        // delegate to `ERC1967Upgrade._getImplementation()`
        return _getImplementation();
    }

    /**
     * @notice Retrieves globally set of features enabled
     *
     * @dev Effectively reads userRoles role for the contract itself
     *
     * @return 256-bit bitmask of the features enabled
     */
    function features() public view returns (uint256) {
        // features are stored in 'this' address  mapping of `userRoles` structure
        return userRoles[address(this)];
    }

    /**
     * @notice Updates set of the globally enabled features (`features`),
     *      taking into account sender's permissions
     *
     * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
     * @dev Function is left for backward compatibility with older versions
     *
     * @param _mask bitmask representing a set of features to enable/disable
     */
    function updateFeatures(uint256 _mask) public {
        // delegate call to `updateRole`
        updateRole(address(this), _mask);
    }

    /**
     * @notice Updates set of permissions (role) for a given user,
     *      taking into account sender's permissions.
     *
     * @dev Setting role to zero is equivalent to removing an all permissions
     * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
     *      copying senders' permissions (role) to the user
     * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
     *
     * @param operator address of a user to alter permissions for or zero
     *      to alter global features of the smart contract
     * @param role bitmask representing a set of permissions to
     *      enable/disable for a user specified
     */
    function updateRole(address operator, uint256 role) public {
        // caller must have a permission to update user roles
        require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

        // evaluate the role and reassign it
        userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

        // fire an event
        emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
    }

    /**
     * @notice Determines the permission bitmask an operator can set on the
     *      target permission set
     * @notice Used to calculate the permission bitmask to be set when requested
     *     in `updateRole` and `updateFeatures` functions
     *
     * @dev Calculated based on:
     *      1) operator's own permission set read from userRoles[operator]
     *      2) target permission set - what is already set on the target
     *      3) desired permission set - what do we want set target to
     *
     * @dev Corner cases:
     *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
     *        `desired` bitset is returned regardless of the `target` permission set value
     *        (what operator sets is what they get)
     *      2) Operator with no permissions (zero bitset):
     *        `target` bitset is returned regardless of the `desired` value
     *        (operator has no authority and cannot modify anything)
     *
     * @dev Example:
     *      Consider an operator with the permissions bitmask     00001111
     *      is about to modify the target permission set          01010101
     *      Operator wants to set that permission set to          00110011
     *      Based on their role, an operator has the permissions
     *      to update only lowest 4 bits on the target, meaning that
     *      high 4 bits of the target set in this example is left
     *      unchanged and low 4 bits get changed as desired:      01010011
     *
     * @param operator address of the contract operator which is about to set the permissions
     * @param target input set of permissions to operator is going to modify
     * @param desired desired set of permissions operator would like to set
     * @return resulting set of permissions given operator will set
     */
    function evaluateBy(
        address operator,
        uint256 target,
        uint256 desired
    ) public view returns (uint256) {
        // read operator's permissions
        uint256 p = userRoles[operator];

        // taking into account operator's permissions,
        // 1) enable the permissions desired on the `target`
        target |= p & desired;
        // 2) disable the permissions desired on the `target`
        target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

        // return calculated result
        return target;
    }

    /**
     * @notice Checks if requested set of features is enabled globally on the contract
     *
     * @param required set of features to check against
     * @return true if all the features requested are enabled, false otherwise
     */
    function isFeatureEnabled(uint256 required) public view returns (bool) {
        // delegate call to `__hasRole`, passing `features` property
        return __hasRole(features(), required);
    }

    /**
     * @notice Checks if transaction sender `msg.sender` has all the permissions required
     *
     * @param required set of permissions (role) to check against
     * @return true if all the permissions requested are enabled, false otherwise
     */
    function isSenderInRole(uint256 required) public view returns (bool) {
        // delegate call to `isOperatorInRole`, passing transaction sender
        return isOperatorInRole(msg.sender, required);
    }

    /**
     * @notice Checks if operator has all the permissions (role) required
     *
     * @param operator address of the user to check role for
     * @param required set of permissions (role) to check
     * @return true if all the permissions requested are enabled, false otherwise
     */
    function isOperatorInRole(address operator, uint256 required) public view returns (bool) {
        // delegate call to `__hasRole`, passing operator's permissions (role)
        return __hasRole(userRoles[operator], required);
    }

    /**
     * @dev Checks if role `actual` contains all the permissions required `required`
     *
     * @param actual existent role
     * @param required required role
     * @return true if actual has required role (all permissions), false otherwise
     */
    function __hasRole(uint256 actual, uint256 required) internal pure returns (bool) {
        // check the bitmask for the role required and return the result
        return actual & required == required;
    }

    /**
     * @inheritdoc UUPSUpgradeable
     */
    function _authorizeUpgrade(address) internal virtual override {
        // caller must have a permission to upgrade the contract
        require(isSenderInRole(ROLE_UPGRADE_MANAGER), "access denied");
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155Supply_init_unchained();
    }

    function __ERC1155Supply_init_unchained() internal initializer {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}