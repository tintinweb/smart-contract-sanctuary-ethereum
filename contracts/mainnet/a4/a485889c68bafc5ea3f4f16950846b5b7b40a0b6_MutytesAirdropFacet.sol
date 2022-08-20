// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableController } from "../../core/access/ownable/OwnableController.sol";
import { erc721BaseStorage, ERC721BaseStorage } from "../../core/token/ERC721/base/ERC721BaseStorage.sol";
import { ERC721MintableController } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { ERC721TokenUtils } from "../../core/token/ERC721/utils/ERC721TokenUtils.sol";
import { ERC721InventoryUtils } from "../../core/token/ERC721/utils/ERC721InventoryUtils.sol";
import { BitmapUtils } from "../../core/utils/BitmapUtils.sol";

/**
 * @title Mutytes airdrop facet
 */
contract MutytesAirdropFacet is OwnableController, ERC721MintableController {
    using ERC721TokenUtils for address;
    using ERC721InventoryUtils for uint256;
    using BitmapUtils for uint256;

    /**
     * @notice Airdrop a token to recipients
     * @param recipients The recipient addresses
     */
    function airdrop(address[] calldata recipients) external virtual onlyOwner {
        ERC721BaseStorage storage es = erc721BaseStorage();
        uint256 inventory = es.inventories[msg.sender];
        uint256 amount = recipients.length;
        uint256 burnIndex = inventory.current() - amount;
        uint256 burnTokenId = msg.sender.toTokenId() | burnIndex;

        unchecked {
            es.inventories[msg.sender] = _removeFromInventory(
                inventory,
                burnIndex,
                amount
            );

            for (uint256 i; i < amount; i++) {
                emit Transfer(msg.sender, address(0), burnTokenId + i);
                address to = recipients[i];
                uint256 mintTokenId = to.toTokenId() | _mintBalanceOf(to);
                es.inventories[to] = es.inventories[to].add(1);
                emit Transfer(address(0), to, mintTokenId);
            }
        }
    }

    /**
     * @notice Airdrop tokens to a recipient
     * @param to The recipient address
     * @param amount The amount of tokens to airdrop
     */
    function airdrop(address to, uint256 amount) external virtual onlyOwner {
        ERC721BaseStorage storage es = erc721BaseStorage();
        uint256 inventory = es.inventories[msg.sender];
        uint256 burnIndex = inventory.current() - amount;
        uint256 burnTokenId = msg.sender.toTokenId() | burnIndex;
        uint256 mintTokenId = to.toTokenId() | _mintBalanceOf(to);
        es.inventories[to] = es.inventories[to].add(amount);

        unchecked {
            es.inventories[msg.sender] = _removeFromInventory(
                inventory,
                burnIndex,
                amount
            );

            for (uint256 i; i < amount; i++) {
                emit Transfer(msg.sender, address(0), burnTokenId + i);
                emit Transfer(address(0), to, mintTokenId + i);
            }
        }
    }

    function _removeFromInventory(
        uint256 inventory,
        uint256 offset,
        uint256 amount
    ) internal pure virtual returns (uint256) {
        return
            inventory.unsetRange(ERC721InventoryUtils.BITMAP_OFFSET + offset, amount) -
            (amount << ERC721InventoryUtils.BALANCE_BITSIZE) -
            amount;
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

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721TransferableController {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
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

bytes32 constant ERC721_SUPPLY_STORAGE_SLOT = keccak256("core.token.erc721.supply.storage");

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