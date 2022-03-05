// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./core/TinyExplorersTypes.sol";
// import "hardhat/console.sol";


contract TinyExplorersRenderer is Ownable, ReentrancyGuard {
    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct Buffer {
        string one;
        string two;
        string three;
        string four;
        string five;
        string six;
        string seven;
        string eight;
    }

    struct Color {
        string hexString;
    }

    struct Layer {
        string name;
        bytes hexString;
    }

    struct LayerInput {
        string name;
        bytes hexString;
        uint8 layerIndex;
        uint8 itemIndex;
    }

    uint256 public constant NUM_LAYERS = 9; // 5 + 5 ? // Chainrunners = 13;
    uint256 public constant NUM_PALETTES = 10; //10;
    uint256 public constant NUM_COLORS = 5;
    uint256 public constant NUM_BACKGROUND_PALETTES = 1;
    uint256 public constant NUM_BACKGROUND_COLORS = 12;
    

    mapping(uint256 => Layer) [NUM_LAYERS] layers;

    /*
    This indexes into a layer index, then an array capturing the frequency each layer should be selected.
    Shout out to Anonymice & Chainrunners for the rarity impl inspiration.
    */
    uint16[][NUM_LAYERS] WEIGHTS;
    string[][NUM_PALETTES] COLORS;
    string[][NUM_BACKGROUND_PALETTES] BACKGROUND_COLORS;

    constructor() {
        // Total 8192
        // Backgrounds 
        WEIGHTS[0] = [8192]; //[921, 921, 921, 921, 921, 921, 921, 926, 102, 102, 102, 102, 102, 102, 102, 105];
        // Shoulders - 0
        WEIGHTS[1] = [8001, 191]; 
        // Faces - 0
        WEIGHTS[2]= [162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 162, 167, 83, 83, 83];
        // Hairs - 0
        WEIGHTS[3] = [390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 390, 392];
        // Facial Hairs - 1
        WEIGHTS[4] = [401, 401, 401, 401, 401, 401, 401, 401, 401, 401, 401];
        // Masks - 1
        // WEIGHTS[4] = [97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 97, 29, 29, 29, 29, 29, 5, 5617];
        WEIGHTS[5] = [129, 129, 129, 129, 29, 7647];
        // Goggles - 1
        WEIGHTS[6] = [143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 143, 4617];
        // Hats - 1
        //WEIGHTS[6] = [73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 73, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 4334];
        WEIGHTS[7] = [83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 83, 3793];
        // Face Accessories - 1
        WEIGHTS[8] = [203, 203, 203, 203, 203, 203, 203, 203, 203, 203, 203, 203, 203, 203, 203, 5147];
        // Backgrounds
        
        // COLORS
        COLORS[0] = ['ffbfb2', 'ffb0a0', 'df8876', 'ac503d', 'cd705d'];
        COLORS[1] = ['DCE9EF', '96BDCF', '9088A7', '72649C', '39324E'];
        COLORS[2] = ['CEDEDC', 'B0C9C6', '89A3AF', '65768E', '455161'];
        COLORS[3] = ['D2AD8C', 'A36E4E', '925452', '613837', '402524'];
        COLORS[4] = ['D49FAD', 'C47C8F', 'B45971', '824654', '61343F'];
        COLORS[5] = ['CF7B72', 'C2574C', 'A34238', '7D332B', '4F1F1A'];
        COLORS[6] = ['DDD6B0', 'CEC38C', '868A6E', '6A6E57', '425044'];
        COLORS[7] = ['79B6AA', '509386', '3E7268', '2C514A', '123142'];
        COLORS[8] = ['7F7C7C', '585656', '523E3E', '352828', '271D1D'];
        COLORS[9] = ['98AC7F', '7F9662', '557759', '405943', '2B3B2D'];
        //COLORS[10]= ['F2E4AA', 'EBD67E', 'E4C852', 'B2885F', '966F48'];

        BACKGROUND_COLORS[0] = ["faf2e5", "f6f4ed", "fcefdf", "fff8e7", "f0f0e8", "F6F1EC", "F1F0F0", "F3EDED", "261C2C", "37263B","1F1D36", "041C32"];
        //BACKGROUND_COLORS[1] = ["1A1A40", "1F1D36", "041C32", "261C2C", "33313B", "303A52", "191919"];
    }


    function setLayers(LayerInput[] calldata toSet) external onlyOwner {
        for (uint16 i = 0; i < toSet.length; i++) {
            layers[toSet[i].layerIndex][toSet[i].itemIndex] = Layer(toSet[i].name, toSet[i].hexString);
        }
    }

    function getLayer(uint8 layerIndex, uint8 itemIndex) public view returns (Layer memory) {
        return layers[layerIndex][itemIndex];
    }

    function generateHash(uint256 tokenId) public view returns (uint256){
        return uint256(
            keccak256(
                abi.encodePacked(
                tokenId,
                msg.sender,
                block.difficulty,
                block.timestamp
                )
                )
        );
    }

    /*
    Generate base64 encoded tokenURI.

    All string constants are pre-base64 encoded to save gas.
    Input strings are padded with spacing/etc to ensure their length is a multiple of 3.
    This way the resulting base64 encoded string is a multiple of 4 and will not include any '=' padding characters,
    which allows these base64 string snippets to be concatenated with other snippets.
    */
    // function tokenURI(uint256 tokenId, TinyExplorersTypes.TinyExplorer memory explorerData) public view returns (string memory) {
    //    (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = getTokenData(explorerData.dna);
    //    string memory attributes;
    //    for (uint8 i = 0; i < numTokenLayers; i++) {
    //        attributes = string(abi.encodePacked(attributes,
    //            bytes(attributes).length == 0 ? 'eyAg' : 'LCB7',
    //            'InRyYWl0X3R5cGUiOiAi', traitTypes[i], 'IiwidmFsdWUiOiAi', tokenLayers[i].name, 'IiB9'
    //            ));
    //    }
    //    string[4] memory svgBuffers = tokenSVGBuffer(tokenLayers, tokenPalettes, numTokenLayers);
    //    return string(abi.encodePacked(
    //            'data:application/json;base64,eyAgImltYWdlX2RhdGEiOiAiPHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+',
    //            svgBuffers[0], svgBuffers[1], svgBuffers[2], svgBuffers[3],
    //            'PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4gIiwgImF0dHJpYnV0ZXMiOiBb',
    //            attributes,
    //            'XSwgICAibmFtZSI6IkV4cGxvcmVyICM',
    //            Base64.encode(uintToByteString(tokenId, 6)),
    //            'IiwgImRlc2NyaXB0aW9uIjogIlRpbnkgRXhwbG9yZXJzIGFyZSAxMDAlIGdlbmVyYXRlZCBvbi1jaGFpbi4ifSA'
    //        ));
    // }

    function tokenSVG(uint256 _dna) public view returns (string memory) {
        (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes) = getTokenData(_dna);
        string[4] memory buffer256 = tokenSVGBuffer(tokenLayers, tokenPalettes, numTokenLayers);
        return string(abi.encodePacked(
                "PHN2ZyBzaGFwZS1yZW5kZXJpbmc9ImNyaXNwRWRnZXMiIHZlcnNpb249IjEuMSIgdmlld0JveD0iMCAwIDMyMCAzMjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+",
                buffer256[0], buffer256[1], buffer256[2], buffer256[3],
                "PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4"
            )
        );
    }

    /*
    Get layers. Race index represents the "type" of base character:
    This allows skull/bot characters to have distinct trait distributions.
    */

    function getLayerIndex(uint16 _dna, uint8 _index) public view returns (uint) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < WEIGHTS[_index].length; i++) {
            percentage = WEIGHTS[_index][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return WEIGHTS[_index].length;
    }


    function getTokenData(uint256 _dna) public view returns (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string [NUM_LAYERS] memory traitTypes) {
        uint16[NUM_LAYERS] memory dna = splitNumber(_dna);
        uint8[NUM_LAYERS] memory paletteIndices = randomPalette(_dna);

        bool isPirateAndHasKingdom = false; // 
        //bool hasGoggle = dna[5] < WEIGHTS[5][25];
        bool hasMask = dna[5] < (8192 - WEIGHTS[5][5]); //false
        bool hasGoggles = dna[6] < (8192 - WEIGHTS[6][25]);
        bool hasHat = dna[7] < (8192 - WEIGHTS[7][53]); 
        // 8 - face accessory
        //bool hasFaceAcc = dna[8] < WEIGHTS[8][15]; 
        
        for (uint8 i = 0; i < NUM_LAYERS; i ++) {
            // console.log("this is for loop index:");
            // console.log(i);
            // console.log("this is even more outside:" );
            // console.log(getLayerIndex(dna[i], i));
            Layer memory layer = layers[i][getLayerIndex(dna[i], i)];

            if (layer.hexString.length > 0) {
                /*
                These conditions help make sure layer selection meshes well visually.
                1. If mask, no face acc/goggles. 
                3. If hat, no hair ?
                4. If mask is not a goggle no facial hair

                */
                //console.log("This is outside!: ");
                //console.log(i);
                if (isPirateAndHasKingdom) {
                    continue;
                } else {
                    if ( (i == 4 && hasGoggles && !hasMask) || (i == 8 && !hasMask ) || (i == 6 && !hasMask) || (i == 3 && !hasHat) || (i < 3 || i == 5 || i == 7) ) {
                        // console.log("this is if condition:");
                        // console.log(i);
                        tokenLayers[numTokenLayers] = layer;
                        tokenPalettes[numTokenLayers] = palette(paletteIndices[i], i, dna[0]); //dna[7]
                        traitTypes[numTokenLayers] = ["QmFja2dyb3VuZCAg", "U2hvdWxkZXJz", "RmFjZSAg","SGFpciAg", "RmFjaWFsSGFpciAg", "TWFzaw==", "R29nZ2xl", "SGF0" ,"RmFjZUFjY2Vzc29yeQ=="][i];
                        numTokenLayers++;
                    } else {
                        continue;
                    }
                    
                }
            }
        }
        return (tokenLayers, tokenPalettes, numTokenLayers, traitTypes);
    }

    function palette(uint8 index, uint8 idx, uint16 _dna) internal view returns (Color [NUM_COLORS] memory) {
        Color [NUM_COLORS] memory colors;
        for (uint16 i = 0; i < NUM_COLORS; i++) {
            // console.log(Base64.encode(bytes(abi.encodePacked( COLORS[index][i]  ))));
            if (idx == 0) {
                colors[i].hexString = Base64.encode(bytes(abi.encodePacked( BACKGROUND_COLORS[0][uint8(_dna % NUM_BACKGROUND_COLORS)] )));
            } else {
                colors[i].hexString = Base64.encode(bytes(abi.encodePacked( COLORS[index][i]  )));
            }
        
        }
        return colors;
    }

    //function background(uint8 index) internal view returns (Color [NUM_COLORS] memory) {
    //    Color [NUM_COLORS] memory colors;
    //    for (uint16 i = 0; i < 1; i++) {
    //        // console.log(Base64.encode(bytes(abi.encodePacked( COLORS[index][i]  ))));
    //        colors[i].hexString = Base64.encode(bytes(abi.encodePacked( BACKGROUND_COLORS[index][i]  )));
    //    }
    //    return colors;
    //}


    function colorForIndex(Layer[NUM_LAYERS] memory tokenLayers, uint k, uint index, Color [NUM_COLORS][NUM_LAYERS] memory palettes, uint numTokenLayers) internal view returns (string memory) {
        for (uint256 i = numTokenLayers - 1; i >= 0; i--) {
            //console.log(i);
            //console.log("numTokenLayers: ");
            //console.log(numTokenLayers);
            if (colorIndex(tokenLayers[i].hexString, k, index) == 0 && i == 0) {
                return "MDAwMDAw";
            } else if (colorIndex(tokenLayers[i].hexString, k, index) == 0 ) {
                continue;
            } else {
                //console.log(colorIndex(tokenLayers[i].hexString, k, index));
                Color memory fg = palettes[i][colorIndex(tokenLayers[i].hexString, k, index)-1];
                //console.log(fg.hexString);
                return fg.hexString;
            }
            
        }
        return "MDAwMDAw";
    }

    /*
    Each color index is 3 bits (there are 8 colors, so 3 bits are needed to index into them).
    Since 3 bits doesn't divide cleanly into 8 bits (1 byte), we look up colors 24 bits (3 bytes) at a time.
    "k" is the starting byte index, and "index" is the color index within the 3 bytes starting at k.
    */
    function colorIndex(bytes memory data, uint k, uint index) internal pure returns (uint8) {
        //console.log(uint8(data[k]));
        if (index == 0) {
            return uint8(data[k]) >> 5;
        } else if (index == 1) {
            return (uint8(data[k]) >> 2) % 8;
        } else if (index == 2) {
            return ((uint8(data[k]) % 4) * 2) + (uint8(data[k + 1]) >> 7);
        } else if (index == 3) {
            return (uint8(data[k + 1]) >> 4) % 8;
        } else if (index == 4) {
            return (uint8(data[k + 1]) >> 1) % 8;
        } else if (index == 5) {
            return ((uint8(data[k + 1]) % 2) * 4) + (uint8(data[k + 2]) >> 6);
        } else if (index == 6) {
            return (uint8(data[k + 2]) >> 3) % 8;
        } else {
            return uint8(data[k + 2]) % 8;
        }
    }

    /*
    Create 4 svg rects, pre-base64 encoding the svg constants to save gas.
    */
    function pixel4(string[32] memory lookup, SVGCursor memory cursor) internal pure returns (string memory result) {
        // console.log(lookup[cursor.x]);
        // console.log("Test");
        return string(abi.encodePacked(
                "PHJlY3QgICBmaWxsPScj", cursor.color1, "JyAgeD0n", lookup[cursor.x], "JyAgeT0n", lookup[cursor.y],
                "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color2, "JyAgeD0n", lookup[cursor.x + 1], "JyAgeT0n", lookup[cursor.y],
                "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color3, "JyAgeD0n", lookup[cursor.x + 2], "JyAgeT0n", lookup[cursor.y],
                "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color4, "JyAgeD0n", lookup[cursor.x + 3], "JyAgeT0n", lookup[cursor.y], "JyAgIC8+"
            ));
    }

    /*
    Generate svg rects, leaving un-concatenated to save a redundant concatenation in calling functions to reduce gas.
    Shout out to Blitmap for a lot of the inspiration for efficient rendering here.
    */
    function tokenSVGBuffer(Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers) public view returns (string[4] memory) {
        // Base64 encoded lookups into x/y position strings from 010 to 310.
        string[32] memory lookup = ["MDAw", "MDEw", "MDIw", "MDMw", "MDQw", "MDUw", "MDYw", "MDcw", "MDgw", "MDkw", "MTAw", "MTEw", "MTIw", "MTMw", "MTQw", "MTUw", "MTYw", "MTcw", "MTgw", "MTkw", "MjAw", "MjEw", "MjIw", "MjMw", "MjQw", "MjUw", "MjYw", "Mjcw", "Mjgw", "Mjkw", "MzAw", "MzEw"];
        // string[32] memory lookup =["MQ==","Mg==","Mw==","NA==","NQ==","Ng==","Nw==","OA==","OQ==","MTA==","MTE==","MTI==","MTM==","MTQ==","MTU==","MTY==","MTc==","MTg==","MTk==","MjA==","MjE==","MjI==","MjM==","MjQ==","MjU==","MjY==","Mjc==","Mjg==","Mjk==","MzA==","MzE==","MzI=="];
        SVGCursor memory cursor;

        /*
        Rather than concatenating the result string with itself over and over (e.g. result = abi.encodePacked(result, newString)),
        we fill up multiple levels of buffers.  This reduces redundant intermediate concatenations, performing O(log(n)) concats
        instead of O(n) concats.  Buffers beyond a length of about 12 start hitting stack too deep issues, so using a length of 8
        because the pixel math is convenient.
        */
        Buffer memory buffer4;
        // 4 pixels per slot, 32 total.  Struct is ever so slightly better for gas, so using when convenient.
        string[8] memory buffer32;
        // 32 pixels per slot, 256 total
        string[4] memory buffer256;
        // 256 pixels per slot, 1024 total
        uint8 buffer32count;
        uint8 buffer256count;
        for (uint k = 0; k < 384;) {
            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.one = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.two = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.three = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.four = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.five = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.six = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.seven = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.eight = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            buffer32[buffer32count++] = string(abi.encodePacked(buffer4.one, buffer4.two, buffer4.three, buffer4.four, buffer4.five, buffer4.six, buffer4.seven, buffer4.eight));
            cursor.x = 0;
            cursor.y += 1;
            if (buffer32count >= 8) {
                buffer256[buffer256count++] = string(abi.encodePacked(buffer32[0], buffer32[1], buffer32[2], buffer32[3], buffer32[4], buffer32[5], buffer32[6], buffer32[7]));
                buffer32count = 0;
            }
        }
        // At this point, buffer256 contains 4 strings or 256*4=1024=32x32 pixels
        return buffer256;
    }

    function splitNumber(uint256 _number) internal pure returns (uint16[NUM_LAYERS] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 8192);
            _number >>= 9;
        }
        return numbers;
    }

    function randomPalette(uint256 _number) internal pure returns (uint8[NUM_LAYERS] memory numbers) {
        numbers[0] = uint8(_number % NUM_PALETTES);
        _number >>= 9; // this was 7
        numbers[1] = uint8(_number % NUM_PALETTES);
        if (numbers[0] == numbers[1]) {
            numbers[1] = uint8((numbers[1] + 1) % NUM_PALETTES);
        }
        return [numbers[0], numbers[0], numbers[0], numbers[0], numbers[0], numbers[1], numbers[1], numbers[1], numbers[1]];
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    /*
    Convert uint to hex string, padding to 6 hex nibbles
    */
    function uintToHexString6(uint a) internal pure returns (string memory) {
        string memory str = uintToHexString2(a);
        if (bytes(str).length == 2) {
            return string(abi.encodePacked("0000", str));
        } else if (bytes(str).length == 3) {
            return string(abi.encodePacked("000", str));
        } else if (bytes(str).length == 4) {
            return string(abi.encodePacked("00", str));
        } else if (bytes(str).length == 5) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to hex string, padding to 2 hex nibbles
    */
    function uintToHexString2(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to byte string, padding number string with spaces at end.
    Useful to ensure result's length is a multiple of 3, and therefore base64 encoding won't
    result in '=' padding chars.
    */
    function uintToByteString(uint a, uint fixedLen) internal pure returns (bytes memory _uintAsString) {
        uint j = a;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        j = fixedLen;
        if (a == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(' ');
        }
        uint k = len;
        while (a != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(a - a / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            a /= 10;
        }
        return bstr;
    }

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString2(byteToUint(b));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface TinyExplorersTypes {
    struct TinyExplorer {
        uint256 dna;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}