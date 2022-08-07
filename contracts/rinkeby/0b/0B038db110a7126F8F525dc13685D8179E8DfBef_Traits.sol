// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITraits.sol";
import "./IDuck.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  string baseTokenImageUri;
  string unrevealedTokenUri;

  string[19] _characterTypes = [
    "Duck",
    "Male1",
    "Male2",
    "Male3",
    "Male4",
    "Male5",
    "Male6",
    "Male7",
    "Male8",
    "Male9",
    "Female1",
    "Female2",
    "Female3",
    "Female4",
    "Female5",
    "Female6",
    "Female7",
    "Female8",
    "Female9"
  ];

  string[][19] _traitTypes;

  // storage of each traits name
  mapping(uint8 => mapping(uint8 => string))[19] public traitData;
  mapping(uint8 =>string) public backgrounds; 

  // mapping from alphaIndex to its score
  string[4] _alphas = [
    "8",
    "7",
    "6",
    "5"
  ];

  IDuck public duck;

  constructor() {}

  /** ADMIN */

  function setDuck(address _duck) external onlyOwner {
    duck = IDuck(_duck);
  }

  /**
   * set the uri of a token for where to get it's image from
   * @param baseImageUri the base token image uri
   * @param unrevealedUri the unrevealed token uri
   */
  function setTokenUris(string calldata baseImageUri, string calldata unrevealedUri) external onlyOwner {
    baseTokenImageUri = baseImageUri;
    unrevealedTokenUri = unrevealedUri;
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitTypes the names of all traitTypes
   */
  function uploadTraitTypes(string[][19] calldata traitTypes) external onlyOwner {
    for(uint i = 0; i < 19; i++) {
      for(uint j = 0; j < traitTypes[i].length; j++) {
        _traitTypes[i].push(traitTypes[i][j]);
      }
    }
  }


  /**
   * administrative to upload the names and images associated with each trait
   * @param characterType the characterType type to upload the traits for, or 0 for duck types
   * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and base64 encoded PNGs for each trait
   */
  function uploadTraits(uint8 characterType, uint8 traitType, string[] calldata traits) external onlyOwner {
    for (uint8 i = 0; i < traits.length; i++) {
      traitData[characterType][traitType][i] = traits[i];
    }
  }

  /**
  * Upload backgrounds of the images (only owner of the contract can do this)
  * @param _backgrounds the backgrounds of the images
  */
  function uploadBackgrounds(string[] calldata _backgrounds) external onlyOwner {
    for (uint8 i = 0; i < _backgrounds.length; i++) {
    backgrounds[i] = _backgrounds[i];
    }
  }
  /** RENDER */


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
      '"},'
    ));
  }

  /**
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    IDuck.DuckHunter memory d = duck.getTokenTraits(tokenId);
    string memory traits = attributeForTypeAndValue("Background", backgrounds[d.background]);
    
    for(uint8 i = 0; i < d.traits.length; i++) {
      if(d.traits[i] != 0) {
        traits = string(abi.encodePacked(
          traits,
          attributeForTypeAndValue(_traitTypes[d.characterType][i], traitData[d.characterType][i][d.traits[i]-1])
        ));
      }
    }
    if (d.characterType > 0) {
      traits = string(abi.encodePacked(
        traits,
        attributeForTypeAndValue("Hunter Type", _characterTypes[d.characterType])
      ));
    } else {
      traits = string(abi.encodePacked(
        traits,
        attributeForTypeAndValue("Alpha Score", _alphas[d.alphaIndex])
      ));
    }
    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Generation","value":',
      tokenId <= duck.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
      '},{"trait_type":"Type","value":',
      d.characterType > 0 ? '"Hunter"' : '"Duck"',
      '}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    IDuck.DuckHunter memory d = duck.getTokenTraits(tokenId);
    
    string memory metadata;

    if(block.timestamp - d.mintTime < 300) { // TODO: Change back to 3600 after beta-testing (less than a hour from mint)
      metadata = string(abi.encodePacked(
        '{"name": "Unrevealed Token #',
        tokenId.toString(),
        '", "description": "Thousands of Hunters and Ducks compete in the metaverse. A tempting prize of $EGG awaits, with deadly high stakes. All the metadata are generated and stored 100% on-chain. NO API. Just the Ethereum blockchain.",',
        ' "image": "',
        unrevealedTokenUri,
        '"}'
      ));
    } else {
      metadata = string(abi.encodePacked(
        '{"name": "',
        d.characterType > 0 ? 'Hunter #' : 'Duck #',
        tokenId.toString(),
        '", "description": "Thousands of Hunters and Ducks compete in the metaverse. A tempting prize of $EGG awaits, with deadly high stakes. All the metadata are generated and stored 100% on-chain. NO API. Just the Ethereum blockchain.",',
        ' "image": "',
        baseTokenImageUri,
        base64(getTokenInfo(tokenId, d)),
        '", "attributes":',
        compileAttributes(tokenId),
        "}"
      ));
    }
    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  /**
  * Generate token info for a token ID
  * @param tokenId the token ID to get the token info for
  * @param d the struct of the token's traits
  * @return tokenInfo the token info for the given token ID
  */
  function getTokenInfo(uint256 tokenId, IDuck.DuckHunter memory d) private pure returns (bytes memory tokenInfo) {
    return abi.encodePacked(
          tokenId,
          d.characterType,
          d.background,
          d.traits[0],
          d.traits[1],
          d.traits[2],
          d.traits[3],
          d.traits[4],
          d.traits[5],
          d.traits[6],
          d.traits[7],
          d.traits[8],
          d.traits[9],
          d.alphaIndex
        );
  }

  /** BASE 64 - Written by Brech Devos */
  
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

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IDuck {

  // struct to store each token's traits
struct DuckHunter {
    uint8 characterType;
    uint8 background;
    uint8[10] traits;
    uint8 alphaIndex;

    uint48 mintTime;
  }


  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (DuckHunter memory);
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