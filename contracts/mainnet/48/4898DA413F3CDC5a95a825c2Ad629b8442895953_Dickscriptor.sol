// SPDX-License-Identifier: MIT

/*********************************
*                                *
*              8==D              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

import './base64.sol';
import "./IDickscriptor.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Dickscriptor is IDickscriptor {
    struct Color {
        string value;
        string name;
    }
    struct Trait {
        string content;
        string name;
        Color color;
        uint64 inches;
    }
    using Strings for uint256;

    string private constant SVG_END_TAG = '</svg>';

    function tokenURI(uint256 tokenId, uint256 seed) external pure override returns (string memory) {
        uint256[4] memory colors = [seed % 100000000000000 / 1000000000000, seed % 10000000000 / 100000000, seed % 1000000 / 10000, seed % 100];
        Trait memory line1 = getLine1(seed / 100000000000000, colors[0]);
        Trait memory line2 = getLine2(seed % 1000000000000 / 10000000000, colors[1]);
        Trait memory line3 = getLine3(seed % 100000000 / 1000000, colors[2]);
        Trait memory line4 = getLine4(seed % 100, colors[3]);

        string memory colorCount = calculateColorCount(colors);
        string memory inchCount = calculateInches([line1.inches, line2.inches, line3.inches, line4.inches]);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#121212"/>',
                '<text x="160" y="130" font-family="Courier,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
                line1.content,
                line2.content,
                line3.content,
                line4.content,
                '</text>',
                SVG_END_TAG
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"Onchain Dicks #', tokenId.toString(), '",',
                            '"description":"Cock",',
                            '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                            '"attributes": [{"trait_type": "Head", "value": "', line1.name,' (',line1.color.name,')', '"},',
                            '{"trait_type": "Shaft", "value": "', line2.name,' (',line2.color.name,')', '"},',
                            '{"trait_type": "Balls", "value": "', line3.name,' (',line3.color.name,')', '"},',
                            '{"trait_type": "Slang", "value": "', line4.name,' (',line4.color.name,')', '"},',
                            '{"trait_type": "Inches", "value": ', inchCount, '},',
                            '{"trait_type": "Colors", "value": ', colorCount, '}',
                            ']',
                            '}')
                    )
                )
            )
        );
    }

    function getColor(uint256 seed) private pure returns (Color memory) {
        if (seed == 10) {
            return Color("#e60049", "UA Red");
        }
        if (seed == 11) {
            return Color("#82b6b9", "Pewter Blue");
        }
        if (seed == 12) {
            return Color("#b3d4ff", "Pale Blue");
        }
        if (seed == 13) {
            return Color("#00ffff", "Aqua");
        }
        if (seed == 14) {
            return Color("#0bb4ff", "Blue Bolt");
        }
        if (seed == 15) {
            return Color("#1853ff", "Blue RYB");
        }
        if (seed == 16) {
            return Color("#35d435", "Lime Green");
        }
        if (seed == 17) {
            return Color("#61ff75", "Screamin Green");
        }
        if (seed == 18) {
            return Color("#00bfa0", "Aqua");
        }
        if (seed == 19) {
            return Color("#ffa300", "Orange");
        }
        if (seed == 20) {
            return Color("#fd7f6f", "Coral Reef");
        }
        if (seed == 21) {
            return Color("#d0f400", "Volt");
        }
        if (seed == 22) {
            return Color("#9b19f5", "Purple X11");
        }
        if (seed == 23) {
            return Color("#dc0ab4", "Deep Magenta");
        }
        if (seed == 24) {
            return Color("#f46a9b", "Cyclamen");
        }
        if (seed == 25) {
            return Color("#bd7ebe", "African Violet");
        }
        if (seed == 26) {
            return Color("#fdcce5", "Classic Rose");
        }
        if (seed == 27) {
            return Color("#FCE74C", "Gargoyle Gas");
        }
        if (seed == 28) {
            return Color("#eeeeee", "Bright Gray");
        }
        if (seed == 29) {
            return Color("#7f766d", "Sonic Silver");
        }

        return Color('','');
    }

    function getLine1(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint64 inches;
        if (seed == 10) {
            content = "8==D";
            name = "2 Inch";
            inches = 2;
        }
        if (seed == 11) {
            content = "8===D";
            name = "3 Inch";
            inches = 3;
        }
        if (seed == 12) {
            content = "8====D";
            name = "4 Inch";
            inches = 4;
        }
        if (seed == 13) {
            content = "8=====D";
            name = "5 Inch";
            inches = 5;
        }
        if (seed == 14) {
            content = "8======D";
            name = "6 Inch";
            inches = 6;
        }
        if (seed == 15) {
            content = "8============D";
            name = "Wow";
            inches = 12;
        }
        if (seed == 16) {
            content = "8-D";
            name = "Micro";
            inches = 1;
        }
        if (seed == 17) {
            content = "8----D";
            name = "Thin";
            inches = 4;
        }
        if (seed == 18) {
            content = "8=-=-=D";
            name = "Weird";
            inches = 5;
        }
        if (seed == 19) {
            content = "8";
            name = "Balls";
            inches = 0;
        }
        if (seed == 20) {
            content = "\u15E1-D";
            name = "Double Ended Thin";
            inches = 1;
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color, inches);
    }

    function getLine2(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint64 inches;
        if (seed == 10) {
            content = "\u15E1==8";
            name = "Reversed 2 Inch";
            inches = 2;
        }
        if (seed == 11) {
            content = "\u15E1===8";
            name = "Reversed 3 Inch";
            inches = 3;
        }
        if (seed == 12) {
            content = "\u15E1====8";
            name = "Reversed 4 Inch";
            inches = 4;
        }
        if (seed == 13) {
            content = "\u15E1=====8";
            name = "Reversed 5 Inch";
            inches = 5;
        }
        if (seed == 14) {
            content = "\u15E1============8";
            name = "Reversed Hung";
            inches = 12;
        }
        if (seed == 15) {
            content = "\u15E1-8";
            name = "Reversed Thin";
            inches = 1;
        }
        if (seed == 16) {
            content = "\u15E1-D";
            name = "Double Ended";
            inches = 1;
        }

        return Trait(string(abi.encodePacked('<tspan dy="20" x="160" fill="', color.value, '">', content, '</tspan>')), name, color, inches);
    }

    function getLine3(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        uint64 inches;
        if (seed == 10) {
            content = "8=D 8=D 8=D";
            name = "3 * 2 Inch";
            inches = 6;
        }
        if (seed == 11) {
            content = "8===D 8===D";
            name = "2 * 3 Inch";
            inches = 6;
        }
        if (seed == 12) {
            content = "8=D \u15E1=8";
            name = "Touch Tips";
            inches = 2;
        }
        if (seed == 13) {
            content = "8====D (|)";
            name = "Lucky";
            inches = 4;
        }
        if (seed == 14) {
            content = "8=D (|) \u15E1=8";
            name = "Double Trouble";
            inches = 2;
        }
        if (seed == 15) {
            content = "8D (|)";
            name = "Performance Anxiety";
            inches = 0;
        }
        if (seed == 16) {
            content = "8====D (*)";
            name = "Backdoor";
            inches = 4;
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color, inches);
    }

    function getLine4(uint256 seed, uint256 colorSeed) private pure returns (Trait memory) {
        Color memory color = getColor(colorSeed);
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "Cock";
            name = "Cock";
        }
        if (seed == 11) {
            content = "Dick";
            name = "Dick";
        }
        if (seed == 12) {
            content = "Johnson";
            name = "Johnson";
        }
        if (seed == 13) {
            content = "Pecker";
            name = "Pecker";
        }
        if (seed == 14) {
            content = "Manhood";
            name = "Manhood";
        }
        if (seed == 15) {
            content = "Rooster";
            name = "Rooster";
        }
        if (seed == 16) {
            content = "Wang";
            name = "Wang";
        }
        if (seed ==  17) {
            content = "Willy";
            name = "Willy";
        }

        return Trait(string(abi.encodePacked('<tspan dy="25" x="160" fill="', color.value, '">', content, '</tspan>')), name, color, 0);
    }

    function calculateColorCount(uint256[4] memory colors) private pure returns (string memory) {
        uint256 count;
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = 0; j < 4; j++) {
                if (colors[i] == colors[j]) {
                    count++;
                }
            }
        }

        if (count == 4) {
            return '4';
        }
        if (count == 6) {
            return '3';
        }
        if (count == 8 || count == 10) {
            return '2';
        }
        if (count == 16) {
            return '1';
        }

        return '0';
    }

    function calculateInches(uint64[4] memory inches) private pure returns (string memory) {
        uint64 count;
        
        for (uint64 i = 0; i < 4; i++) {
            count += inches[i];
        }

        return Strings.toString(count);
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

// SPDX-License-Identifier: MIT

/*********************************
*                                *
*          8======D              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IDickscriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
    hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
    hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
    hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
            mstore(result, encodedLen)

        // prepare the lookup table
            let tablePtr := add(table, 1)

        // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

        // result ptr, jump over length
            let resultPtr := add(result, 32)

        // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
            // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

            // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
        // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

        // set the actual output length
            mstore(result, decodedLen)

        // prepare the lookup table
            let tablePtr := add(table, 1)

        // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

        // result ptr, jump over length
            let resultPtr := add(result, 32)

        // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
            // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

            // write 3 bytes
                let output := add(
                add(
                shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                add(
                shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}