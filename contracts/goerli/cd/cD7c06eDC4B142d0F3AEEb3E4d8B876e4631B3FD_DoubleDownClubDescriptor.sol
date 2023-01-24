// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IDoubleDownClubDescriptor.sol";

contract DoubleDownClubDescriptor is IDoubleDownClubDescriptor {
    using Strings for uint256;

    struct DDC { // a nod to BAYC, "ape" was shorter to type than monkey
        string bg1;
        string bg2;
        string st1;
        string st2;
        string st3;
    }
    string private start = '<svg id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 250 250"><defs><style>.bg{fill:url(#linear-gradient);}.bg1{fill:#';
    string private end = '"/></linearGradient></defs><rect class="bg" width="250" height="250"/><polygon class="bg1" points="61.08 51.02 107.34 51.02 95.98 153.1 72.88 153.1 61.08 51.02"/><ellipse class="bg1" cx="84.2" cy="182.16" rx="18.76" ry="18.93"/><polygon class="bg2" points="142.68 51.02 188.92 51.02 177.58 153.1 154.46 153.1 142.68 51.02"/><ellipse class="bg2" cx="165.8" cy="182.16" rx="18.76" ry="18.93"/></svg>';
    string private stop0 = ';}.bg2{fill:#';
    string private stop1 = ';}</style><linearGradient id="linear-gradient" y1="125" x2="250" y2="125" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#';
    string private stop2 = '"/><stop offset="0.5" stop-color="#';
    string private stop3 = '"/><stop offset="1" stop-color="#';
    string[] private letters = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];

    constructor() {}

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        string memory ddcId = tokenId.toString();
        string memory name = string(abi.encodePacked("DDC #", ddcId));
        string memory description = string(abi.encodePacked("DDC #", ddcId, " joins the club of Double Down!"));
        string memory image = generateSVGImage(tokenId);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            // solhint-disable-next-line
                            '"{"name":"', name, '", "description":"', description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}'
                        )
                    )
                )
            )
        );
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function generateRandomColor(string memory input) internal view returns (string memory result) { 
        for(uint8 i = 0 ; i < 3 ; i ++) {
            uint8 color = uint8(random(string(abi.encodePacked(i, random(input)))) % 16);
            result = string(abi.encodePacked(result, letters[color]));
        }
    }

    function randomOne(uint256 tokenId) internal view returns (DDC memory) {
        DDC memory ddc;
        ddc.bg1 = generateRandomColor(string(abi.encodePacked("A", tokenId.toString())));
        ddc.bg2 = generateRandomColor(string(abi.encodePacked("B", tokenId.toString())));
        ddc.st1 = generateRandomColor(string(abi.encodePacked("C", tokenId.toString())));
        ddc.st2 = generateRandomColor(string(abi.encodePacked("D", tokenId.toString())));
        ddc.st3 = generateRandomColor(string(abi.encodePacked("E", tokenId.toString())));
        return ddc;
    }

    function generateSVGImage(uint256 tokenId) public view override returns (string memory svg) {
        tokenId = 0;
        // solhint-disable-next-line
        DDC memory seed = randomOne(tokenId);
        string memory header = string(abi.encodePacked(start, seed.bg1, stop0, seed.bg2));
        string memory polygon = string(abi.encodePacked(stop1, seed.st1, stop2, seed.st2, stop3, seed.st3, end));
        string memory image = string(abi.encodePacked(header, polygon));
        return Base64.encode(
            bytes(
                string(abi.encodePacked(image))
            )
        );
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly { // solhint-disable-line
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IDoubleDownClubDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function generateSVGImage(uint256 tokenId) external view returns (string memory);
}