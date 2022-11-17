// SPDX-License-Identifier: GOFUCKYOURSELF
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Serializer {
    // Methods to serialize and unserialize the Bracket submission
    // This is needed in order to store the bracket as a key in a map.
    // Takes a bracket [1,2,3] and returns a string "1,2,3"
    function toStr(uint[] memory list) public pure returns(string memory res) {
        for (uint i = 0; i < list.length; i++) { 
            res = string(abi.encodePacked(res, i == 0 ? "" : ",", Strings.toString(list[i])));
        }
    }

    // Takes a string key "1,2,3" and returns an array [1,2,3] 
    function toList(string memory list) public pure returns(uint[] memory) {
        // Convert the string to a bytes so we can read through it. 
        bytes memory buffer = bytes(list);
        uint[] memory bracket; 

        // default; round group
        if(buffer.length >= 44) {
            bracket = new uint[](31);
        // 34 <= length <= 44 => round 16 
        } else if(buffer.length >= 34) {
            bracket = new uint[](15);
        // 13 <= length 20 => round QF 
        } else /*if(buffer.length >= 13)*/ {
            bracket = new uint[](7);
        }

        uint i = 0;
        uint j = 0;

        // Read the buffer two characters at a time.
        while(i < buffer.length) {
            uint8 tens = uint8(buffer[i]);

            // If we only have one more character, then it must be a number, 
            // so we push it and break
            if(i + 1 == buffer.length) {
                bracket[j] = uint(tens % 16);
                break;
            }

            uint8 ones = uint8(buffer[i+1]);

            // 44 is the uint8 representation of ","
            // Case: "1" "," => push one, advance two space
            if(ones == 44) { 
                // Since it's hex, we mod 16 to convert to decimal. 
                bracket[j] = uint(tens % 16);
                j++;
                i += 2;
            } else { 
                // Case: "1" "5" => parse tens ones and push, advance three spaces 
                // Since it's hex, we mod 16 to convert to decimal. 
                bracket[j] = uint(tens % 16) * 10 + uint(ones % 16);

                j++;
                i += 3;
            }
        }

        return bracket;
    }

    // // deprecate me 
    // function arraysEqual(uint[] memory a, uint[] memory b) public pure returns(bool) {
    //     if(a.length != b.length) {
    //         return false;
    //     }

    //     for(uint i = 0; i < a.length; i++) {
    //         if(a[i] != b[i]) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }
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