// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Lawrence X. Rogers

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {BUD_STUB_1, BUD_STUB_2, FLOWER_ANIMATIONS, FLOWER_DEFS} from "contracts/Encodings.sol";

/// @title MergeFlowersArt
/// @author Lawrence X Rogers
/// @notice This smart contract creates the art for the MergeFlowers NFT.

contract MergeFlowerArt {
    using Strings for uint256;

    uint constant NUM_ATTRIBUTES = 4;

    /// @notice color information about the flower
    struct Palette {
        uint h1;            // hue1
        uint h2;            // hue2
        uint s;             // saturation
        uint l;             // lightness
        bool lwalk;         // whether to increase lightness per layer
        uint cycle;         // how many different colors in the palette
        Interval interval;  
        uint opacity;      
        Mutation mutation;  
    }

    /// @notice 
    struct FlowerTraits {
        Palette palette;
        uint maxDistance;      // starting distance of petals on first layer
        uint distanceDecrease; // how much to shrink each layer
        uint minCount;         // starting petal count on first layer
        uint countIncrease;    // how much to increase petal count each layer
        uint maxRadius;        // starting petal size on first layer
        uint radiusDecrease;   // how much to decrease the radius each layer
        uint levels;           // how many layers 
        uint petalSeed;        // seed storing what types of petals are on each layer
        Mutation mutation;     // what "Mutation" this flower has
        bool bg;               // whether or not this flower has a background
    }

    /// @notice this struct packs details for each layer to avoid stack-too-deep errors
    struct LayerDeets {
        uint distance;
        uint count;
        uint countEvened;
        uint radius;
        bool glow;
    }

    enum Interval {MONO, ANALAGOUS, TERTIARY, TRIADIC}
    uint constant NUM_MUTATIONS = 4;
    enum Mutation {NONE, BIO, VEINS, ALBINO}

    /// UTILITY FUNCTIONS
    /// @notice convert a byte to a number between min and max
    function randomValue(bytes1 seed, uint min, uint max) internal pure returns (uint value){
        uint percent = (100* (1 + uint32(uint8(seed)))) / 256;
        value = min + ((percent * (max - min)) / 100);
    }

    /// @notice the corehue is constant between the buds and the flowers, and is based on tokenId
    function getCoreHueFromTokenId(uint tokenId) internal view returns (uint) {
        bytes32 seed = keccak256(abi.encodePacked(tokenId));
        uint hue = uint(uint8(seed[0])) * uint(uint8(seed[10])) % 360;
        return hue % 360;
    }

    /// @notice convert hue, saturation, and lightness values to an HSL(x,y,z) string
    function getColor(uint _h, uint _s, uint _l) internal pure returns (bytes memory color) {
        color = abi.encodePacked("hsl(", _h.toString(), ", ", _s.toString(), "%, ", _l.toString(), "%)");
    }

    /// @notice return strings for each mutation, for attribute metadata
    function getMutationNames() internal pure returns(string[NUM_MUTATIONS] memory) {
        return ["None", "Bioluminescence", "Veins", "Albino"];
    }

    /// @notice each mutation has an opacity override
    function getMutationOpacity(Palette memory _p) internal pure returns(uint) {
        uint[NUM_MUTATIONS] memory opacities = [_p.opacity, 50, 30, 100];
        return opacities[uint(_p.mutation)];
    }

    /// @notice these are color intervals, in terms of degrees in the color wheel 
    function getIntervals() internal pure returns(uint8[4] memory) {
        return [0, 15, 60, 120];
    }

    /// FLOWER DESIGN

    /// @notice given a random seed and tokenId, generate all traits of the flower.
    function getFlowerTraits(uint _seed, uint tokenId) internal view returns (FlowerTraits memory f) {
        bytes32 seed = keccak256(abi.encodePacked(_seed, tokenId));
        
        uint h1 = getCoreHueFromTokenId(tokenId);
        uint s = 1; //the seed indexes could be hard-coded but tracking it with this variable makes coding much easier
        uint l = randomValue(seed[s++], 50, 70);
        uint maxDistance = randomValue(seed[s++], 250, 300);
        uint levels = randomValue(seed[s++], 2, 6);
        uint minCount = randomValue(seed[s++], 2, 6) * 2;
        Mutation mutation = randomValue(seed[s++], 0, 100) < 10 ? Mutation(randomValue(seed[s++], 0, NUM_MUTATIONS)) : Mutation.NONE;

        return FlowerTraits(
            Palette(
                h1,       // hue1
                (h1 + 10 + randomValue(seed[s++], 0, 20)) % 360, // hue2
                mutation == Mutation.BIO ? 100 : randomValue(seed[s++], 40, 80), // saturation
                l,        // lightness
                l < 60 && uint8(seed[s++]) < 180, // lwalk
                uint8(seed[s++]) < 120 ? 1 : randomValue(seed[s++], 2, 4), // cycle
                Interval(randomValue(seed[s++], 0, 4)), // interval
                mutation == Mutation.BIO ? 50 : randomValue(seed[s++], 50, 100), // opacity
                mutation//mutation == Mutation.VEINS || mutation == Mutation.ALBINO// stroked
            ), 
            maxDistance,   // maxDistance
            (maxDistance - randomValue(seed[s++], 80, 120)) / levels, // distanceDecrease
            minCount,      // min Count
            minCount == 4 ? randomValue(seed[s++], 4, 6) : randomValue(seed[s++], 1, 6),   // count increase
            randomValue(seed[s++], 150, 200),   // max width
            randomValue(seed[s++], 70, 90),     // width decrease
            levels,                             // levels
            uint(uint8(seed[s++])),             // petalSeed
            mutation,
            randomValue(seed[s++], 0, 100) < 50 // bg color
        );
    }

    function getAttributes(FlowerTraits memory _traits) internal pure returns (bytes memory attributeBytes) {
        (string[NUM_ATTRIBUTES] memory names, string[NUM_ATTRIBUTES] memory values) = getTraitNamesAndValues(_traits);
        return generateAttributeMetadata(names, values);
    }

    /// @notice generate the metadata strings and store in two arrays
    function getTraitNamesAndValues(FlowerTraits memory _traits) internal pure returns (string[NUM_ATTRIBUTES] memory names, string[NUM_ATTRIBUTES] memory values) {
        names = ["Base Color", "Levels", "Background Color", "Mutation"];
        values[0] = _traits.palette.h1.toString();              // Base Color
        values[1] = _traits.levels.toString();                  // Levels
        values[2] = _traits.bg ? "Color" : "None";              // Background Color
        values[3] = getMutationNames()[uint(_traits.mutation)]; // Mutation names
    }

    /// @notice helper function to pack metadata into a single string
    function generateAttributeMetadata(string[NUM_ATTRIBUTES] memory names, string[NUM_ATTRIBUTES] memory values) internal pure returns (bytes memory attributeMetadata) {
        attributeMetadata = abi.encodePacked("[");
        for (uint i = 0; i < names.length - 1; i++) {
            attributeMetadata = abi.encodePacked(attributeMetadata,
                '{"trait_type":"', names[i], '",',
                '"value":"', values[i], '"},');
        }

        attributeMetadata = abi.encodePacked(attributeMetadata,
                '{"trait_type":"', names[names.length - 1], '",',
                '"value":"', values[names.length - 1], '"}]');
    }

    /// @notice perform color math to turn palette traits into a specific petal's color
    function getColorFromPalette(Palette memory _p, uint _h, uint _index) internal pure returns (bytes memory) {
        uint h = (_h == 1) ? _p.h1 : _p.h2;
        h += (_index % _p.cycle) * getIntervals()[uint(_p.interval)];
        uint l = _p.lwalk ? _p.l + (_index * 7) : _p.l;
        return getColor(
            h, _p.s, l
        );
    }

    /// @notice return the bud SVG with the color injected.
    function getBudArt(uint tokenId) external view returns (bytes memory budBytes) {
        return abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                abi.encodePacked(
                    BUD_STUB_1, 
                    "hsl(", getCoreHueFromTokenId(tokenId).toString(), ",80%,60%",
                    BUD_STUB_2)
            )
        );
    }

    /// @notice pack the art into a single base64 encoded SVG. Can return with or without animations.
    function packArt(bytes memory flowerBytes, bool animated, bytes memory bg) internal pure returns (bytes memory) {
        
        return abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                abi.encodePacked(
                    '<svg width="100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="thesvg" viewBox="-700 -700 1400 1400" ',
                    'style="background-color: ', bg,'">',
                    '<style>',
                    animated ? FLOWER_ANIMATIONS : abi.encodePacked(""),
                    '</style>',
                    flowerBytes, 
                    "</svg>"
                )
            )
        );
    }

    function getBGColor(FlowerTraits memory _traits) internal pure returns (bytes memory bgcolorbytes) {
        if (_traits.mutation == Mutation.BIO) {
            return abi.encodePacked("#000");
        }
        else if (_traits.bg) {
            uint hue = (_traits.palette.h1 + 180 + getIntervals()[uint(_traits.palette.interval)]) % 360;
            return abi.encodePacked("hsl(", hue.toString(), ",40%,60%)");
        }
        else {
            return abi.encodePacked("#FFF");
        }
    }

    function getFlowerArt(uint _seed, uint tokenId) external view returns (bytes memory still, bytes memory animated, bytes memory attributes) {
        bytes memory flowerBytes = FLOWER_DEFS;
        FlowerTraits memory _traits = getFlowerTraits(_seed, tokenId);
        bytes[] memory layers = getFlowerLayers(_traits);
        for (uint i = 0; i < layers.length; i++) {
            flowerBytes = abi.encodePacked(flowerBytes, layers[i]);
        }
        bytes memory bg = getBGColor(_traits);
        return (packArt(flowerBytes, false, bg), packArt(flowerBytes, true, bg), getAttributes(_traits));
    }

    /// FLOWER CONSTRUCTION

    /// @notice rounds down petal radii to avoid petals being too large around top layer
    function getAdjustedRadius(LayerDeets memory _deets) internal pure returns (uint) {
        uint maximumRadius = ((_deets.distance * 2 * 314) / 100) / _deets.countEvened;
        return maximumRadius < _deets.radius ? maximumRadius : _deets.radius;
    }

    /// @notice main construction function. Takes the flower traits and generates each layer
    function getFlowerLayers(FlowerTraits memory _traits) internal pure returns (bytes[] memory layers) {
        layers = new bytes[](_traits.levels + 1);
        LayerDeets memory deets = LayerDeets(
                                    _traits.maxDistance, 
                                    _traits.minCount,
                                    _traits.minCount,
                                    _traits.maxRadius,
                                    _traits.mutation == Mutation.BIO);

        for (uint i = 0; i < _traits.levels; i++) {
            layers[i] = createLayer(i, _traits.petalSeed, deets, _traits.palette);

            deets.distance -= _traits.distanceDecrease;
            deets.count += _traits.countIncrease;
            deets.countEvened = (deets.count / 2) * 2;
            deets.radius = (deets.radius * _traits.radiusDecrease) / 100;
        }
        layers[layers.length - 1] = createCore(deets.distance + _traits.distanceDecrease, _traits.palette, _traits.levels - 1);
        return layers;
    }

    /// @notice creates a given flower layer. Each layer is actually two layers of petals of the same type
    function createLayer(uint _index, uint _typeSeed, LayerDeets memory _deets, Palette memory _p) internal pure returns (bytes memory layerBytes) {
        
        layerBytes = abi.encodePacked(
            "<g style='transform: rotate(0deg) scale(100%); animation: scaleUp 8s cubic-bezier(.24,.95,.6,1) both ",
             (_index * 200).toString(), "ms'>",
            _deets.glow && _index == 0 ? "<g filter='url(#glow)'>" : "<g filter='url(#shadow)'>");
        uint8 petalType = uint8(keccak256(abi.encodePacked(_typeSeed))[_index]);
        uint rotationInterval = 36000 / _deets.countEvened;

        for (uint i = 0; i < _deets.countEvened; i+= 2) {
            bytes memory color = getColorFromPalette(_p, 1, _index);
            layerBytes = abi.encodePacked(
                layerBytes, 
                createPetal(
                    _p,
                    petalType,
                    _deets.distance + 5,
                    (i * rotationInterval) / 100,// (_index % 2 == 1 ? i * rotationInterval + (rotationInterval / 2): i * rotationInterval) / 100,
                    getAdjustedRadius(_deets) + 5, 
                    color));
        }

        layerBytes = abi.encodePacked(
            layerBytes, 
            "</g></g><g style='transform: rotate(0deg) scale(100%); animation: scaleUp 8s cubic-bezier(.24,.95,.6,1) both ",
             (_index * 200).toString(), "ms'>",
            _deets.glow && _index == 0 ? "<g filter='url(#glow)'>" : "<g filter='url(#shadow)'>");
        
        for (uint i = 1; i < _deets.countEvened; i+= 2) {
            bytes memory color = getColorFromPalette(_p, 2, _index);
            layerBytes = abi.encodePacked(
                layerBytes, 
                createPetal(
                    _p,
                    petalType,
                    _deets.distance - 5, 
                    (i * rotationInterval) / 100,//(_index % 2 == 1 ? i * rotationInterval + (rotationInterval / 2): i * rotationInterval) / 100,
                    getAdjustedRadius(_deets) - 5, 
                    color));
        }
        layerBytes = abi.encodePacked(layerBytes, "</g></g>");
    }

    /// @notice each petal has some basic attributes that are the same regardless of petal type
    function getBasicPetalAttributes(Palette memory _p, bytes memory _hue) internal pure returns (bytes memory petalBytes) {
        return abi.encodePacked(
                '" stroke="', _p.mutation == Mutation.ALBINO ? abi.encodePacked("black") : _hue,
                '" fill="', _p.mutation == Mutation.ALBINO ? abi.encodePacked("white") : _hue,
                '" fill-opacity="', getMutationOpacity(_p).toString() , "%"
        );
    }

    /// @notice create the petal. there are three types of petals, each of which are created slightly differently
    function createPetal(Palette memory _p, uint8 _type, uint _distance, uint _rotation, uint _radius, bytes memory _hue) internal pure returns (bytes memory petalBytes) {
        if (_type <  85) { // CIRCLE
            petalBytes = abi.encodePacked(
                '<circle cy="', _distance.toString(), 
                '" r="', _radius.toString(),
                '" stroke-width="', _p.mutation == Mutation.VEINS || _p.mutation == Mutation.ALBINO ? "10px" : "0px",
                getBasicPetalAttributes(_p, _hue),
                '" style="transform: rotate(', _rotation.toString(), 'deg)" />'
            );
        }
        else if (_type < 170) { // ELLIPSE
            petalBytes = abi.encodePacked(
                '<ellipse cy="', _distance.toString(), 
                '" rx="', ((_radius * 80)/100).toString(),
                '" ry="', ((_radius * 150)/100).toString(),
                '" stroke-width="', _p.mutation == Mutation.VEINS || _p.mutation == Mutation.ALBINO ? "10px" : "0px",
                getBasicPetalAttributes(_p, _hue),
                '" style="transform: rotate(', _rotation.toString(), 'deg)" />'
            );
        }
        else {
            uint scale = ((100 * _radius) / 180);// needs two decimal places

            petalBytes = abi.encodePacked( // POINTY
                '<path d="M 0 300 C 0 300 -150 240 -170 170 C -220 0 0 -300 0 -300 C 0 -300 220 0 170 170 C 150 240 0 300 0 300 Z', 
                '" stroke-width="', abi.encodePacked((_p.mutation == Mutation.VEINS || _p.mutation == Mutation.ALBINO ? (1000 / scale) : 0).toString(), "px"),
                getBasicPetalAttributes(_p, _hue),
                '" style="transform: rotate(', _rotation.toString(),
                     'deg) translate(0px, -', _distance.toString(), 
                     'px) scale(', scale.toString(), '%)"/>'
            );
        }
    }

    /// @notice create the "core" of the flower, the circle in the center. 
    function createCore(uint _radius, Palette memory _p, uint _index) internal pure returns (bytes memory coreBytes) {
        bytes memory id = abi.encodePacked(_p.h1.toString(), _p.h2.toString()); //abi.encodePacked(hue1, "-", hue2);
        coreBytes = abi.encodePacked(
            "<radialGradient id='", id,"'>",
                "<stop offset='0%' stop-color='", getColor(_p.h1, _p.s, _p.l), "'/>",
                "<stop offset='100%' stop-color='", getColor(_p.h2, _p.s, _p.l - 30), "'/>",
            "</radialGradient>",
            "<g style='transform: rotate(0deg) scale(100%); animation: scaleUp 8s cubic-bezier(.24,.95,.6,1) both ",
             (_index * 200).toString(), "ms'>",
            "<circle r='", _radius.toString(), 
            "' filter='url(#shadow)'",
            " stroke='", _p.mutation == Mutation.ALBINO ? abi.encodePacked("black") : getColorFromPalette(_p, 0, _index),
            "' stroke-width='", _p.mutation == Mutation.ALBINO ? "10px" : "0px",
            "' fill-opacity='", (_p.mutation == Mutation.ALBINO ? "100" : (_p.opacity + 25).toString()), "%'",
            " fill='", _p.mutation == Mutation.ALBINO ? abi.encodePacked("white") : abi.encodePacked("url(#", id, ")"), 
            
            "'/></g>"
        );
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

bytes constant BUD_STUB_1 = hex"3c7376672077696474683d22313030252220786d6c6e733d22687474703a2f2f7777772e77332e6f72672f323030302f7376672220786d6c6e733a786c696e6b3d22687474703a2f2f7777772e77332e6f72672f313939392f786c696e6b222069643d22746865737667222076696577426f783d222d373030202d37303020313430302031343030223e202020203c7374796c653e406b65796672616d6573206c6561664c6f6164207b3025207b726f746174653a206e6f6e653b7d373025207b726f746174653a202d31306465673b7d31303025207b726f746174653a203336306465673b7d7d406b65796672616d6573207363616c655570207b3025207b726f746174653a2034356465673b7363616c653a203130253b7d31303025207b726f746174653a206e6f6e653b7363616c653a20313030253b7d7d406b65796672616d6573207363616c654f7363696c6c617465207b3025207b7472616e736c6174653a20303b7363616c653a20313030253b7d353025207b7472616e736c6174653a202d3570783b7363616c653a203938253b7d31303025207b7472616e736c6174653a20303b7363616c653a20313030253b7d7d406b65796672616d65732077696e64207b3025207b7472616e736c6174653a20303b7363616c653a20313030253b7d353025207b7472616e736c6174653a202d323070783b7363616c653a20313031253b7d31303025207b7472616e736c6174653a20303b7363616c653a20313030253b7d7d406b65796672616d65732077696e64526f74617465207b3025207b726f746174653a206e6f6e653b7d353025207b726f746174653a202d2e356465673b7d31303025207b726f746174653a206e6f6e653b7d7d237374656d207b7472616e73666f726d2d6f726967696e3a20626f74746f6d3b7d2e616e74686572207b616e696d6174696f6e3a20616e74686572426c6f6f6d2031307320656173652d696e2d6f75743b7d406b65796672616d657320616e74686572426c6f6f6d207b3025207b7363616c653a203230253b7d353025207b7363616c653a20313230253b7d31303025207b7363616c653a20313030253b7d7d3c2f7374796c653e202020203c646566733e20202020202020203c66696c7465722066696c746572556e6974733d227573657253706163654f6e557365222069643d22736861646f772220783d222d3530252220793d222d353025222077696474683d223230302522206865696768743d2232303025223e2020202020202020202020203c66654f666673657420726573756c743d226f66664f75742220696e3d22536f75726365416c706861222064783d2230222064793d2230223e3c2f66654f66667365743e2020202020202020202020203c6665476175737369616e426c757220726573756c743d22626c75724f75742220696e3d226f66664f75742220737464446576696174696f6e3d223230223e3c2f6665476175737369616e426c75723e2020202020202020202020203c6665426c656e6420696e3d22536f75726365477261706869632220696e323d22626c75724f757422206d6f64653d226e6f726d616c223e3c2f6665426c656e643e20202020202020203c2f66696c7465723e20202020202020203c66696c7465722069643d22736861646f772d736d616c6c2220783d222d3530252220793d222d353025222077696474683d223230302522206865696768743d2232303025223e2020202020202020202020203c6665476175737369616e426c757220726573756c743d22626c75724f75742220696e3d22536f75726365416c7068612220737464446576696174696f6e3d2235223e3c2f6665476175737369616e426c75723e2020202020202020202020203c6665426c656e6420696e3d22536f75726365477261706869632220696e323d22626c75724f757422206d6f64653d226e6f726d616c223e3c2f6665426c656e643e20202020202020203c2f66696c7465723e2020202020202020202020203c2f646566733e202020203c726563742069643d227374656d2220783d222d31302220793d2230222077696474683d22303022206865696768743d2232303030222066696c6c3d22677265656e223e3c2f726563743e202020203c672069643d22666c6f77657222207374796c653d22616e696d6174696f6e3a20347320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e672077696e643b223e3c672066696c7465723d2275726c2823736861646f7729223e3c7061746820643d224d202d302e343737202d3133372e3030362043202d302e343737202d3133372e303036202d36302e313037202d34342e313536202d35312e343436202d302e3336332043202d34362e3731342032332e353636202d32322e3939382035302e38343820312e3338372035302e32363720432032342e3638362034392e3731322034342e3934382032322e3339392034392e353037202d302e34353620432035382e303532202d34332e323933202d302e343737202d3133372e303036202d302e343737202d3133372e303036205a22207374796c653d227472616e73666f726d3a20726f74617465283064656729207363616c652831293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e33732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e337320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e367320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f706174683e3c7061746820643d224d202d302e343737202d3133372e3030362043202d302e343737202d3133372e303036202d36302e313037202d34342e313536202d35312e343436202d302e3336332043202d34362e3731342032332e353636202d32322e3939382035302e38343820312e3338372035302e32363720432032342e3638362034392e3731322034342e3934382032322e3339392034392e353037202d302e34353620432035382e303532202d34332e323933202d302e343737202d3133372e303036202d302e343737202d3133372e303036205a22207374796c653d227472616e73666f726d3a20726f746174652831383064656729207363616c652831293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e33732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e337320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e367320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f706174683e3c2f673e3c672066696c7465723d2275726c2823736861646f7729223e3c7061746820643d224d202d302e343737202d3133372e3030362043202d302e343737202d3133372e303036202d36302e313037202d34342e313536202d35312e343436202d302e3336332043202d34362e3731342032332e353636202d32322e3939382035302e38343820312e3338372035302e32363720432032342e3638362034392e3731322034342e3934382032322e3339392034392e353037202d302e34353620432035382e303532202d34332e323933202d302e343737202d3133372e303036202d302e343737202d3133372e303036205a22207374796c653d227472616e73666f726d3a20726f7461746528393064656729207363616c652831293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e33732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e337320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e367320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f706174683e3c7061746820643d224d202d302e343737202d3133372e3030362043202d302e343737202d3133372e303036202d36302e313037202d34342e313536202d35312e343436202d302e3336332043202d34362e3731342032332e353636202d32322e3939382035302e38343820312e3338372035302e32363720432032342e3638362034392e3731322034342e3934382032322e3339392034392e353037202d302e34353620432035382e303532202d34332e323933202d302e343737202d3133372e303036202d302e343737202d3133372e303036205a22207374796c653d227472616e73666f726d3a20726f746174652832373064656729207363616c652831293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e33732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e337320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e367320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f706174683e3c2f673e3c672066696c7465723d2275726c2823736861646f7729223e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f746174652830646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f74617465283930646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f7461746528313830646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f7461746528323730646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c2f673e3c672066696c7465723d2275726c2823736861646f7729223e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f74617465283435646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f7461746528313335646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f7461746528323235646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223430222072783d22333022207374796c653d227472616e73666f726d3a20726f7461746528333135646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c20312920302e32732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420302e327320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031302e347320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c2f673e3c636972636c652066696c6c3d22";
bytes constant BUD_STUB_2 = hex"2220723d223130222069643d2268696e74223e3c2f636972636c653e3c672066696c7465723d2275726c2823736861646f772d736d616c6c223e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f746174652830646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f74617465283630646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528313230646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528313830646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528323430646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528333030646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c2f673e3c672066696c7465723d2275726c2823736861646f772d736d616c6c223e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f74617465283330646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f74617465283930646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528313530646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528323130646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528323730646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c656c6c697073652063783d2230222063793d223237222072783d22313522207374796c653d227472616e73666f726d3a20726f7461746528333330646567293b20616e696d6174696f6e3a203130732063756269632d62657a69657228302e32342c20302e39352c20302e362c2031292030732031206e6f726d616c20626f74682072756e6e696e67207363616c6555702c20377320656173652d696e2d6f757420307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67206c6561664c6f61642c20347320656173652d696e2d6f75742031307320696e66696e697465206e6f726d616c206e6f6e652072756e6e696e67207363616c654f7363696c6c6174653b222066696c6c3d2268736c283132362c203630252c2035302529222066696c6c2d6f7061636974793d22302e3722207374726f6b653d2268736c283132362c203630252c2035302529223e3c2f656c6c697073653e3c2f673e3c2f673e3c2f7376673e";
bytes constant FLOWER_STUB_NO_STYLES = hex"3c7376672077696474683d22313030252220786d6c6e733d22687474703a2f2f7777772e77332e6f72672f323030302f7376672220786d6c6e733a786c696e6b3d22687474703a2f2f7777772e77332e6f72672f313939392f786c696e6b222069643d22746865737667222076696577426f783d222d373030202d37303020313430302031343030223e203c7374796c653e2020203c2f7374796c653e203c646566733e203c66696c7465722066696c746572556e6974733d227573657253706163654f6e557365222069643d22736861646f772220783d222d3530252220793d222d353025222077696474683d223230302522206865696768743d2232303025223e20203c6665476175737369616e426c757220726573756c743d22626c75724f75742220696e3d22536f75726365416c7068612220737464446576696174696f6e3d22323022202f3e20203c6665426c656e6420696e3d22536f75726365477261706869632220696e323d22626c75724f757422206d6f64653d226e6f726d616c22202f3e203c2f66696c7465723e203c66696c7465722066696c746572556e6974733d227573657253706163654f6e557365222069643d22736861646f772d736d616c6c2220783d222d3530252220793d222d353025222077696474683d223230302522206865696768743d2232303025223e20203c6665476175737369616e426c757220726573756c743d22626c75724f75742220696e3d22536f75726365416c7068612220737464446576696174696f6e3d223422202f3e20203c6665426c656e6420696e3d22536f75726365477261706869632220696e323d22626c75724f757422206d6f64653d226e6f726d616c22202f3e203c2f66696c7465723e203c2f646566733e";
bytes constant FLOWER_ANIMATIONS = hex"406b65796672616d6573206c6561664c6f6164207b203025207b20726f746174653a20306465673b207d20373025207b20726f746174653a202d31306465673b207d2031303025207b20726f746174653a203336306465673b207d7d20406b65796672616d6573207363616c655570207b203025207b7363616c653a20313025203130253b726f746174653a2034356465673b207d2031303025207b7363616c653a203130302520313030253b726f746174653a20306465673b207d7d406b65796672616d65732077696e64207b203025207b7472616e736c6174653a203070783b7363616c653a20313030253b207d20353025207b7472616e736c6174653a202d31303070783b7363616c653a203935253b207d2031303025207b7472616e736c6174653a203070783b7363616c653a20313030253b207d7d";
bytes constant FLOWER_DEFS = hex"3c646566733e203c7061747465726e2069643d227061747465726e2d636972636c65732220783d22302220793d2230222077696474683d22383022206865696768743d2233303022207061747465726e556e6974733d227573657253706163654f6e55736522207061747465726e436f6e74656e74556e6974733d227573657253706163654f6e557365223e203c7265637420783d22302220793d2230222077696474683d223130302522206865696768743d2231303025222066696c6c3d2270696e6b222f3e203c7465787420783d22302220793d22302220636c6173733d22686561767922207472616e73666f726d3d22726f7461746528393029223e204d455247453c2f746578743e203c2f7061747465726e3e203c66696c7465722069643d22736861646f77222020783d222d3430252220793d222d343025222077696474683d223138302522206865696768743d2231383025223e203c6665436f6c6f724d617472697820747970653d226d6174726978222076616c7565733d20202022302030203020302020203020302030203020302020203020302030203020302020203020302030203020302e372030222f3e203c6665476175737369616e426c757220737464446576696174696f6e3d2231382220726573756c743d22636f6c6f726564426c7572222f3e203c66654d657267653e203c66654d657267654e6f646520696e3d22636f6c6f726564426c7572222f3e203c66654d657267654e6f646520696e3d22536f7572636547726170686963222f3e203c2f66654d657267653e203c2f66696c7465723e203c66696c746572202069643d22736861646f772d736d616c6c2220783d222d3330252220793d222d333025222077696474683d223136302522206865696768743d2231363025223e203c6665476175737369616e426c757220726573756c743d22626c75724f75742220696e3d22536f75726365416c7068612220737464446576696174696f6e3d223422202f3e203c66654d657267653e203c66654d657267654e6f646520696e3d22626c75724f7574222f3e203c66654d657267654e6f646520696e3d22536f7572636547726170686963222f3e203c2f66654d657267653e203c2f66696c7465723e203c66696c7465722069643d22676c6f772220783d222d3330252220793d222d333025222077696474683d223136302522206865696768743d2231363025223e203c6665476175737369616e426c757220737464446576696174696f6e3d2233302220726573756c743d22636f6c6f726564426c7572222f3e203c66654d657267653e203c66654d657267654e6f646520696e3d22636f6c6f726564426c7572222f3e203c66654d657267654e6f646520696e3d22536f7572636547726170686963222f3e203c2f66654d657267653e203c2f66696c7465723e203c2f646566733e";