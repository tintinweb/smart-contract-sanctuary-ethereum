// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./base64.sol";
import "./IMahDecode.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MahDecode is IMahDecode {
    using Strings for uint256;
    string[] a1 = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF", "#C0C0C0", "#800080", "#FFA500", "#008000"];
    string[] a2 = ["#800000", "#008080", "#FF6347", "#7CFC00", "#00FF7F", "#8B008B", "#FFC0CB", "#000080", "#FFD700", "#DC143C"];
    string[] a3 = ["#FF69B4", "#FFA07A", "#87CEFA", "#FF8C00", "#DA70D6", "#D2B48C", "#8FBC8F", "#1E90FF", "#FF1493", "#FFDAB9"];
    string[] a4 = ["#B22222", "#FF4500", "#6B8E23", "#4B0082", "#40E0D0", "#2E8B57", "#9370DB", "#7B68EE", "#D8BFD8", "#B0C4DE"];
    string[] a5 = ["#778899", "#00BFFF", "#FF7F50", "#228B22", "#9932CC", "#00FA9A", "#FF00FF", "#FFB6C1", "#0000CD", "#FFFFF0"];

    function tokenURI(
        uint256 tokenId,
        string calldata map
    ) external view override returns (string memory) {
        uint8[] memory colorsValueArray = splitString(map);
        
        string memory rawSvg = string(
            abi.encodePacked(
                '<?xml version="1.0" encoding="UTF-8" standalone="no"?>',
                '<svg version="1.1" width="600" height="600" stroke="black" stroke-width="20" fill="none" id="svg8" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">',
                '<circle cx="300" cy="300" r="290" fill="',
                a1[colorsValueArray[0]],
                '" />',
                '<ellipse cx="299.99979" cy="236.00006" fill="',
                a2[colorsValueArray[1]],
                '" rx="144.99988" ry="145.00003" style="stroke-width:20.0001" />',
                '<path fill="',
                a3[colorsValueArray[2]],
                '" stroke-width="17" d="m 283.67499,551.31047 c -53.39015,-3.14758 -106.79544,-22.38185 -148.98669,-53.65858 -6.49687,-4.81612 -14.8344,-11.47547 -14.8165,-11.83427 0.0174,-0.35203 9.93575,-8.26336 15.02604,-11.98564 39.4279,-28.8316 86.6814,-47.10962 135.2942,-52.33302 14.56456,-1.56493 37.14293,-1.87506 51.49738,-0.70736 56.00812,4.55637 107.81901,24.8302 151.66388,59.34691 3.22335,2.53762 6.09562,4.89696 6.38279,5.24293 0.42389,0.51077 -0.3831,1.35372 -4.28764,4.47855 -54.63501,43.72527 -122.66607,65.5246 -191.77346,61.45048 z" />',
                '<ellipse fill="',
                a4[colorsValueArray[3]],
                '" cx="227.42857" cy="213.14285" rx="26.285715" ry="25.714285" stroke-width="15" />',
                '<ellipse fill="',
                a5[colorsValueArray[4]],
                '" cx="344" cy="225.71428" rx="59.42857" ry="62.285713" stroke-width="17" />',
                '<path fill="black" d="m 235.76282,299.15728 c 22.35853,9.52209 44.68358,19.12491 67.00482,28.73682 0,0 -10.04978,-7.93968 -10.04978,-7.93968 v 0 c -22.79543,-9.62794 -45.56914,-19.31094 -68.07876,-29.59427 0,0 11.12372,8.79713 11.12372,8.79713 z" />',
                "</svg>"
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = "fefe";

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"name":"FRDED #',
                                tokenId.toString(),
                                '",',
                                '"description":"',
                                description,
                                '",',
                                '"image": "',
                                "data:image/svg+xml;base64,",
                                encodedSvg,
                                '",',
                                '"attributes": [{"trait_type": "Color Big Circle", "value": "',
                                a1[colorsValueArray[0]],
                                '"},{"trait_type": "Color Little Circle", "value": "',
                                a2[colorsValueArray[1]],
                                '"},{"trait_type": "Color Bust", "value": "',
                                a3[colorsValueArray[2]],
                                '"},{"trait_type": "Color Eyes Circle 1", "value": "',
                                a4[colorsValueArray[3]],
                                '"},{"trait_type": "Color Eyes Circle 2", "value": "',
                                a5[colorsValueArray[4]],
                                '"},{"trait_type": "Map", "value": "',
                                map,
                                '"}]',
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function splitString(string memory str) public pure returns (uint8[] memory) {
        bytes memory strBytes = bytes(str);
        uint8[] memory result = new uint8[](strBytes.length);
        
        for (uint i = 0; i < strBytes.length; i++) {
            result[i] = uint8(strBytes[i]) - 48;
        }
        
        return result;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
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
pragma solidity ^0.8.13;

interface IMahDecode {
    function tokenURI(uint256 tokenId, string memory map) external view returns (string memory);
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