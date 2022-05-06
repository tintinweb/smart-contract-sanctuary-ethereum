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