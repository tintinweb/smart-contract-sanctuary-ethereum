/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// File: contracts/IChicken.sol


pragma solidity ^0.8.0;

interface IChicken {

  // struct to store each token's traits
  
  struct Chicken {
      uint8 comb;
      uint8 face;
      uint8 body;
      // Colors - Primary, Secondary, Tertiary
      uint8 color1;
      uint8 color2;
      uint8 color3;
      uint8 fatness;
      uint8 lvlFatness;
      uint16 level;
  }

  function getTokenTraits(uint256 tokenId) external view returns (Chicken memory);
  function godChicken(uint256 tokenId) external view returns (bool);
}
// File: contracts/ITraits.sol


pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: contracts/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/ChickenTraits.sol


pragma solidity ^0.8.0;





contract ChickenTraits is Ownable, ITraits {

  using Strings for uint256;

  string[] traitTypes = ['comb', 'face', 'body', 'color', 'fatness'];

  // storage of each traits name
  // trait1 => [name1, name2, ...]
  mapping(uint8 => mapping(uint8 => string)) public traitNames;

  // trait1 => id1 => trait2 => id2 => address
  // ex:
  //   0 => address : comb => CombContract
  mapping(uint8 => address) public traitSvgs;

  IChicken public chickens;

  constructor() {
    // comb
    string[12] memory combs = ["Short", "Bald", "Spike", "Forward", "Back", "Slick", "Wavy", "Horned", "Brush", "Fuax Hawk", "Crown", "Feather"];
    for (uint8 i = 0; i < combs.length; i++) {
      traitNames[0][i] = combs[i];  
    }
    // face
    string[12] memory faces = ["Calm", "Sus", "Cry", "Star", "Happy", "Sleeping", "Wink", "Dumb", "Angry", "Surprised", "Love", "Content"];
    for (uint8 i = 0; i < faces.length; i++) {
      traitNames[1][i] = faces[i];  
    }
    // body
    string[12] memory bodies = ["Wattle", "Curl", "Double Wattle", "Swole", "Fancy", "Tuft", "Fuzzy", "Open Wing", "Beard", "Mane", "Bare", "Chesthair"];
    for (uint8 i = 0; i < bodies.length; i++) {
      traitNames[2][i] = bodies[i];  
    }
    // color1
    string[20] memory colors1 = ["Warm Red", "Burning Orange", "Saffron", "Marigold", "Banana", "Lime", "Grass", "Aquamarine", "Turquoise", "Sky Blue", "Purple", "Orchid", "Pink", "Rose", "Light Brown", "Brown", "Light Gray", "Gray", "Dark Gray", "White"];
    for (uint8 i = 0; i < colors1.length; i++) {
      traitNames[3][i] = colors1[i];  
      // traitNames[4][i] = colors1[i];  
      // traitNames[5][i] = colors1[i];  
    }
    // fatness
    string[5] memory fatness = ["Skinny", "Average", "Husky", "Fat", "Chonky"];
    for (uint8 i = 0; i < fatness.length; i++) {
      traitNames[6][i] = fatness[i];  
    }
  }

  /** ADMIN */

  function setChicken(address _addr) external onlyOwner {
    chickens = IChicken(_addr);
  }

  /**
   * administrative to upload the names associated with each trait
   */
  function uploadTraitNames(uint8 trait, uint8[] calldata traitIds, string[] calldata names) external onlyOwner {
    require(traitIds.length == names.length, "Mismatched inputs");
    for (uint256 index = 0; index < traitIds.length; index++) {
      traitNames[trait][traitIds[index]] = names[index];
    }
  }

  function uploadTraitSvgs(uint8 trait1, address source) external onlyOwner {
      traitSvgs[trait1] = source; 
  }

  /*///////////////////////////////////////////////////////////////
                  INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function call(address source, bytes memory sig) internal view returns (string memory svg) {
      (bool succ, bytes memory ret)  = source.staticcall(sig);
      require(succ, "failed to get data");
      svg = abi.decode(ret, (string));
  }

  function getSvg(uint8 traitType, uint8 id) internal view returns (string memory data_) {
      address source = traitSvgs[traitType];
      data_ = call(source, getData(traitType, id));
  }

  function getData(uint8 trait1, uint8 id1) internal view returns (bytes memory data) {
    string memory s = string(abi.encodePacked(
          traitTypes[trait1], '_',toString(id1),
          "()"
      ));
    return abi.encodeWithSignature(s, "");
  }

  function drawSVG(uint256 tokenId) public view returns (string memory) {
    IChicken.Chicken memory s = chickens.getTokenTraits(tokenId);

    return string(abi.encodePacked(
      string(abi.encodePacked(
        '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="#121212"/> <style> .p{fill:',
        getSvg(3, s.color1), ';} .s{fill:', getSvg(3, s.color2), ';} .t{fill:', getSvg(3, s.color3),
        ';} </style> <text x="130" y="130" font-family="Arial,monospace" font-size="20" font-weight="500" letter-spacing="0"> '
      )),
      string(abi.encodePacked(
        getSvg(0, s.comb),
        ' <tspan dy="20" x="125" class="s"> ',
        getSvg(1, s.face), ' </tspan> <tspan dy="24" x="130" class="s"> ',
        getSvg(2, s.body), ' </tspan> <tspan dy="24" x="135" class="t">-\'--\'-</tspan> </text> </svg>'
      ))
    ));
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
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    IChicken.Chicken memory s = chickens.getTokenTraits(tokenId);

    string memory traits1 = string(abi.encodePacked(
      attributeForTypeAndValue("Comb", traitNames[0][s.comb]),',',
      attributeForTypeAndValue("Face", traitNames[1][s.face]),',',
      attributeForTypeAndValue("Body", traitNames[2][s.body]),',',
      attributeForTypeAndValue("Primary Color", traitNames[3][s.color1]),','
    ));
    string memory traits2 = string(abi.encodePacked(
      attributeForTypeAndValue("Secondary Color", traitNames[3][s.color2]),',',
      attributeForTypeAndValue("Tertiary Color", traitNames[3][s.color3]),',',
      attributeForTypeAndValue("Fatness", traitNames[6][s.fatness]),',',
      attributeForTypeAndValue("Fatness Level", toString(s.lvlFatness)),',',
      attributeForTypeAndValue("Chicken Level", toString(s.level))
    ));
    return string(abi.encodePacked(
      '[',
      traits1, traits2,
      ']'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "Chickens #',
      tokenId.toString(),
      '", "description": "100% on-chain", "image": "data:image/svg+xml;base64,',
      base64(bytes(drawSVG(tokenId))),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
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