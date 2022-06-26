/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

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



// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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

    // TODO fill in action traits

    string[] private type_names = ['Incredible','Divine'];

    string[][] private bg_names = 
        [["bg1_0", "bg1_1", "bg1_2", "bg1_3", "bg1_4", "bg1_5", "bg1_6", "bg1_7"],
         ["bg2_0", "bg2_1", "bg2_2", "bg2_3", "bg2_4", "bg2_5", "bg2_6", "bg2_7"]]; 

    string[][] private fur_names = [["fur1_0", "fur1_1", "fur1_2", "fur1_3", "fur1_4", "fur1_5", "fur1_6", "fur1_7", "fur1_8", "fur1_9", "fur1_10", "fur1_11", "fur1_12", "fur1_13", "fur1_14", "fur1_15", "fur1_16", "fur1_17", "fur1_18"],
        ["fur2_0", "fur2_1", "fur2_2", "fur2_3", "fur2_4", "fur2_5", "fur2_6", "fur2_7", "fur2_8", "fur2_9", "fur2_10", "fur2_11", "fur2_12", "fur2_13", "fur2_14", "fur2_15", "fur2_16", "fur2_17", "fur2_18"]];

    string[][] private eyes_names = [["eyes1_0", "eyes1_1", "eyes1_2", "eyes1_3", "eyes1_4", "eyes1_5", "eyes1_6", "eyes1_7", "eyes1_8", "eyes1_9", "eyes1_10", "eyes1_11", "eyes1_12", "eyes1_13", "eyes1_14", "eyes1_15", "eyes1_16", "eyes1_17", "eyes1_18", "eyes1_19", "eyes1_20", "eyes1_21", "eyes1_22"],
        ["eyes2_0", "eyes2_1", "eyes2_2", "eyes2_3", "eyes2_4", "eyes2_5", "eyes2_6", "eyes2_7", "eyes2_8", "eyes2_9", "eyes2_10", "eyes2_11", "eyes2_12", "eyes2_13", "eyes2_14", "eyes2_15", "eyes2_16", "eyes2_17", "eyes2_18", "eyes2_19", "eyes2_20", "eyes2_21", "eyes2_22"]];

    string[][] private mouth_names = [["mouth1_0", "mouth1_1", "mouth1_2", "mouth1_3", "mouth1_4", "mouth1_5", "mouth1_6", "mouth1_7", "mouth1_8", "mouth1_9", "mouth1_10", "mouth1_11", "mouth1_12", "mouth1_13", "mouth1_14", "mouth1_15", "mouth1_16", "mouth1_17", "mouth1_18", "mouth1_19", "mouth1_20", "mouth1_21", "mouth1_22", "mouth1_23", "mouth1_24", "mouth1_25", "mouth1_26", "mouth1_27", "mouth1_28", "mouth1_29", "mouth1_30", "mouth1_31", "mouth1_32"],
        ["mouth2_0", "mouth2_1", "mouth2_2", "mouth2_3", "mouth2_4", "mouth2_5", "mouth2_6", "mouth2_7", "mouth2_8", "mouth2_9", "mouth2_10", "mouth2_11", "mouth2_12", "mouth2_13", "mouth2_14", "mouth2_15", "mouth2_16", "mouth2_17", "mouth2_18", "mouth2_19", "mouth2_20", "mouth2_21", "mouth2_22", "mouth2_23", "mouth2_24", "mouth2_25", "mouth2_26", "mouth2_27", "mouth2_28", "mouth2_29", "mouth2_30", "mouth2_31", "mouth2_32"]];

    string[][] private earrings_names = [["earrings1_0", "earrings1_1", "earrings1_2", "earrings1_3", "earrings1_4", "earrings1_5", "earrings1_6"],
        ["earrings2_0", "earrings2_1", "earrings2_2", "earrings2_3", "earrings2_4", "earrings2_5", "earrings2_6"]];

    string[][] private clothes_names = [["clothes1_0", "clothes1_1", "clothes1_2", "clothes1_3", "clothes1_4", "clothes1_5", "clothes1_6", "clothes1_7", "clothes1_8", "clothes1_9", "clothes1_10", "clothes1_11", "clothes1_12", "clothes1_13", "clothes1_14", "clothes1_15", "clothes1_16", "clothes1_17", "clothes1_18", "clothes1_19", "clothes1_20", "clothes1_21", "clothes1_22", "clothes1_23", "clothes1_24", "clothes1_25", "clothes1_26", "clothes1_27", "clothes1_28", "clothes1_29", "clothes1_30", "clothes1_31", "clothes1_32", "clothes1_33", "clothes1_34", "clothes1_35", "clothes1_36", "clothes1_37", "clothes1_38", "clothes1_39", "clothes1_40", "clothes1_41", "clothes1_42", "clothes1_43"],
        ["clothes2_0", "clothes2_1", "clothes2_2", "clothes2_3", "clothes2_4", "clothes2_5", "clothes2_6", "clothes2_7", "clothes2_8", "clothes2_9", "clothes2_10", "clothes2_11", "clothes2_12", "clothes2_13", "clothes2_14", "clothes2_15", "clothes2_16", "clothes2_17", "clothes2_18", "clothes2_19", "clothes2_20", "clothes2_21", "clothes2_22", "clothes2_23", "clothes2_24", "clothes2_25", "clothes2_26", "clothes2_27", "clothes2_28", "clothes2_29", "clothes2_30", "clothes2_31", "clothes2_32", "clothes2_33", "clothes2_34", "clothes2_35", "clothes2_36", "clothes2_37", "clothes2_38", "clothes2_39", "clothes2_40", "clothes2_41", "clothes2_42", "clothes2_43"]];

    string[][] private hat_names = [["hat1_0", "hat1_1", "hat1_2", "hat1_3", "hat1_4", "hat1_5", "hat1_6", "hat1_7", "hat1_8", "hat1_9", "hat1_10", "hat1_11", "hat1_12", "hat1_13", "hat1_14", "hat1_15", "hat1_16", "hat1_17", "hat1_18", "hat1_19", "hat1_20", "hat1_21", "hat1_22", "hat1_23", "hat1_24", "hat1_25", "hat1_26", "hat1_27", "hat1_28", "hat1_29", "hat1_30", "hat1_31", "hat1_32", "hat1_33", "hat1_34", "hat1_35", "hat1_36"],
        ["hat2_0", "hat2_1", "hat2_2", "hat2_3", "hat2_4", "hat2_5", "hat2_6", "hat2_7", "hat2_8", "hat2_9", "hat2_10", "hat2_11", "hat2_12", "hat2_13", "hat2_14", "hat2_15", "hat2_16", "hat2_17", "hat2_18", "hat2_19", "hat2_20", "hat2_21", "hat2_22", "hat2_23", "hat2_24", "hat2_25", "hat2_26", "hat2_27", "hat2_28", "hat2_29", "hat2_30", "hat2_31", "hat2_32", "hat2_33", "hat2_34", "hat2_35", "hat2_36"]];

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

    function setUrlBase(string memory url) external onlyOwner {
        require(!urlBaseLocked, "urlBase is locked");
        urlBase = url;
    }

    function lockUrlBase() external onlyOwner {
        urlBaseLocked = true;
    }


    // Note that for Dessert K3, it is the tokenId
    // For Public Mint K3, tokenId is shifted by Offset
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
                monkey.name = 'Karma Unrevealed';
                return monkey;
            } 
            tokenId = (tokenId + offset) % 10000; // random shift added
            if (tokenId == 0) {
                tokenId = 10000;
            }
            monkey.karmaType = publicMintKarmaDistribution(tokenId);
            if (monkey.karmaType == 3) {
                monkey.url = k3_tokenId_to_url[monkey.tokenId]; // NOTE this is shifted
                if (bytes(monkey.url).length == 0) {
                  monkey.url = getImageURL(30016); // unrevealed K3 in public mint
                }
                monkey.name = 'Karma3';
                return monkey;
            }
            monkey.url = getImageURL(tokenId);
            tokenId += 91912628207;
        } else if (tokenId <= 20000) { // karma1 from D1
            monkey.karmaType = 1;
            monkey.name = 'Karma1';
            monkey.url = getImageURL(tokenId);
            tokenId = 22839 - tokenId;
        } else if (tokenId <= 30000) { // karma2 from D2
            monkey.karmaType = 2;
            monkey.name = 'Karma2';
            monkey.url = getImageURL(tokenId);
            tokenId = 32839 - tokenId;
        } else { // karma3 from D3
            monkey.karmaType = 3;
            monkey.name = 'Karma3'; // note other fields not needed
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
          return '[{"trait_type": "type", "value": "Celestial"}]';
        }
        string memory str = string(abi.encodePacked('[{"trait_type": "type", "value": "', type_names[monkey.karmaType - 1],
          '"},{"trait_type": "Background", "value": "', bg_names[monkey.karmaType-1][monkey.bg],
          '"},{"trait_type": "Fur", "value": "', fur_names[monkey.karmaType-1][monkey.fur],
          '"},{"trait_type": "Eyes", "value": "', eyes_names[monkey.karmaType-1][monkey.eyes],
          '"},{"trait_type": "Mouth", "value": "', mouth_names[monkey.karmaType-1][monkey.mouth],
          '"},{"trait_type": "Earring", "value": "', earrings_names[monkey.karmaType-1][monkey.earring],
          '"},{"trait_type": "Clothes", "value": "', clothes_names[monkey.karmaType-1][monkey.clothes],
          '"},{"trait_type": "Hat", "value": "', hat_names[monkey.karmaType-1][monkey.hat]));
        string memory karma_type;
        if (monkey.karmaType == 1) {
          karma_type = 'Incredible';
        } else {
          karma_type = 'Divine';
        }
        return string(abi.encodePacked(str, '"},{"trait_type": "type", "value": "', karma_type, '"}]'));
    }    

    function tokenURI(uint256 tokenId, uint256 offset) external view returns (string memory) {
        Monkey memory monkey = getMonkey(tokenId, offset);        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Karma #', tokenId.toString(), 
            '", "description": "Karma is the entry point into the Monkeyverse and OCM DAO.", "image": "', monkey.url, 
            '", "attributes":', getTraits(monkey), '}' ))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    

}