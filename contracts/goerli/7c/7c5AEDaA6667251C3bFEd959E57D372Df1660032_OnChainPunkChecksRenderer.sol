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
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(int256 value) internal pure returns (string memory str) {
        if (value >= 0) return toString(uint256(value));

        unchecked {
            str = toString(uint256(-value));

            /// @solidity memory-safe-assembly
            assembly {
                // Note: This is only safe because we over-allocate memory
                // and write the string from right to left in toString(uint256),
                // and thus can be sure that sub(str, 1) is an unused memory location.

                let length := mload(str) // Load the string length.
                // Put the - character at the start of the string contents.
                mstore(str, 45) // 45 is the ASCII code for the - character.
                str := sub(str, 1) // Move back the string pointer by a byte.
                mstore(str, add(length, 1)) // Update the string length.
            }
        }
    }

    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

pragma solidity ^0.8.13;

abstract contract ICryptoPunksData {
    function punkImage(uint16 index) public view virtual returns (bytes memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SVG.sol";
import "./ICryptoPunksData.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract OnChainPunkChecksRenderer {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    address public constant PUNKS_DATA_ADDRESS = address(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);

    string private constant DESCRIPTION =
        "Punk Checks are an homage to CryptoPunks and Jack Butcher\'s Checks. Each Punk Check is a unique rendering of a CryptoPunk using checks instead of pixels.";

    function tokenURI(uint256 punkId, uint256 t) public view returns (string memory) {
        require(t >= 1 && t <= 4, "Invalid version");
        // FIXME: Commented out for Goerli
        //string memory svgContents = renderSvg(punkId, t);
        string memory svgContents = "";
        string memory name = string.concat("Punk Checks #", LibString.toString(punkId));
        bytes memory s = abi.encodePacked(
            '{"name": "',
            name,
            '","description": "',
            DESCRIPTION,
            '","image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svgContents)),
            '", "attributes": [',
            '{"trait_type": "Origin","value": "',
            t == 1 ? "CryptoPunks V1" : (t == 2 ? "CryptoPunks V2" : t == 3 ? "CryptoPunks OG" : "CryptoPunks Wannabe"),
            '"}]}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(s))));
    }

    function renderSvg(uint256 punkId, uint256 t) public view returns (string memory) {
        bytes memory pixels = ICryptoPunksData(PUNKS_DATA_ADDRESS).punkImage(uint16(punkId));
        string memory checks;

        bytes memory buffer = new bytes(8);
        uint256 i;
        while (i < 576) {
            uint256 p = i * 4;
            unchecked {
                uint256 x = i % 24;
                uint256 y = i / 24;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint256 j = 0; j < 4; j++) {
                        uint8 value = uint8(pixels[p + j]);
                        buffer[j * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[j * 2] = _HEX_SYMBOLS[value & 0xf];
                    }
                    checks = string.concat(
                        checks,
                        svg.el(
                            "use",
                            string.concat(
                                svg.prop("href", "#c"),
                                svg.prop("x", LibString.toString(160 + x * 40)),
                                svg.prop("y", LibString.toString(160 + y * 40)),
                                svg.prop("fill", string.concat("#", string(buffer)))
                            ),
                            utils.NULL
                        )
                    );
                } else {
                    string memory color = backgroundColor(t, i);
                    checks = string.concat(
                        checks,
                        svg.el(
                            "use",
                            string.concat(
                                svg.prop("href", "#c"),
                                svg.prop("x", LibString.toString(160 + x * 40)),
                                svg.prop("y", LibString.toString(160 + y * 40)),
                                svg.prop("fill", color)
                            ),
                            utils.NULL
                        )
                    );
                }
                ++i;
            }
        }

        return string.concat(
            '<svg width="1240" height="1240" viewBox="0 0 1240 1240" fill="none" xmlns="http://www.w3.org/2000/svg">',
            "<defs>",
            '<g id="c"><rect x="-20" y="-20" width="40" height="40" stroke="#191919" fill="#111111"/><circle r="4"/><circle cx="6" r="4"/><circle cy="6" r="4"/><circle cx="-6" r="4"/><circle cy="-6" r="4"/><circle cx="4.243" cy="4.243" r="4"/><circle cx="4.243" cy="-4.243" r="4"/><circle cx="-4.243" cy="4.243" r="4"/><circle cx="-4.243" cy="-4.243" r="4"/><path d="m-.6 3.856 4.56-6.844c.566-.846-.75-1.724-1.316-.878L-1.38 2.177-2.75.809c-.718-.722-1.837.396-1.117 1.116l2.17 2.15a.784.784 0 0 0 .879-.001.767.767 0 0 0 .218-.218Z" fill="#111111"/></g>',
            "</defs>",
            svg.rect(
                string.concat(svg.prop("width", "1240"), svg.prop("height", "1240"), svg.prop("fill", "black")),
                utils.NULL
            ),
            svg.rect(
                string.concat(
                    svg.prop("x", "130"),
                    svg.prop("y", "130"),
                    svg.prop("width", "980"),
                    svg.prop("height", "980"),
                    svg.prop("fill", "#111111")
                ),
                utils.NULL
            ),
            checks,
            "</svg>"
        );
    }

    function backgroundColor(uint256 t, uint256 i) private pure returns (string memory) {
        if (t == 1) return "#a59afeff";
        if (t == 2) return "#638596ff";
        if (t == 3) {
            if (i < 24 || i >= 552 || (i % 24 == 0) || (i % 24 == 23)) return "#FFD700ff";
            return "#638596ff";
        }
        if (t == 4) return "#3EB489ff";
        revert("Invalid color");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Utils.sol";

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("g", _props, _children);
    }

    function path(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("path", _props, _children);
    }

    function text(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("text", _props, _children);
    }

    function line(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("line", _props, _children);
    }

    function circle(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("circle", _props, _children);
    }

    function circle(string memory _props) internal pure returns (string memory) {
        return el("circle", _props);
    }

    function rect(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("rect", _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props);
    }

    function filter(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("filter", _props, _children);
    }

    function cdata(string memory _content) internal pure returns (string memory) {
        return string.concat("<![CDATA[", _content, "]]>");
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("radialGradient", _props, _children);
    }

    function linearGradient(string memory _props, string memory _children) internal pure returns (string memory) {
        return el("linearGradient", _props, _children);
    }

    function gradientStop(uint256 offset, string memory stopColor, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el(
            "stop",
            string.concat(
                prop("stop-color", stopColor),
                " ",
                prop("offset", string.concat(utils.uint2str(offset), "%")),
                " ",
                _props
            )
        );
    }

    function animateTransform(string memory _props) internal pure returns (string memory) {
        return el("animateTransform", _props);
    }

    function image(string memory _href, string memory _props) internal pure returns (string memory) {
        return el("image", string.concat(prop("href", _href), " ", _props));
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(string memory _tag, string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<", _tag, " ", _props, ">", _children, "</", _tag, ">");
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory _tag, string memory _props) internal pure returns (string memory) {
        return string.concat("<", _tag, " ", _props, "/>");
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val) internal pure returns (string memory) {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val) internal pure returns (string memory) {
        return string.concat("--", _key, ":", _val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory _key) internal pure returns (string memory) {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id) internal pure returns (string memory) {
        return string.concat("url(#", _id, ")");
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(uint256 _r, uint256 _g, uint256 _b, uint256 _a) internal pure returns (string memory) {
        string memory formattedA = _a < 100 ? string.concat("0.", utils.uint2str(_a)) : "1";
        return string.concat(
            "rgba(", utils.uint2str(_r), ",", utils.uint2str(_g), ",", utils.uint2str(_b), ",", formattedA, ")"
        );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str) internal pure returns (uint256 length) {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) {
                i += 1;
            } else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) {
                i += 2;
            } else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) {
                i += 3;
            } else if (string_rep[i] >> 3 == bytes1(uint8(0x1E))) {
                i += 4;
            }
            //For safety
            else {
                i += 1;
            }

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}