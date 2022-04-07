/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}
// https://github.com/Brechtpd/base64/blob/main/base64.sol

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
interface IPersonalizedSVG {
    function getSVG(
        string memory,
        string memory,
        string memory
    ) external view returns (string memory);
}

contract PersonalizedSVG is IPersonalizedSVG {
    using Strings for uint256;

    //===== State =====//

    struct RgbColor {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    //===== public Functions =====//

    function getSVG(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) public pure returns (string memory) {
        string memory output = _buildOutput(memberName, tokenName, tokenId);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(output))
                )
            );
    }

    //===== Private Functions =====//

    function _random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function _pluckColor(string memory seed1, string memory seed2)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rgb = RgbColor(
            _random(string(abi.encodePacked(seed1, seed2))) % 255,
            _random(seed1) % 255,
            _random(seed2) % 255
        );
        return rgb;
    }

    function _rotateColor(RgbColor memory rgb)
        private
        pure
        returns (RgbColor memory)
    {
        RgbColor memory rotated = RgbColor(
            (rgb.r + 128) % 255,
            (rgb.g + 128) % 255,
            (rgb.b + 128) % 255
        );
        return rotated;
    }

    function _colorToString(RgbColor memory rgb)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "rgba",
                    "(",
                    rgb.r.toString(),
                    ",",
                    rgb.g.toString(),
                    ",",
                    rgb.b.toString(),
                    ", 1)"
                )
            );
    }

    function _buildOutput(
        string memory memberName,
        string memory tokenName,
        string memory tokenId
    ) private pure returns (string memory) {
        RgbColor memory rgb1 = _pluckColor(tokenName, "");
        RgbColor memory rgb2 = _rotateColor(rgb1);
        RgbColor memory rgb3 = _pluckColor(memberName, "");
        RgbColor memory rgb4 = _rotateColor(rgb3);
        RgbColor memory rgb5 = _pluckColor(tokenId, "");
        RgbColor memory rgb6 = _rotateColor(rgb5);
        string memory output = string(
            abi.encodePacked(
                '<svg width="314" height="400" viewBox="0 0 314 400" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="314" height="400" rx="157" fill="url(#paint0_radial_101_2)"/><rect x="20" y="25" width="274.75" height="350" rx="137.375" fill="url(#paint1_radial_101_2)"/><rect x="39" y="50" width="235.5" height="300" rx="117.75" fill="url(#paint2_radial_101_2)"/><rect x="59" y="75" width="196.25" height="250" rx="98.125" fill="url(#paint3_radial_101_2)"/><rect x="78" y="100" width="157" height="200" rx="78.5" fill="url(#paint4_radial_101_2)"/><rect x="98" y="125" width="117.75" height="150" rx="58.875" fill="url(#paint5_radial_101_2)"/><defs><radialGradient id="paint0_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(157 200) rotate(90) scale(207 161.536)"><stop stop-color="',
                _colorToString(rgb1),
                '"/></radialGradient><radialGradient id="paint1_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(157.375 200) rotate(90) scale(181.125 141.344)"><stop stop-color="',
                _colorToString(rgb2),
                '"/></radialGradient><radialGradient id="paint2_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(156.75 200) rotate(90) scale(155.25 121.152)"><stop stop-color="',
                _colorToString(rgb3),
                '"/></radialGradient><radialGradient id="paint3_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(157.125 200) rotate(90) scale(129.375 100.96)"><stop stop-color="',
                _colorToString(rgb4)
            )
        );
        return
            string(
                abi.encodePacked(
                    output,
                    '"/></radialGradient><radialGradient id="paint4_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(156.5 200) rotate(90) scale(103.5 80.7681)"><stop stop-color="',
                    _colorToString(rgb5),
                    '"/></radialGradient><radialGradient id="paint5_radial_101_2" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(156.875 200) rotate(90) scale(77.625 60.5761)"><stop stop-color="',
                    _colorToString(rgb6),
                    '"/></radialGradient></defs></svg>'
                )
            );
    }
}