// SPDX-License-Identifier: GPL-3.0

/// @title A contract used to convert multi-part RLE compressed images to SVG

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISVGRenderer } from './interfaces/ISVGRenderer.sol';
import { StringBufferLib } from '@lukasz.glen/string-buffer/contracts/StringBufferLib.sol';

contract SVGRenderer is ISVGRenderer {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';
    uint256 private constant _INDEX_TO_BYTES3_FACTOR = 4;

    // prettier-ignore
    string private constant _SVG_START_TAG = '<svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" fill="#597A8A"><rect width="100%" height="100%" />';
    string private constant _SVG_END_TAG = '</svg>';

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Draw {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteId;
        ContentBounds bounds;
        Draw[] draws;
    }

    /**
     * @notice Given RLE image data and color palette pointers, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams calldata params) external pure override returns (string memory svg) { // 6 480 356
        // if (bytes(params.background).length != 0) {
        //     // prettier-ignore
        //     return string(
        //         abi.encodePacked(
        //             _SVG_START_TAG,
        //             '<rect width="100%" height="100%" fill="#', params.background, '" />',
        //             _generateSVGRects(params),
        //             _SVG_END_TAG
        //         )
        //     );
        // }
        StringBufferLib.StringBuffer memory outputBuffer = StringBufferLib.initialize(2048);
        StringBufferLib.appendBytes(outputBuffer, bytes(_SVG_START_TAG));
        _generateSVGRects(params, outputBuffer);
        StringBufferLib.appendBytes(outputBuffer, bytes(_SVG_END_TAG));
        StringBufferLib.finalize(outputBuffer);
        return string(outputBuffer.data);
    }

    /**
     * @notice Given RLE image data and a color palette pointer, merge to generate a partial SVG image.
     */
    function generateSVGPart(Part calldata part) external pure override returns (string memory partialSVG) {
        Part[] memory parts = new Part[](1);
        parts[0] = part;

        StringBufferLib.StringBuffer memory outputBuffer = StringBufferLib.initialize(2048);
        _generateSVGRects(SVGParams({ parts: parts/*, background: '' */}), outputBuffer);
        StringBufferLib.finalize(outputBuffer);
        return string(outputBuffer.data);
    }

    /**
     * @notice Given RLE image data and color palette pointers, merge to generate a partial SVG image.
     */
    function generateSVGParts(Part[] calldata parts) external pure override returns (string memory partialSVG) {
        StringBufferLib.StringBuffer memory outputBuffer = StringBufferLib.initialize(2048);
        _generateSVGRects(SVGParams({ parts: parts/*, background: '' */}), outputBuffer);
        StringBufferLib.finalize(outputBuffer);
        return string(outputBuffer.data);
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, StringBufferLib.StringBuffer memory outputBuffer)
        private
        pure
    {
        bytes32[25] memory lookup = [
            bytes32('0'), '4', '8', '12', '16', '20', '24', '28',
            '32', '36', '40', '44', '48', '52', '56', '60',
            '64', '68', '72', '76', '80', '84', '88', '92',
            '96'
        ];
        string[] memory cache;
        uint256 cachedPaletteId = 256; // just to enforce cache initialization, max paletteId is 255
        for (uint8 p = 0; p < params.parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p].image);
            if (cachedPaletteId != image.paletteId) {
                cache = new string[](144); // Initialize color cache, assumed that palette is shorter than 144
                cachedPaletteId = image.paletteId;
            }
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;

            for (uint256 i = 0; i < image.draws.length; i++) {
                Draw memory draw = image.draws[i];

                uint8 length = _getRectLength(currentX, draw.length, image.bounds.right);
                while (length > 0) {
                    if (draw.colorIndex != 0) {
                        string memory colorPart = _getColorPart(params.parts[p].palette, draw.colorIndex, cache); // color
                        StringBufferLib.appendBytesXX(outputBuffer, 0x3C726563742077696474683D2200000000000000000000000000000000000000, 13);  // <rect width="
                        StringBufferLib.appendBytesXX(outputBuffer, lookup[length], length < 3 ? 1 : 2);
                        StringBufferLib.appendBytesXX(outputBuffer, 0x22206865696768743D22342220783D2200000000000000000000000000000000, 16);  // " height="4" x="
                        StringBufferLib.appendBytesXX(outputBuffer, lookup[currentX], currentX < 3 ? 1 : 2);
                        StringBufferLib.appendBytesXX(outputBuffer, 0x2220793D22000000000000000000000000000000000000000000000000000000, 5);  // " y="
                        StringBufferLib.appendBytesXX(outputBuffer, lookup[currentY], currentY < 3 ? 1 : 2);
                        StringBufferLib.appendBytes(outputBuffer, bytes(colorPart));
                    }

                    currentX += length;
                    if (currentX == image.bounds.right) {
                        currentX = image.bounds.left;
                        currentY++;
                    }

                    draw.length -= length;
                    length = _getRectLength(currentX, draw.length, image.bounds.right);
                }
            }
        }
    }

    /**
     * @notice Given an x-coordinate, draw length, and right bound, return the draw
     * length for a single SVG rectangle.
     */
    function _getRectLength(
        uint256 currentX,
        uint8 drawLength,
        uint8 rightBound
    ) private pure returns (uint8) {
        uint8 remainingPixelsInLine = rightBound - uint8(currentX);
        return drawLength <= remainingPixelsInLine ? drawLength : remainingPixelsInLine;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Draw[] memory draws = new Draw[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            draws[cursor] = Draw({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }
        return DecodedImage({ paletteId: uint8(image[0]), bounds: bounds, draws: draws });
    }

    /**
     * @notice Get the target hex color code from the cache. Populate the cache if
     * the color code does not yet exist.
     */
    function _getColorPart(
        bytes memory palette,
        uint256 index,
        string[] memory cache
    ) private pure returns (string memory) {
        unchecked {
            if (bytes(cache[index]).length == 0) {
                uint256 i = index * _INDEX_TO_BYTES3_FACTOR;
                bytes memory entry;
                if (palette[i + 3] == 0xff) {
                    entry = '" fill="#      " />';
                } else {
                    entry = '" fill="#      " opacity="0.  " />';
                    uint256 opacityValue = uint256(uint8(palette[i + 3])) * 100 / 0xff;
                    entry[28] = bytes1(uint8(48 + (opacityValue / 10))); // 48 is ascii 0
                    entry[29] = bytes1(uint8(48 + (opacityValue % 10))); // 48 is ascii 0
                }
                entry[9] = _HEX_SYMBOLS[uint8(palette[i]) >> 4];
                entry[10] = _HEX_SYMBOLS[uint8(palette[i]) & 0xf];
                entry[11] = _HEX_SYMBOLS[uint8(palette[i + 1]) >> 4];
                entry[12] = _HEX_SYMBOLS[uint8(palette[i + 1]) & 0xf];
                entry[13] = _HEX_SYMBOLS[uint8(palette[i + 2]) >> 4];
                entry[14] = _HEX_SYMBOLS[uint8(palette[i + 2]) & 0xf];
                cache[index] = string(entry);
                return string(entry);
            }
            return cache[index];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for SVGRenderer

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface ISVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        Part[] parts;
//        string background;
    }

    function generateSVG(SVGParams memory params) external view returns (string memory svg);

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);

    function generateSVGParts(Part[] memory parts) external view returns (string memory partialSVG);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title String Buffer Library
 * @author lukasz-glen
 * @dev String Buffer for Solidity.
 * Allocates a single buffer and writes data with appending functions.
 * It works well with large strings/bytes/amount of data/multiple appending.
 * Multiple appends are more gas efficient than multiple abi.encodePacked().
 * StringBuffer struct is fly weight because it uses memory pointers.
 * StringBuffer struct is valid only within a single call, cannot be stored or be passed to another contracts.
 * It uses low level memory manipulation, so some provers or other tools can fail - you must be careful.
 * It does not break solidity memory layout, but it depends on its internal memory structures.
 */
library StringBufferLib {

    struct StringBuffer {
        // a buffer, the length field is changed by finalize()
        bytes data;
        // a pointer in the memory, the current pointer for buffer writing
        uint256 pointer;
        // a pointer is the memory, the boundary pointer for buffer writing, 32 bytes margin not included
        uint256 limit;
    }

    /**
     * @dev creates a new buffer
     * it is better to start large initial length, extending a buffer actually copies byte arrays
     * the actual buffer length is length + 32, 32 bytes is the margin for safe copying
     * @param length initial buffer length
     */
    function initialize(uint256 length) internal pure returns (StringBuffer memory stringBuffer) {
        unchecked {
            bytes memory data = new bytes(length + 32);
            uint256 pointer;
            assembly {
                pointer := add(data, 0x20)
            }
            stringBuffer = StringBuffer(data, pointer, pointer + length);
        }
    }

    /**
     * @dev it sets an actual length of stringBuffer.data
     * it can be called multiple times if needed
     */
    function finalize(StringBuffer memory stringBuffer) internal pure {
        // stringBuffer.data.length = stringBuffer.pointer - beginning of stringBuffer.data
        assembly {
            mstore(mload(stringBuffer), sub(mload(add(stringBuffer, 0x20)), add(mload(stringBuffer), 0x20)))
        }
    }

    /**
     * @dev appends bytes/string to a buffer
     * the buffer is extended if needed
     * if appending a constant string not longer than 32 bytes, it is better to use appendBytesXX()
     */
    function appendBytes(StringBuffer memory stringBuffer, bytes memory newData) internal pure {
        unchecked {
            uint256 newDataLength = newData.length;
            // const value
            uint256 srcEndPointer;
            stringBuffer.pointer += newDataLength;
            // const value
            uint256 destEndPointer = stringBuffer.pointer;
            // extend buffer if the limit is exceeded
            if (destEndPointer > stringBuffer.limit) {
                // values of srcEndPointer and destEndPointer to copy a buffer
                srcEndPointer = destEndPointer - newDataLength;
                uint256 length;
                // length = previous stringBuffer.pointer - beginning of stringBuffer.data
                assembly {
                    length := sub(srcEndPointer, add(mload(stringBuffer), 0x20))
                }
                // a new data buffer, + 32 bytes of margin
                bytes memory extendedData = new bytes(2 * length + 2 * newDataLength + 32);
                assembly {
                    destEndPointer := add(add(extendedData, 0x20), length)
                }
                // copy from an old buffer to a new buffer
                // that is assumed that allocating a string of length 1 << 255 is impossible
                // the condition fails on underflows (length - 1 and length -= 32)
                // length - 1 filters out the case length == 0
                // note that this condition is not equal to length < (1 << 255), check the case length == 0
                while (length - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                    assembly {
                        mstore(sub(destEndPointer, length), mload(sub(srcEndPointer, length)))
                    }
                    length -= 32;
                }
                destEndPointer += newDataLength;
                stringBuffer.data = extendedData;
                stringBuffer.pointer = destEndPointer;
                // stringBuffer.limit = beginning of extendedData + extendedData.length - 32;
                // 32 bytes are subtracted because of the margin at the end
                // first 32 bytes of bytes type keep length, so it is actually - 32 bytes to the length
                assembly {
                    mstore(add(stringBuffer, 0x40), add(extendedData, mload(extendedData)))
                }
            }
            assembly {
                srcEndPointer := add(add(newData, 0x20), newDataLength)
            }
            // that is assumed that allocating a string of newDataLength 1 << 255 is impossible
            // the condition fails on underflows (newDataLength - 1 and newDataLength -= 32)
            // newDataLength - 1 filters out the case newDataLength == 0
            // note that this condition is not equal to newDataLength < (1 << 255), check the case newDataLength == 0
            // copying is safe because of 32 bytes margin
            while (newDataLength - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                assembly {
                    mstore(sub(destEndPointer, newDataLength), mload(sub(srcEndPointer, newDataLength)))
                }
                newDataLength -= 32;
            }
        }
    }

    function appendBytes32(StringBuffer memory stringBuffer, bytes32 newData) internal pure {
        // first copy data, than check limits, it is safe because of 32 bytes margin
        // mem[stringBuffer.pointer, +32] = newData
        assembly {
            mstore(mload(add(stringBuffer, 0x20)), newData)
        }
        unchecked {
            stringBuffer.pointer += 32;
            // extend buffer if the limit is exceeded
            if (stringBuffer.pointer > stringBuffer.limit) {
                // a new data buffer, + 32 bytes of margin
                bytes memory extendedData = new bytes(2 * stringBuffer.data.length + 32);
                uint256 srcEndPointer = stringBuffer.pointer;
                uint256 destEndPointer;
                uint256 length;
                // length = stringBuffer.pointer - beginning of stringBuffer.data
                assembly {
                    length := sub(srcEndPointer, add(mload(stringBuffer), 0x20))
                    destEndPointer := add(add(extendedData, 0x20), length)
                }
                // copy from an old buffer to a new buffer
                // that is assumed that allocating a string of length 1 << 255 is impossible
                // the condition fails on underflows (length - 1 and length -= 32)
                // length - 1 filters out the case length == 0
                // note that this condition is not equal to length < (1 << 255), check the case length == 0
                while (length - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                    assembly {
                        mstore(sub(destEndPointer, length), mload(sub(srcEndPointer, length)))
                    }
                    length -= 32;
                }
                stringBuffer.data = extendedData;
                stringBuffer.pointer = destEndPointer;
                // stringBuffer.limit = beginning of extendedData + extendedData.length - 32;
                // 32 bytes are subtracted because of the margin at the end
                // first 32 bytes of bytes type keep length, so it is actually - 32 bytes to the length
                assembly {
                    mstore(add(stringBuffer, 0x40), add(extendedData, mload(extendedData)))
                }
            }
        }
    }

    /**
     * @dev it copies only first 'length' bytes of newData to stringBuffer.data
     * it is not validated that length <= 32
     * the buffer is extended if needed
     */
    function appendBytesXX(StringBuffer memory stringBuffer, bytes32 newData, uint256 newDataLength) internal pure {
        // first copy data, than check limits, it is safe because of 32 bytes margin
        // mem[stringBuffer.pointer, +32] = newData
        assembly {
            mstore(mload(add(stringBuffer, 0x20)), newData)
        }
        unchecked {
            stringBuffer.pointer += newDataLength;
            // extend buffer if the limit is exceeded
            if (stringBuffer.pointer > stringBuffer.limit) {
                // a new data buffer, + 32 bytes of margin
                bytes memory extendedData = new bytes(2 * stringBuffer.data.length + 32);
                uint256 srcEndPointer = stringBuffer.pointer;
                uint256 destEndPointer;
                uint256 length;
                // length = stringBuffer.pointer - beginning of stringBuffer.data
                assembly {
                    length := sub(srcEndPointer, add(mload(stringBuffer), 0x20))
                    destEndPointer := add(add(extendedData, 0x20), length)
                }
                // copy from an old buffer to a new buffer
                // that is assumed that allocating a string of length 1 << 255 is impossible
                // the condition fails on underflows (length - 1 and length -= 32)
                // length - 1 filters out the case length == 0
                // note that this condition is not equal to length < (1 << 255), check the case length == 0
                while (length - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                    assembly {
                        mstore(sub(destEndPointer, length), mload(sub(srcEndPointer, length)))
                    }
                    length -= 32;
                }
                stringBuffer.data = extendedData;
                stringBuffer.pointer = destEndPointer;
                // stringBuffer.limit = beginning of extendedData + extendedData.length - 32;
                // 32 bytes are subtracted because of the margin at the end
                // first 32 bytes of bytes type keep length, so it is actually - 32 bytes to the length
                assembly {
                    mstore(add(stringBuffer, 0x40), add(extendedData, mload(extendedData)))
                }
            }
        }
    }
}