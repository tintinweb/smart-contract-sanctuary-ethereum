// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { LabArchive } from "../../ethernia/lab/archive/LabArchive.sol";

/**
 * @title Mutytes lab archive facet
 */
contract MutytesLabArchiveFacet is LabArchive {
    /**
     * @notice Test setting a Mutyte's name
     * @param tokenId The Mutyte's token id
     * @param name The Mutyte's name
     */
    function setMutyteNameTest(uint256 tokenId, string calldata name)
        external
        virtual
        onlyOwner
    {
        setMutyteName_(tokenId, name);
    }

    /**
     * @notice Test setting a Mutyte's description
     * @param tokenId The Mutyte's token id
     * @param desc The Mutyte's description
     */
    function setMutyteDescriptionTest(uint256 tokenId, string calldata desc)
        external
        virtual
        onlyOwner
    {
        setMutyteDescription_(tokenId, desc);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ILabArchive } from "./ILabArchive.sol";
import { LabArchiveController } from "./LabArchiveController.sol";

/**
 * @title Lab archive implementation
 */
contract LabArchive is ILabArchive, LabArchiveController {
    /**
     * @inheritdoc ILabArchive
     */
    function mutyteByName(string calldata name) external view virtual returns (uint256) {
        return mutyteByName_(name);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutyteName(uint256 tokenId) external view virtual returns (string memory) {
        return mutyteName_(tokenId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutyteDescription(uint256 tokenId)
        external
        view
        virtual
        returns (string memory)
    {
        return mutyteDescription_(tokenId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutationName(uint256 mutationId)
        external
        view
        virtual
        returns (string memory)
    {
        return mutationName_(mutationId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function mutationDescription(uint256 mutationId)
        external
        view
        virtual
        returns (string memory)
    {
        return mutationDescription_(mutationId);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutyteName(uint256 tokenId, string calldata name) external virtual {
        setMutyteName_(tokenId, name);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutyteDescription(uint256 tokenId, string calldata desc)
        external
        virtual
    {
        setMutyteDescription_(tokenId, desc);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutationName(uint256 mutationId, string calldata name)
        external
        virtual
        onlyOwner
    {
        setMutationName_(mutationId, name);
    }

    /**
     * @inheritdoc ILabArchive
     */
    function setMutationDescription(uint256 mutationId, string calldata desc)
        external
        virtual
        onlyOwner
    {
        setMutationDescription_(mutationId, desc);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ILabArchiveController } from "./ILabArchiveController.sol";

/**
 * @title Lab archive interface
 */
interface ILabArchive is ILabArchiveController {
    /**
     * @notice Get the Mutyte's token id
     * @param name The Mutyte's name
     * @return tokenId The Mutyte's token id
     */
    function mutyteByName(string calldata name) external returns (uint256);

    /**
     * @notice Get the Mutyte's name
     * @param tokenId The Mutyte's token id
     * @return name The Mutyte's name
     */
    function mutyteName(uint256 tokenId) external returns (string memory);

    /**
     * @notice Get the Mutyte's description
     * @param tokenId The Mutyte's token id
     * @return desc The Mutyte's description
     */
    function mutyteDescription(uint256 tokenId) external returns (string memory);

    /**
     * @notice Get the mutation's name
     * @param mutationId The mutation id
     * @return name The mutation's name
     */
    function mutationName(uint256 mutationId) external returns (string memory);

    /**
     * @notice Get the mutation's description
     * @param mutationId The mutation id
     * @return desc The mutation's description
     */
    function mutationDescription(uint256 mutationId) external returns (string memory);

    /**
     * @notice Set the Mutyte's name
     * @param tokenId The Mutyte's token id
     * @param name The Mutyte's name
     */
    function setMutyteName(uint256 tokenId, string calldata name) external;

    /**
     * @notice Set the Mutyte's description
     * @param tokenId The Mutyte's token id
     * @param desc The Mutyte's description
     */
    function setMutyteDescription(uint256 tokenId, string calldata desc) external;

    /**
     * @notice Set the mutations's name
     * @param mutationId The mutation id
     * @param name The mutations's name
     */
    function setMutationName(uint256 mutationId, string calldata name) external;

    /**
     * @notice Set the mutations's description
     * @param mutationId The mutation id
     * @param desc The mutations's description
     */
    function setMutationDescription(uint256 mutationId, string calldata desc) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ILabArchiveController } from "./ILabArchiveController.sol";
import { LabArchiveModel } from "./LabArchiveModel.sol";
import { ERC721ApprovableController } from "../../../core/token/ERC721/approvable/ERC721ApprovableController.sol";
import { OwnableController } from "../../../core/access/ownable/OwnableController.sol";
import { AddressUtils } from "../../../core/utils/AddressUtils.sol";
import { IntegerUtils } from "../../../core/utils/IntegerUtils.sol";

abstract contract LabArchiveController is
    ILabArchiveController,
    LabArchiveModel,
    ERC721ApprovableController,
    OwnableController
{
    using AddressUtils for address;
    using IntegerUtils for uint256;

    function mutyteByName_(string memory name)
        internal
        view
        virtual
        returns (uint256 tokenId)
    {
        tokenId = _mutyteByName(name);
        _enforceTokenExists(tokenId);
    }

    function mutyteName_(uint256 tokenId) internal view virtual returns (string memory) {
        _enforceTokenExists(tokenId);
        return _mutyteName(tokenId);
    }

    function mutyteDescription_(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        _enforceTokenExists(tokenId);
        return _mutyteDescription(tokenId);
    }

    function mutationName_(uint256 mutationId)
        internal
        view
        virtual
        returns (string memory)
    {
        return _mutationName(mutationId);
    }

    function mutationDescription_(uint256 mutationId)
        internal
        view
        virtual
        returns (string memory)
    {
        return _mutationDescription(mutationId);
    }

    function setMutyteName_(uint256 tokenId, string memory name) internal virtual {
        _enforceIsApproved(_ownerOf(tokenId), msg.sender, tokenId);
        _enforceIsValidName(bytes(name));
        _ownerOf(_mutyteByName(name)).enforceIsZeroAddress();
        _setMutyteName(tokenId, name, _mutyteName(tokenId));
    }

    function setMutyteDescription_(uint256 tokenId, string memory desc) internal virtual {
        _enforceIsApproved(_ownerOf(tokenId), msg.sender, tokenId);
        _enforceIsValidDescription(bytes(desc));
        _setMutyteDescription(tokenId, desc);
    }

    function setMutationName_(uint256 mutationId, string memory name) internal virtual {
        _enforceIsValidName(bytes(name));
        _setMutationName(mutationId, name);
    }

    function setMutationDescription_(uint256 mutationId, string memory desc)
        internal
        virtual
    {
        _enforceIsValidDescription(bytes(desc));
        _setMutationDescription(mutationId, desc);
    }

    function _maxNameLength() internal view virtual returns (uint256) {
        return 16;
    }

    function _maxDescriptionLength() internal view virtual returns (uint256) {
        return 256;
    }

    function _enforceIsValidName(bytes memory name) internal view virtual {
        uint256 length = name.length;
        length.enforceNotGreaterThan(_maxNameLength());
        bool whitespace = length > 0;

        unchecked {
            for (uint256 i; i < length; i++) {
                uint8 c = uint8(name[i]);

                if (c == 32) {
                    continue;
                } else if (
                    (c > 96 && c < 123) || // [a-z]
                    (c > 64 && c < 91) || // [A-Z]
                    (c > 47 && c < 59) || // [0-9:]
                    (c == 39) || // [']
                    (c > 43 && c < 47) // [,-.]
                ) {
                    if (whitespace) {
                        whitespace = false;
                    }

                    continue;
                }

                revert UnexpectedCharacter(c);
            }
        }

        if (whitespace) {
            revert UnexpectedWhitespaceString();
        }
    }

    function _enforceIsValidDescription(bytes memory desc) internal view virtual {
        uint256 length = desc.length;
        length.enforceNotGreaterThan(_maxDescriptionLength());
        bool whitespace = length > 0;

        unchecked {
            for (uint256 i; i < length; i++) {
                uint8 c = uint8(desc[i]);

                if (c == 32) {
                    continue;
                } else if (c > 32 && c < 127 && c != 34) {
                    if (whitespace) {
                        whitespace = false;
                    }

                    if (c != 92 || i < length - 1) {
                        continue;
                    }
                }

                revert UnexpectedCharacter(c);
            }
        }

        if (whitespace) {
            revert UnexpectedWhitespaceString();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial lab archive interface required by controller functions
 */
interface ILabArchiveController {
    error UnexpectedCharacter(uint256 code);
    
    error UnexpectedWhitespaceString();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { labArchiveStorage, LabArchiveStorage } from "./LabArchiveStorage.sol";
import { StringUtils } from "../../../core/utils/StringUtils.sol";

abstract contract LabArchiveModel {
    using StringUtils for string;

    function _mutyteByName(string memory name) internal view virtual returns (uint256) {
        return labArchiveStorage().mutyteByName[name.toLowerCase()];
    }

    function _mutyteName(uint256 tokenId) internal view virtual returns (string memory) {
        return labArchiveStorage().mutyteNames[tokenId];
    }

    function _mutyteDescription(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return labArchiveStorage().mutyteDescriptions[tokenId];
    }

    function _mutationName(uint256 mutationId)
        internal
        view
        virtual
        returns (string memory)
    {
        return labArchiveStorage().mutationNames[mutationId];
    }

    function _mutationDescription(uint256 mutationId)
        internal
        view
        virtual
        returns (string memory)
    {
        return labArchiveStorage().mutationDescriptions[mutationId];
    }

    function _setMutyteName(
        uint256 tokenId,
        string memory name,
        string memory oldName
    ) internal virtual {
        LabArchiveStorage storage ls = labArchiveStorage();
        ls.mutyteNames[tokenId] = name;

        if (bytes(name).length > 0) {
            ls.mutyteByName[name.toLowerCase()] = tokenId;
        }

        if (bytes(oldName).length > 0) {
            ls.mutyteByName[oldName.toLowerCase()] = 0;
        }
    }

    function _setMutyteDescription(uint256 tokenId, string memory desc) internal virtual {
        labArchiveStorage().mutyteDescriptions[tokenId] = desc;
    }

    function _setMutationName(uint256 mutationId, string memory name) internal virtual {
        labArchiveStorage().mutationNames[mutationId] = name;
    }

    function _setMutationDescription(uint256 mutationId, string memory desc)
        internal
        virtual
    {
        labArchiveStorage().mutationDescriptions[mutationId] = desc;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721ApprovableController } from "./IERC721ApprovableController.sol";
import { ERC721ApprovableModel } from "./ERC721ApprovableModel.sol";
import { ERC721BaseController } from "../base/ERC721BaseController.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";

abstract contract ERC721ApprovableController is
    IERC721ApprovableController,
    ERC721ApprovableModel,
    ERC721BaseController
{
    using AddressUtils for address;

    function approve_(address approved, uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);
        owner.enforceNotEquals(approved);
        _enforceIsApproved(owner, msg.sender);
        _approve_(owner, approved, tokenId);
    }

    function setApprovalForAll_(address operator, bool approved) internal virtual {
        operator.enforceIsNotZeroAddress();
        operator.enforceNotEquals(msg.sender);
        _setApprovalForAll_(msg.sender, operator, approved);
    }

    function getApproved_(uint256 tokenId) internal view virtual returns (address) {
        _enforceTokenExists(tokenId);
        return _getApproved(tokenId);
    }

    function isApprovedForAll_(address owner, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return _isApprovedForAll(owner, operator);
    }

    function _approve_(
        address owner,
        address approved,
        uint256 tokenId
    ) internal virtual {
        _approve(approved, tokenId);
        emit Approval(owner, approved, tokenId);
    }

    function _setApprovalForAll_(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        _setApprovalForAll(owner, operator, approved);
        emit ApprovalForAll(owner, operator, approved);
    }

    function _isApproved(address owner, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return owner == operator || _isApprovedForAll(owner, operator);
    }

    function _isApproved(
        address owner,
        address operator,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        return _isApproved(owner, operator) || _getApproved(tokenId) == operator;
    }

    function _enforceIsApproved(address owner, address operator) internal view virtual {
        if (!_isApproved(owner, operator)) {
            revert UnapprovedOperatorAction();
        }
    }

    function _enforceIsApproved(
        address owner,
        address operator,
        uint256 tokenId
    ) internal view virtual {
        if (!_isApproved(owner, operator, tokenId)) {
            revert UnapprovedTokenAction(tokenId);
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

bytes32 constant LAB_ARCHIVE_STORAGE_SLOT = keccak256("ethernia.lab.archive.storage");

struct LabArchiveStorage {
    mapping(uint256 => string) mutyteNames;
    mapping(string => uint256) mutyteByName;
    mapping(uint256 => string) mutyteDescriptions;
    mapping(uint256 => string) mutationNames;
    mapping(uint256 => string) mutationDescriptions;
}

function labArchiveStorage() pure returns (LabArchiveStorage storage ls) {
    bytes32 slot = LAB_ARCHIVE_STORAGE_SLOT;
    assembly {
        ls.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title String utilities
 * @dev See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
 */
library StringUtils {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        unchecked {
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
    }

    function toLowerCase(string memory input) internal pure returns (string memory output) {
        uint256 length = bytes(input).length;
        output = new string(length);
        
        assembly {
            let outputPtr := add(output, 0x1F)

            for { let i } lt(i, length) { } {
                i := add(i, 1)
                let c := and(mload(add(input, i)), 0xFF)

                if and(lt(c, 91), gt(c, 64)) {
                    c := add(c, 0x20)
                }

                mstore8(add(outputPtr, i), c)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721ApprovableController {
    error UnapprovedTokenAction(uint256 tokenId);
    
    error UnapprovedOperatorAction();

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc721ApprovableStorage as es } from "./ERC721ApprovableStorage.sol";

abstract contract ERC721ApprovableModel {
    function _approve(address approved, uint256 tokenId) internal virtual {
        es().tokenApprovals[tokenId] = approved;
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        es().operatorApprovals[owner][operator] = approved;
    }

    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return es().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address owner, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return es().operatorApprovals[owner][operator];
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

bytes32 constant ERC721_APPROVABLE_STORAGE_SLOT = keccak256("core.token.erc721.approvable.storage");

struct ERC721ApprovableStorage {
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
}

function erc721ApprovableStorage() pure returns (ERC721ApprovableStorage storage es) {
    bytes32 slot = ERC721_APPROVABLE_STORAGE_SLOT;
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