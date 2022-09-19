// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import "base64-sol/base64.sol";

library NFTSVG {
    using Strings for uint256;

    struct SVGDefsParams {
        string color0;
        string color1;
        string color2;
        string color3;
        string x1;
        string y1;
        string x2;
        string y2;
        string x3;
        string y3;
    }

    struct SVGBodyParams {
        address VaultContract;
        uint256 VaultId;
        string PVRFName;
        uint256 PVRFRound;
        uint256 startRange;
        uint256 endRange;
        string probabilityTier;
        uint256 valuation;
        uint256 insuranceIndex;
        uint256 tokenId;
    }

    function generateSVG(string memory defs, string memory body)
        internal
        pure
        returns (string memory svg)
    {
        return string(abi.encodePacked(defs, body, "</svg>"));
    }

    function generateSVGDefs(SVGDefsParams memory params)
        public
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<svg width="160px" height="230px" viewBox="0 0 160 230" xmlns="http://www.w3.org/2000/svg"',
                ' xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1">',
                "<defs>",
                '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290px' height='500px' fill='#",
                            params.color0,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            params.x1,
                            "' cy='",
                            params.y1,
                            "' r='120px' fill='#",
                            params.color1,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            params.x2,
                            "' cy='",
                            params.y2,
                            "' r='120px' fill='#",
                            params.color2,
                            "'/></svg>"
                        )
                    )
                ),
                '" />',
                '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            params.x3,
                            "' cy='",
                            params.y3,
                            "' r='100px' fill='#",
                            params.color3,
                            "'/></svg>"
                        )
                    )
                ),
                '" /><feBlend mode="overlay" in="p0" in2="p1" /><feBlend mode="exclusion" in2="p2" /><feBlend mode="overlay" in2="p3" result="blendOut" /><feGaussianBlur ',
                'in="blendOut" stdDeviation="42" /></filter> <filter x="-6.1%" y="-4.2%" width="112.2%" height="108.3%" filterUnits="objectBoundingBox" id="f2">',
                '<feMorphology radius="0.25" operator="dilate" in="SourceAlpha" result="shadowSpreadOuter1"></feMorphology>',
                '<feOffset dx="0" dy="0" in="shadowSpreadOuter1" result="shadowOffsetOuter1"></feOffset>',
                '<feMorphology radius="1" operator="erode" in="SourceAlpha" result="shadowInner"></feMorphology>',
                '<feOffset dx="0" dy="0" in="shadowInner" result="shadowInner"></feOffset>',
                '<feComposite in="shadowOffsetOuter1" in2="shadowInner" operator="out" result="shadowOffsetOuter1"></feComposite>',
                '<feGaussianBlur stdDeviation="3" in="shadowOffsetOuter1" result="shadowBlurOuter1"></feGaussianBlur>',
                '<feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 1 0" type="matrix" in="shadowBlurOuter1"></feColorMatrix></filter>',
                '<rect id="path-1" x="0" y="0" width="160" height="230" rx="16"></rect>',
                '<path d="M18,4 L142,4 C149.731986,4 156,10.2680135 156,18 L156,212 C156,219.731986 149.731986,226 142,226 L18,226 C10.2680135,226 4,219.731986 4,212 L4,18 C4,10.2680135 10.2680135,4 18,4 Z"',
                ' id="path-2"></path><linearGradient x1="50%" y1="29.387066%" x2="50%" y2="100%" id="linearGradient-1">',
                '<stop stop-color="#FFFFFF" offset="0%"></stop><stop stop-color="#FF8748" offset="100%"></stop></linearGradient></defs>'
            )
        );
    }

    function generateSVGBody(SVGBodyParams memory params)
        public
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">',
                '<g><mask id="mask-1" fill="white"><use xlink:href="#path-1"></use>',
                '</mask><use fill="#391D79" xlink:href="#path-1"></use><image id="5" filter="url(#f1)" mask="url(#mask-1)" x="-27.7664671" y="-80" width="216.143713" height="384" xlink:href="#f1"/>',
                '<g opacity="0.401912871"><use fill="black" fill-opacity="1" filter="url(#f2)" xlink:href="#path-2" ></use>',
                '<use stroke="#FFFFFF" stroke-width="0.5" xlink:href="#path-2"></use></g></g>',
                '<rect fill="#FFFFFF" opacity="0.400000006" x="157" y="0" width="3" height="3"></rect>',
                '<rect fill="#FFFFFF" opacity="0.400000006" x="0" y="0" width="3" height="3"></rect>'
                '<text font-family="PingFangSC-Medium, PingFang SC" font-size="10" font-weight="400" fill="#FFFFFF">',
                '<tspan x="12" y="23">Propto NFT NO.',
                params.tokenId.toString(),
                '</tspan></text><rect fill="#FFFFFF" opacity="0.300000012" x="12" y="44" width="136" height="1" ></rect>',
                '<text font-family="PingFangSC-Medium, PingFang SC" font-size="10" font-weight="400" fill="#FFFFFF">',
                '<tspan x="12" y="37">Vault #',
                params.VaultId.toString(),
                "</tspan></text>",
                '<text opacity="0.699999988" font-family="PingFangSC-Semibold, PingFang SC" font-size="10" font-weight="500" fill="#FFFFFF"><tspan x="12" y="71">',
                params.PVRFName,
                " Round-",
                params.PVRFRound.toString(),
                "</tspan></text>",
                '<text fill="url(#linearGradient-1)" fill-rule="nonzero" font-family="DINCondensed-Bold, DIN Condensed" font-size="22" font-style="condensed" font-weight="bold" letter-spacing="0.916666667">',
                '<tspan x="12" y="100">[',
                params.startRange.toString(),
                '</tspan></text><text fill="url(#linearGradient-1)" fill-rule="nonzero" font-family="DINCondensed-Bold, DIN Condensed" font-size="22" font-style="condensed" font-weight="bold" letter-spacing="0.916666667">',
                '<tspan x="12" y="142">',
                params.endRange.toString(),
                ']</tspan></text><rect fill="#FFFFFF" x="12" y="113" width="10" height="3"></rect>',
                '<text font-family="PingFangSC-Semibold, PingFang SC" font-size="11" font-weight="500" fill="#FFFFFF"><tspan x="12" y="162">',
                params.probabilityTier,
                "</tspan></text>"
                '<rect fill="#000000" opacity="0.200000003" x="12" y="185" width="53" height="14" rx="2"></rect>',
                '<rect fill="#000000" opacity="0.200000003" x="12" y="203" width="',
                uint256(intlength(params.insuranceIndex) * 3 + 95).toString(),
                '" height="14" rx="2"></rect>',
                '<text opacity="0.699999988" font-family="PingFangSC-Regular, PingFang SC" font-size="10" font-weight="normal" fill="#FFFFFF"><tspan x="17" y="196">',
                params.valuation.toString(),
                "</tspan></text>",
                '<text opacity="0.699999988" font-family="PingFangSC-Regular, PingFang SC" font-size="10" font-weight="normal" fill="#FFFFFF"><tspan x="16" y="214">Propto Insure NO.1</tspan></text></g>'
            )
        );
    }

    function intlength(uint256 i) public pure returns (uint256) {
        uint256 length = 0;
        uint256 tempI = i;
        while (tempI != 0) {
            tempI >>= 4;
            length++;
        }
        return length;
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            r = 255;
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) r -= 1;
        }
    }
}