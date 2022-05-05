/**
 *Submitted for verification at Etherscan.io on 2022-05-05
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
  function tokenURINotRevealed(uint256 tokenId) external view returns (string memory);
  function tokenURITopTalents(uint8 topTalentNo, uint256 tokenId) external view returns (string memory);
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
    function validateOwnerOfDoge(uint256 id, address who_) external view returns (bool);
    function unstakeForQuest(address[] memory owners, uint256[] memory ids) external;
    function updateQuestCooldown(uint256[] memory doges, uint88 timestamp) external;
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level, uint16 breedRerollCount, uint16 classRerollCount, uint8 artStyle) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

interface IDogewoodForCommonerSale {
    function validateDogeOwnerForClaim(uint256 id, address who_) external view returns (bool);
}

interface ICastleForCommonerSale {
    function dogeOwner(uint256 id) external view returns (address);
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

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 value) external;
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

interface QuestLike {
    struct GroupConfig {
        uint16 lvlFrom;
        uint16 lvlTo;
        uint256 entryFee; // additional entry $TREAT
        uint256 initPrize; // init prize pool $TREAT
    }
    struct Action {
        uint256 id; // unique id to distinguish activities
        uint88 timestamp;
        uint256 doge;
        address owner;
        uint256 score;
        uint256 finalScore;
    }

    function doQuestByAdmin(uint256 doge, address owner, uint256 score, uint8 groupIndex, uint256 combatId) external;
}

interface IOracle {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface IVRF {
    function getRandom(uint256 seed) external returns (uint256);
    function getRandom(string memory seed) external returns (uint256);
    function getRand(uint256 nonce) external view returns (uint256);
    function getRange(uint min, uint max,uint nonce) external view returns(uint);
}

interface ICommoner {
    // struct to store each token's traits
    struct Commoner {
        uint8 head;
        uint8 breed;
        uint8 palette;
        uint8 bodyType;
        uint8 clothes;
        uint8 accessory;
        uint8 background;
        uint8 smithing;
        uint8 alchemy;
        uint8 cooking;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Commoner memory);
    function getGenesisSupply() external view returns (uint256);
    function validateOwner(uint256 id, address who_) external view returns (bool);
    function pull(address owner, uint256[] calldata ids) external;
    function adjust(uint256 id, uint8 head, uint8 breed, uint8 palette, uint8 bodyType, uint8 clothes, uint8 accessory, uint8 background, uint8 smithing, uint8 alchemy, uint8 cooking) external;
    function transfer(address to, uint256 tokenId) external;
}

// import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
contract TraitsCommoners is ITraits {

  using Strings for uint256;

  address implementation_;
  address public admin;

  bool public revealed;
  string public notRevealedUri;

  address[4] public sourceTopTalents; // top talents contract address

  /**
    trait types
    index => name
      ['head', 'breed', 'palette', 'bodyType', 'clothes', 'accessory', 'background', 'smithing', 'alchemy', 'cooking']
   */
  mapping (uint8=>string) public traitTypes;

  /**
    storage of each traits name
    trait1 => [name1, name2, ...]
      trait1:
        0: head
        1: breed
        2: palette
        3: bodyType
        4: clothes
        5: accessory A (hats A)
        6: accessory B (hats B)
        7: background
   */
  mapping(uint8 => mapping(uint8 => string)) public traitNames;

  /**
    trait1 => id1 => address
      trait1:
        0: background (background0)
        1: clothes A (clothes0a)
        2: clothes B (clothes0b)
        3: hats A (hat0a)
        4: hats B (hat0b)
   */
  mapping (uint8 => mapping(uint8 => address)) public traitSvgs1;

  /**
    trait1 => id1 => trait2 => id2 => address
      trait1:
        0: breed (breed0head0a)
      trait2:
        0: head A (breed0head0a)
        1: head B (breed0head0b)
        2: color (breed0color0)
   */
  mapping(uint8 => mapping(uint8 => mapping(uint8 => mapping(uint8 => address)))) public traitSvgs2;

  ICommoner public commoner;
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  
  /*///////////////////////////////////////////////////////////////
                  End of data
  //////////////////////////////////////////////////////////////*/

  function initialize() external onlyOwner {
    require(msg.sender == admin);

    string[10] memory traitTypes_ = ['head', 'breed', 'palette', 'bodyType', 'clothes', 'accessory', 'background', 'smithing', 'alchemy', 'cooking'];
    for (uint8 i = 0; i < traitTypes_.length; i++) {
      traitTypes[i] = traitTypes_[i];  
    }

    // // head
    // string[9] memory heads = ["Determined", "High", "Happy", "Determined Tongue", "High Tongue", "Happy Tongue", "Determined Open", "High Open", "Happy Open"];
    // for (uint8 i = 0; i < heads.length; i++) {
    //   traitNames[0][i] = heads[i];  
    // }
    // // bread
    // string[8] memory breeds = ["Shiba", "Pug", "Corgi", "Labrador", "Dachshund", "Poodle", "Pitbull", "Bulldog"];
    // for (uint8 i = 0; i < breeds.length; i++) {
    //   traitNames[1][i] = breeds[i];  
    // }
    // // palette
    // string[6] memory palettes = ["Palette 1", "Palette 2", "Palette 3", "Palette 4", "Palette 5", "Palette 6"];
    // for (uint8 i = 0; i < palettes.length; i++) {
    //   traitNames[2][i] = palettes[i];  
    // }
    // // bodyType
    // string[2] memory bodyTypes = ["A (Male)", "B (Female)"];
    // for (uint8 i = 0; i < bodyTypes.length; i++) {
    //   traitNames[3][i] = bodyTypes[i];  
    // }
    // // clothes
    // string[13] memory clothes = ["Worker Overalls", "Crafter Apron", "Jeweled Robes", "Leather Shawl", "Weaver Attire", 
    //   "Ceremonial Garments", "Peasant Shirt", "Spellcaster Robes", "Thief Rags", "Noble Cape", 
    //   "Performer Costume", "Jaunty Getup", "Traveler Garb"];
    // for (uint8 i = 0; i < clothes.length; i++) {
    //   traitNames[4][i] = clothes[i];  
    // }

    // // accessory - hats A
    // string[13] memory accessoryA = ["None", "Goggles", "Jeweled Cap", "Leather Tophat", "Weaver Tophat", 
    //   "Ceremonial Bone", "Peasant Cap", "Wizard Hat", "Thief Bycocket", "Noble Bowler", 
    //   "Costume Mask", "Jaunty Hat", "Traveler Beret"];
    // for (uint8 i = 0; i < accessoryA.length; i++) {
    //   traitNames[5][i] = accessoryA[i];  
    // }
    // // accessory - hats B
    // string[13] memory accessoryB = ["None", "Goggles", "Jeweler Glasses", "Leather Hat", "Weaver Tophat", 
    //   "Ceremonial Bone", "Bandana", "Witchy Hat", "Thief Hat", "Noble Bonnet", 
    //   "Costume Mask", "Jaunty Turban", "Traveler Bycocket"];
    // for (uint8 i = 0; i < accessoryB.length; i++) {
    //   traitNames[6][i] = accessoryB[i];  
    // }

    // // background
    // string[6] memory background = ["Day Forest", "Dogewood Village Square", "Night Forest", "Home", "Deep Forest", "Hearth"];
    // for (uint8 i = 0; i < background.length; i++) {
    //   traitNames[7][i] = background[i];  
    // }
  }

  modifier onlyOwner() {
      require(msg.sender == admin);
      _;
  }

  /** ADMIN */

  function setSourceTopTalents(address[4] memory source_) external onlyOwner {
    for (uint256 i = 0; i < 4; i++) {
      sourceTopTalents[i] = source_[i];
    }
  }

  function setNotRevealedUri(string memory uri_) external onlyOwner {
    notRevealedUri = uri_;
  }

  function setRevealed(bool revealed_) external onlyOwner {
    revealed = revealed_;
  }

  function setCommoner(address _commoner) external onlyOwner {
    commoner = ICommoner(_commoner);
  }

  function setTraitTypes(uint8[] memory ids_, string[] memory values_) external onlyOwner {
    require(ids_.length == values_.length);
    for (uint256 i = 0; i < ids_.length; i++) {
      traitTypes[ids_[i]] = values_[i];
    }
  }

  /**
   * administrative to upload the names associated with each trait
   */
  function setTraitNames(uint8 trait, uint8[] calldata traitIds, string[] calldata names) external onlyOwner {
    require(traitIds.length == names.length, "Mismatched inputs");
    for (uint256 index = 0; index < traitIds.length; index++) {
      traitNames[trait][traitIds[index]] = names[index];
    }
  }

  function setTraitSvgs1(uint8 trait1, uint8[] calldata trait1Ids, address source) external onlyOwner {
    for (uint256 index = 0; index < trait1Ids.length; index++) {
        traitSvgs1[trait1][trait1Ids[index]] = source; 
    }
  }

  function setTraitSvgs2(uint8 trait1, uint8 id1, uint8 trait2, uint8[] calldata trait2Ids, address source) external onlyOwner {
    for (uint256 index = 0; index < trait2Ids.length; index++) {
        traitSvgs2[trait1][id1][trait2][trait2Ids[index]] = source; 
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

  function _getSvgTopTalents(uint8 topTalentNo_) internal view returns (string memory data_) {
    string memory s = string(abi.encodePacked("image","()"));
    data_ = call(sourceTopTalents[topTalentNo_-1], abi.encodeWithSignature(s, ""));
  }

  function _getSvg1(uint8 trait1, uint8 id1, string memory sig_) internal view returns (string memory data_) {
    string memory s = string(abi.encodePacked(sig_, "()"));
    address source = traitSvgs1[trait1][id1];
    data_ = call(source, abi.encodeWithSignature(s, ""));
  }

  function _getSvg2(uint8 trait1, uint8 id1, uint8 trait2, uint8 id2, string memory sig_) internal view returns (string memory data_) {
    string memory s = string(abi.encodePacked(sig_, "()"));
    address source = traitSvgs2[trait1][id1][trait2][id2];
    data_ = call(source, abi.encodeWithSignature(s, ""));
  }

  // function _getData(uint8 trait1, uint8 id1, uint8 trait2, uint8 id2) internal view returns (bytes memory data) {
  //   string memory s = string(abi.encodePacked(
  //         traitTypes[trait1],toString(id1),
  //         traitTypes[trait2],toString(id2),
  //         "()"
  //     ));
  //   return abi.encodeWithSignature(s, "");
  // }

  function drawSVG(uint256 tokenId) public view returns (string memory) {
    ICommoner.Commoner memory s = commoner.getTokenTraits(tokenId);

    bool isMale_ = s.bodyType == 0;

    return string(abi.encodePacked(
      string(abi.encodePacked(
        '<svg id="doge" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 64 64" shape-rendering="geometricPrecision" text-rendering="geometricPrecision"><style>:root {',
        // '--p:#ECE2D6;--s:#DDDEDB;--t:#52230F;',
        /* Color */
        _getSvg2(
          0,
          s.breed,
          2,
          s.palette,
          string(abi.encodePacked("breed", toString(s.breed), "color", s.palette))
        ),
        '}.p {fill: var(--p)!important;}.s {fill: var(--s)!important;}.t, .sf{fill: var(--t);}.st {fill:none;stroke-width:.6;}.sm, .hs, .ss{fill:none;stroke-width:.5;}.w, .hf{fill: #fff;}.to {fill: #E2B0D0;}.hs,.ss,.hf{opacity:.3;}.sf{opacity:.2;}.hs{stroke: #fff;}.st,.ss, .sm{stroke: var(--t);}.e{fill:#000;opacity:.5;}.n{fill:#000;opacity:.2;};</style><g stroke-linecap="round" stroke-linejoin="round" >',
        /* BG */
        _getSvg1(
          0, 
          s.background,
          string(abi.encodePacked("background", toString(s.background)))
        ),
        /* Clothes (A/B) */
        _getSvg1(
          isMale_ ? 1 : 2,
          s.clothes, 
          isMale_ ? 
            string(abi.encodePacked("clothes", toString(s.clothes), "a")) :
            string(abi.encodePacked("clothes", toString(s.clothes), "b"))
        )
      )),
      /* Head (A/B) */
        _getSvg2(
          0,
          s.breed,
          isMale_ ? 0 : 1,
          s.head,
          isMale_ ? 
            string(abi.encodePacked("breed", toString(s.breed), "head", s.head, "a")) :
            string(abi.encodePacked("breed", toString(s.breed), "head", s.head, "b"))
        ),
      /* Hat (A/B) */
      _getSvg1(
        isMale_ ? 3 : 4,
        s.accessory,
        isMale_ ? 
            string(abi.encodePacked("hat", toString(s.accessory), "a")) :
            string(abi.encodePacked("hat", toString(s.accessory), "b"))
      ),
      '</svg>'
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
    ICommoner.Commoner memory s = commoner.getTokenTraits(tokenId);
    // 'head': 0, 
    // 'breed': 1, 
    // 'palette': 2, 
    // 'bodyType': 3, 
    // 'clothes': 4, 
    // 'accessory A': 5, 
    // 'accessory B': 6, 
    // 'background': 7, 
    // 'smithing', 'alchemy', 'cooking'];
    bool isMale_ = s.bodyType == 0;
    string memory traits1 = string(abi.encodePacked(
      attributeForTypeAndValue(traitTypes[0], traitNames[0][s.head]),',',
      attributeForTypeAndValue(traitTypes[1], traitNames[1][s.breed]),',',
      attributeForTypeAndValue(traitTypes[2], traitNames[2][s.palette]),',',
      attributeForTypeAndValue(traitTypes[3], traitNames[3][s.bodyType]),',',
      attributeForTypeAndValue(traitTypes[4], traitNames[4][s.clothes]),','
    ));

    string memory traits2 = string(abi.encodePacked(
      attributeForTypeAndValue(traitTypes[5], isMale_ ? traitNames[5][s.accessory] : traitNames[6][s.accessory]),',',
      attributeForTypeAndValue(traitTypes[6], traitNames[7][s.background]),',',
      abi.encodePacked('{"trait_type":"',traitTypes[7],'","value":',toString(s.smithing),'},'),
      abi.encodePacked('{"trait_type":"',traitTypes[8],'","value":',toString(s.alchemy),'},'),
      abi.encodePacked('{"trait_type":"',traitTypes[9],'","value":',toString(s.cooking),'},')
    ));
    return string(abi.encodePacked(
      '[',
      traits1,
      traits2,
      ']'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory svgData = drawSVG(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "Commoner #',
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

  /** Not Revealed Traits */
  function tokenURINotRevealed(uint256 tokenId) public view override returns (string memory) {
    return notRevealedUri;
  }

  /** Top Talents Traits */
  function tokenURITopTalents(uint8 topTalentNo, uint256 tokenId) public view override returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "Commoner #',
      tokenId.toString(),
      '", "description": "100% on-chain", "image": "data:image/svg+xml;base64,',
      base64(bytes(_getSvgTopTalents(topTalentNo))),
      '", "attributes":',
      _compileAttributesTalents(topTalentNo),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  function _compileAttributesTalents(uint8 topTalentNo_) internal pure returns (string memory) {
    // ['head', 'breed', 'palette', 'bodyType', 'clothes', 'accessory', 'background', 'smithing', 'alchemy', 'cooking']
    if(topTalentNo_ == 1) {
      // Rudy Hammerpaw, Master Blacksmith
      //     uint8 head; Determined
      //     uint8 breed; Pitbull
      //     uint8 palette; 1
      //     uint8 bodyType; A
      //     uint8 clothes; Rudy's Smithing Apron
      //     uint8 accessory; Rudy's Eye Patch
      //     uint8 background; The Forge
      string memory traits1 = string(abi.encodePacked(
        attributeForTypeAndValue('top talent', 'Rudy Hammerpaw, Master Blacksmith'),',',
        attributeForTypeAndValue('head', 'Determined'),',',
        attributeForTypeAndValue('breed', 'Pitbull'),',',
        attributeForTypeAndValue('palette', 'Palette 1'),',',
        attributeForTypeAndValue('bodyType', 'A (Male)'),',',
        attributeForTypeAndValue('clothes', "Rudy's Smithing Apron"),',',
        attributeForTypeAndValue('accessory', "Rudy's Eye Patch"),',',
        attributeForTypeAndValue('background', 'The Forge')
      ));
      return string(abi.encodePacked(
        '[',
        traits1,
        ']'
      ));
    }
    if(topTalentNo_ == 2) {
      // Catharine Von Schbeagle, Savant of Science
      //     uint8 head; Excited
      //     uint8 breed; Beagle
      //     uint8 palette; 1
      //     uint8 bodyType; A
      //     uint8 clothes; Goggles of Science
      //     uint8 accessory; Von Schbeagle's Lab Coat
      //     uint8 background; Artificer's Lab
      string memory traits1 = string(abi.encodePacked(
        attributeForTypeAndValue('top talent', 'Catharine Von Schbeagle, Savant of Science'),',',
        attributeForTypeAndValue('head', 'Excited'),',',
        attributeForTypeAndValue('breed', 'Beagle'),',',
        attributeForTypeAndValue('palette', 'Palette 1'),',',
        attributeForTypeAndValue('bodyType', 'A (Male)'),',',
        attributeForTypeAndValue('clothes', "Goggles of Science"),',',
        attributeForTypeAndValue('accessory', "Von Schbeagle's Lab Coat"),',',
        attributeForTypeAndValue('background', "Artificer's Lab")
      ));
      return string(abi.encodePacked(
        '[',
        traits1,
        ']'
      ));
    }
    if(topTalentNo_ == 3) {
      // Charlie Chonkins, Royal Cook
      //     uint8 head; Content
      //     uint8 breed; Corgi
      //     uint8 palette; 1
      //     uint8 bodyType; A
      //     uint8 clothes; Royal Chef's Apron
      //     uint8 accessory; Royal Chef's Hat
      //     uint8 background; The Mess Hall
      string memory traits1 = string(abi.encodePacked(
        attributeForTypeAndValue('top talent', 'Charlie Chonkins, Royal Cook'),',',
        attributeForTypeAndValue('head', 'Content'),',',
        attributeForTypeAndValue('breed', 'Corgi'),',',
        attributeForTypeAndValue('palette', 'Palette 1'),',',
        attributeForTypeAndValue('bodyType', 'A (Male)'),',',
        attributeForTypeAndValue('clothes', "Royal Chef's Apron"),',',
        attributeForTypeAndValue('accessory', "Royal Chef's Hat"),',',
        attributeForTypeAndValue('background', 'The Mess Hall')
      ));
      return string(abi.encodePacked(
        '[',
        traits1,
        ']'
      ));
    }
    if(topTalentNo_ == 4) {
      // Prince Pom, Prince of Dogewood Kingdom
      //     uint8 head; Proud
      //     uint8 breed; Pomeranian
      //     uint8 palette; 1
      //     uint8 bodyType; A
      //     uint8 clothes; Coat of the Strategist
      //     uint8 accessory; Dogewood Royal Scepter
      //     uint8 background; The War Room
      string memory traits1 = string(abi.encodePacked(
        attributeForTypeAndValue('top talent', 'Prince Pom, Prince of Dogewood Kingdom'),',',
        attributeForTypeAndValue('head', 'Proud'),',',
        attributeForTypeAndValue('breed', 'Pomeranian'),',',
        attributeForTypeAndValue('palette', 'Palette 1'),',',
        attributeForTypeAndValue('bodyType', 'A (Male)'),',',
        attributeForTypeAndValue('clothes', "Coat of the Strategist"),',',
        attributeForTypeAndValue('accessory', "Dogewood Royal Scepter"),',',
        attributeForTypeAndValue('background', 'The War Room')
      ));
      return string(abi.encodePacked(
        '[',
        traits1,
        ']'
      ));
    }
    return string(abi.encodePacked(
      '[]'
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