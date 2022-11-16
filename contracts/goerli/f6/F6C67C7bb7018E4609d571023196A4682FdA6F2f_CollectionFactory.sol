// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../royaltyManager/interfaces/IRoyaltyManager.sol";
import "../tokenManager/interfaces/ITokenManager.sol";
import "../utils/Ownable.sol";
import "../utils/ERC2981/IERC2981Upgradeable.sol";
import "../utils/ERC165/ERC165CheckerUpgradeable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Base ERC721
 * @author [email protected]
 * @dev Core piece of Highlight NFT contracts (v2)
 */
abstract contract ERC721Base is
    OwnableUpgradeable,
    IERC2981Upgradeable,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165CheckerUpgradeable for address;

    /**
     * @dev Set of minters allowed to mint on contract
     */
    EnumerableSet.AddressSet internal _minters;

    /**
     * @dev Global token/edition manager default
     */
    address public defaultManager;

    /**
     * @dev Token/edition managers per token grouping.
     *      Edition ID if implemented by Editions contract, and token ID if implemented by General contract.
     */
    mapping(uint256 => address) internal _managers;

    /**
     * @dev Default royalty for entire contract
     */
    IRoyaltyManager.Royalty internal _defaultRoyalty;

    /**
     * @dev Royalty per token grouping.
     *      Edition ID if implemented by Editions contract, and token ID if implemented by General contract.
     */
    mapping(uint256 => IRoyaltyManager.Royalty) internal _royalties;

    /**
     * @dev Royalty manager - optional contract that defines the conditions around setting royalties
     */
    address public royaltyManager;

    /**
     * @dev Freezes minting on smart contract forever
     */
    uint8 internal _mintFrozen;

    /**
     * @dev Emitted when minter is registered or unregistered
     * @param minter Minter that was changed
     * @param registered True if the minter was registered, false if unregistered
     */
    event MinterRegistrationChanged(address indexed minter, bool indexed registered);

    /**
     * @dev Emitted when token managers are set for token/edition ids
     * @param _ids Edition / token ids
     * @param _tokenManagers Token managers to set for tokens / editions
     */
    event GranularTokenManagersSet(uint256[] _ids, address[] _tokenManagers);

    /**
     * @dev Emitted when token managers are removed for token/edition ids
     * @param _ids Edition / token ids to remove token managers for
     */
    event GranularTokenManagersRemoved(uint256[] _ids);

    /**
     * @dev Emitted when default token manager changed
     * @param newDefaultTokenManager New default token manager. Zero address if old one was removed
     */
    event DefaultTokenManagerChanged(address indexed newDefaultTokenManager);

    /**
     * @dev Emitted when default royalty is set
     * @param recipientAddress Royalty recipient
     * @param royaltyPercentageBPS Percentage of sale (in basis points) owed to royalty recipient
     */
    event DefaultRoyaltySet(address indexed recipientAddress, uint16 indexed royaltyPercentageBPS);

    /**
     * @dev Emitted when royalties are set for edition / token ids
     * @param ids Token / edition ids
     * @param _newRoyalties New royalties for each token / edition
     */
    event GranularRoyaltiesSet(uint256[] ids, IRoyaltyManager.Royalty[] _newRoyalties);

    /**
     * @dev Emitted when royalty manager is updated
     * @param newRoyaltyManager New royalty manager. Zero address if old one was removed
     */
    event RoyaltyManagerChanged(address indexed newRoyaltyManager);

    /**
     * @dev Emitted when mints are frozen permanently
     */
    event MintsFrozen();

    /**
     * @dev Restricts calls to minters
     */
    modifier onlyMinter() {
        require(_minters.contains(_msgSender()), "Not minter");
        _;
    }

    /**
     * @dev Restricts calls if input royalty bps is over 10000
     */
    modifier royaltyValid(uint16 _royaltyBPS) {
        require(_royaltyBPSValid(_royaltyBPS), "Over BPS limit");
        _;
    }

    /**
     * @dev Registers a minter
     * @param minter New minter
     */
    function registerMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.add(minter), "Already a minter");

        emit MinterRegistrationChanged(minter, true);
    }

    /**
     * @dev Unregisters a minter
     * @param minter Minter to unregister
     */
    function unregisterMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.remove(minter), "Not yet minter");

        emit MinterRegistrationChanged(minter, false);
    }

    /**
     * @dev Sets granular token managers if current token manager(s) allow it
     * @param _ids Edition / token ids
     * @param _tokenManagers Token managers to set for tokens / editions
     */
    function setGranularTokenManagers(uint256[] calldata _ids, address[] calldata _tokenManagers)
        external
        nonReentrant
    {
        address msgSender = _msgSender();
        address tempOwner = owner();

        uint256 idsLength = _ids.length;
        for (uint256 i = 0; i < idsLength; i++) {
            require(_isValidTokenManager(_tokenManagers[i]), "Invalid TM");
            address currentTokenManager = tokenManager(_ids[i]);
            if (currentTokenManager == address(0)) {
                require(msgSender == tempOwner, "Not owner");
            } else {
                require(ITokenManager(currentTokenManager).canSwap(msgSender, _ids[i], _managers[i]), "Can't swap");
            }

            _managers[_ids[i]] = _tokenManagers[i];
        }

        emit GranularTokenManagersSet(_ids, _tokenManagers);
    }

    /**
     * @dev Remove granular token managers
     * @param _ids Edition / token ids to remove token managers for
     */
    function removeGranularTokenManagers(uint256[] calldata _ids) external nonReentrant {
        address msgSender = _msgSender();

        uint256 idsLength = _ids.length;
        for (uint256 i = 0; i < idsLength; i++) {
            address currentTokenManager = _managers[_ids[i]];
            require(currentTokenManager != address(0), "TM non-existent");
            require(ITokenManager(currentTokenManager).canRemoveItself(msgSender, _ids[i]), "Can't remove");

            _managers[_ids[i]] = address(0);
        }

        emit GranularTokenManagersRemoved(_ids);
    }

    /**
     * @dev Set default token manager if current token manager allows it
     * @param _defaultTokenManager New default token manager
     */
    function setDefaultTokenManager(address _defaultTokenManager) external nonReentrant {
        require(_isValidTokenManager(_defaultTokenManager), "Invalid TM");
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        if (currentTokenManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(ITokenManager(currentTokenManager).canSwap(msgSender, 0, _defaultTokenManager), "Can't swap");
        }

        defaultManager = _defaultTokenManager;

        emit DefaultTokenManagerChanged(_defaultTokenManager);
    }

    /**
     * @dev Removes default token manager if current token manager allows it
     */
    function removeDefaultTokenManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        require(currentTokenManager != address(0), "Default TM not existent");
        require(ITokenManager(currentTokenManager).canRemoveItself(msgSender, 0), "Can't remove");

        defaultManager = address(0);

        emit DefaultTokenManagerChanged(address(0));
    }

    /**
     * @dev Sets default royalty if royalty manager allows it
     * @param _royalty New default royalty
     */
    function setDefaultRoyalty(IRoyaltyManager.Royalty calldata _royalty)
        external
        nonReentrant
        royaltyValid(_royalty.royaltyPercentageBPS)
    {
        address msgSender = _msgSender();

        address _royaltyManager = royaltyManager;
        if (_royaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(_royaltyManager).canSetDefaultRoyalty(_royalty, msgSender), "Can't set");
        }

        _defaultRoyalty = _royalty;

        emit DefaultRoyaltySet(_royalty.recipientAddress, _royalty.royaltyPercentageBPS);
    }

    /**
     * @dev Sets granular royalties (per token-grouping) if royalty manager allows it
     * @param ids Token / edition ids
     * @param _newRoyalties New royalties for each token / edition
     */
    function setGranularRoyalties(uint256[] calldata ids, IRoyaltyManager.Royalty[] calldata _newRoyalties)
        external
        nonReentrant
    {
        address msgSender = _msgSender();
        address tempOwner = owner();

        address _royaltyManager = royaltyManager;
        uint256 idsLength = ids.length;
        if (_royaltyManager == address(0)) {
            require(msgSender == tempOwner, "Not owner");

            for (uint256 i = 0; i < idsLength; i++) {
                require(_royaltyBPSValid(_newRoyalties[i].royaltyPercentageBPS), "BPS invalid");
                _royalties[ids[i]] = _newRoyalties[i];
            }
        } else {
            for (uint256 i = 0; i < idsLength; i++) {
                require(_royaltyBPSValid(_newRoyalties[i].royaltyPercentageBPS), "BPS invalid");
                require(
                    IRoyaltyManager(_royaltyManager).canSetGranularRoyalty(ids[i], _newRoyalties[i], msgSender),
                    "Can't set"
                );
                _royalties[ids[i]] = _newRoyalties[i];
            }
        }

        emit GranularRoyaltiesSet(ids, _newRoyalties);
    }

    /**
     * @dev Sets royalty manager if current one allows it
     * @param _royaltyManager New royalty manager
     */
    function setRoyaltyManager(address _royaltyManager) external nonReentrant {
        require(_isValidRoyaltyManager(_royaltyManager), "Invalid RM");
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        if (currentRoyaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(currentRoyaltyManager).canSwap(_royaltyManager, msgSender), "Can't swap");
        }

        royaltyManager = _royaltyManager;

        emit RoyaltyManagerChanged(_royaltyManager);
    }

    /**
     * @dev Removes royalty manager if current one allows it
     */
    function removeRoyaltyManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        require(currentRoyaltyManager != address(0), "RM non-existent");
        require(IRoyaltyManager(currentRoyaltyManager).canRemoveItself(msgSender), "Can't remove");

        royaltyManager = address(0);

        emit RoyaltyManagerChanged(address(0));
    }

    /**
     * @dev Freeze mints on contract forever
     */
    function freezeMints() external onlyOwner nonReentrant {
        _mintFrozen = 1;

        emit MintsFrozen();
    }

    /**
     * @dev Conforms to ERC-2981. Editions should overwrite to return royalty for entire edition
     * @param _tokenGroupingId Token id if on general, and edition id if on editions
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(uint256 _tokenGroupingId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        IRoyaltyManager.Royalty memory royalty = _royalties[_tokenGroupingId];
        if (royalty.recipientAddress == address(0)) {
            royalty = _defaultRoyalty;
        }

        receiver = royalty.recipientAddress;
        royaltyAmount = (_salePrice * uint256(royalty.royaltyPercentageBPS)) / 10000;
    }

    /**
     * @dev Returns the token manager for the id passed in.
     * @param id Token ID or Edition ID for Editions implementing contracts
     */
    function tokenManager(uint256 id) public view returns (address manager) {
        manager = defaultManager;
        address granularManager = _managers[id];

        if (granularManager != address(0)) {
            manager = granularManager;
        }
    }

    /**
     * @dev Initializes the contract, setting the creator as the initial owner.
     * @param _creator Contract creator
     * @param defaultRoyalty Default royalty for the contract
     * @param _defaultTokenManager Default token manager for the contract
     */
    function __ERC721Base_initialize(
        address _creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager
    ) internal onlyInitializing royaltyValid(defaultRoyalty.royaltyPercentageBPS) {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_creator);

        _defaultRoyalty = defaultRoyalty;

        if (_defaultTokenManager != address(0)) {
            defaultManager = _defaultTokenManager;
        }
    }

    /**
     * @dev Returns true if address is a valid tokenManager
     * @param _tokenManager Token manager being checked
     */
    function _isValidTokenManager(address _tokenManager) internal view returns (bool) {
        return _tokenManager.supportsInterface(type(ITokenManager).interfaceId);
    }

    /**
     * @dev Returns true if address is a valid royaltyManager
     * @param _royaltyManager Royalty manager being checked
     */
    function _isValidRoyaltyManager(address _royaltyManager) internal view returns (bool) {
        return _royaltyManager.supportsInterface(type(IRoyaltyManager).interfaceId);
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Returns true if royalty bps passed in is valid (<= 10000)
     * @param _royaltyBPS Royalty basis points
     */
    function _royaltyBPSValid(uint16 _royaltyBPS) private pure returns (bool) {
        return _royaltyBPS <= 10000;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title IRoyaltyManager
 * @author [email protected]
 * @dev Enables interfacing with custom royalty managers that define conditions on setting royalties for NFT contracts
 */
interface IRoyaltyManager {
    /**
     * @dev Struct containing values required to adhere to ERC-2981
     * @param recipientAddress Royalty recipient - can be EOA, royalty splitter contract, etc.
     * @param royaltyPercentageBPS Royalty cut, in basis points
     */
    struct Royalty {
        address recipientAddress;
        uint16 royaltyPercentageBPS;
    }

    /**
     * @dev Defines conditions around being able to swap royalty manager for another one
     * @param newRoyaltyManager New royalty manager being swapped in
     * @param sender msg sender
     */
    function canSwap(address newRoyaltyManager, address sender) external view returns (bool);

    /**
     * @dev Defines conditions around being able to remove current royalty manager
     * @param sender msg sender
     */
    function canRemoveItself(address sender) external view returns (bool);

    /**
     * @dev Defines conditions around being able to set granular royalty (per token or per edition)
     * @param id Edition / token ID whose royalty is being set
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetGranularRoyalty(
        uint256 id,
        Royalty calldata royalty,
        address sender
    ) external view returns (bool);

    /**
     * @dev Defines conditions around being able to set default royalty
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetDefaultRoyalty(Royalty calldata royalty, address sender) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title ITokenManager
 * @author [email protected]
 * @dev Enables interfacing with custom token managers
 */
interface ITokenManager {
    /**
     * @dev Returns whether metadata updater is allowed to update
     * @param sender Updater
     * @param id Token/edition who's uri is being updated
     *           If id is 0, implementation should decide behaviour for base uri update
     * @param newData Token's new uri if called by general contract, and any metadata field if called by editions
     * @return If invocation can update metadata
     */
    function canUpdateMetadata(
        address sender,
        uint256 id,
        bytes calldata newData
    ) external view returns (bool);

    /**
     * @dev Returns whether token manager can be swapped for another one by invocator
     * @dev Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @param newTokenManager New token manager being swapped to
     * @return If invocation can swap token managers
     */
    function canSwap(
        address sender,
        uint256 id,
        address newTokenManager
    ) external view returns (bool);

    /**
     * @dev Returns whether token manager can be removed
     * @dev Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @return If invocation can remove token manager
     */
    function canRemoveItself(address sender, uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
/* solhint-disable */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981Upgradeable.sol)

pragma solidity 0.8.10;

import "../ERC165/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity 0.8.10;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
/* solhint-disable */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165Upgradeable).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 *      Openzeppelin contract slightly modified by [email protected] highlight.xyz to be upgradeable.
 */
abstract contract ERC2771ContextUpgradeable is Initializable {
    address private _trustedForwarder;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function __ERC2771ContextUpgradeable__init__(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /* solhint-disable no-inline-assembly */
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
            /* solhint-enable no-inline-assembly */
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
/* solhint-disable */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ERC721Base.sol";
import "../metadata/MetadataEncryption.sol";
import "../tokenManager/interfaces/IPostTransfer.sol";
import "../tokenManager/interfaces/IPostBurn.sol";
import "./interfaces/IERC721GeneralMint.sol";
import "../utils/ERC721/ERC721URIStorageUpgradeable.sol";

/**
 * @title Generalized ERC721
 * @author [email protected]
 * @dev Generalized NFT smart contract
 */
contract ERC721General is ERC721Base, ERC721URIStorageUpgradeable, MetadataEncryption, IERC721GeneralMint {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Total tokens minted
     */
    uint256 public supply;

    /**
     * @dev Contract metadata
     */
    string public contractURI;

    /**
     * @dev Limit the supply to take advantage of over-promising in summation with multiple mint vectors
     */
    uint256 public limitSupply;

    /**
     * @dev Emitted when uris are set for tokens
     * @param ids IDs of tokens to set uris for
     * @param uris Uris to set on tokens
     */
    event TokenURIsSet(uint256[] ids, string[] uris);

    /**
     * @dev Emitted when limit supply is set
     * @param newLimitSupply Limit supply to set
     */
    event LimitSupplySet(uint256 indexed newLimitSupply);

    /**
     * @dev Emitted when hashed metadata config is set
     * @param hashedURIData Hashed uri data
     * @param hashedRotationData Hashed rotation key
     * @param _supply Supply of tokens to mint w/ reveal
     */
    event HashedMetadataConfigSet(bytes hashedURIData, bytes hashedRotationData, uint256 indexed _supply);

    /**
     * @dev Emitted when metadata is revealed
     * @param key Key used to decode hashed data
     * @param newRotationKey Actual rotation key to be used
     */
    event Revealed(bytes key, uint256 newRotationKey);

    /**
     * @param creator Creator/owner of contract
     * @param _contractURI Contract metadata
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinter Initial minter to register
     * @param newBaseURI Base URI for contract
     * @param _limitSupply Initial limit supply
     */
    function initialize(
        address creator,
        string memory _contractURI,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager,
        string memory _name,
        string memory _symbol,
        address trustedForwarder,
        address initialMinter,
        string calldata newBaseURI,
        uint256 _limitSupply
    ) external initializer nonReentrant {
        __ERC721URIStorage_init();
        __ERC721Base_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        __ERC721_init(_name, _symbol);
        _minters.add(initialMinter);
        contractURI = _contractURI;

        if (bytes(newBaseURI).length > 0) {
            _setBaseURI(newBaseURI);
        }

        if (_limitSupply > 0) {
            limitSupply = _limitSupply;

            emit LimitSupplySet(_limitSupply);
        }
    }

    /**
     * @dev See {IERC721GeneralMint-mintOneToOneRecipient}
     */
    function mintOneToOneRecipient(address recipient) external onlyMinter nonReentrant {
        require(_mintFrozen == 0, "Mint frozen");

        uint256 tempSupply = supply;
        tempSupply++;
        _requireLimitSupply(tempSupply);

        _mint(recipient, tempSupply);
        supply = tempSupply;
    }

    /**
     * @dev See {IERC721GeneralMint-mintAmountToOneRecipient}
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external onlyMinter nonReentrant {
        require(_mintFrozen == 0, "Mint frozen");
        uint256 tempSupply = supply; // cache

        for (uint256 i = 0; i < amount; i++) {
            tempSupply++;
            _mint(recipient, tempSupply);
        }

        _requireLimitSupply(tempSupply);
        supply = tempSupply;
    }

    /**
     * @dev See {IERC721GeneralMint-mintOneToMultipleRecipients}
     */
    function mintOneToMultipleRecipients(address[] calldata recipients) external onlyMinter nonReentrant {
        require(_mintFrozen == 0, "Mint frozen");
        uint256 recipientsLength = recipients.length;
        uint256 tempSupply = supply; // cache

        for (uint256 i = 0; i < recipientsLength; i++) {
            tempSupply++;
            _mint(recipients[i], tempSupply);
        }

        _requireLimitSupply(tempSupply);
        supply = tempSupply;
    }

    /**
     * @dev See {IERC721GeneralMint-mintSameAmountToMultipleRecipients}
     */
    function mintSameAmountToMultipleRecipients(address[] calldata recipients, uint256 amount)
        external
        onlyMinter
        nonReentrant
    {
        require(_mintFrozen == 0, "Mint frozen");
        uint256 recipientsLength = recipients.length;
        uint256 tempSupply = supply; // cache

        for (uint256 i = 0; i < recipientsLength; i++) {
            for (uint256 j = 0; j < amount; j++) {
                tempSupply++;
                _mint(recipients[i], tempSupply);
            }
        }

        _requireLimitSupply(tempSupply);
        supply = tempSupply;
    }

    /**
     * @dev Override base URI system for select tokens, with custom per-token metadata
     * @param ids IDs of tokens to override base uri system for with custom uris
     * @param uris Custom uris
     */
    function setTokenURIs(uint256[] calldata ids, string[] calldata uris) external nonReentrant {
        uint256 idsLength = ids.length;
        require(idsLength == uris.length, "Mismatched array lengths");

        for (uint256 i = 0; i < idsLength; i++) {
            _setTokenURI(ids[i], uris[i]);
        }

        emit TokenURIsSet(ids, uris);
    }

    /**
     * @dev Set base uri
     * @param newBaseURI New base uri to set
     */
    function setBaseURI(string calldata newBaseURI) external nonReentrant {
        require(bytes(newBaseURI).length > 0, "Empty string");

        address _manager = defaultManager;

        if (_manager == address(0)) {
            require(_msgSender() == owner(), "Not owner");
        } else {
            require(
                ITokenManager(_manager).canUpdateMetadata(_msgSender(), 0, bytes(newBaseURI)),
                "Can't update base uri"
            );
        }

        _setBaseURI(newBaseURI);
    }

    /**
     * @dev Set limit supply
     * @param _limitSupply Limit supply to set
     */
    function setLimitSupply(uint256 _limitSupply) external onlyOwner nonReentrant {
        // allow it to be 0, for post-mint
        limitSupply = _limitSupply;

        emit LimitSupplySet(_limitSupply);
    }

    /**
     * @dev Configure a reveal mint metadata
     * @param hashedURIData Hashed uri data
     * @param hashedRotationData Hashed rotation key
     * @param _supply Supply of tokens to mint w/ reveal
     */
    function setHashedMetadataConfig(
        bytes calldata hashedURIData,
        bytes calldata hashedRotationData,
        uint256 _supply
    ) external onlyOwner nonReentrant {
        (bytes memory encryptedURI, bytes32 provenanceHashURI) = abi.decode(hashedURIData, (bytes, bytes32));

        if (encryptedURI.length != 0 && provenanceHashURI != "") {
            _hashedBaseURIData = hashedURIData;
        }

        (bytes memory encryptedRotationKey, bytes32 provenanceHashRotation) = abi.decode(
            hashedRotationData,
            (bytes, bytes32)
        );

        if (encryptedRotationKey.length != 0 && provenanceHashRotation != "") {
            _hashedRotationKeyData = hashedRotationData;
        }

        supply = _supply;

        emit HashedMetadataConfigSet(hashedURIData, hashedRotationData, _supply);
    }

    /**
     * @dev Reveal metadata by decrypting encrypted base uri, and encrypted rotation key, appending the two
     * @param _key Encoded metadata decoder
     */
    function reveal(bytes calldata _key) external onlyOwner nonReentrant {
        bytes memory uriData = _hashedBaseURIData;
        (bytes memory encryptedURI, bytes32 provenanceHashURI) = abi.decode(uriData, (bytes, bytes32));

        require(encryptedURI.length != 0, "nothing to reveal");

        string memory revealedURI = string(encryptDecrypt(encryptedURI, _key));

        require(keccak256(abi.encodePacked(revealedURI, _key, block.chainid)) == provenanceHashURI, "Incorrect key");

        baseURI = revealedURI;
        delete _hashedBaseURIData;

        bytes memory rotationData = _hashedRotationKeyData;
        (bytes memory encryptedRotationKey, bytes32 provenanceHashRotation) = abi.decode(
            rotationData,
            (bytes, bytes32)
        );

        require(encryptedRotationKey.length != 0, "nothing to reveal");

        uint256 revealedRotation = _sliceUint(encryptDecrypt(encryptedRotationKey, _key), 0);

        require(
            keccak256(abi.encodePacked(revealedRotation, _key, block.chainid)) == provenanceHashRotation,
            "Incorrect key"
        );

        _rotationKey = revealedRotation;
        delete _hashedRotationKeyData;

        emit Revealed(_key, revealedRotation);
    }

    /**
     * @dev See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        ERC721Upgradeable.transferFrom(from, to, tokenId);

        address _manager = tokenManager(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override nonReentrant {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = tokenManager(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }
    }

    /**
     * @dev See {IERC721-burn}. Overrides default behaviour to check associated tokenManager.
     */
    function burn(uint256 tokenId) public nonReentrant {
        address _manager = tokenManager(tokenId);

        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostBurn).interfaceId)) {
            address owner = ownerOf(tokenId);
            IPostBurn(_manager).postBurn(_msgSender(), owner, tokenId);
        } else {
            // default to restricting burn to owner or operator if a valid TM isn't present
            require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or operator");
        }

        _burn(tokenId);
    }

    /**
     * @dev Overrides tokenURI to first rotate the token id
     * @param tokenId ID of token to get uri for
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint256 rotatedTokenId = tokenId + _rotationKey;
        if (rotatedTokenId > supply) {
            rotatedTokenId = rotatedTokenId - supply;
        }
        return ERC721URIStorageUpgradeable.tokenURI(rotatedTokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev Override base URI system for select tokens, with custom per-token metadata
     * @param tokenId Token to set uri for
     * @param _uri Uri to set on token
     */
    function _setTokenURI(uint256 tokenId, string calldata _uri) internal {
        address _manager = tokenManager(tokenId);
        address msgSender = _msgSender();

        address tempOwner = owner();
        if (_manager == address(0)) {
            require(msgSender == tempOwner, "Not owner");
        } else {
            require(ITokenManager(_manager).canUpdateMetadata(msgSender, tokenId, bytes(_uri)), "Can't update");
        }

        _tokenURIs[tokenId] = _uri;
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721Base, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ERC721Base, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Require the new supply of tokens after mint to be less than limit supply
     * @param newSupply New supply
     */
    function _requireLimitSupply(uint256 newSupply) internal view {
        uint256 _limitSupply = limitSupply;
        require(_limitSupply == 0 || newSupply <= _limitSupply, "Over limit supply");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Utilities for metadata encryption and decryption
 * @author [email protected]
 */
abstract contract MetadataEncryption {
    /// @dev See: https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain
    function encryptDecrypt(bytes memory data, bytes calldata key) public pure returns (bytes memory result) {
        // Store data length on stack for later use
        uint256 length = data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Set result to free memory pointer
            result := mload(0x40)
            // Increase free memory pointer by lenght + 32
            mstore(0x40, add(add(result, length), 32))
            // Set result length
            mstore(result, length)
        }

        // Iterate over the data stepping by 32 bytes
        for (uint256 i = 0; i < length; i += 32) {
            // Generate hash of the key and offset
            bytes32 hash = keccak256(abi.encodePacked(key, i));

            bytes32 chunk;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Read 32-bytes data chunk
                chunk := mload(add(data, add(i, 32)))
            }
            // XOR the chunk with hash
            chunk ^= hash;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Write 32-byte encrypted chunk
                mstore(add(result, add(i, 32)), chunk)
            }
        }
    }

    function _sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }
        return x;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @author [email protected]
 * @dev If token managers implement this, transfer actions will call
 *      postSafeTransferFrom or postTransferFrom on the token manager.
 */
interface IPostTransfer {
    /**
     * @dev Hook called by community after safe transfers, if token manager of transferred token implements this
     *      interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     * @param data Arbitrary data
     */
    function postSafeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    /**
     * @dev Hook called by community after transfers, if token manager of transferred token implements this interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     */
    function postTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @author [email protected]
 * @dev If token managers implement this, transfer actions will call
 *      postBurn on the token manager.
 */
interface IPostBurn {
    /**
     * @dev Hook called by contract after burn, if token manager of burned token implements this
     *      interface.
     * @param operator Operator burning tokens
     * @param sender Msg sender
     * @param id Burned token's id
     */
    function postBurn(
        address operator,
        address sender,
        uint256 id
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev General721 mint interface
 * @author [email protected]
 */
interface IERC721GeneralMint {
    /**
     * @dev Mint one token to one recipient
     * @param recipient Recipient of minted NFT
     */
    function mintOneToOneRecipient(address recipient) external;

    /**
     * @dev Mint an amount of tokens to one recipient
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external;

    /**
     * @dev Mint one token to multiple recipients. Useful for use-cases like airdrops
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToMultipleRecipients(address[] calldata recipients) external;

    /**
     * @dev Mint the same amount of tokens to multiple recipients
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted to each recipient
     */
    function mintSameAmountToMultipleRecipients(address[] calldata recipients, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.10;

import "./ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Appending URI storage utilities onto template ERC721 contract
 * @author [email protected] and OpenZeppelin
 * @dev ERC721 token with storage based token URI management. OpenZeppelin template edited by Highlight
 */
/* solhint-disable */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {}

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {}

    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    /**
     * @dev Hashed rotation key data
     */
    bytes internal _hashedRotationKeyData;

    /**
     * @dev Hashed base uri data
     */
    bytes internal _hashedBaseURIData;

    /**
     * @dev Rotation key
     */
    uint256 internal _rotationKey;

    /**
     * @dev Contract baseURI
     */
    string public baseURI;

    event BaseURISet(string oldBaseUri, string newBaseURI);

    /**
     * @dev Set contract baseURI
     */
    function _setBaseURI(string calldata newBaseURI) internal {
        emit BaseURISet(baseURI, newBaseURI);

        baseURI = newBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no token URI, return the base URI.
        if (bytes(_tokenURI).length == 0) {
            return super.tokenURI(tokenId);
        }

        return _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.10;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../ERC165/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
/* solhint-disable */
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (
                bytes4 retval
            ) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.10;

import "../ERC165/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
/* solhint-disable */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.8.10;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
/* solhint-disable */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.10;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
/* solhint-disable */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.10;

import "./IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
/* solhint-disable */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../erc721/ERC721Editions.sol";
import "../erc721/ERC721SingleEdition.sol";
import "../erc721/ERC721General.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title CollectionFactory
 * @author [email protected], [email protected]
 * @dev Factory Contract to setup collections
 */
contract CollectionFactory {
    /**
     * @dev MintManager for controlling all mint functionality
     */
    address public immutable mintManagerAddress;

    /**
     * @dev EditionsMetadataRenderer for handling Editions Metadata
     */
    address public immutable editionsMetadataRendererAddress;

    /**
     * @dev ERC721Editions implementation
     */
    address public immutable erc721EditionsImplementation;

    /**
     * @dev ERC721SingleEdition implementation
     */
    address public immutable erc721SingleEditionImplementation;

    /**
     * @dev ERC721General implementation
     */
    address public immutable erc721GeneralImplementation;

    /**
     * @dev Trusted forwarder of meta-transactions
     */
    address public immutable trustedForwarder;

    /**
     * @dev Initialize factory
     * @param _trustedForwarder Trusted meta-tx executor for system
     * @param _mintManagerAddress MintManager for controlling all mint functionality
     * @param _editionsMetadataRendererAddress EditionsMetadataRenderer for handling Editions Metadata
     * @param _erc721EditionsImplementation ERC721Editions implementation
     * @param _erc721SingleEditionImplementation ERC721SingleEdition implementation
     * @param _erc721GeneralImplementation ERC721General implementation
     */
    constructor(
        address _trustedForwarder,
        address _mintManagerAddress,
        address _editionsMetadataRendererAddress,
        address _erc721EditionsImplementation,
        address _erc721SingleEditionImplementation,
        address _erc721GeneralImplementation
    ) {
        trustedForwarder = _trustedForwarder;

        mintManagerAddress = _mintManagerAddress;

        editionsMetadataRendererAddress = _editionsMetadataRendererAddress;

        erc721EditionsImplementation = _erc721EditionsImplementation;
        erc721SingleEditionImplementation = _erc721SingleEditionImplementation;
        erc721GeneralImplementation = _erc721GeneralImplementation;
    }

    /**
     * @dev Initialize ERC721Edition collection, deployed via Create2
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721EditionCollection(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721EditionsImplementation, salt);
        ERC721Editions(clone).initialize(
            _creator,
            _defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            editionsMetadataRendererAddress,
            trustedForwarder,
            mintManagerAddress
        );
        return clone;
    }

    /**
     * @dev Initialize ERC721Edition collection, deployed via Create2 AND create first edition on it
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param _editionInfo First edition's info
     * @param _size First edition's size
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721EditionCollectionWithEdition(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        IEditionsMetadataRenderer.TokenEditionInfo memory _editionInfo,
        uint256 _size,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721EditionsImplementation, salt);
        ERC721Editions(clone).initialize(
            address(this),
            _defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            editionsMetadataRendererAddress,
            trustedForwarder,
            mintManagerAddress
        );
        ERC721Editions(clone).createEdition(
            abi.encode(_editionInfo),
            _size,
            _defaultTokenManager // apply default token manager to edition as well
        );
        ERC721Editions(clone).transferOwnership(_creator);
        return clone;
    }

    /**
     * @dev Initialize ERC721SingleEdition collection, deployed via Create2
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param _editionInfo Single edition's info
     * @param _size Single edition's size
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721SingleEditionCollection(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        IEditionsMetadataRenderer.TokenEditionInfo memory _editionInfo,
        uint256 _size,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721SingleEditionImplementation, salt);
        ERC721SingleEdition(clone).initialize(
            _creator,
            _defaultRoyalty,
            _defaultTokenManager,
            _contractURI,
            _name,
            _symbol,
            abi.encode(_editionInfo),
            _size,
            editionsMetadataRendererAddress,
            trustedForwarder,
            mintManagerAddress
        );
        return clone;
    }

    /**
     * @dev Initialize ERC721General collection, deployed via Create2
     * @param _creator Creator/owner of contract
     * @param _defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param baseUri Collection's base uri
     * @param limitSupply Collection's limit supply
     * @param salt Salt used to uniquely deploy collection (via Create2)
     */
    function setupERC721GeneralCollection(
        address _creator,
        IRoyaltyManager.Royalty memory _defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        string calldata baseUri,
        uint256 limitSupply,
        bytes32 salt // generate off-chain
    ) external returns (address) {
        address clone = Clones.cloneDeterministic(erc721GeneralImplementation, salt);
        ERC721General(clone).initialize(
            _creator,
            _contractURI,
            _defaultRoyalty,
            _defaultTokenManager,
            _name,
            _symbol,
            trustedForwarder,
            mintManagerAddress,
            baseUri,
            limitSupply
        );
        return clone;
    }

    /**
     * @dev Predict Create2 deployed ERC721Edition collection
     * @param salt Salt used to uniquely deploy collection
     */
    function predictERC721EditionCollectionAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc721EditionsImplementation, salt);
    }

    /**
     * @dev Predict Create2 deployed ERC721SingleEdition collection
     * @param salt Salt used to uniquely deploy collection
     */
    function predictERC721SingleEditionCollectionAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc721SingleEditionImplementation, salt);
    }

    /**
     * @dev Predict Create2 deployed ERC721General collection
     * @param salt Salt used to uniquely deploy collection
     */
    function predictERC721GeneralCollectionAddress(bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(erc721GeneralImplementation, salt);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/IERC721Editions.sol";
import "./ERC721Base.sol";
import "../utils/Ownable.sol";
import "../metadata/interfaces/IMetadataRenderer.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "./interfaces/IEditionCollection.sol";

import "../tokenManager/interfaces/IPostTransfer.sol";
import "../utils/ERC721/ERC721Upgradeable.sol";
import "./interfaces/IERC721EditionMint.sol";

/**
 * @title ERC721 Editions
 * @author [email protected], [email protected]
 * @dev Multiple Editions Per Collection
 */
contract ERC721Editions is IEditionCollection, IERC721Editions, IERC721EditionMint, ERC721Base, ERC721Upgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Contract metadata
     */
    string public contractURI;

    /**
     * @dev Keeps track of next token ID
     */
    uint256 private _nextTokenId;

    /**
     * @dev Generates metadata for contract and token
     */
    address private _metadataRendererAddress;

    /**
     * @dev Tracks current supply of each edition, edition indexed
     */
    uint256[] public editionCurrentSupply;

    /**
     * @dev Tracks size of each edition, edition indexed
     */
    uint256[] public editionMaxSupply;

    /**
     * @dev Tracks start token id each edition, edition indexed
     */
    uint256[] public editionStartId;

    /**
     * @dev Emitted when edition is created
     * @param size Edition size
     * @param editionTokenManager Token manager for edition
     */
    event EditionCreated(uint256 indexed size, address indexed editionTokenManager);

    /**
     * @param creator Creator/owner of contract
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param metadataRendererAddress Contract returning metadata for each edition
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinter Initial minter to register
     */
    function initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        address metadataRendererAddress,
        address trustedForwarder,
        address initialMinter
    ) external initializer nonReentrant {
        __ERC721Base_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC721_init(_name, _symbol);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        _metadataRendererAddress = metadataRendererAddress;
        _minters.add(initialMinter);
        _nextTokenId = 1;
        contractURI = _contractURI;
    }

    /**
     * @param _editionInfo Info of the Edition
     * @param _editionSize Size of the Edition
     * @param _editionTokenManager Edition's token manager
     * @dev Used to create a new Edition within the Collection
     */
    function createEdition(
        bytes memory _editionInfo,
        uint256 _editionSize,
        address _editionTokenManager
    ) external onlyOwner nonReentrant returns (uint256) {
        require(_editionSize > 0, "Edition size == 0");

        uint256 editionId = editionStartId.length;

        editionStartId.push(_nextTokenId);
        editionMaxSupply.push(_editionSize);
        editionCurrentSupply.push(0);

        _nextTokenId += _editionSize;

        IMetadataRenderer(_metadataRendererAddress).initializeMetadata(_editionInfo);

        if (_editionTokenManager != address(0)) {
            _managers[editionId] = _editionTokenManager;
        }

        emit EditionCreated(_editionSize, _editionTokenManager);

        return editionId;
    }

    /**
     * @dev See {IERC721EditionMint-mintOneToRecipient}
     */
    function mintOneToRecipient(uint256 editionId, address recipient)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(editionId, recipient, 1);
    }

    /**
     * @dev See {IERC721EditionMint-mintAmountToRecipient}
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(editionId, recipient, amount);
    }

    /**
     * @dev See {IERC721EditionMint-mintOneToRecipients}
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(editionId, recipients, 1);
    }

    /**
     * @dev See {IERC721EditionMint-mintAmountToRecipients}
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(editionId, recipients, amount);
    }

    /**
     * @dev See {IEditionCollection-getEditionDetails}
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return _getEditionDetails(editionId);
    }

    /**
     * @dev See {IEditionCollection-getEditionsDetailsAndUri}
     */
    function getEditionsDetailsAndUri(uint256[] calldata editionIds)
        external
        view
        returns (EditionDetails[] memory, string[] memory)
    {
        uint256 editionIdsLength = editionIds.length;
        EditionDetails[] memory editionsDetails = new EditionDetails[](editionIdsLength);
        string[] memory uris = new string[](editionIdsLength);

        for (uint256 i = 0; i < editionIdsLength; i++) {
            uris[i] = editionURI(editionIds[i]);
            editionsDetails[i] = _getEditionDetails(editionIds[i]);
        }

        return (editionsDetails, uris);
    }

    /**
     * @dev See {IEditionCollection-getEditionStartIds}
     */
    function getEditionStartIds() external view returns (uint256[] memory) {
        return editionStartId;
    }

    /**
     * @dev See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        ERC721Upgradeable.transferFrom(from, to, tokenId);

        address _manager = tokenManagerByTokenId(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override nonReentrant {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = tokenManagerByTokenId(tokenId);
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }
    }

    /**
     * @dev Conforms to ERC-2981.
     * @param _tokenId Token id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return ERC721Base.royaltyInfo(getEditionId(_tokenId), _salePrice);
    }

    /**
     * @dev See {IEditionCollection-getEditionId}
     */
    function getEditionId(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token doesn't exist");
        uint256 editionId = 0;
        uint256[] memory tempEditionStartId = editionStartId; // cache
        uint256 tempEditionStartIdLength = tempEditionStartId.length; // cache
        for (uint256 i = 0; i < tempEditionStartIdLength; i += 1) {
            if (tokenId >= tempEditionStartId[i]) {
                editionId = i;
            }
        }
        return editionId;
    }

    /**
     * @dev Used to get token manager of token id
     * @param tokenId ID of the token
     */
    function tokenManagerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenManager(getEditionId(tokenId));
    }

    /**
     * @dev Get URI for given edition id
     * @param editionId edition id to get uri for
     * @return base64-encoded json metadata object
     */
    function editionURI(uint256 editionId) public view returns (string memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return IEditionsMetadataRenderer(_metadataRendererAddress).editionURI(editionId);
    }

    /**
     * @dev Get URI for given token id
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return IMetadataRenderer(_metadataRendererAddress).tokenURI(tokenId);
    }

    /**
     * @dev See {IERC721Upgradeable-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param editionId Edition being minted on
     * @param recipients Recipients of newly minted tokens
     * @param _amount Amount minted to each recipient
     */
    function _mintEditions(
        uint256 editionId,
        address[] memory recipients,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 recipientsLength = recipients.length;

        uint256 maxSupply = editionMaxSupply[editionId];
        uint256 currentSupply = editionCurrentSupply[editionId];
        uint256 startId = editionStartId[editionId];
        uint256 endAt = currentSupply + (recipientsLength * _amount);

        require(endAt <= maxSupply, "Sold out");

        for (uint256 i = 0; i < recipientsLength; i++) {
            for (uint256 j = 0; j < _amount; j++) {
                _mint(recipients[i], startId + currentSupply);
                currentSupply += 1;
            }
        }

        editionCurrentSupply[editionId] = currentSupply;
        return endAt;
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param editionId Edition being minted on
     * @param recipient Recipient of newly minted token
     * @param _amount Amount minted to recipient
     */
    function _mintEditionsToOne(
        uint256 editionId,
        address recipient,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 maxSupply = editionMaxSupply[editionId];
        uint256 currentSupply = editionCurrentSupply[editionId];
        uint256 startId = editionStartId[editionId];
        uint256 endAt = currentSupply + _amount;

        require(endAt <= maxSupply, "Sold out");

        for (uint256 j = 0; j < _amount; j++) {
            _mint(recipient, startId + currentSupply);
            currentSupply += 1;
        }

        editionCurrentSupply[editionId] = currentSupply;
        return endAt;
    }

    /**
     * @dev Returns whether `editionId` exists.
     * @param editionId Id of edition being checked
     */
    function _editionExists(uint256 editionId) internal view returns (bool) {
        return editionId < editionCurrentSupply.length;
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721Base, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ERC721Base, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Get edition details
     * @param editionId Id of edition to get details for
     */
    function _getEditionDetails(uint256 editionId) private view returns (EditionDetails memory) {
        return
            EditionDetails(
                IEditionsMetadataRenderer(_metadataRendererAddress).editionInfo(address(this), editionId).name,
                editionMaxSupply[editionId],
                editionCurrentSupply[editionId],
                editionStartId[editionId]
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "../metadata/interfaces/IMetadataRenderer.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "./interfaces/IEditionCollection.sol";
import "./ERC721MinimizedBase.sol";
import "../tokenManager/interfaces/IPostTransfer.sol";
import "../utils/ERC721/ERC721Upgradeable.sol";
import "./interfaces/IERC721EditionMint.sol";

/**
 * @title ERC721 Single Edition
 * @author [email protected], [email protected]
 * @dev Single Edition Per Collection
 */
contract ERC721SingleEdition is IERC721EditionMint, IEditionCollection, ERC721MinimizedBase, ERC721Upgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Contract metadata
     */
    string public contractURI;

    /**
     * @dev Keeps track of current token ID in supply
     */
    uint256 private _currentId;

    /**
     * @dev Generates metadata for contract and token
     */
    address private _metadataRendererAddress;

    /**
     * @notice Total size of edition that can be minted
     */
    uint256 public size;

    /**
     * @dev Emitted when edition is created
     * @param size Edition size
     * @param editionTokenManager Token manager for edition
     */
    event EditionCreated(uint256 indexed size, address indexed editionTokenManager);

    /**
     * @param creator Creator/owner of contract
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param _editionInfo Edition info
     * @param _size Edition size
     * @param metadataRendererAddress Contract returning metadata for each edition
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinter Initial minter to register
     */ 
    function initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        bytes memory _editionInfo,
        uint256 _size,
        address metadataRendererAddress,
        address trustedForwarder,
        address initialMinter
    ) external initializer nonReentrant {
        __ERC721MinimizedBase_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC721_init(_name, _symbol);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        size = _size;
        _metadataRendererAddress = metadataRendererAddress;
        IMetadataRenderer(metadataRendererAddress).initializeMetadata(_editionInfo);
        _minters.add(initialMinter);
        _currentId = 1;
        contractURI = _contractURI;

        emit EditionCreated(_size, _defaultTokenManager);
    }

    /**
     * @dev See {IERC721EditionMint-mintOneToRecipient}
     */
    function mintOneToRecipient(uint256 editionId, address recipient)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(recipient, 1);
    }

    /**
     * @dev See {IERC721EditionMint-mintAmountToRecipient}
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(recipient, amount);
    }

    /**
     * @dev See {IERC721EditionMint-mintOneToRecipients}
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(recipients, 1);
    }

    /**
     * @dev See {IERC721EditionMint-mintAmountToRecipients}
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(recipients, amount);
    }

    /**
     * @dev See {IEditionCollection-getEditionId}
     */
    function getEditionId(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Token Id doesn't exist");
        return 0;
    }

    /**
     * @dev See {IEditionCollection-getEditionDetails}
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return _getEditionDetails();
    }

    /**
     * @dev See {IEditionCollection-getEditionsDetailsAndUri}
     */
    function getEditionsDetailsAndUri(uint256[] calldata editionIds)
        external
        view
        returns (EditionDetails[] memory, string[] memory)
    {
        require(editionIds.length == 1, "One possible edition id");
        EditionDetails[] memory editionsDetails = new EditionDetails[](1);
        string[] memory uris = new string[](1);

        // expected to be 0, validated in editionURI call
        uint256 editionId = editionIds[0];

        uris[0] = editionURI(editionId);
        editionsDetails[0] = _getEditionDetails();

        return (editionsDetails, uris);
    }

    /**
     * @dev See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        ERC721Upgradeable.transferFrom(from, to, tokenId);

        address _manager = defaultManager;
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override nonReentrant {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = defaultManager;
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }
    }

    /**
     * @dev Conforms to ERC-2981.
     * @param // Token id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
        return ERC721MinimizedBase.royaltyInfo(0, _salePrice);
    }

    /**
     * @dev Get URI for given edition id
     * @param editionId edition id to get uri for
     * @return base64-encoded json metadata object
     */
    function editionURI(uint256 editionId) public view returns (string memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return IEditionsMetadataRenderer(_metadataRendererAddress).editionURI(editionId);
    }

    /**
     * @dev Get URI for given token id
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "No token");
        return IMetadataRenderer(_metadataRendererAddress).tokenURI(tokenId);
    }

    /**
     * @dev Used to get token manager of token id
     * @param tokenId ID of the token
     */
    function tokenManagerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenManager(tokenId);
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipients Recipients of newly minted tokens
     * @param _amount Amount minted to each recipient
     */
    function _mintEditions(address[] memory recipients, uint256 _amount) internal returns (uint256) {
        uint256 recipientsLength = recipients.length;

        uint256 tempCurrent = _currentId;
        uint256 endAt = tempCurrent + (recipientsLength * _amount) - 1;

        require(size == 0 || endAt <= size, "Sold out");

        for (uint256 i = 0; i < recipientsLength; i++) {
            for (uint256 j = 0; j < _amount; j++) {
                _mint(recipients[i], tempCurrent);
                tempCurrent += 1;
            }
        }
        _currentId = tempCurrent;
        return _currentId;
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipient Recipient of newly minted token
     * @param _amount Amount minted to recipient
     */
    function _mintEditionsToOne(address recipient, uint256 _amount) internal returns (uint256) {
        uint256 tempCurrent = _currentId;
        uint256 endAt = tempCurrent + _amount - 1;

        require(size == 0 || endAt <= size, "Sold out");

        for (uint256 j = 0; j < _amount; j++) {
            _mint(recipient, tempCurrent);
            tempCurrent += 1;
        }
        _currentId = tempCurrent;
        return _currentId;
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Returns whether `editionId` exists.
     */
    function _editionExists(uint256 editionId) internal pure returns (bool) {
        return editionId == 0;
    }

    /**
     * @dev Get edition details
     */
    function _getEditionDetails() private view returns (EditionDetails memory) {
        return EditionDetails(this.name(), size, _currentId - 1, 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Used to interface with EditionsMetadataRenderer
 * @author [email protected], [email protected]
 */
interface IEditionsMetadataRenderer {
    /**
     * @dev Token edition info
     * @param name Edition name
     * @param description Edition description
     * @param imageUrl Edition image url
     * @param animationUrl Edition animation url
     * @param externalUrl Edition external url
     * @param attributes Edition attributes
     */
    struct TokenEditionInfo {
        string name;
        string description;
        string imageUrl;
        string animationUrl;
        string externalUrl;
        string attributes;
    }

    /**
     * @dev Updates name on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param name New name of edition
     */
    function updateName(
        address editionsAddress,
        uint256 editionId,
        string calldata name
    ) external;

    /**
     * @dev Updates description on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param description New description of edition
     */
    function updateDescription(
        address editionsAddress,
        uint256 editionId,
        string calldata description
    ) external;

    /**
     * @dev Updates imageUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param imageUrl New imageUrl of edition
     */
    function updateImageUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata imageUrl
    ) external;

    /**
     * @dev Updates animationUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param animationUrl New animationUrl of edition
     */
    function updateAnimationUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata animationUrl
    ) external;

    /**
     * @dev Updates externalUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param externalUrl New externalUrl of edition
     */
    function updateExternalUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata externalUrl
    ) external;

    /**
     * @dev Updates attributes on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param attributes New attributes of edition
     */
    function updateAttributes(
        address editionsAddress,
        uint256 editionId,
        string calldata attributes
    ) external;

    /**
     * @dev Get an edition's uri. HAS to be called by collection
     * @param editionId Edition's id to get uri for
     */
    function editionURI(uint256 editionId) external view returns (string memory);

    /**
     * @dev Get an edition's info.
     * @param editionsAddress Address of collection that edition is on
     * @param editionsId Edition's id to get info for
     */
    function editionInfo(address editionsAddress, uint256 editionsId) external view returns (TokenEditionInfo memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Core creation interface
 * @author [email protected]
 */
interface IERC721Editions {
    /**
     * @dev Create an edition
     * @param _editionInfo Encoded edition metadata
     * @param _editionSize Edition size
     * @param _editionTokenManager Token manager for edition
     */
    function createEdition(
        bytes memory _editionInfo,
        uint256 _editionSize,
        address _editionTokenManager
    ) external returns (uint256);

    /**
     * @dev Get the first token minted for each edition passed in
     */
    function getEditionStartIds() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Used to interface with core of EditionsMetadataRenderer
 * @author Zora, [email protected]
 */
interface IMetadataRenderer {
    /**
     * @dev Store metadata for an edition
     * @param data Metadata
     */
    function initializeMetadata(bytes memory data) external;

    /**
     * @dev Get uri for token
     * @param tokenId ID of token to get uri for
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Interfaces with the details of editions on collections
 * @author [email protected], [email protected]
 */
interface IEditionCollection {
    /**
     * @dev Edition details
     * @param name Edition name
     * @param size Edition size
     * @param supply Total number of tokens minted on edition
     * @param initialTokenId Token id of first token minted in edition
     */
    struct EditionDetails {
        string name;
        uint256 size;
        uint256 supply;
        uint256 initialTokenId;
    }

    /**
     * @dev Get the edition a token belongs to
     * @param tokenId The token id of the token
     */
    function getEditionId(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get an edition's details
     * @param editionId Edition id
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory);

    /**
     * @dev Get the details and uris of a number of editions
     * @param editionIds List of editions to get info for
     */
    function getEditionsDetailsAndUri(uint256[] calldata editionIds)
        external
        view
        returns (EditionDetails[] memory, string[] memory uris);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Mint interface on editions contracts
 * @author [email protected]
 */
interface IERC721EditionMint {
    /**
     * @dev Mints one NFT to one recipient
     * @param editionId Edition to mint the NFT on
     * @param recipient Recipient of minted NFT
     */
    function mintOneToRecipient(uint256 editionId, address recipient) external returns (uint256);

    /**
     * @dev Mints an amount of NFTs to one recipient
     * @param editionId Edition to mint the NFTs on
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external returns (uint256);

    /**
     * @dev Mints one NFT each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients) external returns (uint256);

    /**
     * @dev Mints an amount of NFTs each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted per recipient
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../royaltyManager/interfaces/IRoyaltyManager.sol";
import "../tokenManager/interfaces/ITokenManager.sol";
import "../utils/Ownable.sol";
import "../utils/ERC2981/IERC2981Upgradeable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../utils/ERC165/ERC165CheckerUpgradeable.sol";

/**
 * @title Minimized Base ERC721
 * @author [email protected]
 * @dev Core piece of Highlight NFT contracts (V2), branch for ERC721SingleEdition
 */
abstract contract ERC721MinimizedBase is
    OwnableUpgradeable,
    IERC2981Upgradeable,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165CheckerUpgradeable for address;

    /**
     * @dev Set of minters allowed to mint on contract
     */
    EnumerableSet.AddressSet internal _minters;

    /**
     * @dev Global token/edition manager default
     */
    address public defaultManager;

    /**
     * @dev Default royalty for entire contract
     */
    IRoyaltyManager.Royalty internal _defaultRoyalty;

    /**
     * @dev Royalty manager - optional contract that defines the conditions around setting royalties
     */
    address public royaltyManager;

    /**
     * @dev Freezes minting on smart contract forever
     */
    uint8 internal _mintFrozen;

    /**
     * @dev Emitted when minter is registered or unregistered
     * @param minter Minter that was changed
     * @param registered True if the minter was registered, false if unregistered
     */
    event MinterRegistrationChanged(address indexed minter, bool indexed registered);

    /**
     * @dev Emitted when default token manager changed
     * @param newDefaultTokenManager New default token manager. Zero address if old one was removed
     */
    event DefaultTokenManagerChanged(address indexed newDefaultTokenManager);

    /**
     * @dev Emitted when default royalty is set
     * @param recipientAddress Royalty recipient
     * @param royaltyPercentageBPS Percentage of sale (in basis points) owed to royalty recipient
     */
    event DefaultRoyaltySet(address indexed recipientAddress, uint16 indexed royaltyPercentageBPS);

    /**
     * @dev Emitted when royalty manager is updated
     * @param newRoyaltyManager New royalty manager. Zero address if old one was removed
     */
    event RoyaltyManagerChanged(address indexed newRoyaltyManager);

    /**
     * @dev Emitted when mints are frozen permanently
     */
    event MintsFrozen();

    /**
     * @dev Restricts calls to minters
     */
    modifier onlyMinter() {
        require(_minters.contains(_msgSender()), "Not minter");
        _;
    }

    /**
     * @dev Restricts calls if input royalty bps is over 10000
     */
    modifier royaltyValid(uint16 _royaltyBPS) {
        require(_royaltyBPS <= 10000, "Over BPS limit");
        _;
    }

    /**
     * @dev Registers a minter
     * @param minter New minter
     */
    function registerMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.add(minter), "Already a minter");

        emit MinterRegistrationChanged(minter, true);
    }

    /**
     * @dev Unregisters a minter
     * @param minter Minter to unregister
     */
    function unregisterMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.remove(minter), "Not yet minter");

        emit MinterRegistrationChanged(minter, false);
    }

    /**
     * @dev Set default token manager if current token manager allows it
     * @param _defaultTokenManager New default token manager
     */
    function setDefaultTokenManager(address _defaultTokenManager) external nonReentrant {
        require(_isValidTokenManager(_defaultTokenManager), "Invalid TM");
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        if (currentTokenManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(ITokenManager(currentTokenManager).canSwap(msgSender, 0, _defaultTokenManager), "Can't swap");
        }

        defaultManager = _defaultTokenManager;

        emit DefaultTokenManagerChanged(_defaultTokenManager);
    }

    /**
     * @dev Removes default token manager if current token manager allows it
     */
    function removeDefaultTokenManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        require(currentTokenManager != address(0), "Default TM not existent");
        require(ITokenManager(currentTokenManager).canRemoveItself(msgSender, 0), "Can't remove");

        defaultManager = address(0);

        emit DefaultTokenManagerChanged(address(0));
    }

    /**
     * @dev Sets default royalty if royalty manager allows it
     * @param _royalty New default royalty
     */
    function setDefaultRoyalty(IRoyaltyManager.Royalty calldata _royalty)
        external
        nonReentrant
        royaltyValid(_royalty.royaltyPercentageBPS)
    {
        address msgSender = _msgSender();

        address _royaltyManager = royaltyManager;
        if (_royaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(_royaltyManager).canSetDefaultRoyalty(_royalty, msgSender), "Can't set");
        }

        _defaultRoyalty = _royalty;

        emit DefaultRoyaltySet(_royalty.recipientAddress, _royalty.royaltyPercentageBPS);
    }

    /**
     * @dev Sets royalty manager if current one allows it
     * @param _royaltyManager New royalty manager
     */
    function setRoyaltyManager(address _royaltyManager) external nonReentrant {
        require(_isValidRoyaltyManager(_royaltyManager), "Invalid RM");
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        if (currentRoyaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(currentRoyaltyManager).canSwap(_royaltyManager, msgSender), "Can't swap");
        }

        royaltyManager = _royaltyManager;

        emit RoyaltyManagerChanged(_royaltyManager);
    }

    /**
     * @dev Removes royalty manager if current one allows it
     */
    function removeRoyaltyManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        require(currentRoyaltyManager != address(0), "RM non-existent");
        require(IRoyaltyManager(currentRoyaltyManager).canRemoveItself(msgSender), "Can't remove");

        royaltyManager = address(0);

        emit RoyaltyManagerChanged(address(0));
    }

    /**
     * @dev Freeze mints on contract forever
     */
    function freezeMints() external onlyOwner nonReentrant {
        _mintFrozen = 1;

        emit MintsFrozen();
    }

    /**
     * @dev Conforms to ERC-2981. Editions should overwrite to return royalty for entire edition
     * @param // Edition id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(
        uint256, /* _tokenGroupingId */
        uint256 _salePrice
    ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
        IRoyaltyManager.Royalty memory royalty = _defaultRoyalty;

        receiver = royalty.recipientAddress;
        royaltyAmount = (_salePrice * uint256(royalty.royaltyPercentageBPS)) / 10000;
    }

    /**
     * @dev Returns the token manager for the id passed in.
     * @param // Token ID or Edition ID for Editions implementing contracts
     */
    function tokenManager(
        uint256 /* id */
    ) public view returns (address manager) {
        return defaultManager;
    }

    /**
     * @dev Initializes the contract, setting the creator as the initial owner.
     * @param creator Contract creator
     * @param defaultRoyalty Default royalty for the contract
     * @param _defaultTokenManager Default token manager for the contract
     */
    function __ERC721MinimizedBase_initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager
    ) internal onlyInitializing royaltyValid(defaultRoyalty.royaltyPercentageBPS) {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(creator);

        _defaultRoyalty = defaultRoyalty;

        defaultManager = _defaultTokenManager;
    }

    /**
     * @dev Returns true if address is a valid tokenManager
     * @param _tokenManager Token manager being checked
     */
    function _isValidTokenManager(address _tokenManager) internal view returns (bool) {
        return _tokenManager.supportsInterface(type(ITokenManager).interfaceId);
    }

    /**
     * @dev Returns true if address is a valid royaltyManager
     * @param _royaltyManager Royalty manager being checked
     */
    function _isValidRoyaltyManager(address _royaltyManager) internal view returns (bool) {
        return _royaltyManager.supportsInterface(type(IRoyaltyManager).interfaceId);
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { MetadataRendererUtil } from "./MetadataRendererUtil.sol";
import "./interfaces/IMetadataRenderer.sol";
import "./interfaces/IEditionsMetadataRenderer.sol";
import "../erc721/interfaces/IEditionCollection.sol";
import "../tokenManager/interfaces/ITokenManager.sol";
import "../erc721/ERC721MinimizedBase.sol";

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Editions Metadata Render
 * @author [email protected], [email protected]
 * @dev Editions ERC721 Metadata Renderer
 * Inspired by Zora (zora.co) Editions Contract
 */
contract EditionsMetadataRenderer is
    IMetadataRenderer,
    IEditionsMetadataRenderer,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev Maps collection to list of edition infos for each edition on collection, edition-indexed
     */
    mapping(address => TokenEditionInfo[]) public tokenInfos;

    /**
     * @dev Emitted when edition's metadata is initialized
     * @param contractAddress Collection address of edition
     * @param editionId Edition id
     * @param data Edition metadata
     */
    event MetadataInitialized(address indexed contractAddress, uint256 indexed editionId, bytes data);

    /**
     * @dev Emitted when edition's name is updated
     * @param contractAddress Collection address of edition
     * @param editionId Edition id
     * @param data Changed metadata (in this case, name)
     */
    event NameUpdated(address indexed contractAddress, uint256 indexed editionId, string data);

    /**
     * @dev Emitted when edition's description is updated
     * @param contractAddress Collection address of edition
     * @param editionId Edition id
     * @param data Changed metadata (in this case, description)
     */
    event DescriptionUpdated(address indexed contractAddress, uint256 indexed editionId, string data);

    /**
     * @dev Emitted when edition's imageUrl is updated
     * @param contractAddress Collection address of edition
     * @param editionId Edition id
     * @param data Changed metadata (in this case, imageUrl)
     */
    event ImageUrlUpdated(address indexed contractAddress, uint256 indexed editionId, string data);

    /**
     * @dev Emitted when edition's animationUrl is updated
     * @param contractAddress Collection address of edition
     * @param editionId Edition id
     * @param data Changed metadata (in this case, animationUrl)
     */
    event AnimationUrlUpdated(address indexed contractAddress, uint256 indexed editionId, string data);

    /**
     * @dev Emitted when edition's externalUrl is updated
     * @param contractAddress Collection address of edition
     * @param editionId Edition id
     * @param data Changed metadata (in this case, externalUrl)
     */
    event ExternalUrlUpdated(address indexed contractAddress, uint256 indexed editionId, string data);

    /**
     * @dev Emitted when edition's attributes is updated
     * @param contractAddress Collection address of edition
     * @param editionId Edition id
     * @param data Changed metadata (in this case, attributes)
     */
    event AttributesUpdated(address indexed contractAddress, uint256 indexed editionId, string data);

    /**
     * @dev Initialize implementation with initial owner
     * @param _owner Initial owner
     */
    function initialize(address _owner) external initializer nonReentrant {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_owner);
    }

    /**
     * @dev Add TokenInfo data for edition
     * @param data Token Info data encoded
     */
    function initializeMetadata(bytes memory data) external nonReentrant {
        address msgSender = msg.sender;
        tokenInfos[msgSender].push(abi.decode(data, (TokenEditionInfo)));

        emit MetadataInitialized(msgSender, tokenInfos[msgSender].length, data);
    }

    /**
     * See {IEditionsMetadataRenderer-updateName}
     */
    function updateName(
        address editionsAddress,
        uint256 editionId,
        string calldata name
    ) external nonReentrant {
        require(_verifyCanUpdateMetadata(editionsAddress, editionId, name), "Can't update metadata");

        tokenInfos[editionsAddress][editionId].name = name;

        emit NameUpdated(editionsAddress, editionId, name);
    }

    /**
     * See {IEditionsMetadataRenderer-updateDescription}
     */
    function updateDescription(
        address editionsAddress,
        uint256 editionId,
        string calldata description
    ) external nonReentrant {
        require(_verifyCanUpdateMetadata(editionsAddress, editionId, description), "Can't update metadata");

        tokenInfos[editionsAddress][editionId].description = description;

        emit DescriptionUpdated(editionsAddress, editionId, description);
    }

    /**
     * See {IEditionsMetadataRenderer-updateImageUrl}
     */
    function updateImageUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata imageUrl
    ) external nonReentrant {
        require(_verifyCanUpdateMetadata(editionsAddress, editionId, imageUrl), "Can't update metadata");

        tokenInfos[editionsAddress][editionId].imageUrl = imageUrl;

        emit ImageUrlUpdated(editionsAddress, editionId, imageUrl);
    }

    /**
     * See {IEditionsMetadataRenderer-updateAnimationUrl}
     */
    function updateAnimationUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata animationUrl
    ) external nonReentrant {
        require(_verifyCanUpdateMetadata(editionsAddress, editionId, animationUrl), "Can't update metadata");

        tokenInfos[editionsAddress][editionId].animationUrl = animationUrl;

        emit AnimationUrlUpdated(editionsAddress, editionId, animationUrl);
    }

    /**
     * See {IEditionsMetadataRenderer-updateExternalUrl}
     */
    function updateExternalUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata externalUrl
    ) external nonReentrant {
        require(_verifyCanUpdateMetadata(editionsAddress, editionId, externalUrl), "Can't update metadata");

        tokenInfos[editionsAddress][editionId].externalUrl = externalUrl;

        emit ExternalUrlUpdated(editionsAddress, editionId, externalUrl);
    }

    /**
     * See {IEditionsMetadataRenderer-updateAttributes}
     */
    function updateAttributes(
        address editionsAddress,
        uint256 editionId,
        string calldata attributes
    ) external nonReentrant {
        require(_verifyCanUpdateMetadata(editionsAddress, editionId, attributes), "Can't update metadata");

        tokenInfos[editionsAddress][editionId].attributes = attributes;

        emit AttributesUpdated(editionsAddress, editionId, attributes);
    }

    /**
     * @dev If edition has a token manager, delegate management of updatability to it
            Otherwise, updater must be collection owner
     * @param editionsAddress Collection address (where edition is on)
     * @param editionId ID of edition
     * @param newMetadata New metadata that was changed for edition
     */
    function _verifyCanUpdateMetadata(
        address editionsAddress,
        uint256 editionId,
        string calldata newMetadata
    ) private view returns (bool) {
        address _manager = ERC721MinimizedBase(editionsAddress).tokenManager(editionId);
        if (_manager == address(0)) {
            return msg.sender == OwnableUpgradeable(editionsAddress).owner();
        } else {
            return ITokenManager(_manager).canUpdateMetadata(msg.sender, editionId, bytes(newMetadata));
        }
    }

    /**
     * @dev Returns Edition URI based on EditionID
     * @param editionId ID to get the EditionURI for
     */
    function editionURI(uint256 editionId) external view override returns (string memory) {
        IEditionCollection.EditionDetails memory details = IEditionCollection(msg.sender).getEditionDetails(editionId);
        TokenEditionInfo storage info = tokenInfos[msg.sender][editionId];
        return _createEditionMetadata(info, details.size);
    }

    /**
     * @dev Returns Token URI based on TokenID
     * @param tokenId ID to get the TokenURI for
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        IEditionCollection collection = IEditionCollection(msg.sender);
        uint256 editionId = collection.getEditionId(tokenId);
        IEditionCollection.EditionDetails memory details = collection.getEditionDetails(editionId);
        uint256 editionTokenId = tokenId - details.initialTokenId + 1;
        TokenEditionInfo storage info = tokenInfos[msg.sender][editionId];
        return _createTokenMetadata(info, editionTokenId, details.size);
    }

    /**
     * @dev Get TokenEditionInfo for an edition
     * @param editionsAddress Address of Editions contract
     * @param editionsId Editions id
     */
    function editionInfo(address editionsAddress, uint256 editionsId) external view returns (TokenEditionInfo memory) {
        return tokenInfos[editionsAddress][editionsId];
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @dev Limit upgrades of contract to EditionsMetadataRenderer owner
     * @param // New implementation
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* solhint-enable no-empty-blocks */

    /**
     * @dev Returns encoded string uri
     * @param _name Name of the Contract
     * @param _symbol Symbol for the Contract
     */
    function _createContractMetadata(string memory _name, string memory _symbol) internal pure returns (string memory) {
        // solhint-disable quotes
        return
            MetadataRendererUtil.encodeMetadataJSON(
                abi.encodePacked('{"name": "', _name, '", "symbol": "', _symbol, '"}')
            );
        // solhint-enable quotes
    }

    /**
     * @dev Returns encoded string uri
     * @param _info Edition Token Info
     * @param _editionSize Size of the Edition
     */
    function _createEditionMetadata(TokenEditionInfo memory _info, uint256 _editionSize)
        internal
        pure
        returns (string memory)
    {
        string memory _size = "Unlimited";
        if (_editionSize > 0) {
            _size = MetadataRendererUtil.numberToString(_editionSize);
        }
        string memory attributes = _info.attributes;
        bool noAttributes = bytes(_info.attributes).length < 1;
        if (noAttributes) {
            attributes = "[]";
        }
        string memory _tokenMedia = _tokenMediaData(_info.imageUrl, _info.animationUrl);
        // solhint-disable quotes
        return
            MetadataRendererUtil.encodeMetadataJSON(
                abi.encodePacked(
                    '{"name": "',
                    _info.name,
                    '", "',
                    'size": "',
                    _size,
                    '", "',
                    'description": "',
                    _info.description,
                    '", ',
                    _tokenMedia,
                    '"external_url": "',
                    _info.externalUrl,
                    '", "',
                    'attributes": ',
                    attributes,
                    "}"
                )
            );
        // solhint-enable quotes
    }

    /**
     * @dev Returns encoded string uri
     * @param _info Edition Token Info
     * @param _editionTokenId ID of the Token within the Edition
     * @param _editionSize Size of the Edition
     */
    function _createTokenMetadata(
        TokenEditionInfo memory _info,
        uint256 _editionTokenId,
        uint256 _editionSize
    ) internal pure returns (string memory) {
        string memory _ofEdition = "";
        if (_editionSize > 0) {
            _ofEdition = string(abi.encodePacked("/", MetadataRendererUtil.numberToString(_editionSize)));
        }
        string memory attributes = _info.attributes;
        bool noAttributes = bytes(_info.attributes).length < 1;
        if (noAttributes) {
            attributes = "[]";
        }
        string memory _tokenMedia = _tokenMediaData(_info.imageUrl, _info.animationUrl);
        /* solhint-disable quotes */
        return
            MetadataRendererUtil.encodeMetadataJSON(
                abi.encodePacked(
                    '{"name": "',
                    _info.name,
                    " ",
                    MetadataRendererUtil.numberToString(_editionTokenId),
                    _ofEdition,
                    '", "',
                    'description": "',
                    _info.description,
                    '", ',
                    _tokenMedia,
                    '"external_url": "',
                    _info.externalUrl,
                    '", "',
                    'attributes": ',
                    attributes,
                    "}"
                )
            );
        /* solhint-enable quotes */
    }

    /**
     * @dev Returns encoded media data
     * @param _imageUrl Edition image url
     * @param _animationUrl Edition animation url
     */
    function _tokenMediaData(string memory _imageUrl, string memory _animationUrl)
        internal
        pure
        returns (string memory)
    {
        bool hasImage = bytes(_imageUrl).length > 0;
        bool hasAnimation = bytes(_animationUrl).length > 0;
        // solhint-disable quotes
        if (hasImage && hasAnimation) {
            return string(abi.encodePacked('"image": "', _imageUrl, '", "animation_url": "', _animationUrl, '", '));
        }
        if (hasImage) {
            return string(abi.encodePacked('"image": "', _imageUrl, '", '));
        }
        if (hasAnimation) {
            return string(abi.encodePacked('"animation_url": "', _animationUrl, '", '));
        }
        // solhint-enable quotes

        return "";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title Metadata Render Helper
 * @author [email protected], Zora
 * @dev Helper methods for Metadata Rendering
 */
library MetadataRendererUtil {
    /**
     * @param json Raw json to base64 and turn into a data-uri
     * @dev Encodes the argument json bytes into base64-data uri format
     */
    function encodeMetadataJSON(bytes memory json) internal pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @param value number to return as a string
     * @dev Proxy to openzeppelin's toString function
     */
    function numberToString(uint256 value) internal pure returns (string memory) {
        return Strings.toString(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
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
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallUUPS(newImplementation, data, true);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
library StorageSlot {
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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../metadata/EditionsMetadataRenderer.sol";

/**
 * @author [email protected]
 * @dev Mock EditionsMetadataRenderer
 */
contract TestEditionsMetadataRenderer is EditionsMetadataRenderer {
    /**
     * @dev Test function to test upgrades
     */
    function test() external pure returns (string memory) {
        return "test";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "../erc721/interfaces/IERC721GeneralMint.sol";
import "../erc721/interfaces/IERC721EditionMint.sol";
import "./interfaces/INativeMetaTransaction.sol";
import "../utils/EIP712Upgradeable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MintManager
 * @author [email protected], [email protected]
 * @dev Faciliates lion's share of minting in Highlight protocol V2 by managing mint "vectors" on-chain and off-chain
 */
contract MintManager is EIP712Upgradeable, UUPSUpgradeable, OwnableUpgradeable, ERC2771ContextUpgradeable {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev On-chain mint vector
     * @param contractAddress NFT smart contract address
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param paymentRecipient Payment recipient
     * @param startTimestamp When minting opens on vector
     * @param endTimestamp When minting ends on vector
     * @param pricePerToken Price that has to be paid per minted token
     * @param tokenLimitPerTx Max number of tokens that can be minted in one transaction
     * @param maxTotalClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxUserClaimableViaVector Max number of tokens that can be minted by user via vector
     * @param totalClaimedViaVector Total number of tokens minted via vector
     * @param allowlistRoot Root of merkle tree with allowlist
     * @param paused If vector is paused
     */
    struct Vector {
        address contractAddress;
        address currency;
        address payable paymentRecipient;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 pricePerToken;
        uint64 tokenLimitPerTx;
        uint64 maxTotalClaimableViaVector;
        uint64 maxUserClaimableViaVector;
        uint64 totalClaimedViaVector;
        bytes32 allowlistRoot;
        uint8 paused;
    }

    /**
     * @dev On-chain mint vector mutability rules
     * @param updatesFrozen If true, vector cannot be updated
     * @param deleteFrozen If true, vector cannot be deleted
     * @param pausesFrozen If true, vector cannot be paused
     */
    struct VectorMutability {
        uint8 updatesFrozen;
        uint8 deleteFrozen;
        uint8 pausesFrozen;
    }

    /**
     * @dev Packet enabling impersonation of purchaser for currencies supporting meta-transactions
     * @param functionSignature Function to call on contract, with arguments encoded
     * @param sigR Elliptic curve signature component
     * @param sigS Elliptic curve signature component
     * @param sigV Elliptic curve signature component
     */
    struct PurchaserMetaTxPacket {
        bytes functionSignature;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }

    /**
     * @dev Claim that is signed off-chain with EIP-712, and unwrapped to facilitate fulfillment of mint
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param contractAddress NFT smart contract address
     * @param claimer Account able to use this claim
     * @param paymentRecipient Payment recipient
     * @param pricePerToken Price that has to be paid per minted token
     * @param numTokensToMint Number of NFTs to mint in this transaction
     * @param maxClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxClaimablePerUser Max number of tokens that can be minted by user via vector
     * @param editionId ID of edition to mint on. Unused if claim is passed into ERC721General minting function
     * @param claimExpiryTimestamp Time when claim expires
     * @param claimNonce Unique identifier of claim
     * @param offchainVectorId Unique identifier of vector offchain
     */
    struct Claim {
        address currency;
        address contractAddress;
        address claimer;
        address payable paymentRecipient;
        uint256 pricePerToken;
        uint64 numTokensToMint;
        uint256 maxClaimableViaVector;
        uint256 maxClaimablePerUser;
        uint256 editionId;
        uint256 claimExpiryTimestamp;
        bytes32 claimNonce;
        bytes32 offchainVectorId;
    }

    /**
     * @dev Claim that is signed off-chain with EIP-712, and unwrapped to facilitate fulfillment of mint.
     *      Includes meta-tx packets to impersonate purchaser and make payments.
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param contractAddress NFT smart contract address
     * @param claimer Account able to use this claim
     * @param paymentRecipient Payment recipient
     * @param pricePerToken Price that has to be paid per minted token
     * @param numTokensToMint Number of NFTs to mint in this transaction
     * @param purchaseToCreatorPacket Meta-tx packet that send portion of payment to creator
     * @param purchaseToPlatformPacket Meta-tx packet that send portion of payment to platform
     * @param maxClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxClaimablePerUser Max number of tokens that can be minted by user via vector
     * @param editionId ID of edition to mint on. Unused if claim is passed into ERC721General minting function
     * @param claimExpiryTimestamp Time when claim expires
     * @param claimNonce Unique identifier of claim
     * @param offchainVectorId Unique identifier of vector offchain
     */
    struct ClaimWithMetaTxPacket {
        address currency;
        address contractAddress;
        address claimer;
        uint256 pricePerToken;
        uint64 numTokensToMint;
        PurchaserMetaTxPacket purchaseToCreatorPacket;
        PurchaserMetaTxPacket purchaseToPlatformPacket;
        uint256 maxClaimableViaVector;
        uint256 maxClaimablePerUser;
        uint256 editionId; // unused if for general contract mints
        uint256 claimExpiryTimestamp;
        bytes32 claimNonce;
        bytes32 offchainVectorId;
    }

    /**
     * @dev Tracks current claim state of offchain vectors
     * @param numClaimed Total claimed on vector
     * @param numClaimedPerUser Tracks totals claimed per user on vector
     */
    struct OffchainVectorClaimState {
        uint256 numClaimed;
        mapping(address => uint256) numClaimedPerUser;
    }

    /* solhint-disable max-line-length */
    /**
     * @dev DEPRECATED - Claim typehash used via typed structured data hashing (EIP-712)
     */
    bytes32 private constant _CLAIM_TYPEHASH =
        keccak256(
            "Claim(address currency,address contractAddress,address claimer,address paymentRecipient,uint256 pricePerToken,uint64 numTokensToMint,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
        );

    /**
     * @dev DEPRECATED - Claim typehash used via typed structured data hashing (EIP-712)
     */
    bytes32 private constant _CLAIM_WITH_META_TX_PACKET_TYPEHASH =
        keccak256(
            "ClaimWithMetaTxPacket(address currency,address contractAddress,address claimer,uint256 pricePerToken,uint64 numTokensToMint,PurchaserMetaTxPacket purchaseToCreatorPacket,PurchaserMetaTxPacket purchaseToCreatorPacket,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
        );

    /* solhint-enable max-line-length */

    /**
     * @dev Platform receiving portion of payment
     */
    address payable private _platform;

    /**
     * @dev System-wide mint vectors
     */
    mapping(uint256 => Vector) public vectors;

    /**
     * @dev System-wide mint vectors' mutabilities
     */
    mapping(uint256 => VectorMutability) public vectorMutabilities;

    /**
     * @dev System-wide vector ids to (user to user claims count)
     */
    mapping(uint256 => mapping(address => uint64)) public userClaims;

    /**
     * @dev Tracks what nonces used in signed mint keys have been used for vectors enforced offchain
     *      Requires the platform to not re-use offchain vector IDs.
     */
    mapping(bytes32 => EnumerableSet.Bytes32Set) private _offchainVectorsToNoncesUsed;

    /**
     * @dev Tracks running state of offchain vectors
     */
    mapping(bytes32 => OffchainVectorClaimState) public offchainVectorsClaimState;

    /**
     * @dev Maps vector ids to edition ids
     */
    mapping(uint256 => uint256) public vectorToEditionId;

    /**
     * @dev Current vector id index
     */
    uint256 private _vectorSupply;

    /**
     * @dev Platform transaction executors
     */
    EnumerableSet.AddressSet internal _platformExecutors;

    /**
     * @dev Emitted when platform executor is added or removed
     * @param executor Changed executor
     * @param added True if executor was added and false otherwise
     */
    event PlatformExecutorChanged(address indexed executor, bool indexed added);

    /**
     * @dev Emitted when vector is created on-chain
     * @param vectorId ID of vector
     * @param editionId Edition id of vector, meaningful if vector is for Editions collection
     * @param vector Vector to create
     */
    event VectorCreated(uint256 indexed vectorId, uint256 indexed editionId, Vector vector);

    /**
     * @dev Emitted when vector is updated on-chain
     * @param vectorId ID of vector
     * @param newVector New vector details
     */
    event VectorUpdated(uint256 indexed vectorId, Vector newVector);

    /**
     * @dev Emitted when vector is deleted on-chain
     * @param vectorId ID of vector to delete
     */
    event VectorDeleted(uint256 indexed vectorId);

    /**
     * @dev Emitted when vector is paused or unpaused on-chain
     * @param vectorId ID of vector
     * @param paused True if vector was paused, false otherwise
     */
    event VectorPausedOrUnpaused(uint256 indexed vectorId, uint8 indexed paused);

    /**
     * @dev Emitted when vector mutability updated
     * @param vectorId ID of vector
     * @param _newVectorMutability New vector mutability
     */
    event VectorMutabilityUpdated(uint256 indexed vectorId, VectorMutability _newVectorMutability);

    /**
     * @dev Emits when native gas token held by contract is withdrawn by platform
     * @param withdrawnValue Amount withdrawn
     */
    event NativeGasTokenWithdrawn(uint256 withdrawnValue);

    /**
     * @dev Emitted when payment is made in native gas token
     * @param paymentRecipient Creator recipient of payment
     * @param vectorId Vector that payment was for
     * @param amountToCreator Amount sent to creator
     * @param percentageBPSOfTotal Percentage (in basis points) that was sent to creator, of total payment
     */
    event NativeGasTokenPayment(
        address indexed paymentRecipient,
        bytes32 indexed vectorId,
        uint256 amountToCreator,
        uint32 percentageBPSOfTotal
    );

    /**
     * @dev Emitted when payment is made in ERC20
     * @param currency ERC20 currency
     * @param paymentRecipient Creator recipient of payment
     * @param vectorId Vector that payment was for
     * @param payer Payer
     * @param amountToCreator Amount sent to creator
     * @param percentageBPSOfTotal Percentage (in basis points) that was sent to creator, of total payment
     */
    event ERC20Payment(
        address indexed currency,
        address indexed paymentRecipient,
        bytes32 indexed vectorId,
        address payer,
        uint256 amountToCreator,
        uint32 percentageBPSOfTotal
    );

    /**
     * @dev Emitted when payment is made in ERC20 via meta-tx packet method
     * @param currency ERC20 currency
     * @param msgSender Payer
     * @param vectorId Vector that payment was for
     * @param purchaseToCreatorPacket Meta-tx packet facilitating payment to creator
     * @param purchaseToPlatformPacket Meta-tx packet facilitating payment to platform
     * @param amount Payment amount
     */
    event ERC20PaymentMetaTxPackets(
        address indexed currency,
        address indexed msgSender,
        bytes32 indexed vectorId,
        PurchaserMetaTxPacket purchaseToCreatorPacket,
        PurchaserMetaTxPacket purchaseToPlatformPacket,
        uint256 amount
    );

    /**
     * @dev Restricts calls to platform
     */
    modifier onlyPlatform() {
        require(_msgSender() == _platform, "Not platform");
        _;
    }

    /**
     * @dev Initializes MintManager
     * @param platform Platform address
     * @param _owner MintManager owner
     * @param trustedForwarder Trusted meta-tx executor
     * @param initialExecutor Initial platform executor
     */
    function initialize(
        address payable platform,
        address _owner,
        address trustedForwarder,
        address initialExecutor
    ) external initializer {
        _platform = platform;
        __EIP721Upgradeable_initialize("MintManager", "1.0.0");
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        __Ownable_init();
        _transferOwnership(_owner);
        _platformExecutors.add(initialExecutor);
    }

    /**
     * @dev Add platform executor. Expected to be protected by a smart contract wallet.
     * @param _executor Platform executor to add
     */
    function addPlatformExecutor(address _executor) external onlyOwner {
        require(_executor != address(0), "Cannot set to null address");
        require(_platformExecutors.add(_executor), "Already added");
        emit PlatformExecutorChanged(_executor, true);
    }

    /**
     * @dev Deprecate platform executor. Expected to be protected by a smart contract wallet.
     * @param _executor Platform executor to deprecate
     */
    function deprecatePlatformExecutor(address _executor) external onlyOwner {
        require(_platformExecutors.remove(_executor), "Not deprecated");
        emit PlatformExecutorChanged(_executor, false);
    }

    /**
     * @dev Creates on-chain vector
     * @param _vector Vector to create
     * @param _vectorMutability Vector mutability
     * @param editionId Edition id of vector, meaningful if vector is for Editions collection
     */
    function createVector(
        Vector calldata _vector,
        VectorMutability calldata _vectorMutability,
        uint256 editionId
    ) external {
        require(Ownable(_vector.contractAddress).owner() == _msgSender(), "Not contract owner");
        require(_vector.totalClaimedViaVector == 0, "totalClaimedViaVector not 0");

        _vectorSupply++;
        vectors[_vectorSupply] = _vector;
        vectorMutabilities[_vectorSupply] = _vectorMutability;
        vectorToEditionId[_vectorSupply] = editionId;

        emit VectorCreated(_vectorSupply, editionId, _vector);
    }

    /**
     * @dev Updates on-chain vector
     * @param vectorId ID of vector to update
     * @param _newVector New vector details
     */
    function updateVector(uint256 vectorId, Vector calldata _newVector) external {
        Vector memory _oldVector = vectors[vectorId];
        require(vectorMutabilities[vectorId].updatesFrozen == 0, "Updates frozen");
        require(_oldVector.totalClaimedViaVector == _newVector.totalClaimedViaVector, "Total claimed different");
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        vectors[vectorId] = _newVector;

        emit VectorUpdated(vectorId, _newVector);
    }

    /**
     * @dev Deletes on-chain vector
     * @param vectorId ID of vector to delete
     */
    function deleteVector(uint256 vectorId) external {
        Vector memory _oldVector = vectors[vectorId];
        require(vectorMutabilities[vectorId].deleteFrozen == 0, "Delete frozen");
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        delete vectors[vectorId];
        delete vectorMutabilities[vectorId];
        delete vectorToEditionId[_vectorSupply];

        emit VectorDeleted(vectorId);
    }

    /**
     * @dev Pauses on-chain vector
     * @param vectorId ID of vector to pause
     */
    function pauseVector(uint256 vectorId) external {
        Vector memory _oldVector = vectors[vectorId];
        require(vectorMutabilities[vectorId].pausesFrozen == 0, "Pauses frozen");
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        vectors[vectorId].paused = 1;

        emit VectorPausedOrUnpaused(vectorId, 1);
    }

    /**
     * @dev Unpauses on-chain vector
     * @param vectorId ID of vector to unpause
     */
    function unpauseVector(uint256 vectorId) external {
        Vector memory _oldVector = vectors[vectorId];
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        vectors[vectorId].paused = 0;

        emit VectorPausedOrUnpaused(vectorId, 0);
    }

    /**
     * @dev Updates on-chain vector mutability. Protected by vector mutability field updatesFrozen itself
     * @param vectorId ID of vector mutability to update
     * @param _newVectorMutability New vector mutability details
     */
    function updateVectorMutability(uint256 vectorId, VectorMutability calldata _newVectorMutability) external {
        require(vectorMutabilities[vectorId].updatesFrozen == 0, "Updates frozen");
        require(Ownable(vectors[vectorId].contractAddress).owner() == _msgSender(), "Not contract owner");

        vectorMutabilities[vectorId] = _newVectorMutability;

        emit VectorMutabilityUpdated(vectorId, _newVectorMutability);
    }

    /**
     * @dev Mint on vector pointing to ERC721General collection
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function vectorMintGeneral721(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        require(_vector.allowlistRoot == 0, "Use allowlist mint");

        _vectorMintGeneral721(
            vectorId,
            _vector,
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on vector pointing to ERC721General collection, with allowlist
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param proof Proof of minter's inclusion in allowlist
     */
    function vectorMintGeneral721WithAllowlist(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient,
        bytes32[] calldata proof
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        // merkle tree allowlist validation
        bytes32 leaf = keccak256(abi.encodePacked(msgSender));
        require(MerkleProof.verify(proof, _vector.allowlistRoot, leaf), "Invalid proof");

        _vectorMintGeneral721(
            vectorId,
            _vector,
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on am ERC721General collection with a valid claim
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function gatedMintGeneral721(
        Claim calldata claim,
        bytes calldata claimSignature,
        address mintRecipient
    ) external payable {
        _processGatedMintClaim(claim, claimSignature);
        // mint NFT(s)
        if (claim.numTokensToMint == 1) {
            IERC721GeneralMint(claim.contractAddress).mintOneToOneRecipient(mintRecipient);
        } else {
            IERC721GeneralMint(claim.contractAddress).mintAmountToOneRecipient(mintRecipient, claim.numTokensToMint);
        }
    }

    /**
     * @dev Mint on am ERC721General collection with a valid claim, using meta-tx packets
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function gatedMintPaymentPacketGeneral721(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata claimSignature,
        address mintRecipient
    ) external {
        address msgSender = _msgSender();

        _verifyAndUpdateClaimWithMetaTxPacket(claim, claimSignature, msgSender);

        require(claim.currency != address(0), "Not ERC20 payment");

        // make payments
        if (claim.pricePerToken > 0) {
            _processERC20PaymentWithMetaTxPackets(
                claim.currency,
                claim.purchaseToCreatorPacket,
                claim.purchaseToPlatformPacket,
                msgSender,
                claim.offchainVectorId,
                claim.pricePerToken * claim.numTokensToMint
            );
        }

        // mint NFT(s)
        if (claim.numTokensToMint == 1) {
            IERC721GeneralMint(claim.contractAddress).mintOneToOneRecipient(mintRecipient);
        } else {
            IERC721GeneralMint(claim.contractAddress).mintAmountToOneRecipient(mintRecipient, claim.numTokensToMint);
        }
    }

    /**
     * @dev Mint on vector pointing to ERC721Editions or ERC721SingleEdiion collection
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function vectorMintEdition721(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        require(_vector.allowlistRoot == 0, "Use allowlist mint");

        _vectorMintEdition721(
            vectorId,
            _vector,
            vectorToEditionId[vectorId],
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on vector pointing to ERC721Editions or ERC721SingleEdiion collection, with allowlist
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param proof Proof of minter's inclusion in allowlist
     */
    function vectorMintEdition721WithAllowlist(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient,
        bytes32[] calldata proof
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        // merkle tree allowlist validation
        bytes32 leaf = keccak256(abi.encodePacked(msgSender));
        require(MerkleProof.verify(proof, _vector.allowlistRoot, leaf), "Invalid proof");

        _vectorMintEdition721(
            vectorId,
            _vector,
            vectorToEditionId[vectorId],
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on an ERC721Editions or ERC721SingleEdiion collection with a valid claim
     * @param _claim Claim
     * @param _signature Signed + encoded claim
     * @param _recipient Who to mint the NFT(s) to
     */
    function gatedMintEdition721(
        Claim calldata _claim,
        bytes calldata _signature,
        address _recipient
    ) external payable {
        _processGatedMintClaim(_claim, _signature);
        // mint NFT(s)
        if (_claim.numTokensToMint == 1) {
            IERC721EditionMint(_claim.contractAddress).mintOneToRecipient(_claim.editionId, _recipient);
        } else {
            IERC721EditionMint(_claim.contractAddress).mintAmountToRecipient(
                _claim.editionId,
                _recipient,
                _claim.numTokensToMint
            );
        }
    }

    /**
     * @dev Mint on an ERC721Editions or ERC721SingleEdiion collection with a valid claim, using meta-tx packets
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function gatedMintPaymentPacketEdition721(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata claimSignature,
        address mintRecipient
    ) external {
        address msgSender = _msgSender();

        _verifyAndUpdateClaimWithMetaTxPacket(claim, claimSignature, msgSender);

        require(claim.currency != address(0), "Has to be ERC20 payment");

        // make payments
        if (claim.pricePerToken > 0) {
            _processERC20PaymentWithMetaTxPackets(
                claim.currency,
                claim.purchaseToCreatorPacket,
                claim.purchaseToPlatformPacket,
                msgSender,
                claim.offchainVectorId,
                claim.pricePerToken * claim.numTokensToMint
            );
        }

        // mint NFT(s)
        if (claim.numTokensToMint == 1) {
            IERC721EditionMint(claim.contractAddress).mintOneToRecipient(claim.editionId, mintRecipient);
        } else {
            IERC721EditionMint(claim.contractAddress).mintAmountToRecipient(
                claim.editionId,
                mintRecipient,
                claim.numTokensToMint
            );
        }
    }

    /**
     * @dev Withdraw native gas token owed to platform
     */
    function withdrawNativeGasToken() external onlyPlatform {
        uint256 withdrawnValue = address(this).balance;
        (bool sentToPlatform, bytes memory dataPlatform) = _platform.call{ value: withdrawnValue }("");
        require(sentToPlatform, "Failed to send Ether to platform");

        emit NativeGasTokenWithdrawn(withdrawnValue);
    }

    /**
     * @dev Returns platform executors
     */
    function platformExecutors() external view returns (address[] memory) {
        return _platformExecutors.values();
    }

    /**
     * @dev Returns claim ids used for an offchain vector
     * @param vectorId ID of offchain vector
     */
    function getClaimNoncesUsedForOffchainVector(bytes32 vectorId) external view returns (bytes32[] memory) {
        return _offchainVectorsToNoncesUsed[vectorId].values();
    }

    /**
     * @dev Returns number of NFTs minted by user on vector
     * @param vectorId ID of offchain vector
     * @param user Minting user
     */
    function getNumClaimedPerUserOffchainVector(bytes32 vectorId, address user) external view returns (uint256) {
        return offchainVectorsClaimState[vectorId].numClaimedPerUser[user];
    }

    /**
     * @dev Verify that claim and claim signature are valid for a mint
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param expectedMsgSender Expected claimer to verify claim for
     */
    function verifyClaim(
        Claim calldata claim,
        bytes calldata signature,
        address expectedMsgSender
    ) external view returns (bool) {
        address signer = _claimSigner(claim, signature);
        require(expectedMsgSender == claim.claimer, "Sender not claimer");

        return
            _isPlatformExecutor(signer) &&
            !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
            block.timestamp <= claim.claimExpiryTimestamp &&
            (claim.maxClaimableViaVector == 0 ||
                claim.numTokensToMint + offchainVectorsClaimState[claim.offchainVectorId].numClaimed <=
                claim.maxClaimableViaVector) &&
            (claim.maxClaimablePerUser == 0 ||
                claim.numTokensToMint +
                    offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[expectedMsgSender] <=
                claim.maxClaimablePerUser);
    }

    /**
     * @dev Verify that claim and claim signature are valid for a mint (claim version with meta-tx packets)
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param expectedMsgSender Expected claimer to verify claim for
     */
    function verifyClaimWithMetaTxPacket(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata signature,
        address expectedMsgSender
    ) external view returns (bool) {
        address signer = _claimWithMetaTxPacketSigner(claim, signature);
        require(expectedMsgSender == claim.claimer, "Sender not claimer");

        return
            _isPlatformExecutor(signer) &&
            !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
            block.timestamp <= claim.claimExpiryTimestamp &&
            (claim.maxClaimableViaVector == 0 ||
                claim.numTokensToMint + offchainVectorsClaimState[claim.offchainVectorId].numClaimed <=
                claim.maxClaimableViaVector) &&
            (claim.maxClaimablePerUser == 0 ||
                claim.numTokensToMint +
                    offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[expectedMsgSender] <=
                claim.maxClaimablePerUser);
    }

    /**
     * @dev Returns if nonce is used for the vector
     * @param vectorId ID of offchain vector
     * @param nonce Nonce being checked
     */
    function isNonceUsed(bytes32 vectorId, bytes32 nonce) external view returns (bool) {
        return _offchainVectorsToNoncesUsed[vectorId].contains(nonce);
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @dev Limit upgrades of contract to MintManager owner
     * @param // New implementation address
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* solhint-enable no-empty-blocks */

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Process, verify, and update the state of a gated mint claim
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     */
    function _processGatedMintClaim(Claim calldata claim, bytes calldata claimSignature) private {
        address msgSender = _msgSender();

        _verifyAndUpdateClaim(claim, claimSignature, msgSender);

        // make payments
        if (claim.currency == address(0) && claim.pricePerToken > 0) {
            // pay in native gas token
            uint256 amount = claim.numTokensToMint * claim.pricePerToken;
            _processNativeGasTokenPayment(amount, claim.paymentRecipient, claim.offchainVectorId);
        } else if (claim.pricePerToken > 0) {
            // pay in ERC20
            uint256 amount = claim.numTokensToMint * claim.pricePerToken;
            _processERC20Payment(amount, claim.paymentRecipient, msgSender, claim.currency, claim.offchainVectorId);
        }
    }

    /**
     * @dev Verify, and update the state of a gated mint claim
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param msgSender Expected claimer
     */
    function _verifyAndUpdateClaim(
        Claim calldata claim,
        bytes calldata signature,
        address msgSender
    ) private {
        address signer = _claimSigner(claim, signature);
        require(msgSender == claim.claimer, "Sender not claimer");

        // cannot cache here due to nested mapping
        uint256 expectedNumClaimedViaVector = offchainVectorsClaimState[claim.offchainVectorId].numClaimed +
            claim.numTokensToMint;
        uint256 expectedNumClaimedByUser = offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[
            msgSender
        ] + claim.numTokensToMint;

        require(
            _isPlatformExecutor(signer) &&
                !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
                block.timestamp <= claim.claimExpiryTimestamp &&
                (expectedNumClaimedViaVector <= claim.maxClaimableViaVector || claim.maxClaimableViaVector == 0) &&
                (expectedNumClaimedByUser <= claim.maxClaimablePerUser || claim.maxClaimablePerUser == 0),
            "Invalid claim"
        );

        _offchainVectorsToNoncesUsed[claim.offchainVectorId].add(claim.claimNonce); // mark claim nonce as used
        // update claim state
        offchainVectorsClaimState[claim.offchainVectorId].numClaimed = expectedNumClaimedViaVector;
        offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[msgSender] = expectedNumClaimedByUser;
    }

    /**
     * @dev Verify, and update the state of a gated mint claim (version w/ meta-tx packets)
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param msgSender Expected claimer
     */
    function _verifyAndUpdateClaimWithMetaTxPacket(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata signature,
        address msgSender
    ) private {
        address signer = _claimWithMetaTxPacketSigner(claim, signature);
        require(msgSender == claim.claimer, "Sender not claimer");

        // cannot cache here due to nested mapping
        uint256 expectedNumClaimedViaVector = offchainVectorsClaimState[claim.offchainVectorId].numClaimed +
            claim.numTokensToMint;
        uint256 expectedNumClaimedByUser = offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[
            msgSender
        ] + claim.numTokensToMint;

        require(
            _isPlatformExecutor(signer) &&
                !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
                block.timestamp <= claim.claimExpiryTimestamp &&
                (expectedNumClaimedViaVector <= claim.maxClaimableViaVector || claim.maxClaimableViaVector == 0) &&
                (expectedNumClaimedByUser <= claim.maxClaimablePerUser || claim.maxClaimablePerUser == 0),
            "Invalid claim"
        );

        _offchainVectorsToNoncesUsed[claim.offchainVectorId].add(claim.claimNonce); // mark claim nonce as used
        // update claim state
        offchainVectorsClaimState[claim.offchainVectorId].numClaimed = expectedNumClaimedViaVector;
        offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[msgSender] = expectedNumClaimedByUser;
    }

    /**
     * @dev Process a mint on an on-chain vector
     * @param _vectorId ID of vector being minted on
     * @param _vector Vector being minted on
     * @param numTokensToMint Number of NFTs to mint on vector
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _processVectorMint(
        uint256 _vectorId,
        Vector memory _vector,
        uint64 numTokensToMint,
        uint256 newNumClaimedViaVector,
        uint256 newNumClaimedForUser
    ) private {
        require(
            _vector.maxTotalClaimableViaVector >= newNumClaimedViaVector || _vector.maxTotalClaimableViaVector == 0,
            "> maxClaimableViaVector"
        );
        require(
            _vector.maxUserClaimableViaVector >= newNumClaimedForUser || _vector.maxUserClaimableViaVector == 0,
            "> maxClaimablePerUser"
        );
        require(_vector.paused == 0, "Vector paused");
        require(
            (_vector.startTimestamp <= block.timestamp || _vector.startTimestamp == 0) &&
                (block.timestamp <= _vector.endTimestamp || _vector.endTimestamp == 0),
            "Invalid mint time"
        );
        require(numTokensToMint > 0, "Have to mint something");
        require(numTokensToMint <= _vector.tokenLimitPerTx, "Too many per tx");

        if (_vector.currency == address(0) && _vector.pricePerToken > 0) {
            // pay in native gas token
            uint256 amount = numTokensToMint * _vector.pricePerToken;
            _processNativeGasTokenPayment(amount, _vector.paymentRecipient, bytes32(_vectorId));
        } else if (_vector.pricePerToken > 0) {
            // pay in ERC20
            uint256 amount = numTokensToMint * _vector.pricePerToken;
            _processERC20Payment(amount, _vector.paymentRecipient, _msgSender(), _vector.currency, bytes32(_vectorId));
        }
    }

    /**
     * @dev Mint on vector pointing to ERC721General collection
     * @param _vectorId ID of vector
     * @param _vector Vector being minted on
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _vectorMintGeneral721(
        uint256 _vectorId,
        Vector memory _vector,
        uint64 numTokensToMint,
        address mintRecipient,
        uint256 newNumClaimedViaVector,
        uint256 newNumClaimedForUser
    ) private {
        _processVectorMint(_vectorId, _vector, numTokensToMint, newNumClaimedViaVector, newNumClaimedForUser);
        if (numTokensToMint == 1) {
            IERC721GeneralMint(_vector.contractAddress).mintOneToOneRecipient(mintRecipient);
        } else {
            IERC721GeneralMint(_vector.contractAddress).mintAmountToOneRecipient(mintRecipient, numTokensToMint);
        }
    }

    /**
     * @dev Mint on vector pointing to ERC721Editions or ERC721SingleEdiion collection
     * @param _vectorId ID of vector
     * @param _vector Vector being minted on
     * @param editionId ID of edition being minted on
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _vectorMintEdition721(
        uint256 _vectorId,
        Vector memory _vector,
        uint256 editionId,
        uint64 numTokensToMint,
        address mintRecipient,
        uint256 newNumClaimedViaVector,
        uint256 newNumClaimedForUser
    ) private {
        _processVectorMint(_vectorId, _vector, numTokensToMint, newNumClaimedViaVector, newNumClaimedForUser);
        if (numTokensToMint == 1) {
            IERC721EditionMint(_vector.contractAddress).mintOneToRecipient(editionId, mintRecipient);
        } else {
            IERC721EditionMint(_vector.contractAddress).mintAmountToRecipient(
                editionId,
                mintRecipient,
                numTokensToMint
            );
        }
    }

    /**
     * @dev Process payment in native gas token, sending to creator and platform
     * @param totalAmount Total amount being paid
     * @param recipient Creator recipient of payment
     * @param vectorId ID of vector (on-chain or off-chain)
     */
    function _processNativeGasTokenPayment(
        uint256 totalAmount,
        address payable recipient,
        bytes32 vectorId
    ) private {
        require(totalAmount == msg.value, "Invalid amount");

        uint256 amountToCreator = (totalAmount * 95) / 100;
        (bool sentToRecipient, bytes memory dataRecipient) = recipient.call{ value: amountToCreator }("");
        require(sentToRecipient, "Failed to send Ether to recipient");

        emit NativeGasTokenPayment(recipient, vectorId, amountToCreator, 9500);
    }

    /**
     * @dev Process payment in ERC20, sending to creator and platform
     * @param totalAmount Total amount being paid
     * @param recipient Creator recipient of payment
     * @param payer Payer
     * @param currency ERC20 currency
     * @param vectorId ID of vector (on-chain or off-chain)
     */
    function _processERC20Payment(
        uint256 totalAmount,
        address recipient,
        address payer,
        address currency,
        bytes32 vectorId
    ) private {
        uint256 amountToCreator = (totalAmount * 95) / 100;

        IERC20(currency).transferFrom(payer, recipient, amountToCreator);
        IERC20(currency).transferFrom(payer, _platform, totalAmount - amountToCreator);

        emit ERC20Payment(currency, recipient, vectorId, payer, amountToCreator, 9500);
    }

    /**
     * @dev Process payment in ERC20 with meta-tx packets, sending to creator and platform
     * @param currency ERC20 currency
     * @param purchaseToCreatorPacket Meta-tx packet facilitating payment to creator recipient
     * @param purchaseToPlatformPacket Meta-tx packet facilitating payment to platform
     * @param msgSender Claimer
     * @param vectorId ID of vector (on-chain or off-chain)
     * @param amount Total amount paid
     */
    function _processERC20PaymentWithMetaTxPackets(
        address currency,
        PurchaserMetaTxPacket calldata purchaseToCreatorPacket,
        PurchaserMetaTxPacket calldata purchaseToPlatformPacket,
        address msgSender,
        bytes32 vectorId,
        uint256 amount
    ) private {
        uint256 previousBalance = IERC20(currency).balanceOf(msgSender);
        INativeMetaTransaction(currency).executeMetaTransaction(
            msgSender,
            purchaseToCreatorPacket.functionSignature,
            purchaseToCreatorPacket.sigR,
            purchaseToCreatorPacket.sigS,
            purchaseToCreatorPacket.sigV
        );

        INativeMetaTransaction(currency).executeMetaTransaction(
            msgSender,
            purchaseToPlatformPacket.functionSignature,
            purchaseToPlatformPacket.sigR,
            purchaseToPlatformPacket.sigS,
            purchaseToPlatformPacket.sigV
        );

        require(IERC20(currency).balanceOf(msgSender) <= previousBalance - amount, "Invalid amount transacted");

        emit ERC20PaymentMetaTxPackets(
            currency,
            msgSender,
            vectorId,
            purchaseToCreatorPacket,
            purchaseToPlatformPacket,
            amount
        );
    }

    /**
     * @dev Recover claim signature signer
     * @param claim Claim
     * @param signature Claim signature
     */
    function _claimSigner(Claim calldata claim, bytes calldata signature) private view returns (address) {
        return
            _hashTypedDataV4(
                keccak256(bytes.concat(_claimABIEncoded1(claim), _claimABIEncoded2(claim.offchainVectorId)))
            ).recover(signature);
    }

    /**
     * @dev Recover claimWithMetaTxPacket signature signer
     * @param claim Claim
     * @param signature Claim signature
     */
    function _claimWithMetaTxPacketSigner(ClaimWithMetaTxPacket calldata claim, bytes calldata signature)
        private
        view
        returns (address)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    bytes.concat(
                        _claimWithMetaTxABIEncoded1(claim),
                        _claimWithMetaTxABIEncoded2(claim.claimNonce, claim.offchainVectorId)
                    )
                )
            ).recover(signature);
    }

    /**
     * @dev Returns true if account passed in is a platform executor
     * @param _executor Account being checked
     */
    function _isPlatformExecutor(address _executor) private view returns (bool) {
        return _platformExecutors.contains(_executor);
    }

    /* solhint-disable max-line-length */
    /**
     * @dev Get claim typehash
     */
    function _getClaimTypeHash() private pure returns (bytes32) {
        return
            keccak256(
                "Claim(address currency,address contractAddress,address claimer,address paymentRecipient,uint256 pricePerToken,uint64 numTokensToMint,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
            );
    }

    /**
     * @dev Get claimWithMetaTxPacket typehash
     */
    function _getClaimWithMetaTxPacketTypeHash() private pure returns (bytes32) {
        return
            keccak256(
                "ClaimWithMetaTxPacket(address currency,address contractAddress,address claimer,uint256 pricePerToken,uint64 numTokensToMint,PurchaserMetaTxPacket purchaseToCreatorPacket,PurchaserMetaTxPacket purchaseToPlatformPacket,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
            );
    }

    /* solhint-enable max-line-length */

    /**
     * @dev Return abi-encoded claim part one
     * @param claim Claim
     */
    function _claimABIEncoded1(Claim calldata claim) private pure returns (bytes memory) {
        return
            abi.encode(
                _getClaimTypeHash(),
                claim.currency,
                claim.contractAddress,
                claim.claimer,
                claim.paymentRecipient,
                claim.pricePerToken,
                claim.numTokensToMint,
                claim.maxClaimableViaVector,
                claim.maxClaimablePerUser,
                claim.editionId,
                claim.claimExpiryTimestamp,
                claim.claimNonce
            );
    }

    /**
     * @dev Return abi-encoded claim part two
     * @param offchainVectorId Offchain vector ID of claim
     */
    function _claimABIEncoded2(bytes32 offchainVectorId) private pure returns (bytes memory) {
        return abi.encode(offchainVectorId);
    }

    /**
     * @dev Return abi-encoded claimWithMetaTxPacket part one
     * @param claim Claim
     */
    function _claimWithMetaTxABIEncoded1(ClaimWithMetaTxPacket calldata claim) private pure returns (bytes memory) {
        return
            abi.encode(
                _getClaimWithMetaTxPacketTypeHash(),
                claim.currency,
                claim.contractAddress,
                claim.claimer,
                claim.pricePerToken,
                claim.numTokensToMint,
                claim.purchaseToCreatorPacket,
                claim.purchaseToPlatformPacket,
                claim.maxClaimableViaVector,
                claim.maxClaimablePerUser,
                claim.editionId,
                claim.claimExpiryTimestamp
            );
    }

    /**
     * @dev Return abi-encoded claimWithMetaTxPacket part two
     * @param claimNonce Claim's unique identifier
     * @param offchainVectorId Offchain vector ID of claim
     */
    function _claimWithMetaTxABIEncoded2(bytes32 claimNonce, bytes32 offchainVectorId)
        private
        pure
        returns (bytes memory)
    {
        return abi.encode(claimNonce, offchainVectorId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title NativeMetaTransaction interface. Used by eg. wETH on Polygon
 * @author [email protected]
 */
interface INativeMetaTransaction {
    /**
     * @dev Meta-transaction object
     * @param nonce Account nonce
     * @param from Account to be considered as sender
     * @param functionSignature Function to call on contract, with arguments encoded
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /**
     * @dev Execute meta transaction on contract containing EIP-712 stuff natively
     * @param userAddress User to be considered as sender
     * @param functionSignature Function to call on contract, with arguments encoded
     * @param sigR Elliptic curve signature component
     * @param sigS Elliptic curve signature component
     * @param sigV Elliptic curve signature component
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @author OpenZeppelin, modified by [email protected] to make compliant to upgradeable contracts
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
/* solhint-disable */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    uint256 private _CACHED_CHAIN_ID;

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP721Upgradeable_initialize(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        /* solhint-disable max-line-length */
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        /* solhint-enable max-line-length */
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../mint/MintManager.sol";

/**
 * @author [email protected]
 * @dev Mock MintManager
 */
contract TestMintManager is MintManager {
    /**
     * @dev Test function to test upgrades
     */
    function test() external pure returns (string memory) {
        return "test";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IPermissionsRegistry.sol";
import "../utils/ERC165/ERC165.sol";
import "../utils/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Highlight permissions registry
 * @author [email protected], [email protected]
 * @dev Allows for O(1) swapping of the platform executor.
 */
contract PermissionsRegistry is IPermissionsRegistry, Ownable, ERC165 {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Whitelisted currencies for system
     */
    EnumerableSetUpgradeable.AddressSet internal _whitelistedCurrencies;

    /**
     * @dev Platform transaction executors
     */
    EnumerableSetUpgradeable.AddressSet internal _platformExecutors;

    /**
     * @notice Initialize the registry with an initial platform executor and the platform vault
     */
    constructor(address _initialExecutor, address _initialOwner) {
        _platformExecutors.add(_initialExecutor);
        _transferOwnership(_initialOwner);
    }

    /**
     * @dev Add platform executor. Expected to be protected by a smart contract wallet.
     */
    function addPlatformExecutor(address _executor) external onlyOwner {
        require(_executor != address(0), "Cannot set to null address");
        require(_platformExecutors.add(_executor), "Already added");
        emit PlatformExecutorAdded(_executor);
    }

    /**
     * @dev Deprecate the platform executor.
     */
    function deprecatePlatformExecutor(address _executor) external onlyOwner {
        require(_platformExecutors.remove(_executor), "Not deprecated");
        emit PlatformExecutorDeprecated(_executor);
    }

    /**
     * @dev Whitelists a currency
     */
    function whitelistCurrency(address _currency) external onlyOwner {
        require(_whitelistedCurrencies.add(_currency), "Already whitelisted");
        emit CurrencyWhitelisted(_currency);
    }

    /**
     * @dev Unwhitelists a currency
     */
    function unwhitelistCurrency(address _currency) external onlyOwner {
        require(_whitelistedCurrencies.remove(_currency), "Not whitelisted");
        emit CurrencyUnwhitelisted(_currency);
    }

    /**
     * @dev Returns true if executor is a platform executor
     */
    function isPlatformExecutor(address _executor) external view returns (bool) {
        return _platformExecutors.contains(_executor);
    }

    /**
     * @dev Returns platform executors
     */
    function platformExecutors() external view returns (address[] memory) {
        return _platformExecutors.values();
    }

    /**
     * @dev Returns true if a currency is whitelisted
     */
    function isCurrencyWhitelisted(address _currency) external view returns (bool) {
        return _whitelistedCurrencies.contains(_currency);
    }

    /**
     * @dev Returns whitelisted currencies
     */
    function whitelistedCurrencies() external view returns (address[] memory) {
        return _whitelistedCurrencies.values();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IPermissionsRegistry).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title Highlight permissions registry interface
 * @author [email protected], [email protected]
 */
interface IPermissionsRegistry {
    /**
     * @notice Emitted when a platform executor is added
     */
    event PlatformExecutorAdded(address indexed newExecutor);

    /**
     * @notice Emitted when a platform executor is deprecated
     */
    event PlatformExecutorDeprecated(address indexed oldExecutor);

    /**
     * @notice Emitted when a currrency is whitelisted system wide
     */
    event CurrencyWhitelisted(address indexed currency);

    /**
     * @notice Emitted when a currrency is unwhitelisted system wide
     */
    event CurrencyUnwhitelisted(address indexed currency);

    /**
     * @dev Swap the platform executor. Expected to be protected by a smart contract wallet.
     */
    function addPlatformExecutor(address _executor) external;

    /**
     * @dev Deprecate the platform executor.
     */
    function deprecatePlatformExecutor(address _executor) external;

    /**
     * @dev Whitelists a currency
     */
    function whitelistCurrency(address _currency) external;

    /**
     * @dev Unwhitelists a currency
     */
    function unwhitelistCurrency(address _currency) external;

    /**
     * @dev Returns true if executor is the platform executor
     */
    function isPlatformExecutor(address executor) external view returns (bool);

    /**
     * @dev Returns the platform executor
     */
    function platformExecutors() external view returns (address[] memory);

    /**
     * @dev Returns true if a currency is whitelisted
     */
    function isCurrencyWhitelisted(address _currency) external view returns (bool);

    /**
     * @dev Returns whitelisted currencies
     */
    function whitelistedCurrencies() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.10;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.10;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportTokenManager.sol";
import "./interfaces/IPostTransfer.sol";
import "./interfaces/IPostBurn.sol";

/**
 * @author [email protected]
 * @dev A basic token manager / sample implementation that locks burns / transfers
 */
contract TransferAndBurnLockedTokenManager is ITokenManager, IPostTransfer, IPostBurn, InterfaceSupportTokenManager {
    /**
     * @dev See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address sender,
        uint256, /* id */
        bytes calldata /* newTokenUri */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canSwap}
     */
    function canSwap(
        address sender,
        uint256, /* id */
        address /* newTokenManager */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address sender,
        uint256 /* id */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IPostTransfer-postSafeTransferFrom}
     */
    function postSafeTransferFrom(
        address, /* operator */
        address, /* from */
        address, /* to */
        uint256, /* id */
        bytes memory /* data */
    ) external pure override {
        revert("Transfers disallowed");
    }

    /**
     * @dev See {IPostTransfer-postTransferFrom}
     */
    function postTransferFrom(
        address, /* operator */
        address, /* from */
        address, /* to */
        uint256 /* id */
    ) external pure override {
        revert("Transfers disallowed");
    }

    /**
     * @dev See {IPostBurn-postBurn}
     */
    function postBurn(
        address, /* operator */
        address, /* sender */
        uint256 /* id */
    ) external pure override {
        revert("Burns disallowed");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(InterfaceSupportTokenManager)
        returns (bool)
    {
        return
            interfaceId == type(IPostTransfer).interfaceId ||
            interfaceId == type(IPostBurn).interfaceId ||
            InterfaceSupportTokenManager.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/ITokenManager.sol";
import "../utils/ERC165/IERC165.sol";

/**
 * @author [email protected]
 * @dev Abstract contract to be inherited by all valid token managers
 */
abstract contract InterfaceSupportTokenManager {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(ITokenManager).interfaceId || _supportsERC165Interface(interfaceId);
    }

    /**
     * @dev Used to show support for IERC165, without inheriting contract from IERC165 implementations
     */
    function _supportsERC165Interface(bytes4 interfaceId) internal pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportTokenManager.sol";
import "./interfaces/IPostTransfer.sol";

/**
 * @author [email protected]
 * @dev A basic token manager that prevents transfers
 */
contract NonTransferableTokenManager is ITokenManager, IPostTransfer, InterfaceSupportTokenManager {
    /**
     * @dev See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address sender,
        uint256, /* id */
        bytes calldata /* newTokenUri */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canSwap}
     */
    function canSwap(
        address sender,
        uint256, /* id */
        address /* newTokenManager */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address sender,
        uint256 /* id */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IPostTransfer-postSafeTransferFrom}
     */
    function postSafeTransferFrom(
        address, /* operator */
        address, /* from */
        address, /* to */
        uint256, /* id */
        bytes memory /* data */
    ) external pure override {
        revert("Transfers disallowed");
    }

    /**
     * @dev See {IPostTransfer-postTransferFrom}
     */
    function postTransferFrom(
        address, /* operator */
        address, /* from */
        address, /* to */
        uint256 /* id */
    ) external pure override {
        revert("Transfers disallowed");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(InterfaceSupportTokenManager)
        returns (bool)
    {
        return
            interfaceId == type(IPostTransfer).interfaceId ||
            InterfaceSupportTokenManager.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportTokenManager.sol";

/**
 * @author [email protected]
 * @dev A basic token manager / sample implementation that locks swaps / removals / metadata updates
 */
contract TotalLockedTokenManager is ITokenManager, InterfaceSupportTokenManager {
    /**
     * @dev See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address, /* sender */
        uint256, /* id */
        bytes calldata /* newTokenUri */
    ) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {ITokenManager-canSwap}
     */
    function canSwap(
        address, /* sender */
        uint256, /* id */
        address /* newTokenManager */
    ) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address, /* sender */
        uint256 /* id */
    ) external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportTokenManager.sol";

/**
 * @author [email protected]
 * @dev A basic token manager / sample implementation that only lets owner perform operations
 */
contract OwnerOnlyTokenManager is ITokenManager, InterfaceSupportTokenManager {
    /**
     * @dev See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address sender,
        uint256, /* id */
        bytes calldata /* newTokenUri */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canSwap}
     */
    function canSwap(
        address sender,
        uint256, /* id */
        address /* newTokenManager */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address sender,
        uint256 /* id */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportTokenManager.sol";

/**
 * @author [email protected]
 * @dev A basic token manager / sample implementation that locks swaps / removals
 */
contract LockedTokenManager is ITokenManager, InterfaceSupportTokenManager {
    /**
     * @dev See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address sender,
        uint256, /* id */
        bytes calldata /* newTokenUri */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canSwap}
     */
    function canSwap(
        address, /* sender */
        uint256, /* id */
        address /* newTokenManager */
    ) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address, /* sender */
        uint256 /* id */
    ) external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.10;

import "../ERC165/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
/* solhint-disable */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.10;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.10;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../ERC165/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
/* solhint-disable */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.8.10;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
/* solhint-disable */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.10;

import "./ERC721.sol";

/**
 * @title Appending URI storage utilities onto template ERC721 contract
 * @author [email protected] and OpenZeppelin
 * @dev ERC721 token with storage based token URI management. OpenZeppelin template edited by Highlight
 */
/* solhint-disable */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    /**
     * @dev Optional token-grouping mapping for uris. Edition IDs / Token IDs depending on implementing contract
     */
    mapping(uint256 => string) internal _tokenURIs;

    /**
     * @dev Hashed rotation key data
     */
    bytes internal _hashedRotationKeyData;

    /**
     * @dev Hashed base uri data
     */
    bytes internal _hashedBaseURIData;

    /**
     * @dev Rotation key
     */
    uint256 internal _rotationKey;

    // TODO: change to support multiple baseURIs per contract, and multiple nextTokenIds / supplies
    /**
     * @dev Contract baseURI
     */
    string public baseURI;

    /**
     * @dev Set contract baseURI
     */
    function _setBaseURI(string calldata newBaseURI) internal {
        string memory currentBaseURI = _baseURI();
        require(bytes(currentBaseURI).length == 0, "Already set");
        require(bytes(newBaseURI).length > 0, "Empty string");

        baseURI = newBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no token URI, return the base URI.
        if (bytes(_tokenURI).length == 0) {
            return super.tokenURI(tokenId);
        }

        return _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    // just remove the original function in ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EthereumWETH is ERC20, Ownable {
    constructor() ERC20("EthereumWETH", "EWETH") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * WETH on Polygon slightly modified by ishan at highlight.xyz for testing purposes and to compile w/ solidity 0.8.10
 */

/* solhint-disable */
contract AccessControlMixin is AccessControl {
    string private _revertMsg;

    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
    }

    modifier only(bytes32 role) {
        require(hasRole(role, _msgSender()), _revertMsg);
        _;
    }
}

interface IChildToken {
    function deposit(address user, bytes calldata depositData) external;
}

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name, string memory version) internal initializer {
        _setDomainSeperator(name, version);
    }

    function _setDomainSeperator(string memory name, string memory version) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }
}

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));
    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature))
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return signer == ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
    }
}

contract ChainConstants {
    string public constant ERC712_VERSION = "1";

    uint256 public constant ROOT_CHAIN_ID = 1;
    bytes public constant ROOT_CHAIN_ID_BYTES = hex"01";

    uint256 public constant CHILD_CHAIN_ID = 137;
    bytes public constant CHILD_CHAIN_ID_BYTES = hex"89";
}

abstract contract ContextMixin {
    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

contract ChildERC20 is ERC20, IChildToken, AccessControlMixin, NativeMetaTransaction, ChainConstants, ContextMixin {
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        address childChainManager
    ) public ERC20(name_, symbol_) {
        _setupContractId("ChildERC20");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, childChainManager);
        _initializeEIP712(name_, ERC712_VERSION);
        _mint(_msgSender(), 100000000000000000000); // initially mint 100 wETH to deployer
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external override only(DEPOSITOR_ROLE) {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}

contract MaticWETH is ChildERC20 {
    constructor(address childChainManager) public ChildERC20("Wrapped Ether", "WETH", childChainManager) {}
}

/* solhint-enable */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

/**
 * @title Appending ERC1967Proxy to use UUPS
 * @author [email protected] and OpenZeppelin
 * @dev Implements an upgradeable proxy. OpenZeppelin template edited by Highlight
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCallUUPS(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        /* solhint-disable reason-string */
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        /* solhint-enable reason-string */
        _nonces[req.from] = req.nonce + 1;

        /* solhint-disable avoid-low-level-calls */
        (bool success, bytes memory returndata) = req.to.call{ gas: req.gas, value: req.value }(
            abi.encodePacked(req.data, req.from)
        );
        /* solhint-enable avoid-low-level-calls */

        require(success, string(returndata));

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /* solhint-disable no-inline-assembly */
            assembly {
                invalid()
            }
            /* solhint-enable no-inline-assembly */
        }

        return (success, returndata);
    }

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity 0.8.10;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
/* solhint-disable */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/IRoyaltyManager.sol";
import "../utils/ERC165/IERC165.sol";

/**
 * @author [email protected]
 * @dev Abstract contract to be inherited by all valid royalty managers
 */
abstract contract InterfaceSupportRoyaltyManager {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IRoyaltyManager).interfaceId || _supportsERC165Interface(interfaceId);
    }

    /**
     * @dev Used to show support for IERC165, without inheriting contract from IERC165 implementations
     * @param interfaceId Interface ID
     */
    function _supportsERC165Interface(bytes4 interfaceId) internal pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportRoyaltyManager.sol";

/**
 * @author [email protected]
 * @dev A basic royalty manager / sample implementation that only lets owner perform operations
 */
contract OwnerOnlyRoyaltyManager is IRoyaltyManager, InterfaceSupportRoyaltyManager {
    /**
     * @dev See {IRoyaltyManager-canSetGranularRoyalty}
     */
    function canSetGranularRoyalty(
        uint256, /* id */
        Royalty calldata, /* royalty */
        address sender
    ) external view override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IRoyaltyManager-canSetDefaultRoyalty}
     */
    function canSetDefaultRoyalty(
        Royalty calldata, /* royalty */
        address sender
    ) external view override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IRoyaltyManager-canSwap}
     */
    function canSwap(
        address, /* newRoyaltyManager */
        address sender
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IRoyaltyManager-canRemoveItself}
     */
    function canRemoveItself(address sender) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "./InterfaceSupportRoyaltyManager.sol";

/**
 * @author [email protected]
 * @dev A basic royalty manager / sample implementation that locks swaps / removals / setting of royalties
 */
contract LockedRoyaltyManager is IRoyaltyManager, InterfaceSupportRoyaltyManager {
    /**
     * @dev See {IRoyaltyManager-canSetGranularRoyalty}
     */
    function canSetGranularRoyalty(
        uint256, /* id */
        Royalty calldata, /* royalty */
        address /* sender */
    ) external pure override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return false;
    }

    /**
     * @dev See {IRoyaltyManager-canSetDefaultRoyalty}
     */
    function canSetDefaultRoyalty(
        Royalty calldata, /* royalty */
        address /* sender */
    ) external pure override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return false;
    }

    /**
     * @dev See {IRoyaltyManager-canSwap}
     */
    function canSwap(
        address, /* newRoyaltyManager */
        address /* sender */
    ) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {IRoyaltyManager-canRemoveItself}
     */
    function canRemoveItself(
        address /* sender */
    ) external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../interfaces/IRoyaltyManager.sol";
import "../../utils/Ownable.sol";

/**
 * @author [email protected]
 * @dev A basic royalty manager / sample implementation that locks swaps / removals, 
        but doesn't implement supportsInterface
 */
contract InvalidRoyaltyManager is IRoyaltyManager {
    /**
     * @dev See {IRoyaltyManager-canSetGranularRoyalty}
     */
    function canSetGranularRoyalty(
        uint256, /* id */
        Royalty calldata, /* royalty */
        address sender
    ) external view override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IRoyaltyManager-canSetDefaultRoyalty}
     */
    function canSetDefaultRoyalty(
        Royalty calldata, /* royalty */
        address sender
    ) external view override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IRoyaltyManager-canSwap}
     */
    function canSwap(
        address, /* newRoyaltyManager */
        address /* sender */
    ) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {IRoyaltyManager-canRemoveItself}
     */
    function canRemoveItself(
        address /* sender */
    ) external pure override returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../interfaces/ITokenManager.sol";
import "../../utils/Ownable.sol";

/**
 * @author [email protected]
 * @dev A basic token manager / sample implementation that locks swaps / removals, 
        but doesn't implement supportsInterface
 */
contract InvalidTokenManager is ITokenManager {
    /**
     * @dev See {ITokenManager-canUpdateMetadata}
     */
    function canUpdateMetadata(
        address sender,
        uint256, /* id */
        bytes calldata /* newTokenUri */
    ) external view override returns (bool) {
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {ITokenManager-canSwap}
     */
    function canSwap(
        address, /* sender */
        uint256, /* id */
        address /* newTokenManager */
    ) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {ITokenManager-canRemoveItself}
     */
    function canRemoveItself(
        address, /* sender */
        uint256 /* id */
    ) external pure override returns (bool) {
        return false;
    }
}