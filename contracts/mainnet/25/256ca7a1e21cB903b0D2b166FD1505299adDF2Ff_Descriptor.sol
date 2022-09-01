// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Descriptor {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant FONT_DATA = "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";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
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

    function toString(uint256 value) internal pure returns (string memory) {
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

    function GetSentenceDesc(uint256 tokenId, string memory sentence, uint24 color) public pure returns (string memory){
        string memory output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMiDYMid meet" viewBox="0 0,360,360"><style>@font-face {font-family: "Unifont";font-style: normal;font-weight: normal;src: url(data:font/woff;base64,',
                FONT_DATA,
                ') format("woff");}</style><style>.base{fill:rgb(',
                toString(uint8(bytes3(color)[0])),
                ',',
                toString(uint8(bytes3(color)[1])),
                ',',
                toString(uint8(bytes3(color)[2])),
                '); font-family:Unifont;font-size:22px;text-anchor:start;white-space:pre}</style><rect width="100%" height="100%" fill="black" />'
            )
        );
        bytes memory b = bytes(sentence);
        uint256 len = b.length / 29;
        uint256 startPosY = 35;
        uint256 i = 0;
        for (; i < len; ++i){
            bytes memory temp = new bytes(29);
            for (uint256 j = 0; j < 29; ++j){
                temp[j] = b[i*29+j];
            }
            bytes memory line = abi.encodePacked(
                '<text x="20" y="',
                toString(startPosY + i * 30),
                '" class="base"><![CDATA[',
                temp,
                ']]></text>'
                );
            output = string(abi.encodePacked(output, line));
        }

        uint256 remain = b.length % 29;
        if (remain > 0){
            bytes memory temp = new bytes(remain);
            for (uint256 j = 0; j < remain; ++j){
                temp[j] = b[i*29+j];
            }
            bytes memory line = abi.encodePacked(
                '<text x="20" y="',
                toString(startPosY + i * 30),
                '" class="base"><![CDATA[',
                temp,
                ']]></text>'
                );
            output = string(abi.encodePacked(output, line));
        }
        output = string(abi.encodePacked(output, "</svg>"));

        string memory json = encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Sentence#',
                        toString(tokenId),
                        '", "description": "", "image": "data:image/svg+xml;base64,',
                        encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }


    function GetWordDesc(uint256 tokenId, string memory word) public pure returns (string memory) {
        string memory output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMiDYMid meet" viewBox="0 0,360,360"><style>@font-face {font-family: "Unifont";font-style: normal;font-weight: normal;src: url(data:font/woff;base64,',
                FONT_DATA,
                ') format("woff");}</style><style>.base{fill:rgb(255,255,255); font-family:Unifont;font-size:22px;text-anchor:middle}</style><rect width="100%" height="100%" fill="black" /><text x="180" y="195" class="base">',
                word,
                "</text></svg>"
            )
        );
        string memory json = encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Word#',
                        toString(tokenId),
                        '", "description": "", "image": "data:image/svg+xml;base64,',
                        encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }
}