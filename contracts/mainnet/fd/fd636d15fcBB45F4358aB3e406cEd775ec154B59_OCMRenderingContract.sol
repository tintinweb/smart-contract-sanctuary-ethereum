// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//
// Rendering contract for Karma
// 
// created by Metagood
//

// 1-10000     Public Mint
// 10001-20000 Karma1
// 20001-30000 Karma2
// 30001-30015 Karma3
// 0           prereview image
// 30016       k3 art unrevealed in public mint

contract OCMRenderingContract is Ownable {
    using Strings for uint256;

    // used for random distribution of Genesis & Karma
    uint8[] private fur_w =[249, 246, 223, 141, 116, 114, 93, 90, 89, 86, 74, 72, 55, 48, 39, 32, 28, 14, 8];
    uint8[] private eyes_w = [245, 121, 107, 101, 79, 78, 70, 68, 62, 58, 56, 51, 50, 48, 44, 38, 35, 33, 31, 22, 15, 10, 7];
    uint8[] private mouth_w = [252, 172, 80, 79, 56, 49, 37, 33, 31, 30, 28, 27, 26, 23, 22, 18, 15, 14, 13, 12, 11, 10, 10, 10, 9, 8, 7, 7, 6, 5, 5, 4, 3];
    uint8[] private earring_w = [251, 32, 29, 17, 16, 8, 5];
    uint8[] private clothes_w = [251, 55, 45, 43, 38, 37, 34, 33, 32, 31, 31, 31, 31, 31, 30, 30, 29, 29, 28, 27, 27, 27, 26, 25, 24, 22, 21, 20, 19, 19, 19, 19, 19, 19, 18, 17, 16, 15, 14, 13, 11, 9, 8, 6];
    uint8[] private hat_w = [251, 64, 47, 42, 39, 38, 36, 35, 34, 34, 33, 29, 28, 26, 26, 25, 25, 25, 22, 21, 20, 20, 18, 17, 17, 15, 14, 14, 13, 13, 12, 12, 12, 10, 9, 8, 7];

    string[2] private type_names = ['Incredible','Divine'];

    string[8][2] private bg_names = [["Midnight","Cream Soda","Orange","Mint","Sage","River","Ocean","Platinum"],["Karmic Midnight","Karmic Cream Soda","Karmic Orange","Karmic Mint","Karmic Sage","Karmic River","Karmic Ocean","Karmic Platinum"]];
    string[44][2] private clothes_names = [["None","Hoopster","Rocket Pop","Sun!RISE","Nana Crew","Vibes","Bellhop","Banana Lounge","Neon","Safari","Metropolis","OG Hoodie","Professional","Aviator","Team Karma","Denim","Back In Time","Moto","Tracksuit","Zebra","Taxi","Retro","Funky Velvet","Calavera","Gladiator","Powersuit","Metagood Mage","Banana Party","Loungesuit","Pirate","Indy","Western","Money","Thriller","Snappy","Fabulous","Mummy","Diablo","Starry Night","Royal","Viking","Illustrious Monk","Mecha Pilot","Guardian of the Monkeyverse"],["None","Baller","Tie Dye","Moon!RISE","Bananza","Warm Vibes","Concierge","Club Bananas","Links","Explorer","Super Monk","Camo Hoodie","Monkey Business","Nana Flyer","Karma All-Star","Denim !RISE","Hover Time","Punk","Blingsuit","Chromopop","Steampunk","Light Show","Crystal Armor","Bones","Emperor","Chief Karma Officer","Marvelous Metagood Mage","Surf's Up","High Roller","Swashbuckler","Venom","Banana Buckaroo","Stacks","Ethereal","Dapper","Dr. Dream","Pharaoh","Inferno","Galaxy","Interstellar","Odin","Monk of the Year","Mecha Monk","Champion of the Monkeyverse"]];
    string[7][2] private earring_names = [["None","Silver Loop","Gold Loop","Cross","Silver Stud","Gold Stud","Diamond"],["None","Silver Banana Loop","Gold Banana Loop","Golden Banana","Silver Banana Stud","Gold Banana Stud","Diamond Bananas"]];
    string[23][2] private eyes_names = [["Sky","Green","Hazel","Gray","Lime","Clever Sky","Clever Green","Clever Hazel","Clever Gray","Clever Lime","Clever Blue","Calm Sky","Calm Green","Calm Hazel","Calm Gray","Calm Lime","Calm Blue","Piercing Sky","Piercing Green","Piercing Hazel","Upgrade","Starlight Stare","Laser Eyes"],["Karmic Sky","Karmic Green","Karmic Hazel","Karmic Gray","Karmic Lime","Clever Karmic Sky","Clever Karmic Green","Clever Karmic Hazel","Gray Sus","Lime Sus","Blue Sus","Smooth Sky","Smooth Green","Smooth Hazel","Glimpsing Gray","Glimpsing Lime","Glimpsing Blue","Intense","Super Sus","Anime","Cyborg","Galactic Gaze","Karmic Destiny"]];
    string[19][2] private fur_names = [["K1 Monkey","K1 Wood","K1 Onyx","K1 Cinnamon","K1 Peach","K1 Coffee","K1 Crystal","K1 Rock","K1 Aqua","K1 Magma","K1 Cheetah","K1 Porcelain","K1 Frog","K1 Robot","K1 Atomic","K1 Midnight","K1 Zombie","K1 Alien","Gold"],["K2 Monkey","K2 Wood","K2 Onyx","K2 Cinnamon","K2 Peach","K2 Coffee","K2 Crystal","K2 Rock","K2 Aqua","K2 Magma","K2 Cheetah","K2 Porcelain","K2 Frog","K2 Robot","K2 Atomic","K2 Midnight","K2 Zombie","K2 Alien","Dragon"]];
    string[37][2] private hat_names = [["None","Neon !RISE","Rocket Pop","Beanie","Safari","Bellhop","Newsie","Panama","Metropolis","Trippy","OG Snapback","Aviator","Wayfarer","Glitz","Bowler","Sun!RISE","Cat Ears","Mage","Prism","Sombrero","En Vogue","Viking","Faux Hawk","Bandana","Sgt. Pepper","Indy","Cowboy","Mummy","Snappy","Red Racer","Pirate","Diablo","Chic","Captain","Monkeysaurus","Knight","Crown"],["None","Links","Tie Dye","X Monk","Explorer","Concierge","Driver","Panama Rose","Super Monk","Psychedelic","Camo Snapback","Nana Flyer","Bucket Bling","Nightlife","Party Animal","Moon!RISE","Cute Cat Ears","Marvelous Mage","Luminescence","Skulls","Ibiza","Odin","Pink Flame","Hex Specs","Imagine","Venom","Desperado","Pharaoh","Dapper","Super Racer","Swashbuckler","Inferno","Disco Chic","Captain Borealis","Gigasaurus","Centurion","Cosmic Crown"]];
    string[33][2] private mouth_names = [["Smile","Yellow Grin","Pink Smirk","Charcoal Smile","Blue Confident","Red Confident","Steel Smirk","Red Grin","Cheerful","Yellow Focused","Pfft","Pink Oof","Charcoal Focused","Blue Pfft","Steel Oof","Silly","Toothpick","Delight","Not Entertained","Red Twig","Yellow Twig","Pink Twig","Charcoal Twig","Blue Ladybug","Gold Ladybug","Pink Ladybug","Charcoal Ladybug","Steel Butterfly","Red Butterfly","Blue Butterfly","Blue Rose","Fire Rose","Golden Rose"],["Karmic Smile","Karmic Grin","Not Impressed","Karmic Doubt","Unamused","Mischievous","Sly","Beaming","Sparkle","Karmic Focus","Karmic Pfft","Karmic Oof","Refreshing","Downvote","Fangs","Divine Sprinkle","Smarty Pants","Mouthguard","Wheat","Lollipop","Pizza","Superpop","Gilded Feather","Divine Delight","Golden Grin","Bubblegum","Platinum Martini","Bubbles","Rainbow","Hummingbird","Ballad of Karma","Dragon's Breath","Billion Dollar Bananas"]];

    mapping(uint256 => string) public k3_tokenId_to_url; // full url
    string public urlBase;   // base url for ipfs submarining
    bool public urlBaseLocked = false;

    struct Monkey {
        uint8 bg;
        uint8 fur;
        uint8 eyes;
        uint8 mouth;
        uint8 earring;
        uint8 clothes;
        uint8 hat;
        uint8 karmaType; // 0 means unrevealed
        uint256 tokenId;
        string url;
        string name;
    }    

    function setBgName(uint8 karmaType, uint8 index, string memory name) external onlyOwner {
        bg_names[karmaType-1][index] = name;
    }

    function setFurName(uint8 karmaType, uint8 index, string memory name) external onlyOwner {
        fur_names[karmaType-1][index] = name;
    }

    function setEyesName(uint8 karmaType, uint8 index, string memory name) external onlyOwner {
        eyes_names[karmaType-1][index] = name;
    }

    function setMouthName(uint8 karmaType, uint8 index, string memory name) external onlyOwner {
        mouth_names[karmaType-1][index] = name;
    }

    function setEarringName(uint8 karmaType, uint8 index, string memory name) external onlyOwner {
        earring_names[karmaType-1][index] = name;
    }

    function setClothesName(uint8 karmaType, uint8 index, string memory name) external onlyOwner {
        clothes_names[karmaType-1][index] = name;
    }

    function setHatName(uint8 karmaType, uint8 index, string memory name) external onlyOwner {
        hat_names[karmaType-1][index] = name;
    }

    function setUrlBase(string memory url) external onlyOwner {
        require(!urlBaseLocked, "urlBase is locked");
        urlBase = url;
    }

    function lockUrlBase() external onlyOwner {
        urlBaseLocked = true;
    }


    function setK3Url(uint256 tokenId, string memory url) external onlyOwner {
        require(bytes(k3_tokenId_to_url[tokenId]).length == 0, "k3Url already set");
        k3_tokenId_to_url[tokenId] = url;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // used to sample from random distribution
    function usew(uint8[] memory w,uint256 i) internal pure returns (uint8) {
        uint8 ind=0;
        uint256 j=uint256(w[0]);
        while (j<=i) {
            ind++;
            j+=uint256(w[ind]);
        }
        return ind;
    }

    function getImageURL(uint256 tokenId) private view returns (string memory) {
        return string(abi.encodePacked(urlBase, tokenId.toString()));
    }

    // offset is >= 10000 before the random draw for setting offset once
    // offset is the offset for karma public mint
    function getMonkey(uint256 tokenId, uint256 offset) public view returns (Monkey memory) {
        Monkey memory monkey;
        monkey.tokenId = tokenId;

        if (tokenId <= 10000) { // public mint has k1, k2, k3
            if (offset >= 10000) { 
                monkey.karmaType = 0;
                monkey.url = getImageURL(0); // unrevealed
                return monkey;
            } 
            tokenId = (tokenId + offset) % 10000; // random shift added
            if (tokenId == 0) {
                tokenId = 10000;
            }
            monkey.karmaType = publicMintKarmaDistribution(tokenId);
            if (monkey.karmaType == 3) {
                monkey.url = k3_tokenId_to_url[monkey.tokenId];
                if (bytes(monkey.url).length == 0) {
                  monkey.url = getImageURL(30016); // unrevealed K3 in public mint
                }
                return monkey;
            }
            monkey.url = getImageURL(tokenId);
            tokenId += 91912628207;
        } else if (tokenId <= 20000) { // karma1 from D1
            monkey.karmaType = 1;
            monkey.url = getImageURL(tokenId);
            tokenId = 22839 - tokenId;
        } else if (tokenId <= 30000) { // karma2 from D2
            monkey.karmaType = 2;
            monkey.url = getImageURL(tokenId);
            tokenId = 32839 - tokenId;
        } else { // karma3 from D3
            monkey.karmaType = 3;
            monkey.url = k3_tokenId_to_url[monkey.tokenId]; // Owner manually sets this
            return monkey;
        }

        monkey.bg      = uint8(random(string(abi.encodePacked('A',tokenId.toString()))) % 8);
        monkey.fur     = usew(fur_w,random(string(abi.encodePacked('<rect width="300" height="120" x="99" y="400" style="fill:#',tokenId.toString())))%1817);
        monkey.eyes    = usew(eyes_w,random(string(abi.encodePacked('C',tokenId.toString())))%1429);
        monkey.mouth   = usew(mouth_w,random(string(abi.encodePacked('D',tokenId.toString())))%1112);
        monkey.earring = usew(earring_w,random(string(abi.encodePacked('E',tokenId.toString())))%358);
        monkey.clothes = usew(clothes_w,random(string(abi.encodePacked('F',tokenId.toString())))%1329);
        monkey.hat     = usew(hat_w,random(string(abi.encodePacked('G',tokenId.toString())))%1111);

        // avoid collision in Karma from Genesis + Dessert1/2
        if (tokenId==7403) {
            monkey.hat++; // fix collision
        }
        return monkey;
    }

    function publicMintKarmaDistribution(uint256 id) public pure returns (uint8) {
        uint256 r = (uint256(keccak256(abi.encode((id+21620000).toString())))) % 10000; // this is the fixed sequence with the desired rarity distribution
        if (r < 5) {
            return 3; // 5 Karma3
        } else if (r >= 8500) {
            return 2; // 15% Karma2
        } else {
            return 1; // 85% Karma1
        }
    } 

    // get string attributes of properties, used in tokenURI call
    //  { "trait_type": "Hat", "value": "xxx" }, 
    function getTraits(Monkey memory monkey) internal view returns (string memory) {
        if (monkey.karmaType == 0) {
          return '[{"trait_type": "Status", "value": "Not Revealed"}]';
        } else if (monkey.karmaType == 3) {
          return '[{"trait_type": "Type", "value": "Celestial"}]';
        }
        string memory str = string(abi.encodePacked('[{"trait_type": "Type", "value": "', type_names[monkey.karmaType - 1],
          '"},{"trait_type": "Background", "value": "', bg_names[monkey.karmaType-1][monkey.bg],
          '"},{"trait_type": "Fur", "value": "', fur_names[monkey.karmaType-1][monkey.fur],
          '"},{"trait_type": "Eyes", "value": "', eyes_names[monkey.karmaType-1][monkey.eyes],
          '"},{"trait_type": "Mouth", "value": "', mouth_names[monkey.karmaType-1][monkey.mouth],
          '"},{"trait_type": "Earring", "value": "', earring_names[monkey.karmaType-1][monkey.earring],
          '"},{"trait_type": "Clothes", "value": "', clothes_names[monkey.karmaType-1][monkey.clothes],
          '"},{"trait_type": "Hat", "value": "', hat_names[monkey.karmaType-1][monkey.hat],
          '"}]'));
        return str;
    }    

    function tokenURI(uint256 tokenId, uint256 offset) external view returns (string memory) {
        Monkey memory monkey = getMonkey(tokenId, offset);        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Karma #', tokenId.toString(), 
            '", "description": "Karma is your membership into the Monkeyverse", "image": "', monkey.url,
            '", "attributes":', getTraits(monkey), '}' ))));
        return string(abi.encodePacked('data:application/json;base64,', json));
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