/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: MIT
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

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDrawSvg {
  function drawSvg(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
  function drawSvgNew(
    string memory svgBreedColor, string memory svgBreedHead, string memory svgOffhand, string memory svgArmor, string memory svgMainhand
  ) external view returns (string memory);
}

interface INameChange {
  function changeName(address owner, uint256 id, string memory newName) external;
}

interface IDogewood {
    // struct to store each token's traits
    struct Doge2 {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
        uint16 breedRerollCount;
        uint16 classRerollCount;
        uint8 artStyle; // 0: new, 1: old
    }

    function getTokenTraits(uint256 tokenId) external view returns (Doge2 memory);
    function getGenesisSupply() external view returns (uint256);
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level, uint16 breedRerollCount, uint16 classRerollCount, uint8 artStyle) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

// interface DogeLike {
//     function pull(address owner, uint256[] calldata ids) external;
//     function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
//     function transfer(address to, uint256 tokenId) external;
//     function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

// interface DogewoodLike {
//     function ownerOf(uint256 id) external view returns (address owner_);
//     function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
//     function doges(uint256 dogeId) external view returns (uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

// import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
contract Traits is ITraits {

  using Strings for uint256;

  address implementation_;
  address public admin;

  mapping (uint8=>string) public traitTypes;

  // storage of each traits name
  // trait1 => [name1, name2, ...]
  mapping(uint8 => mapping(uint8 => string)) public traitNames;

  // trait1 => id1 => trait2 => id2 => address
  // ex:
  //   breed => 0 => head => 0 => breedHeas
  //   class => {armor | offhand | mainhand} => value => address
  mapping(uint8 => mapping(uint8 => mapping(uint8 => mapping(uint8 => address)))) public traitSvgs;

  IDogewood public dogewood;
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  // trait1 => id1 => trait2 => id2 => address
  // ex:
  //   breed => 0 => head => 0 => breedHeas
  //   class => {armor | offhand | mainhand} => value => address
  mapping(uint8 => mapping(uint8 => mapping(uint8 => mapping(uint8 => address)))) public traitSvgsNew;
  
  // gearType => value => traitName
  //    gearType: (0: armor, 1: offhand, 2: mainhand)
  // ex: 0 => 0 => "Training Half Plate": (Armor 0 value - Training Half Plate)
  mapping(uint8 => mapping(uint8 => string)) public gearNames;

  // draw contract address (Note: we separate this to reduce contract size)
  IDrawSvg drawContract;

  /*///////////////////////////////////////////////////////////////
                  End of data
  //////////////////////////////////////////////////////////////*/

  function initialize() external onlyOwner {
    require(msg.sender == admin);

    string[8] memory traitTypes_ = ['head', 'breed', 'color', 'class', 'armor', 'offhand', 'mainhand', 'level'];
    for (uint8 i = 0; i < traitTypes_.length; i++) {
      traitTypes[i] = traitTypes_[i];  
    }

    // head
    string[9] memory heads = ["Determined", "High", "Happy", "Determined Tongue", "High Tongue", "Happy Tongue", "Determined Open", "High Open", "Happy Open"];
    for (uint8 i = 0; i < heads.length; i++) {
      traitNames[0][i] = heads[i];  
    }
    // bread
    string[8] memory breads = ["Shiba", "Pug", "Corgi", "Labrador", "Dachshund", "Poodle", "Pitbull", "Bulldog"];
    for (uint8 i = 0; i < breads.length; i++) {
      traitNames[1][i] = breads[i];  
    }
    // color
    string[6] memory colors = ["Palette 1", "Palette 2", "Palette 3", "Palette 4", "Palette 5", "Palette 6"];
    for (uint8 i = 0; i < colors.length; i++) {
      traitNames[2][i] = colors[i];  
    }
    // class
    string[8] memory classes = ["Warrior", "Rogue", "Mage", "Hunter", "Cleric", "Bard", "Merchant", "Forager"];
    for (uint8 i = 0; i < classes.length; i++) {
      traitNames[3][i] = classes[i];  
    }

    // gear names
    gearNames[0][0] = 'Training Half Plate'; // Armor 0 value - Training Half Plate
    gearNames[2][0] = 'Training Sword'; // mainhand 0 value - Training Sword
  }

  modifier onlyOwner() {
      require(msg.sender == admin);
      _;
  }

  /** ADMIN */

  function setDogewood(address _dogewood) external onlyOwner {
    dogewood = IDogewood(_dogewood);
  }

  function setDrawContract(address drawContract_) external onlyOwner {
    drawContract = IDrawSvg(drawContract_);
  }

  function setTraitTypes(uint8 id, string memory value) external onlyOwner {
    traitTypes[id] = value;
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

  function uploadGearNames(uint8 gearType, uint8[] calldata values, string[] calldata names) external onlyOwner {
    require(values.length == names.length, "Mismatched inputs");
    for (uint256 index = 0; index < values.length; index++) {
      gearNames[gearType][values[index]] = names[index];
    }
  }

  function uploadTraitSvgs(uint8 trait1, uint8 id1, uint8 trait2, uint8[] calldata trait2Ids, address source) external onlyOwner {
    for (uint256 index = 0; index < trait2Ids.length; index++) {
        traitSvgs[trait1][id1][trait2][trait2Ids[index]] = source; 
    }
  }

  function uploadTraitSvgsNew(uint8 trait1, uint8 id1, uint8 trait2, uint8[] calldata trait2Ids, address source) external onlyOwner {
    for (uint256 index = 0; index < trait2Ids.length; index++) {
        traitSvgsNew[trait1][id1][trait2][trait2Ids[index]] = source; 
    }
  }

  /*///////////////////////////////////////////////////////////////
                  INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function call(address source, bytes memory sig) internal view returns (string memory svg) {
      (bool succ, bytes memory ret)  = source.staticcall(sig);
      require(succ, "failed to get data");
      svg = abi.decode(ret, (string));
  }

  function getSvg(uint8 trait1, uint8 id1, uint8 trait2, uint8 id2) internal view returns (string memory data_) {
      address source = traitSvgs[trait1][id1][trait2][id2];
      data_ = call(source, getData(trait1, id1, trait2, id2));
  }

  function getSvgNew(uint8 trait1, uint8 id1, uint8 trait2, uint8 id2) internal view returns (string memory data_) {
      address source = traitSvgsNew[trait1][id1][trait2][id2];
      data_ = call(source, getData(trait1, id1, trait2, id2));
  }

  function getData(uint8 trait1, uint8 id1, uint8 trait2, uint8 id2) internal view returns (bytes memory data) {
    string memory s = string(abi.encodePacked(
          traitTypes[trait1],toString(id1),
          traitTypes[trait2],toString(id2),
          "()"
      ));
    return abi.encodeWithSignature(s, "");
  }

  function drawSVG(uint256 tokenId) public view returns (string memory) {
    IDogewood.Doge2 memory s = dogewood.getTokenTraits(tokenId);

    return drawContract.drawSvg(
      getSvg(1, s.breed, 2, s.color), 
      getSvg(1, s.breed, 0, s.head), 
      getSvg(3, s.class, 5, s.offhand), 
      getSvg(3, s.class, 4, s.armor), 
      getSvg(3, s.class, 6, s.mainhand)
    );
  }

  function drawSVGNew(uint256 tokenId) public view returns (string memory) {
    IDogewood.Doge2 memory s = dogewood.getTokenTraits(tokenId);

    return drawContract.drawSvgNew(
      getSvgNew(1, s.breed, 2, s.color), 
      getSvgNew(1, s.breed, 0, s.head), 
      getSvgNew(3, s.class, 5, s.offhand), 
      getSvgNew(3, s.class, 4, s.armor), 
      getSvgNew(3, s.class, 6, s.mainhand)
    );
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
    IDogewood.Doge2 memory s = dogewood.getTokenTraits(tokenId);

    string memory traits1 = string(abi.encodePacked(
      attributeForTypeAndValue(traitTypes[0], traitNames[0][s.head]),',',
      attributeForTypeAndValue(traitTypes[1], traitNames[1][s.breed]),',',
      attributeForTypeAndValue(traitTypes[2], traitNames[2][s.color]),',',
      attributeForTypeAndValue(traitTypes[3], traitNames[3][s.class]),','
    ));
    string memory traits2 = string(abi.encodePacked(
      attributeForTypeAndValue(traitTypes[4], toString(s.armor)),',',
      // attributeForTypeAndValue(traitTypes[4], gearNames[0][s.armor]),',',
      attributeForTypeAndValue(traitTypes[5], toString(s.offhand)),',',
      attributeForTypeAndValue(traitTypes[6], toString(s.mainhand)),',',
      // attributeForTypeAndValue(traitTypes[6], gearNames[2][s.mainhand]),',',
      // attributeForTypeAndValue(traitTypes[7], toString(s.level)),','
      abi.encodePacked('{"trait_type":"',traitTypes[7],'","value":',toString(s.level),'},'),
      attributeForTypeAndValue('art', s.artStyle == 1 ? 'OG' : 'Standard'),','
    ));
    return string(abi.encodePacked(
      '[',
      traits1, traits2,
      '{"trait_type":"Generation","value":',
      tokenId <= dogewood.getGenesisSupply() ? '"Gen 0"' : '"Gen 1"',
      '},{"display_type":"number","trait_type":"Reroll Breed Count","value":', toString(s.breedRerollCount),
      '},{"display_type":"number","trait_type":"Reroll Class Count","value":', toString(s.classRerollCount),
      '}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    IDogewood.Doge2 memory s = dogewood.getTokenTraits(tokenId);
    string memory svgData = s.artStyle == 1 ? drawSVG(tokenId) : drawSVGNew(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "Dogewood #',
      tokenId.toString(),
      '", "description": "100% on-chain", "image": "data:image/svg+xml;base64,',
      base64(bytes(svgData)),
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