// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/Helpers.sol";
import "./Interfaces/ITraits.sol";
import "./Interfaces/IMetacity.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  string public baseURI;

  string public description = 'OUR CITY NEVER SLEEPS. NOR DO YOU! EARN $CITY COINS, PAY TAXES, BEWARE OF RATS.';

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    uint256 power;
  }

  // mapping from trait type (index) to its name
  string[] public zenTraitTypes;

  // mapping from trait type (index) to its name
  string[] public ratTraitTypes;

  // list of probabilities for each trait type
  uint256[][256] public rarities;
  // list of aliases for Walker's Alias algorithm
  uint256[][256] public aliases;

  // storage of each zen traits name and power
  mapping(uint256 => mapping(uint256 => Trait)) public zenTraitData;
  // storage of each rat traits name and power
  mapping(uint256 => mapping(uint256 => Trait)) public ratTraitData;

  IMetacity public metacity;

  constructor() {}

  /** ADMIN */

  function setMetacity(address _metacity) external onlyOwner {
    metacity = IMetacity(_metacity);
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setDescription(string memory _description) external onlyOwner {
    description = _description;
  }

  function setZenTraitTypes(string[] memory _zenTraitTypes) external onlyOwner {
    zenTraitTypes = _zenTraitTypes;
  }

  function setRatTraitTypes(string[] memory _ratTraitTypes) external onlyOwner {
    ratTraitTypes = _ratTraitTypes;
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitTypeIdx the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and cid hash for each trait
   */
  function addZenTraits(uint256 traitTypeIdx, uint256[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    require(bytes(zenTraitTypes[traitTypeIdx]).length > 0, "Trait does not exists");
    for (uint i = 0; i < traits.length; i++) {
      zenTraitData[traitTypeIdx][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].power
      );
    }
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitTypeIdx the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and cid hash for each trait
   */
  function addRatTraits(uint256 traitTypeIdx, uint256[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    require(bytes(ratTraitTypes[traitTypeIdx]).length > 0, "Trait does not exists");
    for (uint i = 0; i < traits.length; i++) {
      ratTraitData[traitTypeIdx][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].power
      );
    }
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param _rarities the trait type to upload the traits for (see traitTypes for a mapping)
   * @param _aliases the names and cid hash for each trait
   */
  function addRarities(uint256 rarityIdx, uint256[] calldata _rarities, uint256[] calldata _aliases) external onlyOwner {
    require(rarities.length == aliases.length, "Mismatched inputs");
    require(rarityIdx < zenTraitTypes.length + ratTraitTypes.length, "Trait does not exists");
    rarities[rarityIdx] = _rarities;
    aliases[rarityIdx] = _aliases;
  }

  // rarity on mint
  /**
   * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
   * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
   * probability & alias tables are generated off-chain beforehand
   * @param seed portion of the 256 bit seed to remove trait correlation
   * @param rarityIdx the trait type to select a trait for 
   * @return the ID of the randomly selected trait
   */
  function selectTrait(uint16 seed, uint256 rarityIdx) internal view returns (uint256) {
    uint256 trait = uint256(seed) % uint256(rarities[rarityIdx].length);
    if (seed >> 8 < rarities[rarityIdx][trait]) return trait;
    return aliases[rarityIdx][trait];
  }

  /**
   * selects the species and all of its traits based on the seed value
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @param _isZen a boolean for metacity / rat
   * @return t -  a struct of randomly selected traits
   */
  function selectTraits(uint256 seed, bool _isZen) public view override returns (uint256[] memory) {
    uint256[] memory t = new uint256[](_isZen ? zenTraitTypes.length : ratTraitTypes.length);
    if (_isZen) {
      for (uint i = 0; i < zenTraitTypes.length; i++) {
        seed >>= 16;
        t[i] = selectTrait(uint16(seed & 0xFFFF), uint256(i));
      }
    } else {
      for (uint i = 0; i < ratTraitTypes.length; i++) {
        seed >>= 16;
        t[i] = selectTrait(uint16(seed & 0xFFFF), uint256(i + zenTraitTypes.length));
      }
    }
    return t;
  }

  function level(uint256 tokenId) public view override returns (uint256) {
    uint256[] memory _tokenTraits = metacity.getTokenTraits(tokenId);
    bool _isZen = metacity.isZen(tokenId);
    uint256 _level = 0;
    for (uint i = 0; i < _tokenTraits.length; i++) {
      _level += _isZen ? zenTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].power : ratTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].power;
    }
    return _level;
  }

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  /**
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    uint256[] memory _tokenTraits = metacity.getTokenTraits(tokenId);
    string memory traits;
    bool _isZen = metacity.isZen(tokenId);
    for (uint i = 0; i < _tokenTraits.length; i++) {
      if (_isZen) {
        traits = string(abi.encodePacked(
          traits,
          attributeForTypeAndValue(zenTraitTypes[i], zenTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].name),
          ','
        ));
      } else {
        traits = string(abi.encodePacked(
          traits,
          attributeForTypeAndValue(ratTraitTypes[i], ratTraitData[uint256(i)][uint256(_tokenTraits[uint256(i)])].name),
          ','
        ));
      }
    }
    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Type","value":',
      _isZen ? '"Zen"' : '"Rat"',
      '},{"trait_type":"Level","value":"',
      level(tokenId).toString(),
      '"}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    bool _isZen = metacity.isZen(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      _isZen ? 'Zen #' : 'Rat #',
      tokenId.toString(),
      '", "description": "',
      description,
      '",',
      '"image": "',
      baseURI,
      tokenId.toString(),
      '",',
      '"attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      Helpers.base64(bytes(metadata))
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Helpers {
  /// @dev generates a pseudorandom number
  /// @param seed a value ensure different outcomes for different sources in the same block
  /// @return a pseudorandom value
  function random(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.difficulty,
      block.timestamp,
      seed
    )));
  }

  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }

}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITraits {
  function selectTraits(uint256 seed, bool _isZen) external view returns (uint256[] memory t);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function level(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IMetacity {
  function getTokenTraits(uint256 tokenId) external view returns (uint256[] memory);
  function isZen(uint256 tokenId) external view returns (bool);
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