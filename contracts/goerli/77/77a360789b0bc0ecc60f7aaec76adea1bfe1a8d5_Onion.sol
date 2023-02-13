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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IShape {
    function name() external view returns (string memory);

    function description() external view returns (string memory);

    function path(string memory color) external view returns (string memory);

    function path(uint24 color) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {IShape} from "./IShape.sol";
import {HexadecimalColor} from "src/utils/HexadecimalColor.sol";

contract Onion is IShape {
    using HexadecimalColor for uint24;

    string public constant name = "Onion";
    string public constant description =
        'Onion: \\"The essence of Solarpunk is a vision of the future that embodies the best of what humanity can achieve: a post-scarcity, post-hierarchy, post-capitalism world where humanity sees itself as part of nature and clean energy replaces fossil fuels.\\"';

    function path(string memory color)
        public
        pure
        override
        returns (string memory)
    {
        string memory start = string.concat('<path style="fill:', color);
        return
            string.concat(
                start,
                '" d="M477 309s5 38-53 105-36 118-30 139c6 22 57 87 138 65 82-22 88-114 79-136-9-23-14-42-68-112 0 0-23-36-20-61h30s-4 20 40 76c0 0 55 62 52 129-3 66-41 92-49 102 0 0-31 28-63 33l10 5s10 15-7 13l-11-5 5 11s0 17-13 7l-9-18v23s-6 13-16 0v-23l-7 15s-19 17-13-9l3-6-13 6s-12-1-6-13l11-6s-107-22-111-140c0 0-10-53 59-133 0 0 32-34 31-67h31Z"/>',
                start,
                '" d="M500 340c4 4 54 69 73 97 21 30 38 75 16 115-21 39-57 55-89 55s-68-16-89-55c-22-40-6-85 16-115 19-28 69-93 73-97v-1 1Zm0 49c2 3 38 48 51 68 15 22 27 53 11 81a71 71 0 0 1-62 39c-23 0-48-12-63-39-15-28-4-59 11-81 14-20 49-65 52-68Z"/>',
                start,
                '" d="m500 416 40 53c12 16 21 41 9 63a55 55 0 0 1-49 30c-17 0-37-9-49-30-12-22-3-47 9-63l40-53v-1 1-1 1Zm0 50 17 24c5 7 9 18 4 28-5 9-14 13-21 13-8 0-16-4-21-13-5-10-1-21 4-28l17-24Z"/>',
                start,
                '" d="m500 493 6 9c1 2 3 6 1 9s-5 5-7 5c-3 0-6-2-7-5-2-3-1-7 1-9l6-9Z"/>'
            );
    }

    function path(uint24 color) external pure override returns (string memory) {
        return path(color.toColor());
    }
}