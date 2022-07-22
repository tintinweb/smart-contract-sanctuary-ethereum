// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC165Controller } from "../../core/introspection/ERC165Controller.sol";
import { OwnableController } from "../../core/access/ownable/OwnableController.sol";
import { ERC721MintableController } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { ERC721TokenURIController } from "../../core/token/ERC721/tokenURI/ERC721TokenURIController.sol";
import { ERC721EnumerableController } from "../../core/token/ERC721/enumerable/ERC721EnumerableController.sol";
import { ERC721MintableController } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { PageInfo } from "../../core/token/ERC721/enumerable/ERC721EnumerableModel.sol";
import { ProxyFacetedController } from "../../core/proxy/faceted/ProxyFacetedController.sol";
import { IntegerUtils } from "../../core/utils/IntegerUtils.sol";

/**
 * @title Mutytes initialization facet
 */
contract MutytesInitFacet is
    ERC165Controller,
    OwnableController,
    ERC721MintableController,
    ERC721TokenURIController,
    ERC721EnumerableController,
    ProxyFacetedController
{
    using IntegerUtils for uint256;

    /**
     * @notice Set upgradable functions and supported interfaces
     * @param selectors The upgradable function selectors
     * @param isUpgradable Whether the functions should be upgradable
     * @param interfaceIds The interface ids
     * @param isSupported Whether the interfaces should be supported
     */
    function setFunctionsAndInterfaces(
        bytes4[] calldata selectors,
        bool isUpgradable,
        bytes4[] calldata interfaceIds,
        bool isSupported
    ) external virtual onlyOwner {
        setUpgradableFunctions_(selectors, isUpgradable);
        _setSupportedInterfaces(interfaceIds, isSupported);
    }

    /**
     * @notice Set upgradable functions
     * @param selectors The upgradable function selectors
     * @param isUpgradable Whether the functions should be upgradable
     */
    function setUpgradableFunctions(bytes4[] calldata selectors, bool isUpgradable)
        external
        virtual
        onlyOwner
    {
        setUpgradableFunctions_(selectors, isUpgradable);
    }

    /**
     * @notice Set supported interfaces
     * @param interfaceIds The interface ids
     * @param isSupported Whether the interfaces should be supported
     */
    function setSupportedInterfaces(bytes4[] calldata interfaceIds, bool isSupported)
        external
        virtual
        onlyOwner
    {
        _setSupportedInterfaces(interfaceIds, isSupported);
    }

    /**
     * @notice Initialize the default token URI provider
     * @param id The URI provider id
     * @param provider The URI provider address
     * @param isProxyable Whether to proxy the URI provider
     */
    function initTokenURI(
        uint256 id,
        address provider,
        bool isProxyable
    ) external virtual onlyOwner {
        ERC721TokenURI_(id, provider, isProxyable);
    }

    /**
     * @notice Initialize the token supply and mint reserved tokens
     * @param supply The initial supply amount
     * @param reserved The reserved supply amount
     */
    function initSupply(uint256 supply, uint256 reserved) external virtual onlyOwner {
        reserved.enforceNotGreaterThan(supply);
        ERC721Supply_(supply);

        if (reserved > 0) {
            (uint256 tokenId, uint256 maxTokenId) = _mint_(msg.sender, reserved);

            unchecked {
                while (tokenId < maxTokenId) {
                    emit Transfer(address(0), msg.sender, tokenId++);
                }
            }
        }
    }

    /**
     * @notice Initialize enumerable extension
     * @param pages The enumerable token pages
     */
    function initEnumerable(PageInfo[] calldata pages) external virtual onlyOwner {
        _ERC721Enumerable(pages);
    }

    /**
     * @notice Burn any remaining supply
     */
    function burnRemainingSupply() external virtual onlyOwner {
        uint256 availableSupply = _availableSupply();
        availableSupply.enforceIsNotZero();
        _setAvailableSupply(0);
        _updateMaxSupply(availableSupply);
        _updateInitialSupply(availableSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC165Model } from "./ERC165Model.sol";

abstract contract ERC165Controller is ERC165Model {
    function supportsInterface_(bytes4 interfaceId) internal view virtual returns (bool) {
        return _supportsInterface(interfaceId);
    }

    function _setSupportedInterfaces(bytes4[] memory interfaceIds, bool isSupported)
        internal
        virtual
    {
        unchecked {
            for (uint256 i; i < interfaceIds.length; i++) {
                _setSupportedInterface(interfaceIds[i], isSupported);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Controller } from "../IERC173Controller.sol";
import { OwnableModel } from "./OwnableModel.sol";
import { AddressUtils } from "../../utils/AddressUtils.sol";

abstract contract OwnableController is IERC173Controller, OwnableModel {
    using AddressUtils for address;

    modifier onlyOwner() {
        _enforceOnlyOwner();
        _;
    }

    function Ownable_() internal virtual {
        Ownable_(msg.sender);
    }

    function Ownable_(address owner) internal virtual {
        transferOwnership_(owner);
    }

    function owner_() internal view virtual returns (address) {
        return _owner();
    }

    function transferOwnership_(address newOwner) internal virtual {
        _transferOwnership(newOwner);
        emit OwnershipTransferred(_owner(), newOwner);
    }

    function _enforceOnlyOwner() internal view virtual {
        msg.sender.enforceEquals(_owner());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721MintableController } from "./IERC721MintableController.sol";
import { ERC721MintableModel } from "./ERC721MintableModel.sol";
import { ERC721SupplyController } from "../supply/ERC721SupplyController.sol";
import { ERC721TokenUtils } from "../utils/ERC721TokenUtils.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";
import { IntegerUtils } from "../../../utils/IntegerUtils.sol";

abstract contract ERC721MintableController is
    IERC721MintableController,
    ERC721MintableModel,
    ERC721SupplyController
{
    using ERC721TokenUtils for address;
    using AddressUtils for address;
    using IntegerUtils for uint256;

    function mintBalanceOf_(address owner) internal view virtual returns (uint256) {
        owner.enforceIsNotZeroAddress();
        return _mintBalanceOf(owner);
    }

    function mint_(uint256 amount) internal virtual {
        _enforceCanMint(amount);
        (uint256 tokenId, uint256 maxTokenId) = _mint_(msg.sender, amount);

        unchecked {
            while (tokenId < maxTokenId) {
                emit Transfer(address(0), msg.sender, tokenId++);
            }
        }
    }

    function _mint_(address to, uint256 amount)
        internal
        virtual
        returns (uint256 tokenId, uint256 maxTokenId)
    {
        tokenId = to.toTokenId() | _mintBalanceOf(to);
        maxTokenId = tokenId + amount;
        _mint(to, amount);
        _updateAvailableSupply(amount);
    }

    function _mintValue() internal view virtual returns (uint256) {
        return 0 ether;
    }

    function _mintedSupply() internal view virtual returns (uint256) {
        return _initialSupply() - _availableSupply();
    }

    function _enforceCanMint(uint256 amount) internal view virtual {
        amount.enforceIsNotZero();
        amount.enforceNotGreaterThan(_availableSupply());
        msg.value.enforceEquals(amount * _mintValue());
        (_mintBalanceOf(msg.sender) + amount).enforceNotGreaterThan(_maxMintBalance());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721TokenURIController } from "./IERC721TokenURIController.sol";
import { ERC721TokenURIModel } from "./ERC721TokenURIModel.sol";
import { ERC721BaseController } from "../base/ERC721BaseController.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";

abstract contract ERC721TokenURIController is
    IERC721TokenURIController,
    ERC721TokenURIModel,
    ERC721BaseController
{
    using AddressUtils for address;

    function ERC721TokenURI_(
        uint256 id,
        address provider,
        bool isProxyable
    ) internal virtual {
        _setTokenURIProviderInfo(id, provider, isProxyable);
        _setDefaultTokenURIProvider(id);
    }

    function tokenURI_(uint256 tokenId) internal view virtual returns (string memory) {
        uint256 providerId = tokenURIProvider_(tokenId);
        (address provider, bool isProxyable) = _tokenURIProviderInfo(providerId);

        if (isProxyable) {
            revert UnexpectedTokenURIProvider(providerId);
        }

        return _tokenURI(tokenId, provider);
    }

    function tokenURIProvider_(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256 providerId)
    {
        _enforceTokenExists(tokenId);
        providerId = _tokenURIProvider_(tokenId);
        (address provider, ) = _tokenURIProviderInfo(providerId);
        provider.enforceIsNotZeroAddress();
    }

    function tokenURIProviderInfo_(uint256 providerId)
        internal
        view
        virtual
        returns (address provider, bool isProxyable)
    {
        (provider, isProxyable) = _tokenURIProviderInfo_(providerId);
        provider.enforceIsNotZeroAddress();
    }

    function _tokenURIProvider_(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256 providerId)
    {
        providerId = _tokenURIProvider(tokenId);
        (address provider, ) = _tokenURIProviderInfo(providerId);

        if (provider == address(0)) {
            providerId = _defaultTokenURIProvider();
        }
    }

    function _tokenURIProviderInfo_(uint256 providerId)
        internal
        view
        virtual
        returns (address provider, bool isProxyable)
    {
        (provider, isProxyable) = _tokenURIProviderInfo(providerId);

        if (provider == address(0)) {
            (provider, isProxyable) = _tokenURIProviderInfo(_defaultTokenURIProvider());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721EnumerableModel } from "./ERC721EnumerableModel.sol";
import { ERC721SupplyController } from "../supply/ERC721SupplyController.sol";
import { ERC721BaseController } from "../base/ERC721BaseController.sol";
import { IntegerUtils } from "../../../utils/IntegerUtils.sol";

abstract contract ERC721EnumerableController is
    ERC721EnumerableModel,
    ERC721SupplyController,
    ERC721BaseController
{
    using IntegerUtils for uint256;

    function totalSupply_() internal view virtual returns (uint256) {
        return _maxSupply() - _availableSupply();
    }

    function tokenByIndex_(uint256 index) internal view virtual returns (uint256) {
        index.enforceLessThan(totalSupply_());
        return _tokenByIndex_(index);
    }

    function tokenOfOwnerByIndex_(address owner, uint256 index)
        internal
        view
        virtual
        returns (uint256)
    {
        index.enforceLessThan(_balanceOf(owner));
        return _tokenOfOwnerByIndex_(owner, index);
    }

    function _tokenOfOwnerByIndex_(address owner, uint256 index)
        internal
        view
        virtual
        returns (uint256 tokenId)
    {
        unchecked {
            index++;
            for (uint256 i; index > 0; i++) {
                if (_ownerOf(tokenId = _tokenByIndex(i)) == owner) {
                    index--;
                }
            }
        }
    }

    function _tokenByIndex_(uint256 index) internal view returns (uint256 tokenId) {
        unchecked {
            index++;
            for (uint256 i; index > 0; i++) {
                if (_tokenExists(tokenId = _tokenByIndex(i))) {
                    index--;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721EnumerablePage } from "./IERC721EnumerablePage.sol";
import { erc721EnumerableStorage, ERC721EnumerableStorage, PageInfo } from "./ERC721EnumerableStorage.sol";

abstract contract ERC721EnumerableModel {
    function _ERC721Enumerable(PageInfo[] memory pages) internal virtual {
        erc721EnumerableStorage().pages = pages;
    }

    function _tokenByIndex(uint256 index)
        internal
        view
        virtual
        returns (uint256 tokenId)
    {
        ERC721EnumerableStorage storage es = erc721EnumerableStorage();

        unchecked {
            for (uint256 i; i < es.pages.length; i++) {
                PageInfo memory page = es.pages[i];

                if (index < page.length) {
                    return IERC721EnumerablePage(page.pageAddress).tokenByIndex(index);
                }
                
                index -= page.length;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ProxyFacetedModel } from "./ProxyFacetedModel.sol";
import { ProxyController } from "../ProxyController.sol";
import { AddressUtils } from "../../utils/AddressUtils.sol";

abstract contract ProxyFacetedController is ProxyFacetedModel, ProxyController {
    using AddressUtils for address;

    function implementation_() internal view virtual override returns (address) {
        return implementation_(msg.sig);
    }

    function implementation_(bytes4 selector)
        internal
        view
        virtual
        returns (address implementation)
    {
        implementation = _implementation(selector);
        implementation.enforceIsNotZeroAddress();
    }

    function addFunctions_(
        bytes4[] memory selectors,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _enforceCanAddFunctions(implementation);

        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                bytes4 selector = selectors[i];
                _enforceCanAddFunction(selector, implementation);
                _addFunction_(selector, implementation, isUpgradable);
            }
        }
    }

    function addFunction_(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _enforceCanAddFunctions(implementation);
        _enforceCanAddFunction(selector, implementation);
        _addFunction_(selector, implementation, isUpgradable);
    }

    function replaceFunctions_(bytes4[] memory selectors, address implementation)
        internal
        virtual
    {
        _enforceCanAddFunctions(implementation);

        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                bytes4 selector = selectors[i];
                _enforceCanReplaceFunction(selector, implementation);
                _replaceFunction_(selector, implementation);
            }
        }
    }

    function replaceFunction_(bytes4 selector, address implementation) internal virtual {
        _enforceCanAddFunctions(implementation);
        _enforceCanReplaceFunction(selector, implementation);
        _replaceFunction_(selector, implementation);
    }

    function removeFunctions_(bytes4[] memory selectors) internal virtual {
        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                removeFunction_(selectors[i]);
            }
        }
    }

    function removeFunction_(bytes4 selector) internal virtual {
        address implementation = _implementation(selector);
        _enforceCanRemoveFunction(selector, implementation);
        _removeFunction_(selector, implementation);
    }

    function setUpgradableFunctions_(bytes4[] memory selectors, bool isUpgradable)
        internal
        virtual
    {
        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                setUpgradableFunction_(selectors[i], isUpgradable);
            }
        }
    }

    function setUpgradableFunction_(bytes4 selector, bool isUpgradable) internal virtual {
        _implementation(selector).enforceIsNotZeroAddress();
        _setUpgradableFunction(selector, isUpgradable);
    }

    function _addFunction_(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _addFunction(selector, implementation, isUpgradable);
        _afterAddFunction(implementation);
    }

    function _replaceFunction_(bytes4 selector, address implementation) internal virtual {
        address oldImplementation = _implementation(selector);
        _replaceFunction(selector, implementation);
        _afterRemoveFunction(oldImplementation);
        _afterAddFunction(implementation);
    }

    function _removeFunction_(bytes4 selector, address implementation) internal virtual {
        _removeFunction(selector);
        _afterRemoveFunction(implementation);
    }

    function _enforceCanAddFunctions(address implementation) internal view virtual {
        if (implementation != address(this)) {
            implementation.enforceIsContract();
        }
    }

    function _enforceCanAddFunction(bytes4 selector, address) internal view virtual {
        _implementation(selector).enforceIsZeroAddress();
    }

    function _enforceCanReplaceFunction(bytes4 selector, address implementation)
        internal
        view
        virtual
    {
        address oldImplementation = _implementation(selector);
        oldImplementation.enforceNotEquals(implementation);
        _enforceCanRemoveFunction(selector, oldImplementation);
    }

    function _enforceCanRemoveFunction(bytes4 selector, address implementation)
        internal
        view
        virtual
    {
        implementation.enforceIsNotZeroAddress();

        if (!_isUpgradable(selector)) {
            implementation.enforceNotEquals(address(this));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Integer utilities
 */
library IntegerUtils {
    error UnexpectedZeroValue();
    error UnexpectedNonZeroValue();
    error OutOfBoundsValue(uint256 value, uint256 length);
    error UnexpectedValue();

    function enforceIsZero(uint256 i) internal pure {
        if (i == 0) {
            return;
        }

        revert UnexpectedNonZeroValue();
    }

    function enforceIsNotZero(uint256 i) internal pure {
        if (i == 0) {
            revert UnexpectedZeroValue();
        }
    }

    function enforceLessThan(uint256 a, uint256 b) internal pure {
        if (a < b) {
            return;
        }

        revert OutOfBoundsValue(a, b);
    }

    function enforceNotLessThan(uint256 a, uint256 b) internal pure {
        if (a < b) {
            revert OutOfBoundsValue(b, a);
        }
    }

    function enforceGreaterThan(uint256 a, uint256 b) internal pure {
        if (a > b) {
            return;
        }

        revert OutOfBoundsValue(b, a);
    }

    function enforceNotGreaterThan(uint256 a, uint256 b) internal pure {
        if (a > b) {
            revert OutOfBoundsValue(a, b);
        }
    }
    
    function enforceEquals(uint256 a, uint256 b) internal pure {
        if (a == b) {
            return;
        }

        revert UnexpectedValue();
    }

    function enforceNotEquals(uint256 a, uint256 b) internal pure {
        if (a == b) {
            revert UnexpectedValue();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc165Storage as es } from "./ERC165Storage.sol";

abstract contract ERC165Model {
    function _supportsInterface(bytes4 interfaceId) internal view virtual returns (bool) {
        return es().supportedInterfaces[interfaceId];
    }

    function _setSupportedInterface(bytes4 interfaceId, bool isSupported)
        internal
        virtual
    {
        es().supportedInterfaces[interfaceId] = isSupported;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC165_STORAGE_SLOT = keccak256("core.introspection.erc165.storage");

struct ERC165Storage {
    mapping(bytes4 => bool) supportedInterfaces;
}

function erc165Storage() pure returns (ERC165Storage storage es) {
    bytes32 slot = ERC165_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface required by controller functions
 */
interface IERC173Controller {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ownableStorage as os } from "./OwnableStorage.sol";

abstract contract OwnableModel {
    function _owner() internal view virtual returns (address) {
        return os().owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        os().owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Address utilities
 */
library AddressUtils {
    error UnexpectedContractAddress();
    error UnexpectedNonContractAddress();
    error UnexpectedZeroAddress();
    error UnexpectedNonZeroAddress();
    error UnexpectedAddress();

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function enforceIsContract(address account) internal view {
        if (isContract(account)) {
            return;
        }

        revert UnexpectedNonContractAddress();
    }

    function enforceIsNotContract(address account) internal view {
        if (isContract(account)) {
            revert UnexpectedContractAddress();
        }
    }

    function enforceIsZeroAddress(address account) internal pure {
        if (account == address(0)) {
            return;
        }

        revert UnexpectedNonZeroAddress();
    }

    function enforceIsNotZeroAddress(address account) internal pure {
        if (account == address(0)) {
            revert UnexpectedZeroAddress();
        }
    }

    function enforceEquals(address a, address b) internal pure {
        if (a == b) {
            return;
        }

        revert UnexpectedAddress();
    }

    function enforceNotEquals(address a, address b) internal pure {
        if (a == b) {
            revert UnexpectedAddress();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant OWNABLE_STORAGE_SLOT = keccak256("core.access.ownable.storage");

struct OwnableStorage {
    address owner;
}

function ownableStorage() pure returns (OwnableStorage storage os) {
    bytes32 slot = OWNABLE_STORAGE_SLOT;
    assembly {
        os.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721TransferableController } from "../transferable/IERC721TransferableController.sol";

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721MintableController is IERC721TransferableController {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721BaseStorage, ERC721BaseStorage } from "../base/ERC721BaseStorage.sol";
import { ERC721InventoryUtils } from "../utils/ERC721InventoryUtils.sol";

abstract contract ERC721MintableModel {
    using ERC721InventoryUtils for uint256;

    function _maxMintBalance() internal view virtual returns (uint256) {
        return ERC721InventoryUtils.SLOTS_PER_INVENTORY;
    }

    function _mintBalanceOf(address owner) internal view virtual returns (uint256) {
        return erc721BaseStorage().inventories[owner].current();
    }

    function _mint(address to, uint256 amount) internal virtual {
        ERC721BaseStorage storage es = erc721BaseStorage();
        es.inventories[to] = es.inventories[to].add(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721SupplyModel } from "./ERC721SupplyModel.sol";

abstract contract ERC721SupplyController is ERC721SupplyModel {
    function ERC721Supply_(uint256 supply) internal virtual {
        _setInitialSupply(supply);
        _setMaxSupply(supply);
        _setAvailableSupply(supply);
    }

    function _updateSupply(uint256 supply) internal virtual {
        _setInitialSupply(_initialSupply() + supply);
        _setMaxSupply(_maxSupply() + supply);
        _setAvailableSupply(_availableSupply() + supply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token utilities
 */
library ERC721TokenUtils {
    uint256 constant HOLDER_OFFSET = 8;
    uint256 constant INDEX_BITMASK = (1 << HOLDER_OFFSET) - 1; // = 0xFF

    function toTokenId(address owner) internal pure returns (uint256) {
        return uint256(uint160(owner)) << HOLDER_OFFSET;
    }

    function index(uint256 tokenId) internal pure returns (uint256) {
        return tokenId & INDEX_BITMASK;
    }

    function holder(uint256 tokenId) internal pure returns (address) {
        return address(uint160(tokenId >> HOLDER_OFFSET));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721TransferableController {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_BASE_STORAGE_SLOT = keccak256("core.token.erc721.base.storage");

struct ERC721BaseStorage {
    mapping(uint256 => address) owners;
    mapping(address => uint256) inventories;
}

function erc721BaseStorage() pure returns (ERC721BaseStorage storage es) {
    bytes32 slot = ERC721_BASE_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BitmapUtils } from "../../../utils/BitmapUtils.sol";

/**
 * @title ERC721 token inventory utilities
 */
library ERC721InventoryUtils {
    using BitmapUtils for uint256;

    uint256 constant BALANCE_BITSIZE = 16;
    uint256 constant BALANCE_BITMASK = (1 << BALANCE_BITSIZE) - 1;              // = 0xFFFF;
    uint256 constant CURRENT_SLOT_BITSIZE = 8;
    uint256 constant CURRENT_SLOT_BITMASK = (1 << CURRENT_SLOT_BITSIZE) - 1;    // = 0xFF;
    uint256 constant BITMAP_OFFSET = BALANCE_BITSIZE + CURRENT_SLOT_BITSIZE;    // = 24
    uint256 constant SLOTS_PER_INVENTORY = 256 - BITMAP_OFFSET;                 // = 232

    function balance(uint256 inventory) internal pure returns (uint256) {
        return inventory & BALANCE_BITMASK;
    }

    function current(uint256 inventory) internal pure returns (uint256) {
        return (inventory >> BALANCE_BITSIZE) & CURRENT_SLOT_BITMASK;
    }

    function has(uint256 inventory, uint256 index) internal pure returns (bool) {
        return inventory.isSet(BITMAP_OFFSET + index);
    }

    function add(uint256 inventory, uint256 amount) internal pure returns (uint256) {
        return
            inventory.setRange(BITMAP_OFFSET + current(inventory), amount) +
            (amount << BALANCE_BITSIZE) +
            amount;
    }

    function remove(uint256 inventory, uint256 index) internal pure returns (uint256) {
        return inventory.unset(BITMAP_OFFSET + index) - 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Bitmap utilities
 */
library BitmapUtils {
    function get(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return (bitmap >> index) & 1;
    }

    function isSet(uint256 bitmap, uint256 index) internal pure returns (bool) {
        return get(bitmap, index) == 1;
    }

    function set(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return bitmap | (1 << index);
    }

    function setRange(uint256 bitmap, uint256 offset, uint256 amount) internal pure returns (uint256) {
        return bitmap | (((1 << amount) - 1) << offset);
    }

    function unset(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return bitmap & toggle(type(uint256).max, index);
    }
    
    function unsetRange(uint256 bitmap, uint256 offset, uint256 amount) internal pure returns (uint256) {
        return bitmap & toggleRange(type(uint256).max, offset, amount);
    }

    function toggle(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return bitmap ^ (1 << index);
    }

    function toggleRange(uint256 bitmap, uint256 offset, uint256 amount) internal pure returns (uint256) {
        return bitmap ^ (((1 << amount) - 1) << offset);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721SupplyStorage as es } from "./ERC721SupplyStorage.sol";

abstract contract ERC721SupplyModel {
    function _initialSupply() internal view virtual returns (uint256) {
        return es().initialSupply;
    }

    function _maxSupply() internal view virtual returns (uint256) {
        return es().maxSupply;
    }

    function _availableSupply() internal view virtual returns (uint256) {
        return es().availableSupply;
    }

    function _setInitialSupply(uint256 supply) internal virtual {
        es().initialSupply = supply;
    }

    function _setMaxSupply(uint256 supply) internal virtual {
        es().maxSupply = supply;
    }

    function _setAvailableSupply(uint256 supply) internal virtual {
        es().availableSupply = supply;
    }

    function _updateInitialSupply(uint256 amount) internal virtual {
        es().initialSupply -= amount;
    }

    function _updateMaxSupply(uint256 amount) internal virtual {
        es().maxSupply -= amount;
    }

    function _updateAvailableSupply(uint256 amount) internal virtual {
        es().availableSupply -= amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_SUPPLY_STORAGE_SLOT = keccak256(
    "core.token.erc721.supply.storage"
);

struct ERC721SupplyStorage {
    uint256 initialSupply;
    uint256 maxSupply;
    uint256 availableSupply;
}

function erc721SupplyStorage() pure returns (ERC721SupplyStorage storage es) {
    bytes32 slot = ERC721_SUPPLY_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721TokenURIController {
    error UnexpectedTokenURIProvider(uint256 providerId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721TokenURIProvider } from "./IERC721TokenURIProvider.sol";
import { erc721TokenURIStorage as es, ProviderInfo } from "./ERC721TokenURIStorage.sol";

abstract contract ERC721TokenURIModel {
    function _ERC721TokenURI(
        uint256 id,
        address provider,
        bool isProxyable
    ) internal virtual {
        _setTokenURIProviderInfo(id, provider, isProxyable);
        _setDefaultTokenURIProvider(id);
    }

    function _tokenURI(uint256 tokenId, address provider)
        internal
        view
        virtual
        returns (string memory)
    {
        return IERC721TokenURIProvider(provider).tokenURI(tokenId);
    }

    function _setTokenURIProvider(uint256 tokenId, uint256 providerId) internal virtual {
        es().tokenURIProviders[tokenId] = providerId;
    }

    function _setTokenURIProviderInfo(
        uint256 providerId,
        address providerAddress,
        bool isProxyable
    ) internal virtual {
        es().providerInfo[providerId] = ProviderInfo(isProxyable, providerAddress);
    }

    function _setDefaultTokenURIProvider(uint256 providerId) internal virtual {
        es().defaultProvider = providerId;
    }

    function _tokenURIProvider(uint256 tokenId) internal view virtual returns (uint256) {
        return es().tokenURIProviders[tokenId];
    }

    function _tokenURIProviderInfo(uint256 providerId)
        internal
        view
        virtual
        returns (address, bool)
    {
        ProviderInfo memory providerInfo = es().providerInfo[providerId];
        return (providerInfo.providerAddress, providerInfo.isProxyable);
    }

    function _defaultTokenURIProvider() internal view virtual returns (uint256) {
        return es().defaultProvider;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721BaseController } from "./IERC721BaseController.sol";
import { ERC721BaseModel } from "./ERC721BaseModel.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";

abstract contract ERC721BaseController is IERC721BaseController, ERC721BaseModel {
    using AddressUtils for address;

    function balanceOf_(address owner) internal view virtual returns (uint256) {
        owner.enforceIsNotZeroAddress();
        return _balanceOf(owner);
    }

    function ownerOf_(uint256 tokenId) internal view virtual returns (address owner) {
        owner = _ownerOf(tokenId);
        owner.enforceIsNotZeroAddress();
    }

    function _enforceTokenExists(uint256 tokenId) internal view virtual {
        if (!_tokenExists(tokenId)) {
            revert NonExistentToken(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token URI provider interface
 */
interface IERC721TokenURIProvider {
    /**
     * @notice Get the URI of a token
     * @param tokenId The token id
     * @return tokenURI The token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_TOKEN_URI_STORAGE_SLOT = keccak256("core.token.erc721.tokenURI.storage");

struct ProviderInfo {
    bool isProxyable;
    address providerAddress;
}

struct ERC721TokenURIStorage {
    uint256 defaultProvider;
    mapping(uint256 => uint256) tokenURIProviders;
    mapping(uint256 => ProviderInfo) providerInfo;
}

function erc721TokenURIStorage() pure returns (ERC721TokenURIStorage storage es) {
    bytes32 slot = ERC721_TOKEN_URI_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721BaseController {
    error NonExistentToken(uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721BaseStorage, ERC721BaseStorage } from "./ERC721BaseStorage.sol";
import { ERC721TokenUtils } from "../utils/ERC721TokenUtils.sol";
import { ERC721InventoryUtils } from "../utils/ERC721InventoryUtils.sol";

abstract contract ERC721BaseModel {
    using ERC721TokenUtils for uint256;
    using ERC721InventoryUtils for uint256;
    
    function _balanceOf(address owner) internal view virtual returns (uint256) {
        return erc721BaseStorage().inventories[owner].balance();
    }
    
    function _ownerOf(uint256 tokenId) internal view virtual returns (address owner) {
        ERC721BaseStorage storage es = erc721BaseStorage();
        owner = es.owners[tokenId];

        if (owner == address(0)) {
            address holder = tokenId.holder();
            if (es.inventories[holder].has(tokenId.index())) {
                owner = holder;
            }
        }
    }

    function _tokenExists(uint256 tokenId) internal view virtual returns (bool) {
        ERC721BaseStorage storage es = erc721BaseStorage();

        if (es.owners[tokenId] == address(0)) {
            return es.inventories[tokenId.holder()].has(tokenId.index());
        }
        
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 enumerable page interface
 */
interface IERC721EnumerablePage {
    /**
     * @notice Get a token by enumeration index
     * @param index The token position
     * @return tokenId The token id
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC721_ENUMERABLE_STORAGE_SLOT = keccak256("core.token.erc721.enumerable.storage");

struct PageInfo {
    uint16 length;
    address pageAddress;
}

struct ERC721EnumerableStorage {
    PageInfo[] pages;
}

function erc721EnumerableStorage() pure returns (ERC721EnumerableStorage storage es) {
    bytes32 slot = ERC721_ENUMERABLE_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { proxyFacetedStorage, ProxyFacetedStorage, SelectorInfo, ImplementationInfo } from "./ProxyFacetedStorage.sol";

abstract contract ProxyFacetedModel {
    function _implementation(bytes4 selector) internal view virtual returns (address) {
        return proxyFacetedStorage().selectorInfo[selector].implementation;
    }

    function _addFunction(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ps.selectorInfo[selector] = SelectorInfo(
            isUpgradable,
            uint16(ps.selectors.length),
            implementation
        );
        ps.selectors.push(selector);
    }

    function _replaceFunction(bytes4 selector, address implementation) internal virtual {
        proxyFacetedStorage().selectorInfo[selector].implementation = implementation;
    }

    function _removeFunction(bytes4 selector) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        uint16 position = ps.selectorInfo[selector].position;
        uint256 lastPosition = ps.selectors.length - 1;

        if (position != lastPosition) {
            bytes4 lastSelector = ps.selectors[lastPosition];
            ps.selectors[position] = lastSelector;
            ps.selectorInfo[lastSelector].position = position;
        }

        ps.selectors.pop();
        delete ps.selectorInfo[selector];
    }

    function _afterAddFunction(address implementation) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ImplementationInfo memory info = ps.implementationInfo[implementation];

        if (++info.selectorCount == 1) {
            info.position = uint16(ps.implementations.length);
            ps.implementations.push(implementation);
        }

        ps.implementationInfo[implementation] = info;
    }

    function _afterRemoveFunction(address implementation) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ImplementationInfo memory info = ps.implementationInfo[implementation];

        if (--info.selectorCount == 0) {
            uint16 position = info.position;
            uint256 lastPosition = ps.implementations.length - 1;

            if (position != lastPosition) {
                address lastImplementation = ps.implementations[lastPosition];
                ps.implementations[position] = lastImplementation;
                ps.implementationInfo[lastImplementation].position = position;
            }

            ps.implementations.pop();
            delete ps.implementationInfo[implementation];
        } else {
            ps.implementationInfo[implementation] = info;
        }
    }

    function _setUpgradableFunction(bytes4 selector, bool isUpgradable) internal virtual {
        proxyFacetedStorage().selectorInfo[selector].isUpgradable = isUpgradable;
    }

    function _isUpgradable(bytes4 selector) internal view virtual returns (bool) {
        return proxyFacetedStorage().selectorInfo[selector].isUpgradable;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ProxyModel } from "./ProxyModel.sol";
import { AddressUtils } from "../utils/AddressUtils.sol";
import { IntegerUtils } from "../utils/IntegerUtils.sol";

abstract contract ProxyController is ProxyModel {
    using AddressUtils for address;
    using IntegerUtils for uint256;

    function Proxy_(address init, bytes memory data) internal virtual {
        data.length.enforceIsNotZero();
        init.enforceIsContract();
        _Proxy(init, data);
    }

    function fallback_() internal virtual {
        _delegate(implementation_());
    }

    function implementation_() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant FACETED_PROXY_STORAGE_SLOT = keccak256("core.proxy.faceted.storage");

struct SelectorInfo {
    bool isUpgradable;
    uint16 position;
    address implementation;
}

struct ImplementationInfo {
    uint16 position;
    uint16 selectorCount;
}

struct ProxyFacetedStorage {
    mapping(bytes4 => SelectorInfo) selectorInfo;
    bytes4[] selectors;
    mapping(address => ImplementationInfo) implementationInfo;
    address[] implementations;
}

function proxyFacetedStorage() pure returns (ProxyFacetedStorage storage ps) {
    bytes32 slot = FACETED_PROXY_STORAGE_SLOT;
    assembly {
        ps.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ProxyModel {
    function _Proxy(address init, bytes memory data) internal virtual {
        (bool success, bytes memory reason) = init.delegatecall(data);

        if (!success) {
            assembly {
                revert(add(reason, 0x20), mload(reason))
            }
        }
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}