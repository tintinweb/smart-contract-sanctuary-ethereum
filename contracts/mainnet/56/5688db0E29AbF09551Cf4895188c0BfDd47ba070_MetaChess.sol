// SPDX-License-Identifier: CONSTANTLY WANTS TO MAKE THE WORLD BEAUTIFUL

// METACHESS - A ON-CHAIN CHESS MOVE GENERATOR COLLECTION FOR HUNDREDELEVEN COLLECTION
//               __    __    __    __
//           8 /__////__////__////__////
//          7 ////__////__////__////__/
//         6 /__////__////__////__////
//        5 ////__////__////__////__/
//       4 /__////__////__////__////
//      3 ////__////__////__////__/
//     2 /__////__////__////__////
//    1 ////__////__////__////__/
//       a  b  c  d  e  f  g  h
 
// THIS CHESS GAME HAS NO RULES. NO PAIN. NO GAIN. ON CHAIN.
// https://hundredeleven.art
// by berk aka princess camel aka guerrilla pimp minion bastard
// @berkozdemir

pragma solidity ^0.8.0;

contract MetaChess {

    string[] private pieceColor = [
        "White",
        "Black"
    ];

    string[] private colors = [
        "#fff",
        "#000"
    ];
    
    string[] private chessPiece = [
        "King",
        "Queen",
        "Rook",
        "Knight",
        "Bishop",
        "Pawn"
    ];
    
    string[] private chessX = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h"
    ];

    string[] private chessY = [
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8"
    ];
    
    
    
    
    function getRandom(uint256 tokenId, string memory keyPrefix, uint256 modulo) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(address(this), keyPrefix, toString(tokenId)))) % modulo;
    }

    function getPieceColor(uint256 tokenId) public view returns (string memory) {
        return pieceColor[ getRandom(tokenId, "pieceColor", 2) ];
    }
    function getChessPiece(uint256 tokenId) public view returns (string memory) {
        return chessPiece[ getRandom(tokenId, "chessPiece", 6)];
    }
    function getCoordinate(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(chessX[getRandom(tokenId, "chessX", 8)],
            chessY[ getRandom(tokenId, "chessY", 8) ]));
    }
    
    function generateImage(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 200 200"><style>.base { fill:',
            colors[ ( getRandom(tokenId, "pieceColor", 2) + 1 ) % 2 ],
            '; font-family: Arial Black; font-size: 14px; }</style><rect width="100%" height="100%" fill="',
            colors[ getRandom(tokenId, "pieceColor", 2)],
            '" /><text x="10" y="20" class="base">Move ',
            toString(tokenId),
            '</text><text text-anchor="middle" x="50%" y="60" class="base">',
            pieceColor[ getRandom(tokenId, "pieceColor", 2) ],
            '</text><text text-anchor="middle" x="50%" y="90" class="base">',
            chessPiece[ getRandom(tokenId, "chessPiece", 6)],
            '</text><text text-anchor="middle" x="50%" y="120" class="base">to</text><text text-anchor="middle" x="50%" y="150" class="base">',
            chessX[getRandom(tokenId, "chessX", 8)],
            chessY[ getRandom(tokenId, "chessY", 8) ], "</text></svg>" ));

    }

    function getMetadataJSON(uint256 tokenId) public view returns (string memory) {
        string memory image = generateImage(tokenId);
        string memory json = string(abi.encodePacked('{"name": "#', toString(tokenId), ' - MetaChess", "description": "HundredEleven is a cryptoart metacollection with interchangeable metadata, created by berk aka princesscamel aka guerrilla pimp minion bastard. Holders of a NFT from this series can swap the active metadata within collections on-chain. Visit https://hundredeleven.art for more info about the metacollection and interacting with tokens. Current collection shown in this token is MetaChess - randomly generated chess moves. this is a chess game with no rules. no pain, no gain, on-chain.", "external_url": "https://hundredeleven.art/collection/5/token/',toString(tokenId),'", "artist": "berk aka princesscamel aka guerrilla pimp minion bastard", "media_type": "image", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '","attributes":[{"trait_type": "Collection", "value": "MetaChess"' , '}]}'));
        return json;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory base64JSON = Base64.encode(bytes(getMetadataJSON(tokenId)));
        return string(abi.encodePacked('data:application/json;base64,',base64JSON));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('{"name": "MetaChess", "description": "randomly generated chess moves. this is a chess game with no rules. no pain, no gain, on-chain.", "artist": "berk aka princesscamel aka guerrilla pimp minion bastard", "external_link": "https://hundredeleven.art/collection/5", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(generateImage(69))),'"}'));
    }
   
    function toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
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