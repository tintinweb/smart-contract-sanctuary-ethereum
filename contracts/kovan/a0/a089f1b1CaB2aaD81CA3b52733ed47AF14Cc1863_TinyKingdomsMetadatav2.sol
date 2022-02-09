// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TinyKingdoms
 * @dev Another attempt to reduce the cost using calldata
 */
import "@openzeppelin/contracts/access/Ownable.sol";

contract TinyKingdomsMetadatav2 is Ownable{

    using strings for string;
    using strings for strings.slice;
    
    string private constant Flags="Rising Sun_Vertical Triband_Chevron_Nordic Cross_Spanish Fess_Five Stripes_Hinomaru_Vertical Bicolor_Saltire_Horizontal Bicolor_Vertical Misplaced Bicolor_Bordure_Inverted Pall_Twenty-four squared_Diagonal Bicolor_Horizontal Triband_Diagonal Bicolor Inverse_Quadrisection_Diagonal Tricolor Inverse_Rising Split Sun_Lonely Star_Diagonal Bicolor Right_Horizontal Bicolor with a star_Bonnie Star_Jolly Roger";
    string private constant Nouns="Eagle_Meditation_Folklore_Star_Light_Play_Palace_Wildflower_Rescue_Fish_Painting_Shadow_Revolution_Planet_Storm_Land_Surrounding_Spirit_Ocean_Night_Snow_River_Sheep_Poison_State_Flame_River_Cloud_Pattern_Water_Forest_Tactic_Fire_Strategy_Space_Time_Art_Stream_Spectrum_Fleet_Ship_Spring_Shore_Plant_Meadow_System_Past_Parrot_Throne_Ken_Buffalo_Perspective_Tear_Moon_Moon_Wing_Summer_Broad_Owls_Serpent_Desert_Fools_Spirit_Crystal_Persona_Dove_Rice_Crow_Ruin_Voice_Destiny_Seashell_Structure_Toad_Shadow_Sparrow_Sun_Sky_Mist_Wind_Smoke_Division_Oasis_Tundra_Blossom_Dune_Tree_Petal_Peach_Birch_Space_Flower_Valley_Cattail_Bulrush_Wilderness_Ginger_Sunset_Riverbed_Fog_Leaf_Fruit_Country_Pillar_Bird_Reptile_Melody_Universe_Majesty_Mirage_Lakes_Harvest_Warmth_Fever_Stirred_Orchid_Rock_Pine_Hill_Stone_Scent_Ocean_Tide_Dream_Bog_Moss_Canyon_Grave_Dance_Hill_Valley_Cave_Meadow_Blackthorn_Mushroom_Bluebell_Water_Dew_Mud_Family_Garden_Stork_Butterfly_Seed_Birdsong_Lullaby_Cupcake_Wish_Laughter_Ghost_Gardenia_Lavender_Sage_Strawberry_Peaches_Pear_Rose_Thistle_Tulip_Wheat_Thorn_Violet_Chrysanthemum_Amaranth_Corn_Sunflower_Sparrow_Sky_Daisy_Apple_Oak_Bear_Pine_Poppy_Nightingale_Mockingbird_Ice_Daybreak_Coral_Daffodil_Butterfly_Plum_Fern_Sidewalk_Lilac_Egg_Hummingbird_Heart_Creek_Bridge_Falling Leaf_Lupine_Creek_Iris Amethyst_Ruby_Diamond_Saphire_Quartz_Clay_Coal_Briar_Dusk_Sand_Scale_Wave_Rapid_Pearl_Opal_Dust_Sanctuary_Phoenix_Moonstone_Agate_Opal_Malachite_Jade_Peridot_Topaz_Turquoise_Aquamarine_Amethyst_Garnet_Diamond_Emerald_Ruby_Sapphire_Typha_Sedge_Wood";
    string private constant Adjectives="Central_Free_United_Socialist_Ancient Republic of_Third Republic of_Eastern_Cyber_Northern_Northwestern_Galactic Empire of_Southern_Solar_Islands of_Kingdom of_State of_Federation of_Confederation of_Alliance of_Assembly of_Region of_Ruins of_Caliphate of_Republic of_Province of_Grand_Duchy of_Capital Federation of_Autonomous Province of_Free Democracy of_Federal Republic of_Unitary Republic of_Autonomous Regime of_New_Old Empire of";
    string private constant Suffixes="Beach_Center_City_Coast_Creek_Estates_Falls_Grove_Heights_Hill_Hills_Island_Lake_Lakes_Park_Point_Ridge_River_Springs_Valley_Village_Woods_Waters_Rivers_Points_ Mountains_Volcanic Ridges_Dunes_Cliffs_Summit";

     function getFlag(uint256 index) internal pure returns (string memory) {
        strings.slice memory strSlice = Flags.toSlice();
        string memory separatorStr = "_";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function getNoun(uint256 index) public pure returns (string memory) {
        strings.slice memory strSlice = Nouns.toSlice();
        string memory separatorStr = "_";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function getAdjective(uint256 index) public pure returns (string memory) {
        strings.slice memory strSlice = Adjectives.toSlice();
        string memory separatorStr = "_";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function getSuffix(uint256 index) public pure returns (string memory) {
        strings.slice memory strSlice = Suffixes.toSlice();
        string memory separatorStr = "_";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function getFlagIndex(uint256 tokenId) public pure returns (string memory) {
        uint256 rand = random(tokenId,"FLAG") % 1000;
        uint256 flagIndex =0;

        if (rand>980){flagIndex=24;}
        else {flagIndex = rand/40;}
        
        return getFlag(flagIndex);
    }
    
    function getRandomAdjective(uint256 tokenId) public pure returns (string memory){
        uint256 rand = random(tokenId,"PLACE");
        return (getAdjective((rand / 7) % 35));
    }

    function getKingdom(uint256 tokenId) public pure returns (string memory){
        uint256 rand = random(tokenId,"PLACE");
        string memory a1= (getAdjective((rand / 7) % 35));
        string memory n1= (getNoun((rand / 200) % 229));
        string memory s1= (getSuffix((rand/11)%30));
        string memory output = string(abi.encodePacked(a1,' ',n1,' ',s1));
        
        return output;
    }

    // function getKingdom (uint256 tokenId, uint256 flagIndex) internal view returns (string memory) {
        // uint256 rand = random(tokenId, "PLACE");
        // string memory a1 = adjectives[(rand / 7) % adjectives.length];
        // string memory n1 = nouns[(rand / 200) % nouns.length];
        // string memory s1;

    //     if (flagIndex == 24) {
    //         s1 = "Pirate Ship";
    //     } else {
    //         s1 = suffixes[(rand /11) % suffixes.length];
    //     }
        
    //     string memory output= string(abi.encodePacked(a1,' ',n1,' ',s1));

    // return output;

    // }


      function random(uint256 tokenId, string memory seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, toString(tokenId))));
    }




    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

}

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
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