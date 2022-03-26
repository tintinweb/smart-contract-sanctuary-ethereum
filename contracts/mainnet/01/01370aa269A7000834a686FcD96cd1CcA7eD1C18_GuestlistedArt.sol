// File contracts/GuestlistedLibrary.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library GuestlistedLibrary {
    struct Venue { 
        string name;
        string location;
        uint[2][] indexes;
        string[] colors;
        uint[] djIndexes;
    }

    struct DJ { 
        string firstName;
        string lastName;
        uint fontSize;
    }

    struct TokenData {
        uint tokenId;
        uint deterministicNumber;
        uint randomNumber;
        uint shapeRandomNumber;
        uint shapeIndex;
        string json;
        string date;
        string bg;
        string color;
        string shape;
        string attributes;
        string customMetadata;
        string djFullName;
        Venue venue;
        DJ dj;
    }

    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
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
}


// File contracts/GuestlistedArt.sol


pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

// author: @etherlect

contract GuestlistedArt {

    // --------------------------------------------------------
    // 
    //  Draw the token image (SVG) from token tokenData
    // 
    // --------------------------------------------------------
    function draw (GuestlistedLibrary.TokenData memory tokenData) external pure returns (string memory) {
        uint rotate = tokenData.randomNumber % 360;
        uint patternSize = 150;
        uint dasharray = tokenData.randomNumber % 3;
        uint scale;
        string memory drawing;

        // --------------------------------------------------------
        // 
        //  Setup scale, rotate and patternSize 
        //  depending on shape type
        // 
        // --------------------------------------------------------
        if (tokenData.shapeIndex == 0) {
            // circle
            rotate = 0;
            scale = 8;
        } else if (tokenData.shapeIndex == 1) {
            // prism
            scale = tokenData.randomNumber % 8 + 4;
        } else if (tokenData.shapeIndex == 2) {
            // square
            scale = tokenData.randomNumber % 4 + 4;
        } else if (tokenData.shapeIndex == 3) {
            // cube
            scale = tokenData.randomNumber % 4 + 3;
            patternSize = 210;
        } else if (tokenData.shapeIndex == 4) {
            // line
            scale = tokenData.randomNumber % 5 + 1;
            patternSize = 50;
        }

        // --------------------------------------------------------
        // 
        //  Starting to build the SVG pattern
        // 
        // --------------------------------------------------------
        string memory pattern = string(
            abi.encodePacked(
                '<pattern id="p-',
                GuestlistedLibrary.toString(tokenData.tokenId),
                '" patternUnits="userSpaceOnUse" width="',
                GuestlistedLibrary.toString(patternSize),
                '" height="',
                GuestlistedLibrary.toString(patternSize),
                '" patternTransform="scale(',
                GuestlistedLibrary.toString(scale),
                ') rotate(',
                GuestlistedLibrary.toString(rotate),
                ')"><rect width="100%" height="100%" fill="#',
                tokenData.bg,
                '"/>'
            )
        );

        // --------------------------------------------------------
        // 
        //  Adding the shape and animations to the pattern
        // 
        // --------------------------------------------------------
        if (tokenData.shapeIndex == 0) {
            // circle
            uint position = tokenData.randomNumber % 70 + 30;
            uint radius = tokenData.randomNumber % 50 + 20;
            string memory random = string(abi.encodePacked(GuestlistedLibrary.toString(tokenData.randomNumber % 10), '.2'));

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<circle cx="',
                    GuestlistedLibrary.toString(position),
                    '" cy="',
                    GuestlistedLibrary.toString(position),
                    '" r="',
                    GuestlistedLibrary.toString(radius),
                    '" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.2"/>',
                    '<circle cx="',
                    GuestlistedLibrary.toString(position + radius - 50),
                    '" cy="',
                    GuestlistedLibrary.toString(position + radius - 50),
                    '" r="',
                    GuestlistedLibrary.toString(radius / 2),
                    '" fill="none" stroke="#'
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    tokenData.color,
                    '" stroke-width="0.2"><animate attributeName="stroke-width" values="0.2;',
                    random,
                    ';0.2" dur="20s" calcMode="paced" repeatCount="indefinite"/></circle>'
                )
            );

        } else if (tokenData.shapeIndex == 1) {
            // prism
            uint position = tokenData.randomNumber % 100;

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<polygon points="50,16 85,85 15,85 50,16" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.3"/><polygon points="',
                    GuestlistedLibrary.toString(position),
                    ',16 85,85 15,85 50,16" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.3"><animate id="polygon_animation_1_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '" begin="0s;polygon_animation_2_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '.end" attributeName="points"  from="'
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    GuestlistedLibrary.toString(position),
                    ',16 85,85 15,85 50,16" to="',
                    GuestlistedLibrary.toString(position + 50),
                    ',16 85,85 15,85 50,16"  dur="60s" calcMode="paced"/><animate id="polygon_animation_2_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '" begin="polygon_animation_1_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '.end" attributeName="points" from="',
                    GuestlistedLibrary.toString(position + 50),
                    ',16 85,85 15,85 50,16" to="',
                    GuestlistedLibrary.toString(position),
                    ',16 85,85 15,85 50,16"  dur="60s" calcMode="paced"/></polygon><line x1="'
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    GuestlistedLibrary.toString(position),
                    '" y1="16" x2="15" y2="85" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.3" stroke-dasharray="',
                    GuestlistedLibrary.toString(dasharray),
                    '"><animate id="line_animation_1_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '" begin="0s;line_animation_2_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '.end" attributeName="x1"  from="',
                    GuestlistedLibrary.toString(position)
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '" to="',
                    GuestlistedLibrary.toString(position + 50),
                    '"  dur="60s" calcMode="paced"/><animate id="line_animation_2_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '" begin="line_animation_1_',
                    GuestlistedLibrary.toString(tokenData.tokenId),
                    '.end" attributeName="x1" from="',
                    GuestlistedLibrary.toString(position + 50),
                    '" to="',
                    GuestlistedLibrary.toString(position),
                    '"  dur="60s" calcMode="paced"/></line>'
                )
            );

        } else if (tokenData.shapeIndex == 2) {
            // square
            uint size = tokenData.randomNumber % 100 + 40;
            uint random = tokenData.randomNumber % 50;

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<rect x="0" y="0" width="',
                    GuestlistedLibrary.toString(size),
                    '" height="',
                    GuestlistedLibrary.toString(size),
                    '" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.5"><animate attributeName="x" values="0;50;0" dur="60s" repeatCount="indefinite" calcMode="paced" /></rect><rect x="0" y="0" width="',
                    GuestlistedLibrary.toString(size + random),
                    '" height="',
                    GuestlistedLibrary.toString(size + random),
                    '" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.5"/>'
                )
            );

        } else if (tokenData.shapeIndex == 3) {
            // cube
            uint size = tokenData.randomNumber % 100 + 50;
            uint position = tokenData.randomNumber % 50 + 10;

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<rect x="0" y="0" width="',
                    GuestlistedLibrary.toString(size),
                    '" height="',
                    GuestlistedLibrary.toString(size),
                    '" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.5"></rect><rect x="',
                    GuestlistedLibrary.toString(position),
                    '" y="',
                    GuestlistedLibrary.toString(position),
                    '" width="'
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    GuestlistedLibrary.toString(size),
                    '" height="',
                    GuestlistedLibrary.toString(size),
                    '" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.5"><animate attributeName="x" values="',
                    GuestlistedLibrary.toString(position),
                    ';0;',
                    GuestlistedLibrary.toString(position),
                    '" dur="60s" repeatCount="indefinite" calcMode="paced" /><animate attributeName="y" values="',
                    GuestlistedLibrary.toString(position),
                    ';0;',
                    GuestlistedLibrary.toString(position),
                    '" dur="60s" repeatCount="indefinite" calcMode="paced" /></rect>'
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<line x1="0" y1="0" x2="',
                    GuestlistedLibrary.toString(position),
                    '" y2="',
                    GuestlistedLibrary.toString(position),
                    '" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.3" stroke-dasharray="',
                    GuestlistedLibrary.toString(dasharray)
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '"><animate attributeName="x2" values="',
                    GuestlistedLibrary.toString(position),
                    ';0;',
                    GuestlistedLibrary.toString(position),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/><animate attributeName="y2" values="',
                    GuestlistedLibrary.toString(position),
                    ';0;',
                    GuestlistedLibrary.toString(position),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/></line>'
                )
            );


            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<line x1="',
                    GuestlistedLibrary.toString(size),
                   '" y1="0" x2="',
                    GuestlistedLibrary.toString(position + size),
                    '" y2="',
                    GuestlistedLibrary.toString(position),
                    '" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.3" stroke-dasharray="',
                    GuestlistedLibrary.toString(dasharray)
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '">',
                    '<animate attributeName="x2" values="',
                    GuestlistedLibrary.toString(position + size),
                    ';',
                    GuestlistedLibrary.toString(size),
                    ';',
                    GuestlistedLibrary.toString(position + size),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/><animate attributeName="y2" values="',
                    GuestlistedLibrary.toString(position),
                    ';0;',
                    GuestlistedLibrary.toString(position),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/></line>'
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<line x1="0" y1="',
                    GuestlistedLibrary.toString(size),
                    '" x2="',
                    GuestlistedLibrary.toString(position),
                    '" y2="',
                    GuestlistedLibrary.toString(position + size),
                    '" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.3" stroke-dasharray="',
                    GuestlistedLibrary.toString(dasharray)
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '"><animate attributeName="x2" values="',
                    GuestlistedLibrary.toString(position),
                    ';0;',
                    GuestlistedLibrary.toString(position),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/><animate attributeName="y2" values="',
                    GuestlistedLibrary.toString(position + size),
                    ';',
                    GuestlistedLibrary.toString(size),
                    ';',
                    GuestlistedLibrary.toString(position + size),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/></line>'
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<line x1="',
                    GuestlistedLibrary.toString(size),
                    '" y1="',
                    GuestlistedLibrary.toString(size),
                    '" x2="',
                    GuestlistedLibrary.toString(position + size),
                    '" y2="',
                    GuestlistedLibrary.toString(position + size),
                    '" stroke="#',
                    tokenData.color,
                    '" stroke-width="0.3" stroke-dasharray="',
                    GuestlistedLibrary.toString(dasharray)
                )
            );

            pattern = string(
                abi.encodePacked(
                    pattern,
                    '"><animate attributeName="x2" values="',
                    GuestlistedLibrary.toString(position + size),
                    ';',
                    GuestlistedLibrary.toString(size),
                    ';',
                    GuestlistedLibrary.toString(position + size),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/><animate attributeName="y2" values="',
                    GuestlistedLibrary.toString(position + size),
                    ';',
                    GuestlistedLibrary.toString(size),
                    ';',
                    GuestlistedLibrary.toString(position + size),
                    '"  dur="60s" repeatCount="indefinite" calcMode="paced"/></line>'
                )
            );

        } else if (tokenData.shapeIndex == 4) {
            // line
            pattern = string(
                abi.encodePacked(
                    pattern,
                    '<line x1="0" y1="0" x2="0" y2="50" fill="none" stroke="#',
                    tokenData.color,
                    '" stroke-width="1"/>'
                )
            );
        } 
 
        pattern = string(
            abi.encodePacked(
                pattern,
                '</pattern>'
            )
        );
        // --------------------------------------------------------
        // 
        //  Building the SVG
        // 
        // --------------------------------------------------------
        drawing = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="850"><defs><style>.bg{fill: url(#p-',
                GuestlistedLibrary.toString(tokenData.tokenId),
                ') #',
                tokenData.bg,
                ';}.dj, .venue,.id, .location, .date {fill: #'
            )
        );

        drawing = string(
            abi.encodePacked(
                drawing,
                tokenData.color,
                ';font-family:Arial;font-weight:700;}.venue{font-size:60px;}.date{font-size:40px;}.location{font-size:30px;}.id{font-size:20px;}.figure{fill:none;stroke: #',
                tokenData.color,
                ';} .bg { transform-origin: center; animation: spin 120s linear infinite; }@keyframes spin{0% { transform: rotate(0deg) scale(1);} 50%{ transform: rotate(180deg) scale(2);} 100%{ transform: rotate(360deg) scale(1);}}</style>',
                pattern,
                '</defs>'
            )
        );

        drawing = string(
            abi.encodePacked(
                drawing,
                '<rect class="bg" x="-300" y="-425" width="1200" height="1700"/><text class="id" x="75" y="70"><tspan x="75" dy="0">#',
                GuestlistedLibrary.toString(tokenData.tokenId),
                '</tspan></text><text x="70" y="80" class="dj"><tspan x="70" dy="0" alignment-baseline="hanging" style="font-size:',
                GuestlistedLibrary.toString(tokenData.dj.fontSize),
                '">',
                tokenData.dj.firstName,
                '</tspan><tspan x="70" dy="',
                GuestlistedLibrary.toString(tokenData.dj.fontSize),
                '" alignment-baseline="hanging" style="font-size:',
                GuestlistedLibrary.toString(tokenData.dj.fontSize),
                '">'
            )
        );

        drawing = string(
            abi.encodePacked(
                drawing,
                tokenData.dj.lastName,
                '</tspan></text><text class="date" text-anchor="end" x="530" y="650">',
                tokenData.date,
                '</text><text class="venue" text-anchor="end" x="530" y="720">',
                tokenData.venue.name,
                '</text><text class="location" text-anchor="end" x="530" y="770">',
                tokenData.venue.location,
                '</text></svg>'
            )
        );

        drawing = Base64.encode(bytes(drawing));
        return string(abi.encodePacked("data:image/svg+xml;base64,", drawing));
    }

    constructor() {}
}