// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./lib/Base64.sol";
import "./IGIFEncoder.sol";
import "./GIF.sol";

/** @notice Encodes image data in GIF format. GIF is much more compact than SVG, allows for animation (SVG does as well), and also represents images that are already rastered. 
            This is important if the art shouldn't change fundamentally depending on which process is doing the SVG rendering, such as a browser or custom application.
 */
contract GIFEncoder is IGIFEncoder {
    
    uint32 private constant MASK = (1 << 12) - 1;
    uint32 private constant CLEAR_CODE = 256;
    uint32 private constant END_CODE = 257;
    uint16 private constant CODE_START = 258;
    uint16 private constant TREE_TABLE_LENGTH = 4096;
    uint16 private constant CODE_TABLE_LENGTH = TREE_TABLE_LENGTH - CODE_START;

    bytes private constant HEADER = hex"474946383961";
    bytes private constant NETSCAPE = hex"21FF0b4E45545343415045322E300301000000";
    bytes private constant GIF_URI_PREFIX = "data:image/gif;base64,";

    struct GCT {
        uint32 start;
        uint32 count;
    }

    struct LZW {
        uint16 codeCount;
        int32 codeBitsUsed;
        uint32 activePrefix;
        uint32 activeSuffix;
        uint32[CODE_TABLE_LENGTH] codeTable;
        uint16[TREE_TABLE_LENGTH] treeRoots;
        Pending pending;
    }

    struct Pending {
        uint32 value;
        int32 bits;
        uint32 chunkSize;
    }

    function getDataUri(GIF memory gif) external pure returns (string memory) {
        (bytes memory buffer, uint length) = encode(gif);
        string memory base64 = Base64.encode(buffer, length);
        return string(abi.encodePacked(GIF_URI_PREFIX, base64));
    }

    function encode(GIF memory gif) private pure returns (bytes memory buffer, uint length) {
        buffer = new bytes(gif.width * gif.height * 3);
        uint32 position = 0;

        // header
        position = writeBuffer(buffer, position, HEADER);

        // logical screen descriptor
        {
            position = writeUInt16(buffer, position, gif.width);
            position = writeUInt16(buffer, position, gif.height);

            uint8 packed = 0;
            packed |= 1 << 7;
            packed |= 7 << 4;
            packed |= 0 << 3;
            packed |= 7 << 0;

            position = writeByte(buffer, position, packed);
            position = writeByte(buffer, position, 0);
            position = writeByte(buffer, position, 0);
        }

        // global color table
        GCT memory gct;
        gct.start = position;
        gct.count = 1;
        {
            for (uint256 i = 0; i < 768; i++) {
                position = writeByte(buffer, position, 0);
            }
        }

        if (gif.frameCount > 1) {
            // netscape extension block
            position = writeBuffer(buffer, position, NETSCAPE);
        }

        uint32[CODE_TABLE_LENGTH] memory codeTable;

        for (uint256 i = 0; i < gif.frameCount; i++) {
            // graphic control extension
            {
                position = writeByte(buffer, position, 0x21);
                position = writeByte(buffer, position, 0xF9);
                position = writeByte(buffer, position, 0x04);

                uint8 packed = 0;
                packed |= (gif.frameCount > 1 ? 2 : 0) << 2;
                packed |= 0 << 1;
                packed |= 1 << 0;
                position = writeByte(buffer, position, packed);

                position = writeUInt16(buffer, position, gif.frameCount > 1 ? gif.frames[i].delay : uint16(0));                
                position = writeByte(buffer, position, 0);
                position = writeByte(buffer, position, 0);
            }

            // image descriptor
            {
                position = writeByte(buffer, position, 0x2C);
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, gif.frames[i].width);
                position = writeUInt16(buffer, position, gif.frames[i].height);

                uint8 packed = 0;
                packed |= 0 << 7;
                packed |= 0 << 6;
                packed |= 0 << 5;
                packed |= 0 << 0;
                position = writeByte(buffer, position, packed);
            }

            // image data
            {
                uint16[TREE_TABLE_LENGTH] memory treeRoots;

                (uint32 p, uint32 c) = writeImageData(
                    buffer,
                    position,
                    gct,
                    gif.frames[i],
                    LZW(0, 9, 0, 0, codeTable, treeRoots, Pending(0, 0, 0))
                );
                position = p;
                gct.count = c;
            }
        }

        // trailer
        position = writeByte(buffer, position, 0x3B);

        return (buffer, position);
    }

    function writeBuffer(
        bytes memory buffer,
        uint32 position,
        bytes memory value
    ) private pure returns (uint32) {
        for (uint256 i = 0; i < value.length; i++)
            buffer[position++] = bytes1(value[i]);
        return position;
    }

    function writeByte(
        bytes memory buffer,
        uint32 position,
        uint8 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(value);
        return position;
    }

    function writeUInt16(
        bytes memory buffer,
        uint32 position,
        uint16 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(uint8(uint16(value >> 0)));
        buffer[position++] = bytes1(uint8(uint16(value >> 8)));
        return position;
    }

    function writeImageData(
        bytes memory buffer,
        uint32 position,
        GCT memory gct,
        GIFFrame memory frame,
        LZW memory lzw
    ) private pure returns (uint32, uint32) {
                
        position = writeByte(buffer, position, 8);
        position = writeByte(buffer, position, 0);

        lzw.codeCount = 0;
        lzw.codeBitsUsed = 9;

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                CLEAR_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[0]
            );
            gct.count = c;
            lzw.activePrefix = p;
        }        

        for (uint32 i = 1; i < frame.width * frame.height; i++) {

            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[i]
            );
            gct.count = c;
            lzw.activeSuffix = p;

            position = writeColor(buffer, position, lzw);
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                lzw.activePrefix,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                END_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        if (lzw.pending.bits > 0) {
            position = writeChunked(
                buffer,
                position,
                uint8(lzw.pending.value & 0xFF),
                lzw.pending
            );
            lzw.pending.value = 0;
            lzw.pending.bits = 0;
        }

        if (lzw.pending.chunkSize > 0) {
            buffer[position - lzw.pending.chunkSize - 1] = bytes1(
                uint8(uint32(lzw.pending.chunkSize))
            );
            lzw.pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return (position, gct.count);
    }

    function writeColor(bytes memory buffer, uint32 position, LZW memory lzw) private pure returns (uint32) {
        uint32 lastTreePosition = 0;
        uint32 foundSuffix = 0;

        bool found = false;
        {
            uint32 treePosition = lzw.treeRoots[lzw.activePrefix];
            while (treePosition != 0) {
                lastTreePosition = treePosition;
                foundSuffix = lzw.codeTable[treePosition - CODE_START] & 0xFF;

                if (lzw.activeSuffix == foundSuffix) {
                    lzw.activePrefix = treePosition;
                    found = true;
                    break;
                } else if (lzw.activeSuffix < foundSuffix) {
                    treePosition = (lzw.codeTable[treePosition - CODE_START] >> 8) & MASK;
                } else {
                    treePosition = lzw.codeTable[treePosition - CODE_START] >> 20;
                }
            }
        }

        if (!found) {
            {
                (
                    uint32 p,
                    Pending memory pending
                ) = writeVariableBitsChunked(
                        buffer,
                        position,
                        lzw.activePrefix,
                        lzw.codeBitsUsed,
                        lzw.pending
                    );
                position = p;
                lzw.pending = pending;
            }

            if (lzw.codeCount == CODE_TABLE_LENGTH) {
                {
                    (
                        uint32 p,
                        Pending memory pending
                    ) = writeVariableBitsChunked(
                            buffer,
                            position,
                            CLEAR_CODE,
                            lzw.codeBitsUsed,
                            lzw.pending
                        );
                    position = p;
                    lzw.pending = pending;
                }

                for (uint16 j = 0; j < TREE_TABLE_LENGTH; j++) {
                    lzw.treeRoots[j] = 0;
                }
                lzw.codeCount = 0;
                lzw.codeBitsUsed = 9;
            } else {
                if (lastTreePosition == 0)
                    lzw.treeRoots[lzw.activePrefix] = uint16(CODE_START + lzw.codeCount);
                else if (lzw.activeSuffix < foundSuffix)
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 8)) | (uint32(CODE_START + lzw.codeCount) << 8);
                else {
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 20)) | (uint32(CODE_START + lzw.codeCount) << 20);
                }

                if (uint32(CODE_START + lzw.codeCount) == (uint32(1) << uint32(lzw.codeBitsUsed))) {
                    lzw.codeBitsUsed++;
                }

                lzw.codeTable[lzw.codeCount++] = lzw.activeSuffix;
            }

            lzw.activePrefix = lzw.activeSuffix;
        }

        return position;
    }    

    function writeVariableBitsChunked(
        bytes memory buffer,
        uint32 position,
        uint32 value,
        int32 bits,
        Pending memory pending
    ) private pure returns (uint32, Pending memory) {
        while (bits > 0) {
            int32 takeBits = min(bits, 8 - pending.bits);
            uint32 takeMask = uint32((uint32(1) << uint32(takeBits)) - 1);

            pending.value |= ((value & takeMask) << uint32(pending.bits));

            pending.bits += takeBits;
            bits -= takeBits;
            value >>= uint32(takeBits);

            if (pending.bits == 8) {
                position = writeChunked(
                    buffer,
                    position,
                    uint8(pending.value & 0xFF),
                    pending
                );
                pending.value = 0;
                pending.bits = 0;
            }
        }

        return (position, pending);
    }

    function writeChunked(
        bytes memory buffer,
        uint32 position,
        uint8 value,
        Pending memory pending
    ) private pure returns (uint32) {
        position = writeByte(buffer, position, value);
        pending.chunkSize++;

        if (pending.chunkSize == 255) {
            buffer[position - 256] = bytes1(uint8(255));
            pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return position;
    }

    function getColorTableIndex(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32, uint32) {
        if (target >> 24 != 0xFF) return (colorCount, 0);

        uint32 i = 1;
        for (; i < colorCount; i++) {
            if (uint8(buffer[colorTableStart + i * 3 + 0]) != uint8(target >> 16)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 1]) != uint8(target >> 8)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 2]) != uint8(target >> 0)
            ) continue;
            return (colorCount, i);
        }

        if (colorCount == 256) {
            return (
                colorCount,
                getColorTableBestMatch(
                    buffer,
                    colorTableStart,
                    colorCount,
                    target
                )
            );
        } else {
            buffer[colorTableStart + colorCount * 3 + 0] = bytes1(uint8(target >> 16));
            buffer[colorTableStart + colorCount * 3 + 1] = bytes1(uint8(target >> 8));
            buffer[colorTableStart + colorCount * 3 + 2] = bytes1(uint8(target >> 0));
            return (colorCount + 1, colorCount);
        }
    }

    function getColorTableBestMatch(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32) {
        uint32 bestDistance = type(uint32).max;
        uint32 bestIndex = 0;

        for (uint32 i = 1; i < colorCount; i++) {
            uint32 distance;
            {
                uint8 rr = uint8(buffer[colorTableStart + i * 3 + 0]) - uint8(target >> 16);
                uint8 gg = uint8(buffer[colorTableStart + i * 3 + 1]) - uint8(target >> 8);
                uint8 bb = uint8(buffer[colorTableStart + i * 3 + 2]) - uint8(target >> 0);
                distance = rr * rr + gg * gg + bb * bb;
            }
            if (distance < bestDistance) {
                bestDistance = distance;
                bestIndex = i;
            }
        }

        return bestIndex;
    }

    function max(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 >= val2) ? val1 : val2;
    }

    function min(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 <= val2) ? val1 : val2;
    }

    function min(int32 val1, int32 val2) private pure returns (int32) {
        return (val1 <= val2) ? val1 : val2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data, uint length) internal pure returns (string memory) {
        if (data.length == 0 || length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((length + 2) / 3);

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
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIF.sol";

interface IGIFEncoder {
    function getDataUri(GIF memory gif) external pure returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFFrame.sol";

struct GIF {
    uint32 frameCount;
    GIFFrame[] frames;
    uint16 width;
    uint16 height;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

struct GIFFrame {
    uint32[] buffer;
    uint16 delay;
    uint16 width;
    uint16 height;
}