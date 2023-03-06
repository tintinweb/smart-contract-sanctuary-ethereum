// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./ICheckDescriptor.sol";

contract CheckDescriptor is ICheckDescriptor {
    uint base = 1000000;
    uint layers = 5;
    function tokenURI(string memory tokenId, string memory seed) external pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="100%" height="100%" fill="#121212"/>',
            '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
            '<tspan fill="#', substring(seed, 60, 65),'">-------</tspan>',
            '<tspan dy="20" x="160" fill="#', substring(seed, 54, 59),'">/...../.\\</tspan>',
            '<tspan dy="25" x="160" fill="#', substring(seed, 48, 53),'">|...../...|</tspan>',
            '<tspan dy="25" x="160" fill="#', substring(seed, 42, 47),'">\\..\\/.../</tspan>',
            '<tspan dy="22" x="160" fill="#', substring(seed, 36, 41),'">-------</tspan>',
            '</text></svg>'
        );
        string memory img = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            )    
        );
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Checkscii #', tokenId, '",',
                '"description": "Randomly generated on-chain Checks!",',
                '"image": "', img, '"',
                ', "attributes": [',
                '{"trait_type" : "Layer #1", "value": "', substring(seed, 60, 65),'"}, {"trait_type" : "Layer #2", "value": "', substring(seed, 54, 59),'"}, '
                '{"trait_type" : "Layer #3", "value": "', substring(seed, 48, 53),'"}, {"trait_type" : "Layer #4", "value": "', substring(seed, 42, 47),'"}, {"trait_type" : "Layer #5", "value": "', substring(seed, 36, 41),'"}]'
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(startIndex < strBytes.length && endIndex < strBytes.length, "Index out of range");
        require(endIndex >= startIndex, "Invalid index range");
        bytes memory result = new bytes(endIndex - startIndex + 1);
        for (uint i = startIndex; i <= endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }      
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ICheckDescriptor {
    function tokenURI(string memory tokenId, string memory seed) external view returns (string memory);
}