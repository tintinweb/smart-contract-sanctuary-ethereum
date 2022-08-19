/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.13;

library BClaimsParserLibraryErrorCodes {
    // BClaimsParserLibrary error codes
    bytes32 public constant BCLAIMSPARSERLIB_SIZE_THRESHOLD_EXCEEDED = "1100"; //"BClaimsParserLibrary: The size of the data section should be 1 or 2 words!"
    bytes32 public constant BCLAIMSPARSERLIB_DATA_OFFSET_OVERFLOW = "1101"; //"BClaimsParserLibrary: Invalid parsing. Overflow on the dataOffset parameter"
    bytes32 public constant BCLAIMSPARSERLIB_NOT_ENOUGH_BYTES = "1102"; //"BClaimsParserLibrary: Invalid parsing. Not enough bytes to extract BClaims"
    bytes32 public constant BCLAIMSPARSERLIB_CHAINID_ZERO = "1103"; //"BClaimsParserLibrary: Invalid parsing. The chainId should be greater than 0!"
    bytes32 public constant BCLAIMSPARSERLIB_HEIGHT_ZERO = "1104"; //"BClaimsParserLibrary: Invalid parsing. The height should be greater than 0!"
}

library BaseParserLibraryErrorCodes {
    // BaseParserLibrary error codes
    bytes32 public constant BASEPARSERLIB_OFFSET_PARAMETER_OVERFLOW = "1000"; // "BaseParserLibrary: An overflow happened with the offset parameter!"
    bytes32 public constant BASEPARSERLIB_OFFSET_OUT_OF_BOUNDS = "1001"; // "BaseParserLibrary: Trying to read an offset out of boundaries in the src binary!"
    bytes32 public constant BASEPARSERLIB_LE_UINT16_OFFSET_PARAMETER_OVERFLOW = "1002"; //  "BaseParserLibrary: Error extracting uin16! An overflow happened with the offset parameter!"
    bytes32 public constant BASEPARSERLIB_LE_UINT16_OFFSET_OUT_OF_BOUNDS = "1003"; //  "BaseParserLibrary: UINT16 ERROR! Trying to read an offset out of boundaries!"
    bytes32 public constant BASEPARSERLIB_BE_UINT16_OFFSET_PARAMETER_OVERFLOW = "1004"; // "BaseParserLibrary: UINT16 ERROR! An overflow happened with the offset parameter!"
    bytes32 public constant BASEPARSERLIB_BE_UINT16_OFFSET_OUT_OF_BOUNDS = "1005"; // "BaseParserLibrary: UINT16 ERROR! Trying to read an offset out of boundaries!"
    bytes32 public constant BASEPARSERLIB_BOOL_OFFSET_PARAMETER_OVERFLOW = "1006"; // "BaseParserLibrary: BOOL ERROR: OVERFLOW!"
    bytes32 public constant BASEPARSERLIB_BOOL_OFFSET_OUT_OF_BOUNDS = "1007"; //  "BaseParserLibrary: BOOL ERROR: OFFSET OUT OF BOUNDARIES!"
    bytes32 public constant BASEPARSERLIB_LE_UINT256_OFFSET_PARAMETER_OVERFLOW = "1008"; //  "BaseParserLibrary: Error extracting uin16! An overflow happened with the offset parameter!"
    bytes32 public constant BASEPARSERLIB_LE_UINT256_OFFSET_OUT_OF_BOUNDS = "1009"; //  "BaseParserLibrary: UINT16 ERROR! Trying to read an offset out of boundaries!"
    bytes32 public constant BASEPARSERLIB_BE_UINT256_OFFSET_PARAMETER_OVERFLOW = "1010"; // "BaseParserLibrary: UINT16 ERROR! An overflow happened with the offset parameter!"
    bytes32 public constant BASEPARSERLIB_BE_UINT256_OFFSET_OUT_OF_BOUNDS = "1011"; // "BaseParserLibrary: UINT16 ERROR! Trying to read an offset out of boundaries!"
    bytes32 public constant BASEPARSERLIB_BYTES_OFFSET_PARAMETER_OVERFLOW = "1012"; // "BaseParserLibrary: An overflow happened with the offset or the howManyBytes parameter!"
    bytes32 public constant BASEPARSERLIB_BYTES_OFFSET_OUT_OF_BOUNDS = "1013"; //   "BaseParserLibrary: Not enough bytes to extract in the src binary"
    bytes32 public constant BASEPARSERLIB_BYTES32_OFFSET_PARAMETER_OVERFLOW = "1014"; // "BaseParserLibrary: An overflow happened with the offset parameter!"
    bytes32 public constant BASEPARSERLIB_BYTES32_OFFSET_OUT_OF_BOUNDS = "1015"; //   "BaseParserLibrary: not enough bytes to extract"
}

library BaseParserLibrary {
    // Size of a word, in bytes.
    uint256 internal constant _WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint256 internal constant _BYTES_HEADER_SIZE = 32;

    /// @notice Extracts a uint32 from a little endian bytes array.
    /// @param src the binary data
    /// @param offset place inside `src` to start reading data from
    /// @return val a uint32
    /// @dev ~559 gas
    function extractUInt32(bytes memory src, uint256 offset) internal pure returns (uint32 val) {
        require(
            offset + 4 > offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length >= offset + 4,
            string(abi.encodePacked(BaseParserLibraryErrorCodes.BASEPARSERLIB_OFFSET_OUT_OF_BOUNDS))
        );

        assembly {
            val := shr(sub(256, 32), mload(add(add(src, 0x20), offset)))
            val := or(
                or(
                    or(shr(24, and(val, 0xff000000)), shr(8, and(val, 0x00ff0000))),
                    shl(8, and(val, 0x0000ff00))
                ),
                shl(24, and(val, 0x000000ff))
            )
        }
    }

    /// @notice Extracts a uint16 from a little endian bytes array.
    /// @param src the binary data
    /// @param offset place inside `src` to start reading data from
    /// @return val a uint16
    /// @dev ~204 gas
    function extractUInt16(bytes memory src, uint256 offset) internal pure returns (uint16 val) {
        require(
            offset + 2 > offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_LE_UINT16_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length >= offset + 2,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_LE_UINT16_OFFSET_OUT_OF_BOUNDS
                )
            )
        );

        assembly {
            val := shr(sub(256, 16), mload(add(add(src, 0x20), offset)))
            val := or(shr(8, and(val, 0xff00)), shl(8, and(val, 0x00ff)))
        }
    }

    /// @notice Extracts a uint16 from a big endian bytes array.
    /// @param src the binary data
    /// @param offset place inside `src` to start reading data from
    /// @return val a uint16
    /// @dev ~204 gas
    function extractUInt16FromBigEndian(bytes memory src, uint256 offset)
        internal
        pure
        returns (uint16 val)
    {
        require(
            offset + 2 > offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BE_UINT16_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length >= offset + 2,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BE_UINT16_OFFSET_OUT_OF_BOUNDS
                )
            )
        );

        assembly {
            val := and(shr(sub(256, 16), mload(add(add(src, 0x20), offset))), 0xffff)
        }
    }

    /// @notice Extracts a bool from a bytes array.
    /// @param src the binary data
    /// @param offset place inside `src` to start reading data from
    /// @return a bool
    /// @dev ~204 gas
    function extractBool(bytes memory src, uint256 offset) internal pure returns (bool) {
        require(
            offset + 1 > offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BOOL_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length >= offset + 1,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BOOL_OFFSET_OUT_OF_BOUNDS
                )
            )
        );
        uint256 val;
        assembly {
            val := shr(sub(256, 8), mload(add(add(src, 0x20), offset)))
            val := and(val, 0x01)
        }
        return val == 1;
    }

    /// @notice Extracts a uint256 from a little endian bytes array.
    /// @param src the binary data
    /// @param offset place inside `src` to start reading data from
    /// @return val a uint256
    /// @dev ~5155 gas
    function extractUInt256(bytes memory src, uint256 offset) internal pure returns (uint256 val) {
        require(
            offset + 31 > offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_LE_UINT256_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length > offset + 31,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_LE_UINT256_OFFSET_OUT_OF_BOUNDS
                )
            )
        );

        assembly {
            val := mload(add(add(src, 0x20), offset))
        }
    }

    /// @notice Extracts a uint256 from a big endian bytes array.
    /// @param src the binary data
    /// @param offset place inside `src` to start reading data from
    /// @return val a uint256
    /// @dev ~1400 gas
    function extractUInt256FromBigEndian(bytes memory src, uint256 offset)
        internal
        pure
        returns (uint256 val)
    {
        require(
            offset + 31 > offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BE_UINT256_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length > offset + 31,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BE_UINT256_OFFSET_OUT_OF_BOUNDS
                )
            )
        );

        uint256 srcDataPointer;
        uint32 val0 = 0;
        uint32 val1 = 0;
        uint32 val2 = 0;
        uint32 val3 = 0;
        uint32 val4 = 0;
        uint32 val5 = 0;
        uint32 val6 = 0;
        uint32 val7 = 0;

        assembly {
            srcDataPointer := mload(add(add(src, 0x20), offset))
            val0 := and(srcDataPointer, 0xffffffff)
            val1 := and(shr(32, srcDataPointer), 0xffffffff)
            val2 := and(shr(64, srcDataPointer), 0xffffffff)
            val3 := and(shr(96, srcDataPointer), 0xffffffff)
            val4 := and(shr(128, srcDataPointer), 0xffffffff)
            val5 := and(shr(160, srcDataPointer), 0xffffffff)
            val6 := and(shr(192, srcDataPointer), 0xffffffff)
            val7 := and(shr(224, srcDataPointer), 0xffffffff)

            val0 := or(
                or(
                    or(shr(24, and(val0, 0xff000000)), shr(8, and(val0, 0x00ff0000))),
                    shl(8, and(val0, 0x0000ff00))
                ),
                shl(24, and(val0, 0x000000ff))
            )
            val1 := or(
                or(
                    or(shr(24, and(val1, 0xff000000)), shr(8, and(val1, 0x00ff0000))),
                    shl(8, and(val1, 0x0000ff00))
                ),
                shl(24, and(val1, 0x000000ff))
            )
            val2 := or(
                or(
                    or(shr(24, and(val2, 0xff000000)), shr(8, and(val2, 0x00ff0000))),
                    shl(8, and(val2, 0x0000ff00))
                ),
                shl(24, and(val2, 0x000000ff))
            )
            val3 := or(
                or(
                    or(shr(24, and(val3, 0xff000000)), shr(8, and(val3, 0x00ff0000))),
                    shl(8, and(val3, 0x0000ff00))
                ),
                shl(24, and(val3, 0x000000ff))
            )
            val4 := or(
                or(
                    or(shr(24, and(val4, 0xff000000)), shr(8, and(val4, 0x00ff0000))),
                    shl(8, and(val4, 0x0000ff00))
                ),
                shl(24, and(val4, 0x000000ff))
            )
            val5 := or(
                or(
                    or(shr(24, and(val5, 0xff000000)), shr(8, and(val5, 0x00ff0000))),
                    shl(8, and(val5, 0x0000ff00))
                ),
                shl(24, and(val5, 0x000000ff))
            )
            val6 := or(
                or(
                    or(shr(24, and(val6, 0xff000000)), shr(8, and(val6, 0x00ff0000))),
                    shl(8, and(val6, 0x0000ff00))
                ),
                shl(24, and(val6, 0x000000ff))
            )
            val7 := or(
                or(
                    or(shr(24, and(val7, 0xff000000)), shr(8, and(val7, 0x00ff0000))),
                    shl(8, and(val7, 0x0000ff00))
                ),
                shl(24, and(val7, 0x000000ff))
            )

            val := or(
                or(
                    or(
                        or(
                            or(
                                or(or(shl(224, val0), shl(192, val1)), shl(160, val2)),
                                shl(128, val3)
                            ),
                            shl(96, val4)
                        ),
                        shl(64, val5)
                    ),
                    shl(32, val6)
                ),
                val7
            )
        }
    }

    /// @notice Reverts a bytes array. Can be used to convert an array from little endian to big endian and vice-versa.
    /// @param orig the binary data
    /// @return reversed the reverted bytes array
    /// @dev ~13832 gas
    function reverse(bytes memory orig) internal pure returns (bytes memory reversed) {
        reversed = new bytes(orig.length);
        for (uint256 idx = 0; idx < orig.length; idx++) {
            reversed[orig.length - idx - 1] = orig[idx];
        }
    }

    /// @notice Copy 'len' bytes from memory address 'src', to address 'dest'. This function does not check the or destination, it only copies the bytes.
    /// @param src the pointer to the source
    /// @param dest the pointer to the destination
    /// @param len the len of data to be copied
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= _WORD_SIZE; len -= _WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += _WORD_SIZE;
            src += _WORD_SIZE;
        }
        // Returning earlier if there's no leftover bytes to copy
        if (len == 0) {
            return;
        }
        // Copy remaining bytes
        uint256 mask = 256**(_WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /// @notice Returns a memory pointer to the data portion of the provided bytes array.
    /// @param bts the bytes array to get a pointer from
    /// @return addr the pointer to the `bts` bytes array
    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly {
            addr := add(bts, _BYTES_HEADER_SIZE)
        }
    }

    /// @notice Extracts a bytes array with length `howManyBytes` from `src`'s `offset` forward.
    /// @param src the bytes array to extract from
    /// @param offset where to start extracting from
    /// @param howManyBytes how many bytes we want to extract from `src`
    /// @return out the extracted bytes array
    /// @dev Extracting the 32-64th bytes out of a 64 bytes array takes ~7828 gas.
    function extractBytes(
        bytes memory src,
        uint256 offset,
        uint256 howManyBytes
    ) internal pure returns (bytes memory out) {
        require(
            offset + howManyBytes >= offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BYTES_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length >= offset + howManyBytes,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BYTES_OFFSET_OUT_OF_BOUNDS
                )
            )
        );
        out = new bytes(howManyBytes);
        uint256 start;

        assembly {
            start := add(add(src, offset), _BYTES_HEADER_SIZE)
        }

        copy(start, dataPtr(out), howManyBytes);
    }

    /// @notice Extracts a bytes32 extracted from `src`'s `offset` forward.
    /// @param src the source bytes array to extract from
    /// @param offset where to start extracting from
    /// @return out the bytes32 data extracted from `src`
    /// @dev ~439 gas
    function extractBytes32(bytes memory src, uint256 offset) internal pure returns (bytes32 out) {
        require(
            offset + 32 > offset,
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BYTES32_OFFSET_PARAMETER_OVERFLOW
                )
            )
        );
        require(
            src.length >= (offset + 32),
            string(
                abi.encodePacked(
                    BaseParserLibraryErrorCodes.BASEPARSERLIB_BYTES32_OFFSET_OUT_OF_BOUNDS
                )
            )
        );
        assembly {
            out := mload(add(add(src, _BYTES_HEADER_SIZE), offset))
        }
    }
}

/// @title Library to parse the BClaims structure from a blob of capnproto data
library BClaimsParserLibrary {
    struct BClaims {
        uint32 chainId;
        uint32 height;
        uint32 txCount;
        bytes32 prevBlock;
        bytes32 txRoot;
        bytes32 stateRoot;
        bytes32 headerRoot;
    }

    /** @dev size in bytes of a BCLAIMS cap'npro structure without the cap'n
      proto header bytes*/
    uint256 internal constant _BCLAIMS_SIZE = 176;
    /** @dev Number of bytes of a capnproto header, the data starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;

    /**
    @notice This function computes the offset adjustment in the pointer section
    of the capnproto blob of data. In case the txCount is 0, the value is not
    included in the binary blob by capnproto. Therefore, we need to deduce 8
    bytes from the pointer's offset.
    */
    /// @param src Binary data containing a BClaims serialized struct
    /// @param dataOffset Blob of binary data with a capnproto serialization
    /// @return pointerOffsetAdjustment the pointer offset adjustment in the blob data
    /// @dev Execution cost: 499 gas
    function getPointerOffsetAdjustment(bytes memory src, uint256 dataOffset)
        internal
        pure
        returns (uint16 pointerOffsetAdjustment)
    {
        // Size in capnproto words (16 bytes) of the data section
        uint16 dataSectionSize = BaseParserLibrary.extractUInt16(src, dataOffset);
        require(
            dataSectionSize > 0 && dataSectionSize <= 2,
            string(
                abi.encodePacked(
                    BClaimsParserLibraryErrorCodes.BCLAIMSPARSERLIB_SIZE_THRESHOLD_EXCEEDED
                )
            )
        );
        // In case the txCount is 0, the value is not included in the binary
        // blob by capnproto. Therefore, we need to deduce 8 bytes from the
        // pointer's offset.
        if (dataSectionSize == 1) {
            pointerOffsetAdjustment = 8;
        } else {
            pointerOffsetAdjustment = 0;
        }
    }

    /**
    @notice This function is for deserializing data directly from capnproto
            BClaims. It will skip the first 8 bytes (capnproto headers) and
            deserialize the BClaims Data. This function also computes the right
            PointerOffset adjustment (see the documentation on
            `getPointerOffsetAdjustment(bytes, uint256)` for more details). If
            BClaims is being extracted from inside of other structure (E.g
            PClaims capnproto) use the `extractInnerBClaims(bytes, uint,
            uint16)` instead.
    */
    /// @param src Binary data containing a BClaims serialized struct with Capn Proto headers
    /// @return bClaims the BClaims struct
    /// @dev Execution cost: 2484 gas
    function extractBClaims(bytes memory src) internal pure returns (BClaims memory bClaims) {
        return extractInnerBClaims(src, _CAPNPROTO_HEADER_SIZE, getPointerOffsetAdjustment(src, 4));
    }

    /**
    @notice This function is for deserializing the BClaims struct from an defined
            location inside a binary blob. E.G Extract BClaims from inside of
            other structure (E.g PClaims capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary data containing a BClaims serialized struct without Capn proto headers
    /// @param dataOffset offset to start reading the BClaims data from inside src
    /// @param pointerOffsetAdjustment Pointer's offset that will be deduced from the pointers location, in case txCount is missing in the binary
    /// @return bClaims the BClaims struct
    /// @dev Execution cost: 2126 gas
    function extractInnerBClaims(
        bytes memory src,
        uint256 dataOffset,
        uint16 pointerOffsetAdjustment
    ) internal pure returns (BClaims memory bClaims) {
        require(
            dataOffset + _BCLAIMS_SIZE - pointerOffsetAdjustment > dataOffset,
            string(
                abi.encodePacked(
                    BClaimsParserLibraryErrorCodes.BCLAIMSPARSERLIB_DATA_OFFSET_OVERFLOW
                )
            )
        );
        require(
            src.length >= dataOffset + _BCLAIMS_SIZE - pointerOffsetAdjustment,
            string(
                abi.encodePacked(BClaimsParserLibraryErrorCodes.BCLAIMSPARSERLIB_NOT_ENOUGH_BYTES)
            )
        );

        if (pointerOffsetAdjustment == 0) {
            bClaims.txCount = BaseParserLibrary.extractUInt32(src, dataOffset + 8);
        } else {
            // In case the txCount is 0, the value is not included in the binary
            // blob by capnproto.
            bClaims.txCount = 0;
        }

        bClaims.chainId = BaseParserLibrary.extractUInt32(src, dataOffset);
        require(
            bClaims.chainId > 0,
            string(abi.encodePacked(BClaimsParserLibraryErrorCodes.BCLAIMSPARSERLIB_CHAINID_ZERO))
        );
        bClaims.height = BaseParserLibrary.extractUInt32(src, dataOffset + 4);
        require(
            bClaims.height > 0,
            string(abi.encodePacked(BClaimsParserLibraryErrorCodes.BCLAIMSPARSERLIB_HEIGHT_ZERO))
        );
        bClaims.prevBlock = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 48 - pointerOffsetAdjustment
        );
        bClaims.txRoot = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 80 - pointerOffsetAdjustment
        );
        bClaims.stateRoot = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 112 - pointerOffsetAdjustment
        );
        bClaims.headerRoot = BaseParserLibrary.extractBytes32(
            src,
            dataOffset + 144 - pointerOffsetAdjustment
        );
    }
}


struct Snapshot {
    uint256 committedAt;
    BClaimsParserLibrary.BClaims blockClaims;
}

interface ISnapshots {
    event SnapshotTaken(
        uint256 chainId,
        uint256 indexed epoch,
        uint256 height,
        address indexed validator,
        bool isSafeToProceedConsensus,
        bytes signatureRaw
    );

    function setSnapshotDesperationDelay(uint32 desperationDelay_) external;

    function setSnapshotDesperationFactor(uint32 desperationFactor_) external;

    function setMinimumIntervalBetweenSnapshots(uint32 minimumIntervalBetweenSnapshots_) external;

    function snapshot(bytes calldata signatureGroup_, bytes calldata bClaims_)
        external
        returns (bool);

    function migrateSnapshots(bytes[] memory groupSignature_, bytes[] memory bClaims_)
        external
        returns (bool);

    function getSnapshotDesperationDelay() external view returns (uint256);

    function getSnapshotDesperationFactor() external view returns (uint256);

    function getMinimumIntervalBetweenSnapshots() external view returns (uint256);

    function getChainId() external view returns (uint256);

    function getEpoch() external view returns (uint256);

    function getEpochLength() external view returns (uint256);

    function getChainIdFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getChainIdFromLatestSnapshot() external view returns (uint256);

    function getBlockClaimsFromSnapshot(uint256 epoch_)
        external
        view
        returns (BClaimsParserLibrary.BClaims memory);

    function getBlockClaimsFromLatestSnapshot()
        external
        view
        returns (BClaimsParserLibrary.BClaims memory);

    function getCommittedHeightFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getCommittedHeightFromLatestSnapshot() external view returns (uint256);

    function getAliceNetHeightFromSnapshot(uint256 epoch_) external view returns (uint256);

    function getAliceNetHeightFromLatestSnapshot() external view returns (uint256);

    function getSnapshot(uint256 epoch_) external view returns (Snapshot memory);

    function getLatestSnapshot() external view returns (Snapshot memory);

    function getEpochFromHeight(uint256 height) external view returns (uint256);

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 blsig,
        uint256 desperationFactor
    ) external pure returns (bool);
}



library CustomEnumerableMapsErrorCodes {
    // CustomEnumerableMaps error codes
    bytes32 public constant CUSTOMENUMMAP_KEY_NOT_IN_MAP = "1900"; //"Error: Key not in the map!"
}


struct ValidatorData {
    address _address;
    uint256 _tokenID;
}

struct ExitingValidatorData {
    uint128 _tokenID;
    uint128 _freeAfter;
}

struct ValidatorDataMap {
    ValidatorData[] _values;
    mapping(address => uint256) _indexes;
}

library CustomEnumerableMaps {
    /**
     * @dev Add a value to a map. O(1).
     *
     * Returns true if the value was added to the map, that is if it was not
     * already present.
     */
    function add(ValidatorDataMap storage map, ValidatorData memory value) internal returns (bool) {
        if (!contains(map, value._address)) {
            map._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[value._address] = map._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a map using its address. O(1).
     *
     * Returns true if the value was removed from the map, that is if it was
     * present.
     */
    function remove(ValidatorDataMap storage map, address key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = map._indexes[key];

        if (valueIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = map._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                ValidatorData memory lastValue = map._values[lastIndex];

                // Move the last value to the index where the value to delete is
                map._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                map._indexes[lastValue._address] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved key was stored
            map._values.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(ValidatorDataMap storage map, address key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of values in the map. O(1).
     */
    function length(ValidatorDataMap storage map) internal view returns (uint256) {
        return map._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(ValidatorDataMap storage map, uint256 index)
        internal
        view
        returns (ValidatorData memory)
    {
        return map._values[index];
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     */
    function tryGet(ValidatorDataMap storage map, address key)
        internal
        view
        returns (bool, ValidatorData memory)
    {
        uint256 index = map._indexes[key];
        if (index == 0) {
            return (false, ValidatorData(address(0), 0));
        } else {
            return (true, map._values[index - 1]);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(ValidatorDataMap storage map, address key)
        internal
        view
        returns (ValidatorData memory)
    {
        (bool success, ValidatorData memory value) = tryGet(map, key);
        require(
            success,
            string(abi.encodePacked(CustomEnumerableMapsErrorCodes.CUSTOMENUMMAP_KEY_NOT_IN_MAP))
        );
        return value;
    }

    /**
     * @dev Return the entire map in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(ValidatorDataMap storage map) internal view returns (ValidatorData[] memory) {
        return map._values;
    }

    /**
     * @dev Return the address of every entry in the entire map in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function addressValues(ValidatorDataMap storage map) internal view returns (address[] memory) {
        ValidatorData[] memory _values = values(map);
        address[] memory addresses = new address[](_values.length);
        for (uint256 i = 0; i < _values.length; i++) {
            addresses[i] = _values[i]._address;
        }
        return addresses;
    }
}


interface IValidatorPool {
    event ValidatorJoined(address indexed account, uint256 validatorStakingTokenID);
    event ValidatorLeft(address indexed account, uint256 publicStakingTokenID);
    event ValidatorMinorSlashed(address indexed account, uint256 publicStakingTokenID);
    event ValidatorMajorSlashed(address indexed account);
    event MaintenanceScheduled();

    function setStakeAmount(uint256 stakeAmount_) external;

    function setMaxNumValidators(uint256 maxNumValidators_) external;

    function setDisputerReward(uint256 disputerReward_) external;

    function setLocation(string calldata ip) external;

    function scheduleMaintenance() external;

    function initializeETHDKG() external;

    function completeETHDKG() external;

    function pauseConsensus() external;

    function pauseConsensusOnArbitraryHeight(uint256 aliceNetHeight) external;

    function registerValidators(
        address[] calldata validators,
        uint256[] calldata publicStakingTokenIDs
    ) external;

    function unregisterValidators(address[] calldata validators) external;

    function unregisterAllValidators() external;

    function collectProfits() external returns (uint256 payoutEth, uint256 payoutToken);

    function claimExitingNFTPosition() external returns (uint256);

    function majorSlash(address dishonestValidator_, address disputer_) external;

    function minorSlash(address dishonestValidator_, address disputer_) external;

    function getValidatorsCount() external view returns (uint256);

    function getValidatorsAddresses() external view returns (address[] memory);

    function getValidator(uint256 index) external view returns (address);

    function getValidatorData(uint256 index) external view returns (ValidatorData memory);

    function getLocation(address validator) external view returns (string memory);

    function getLocations(address[] calldata validators_) external view returns (string[] memory);

    function getStakeAmount() external view returns (uint256);

    function getMaxNumValidators() external view returns (uint256);

    function getDisputerReward() external view returns (uint256);

    function tryGetTokenID(address account_)
        external
        view
        returns (
            bool,
            address,
            uint256
        );

    function isValidator(address participant) external view returns (bool);

    function isInExitingQueue(address participant) external view returns (bool);

    function isAccusable(address participant) external view returns (bool);

    function isMaintenanceScheduled() external view returns (bool);

    function isConsensusRunning() external view returns (bool);
}



abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(bytes32 _salt, address _factory)
        public
        pure
        returns (address)
    {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}



library ImmutableAuthErrorCodes {
    // ImmutableAuth error codes
    bytes32 public constant IMMUTEABLEAUTH_ONLY_FACTORY = "2000"; //"onlyFactory"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_ATOKEN = "2001"; //"onlyAToken"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_FOUNDATION = "2002"; //"onlyFoundation"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_GOVERNANCE = "2003"; // "onlyGovernance"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_LIQUIDITYPROVIDERSTAKING = "2004"; // "onlyLiquidityProviderStaking"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_BTOKEN = "2005"; // "onlyBToken"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_MADTOKEN = "2006"; // "onlyMadToken"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_PUBLICSTAKING = "2007"; // "onlyPublicStaking"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_SNAPSHOTS = "2008"; // "onlySnapshots"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_STAKINGPOSITIONDESCRIPTOR = "2009"; // "onlyStakingPositionDescriptor"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_VALIDATORPOOL = "2010"; // "onlyValidatorPool"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_VALIDATORSTAKING = "2011"; // "onlyValidatorStaking"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_ATOKENBURNER = "2012"; // "onlyATokenBurner"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_ATOKENMINTER = "2013"; // "onlyATokenMinter"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_ETHDKGACCUSATIONS = "2014"; // "onlyETHDKGAccusations"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_ETHDKGPHASES = "2015"; // "onlyETHDKGPhases"
    bytes32 public constant IMMUTEABLEAUTH_ONLY_ETHDKG = "2016"; // "onlyETHDKG"
}




abstract contract ImmutableFactory is DeterministicAddress {
    address private immutable _factory;

    modifier onlyFactory() {
        require(
            msg.sender == _factory,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_FACTORY))
        );
        _;
    }

    constructor(address factory_) {
        _factory = factory_;
    }

    function _factoryAddress() internal view returns (address) {
        return _factory;
    }
}

abstract contract ImmutableAToken is ImmutableFactory {
    address private immutable _aToken;

    modifier onlyAToken() {
        require(
            msg.sender == _aToken,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_ATOKEN))
        );
        _;
    }

    constructor() {
        _aToken = getMetamorphicContractAddress(
            0x41546f6b656e0000000000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _aTokenAddress() internal view returns (address) {
        return _aToken;
    }

    function _saltForAToken() internal pure returns (bytes32) {
        return 0x41546f6b656e0000000000000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableATokenBurner is ImmutableFactory {
    address private immutable _aTokenBurner;

    modifier onlyATokenBurner() {
        require(
            msg.sender == _aTokenBurner,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_ATOKENBURNER))
        );
        _;
    }

    constructor() {
        _aTokenBurner = getMetamorphicContractAddress(
            0x41546f6b656e4275726e65720000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _aTokenBurnerAddress() internal view returns (address) {
        return _aTokenBurner;
    }

    function _saltForATokenBurner() internal pure returns (bytes32) {
        return 0x41546f6b656e4275726e65720000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableATokenMinter is ImmutableFactory {
    address private immutable _aTokenMinter;

    modifier onlyATokenMinter() {
        require(
            msg.sender == _aTokenMinter,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_ATOKENMINTER))
        );
        _;
    }

    constructor() {
        _aTokenMinter = getMetamorphicContractAddress(
            0x41546f6b656e4d696e7465720000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _aTokenMinterAddress() internal view returns (address) {
        return _aTokenMinter;
    }

    function _saltForATokenMinter() internal pure returns (bytes32) {
        return 0x41546f6b656e4d696e7465720000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableBToken is ImmutableFactory {
    address private immutable _bToken;

    modifier onlyBToken() {
        require(
            msg.sender == _bToken,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_BTOKEN))
        );
        _;
    }

    constructor() {
        _bToken = getMetamorphicContractAddress(
            0x42546f6b656e0000000000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _bTokenAddress() internal view returns (address) {
        return _bToken;
    }

    function _saltForBToken() internal pure returns (bytes32) {
        return 0x42546f6b656e0000000000000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableFoundation is ImmutableFactory {
    address private immutable _foundation;

    modifier onlyFoundation() {
        require(
            msg.sender == _foundation,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_FOUNDATION))
        );
        _;
    }

    constructor() {
        _foundation = getMetamorphicContractAddress(
            0x466f756e646174696f6e00000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _foundationAddress() internal view returns (address) {
        return _foundation;
    }

    function _saltForFoundation() internal pure returns (bytes32) {
        return 0x466f756e646174696f6e00000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableGovernance is ImmutableFactory {
    address private immutable _governance;

    modifier onlyGovernance() {
        require(
            msg.sender == _governance,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_GOVERNANCE))
        );
        _;
    }

    constructor() {
        _governance = getMetamorphicContractAddress(
            0x476f7665726e616e636500000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _governanceAddress() internal view returns (address) {
        return _governance;
    }

    function _saltForGovernance() internal pure returns (bytes32) {
        return 0x476f7665726e616e636500000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableLiquidityProviderStaking is ImmutableFactory {
    address private immutable _liquidityProviderStaking;

    modifier onlyLiquidityProviderStaking() {
        require(
            msg.sender == _liquidityProviderStaking,
            string(
                abi.encodePacked(
                    ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_LIQUIDITYPROVIDERSTAKING
                )
            )
        );
        _;
    }

    constructor() {
        _liquidityProviderStaking = getMetamorphicContractAddress(
            0x4c697175696469747950726f76696465725374616b696e670000000000000000,
            _factoryAddress()
        );
    }

    function _liquidityProviderStakingAddress() internal view returns (address) {
        return _liquidityProviderStaking;
    }

    function _saltForLiquidityProviderStaking() internal pure returns (bytes32) {
        return 0x4c697175696469747950726f76696465725374616b696e670000000000000000;
    }
}

abstract contract ImmutablePublicStaking is ImmutableFactory {
    address private immutable _publicStaking;

    modifier onlyPublicStaking() {
        require(
            msg.sender == _publicStaking,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_PUBLICSTAKING))
        );
        _;
    }

    constructor() {
        _publicStaking = getMetamorphicContractAddress(
            0x5075626c69635374616b696e6700000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _publicStakingAddress() internal view returns (address) {
        return _publicStaking;
    }

    function _saltForPublicStaking() internal pure returns (bytes32) {
        return 0x5075626c69635374616b696e6700000000000000000000000000000000000000;
    }
}

abstract contract ImmutableSnapshots is ImmutableFactory {
    address private immutable _snapshots;

    modifier onlySnapshots() {
        require(
            msg.sender == _snapshots,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_SNAPSHOTS))
        );
        _;
    }

    constructor() {
        _snapshots = getMetamorphicContractAddress(
            0x536e617073686f74730000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _snapshotsAddress() internal view returns (address) {
        return _snapshots;
    }

    function _saltForSnapshots() internal pure returns (bytes32) {
        return 0x536e617073686f74730000000000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableStakingPositionDescriptor is ImmutableFactory {
    address private immutable _stakingPositionDescriptor;

    modifier onlyStakingPositionDescriptor() {
        require(
            msg.sender == _stakingPositionDescriptor,
            string(
                abi.encodePacked(
                    ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_STAKINGPOSITIONDESCRIPTOR
                )
            )
        );
        _;
    }

    constructor() {
        _stakingPositionDescriptor = getMetamorphicContractAddress(
            0x5374616b696e67506f736974696f6e44657363726970746f7200000000000000,
            _factoryAddress()
        );
    }

    function _stakingPositionDescriptorAddress() internal view returns (address) {
        return _stakingPositionDescriptor;
    }

    function _saltForStakingPositionDescriptor() internal pure returns (bytes32) {
        return 0x5374616b696e67506f736974696f6e44657363726970746f7200000000000000;
    }
}

abstract contract ImmutableValidatorPool is ImmutableFactory {
    address private immutable _validatorPool;

    modifier onlyValidatorPool() {
        require(
            msg.sender == _validatorPool,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_VALIDATORPOOL))
        );
        _;
    }

    constructor() {
        _validatorPool = getMetamorphicContractAddress(
            0x56616c696461746f72506f6f6c00000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _validatorPoolAddress() internal view returns (address) {
        return _validatorPool;
    }

    function _saltForValidatorPool() internal pure returns (bytes32) {
        return 0x56616c696461746f72506f6f6c00000000000000000000000000000000000000;
    }
}

abstract contract ImmutableValidatorStaking is ImmutableFactory {
    address private immutable _validatorStaking;

    modifier onlyValidatorStaking() {
        require(
            msg.sender == _validatorStaking,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_VALIDATORSTAKING))
        );
        _;
    }

    constructor() {
        _validatorStaking = getMetamorphicContractAddress(
            0x56616c696461746f725374616b696e6700000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _validatorStakingAddress() internal view returns (address) {
        return _validatorStaking;
    }

    function _saltForValidatorStaking() internal pure returns (bytes32) {
        return 0x56616c696461746f725374616b696e6700000000000000000000000000000000;
    }
}

abstract contract ImmutableETHDKGAccusations is ImmutableFactory {
    address private immutable _ethdkgAccusations;

    modifier onlyETHDKGAccusations() {
        require(
            msg.sender == _ethdkgAccusations,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_ETHDKGACCUSATIONS))
        );
        _;
    }

    constructor() {
        _ethdkgAccusations = getMetamorphicContractAddress(
            0x455448444b4741636375736174696f6e73000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgAccusationsAddress() internal view returns (address) {
        return _ethdkgAccusations;
    }

    function _saltForETHDKGAccusations() internal pure returns (bytes32) {
        return 0x455448444b4741636375736174696f6e73000000000000000000000000000000;
    }
}

abstract contract ImmutableETHDKGPhases is ImmutableFactory {
    address private immutable _ethdkgPhases;

    modifier onlyETHDKGPhases() {
        require(
            msg.sender == _ethdkgPhases,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_ETHDKGPHASES))
        );
        _;
    }

    constructor() {
        _ethdkgPhases = getMetamorphicContractAddress(
            0x455448444b475068617365730000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgPhasesAddress() internal view returns (address) {
        return _ethdkgPhases;
    }

    function _saltForETHDKGPhases() internal pure returns (bytes32) {
        return 0x455448444b475068617365730000000000000000000000000000000000000000;
    }
}

abstract contract ImmutableETHDKG is ImmutableFactory {
    address private immutable _ethdkg;

    modifier onlyETHDKG() {
        require(
            msg.sender == _ethdkg,
            string(abi.encodePacked(ImmutableAuthErrorCodes.IMMUTEABLEAUTH_ONLY_ETHDKG))
        );
        _;
    }

    constructor() {
        _ethdkg = getMetamorphicContractAddress(
            0x455448444b470000000000000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _ethdkgAddress() internal view returns (address) {
        return _ethdkg;
    }

    function _saltForETHDKG() internal pure returns (bytes32) {
        return 0x455448444b470000000000000000000000000000000000000000000000000000;
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}





enum Phase {
    RegistrationOpen,
    ShareDistribution,
    DisputeShareDistribution,
    KeyShareSubmission,
    MPKSubmission,
    GPKJSubmission,
    DisputeGPKJSubmission,
    Completion
}

// State of key generation
struct Participant {
    uint256[2] publicKey;
    uint64 nonce;
    uint64 index;
    Phase phase;
    bytes32 distributedSharesHash;
    uint256[2] commitmentsFirstCoefficient;
    uint256[2] keyShares;
    uint256[4] gpkj;
}

abstract contract ETHDKGStorage is
    Initializable,
    ImmutableFactory,
    ImmutableSnapshots,
    ImmutableValidatorPool
{
    // ISnapshots internal immutable _snapshots;
    // IValidatorPool internal immutable _validatorPool;
    //address internal immutable _factory;
    uint256 internal constant _MIN_VALIDATORS = 4;

    uint64 internal _nonce;
    uint64 internal _phaseStartBlock;
    Phase internal _ethdkgPhase;
    uint32 internal _numParticipants;
    uint16 internal _badParticipants;
    uint16 internal _phaseLength;
    uint16 internal _confirmationLength;

    // AliceNet height used to start the new validator set in arbitrary height points if the AliceNet
    // Consensus is halted
    uint256 internal _customAliceNetHeight;

    address internal _admin;

    uint256[4] internal _masterPublicKey;
    uint256[2] internal _mpkG1;
    bytes32 internal _masterPublicKeyHash;

    mapping(address => Participant) internal _participants;

    constructor() ImmutableFactory(msg.sender) ImmutableSnapshots() ImmutableValidatorPool() {}
}



interface IETHDKG {
    function setPhaseLength(uint16 phaseLength_) external;

    function setConfirmationLength(uint16 confirmationLength_) external;

    function setCustomAliceNetHeight(uint256 aliceNetHeight) external;

    function initializeETHDKG() external;

    function register(uint256[2] memory publicKey) external;

    function distributeShares(uint256[] memory encryptedShares, uint256[2][] memory commitments)
        external;

    function submitKeyShare(
        uint256[2] memory keyShareG1,
        uint256[2] memory keyShareG1CorrectnessProof,
        uint256[4] memory keyShareG2
    ) external;

    function submitMasterPublicKey(uint256[4] memory masterPublicKey_) external;

    function submitGPKJ(uint256[4] memory gpkj) external;

    function complete() external;

    function migrateValidators(
        address[] memory validatorsAccounts_,
        uint256[] memory validatorIndexes_,
        uint256[4][] memory validatorShares_,
        uint8 validatorCount_,
        uint256 epoch_,
        uint256 sideChainHeight_,
        uint256 ethHeight_,
        uint256[4] memory masterPublicKey_
    ) external;

    function accuseParticipantNotRegistered(address[] memory dishonestAddresses) external;

    function accuseParticipantDidNotDistributeShares(address[] memory dishonestAddresses) external;

    function accuseParticipantDistributedBadShares(
        address dishonestAddress,
        uint256[] memory encryptedShares,
        uint256[2][] memory commitments,
        uint256[2] memory sharedKey,
        uint256[2] memory sharedKeyCorrectnessProof
    ) external;

    function accuseParticipantDidNotSubmitKeyShares(address[] memory dishonestAddresses) external;

    function accuseParticipantDidNotSubmitGPKJ(address[] memory dishonestAddresses) external;

    function accuseParticipantSubmittedBadGPKJ(
        address[] memory validators,
        bytes32[] memory encryptedSharesHash,
        uint256[2][][] memory commitments,
        address dishonestAddress
    ) external;

    function isETHDKGRunning() external view returns (bool);

    function isMasterPublicKeySet() external view returns (bool);

    function getNonce() external view returns (uint256);

    function getPhaseStartBlock() external view returns (uint256);

    function getPhaseLength() external view returns (uint256);

    function getConfirmationLength() external view returns (uint256);

    function getETHDKGPhase() external view returns (Phase);

    function getNumParticipants() external view returns (uint256);

    function getBadParticipants() external view returns (uint256);

    function getMinValidators() external view returns (uint256);

    function getParticipantInternalState(address participant)
        external
        view
        returns (Participant memory);

    function getMasterPublicKey() external view returns (uint256[4] memory);

    function getMasterPublicKeyHash() external view returns (bytes32);

    function tryGetParticipantIndex(address participant) external view returns (bool, uint256);
}



library RCertParserLibraryErrorCodes {
    // RCertParserLibrary error codes
    bytes32 public constant RCERTPARSERLIB_DATA_OFFSET_OVERFLOW = "1400"; //"RClaimsParserLibrary: Overflow on the dataOffset parameter"
    bytes32 public constant RCERTPARSERLIB_INSUFFICIENT_BYTES = "1401"; // "RCertParserLibrary: Not enough bytes to extract"
    bytes32 public constant RCERTPARSERLIB_INSUFFICIENT_BYTES_TO_EXTRACT = "1402"; // "RCertParserLibrary: Not enough bytes to extract RCert"
}



library RClaimsParserLibraryErrorCodes {
    // RClaimsParserLibrary error codes
    bytes32 public constant RCLAIMSPARSERLIB_DATA_OFFSET_OVERFLOW = "1500"; //"RClaimsParserLibrary: Overflow on the dataOffset parameter"
    bytes32 public constant RCLAIMSPARSERLIB_INSUFFICIENT_BYTES = "1501"; // "RClaimsParserLibrary: Not enough bytes to extract RClaims"
    bytes32 public constant RCLAIMSPARSERLIB_CHAINID_ZERO = "1502"; // "RClaimsParserLibrary: Invalid parsing. The chainId should be greater than 0!"
    bytes32 public constant RCLAIMSPARSERLIB_HEIGHT_ZERO = "1503"; // "RClaimsParserLibrary: Invalid parsing. The height should be greater than 0!"
    bytes32 public constant RCLAIMSPARSERLIB_ROUND_ZERO = "1504"; // "RClaimsParserLibrary: Invalid parsing. The round should be greater than 0!"
}



/// @title Library to parse the RClaims structure from a blob of capnproto data
library RClaimsParserLibrary {
    struct RClaims {
        uint32 chainId;
        uint32 height;
        uint32 round;
        bytes32 prevBlock;
    }

    /** @dev size in bytes of a RCLAIMS cap'npro structure without the cap'n
      proto header bytes*/
    uint256 internal constant _RCLAIMS_SIZE = 56;
    /** @dev Number of bytes of a capnproto header, the data starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;

    /**
    @notice This function is for deserializing data directly from capnproto
            RClaims. It will skip the first 8 bytes (capnproto headers) and
            deserialize the RClaims Data. If RClaims is being extracted from
            inside of other structure (E.g RCert capnproto) use the
            `extractInnerRClaims(bytes, uint)` instead.
    */
    /// @param src Binary data containing a RClaims serialized struct with Capn Proto headers
    /// @dev Execution cost: 1506 gas
    function extractRClaims(bytes memory src) internal pure returns (RClaims memory rClaims) {
        return extractInnerRClaims(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for serializing the RClaims struct from an defined
            location inside a binary blob. E.G Extract RClaims from inside of
            other structure (E.g RCert capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary data containing a RClaims serialized struct without Capn Proto headers
    /// @param dataOffset offset to start reading the RClaims data from inside src
    /// @dev Execution cost: 1332 gas
    function extractInnerRClaims(bytes memory src, uint256 dataOffset)
        internal
        pure
        returns (RClaims memory rClaims)
    {
        require(
            dataOffset + _RCLAIMS_SIZE > dataOffset,
            string(
                abi.encodePacked(
                    RClaimsParserLibraryErrorCodes.RCLAIMSPARSERLIB_DATA_OFFSET_OVERFLOW
                )
            )
        );
        require(
            src.length >= dataOffset + _RCLAIMS_SIZE,
            string(
                abi.encodePacked(RClaimsParserLibraryErrorCodes.RCLAIMSPARSERLIB_INSUFFICIENT_BYTES)
            )
        );
        rClaims.chainId = BaseParserLibrary.extractUInt32(src, dataOffset);
        require(
            rClaims.chainId > 0,
            string(abi.encodePacked(RClaimsParserLibraryErrorCodes.RCLAIMSPARSERLIB_CHAINID_ZERO))
        );
        rClaims.height = BaseParserLibrary.extractUInt32(src, dataOffset + 4);
        require(
            rClaims.height > 0,
            string(abi.encodePacked(RClaimsParserLibraryErrorCodes.RCLAIMSPARSERLIB_HEIGHT_ZERO))
        );
        rClaims.round = BaseParserLibrary.extractUInt32(src, dataOffset + 8);
        require(
            rClaims.round > 0,
            string(abi.encodePacked(RClaimsParserLibraryErrorCodes.RCLAIMSPARSERLIB_ROUND_ZERO))
        );
        rClaims.prevBlock = BaseParserLibrary.extractBytes32(src, dataOffset + 24);
    }
}




/// @title Library to parse the RCert structure from a blob of capnproto data
library RCertParserLibrary {
    struct RCert {
        RClaimsParserLibrary.RClaims rClaims;
        uint256[4] sigGroupPublicKey;
        uint256[2] sigGroupSignature;
    }

    /** @dev size in bytes of a RCert cap'npro structure without the cap'n proto
      header bytes */
    uint256 internal constant _RCERT_SIZE = 264;
    /** @dev Number of bytes of a capnproto header, the data starts after the
      header */
    uint256 internal constant _CAPNPROTO_HEADER_SIZE = 8;
    /** @dev Number of Bytes of the sig group array */
    uint256 internal constant _SIG_GROUP_SIZE = 192;

    /// @notice Extracts the signature group out of a Capn Proto blob.
    /// @param src Binary data containing signature group data
    /// @param dataOffset offset of the signature group data inside src
    /// @return publicKey the public keys
    /// @return signature the signature
    /// @dev Execution cost: 1645 gas.
    function extractSigGroup(bytes memory src, uint256 dataOffset)
        internal
        pure
        returns (uint256[4] memory publicKey, uint256[2] memory signature)
    {
        require(
            dataOffset + RCertParserLibrary._SIG_GROUP_SIZE > dataOffset,
            string(
                abi.encodePacked(RCertParserLibraryErrorCodes.RCERTPARSERLIB_DATA_OFFSET_OVERFLOW)
            )
        );
        require(
            src.length >= dataOffset + RCertParserLibrary._SIG_GROUP_SIZE,
            string(abi.encodePacked(RCertParserLibraryErrorCodes.RCERTPARSERLIB_INSUFFICIENT_BYTES))
        );
        // _SIG_GROUP_SIZE = 192 bytes -> size in bytes of 6 uint256/bytes32 elements (6*32)
        publicKey[0] = BaseParserLibrary.extractUInt256(src, dataOffset + 0);
        publicKey[1] = BaseParserLibrary.extractUInt256(src, dataOffset + 32);
        publicKey[2] = BaseParserLibrary.extractUInt256(src, dataOffset + 64);
        publicKey[3] = BaseParserLibrary.extractUInt256(src, dataOffset + 96);
        signature[0] = BaseParserLibrary.extractUInt256(src, dataOffset + 128);
        signature[1] = BaseParserLibrary.extractUInt256(src, dataOffset + 160);
    }

    /**
    @notice This function is for deserializing data directly from capnproto
            RCert. It will skip the first 8 bytes (capnproto headers) and
            deserialize the RCert Data. If RCert is being extracted from
            inside of other structure (E.g PClaim capnproto) use the
            `extractInnerRCert(bytes, uint)` instead.
    */
    /// @param src Binary data containing a RCert serialized struct with Capn Proto headers
    /// @return the RCert struct
    /// @dev Execution cost: 4076 gas
    function extractRCert(bytes memory src) internal pure returns (RCert memory) {
        return extractInnerRCert(src, _CAPNPROTO_HEADER_SIZE);
    }

    /**
    @notice This function is for deserializing the RCert struct from an defined
            location inside a binary blob. E.G Extract RCert from inside of
            other structure (E.g RCert capnproto) or skipping the capnproto
            headers.
    */
    /// @param src Binary data containing a RCert serialized struct without Capn Proto headers
    /// @param dataOffset offset to start reading the RCert data from inside src
    /// @return rCert the RCert struct
    /// @dev Execution cost: 3691 gas
    function extractInnerRCert(bytes memory src, uint256 dataOffset)
        internal
        pure
        returns (RCert memory rCert)
    {
        require(
            dataOffset + _RCERT_SIZE > dataOffset,
            string(
                abi.encodePacked(RCertParserLibraryErrorCodes.RCERTPARSERLIB_DATA_OFFSET_OVERFLOW)
            )
        );
        require(
            src.length >= dataOffset + _RCERT_SIZE,
            string(
                abi.encodePacked(
                    RCertParserLibraryErrorCodes.RCERTPARSERLIB_INSUFFICIENT_BYTES_TO_EXTRACT
                )
            )
        );
        rCert.rClaims = RClaimsParserLibrary.extractInnerRClaims(src, dataOffset + 16);
        (rCert.sigGroupPublicKey, rCert.sigGroupSignature) = extractSigGroup(src, dataOffset + 72);
    }
}



library CryptoLibraryErrorCodes {
    // CryptoLibrary error codes
    bytes32 public constant CRYPTOLIB_ELLIPTIC_CURVE_ADDITION = "700"; //"elliptic curve addition failed"
    bytes32 public constant CRYPTOLIB_ELLIPTIC_CURVE_MULTIPLICATION = "701"; //"elliptic curve multiplication failed"
    bytes32 public constant CRYPTOLIB_ELLIPTIC_CURVE_PAIRING = "702"; //"elliptic curve pairing failed"
    bytes32 public constant CRYPTOLIB_MODULAR_EXPONENTIATION = "703"; //"modular exponentiation falied"
    bytes32 public constant CRYPTOLIB_HASH_POINT_NOT_ON_CURVE = "704"; //"Invalid hash point: not on elliptic curve"
    bytes32 public constant CRYPTOLIB_HASH_POINT_UNSAFE = "705"; //"Dangerous hash point: not safe for signing"
    bytes32 public constant CRYPTOLIB_POINT_NOT_ON_CURVE = "706"; //"Invalid point: not on elliptic curve"
    bytes32 public constant CRYPTOLIB_SIGNATURES_INDICES_LENGTH_MISMATCH = "707"; //"Mismatch between length of signatures and index array"
    bytes32 public constant CRYPTOLIB_SIGNATURES_LENGTH_THRESHOLD_NOT_MET = "708"; //"Failed to meet required number of signatures for threshold"
    bytes32 public constant CRYPTOLIB_INVERSE_ARRAY_INCORRECT = "709"; //"invArray does not include correct inverses"
    bytes32 public constant CRYPTOLIB_INVERSE_ARRAY_THRESHOLD_EXCEEDED = "710"; // "checkInverses: insufficient inverses for group signature calculation"
    bytes32 public constant CRYPTOLIB_POINTSG1_INDICES_LENGTH_MISMATCH = "711"; // "Mismatch between pointsG1 and indices arrays"
    bytes32 public constant CRYPTOLIB_K_EQUAL_TO_J = "712"; // "Must have k != j when computing Rj partial constants"
}



/*
    Author: Philipp Schindler
    Source code and documentation available on Github: https://github.com/PhilippSchindler/ethdkg

    Copyright 2019 Philipp Schindler

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// TODO: we may want to check some of the functions to ensure that they are valid.
//       some of them may not be if there are attempts they are called with
//       invalid points.
library CryptoLibrary {
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// CRYPTOGRAPHIC CONSTANTS

    ////////
    //// These constants are updated to reflect our version, not theirs.
    ////////

    // GROUP_ORDER is the are the number of group elements in the groups G1, G2, and GT.
    uint256 public constant GROUP_ORDER =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // FIELD_MODULUS is the prime number over which the elliptic curves are based.
    uint256 public constant FIELD_MODULUS =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    // CURVE_B is the constant of the elliptic curve for G1:
    //
    //      y^2 == x^3 + CURVE_B,
    //
    // with CURVE_B == 3.
    uint256 public constant CURVE_B = 3;

    // G1 == (G1_X, G1_Y) is the standard generator for group G1.
    // uint256 constant G1_X  = 1;
    // uint256 constant G1_Y  = 2;
    // H1 == (H1X, H1Y) = hashToG1([]byte("MadHive Rocks!") from golang code;
    // this is another generator for G1 and dlog_G1(H1) is unknown,
    // which is necessary for security.
    //
    // In the future, the specific value of H1 could be changed every time
    // there is a change in validator set. For right now, though, this will
    // be a fixed constant.
    uint256 public constant H1_X =
        2788159449993757418373833378244720686978228247930022635519861138679785693683;
    uint256 public constant H1_Y =
        12344898367754966892037554998108864957174899548424978619954608743682688483244;

    // H2 == ([H2_XI, H2_X], [H2_YI, H2_Y]) is the *negation* of the
    // standard generator of group G2.
    // The standard generator comes from the Ethereum bn256 Go code.
    // The negated form is required because bn128_pairing check in Solidty requires this.
    //
    // In particular, to check
    //
    //      sig = H(msg)^privK
    //
    // is a valid signature for
    //
    //      pubK = H2Gen^privK,
    //
    // we need
    //
    //      e(sig, H2Gen) == e(H(msg), pubK).
    //
    // This is equivalent to
    //
    //      e(sig, H2) * e(H(msg), pubK) == 1.
    uint256 public constant H2_XI =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 public constant H2_X =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 public constant H2_YI =
        17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 public constant H2_Y =
        13392588948715843804641432497768002650278120570034223513918757245338268106653;

    uint256 public constant G1_X = 1;
    uint256 public constant G1_Y = 2;

    // TWO_256_MOD_P == 2^256 mod FIELD_MODULUS;
    // this is used in hashToBase to obtain a more uniform hash value.
    uint256 public constant TWO_256_MOD_P =
        6350874878119819312338956282401532409788428879151445726012394534686998597021;

    // P_MINUS1 == -1 mod FIELD_MODULUS;
    // this is used in sign0 and all ``negative'' values have this sign value.
    uint256 public constant P_MINUS1 =
        21888242871839275222246405745257275088696311157297823662689037894645226208582;

    // P_MINUS2 == FIELD_MODULUS - 2;
    // this is the exponent used in finite field inversion.
    uint256 public constant P_MINUS2 =
        21888242871839275222246405745257275088696311157297823662689037894645226208581;

    // P_MINUS1_OVER2 == (FIELD_MODULUS - 1) / 2;
    // this is the exponent used in computing the Legendre symbol and is
    // also used in sign0 as the cutoff point between ``positive'' and
    // ``negative'' numbers.
    uint256 public constant P_MINUS1_OVER2 =
        10944121435919637611123202872628637544348155578648911831344518947322613104291;

    // P_PLUS1_OVER4 == (FIELD_MODULUS + 1) / 4;
    // this is the exponent used in computing finite field square roots.
    uint256 public constant P_PLUS1_OVER4 =
        5472060717959818805561601436314318772174077789324455915672259473661306552146;

    // baseToG1 constants
    //
    // These are precomputed constants which are independent of t.
    // All of these constants are computed modulo FIELD_MODULUS.
    //
    // (-1 + sqrt(-3))/2
    uint256 public constant HASH_CONST_1 =
        2203960485148121921418603742825762020974279258880205651966;
    // sqrt(-3)
    uint256 public constant HASH_CONST_2 =
        4407920970296243842837207485651524041948558517760411303933;
    // 1/3
    uint256 public constant HASH_CONST_3 =
        14592161914559516814830937163504850059130874104865215775126025263096817472389;
    // 1 + CURVE_B (CURVE_B == 3)
    uint256 public constant HASH_CONST_4 = 4;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// HELPER FUNCTIONS

    function discreteLogEquality(
        uint256[2] memory x1,
        uint256[2] memory y1,
        uint256[2] memory x2,
        uint256[2] memory y2,
        uint256[2] memory proof
    ) internal view returns (bool proofIsValid) {
        uint256[2] memory tmp1;
        uint256[2] memory tmp2;

        tmp1 = bn128Multiply([x1[0], x1[1], proof[1]]);
        tmp2 = bn128Multiply([y1[0], y1[1], proof[0]]);
        uint256[2] memory t1prime = bn128Add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        tmp1 = bn128Multiply([x2[0], x2[1], proof[1]]);
        tmp2 = bn128Multiply([y2[0], y2[1], proof[0]]);
        uint256[2] memory t2prime = bn128Add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        uint256 challenge = uint256(keccak256(abi.encodePacked(x1, y1, x2, y2, t1prime, t2prime)));
        proofIsValid = challenge == proof[0];
    }

    function bn128Add(uint256[4] memory input) internal view returns (uint256[2] memory result) {
        // computes P + Q
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        assembly {
            // solium-disable-line
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(not(0), 0x06, input, 128, result, 64)
        }
        require(
            success,
            string(abi.encodePacked(CryptoLibraryErrorCodes.CRYPTOLIB_ELLIPTIC_CURVE_ADDITION))
        );
    }

    function bn128Multiply(uint256[3] memory input)
        internal
        view
        returns (uint256[2] memory result)
    {
        // computes P*x
        // input: 3 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) scalar x

        bool success;
        assembly {
            // solium-disable-line
            // 0x07     id of precompiled bn256ScalarMul contract
            // 0        number of ether to transfer
            // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(not(0), 0x07, input, 96, result, 64)
        }
        require(success, "elliptic curve multiplication failed");
    }

    function bn128CheckPairing(uint256[12] memory input) internal view returns (bool) {
        uint256[1] memory result;
        bool success;
        assembly {
            // solium-disable-line
            // 0x08     id of precompiled bn256Pairing contract     (checking the elliptic curve pairings)
            // 0        number of ether to transfer
            // 384       size of call parameters, i.e. 12*256 bits == 384 bytes
            // 32        size of result (one 32 byte boolean!)
            success := staticcall(not(0), 0x08, input, 384, result, 32)
        }
        require(success, "elliptic curve pairing failed");
        return result[0] == 1;
    }

    //// Begin new helper functions added
    // expmod perform modular exponentiation with all variables uint256;
    // this is used in legendre, sqrt, and invert.
    //
    // Copied from
    //      https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    // and slightly modified
    function expmod(
        uint256 base,
        uint256 e,
        uint256 m
    ) internal view returns (uint256 result) {
        bool success;
        assembly {
            // solium-disable-line
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            // 0x05           id of precompiled modular exponentiation contract
            // 0xc0 == 192    size of call parameters
            // 0x20 ==  32    size of result
            success := staticcall(gas(), 0x05, p, 0xc0, p, 0x20)
            // data
            result := mload(p)
        }
        require(success, "modular exponentiation falied");
    }

    // Sign takes byte slice message and private key privK.
    // It then calls HashToG1 with message as input and performs scalar
    // multiplication to produce the resulting signature.
    function sign(bytes memory message, uint256 privK)
        internal
        view
        returns (uint256[2] memory sig)
    {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1(message);
        sig = bn128Multiply([hashPoint[0], hashPoint[1], privK]);
    }

    // Verify takes byte slice message, signature sig (element of G1),
    // public key pubK (element of G2), and checks that sig is a valid
    // signature for pubK for message. Also look at the definition of H2.
    function verifySignature(
        bytes memory message,
        uint256[2] memory sig,
        uint256[4] memory pubK
    ) internal view returns (bool v) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1(message);
        v = bn128CheckPairing(
            [
                sig[0],
                sig[1],
                H2_XI,
                H2_X,
                H2_YI,
                H2_Y,
                hashPoint[0],
                hashPoint[1],
                pubK[0],
                pubK[1],
                pubK[2],
                pubK[3]
            ]
        );
    }

    // Optimized version written in ASM of the Verify function. It takes byte slice message, signature
    // sig (element of G1), public key pubK (element of G2), and checks that sig is a valid signature
    // for pubK for message. Also look at the definition of H2.
    function verifySignatureASM(
        bytes memory message,
        uint256[2] memory sig,
        uint256[4] memory pubK
    ) internal view returns (bool v) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1ASM(message);
        v = bn128CheckPairing(
            [
                sig[0],
                sig[1],
                H2_XI,
                H2_X,
                H2_YI,
                H2_Y,
                hashPoint[0],
                hashPoint[1],
                pubK[0],
                pubK[1],
                pubK[2],
                pubK[3]
            ]
        );
    }

    // HashToG1 takes byte slice message and outputs an element of G1.
    // This function is based on the Fouque and Tibouchi 2012 paper
    // ``Indifferentiable Hashing to Barreto--Naehrig Curves''.
    // There are a couple improvements included from Wahby and Boneh's 2019 paper
    // ``Fast and simple constant-time hashing to the BLS12-381 elliptic curve''.
    //
    // There are two parts: hashToBase and baseToG1.
    //
    // hashToBase takes a byte slice (with additional bytes for domain
    // separation) and returns uint256 t with 0 <= t < FIELD_MODULUS; thus,
    // it is a valid element of F_p, the base field of the elliptic curve.
    // This is the ``hash'' portion of the hash function. The two byte
    // values are used for domain separation in order to obtain independent
    // hash functions.
    //
    // baseToG1 is a deterministic function which takes t in F_p and returns
    // a valid element of the elliptic curve.
    //
    // By combining hashToBase and baseToG1, we get a HashToG1. Now, we
    // perform this operation twice because without it, we would not have
    // a valid hash function. The reason is that baseToG1 only maps to
    // approximately 9/16ths of the points in the elliptic curve.
    // By doing this twice (with independent hash functions) and adding the
    // resulting points, we have an actual hash function to G1.
    // For more information relating to the hash-to-curve theory,
    // see the FT 2012 paper.
    function hashToG1(bytes memory message) internal view returns (uint256[2] memory h) {
        uint256 t0 = hashToBase(message, 0x00, 0x01);
        uint256 t1 = hashToBase(message, 0x02, 0x03);

        uint256[2] memory h0 = baseToG1(t0);
        uint256[2] memory h1 = baseToG1(t1);

        // Each BaseToG1 call involves a check that we have a valid curve point.
        // Here, we check that we have a valid curve point after the addition.
        // Again, this is to ensure that even if something strange happens, we
        // will not return an invalid curvepoint.
        h = bn128Add([h0[0], h0[1], h1[0], h1[1]]);
        require(
            bn128IsOnCurve(h),
            string(abi.encodePacked(CryptoLibraryErrorCodes.CRYPTOLIB_HASH_POINT_NOT_ON_CURVE))
        );
        require(
            safeSigningPoint(h),
            string(abi.encodePacked(CryptoLibraryErrorCodes.CRYPTOLIB_HASH_POINT_UNSAFE))
        );
    }

    /// HashToG1 takes byte slice message and outputs an element of G1. Optimized version of `hashToG1`
    /// written in EVM assembly.
    function hashToG1ASM(bytes memory message) internal view returns (uint256[2] memory h) {
        assembly {
            function memCopy(dest, src, len) {
                if lt(len, 32) {
                    mstore(0, "invalid len")
                    revert(0, 32)
                }
                // Copy word-length chunks while possible
                for {

                } gt(len, 31) {
                    len := sub(len, 32)
                } {
                    mstore(dest, mload(src))
                    src := add(src, 32)
                    dest := add(dest, 32)
                }

                if iszero(eq(len, 0)) {
                    // Copy remaining bytes
                    let mask := sub(exp(256, sub(32, len)), 1)
                    // e.g len = 4, yields
                    // mask    = 00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                    // notMask = ffffffff00000000000000000000000000000000000000000000000000000000
                    let srcpart := and(mload(src), not(mask))
                    let destpart := and(mload(dest), mask)
                    mstore(dest, or(destpart, srcpart))
                }
            }

            function bn128CheckPairing(ptr, paramPtr, x, y) -> result {
                mstore(add(ptr, 0xb0), x)
                mstore(add(ptr, 0xc0), y)
                memCopy(ptr, paramPtr, 0xb0)
                let success := staticcall(gas(), 0x08, ptr, 384, ptr, 32)
                if iszero(success) {
                    revert(0, 0)
                }
                result := mload(ptr)
            }

            function bn128IsOnCurve(p0, p1) -> result {
                let o1 := mulmod(p0, p0, FIELD_MODULUS)
                o1 := mulmod(p0, o1, FIELD_MODULUS)
                o1 := addmod(o1, 3, FIELD_MODULUS)
                let o2 := mulmod(p1, p1, FIELD_MODULUS)
                result := eq(o1, o2)
            }

            function baseToG1(ptr, t, output) {
                let fp := add(ptr, 0xc0)
                let ap1 := mulmod(t, t, FIELD_MODULUS)

                let alpha := mulmod(ap1, addmod(ap1, HASH_CONST_4, FIELD_MODULUS), FIELD_MODULUS)
                // invert alpha
                mstore(add(ptr, 0x60), alpha)
                mstore(add(ptr, 0x80), P_MINUS2)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    mstore(0, "exp mod failed at 1")
                    revert(0, 0x20)
                }
                alpha := mload(fp)

                ap1 := mulmod(ap1, ap1, FIELD_MODULUS)

                let x := mulmod(ap1, HASH_CONST_2, FIELD_MODULUS)
                x := mulmod(x, alpha, FIELD_MODULUS)
                // negating x
                x := sub(FIELD_MODULUS, x)
                x := addmod(x, HASH_CONST_1, FIELD_MODULUS)

                let x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x80), P_PLUS1_OVER4)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    mstore(0, "exp mod failed at 2")
                    revert(0, 0x20)
                }

                let ymul := 1
                if gt(t, P_MINUS1_OVER2) {
                    ymul := P_MINUS1
                }
                let y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                let y_two := mulmod(y, y, FIELD_MODULUS)
                if eq(x_three, y_two) {
                    mstore(output, x)
                    mstore(add(output, 0x20), y)
                    leave
                }
                x := addmod(x, 1, FIELD_MODULUS)
                x := sub(FIELD_MODULUS, x)
                x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    mstore(0, "exp mod failed at 3")
                    revert(0, 0x20)
                }
                y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                y_two := mulmod(y, y, FIELD_MODULUS)
                if eq(x_three, y_two) {
                    mstore(output, x)
                    mstore(add(output, 0x20), y)
                    leave
                }
                ap1 := addmod(mulmod(t, t, FIELD_MODULUS), 4, FIELD_MODULUS)
                x := mulmod(ap1, ap1, FIELD_MODULUS)
                x := mulmod(x, ap1, FIELD_MODULUS)
                x := mulmod(x, HASH_CONST_3, FIELD_MODULUS)
                x := mulmod(x, alpha, FIELD_MODULUS)
                x := sub(FIELD_MODULUS, x)
                x := addmod(x, 1, FIELD_MODULUS)
                x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    mstore(0, "exp mod failed at 4")
                    revert(0, 0x20)
                }
                y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                mstore(output, x)
                mstore(add(output, 0x20), y)
            }

            function hashToG1(ptr, messageptr, messagesize, output) {
                let size := add(messagesize, 1)
                memCopy(add(ptr, 1), messageptr, messagesize)
                mstore8(ptr, 0x00)
                let h0 := keccak256(ptr, size)
                mstore8(ptr, 0x01)
                let h1 := keccak256(ptr, size)
                mstore8(ptr, 0x02)
                let h2 := keccak256(ptr, size)
                mstore8(ptr, 0x03)
                let h3 := keccak256(ptr, size)
                mstore(ptr, 0x20)
                mstore(add(ptr, 0x20), 0x20)
                mstore(add(ptr, 0x40), 0x20)
                mstore(add(ptr, 0xa0), FIELD_MODULUS)
                h1 := addmod(h1, mulmod(h0, TWO_256_MOD_P, FIELD_MODULUS), FIELD_MODULUS)
                h2 := addmod(h3, mulmod(h2, TWO_256_MOD_P, FIELD_MODULUS), FIELD_MODULUS)
                baseToG1(ptr, h1, output)
                let x1 := mload(output)
                let y1 := mload(add(output, 0x20))
                let success := bn128IsOnCurve(x1, y1)
                if iszero(success) {
                    mstore(0, "x1 y1 not in curve")
                    revert(0, 0x20)
                }
                baseToG1(ptr, h2, output)
                let x2 := mload(output)
                let y2 := mload(add(output, 0x20))
                success := bn128IsOnCurve(x2, y2)
                if iszero(success) {
                    mstore(0, "x2 y2 not in curve")
                    revert(0, 0x20)
                }
                mstore(ptr, x1)
                mstore(add(ptr, 0x20), y1)
                mstore(add(ptr, 0x40), x2)
                mstore(add(ptr, 0x60), y2)
                if iszero(staticcall(gas(), 0x06, ptr, 128, ptr, 64)) {
                    mstore(0, "bn256 add failed")
                    revert(0, 0x20)
                }
                let x := mload(ptr)
                let y := mload(add(ptr, 0x20))
                success := bn128IsOnCurve(x, y)
                if iszero(success) {
                    mstore(0, "x2 y2 not in curve")
                    revert(0, 0x20)
                }
                if or(iszero(x), eq(y, 1)) {
                    mstore(0, "point not safe to sign")
                    revert(0, 0x20)
                }
                mstore(output, x)
                mstore(add(output, 0x20), y)
            }

            let messageptr := add(message, 0x20)
            let messagesize := mload(message)
            let ptr := mload(0x40)
            hashToG1(ptr, messageptr, messagesize, h)
        }
    }

    // baseToG1 is a deterministic map from the base field F_p to the elliptic
    // curve. All values in [0, FIELD_MODULUS) are valid including 0, so we
    // do not need to worry about any exceptions.
    //
    // We remember our elliptic curve has the form
    //
    //      y^2 == x^3 + b
    //          == g(x)
    //
    // The main idea is that given t, we can produce x values x1, x2, and x3
    // such that
    //
    //      g(x1)*g(x2)*g(x3) == s^2.
    //
    // The above equation along with quadratic residues means that
    // when s != 0, at least one of g(x1), g(x2), or g(x3) is a square,
    // which implies that x1, x2, or x3 is a valid x-coordinate to a point
    // on the elliptic curve. For uniqueness, we choose the smallest coordinate.
    // In our construction, the above s value will always be nonzero, so we will
    // always have a solution. This means that baseToG1 is a deterministic
    // map from the base field to the elliptic curve.
    function baseToG1(uint256 t) internal view returns (uint256[2] memory h) {
        // ap1 and ap2 are temporary variables, originally named to represent
        // alpha part 1 and alpha part 2. Now they are somewhat general purpose
        // variables due to using too many variables on stack.
        uint256 ap1;
        uint256 ap2;

        // One of the main constants variables to form x1, x2, and x3
        // is alpha, which has the following definition:
        //
        //      alpha == (ap1*ap2)^(-1)
        //            == [t^2*(t^2 + h4)]^(-1)
        //
        //      ap1 == t^2
        //      ap2 == t^2 + h4
        //      h4  == HASH_CONST_4
        //
        // Defining alpha helps decrease the calls to expmod,
        // which is the most expensive operation we do.
        uint256 alpha;
        ap1 = mulmod(t, t, FIELD_MODULUS);
        ap2 = addmod(ap1, HASH_CONST_4, FIELD_MODULUS);
        alpha = mulmod(ap1, ap2, FIELD_MODULUS);
        alpha = invert(alpha);

        // Another important constant which is used when computing x3 is tmp,
        // which has the following definition:
        //
        //      tmp == (t^2 + h4)^3
        //          == ap2^3
        //
        //      h4  == HASH_CONST_4
        //
        // This is cheap to compute because ap2 has not changed
        uint256 tmp;
        tmp = mulmod(ap2, ap2, FIELD_MODULUS);
        tmp = mulmod(tmp, ap2, FIELD_MODULUS);

        // When computing x1, we need to compute t^4. ap1 will be the
        // temporary variable which stores this value now:
        //
        // Previous definition:
        //      ap1 == t^2
        //
        // Current definition:
        //      ap1 == t^4
        ap1 = mulmod(ap1, ap1, FIELD_MODULUS);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x1 == h1 - h2*t^4*alpha
        //         == h1 - h2*ap1*alpha
        //
        //      ap1 == t^4 (note previous assignment)
        //      h1  == HASH_CONST_1
        //      h2  == HASH_CONST_2
        //
        // When t == 0, x1 is a valid x-coordinate of a point on the elliptic
        // curve, so we need no exceptions; this is different than the original
        // Fouque and Tibouchi 2012 paper. This comes from the fact that
        // 0^(-1) == 0 mod p, as we use expmod for inversion.
        uint256 x1;
        x1 = mulmod(HASH_CONST_2, ap1, FIELD_MODULUS);
        x1 = mulmod(x1, alpha, FIELD_MODULUS);
        x1 = neg(x1);
        x1 = addmod(x1, HASH_CONST_1, FIELD_MODULUS);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x2 == -1 - x1
        uint256 x2;
        x2 = addmod(x1, 1, FIELD_MODULUS);
        x2 = neg(x2);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x3 == 1 - h3*tmp*alpha
        //
        //      h3 == HASH_CONST_3
        uint256 x3;
        x3 = mulmod(HASH_CONST_3, tmp, FIELD_MODULUS);
        x3 = mulmod(x3, alpha, FIELD_MODULUS);
        x3 = neg(x3);
        x3 = addmod(x3, 1, FIELD_MODULUS);

        // We now focus on determing residue1; if residue1 == 1,
        // then x1 is a valid x-coordinate for a point on E(F_p).
        //
        // When computing residues, the original FT 2012 paper suggests
        // blinding for security. We do not use that suggestion here
        // because of the possibility of a random integer being returned
        // which is 0, which would completely destroy the output.
        // Additionally, computing random numbers on Ethereum is difficult.
        uint256 y;
        y = mulmod(x1, x1, FIELD_MODULUS);
        y = mulmod(y, x1, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        int256 residue1 = legendre(y);

        // We now focus on determing residue2; if residue2 == 1,
        // then x2 is a valid x-coordinate for a point on E(F_p).
        y = mulmod(x2, x2, FIELD_MODULUS);
        y = mulmod(y, x2, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        int256 residue2 = legendre(y);

        // i is the index which gives us the correct x value (x1, x2, or x3)
        int256 i = ((residue1 - 1) * (residue2 - 3)) / 4 + 1;

        // This is the simplest way to determine which x value is correct
        // but is not secure. If possible, we should improve this.
        uint256 x;
        if (i == 1) {
            x = x1;
        } else if (i == 2) {
            x = x2;
        } else {
            x = x3;
        }

        // Now that we know x, we compute y
        y = mulmod(x, x, FIELD_MODULUS);
        y = mulmod(y, x, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        y = sqrt(y);

        // We now determine the sign of y based on t; this is a change from
        // the original FT 2012 paper and uses the suggestion from WB 2019.
        //
        // This is done to save computation, as using sign0 reduces the
        // number of calls to expmod from 5 to 4; currently, we call expmod
        // for inversion (alpha), two legendre calls (for residue1 and
        // residue2), and one sqrt call.
        // This change nullifies the proof in FT 2012 that we have a valid
        // hash function. Whether the proof could be slightly modified to
        // compensate for this change is possible but not currently known.
        //
        // (CHG: At the least, I am not sure that the proof holds, nor am I
        // able to see how the proof could potentially be fixed in order
        // for the hash function to be admissible.)
        //
        // If this is included as a precompile, it may be worth it to ignore
        // the cost savings in order to ensure uniformity of the hash function.
        // Also, we would need to change legendre so that legendre(0) == 1,
        // or else things would fail when t == 0. We could also have a separate
        // function for the sign determiniation.
        uint256 ySign;
        ySign = sign0(t);
        y = mulmod(y, ySign, FIELD_MODULUS);

        // Before returning the value, we check to make sure we have a valid
        // curve point. This ensures we will always have a valid point.
        // From Fouque-Tibouchi 2012, the only way to get an invalid point is
        // when t == 0, but we have already taken care of that to ensure that
        // when t == 0, we still return a valid curve point.
        require(
            bn128IsOnCurve([x, y]),
            string(abi.encodePacked(CryptoLibraryErrorCodes.CRYPTOLIB_POINT_NOT_ON_CURVE))
        );

        h[0] = x;
        h[1] = y;
    }

    // invert computes the multiplicative inverse of t modulo FIELD_MODULUS.
    // When t == 0, s == 0.
    function invert(uint256 t) internal view returns (uint256 s) {
        s = expmod(t, P_MINUS2, FIELD_MODULUS);
    }

    // sqrt computes the multiplicative square root of t modulo FIELD_MODULUS.
    // sqrt does not check that a square root is possible; see legendre.
    function sqrt(uint256 t) internal view returns (uint256 s) {
        s = expmod(t, P_PLUS1_OVER4, FIELD_MODULUS);
    }

    // legendre computes the legendre symbol of t with respect to FIELD_MODULUS.
    // That is, legendre(t) == 1 when a square root of t exists modulo
    // FIELD_MODULUS, legendre(t) == -1 when a square root of t does not exist
    // modulo FIELD_MODULUS, and legendre(t) == 0 when t == 0 mod FIELD_MODULUS.
    function legendre(uint256 t) internal view returns (int256 chi) {
        uint256 s = expmod(t, P_MINUS1_OVER2, FIELD_MODULUS);
        if (s != 0) {
            chi = 2 * int256(s & 1) - 1;
        } else {
            chi = 0;
        }
    }

    // AggregateSignatures takes takes the signature array sigs, index array
    // indices, and threshold to compute the thresholded group signature.
    // After ensuring some basic requirements are met, it calls
    // LagrangeInterpolationG1 to perform this interpolation.
    //
    // To trade computation (and expensive gas costs) for space, we choose
    // to require that the multiplicative inverses modulo GROUP_ORDER be
    // entered for this function call in invArray. This allows the expensive
    // portion of gas cost to grow linearly in the size of the group rather
    // than quadratically. Additional improvements made be included
    // in the future.
    //
    // One advantage to how this function is designed is that we do not need
    // to know the number of participants, as we only require inverses which
    // will be required as deteremined by indices.
    function aggregateSignatures(
        uint256[2][] memory sigs,
        uint256[] memory indices,
        uint256 threshold,
        uint256[] memory invArray
    ) internal view returns (uint256[2] memory) {
        require(
            sigs.length == indices.length,
            string(
                abi.encodePacked(
                    CryptoLibraryErrorCodes.CRYPTOLIB_SIGNATURES_INDICES_LENGTH_MISMATCH
                )
            )
        );
        require(
            sigs.length > threshold,
            string(
                abi.encodePacked(
                    CryptoLibraryErrorCodes.CRYPTOLIB_SIGNATURES_LENGTH_THRESHOLD_NOT_MET
                )
            )
        );
        uint256 maxIndex = computeArrayMax(indices);
        require(
            checkInverses(invArray, maxIndex),
            string(abi.encodePacked(CryptoLibraryErrorCodes.CRYPTOLIB_INVERSE_ARRAY_INCORRECT))
        );
        uint256[2] memory grpsig;
        grpsig = lagrangeInterpolationG1(sigs, indices, threshold, invArray);
        return grpsig;
    }

    // LagrangeInterpolationG1 efficiently computes Lagrange interpolation
    // of pointsG1 using indices as the point location in the finite field.
    // This is an efficient method of Lagrange interpolation as we assume
    // finite field inverses are in invArray.
    function lagrangeInterpolationG1(
        uint256[2][] memory pointsG1,
        uint256[] memory indices,
        uint256 threshold,
        uint256[] memory invArray
    ) internal view returns (uint256[2] memory) {
        require(pointsG1.length == indices.length, "Mismatch between pointsG1 and indices arrays");
        uint256[2] memory val;
        val[0] = 0;
        val[1] = 0;
        uint256 i;
        uint256 ell;
        uint256 idxJ;
        uint256 idxK;
        uint256 rj;
        uint256 rjPartial;
        uint256[2] memory partialVal;
        for (i = 0; i < indices.length; i++) {
            idxJ = indices[i];
            if (i > threshold) {
                break;
            }
            rj = 1;
            for (ell = 0; ell < indices.length; ell++) {
                idxK = indices[ell];
                if (ell > threshold) {
                    break;
                }
                if (idxK == idxJ) {
                    continue;
                }
                rjPartial = liRjPartialConst(idxK, idxJ, invArray);
                rj = mulmod(rj, rjPartial, GROUP_ORDER);
            }
            partialVal = pointsG1[i];
            partialVal = bn128Multiply([partialVal[0], partialVal[1], rj]);
            val = bn128Add([val[0], val[1], partialVal[0], partialVal[1]]);
        }
        return val;
    }

    // liRjPartialConst computes the partial constants of rj in Lagrange
    // interpolation based on the the multiplicative inverses in invArray.
    function liRjPartialConst(
        uint256 k,
        uint256 j,
        uint256[] memory invArray
    ) internal pure returns (uint256) {
        require(k != j, "Must have k != j when computing rj partial constants");
        uint256 tmp1 = k;
        uint256 tmp2;
        if (k > j) {
            tmp2 = k - j;
        } else {
            tmp1 = mulmod(tmp1, GROUP_ORDER - 1, GROUP_ORDER);
            tmp2 = j - k;
        }
        tmp2 = invArray[tmp2 - 1];
        tmp2 = mulmod(tmp1, tmp2, GROUP_ORDER);
        return tmp2;
    }

    // TODO: identity (0, 0) should be considered a valid point
    function bn128IsOnCurve(uint256[2] memory point) internal pure returns (bool) {
        // check if the provided point is on the bn128 curve (y**2 = x**3 + 3)
        return
            mulmod(point[1], point[1], FIELD_MODULUS) ==
            addmod(
                mulmod(point[0], mulmod(point[0], point[0], FIELD_MODULUS), FIELD_MODULUS),
                3,
                FIELD_MODULUS
            );
    }

    // hashToBase takes in a byte slice message and bytes c0 and c1 for
    // domain separation. The idea is that we treat keccak256 as a random
    // oracle which outputs uint256. The problem is that we want to hash modulo
    // FIELD_MODULUS (p, a prime number). Just using uint256 mod p will lead
    // to bias in the distribution. In particular, there is bias towards the
    // lower 5% of the numbers in [0, FIELD_MODULUS). The 1-norm error between
    // s0 mod p and a uniform distribution is ~ 1/4. By itself, this 1-norm
    // error is not too enlightening, but continue reading, as we will compare
    // it with another distribution that has much smaller 1-norm error.
    //
    // To obtain a better distribution with less bias, we take 2 uint256 hash
    // outputs (using c0 and c1 for domain separation so the hashes are
    // independent) and ``combine them'' to form a ``uint512''. Of course,
    // this is not possible in practice, so we view the combined output as
    //
    //      x == s0*2^256 + s1.
    //
    // This implies that x (combined from s0 and s1 in this way) is a
    // 512-bit uint. If s0 and s1 are uniformly distributed modulo 2^256,
    // then x is uniformly distributed modulo 2^512. We now want to reduce
    // this modulo FIELD_MODULUS (p). This is done as follows:
    //
    //      x mod p == [(s0 mod p)*(2^256 mod p)] + s1 mod p.
    //
    // This allows us easily compute the result without needing to implement
    // higher precision. The 1-norm error between x mod p and a uniform
    // distribution is ~1e-77. This is a *signficant* improvement from s0 mod p.
    // For all practical purposes, there is no difference from a
    // uniform distribution.
    function hashToBase(
        bytes memory message,
        bytes1 c0,
        bytes1 c1
    ) internal pure returns (uint256 t) {
        uint256 s0 = uint256(keccak256(abi.encodePacked(c0, message)));
        uint256 s1 = uint256(keccak256(abi.encodePacked(c1, message)));
        t = addmod(mulmod(s0, TWO_256_MOD_P, FIELD_MODULUS), s1, FIELD_MODULUS);
    }

    // safeSigningPoint ensures that the HashToG1 point we are returning
    // is safe to sign; in particular, it is not Infinity (the group identity
    // element) or the standard curve generator (curveGen) or its negation.
    //
    // TODO: may want to confirm point is valid first as well as reducing mod field prime
    function safeSigningPoint(uint256[2] memory input) internal pure returns (bool) {
        if (input[0] == 0 || input[0] == 1) {
            return false;
        } else {
            return true;
        }
    }

    // neg computes the additive inverse (the negative) modulo FIELD_MODULUS.
    function neg(uint256 t) internal pure returns (uint256 s) {
        if (t == 0) {
            s = 0;
        } else {
            s = FIELD_MODULUS - t;
        }
    }

    // sign0 computes the sign of a finite field element.
    // sign0 is used instead of legendre in baseToG1 from the suggestion
    // of WB 2019.
    function sign0(uint256 t) internal pure returns (uint256 s) {
        s = 1;
        if (t > P_MINUS1_OVER2) {
            s = P_MINUS1;
        }
    }

    // checkInverses takes maxIndex as the maximum element of indices
    // (used in AggregateSignatures) and checks that all of the necessary
    // multiplicative inverses in invArray are correct and present.
    function checkInverses(uint256[] memory invArray, uint256 maxIndex)
        internal
        pure
        returns (bool)
    {
        uint256 k;
        uint256 kInv;
        uint256 res;
        bool validInverses = true;
        require(
            (maxIndex - 1) <= invArray.length,
            "checkInverses: insufficient inverses for group signature calculation"
        );
        for (k = 1; k < maxIndex; k++) {
            kInv = invArray[k - 1];
            res = mulmod(k, kInv, GROUP_ORDER);
            if (res != 1) {
                validInverses = false;
                break;
            }
        }
        return validInverses;
    }

    // checkIndices determines whether or not each of these arrays contain
    // unique indices. There is no reason any index should appear twice.
    // All indices should be in {1, 2, ..., n} and this function ensures this.
    // n is the total number of participants; that is, n == addresses.length.
    function checkIndices(
        uint256[] memory honestIndices,
        uint256[] memory dishonestIndices,
        uint256 n
    ) internal pure returns (bool validIndices) {
        validIndices = true;
        uint256 k;
        uint256 f;
        uint256 curIdx;

        assert(n > 0);
        assert(n < 256);

        // Make sure each honestIndices list is unique
        for (k = 0; k < honestIndices.length; k++) {
            curIdx = honestIndices[k];
            // All indices must be between 1 and n
            if ((curIdx == 0) || (curIdx > n)) {
                validIndices = false;
                break;
            }
            // Only check for equality with previous indices
            if ((f & (1 << curIdx)) == 0) {
                f |= 1 << curIdx;
            } else {
                // We have seen this index before; invalid index sets
                validIndices = false;
                break;
            }
        }
        if (!validIndices) {
            return validIndices;
        }

        // Make sure each dishonestIndices list is unique and does not match
        // any from honestIndices.
        for (k = 0; k < dishonestIndices.length; k++) {
            curIdx = dishonestIndices[k];
            // All indices must be between 1 and n
            if ((curIdx == 0) || (curIdx > n)) {
                validIndices = false;
                break;
            }
            // Only check for equality with previous indices
            if ((f & (1 << curIdx)) == 0) {
                f |= 1 << curIdx;
            } else {
                // We have seen this index before; invalid index sets
                validIndices = false;
                break;
            }
        }
        return validIndices;
    }

    // computeArrayMax computes the maximum uin256 element of uint256Array
    function computeArrayMax(uint256[] memory uint256Array) internal pure returns (uint256) {
        uint256 curVal;
        uint256 maxVal = uint256Array[0];
        for (uint256 i = 1; i < uint256Array.length; i++) {
            curVal = uint256Array[i];
            if (curVal > maxVal) {
                maxVal = curVal;
            }
        }
        return maxVal;
    }
}




abstract contract SnapshotsStorage is ImmutableETHDKG, ImmutableValidatorPool {
    uint256 internal immutable _epochLength;

    uint256 internal immutable _chainId;

    uint32 internal _epoch;

    // Number of ethereum blocks that we should wait between snapshots. Mainly used to prevent the
    // submission of snapshots in short amount of time by validators that could be potentially being
    // malicious
    uint32 internal _minimumIntervalBetweenSnapshots;

    // after how many eth blocks of not having a snapshot will we start allowing more validators to
    // make it
    uint32 internal _snapshotDesperationDelay;

    // how quickly more validators will be allowed to make a snapshot, once
    // _snapshotDesperationDelay has passed
    uint32 internal _snapshotDesperationFactor;

    mapping(uint256 => Snapshot) internal _snapshots;

    constructor(uint256 chainId_, uint256 epochLength_)
        ImmutableFactory(msg.sender)
        ImmutableETHDKG()
        ImmutableValidatorPool()
    {
        _chainId = chainId_;
        _epochLength = epochLength_;
    }
}



library SnapshotsErrorCodes {
    // Snapshot error codes
    bytes32 public constant SNAPSHOT_ONLY_VALIDATORS_ALLOWED = "400"; //"Snapshots: Only validators allowed!"
    bytes32 public constant SNAPSHOT_CONSENSUS_RUNNING = "401"; //"Snapshots: Consensus is not running!"
    bytes32 public constant SNAPSHOT_MIN_BLOCKS_INTERVAL_NOT_PASSED = "402"; //"Snapshots: Necessary amount of ethereum blocks has not passed since last snapshot!"
    bytes32 public constant SNAPSHOT_CALLER_NOT_ETHDKG_PARTICIPANT = "403"; //"Snapshots: Caller didn't participate in the last ethdkg round!"
    bytes32 public constant SNAPSHOT_WRONG_MASTER_PUBLIC_KEY = "404"; //"Snapshots: Wrong master public key!"
    bytes32 public constant SNAPSHOT_SIGNATURE_VERIFICATION_FAILED = "405"; //"Snapshots: Signature verification failed!"
    bytes32 public constant SNAPSHOT_INCORRECT_BLOCK_HEIGHT = "406"; //"Snapshots: Incorrect AliceNet height for snapshot!"
    bytes32 public constant SNAPSHOT_INCORRECT_CHAIN_ID = "407"; //"Snapshots: Incorrect chainID for snapshot!"
    bytes32 public constant SNAPSHOT_MIGRATION_NOT_ALLOWED = "408"; //Snapshots: Migration only allowed at epoch 0!
    bytes32 public constant SNAPSHOT_MIGRATION_INPUT_DATA_MISMATCH = "409"; //Snapshots: Mismatch calldata length!
}











/// @custom:salt Snapshots
/// @custom:deploy-type deployUpgradeable
contract Snapshots is Initializable, SnapshotsStorage, ISnapshots {
    constructor(uint256 chainID_, uint256 epochLength_) SnapshotsStorage(chainID_, epochLength_) {}

    function initialize(uint32 desperationDelay_, uint32 desperationFactor_)
        public
        onlyFactory
        initializer
    {
        // considering that in optimum conditions 1 Sidechain block is at every 3 seconds and 1 block at
        // ethereum is approx at 13 seconds
        _minimumIntervalBetweenSnapshots = uint32(_epochLength / 4);
        _snapshotDesperationDelay = desperationDelay_;
        _snapshotDesperationFactor = desperationFactor_;
    }

    function setSnapshotDesperationDelay(uint32 desperationDelay_) public onlyFactory {
        _snapshotDesperationDelay = desperationDelay_;
    }

    function setSnapshotDesperationFactor(uint32 desperationFactor_) public onlyFactory {
        _snapshotDesperationFactor = desperationFactor_;
    }

    function setMinimumIntervalBetweenSnapshots(uint32 minimumIntervalBetweenSnapshots_)
        public
        onlyFactory
    {
        _minimumIntervalBetweenSnapshots = minimumIntervalBetweenSnapshots_;
    }

    /// @notice Saves next snapshot
    /// @param groupSignature_ The group signature used to sign the snapshots' block claims
    /// @param bClaims_ The claims being made about given block
    /// @return Flag whether we should kick off another round of key generation
    function snapshot(bytes calldata groupSignature_, bytes calldata bClaims_)
        public
        returns (bool)
    {
        require(
            IValidatorPool(_validatorPoolAddress()).isValidator(msg.sender),
            string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_ONLY_VALIDATORS_ALLOWED))
        );
        require(
            IValidatorPool(_validatorPoolAddress()).isConsensusRunning(),
            string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_CONSENSUS_RUNNING))
        );

        require(
            block.number >= _snapshots[_epoch].committedAt + _minimumIntervalBetweenSnapshots,
            string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_MIN_BLOCKS_INTERVAL_NOT_PASSED))
        );

        uint32 epoch = _epoch + 1;

        // // TODO: BRING BACK AFTER GOLANG LOGIC IS DEBUGGED AND MERGED
        // {
        //     // Check if sender is the elected validator allowed to make the snapshot
        //     (bool success, uint256 validatorIndex) = IETHDKG(_ethdkgAddress())
        //         .tryGetParticipantIndex(msg.sender);
        //     require(success, "Snapshots: Caller didn't participate in the last ethdkg round!");

        //     uint256 ethBlocksSinceLastSnapshot = block.number - _snapshots[epoch - 1].committedAt;

        //     uint256 blocksSinceDesperation = ethBlocksSinceLastSnapshot >= _snapshotDesperationDelay
        //         ? ethBlocksSinceLastSnapshot - _snapshotDesperationDelay
        //         : 0;

        //     require(
        //         _mayValidatorSnapshot(
        //             IValidatorPool(_validatorPoolAddress()).getValidatorsCount(),
        //             validatorIndex - 1,
        //             blocksSinceDesperation,
        //             keccak256(bClaims_),
        //             uint256(_snapshotDesperationFactor)
        //         ),
        //         "Snapshots: Validator not elected to do snapshot!"
        //     );
        // }

        {
            (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
                .extractSigGroup(groupSignature_, 0);

            require(
                keccak256(abi.encodePacked(masterPublicKey)) ==
                    IETHDKG(_ethdkgAddress()).getMasterPublicKeyHash(),
                string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_WRONG_MASTER_PUBLIC_KEY))
            );

            require(
                CryptoLibrary.verifySignatureASM(
                    abi.encodePacked(keccak256(bClaims_)),
                    signature,
                    masterPublicKey
                ),
                string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_SIGNATURE_VERIFICATION_FAILED))
            );
        }

        BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.extractBClaims(
            bClaims_
        );

        require(
            epoch * _epochLength == blockClaims.height,
            string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_INCORRECT_BLOCK_HEIGHT))
        );

        require(
            blockClaims.chainId == _chainId,
            string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_INCORRECT_CHAIN_ID))
        );

        bool isSafeToProceedConsensus = true;
        if (IValidatorPool(_validatorPoolAddress()).isMaintenanceScheduled()) {
            isSafeToProceedConsensus = false;
            IValidatorPool(_validatorPoolAddress()).pauseConsensus();
        }

        _snapshots[epoch] = Snapshot(block.number, blockClaims);
        _epoch = epoch;

        emit SnapshotTaken(
            _chainId,
            epoch,
            blockClaims.height,
            msg.sender,
            isSafeToProceedConsensus,
            groupSignature_
        );
        return isSafeToProceedConsensus;
    }

    /// @notice Saves next snapshot
    /// @param groupSignature_ The group signature used to sign the snapshots' block claims
    /// @param bClaims_ The claims being made about given block
    /// @return Flag whether we should kick off another round of key generation
    function migrateSnapshots(bytes[] memory groupSignature_, bytes[] memory bClaims_)
        public
        onlyFactory
        returns (bool)
    {
        {
            require(
                _epoch == 0,
                string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_MIGRATION_NOT_ALLOWED))
            );
            require(
                groupSignature_.length == bClaims_.length && groupSignature_.length >= 1,
                string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_MIGRATION_INPUT_DATA_MISMATCH))
            );
        }

        uint256 epoch;
        for (uint256 i = 0; i < bClaims_.length; i++) {
            BClaimsParserLibrary.BClaims memory blockClaims = BClaimsParserLibrary.extractBClaims(
                bClaims_[i]
            );
            require(
                blockClaims.height % _epochLength == 0,
                string(abi.encodePacked(SnapshotsErrorCodes.SNAPSHOT_INCORRECT_BLOCK_HEIGHT))
            );
            epoch = getEpochFromHeight(blockClaims.height);
            _snapshots[epoch] = Snapshot(block.number, blockClaims);
            emit SnapshotTaken(
                _chainId,
                epoch,
                blockClaims.height,
                msg.sender,
                true,
                groupSignature_[i]
            );
        }
        _epoch = uint32(epoch);
        return true;
    }

    function getSnapshotDesperationFactor() public view returns (uint256) {
        return _snapshotDesperationFactor;
    }

    function getSnapshotDesperationDelay() public view returns (uint256) {
        return _snapshotDesperationDelay;
    }

    function getMinimumIntervalBetweenSnapshots() public view returns (uint256) {
        return _minimumIntervalBetweenSnapshots;
    }

    function getChainId() public view returns (uint256) {
        return _chainId;
    }

    function getEpoch() public view returns (uint256) {
        return _epoch;
    }

    function getEpochLength() public view returns (uint256) {
        return _epochLength;
    }

    function getChainIdFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].blockClaims.chainId;
    }

    function getChainIdFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].blockClaims.chainId;
    }

    function getBlockClaimsFromSnapshot(uint256 epoch_)
        public
        view
        returns (BClaimsParserLibrary.BClaims memory)
    {
        return _snapshots[epoch_].blockClaims;
    }

    function getBlockClaimsFromLatestSnapshot()
        public
        view
        returns (BClaimsParserLibrary.BClaims memory)
    {
        return _snapshots[_epoch].blockClaims;
    }

    function getCommittedHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].committedAt;
    }

    function getCommittedHeightFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].committedAt;
    }

    function getAliceNetHeightFromSnapshot(uint256 epoch_) public view returns (uint256) {
        return _snapshots[epoch_].blockClaims.height;
    }

    function getAliceNetHeightFromLatestSnapshot() public view returns (uint256) {
        return _snapshots[_epoch].blockClaims.height;
    }

    function getSnapshot(uint256 epoch_) public view returns (Snapshot memory) {
        return _snapshots[epoch_];
    }

    function getLatestSnapshot() public view returns (Snapshot memory) {
        return _snapshots[_epoch];
    }

    function getEpochFromHeight(uint256 height) public view returns (uint256) {
        if (height <= _epochLength) {
            return 1;
        }
        if (height % _epochLength == 0) {
            return height / _epochLength;
        }
        return (height / _epochLength) + 1;
    }

    function mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 blsig,
        uint256 desperationFactor
    ) public pure returns (bool) {
        return
            _mayValidatorSnapshot(
                numValidators,
                myIdx,
                blocksSinceDesperation,
                blsig,
                desperationFactor
            );
    }

    function _mayValidatorSnapshot(
        uint256 numValidators,
        uint256 myIdx,
        uint256 blocksSinceDesperation,
        bytes32 blsig,
        uint256 desperationFactor
    ) internal pure returns (bool) {
        uint256 numValidatorsAllowed = 1;

        uint256 desperation = 0;
        while (desperation < blocksSinceDesperation && numValidatorsAllowed <= numValidators / 3) {
            desperation += desperationFactor / numValidatorsAllowed;
            numValidatorsAllowed++;
        }

        uint256 rand = uint256(blsig);
        uint256 start = (rand % numValidators);
        uint256 end = (start + numValidatorsAllowed) % numValidators;

        if (end > start) {
            return myIdx >= start && myIdx < end;
        } else {
            return myIdx >= start || myIdx < end;
        }
    }
}