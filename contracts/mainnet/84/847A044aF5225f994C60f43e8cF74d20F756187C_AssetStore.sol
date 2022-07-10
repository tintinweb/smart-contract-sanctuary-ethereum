// SPDX-License-Identifier: MIT

/*
 * On-chain asset store, which allows multiple smart contracts to shara vector assets.
 *
 * All assets registered to this store will be treated as cc0 (public domain), 
 * CC-BY-SA(Attribution-ShareAlike) 2.0, Apache 2.0, MIT, or something similar 
 * (should be specified in the "group"). If the attribution is required, 
 * the creater's name should be either in the "group", "category" or "name".
 *
 * All registered assets will be available to other smart contracts for free, including
 * commecial services. Therefore, it is not allowed to register assets that require
 * any form of commercial licenses. 
 *
 * Once an asset is registed with group/category/name, it is NOT possible to update,
 * which guaranttees the availability in future.
 *
 * Please respect those people who paid gas fees to register those assets. 
 * Their wallet addresses are permanently stored as the "souldbound" attribute
 * of each asset (which is accessible via getAttributes). Using those addressed 
 * for air-drops and whitelisting is one way to appreciate their efforts. 
 * 
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IAssetStoreRegistry, IAssetStore } from './interfaces/IAssetStore.sol';
import { IStringValidator } from './interfaces/IStringValidator.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import './libs/StringValidator.sol';
import './libs/StringSet.sol';
import './libs/SVGPathDecoder.sol';

// import "hardhat/console.sol";

/*
 * Abstract contract that implements the categolized asset storage system. 
 */
abstract contract AssetStoreCore is Ownable, IAssetStoreRegistry {
  using StringSet for StringSet.Set;
  using Strings for uint16;
  using Strings for uint256;
  
  struct Asset {
    uint32 groupId;    // index to groups + 1
    uint32 categoryId; // index to categories + 1
    string name;
    string minter;
    bytes metadata;
    address soulbound;
    uint256[] partsIds;
  }

  // Upgradable string validator
  IStringValidator public validator;

  // Upgradable path decoder
  IPathDecoder public decoder;

  // asset & part database
  mapping(uint256 => Asset) private assets;
  uint256 private nextAssetIndex = 1; // 0 indicates an error
  mapping(uint256 => Part) private parts;
  uint256 private nextPartIndex = 1; // 0 indicates an error

  // Groups and categories(for browsing)
  StringSet.Set internal groupSet;
  mapping(uint32 => StringSet.Set) internal categorySets;
  
  // Grouped and categorized assetIds (for browsing)
  struct AssetCatalog {
    mapping(uint32 => uint256) assetIds; 
    uint32 nextAssetIndex;
    mapping(string => uint256) assetNameToId;
  }
  mapping(uint32 => mapping(uint32 => AssetCatalog)) internal assetCatalogs;

  constructor() {
    validator = new StringValidator(); // default validator
    decoder = new SVGPathDecoder(); // default decoder
  }

  /*
   * Returns the groupId of the specified group, creating a new Id if necessary.
   * @notice gruopId == groupIndex + 1
   */
  function _getGroupId(string memory group) private returns(uint32) {
    (uint32 id, bool created) = groupSet.getOrCreateId(group, validator);
    if (created) {
      emit GroupAdded(group); 
    }
    return id;
  }

  /*
   * Returns the categoryId of the specified category in a group, creating a new Id if necessary.
   * The categoryId is unique only within that group. 
   * @notice categoryId == categoryIndex + 1
   */
  function _getCategoryId(string memory group, uint32 groupId, string memory category) private returns(uint32) {
    StringSet.Set storage categorySet =  categorySets[groupId];
    (uint32 id, bool created) = categorySet.getOrCreateId(category, validator);
    if (created) {
      emit CategoryAdded(group, category);
    }
    return id;
  }

  /*
   * Register a Part and returns its id, which is its index in parts[].
   */
  function _registerPart(Part memory _part) private returns(uint256) {
    parts[nextPartIndex++] = _part;
    return nextPartIndex-1;    
  }

  /*
   * We need to validate any strings embedded in SVG to prevent malicious injections. 
   * @notice: group and catalog are validated in Stringset.getId(). 
   *  The body is a binary format, which will be validated when we decode.
   */
  modifier validateAsset(AssetInfo memory _assetInfo) {
    uint size = _assetInfo.parts.length;
    uint i;
    for (i=0; i < size; i++) {
      Part memory part = _assetInfo.parts[i];
      require(validator.validate(bytes(part.color)), "Invalid AssetData Color");
    }
    require(validator.validate(bytes(_assetInfo.name)), "Invalid AssetData Name");
    _;
  }

  /*
   * Register an Asset and returns its id, which is its index in assets[].
   */
  function _registerAsset(AssetInfo memory _assetInfo) internal validateAsset(_assetInfo) returns(uint256) {
    uint32 groupId = _getGroupId(_assetInfo.group);
    uint32 categoryId = _getCategoryId(_assetInfo.group, groupId, _assetInfo.category);
    uint size = _assetInfo.parts.length;
    uint256[] memory partsIds = new uint256[](size);
    uint i;
    for (i=0; i<size; i++) {
      partsIds[i] = _registerPart(_assetInfo.parts[i]);
    }
    uint256 assetId = nextAssetIndex++;
    Asset storage asset = assets[assetId];
    asset.name = _assetInfo.name;
    asset.soulbound = _assetInfo.soulbound;
    uint minterLength = bytes(_assetInfo.minter).length; 
    if (minterLength > 0) {
      require(minterLength <= 32, "AssetSgore: _registerAsset, minter name is too long.");
      asset.minter = _assetInfo.minter; // @notice: no validation
    }
    if (_assetInfo.metadata.length > 0) {
      asset.metadata = _assetInfo.metadata;
    }
    asset.groupId = groupId;
    asset.categoryId = categoryId;
    asset.partsIds = partsIds;
    
    AssetCatalog storage assetCatalog = assetCatalogs[groupId][categoryId];
    require(assetCatalog.assetNameToId[_assetInfo.name] == 0, "Asset already exists with the same group, category and name");
    assetCatalog.assetIds[assetCatalog.nextAssetIndex++] = assetId;
    assetCatalog.assetNameToId[_assetInfo.name] = assetId;

    emit AssetRegistered(msg.sender, assetId);
    return assetId;
  }

  // Returns the number of registered assets
  function getAssetCount() external view returns(uint256) {
    return nextAssetIndex - 1;
  }

  modifier assetExists(uint256 _assetId) {
    require(_assetId > 0 && _assetId < nextAssetIndex, "AssetStore: assetId is out of range"); 
    _;
  }

  modifier partExists(uint256 _partId) {
    require(_partId > 0 && _partId < nextPartIndex, "partId is out of range");
    _;
  }

  // This allows us to keep the assets private. 
  function _getAsset(uint256 _assetId) internal view assetExists(_assetId) returns(Asset memory) {
    return assets[_assetId];
  }

  // This allows us to keep the parts private. 
  function _getPart(uint256 _partId) internal view partExists(_partId) returns(Part memory) {
    return parts[_partId];
  }
}

/*
 * Abstract contract that implements various adminstrative functions, such as
 * managing the whitelist, disable/enable assets and accessing the raw data.
 */
abstract contract AssetStoreAdmin is AssetStoreCore {
  // Upgradable admin (only by owner)
  address public admin;

  /*
   * Whitelist manages the list of contracts which can register assets
   * In future, we disable the whitelist allowing anybody to register assets.
   */
  mapping(address => bool) whitelist;
  bool disableWhitelist = false;

  /*
   * It allows us to disable indivial assets, just in case. 
   */
  mapping(uint256 => bool) disabled;

  constructor() {
    whitelist[msg.sender] = true;
    admin = owner();
  }

  modifier onlyAdmin() {
    require(owner() == _msgSender() || admin == _msgSender(), "AssetStoreAdmin: caller is not the admin");
    _;
  }

  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
  }  

  function setWhitelistStatus(address _address, bool _status) external onlyAdmin {
    whitelist[_address] = _status;
  }

  function setDisabled(uint256 _assetId, bool _status) external assetExists(_assetId) onlyAdmin {
    disabled[_assetId] = _status;
  }

  function setDisableWhitelist(bool _disable) external onlyAdmin {
    disableWhitelist = _disable;
  } 

  function setValidator(IStringValidator _validator) external onlyAdmin {
    validator = _validator;
  }

  function setPathDecoder(IPathDecoder _decoder) external onlyAdmin {
    decoder = _decoder;
  }

  // returns the raw asset data speicified by the assetId (1, ..., count)
  function getRawAsset(uint256 _assetId) external view onlyAdmin returns(Asset memory) {
    return _getAsset(_assetId);
  }

  // returns the raw part data specified by the assetId (1, ... count)
  function getRawPart(uint256 _partId) external view onlyAdmin returns(Part memory) {
    return _getPart(_partId);
  }
}

/*
 * Concreate contract that implements IAssetStoreRegistory
 * Even though this is a concreate contract, we will never deploy this contract directly. 
 */
contract AppStoreRegistory is AssetStoreAdmin {
  modifier onlyWhitelist {
    require(disableWhitelist || whitelist[msg.sender], "AssetStore: The sender must be in the white list.");
    _;
  }
   
  function registerAsset(AssetInfo memory _assetInfo) external override onlyWhitelist returns(uint256) {
    return _registerAsset(_assetInfo);
  }

  function registerAssets(AssetInfo[] memory _assetInfos) external override onlyWhitelist {
    uint i;
    for (i=0; i<_assetInfos.length; i++) {
      _registerAsset(_assetInfos[i]);
    }
  }
}

/*
 * Concreate contract that implements both IAssetStore and IAssetStoreRegistory
 * This is the contract we deploy to the blockchain.
 */
contract AssetStore is AppStoreRegistory, IAssetStore {
  using Strings for uint16;
  using Strings for uint256;
  using StringSet for StringSet.Set;

  modifier enabled(uint256 _assetId) {
    require(disabled[_assetId] != true, "AssetStore: this asset is diabled");
    _;    
  }

  // Returns the number of registered groups.
  function getGroupCount() external view override returns(uint32) {
    return groupSet.getCount();
  }

  // Returns the name of a group specified with groupIndex (groupId - 1). 
  function getGroupNameAtIndex(uint32 _groupIndex) external view override returns(string memory) {
    return groupSet.nameAtIndex(_groupIndex);
  }

  // Returns the number of categories in the specified group.
  function getCategoryCount(string memory _group) external view override returns(uint32) {
    return categorySets[groupSet.getId(_group)].getCount();
  }

  // Returns the name of category specified with group/categoryIndex pair.
  function getCategoryNameAtIndex(string memory _group, uint32 _categoryIndex) external view override returns(string memory) {
    return categorySets[groupSet.getId(_group)].nameAtIndex(_categoryIndex);
  }

  // Returns the number of asset in the specified group/category. 
  function getAssetCountInCategory(string memory _group, string memory _category) external view override returns(uint32) {
    uint32 groupId = groupSet.getId(_group);
    StringSet.Set storage categorySet = categorySets[groupId];
    return assetCatalogs[groupId][categorySet.getId(_category)].nextAssetIndex;
  }

  // Returns the assetId of the specified group/category/assetIndex. 
  function getAssetIdInCategory(string memory _group, string memory _category, uint32 _assetIndex) external view override returns(uint256) {
    uint32 groupId = groupSet.getId(_group);
    StringSet.Set storage categorySet = categorySets[groupId];
    AssetCatalog storage assetCatalog = assetCatalogs[groupId][categorySet.getId(_category)]; 
    require(_assetIndex < assetCatalog.nextAssetIndex, "The assetIndex is out of range");
    return assetCatalog.assetIds[_assetIndex];
  }

  // Returns the assetId of the specified group/category/name. 
  function getAssetIdWithName(string memory _group, string memory _category, string memory _name) external override view returns(uint256) {
    uint32 groupId = groupSet.getId(_group);
    StringSet.Set storage categorySet = categorySets[groupId];
    return assetCatalogs[groupId][categorySet.getId(_category)].assetNameToId[_name];
  }

  function _getDescription(Asset memory asset) internal view returns(bytes memory) {
    string memory group = groupSet.nameAtIndex(asset.groupId - 1);
    return abi.encodePacked(group, '/', categorySets[asset.groupId].nameAtIndex(asset.categoryId - 1), '/', asset.name);
  }

  /*
   * Generate an id for SVG based on the assetId.
   */
  function _tagForAsset(uint256 _assetId) internal pure returns(string memory) {
    return string(abi.encodePacked('asset', _assetId.toString()));
  }

  function _safeGenerateSVGPart(uint256 _assetId, string memory _tag) internal view returns(bytes memory) {
    Asset memory asset = _getAsset(_assetId);
    uint256[] memory indeces = asset.partsIds;
    bytes memory pack = abi.encodePacked(' <g id="', _tag, '" desc="', _getDescription(asset), '">\n');
    uint i;
    for (i=0; i<indeces.length; i++) {
      Part memory part = _getPart(indeces[i]);
      bytes memory color;
      if (bytes(part.color).length > 0) {
        color = abi.encodePacked(' fill="', part.color ,'"');
      }
      pack = abi.encodePacked(pack, '  <path d="', decoder.decodePath(part.body), '"', color,' />\n');
    }
    pack = abi.encodePacked(pack, ' </g>\n');
    return pack;
  }

  // returns a SVG part with the specified asset
  function generateSVGPart(uint256 _assetId, string memory _tag) external override view enabled(_assetId) returns(string memory) {
    return string(_safeGenerateSVGPart(_assetId, _tag));
  }

  // returns a full SVG with the specified asset
  function generateSVG(uint256 _assetId) external override view enabled(_assetId) returns(string memory) {
    bytes memory pack = abi.encodePacked(
      '<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">\n', 
      _safeGenerateSVGPart(_assetId, _tagForAsset(_assetId)), 
      '</svg>');
    return string(pack);
  }

  // returns the attributes of the specified asset
  function getAttributes(uint256 _assetId) external view override returns(AssetAttributes memory) {
    Asset memory asset = _getAsset(_assetId);
    AssetAttributes memory attr;
    attr.name = asset.name;
    attr.tag = _tagForAsset(_assetId);
    attr.soulbound = asset.soulbound;
    attr.minter = asset.minter;
    attr.metadata = asset.metadata;
    attr.group = groupSet.nameAtIndex(asset.groupId - 1);
    attr.category = categorySets[asset.groupId].nameAtIndex(asset.categoryId - 1);
    attr.width = 1024;
    attr.height = 1024;
    return attr;
  }

  function getStringValidator() external override view returns(IStringValidator) {
    return validator;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.8.6;

import { IStringValidator } from './IStringValidator.sol';

// IAssetStore is the inteface for consumers of the AsseStore.
interface IAssetStore {
  // Browsing
  function getGroupCount() external view returns(uint32);
  function getGroupNameAtIndex(uint32 _groupIndex) external view returns(string memory);
  function getCategoryCount(string memory _group) external view returns(uint32);
  function getCategoryNameAtIndex(string memory _group, uint32 _categoryIndex) external view returns(string memory);
  function getAssetCountInCategory(string memory _group, string memory _category) external view returns(uint32);
  function getAssetIdInCategory(string memory _group, string memory _category, uint32 _assetIndex) external view returns(uint256);
  function getAssetIdWithName(string memory _group, string memory _category, string memory _name) external view returns(uint256);

  // Fetching
  struct AssetAttributes {
    string group;
    string category;
    string name;
    string tag; // the id in SVG
    string minter; // the name of the minter (who paid the gas fee)
    address soulbound; // wallet address of the minter
    bytes metadata; // group/category specific metadata
    uint16 width;
    uint16 height;
  }

  function generateSVG(uint256 _assetId) external view returns(string memory);
  function generateSVGPart(uint256 _assetId, string memory _tag) external view returns(string memory);
  function getAttributes(uint256 _assetId) external view returns(AssetAttributes memory);
  function getStringValidator() external view returns(IStringValidator);
}

// IAssetStoreRegistry is the interface for contracts who registers assets to the AssetStore.
interface IAssetStoreRegistry {
  struct Part {
    bytes body;
    string color;
  }

  struct AssetInfo {
    string group;
    string category;
    string name;
    string minter; // the name of the minter, who is paying the gas fee
    address soulbound; // wallet address of the minter
    bytes metadata; // group/category specific metadata (optional)
    Part[] parts;
  }

  event AssetRegistered(address from, uint256 assetId);
  event GroupAdded(string group);
  event CategoryAdded(string group, string category);

  function registerAsset(AssetInfo memory _assetInfo) external returns(uint256);
  function registerAssets(AssetInfo[] memory _assetInfos) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStringValidator {
  function validate(bytes memory str) external pure returns (bool);
  function sanitizeJason(string memory _str) external pure returns(bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
import { IStringValidator } from '../interfaces/IStringValidator.sol';

pragma solidity ^0.8.6;


contract StringValidator is IStringValidator {
  function validate(bytes memory str) external pure override returns (bool) {
    for(uint i; i < str.length; i++){
      bytes1 char = str[i];
        if(!(
         (char >= 0x30 && char <= 0x39) || //0-9
         (char >= 0x41 && char <= 0x5A) || //A-Z
         (char >= 0x61 && char <= 0x7A) || //a-z
         (char == 0x20) || //SP
         (char == 0x23) || // #
         (char == 0x28) || // (
         (char == 0x29) || // )
         (char == 0x2C) || //,
         (char == 0x2D) || //-
         (char == 0x2E) // .
        )) {
          return false;
      }
    }
    return true;
  }

  function sanitizeJason(string memory _str) external override pure returns(bytes memory) {
    bytes memory src = bytes(_str);
    bytes memory res;
    uint i;
    for (i=0; i<src.length; i++) {
      uint8 b = uint8(src[i]);
      // Skip control codes, escape backslash and double-quote
      if (b >= 0x20) {
        if  (b == 0x5c || b == 0x22) {
          res = abi.encodePacked(res, bytes1(0x5c));
        }
        res = abi.encodePacked(res, b);
      }
    }
    return res;
  }  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { IStringValidator } from '../interfaces/IStringValidator.sol';

/*
 * StringSet stores a set of names (or either group or catalog in AssetStore). 
 */
library StringSet {
  struct Set {
    mapping(uint32 => string) names;
    uint32 nextIndex;
    mapping(string => uint32) ids; // index+1
  }

  function getOrCreateId(Set storage _set, string memory _name, IStringValidator _validator) internal returns(uint32, bool) {
    uint32 id = _set.ids[_name];
    if (id > 0) {
      return (id, false);
    }

    require(_validator.validate(bytes(_name)), "StringSet.getId: Invalid String");
    _set.names[_set.nextIndex++] = _name;
    id = _set.nextIndex; // idex + 1
    _set.ids[_name] = id; 
    return (id, true);
  }

  function getId(Set storage _set, string memory _name) internal view returns (uint32) {
    uint32 id = _set.ids[_name];
    require(id > 0, "StringSet: the specified name does not exist");
    return id;
  }

  /*
   * Retuns the number of items in the set. 
   */
  function getCount(Set storage _set) internal view returns (uint32) {
    return _set.nextIndex;
  }

  /*
   * Safe method to access the name with its index
   */
  function nameAtIndex(Set storage _set, uint32 _index) internal view returns(string memory) {
    require(_index < _set.nextIndex, "StringSet.nameAtIndex: The index is out of range");
    return _set.names[_index];
  }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IPathDecoder.sol";

pragma solidity ^0.8.6;

contract SVGPathDecoder is IPathDecoder {
  using Strings for uint16;
  /**
  * Decode the compressed binary deta and reconstruct SVG path. 
  * The binaryformat is 12-bit middle endian, where the low 4-bit of the middle byte is
  * the high 4-bit of the even item ("ijkl"), and the high 4-bit of the middle byte is the high
  * 4-bit of the odd item ("IJKL"). 
  *   abcdefgh ijklIJKL ABCDEFG
  *
  * If we want to upgrade this decoder, it is possible to use the high 4-bit of the first
  * element for versioning, because it is guaraneed to be zero for the current version.
  */
  function decodePath(bytes memory body) external pure override returns (bytes memory) {
    bytes memory ret;
    uint16 i;
    uint16 length = (uint16(body.length) * 2)/ 3;
    for (i = 0; i < length; i++) {
      // unpack 12-bit middle endian
      uint16 offset = i / 2 * 3;
      uint8 low;
      uint8 high;
      if (i % 2 == 0) {
        low = uint8(body[offset]);
        high = uint8(body[offset + 1]) % 0x10; // low 4 bits of middle byte
      } else {
        low = uint8(body[offset + 2]);
        high = uint8(body[offset + 1]) / 0x10; // high 4 bits of middle byte
      }
      if (high == 0) {
        // SVG command: Accept only [A-Za-z] and ignore others 
        if ((low >=65 && low<=90) || (low >= 97 && low <= 122)) {
          ret = abi.encodePacked(ret, low);
        }
      } else {
        // SVG value: undo (value + 1024) + 0x100 
        uint16 value = uint16(high) * 0x100 + uint16(low) - 0x100;
        if (value >= 1024) {
          ret = abi.encodePacked(ret, (value - 1024).toString(), " ");
        } else {
          ret = abi.encodePacked(ret, "-", (1024 - value).toString(), " ");
        }
      }
    }
    return ret;
  }
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

pragma solidity ^0.8.6;

interface IPathDecoder {
  function decodePath(bytes memory body) external pure returns (bytes memory);
}