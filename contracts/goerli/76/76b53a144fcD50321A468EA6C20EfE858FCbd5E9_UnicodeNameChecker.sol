// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

interface INameChecker {
    function checkName(string memory name) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;
import "./INameChecker.sol";

contract UnicodeNameChecker is INameChecker {
    uint256 constant CHAR_ENGLISH = 1;
    uint256 constant CHAR_DIGITS = 2;
    uint256 constant CHAR_MINUS = 4;
    uint256 constant CHAR_GREEK = 8;
    uint256 constant CHAR_CYRILLIC = 16;
    uint256 constant CHAR_JP_S = 32;
    uint256 constant CHAR_CJK = 64;

    function checkName(string memory name)
        external
        pure
        override
        returns (uint256)
    {
        return checkString(name);
    }

    /**
     * Convert utf-8 string to unicode char and check each char, return how many unicode chars.
     */
    function checkString(string memory s) internal pure returns (uint256) {
        bytes memory bs = bytes(s);
        uint256 i = 0;
        uint256 len = 0;
        uint256 has_chars = 0;
        uint256 last_char = 0;
        uint256 current_char = 0;
        while (i < bs.length) {
            uint8 b1 = uint8(bs[i]);
            i++;
            if (b1 & 0x80 == 0) {
                // 0xxxxxxx
                current_char = checkUnicodeChar(b1);
                if (last_char == CHAR_MINUS && current_char == CHAR_MINUS) {
                    revert("Cannot contains '--'");
                }
                has_chars |= current_char;
                len++;
            } else if (b1 & 0xe0 == 0xc0) {
                // 110xxxxx 10xxxxxx
                uint8 b2 = uint8(bs[i]);
                i++;
                require(b2 & 0xc0 == 0x80, "Invalid UTF-8 sequence");
                uint16 c = ((uint16(b1) & 0x1f) << 6) + (uint16(b2) & 0x3f);
                current_char = checkUnicodeChar(c);
                has_chars |= current_char;
                len++;
            } else if (b1 & 0xf0 == 0xe0) {
                // 1110xxxx 10xxxxxx 10xxxxxx
                uint8 b2 = uint8(bs[i]);
                i++;
                require(b2 & 0xc0 == 0x80, "Invalid UTF-8 sequence");
                uint8 b3 = uint8(bs[i]);
                i++;
                require(b3 & 0xc0 == 0x80, "Invalid UTF-8 sequence");
                uint16 c = ((uint16(b1) & 0x0f) << 12) +
                    ((uint16(b2) & 0x3f) << 6) +
                    (uint16(b3) & 0x3f);
                current_char = checkUnicodeChar(c);
                has_chars |= current_char;
                len++;
            } else {
                revert("Invalid char");
            }
            last_char = current_char;
        }
        // disallow first and last '-':
        if (bs[0] == "-" || bs[bs.length - 1] == "-") {
            revert("Cannot use minus at first or last.");
        }

        // disallow mix of English, Greek, Cyrillic to prevent homograph attack:
        // https://en.wikipedia.org/wiki/IDN_homograph_attack
        uint256 mixes = 0;
        if ((has_chars & CHAR_ENGLISH) > 0) {
            mixes++;
        }
        if ((has_chars & CHAR_GREEK) > 0) {
            mixes++;
        }
        if ((has_chars & CHAR_CYRILLIC) > 0) {
            mixes++;
        }
        if (mixes >= 2) {
            revert("cannot use mixed alphabets");
        }
        return len;
    }

    function checkUnicodeChar(uint16 b) internal pure returns (uint256) {
        // https://en.wikipedia.org/wiki/List_of_Unicode_characters
        // ASCII: a-z:
        if ((b >= 0x61 && b <= 0x7a)) {
            return CHAR_ENGLISH;
        }
        // 0-9:
        if ((b >= 0x30 && b <= 0x39)) {
            return CHAR_DIGITS;
        }
        // minus '-':
        if (b == 0x2d) {
            return CHAR_MINUS;
        }
        // Greek: α-ω: https://unicode-table.com/en/blocks/greek-coptic/
        if ((b >= 0x03b1) && (b <= 0x03c9)) {
            return CHAR_GREEK;
        }
        // Cyrillic: а-я: https://unicode-table.com/en/blocks/cyrillic/
        if ((b >= 0x0430) && (b <= 0x044f)) {
            return CHAR_CYRILLIC;
        }
        // disallow white space and zero-width joiner:
        if ((b >= 0x2000) && (b <= 0x200f)) {
            revert("Unsupported white space or zero-width joiner.");
        }
        if ((b == 0x2028) || (b == 0x205f) || (b == 0x3000)) {
            revert("Unsupported white space.");
        }
        // JP_S:
        // https://unicode-table.com/en/blocks/hiragana/
        if ((b >= 0x3041) && (b <= 0x3096)) {
            return CHAR_JP_S;
        }
        // https://unicode-table.com/en/blocks/katakana/
        if ((b >= 0x30a1) && (b <= 0x30fa)) {
            return CHAR_JP_S;
        }
        // CJK:
        if ((b >= 0x4e00) && (b <= 0x9fa5)) {
            return CHAR_CJK;
        }
        revert("Unsupported char code");
    }
}