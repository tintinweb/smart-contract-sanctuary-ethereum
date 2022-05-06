// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {Integers} from "../utils/Integers.sol";
import {Bytes} from "../utils/Bytes.sol";
import {Array} from "../utils/Array.sol";
import {RendererCommons} from "./RendererCommons.sol";

error InvalidLength(uint256 length);
error CharacteristicOutOfRange(uint256 characteristic);
error TraitOutOfRange(uint256 trait);

/**  @title RectRenderer
 *
 *   This library can be used to render on-chain images stored as a layering of rectangles.
 *   The returned images is an url safe encoded image uri.
 *
 * @author Clement Walter <[email protected]>
 */
library RectRenderer {
    using Integers for uint8;
    using Integers for uint256;
    using Bytes for bytes;
    using Array for bytes[];
    using Array for string[];

    string public constant RECT_TAG_START = "%3crect%20x=%27";
    string public constant Y_TAG = "%27%20y=%27";
    string public constant WIDTH_TAG = "%27%20width=%27";
    string public constant HEIGHT_TAG = "%27%20height=%27";
    string public constant FILL_TAG = "%27%20fill=%27%23";
    string public constant RECT_TAG_END = "%27/%3e";

    /** @dev Retrieve the bytes for the given trait from the traits storage.
     *  @param pointer The pointer to the traits stored with SSTORE2.
     *  @param characteristicIndex The index of the characteristic in the collection.
     *  @param traitIndex The index of the trait in the characteristic.
     *  @return The bytes of the trait.
     */
    function getTraitBytes(
        address pointer,
        uint256 characteristicIndex,
        uint256 traitIndex
    ) public view returns (bytes memory) {
        uint16 characteristicsLength = SSTORE2.read(pointer, 0, 2).toUint16();

        if (characteristicsLength - 1 < characteristicIndex)
            revert CharacteristicOutOfRange(characteristicIndex);
        uint16 characteristicStart = SSTORE2
            .read(
                pointer,
                2 + 2 * characteristicIndex,
                2 + 2 * characteristicIndex + 2
            )
            .toUint16();
        uint16 traitsLength = SSTORE2
            .read(pointer, characteristicStart, characteristicStart + 2)
            .toUint16() - 1;
        if (traitsLength - 1 < traitIndex) revert TraitOutOfRange(traitIndex);
        bytes memory _indexes = SSTORE2.read(
            pointer,
            characteristicStart + 2 + 2 * traitIndex,
            characteristicStart + 2 + 2 * traitIndex + 4
        );
        return
            SSTORE2.read(
                pointer,
                characteristicStart + _indexes.toUint16(0),
                characteristicStart + _indexes.toUint16(2)
            );
    }

    function decodeBytes4ToRect(bytes4 rectBytes, string[] memory palette)
        public
        pure
        returns (string memory)
    {
        return decodeBytes4ToRect(rectBytes, palette, 0, 0);
    }

    function decodeBytes4ToRect(
        bytes4 rectBytes,
        string[] memory palette,
        uint256 offsetX,
        uint256 offsetY
    ) public pure returns (string memory) {
        return
            string.concat(
                RECT_TAG_START,
                (uint8(uint32(rectBytes >> 26)) + offsetX).toString(),
                Y_TAG,
                ((uint8(uint32(rectBytes >> 20)) & 0x3f) + offsetY).toString(),
                WIDTH_TAG,
                (uint8(uint32(rectBytes >> 14)) & 0x3f).toString(),
                HEIGHT_TAG,
                (uint8(uint32(rectBytes >> 8)) & 0x3f).toString(),
                FILL_TAG,
                palette[uint8(rectBytes[3])],
                RECT_TAG_END
            );
    }

    /** @dev Decode a bytes array.
     *  @param rectsBytes The bytes concatenating several rects, typically from getTraitsBytes
     *  @param palette The image palette.
     *  @return A string of all the decoded rects.
     */
    function decodeBytesMemoryToRects(
        bytes memory rectsBytes,
        string[] memory palette
    ) public pure returns (string memory) {
        if (rectsBytes.length % 4 != 0) {
            revert InvalidLength(rectsBytes.length);
        }
        uint256 nbRects = rectsBytes.length / 4;
        string[] memory rects = new string[](nbRects);
        for (uint256 i = 0; i < rects.length; i++) {
            rects[i] = decodeBytes4ToRect(
                bytes4(rectsBytes.toUint32(i * 4)),
                palette
            );
        }
        return rects.join();
    }

    /** @dev Usually, an image is made of a selection of one trait in each characteristic. This function can then be
     *  used to get the single bytes array containing all the data for a given token (set of traits).
     *  @param pointer The address of the SSTORE2 contract.
     *  @param items A list of trait indexes, should be of the same length as the number of characteristics.
     *  @return The bytes array for the whole image.
     */
    function imageBytes(address pointer, uint256[] memory items)
        public
        view
        returns (bytes memory)
    {
        bytes[] memory traits = new bytes[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            traits[i] = getTraitBytes(pointer, i, items[i]);
        }
        return traits.join();
    }

    /** @dev Get the inner part (without the header) of an image, ie the concatenated list of <rect>s.
     * @param collectionPointer The address of the SSTORE2 contract for the traits.
     * @param palettePointer The address of the SSTORE2 contract for the palette.
     * @param items A list of trait indexes, should be of the same length as the number of characteristics.
     * @return The inner part of the svg as a string.
     */
    function decodeImage(
        address collectionPointer,
        address palettePointer,
        uint256[] memory items
    ) public view returns (string memory) {
        return
            decodeBytesMemoryToRects(
                imageBytes(collectionPointer, items),
                RendererCommons.getPalette(palettePointer)
            );
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

pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < res.length; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
    }
}

// SPDX-License-Identifier: MIT

/*
 * @title Solidity Bytes Arrays Utils
 * @author Clement Walter <[email protected]> from Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library Bytes {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) public pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
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
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (address tmp)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");

        assembly {
            tmp := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint8 tmp)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x1), _start))
        }
    }

    function toBytes1(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes1 tmp)
    {
        require(_bytes.length >= _start + 1, "toBytes1_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x1), _start))
        }
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint16 tmp)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x2), _start))
        }
    }

    function toUint16(bytes memory _bytes) public pure returns (uint16 tmp) {
        return toUint16(_bytes, 0);
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint24 tmp)
    {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x3), _start))
        }
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint32 tmp)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x4), _start))
        }
    }

    function toUint40(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint40 tmp)
    {
        require(_bytes.length >= _start + 5, "toUint40_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x5), _start))
        }
    }

    function toBytes5(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes5 tmp)
    {
        require(_bytes.length >= _start + 5, "toBytes5_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x5), _start))
        }
    }

    function toUint48(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint48 tmp)
    {
        require(_bytes.length >= _start + 6, "toUint48_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x6), _start))
        }
    }

    function toBytes6(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes6 tmp)
    {
        require(_bytes.length >= _start + 6, "toBytes6_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x6), _start))
        }
    }

    function toUint56(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint56 tmp)
    {
        require(_bytes.length >= _start + 7, "toUint56_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x7), _start))
        }
    }

    function toByes7(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes7 tmp)
    {
        require(_bytes.length >= _start + 7, "toBytes7_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x7), _start))
        }
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint64 tmp)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x8), _start))
        }
    }

    function toBytes8(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint64 tmp)
    {
        require(_bytes.length >= _start + 8, "toBytes8_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x8), _start))
        }
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint96 tmp)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0xc), _start))
        }
    }

    function toBytes12(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes12 tmp)
    {
        require(_bytes.length >= _start + 12, "toBytes12_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0xc), _start))
        }
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint128 tmp)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x10), _start))
        }
    }

    function toBytes16(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes12 tmp)
    {
        require(_bytes.length >= _start + 16, "toBytes16_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x10), _start))
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (uint256 tmp)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        public
        pure
        returns (bytes32 tmp)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");

        assembly {
            tmp := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        public
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        public
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

/*
 * @title Arrays Utils
 * @author Clement Walter <[email protected]>
 *
 * @notice An attempt at implementing some of the widely used javascript's Array functions in solidity.
 */
pragma solidity ^0.8.12;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {Integers} from "../utils/Integers.sol";
import {Array} from "../utils/Array.sol";

struct Attribute {
    string trait_type;
    string value;
}

struct TokenData {
    string image;
    string description;
    string name;
    Attribute[] attributes;
}

/**  @title BaseRenderer
 *
 *   This library contains shared functionality and constants for the renderers.
 *
 * @author Clement Walter <[email protected]>
 */
library RendererCommons {
    using Integers for uint256;
    using Integers for uint8;
    using Array for string[];

    string public constant DATA_URI = "data:image/svg+xml,";
    string public constant XMLNS_HEADER =
        "xmlns=%27http://www.w3.org/2000/svg%27";
    string public constant SPACE = "%20";
    string public constant QUOTE = "%27";
    string public constant NUMBER_SIGN = "%23";
    string public constant TAG_START = "%3c";
    string public constant TAG_END = "/%3e";

    event BytesStored(address pointer);

    /**
     * @dev Usually colors are already defined in hex color space so we just concat all the colors. No check is made
     *      and this function only concatenates the input colors.
     * @param palette The list of colors as hex strings, without the leading #.
     * @return The concatenated colors as string. To be used as bytes afterwards.
     */
    function encodePalette(string[] memory palette)
        public
        pure
        returns (string memory)
    {
        return string.concat("0x", palette.join());
    }

    /** @dev Returns one single color reading directly from the storage.
     * @param pointer The pointer to the palette bytes array where each color is R, G, B at storage i, i+1, i+2.
     * @param index The index of the color to retrieve
     * @return The hexstring representation of the color, e.g. "a3120f".
     */
    function getFill(address pointer, uint256 index)
        public
        view
        returns (string memory)
    {
        bytes memory palette = SSTORE2.read(pointer, 3 * index, 3 * index + 3);

        return
            string.concat(
                uint8(palette[0]).toString(16, 2),
                uint8(palette[1]).toString(16, 2),
                uint8(palette[2]).toString(16, 2)
            );
    }

    /** @dev Returns one single color from a pre-loaded whole palette as a bytes array.
     * @param palette A bytes array encoding several RGB colors. Length should be a multiple of 3.
     * @param index The index of the color to retrieve
     * @return The hexstring representation of the color, e.g. "a3120f".
     */
    function getFill(bytes memory palette, uint256 index)
        public
        pure
        returns (string memory)
    {
        return
            string.concat(
                uint8(palette[3 * index]).toString(16, 2),
                uint8(palette[3 * index + 1]).toString(16, 2),
                uint8(palette[3 * index + 2]).toString(16, 2)
            );
    }

    /** @dev Decode the whole palette once for all and returns an array of hexstrings.
     * @param pointer The pointer to the palette bytes array where each color is at storage at i, i+1, i+2.
     * @return An array of hexstring representation of the color, e.g. "a3120f".
     */
    function getPalette(address pointer) public view returns (string[] memory) {
        bytes memory palette = SSTORE2.read(pointer);
        return getPalette(palette);
    }

    function getPalette(bytes memory palette)
        public
        pure
        returns (string[] memory)
    {
        uint256 paletteSize = palette.length / 3;
        string[] memory paletteHex = new string[](paletteSize);
        for (uint256 i = 0; i < paletteSize; i++) {
            paletteHex[i] = getFill(palette, i);
        }
        return paletteHex;
    }

    /** @dev Retrieve the names encoded with the collection: description, characteristics and traits names array.
     * @param names The bytes the names encoded by the RectEncoder.
     */
    function decodeNames(bytes memory names)
        public
        pure
        returns (
            string memory description,
            string[] memory characteristicNames,
            string[][] memory traitNames
        )
    {
        return abi.decode(names, (string, string[], string[][]));
    }

    /** @dev Retrieve the names encoded with the collection: description, characteristics and traits names array.
     * @param pointer The address of the SSTORE2 contract for the names.
     */
    function decodeNames(address pointer)
        public
        view
        returns (
            string memory description,
            string[] memory characteristicNames,
            string[][] memory traitNames
        )
    {
        return decodeNames(SSTORE2.read(pointer));
    }


    /** @dev This is just a direct call to abi.encode to insure standard encoding scheme for the names across renders.
     * @param description The description of the collection.
     * @param characteristicNames The names of the characteristics.
     * @param traitNames The names of the traits.
     * @return The encoded bytes.
     */
    function encodeNames(string memory description, string[] memory characteristicNames, string[][] memory traitNames)
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(
            description, characteristicNames, traitNames
        );
    }

    function tokenData(address pointer, uint256[] memory items)
        public
        view
        returns (TokenData memory)
    {
        (
            string memory description,
            string[] memory characteristicNames,
            string[][] memory traitNames
        ) = decodeNames(SSTORE2.read(pointer));
        Attribute[] memory attributes = new Attribute[](items.length);
        for (uint256 i = 0; i < items.length; i++) {
            attributes[i] = Attribute(
                characteristicNames[i],
                traitNames[i][items[i]]
            );
        }
        return TokenData("", description, "", attributes);
    }

    function tokenURI(address pointer, uint256[] memory items) public view returns (string memory) {
        TokenData memory _tokenData = tokenData(pointer, items);
        string[] memory attributes = new string[](_tokenData.attributes.length);
        for (uint256 i = 0; i < _tokenData.attributes.length; i++) {
            attributes[i] = string.concat(
                '{"trait_type": "',
                _tokenData.attributes[i].trait_type,
                '", "value": "',
                _tokenData.attributes[i].value,
                '"}'
            );
        }
        return
            string.concat(
                "data:application/json,",
                '{"image": "',
                _tokenData.image,
                '"',
                ',"description": "',
                _tokenData.description,
                '"',
                ',"name": "',
                _tokenData.name,
                '"',
                ',"attributes": ',
                "[",
                attributes.join(","),
                "]",
                "}"
            );
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