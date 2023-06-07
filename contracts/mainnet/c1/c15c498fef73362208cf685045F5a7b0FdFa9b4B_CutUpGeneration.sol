// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import {ICutUpGeneration} from "./interfaces/ICutUpGeneration.sol";

interface ITerraNullius {
    struct Claim {
        address claimant;
        string message;
        uint blockNumber;
    }

    // Claim[] public claims;
    function claims(uint256) external view returns (address, string memory, uint256);
}

contract CutUpGeneration is ICutUpGeneration {
    ITerraNullius public terraNullius;
    uint256 public maxSupply = 4621;

    constructor(address terraNulliusAddress) {
        terraNullius = ITerraNullius(terraNulliusAddress);
    }

    function cutUp(bytes32 seed) external view returns (ICutUpGeneration.Messages memory) {
        uint256 n;
        if (seed == 0x0) {
            n = uint256(blockhash(block.number - 1));
        } else {
            n = uint256(seed);
        }

        return ICutUpGeneration.Messages(
            getMessage(((n << 240) >> 240) % maxSupply),
            getMessage(((n << 224) >> 240) % maxSupply),
            getMessage(((n << 208) >> 240) % maxSupply),
            getMessage(((n << 192) >> 240) % maxSupply),
            getMessage(((n << 176) >> 240) % maxSupply),
            getMessage(((n << 160) >> 240) % maxSupply),
            getMessage(((n << 144) >> 240) % maxSupply),
            getMessage(((n << 128) >> 240) % maxSupply),
            getMessage(((n << 112) >> 240) % maxSupply),
            getMessage(((n << 96) >> 240) % maxSupply),
            getMessage(((n << 80) >> 240) % maxSupply),
            getMessage(((n << 64) >> 240) % maxSupply)
        );
    }

    function getMessage(uint256 index) private view returns (string memory) {
        try terraNullius.claims(index) returns (address, string memory message, uint256) {
            return Base64.encode(bytes(message));
        } catch {
            return "";
        }
    }
}

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
pragma solidity ^0.8.17;

interface ICutUpGeneration {
    struct Messages {
        string message1;
        string message2;
        string message3;
        string message4;
        string message5;
        string message6;
        string message7;
        string message8;
        string message9;
        string message10;
        string message11;
        string message12;
    }

    function cutUp(bytes32 seed) external view returns (Messages memory);
}