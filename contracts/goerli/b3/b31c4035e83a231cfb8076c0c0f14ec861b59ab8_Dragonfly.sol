//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title HexadecimalColor
 * @notice Library used to convert an `uint24` to his
 * hexadecimal string representation starting with `#`
 * */
library HexadecimalColor {
    bytes16 private constant _HEX_SYMBOLS = "0123456789ABCDEF";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toColor(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "#000000";
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 1);
        buffer[0] = "#";
        for (uint256 i = 2 * length; i > 0; ) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
            unchecked {
                --i;
            }
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IShape} from "./IShape.sol";
import {HexadecimalColor} from "src/utils/HexadecimalColor.sol";

contract Dragonfly is IShape {
    using HexadecimalColor for uint24;

    string public constant name = "Dragonfly";
    string public constant description =
        'Dragonfly: \\"We are solarpunks because the only other options are denial and despair.\\"';

    function path(string memory color)
        public
        pure
        override
        returns (string memory)
    {
        return
            string.concat(
                '<path style="fill:',
                color,
                '" d="M474 459c-8-8-9-23-9-23-16-15-7-44-7-44l4 2c4 4 15 17 38 17s41-18 41-18c3 3 3 12 3 15v1-1 2c0 20-9 27-9 27v5c-6 12-35 13-35 13-12 7-4 14-1 15s12 2 26-5l3 37c0 4-4 7-4 7l2 33c0 6-5 8-5 8l3 30c0 2-4 5-4 5s3 22 2 28c0 2-3 5-3 5l2 24c0 2-3 3-3 3l2 18c0 2-3 5-3 5v13c0 1-7 14-17-3-10 17-17 4-18 3v-13l-2-5 1-18s-2-1-2-3l2-24s-4-3-4-5l3-28s-4-3-4-5l2-30s-5-2-5-8l3-33s-4-3-4-7l2-37v-6Zm-30-74s-3 11-2 15l-79 8s-47-21-49-56c0 0-1-15 22-9 0 0 42 10 108 42Zm112 0 3 15 79 8s46-21 49-56c0 0 1-15-23-9 0 0-42 10-108 42Z"/>',
                '<path style="fill:',
                color,
                '" d="M500 396c-1 0-20 0-29-15 0 0-22-6-23-26 0 0-2-18 18-19 0 0 3-2 10 5l7 7s16 8 13-9c0-3-16-18-20-16 5-7 14-9 24-10 11 1 19 3 24 10-4-2-19 13-20 16-2 17 14 9 14 9l6-7c7-7 11-5 11-5 19 1 17 19 17 19 0 20-22 26-22 26-10 15-30 15-30 15Zm-58 20s2 21 9 25c0 0 1 11 5 16 0 0-25 25-105 7 0 0-39-6-37-23 0 0-14-15 104-24l24-1Zm116-1s-2 20-8 26c0 0-4 11-8 16 0 0 27 25 107 7 0 0 39-6 37-23 0 0 14-16-104-25l-24-1Z"/>'
            );
    }

    function path(uint24 color) external pure override returns (string memory) {
        return path(color.toColor());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IShape {
    function name() external view returns (string memory);

    function description() external view returns (string memory);

    function path(string memory color) external view returns (string memory);

    function path(uint24 color) external view returns (string memory);
}