// SPDX-License-Identifier: MIT

/*
 * On-chain asset store, which allows multiple smart contracts to shara vector assets.
 *
 * All assets registered to this store will be treated as cc0 (public domain), 
 * CC-BY(attribution), Apache 2.0 or MIT (should be specified in the "group"). 
 * In case of CC-BY, the creater's name should be in the "group", "category" or "name".
 *
 * All registered assets will be available to other smart contracts for free, including
 * commecial services. Therefore, it is not allowed to register assets that require
 * any form of commercial licenses. 
 *
 * Once an asset is registed with group/category/name, it is NOT possible to update,
 * which guaranttees the availability in future.  
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
    uint16 width;
    uint16 height;
    string name;
    string minter;
    address soulbound;
    uint256[] partsIds;
  }

  // Upgradable string validator
  IStringValidator validator;

  // Upgradable path decoder
  IPathDecoder decoder;

  // asset & part database
  mapping(uint256 => Asset) private assets;
  uint256 private nextAssetIndex = 1; // 0 indicates an error
  mapping(uint256 => Part) private parts;
  uint256 private nextPartIndex = 1; // 0 indicates an error

  // Groups and categories(for browsing)
  StringSet.Set internal groupSet;
  mapping(string => StringSet.Set) internal categorySets;
  
  // Grouped and categorized assetIds (for browsing)
  mapping(string => mapping(string => mapping(uint32 => uint256))) internal assetIdsInCategory;
  mapping(string => mapping(string => uint32)) internal nextAssetIndecesInCategory;

  // Group/Category/Name => assetId
  mapping(string => mapping(string => mapping(string => uint256))) internal assetIdsLookup;

  constructor() {
    validator = new StringValidator(); // default validator
    decoder = new SVGPathDecoder(); // default decoder
  }

  // Returns the groupId of the specified group, creating a new Id if necessary.
  // @notice gruopId == groupIndex + 1
  function _getGroupId(string memory group) private returns(uint32) {
    return groupSet.getId(group, validator);
  }

  // Returns the categoryId of the specified category in a group, creating a new Id if necessary.
  // The categoryId is unique only within that group. 
  // @notice categoryId == categoryIndex + 1
  function _getCategoryId(string memory group, string memory category) private returns(uint32) {
    return categorySets[group].getId(category, validator);
  }

  // Register a Part and returns its id, which is its index in parts[].
  function _registerPart(Part memory _part) private returns(uint256) {
    parts[nextPartIndex++] = _part;
    return nextPartIndex-1;    
  }

  // Validator
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

  // Register an Asset and returns its id, which is its index in assests[].
  function _registerAsset(AssetInfo memory _assetInfo) internal validateAsset(_assetInfo) returns(uint256) {
    require(assetIdsLookup[_assetInfo.group][_assetInfo.category][_assetInfo.name] == 0, "Asset already exists with the same group, category and name");
    uint size = _assetInfo.parts.length;
    uint256[] memory partsIds = new uint256[](size);
    uint i;
    for (i=0; i<size; i++) {
      partsIds[i] = _registerPart(_assetInfo.parts[i]);
    }
    uint256 assetId = nextAssetIndex++;
    Asset memory asset;
    asset.name = _assetInfo.name;
    asset.soulbound = _assetInfo.soulbound;
    asset.minter = _assetInfo.minter;
    asset.width = _assetInfo.width;
    asset.height = _assetInfo.height;
    asset.groupId = _getGroupId(_assetInfo.group);
    asset.categoryId = _getCategoryId(_assetInfo.group, _assetInfo.category);
    asset.partsIds = partsIds;
    assets[assetId] = asset;
    assetIdsInCategory[_assetInfo.group][_assetInfo.category][nextAssetIndecesInCategory[_assetInfo.group][_assetInfo.category]++] = assetId;
    assetIdsLookup[_assetInfo.group][_assetInfo.category][_assetInfo.name] = assetId;

    emit AssetRegistered(msg.sender, assetId);
    return assetId;
  }

  // Returns the number of registered assets
  function getAssetCount() external view onlyOwner returns(uint256) {
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

  // It allows us to keep the assets private. 
  function _getAsset(uint256 _assetId) internal view assetExists(_assetId) returns(Asset memory) {
    return assets[_assetId];
  }

  // It allows us to keep the parts private. 
  function _getPart(uint256 _partId) internal view partExists(_partId) returns(Part memory) {
    return parts[_partId];
  }
}

/*
 * Abstract contract that implements various adminstrative functions, such as
 * managing the whitelist, disable/enable assets and accessing the raw data.
 */
abstract contract AssetStoreAdmin is AssetStoreCore {
  constructor() {
    whitelist[msg.sender] = true;
  }

  // Whitelist
  mapping(address => bool) whitelist;
  bool disableWhitelist = false;

  // Disabled (just in case...)
  mapping(uint256 => bool) disabled;

  function setWhitelistStatus(address _address, bool _status) external onlyOwner {
    whitelist[_address] = _status;
  }

  function setDisabled(uint256 _assetId, bool _status) external assetExists(_assetId) onlyOwner {
    disabled[_assetId] = _status;
  }

  function setDisableWhitelist(bool _disable) external onlyOwner {
    disableWhitelist = _disable;
  } 

  function setValidator(IStringValidator _validator) external onlyOwner {
    validator = _validator;
  }

  function setPathDecoder(IPathDecoder _decoder) external onlyOwner {
    decoder = _decoder;
  }

  // returns the raw asset data speicified by the assetId (1, ..., count)
  function getRawAsset(uint256 _assetId) external view onlyOwner returns(Asset memory) {
    return _getAsset(_assetId);
  }

  // returns the raw part data specified by the assetId (1, ... count)
  function getRawPart(uint256 _partId) external view onlyOwner returns(Part memory) {
    return _getPart(_partId);
  }
}

/*
 * Concreate contract that implements IAssetStoreRegistory
 * We will never deploy this contract. 
 */
contract AppStoreRegistory is AssetStoreAdmin {
  modifier onlyWhitelist {
    require(disableWhitelist || whitelist[msg.sender], "AssetStore: Tjhe sender must be in the white list.");
    _;
  }
   
  function registerAsset(AssetInfo memory _assetInfo) external override onlyWhitelist returns(uint256) {
    return _registerAsset(_assetInfo);
  }

  function registerAssets(AssetInfo[] memory _assetInfos) external override onlyWhitelist returns(uint256) {
    uint i;
    uint assetIndex;
    for (i=0; i<_assetInfos.length; i++) {
      assetIndex = _registerAsset(_assetInfos[i]);
    }
    return assetIndex;
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
    return groupSet.nextIndex;
  }

  // Returns the name of a group specified with groupIndex (groupId - 1). 
  function getGroupNameAtIndex(uint32 _groupIndex) external view override returns(string memory) {
    return groupSet.nameAtIndex(_groupIndex);
  }

  // Returns the number of categories in the specified group.
  function getCategoryCount(string memory group) external view override returns(uint32) {
    return categorySets[group].nextIndex;
  }

  // Returns the name of category specified with group/categoryIndex pair.
  function getCategoryNameAtIndex(string memory _group, uint32 _categoryIndex) external view override returns(string memory) {
    return categorySets[_group].nameAtIndex(_categoryIndex);
  }

  // Returns the number of asset in the specified group/category. 
  function getAssetCountInCategory(string memory group, string memory category) external view override returns(uint32) {
    return nextAssetIndecesInCategory[group][category];
  }

  // Returns the assetId of the specified group/category/assetIndex. 
  function getAssetIdInCategory(string memory group, string memory category, uint32 assetIndex) external view override returns(uint256) {
    require(assetIndex < nextAssetIndecesInCategory[group][category], "The assetIndex is out of range");
    return assetIdsInCategory[group][category][assetIndex];
  }

  // Returns the assetId of the specified group/category/name. 
  function getAssetIdWithName(string memory group, string memory category, string memory name) external override view returns(uint256) {
    return assetIdsLookup[group][category][name];
  }

  function _getDescription(Asset memory asset) internal view returns(bytes memory) {
    string memory group = groupSet.nameAtIndex(asset.groupId - 1);
    return abi.encodePacked(group, '/', categorySets[group].nameAtIndex(asset.categoryId - 1), '/', asset.name);
  }

  function _safeGenerateSVGPart(uint256 _assetId) internal view returns(bytes memory) {
    Asset memory asset = _getAsset(_assetId);
    uint256[] memory indeces = asset.partsIds;
    bytes memory pack = abi.encodePacked(' <g id="asset', _assetId.toString(), '" desc="', _getDescription(asset), '">\n');
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
  function generateSVGPart(uint256 _assetId) external override view enabled(_assetId) returns(string memory) {
    return string(_safeGenerateSVGPart(_assetId));
  }

  // returns a full SVG with the specified asset
  function generateSVG(uint256 _assetId) external override view enabled(_assetId) returns(string memory) {
    Asset memory asset = _getAsset(_assetId);
    bytes memory pack = abi.encodePacked(
      '<svg viewBox="0 0 ', (asset.width).toString(), ' ', (asset.height).toString(), '" xmlns="http://www.w3.org/2000/svg">\n', 
      _safeGenerateSVGPart(_assetId), 
      '</svg>');
    return string(pack);
  }

  // returns the attributes of the specified asset
  function getAttributes(uint256 _assetId) external view override returns(AssetAttributes memory) {
    Asset memory asset = _getAsset(_assetId);
    AssetAttributes memory attr;
    attr.name = asset.name;
    attr.soulbound = asset.soulbound;
    attr.minter = asset.minter;
    attr.group = groupSet.nameAtIndex(asset.groupId - 1);
    attr.category = categorySets[attr.group].nameAtIndex(asset.categoryId - 1);
    attr.width = asset.width;
    attr.height = asset.height;
    return attr;
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

// IAssetStore is the inteface for consumers of the AsseStore.
interface IAssetStore {
  // Browsing
  function getGroupCount() external view returns(uint32);
  function getGroupNameAtIndex(uint32 groupIndex) external view returns(string memory);
  function getCategoryCount(string memory group) external view returns(uint32);
  function getCategoryNameAtIndex(string memory group, uint32 categoryIndex) external view returns(string memory);
  function getAssetCountInCategory(string memory group, string memory category) external view returns(uint32);
  function getAssetIdInCategory(string memory group, string memory category, uint32 assetIndex) external view returns(uint256);
  function getAssetIdWithName(string memory group, string memory category, string memory name) external view returns(uint256);

  // Fetching
  struct AssetAttributes {
    string group;
    string category;
    string name;
    string minter;
    address soulbound;
    uint16 width;
    uint16 height;
  }

  function generateSVG(uint256 _assetId) external view returns(string memory);
  function generateSVGPart(uint256 _assetId) external view returns(string memory);
  function getAttributes(uint256 _assetId) external view returns(AssetAttributes memory);
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
    string minter;
    address soulbound;
    uint16 width;
    uint16 height;
    Part[] parts;
  }

  event AssetRegistered(address indexed from, uint256 indexed assetId);

  function registerAsset(AssetInfo memory _assetInfo) external returns(uint256);
  function registerAssets(AssetInfo[] memory _assetInfos) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStringValidator {
  function validate(bytes memory str) external returns (bool);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { IStringValidator } from '../interfaces/IStringValidator.sol';

library StringSet {
  struct Set {
    mapping(uint32 => string) names;
    uint32 nextIndex;
    mapping(string => uint32) ids; // index+1
  }

  function getId(Set storage set, string memory name, IStringValidator validator) internal returns(uint32) {
    uint32 id = set.ids[name];
    if (id == 0) {
      require(validator.validate(bytes(name)), "StringSet.getId: Invalid String");
      set.names[set.nextIndex++] = name;
      id = set.nextIndex; // idex + 1
      set.ids[name] = id; 
    }
    return id;
  }

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