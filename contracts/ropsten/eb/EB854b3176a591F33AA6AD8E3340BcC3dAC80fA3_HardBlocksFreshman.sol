// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Base64.sol";
import "./Strings.sol";
import "./HardBlocksStudent.sol";

contract HardBlocksFreshman is IHardBlocksStudent {
    using Strings for uint256;

    function tokenURI(
        uint256 tokenId,
        string memory studentName,
        uint256 score
    ) override external pure returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "', studentName,'",',
                                '"description": "For the self-taught web3 developer: ',
                                'School of Hard Blocks. Freshman year now enrolling.",',
                                '"image": "data:image/svg+xml;base64,',
                                genSVG(tokenId, studentName, score),
                                '","attributes":',
                                '[{"trait_type": "Score", "value": ', score.toString(), '}]',
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function genSVG(uint256 tokenId, string memory studentName, uint256 currentScore)
        private 
        pure 
        returns (string memory)  {

            require(currentScore < 6, 'OutOfBounds'); 
            require(currentScore > 0, 'OutOfBounds');

            string[32] memory canvas; 
            uint256 length  = bytes(studentName).length; 
            string memory wholeOutput;

            // for shimmer only.
            string memory seqStr = '0.1;0.2;0.3;0.4;0.5';
            uint8[9] memory sequence = [9, 7, 4, 7, 9, 7, 4, 7, 9];
            
            string[6] memory extraText; 
            bytes1 emptyChar = bytes(" ")[0];

            extraText[0] = '<text x="5" y="';
            extraText[1] = '" xml:space="preserve"  class="';
            extraText[2] = '">';
            extraText[3] = '<animate attributeName="opacity"  values="'; 
            extraText[4] = '" dur="3s" repeatCount="indefinite"/>';
            extraText[5] = '</text>';

            wholeOutput = '<g transform="scale(4)"> <rect width="200" height="345" fill="#010101" />';
            
            uint256 yVal;

            // prepare the string array of text values for the ground section. 
            canvas = _drawGround(canvas, tokenId, emptyChar);

            canvas[31] = _text(canvas[31],   studentName,    length,   0); 
            canvas[31] = _text(canvas[31],   string(abi.encodePacked("0x_0", currentScore.toString(), " ")),    6,   26); 

            for (uint256 thisLine = 0; thisLine < 32; thisLine++) {

                yVal = thisLine*10 + 20;
            
                if (currentScore == 5) {
                    seqStr = rotateByX(thisLine, sequence, seqStr);
                    wholeOutput = string(abi.encodePacked(
                        wholeOutput, extraText[0], yVal.toString(), 
                        extraText[1], "ground", extraText[2], extraText[3],
                        seqStr,
                        extraText[4]
                        ));

                    wholeOutput = string(abi.encodePacked(
                        wholeOutput,
                        canvas[thisLine], 
                        extraText[5]
                        ));
                } else {
                    wholeOutput = string(abi.encodePacked(
                        wholeOutput, extraText[0], yVal.toString(), 
                        extraText[1], "ground", extraText[2], 
                        canvas[thisLine], 
                        extraText[5]));
                }

            }

            // template
            wholeOutput = string(abi.encodePacked(wholeOutput, 
                rw(80, 70, 35, 20, 'hair'), 
                rw(75, 80, 5, 50, 'hair'),
                rw(115, 80, 5, 50, 'hair'),
                rw(70, 90, 5, 20, 'hair'),
                rw(120, 90, 5, 20, 'hair'),
                rw(80, 130, 35, 40, 'skin'),
                rw(75, 130, 5, 30, 'skin'),
                rw(115, 130, 5, 20, 'skin')
                ));

            wholeOutput = string(abi.encodePacked(wholeOutput, 
                rw(85, 170, 25, 10, 'skin'),
                rw(90, 180, 10, 10, 'skin'),
                rw(70, 110, 5, 20, 'skin'),
                rw(120, 110, 5, 20, 'skin'),
                rw(80, 90, 5, 40, 'skin'),
                rw(80, 90, 35, 10, 'skin'),
                rw(95, 90, 5, 40, 'skin'),
                rw(110, 90, 5, 40, 'skin')
                ));

            wholeOutput = string(abi.encodePacked(wholeOutput, 
                rw(80, 190, 35, 40, 'shirt'),
                rw(85, 180, 5, 10, 'shirt'),
                rw(100, 180, 10, 10, 'shirt'),
                rw(75, 200, 5, 20, 'skin'),
                rw(110, 200, 5, 20, 'skin'),
                rw(100, 210, 10, 10, 'skin'),
                rw(80, 230, 15, 20, 'pants'),
                rw(95, 230, 5, 10, 'pants')
                ));

            wholeOutput = string(abi.encodePacked(wholeOutput, 
                rw(100, 230, 15, 20, 'pants'),
                rw(80, 250, 10, 10, 'pants'),
                rw(105, 250, 10, 10, 'pants'),
                rw(80, 260, 10, 10, 'grey'),
                rw(105, 260, 10, 10, 'grey'),
                rw(90, 160, 15, 10, 'black'),
                rw(85, 120, 5, 10, 'white'),
                rw(100, 120, 5, 10, 'white')
                ));

            // beards: 
            if (tokenId % 13 == 0) {
                // large beard
                wholeOutput = string(abi.encodePacked(wholeOutput, 
                    rw(75, 130, 5, 30, 'hair'),
                    rw(115, 130, 5, 30, 'hair'),
                    rw(90, 150, 10, 10, 'hair'),
                    rw(80, 160, 10, 10, 'hair'),
                    rw(100, 160, 10, 20, 'hair'),
                    rw(110, 150, 5, 20, 'hair'),
                    rw(85, 170, 5, 10, 'hair'),
                    rw(90, 170, 10, 20, 'hair')
                )); 
            } else if (tokenId % 13 == 1) {
                //small beard
                wholeOutput = string(abi.encodePacked(wholeOutput, 
                    rw(85, 150, 5, 30, 'hair'),
                    rw(100, 150, 5, 30, 'hair'),
                    rw(90, 150, 10, 10, 'hair'),
                    rw(90, 170, 10, 20, 'hair')
                ));
            }
        
            // hair (only for score > 1; and not everyone with score > 1).
            if (currentScore > 1) {
                if (tokenId % 7 == 0) {
                    // bald
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(80, 70, 35, 10, 'skin'),
                        rw(85, 80, 25, 10, 'skin')
                    ));
                } else if (tokenId % 7 == 1) {
                    // bob
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(60, 160, 5, 10, 'hair'),
                        rw(65, 170, 10, 10, 'hair'),
                        rw(70, 130, 5, 30, 'hair'),
                        rw(70, 130, 10, 10, 'hair'),
                        rw(70, 160, 10, 10, 'hair')
                    ));
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(115, 130, 5, 50, 'hair'),
                        rw(120, 130, 5, 60, 'hair'),
                        rw(125, 110, 5, 40, 'hair'),
                        rw(125, 180, 5, 10, 'hair'),
                        rw(130, 170, 5, 10, 'hair')
                    ));
                } else if (tokenId % 7 == 2) {
                    // fringe
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(80, 90, 5, 50, 'hair'),
                        rw(85, 90, 5, 30, 'hair'),
                        rw(75, 130, 5, 30, 'hair'),
                        rw(105, 90, 5, 20, 'hair'),
                        rw(110, 90, 5, 50, 'hair'),
                        rw(120, 130, 5, 30, 'hair')
                    ));
                } else if (tokenId % 7 == 3) {
                    // long hair
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(75, 130, 5, 40, 'hair'),
                        rw(125, 110, 5, 50, 'hair'),
                        rw(120, 130, 5, 40, 'hair'),
                        rw(115, 130, 5, 50, 'hair')
                    ));
                }
            }

            // accessories (only for score > 2).
            if (currentScore > 2) {
                if (tokenId % 5 == 0) {
                    // phone
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(95, 190, 10, 20, 'black'),
                        rw(95, 210, 5, 10, 'black')
                    ));
                } else if (tokenId % 5 == 1 ) {
                    // bag
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(105, 210, 5, 20, 'acc'),
                        rw(100, 230, 15, 30, 'acc')
                    ));
                } else if ( tokenId % 5 == 2) {
                    // cape
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(85, 180, 5, 10, 'acc'),
                        rw(90, 190, 10, 10, 'acc'),
                        rw(100, 180, 15, 10, 'acc'),
                        rw(115, 190, 5, 80, 'acc'),
                        rw(90, 250, 15, 10, 'acc'),
                        rw(95, 240, 5, 10, 'acc'),
                        rw(90, 260, 5, 10, 'acc')
                    ));
                } else if ( tokenId % 5 == 3) {
                    // book
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(90, 200, 10, 40, 'acc'),
                        rw(100, 200, 5, 10, 'acc'),
                        rw(100, 220, 5, 20, 'acc')
                    ));
                } else {
                    // tie 
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(93, 190, 4, 30, 'acc'),
                        rw(90, 180, 10, 10, 'acc')
                    ));
                }
            }


        // hats (everyone score > 3)
            if (currentScore > 3) {
                if (tokenId % 4 == 0) {
                    // ponytail + bow.
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(120, 50, 10, 10, 'hair'),
                        rw(120, 60, 15, 10, 'hair'),
                        rw(120, 70, 20, 10, 'hair'),
                        rw(130, 80, 10, 20, 'hair'),
                        rw(135, 100, 5, 10, 'hair')
                    ));
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(110, 50, 5, 10, 'acc'),
                        rw(110, 60, 10, 10, 'acc'),
                        rw(105, 70, 15, 10, 'acc'),
                        rw(120, 80, 10, 10, 'acc'),
                        rw(120, 90, 15, 10, 'acc'),
                        rw(125, 100, 5, 10, 'acc')
                    ));
                } else if (tokenId % 4 == 1) {
                    // cap
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(75, 50, 35, 40, 'acc'),
                        rw(55, 80, 20, 10, 'acc'),
                        rw(110, 60, 5, 30, 'acc'),
                        rw(115, 70, 5, 20, 'acc'),
                        rw(80, 60, 10, 20, 'shirt')
                    ));
                } else if (tokenId % 4 == 2) {
                    // crown
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(75, 70, 45, 20, 'gold'),
                        rw(70, 60, 5, 10, 'gold'),
                        rw(120, 60, 5, 10, 'gold'),
                        rw(90, 60, 15, 10, 'gold'),
                        rw(95, 50, 5, 10, 'gold'),
                        rw(90, 60, 15, 10, 'gold')
                    ));
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(95, 70, 5, 10, 'acc')
                    ));
                } else {
                    // graduate
                    wholeOutput = string(abi.encodePacked(wholeOutput, 
                        rw(70, 50, 55, 10, 'grey'),
                        rw(85, 60, 25, 10, 'grey'),
                        rw(115, 50, 5, 30, 'shirt')
                    ));
                }
            }


            // reuse the canvas variable to select colours.
            canvas = _drawColours(canvas);


            // no, not random. But not simple. 
            sequence[0] = uint8(26 + (uint256(keccak256(abi.encodePacked(tokenId.toString(), 'text')))) % 6);
            sequence[1] = uint8(0 + (uint256(keccak256(abi.encodePacked(tokenId.toString(), 'skin')))) % 4);
            sequence[2] = uint8(4 + (uint256(keccak256(abi.encodePacked(tokenId.toString(), 'hair')))) % 6);
            sequence[3] = uint8(10 + (uint256(keccak256(abi.encodePacked(tokenId.toString(), 'shirt')))) % 6);
            sequence[4] = uint8(20 + (uint256(keccak256(abi.encodePacked(tokenId.toString(), 'pants')))) % 4);
            sequence[5] = uint8(26 + (uint256(keccak256(abi.encodePacked(tokenId.toString(), 'acc')))) % 6);

            wholeOutput = string(abi.encodePacked(wholeOutput, 
                '<rect x = "191" y = "321" width="5" height="12" style="fill:rgb(255,255,255)" >',
                '<animate attributeName="fill" values="black;black;black;white;white;white" dur="1s" repeatCount="indefinite" />',
                '</rect> <!-- DadJokeLabs-->  </g> </svg>'));

            wholeOutput = string(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 800 1380">',
                '<style>.ground { fill: ',
                canvas[sequence[0]],
                ';font-family: monospace; font-size: 10px; } .skin { fill: ',
                canvas[sequence[1]],
                ';} .hair {fill: ',
                canvas[sequence[2]],
                ';}.shirt {fill: ',
                canvas[sequence[3]],
                ';}.pants {fill: ',
                canvas[sequence[4]],
                ';}.acc {fill: ',
                canvas[sequence[5]],
                ';} .black {fill: #000000;} .white {fill: #FFFFFF;}',
                '.gold {fill: #FCE500;} .grey {fill: #222222;}',
                '</style>',
                wholeOutput));

            return Base64.encode(abi.encodePacked(wholeOutput));

    }  // of _draw function

    function _drawGround(string[32] memory canvas, uint256 tokenId, bytes1 emptyChar) 
    private 
    pure 
    returns (string[32] memory) {
        
        string memory holder;

        for (uint256 k = 0; k < 17; k++) {

            if ((tokenId+k) % 8 == 0) {
                holder = 'struct Transaction { address to;';
            } else if ((tokenId+k) % 8 == 1) {
                holder = 'unit value; bytes data; bool exe';
            } else if ((tokenId+k) % 8 == 2) {
                holder = 'uint numConfirmations uint value';
            } else if ((tokenId+k) % 8 == 3) {
                holder = 'public pure returns (bool) {byte';
            } else if ((tokenId+k) % 8 == 4) {            
                holder = 'mapping(address => bool) public ';
            } else if ((tokenId+k) % 8 == 5) {    
                holder = ' interface IERC721 is IERC165 { ';
            } else if ((tokenId+k) % 8 == 6) {    
                holder = 'require(isOwner[msg.sender],xy);';
            } else if ((tokenId+k) % 8 == 7) {    
                holder = 'function isApprovedForAll(addres';
            }

            if (k == 15 || k == 16) {
                canvas[k] = holder;
            } else if  (k < 8) {
                canvas[k] = '                                ';
                    for (uint thisChar = (15-k); thisChar < (16+k); thisChar++) {
                        bytes(canvas[k])[thisChar] = bytes(holder)[thisChar];
                    }
                canvas[31-k] = string(copyBytes(bytes(canvas[k])));
            } else if ( k < 15) {
                canvas[k] = holder;
                    for (uint thisChar = 0; thisChar < (15-k); thisChar++) {
                        bytes(canvas[k])[thisChar] = emptyChar;
                    }
                    for (uint thisChar = (17+k); thisChar < 32; thisChar++) {
                        bytes(canvas[k])[thisChar] = emptyChar;
                    }
                canvas[31-k] = string(copyBytes(bytes(canvas[k])));
            }

        }
        return canvas; 
    } // of _drawGround function.

    function copyBytes(bytes memory _bytes) private pure returns (bytes memory) {
        bytes memory bytesCopy = new bytes(_bytes.length);
        uint256 bytesLength = _bytes.length + 31;
        for (uint256 i = 32; i <= bytesLength; i += 32)
        {
            assembly { mstore(add(bytesCopy, i), mload(add(_bytes, i))) }
        }
        return bytesCopy;
    }

    function _text(string memory baseline, string memory message, uint256 messageLength, uint256 x) 
    private 
    pure 
    returns (string memory) {
        for (uint256 i = 0; i < messageLength; i++) {
            bytes(baseline)[x + i] = bytes(message)[i];
        }
        return baseline;
    } // of _text function.


    function rotateByX(uint256 move, uint8[9] memory sequence, string memory seqStr) 
    private 
    pure 
    returns (string memory)  {

        if (move >= 5) {
            move = move % 5;
        }
        
        for (uint8 thisChar = 0; thisChar < 5; thisChar++) {
            bytes(seqStr) [(4*thisChar) + 2] = bytes(uint256(sequence[move + thisChar]).toString())[0];
        }

        return seqStr;

    } // of rotationFunction.


    function _drawColours(string[32] memory canvas)
    private 
    pure
    returns (string[32] memory) {
        // skin: 4 options.
        canvas[0] =  '#ffcc99'; // Lightest skin
        canvas[1] =  '#f1c27d'; // Middle light
        canvas[2] =  '#c68642'; // Middle dark
        canvas[3] =  '#8d5524'; // Darkest skin
        // hair: 6 options. 
        canvas[4] =  '#a2826d'; // Brown
        canvas[5] =  '#3a1413'; // Maroon
        canvas[6] =  '#191207'; // Black
        canvas[7] =  '#FFF5e1'; // White Blonde
        canvas[8] = '#4bc8f4'; // Blue
        canvas[9] = '#e27589'; // Pink
        // shirt: 6 options 
        canvas[10] =  '#1166ff'; // Heroic Blue
        canvas[11] =  '#00ff7c'; // Spring Grass
        canvas[12] =  '#ff7f50'; // Coral
        canvas[13] = '#f1ff62'; // Lemon Pie
        canvas[14] =  '#FFFFFF'; // White
        canvas[15] =  '#00fdff'; // Fluorescent Turquoise
        // pants: 4 options 
        canvas[16] = '#373e02'; // Dark Olive
        canvas[17] = '#4f1507'; // Earth Brown
        canvas[18] = '#112222'; // Dark Water
        canvas[19] = '#1560bd'; // Denim
        // acc: 6 options 
        canvas[20] =  '#fe01b1'; // Bright Pink
        canvas[21] =  '#87fd05'; // Bright Lime
        canvas[22] =  '#9f00ff'; // Vivid Violet
        canvas[23] =  '#89939a'; // Bright Silver
        canvas[24] = '#ffff14 '; // YellowSubmarine
        canvas[25] = '#FF0080'; // Fuschia
        // text: 6 options
        canvas[26] = '#C39953'; // Burnt Gold
        canvas[27] = '#FF404C'; // 'Sunburnt cyclops'
        canvas[28] = '#0066FF'; // Bright Blue
        canvas[29] = '#33FF33'; // Apple II green.
        canvas[30] = '#676767'; // grey
        canvas[31] = '#5946B2'; // purple
    
        return canvas;
    }

    function rw(uint256 x, uint256 y, uint256 width, uint256 height, string memory class) 
    private 
    pure 
    returns (string memory) {
        class = string(abi.encodePacked(
            '<rect x = "',
            x.toString(),
            '" y = "',
            y.toString(),
            '" width="',
            width.toString(),
            '" height="',
            height.toString(),
            '" class="',
            class,
            '" />'
        ));
        return class;
    }

}

/// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.0;

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

    function ENCODE(string memory) internal pure returns (string memory) {
        return "CaSe mAttERs";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
    //from:  "@openzeppelin/contracts/utils/Strings.sol";
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IHardBlocksStudent {
    function tokenURI(
        uint256 tokenId,
        string memory studentName,
        uint256 score
    ) external view returns (string memory);
}