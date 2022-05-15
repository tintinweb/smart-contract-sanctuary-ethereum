// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./core/TinyExplorersTypes.sol";
import "./utils/Base64.sol";
import "@0xsequence/sstore2/contracts/SSTORE2.sol";



// based on the solid concepts + foundations set by the greatest: Anonymice, Blitmap, Chainrunners, fiveoutofnine and countless other on-chain projects
// written by @emrecolako + ege


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

    bytes32 internal constant HEXADECIMAL_DIGITS = "0123456789ABCDEF";

    uint256 private constant NUM_LAYERS = 8;
    uint256 private constant NUM_PALETTES = 10;
    uint256 private constant NUM_COLORS = 5;
    

    mapping(uint256 => Layer) [NUM_LAYERS] layers;
    

    uint16[3][NUM_LAYERS] ITEMS;
    uint8[4] RARITY;
    uint8[5][2] PIRATE_ITEMS;
    uint256[NUM_PALETTES] COLORS;
    uint256[2] BACKGROUND_COLORS;

    constructor() {
    
        RARITY = [67, 22, 7, 1];

        PIRATE_ITEMS[0] = [49, 50, 51, 52, 53];
        PIRATE_ITEMS[1] = [26, 27, 28, 29, 29];

        // Shoulders 
        ITEMS[0] = [1, 0, 8192]; 
        // Faces
        ITEMS[1]= [55, 0, 8192];
        // Hair
        ITEMS[2] = [21, 11, 6369];
        // Facial Hair
        ITEMS[3] = [11, 6, 1740];
        // Masks
        ITEMS[4] = [10, 6, 1734];
        // Goggles
        ITEMS[5] = [26, 6, 4062];
        // Hats
        ITEMS[6] = [49, 2, 2516];
        // Face Accessories
        ITEMS[7] = [17, 5, 2410];

        BACKGROUND_COLORS = [
            0xfaf2e5f6f4edfcefdffff8e7,
            0xf0f0e8f6f1ecf1f0f0f3eded
        ];

        COLORS=[
            0xffbfb2ffb0a0df8876ac503dcd705d,
            0xdce9ef96bdcf9088a772649c39324e,
            0xcededcb0c9c689a3af65768e455161,
            0xd2ad8ca36e4e925452613837402524,
            0xd49fadc47c8fb4597182465461343f,
            0xcf7b72c2574ca342387d332b4f1f1a,
            0xddd6b0cec38c868a6e6a6e57425044,
            0x79b6aa5093863e72682c514a123142,
            0x7f7c7c585656523e3e352828271d1d,
            0x98ac7f7f96625577594059432b3b2d
        ];
        
    }



    function setLayers(LayerInput[] calldata toSet) external onlyOwner{
        
        for (uint16 i; i < toSet.length; ++i) {
                
        (string memory name,bytes memory hexString, uint8 layerIndex,uint8 itemIndex)=
            abi.decode(
                SSTORE2.read(
                    SSTORE2.write(abi.encode(toSet[i].name, toSet[i].hexString,toSet[i].layerIndex,toSet[i].itemIndex))),(string,bytes,uint8,uint8)
                );
            layers[layerIndex][itemIndex]=Layer(name,hexString);
            }
        }

    
    /*
    Generates base64 encoded tokenURI.
    */
    function tokenURI(uint256 tokenId, TinyExplorersTypes.TinyExplorer memory explorerData ) public view returns (string memory) {
        

        string memory description;
        unchecked {
        description = Base64.encode (
            bytes(
                string(abi.encodePacked(
                    '{"name": "',
                    bytes(getExplorerName(explorerData)),
                    '","image": "data:image/svg+xml;base64,',
                    bytes(tokenSVG(explorerData)),'"',
                    bytes(tokenAttributes(explorerData))
                    ))));
        description = string(abi.encodePacked('data:application/json;base64,',description));
        }
        
       return description;
    }

    function getExplorerName(TinyExplorersTypes.TinyExplorer memory explorerData) public view returns (string memory){

        (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes, string memory backColor) = getTokenData(explorerData);
                          
        return (string.concat(tokenLayers[1].name,' ',tokenLayers[2].name));
    }


    function tokenAttributes(TinyExplorersTypes.TinyExplorer memory explorerData) public view returns (string memory) {

      (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes, string memory backColor) = getTokenData(explorerData);
      string memory attributes='[';
      
      for (uint8 i=1; i < numTokenLayers; ++i) {        
          
          attributes = string.concat(
              attributes,
             '{"trait_type":"',
              traitTypes[i],
              '","value":"',
              tokenLayers[i].name,
              '"},'
          );
      }
        return string.concat(',"attributes":', attributes,'{"trait_type":"Type","value":"', boolToString(explorerData.isPirate),'"}]}');
    }

    function tokenSVG(TinyExplorersTypes.TinyExplorer memory explorerData) public view returns (string memory) {
        (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string[NUM_LAYERS] memory traitTypes, string memory backColor) = getTokenData(explorerData);
        string[4] memory buffer256 = tokenSVGBuffer(tokenLayers, tokenPalettes, numTokenLayers, backColor);
        return string.concat(
                "PHN2ZyBzaGFwZS1yZW5kZXJpbmc9J2NyaXNwRWRnZXMnIHZlcnNpb249JzEuMScgdmlld0JveD0nMCAwIDMyMCAzMjAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+ICA8cmVjdCBmaWxsPScj",
                Base64.encode(bytes(backColor)),
                "JyBoZWlnaHQ9JzEwMCUnIHdpZHRoPScxMDAlJy8+",
                buffer256[0],
                buffer256[1], 
                buffer256[2], 
                buffer256[3],
                "IDwvc3ZnPg=="
            );

    }

    function getRarityIndex(uint16 _dna, uint8 _index) internal view returns (uint) {

        uint16 lowerBound;
        uint16 bucketSize;
        uint16 bucketIndex;
        uint16 setSize;

        for (uint8 i; i < ITEMS[_index][0]; i++ ) {
            if (_index < 2) {
                bucketSize = (8192 / ITEMS[_index][0]) + 1;
            } else {
                setSize = (ITEMS[_index][0] / 4) + 1;
                bucketIndex = i / setSize;
                bucketSize = RARITY[bucketIndex] * ITEMS[_index][1];
                
            }
            if (_dna >= lowerBound && _dna < lowerBound + bucketSize) {
                return i;
            }
            lowerBound += bucketSize;
        }

        if (_index == 5) {
            return ITEMS[_index][0] + 3;
        } else if (_index == 6) {
            return ITEMS[_index][0] + 5;
        } 
        return ITEMS[_index][0];
    }

    function getTokenData(TinyExplorersTypes.TinyExplorer memory explorerData) public view returns (Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string [NUM_LAYERS] memory traitTypes, string memory backColor) {
        uint16[NUM_LAYERS+1] memory dna = splitNumber(explorerData.dna);
        uint8[NUM_LAYERS] memory paletteIndices = randomPalette(explorerData.dna);
        backColor = allColors(BACKGROUND_COLORS[uint8(dna[8] % 2)], true)[uint8(dna[8] % 4)];


        bool isPirateAndHasKingdom = explorerData.isPirate; 
        bool hasMask = dna[4] < ITEMS[4][2];
        bool hasGoggles = (dna[5] < ITEMS[5][2]) || isPirateAndHasKingdom;
        bool hasHat = (dna[6] < ITEMS[6][2]) || isPirateAndHasKingdom; 
        
        for (uint8 i; i < NUM_LAYERS; i ++) {
            
            Layer memory layer;
            if (( i == 6 ||  i == 5) && isPirateAndHasKingdom) {
                if (i == 6) {
                    layer = layers[6][PIRATE_ITEMS[0][uint8(dna[6] % 5)]];   
                } 
                if (i == 5) {
                    layer = layers[5][PIRATE_ITEMS[1][uint8(dna[5] % 3)]];
                }
            } else {
                layer = layers[i][getRarityIndex(dna[i], i)]; 
        
            }

            if (layer.hexString.length > 0) {
                if ( (( i == 6 ||  i == 5) && isPirateAndHasKingdom) || (i == 4 && !isPirateAndHasKingdom ) ||  (i == 3 && hasGoggles && !hasMask) || (i == 7 && !hasMask ) || (i == 5 && !hasMask) || (i == 2 && !hasHat) || (i < 2 || i == 4 || i == 6) ) {
                    tokenLayers[numTokenLayers] = layer;
                    tokenPalettes[numTokenLayers] = palette(paletteIndices[i], i);
                    traitTypes[numTokenLayers] = ["Shoulders","Face","Hair","Facial Hair","Mask","Goggle","Hat","Face Accessory"][i];
                    numTokenLayers++;
                } else {
                    continue;
                }
            }
        }
        return (tokenLayers, tokenPalettes, numTokenLayers, traitTypes, backColor);
    }

    function palette(uint8 index, uint8 idx) internal view returns (Color [NUM_COLORS] memory) {
        
        Color [NUM_COLORS] memory colors;
        for (uint16 i = 0; i < NUM_COLORS; ++i) {
            colors[i].hexString=(allColors(COLORS[index], false)[i]);
        }
        return colors;
    }

    function allColors(uint256 _integer, bool back) internal pure returns (string [5] memory){    
        string[5] memory colors;
        if (back) {
            colors[0]=string(toColorHexString(_integer >> 0x48));
            colors[1]=string(toColorHexString(_integer >> 0x30));
            colors[2]=string(toColorHexString(_integer >> 0x18));
            colors[3]=string(toColorHexString(_integer >> 0x0));
            colors[4]=string(toColorHexString(_integer >> 0x0));
        } else {
            colors[0]=toColorHexString(_integer >> 0x60);
            colors[1]=string(toColorHexString(_integer >> 0x48));
            colors[2]=string(toColorHexString(_integer >> 0x30));
            colors[3]=string(toColorHexString(_integer >> 0x18));
            colors[4]=string(toColorHexString(_integer >> 0x0));
        }
        
        return colors;
    }


    function toColorHexString(uint256 _integer) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                HEXADECIMAL_DIGITS[(_integer >> 0x14) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 0x10) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 0xC) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 8) & 0xF],
                HEXADECIMAL_DIGITS[(_integer >> 4) & 0xF],
                HEXADECIMAL_DIGITS[_integer & 0xF]
            )
        );
    }


    function colorForIndex(Layer[NUM_LAYERS] memory tokenLayers, uint k, uint index, Color [NUM_COLORS][NUM_LAYERS] memory palettes, uint numTokenLayers, string memory backColor) internal pure returns (string memory) {

        for (uint256 i = numTokenLayers - 1; i >= 0; i--) {
            if (colorIndex(tokenLayers[i].hexString, k, index) == 0 && i == 0) {
                return "bm9wZQ==";
            } else if (colorIndex(tokenLayers[i].hexString, k, index) == 0 ) {
                continue;
            } else {
                Color memory fg = palettes[i][colorIndex(tokenLayers[i].hexString, k, index)-1];
                return fg.hexString;
            }
            
        }
        return "bm9wZQ==";
    }

    
    function colorIndex(bytes memory data, uint k, uint index) internal pure returns (uint8) {
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

    function pixelMaybe(string[32] memory lookup, SVGCursor memory cursor) internal pure returns (string memory result) {
        
        string memory pixels = "";
        if (keccak256(abi.encodePacked(cursor.color1)) != keccak256(abi.encodePacked("bm9wZQ=="))) {
            pixels = string(abi.encodePacked(pixels," <rect fill='#", cursor.color1, "'  x='", lookup[cursor.x], "'  y='", lookup[cursor.y], "' height='10' width='10' /> "));
        }
        if (keccak256(abi.encodePacked(cursor.color2)) != keccak256(abi.encodePacked("bm9wZQ=="))) {
            pixels = string(abi.encodePacked(pixels," <rect fill='#", cursor.color2, "'  x='", lookup[cursor.x+1], "'  y='", lookup[cursor.y], "' height='10' width='10' /> "));
        }
        if (keccak256(abi.encodePacked(cursor.color3)) != keccak256(abi.encodePacked("bm9wZQ=="))) {
            pixels = string(abi.encodePacked(pixels," <rect fill='#", cursor.color3, "'  x='", lookup[cursor.x+2], "'  y='", lookup[cursor.y], "' height='10' width='10' /> "));
        }
        if (keccak256(abi.encodePacked(cursor.color4)) != keccak256(abi.encodePacked("bm9wZQ=="))) {
            pixels = string(abi.encodePacked(pixels," <rect fill='#", cursor.color4, "'  x='", lookup[cursor.x+3], "'  y='", lookup[cursor.y], "' height='10' width='10' /> "));
        }
        return pixels;
    }
    

    function tokenSVGBuffer(Layer [NUM_LAYERS] memory tokenLayers, Color [NUM_COLORS][NUM_LAYERS] memory tokenPalettes, uint8 numTokenLayers, string memory backColor) internal pure returns (string[4] memory) {
    
        string[32] memory lookup =  ["000","010","020","030","040","050","060","070","080","090","100","110","120","130","140","150","160","170","180","190","200","210","220","230","240","250","260","270","280","290","300","310"];
        SVGCursor memory cursor;

        
        Buffer memory buffer4;
        string[8] memory buffer32;
        string[4] memory buffer256;
        uint8 buffer32count;
        uint8 buffer256count;
        for (uint k; k < 384;) {
            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers, backColor);
            buffer4.one = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers, backColor);
            buffer4.two = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers, backColor);
            buffer4.three = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers, backColor);
            buffer4.four = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers, backColor);
            buffer4.five = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers, backColor);
            buffer4.six = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers, backColor);
            buffer4.seven = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers, backColor);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers, backColor);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers, backColor);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers, backColor);
            buffer4.eight = pixelMaybe(lookup, cursor);
            cursor.x += 4;

            k += 3;
           
            
            buffer32[buffer32count++] = string.concat(buffer4.one, buffer4.two, buffer4.three, buffer4.four, buffer4.five, buffer4.six, buffer4.seven, buffer4.eight);

            cursor.x = 0;
            cursor.y += 1;
            if (buffer32count >= 8) {
                buffer256[buffer256count++] = Base64.encode (bytes(string.concat(buffer32[0], buffer32[1], buffer32[2], buffer32[3], buffer32[4], buffer32[5], buffer32[6], buffer32[7])));
                buffer32count = 0;
            }
        }
        
        return buffer256;
    }

    function splitNumber(uint256 _number) internal pure returns (uint16[NUM_LAYERS+1] memory numbers) {
        for (uint256 i; i < numbers.length; ++i) {
            numbers[i] = uint16(_number % 8192);
            _number >>= 9;
        }
        return numbers;
    }

    function randomPalette(uint256 _number) internal pure returns (uint8[NUM_LAYERS] memory numbers) {
        numbers[0] = uint8(_number % NUM_PALETTES);
        _number >>= 8;
        numbers[1] = uint8(_number % NUM_PALETTES);
        if (numbers[0] == numbers[1]) {
            numbers[1] = uint8((numbers[1] + 1) % NUM_PALETTES);
        }
        return [numbers[0], numbers[0], numbers[0], numbers[0], numbers[1], numbers[1], numbers[1], numbers[1]];
    }

    function boolToString(bool isPirate) internal pure returns (string memory){
        unchecked {
            if (isPirate==true) return "Pirate";
            else return "Explorer";
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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
        bool isPirate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz012345678"
        "9+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLength = ((data.length + 2) / 3) << 2;
        string memory result = new string(encodedLength + 0x20);

        assembly {
            mstore(result, encodedLength)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 0x20)
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               let input := mload(dataPtr)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0x12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0xC, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(input, 0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(0xF0, 0x3D3D)) }
            case 2 { mstore(sub(resultPtr, 1), shl(0xF8, 0x3D)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}