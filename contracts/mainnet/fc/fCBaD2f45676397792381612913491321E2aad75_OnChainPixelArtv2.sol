// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

import {OnChainPixelArtLibrary} from "./OnChainPixelArtLibrary.sol";
import {OnChainPixelArtLibraryv2} from "./OnChainPixelArtLibraryv2.sol";

pragma solidity ^0.8.0;

contract OnChainPixelArtv2 {
    function base64Encode(bytes memory data)
        public
        pure
        returns (string memory)
    {
        return OnChainPixelArtLibrary.base64Encode(data);
    }

    function toHexString(uint256 value) public pure returns (string memory) {
        return OnChainPixelArtLibrary.toHexString(value);
    }

    function toString(uint256 value) public pure returns (string memory) {
        return OnChainPixelArtLibrary.toString(value);
    }

    function getColorCompression(uint256 colorCount)
        internal
        pure
        returns (uint256 comp)
    {
        return OnChainPixelArtLibrary.getColorCompression(colorCount);
    }

    function getPixelCompression(uint256[] memory layers)
        internal
        pure
        returns (uint256 pixelCompression)
    {
        return OnChainPixelArtLibrary.getPixelCompression(layers);
    }

    function getColorCount(uint256[] memory layers)
        public
        pure
        returns (uint256 colorCount)
    {
        return OnChainPixelArtLibrary.getColorCount(layers);
    }

    function getStartingIndex(uint256[] memory layers)
        internal
        pure
        returns (uint256 startingIndex)
    {
        return OnChainPixelArtLibrary.getStartingIndex(layers);
    }

    function encodeColorArray(
        uint256[] memory colors,
        uint256 pixelCompression,
        uint256 colorCount
    ) public pure returns (uint256[] memory encoded) {
        return
            OnChainPixelArtLibrary.encodeColorArray(
                colors,
                pixelCompression,
                colorCount
            );
    }

    function composePalettes(
        uint256[] memory palette1,
        uint256[] memory palette2,
        uint256 colorCount1,
        uint256 colorCount2
    ) public pure returns (uint256[] memory composedPalette) {
        return
            OnChainPixelArtLibrary.composePalettes(
                palette1,
                palette2,
                colorCount1,
                colorCount2
            );
    }

    function composeLayer(
        uint256[] memory layer,
        uint256 colorOffset,
        uint256[] memory colors,
        uint256 totalPixels
    ) internal pure returns (uint256[] memory comp) {
        return
            OnChainPixelArtLibrary.composeLayer(
                layer,
                colorOffset,
                colors,
                totalPixels
            );
    }

    function composeLayers(
        uint256[] memory layer1,
        uint256[] memory layer2,
        uint256 totalPixels
    ) public pure returns (uint256[] memory comp) {
        return
            OnChainPixelArtLibrary.composeLayers(layer1, layer2, totalPixels);
    }

    function uri(string memory data)
        external
        pure
        returns (string memory encoded)
    {
        return OnChainPixelArtLibrary.uri(data);
    }

    function uriSvg(string memory data)
        external
        pure
        returns (string memory encoded)
    {
        return OnChainPixelArtLibrary.uriSvg(data);
    }

    function render(
        uint256[] memory canvas,
        uint256[] memory palette,
        uint256 xDim,
        uint256 yDim,
        string memory svgExtension,
        uint256 paddingX,
        uint256 paddingY
    ) external pure returns (string memory svg) {
        return
            OnChainPixelArtLibraryv2.render(
                canvas,
                palette,
                xDim,
                yDim,
                svgExtension,
                paddingX,
                paddingY
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

import {Array} from "./Array.sol";

pragma solidity ^0.8.0;

library OnChainPixelArtLibrary {
    using Array for string[];

    uint24 constant COLOR_MASK = 0xFFFFFF;
    //[12 bits startingIndex][12 bits color count][4 bits compression]
    uint8 constant metadataLength = 28;

    struct RenderTracker {
        uint256 colorCompression;
        uint256 pixelCompression;
        uint256 colorCount;
        // tracks which layer in the array of layers
        uint256 layerIndex;
        // tracks which packet within a single layer
        uint256 packet;
        // tracks individual pixel
        uint256 pixel;
        // width of a block to insert
        uint256 width;
        // tracks number of packets accross all layers
        uint256 iterator;
        uint256 x;
        uint256 y;
        uint256 blockSize;
        // x dim * y dim
        uint256 limit;
        // the number of packets including metdata
        uint256 layerOnePackets;
        // pixel compression + color compression
        uint256 packetLength;
        string[] svg;
        uint256 svgIndex;
    }

    struct ComposerTracker {
        uint256 colorCompression;
        uint256 pixelCompression;
        uint256 colorCount;
        uint256 colorOffset;
        uint256 pixel;
        uint256 layerIndex;
        uint256 packet;
        uint256 iterator;
        uint256 numberOfPixels;
        uint256 layerOnePackets;
        uint256 packetLength;
    }

    struct EncoderTracker {
        uint256 colorCompression;
        uint256 layer;
        uint256[] layers;
        uint256 color;
        uint256 packet;
        uint256 numberOfConsecutiveColors;
        uint256 layerIndex;
        uint256 startingIndex;
        uint256 endingIndex;
        uint256 maxConsecutiveColors;
        uint256 packetLength;
        uint256 packetsPerLayer;
        uint256 layerOnePackets;
    }

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64Encode(bytes memory data)
        public
        pure
        returns (string memory)
    {
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

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = 2 * length - 1; i > 0; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        buffer[0] = _HEX_SYMBOLS[value & 0xf];
        return string(buffer);
    }

    function toString(uint256 value) public pure returns (string memory) {
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

    function bitsToMask(uint256 bits) internal pure returns (uint256 mask) {
        return 2**bits - 1;
    }

    function getColorCompression(uint256 colorCount)
        internal
        pure
        returns (uint256 comp)
    {
        uint256 compression = 1;
        while (colorCount >= 2**compression) {
            compression = compression + 1;
        }

        return compression;
    }

    function getPixelCompression(uint256[] memory layers)
        internal
        pure
        returns (uint256 pixelCompression)
    {
        return layers[0] & 0xF;
    }

    function getColorCount(uint256[] memory layers)
        public
        pure
        returns (uint256 colorCount)
    {
        return (layers[0] & 0xFFF0) >> 4;
    }

    function getStartingIndex(uint256[] memory layers)
        internal
        pure
        returns (uint256 startingIndex)
    {
        return (layers[0] & 0xFFF0000) >> 16;
    }

    function encodeColorArray(
        uint256[] memory colors,
        uint256 pixelCompression,
        uint256 colorCount
    ) public pure returns (uint256[] memory encoded) {
        require(pixelCompression < 16, "compression not supported");

        EncoderTracker memory tracker = EncoderTracker(
            getColorCompression(colorCount),
            0,
            new uint256[](
                (colors.length /
                    (256 /
                        (pixelCompression + getColorCompression(colorCount)))) +
                    1
            ),
            0,
            0,
            0,
            0,
            0,
            colors.length - 1,
            2**pixelCompression - 1,
            0,
            0,
            0
        );

        tracker.packetLength = pixelCompression + tracker.colorCompression;
        tracker.packetsPerLayer = (256 / (tracker.packetLength) - 1);
        tracker.layerOnePackets = ((256 - metadataLength) /
            (tracker.packetLength) -
            1);

        // make sure we don't overflow the metadata (4096 max)
        while (colors[tracker.startingIndex] == 0) {
            tracker.startingIndex = increment(tracker.startingIndex);
        }

        while (colors[tracker.endingIndex] == 0) {
            tracker.endingIndex -= 1;
        }

        tracker.color = tracker.startingIndex;
        // otherwise we cutoff the last pixel
        tracker.endingIndex = increment(tracker.endingIndex);

        while (tracker.color < tracker.endingIndex) {
            // find number of colors in a row
            while (
                tracker.color + tracker.numberOfConsecutiveColors <
                colors.length &&
                // conditions are in order of most likely to break loop for gas savings
                colors[tracker.color + tracker.numberOfConsecutiveColors] ==
                colors[tracker.color] &&
                // less than or equal to?
                tracker.numberOfConsecutiveColors < tracker.maxConsecutiveColors
                // 1111 would be 2^4 - 1
            ) {
                tracker.numberOfConsecutiveColors = increment(
                    tracker.numberOfConsecutiveColors
                );
            }

            // add packet to layer
            tracker.layer =
                tracker.layer +
                ((
                    // make packet
                    ((colors[tracker.color] << pixelCompression) +
                        tracker.numberOfConsecutiveColors)
                ) <<
                    // shift new packet over to new spot
                    ((tracker.packetLength) * tracker.packet));

            // if we've reached the max number of packets in a 256, push and move to next layer. 10 packets is 0 - 9, hence -1
            // if we're on layer 0, we'll need to pack in the starting index too
            if (
                tracker.packet == tracker.packetsPerLayer ||
                (tracker.layerIndex == 0 &&
                    tracker.packet == tracker.layerOnePackets)
            ) {
                tracker.layers[tracker.layerIndex] = tracker.layer;
                tracker.layerIndex = increment(tracker.layerIndex);
                tracker.layer = 0;
                tracker.packet = 0;
            } else {
                // only progress packet if we on the same layer, otherwise we need to carry over to 0
                tracker.packet = increment(tracker.packet);
            }

            // update color to the next color
            tracker.color = tracker.color + tracker.numberOfConsecutiveColors;
            tracker.numberOfConsecutiveColors = 0;
        }

        // we only added layers if they were full, we now need to add the last "incomplete" layer
        tracker.layers[tracker.layerIndex] = tracker.layer;
        // add starting index and compression metadata to first layer
        tracker.layers[0] =
            (tracker.layers[0] << metadataLength) +
            ((tracker.startingIndex & 0xFFF) << 16) +
            ((colorCount & 0xFFF) << 4) +
            (pixelCompression & 0xF);

        // shave off the unused indices, add 1 to index to get array size
        uint256[] memory reducedLayers = new uint256[](
            increment(tracker.layerIndex)
        );

        for (uint256 i; i <= tracker.layerIndex; i = increment(i)) {
            reducedLayers[i] = tracker.layers[i];
        }

        return reducedLayers;
    }

    function composePalettes(
        uint256[] memory palette1,
        uint256[] memory palette2,
        uint256 colorCount1,
        uint256 colorCount2
    ) public pure returns (uint256[] memory composedPalette) {
        uint256 color;
        uint256 layer;
        uint256[] memory colors = new uint256[](colorCount1 + colorCount2);
        // calculate how many palette layers we'll need, 10 colors fit in one layer
        uint256[] memory composed = new uint256[](
            ((colorCount1 + colorCount2) / 10) + 1
        );
        uint256 layerIndex;

        //TODO: DRY this up

        // fill with colors from first palette
        while (color < colorCount1) {
            colors[color] =
                (palette1[color / 10] >> ((color % 10) * 24)) &
                COLOR_MASK;

            color += 1;
        }

        // fill with colors from second palette, don't reset layer or color for continuity
        while (color < colorCount1 + colorCount2) {
            colors[color] =
                (palette2[(color - colorCount1) / 10] >>
                    (((color - colorCount1) % 10) * 24)) &
                COLOR_MASK;

            color += 1;
        }

        for (uint256 c; c < colors.length; c += 1) {
            layer = layer + (colors[c] << ((c % 10) * 24));

            // we've put 10 colors in, 0 - 9
            if (c % 10 == 9) {
                composed[layerIndex] = layer;
                layerIndex += 1;
                layer = 0;
            }
        }

        // we need to push the last incomplete layer
        composed[layerIndex] = layer;

        return composed;
    }

    function composeLayer(
        uint256[] memory layer,
        // 0 if already on layer 1
        uint256 colorOffset,
        uint256[] memory colors,
        uint256 totalPixels
    ) internal pure returns (uint256[] memory comp) {
        ComposerTracker memory tracker = ComposerTracker(
            getColorCompression(getColorCount(layer)),
            getPixelCompression(layer),
            getColorCount(layer),
            colorOffset,
            getStartingIndex(layer),
            0,
            0,
            0,
            0,
            0,
            0
        );

        tracker.packetLength =
            tracker.pixelCompression +
            tracker.colorCompression;

        tracker.layerOnePackets =
            (256 - metadataLength) /
            (tracker.packetLength);

        layer[0] = layer[0] >> metadataLength;

        while (tracker.pixel < totalPixels) {
            // if the next layer would have had the breaking 0
            if (tracker.layerIndex > layer.length - 1) {
                break;
            }

            tracker.numberOfPixels =
                (layer[tracker.layerIndex] >>
                    ((tracker.packet) * (tracker.packetLength))) &
                bitsToMask(tracker.pixelCompression);

            if (tracker.numberOfPixels == 0) {
                break;
            }

            uint256 colorIndex = (layer[tracker.layerIndex] >>
                ((tracker.packet) *
                    (tracker.packetLength) +
                    tracker.pixelCompression)) &
                bitsToMask(tracker.colorCompression);

            if (colorIndex > 0) {
                for (uint256 i; i < tracker.numberOfPixels; i += 1) {
                    // offset by the number of colors in first layer
                    colors[tracker.pixel + i] = colorIndex + colorOffset;
                }
            }
            tracker.pixel += tracker.numberOfPixels;
            tracker.iterator += 1;

            tracker.layerIndex = getLayerIndex(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
            tracker.packet = getPacket(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
        }

        return colors;
    }

    // COLOR BITS/NUMBER OF PIXEL BITS

    function composeLayers(
        uint256[] memory layer1,
        uint256[] memory layer2,
        uint256 totalPixels
    ) public pure returns (uint256[] memory comp) {
        uint256 colorCount1 = getColorCount(layer1);
        uint256 colorCount2 = getColorCount(layer2);

        uint256 pixelCompression1 = getPixelCompression(layer1);
        uint256 pixelCompression2 = getPixelCompression(layer2);

        uint256[] memory colors = new uint256[](totalPixels);
        colors = composeLayer(layer1, 0, colors, totalPixels);
        colors = composeLayer(layer2, colorCount1, colors, totalPixels);

        uint256 pixelCompression = pixelCompression1;

        // pick smaller compression since it will likely be more optimal
        if (pixelCompression2 < pixelCompression1) {
            pixelCompression = pixelCompression2;
        }

        return
            encodeColorArray(
                colors,
                pixelCompression,
                colorCount1 + colorCount2
            );
    }

    function getLayerIndex(
        uint256 iterator,
        uint256 packetLength,
        uint256 layerOnePackets
    ) internal pure returns (uint256 layerIndex) {
        if (iterator < layerOnePackets) {
            return 0;
        }

        return (iterator - layerOnePackets) / (256 / (packetLength)) + 1;
    }

    function getPacket(
        uint256 iterator,
        uint256 packetLength,
        uint256 layerOnePackets
    ) internal pure returns (uint256 packet) {
        if (iterator < layerOnePackets) {
            return iterator % layerOnePackets;
        }
        return (iterator - layerOnePackets) % (256 / (packetLength));
    }

    function uri(string memory data)
        external
        pure
        returns (string memory encoded)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64Encode(bytes(data))
                )
            );
    }

    function uriSvg(string memory data)
        external
        pure
        returns (string memory encoded)
    {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    base64Encode(bytes(data))
                )
            );
    }

    function increment(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function getColorClass(uint256 index) private pure returns (bytes memory) {
        if (index > 26) {
            // we've run out of 2 digit combinations
            if (index > 676) {
                return
                    abi.encodePacked(
                        bytes(TABLE)[index % 26],
                        bytes(TABLE)[(index - 676) / 26],
                        bytes(TABLE)[index / 676]
                    );
            }
            return
                abi.encodePacked(
                    bytes(TABLE)[index % 26],
                    bytes(TABLE)[index / 26]
                );
        }
        return abi.encodePacked(bytes(TABLE)[index % 26]);
    }

    function getColorClasses(uint256[] memory palette, uint256 colorCount)
        internal
        pure
        returns (string memory c)
    {
        string[] memory classes = new string[](colorCount + 2);
        classes[0] = '<style type="text/css" ><![CDATA[';

        for (uint256 i = 0; i < colorCount; i = increment(i)) {
            uint256 paletteIndex = i / 10;

            classes[i + 1] = string(
                abi.encodePacked(
                    "rect.",
                    getColorClass(i),
                    " { fill: #",
                    toHexString(
                        (palette[paletteIndex] >> ((i % 10) * 24)) & COLOR_MASK
                    ),
                    "} "
                )
            );
        }
        classes[colorCount + 1] = "]]></style>";
        return classes.join();
    }

    // compressions are number of bits for compresssing
    function render(
        uint256[] memory canvas,
        uint256[] memory palette,
        uint256 xDim,
        uint256 yDim,
        string memory svgExtension
    ) external view returns (string memory svg) {
        RenderTracker memory tracker = RenderTracker(
            getColorCompression(getColorCount(canvas)),
            getPixelCompression(canvas),
            getColorCount(canvas),
            0,
            0,
            getStartingIndex(canvas),
            0,
            0,
            0,
            0,
            0,
            yDim * xDim,
            0,
            0,
            new string[](0),
            // svg starts at index 1 because we have a starting svg string
            1
        );

        tracker.packetLength =
            tracker.pixelCompression +
            tracker.colorCompression;

        tracker.layerOnePackets =
            (256 - metadataLength) /
            (tracker.packetLength);

        // breaks cause an extra block, so we need to add yDim for each possible line break
        tracker.svg = new string[](
            ((256 / tracker.packetLength) * canvas.length) + yDim
        );

        string memory close = string(abi.encodePacked('" ', svgExtension, ">"));

        // shave off metadata
        canvas[0] = canvas[0] >> metadataLength;

        tracker.svg[0] = string(
            abi.encodePacked(
                '<svg shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 ',
                toString(xDim),
                " ",
                toString(yDim),
                close,
                getColorClasses(palette, tracker.colorCount)
            )
        );

        // while pixel is in the bounds of the image
        while (tracker.pixel < tracker.limit) {
            tracker.packet = getPacket(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
            // 32 points for every layer of pixel groups
            // uint8 layer = uint8(iterator / packetsPerLayer);
            // 8 bits, 4 bits for color index and 4 bits for up to 16 repetitions
            uint256 numberOfPixels = (canvas[tracker.layerIndex] >>
                ((tracker.packet) * (tracker.packetLength))) &
                bitsToMask(tracker.pixelCompression);

            // short circuit the empty pixels at the end of an image
            if (numberOfPixels == 0) {
                break;
            }

            uint256 colorIndex = (canvas[uint8(tracker.layerIndex)] >>
                ((tracker.packet) *
                    (tracker.packetLength) +
                    tracker.pixelCompression)) &
                bitsToMask(tracker.colorCompression);

            // colorIndex 1 corresponds to color array index 0
            if (colorIndex > 0) {
                uint256 x = tracker.pixel % xDim;
                uint256 y = tracker.pixel / xDim;

                // calculate how many blocks of pixels we'll need to make
                tracker.blockSize = ((x + numberOfPixels) / xDim) + 1;
                // if we fit the row snuggly, we'll want to remove the 1 we added
                if ((x + numberOfPixels) % xDim == 0) {
                    tracker.blockSize = tracker.blockSize - 1;
                }

                for (
                    uint256 blockCounter;
                    blockCounter < tracker.blockSize;
                    blockCounter = increment(blockCounter)
                ) {
                    x = tracker.pixel % xDim;
                    y = tracker.pixel / xDim;

                    // check that the block overflows into the next row
                    if (numberOfPixels > xDim - x) {
                        tracker.width = xDim - x;
                    } else {
                        tracker.width = numberOfPixels;
                    }
                    tracker.pixel = tracker.pixel + tracker.width;
                    tracker.svg[tracker.svgIndex] = string(
                        abi.encodePacked(
                            svg,
                            '<rect x="',
                            toString(x),
                            '" y="',
                            toString(y),
                            '" width="',
                            toString(tracker.width),
                            '" height="1" class="',
                            getColorClass(colorIndex - 1),
                            '"/>'
                        )
                    );
                    numberOfPixels = numberOfPixels - tracker.width;
                    tracker.svgIndex += 1;
                }
            } else {
                // we still need to account for the empty pixels
                tracker.pixel = tracker.pixel + numberOfPixels;
            }

            tracker.iterator += 1;

            tracker.layerIndex = getLayerIndex(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
        }

        tracker.svg[tracker.iterator + 1] = "</svg>";

        return tracker.svg.join();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

import {OnChainPixelArtLibrary} from "./OnChainPixelArtLibrary.sol";
import {Array} from "./Array.sol";

pragma solidity ^0.8.0;

library OnChainPixelArtLibraryv2 {
    using Array for string[];

    uint24 constant COLOR_MASK = 0xFFFFFF;
    //[12 bits startingIndex][12 bits color count][4 bits compression]
    uint8 constant metadataLength = 28;

    struct RenderTracker {
        uint256 colorCompression;
        uint256 pixelCompression;
        uint256 colorCount;
        // tracks which layer in the array of layers
        uint256 layerIndex;
        // tracks which packet within a single layer
        uint256 packet;
        // tracks individual pixel
        uint256 pixel;
        // width of a block to insert
        uint256 width;
        // tracks number of packets accross all layers
        uint256 iterator;
        uint256 x;
        uint256 y;
        uint256 blockSize;
        // x dim * y dim
        uint256 limit;
        // the number of packets including metdata
        uint256 layerOnePackets;
        // pixel compression + color compression
        uint256 packetLength;
        string[] svg;
        uint256 svgIndex;
    }

    struct ComposerTracker {
        uint256 colorCompression;
        uint256 pixelCompression;
        uint256 colorCount;
        uint256 colorOffset;
        uint256 pixel;
        uint256 layerIndex;
        uint256 packet;
        uint256 iterator;
        uint256 numberOfPixels;
        uint256 layerOnePackets;
        uint256 packetLength;
    }

    struct EncoderTracker {
        uint256 colorCompression;
        uint256 layer;
        uint256[] layers;
        uint256 color;
        uint256 packet;
        uint256 numberOfConsecutiveColors;
        uint256 layerIndex;
        uint256 startingIndex;
        uint256 endingIndex;
        uint256 maxConsecutiveColors;
        uint256 packetLength;
        uint256 packetsPerLayer;
        uint256 layerOnePackets;
    }

    string public constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function increment(uint256 x) public pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function getColorClass(uint256 index) public pure returns (bytes memory) {
        if (index > 26) {
            // we've run out of 2 digit combinations
            if (index > 676) {
                return
                    abi.encodePacked(
                        bytes(TABLE)[index % 26],
                        bytes(TABLE)[(index - 676) / 26],
                        bytes(TABLE)[index / 676]
                    );
            }
            return
                abi.encodePacked(
                    bytes(TABLE)[index % 26],
                    bytes(TABLE)[index / 26]
                );
        }
        return abi.encodePacked(bytes(TABLE)[index % 26]);
    }

    function getViewBox(
        uint256 xDim,
        uint256 yDim,
        uint256 paddingX,
        uint256 paddingY
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'viewBox="-',
                    OnChainPixelArtLibrary.toString(paddingX),
                    " -",
                    OnChainPixelArtLibrary.toString(paddingY),
                    " ",
                    OnChainPixelArtLibrary.toString(xDim + paddingX * 2),
                    " ",
                    OnChainPixelArtLibrary.toString(yDim + paddingY * 2)
                    //closed by "close" variable in render
                )
            );
    }

    // compressions are number of bits for compresssing
    function render(
        uint256[] memory canvas,
        uint256[] memory palette,
        uint256 xDim,
        uint256 yDim,
        string memory svgExtension,
        uint256 paddingX,
        uint256 paddingY
    ) external pure returns (string memory svg) {
        RenderTracker memory tracker = RenderTracker(
            OnChainPixelArtLibrary.getColorCompression(
                OnChainPixelArtLibrary.getColorCount(canvas)
            ),
            OnChainPixelArtLibrary.getPixelCompression(canvas),
            OnChainPixelArtLibrary.getColorCount(canvas),
            0,
            0,
            OnChainPixelArtLibrary.getStartingIndex(canvas),
            0,
            0,
            0,
            0,
            0,
            yDim * xDim,
            0,
            0,
            new string[](0),
            // svg starts at index 1 because we have a starting svg string
            1
        );

        tracker.packetLength =
            tracker.pixelCompression +
            tracker.colorCompression;

        tracker.layerOnePackets =
            (256 - metadataLength) /
            (tracker.packetLength);

        // breaks cause an extra block, so we need to add yDim for each possible line break
        tracker.svg = new string[](
            ((256 / tracker.packetLength) * canvas.length) + yDim
        );

        string memory close = string(abi.encodePacked('" ', svgExtension, ">"));

        // shave off metadata
        canvas[0] = canvas[0] >> metadataLength;

        tracker.svg[0] = string(
            abi.encodePacked(
                '<svg shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" ',
                getViewBox(xDim, yDim, paddingX, paddingY),
                close,
                OnChainPixelArtLibrary.getColorClasses(
                    palette,
                    tracker.colorCount
                )
            )
        );

        // while pixel is in the bounds of the image
        while (tracker.pixel < tracker.limit) {
            tracker.packet = OnChainPixelArtLibrary.getPacket(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
            // 32 points for every layer of pixel groups
            // uint8 layer = uint8(iterator / packetsPerLayer);
            // 8 bits, 4 bits for color index and 4 bits for up to 16 repetitions
            uint256 numberOfPixels = (canvas[tracker.layerIndex] >>
                ((tracker.packet) * (tracker.packetLength))) &
                OnChainPixelArtLibrary.bitsToMask(tracker.pixelCompression);

            // short circuit the empty pixels at the end of an image
            if (numberOfPixels == 0) {
                break;
            }

            uint256 colorIndex = (canvas[uint8(tracker.layerIndex)] >>
                ((tracker.packet) *
                    (tracker.packetLength) +
                    tracker.pixelCompression)) &
                OnChainPixelArtLibrary.bitsToMask(tracker.colorCompression);

            // colorIndex 1 corresponds to color array index 0
            if (colorIndex > 0) {
                uint256 x = tracker.pixel % xDim;
                uint256 y = tracker.pixel / xDim;

                // calculate how many blocks of pixels we'll need to make
                tracker.blockSize = ((x + numberOfPixels) / xDim) + 1;
                // if we fit the row snuggly, we'll want to remove the 1 we added
                if ((x + numberOfPixels) % xDim == 0) {
                    tracker.blockSize = tracker.blockSize - 1;
                }

                for (
                    uint256 blockCounter;
                    blockCounter < tracker.blockSize;
                    blockCounter = increment(blockCounter)
                ) {
                    x = tracker.pixel % xDim;
                    y = tracker.pixel / xDim;

                    // check that the block overflows into the next row
                    if (numberOfPixels > xDim - x) {
                        tracker.width = xDim - x;
                    } else {
                        tracker.width = numberOfPixels;
                    }
                    tracker.pixel = tracker.pixel + tracker.width;
                    tracker.svg[tracker.svgIndex] = string(
                        abi.encodePacked(
                            svg,
                            '<rect x="',
                            OnChainPixelArtLibrary.toString(x),
                            '" y="',
                            OnChainPixelArtLibrary.toString(y),
                            '" width="',
                            OnChainPixelArtLibrary.toString(tracker.width),
                            '" height="1" class="',
                            getColorClass(colorIndex - 1),
                            '"/>'
                        )
                    );
                    numberOfPixels = numberOfPixels - tracker.width;
                    tracker.svgIndex += 1;
                }
            } else {
                // we still need to account for the empty pixels
                tracker.pixel = tracker.pixel + numberOfPixels;
            }

            tracker.iterator += 1;

            tracker.layerIndex = OnChainPixelArtLibrary.getLayerIndex(
                tracker.iterator,
                tracker.packetLength,
                tracker.layerOnePackets
            );
        }

        tracker.svg[tracker.iterator + 1] = "</svg>";

        return tracker.svg.join();
    }
}

// SPDX-License-Identifier: MIT

/*
 * @title Arrays Utils
 * @author Clement Walter <[email protected]>
 *
 * @notice An attempt at implementing some of the widely used javascript's Array functions in solidity.
 */
pragma solidity ^0.8.0;

error EmptyArray();
error GlueOutOfBounds(uint256 length);

library Array {
    function join(string[] memory a, string memory glue)
        public
        pure
        returns (string memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return string(_joinReferenceType(inputPointer, gluePointer));
    }

    function join(string[] memory a) public pure returns (string memory) {
        return join(a, "");
    }

    function join(bytes[] memory a, bytes memory glue)
        public
        pure
        returns (bytes memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return _joinReferenceType(inputPointer, gluePointer);
    }

    function join(bytes[] memory a) public pure returns (bytes memory) {
        return join(a, bytes(""));
    }

    function join(bytes2[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 0);
    }

    /// @dev Join the underlying array of bytes2 to a string.
    function join(uint16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 256 - 16);
    }

    function join(bytes3[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 3, 0);
    }

    function join(bytes4[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 4, 0);
    }

    function join(bytes8[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 8, 0);
    }

    function join(bytes16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 16, 0);
    }

    function join(bytes32[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 32, 0);
    }

    function _joinValueType(
        uint256 a,
        uint256 typeLength,
        uint256 shiftLeft
    ) private pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            let inputLength := mload(a)
            let inputData := add(a, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Initialize the length of the final bytes: length is typeLength x inputLength (array of bytes4)
            mstore(tempBytes, mul(inputLength, typeLength))
            let memoryPointer := add(tempBytes, 0x20)

            // Iterate over all bytes4
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentSlot := shl(shiftLeft, mload(pointer))
                mstore(memoryPointer, currentSlot)
                memoryPointer := add(memoryPointer, typeLength)
            }

            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }

    function _joinReferenceType(uint256 inputPointer, uint256 gluePointer)
        public
        pure
        returns (bytes memory tempBytes)
    {
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Skip the first 32 bytes where we will store the length of the result
            let memoryPointer := add(tempBytes, 0x20)

            // Load glue
            let glueLength := mload(gluePointer)
            if gt(glueLength, 0x20) {
                revert(gluePointer, 0x20)
            }
            let glue := mload(add(gluePointer, 0x20))

            // Load the length (first 32 bytes)
            let inputLength := mload(inputPointer)
            let inputData := add(inputPointer, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Initialize the length of the final string
            let stringLength := 0

            // Iterate over all strings (a string is itself an array).
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentStringArray := mload(pointer)
                let currentStringLength := mload(currentStringArray)
                stringLength := add(stringLength, currentStringLength)
                let currentStringBytesCount := add(
                    div(currentStringLength, 0x20),
                    gt(mod(currentStringLength, 0x20), 0)
                )

                let currentPointer := add(currentStringArray, 0x20)

                for {
                    let copiedBytesCount := 0
                } lt(copiedBytesCount, currentStringBytesCount) {
                    copiedBytesCount := add(copiedBytesCount, 1)
                } {
                    mstore(
                        add(memoryPointer, mul(copiedBytesCount, 0x20)),
                        mload(currentPointer)
                    )
                    currentPointer := add(currentPointer, 0x20)
                }
                memoryPointer := add(memoryPointer, currentStringLength)
                mstore(memoryPointer, glue)
                memoryPointer := add(memoryPointer, glueLength)
            }

            mstore(
                tempBytes,
                add(stringLength, mul(sub(inputLength, 1), glueLength))
            )
            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }
}