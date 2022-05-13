// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {png} from '../src/png.sol';

contract pixelImage {
    
    function viewImage() public pure returns (string memory) {
        
        bytes3[] memory palette = new bytes3[](3);

        palette[0] = png.rgbToPalette(bytes1(0xcc),bytes1(0x00),bytes1(0x44));
        palette[1] = png.rgbToPalette(bytes1(0x00),bytes1(0x44),bytes1(0xcc));
        palette[2] = png.rgbToPalette(bytes1(0x00),bytes1(0xcc),bytes1(0x44));
        
        uint32 width = 64;
        uint32 height = 64;

        bytes memory picture = buildSquares(width, height);

        return png.encodedPNG(width, height, palette, picture, false);

    }

    function toIndex(uint256 _x, uint256 _y, uint256 _width) public pure returns (uint256 index){
        index = _y * (_width +1) + _x + 1;
    }

    function buildSquares(uint32 width, uint32 height) public pure returns (bytes memory) {

        bytes memory pixelArray = new bytes((width+1) * height);

        for (uint256 i = 0; i < 40; i++) {
            for (uint256 j = 0; j < 40; j++) {
                pixelArray[toIndex(i + 20, j+10, width)] = bytes1(0x01);
                pixelArray[toIndex(i + 15, j+15, width)] = bytes1(0x02);
                pixelArray[toIndex(i + 10, j+20, width)] = bytes1(0x03);
                }
        }

        return pixelArray;

    }





}

// SPDX-License-Identifier: Unlicense
/*
 * @title Onchain PNGs
 * @author Colin Platt <[email protected]>
 *
 * @dev PNG encoding tools written in Solidity for producing read-only onchain PNG files.
 */

pragma solidity =0.8.13;

library png {
    
    struct RGBA {
        bytes1 red;
        bytes1 green;
        bytes1 blue;
    }

    function rgbToPalette(bytes1 red, bytes1 green, bytes1 blue) internal pure returns (bytes3) {
        return bytes3(abi.encodePacked(red, green, blue));
    }

    function rgbToPalette(RGBA memory _rgb) internal pure returns (bytes3) {
        return bytes3(abi.encodePacked(_rgb.red, _rgb.green, _rgb.blue));
    }

    function calculateBitDepth(uint256 _length) internal pure returns (uint256) {
        if (_length < 3) {
            return 2;
        } else if(_length < 5) {
            return 4;
        } else if(_length < 17) {
            return 16;
        } else {
            return 256;
        }
    }

    function formatPalette(bytes3[] memory _palette, bool _8bit) internal pure returns (bytes memory) {
        require(_palette.length <= 256, "PNG: Palette too large.");

        uint256 depth = _8bit? uint256(256) : calculateBitDepth(_palette.length);
        bytes memory paletteObj;

        for (uint i = 0; i<_palette.length; i++) {
            paletteObj = abi.encodePacked(paletteObj, _palette[i]);
        }

        for (uint i = _palette.length; i<depth-1; i++) {
            paletteObj = abi.encodePacked(paletteObj, bytes3(0x000000));
        }

        return abi.encodePacked(
            uint32(depth*3),
            'PLTE',
            bytes3(0x000000),
            paletteObj
        );
    }

    function _tRNS(uint256 _bitDepth, uint256 _palette) internal pure returns (bytes memory) {

        bytes memory tRNSObj = abi.encodePacked(bytes1(0x00));

        for (uint i = 0; i<_palette; i++) {
            tRNSObj = abi.encodePacked(tRNSObj, bytes1(0xFF));
        }

        for (uint i = _palette; i<_bitDepth-1; i++) {
            tRNSObj = abi.encodePacked(tRNSObj, bytes1(0x00));
        }

        return abi.encodePacked(
            uint32(_bitDepth),
            'tRNS',
            tRNSObj
        );
    }

    function rawPNG(uint32 width, uint32 height, bytes3[] memory palette, bytes memory pixels, bool force8bit) internal pure returns (bytes memory) {

        // Write PLTE
        bytes memory plte = formatPalette(palette, force8bit);

        bytes4 plteCRC = _CRC(abi.encodePacked(plte),4);

        // Write tRNS
        // @TODO add tRNS
        uint256 bitDepth = force8bit ? 256 : calculateBitDepth(palette.length);

        bytes memory tRNS = png._tRNS(bitDepth, palette.length);

        bytes4 tRNSCRC = _CRC(abi.encodePacked(tRNS),4);


        // Write IHDR
        bytes21 header = bytes21(abi.encodePacked(
                uint32(13),
                'IHDR',
                width,
                height,
                bytes5(0x0803000000)
            )
        );

        bytes4 headerCRC = _CRC(abi.encodePacked(header),4);

        // we add a line filter to the pixels byte string

        bytes1 bits = pixels.length > 65535 ? bytes1(0x00) :  bytes1(0x01);

        bytes7 deflate = bytes7(
            abi.encodePacked(
                bytes2(0x78DA),
                bits,
                png.byte2lsb(uint16(pixels.length)),
                ~png.byte2lsb(uint16(pixels.length))
            )
        );

        bytes memory zlib = abi.encodePacked('IDAT', deflate, pixels, _adler32(pixels));
        
        bytes4 dataCRC = _CRC(abi.encodePacked(zlib), 0);

        return abi.encodePacked(
            bytes8(0x89504E470D0A1A0A),
            header, 
            headerCRC,
            plte, 
            plteCRC,
            tRNS, 
            tRNSCRC,
            uint32(zlib.length-4),
            zlib,
            dataCRC, 
            bytes12(0x0000000049454E44AE426082)
        );

    }

    function encodedPNG(uint32 width, uint32 height, bytes3[] memory palette, bytes memory pixels, bool force8bit) internal pure returns (string memory) {
        return string.concat('data:image/png;base64,', base64encode(rawPNG(width, height, palette, pixels, force8bit)));
    }






    // @dev Does not check out of bounds
    function coordinatesToIndex(uint256 _x, uint256 _y, uint256 _width) internal pure returns (uint256 index) {
            index = _y * (_width + 1) + _x + 1;
	}

    

    








    /////////////////////////// 
    /// Checksums

    // need to check faster ways to do this
    function calcCrcTable() internal pure returns (uint256[256] memory crcTable) {
        uint256 c;

        for(uint256 n = 0; n < 256; n++) {
            c = n;
            for (uint256 k = 0; k < 8; k++) {
                if(c & 1 == 1) {
                    c = 0xedb88320 ^ (c >>1);
                } else {
                    c = c >> 1;
                }
            }
            crcTable[n] = c;
        }
    }

    function _CRC(bytes memory chunk, uint256 offset) internal pure returns (bytes4) {

        uint256[256] memory crcTable = calcCrcTable();

        bytes1[] memory data = _toBuffer(chunk);
        uint256 len = data.length;

        uint32 c = uint32(0xffffffff);

        for(uint256 n = offset; n < len; n++) {
            c = uint32(crcTable[(c^uint8(data[n])) & 0xff] ^ (c >> 8));
        }
        return bytes4(c)^0xffffffff;

    }

    
    function _adler32(bytes memory _data) internal pure returns (bytes4) {
        uint32 a = 1;
        uint32 b = 0;

        bytes1[] memory _buffer = _toBuffer(_data);
        uint256 _len = _buffer.length;

        for (uint256 i = 0; i < _len; i++) {
            a = (a + uint8(_buffer[i])) % 65521; //may need to convert to uint32
            b = (b + a) % 65521;
        }

        return bytes4((b << 16) | a);

    }

    /////////////////////////// 
    /// Utilities

    function byte2lsb(uint16 _input) internal pure returns (bytes2) {

        return byte2lsb(bytes2(_input));

    }

    function byte2lsb(bytes2 _input) internal pure returns (bytes2) {

        return bytes2(abi.encodePacked(bytes1(_input << 8), bytes1(_input)));

    }

    function _toBuffer(bytes memory _bytes) internal pure returns (bytes1[] memory) {

        uint256 _length = _bytes.length;

        bytes1[] memory byteArray = new bytes1[](_length);
        bytes memory tempBytes;

        for (uint256 i = 0; i<_length; i++) {
            assembly {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(1, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, 1)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), i)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, 1)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }

            byteArray[i] = bytes1(tempBytes);

        }
        
        return byteArray;
    }

    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function base64encode(bytes memory data) internal pure returns (string memory) {
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