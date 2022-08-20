// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMutytesLegacyProvider } from "./IMutytesLegacyProvider.sol";
import { IERC721TokenURIProvider } from "../../core/token/ERC721/tokenURI/IERC721TokenURIProvider.sol";
import { IERC721Enumerable } from "../../core/token/ERC721/enumerable/IERC721Enumerable.sol";
import { LabArchiveController } from "../../ethernia/lab/archive/LabArchiveController.sol";
import { ERC721EnumerableController } from "../../core/token/ERC721/enumerable/ERC721EnumerableController.sol";
import { ERC165Controller } from "../../core/introspection/ERC165Controller.sol";
import { StringUtils } from "../../core/utils/StringUtils.sol";

/**
 * @title Mutytes legacy token URI provider implementation
 */
contract MutytesLegacyProvider2 is
    IERC721TokenURIProvider,
    LabArchiveController,
    ERC721EnumerableController,
    ERC165Controller
{
    using StringUtils for uint256;

    /**
     * @inheritdoc IERC721TokenURIProvider
     */
    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        IMutytesLegacyProvider interpreter = IMutytesLegacyProvider(
            address(0x583473cc07fE026b65f9Dc8aDD96F59bF4d22A32)
        );
        IMutytesLegacyProvider.TokenData memory token;
        IMutytesLegacyProvider.MutationData memory mutation;

        token.id = tokenId;
        token.name = _mutyteName(tokenId);
        token.info = _mutyteDescription(tokenId);
        token.dna = new uint256[](1);
        token.dna[0] = uint256(keccak256(abi.encode(tokenId)));

        if (
            bytes(token.name).length == 0 &&
            _supportsInterface(type(IERC721Enumerable).interfaceId)
        ) {
            token.name = string.concat("Mutyte #", _indexOfToken(tokenId).toString());
        }

        if (bytes(token.info).length == 0) {
            token
                .info = "The Mutytes are a collection of 1,721 severely mutated creatures that invaded Ethernia. Completely decentralized, every Mutyte is generated, stored and rendered 100% on-chain. Once acquired, a Mutyte grants its owner access to the lab and its facilities.";
        }

        mutation.name = _mutationName(0);
        mutation.info = _mutationDescription(0);
        mutation.count = 1;

        return interpreter.tokenURI(token, mutation, "https://www.mutytes.com/mutyte/");
    }

    function _indexOfToken(uint256 tokenId) internal view virtual returns (uint256 i) {
        unchecked {
            for (; i < _initialSupply(); i++) {
                if (_tokenByIndex(i) == tokenId) {
                    break;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Mutytes legacy token URI provider interface
 */
interface IMutytesLegacyProvider {
    struct TokenData {
        uint256 id;
        string name;
        string info;
        uint256[] dna;
    }

    struct MutationData {
        uint256 id;
        string name;
        string info;
        uint256 count;
    }

    /**
     * @notice Get the URI of a token
     * @param token The token data
     * @param mutation The mutation data
     * @param externalURL External token URL
     * @return tokenURI The token URI
     */
    function tokenURI(
        TokenData calldata token,
        MutationData calldata mutation,
        string calldata externalURL
    ) external view returns (string memory);
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

/**
 * @title ERC721 enumerable extension interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable {
    /**
     * @notice Get the total token supply
     * @return supply The total supply amount
     */
    function totalSupply() external returns (uint256);

    /**
     * @notice Get a token by global enumeration index
     * @param index The token position
     * @return tokenId The token id
     */
    function tokenByIndex(uint256 index) external returns (uint256);

    /**
     * @notice Get an owner's token by enumeration index
     * @param owner The owner's address
     * @param index The token position
     * @return tokenId The token id
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
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
        return 31;
    }

    function _maxDescriptionLength() internal view virtual returns (uint256) {
        return 256;
    }

    function _enforceIsValidName(bytes memory name) internal view virtual {
        name.length.enforceNotGreaterThan(_maxNameLength());

        unchecked {
            for (uint256 i; i < name.length; i++) {
                uint8 c = uint8(name[i]);

                if (
                    (c > 96 && c < 123) || // [a-z]
                    (c > 64 && c < 91) || // [A-Z]
                    (c > 47 && c < 59) || // [0-9:]
                    (c == 32 || c == 34 || c == 39) || // [SPACE"']
                    (c > 43 && c < 47) // [,-.]
                ) {
                    continue;
                }

                revert UnexpectedCharacter(c);
            }
        }
    }

    function _enforceIsValidDescription(bytes memory desc) internal view virtual {
        desc.length.enforceNotGreaterThan(_maxDescriptionLength());

        unchecked {
            for (uint256 i; i < desc.length; i++) {
                uint8 c = uint8(desc[i]);

                if (c > 31 && c < 127) {
                    continue;
                }

                revert UnexpectedCharacter(c);
            }
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial lab archive interface required by controller functions
 */
interface ILabArchiveController {
    error UnexpectedCharacter(uint256 code);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { labArchiveStorage, LabArchiveStorage } from "./LabArchiveStorage.sol";

abstract contract LabArchiveModel {
    function _mutyteByName(string memory name) internal view virtual returns (uint256) {
        return labArchiveStorage().mutyteByName[name];
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
            ls.mutyteByName[name] = tokenId;
        }

        if (bytes(oldName).length > 0) {
            ls.mutyteByName[oldName] = 0;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721EnumerablePage } from "./IERC721EnumerablePage.sol";
import { erc721EnumerableStorage, ERC721EnumerableStorage, PageInfo } from "./ERC721EnumerableStorage.sol";

abstract contract ERC721EnumerableModel {
    function _ERC721Enumerable(PageInfo[] memory pages) internal virtual {
        ERC721EnumerableStorage storage es = erc721EnumerableStorage();

        if (es.pages.length > 0) {
            delete es.pages;
        }

        unchecked {
            for (uint256 i; i < pages.length; i++) {
                es.pages.push(pages[i]);
            }
        }
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