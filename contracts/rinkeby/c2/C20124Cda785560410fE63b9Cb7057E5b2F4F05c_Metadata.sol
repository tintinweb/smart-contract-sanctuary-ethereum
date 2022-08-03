//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IRenderer {
  function imageData(uint256 dna) external view returns (string memory);
}

interface IDna {
  function getDNA(uint256 tokenId) external view returns(uint256);
}

contract Metadata is Ownable {

    using Strings for uint256;

    // definitions
    struct TraitType {
      // display_type
      string trait_type;
      uint8 index;
    }

    // instances
    struct Trait {
      string trait_type;
      uint256 trait_index;
      string value;
    }

    // https://docs.opensea.io/docs/metadata-standards
    struct Metadata {
      string name;
      string description;
      string external_url;
      //string image computed: basePath + dna + extension
      string image_base_uri;
      string image_extension;

      address image_data;
      string animation_url;
      // attributes
    }

    TraitType[] public traits;

    // trait_type => index => value
    mapping(uint256 => mapping(uint256 => string)) public traitValues;

    Metadata public metadata;

    address public dnaContract;

    // 8 bits per trait
    // 255 = 1111 1111
    uint256 constant TRAIT_MASK = 255;


// Regular Traits

    string[] private _traits = ["Type", "Background", "Skin", "Haircut", "Hair Color", "Eyes", "Facial Hair", "Earrings" "Clothes",
          "Lipstick", "Eyeshadow", "Glasses"];

// List Traits

    string[] private traitType = [
        "Regular",
        "Heavy Makeup",
        "McDonald's Worker",
        "Wendy's Worker",
        "Clown",
        "Red Devil",
        "McDonald's Manager",
        "Blue Devil"
    ];
    string[] private traitBackground = [
        "Grapes",
        "Sage",
        "Lagoon",
        "Dark Teal",
        "Marine",
        "Yellow Glow",
        "Manilla",
        "Chili",
        "Sulfur",
        "Juice Box",
        "Swamp",
        "Houseplant",
        "Blue",
        "Potpourri",
        "Eggplant",
        "Perpy",
        "Mustard",
        "Backlit Yellow",
        "Laser",
        "Backlit Lilac",
        "Dark Marsh Green",
        "TV Glow"
    ];
    string[] private traitSkin = [
        "Brown",
        "Alien",
        "Pale White",
        "Medium",
        "Olive",
        "White",
        "Black"
    ];
    string[] private traitHaircut = [
        "Round Crew Cut",
        "Long And Luxurious",
        "Frizzy",
        "Short And Wooly",
        "Crew Cut",
        "Combed",
        "Balding And Buzzed",
        "Center Part",
        "Asian",
        "Short And Neat",
        "Loose Curls",
        "Clean Cut",
        "Round Crew",
        "Long And Straight",
        "Crimped",
        "Dreads",
        "Faux Hawk",
        "Asymmetrical Bob",
        "Biff",
        "Arty",
        "Bangs",
        "Long Layers",
        "Constanza",
        "Thick + Combed",
        "Bieber",
        "Bang Super Wave",
        "Flat Mini Fro",
        "Bang Wave",
        "Crimpy Bob",
        "Pullback",
        "Toupee",
        "Bun",
        "Pompadour",
        "Mini Fro",
        "Fresh",
        "Sultry",
        "Woody",
        "Tarzan",
        "Double Bun",
        "Messy Bun",
        "Wisp",
        "Clown On Sides",
        "Clown Round",
        "Loose Layers",
        "Clown Unique",
        "Side Part",
        "Horns On Holder",
        "Clown Round Curly Rainbow",
        "Clown On Top",
        "Horns Small",
        "Horns Thick",
        "Horns Hook",
        "Horns Screw"
    ];
    string[] private traitHairColor = [
        "Brunette",
        "Brown",
        "Blonde",
        "Lilac",
        "Dirty Blonde",
        "Red",
        "Silver",
        "Green",
        "Pink Streaks",
        "Pink",
        "Green Streaks",
        "Blue",
        "Platinum",
        "Blue Streaks",
        "Orange",
        "Purple",
        "Dyed Red",
        "Orange Streaks",
        "Yellow",
        "Rainbow",
        "Green Black"
    ];
    string[] private traitEyes = [
        "Brown",
        "Green",
        "Brown Monolid",
        "Blue Monolid",
        "Blue",
        "Green Monolid",
        "Snake",
        "Glowing Pink",
        "Fire"
    ];
    string[] private traitFacialHair = [
        "Fancy",
        "Heavy Stubble",
        "Clean",
        "Underchin Heavy",
        "Heavy Peach Fuzz",
        "Peach Fuzz",
        "Sportsman",
        "Underchin With Ministache",
        "Light Stubble",
        "Trimmed Beard",
        "Shaman",
        "Burly",
        "Extra Heavy Stubble",
        "Natural Beard",
        "Full Long Beard",
        "Medium Stubble",
        "Underchin Light",
        "Flavor Saver",
        "Teenage Stache",
        "Sand Paper",
        "Retro Stache",
        "Icky Stache",
        "Medium Stache",
        "Well Groomed",
        "Relaxed Beard",
        "Tamed Beard",
        "Goatee",
        "Classic Stache",
        "Devil Mustache"
    ];
    string[] private traitEarrings = [
        "Silver",
        "Pearl",
        "Jewel Green",
        "Jewel Blue",
        "Jewel Red",
        "Gold",
        "Jewel Purple",
        "Jewel Clear",
        "Jewel Yellow"
    ];
    string[] private traitClothes = [
        "Medium Thickness Sweater",
        "Wide Hoodie",
        "Sports Jacket With Zipper",
        "Polka Dot Shirt",
        "Men's Suit",
        "Small Hoodie",
        "Polo Shirt",
        "Striped T-Shirt",
        "Plain T-Shirt",
        "Denim Shirt",
        "Striped Thick T-Shirt",
        "Thick Knitted Sweater",
        "Women's V-Neck T-Shirt",
        "Tiger Jacket",
        "Frilled Women's Shirt",
        "Painted Top"
    ];
    string[] private traitLipstick = [
        "Bold Shiny",
        "Light Shiny",
        "Dark Red Shiny",
        "Light",
        "Dark Brown Shiny",
        "Medium Shiny",
        "Dark Red",
        "Black Shiny",
        "Medium",
        "Bold",
        "Blue Shiny",
        "Orange Shiny",
        "Dark Brown",
        "Black",
        "Lilac Shiny",
        "Orange",
        "Pink",
        "Red Shiny",
        "Light Brown Shiny",
        "Blue",
        "Pink Shiny",
        "Lilac",
        "Light Brown",
        "Red"
    ];
    string[] private traitEyeshadow = [
        "Bold",
        "Medium Glitter",
        "Medium",
        "Light Glitter",
        "Medium Shiny",
        "Bold Glitter",
        "Light Shiny",
        "Bold Shiny",
        "Light",
        "Blue Shiny",
        "Black",
        "Lilac Shiny",
        "Orange Shiny",
        "Lilac",
        "Pink",
        "Blue",
        "Pink Glitter",
        "Black Glitter",
        "Black Shiny",
        "Blue Glitter",
        "Pink Shiny",
        "Orange Glitter",
        "Lilac Glitter",
        "Orange"
    ];
    string[] private traitGlasses = [
        "Dark Self-Tint Thin Rim",
        "Enhanced Sporty",
        "Gradient Sporty",
        "Light Self-Tint Glasses",
        "Enhanced Fashion",
        "Pit Vipers",
        "Soft Glasses",
        "Enhanced Glasses",
        "Sunglasses Disciplined",
        "Enhanced Thin Rim",
        "Clear Glasses",
        "Dark Self-Tint Glasses",
        "Light Self-Tint Disciplined",
        "Dark Self-Tint Fashion",
        "Sunglasses Sporty",
        "Light Self-Tint Aviator",
        "Gradient Glasses",
        "Dark Self-Tint Disciplined",
        "Enhanced Mellow",
        "Soft Disciplined",
        "Dark Self-Tint Bejeweled",
        "Light Self-Tint Thin Rim",
        "Sunglasses Mellow",
        "Clear Mellow",
        "Clear Disciplined",
        "Enhanced Aviator",
        "Gradient Aviator",
        "Soft Aviator",
        "Sunglasses Glasses",
        "Light Self-Tint Mellow",
        "Clear Bejeweled",
        "Sunglasses Thin Rim",
        "Dark Self-Tint Aviator",
        "Gradient Mellow",
        "Enhanced Bejeweled",
        "Soft Fashion",
        "Gradient Thin Rim",
        "Sunglasses Bejeweled",
        "Enhanced Disciplined",
        "Clear Aviator",
        "Light Self-Tint Sporty",
        "Light Self-Tint Fashion",
        "Gradient Disciplined",
        "Dark Self-Tint Mellow",
        "Clear Sporty",
        "Soft Bejeweled",
        "Sunglasses Fashion",
        "Soft Sporty",
        "Soft Thin Rim",
        "Soft Mellow",
        "Gradient Fashion",
        "Sunglasses Aviator",
        "Clear Thin Rim",
        "Light Self-Tint Bejeweled",
        "Dark Self-Tint Sporty",
        "Gradient Bejeweled",
        "Clear Fashion"
    ];

// constructor

    constructor() {
        writeTraitTypes(_traits);
      // trait type / start / length / trat_values
      writeTraitData(0, 0, traitType.length, traitType);
      writeTraitData(1, 0, traitBackground.length, traitBackground);
      writeTraitData(2, 0, traitSkin.length, traitSkin);
      // writeTraitData(3, 0, traitHaircut.length, traitHaircut);
      // writeTraitData(4, 0, traitHairColor.length, traitHairColor);
      // writeTraitData(5, 0, traitEyes.length, traitEyes);
      // writeTraitData(6, 0, traitFacialHair.length, traitFacialHair);
      // writeTraitData(7, 0, traitEarrings.length, traitEarrings);
      // writeTraitData(8, 0, traitClothes.length, traitClothes);
      // writeTraitData(9, 0, traitLipstick.length, traitLipstick);
      // writeTraitData(10, 0, traitEyeshadow.length, traitEyeshadow);
      // writeTraitData(11, 0, traitGlasses.length, traitGlasses);

      // _metadata.name	string	Crecodile
      // _metadata.description	string	Ladies and gentlemen, boys and girls… welcome to the grand opening of Crecoland! For the first time in decentralized history, the wonderful world of Crecodiles is open to the public. Crecodiles are a series of 8888 crocodile NFTs. Not just a charming collectible, these fancy friends have their DNA fully stored on the Ethereum blockchain and are excited to explore the full potential of on-chain metadata.
      // _metadata.external_url	string	https://www.creco.xyz/crecodile/
      // _metadata.image_base_uri	string	https://ik.imagekit.io/2j0dbks5n/img/static/crecos/prerender/
      // _metadata.image_extension	string	.png
      // _metadata.image_data	address	0x0000000000000000000000000000000000000000
      // _metadata.animation_url	string	

      Metadata memory _metadata = Metadata({
        name : "Regulars",
        description : "An extra-ordinary collection by p0pps",
        external_url : "https://regular.world",
        image_base_uri : "my-image-base-url",
        image_extension : ".should-this-be-png?",
        image_data : 0x0000000000000000000000000000000000000000,
        animation_url : "none"
      });
      setMetadata(_metadata);
    }

    // O W N E R

    function writeTraitTypes(string[] memory trait_types) public onlyOwner  {
      for (uint8 index = 0; index < trait_types.length; index++) {
        traits.push(TraitType(trait_types[index], index));
      }
    }

    function setTraitType(uint8 trait_type_idx, string memory trait_type) public onlyOwner {
      traits[trait_type_idx] = TraitType(trait_type, trait_type_idx);
    }

    function setTrait(uint8 trait_type, uint8 trait_idx, string memory value) public onlyOwner {
      traitValues[trait_type][trait_idx] = value;
    }

    function writeTraitData(uint8 trait_type, uint8 start, uint256 length, string[] memory trait_values) public onlyOwner {
      for (uint8 index = 0; index < length; index++) {
        setTrait(trait_type, start+index, trait_values[index]);
      }
    }

    function setDnaContract(address _dnaContract) public onlyOwner {
      dnaContract = _dnaContract;
    }

    function setMetadata(Metadata memory _metadata) public onlyOwner {
      metadata = _metadata;
    }

    function setDescription(string memory description) public onlyOwner {
      metadata.description = description;
    }

    function setExternalUrl(string memory external_url) public onlyOwner {
      metadata.external_url = external_url;
    }

    function setImage(string memory image_base_uri, string memory image_extension) public onlyOwner {
      metadata.image_base_uri = image_base_uri;
      metadata.image_extension = image_extension;
    }

    function setImageData(address imageData) public onlyOwner {
      metadata.image_data = imageData;
    }

    function setAnimationUrl(string memory animation_url) public onlyOwner {
      metadata.animation_url = animation_url;
    }

    // P U B L I C

    function dnaToTraits(uint256 dna) public view returns (Trait[] memory) {
      uint256 trait_count = traits.length;
      Trait[] memory tValues = new Trait[](trait_count);
      for (uint256 i = 0; i < trait_count; i++) {
        uint256 bitMask = TRAIT_MASK << (8 * i);
        uint256 trait_index = (dna & bitMask) >> (8 * i);
        string memory value = traitValues[ traits[i].index ][trait_index];
        tValues[i] = Trait(traits[i].trait_type, trait_index, value);
      }
      return tValues;
    }

    function getAttributesJson(uint256 dna) internal view returns (string memory) {
      Trait[] memory _traits = dnaToTraits(dna);
      uint8 trait_count = uint8(traits.length);
      string memory attributes = '[\n';
      for (uint8 i = 0; i < trait_count; i++) {
        attributes = string(abi.encodePacked(attributes,
          '{"trait_type": "', _traits[i].trait_type, '", "value": "', _traits[i].value,'"}', i < (trait_count - 1) ? ',' : '','\n'
        ));
      }
      return string(abi.encodePacked(attributes, ']'));
    }

    function getImage(uint256 dna) internal view returns (string memory) {
      return bytes(metadata.image_base_uri).length > 0 ? string(abi.encodePacked(metadata.image_base_uri, dna.toString(), metadata.image_extension)) : "";
    }

    function getImageData(uint256 dna) internal view returns (string memory) {
      if (metadata.image_data != address(0x0)) {
        return IRenderer(metadata.image_data).imageData(dna);
      }
      return "";
    }

    function getMetadataJson(uint256 tokenId, uint256 dna) public view returns (string memory){
      string memory attributes = getAttributesJson(dna);
      string memory image_data = getImageData(dna);
      string memory meta = string(
        abi.encodePacked(
          '{\n"name": "', metadata.name,' #', tokenId.toString(),
          '"\n,"description": "', metadata.description,
          '"\n,"attributes":', attributes,
          '\n,"external_url": "', metadata.external_url, tokenId.toString()
        )
      );
      if (bytes(metadata.animation_url).length > 0) {
        meta = string(
          abi.encodePacked(
            meta,
            '"\n,"animation_url": "', metadata.animation_url, tokenId.toString()
          )
        );
      }
      if (bytes(metadata.image_base_uri).length > 0) {
        meta = string(
          abi.encodePacked(
            meta,
            '"\n,"image": "', getImage(dna)
          )
        );
      } 
      else if(bytes(image_data).length > 0) {
        meta = string(
          abi.encodePacked(
            meta,
            '"\n,"image_data": "', image_data
          )
        );
      }

      return string(
        abi.encodePacked(
          meta,
          '"\n}'
        )
      );
    }

    function tokenURI(uint256 tokenId, uint256 dna) public view returns (string memory) {
      string memory json = Base64.encode(bytes(getMetadataJson(tokenId, dna)));
      string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
      );
      return output;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
      if(address(dnaContract) == address(0x0)) {
        return "";
      }
      uint256 dna = IDna(dnaContract).getDNA(tokenId);
      return tokenURI(tokenId, dna);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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