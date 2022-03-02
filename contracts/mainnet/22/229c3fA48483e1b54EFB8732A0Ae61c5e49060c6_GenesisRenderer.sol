// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGenesisAdventurer {
    function getWeapon(uint256 tokenId) external view returns (string memory);
    function getChest(uint256 tokenId) external view returns (string memory);
    function getHead(uint256 tokenId) external view returns (string memory);
    function getWaist(uint256 tokenId) external view returns (string memory);
    function getFoot(uint256 tokenId) external view returns (string memory);
    function getHand(uint256 tokenId) external view returns (string memory);
    function getNeck(uint256 tokenId) external view returns (string memory);
    function getRing(uint256 tokenId) external view returns (string memory);
    function getOrder(uint256 tokenId) external view returns (string memory);
    function getOrderColor(uint256 tokenId) external view returns (string memory);
    function getOrderCount(uint256 tokenId) external view returns (string memory);
    function getLootTokenIds(uint256 tokenId) external pure returns(uint256[8] memory);
    function getName(uint256 tokenId) external view returns (string memory);
}

interface ILootStats {
    enum Class
    {
        Warrior,
        Hunter,
        Mage,
        Any
    }
    function getLevel(uint256[8] memory tokenId) external view returns (uint256);
    function getGreatness(uint256[8] memory tokenId) external view returns (uint256);
    function getRating(uint256[8] memory tokenId) external view returns (uint256);
    function getNumberOfItemsInClass(Class classType, uint256[8] memory tokenId) external view returns (uint256);
}

contract GenesisRenderer is Ownable {
    address public genesisAdventurerAddress;
    address public lootStatsAddress;
    address public genesisNamingAddress;
    IGenesisAdventurer private ga;
    ILootStats private stats;

    constructor(address genesisAdventurer_, address lootStats_) {
        setGenesisAdventurer(genesisAdventurer_);
        setLootStats(lootStats_);
    }

    function setGenesisAdventurer(address addr_) public onlyOwner {
        genesisAdventurerAddress = addr_;
        ga = IGenesisAdventurer(addr_);
    }

    function setLootStats(address addr_) public onlyOwner {
        lootStatsAddress = addr_;
        stats = ILootStats(lootStatsAddress);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {

      string[27] memory parts;
      string memory name = ga.getName(tokenId);
      uint256[8] memory lootTokenIds = ga.getLootTokenIds(tokenId);
      
      parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; widht: 350px} .italic {font-style: italic} .dark { fill: #000; fill-opacity: .5}</style><rect width="100%" height="100%" fill="#000"/><rect y="300" width="350" height="50" fill="';
      parts[1] = ga.getOrderColor(tokenId);
      parts[2] = '"/><text x="10" y="20" class="base">';
      parts[3] = ga.getWeapon(tokenId);
      parts[4] = '</text><text x="10" y="40" class="base">';
      parts[5] = ga.getChest(tokenId);
      parts[6] = '</text><text x="10" y="60" class="base">';
      parts[7] = ga.getHead(tokenId);
      parts[8] = '</text><text x="10" y="80" class="base">';
      parts[9] = ga.getWaist(tokenId);
      parts[10] = '</text><text x="10" y="100" class="base">';
      parts[11] = ga.getFoot(tokenId);
      parts[12] = '</text><text x="10" y="120" class="base">';
      parts[13] = ga.getHand(tokenId);
      parts[14] = '</text><text x="10" y="140" class="base">';
      parts[15] = ga.getNeck(tokenId);
      parts[16] = '</text><text x="10" y="160" class="base">';
      parts[17] = ga.getRing(tokenId);
      parts[18] = '</text><text x="10" y="320" class="base italic">';
      parts[19] = name;
      parts[20] = '</text><text x="340" y="340" class="base dark" text-anchor="end">';
      parts[21] = ga.getOrder(tokenId);
      parts[22] = ' ';
      parts[23] = ga.getOrderCount(tokenId);
      parts[24] = '</text><text x="10" y="340" class="base dark">Rating ';
      parts[25] = _toString(stats.getRating(lootTokenIds));
      parts[26] = ' / 720</text></svg>';

      string memory image = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
      image = string(abi.encodePacked(image, parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
      image = string(abi.encodePacked(image, parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
      image = string(abi.encodePacked(image, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22]));
      image = string(abi.encodePacked(image, parts[23], parts[24], parts[25], parts[26]));
      string memory attributes = string(abi.encodePacked('{"trait_type": "Order", "value": "', ga.getOrder(tokenId),'"},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Greatness", "value": ', _toString(stats.getGreatness(lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Level", "value": ', _toString(stats.getLevel(lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Rating", "value": ', _toString(stats.getRating(lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Number of Warrior Items", "value": ', _toString(stats.getNumberOfItemsInClass(ILootStats.Class.Warrior, lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Number of Hunter Items", "value": ', _toString(stats.getNumberOfItemsInClass(ILootStats.Class.Hunter, lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Number of Mage Items", "value": ', _toString(stats.getNumberOfItemsInClass(ILootStats.Class.Mage, lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Generation", "value": "Genesis"}'));
      string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "This item is a Genesis Adventurer used in Loot (for Adventurers)", '));
      json = string(abi.encodePacked(json, '"attributes": [', attributes,'], '));
      json = string(abi.encodePacked(json, '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}'));
      json = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
      return json;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
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
}

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.0;

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