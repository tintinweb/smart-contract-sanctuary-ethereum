// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

type CalldataPointer is uint256;

type ReturndataPointer is uint256;

type MemoryPointer is uint256;

using CalldataPointerLib for CalldataPointer global;
using MemoryPointerLib for MemoryPointer global;
using ReturndataPointerLib for ReturndataPointer global;

using CalldataReaders for CalldataPointer global;
using ReturndataReaders for ReturndataPointer global;
using MemoryReaders for MemoryPointer global;
using MemoryWriters for MemoryPointer global;

CalldataPointer constant CalldataStart = CalldataPointer.wrap(0x04);
MemoryPointer constant FreeMemoryPPtr = MemoryPointer.wrap(0x40);
uint256 constant IdentityPrecompileAddress = 0x4;
uint256 constant OffsetOrLengthMask = 0xffffffff;
uint256 constant _OneWord = 0x20;
uint256 constant _FreeMemoryPointerSlot = 0x40;

/// @dev Allocates `size` bytes in memory by increasing the free memory pointer
///    and returns the memory pointer to the first byte of the allocated region.
// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function malloc(uint256 size) pure returns (MemoryPointer mPtr) {
    assembly {
        mPtr := mload(_FreeMemoryPointerSlot)
        mstore(_FreeMemoryPointerSlot, add(mPtr, size))
    }
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function getFreeMemoryPointer() pure returns (MemoryPointer mPtr) {
    mPtr = FreeMemoryPPtr.readMemoryPointer();
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function setFreeMemoryPointer(MemoryPointer mPtr) pure {
    FreeMemoryPPtr.write(mPtr);
}

library CalldataPointerLib {
    function lt(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    /// @dev Resolves an offset stored at `cdPtr + headOffset` to a calldata.
    ///      pointer `cdPtr` must point to some parent object with a dynamic
    ///      type's head stored at `cdPtr + headOffset`.
    function pptr(
        CalldataPointer cdPtr,
        uint256 headOffset
    ) internal pure returns (CalldataPointer cdPtrChild) {
        cdPtrChild = cdPtr.offset(
            cdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
        );
    }

    /// @dev Resolves an offset stored at `cdPtr` to a calldata pointer.
    ///      `cdPtr` must point to some parent object with a dynamic type as its
    ///      first member, e.g. `struct { bytes data; }`
    function pptr(
        CalldataPointer cdPtr
    ) internal pure returns (CalldataPointer cdPtrChild) {
        cdPtrChild = cdPtr.offset(cdPtr.readUint256() & OffsetOrLengthMask);
    }

    /// @dev Returns the calldata pointer one word after `cdPtr`.
    function next(
        CalldataPointer cdPtr
    ) internal pure returns (CalldataPointer cdPtrNext) {
        assembly {
            cdPtrNext := add(cdPtr, _OneWord)
        }
    }

    /// @dev Returns the calldata pointer `_offset` bytes after `cdPtr`.
    function offset(
        CalldataPointer cdPtr,
        uint256 _offset
    ) internal pure returns (CalldataPointer cdPtrNext) {
        assembly {
            cdPtrNext := add(cdPtr, _offset)
        }
    }

    /// @dev Copies `size` bytes from calldata starting at `src` to memory at
    ///      `dst`.
    function copy(
        CalldataPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal pure {
        assembly {
            calldatacopy(dst, src, size)
        }
    }
}

library ReturndataPointerLib {
    function lt(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    /// @dev Resolves an offset stored at `rdPtr + headOffset` to a returndata
    ///      pointer. `rdPtr` must point to some parent object with a dynamic
    ///      type's head stored at `rdPtr + headOffset`.
    function pptr(
        ReturndataPointer rdPtr,
        uint256 headOffset
    ) internal pure returns (ReturndataPointer rdPtrChild) {
        rdPtrChild = rdPtr.offset(
            rdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
        );
    }

    /// @dev Resolves an offset stored at `rdPtr` to a returndata pointer.
    ///    `rdPtr` must point to some parent object with a dynamic type as its
    ///    first member, e.g. `struct { bytes data; }`
    function pptr(
        ReturndataPointer rdPtr
    ) internal pure returns (ReturndataPointer rdPtrChild) {
        rdPtrChild = rdPtr.offset(rdPtr.readUint256() & OffsetOrLengthMask);
    }

    /// @dev Returns the returndata pointer one word after `cdPtr`.
    function next(
        ReturndataPointer rdPtr
    ) internal pure returns (ReturndataPointer rdPtrNext) {
        assembly {
            rdPtrNext := add(rdPtr, _OneWord)
        }
    }

    /// @dev Returns the returndata pointer `_offset` bytes after `cdPtr`.
    function offset(
        ReturndataPointer rdPtr,
        uint256 _offset
    ) internal pure returns (ReturndataPointer rdPtrNext) {
        assembly {
            rdPtrNext := add(rdPtr, _offset)
        }
    }

    /// @dev Copies `size` bytes from returndata starting at `src` to memory at
    /// `dst`.
    function copy(
        ReturndataPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal pure {
        assembly {
            returndatacopy(dst, src, size)
        }
    }
}

library MemoryPointerLib {
    function copy(
        MemoryPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal view {
        assembly {
            let success := staticcall(
                gas(),
                IdentityPrecompileAddress,
                src,
                size,
                dst,
                size
            )
            if or(iszero(returndatasize()), iszero(success)) {
                revert(0, 0)
            }
        }
    }

    function lt(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    /// @dev Returns the memory pointer one word after `mPtr`.
    function next(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer mPtrNext) {
        assembly {
            mPtrNext := add(mPtr, _OneWord)
        }
    }

    /// @dev Returns the memory pointer `_offset` bytes after `mPtr`.
    function offset(
        MemoryPointer mPtr,
        uint256 _offset
    ) internal pure returns (MemoryPointer mPtrNext) {
        assembly {
            mPtrNext := add(mPtr, _offset)
        }
    }

    /// @dev Resolves a pointer pointer at `mPtr + headOffset` to a memory
    ///    pointer. `mPtr` must point to some parent object with a dynamic
    ///    type's pointer stored at `mPtr + headOffset`.
    function pptr(
        MemoryPointer mPtr,
        uint256 headOffset
    ) internal pure returns (MemoryPointer mPtrChild) {
        mPtrChild = mPtr.offset(headOffset).readMemoryPointer();
    }

    /// @dev Resolves a pointer pointer stored at `mPtr` to a memory pointer.
    ///    `mPtr` must point to some parent object with a dynamic type as its
    ///    first member, e.g. `struct { bytes data; }`
    function pptr(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer mPtrChild) {
        mPtrChild = mPtr.readMemoryPointer();
    }
}

library CalldataReaders {
    /// @dev Reads the value at `cdPtr` and applies a mask to return only the
    ///    last 4 bytes.
    function readMaskedUint256(
        CalldataPointer cdPtr
    ) internal pure returns (uint256 value) {
        value = cdPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `cdPtr` in calldata.
    function readBool(
        CalldataPointer cdPtr
    ) internal pure returns (bool value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the address at `cdPtr` in calldata.
    function readAddress(
        CalldataPointer cdPtr
    ) internal pure returns (address value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes1 at `cdPtr` in calldata.
    function readBytes1(
        CalldataPointer cdPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes2 at `cdPtr` in calldata.
    function readBytes2(
        CalldataPointer cdPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes3 at `cdPtr` in calldata.
    function readBytes3(
        CalldataPointer cdPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes4 at `cdPtr` in calldata.
    function readBytes4(
        CalldataPointer cdPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes5 at `cdPtr` in calldata.
    function readBytes5(
        CalldataPointer cdPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes6 at `cdPtr` in calldata.
    function readBytes6(
        CalldataPointer cdPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes7 at `cdPtr` in calldata.
    function readBytes7(
        CalldataPointer cdPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes8 at `cdPtr` in calldata.
    function readBytes8(
        CalldataPointer cdPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes9 at `cdPtr` in calldata.
    function readBytes9(
        CalldataPointer cdPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes10 at `cdPtr` in calldata.
    function readBytes10(
        CalldataPointer cdPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes11 at `cdPtr` in calldata.
    function readBytes11(
        CalldataPointer cdPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes12 at `cdPtr` in calldata.
    function readBytes12(
        CalldataPointer cdPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes13 at `cdPtr` in calldata.
    function readBytes13(
        CalldataPointer cdPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes14 at `cdPtr` in calldata.
    function readBytes14(
        CalldataPointer cdPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes15 at `cdPtr` in calldata.
    function readBytes15(
        CalldataPointer cdPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes16 at `cdPtr` in calldata.
    function readBytes16(
        CalldataPointer cdPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes17 at `cdPtr` in calldata.
    function readBytes17(
        CalldataPointer cdPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes18 at `cdPtr` in calldata.
    function readBytes18(
        CalldataPointer cdPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes19 at `cdPtr` in calldata.
    function readBytes19(
        CalldataPointer cdPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes20 at `cdPtr` in calldata.
    function readBytes20(
        CalldataPointer cdPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes21 at `cdPtr` in calldata.
    function readBytes21(
        CalldataPointer cdPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes22 at `cdPtr` in calldata.
    function readBytes22(
        CalldataPointer cdPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes23 at `cdPtr` in calldata.
    function readBytes23(
        CalldataPointer cdPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes24 at `cdPtr` in calldata.
    function readBytes24(
        CalldataPointer cdPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes25 at `cdPtr` in calldata.
    function readBytes25(
        CalldataPointer cdPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes26 at `cdPtr` in calldata.
    function readBytes26(
        CalldataPointer cdPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes27 at `cdPtr` in calldata.
    function readBytes27(
        CalldataPointer cdPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes28 at `cdPtr` in calldata.
    function readBytes28(
        CalldataPointer cdPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes29 at `cdPtr` in calldata.
    function readBytes29(
        CalldataPointer cdPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes30 at `cdPtr` in calldata.
    function readBytes30(
        CalldataPointer cdPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes31 at `cdPtr` in calldata.
    function readBytes31(
        CalldataPointer cdPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes32 at `cdPtr` in calldata.
    function readBytes32(
        CalldataPointer cdPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint8 at `cdPtr` in calldata.
    function readUint8(
        CalldataPointer cdPtr
    ) internal pure returns (uint8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint16 at `cdPtr` in calldata.
    function readUint16(
        CalldataPointer cdPtr
    ) internal pure returns (uint16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint24 at `cdPtr` in calldata.
    function readUint24(
        CalldataPointer cdPtr
    ) internal pure returns (uint24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint32 at `cdPtr` in calldata.
    function readUint32(
        CalldataPointer cdPtr
    ) internal pure returns (uint32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint40 at `cdPtr` in calldata.
    function readUint40(
        CalldataPointer cdPtr
    ) internal pure returns (uint40 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint48 at `cdPtr` in calldata.
    function readUint48(
        CalldataPointer cdPtr
    ) internal pure returns (uint48 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint56 at `cdPtr` in calldata.
    function readUint56(
        CalldataPointer cdPtr
    ) internal pure returns (uint56 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint64 at `cdPtr` in calldata.
    function readUint64(
        CalldataPointer cdPtr
    ) internal pure returns (uint64 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint72 at `cdPtr` in calldata.
    function readUint72(
        CalldataPointer cdPtr
    ) internal pure returns (uint72 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint80 at `cdPtr` in calldata.
    function readUint80(
        CalldataPointer cdPtr
    ) internal pure returns (uint80 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint88 at `cdPtr` in calldata.
    function readUint88(
        CalldataPointer cdPtr
    ) internal pure returns (uint88 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint96 at `cdPtr` in calldata.
    function readUint96(
        CalldataPointer cdPtr
    ) internal pure returns (uint96 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint104 at `cdPtr` in calldata.
    function readUint104(
        CalldataPointer cdPtr
    ) internal pure returns (uint104 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint112 at `cdPtr` in calldata.
    function readUint112(
        CalldataPointer cdPtr
    ) internal pure returns (uint112 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint120 at `cdPtr` in calldata.
    function readUint120(
        CalldataPointer cdPtr
    ) internal pure returns (uint120 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint128 at `cdPtr` in calldata.
    function readUint128(
        CalldataPointer cdPtr
    ) internal pure returns (uint128 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint136 at `cdPtr` in calldata.
    function readUint136(
        CalldataPointer cdPtr
    ) internal pure returns (uint136 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint144 at `cdPtr` in calldata.
    function readUint144(
        CalldataPointer cdPtr
    ) internal pure returns (uint144 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint152 at `cdPtr` in calldata.
    function readUint152(
        CalldataPointer cdPtr
    ) internal pure returns (uint152 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint160 at `cdPtr` in calldata.
    function readUint160(
        CalldataPointer cdPtr
    ) internal pure returns (uint160 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint168 at `cdPtr` in calldata.
    function readUint168(
        CalldataPointer cdPtr
    ) internal pure returns (uint168 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint176 at `cdPtr` in calldata.
    function readUint176(
        CalldataPointer cdPtr
    ) internal pure returns (uint176 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint184 at `cdPtr` in calldata.
    function readUint184(
        CalldataPointer cdPtr
    ) internal pure returns (uint184 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint192 at `cdPtr` in calldata.
    function readUint192(
        CalldataPointer cdPtr
    ) internal pure returns (uint192 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint200 at `cdPtr` in calldata.
    function readUint200(
        CalldataPointer cdPtr
    ) internal pure returns (uint200 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint208 at `cdPtr` in calldata.
    function readUint208(
        CalldataPointer cdPtr
    ) internal pure returns (uint208 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint216 at `cdPtr` in calldata.
    function readUint216(
        CalldataPointer cdPtr
    ) internal pure returns (uint216 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint224 at `cdPtr` in calldata.
    function readUint224(
        CalldataPointer cdPtr
    ) internal pure returns (uint224 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint232 at `cdPtr` in calldata.
    function readUint232(
        CalldataPointer cdPtr
    ) internal pure returns (uint232 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint240 at `cdPtr` in calldata.
    function readUint240(
        CalldataPointer cdPtr
    ) internal pure returns (uint240 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint248 at `cdPtr` in calldata.
    function readUint248(
        CalldataPointer cdPtr
    ) internal pure returns (uint248 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint256 at `cdPtr` in calldata.
    function readUint256(
        CalldataPointer cdPtr
    ) internal pure returns (uint256 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int8 at `cdPtr` in calldata.
    function readInt8(
        CalldataPointer cdPtr
    ) internal pure returns (int8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int16 at `cdPtr` in calldata.
    function readInt16(
        CalldataPointer cdPtr
    ) internal pure returns (int16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int24 at `cdPtr` in calldata.
    function readInt24(
        CalldataPointer cdPtr
    ) internal pure returns (int24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int32 at `cdPtr` in calldata.
    function readInt32(
        CalldataPointer cdPtr
    ) internal pure returns (int32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int40 at `cdPtr` in calldata.
    function readInt40(
        CalldataPointer cdPtr
    ) internal pure returns (int40 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int48 at `cdPtr` in calldata.
    function readInt48(
        CalldataPointer cdPtr
    ) internal pure returns (int48 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int56 at `cdPtr` in calldata.
    function readInt56(
        CalldataPointer cdPtr
    ) internal pure returns (int56 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int64 at `cdPtr` in calldata.
    function readInt64(
        CalldataPointer cdPtr
    ) internal pure returns (int64 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int72 at `cdPtr` in calldata.
    function readInt72(
        CalldataPointer cdPtr
    ) internal pure returns (int72 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int80 at `cdPtr` in calldata.
    function readInt80(
        CalldataPointer cdPtr
    ) internal pure returns (int80 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int88 at `cdPtr` in calldata.
    function readInt88(
        CalldataPointer cdPtr
    ) internal pure returns (int88 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int96 at `cdPtr` in calldata.
    function readInt96(
        CalldataPointer cdPtr
    ) internal pure returns (int96 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int104 at `cdPtr` in calldata.
    function readInt104(
        CalldataPointer cdPtr
    ) internal pure returns (int104 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int112 at `cdPtr` in calldata.
    function readInt112(
        CalldataPointer cdPtr
    ) internal pure returns (int112 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int120 at `cdPtr` in calldata.
    function readInt120(
        CalldataPointer cdPtr
    ) internal pure returns (int120 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int128 at `cdPtr` in calldata.
    function readInt128(
        CalldataPointer cdPtr
    ) internal pure returns (int128 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int136 at `cdPtr` in calldata.
    function readInt136(
        CalldataPointer cdPtr
    ) internal pure returns (int136 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int144 at `cdPtr` in calldata.
    function readInt144(
        CalldataPointer cdPtr
    ) internal pure returns (int144 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int152 at `cdPtr` in calldata.
    function readInt152(
        CalldataPointer cdPtr
    ) internal pure returns (int152 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int160 at `cdPtr` in calldata.
    function readInt160(
        CalldataPointer cdPtr
    ) internal pure returns (int160 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int168 at `cdPtr` in calldata.
    function readInt168(
        CalldataPointer cdPtr
    ) internal pure returns (int168 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int176 at `cdPtr` in calldata.
    function readInt176(
        CalldataPointer cdPtr
    ) internal pure returns (int176 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int184 at `cdPtr` in calldata.
    function readInt184(
        CalldataPointer cdPtr
    ) internal pure returns (int184 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int192 at `cdPtr` in calldata.
    function readInt192(
        CalldataPointer cdPtr
    ) internal pure returns (int192 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int200 at `cdPtr` in calldata.
    function readInt200(
        CalldataPointer cdPtr
    ) internal pure returns (int200 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int208 at `cdPtr` in calldata.
    function readInt208(
        CalldataPointer cdPtr
    ) internal pure returns (int208 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int216 at `cdPtr` in calldata.
    function readInt216(
        CalldataPointer cdPtr
    ) internal pure returns (int216 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int224 at `cdPtr` in calldata.
    function readInt224(
        CalldataPointer cdPtr
    ) internal pure returns (int224 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int232 at `cdPtr` in calldata.
    function readInt232(
        CalldataPointer cdPtr
    ) internal pure returns (int232 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int240 at `cdPtr` in calldata.
    function readInt240(
        CalldataPointer cdPtr
    ) internal pure returns (int240 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int248 at `cdPtr` in calldata.
    function readInt248(
        CalldataPointer cdPtr
    ) internal pure returns (int248 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int256 at `cdPtr` in calldata.
    function readInt256(
        CalldataPointer cdPtr
    ) internal pure returns (int256 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }
}

library ReturndataReaders {
    /// @dev Reads value at `rdPtr` & applies a mask to return only last 4 bytes
    function readMaskedUint256(
        ReturndataPointer rdPtr
    ) internal pure returns (uint256 value) {
        value = rdPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `rdPtr` in returndata.
    function readBool(
        ReturndataPointer rdPtr
    ) internal pure returns (bool value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the address at `rdPtr` in returndata.
    function readAddress(
        ReturndataPointer rdPtr
    ) internal pure returns (address value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes1 at `rdPtr` in returndata.
    function readBytes1(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes2 at `rdPtr` in returndata.
    function readBytes2(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes3 at `rdPtr` in returndata.
    function readBytes3(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes4 at `rdPtr` in returndata.
    function readBytes4(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes5 at `rdPtr` in returndata.
    function readBytes5(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes6 at `rdPtr` in returndata.
    function readBytes6(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes7 at `rdPtr` in returndata.
    function readBytes7(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes8 at `rdPtr` in returndata.
    function readBytes8(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes9 at `rdPtr` in returndata.
    function readBytes9(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes10 at `rdPtr` in returndata.
    function readBytes10(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes11 at `rdPtr` in returndata.
    function readBytes11(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes12 at `rdPtr` in returndata.
    function readBytes12(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes13 at `rdPtr` in returndata.
    function readBytes13(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes14 at `rdPtr` in returndata.
    function readBytes14(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes15 at `rdPtr` in returndata.
    function readBytes15(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes16 at `rdPtr` in returndata.
    function readBytes16(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes17 at `rdPtr` in returndata.
    function readBytes17(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes18 at `rdPtr` in returndata.
    function readBytes18(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes19 at `rdPtr` in returndata.
    function readBytes19(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes20 at `rdPtr` in returndata.
    function readBytes20(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes21 at `rdPtr` in returndata.
    function readBytes21(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes22 at `rdPtr` in returndata.
    function readBytes22(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes23 at `rdPtr` in returndata.
    function readBytes23(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes24 at `rdPtr` in returndata.
    function readBytes24(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes25 at `rdPtr` in returndata.
    function readBytes25(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes26 at `rdPtr` in returndata.
    function readBytes26(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes27 at `rdPtr` in returndata.
    function readBytes27(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes28 at `rdPtr` in returndata.
    function readBytes28(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes29 at `rdPtr` in returndata.
    function readBytes29(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes30 at `rdPtr` in returndata.
    function readBytes30(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes31 at `rdPtr` in returndata.
    function readBytes31(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes32 at `rdPtr` in returndata.
    function readBytes32(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint8 at `rdPtr` in returndata.
    function readUint8(
        ReturndataPointer rdPtr
    ) internal pure returns (uint8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint16 at `rdPtr` in returndata.
    function readUint16(
        ReturndataPointer rdPtr
    ) internal pure returns (uint16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint24 at `rdPtr` in returndata.
    function readUint24(
        ReturndataPointer rdPtr
    ) internal pure returns (uint24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint32 at `rdPtr` in returndata.
    function readUint32(
        ReturndataPointer rdPtr
    ) internal pure returns (uint32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint40 at `rdPtr` in returndata.
    function readUint40(
        ReturndataPointer rdPtr
    ) internal pure returns (uint40 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint48 at `rdPtr` in returndata.
    function readUint48(
        ReturndataPointer rdPtr
    ) internal pure returns (uint48 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint56 at `rdPtr` in returndata.
    function readUint56(
        ReturndataPointer rdPtr
    ) internal pure returns (uint56 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint64 at `rdPtr` in returndata.
    function readUint64(
        ReturndataPointer rdPtr
    ) internal pure returns (uint64 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint72 at `rdPtr` in returndata.
    function readUint72(
        ReturndataPointer rdPtr
    ) internal pure returns (uint72 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint80 at `rdPtr` in returndata.
    function readUint80(
        ReturndataPointer rdPtr
    ) internal pure returns (uint80 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint88 at `rdPtr` in returndata.
    function readUint88(
        ReturndataPointer rdPtr
    ) internal pure returns (uint88 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint96 at `rdPtr` in returndata.
    function readUint96(
        ReturndataPointer rdPtr
    ) internal pure returns (uint96 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint104 at `rdPtr` in returndata.
    function readUint104(
        ReturndataPointer rdPtr
    ) internal pure returns (uint104 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint112 at `rdPtr` in returndata.
    function readUint112(
        ReturndataPointer rdPtr
    ) internal pure returns (uint112 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint120 at `rdPtr` in returndata.
    function readUint120(
        ReturndataPointer rdPtr
    ) internal pure returns (uint120 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint128 at `rdPtr` in returndata.
    function readUint128(
        ReturndataPointer rdPtr
    ) internal pure returns (uint128 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint136 at `rdPtr` in returndata.
    function readUint136(
        ReturndataPointer rdPtr
    ) internal pure returns (uint136 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint144 at `rdPtr` in returndata.
    function readUint144(
        ReturndataPointer rdPtr
    ) internal pure returns (uint144 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint152 at `rdPtr` in returndata.
    function readUint152(
        ReturndataPointer rdPtr
    ) internal pure returns (uint152 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint160 at `rdPtr` in returndata.
    function readUint160(
        ReturndataPointer rdPtr
    ) internal pure returns (uint160 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint168 at `rdPtr` in returndata.
    function readUint168(
        ReturndataPointer rdPtr
    ) internal pure returns (uint168 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint176 at `rdPtr` in returndata.
    function readUint176(
        ReturndataPointer rdPtr
    ) internal pure returns (uint176 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint184 at `rdPtr` in returndata.
    function readUint184(
        ReturndataPointer rdPtr
    ) internal pure returns (uint184 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint192 at `rdPtr` in returndata.
    function readUint192(
        ReturndataPointer rdPtr
    ) internal pure returns (uint192 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint200 at `rdPtr` in returndata.
    function readUint200(
        ReturndataPointer rdPtr
    ) internal pure returns (uint200 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint208 at `rdPtr` in returndata.
    function readUint208(
        ReturndataPointer rdPtr
    ) internal pure returns (uint208 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint216 at `rdPtr` in returndata.
    function readUint216(
        ReturndataPointer rdPtr
    ) internal pure returns (uint216 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint224 at `rdPtr` in returndata.
    function readUint224(
        ReturndataPointer rdPtr
    ) internal pure returns (uint224 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint232 at `rdPtr` in returndata.
    function readUint232(
        ReturndataPointer rdPtr
    ) internal pure returns (uint232 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint240 at `rdPtr` in returndata.
    function readUint240(
        ReturndataPointer rdPtr
    ) internal pure returns (uint240 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint248 at `rdPtr` in returndata.
    function readUint248(
        ReturndataPointer rdPtr
    ) internal pure returns (uint248 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint256 at `rdPtr` in returndata.
    function readUint256(
        ReturndataPointer rdPtr
    ) internal pure returns (uint256 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int8 at `rdPtr` in returndata.
    function readInt8(
        ReturndataPointer rdPtr
    ) internal pure returns (int8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int16 at `rdPtr` in returndata.
    function readInt16(
        ReturndataPointer rdPtr
    ) internal pure returns (int16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int24 at `rdPtr` in returndata.
    function readInt24(
        ReturndataPointer rdPtr
    ) internal pure returns (int24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int32 at `rdPtr` in returndata.
    function readInt32(
        ReturndataPointer rdPtr
    ) internal pure returns (int32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int40 at `rdPtr` in returndata.
    function readInt40(
        ReturndataPointer rdPtr
    ) internal pure returns (int40 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int48 at `rdPtr` in returndata.
    function readInt48(
        ReturndataPointer rdPtr
    ) internal pure returns (int48 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int56 at `rdPtr` in returndata.
    function readInt56(
        ReturndataPointer rdPtr
    ) internal pure returns (int56 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int64 at `rdPtr` in returndata.
    function readInt64(
        ReturndataPointer rdPtr
    ) internal pure returns (int64 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int72 at `rdPtr` in returndata.
    function readInt72(
        ReturndataPointer rdPtr
    ) internal pure returns (int72 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int80 at `rdPtr` in returndata.
    function readInt80(
        ReturndataPointer rdPtr
    ) internal pure returns (int80 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int88 at `rdPtr` in returndata.
    function readInt88(
        ReturndataPointer rdPtr
    ) internal pure returns (int88 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int96 at `rdPtr` in returndata.
    function readInt96(
        ReturndataPointer rdPtr
    ) internal pure returns (int96 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int104 at `rdPtr` in returndata.
    function readInt104(
        ReturndataPointer rdPtr
    ) internal pure returns (int104 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int112 at `rdPtr` in returndata.
    function readInt112(
        ReturndataPointer rdPtr
    ) internal pure returns (int112 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int120 at `rdPtr` in returndata.
    function readInt120(
        ReturndataPointer rdPtr
    ) internal pure returns (int120 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int128 at `rdPtr` in returndata.
    function readInt128(
        ReturndataPointer rdPtr
    ) internal pure returns (int128 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int136 at `rdPtr` in returndata.
    function readInt136(
        ReturndataPointer rdPtr
    ) internal pure returns (int136 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int144 at `rdPtr` in returndata.
    function readInt144(
        ReturndataPointer rdPtr
    ) internal pure returns (int144 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int152 at `rdPtr` in returndata.
    function readInt152(
        ReturndataPointer rdPtr
    ) internal pure returns (int152 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int160 at `rdPtr` in returndata.
    function readInt160(
        ReturndataPointer rdPtr
    ) internal pure returns (int160 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int168 at `rdPtr` in returndata.
    function readInt168(
        ReturndataPointer rdPtr
    ) internal pure returns (int168 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int176 at `rdPtr` in returndata.
    function readInt176(
        ReturndataPointer rdPtr
    ) internal pure returns (int176 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int184 at `rdPtr` in returndata.
    function readInt184(
        ReturndataPointer rdPtr
    ) internal pure returns (int184 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int192 at `rdPtr` in returndata.
    function readInt192(
        ReturndataPointer rdPtr
    ) internal pure returns (int192 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int200 at `rdPtr` in returndata.
    function readInt200(
        ReturndataPointer rdPtr
    ) internal pure returns (int200 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int208 at `rdPtr` in returndata.
    function readInt208(
        ReturndataPointer rdPtr
    ) internal pure returns (int208 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int216 at `rdPtr` in returndata.
    function readInt216(
        ReturndataPointer rdPtr
    ) internal pure returns (int216 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int224 at `rdPtr` in returndata.
    function readInt224(
        ReturndataPointer rdPtr
    ) internal pure returns (int224 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int232 at `rdPtr` in returndata.
    function readInt232(
        ReturndataPointer rdPtr
    ) internal pure returns (int232 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int240 at `rdPtr` in returndata.
    function readInt240(
        ReturndataPointer rdPtr
    ) internal pure returns (int240 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int248 at `rdPtr` in returndata.
    function readInt248(
        ReturndataPointer rdPtr
    ) internal pure returns (int248 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int256 at `rdPtr` in returndata.
    function readInt256(
        ReturndataPointer rdPtr
    ) internal pure returns (int256 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }
}

library MemoryReaders {
    /// @dev Reads the memory pointer at `mPtr` in memory.
    function readMemoryPointer(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads value at `mPtr` & applies a mask to return only last 4 bytes
    function readMaskedUint256(
        MemoryPointer mPtr
    ) internal pure returns (uint256 value) {
        value = mPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `mPtr` in memory.
    function readBool(MemoryPointer mPtr) internal pure returns (bool value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the address at `mPtr` in memory.
    function readAddress(
        MemoryPointer mPtr
    ) internal pure returns (address value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes1 at `mPtr` in memory.
    function readBytes1(
        MemoryPointer mPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes2 at `mPtr` in memory.
    function readBytes2(
        MemoryPointer mPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes3 at `mPtr` in memory.
    function readBytes3(
        MemoryPointer mPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes4 at `mPtr` in memory.
    function readBytes4(
        MemoryPointer mPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes5 at `mPtr` in memory.
    function readBytes5(
        MemoryPointer mPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes6 at `mPtr` in memory.
    function readBytes6(
        MemoryPointer mPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes7 at `mPtr` in memory.
    function readBytes7(
        MemoryPointer mPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes8 at `mPtr` in memory.
    function readBytes8(
        MemoryPointer mPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes9 at `mPtr` in memory.
    function readBytes9(
        MemoryPointer mPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes10 at `mPtr` in memory.
    function readBytes10(
        MemoryPointer mPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes11 at `mPtr` in memory.
    function readBytes11(
        MemoryPointer mPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes12 at `mPtr` in memory.
    function readBytes12(
        MemoryPointer mPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes13 at `mPtr` in memory.
    function readBytes13(
        MemoryPointer mPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes14 at `mPtr` in memory.
    function readBytes14(
        MemoryPointer mPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes15 at `mPtr` in memory.
    function readBytes15(
        MemoryPointer mPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes16 at `mPtr` in memory.
    function readBytes16(
        MemoryPointer mPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes17 at `mPtr` in memory.
    function readBytes17(
        MemoryPointer mPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes18 at `mPtr` in memory.
    function readBytes18(
        MemoryPointer mPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes19 at `mPtr` in memory.
    function readBytes19(
        MemoryPointer mPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes20 at `mPtr` in memory.
    function readBytes20(
        MemoryPointer mPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes21 at `mPtr` in memory.
    function readBytes21(
        MemoryPointer mPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes22 at `mPtr` in memory.
    function readBytes22(
        MemoryPointer mPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes23 at `mPtr` in memory.
    function readBytes23(
        MemoryPointer mPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes24 at `mPtr` in memory.
    function readBytes24(
        MemoryPointer mPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes25 at `mPtr` in memory.
    function readBytes25(
        MemoryPointer mPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes26 at `mPtr` in memory.
    function readBytes26(
        MemoryPointer mPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes27 at `mPtr` in memory.
    function readBytes27(
        MemoryPointer mPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes28 at `mPtr` in memory.
    function readBytes28(
        MemoryPointer mPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes29 at `mPtr` in memory.
    function readBytes29(
        MemoryPointer mPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes30 at `mPtr` in memory.
    function readBytes30(
        MemoryPointer mPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes31 at `mPtr` in memory.
    function readBytes31(
        MemoryPointer mPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes32 at `mPtr` in memory.
    function readBytes32(
        MemoryPointer mPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint8 at `mPtr` in memory.
    function readUint8(MemoryPointer mPtr) internal pure returns (uint8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint16 at `mPtr` in memory.
    function readUint16(
        MemoryPointer mPtr
    ) internal pure returns (uint16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint24 at `mPtr` in memory.
    function readUint24(
        MemoryPointer mPtr
    ) internal pure returns (uint24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint32 at `mPtr` in memory.
    function readUint32(
        MemoryPointer mPtr
    ) internal pure returns (uint32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint40 at `mPtr` in memory.
    function readUint40(
        MemoryPointer mPtr
    ) internal pure returns (uint40 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint48 at `mPtr` in memory.
    function readUint48(
        MemoryPointer mPtr
    ) internal pure returns (uint48 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint56 at `mPtr` in memory.
    function readUint56(
        MemoryPointer mPtr
    ) internal pure returns (uint56 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint64 at `mPtr` in memory.
    function readUint64(
        MemoryPointer mPtr
    ) internal pure returns (uint64 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint72 at `mPtr` in memory.
    function readUint72(
        MemoryPointer mPtr
    ) internal pure returns (uint72 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint80 at `mPtr` in memory.
    function readUint80(
        MemoryPointer mPtr
    ) internal pure returns (uint80 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint88 at `mPtr` in memory.
    function readUint88(
        MemoryPointer mPtr
    ) internal pure returns (uint88 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint96 at `mPtr` in memory.
    function readUint96(
        MemoryPointer mPtr
    ) internal pure returns (uint96 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint104 at `mPtr` in memory.
    function readUint104(
        MemoryPointer mPtr
    ) internal pure returns (uint104 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint112 at `mPtr` in memory.
    function readUint112(
        MemoryPointer mPtr
    ) internal pure returns (uint112 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint120 at `mPtr` in memory.
    function readUint120(
        MemoryPointer mPtr
    ) internal pure returns (uint120 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint128 at `mPtr` in memory.
    function readUint128(
        MemoryPointer mPtr
    ) internal pure returns (uint128 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint136 at `mPtr` in memory.
    function readUint136(
        MemoryPointer mPtr
    ) internal pure returns (uint136 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint144 at `mPtr` in memory.
    function readUint144(
        MemoryPointer mPtr
    ) internal pure returns (uint144 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint152 at `mPtr` in memory.
    function readUint152(
        MemoryPointer mPtr
    ) internal pure returns (uint152 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint160 at `mPtr` in memory.
    function readUint160(
        MemoryPointer mPtr
    ) internal pure returns (uint160 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint168 at `mPtr` in memory.
    function readUint168(
        MemoryPointer mPtr
    ) internal pure returns (uint168 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint176 at `mPtr` in memory.
    function readUint176(
        MemoryPointer mPtr
    ) internal pure returns (uint176 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint184 at `mPtr` in memory.
    function readUint184(
        MemoryPointer mPtr
    ) internal pure returns (uint184 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint192 at `mPtr` in memory.
    function readUint192(
        MemoryPointer mPtr
    ) internal pure returns (uint192 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint200 at `mPtr` in memory.
    function readUint200(
        MemoryPointer mPtr
    ) internal pure returns (uint200 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint208 at `mPtr` in memory.
    function readUint208(
        MemoryPointer mPtr
    ) internal pure returns (uint208 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint216 at `mPtr` in memory.
    function readUint216(
        MemoryPointer mPtr
    ) internal pure returns (uint216 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint224 at `mPtr` in memory.
    function readUint224(
        MemoryPointer mPtr
    ) internal pure returns (uint224 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint232 at `mPtr` in memory.
    function readUint232(
        MemoryPointer mPtr
    ) internal pure returns (uint232 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint240 at `mPtr` in memory.
    function readUint240(
        MemoryPointer mPtr
    ) internal pure returns (uint240 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint248 at `mPtr` in memory.
    function readUint248(
        MemoryPointer mPtr
    ) internal pure returns (uint248 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint256 at `mPtr` in memory.
    function readUint256(
        MemoryPointer mPtr
    ) internal pure returns (uint256 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int8 at `mPtr` in memory.
    function readInt8(MemoryPointer mPtr) internal pure returns (int8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int16 at `mPtr` in memory.
    function readInt16(MemoryPointer mPtr) internal pure returns (int16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int24 at `mPtr` in memory.
    function readInt24(MemoryPointer mPtr) internal pure returns (int24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int32 at `mPtr` in memory.
    function readInt32(MemoryPointer mPtr) internal pure returns (int32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int40 at `mPtr` in memory.
    function readInt40(MemoryPointer mPtr) internal pure returns (int40 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int48 at `mPtr` in memory.
    function readInt48(MemoryPointer mPtr) internal pure returns (int48 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int56 at `mPtr` in memory.
    function readInt56(MemoryPointer mPtr) internal pure returns (int56 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int64 at `mPtr` in memory.
    function readInt64(MemoryPointer mPtr) internal pure returns (int64 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int72 at `mPtr` in memory.
    function readInt72(MemoryPointer mPtr) internal pure returns (int72 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int80 at `mPtr` in memory.
    function readInt80(MemoryPointer mPtr) internal pure returns (int80 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int88 at `mPtr` in memory.
    function readInt88(MemoryPointer mPtr) internal pure returns (int88 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int96 at `mPtr` in memory.
    function readInt96(MemoryPointer mPtr) internal pure returns (int96 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int104 at `mPtr` in memory.
    function readInt104(
        MemoryPointer mPtr
    ) internal pure returns (int104 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int112 at `mPtr` in memory.
    function readInt112(
        MemoryPointer mPtr
    ) internal pure returns (int112 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int120 at `mPtr` in memory.
    function readInt120(
        MemoryPointer mPtr
    ) internal pure returns (int120 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int128 at `mPtr` in memory.
    function readInt128(
        MemoryPointer mPtr
    ) internal pure returns (int128 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int136 at `mPtr` in memory.
    function readInt136(
        MemoryPointer mPtr
    ) internal pure returns (int136 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int144 at `mPtr` in memory.
    function readInt144(
        MemoryPointer mPtr
    ) internal pure returns (int144 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int152 at `mPtr` in memory.
    function readInt152(
        MemoryPointer mPtr
    ) internal pure returns (int152 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int160 at `mPtr` in memory.
    function readInt160(
        MemoryPointer mPtr
    ) internal pure returns (int160 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int168 at `mPtr` in memory.
    function readInt168(
        MemoryPointer mPtr
    ) internal pure returns (int168 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int176 at `mPtr` in memory.
    function readInt176(
        MemoryPointer mPtr
    ) internal pure returns (int176 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int184 at `mPtr` in memory.
    function readInt184(
        MemoryPointer mPtr
    ) internal pure returns (int184 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int192 at `mPtr` in memory.
    function readInt192(
        MemoryPointer mPtr
    ) internal pure returns (int192 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int200 at `mPtr` in memory.
    function readInt200(
        MemoryPointer mPtr
    ) internal pure returns (int200 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int208 at `mPtr` in memory.
    function readInt208(
        MemoryPointer mPtr
    ) internal pure returns (int208 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int216 at `mPtr` in memory.
    function readInt216(
        MemoryPointer mPtr
    ) internal pure returns (int216 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int224 at `mPtr` in memory.
    function readInt224(
        MemoryPointer mPtr
    ) internal pure returns (int224 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int232 at `mPtr` in memory.
    function readInt232(
        MemoryPointer mPtr
    ) internal pure returns (int232 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int240 at `mPtr` in memory.
    function readInt240(
        MemoryPointer mPtr
    ) internal pure returns (int240 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int248 at `mPtr` in memory.
    function readInt248(
        MemoryPointer mPtr
    ) internal pure returns (int248 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int256 at `mPtr` in memory.
    function readInt256(
        MemoryPointer mPtr
    ) internal pure returns (int256 value) {
        assembly {
            value := mload(mPtr)
        }
    }
}

library MemoryWriters {
    /// @dev Writes `valuePtr` to memory at `mPtr`.
    function write(MemoryPointer mPtr, MemoryPointer valuePtr) internal pure {
        assembly {
            mstore(mPtr, valuePtr)
        }
    }

    /// @dev Writes a boolean `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, bool value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes an address `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, address value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes a bytes32 `value` to `mPtr` in memory.
    /// Separate name to disambiguate literal write parameters.
    function writeBytes32(MemoryPointer mPtr, bytes32 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes a uint256 `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, uint256 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes an int256 `value` to `mPtr` in memory.
    /// Separate name to disambiguate literal write parameters.
    function writeInt(MemoryPointer mPtr, int256 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ItemType } from "../../lib/ConsiderationEnums.sol";
import {
    Order,
    OrderParameters,
    BasicOrderParameters,
    OfferItem,
    ConsiderationItem,
    Schema,
    ZoneParameters
} from "../../lib/ConsiderationStructs.sol";
import { ConsiderationTypeHashes } from "./lib/ConsiderationTypeHashes.sol";
import {
    ConsiderationInterface
} from "../../interfaces/ConsiderationInterface.sol";
import {
    ConduitControllerInterface
} from "../../interfaces/ConduitControllerInterface.sol";
import {
    ContractOffererInterface
} from "../../interfaces/ContractOffererInterface.sol";
import { ZoneInterface } from "../../interfaces/ZoneInterface.sol";
import { GettersAndDerivers } from "../../lib/GettersAndDerivers.sol";
import {
    SeaportValidatorInterface
} from "../../interfaces/SeaportValidatorInterface.sol";
import { ZoneInterface } from "../../interfaces/ZoneInterface.sol";
import {
    ERC20Interface,
    ERC721Interface,
    ERC1155Interface
} from "../../interfaces/AbridgedTokenInterfaces.sol";
import { IERC165 } from "../../interfaces/IERC165.sol";
import { IERC2981 } from "../../interfaces/IERC2981.sol";
import {
    ErrorsAndWarnings,
    ErrorsAndWarningsLib
} from "./lib/ErrorsAndWarnings.sol";
import { SafeStaticCall } from "./lib/SafeStaticCall.sol";
import { Murky } from "./lib/Murky.sol";
import {
    IssueParser,
    ValidationConfiguration,
    TimeIssue,
    StatusIssue,
    OfferIssue,
    ContractOffererIssue,
    ConsiderationIssue,
    PrimaryFeeIssue,
    ERC721Issue,
    ERC1155Issue,
    ERC20Issue,
    NativeIssue,
    ZoneIssue,
    ConduitIssue,
    CreatorFeeIssue,
    SignatureIssue,
    GenericIssue
} from "./lib/SeaportValidatorTypes.sol";
import { Verifiers } from "../../lib/Verifiers.sol";

/**
 * @title SeaportValidator
 * @notice SeaportValidator provides advanced validation to seaport orders.
 */
contract SeaportValidator is
    SeaportValidatorInterface,
    ConsiderationTypeHashes,
    Murky
{
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using SafeStaticCall for address;
    using IssueParser for *;

    /// @notice Cross-chain seaport address
    ConsiderationInterface public constant seaport =
        ConsiderationInterface(0x00000000000001ad428e4906aE43D8F9852d0dD6);
    /// @notice Cross-chain conduit controller Address
    ConduitControllerInterface public constant conduitController =
        ConduitControllerInterface(0x00000000F9490004C11Cef243f5400493c00Ad63);
    /// @notice Ethereum creator fee engine address
    CreatorFeeEngineInterface public immutable creatorFeeEngine;

    bytes4 public constant ERC20_INTERFACE_ID = 0x36372b07;

    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd;

    bytes4 public constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    bytes4 public constant CONTRACT_OFFERER_INTERFACE_ID = 0x1be900b1;

    bytes4 public constant ZONE_INTERFACE_ID = 0x3839be19;

    bytes4 public constant SIP_5_INTERFACE_ID = 0x2e778efc;

    constructor() {
        address creatorFeeEngineAddress;
        if (block.chainid == 1 || block.chainid == 31337) {
            creatorFeeEngineAddress = 0x0385603ab55642cb4Dd5De3aE9e306809991804f;
        } else if (block.chainid == 3) {
            // Ropsten
            creatorFeeEngineAddress = 0xFf5A6F7f36764aAD301B7C9E85A5277614Df5E26;
        } else if (block.chainid == 4) {
            // Rinkeby
            creatorFeeEngineAddress = 0x8d17687ea9a6bb6efA24ec11DcFab01661b2ddcd;
        } else if (block.chainid == 5) {
            // Goerli
            creatorFeeEngineAddress = 0xe7c9Cb6D966f76f3B5142167088927Bf34966a1f;
        } else if (block.chainid == 42) {
            // Kovan
            creatorFeeEngineAddress = 0x54D88324cBedfFe1e62c9A59eBb310A11C295198;
        } else if (block.chainid == 137) {
            // Polygon
            creatorFeeEngineAddress = 0x28EdFcF0Be7E86b07493466e7631a213bDe8eEF2;
        } else if (block.chainid == 80001) {
            // Mumbai
            creatorFeeEngineAddress = 0x0a01E11887f727D1b1Cd81251eeEE9BEE4262D07;
        } else {
            // No creator fee engine for this chain
            creatorFeeEngineAddress = address(0);
        }

        creatorFeeEngine = CreatorFeeEngineInterface(creatorFeeEngineAddress);
    }

    /**
     * @notice Conduct a comprehensive validation of the given order.
     *    `isValidOrder` validates simple orders that adhere to a set of rules defined below:
     *    - The order is either a listing or an offer order (one NFT to buy or one NFT to sell).
     *    - The first consideration is the primary consideration.
     *    - The order pays up to two fees in the fungible token currency. First fee is primary fee, second is creator fee.
     *    - In private orders, the last consideration specifies a recipient for the offer item.
     *    - Offer items must be owned and properly approved by the offerer.
     *    - There must be one offer item
     *    - Consideration items must exist.
     *    - The signature must be valid, or the order must be already validated on chain
     * @param order The order to validate.
     * @return errorsAndWarnings The errors and warnings found in the order.
     */
    function isValidOrder(
        Order calldata order
    ) external returns (ErrorsAndWarnings memory errorsAndWarnings) {
        return
            isValidOrderWithConfiguration(
                ValidationConfiguration(
                    address(0),
                    0,
                    false,
                    false,
                    30 minutes,
                    26 weeks
                ),
                order
            );
    }

    /**
     * @notice Same as `isValidOrder` but allows for more configuration related to fee validation.
     *    If `skipStrictValidation` is set order logic validation is not carried out: fees are not
     *       checked and there may be more than one offer item as well as any number of consideration items.
     */
    function isValidOrderWithConfiguration(
        ValidationConfiguration memory validationConfiguration,
        Order memory order
    ) public returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Concatenates errorsAndWarnings with the returned errorsAndWarnings
        errorsAndWarnings.concat(
            validateTime(
                order.parameters,
                validationConfiguration.shortOrderDuration,
                validationConfiguration.distantOrderExpiration
            )
        );
        errorsAndWarnings.concat(validateOrderStatus(order.parameters));
        errorsAndWarnings.concat(validateOfferItems(order.parameters));
        errorsAndWarnings.concat(validateConsiderationItems(order.parameters));
        errorsAndWarnings.concat(isValidZone(order.parameters));
        errorsAndWarnings.concat(validateSignature(order));

        // Skip strict validation if requested
        if (!validationConfiguration.skipStrictValidation) {
            errorsAndWarnings.concat(
                validateStrictLogic(
                    order.parameters,
                    validationConfiguration.primaryFeeRecipient,
                    validationConfiguration.primaryFeeBips,
                    validationConfiguration.checkCreatorFee
                )
            );
        }
    }

    /**
     * @notice Checks if a conduit key is valid.
     * @param conduitKey The conduit key to check.
     * @return errorsAndWarnings The errors and warnings
     */
    function isValidConduit(
        bytes32 conduitKey
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        (, errorsAndWarnings) = getApprovalAddress(conduitKey);
    }

    /**
     * @notice Checks if the zone of an order is set and implements the EIP165
     *         zone interface
     * @dev To validate the zone call for an order, see validateOrderWithZone
     * @param orderParameters The order parameters to check.
     * @return errorsAndWarnings The errors and warnings
     */
    function isValidZone(
        OrderParameters memory orderParameters
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // If not restricted, zone isn't checked
        if (
            uint8(orderParameters.orderType) < 2 ||
            uint8(orderParameters.orderType) == 4
        ) {
            return errorsAndWarnings;
        }

        if (orderParameters.zone == address(0)) {
            // Zone is not set
            errorsAndWarnings.addError(ZoneIssue.NotSet.parseInt());
            return errorsAndWarnings;
        }

        // EOA zone is always valid
        if (address(orderParameters.zone).code.length == 0) {
            // Address is EOA. Valid order
            return errorsAndWarnings;
        }

        // Check the EIP165 zone interface
        if (!checkInterface(orderParameters.zone, ZONE_INTERFACE_ID)) {
            errorsAndWarnings.addError(ZoneIssue.InvalidZone.parseInt());
            return errorsAndWarnings;
        }

        // Check if the contract offerer implements SIP-5
        try ZoneInterface(orderParameters.zone).getSeaportMetadata() {} catch {
            errorsAndWarnings.addError(ZoneIssue.InvalidZone.parseInt());
        }
    }

    /**
     * @notice Gets the approval address for the given conduit key
     * @param conduitKey Conduit key to get approval address for
     * @return approvalAddress The address to use for approvals
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function getApprovalAddress(
        bytes32 conduitKey
    )
        public
        view
        returns (address, ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Zero conduit key corresponds to seaport
        if (conduitKey == 0) return (address(seaport), errorsAndWarnings);

        // Pull conduit info from conduitController
        (address conduitAddress, bool exists) = conduitController.getConduit(
            conduitKey
        );

        // Conduit does not exist
        if (!exists) {
            errorsAndWarnings.addError(ConduitIssue.KeyInvalid.parseInt());
            conduitAddress = address(0); // Don't return invalid conduit
        }

        // Approval address does not have Seaport v1.4 added as a channel
        if (
            exists &&
            !conduitController.getChannelStatus(
                conduitAddress,
                address(seaport)
            )
        ) {
            errorsAndWarnings.addError(
                ConduitIssue.MissingCanonicalSeaportChannel.parseInt()
            );
        }

        return (conduitAddress, errorsAndWarnings);
    }

    /**
     * @notice Validates the signature for the order using the offerer's current counter
     * @dev Will also check if order is validated on chain.
     */
    function validateSignature(
        Order memory order
    ) public returns (ErrorsAndWarnings memory errorsAndWarnings) {
        // Pull current counter from seaport
        uint256 currentCounter = seaport.getCounter(order.parameters.offerer);

        return validateSignatureWithCounter(order, currentCounter);
    }

    /**
     * @notice Validates the signature for the order using the given counter
     * @dev Will also check if order is validated on chain.
     */
    function validateSignatureWithCounter(
        Order memory order,
        uint256 counter
    ) public returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Contract orders do not have signatures
        if (uint8(order.parameters.orderType) == 4) {
            errorsAndWarnings.addWarning(
                SignatureIssue.ContractOrder.parseInt()
            );
        }

        // Get current counter for context
        uint256 currentCounter = seaport.getCounter(order.parameters.offerer);

        if (currentCounter > counter) {
            // Counter strictly increases
            errorsAndWarnings.addError(SignatureIssue.LowCounter.parseInt());
            return errorsAndWarnings;
        } else if (currentCounter < counter) {
            // Counter is incremented by random large number
            errorsAndWarnings.addError(SignatureIssue.HighCounter.parseInt());
            return errorsAndWarnings;
        }

        bytes32 orderHash = _deriveOrderHash(order.parameters, counter);

        // Check if order is validated on chain
        (bool isValid, , , ) = seaport.getOrderStatus(orderHash);

        if (isValid) {
            // Shortcut success, valid on chain
            return errorsAndWarnings;
        }

        // Create memory array to pass into validate
        Order[] memory orderArray = new Order[](1);

        // Store order in array
        orderArray[0] = order;

        try
            // Call validate on Seaport
            seaport.validate(orderArray)
        returns (bool success) {
            if (!success) {
                // Call was unsuccessful, so signature is invalid
                errorsAndWarnings.addError(SignatureIssue.Invalid.parseInt());
            }
        } catch {
            if (
                order.parameters.consideration.length !=
                order.parameters.totalOriginalConsiderationItems
            ) {
                // May help diagnose signature issues
                errorsAndWarnings.addWarning(
                    SignatureIssue.OriginalConsiderationItems.parseInt()
                );
            }
            // Call reverted, so signature is invalid
            errorsAndWarnings.addError(SignatureIssue.Invalid.parseInt());
        }
    }

    /**
     * @notice Check that a contract offerer implements the EIP165
     *         contract offerer interface
     * @param contractOfferer The address of the contract offerer
     * @return errorsAndWarnings The errors and warnings
     */
    function validateContractOfferer(
        address contractOfferer
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Check the EIP165 contract offerer interface
        if (!checkInterface(contractOfferer, CONTRACT_OFFERER_INTERFACE_ID)) {
            errorsAndWarnings.addError(
                ContractOffererIssue.InvalidContractOfferer.parseInt()
            );
        }

        // Check if the contract offerer implements SIP-5
        try
            ContractOffererInterface(contractOfferer).getSeaportMetadata()
        {} catch {
            errorsAndWarnings.addError(
                ContractOffererIssue.InvalidContractOfferer.parseInt()
            );
        }

        return errorsAndWarnings;
    }

    /**
     * @notice Check the time validity of an order
     * @param orderParameters The parameters for the order to validate
     * @param shortOrderDuration The duration of which an order is considered short
     * @param distantOrderExpiration Distant order expiration delta in seconds.
     * @return errorsAndWarnings The errors and warnings
     */
    function validateTime(
        OrderParameters memory orderParameters,
        uint256 shortOrderDuration,
        uint256 distantOrderExpiration
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (orderParameters.endTime <= orderParameters.startTime) {
            // Order duration is zero
            errorsAndWarnings.addError(
                TimeIssue.EndTimeBeforeStartTime.parseInt()
            );
            return errorsAndWarnings;
        }

        if (orderParameters.endTime < block.timestamp) {
            // Order is expired
            errorsAndWarnings.addError(TimeIssue.Expired.parseInt());
            return errorsAndWarnings;
        } else if (
            orderParameters.endTime > block.timestamp + distantOrderExpiration
        ) {
            // Order expires in a long time
            errorsAndWarnings.addWarning(
                TimeIssue.DistantExpiration.parseInt()
            );
        }

        if (orderParameters.startTime > block.timestamp) {
            // Order is not active
            errorsAndWarnings.addWarning(TimeIssue.NotActive.parseInt());
        }

        if (
            orderParameters.endTime -
                (
                    orderParameters.startTime > block.timestamp
                        ? orderParameters.startTime
                        : block.timestamp
                ) <
            shortOrderDuration
        ) {
            // Order has a short duration
            errorsAndWarnings.addWarning(TimeIssue.ShortOrder.parseInt());
        }
    }

    /**
     * @notice Validate the status of an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOrderStatus(
        OrderParameters memory orderParameters
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Cannot validate status of contract order
        if (uint8(orderParameters.orderType) == 4) {
            errorsAndWarnings.addWarning(StatusIssue.ContractOrder.parseInt());
        }

        // Pull current counter from seaport
        uint256 currentOffererCounter = seaport.getCounter(
            orderParameters.offerer
        );
        // Derive order hash using orderParameters and currentOffererCounter
        bytes32 orderHash = _deriveOrderHash(
            orderParameters,
            currentOffererCounter
        );
        // Get order status from seaport
        (, bool isCancelled, uint256 totalFilled, uint256 totalSize) = seaport
            .getOrderStatus(orderHash);

        if (isCancelled) {
            // Order is cancelled
            errorsAndWarnings.addError(StatusIssue.Cancelled.parseInt());
        }

        if (totalSize > 0 && totalFilled == totalSize) {
            // Order is fully filled
            errorsAndWarnings.addError(StatusIssue.FullyFilled.parseInt());
        }
    }

    /**
     * @notice Validate all offer items for an order. Ensures that
     *         offerer has sufficient balance and approval for each item.
     * @dev Amounts are not summed and verified, just the individual amounts.
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOfferItems(
        OrderParameters memory orderParameters
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Iterate over each offer item and validate it
        for (uint256 i = 0; i < orderParameters.offer.length; i++) {
            errorsAndWarnings.concat(validateOfferItem(orderParameters, i));

            // Check for duplicate offer item
            OfferItem memory offerItem1 = orderParameters.offer[i];

            for (uint256 j = i + 1; j < orderParameters.offer.length; j++) {
                // Iterate over each remaining offer item
                // (previous items already check with this item)
                OfferItem memory offerItem2 = orderParameters.offer[j];

                // Check if token and id are the same
                if (
                    offerItem1.token == offerItem2.token &&
                    offerItem1.identifierOrCriteria ==
                    offerItem2.identifierOrCriteria
                ) {
                    errorsAndWarnings.addError(
                        OfferIssue.DuplicateItem.parseInt()
                    );
                }
            }
        }

        // You must have an offer item
        if (orderParameters.offer.length == 0) {
            errorsAndWarnings.addWarning(OfferIssue.ZeroItems.parseInt());
        }

        // Warning if there is more than one offer item
        if (orderParameters.offer.length > 1) {
            errorsAndWarnings.addWarning(OfferIssue.MoreThanOneItem.parseInt());
        }
    }

    /**
     * @notice Validates an offer item
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItem(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        // First validate the parameters (correct amount, contract, etc)
        errorsAndWarnings = validateOfferItemParameters(
            orderParameters,
            offerItemIndex
        );
        if (errorsAndWarnings.hasErrors()) {
            // Only validate approvals and balances if parameters are valid
            return errorsAndWarnings;
        }

        // Validate approvals and balances for the offer item
        errorsAndWarnings.concat(
            validateOfferItemApprovalAndBalance(orderParameters, offerItemIndex)
        );
    }

    /**
     * @notice Validates the OfferItem parameters. This includes token contract validation
     * @dev OfferItems with criteria are currently not allowed
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemParameters(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Get the offer item at offerItemIndex
        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        // Check if start amount and end amount are zero
        if (offerItem.startAmount == 0 && offerItem.endAmount == 0) {
            errorsAndWarnings.addError(OfferIssue.AmountZero.parseInt());
            return errorsAndWarnings;
        }

        // Check that amount velocity is not too high.
        if (
            offerItem.startAmount != offerItem.endAmount &&
            orderParameters.endTime > orderParameters.startTime
        ) {
            // Assign larger and smaller amount values
            (uint256 maxAmount, uint256 minAmount) = offerItem.startAmount >
                offerItem.endAmount
                ? (offerItem.startAmount, offerItem.endAmount)
                : (offerItem.endAmount, offerItem.startAmount);

            uint256 amountDelta = maxAmount - minAmount;
            // delta of time that order exists for
            uint256 timeDelta = orderParameters.endTime -
                orderParameters.startTime;

            // Velocity scaled by 1e10 for precision
            uint256 velocity = (amountDelta * 1e10) / timeDelta;
            // gives velocity percentage in hundredth of a basis points per second in terms of larger value
            uint256 velocityPercentage = velocity / (maxAmount * 1e4);

            // 278 * 60 * 30 ~= 500,000
            if (velocityPercentage > 278) {
                // Over 50% change per 30 min
                errorsAndWarnings.addError(
                    OfferIssue.AmountVelocityHigh.parseInt()
                );
            }
            // Over 50% change per 30 min
            else if (velocityPercentage > 28) {
                // Over 5% change per 30 min
                errorsAndWarnings.addWarning(
                    OfferIssue.AmountVelocityHigh.parseInt()
                );
            }

            // Check for large amount steps
            if (minAmount <= 1e15) {
                errorsAndWarnings.addWarning(
                    OfferIssue.AmountStepLarge.parseInt()
                );
            }
        }

        if (offerItem.itemType == ItemType.ERC721) {
            // ERC721 type requires amounts to be 1
            if (offerItem.startAmount != 1 || offerItem.endAmount != 1) {
                errorsAndWarnings.addError(ERC721Issue.AmountNotOne.parseInt());
            }

            // Check the EIP165 token interface
            if (!checkInterface(offerItem.token, ERC721_INTERFACE_ID)) {
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
            }
        } else if (offerItem.itemType == ItemType.ERC721_WITH_CRITERIA) {
            // Check the EIP165 token interface
            if (!checkInterface(offerItem.token, ERC721_INTERFACE_ID)) {
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
            }

            if (offerItem.startAmount > 1 || offerItem.endAmount > 1) {
                // Require partial fill enabled. Even orderTypes are full
                if (uint8(orderParameters.orderType) % 2 == 0) {
                    errorsAndWarnings.addError(
                        ERC721Issue.CriteriaNotPartialFill.parseInt()
                    );
                }
            }
        } else if (
            offerItem.itemType == ItemType.ERC1155 ||
            offerItem.itemType == ItemType.ERC1155_WITH_CRITERIA
        ) {
            // Check the EIP165 token interface
            if (!checkInterface(offerItem.token, ERC1155_INTERFACE_ID)) {
                errorsAndWarnings.addError(
                    ERC1155Issue.InvalidToken.parseInt()
                );
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            // ERC20 must have `identifierOrCriteria` be zero
            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ERC20Issue.IdentifierNonZero.parseInt()
                );
            }

            // Validate contract, should return an uint256 if its an ERC20
            if (
                !offerItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.allowance.selector,
                        address(seaport),
                        address(seaport)
                    ),
                    0
                )
            ) {
                errorsAndWarnings.addError(ERC20Issue.InvalidToken.parseInt());
            }
        } else {
            // Must be native
            // NATIVE must have `token` be zero address
            if (offerItem.token != address(0)) {
                errorsAndWarnings.addError(NativeIssue.TokenAddress.parseInt());
            }

            // NATIVE must have `identifierOrCriteria` be zero
            if (offerItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    NativeIssue.IdentifierNonZero.parseInt()
                );
            }
        }
    }

    /**
     * @notice Validates the OfferItem approvals and balances
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemApprovalAndBalance(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        // Note: If multiple items are of the same token, token amounts are not summed for validation

        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Get the approval address for the given conduit key
        (
            address approvalAddress,
            ErrorsAndWarnings memory ew
        ) = getApprovalAddress(orderParameters.conduitKey);
        errorsAndWarnings.concat(ew);

        if (ew.hasErrors()) {
            // Approval address is invalid
            return errorsAndWarnings;
        }

        // Get the offer item at offerItemIndex
        OfferItem memory offerItem = orderParameters.offer[offerItemIndex];

        if (offerItem.itemType == ItemType.ERC721) {
            ERC721Interface token = ERC721Interface(offerItem.token);

            // Check that offerer owns token
            if (
                !address(token).safeStaticCallAddress(
                    abi.encodeWithSelector(
                        ERC721Interface.ownerOf.selector,
                        offerItem.identifierOrCriteria
                    ),
                    orderParameters.offerer
                )
            ) {
                errorsAndWarnings.addError(ERC721Issue.NotOwner.parseInt());
            }

            // Check for approval via `getApproved`
            if (
                !address(token).safeStaticCallAddress(
                    abi.encodeWithSelector(
                        ERC721Interface.getApproved.selector,
                        offerItem.identifierOrCriteria
                    ),
                    approvalAddress
                )
            ) {
                // Fallback to `isApprovalForAll`
                if (
                    !address(token).safeStaticCallBool(
                        abi.encodeWithSelector(
                            ERC721Interface.isApprovedForAll.selector,
                            orderParameters.offerer,
                            approvalAddress
                        ),
                        true
                    )
                ) {
                    // Not approved
                    errorsAndWarnings.addError(
                        ERC721Issue.NotApproved.parseInt()
                    );
                }
            }
        } else if (offerItem.itemType == ItemType.ERC721_WITH_CRITERIA) {
            ERC721Interface token = ERC721Interface(offerItem.token);

            // Check for approval
            if (
                !address(token).safeStaticCallBool(
                    abi.encodeWithSelector(
                        ERC721Interface.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                // Not approved
                errorsAndWarnings.addError(ERC721Issue.NotApproved.parseInt());
            }
        } else if (offerItem.itemType == ItemType.ERC1155) {
            ERC1155Interface token = ERC1155Interface(offerItem.token);

            // Check for approval
            if (
                !address(token).safeStaticCallBool(
                    abi.encodeWithSelector(
                        ERC1155Interface.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                errorsAndWarnings.addError(ERC1155Issue.NotApproved.parseInt());
            }

            // Get min required balance (max(startAmount, endAmount))
            uint256 minBalance = offerItem.startAmount < offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            // Check for sufficient balance
            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC1155Interface.balanceOf.selector,
                        orderParameters.offerer,
                        offerItem.identifierOrCriteria
                    ),
                    minBalance
                )
            ) {
                // Insufficient balance
                errorsAndWarnings.addError(
                    ERC1155Issue.InsufficientBalance.parseInt()
                );
            }
        } else if (offerItem.itemType == ItemType.ERC1155_WITH_CRITERIA) {
            ERC1155Interface token = ERC1155Interface(offerItem.token);

            // Check for approval
            if (
                !address(token).safeStaticCallBool(
                    abi.encodeWithSelector(
                        ERC1155Interface.isApprovedForAll.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    true
                )
            ) {
                errorsAndWarnings.addError(ERC1155Issue.NotApproved.parseInt());
            }
        } else if (offerItem.itemType == ItemType.ERC20) {
            ERC20Interface token = ERC20Interface(offerItem.token);

            // Get min required balance and approval (max(startAmount, endAmount))
            uint256 minBalanceAndAllowance = offerItem.startAmount <
                offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            // Check allowance
            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.allowance.selector,
                        orderParameters.offerer,
                        approvalAddress
                    ),
                    minBalanceAndAllowance
                )
            ) {
                errorsAndWarnings.addError(
                    ERC20Issue.InsufficientAllowance.parseInt()
                );
            }

            // Check balance
            if (
                !address(token).safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.balanceOf.selector,
                        orderParameters.offerer
                    ),
                    minBalanceAndAllowance
                )
            ) {
                errorsAndWarnings.addError(
                    ERC20Issue.InsufficientBalance.parseInt()
                );
            }
        } else {
            // Must be native
            // Get min required balance (max(startAmount, endAmount))
            uint256 minBalance = offerItem.startAmount < offerItem.endAmount
                ? offerItem.startAmount
                : offerItem.endAmount;

            // Check for sufficient balance
            if (orderParameters.offerer.balance < minBalance) {
                errorsAndWarnings.addError(
                    NativeIssue.InsufficientBalance.parseInt()
                );
            }

            // Native items can not be pulled so warn
            errorsAndWarnings.addWarning(OfferIssue.NativeItem.parseInt());
        }
    }

    /**
     * @notice Validate all consideration items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItems(
        OrderParameters memory orderParameters
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // You must have a consideration item
        if (orderParameters.consideration.length == 0) {
            errorsAndWarnings.addWarning(
                ConsiderationIssue.ZeroItems.parseInt()
            );
            return errorsAndWarnings;
        }

        // Declare a boolean to check if offerer is receiving at least
        // one consideration item
        bool offererReceivingAtLeastOneItem = false;

        // Iterate over each consideration item
        for (uint256 i = 0; i < orderParameters.consideration.length; i++) {
            // Validate consideration item
            errorsAndWarnings.concat(
                validateConsiderationItem(orderParameters, i)
            );

            ConsiderationItem memory considerationItem1 = orderParameters
                .consideration[i];

            // Check if the offerer is the recipient
            if (!offererReceivingAtLeastOneItem) {
                if (considerationItem1.recipient == orderParameters.offerer) {
                    offererReceivingAtLeastOneItem = true;
                }
            }

            // Check for duplicate consideration items
            for (
                uint256 j = i + 1;
                j < orderParameters.consideration.length;
                j++
            ) {
                // Iterate over each remaining consideration item
                // (previous items already check with this item)
                ConsiderationItem memory considerationItem2 = orderParameters
                    .consideration[j];

                // Check if itemType, token, id, and recipient are the same
                if (
                    considerationItem2.itemType ==
                    considerationItem1.itemType &&
                    considerationItem2.token == considerationItem1.token &&
                    considerationItem2.identifierOrCriteria ==
                    considerationItem1.identifierOrCriteria &&
                    considerationItem2.recipient == considerationItem1.recipient
                ) {
                    errorsAndWarnings.addWarning(
                        // Duplicate consideration item, warning
                        ConsiderationIssue.DuplicateItem.parseInt()
                    );
                }
            }
        }

        if (!offererReceivingAtLeastOneItem) {
            // Offerer is not receiving at least one consideration item
            errorsAndWarnings.addWarning(
                ConsiderationIssue.OffererNotReceivingAtLeastOneItem.parseInt()
            );
        }
    }

    /**
     * @notice Validate a consideration item
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItem(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Validate the consideration item at considerationItemIndex
        errorsAndWarnings.concat(
            validateConsiderationItemParameters(
                orderParameters,
                considerationItemIndex
            )
        );
    }

    /**
     * @notice Validates the parameters of a consideration item including contract validation
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItemParameters(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        ConsiderationItem memory considerationItem = orderParameters
            .consideration[considerationItemIndex];

        // Check if startAmount and endAmount are zero
        if (
            considerationItem.startAmount == 0 &&
            considerationItem.endAmount == 0
        ) {
            errorsAndWarnings.addError(
                ConsiderationIssue.AmountZero.parseInt()
            );
            return errorsAndWarnings;
        }

        // Check if the recipient is the null address
        if (considerationItem.recipient == address(0)) {
            errorsAndWarnings.addError(
                ConsiderationIssue.NullRecipient.parseInt()
            );
        }

        if (
            considerationItem.startAmount != considerationItem.endAmount &&
            orderParameters.endTime > orderParameters.startTime
        ) {
            // Check that amount velocity is not too high.
            // Assign larger and smaller amount values
            (uint256 maxAmount, uint256 minAmount) = considerationItem
                .startAmount > considerationItem.endAmount
                ? (considerationItem.startAmount, considerationItem.endAmount)
                : (considerationItem.endAmount, considerationItem.startAmount);

            uint256 amountDelta = maxAmount - minAmount;
            // delta of time that order exists for
            uint256 timeDelta = orderParameters.endTime -
                orderParameters.startTime;

            // Velocity scaled by 1e10 for precision
            uint256 velocity = (amountDelta * 1e10) / timeDelta;
            // gives velocity percentage in hundredth of a basis points per second in terms of larger value
            uint256 velocityPercentage = velocity / (maxAmount * 1e4);

            // 278 * 60 * 30 ~= 500,000
            if (velocityPercentage > 278) {
                // Over 50% change per 30 min
                errorsAndWarnings.addError(
                    ConsiderationIssue.AmountVelocityHigh.parseInt()
                );
            }
            // 28 * 60 * 30 ~= 50,000
            else if (velocityPercentage > 28) {
                // Over 5% change per 30 min
                errorsAndWarnings.addWarning(
                    ConsiderationIssue.AmountVelocityHigh.parseInt()
                );
            }

            // Check for large amount steps
            if (minAmount <= 1e15) {
                errorsAndWarnings.addWarning(
                    ConsiderationIssue.AmountStepLarge.parseInt()
                );
            }
        }

        if (considerationItem.itemType == ItemType.ERC721) {
            // ERC721 type requires amounts to be 1
            if (
                considerationItem.startAmount != 1 ||
                considerationItem.endAmount != 1
            ) {
                errorsAndWarnings.addError(ERC721Issue.AmountNotOne.parseInt());
            }

            // Check EIP165 interface
            if (!checkInterface(considerationItem.token, ERC721_INTERFACE_ID)) {
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
                return errorsAndWarnings;
            }

            // Check that token exists
            if (
                !considerationItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC721Interface.ownerOf.selector,
                        considerationItem.identifierOrCriteria
                    ),
                    1
                )
            ) {
                // Token does not exist
                errorsAndWarnings.addError(
                    ERC721Issue.IdentifierDNE.parseInt()
                );
            }
        } else if (
            considerationItem.itemType == ItemType.ERC721_WITH_CRITERIA
        ) {
            // Check EIP165 interface
            if (!checkInterface(considerationItem.token, ERC721_INTERFACE_ID)) {
                // Does not implement required interface
                errorsAndWarnings.addError(ERC721Issue.InvalidToken.parseInt());
            }
        } else if (
            considerationItem.itemType == ItemType.ERC1155 ||
            considerationItem.itemType == ItemType.ERC1155_WITH_CRITERIA
        ) {
            // Check EIP165 interface
            if (
                !checkInterface(considerationItem.token, ERC1155_INTERFACE_ID)
            ) {
                // Does not implement required interface
                errorsAndWarnings.addError(
                    ERC1155Issue.InvalidToken.parseInt()
                );
            }
        } else if (considerationItem.itemType == ItemType.ERC20) {
            // ERC20 must have `identifierOrCriteria` be zero
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    ERC20Issue.IdentifierNonZero.parseInt()
                );
            }

            // Check that it is an ERC20 token. ERC20 will return a uint256
            if (
                !considerationItem.token.safeStaticCallUint256(
                    abi.encodeWithSelector(
                        ERC20Interface.allowance.selector,
                        address(seaport),
                        address(seaport)
                    ),
                    0
                )
            ) {
                // Not an ERC20 token
                errorsAndWarnings.addError(ERC20Issue.InvalidToken.parseInt());
            }
        } else {
            // Must be native
            // NATIVE must have `token` be zero address
            if (considerationItem.token != address(0)) {
                errorsAndWarnings.addError(NativeIssue.TokenAddress.parseInt());
            }
            // NATIVE must have `identifierOrCriteria` be zero
            if (considerationItem.identifierOrCriteria != 0) {
                errorsAndWarnings.addError(
                    NativeIssue.IdentifierNonZero.parseInt()
                );
            }
        }
    }

    /**
     * @notice Strict validation operates under tight assumptions. It validates primary
     *    fee, creator fee, private sale consideration, and overall order format.
     * @dev Only checks first fee recipient provided by CreatorFeeEngine.
     *    Order of consideration items must be as follows:
     *    1. Primary consideration
     *    2. Primary fee
     *    3. Creator fee
     *    4. Private sale consideration
     * @param orderParameters The parameters for the order to validate.
     * @param primaryFeeRecipient The primary fee recipient. Set to null address for no primary fee.
     * @param primaryFeeBips The primary fee in BIPs.
     * @param checkCreatorFee Should check for creator fee. If true, creator fee must be present as
     *    according to creator fee engine. If false, must not have creator fee.
     * @return errorsAndWarnings The errors and warnings.
     */
    function validateStrictLogic(
        OrderParameters memory orderParameters,
        address primaryFeeRecipient,
        uint256 primaryFeeBips,
        bool checkCreatorFee
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Check that order matches the required format (listing or offer)
        {
            bool canCheckFee = true;
            // Single offer item and at least one consideration
            if (
                orderParameters.offer.length != 1 ||
                orderParameters.consideration.length == 0
            ) {
                // Not listing or offer, can't check fees
                canCheckFee = false;
            } else if (
                // Can't have both items be fungible
                isPaymentToken(orderParameters.offer[0].itemType) &&
                isPaymentToken(orderParameters.consideration[0].itemType)
            ) {
                // Not listing or offer, can't check fees
                canCheckFee = false;
            } else if (
                // Can't have both items be non-fungible
                !isPaymentToken(orderParameters.offer[0].itemType) &&
                !isPaymentToken(orderParameters.consideration[0].itemType)
            ) {
                // Not listing or offer, can't check fees
                canCheckFee = false;
            }
            if (!canCheckFee) {
                // Does not match required format
                errorsAndWarnings.addError(
                    GenericIssue.InvalidOrderFormat.parseInt()
                );
                return errorsAndWarnings;
            }
        }

        // Validate secondary consideration items (fees)
        (
            uint256 tertiaryConsiderationIndex,
            ErrorsAndWarnings memory errorsAndWarningsLocal
        ) = _validateSecondaryConsiderationItems(
                orderParameters,
                primaryFeeRecipient,
                primaryFeeBips,
                checkCreatorFee
            );

        errorsAndWarnings.concat(errorsAndWarningsLocal);

        // Validate tertiary consideration items if not 0 (0 indicates error).
        // Only if no prior errors
        if (tertiaryConsiderationIndex != 0) {
            errorsAndWarnings.concat(
                _validateTertiaryConsiderationItems(
                    orderParameters,
                    tertiaryConsiderationIndex
                )
            );
        }
    }

    function _validateSecondaryConsiderationItems(
        OrderParameters memory orderParameters,
        address primaryFeeRecipient,
        uint256 primaryFeeBips,
        bool checkCreatorFee
    )
        internal
        view
        returns (
            uint256 tertiaryConsiderationIndex,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // non-fungible item address
        address itemAddress;
        // non-fungible item identifier
        uint256 itemIdentifier;
        // fungible item start amount
        uint256 transactionAmountStart;
        // fungible item end amount
        uint256 transactionAmountEnd;

        // Consideration item to hold expected creator fee info
        ConsiderationItem memory creatorFeeConsideration;

        if (isPaymentToken(orderParameters.offer[0].itemType)) {
            // Offer is an offer. Offer item is fungible and used for fees
            creatorFeeConsideration.itemType = orderParameters
                .offer[0]
                .itemType;
            creatorFeeConsideration.token = orderParameters.offer[0].token;
            transactionAmountStart = orderParameters.offer[0].startAmount;
            transactionAmountEnd = orderParameters.offer[0].endAmount;

            // Set non-fungible information for calculating creator fee
            itemAddress = orderParameters.consideration[0].token;
            itemIdentifier = orderParameters
                .consideration[0]
                .identifierOrCriteria;
        } else {
            // Offer is an offer. Consideration item is fungible and used for fees
            creatorFeeConsideration.itemType = orderParameters
                .consideration[0]
                .itemType;
            creatorFeeConsideration.token = orderParameters
                .consideration[0]
                .token;
            transactionAmountStart = orderParameters
                .consideration[0]
                .startAmount;
            transactionAmountEnd = orderParameters.consideration[0].endAmount;

            // Set non-fungible information for calculating creator fees
            itemAddress = orderParameters.offer[0].token;
            itemIdentifier = orderParameters.offer[0].identifierOrCriteria;
        }

        // Store flag if primary fee is present
        bool primaryFeePresent = false;
        {
            // Calculate primary fee start and end amounts
            uint256 primaryFeeStartAmount = (transactionAmountStart *
                primaryFeeBips) / 10000;
            uint256 primaryFeeEndAmount = (transactionAmountEnd *
                primaryFeeBips) / 10000;

            // Check if primary fee check is desired. Skip if calculated amount is zero.
            if (
                primaryFeeRecipient != address(0) &&
                (primaryFeeStartAmount > 0 || primaryFeeEndAmount > 0)
            ) {
                // Ensure primary fee is present
                if (orderParameters.consideration.length < 2) {
                    errorsAndWarnings.addError(
                        PrimaryFeeIssue.Missing.parseInt()
                    );
                    return (0, errorsAndWarnings);
                }
                primaryFeePresent = true;

                ConsiderationItem memory primaryFeeItem = orderParameters
                    .consideration[1];

                // Check item type
                if (
                    primaryFeeItem.itemType != creatorFeeConsideration.itemType
                ) {
                    errorsAndWarnings.addError(
                        PrimaryFeeIssue.ItemType.parseInt()
                    );
                    return (0, errorsAndWarnings);
                }
                // Check token
                if (primaryFeeItem.token != creatorFeeConsideration.token) {
                    errorsAndWarnings.addError(
                        PrimaryFeeIssue.Token.parseInt()
                    );
                }
                // Check start amount
                if (primaryFeeItem.startAmount < primaryFeeStartAmount) {
                    errorsAndWarnings.addError(
                        PrimaryFeeIssue.StartAmount.parseInt()
                    );
                }
                // Check end amount
                if (primaryFeeItem.endAmount < primaryFeeEndAmount) {
                    errorsAndWarnings.addError(
                        PrimaryFeeIssue.EndAmount.parseInt()
                    );
                }
                // Check recipient
                if (primaryFeeItem.recipient != primaryFeeRecipient) {
                    errorsAndWarnings.addError(
                        PrimaryFeeIssue.Recipient.parseInt()
                    );
                }
            }
        }

        // Check creator fee
        (
            creatorFeeConsideration.recipient,
            creatorFeeConsideration.startAmount,
            creatorFeeConsideration.endAmount
        ) = getCreatorFeeInfo(
            itemAddress,
            itemIdentifier,
            transactionAmountStart,
            transactionAmountEnd
        );

        // Flag indicating if creator fee is present in considerations
        bool creatorFeePresent = false;

        // Determine if should check for creator fee
        if (
            creatorFeeConsideration.recipient != address(0) &&
            checkCreatorFee &&
            (creatorFeeConsideration.startAmount > 0 ||
                creatorFeeConsideration.endAmount > 0)
        ) {
            // Calculate index of creator fee consideration item
            uint16 creatorFeeConsiderationIndex = primaryFeePresent ? 2 : 1; // 2 if primary fee, ow 1

            // Check that creator fee consideration item exists
            if (
                orderParameters.consideration.length - 1 <
                creatorFeeConsiderationIndex
            ) {
                errorsAndWarnings.addError(CreatorFeeIssue.Missing.parseInt());
                return (0, errorsAndWarnings);
            }

            ConsiderationItem memory creatorFeeItem = orderParameters
                .consideration[creatorFeeConsiderationIndex];

            creatorFeePresent = true;

            // Check type
            if (creatorFeeItem.itemType != creatorFeeConsideration.itemType) {
                errorsAndWarnings.addError(CreatorFeeIssue.ItemType.parseInt());
                return (0, errorsAndWarnings);
            }
            // Check token
            if (creatorFeeItem.token != creatorFeeConsideration.token) {
                errorsAndWarnings.addError(CreatorFeeIssue.Token.parseInt());
            }
            // Check start amount
            if (
                creatorFeeItem.startAmount < creatorFeeConsideration.startAmount
            ) {
                errorsAndWarnings.addError(
                    CreatorFeeIssue.StartAmount.parseInt()
                );
            }
            // Check end amount
            if (creatorFeeItem.endAmount < creatorFeeConsideration.endAmount) {
                errorsAndWarnings.addError(
                    CreatorFeeIssue.EndAmount.parseInt()
                );
            }
            // Check recipient
            if (creatorFeeItem.recipient != creatorFeeConsideration.recipient) {
                errorsAndWarnings.addError(
                    CreatorFeeIssue.Recipient.parseInt()
                );
            }
        }

        // Calculate index of first tertiary consideration item
        tertiaryConsiderationIndex =
            1 +
            (primaryFeePresent ? 1 : 0) +
            (creatorFeePresent ? 1 : 0);
    }

    /**
     * @notice Fetches the on chain creator fees.
     * @dev Uses the creatorFeeEngine when available, otherwise fallback to `IERC2981`.
     * @param token The token address
     * @param tokenId The token identifier
     * @param transactionAmountStart The transaction start amount
     * @param transactionAmountEnd The transaction end amount
     * @return recipient creator fee recipient
     * @return creatorFeeAmountStart creator fee start amount
     * @return creatorFeeAmountEnd creator fee end amount
     */
    function getCreatorFeeInfo(
        address token,
        uint256 tokenId,
        uint256 transactionAmountStart,
        uint256 transactionAmountEnd
    )
        public
        view
        returns (
            address payable recipient,
            uint256 creatorFeeAmountStart,
            uint256 creatorFeeAmountEnd
        )
    {
        // Check if creator fee engine is on this chain
        if (address(creatorFeeEngine) != address(0)) {
            // Creator fee engine may revert if no creator fees are present.
            try
                creatorFeeEngine.getRoyaltyView(
                    token,
                    tokenId,
                    transactionAmountStart
                )
            returns (
                address payable[] memory creatorFeeRecipients,
                uint256[] memory creatorFeeAmountsStart
            ) {
                if (creatorFeeRecipients.length != 0) {
                    // Use first recipient and amount
                    recipient = creatorFeeRecipients[0];
                    creatorFeeAmountStart = creatorFeeAmountsStart[0];
                }
            } catch {
                // Creator fee not found
            }

            // If fees found for start amount, check end amount
            if (recipient != address(0)) {
                // Creator fee engine may revert if no creator fees are present.
                try
                    creatorFeeEngine.getRoyaltyView(
                        token,
                        tokenId,
                        transactionAmountEnd
                    )
                returns (
                    address payable[] memory,
                    uint256[] memory creatorFeeAmountsEnd
                ) {
                    creatorFeeAmountEnd = creatorFeeAmountsEnd[0];
                } catch {}
            }
        } else {
            // Fallback to ERC2981
            {
                // Static call to token using ERC2981
                (bool success, bytes memory res) = token.staticcall(
                    abi.encodeWithSelector(
                        IERC2981.royaltyInfo.selector,
                        tokenId,
                        transactionAmountStart
                    )
                );
                // Check if call succeeded
                if (success) {
                    // Ensure 64 bytes returned
                    if (res.length == 64) {
                        // Decode result and assign recipient and start amount
                        (recipient, creatorFeeAmountStart) = abi.decode(
                            res,
                            (address, uint256)
                        );
                    }
                }
            }

            // Only check end amount if start amount found
            if (recipient != address(0)) {
                // Static call to token using ERC2981
                (bool success, bytes memory res) = token.staticcall(
                    abi.encodeWithSelector(
                        IERC2981.royaltyInfo.selector,
                        tokenId,
                        transactionAmountEnd
                    )
                );
                // Check if call succeeded
                if (success) {
                    // Ensure 64 bytes returned
                    if (res.length == 64) {
                        // Decode result and assign end amount
                        (, creatorFeeAmountEnd) = abi.decode(
                            res,
                            (address, uint256)
                        );
                    }
                }
            }
        }
    }

    /**
     * @notice Internal function for validating all consideration items after the fee items.
     *    Only additional acceptable consideration is private sale.
     */
    function _validateTertiaryConsiderationItems(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) internal pure returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (orderParameters.consideration.length <= considerationItemIndex) {
            // No more consideration items
            return errorsAndWarnings;
        }

        ConsiderationItem memory privateSaleConsideration = orderParameters
            .consideration[considerationItemIndex];

        // Check if offer is payment token. Private sale not possible if so.
        if (isPaymentToken(orderParameters.offer[0].itemType)) {
            errorsAndWarnings.addError(
                ConsiderationIssue.ExtraItems.parseInt()
            );
            return errorsAndWarnings;
        }

        // Check if private sale to self
        if (privateSaleConsideration.recipient == orderParameters.offerer) {
            errorsAndWarnings.addError(
                ConsiderationIssue.PrivateSaleToSelf.parseInt()
            );
            return errorsAndWarnings;
        }

        // Ensure that private sale parameters match offer item.
        if (
            privateSaleConsideration.itemType !=
            orderParameters.offer[0].itemType ||
            privateSaleConsideration.token != orderParameters.offer[0].token ||
            orderParameters.offer[0].startAmount !=
            privateSaleConsideration.startAmount ||
            orderParameters.offer[0].endAmount !=
            privateSaleConsideration.endAmount ||
            orderParameters.offer[0].identifierOrCriteria !=
            privateSaleConsideration.identifierOrCriteria
        ) {
            // Invalid private sale, say extra consideration item
            errorsAndWarnings.addError(
                ConsiderationIssue.ExtraItems.parseInt()
            );
            return errorsAndWarnings;
        }

        errorsAndWarnings.addWarning(ConsiderationIssue.PrivateSale.parseInt());

        // Should not be any additional consideration items
        if (orderParameters.consideration.length - 1 > considerationItemIndex) {
            // Extra consideration items
            errorsAndWarnings.addError(
                ConsiderationIssue.ExtraItems.parseInt()
            );
            return errorsAndWarnings;
        }
    }

    /**
     * @notice Validates the zone call for an order
     * @param orderParameters The order parameters for the order to validate
     * @param zoneParameters The zone parameters for the order to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOrderWithZone(
        OrderParameters memory orderParameters,
        ZoneParameters memory zoneParameters
    ) public view returns (ErrorsAndWarnings memory errorsAndWarnings) {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        // Call isValidZone to check if zone is set and implements EIP165
        errorsAndWarnings.concat(isValidZone(orderParameters));

        // Call zone function `validateOrder` with the supplied ZoneParameters
        if (
            !orderParameters.zone.safeStaticCallBytes4(
                abi.encodeWithSelector(
                    ZoneInterface.validateOrder.selector,
                    zoneParameters
                ),
                ZoneInterface.validateOrder.selector
            )
        ) {
            // Call to validateOrder reverted or returned invalid magic value
            errorsAndWarnings.addWarning(ZoneIssue.RejectedOrder.parseInt());
        }
    }

    /**
     * @notice Safely check that a contract implements an interface
     * @param token The token address to check
     * @param interfaceHash The interface hash to check
     */
    function checkInterface(
        address token,
        bytes4 interfaceHash
    ) public view returns (bool) {
        return
            token.safeStaticCallBool(
                abi.encodeWithSelector(
                    IERC165.supportsInterface.selector,
                    interfaceHash
                ),
                true
            );
    }

    function isPaymentToken(ItemType itemType) public pure returns (bool) {
        return itemType == ItemType.NATIVE || itemType == ItemType.ERC20;
    }

    /*//////////////////////////////////////////////////////////////
                        Merkle Helpers
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sorts an array of token ids by the keccak256 hash of the id. Required ordering of ids
     *    for other merkle operations.
     * @param includedTokens An array of included token ids.
     * @return sortedTokens The sorted `includedTokens` array.
     */
    function sortMerkleTokens(
        uint256[] memory includedTokens
    ) public pure returns (uint256[] memory sortedTokens) {
        // Sort token ids by the keccak256 hash of the id
        return _sortUint256ByHash(includedTokens);
    }

    /**
     * @notice Creates a merkle root for includedTokens.
     * @dev `includedTokens` must be sorting in strictly ascending order according to the keccak256 hash of the value.
     * @return merkleRoot The merkle root
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleRoot(
        uint256[] memory includedTokens
    )
        public
        pure
        returns (bytes32 merkleRoot, ErrorsAndWarnings memory errorsAndWarnings)
    {
        (merkleRoot, errorsAndWarnings) = _getRoot(includedTokens);
    }

    /**
     * @notice Creates a merkle proof for the the targetIndex contained in includedTokens.
     * @dev `targetIndex` is referring to the index of an element in `includedTokens`.
     *    `includedTokens` must be sorting in ascending order according to the keccak256 hash of the value.
     * @return merkleProof The merkle proof
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleProof(
        uint256[] memory includedTokens,
        uint256 targetIndex
    )
        public
        pure
        returns (
            bytes32[] memory merkleProof,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        (merkleProof, errorsAndWarnings) = _getProof(
            includedTokens,
            targetIndex
        );
    }

    /**
     * @notice Verifies a merkle proof for the value to prove and given root and proof.
     * @dev The `valueToProve` is hashed prior to executing the proof verification.
     * @param merkleRoot The root of the merkle tree
     * @param merkleProof The merkle proof
     * @param valueToProve The value to prove
     * @return whether proof is valid
     */
    function verifyMerkleProof(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        uint256 valueToProve
    ) public pure returns (bool) {
        bytes32 hashedValue = keccak256(abi.encode(valueToProve));

        return _verifyProof(merkleRoot, merkleProof, hashedValue);
    }
}

interface CreatorFeeEngineInterface {
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../../../lib/ConsiderationStructs.sol";

uint256 constant EIP712_Order_size = 0x180;
uint256 constant EIP712_OfferItem_size = 0xc0;
uint256 constant EIP712_ConsiderationItem_size = 0xe0;
uint256 constant EIP712_DomainSeparator_offset = 0x02;
uint256 constant EIP712_OrderHash_offset = 0x22;
uint256 constant EIP712_DigestPayload_size = 0x42;
uint256 constant EIP_712_PREFIX = (
    0x1901000000000000000000000000000000000000000000000000000000000000
);

contract ConsiderationTypeHashes {
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 internal immutable _OFFER_ITEM_TYPEHASH;
    bytes32 internal immutable _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal immutable _ORDER_TYPEHASH;
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    address internal constant seaportAddress =
        address(0x00000000000006c7676171937C444f6BDe3D6282);

    constructor() {
        // Derive hash of the name of the contract.
        _NAME_HASH = keccak256(bytes("Seaport"));

        // Derive hash of the version string of the contract.
        _VERSION_HASH = keccak256(bytes("1.2"));

        bytes memory offerItemTypeString = abi.encodePacked(
            "OfferItem(",
            "uint8 itemType,",
            "address token,",
            "uint256 identifierOrCriteria,",
            "uint256 startAmount,",
            "uint256 endAmount",
            ")"
        );

        // Construct the ConsiderationItem type string.
        // prettier-ignore
        bytes memory considerationItemTypeString = abi.encodePacked(
            "ConsiderationItem(",
                "uint8 itemType,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 startAmount,",
                "uint256 endAmount,",
                "address recipient",
            ")"
        );

        // Construct the OrderComponents type string, not including the above.
        // prettier-ignore
        bytes memory orderComponentsPartialTypeString = abi.encodePacked(
            "OrderComponents(",
                "address offerer,",
                "address zone,",
                "OfferItem[] offer,",
                "ConsiderationItem[] consideration,",
                "uint8 orderType,",
                "uint256 startTime,",
                "uint256 endTime,",
                "bytes32 zoneHash,",
                "uint256 salt,",
                "bytes32 conduitKey,",
                "uint256 counter",
            ")"
        );
        // Derive the OfferItem type hash using the corresponding type string.
        bytes32 offerItemTypehash = keccak256(offerItemTypeString);

        // Derive ConsiderationItem type hash using corresponding type string.
        bytes32 considerationItemTypehash = keccak256(
            considerationItemTypeString
        );

        // Construct the primary EIP-712 domain type string.
        // prettier-ignore
        _EIP_712_DOMAIN_TYPEHASH = keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                    "string name,",
                    "string version,",
                    "uint256 chainId,",
                    "address verifyingContract",
                ")"
            )
        );

        _OFFER_ITEM_TYPEHASH = offerItemTypehash;
        _CONSIDERATION_ITEM_TYPEHASH = considerationItemTypehash;

        // Derive OrderItem type hash via combination of relevant type strings.
        _ORDER_TYPEHASH = keccak256(
            abi.encodePacked(
                orderComponentsPartialTypeString,
                considerationItemTypeString,
                offerItemTypeString
            )
        );

        _DOMAIN_SEPARATOR = _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator() internal view returns (bytes32) {
        // prettier-ignore
        return keccak256(
            abi.encode(
                _EIP_712_DOMAIN_TYPEHASH,
                _NAME_HASH,
                _VERSION_HASH,
                block.chainid,
                seaportAddress
            )
        );
    }

    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param orderHash       The order hash.
     *
     * @return value The hash.
     */
    function _deriveEIP712Digest(
        bytes32 orderHash
    ) internal view returns (bytes32 value) {
        bytes32 domainSeparator = _DOMAIN_SEPARATOR;
        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(0, EIP_712_PREFIX)

            // Place the domain separator in the next region of scratch space.
            mstore(EIP712_DomainSeparator_offset, domainSeparator)

            // Place the order hash in scratch space, spilling into the first
            // two bytes of the free memory pointer — this should never be set
            // as memory cannot be expanded to that size, and will be zeroed out
            // after the hash is performed.
            mstore(EIP712_OrderHash_offset, orderHash)

            // Hash the relevant region (65 bytes).
            value := keccak256(0, EIP712_DigestPayload_size)

            // Clear out the dirtied bits in the memory pointer.
            mstore(EIP712_OrderHash_offset, 0)
        }
    }

    /**
     * @dev Internal view function to derive the EIP-712 hash for an offer item.
     *
     * @param offerItem The offered item to hash.
     *
     * @return The hash.
     */
    function _hashOfferItem(
        OfferItem memory offerItem
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _OFFER_ITEM_TYPEHASH,
                    offerItem.itemType,
                    offerItem.token,
                    offerItem.identifierOrCriteria,
                    offerItem.startAmount,
                    offerItem.endAmount
                )
            );
    }

    /**
     * @dev Internal view function to derive the EIP-712 hash for a consideration item.
     *
     * @param considerationItem The consideration item to hash.
     *
     * @return The hash.
     */
    function _hashConsiderationItem(
        ConsiderationItem memory considerationItem
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _CONSIDERATION_ITEM_TYPEHASH,
                    considerationItem.itemType,
                    considerationItem.token,
                    considerationItem.identifierOrCriteria,
                    considerationItem.startAmount,
                    considerationItem.endAmount,
                    considerationItem.recipient
                )
            );
    }

    /**
     * @dev Internal view function to derive the order hash for a given order.
     *      Note that only the original consideration items are included in the
     *      order hash, as additional consideration items may be supplied by the
     *      caller.
     *
     * @param orderParameters The parameters of the order to hash.
     * @param counter           The counter of the order to hash.
     *
     * @return orderHash The hash.
     */
    function _deriveOrderHash(
        OrderParameters memory orderParameters,
        uint256 counter
    ) internal view returns (bytes32 orderHash) {
        // Designate new memory regions for offer and consideration item hashes.
        bytes32[] memory offerHashes = new bytes32[](
            orderParameters.offer.length
        );
        bytes32[] memory considerationHashes = new bytes32[](
            orderParameters.totalOriginalConsiderationItems
        );

        // Iterate over each offer on the order.
        for (uint256 i = 0; i < orderParameters.offer.length; ++i) {
            // Hash the offer and place the result into memory.
            offerHashes[i] = _hashOfferItem(orderParameters.offer[i]);
        }

        // Iterate over each consideration on the order.
        for (
            uint256 i = 0;
            i < orderParameters.totalOriginalConsiderationItems;
            ++i
        ) {
            // Hash the consideration and place the result into memory.
            considerationHashes[i] = _hashConsiderationItem(
                orderParameters.consideration[i]
            );
        }

        // Derive and return the order hash as specified by EIP-712.

        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    orderParameters.offerer,
                    orderParameters.zone,
                    keccak256(abi.encodePacked(offerHashes)),
                    keccak256(abi.encodePacked(considerationHashes)),
                    orderParameters.orderType,
                    orderParameters.startTime,
                    orderParameters.endTime,
                    orderParameters.zoneHash,
                    orderParameters.salt,
                    orderParameters.conduitKey,
                    counter
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ErrorsAndWarnings {
    uint16[] errors;
    uint16[] warnings;
}

library ErrorsAndWarningsLib {
    function concat(ErrorsAndWarnings memory ew1, ErrorsAndWarnings memory ew2)
        internal
        pure
    {
        ew1.errors = concatMemory(ew1.errors, ew2.errors);
        ew1.warnings = concatMemory(ew1.warnings, ew2.warnings);
    }

    function addError(ErrorsAndWarnings memory ew, uint16 err) internal pure {
        ew.errors = pushMemory(ew.errors, err);
    }

    function addWarning(ErrorsAndWarnings memory ew, uint16 warn)
        internal
        pure
    {
        ew.warnings = pushMemory(ew.warnings, warn);
    }

    function hasErrors(ErrorsAndWarnings memory ew)
        internal
        pure
        returns (bool)
    {
        return ew.errors.length != 0;
    }

    function hasWarnings(ErrorsAndWarnings memory ew)
        internal
        pure
        returns (bool)
    {
        return ew.warnings.length != 0;
    }

    // Helper Functions
    function concatMemory(uint16[] memory array1, uint16[] memory array2)
        private
        pure
        returns (uint16[] memory)
    {
        if (array1.length == 0) {
            return array2;
        } else if (array2.length == 0) {
            return array1;
        }

        uint16[] memory returnValue = new uint16[](
            array1.length + array2.length
        );

        for (uint256 i = 0; i < array1.length; i++) {
            returnValue[i] = array1[i];
        }
        for (uint256 i = 0; i < array2.length; i++) {
            returnValue[i + array1.length] = array2[i];
        }

        return returnValue;
    }

    function pushMemory(uint16[] memory uint16Array, uint16 newValue)
        internal
        pure
        returns (uint16[] memory)
    {
        uint16[] memory returnValue = new uint16[](uint16Array.length + 1);

        for (uint256 i = 0; i < uint16Array.length; i++) {
            returnValue[i] = uint16Array[i];
        }
        returnValue[uint16Array.length] = newValue;

        return returnValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {
    ErrorsAndWarnings,
    ErrorsAndWarningsLib
} from "./ErrorsAndWarnings.sol";

import { IssueParser, MerkleIssue } from "./SeaportValidatorTypes.sol";

contract Murky {
    using ErrorsAndWarningsLib for ErrorsAndWarnings;
    using IssueParser for MerkleIssue;

    bool internal constant HASH_ODD_WITH_ZERO = false;

    function _verifyProof(
        bytes32 root,
        bytes32[] memory proof,
        bytes32 valueToProve
    ) internal pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = valueToProve;
        uint256 length = proof.length;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                rollingHash = _hashLeafPairs(rollingHash, proof[i]);
            }
        }
        return root == rollingHash;
    }

    /********************
     * HASHING FUNCTION *
     ********************/

    /// ascending sort and concat prior to hashing
    function _hashLeafPairs(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 _hash)
    {
        assembly {
            switch lt(left, right)
            case 0 {
                mstore(0x0, right)
                mstore(0x20, left)
            }
            default {
                mstore(0x0, left)
                mstore(0x20, right)
            }
            _hash := keccak256(0x0, 0x40)
        }
    }

    /********************
     * PROOF GENERATION *
     ********************/

    function _getRoot(uint256[] memory data)
        internal
        pure
        returns (bytes32 result, ErrorsAndWarnings memory errorsAndWarnings)
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (data.length < 2) {
            errorsAndWarnings.addError(MerkleIssue.SingleLeaf.parseInt());
            return (0, errorsAndWarnings);
        }

        bool hashOddWithZero = HASH_ODD_WITH_ZERO;

        if (!_processInput(data)) {
            errorsAndWarnings.addError(MerkleIssue.Unsorted.parseInt());
            return (0, errorsAndWarnings);
        }

        assembly {
            function hashLeafPairs(left, right) -> _hash {
                switch lt(left, right)
                case 0 {
                    mstore(0x0, right)
                    mstore(0x20, left)
                }
                default {
                    mstore(0x0, left)
                    mstore(0x20, right)
                }
                _hash := keccak256(0x0, 0x40)
            }
            function hashLevel(_data, length, _hashOddWithZero) -> newLength {
                // we will be modifying data in-place, so set result pointer to data pointer
                let _result := _data
                // get length of original data array
                // let length := mload(_data)
                // bool to track if we need to hash the last element of an odd-length array with zero
                let oddLength

                // if length is odd, we need to hash the last element with zero
                switch and(length, 1)
                case 1 {
                    // if length is odd, add 1 so division by 2 will round up
                    newLength := add(1, div(length, 2))
                    oddLength := 1
                }
                default {
                    newLength := div(length, 2)
                }
                // todo: necessary?
                // mstore(_data, newLength)
                let resultIndexPointer := add(0x20, _data)
                let dataIndexPointer := resultIndexPointer

                // stop iterating over for loop at length-1
                let stopIteration := add(_data, mul(length, 0x20))
                // write result array in-place over data array
                for {

                } lt(dataIndexPointer, stopIteration) {

                } {
                    // get next two elements from data, hash them together
                    let data1 := mload(dataIndexPointer)
                    let data2 := mload(add(dataIndexPointer, 0x20))
                    let hashedPair := hashLeafPairs(data1, data2)
                    // overwrite an element of data array with
                    mstore(resultIndexPointer, hashedPair)
                    // increment result pointer by 1 slot
                    resultIndexPointer := add(0x20, resultIndexPointer)
                    // increment data pointer by 2 slot
                    dataIndexPointer := add(0x40, dataIndexPointer)
                }
                // we did not yet hash last index if odd-length
                if oddLength {
                    let data1 := mload(dataIndexPointer)
                    let nextValue
                    switch _hashOddWithZero
                    case 0 {
                        nextValue := data1
                    }
                    default {
                        nextValue := hashLeafPairs(data1, 0)
                    }
                    mstore(resultIndexPointer, nextValue)
                }
            }

            let dataLength := mload(data)
            for {

            } gt(dataLength, 1) {

            } {
                dataLength := hashLevel(data, dataLength, hashOddWithZero)
            }
            result := mload(add(0x20, data))
        }
    }

    function _getProof(uint256[] memory data, uint256 node)
        internal
        pure
        returns (
            bytes32[] memory result,
            ErrorsAndWarnings memory errorsAndWarnings
        )
    {
        errorsAndWarnings = ErrorsAndWarnings(new uint16[](0), new uint16[](0));

        if (data.length < 2) {
            errorsAndWarnings.addError(MerkleIssue.SingleLeaf.parseInt());
            return (new bytes32[](0), errorsAndWarnings);
        }

        bool hashOddWithZero = HASH_ODD_WITH_ZERO;

        if (!_processInput(data)) {
            errorsAndWarnings.addError(MerkleIssue.Unsorted.parseInt());
            return (new bytes32[](0), errorsAndWarnings);
        }

        // The size of the proof is equal to the ceiling of log2(numLeaves)
        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        assembly {
            function hashLeafPairs(left, right) -> _hash {
                switch lt(left, right)
                case 0 {
                    mstore(0x0, right)
                    mstore(0x20, left)
                }
                default {
                    mstore(0x0, left)
                    mstore(0x20, right)
                }
                _hash := keccak256(0x0, 0x40)
            }
            function hashLevel(_data, length, _hashOddWithZero) -> newLength {
                // we will be modifying data in-place, so set result pointer to data pointer
                let _result := _data
                // get length of original data array
                // let length := mload(_data)
                // bool to track if we need to hash the last element of an odd-length array with zero
                let oddLength

                // if length is odd, we'll need to hash the last element with zero
                switch and(length, 1)
                case 1 {
                    // if length is odd, add 1 so division by 2 will round up
                    newLength := add(1, div(length, 2))
                    oddLength := 1
                }
                default {
                    newLength := div(length, 2)
                }
                // todo: necessary?
                // mstore(_data, newLength)
                let resultIndexPointer := add(0x20, _data)
                let dataIndexPointer := resultIndexPointer

                // stop iterating over for loop at length-1
                let stopIteration := add(_data, mul(length, 0x20))
                // write result array in-place over data array
                for {

                } lt(dataIndexPointer, stopIteration) {

                } {
                    // get next two elements from data, hash them together
                    let data1 := mload(dataIndexPointer)
                    let data2 := mload(add(dataIndexPointer, 0x20))
                    let hashedPair := hashLeafPairs(data1, data2)
                    // overwrite an element of data array with
                    mstore(resultIndexPointer, hashedPair)
                    // increment result pointer by 1 slot
                    resultIndexPointer := add(0x20, resultIndexPointer)
                    // increment data pointer by 2 slot
                    dataIndexPointer := add(0x40, dataIndexPointer)
                }
                // we did not yet hash last index if odd-length
                if oddLength {
                    let data1 := mload(dataIndexPointer)
                    let nextValue
                    switch _hashOddWithZero
                    case 0 {
                        nextValue := data1
                    }
                    default {
                        nextValue := hashLeafPairs(data1, 0)
                    }
                    mstore(resultIndexPointer, nextValue)
                }
            }

            // set result pointer to free memory
            result := mload(0x40)
            // get pointer to first index of result
            let resultIndexPtr := add(0x20, result)
            // declare so we can use later
            let newLength
            // put length of data onto stack
            let dataLength := mload(data)
            for {
                // repeat until only one element is left
            } gt(dataLength, 1) {

            } {
                // bool if node is odd
                let oddNodeIndex := and(node, 1)
                // bool if node is last
                let lastNodeIndex := eq(dataLength, add(1, node))
                // store both bools in one value so we can switch on it
                let switchVal := or(shl(1, lastNodeIndex), oddNodeIndex)
                switch switchVal
                // 00 - neither odd nor last
                case 0 {
                    // store data[node+1] at result[i]
                    // get pointer to result[node+1] by adding 2 to node and multiplying by 0x20
                    // to account for the fact that result points to array length, not first index
                    mstore(
                        resultIndexPtr,
                        mload(add(data, mul(0x20, add(2, node))))
                    )
                }
                // 10 - node is last
                case 2 {
                    // store 0 at result[i]
                    mstore(resultIndexPtr, 0)
                }
                // 01 or 11 - node is odd (and possibly also last)
                default {
                    // store data[node-1] at result[i]
                    mstore(resultIndexPtr, mload(add(data, mul(0x20, node))))
                }
                // increment result index
                resultIndexPtr := add(0x20, resultIndexPtr)

                // get new node index
                node := div(node, 2)
                // keep track of how long result array is
                newLength := add(1, newLength)
                // compute the next hash level, overwriting data, and get the new length
                dataLength := hashLevel(data, dataLength, hashOddWithZero)
            }
            // store length of result array at pointer
            mstore(result, newLength)
            // set free mem pointer to word after end of result array
            mstore(0x40, resultIndexPtr)
        }
    }

    /**
     * Hashes each element of the input array in place using keccak256
     */
    function _processInput(uint256[] memory data)
        private
        pure
        returns (bool sorted)
    {
        sorted = true;

        // Hash inputs with keccak256
        for (uint256 i = 0; i < data.length; ++i) {
            assembly {
                mstore(
                    add(data, mul(0x20, add(1, i))),
                    keccak256(add(data, mul(0x20, add(1, i))), 0x20)
                )
                // for every element after the first, hashed value must be greater than the last one
                if and(
                    gt(i, 0),
                    iszero(
                        gt(
                            mload(add(data, mul(0x20, add(1, i)))),
                            mload(add(data, mul(0x20, add(1, sub(i, 1)))))
                        )
                    )
                ) {
                    sorted := 0 // Elements not ordered by hash
                }
            }
        }
    }

    // Sort uint256 in order of the keccak256 hashes
    struct HashAndIntTuple {
        uint256 num;
        bytes32 hash;
    }

    function _sortUint256ByHash(uint256[] memory values)
        internal
        pure
        returns (uint256[] memory sortedValues)
    {
        HashAndIntTuple[] memory toSort = new HashAndIntTuple[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            toSort[i] = HashAndIntTuple(
                values[i],
                keccak256(abi.encode(values[i]))
            );
        }

        _quickSort(toSort, 0, int256(toSort.length - 1));

        sortedValues = new uint256[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            sortedValues[i] = toSort[i].num;
        }
    }

    function _quickSort(
        HashAndIntTuple[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        bytes32 pivot = arr[uint256(left + (right - left) / 2)].hash;
        while (i <= j) {
            while (arr[uint256(i)].hash < pivot) i++;
            while (pivot < arr[uint256(j)].hash) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library SafeStaticCall {
    function safeStaticCallBool(
        address target,
        bytes memory callData,
        bool expectedReturn
    ) internal view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        if (
            bytes32(res) &
                0x0000000000000000000000000000000000000000000000000000000000000001 !=
            bytes32(res)
        ) {
            return false;
        }

        return expectedReturn ? res[31] == 0x01 : res[31] == 0;
    }

    function safeStaticCallAddress(
        address target,
        bytes memory callData,
        address expectedReturn
    ) internal view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        if (
            bytes32(res) &
                0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF !=
            bytes32(res)
        ) {
            // Ensure only 20 bytes used
            return false;
        }

        return abi.decode(res, (address)) == expectedReturn;
    }

    function safeStaticCallUint256(
        address target,
        bytes memory callData,
        uint256 minExpectedReturn
    ) internal view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;

        return abi.decode(res, (uint256)) >= minExpectedReturn;
    }

    function safeStaticCallBytes4(
        address target,
        bytes memory callData,
        bytes4 expectedReturn
    ) internal view returns (bool) {
        (bool success, bytes memory res) = target.staticcall(callData);
        if (!success) return false;
        if (res.length != 32) return false;
        if (
            bytes32(res) &
                0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 !=
            bytes32(res)
        ) {
            // Ensure only 4 bytes used
            return false;
        }

        return abi.decode(res, (bytes4)) == expectedReturn;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct ValidationConfiguration {
    /// @notice Recipient for primary fee payments.
    address primaryFeeRecipient;
    /// @notice Bips for primary fee payments.
    uint256 primaryFeeBips;
    /// @notice Should creator fees be checked?
    bool checkCreatorFee;
    /// @notice Should strict validation be skipped?
    bool skipStrictValidation;
    /// @notice Short order duration in seconds
    uint256 shortOrderDuration;
    /// @notice Distant order expiration delta in seconds. Warning if order expires in longer than this.
    uint256 distantOrderExpiration;
}

enum GenericIssue {
    InvalidOrderFormat // 100
}

enum ERC20Issue {
    IdentifierNonZero, // 200
    InvalidToken, // 201
    InsufficientAllowance, // 202
    InsufficientBalance // 203
}

enum ERC721Issue {
    AmountNotOne, // 300
    InvalidToken, // 301
    IdentifierDNE, // 302
    NotOwner, // 303
    NotApproved, // 304
    CriteriaNotPartialFill // 305
}

enum ERC1155Issue {
    InvalidToken, // 400
    NotApproved, // 401
    InsufficientBalance // 402
}

enum ConsiderationIssue {
    AmountZero, // 500
    NullRecipient, // 501
    ExtraItems, // 502
    PrivateSaleToSelf, // 503
    ZeroItems, // 504
    DuplicateItem, // 505
    OffererNotReceivingAtLeastOneItem, // 506
    PrivateSale, // 507
    AmountVelocityHigh, // 508
    AmountStepLarge // 509
}

enum OfferIssue {
    ZeroItems, // 600
    AmountZero, // 601
    MoreThanOneItem, // 602
    NativeItem, // 603
    DuplicateItem, // 604
    AmountVelocityHigh, // 605
    AmountStepLarge // 606
}

enum PrimaryFeeIssue {
    Missing, // 700
    ItemType, // 701
    Token, // 702
    StartAmount, // 703
    EndAmount, // 704
    Recipient // 705
}

enum StatusIssue {
    Cancelled, // 800
    FullyFilled, // 801
    ContractOrder // 802
}

enum TimeIssue {
    EndTimeBeforeStartTime, // 900
    Expired, // 901
    DistantExpiration, // 902
    NotActive, // 903
    ShortOrder // 904
}

enum ConduitIssue {
    KeyInvalid, // 1000
    MissingCanonicalSeaportChannel // 1001
}

enum SignatureIssue {
    Invalid, // 1100
    ContractOrder, // 1101
    LowCounter, // 1102
    HighCounter, // 1103
    OriginalConsiderationItems // 1104
}

enum CreatorFeeIssue {
    Missing, // 1200
    ItemType, // 1201
    Token, // 1202
    StartAmount, // 1203
    EndAmount, // 1204
    Recipient // 1205
}

enum NativeIssue {
    TokenAddress, // 1300
    IdentifierNonZero, // 1301
    InsufficientBalance // 1302
}

enum ZoneIssue {
    InvalidZone, // 1400
    RejectedOrder, // 1401
    NotSet // 1402
}

enum MerkleIssue {
    SingleLeaf, // 1500
    Unsorted // 1501
}

enum ContractOffererIssue {
    InvalidContractOfferer // 1600
}

/**
 * @title IssueParser - parse issues into integers
 * @notice Implements a `parseInt` function for each issue type.
 *    offsets the enum value to place within the issue range.
 */
library IssueParser {
    function parseInt(GenericIssue err) internal pure returns (uint16) {
        return uint16(err) + 100;
    }

    function parseInt(ERC20Issue err) internal pure returns (uint16) {
        return uint16(err) + 200;
    }

    function parseInt(ERC721Issue err) internal pure returns (uint16) {
        return uint16(err) + 300;
    }

    function parseInt(ERC1155Issue err) internal pure returns (uint16) {
        return uint16(err) + 400;
    }

    function parseInt(ConsiderationIssue err) internal pure returns (uint16) {
        return uint16(err) + 500;
    }

    function parseInt(OfferIssue err) internal pure returns (uint16) {
        return uint16(err) + 600;
    }

    function parseInt(PrimaryFeeIssue err) internal pure returns (uint16) {
        return uint16(err) + 700;
    }

    function parseInt(StatusIssue err) internal pure returns (uint16) {
        return uint16(err) + 800;
    }

    function parseInt(TimeIssue err) internal pure returns (uint16) {
        return uint16(err) + 900;
    }

    function parseInt(ConduitIssue err) internal pure returns (uint16) {
        return uint16(err) + 1000;
    }

    function parseInt(SignatureIssue err) internal pure returns (uint16) {
        return uint16(err) + 1100;
    }

    function parseInt(CreatorFeeIssue err) internal pure returns (uint16) {
        return uint16(err) + 1200;
    }

    function parseInt(NativeIssue err) internal pure returns (uint16) {
        return uint16(err) + 1300;
    }

    function parseInt(ZoneIssue err) internal pure returns (uint16) {
        return uint16(err) + 1400;
    }

    function parseInt(MerkleIssue err) internal pure returns (uint16) {
        return uint16(err) + 1500;
    }

    function parseInt(ContractOffererIssue err) internal pure returns (uint16) {
        return uint16(err) + 1600;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ERC20Interface
 * @notice Contains the minimum interfaces needed to interact with ERC20s.
 */
interface ERC20Interface {
    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from  The address of the owner.
     * @param to    The address of the recipient.
     * @param value The amount of tokens to transfer.
     *
     * @return success True if the transfer was successful.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /**
     * @dev Allows an operator to approve a spender to transfer tokens on behalf
     *      of a user.
     *
     * @param spender The address of the spender.
     * @param value   The amount of tokens to approve.
     *
     * @return success True if the approval was successful.
     */

    function approve(
        address spender,
        uint256 value
    ) external returns (bool success);

    /**
     * @dev Returns the balance of a user.
     *
     * @param account The address of the user.
     *
     * @return balance The balance of the user.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount which spender is still allowed to withdraw from owner.
     *
     * @param owner   The address of the owner.
     * @param spender The address of the spender.
     *
     * @return remaining The amount of tokens that the spender is allowed to
     *                   transfer on behalf of the owner.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256 remaining);
}

/**
 * @title ERC721Interface
 * @notice Contains the minimum interfaces needed to interact with ERC721s.
 */
interface ERC721Interface {
    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from    The address of the owner.
     * @param to      The address of the recipient.
     * @param tokenId The ID of the token to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Allows an owner to approve an operator to transfer all tokens on a
     *      contract on behalf of the owner.
     *
     * @param to       The address of the operator.
     * @param approved Whether the operator is approved.
     */
    function setApprovalForAll(address to, bool approved) external;

    /**
     * @dev Returns the account approved for tokenId token
     *
     * @param tokenId The tokenId to query the approval of.
     *
     * @return operator The approved account of the tokenId.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns whether an operator is allowed to manage all of
     *      the assets of owner.
     *
     * @param owner    The address of the owner.
     * @param operator The address of the operator.
     *
     * @return approved True if the operator is approved by the owner.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * @dev Returns the owner of a given token ID.
     *
     * @param tokenId The token ID.
     *
     * @return owner The owner of the token.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * @title ERC1155Interface
 * @notice Contains the minimum interfaces needed to interact with ERC1155s.
 */
interface ERC1155Interface {
    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from   The address of the owner.
     * @param to     The address of the recipient.
     * @param id     The ID of the token(s) to transfer.
     * @param amount The amount of tokens to transfer.
     * @param data   Additional data.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Allows an operator to transfer tokens on behalf of an owner.
     *
     * @param from    The address of the owner.
     * @param to      The address of the recipient.
     * @param ids     The IDs of the token(s) to transfer.
     * @param amounts The amounts of tokens to transfer.
     * @param data    Additional data.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @dev Returns the amount of token type id owned by account.
     *
     * @param account The address of the account.
     * @param id      The id of the token.
     *
     * @return balance The amount of tokens of type id owned by account.
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @dev Allows an owner to approve an operator to transfer all tokens on a
     *      contract on behalf of the owner.
     *
     * @param to       The address of the operator.
     * @param approved Whether the operator is approved.
     */
    function setApprovalForAll(address to, bool approved) external;

    /**
     * @dev Returns true if operator is approved to transfer account's tokens.
     *
     * @param account  The address of the account.
     * @param operator The address of the operator.
     *
     * @return approved True if the operator is approved to transfer account's
     *                  tokens.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ConduitControllerInterface
 * @author 0age
 * @notice ConduitControllerInterface contains all external function interfaces,
 *         structs, events, and errors for the conduit controller.
 */
interface ConduitControllerInterface {
    /**
     * @dev Track the conduit key, current owner, new potential owner, and open
     *      channels for each deployed conduit.
     */
    struct ConduitProperties {
        bytes32 key;
        address owner;
        address potentialOwner;
        address[] channels;
        mapping(address => uint256) channelIndexesPlusOne;
    }

    /**
     * @dev Emit an event whenever a new conduit is created.
     *
     * @param conduit    The newly created conduit.
     * @param conduitKey The conduit key used to create the new conduit.
     */
    event NewConduit(address conduit, bytes32 conduitKey);

    /**
     * @dev Emit an event whenever conduit ownership is transferred.
     *
     * @param conduit       The conduit for which ownership has been
     *                      transferred.
     * @param previousOwner The previous owner of the conduit.
     * @param newOwner      The new owner of the conduit.
     */
    event OwnershipTransferred(
        address indexed conduit,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emit an event whenever a conduit owner registers a new potential
     *      owner for that conduit.
     *
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    event PotentialOwnerUpdated(address indexed newPotentialOwner);

    /**
     * @dev Revert with an error when attempting to create a new conduit using a
     *      conduit key where the first twenty bytes of the key do not match the
     *      address of the caller.
     */
    error InvalidCreator();

    /**
     * @dev Revert with an error when attempting to create a new conduit when no
     *      initial owner address is supplied.
     */
    error InvalidInitialOwner();

    /**
     * @dev Revert with an error when attempting to set a new potential owner
     *      that is already set.
     */
    error NewPotentialOwnerAlreadySet(
        address conduit,
        address newPotentialOwner
    );

    /**
     * @dev Revert with an error when attempting to cancel ownership transfer
     *      when no new potential owner is currently set.
     */
    error NoPotentialOwnerCurrentlySet(address conduit);

    /**
     * @dev Revert with an error when attempting to interact with a conduit that
     *      does not yet exist.
     */
    error NoConduit();

    /**
     * @dev Revert with an error when attempting to create a conduit that
     *      already exists.
     */
    error ConduitAlreadyExists(address conduit);

    /**
     * @dev Revert with an error when attempting to update channels or transfer
     *      ownership of a conduit when the caller is not the owner of the
     *      conduit in question.
     */
    error CallerIsNotOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsZeroAddress(address conduit);

    /**
     * @dev Revert with an error when attempting to claim ownership of a conduit
     *      with a caller that is not the current potential owner for the
     *      conduit in question.
     */
    error CallerIsNotNewPotentialOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to retrieve a channel using an
     *      index that is out of range.
     */
    error ChannelOutOfRange(address conduit);

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(
        bytes32 conduitKey,
        address initialOwner
    ) external returns (address conduit);

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(
        address conduit,
        address newPotentialOwner
    ) external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external;

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit) external view returns (address owner);

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit) external view returns (bytes32 conduitKey);

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(
        bytes32 conduitKey
    ) external view returns (address conduit, bool exists);

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(
        address conduit
    ) external view returns (address potentialOwner);

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(
        address conduit,
        address channel
    ) external view returns (bool isOpen);

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(
        address conduit
    ) external view returns (uint256 totalChannels);

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(
        address conduit,
        uint256 channelIndex
    ) external view returns (address channel);

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(
        address conduit
    ) external view returns (address[] memory channels);

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    OrderParameters,
    ReceivedItem,
    SpentItem
} from "../lib/ConsiderationStructs.sol";

/**
 * @title ConsiderationEventsAndErrors
 * @author 0age
 * @notice ConsiderationEventsAndErrors contains all events and errors.
 */
interface ConsiderationEventsAndErrors {
    /**
     * @dev Emit an event whenever an order is successfully fulfilled.
     *
     * @param orderHash     The hash of the fulfilled order.
     * @param offerer       The offerer of the fulfilled order.
     * @param zone          The zone of the fulfilled order.
     * @param recipient     The recipient of each spent item on the fulfilled
     *                      order, or the null address if there is no specific
     *                      fulfiller (i.e. the order is part of a group of
     *                      orders). Defaults to the caller unless explicitly
     *                      specified otherwise by the fulfiller.
     * @param offer         The offer items spent as part of the order.
     * @param consideration The consideration items received as part of the
     *                      order along with the recipients of each item.
     */
    event OrderFulfilled(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone,
        address recipient,
        SpentItem[] offer,
        ReceivedItem[] consideration
    );

    /**
     * @dev Emit an event whenever an order is successfully cancelled.
     *
     * @param orderHash The hash of the cancelled order.
     * @param offerer   The offerer of the cancelled order.
     * @param zone      The zone of the cancelled order.
     */
    event OrderCancelled(
        bytes32 orderHash,
        address indexed offerer,
        address indexed zone
    );

    /**
     * @dev Emit an event whenever an order is explicitly validated. Note that
     *      this event will not be emitted on partial fills even though they do
     *      validate the order as part of partial fulfillment.
     *
     * @param orderHash        The hash of the validated order.
     * @param orderParameters  The parameters of the validated order.
     */
    event OrderValidated(bytes32 orderHash, OrderParameters orderParameters);

    /**
     * @dev Emit an event whenever one or more orders are matched using either
     *      matchOrders or matchAdvancedOrders.
     *
     * @param orderHashes The order hashes of the matched orders.
     */
    event OrdersMatched(bytes32[] orderHashes);

    /**
     * @dev Emit an event whenever a counter for a given offerer is incremented.
     *
     * @param newCounter The new counter for the offerer.
     * @param offerer    The offerer in question.
     */
    event CounterIncremented(uint256 newCounter, address indexed offerer);

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      already been fully filled.
     *
     * @param orderHash The order hash on which a fill was attempted.
     */
    error OrderAlreadyFilled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to fill an order outside the
     *      specified start time and end time.
     *
     * @param startTime The time at which the order becomes active.
     * @param endTime   The time at which the order becomes inactive.
     */
    error InvalidTime(uint256 startTime, uint256 endTime);

    /**
     * @dev Revert with an error when attempting to fill an order referencing an
     *      invalid conduit (i.e. one that has not been deployed).
     */
    error InvalidConduit(bytes32 conduitKey, address conduit);

    /**
     * @dev Revert with an error when an order is supplied for fulfillment with
     *      a consideration array that is shorter than the original array.
     */
    error MissingOriginalConsiderationItems();

    /**
     * @dev Revert with an error when an order is validated and the length of
     *      the consideration array is not equal to the supplied total original
     *      consideration items value. This error is also thrown when contract
     *      orders supply a total original consideration items value that does
     *      not match the supplied consideration array length.
     */
    error ConsiderationLengthNotEqualToTotalOriginal();

    /**
     * @dev Revert with an error when a call to a conduit fails with revert data
     *      that is too expensive to return.
     */
    error InvalidCallToConduit(address conduit);

    /**
     * @dev Revert with an error if a consideration amount has not been fully
     *      zeroed out after applying all fulfillments.
     *
     * @param orderIndex         The index of the order with the consideration
     *                           item with a shortfall.
     * @param considerationIndex The index of the consideration item on the
     *                           order.
     * @param shortfallAmount    The unfulfilled consideration amount.
     */
    error ConsiderationNotMet(
        uint256 orderIndex,
        uint256 considerationIndex,
        uint256 shortfallAmount
    );

    /**
     * @dev Revert with an error when insufficient native tokens are supplied as
     *      part of msg.value when fulfilling orders.
     */
    error InsufficientNativeTokensSupplied();

    /**
     * @dev Revert with an error when a native token transfer reverts.
     */
    error NativeTokenTransferGenericFailure(address account, uint256 amount);

    /**
     * @dev Revert with an error when a partial fill is attempted on an order
     *      that does not specify partial fill support in its order type.
     */
    error PartialFillsNotEnabledForOrder();

    /**
     * @dev Revert with an error when attempting to fill an order that has been
     *      cancelled.
     *
     * @param orderHash The hash of the cancelled order.
     */
    error OrderIsCancelled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to fill a basic order that has
     *      been partially filled.
     *
     * @param orderHash The hash of the partially used order.
     */
    error OrderPartiallyFilled(bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to cancel an order as a caller
     *      other than the indicated offerer or zone or when attempting to
     *      cancel a contract order.
     */
    error CannotCancelOrder();

    /**
     * @dev Revert with an error when supplying a fraction with a value of zero
     *      for the numerator or denominator, or one where the numerator exceeds
     *      the denominator.
     */
    error BadFraction();

    /**
     * @dev Revert with an error when a caller attempts to supply callvalue to a
     *      non-payable basic order route or does not supply any callvalue to a
     *      payable basic order route.
     */
    error InvalidMsgValue(uint256 value);

    /**
     * @dev Revert with an error when attempting to fill a basic order using
     *      calldata not produced by default ABI encoding.
     */
    error InvalidBasicOrderParameterEncoding();

    /**
     * @dev Revert with an error when attempting to fulfill any number of
     *      available orders when none are fulfillable.
     */
    error NoSpecifiedOrdersAvailable();

    /**
     * @dev Revert with an error when attempting to fulfill an order with an
     *      offer for a native token outside of matching orders.
     */
    error InvalidNativeOfferItem();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    AdvancedOrder,
    BasicOrderParameters,
    CriteriaResolver,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    Order,
    OrderComponents
} from "../lib/ConsiderationStructs.sol";

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1.4
 * @notice Consideration is a generalized native token/ERC20/ERC721/ERC1155
 *         marketplace. It minimizes external calls to the greatest extent
 *         possible and provides lightweight methods for common routes as well
 *         as more flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their preferred conduit if indicated by the order) for
     *                   their offered ERC721 token to be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(
        BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @param order               The order to fulfill. Note that both the
     *                            offerer and the fulfiller must first approve
     *                            this contract (or the corresponding conduit if
     *                            indicated) to transfer any relevant tokens on
     *                            their behalf and that contracts must implement
     *                            `onERC1155Received` to receive ERC1155 tokens
     *                            as consideration.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillOrder(
        Order calldata order,
        bytes32 fulfillerConduitKey
    ) external payable returns (bool fulfilled);

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder       The order to fulfill along with the fraction
     *                            of the order to attempt to fill. Note that
     *                            both the offerer and the fulfiller must first
     *                            approve this contract (or their preferred
     *                            conduit if indicated by the order) to transfer
     *                            any relevant tokens on their behalf and that
     *                            contracts must implement `onERC1155Received`
     *                            to receive ERC1155 tokens as consideration.
     *                            Also note that all offer and consideration
     *                            components must have no remainder after
     *                            multiplication of the respective amount with
     *                            the supplied fraction for the partial fill to
     *                            be considered valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the merkle root held by the item
     *                            in question's criteria element. Note that an
     *                            empty criteria indicates that any
     *                            (transferable) token identifier on the token
     *                            in question is valid and that no associated
     *                            proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     * @param recipient           The intended recipient for all received items,
     *                            with `address(0)` indicating that the caller
     *                            should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    /**
     * @notice Attempt to fill a group of orders, each with an arbitrary number
     *         of items for offer and consideration. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *         Note that this function does not support criteria-based orders or
     *         partial filling of orders (though filling the remainder of a
     *         partially-filled order is supported).
     *
     * @param orders                    The orders to fulfill. Note that both
     *                                  the offerer and the fulfiller must first
     *                                  approve this contract (or the
     *                                  corresponding conduit if indicated) to
     *                                  transfer any relevant tokens on their
     *                                  behalf and that contracts must implement
     *                                  `onERC1155Received` to receive ERC1155
     *                                  tokens as consideration.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders. Note that unspent offer item amounts or
     *                         native tokens will not be reflected as part of
     *                         this array.
     */
    function fulfillAvailableOrders(
        Order[] calldata orders,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or their preferred conduit if
     *                                  indicated by the order) to transfer any
     *                                  relevant tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` to enable receipt of
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param recipient                 The intended recipient for all received
     *                                  items, with `address(0)` indicating that
     *                                  the caller should receive the items.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders. Note that unspent offer item amounts or
     *                         native tokens will not be reflected as part of
     *                         this array.
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with a set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported). Any unspent
     *         offer item amounts or native tokens will be transferred to the
     *         caller.
     *
     * @param orders       The orders to match. Note that both the offerer and
     *                     fulfiller on each order must first approve this
     *                     contract (or their conduit if indicated by the order)
     *                     to transfer any relevant tokens on their behalf and
     *                     each consideration recipient must implement
     *                     `onERC1155Received` to enable ERC1155 token receipt.
     * @param fulfillments An array of elements allocating offer components to
     *                     consideration components. Note that each
     *                     consideration component must be fully met for the
     *                     match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders. Note that unspent offer item amounts or
     *                    native tokens will not be reflected as part of this
     *                    array.
     */
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of full or partial orders, each with an
     *         arbitrary number of items for offer and consideration, supplying
     *         criteria resolvers containing specific token identifiers and
     *         associated proofs as well as fulfillments allocating offer
     *         components to consideration components. Any unspent offer item
     *         amounts will be transferred to the designated recipient (with the
     *         null address signifying to use the caller) and any unspent native
     *         tokens will be returned to the caller.
     *
     * @param orders            The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or a preferred conduit if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order to receive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     * @param recipient         The intended recipient for all unspent offer
     *                          item amounts, or the caller if the null address
     *                          is supplied.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders. Note that unspent offer item amounts or native
     *                    tokens will not be reflected as part of this array.
     */
    function matchAdvancedOrders(
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments,
        address recipient
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Cancel an arbitrary number of orders. Note that only the offerer
     *         or the zone of a given order may cancel it. Callers should ensure
     *         that the intended order was cancelled by calling `getOrderStatus`
     *         and confirming that `isCancelled` returns `true`.
     *
     * @param orders The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancel(
        OrderComponents[] calldata orders
    ) external returns (bool cancelled);

    /**
     * @notice Validate an arbitrary number of orders, thereby registering their
     *         signatures as valid and allowing the fulfiller to skip signature
     *         verification on fulfillment. Note that validated orders may still
     *         be unfulfillable due to invalid item amounts or other factors;
     *         callers should determine whether validated orders are fulfillable
     *         by simulating the fulfillment call prior to execution. Also note
     *         that anyone can validate a signed order, but only the offerer can
     *         validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return validated A boolean indicating whether the supplied orders have
     *                   been successfully validated.
     */
    function validate(
        Order[] calldata orders
    ) external returns (bool validated);

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a counter. Note that only the offerer may
     *         increment the counter.
     *
     * @return newCounter The new counter.
     */
    function incrementCounter() external returns (uint256 newCounter);

    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration. Note that this function costs less gas than
     *         `fulfillBasicOrder` due to the zero bytes in the function
     *         selector (0x00000000) which also results in earlier function
     *         dispatch.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their preferred conduit if indicated by the order) for
     *                   their offered ERC721 token to be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder_efficient_6GL6yc(
        BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @param order The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(
        OrderComponents calldata order
    ) external view returns (bytes32 orderHash);

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(
        bytes32 orderHash
    )
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(
        address offerer
    ) external view returns (uint256 counter);

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        );

    function getContractOffererNonce(
        address contractOfferer
    ) external view returns (uint256 nonce);

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return contractName The name of this contract.
     */
    function name() external view returns (string memory contractName);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    ReceivedItem,
    Schema,
    SpentItem
} from "../lib/ConsiderationStructs.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

/**
 * @title ContractOffererInterface
 * @notice Contains the minimum interfaces needed to interact with a contract
 *         offerer.
 */
interface ContractOffererInterface is IERC165 {
    /**
     * @dev Generates an order with the specified minimum and maximum spent
     *      items, and optional context (supplied as extraData).
     *
     * @param fulfiller       The address of the fulfiller.
     * @param minimumReceived The minimum items that the caller is willing to
     *                        receive.
     * @param maximumSpent    The maximum items the caller is willing to spend.
     * @param context         Additional context of the order.
     *
     * @return offer         A tuple containing the offer items.
     * @return consideration A tuple containing the consideration items.
     */
    function generateOrder(
        address fulfiller,
        SpentItem[] calldata minimumReceived,
        SpentItem[] calldata maximumSpent,
        bytes calldata context // encoded based on the schemaID
    )
        external
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration);

    /**
     * @dev Ratifies an order with the specified offer, consideration, and
     *      optional context (supplied as extraData).
     *
     * @param offer         The offer items.
     * @param consideration The consideration items.
     * @param context       Additional context of the order.
     * @param orderHashes   The hashes to ratify.
     * @param contractNonce The nonce of the contract.
     *
     * @return ratifyOrderMagicValue The magic value returned by the contract
     *                               offerer.
     */
    function ratifyOrder(
        SpentItem[] calldata offer,
        ReceivedItem[] calldata consideration,
        bytes calldata context, // encoded based on the schemaID
        bytes32[] calldata orderHashes,
        uint256 contractNonce
    ) external returns (bytes4 ratifyOrderMagicValue);

    /**
     * @dev View function to preview an order generated in response to a minimum
     *      set of received items, maximum set of spent items, and context
     *      (supplied as extraData).
     *
     * @param caller          The address of the caller (e.g. Seaport).
     * @param fulfiller       The address of the fulfiller (e.g. the account
     *                        calling Seaport).
     * @param minimumReceived The minimum items that the caller is willing to
     *                        receive.
     * @param maximumSpent    The maximum items the caller is willing to spend.
     * @param context         Additional context of the order.
     *
     * @return offer         A tuple containing the offer items.
     * @return consideration A tuple containing the consideration items.
     */
    function previewOrder(
        address caller,
        address fulfiller,
        SpentItem[] calldata minimumReceived,
        SpentItem[] calldata maximumSpent,
        bytes calldata context // encoded based on the schemaID
    )
        external
        view
        returns (SpentItem[] memory offer, ReceivedItem[] memory consideration);

    /**
     * @dev Gets the metadata for this contract offerer.
     *
     * @return name    The name of the contract offerer.
     * @return schemas The schemas supported by the contract offerer.
     */
    function getSeaportMetadata()
        external
        view
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        );

    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool);

    // Additional functions and/or events based on implemented schemaIDs
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ReentrancyErrors
 * @author 0age
 * @notice ReentrancyErrors contains errors related to reentrancy.
 */
interface ReentrancyErrors {
    /**
     * @dev Revert with an error when a caller attempts to reenter a protected
     *      function.
     */
    error NoReentrantCalls();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { ItemType } from "../lib/ConsiderationEnums.sol";
import {
    Order,
    OrderParameters,
    ZoneParameters
} from "../lib/ConsiderationStructs.sol";
import {
    ErrorsAndWarnings
} from "../helpers/order-validator/lib/ErrorsAndWarnings.sol";
import {
    ValidationConfiguration
} from "../helpers/order-validator/lib/SeaportValidatorTypes.sol";

/**
 * @title SeaportValidator
 * @notice SeaportValidator validates simple orders that adhere to a set of rules defined below:
 *    - The order is either a listing or an offer order (one NFT to buy or one NFT to sell).
 *    - The first consideration is the primary consideration.
 *    - The order pays up to two fees in the fungible token currency. First fee is primary fee, second is creator fee.
 *    - In private orders, the last consideration specifies a recipient for the offer item.
 *    - Offer items must be owned and properly approved by the offerer.
 *    - Consideration items must exist.
 */
interface SeaportValidatorInterface {
    /**
     * @notice Conduct a comprehensive validation of the given order.
     * @param order The order to validate.
     * @return errorsAndWarnings The errors and warnings found in the order.
     */
    function isValidOrder(
        Order calldata order
    ) external returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Same as `isValidOrder` but allows for more configuration related to fee validation.
     */
    function isValidOrderWithConfiguration(
        ValidationConfiguration memory validationConfiguration,
        Order memory order
    ) external returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Checks if a conduit key is valid.
     * @param conduitKey The conduit key to check.
     * @return errorsAndWarnings The errors and warnings
     */
    function isValidConduit(
        bytes32 conduitKey
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    // TODO: Need to add support for order with extra data
    /**
     * @notice Checks that the zone of an order implements the required interface
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function isValidZone(
        OrderParameters memory orderParameters
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    function validateSignature(
        Order memory order
    ) external returns (ErrorsAndWarnings memory errorsAndWarnings);

    function validateSignatureWithCounter(
        Order memory order,
        uint256 counter
    ) external returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Check the time validity of an order
     * @param orderParameters The parameters for the order to validate
     * @param shortOrderDuration The duration of which an order is considered short
     * @param distantOrderExpiration Distant order expiration delta in seconds.
     * @return errorsAndWarnings The Issues and warnings
     */
    function validateTime(
        OrderParameters memory orderParameters,
        uint256 shortOrderDuration,
        uint256 distantOrderExpiration
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate the status of an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOrderStatus(
        OrderParameters memory orderParameters
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate all offer items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateOfferItems(
        OrderParameters memory orderParameters
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate all consideration items for an order
     * @param orderParameters The parameters for the order to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItems(
        OrderParameters memory orderParameters
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Strict validation operates under tight assumptions. It validates primary
     *    fee, creator fee, private sale consideration, and overall order format.
     * @dev Only checks first fee recipient provided by CreatorFeeRegistry.
     *    Order of consideration items must be as follows:
     *    1. Primary consideration
     *    2. Primary fee
     *    3. Creator Fee
     *    4. Private sale consideration
     * @param orderParameters The parameters for the order to validate.
     * @param primaryFeeRecipient The primary fee recipient. Set to null address for no primary fee.
     * @param primaryFeeBips The primary fee in BIPs.
     * @param checkCreatorFee Should check for creator fee. If true, creator fee must be present as
     *    according to creator fee engine. If false, must not have creator fee.
     * @return errorsAndWarnings The errors and warnings.
     */
    function validateStrictLogic(
        OrderParameters memory orderParameters,
        address primaryFeeRecipient,
        uint256 primaryFeeBips,
        bool checkCreatorFee
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validate a consideration item
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItem(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates the parameters of a consideration item including contract validation
     * @param orderParameters The parameters for the order to validate
     * @param considerationItemIndex The index of the consideration item to validate
     * @return errorsAndWarnings  The errors and warnings
     */
    function validateConsiderationItemParameters(
        OrderParameters memory orderParameters,
        uint256 considerationItemIndex
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates an offer item
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItem(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates the OfferItem parameters. This includes token contract validation
     * @dev OfferItems with criteria are currently not allowed
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemParameters(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Validates the OfferItem approvals and balances
     * @param orderParameters The parameters for the order to validate
     * @param offerItemIndex The index of the offerItem in offer array to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOfferItemApprovalAndBalance(
        OrderParameters memory orderParameters,
        uint256 offerItemIndex
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Calls validateOrder on the order's zone with the given zoneParameters
     * @param orderParameters The parameters for the order to validate
     * @param zoneParameters The parameters for the zone to validate
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function validateOrderWithZone(
        OrderParameters memory orderParameters,
        ZoneParameters memory zoneParameters
    ) external view returns (ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Gets the approval address for the given conduit key
     * @param conduitKey Conduit key to get approval address for
     * @return errorsAndWarnings An ErrorsAndWarnings structs with results
     */
    function getApprovalAddress(
        bytes32 conduitKey
    )
        external
        view
        returns (address, ErrorsAndWarnings memory errorsAndWarnings);

    /**
     * @notice Safely check that a contract implements an interface
     * @param token The token address to check
     * @param interfaceHash The interface hash to check
     */
    function checkInterface(
        address token,
        bytes4 interfaceHash
    ) external view returns (bool);

    function isPaymentToken(ItemType itemType) external pure returns (bool);

    /*//////////////////////////////////////////////////////////////
                        Merkle Helpers
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sorts an array of token ids by the keccak256 hash of the id. Required ordering of ids
     *    for other merkle operations.
     * @param includedTokens An array of included token ids.
     * @return sortedTokens The sorted `includedTokens` array.
     */
    function sortMerkleTokens(
        uint256[] memory includedTokens
    ) external view returns (uint256[] memory sortedTokens);

    /**
     * @notice Creates a merkle root for includedTokens.
     * @dev `includedTokens` must be sorting in strictly ascending order according to the keccak256 hash of the value.
     * @return merkleRoot The merkle root
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleRoot(
        uint256[] memory includedTokens
    )
        external
        view
        returns (
            bytes32 merkleRoot,
            ErrorsAndWarnings memory errorsAndWarnings
        );

    /**
     * @notice Creates a merkle proof for the the targetIndex contained in includedTokens.
     * @dev `targetIndex` is referring to the index of an element in `includedTokens`.
     *    `includedTokens` must be sorting in ascending order according to the keccak256 hash of the value.
     * @return merkleProof The merkle proof
     * @return errorsAndWarnings Errors and warnings from the operation
     */
    function getMerkleProof(
        uint256[] memory includedTokens,
        uint256 targetIndex
    )
        external
        view
        returns (
            bytes32[] memory merkleProof,
            ErrorsAndWarnings memory errorsAndWarnings
        );

    function verifyMerkleProof(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        uint256 valueToProve
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title SignatureVerificationErrors
 * @author 0age
 * @notice SignatureVerificationErrors contains all errors related to signature
 *         verification.
 */
interface SignatureVerificationErrors {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
    /**
     * @dev Revert with an error when an ERC721 transfer with amount other than
     *      one is attempted.
     *
     * @param amount The amount of the ERC721 tokens to transfer.
     */
    error InvalidERC721TransferAmount(uint256 amount);

    /**
     * @dev Revert with an error when attempting to fulfill an order where an
     *      item has an amount of zero.
     */
    error MissingItemAmount();

    /**
     * @dev Revert with an error when attempting to fulfill an order where an
     *      item has unused parameters. This includes both the token and the
     *      identifier parameters for native transfers as well as the identifier
     *      parameter for ERC20 transfers. Note that the conduit does not
     *      perform this check, leaving it up to the calling channel to enforce
     *      when desired.
     */
    error UnusedItemParameters();

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param from       The source of the attempted transfer.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    );

    /**
     * @dev Revert with an error when a batch ERC1155 token transfer reverts.
     *
     * @param token       The token for which the transfer was attempted.
     * @param from        The source of the attempted transfer.
     * @param to          The recipient of the attempted transfer.
     * @param identifiers The identifiers for the attempted transfer.
     * @param amounts     The amounts for the attempted transfer.
     */
    error ERC1155BatchTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256[] identifiers,
        uint256[] amounts
    );

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param from       The source of the attempted ERC20 transfer.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    /**
     * @dev Revert with an error when an account being called as an assumed
     *      contract does not have code and returns no data.
     *
     * @param account The account that should contain code.
     */
    error NoContract(address account);

    /**
     * @dev Revert with an error when attempting to execute an 1155 batch
     *      transfer using calldata not produced by default ABI encoding or with
     *      different lengths for ids and amounts arrays.
     */
    error Invalid1155BatchTransferEncoding();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ZoneParameters, Schema } from "../lib/ConsiderationStructs.sol";

import { IERC165 } from "../interfaces/IERC165.sol";

/**
 * @title  ZoneInterface
 * @notice Contains functions exposed by a zone.
 */
interface ZoneInterface is IERC165 {
    /**
     * @dev Validates an order.
     *
     * @param zoneParameters The context about the order fulfillment and any
     *                       supplied extraData.
     *
     * @return validOrderMagicValue The magic value that indicates a valid
     *                              order.
     */
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external returns (bytes4 validOrderMagicValue);

    /**
     * @dev Returns the metadata for this zone.
     *
     * @return name The name of the zone.
     * @return schemas The schemas that the zone implements.
     */
    function getSeaportMetadata()
        external
        view
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        );

    function supportsInterface(
        bytes4 interfaceId
    ) external view override returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { OrderParameters } from "./ConsiderationStructs.sol";

import { GettersAndDerivers } from "./GettersAndDerivers.sol";

import {
    TokenTransferrerErrors
} from "../interfaces/TokenTransferrerErrors.sol";

import { CounterManager } from "./CounterManager.sol";

import {
    AdditionalRecipient_size_shift,
    AddressDirtyUpperBitThreshold,
    BasicOrder_additionalRecipients_head_cdPtr,
    BasicOrder_additionalRecipients_head_ptr,
    BasicOrder_additionalRecipients_length_cdPtr,
    BasicOrder_basicOrderType_cdPtr,
    BasicOrder_basicOrderType_range,
    BasicOrder_considerationToken_cdPtr,
    BasicOrder_offerer_cdPtr,
    BasicOrder_offerToken_cdPtr,
    BasicOrder_parameters_cdPtr,
    BasicOrder_parameters_ptr,
    BasicOrder_signature_cdPtr,
    BasicOrder_signature_ptr,
    BasicOrder_zone_cdPtr
} from "./ConsiderationConstants.sol";

import {
    Error_selector_offset,
    MissingItemAmount_error_length,
    MissingItemAmount_error_selector
} from "./ConsiderationErrorConstants.sol";

import {
    _revertInvalidBasicOrderParameterEncoding,
    _revertMissingOriginalConsiderationItems
} from "./ConsiderationErrors.sol";

/**
 * @title Assertions
 * @author 0age
 * @notice Assertions contains logic for making various assertions that do not
 *         fit neatly within a dedicated semantic scope.
 */
contract Assertions is
    GettersAndDerivers,
    CounterManager,
    TokenTransferrerErrors
{
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(
        address conduitController
    ) GettersAndDerivers(conduitController) {}

    /**
     * @dev Internal view function to ensure that the supplied consideration
     *      array length on a given set of order parameters is not less than the
     *      original consideration array length for that order and to retrieve
     *      the current counter for a given order's offerer and zone and use it
     *      to derive the order hash.
     *
     * @param orderParameters The parameters of the order to hash.
     *
     * @return The hash.
     */
    function _assertConsiderationLengthAndGetOrderHash(
        OrderParameters memory orderParameters
    ) internal view returns (bytes32) {
        // Ensure supplied consideration array length is not less than original.
        _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            orderParameters.consideration.length,
            orderParameters.totalOriginalConsiderationItems
        );

        // Derive and return order hash using current counter for the offerer.
        return
            _deriveOrderHash(
                orderParameters,
                _getCounter(orderParameters.offerer)
            );
    }

    /**
     * @dev Internal pure function to ensure that the supplied consideration
     *      array length for an order to be fulfilled is not less than the
     *      original consideration array length for that order.
     *
     * @param suppliedConsiderationItemTotal The number of consideration items
     *                                       supplied when fulfilling the order.
     * @param originalConsiderationItemTotal The number of consideration items
     *                                       supplied on initial order creation.
     */
    function _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
        uint256 suppliedConsiderationItemTotal,
        uint256 originalConsiderationItemTotal
    ) internal pure {
        // Ensure supplied consideration array length is not less than original.
        if (suppliedConsiderationItemTotal < originalConsiderationItemTotal) {
            _revertMissingOriginalConsiderationItems();
        }
    }

    /**
     * @dev Internal pure function to ensure that a given item amount is not
     *      zero.
     *
     * @param amount The amount to check.
     */
    function _assertNonZeroAmount(uint256 amount) internal pure {
        assembly {
            if iszero(amount) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, MissingItemAmount_error_selector)

                // revert(abi.encodeWithSignature("MissingItemAmount()"))
                revert(Error_selector_offset, MissingItemAmount_error_length)
            }
        }
    }

    /**
     * @dev Internal pure function to validate calldata offsets for dynamic
     *      types in BasicOrderParameters and other parameters. This ensures
     *      that functions using the calldata object normally will be using the
     *      same data as the assembly functions and that values that are bound
     *      to a given range are within that range. Note that no parameters are
     *      supplied as all basic order functions use the same calldata
     *      encoding.
     */
    function _assertValidBasicOrderParameters() internal pure {
        // Declare a boolean designating basic order parameter offset validity.
        bool validOffsets;

        // Utilize assembly in order to read offset data directly from calldata.
        assembly {
            /*
             * Checks:
             * 1. Order parameters struct offset == 0x20
             * 2. Additional recipients arr offset == 0x240
             * 3. Signature offset == 0x260 + (recipients.length * 0x40)
             * 4. BasicOrderType between 0 and 23 (i.e. < 24)
             * 5. Offerer, zone, offer token, and consideration token have no
             *    upper dirty bits — each argument is type(uint160).max or less
             */
            validOffsets := and(
                and(
                    and(
                        // Order parameters at cd 0x04 must have offset of 0x20.
                        eq(
                            calldataload(BasicOrder_parameters_cdPtr),
                            BasicOrder_parameters_ptr
                        ),
                        // Additional recipients (cd 0x224) arr offset == 0x240.
                        eq(
                            calldataload(
                                BasicOrder_additionalRecipients_head_cdPtr
                            ),
                            BasicOrder_additionalRecipients_head_ptr
                        )
                    ),
                    // Signature offset == 0x260 + (recipients.length * 0x40).
                    eq(
                        // Load signature offset from calldata 0x244.
                        calldataload(BasicOrder_signature_cdPtr),
                        // Expected offset is start of recipients + len * 64.
                        add(
                            BasicOrder_signature_ptr,
                            shl(
                                // Each additional recipient has length of 0x40.
                                AdditionalRecipient_size_shift,
                                // Additional recipients length at cd 0x264.
                                calldataload(
                                    BasicOrder_additionalRecipients_length_cdPtr
                                )
                            )
                        )
                    )
                ),
                and(
                    // Ensure BasicOrderType parameter is less than 0x18.
                    lt(
                        // BasicOrderType parameter at calldata offset 0x124.
                        calldataload(BasicOrder_basicOrderType_cdPtr),
                        // Value should be less than 24.
                        BasicOrder_basicOrderType_range
                    ),
                    // Ensure no dirty upper bits are present on offerer, zone,
                    // offer token, or consideration token.
                    lt(
                        or(
                            or(
                                // Offerer parameter at calldata offset 0x84.
                                calldataload(BasicOrder_offerer_cdPtr),
                                // Zone parameter at calldata offset 0xa4.
                                calldataload(BasicOrder_zone_cdPtr)
                            ),
                            or(
                                // Offer token parameter at cd offset 0xc4.
                                calldataload(BasicOrder_offerToken_cdPtr),
                                // Consideration token parameter at offset 0x24.
                                calldataload(
                                    BasicOrder_considerationToken_cdPtr
                                )
                            )
                        ),
                        AddressDirtyUpperBitThreshold
                    )
                )
            )
        }

        // Revert with an error if basic order parameter offsets are invalid.
        if (!validOffsets) {
            _revertInvalidBasicOrderParameterEncoding();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ConduitControllerInterface
} from "../interfaces/ConduitControllerInterface.sol";

import {
    ConsiderationEventsAndErrors
} from "../interfaces/ConsiderationEventsAndErrors.sol";

import {
    BulkOrder_Typehash_Height_One,
    BulkOrder_Typehash_Height_Two,
    BulkOrder_Typehash_Height_Three,
    BulkOrder_Typehash_Height_Four,
    BulkOrder_Typehash_Height_Five,
    BulkOrder_Typehash_Height_Six,
    BulkOrder_Typehash_Height_Seven,
    BulkOrder_Typehash_Height_Eight,
    BulkOrder_Typehash_Height_Nine,
    BulkOrder_Typehash_Height_Ten,
    BulkOrder_Typehash_Height_Eleven,
    BulkOrder_Typehash_Height_Twelve,
    BulkOrder_Typehash_Height_Thirteen,
    BulkOrder_Typehash_Height_Fourteen,
    BulkOrder_Typehash_Height_Fifteen,
    BulkOrder_Typehash_Height_Sixteen,
    BulkOrder_Typehash_Height_Seventeen,
    BulkOrder_Typehash_Height_Eighteen,
    BulkOrder_Typehash_Height_Nineteen,
    BulkOrder_Typehash_Height_Twenty,
    BulkOrder_Typehash_Height_TwentyOne,
    BulkOrder_Typehash_Height_TwentyTwo,
    BulkOrder_Typehash_Height_TwentyThree,
    BulkOrder_Typehash_Height_TwentyFour,
    EIP712_domainData_chainId_offset,
    EIP712_domainData_nameHash_offset,
    EIP712_domainData_size,
    EIP712_domainData_verifyingContract_offset,
    EIP712_domainData_versionHash_offset,
    FreeMemoryPointerSlot,
    NameLengthPtr,
    NameWithLength,
    OneWord,
    OneWordShift,
    Slot0x80,
    ThreeWords,
    ZeroSlot
} from "./ConsiderationConstants.sol";

import { ConsiderationDecoder } from "./ConsiderationDecoder.sol";
import { ConsiderationEncoder } from "./ConsiderationEncoder.sol";

/**
 * @title ConsiderationBase
 * @author 0age
 * @notice ConsiderationBase contains immutable constants and constructor logic.
 */
contract ConsiderationBase is
    ConsiderationDecoder,
    ConsiderationEncoder,
    ConsiderationEventsAndErrors
{
    // Precompute hashes, original chainId, and domain separator on deployment.
    bytes32 internal immutable _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH;
    bytes32 internal immutable _OFFER_ITEM_TYPEHASH;
    bytes32 internal immutable _CONSIDERATION_ITEM_TYPEHASH;
    bytes32 internal immutable _ORDER_TYPEHASH;
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    // Allow for interaction with the conduit controller.
    ConduitControllerInterface internal immutable _CONDUIT_CONTROLLER;

    // Cache the conduit creation code hash used by the conduit controller.
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;

    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) {
        // Derive name and version hashes alongside required EIP-712 typehashes.
        (
            _NAME_HASH,
            _VERSION_HASH,
            _EIP_712_DOMAIN_TYPEHASH,
            _OFFER_ITEM_TYPEHASH,
            _CONSIDERATION_ITEM_TYPEHASH,
            _ORDER_TYPEHASH
        ) = _deriveTypehashes();

        // Store the current chainId and derive the current domain separator.
        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();

        // Set the supplied conduit controller.
        _CONDUIT_CONTROLLER = ConduitControllerInterface(conduitController);

        // Retrieve the conduit creation code hash from the supplied controller.
        (_CONDUIT_CREATION_CODE_HASH, ) = (
            _CONDUIT_CONTROLLER.getConduitCodeHashes()
        );
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return domainSeparator The derived domain separator.
     */
    function _deriveDomainSeparator()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        bytes32 typehash = _EIP_712_DOMAIN_TYPEHASH;
        bytes32 nameHash = _NAME_HASH;
        bytes32 versionHash = _VERSION_HASH;

        // Leverage scratch space and other memory to perform an efficient hash.
        assembly {
            // Retrieve the free memory pointer; it will be replaced afterwards.
            let freeMemoryPointer := mload(FreeMemoryPointerSlot)

            // Retrieve value at 0x80; it will also be replaced afterwards.
            let slot0x80 := mload(Slot0x80)

            // Place typehash, name hash, and version hash at start of memory.
            mstore(0, typehash)
            mstore(EIP712_domainData_nameHash_offset, nameHash)
            mstore(EIP712_domainData_versionHash_offset, versionHash)

            // Place chainId in the next memory location.
            mstore(EIP712_domainData_chainId_offset, chainid())

            // Place the address of this contract in the next memory location.
            mstore(EIP712_domainData_verifyingContract_offset, address())

            // Hash relevant region of memory to derive the domain separator.
            domainSeparator := keccak256(0, EIP712_domainData_size)

            // Restore the free memory pointer.
            mstore(FreeMemoryPointerSlot, freeMemoryPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)

            // Restore the value at 0x80.
            mstore(Slot0x80, slot0x80)
        }
    }

    /**
     * @dev Internal pure function to retrieve the default name of this
     *      contract and return.
     *
     * @return The name of this contract.
     */
    function _name() internal pure virtual returns (string memory) {
        // Return the name of the contract.
        assembly {
            // First element is the offset for the returned string. Offset the
            // value in memory by one word so that the free memory pointer will
            // be overwritten by the next write.
            mstore(OneWord, OneWord)

            // Name is right padded, so it touches the length which is left
            // padded. This enables writing both values at once. The free memory
            // pointer will be overwritten in the process.
            mstore(NameLengthPtr, NameWithLength)

            // Standard ABI encoding pads returned data to the nearest word. Use
            // the already empty zero slot memory region for this purpose and
            // return the final name string, offset by the original single word.
            return(OneWord, ThreeWords)
        }
    }

    /**
     * @dev Internal pure function to retrieve the default name of this contract
     *      as a string that can be used internally.
     *
     * @return The name of this contract.
     */
    function _nameString() internal pure virtual returns (string memory) {
        // Return the name of the contract.
        return "Consideration";
    }

    /**
     * @dev Internal pure function to derive required EIP-712 typehashes and
     *      other hashes during contract creation.
     *
     * @return nameHash                  The hash of the name of the contract.
     * @return versionHash               The hash of the version string of the
     *                                   contract.
     * @return eip712DomainTypehash      The primary EIP-712 domain typehash.
     * @return offerItemTypehash         The EIP-712 typehash for OfferItem
     *                                   types.
     * @return considerationItemTypehash The EIP-712 typehash for
     *                                   ConsiderationItem types.
     * @return orderTypehash             The EIP-712 typehash for Order types.
     */
    function _deriveTypehashes()
        internal
        pure
        returns (
            bytes32 nameHash,
            bytes32 versionHash,
            bytes32 eip712DomainTypehash,
            bytes32 offerItemTypehash,
            bytes32 considerationItemTypehash,
            bytes32 orderTypehash
        )
    {
        // Derive hash of the name of the contract.
        nameHash = keccak256(bytes(_nameString()));

        // Derive hash of the version string of the contract.
        versionHash = keccak256(bytes("1.4"));

        // Construct the OfferItem type string.
        bytes memory offerItemTypeString = bytes(
            "OfferItem("
            "uint8 itemType,"
            "address token,"
            "uint256 identifierOrCriteria,"
            "uint256 startAmount,"
            "uint256 endAmount"
            ")"
        );

        // Construct the ConsiderationItem type string.
        bytes memory considerationItemTypeString = bytes(
            "ConsiderationItem("
            "uint8 itemType,"
            "address token,"
            "uint256 identifierOrCriteria,"
            "uint256 startAmount,"
            "uint256 endAmount,"
            "address recipient"
            ")"
        );

        // Construct the OrderComponents type string, not including the above.
        bytes memory orderComponentsPartialTypeString = bytes(
            "OrderComponents("
            "address offerer,"
            "address zone,"
            "OfferItem[] offer,"
            "ConsiderationItem[] consideration,"
            "uint8 orderType,"
            "uint256 startTime,"
            "uint256 endTime,"
            "bytes32 zoneHash,"
            "uint256 salt,"
            "bytes32 conduitKey,"
            "uint256 counter"
            ")"
        );

        // Construct the primary EIP-712 domain type string.
        eip712DomainTypehash = keccak256(
            bytes(
                "EIP712Domain("
                "string name,"
                "string version,"
                "uint256 chainId,"
                "address verifyingContract"
                ")"
            )
        );

        // Derive the OfferItem type hash using the corresponding type string.
        offerItemTypehash = keccak256(offerItemTypeString);

        // Derive ConsiderationItem type hash using corresponding type string.
        considerationItemTypehash = keccak256(considerationItemTypeString);

        bytes memory orderTypeString = bytes.concat(
            orderComponentsPartialTypeString,
            considerationItemTypeString,
            offerItemTypeString
        );

        // Derive OrderItem type hash via combination of relevant type strings.
        orderTypehash = keccak256(orderTypeString);
    }

    /**
     * @dev Internal pure function to look up one of twenty-four potential bulk
     *      order typehash constants based on the height of the bulk order tree.
     *      Note that values between one and twenty-four are supported, which is
     *      enforced by _isValidBulkOrderSize.
     *
     * @param _treeHeight The height of the bulk order tree. The value must be
     *                    between one and twenty-four.
     *
     * @return _typeHash The EIP-712 typehash for the bulk order type with the
     *                   given height.
     */
    function _lookupBulkOrderTypehash(
        uint256 _treeHeight
    ) internal pure returns (bytes32 _typeHash) {
        // Utilize assembly to efficiently retrieve correct bulk order typehash.
        assembly {
            // Use a Yul function to enable use of the `leave` keyword
            // to stop searching once the appropriate type hash is found.
            function lookupTypeHash(treeHeight) -> typeHash {
                // Handle tree heights one through eight.
                if lt(treeHeight, 9) {
                    // Handle tree heights one through four.
                    if lt(treeHeight, 5) {
                        // Handle tree heights one and two.
                        if lt(treeHeight, 3) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 1),
                                BulkOrder_Typehash_Height_One,
                                BulkOrder_Typehash_Height_Two
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height three and four via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 3),
                            BulkOrder_Typehash_Height_Three,
                            BulkOrder_Typehash_Height_Four
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height five and six.
                    if lt(treeHeight, 7) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 5),
                            BulkOrder_Typehash_Height_Five,
                            BulkOrder_Typehash_Height_Six
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height seven and eight via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 7),
                        BulkOrder_Typehash_Height_Seven,
                        BulkOrder_Typehash_Height_Eight
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height nine through sixteen.
                if lt(treeHeight, 17) {
                    // Handle tree height nine through twelve.
                    if lt(treeHeight, 13) {
                        // Handle tree height nine and ten.
                        if lt(treeHeight, 11) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 9),
                                BulkOrder_Typehash_Height_Nine,
                                BulkOrder_Typehash_Height_Ten
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height eleven and twelve via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 11),
                            BulkOrder_Typehash_Height_Eleven,
                            BulkOrder_Typehash_Height_Twelve
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height thirteen and fourteen.
                    if lt(treeHeight, 15) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 13),
                            BulkOrder_Typehash_Height_Thirteen,
                            BulkOrder_Typehash_Height_Fourteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }
                    // Handle height fifteen and sixteen via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 15),
                        BulkOrder_Typehash_Height_Fifteen,
                        BulkOrder_Typehash_Height_Sixteen
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height seventeen through twenty.
                if lt(treeHeight, 21) {
                    // Handle tree height seventeen and eighteen.
                    if lt(treeHeight, 19) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 17),
                            BulkOrder_Typehash_Height_Seventeen,
                            BulkOrder_Typehash_Height_Eighteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height nineteen and twenty via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 19),
                        BulkOrder_Typehash_Height_Nineteen,
                        BulkOrder_Typehash_Height_Twenty
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height twenty-one and twenty-two.
                if lt(treeHeight, 23) {
                    // Utilize branchless logic to determine typehash.
                    typeHash := ternary(
                        eq(treeHeight, 21),
                        BulkOrder_Typehash_Height_TwentyOne,
                        BulkOrder_Typehash_Height_TwentyTwo
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle height twenty-three & twenty-four w/ branchless logic.
                typeHash := ternary(
                    eq(treeHeight, 23),
                    BulkOrder_Typehash_Height_TwentyThree,
                    BulkOrder_Typehash_Height_TwentyFour
                )

                // Exit the function once typehash has been located.
                leave
            }

            // Implement ternary conditional using branchless logic.
            function ternary(cond, ifTrue, ifFalse) -> c {
                c := xor(ifFalse, mul(cond, xor(ifFalse, ifTrue)))
            }

            // Look up the typehash using the supplied tree height.
            _typeHash := lookupTypeHash(_treeHeight)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.17/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

// Declare constants for name, version, and reentrancy sentinel values.

// Name is right padded, so it touches the length which is left padded. This
// enables writing both values at once. Length goes at byte 95 in memory, and
// name fills bytes 96-109, so both values can be written left-padded to 77.
uint256 constant NameLengthPtr = 0x4D;
uint256 constant NameWithLength = 0x0d436F6E73696465726174696F6E;

uint256 constant information_version_offset = 0;
uint256 constant information_version_cd_offset = 0x60;
uint256 constant information_domainSeparator_offset = 0x20;
uint256 constant information_conduitController_offset = 0x40;
uint256 constant information_versionLengthPtr = 0x63;
uint256 constant information_versionWithLength = 0x03312e34; // 1.4
uint256 constant information_length = 0xa0;

uint256 constant _NOT_ENTERED = 1;
uint256 constant _ENTERED = 2;
uint256 constant _ENTERED_AND_ACCEPTING_NATIVE_TOKENS = 3;

uint256 constant Offset_fulfillAdvancedOrder_criteriaResolvers = 0x20;
uint256 constant Offset_fulfillAvailableOrders_offerFulfillments = 0x20;
uint256 constant Offset_fulfillAvailableOrders_considerationFulfillments = 0x40;
uint256 constant Offset_fulfillAvailableAdvancedOrders_criteriaResolvers = 0x20;
uint256 constant Offset_fulfillAvailableAdvancedOrders_offerFulfillments = 0x40;
uint256 constant Offset_fulfillAvailableAdvancedOrders_cnsdrationFlflmnts = (
    0x60
);

uint256 constant Offset_matchOrders_fulfillments = 0x20;

uint256 constant Offset_matchAdvancedOrders_criteriaResolvers = 0x20;
uint256 constant Offset_matchAdvancedOrders_fulfillments = 0x40;

// Common Offsets
// Offsets for identically positioned fields shared by:
// OfferItem, ConsiderationItem, SpentItem, ReceivedItem

uint256 constant Selector_length = 0x4;

uint256 constant Common_token_offset = 0x20;
uint256 constant Common_identifier_offset = 0x40;
uint256 constant Common_amount_offset = 0x60;
uint256 constant Common_endAmount_offset = 0x80;

uint256 constant SpentItem_size = 0x80;
uint256 constant SpentItem_size_shift = 0x7;

uint256 constant OfferItem_size = 0xa0;
uint256 constant OfferItem_size_with_length = 0xc0;

uint256 constant ReceivedItem_size_excluding_recipient = 0x80;
uint256 constant ReceivedItem_size = 0xa0;
uint256 constant ReceivedItem_amount_offset = 0x60;
uint256 constant ReceivedItem_recipient_offset = 0x80;

uint256 constant ReceivedItem_CommonParams_size = 0x60;

uint256 constant ConsiderationItem_size = 0xc0;
uint256 constant ConsiderationItem_size_with_length = 0xe0;

uint256 constant ConsiderationItem_recipient_offset = 0xa0;
// Store the same constant in an abbreviated format for a line length fix.
uint256 constant ConsiderItem_recipient_offset = 0xa0;

uint256 constant Execution_offerer_offset = 0x20;
uint256 constant Execution_conduit_offset = 0x40;

// uint256 constant OrderParameters_offerer_offset = 0x00;
uint256 constant OrderParameters_zone_offset = 0x20;
uint256 constant OrderParameters_offer_head_offset = 0x40;
uint256 constant OrderParameters_consideration_head_offset = 0x60;
// uint256 constant OrderParameters_orderType_offset = 0x80;
uint256 constant OrderParameters_startTime_offset = 0xa0;
uint256 constant OrderParameters_endTime_offset = 0xc0;
uint256 constant OrderParameters_zoneHash_offset = 0xe0;
// uint256 constant OrderParameters_salt_offset = 0x100;
uint256 constant OrderParameters_conduit_offset = 0x120;
uint256 constant OrderParameters_counter_offset = 0x140;

uint256 constant Fulfillment_itemIndex_offset = 0x20;

uint256 constant AdvancedOrder_head_size = 0xa0;
uint256 constant AdvancedOrder_numerator_offset = 0x20;
uint256 constant AdvancedOrder_denominator_offset = 0x40;
uint256 constant AdvancedOrder_signature_offset = 0x60;
uint256 constant AdvancedOrder_extraData_offset = 0x80;

uint256 constant OrderStatus_ValidatedAndNotCancelled = 1;
uint256 constant OrderStatus_filledNumerator_offset = 0x10;
uint256 constant OrderStatus_filledDenominator_offset = 0x88;

uint256 constant ThirtyOneBytes = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;
uint256 constant FourWords = 0x80;
uint256 constant FiveWords = 0xa0;

uint256 constant OneWordShift = 0x5;
uint256 constant TwoWordsShift = 0x6;

uint256 constant SixtyThreeBytes = 0x3f;
uint256 constant OnlyFullWordMask = 0xffffffe0;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;

// uint256 constant BasicOrder_endAmount_cdPtr = 0x104;
uint256 constant BasicOrder_common_params_size = 0xa0;
uint256 constant BasicOrder_considerationHashesArray_ptr = 0x160;
uint256 constant BasicOrder_receivedItemByteMap = (
    0x0000010102030000000000000000000000000000000000000000000000000000
);
uint256 constant BasicOrder_offeredItemByteMap = (
    0x0203020301010000000000000000000000000000000000000000000000000000
);

bytes32 constant OrdersMatchedTopic0 = (
    0x4b9f2d36e1b4c93de62cc077b00b1a91d84b6c31b4a14e012718dcca230689e7
);

uint256 constant EIP712_Order_size = 0x180;
uint256 constant EIP712_OfferItem_size = 0xc0;
uint256 constant EIP712_ConsiderationItem_size = 0xe0;
uint256 constant AdditionalRecipient_size = 0x40;
uint256 constant AdditionalRecipient_size_shift = 0x6;

uint256 constant EIP712_DomainSeparator_offset = 0x02;
uint256 constant EIP712_OrderHash_offset = 0x22;
uint256 constant EIP712_DigestPayload_size = 0x42;

uint256 constant EIP712_domainData_nameHash_offset = 0x20;
uint256 constant EIP712_domainData_versionHash_offset = 0x40;
uint256 constant EIP712_domainData_chainId_offset = 0x60;
uint256 constant EIP712_domainData_verifyingContract_offset = 0x80;
uint256 constant EIP712_domainData_size = 0xa0;

// Minimum BulkOrder proof size: 64 bytes for signature + 3 for key + 32 for 1
// sibling. Maximum BulkOrder proof size: 65 bytes for signature + 3 for key +
// 768 for 24 siblings.

uint256 constant BulkOrderProof_minSize = 0x63;
uint256 constant BulkOrderProof_rangeSize = 0x2e2;
uint256 constant BulkOrderProof_lengthAdjustmentBeforeMask = 0x1d;
uint256 constant BulkOrderProof_lengthRangeAfterMask = 0x2;
uint256 constant BulkOrderProof_keyShift = 0xe8;
uint256 constant BulkOrderProof_keySize = 0x3;

uint256 constant BulkOrder_Typehash_Height_One = (
    0x3ca2711d29384747a8f61d60aad3c450405f7aaff5613541dee28df2d6986d32
);
uint256 constant BulkOrder_Typehash_Height_Two = (
    0xbf8e29b89f29ed9b529c154a63038ffca562f8d7cd1e2545dda53a1b582dde30
);
uint256 constant BulkOrder_Typehash_Height_Three = (
    0x53c6f6856e13104584dd0797ca2b2779202dc2597c6066a42e0d8fe990b0024d
);
uint256 constant BulkOrder_Typehash_Height_Four = (
    0xa02eb7ff164c884e5e2c336dc85f81c6a93329d8e9adf214b32729b894de2af1
);
uint256 constant BulkOrder_Typehash_Height_Five = (
    0x39c9d33c18e050dda0aeb9a8086fb16fc12d5d64536780e1da7405a800b0b9f6
);
uint256 constant BulkOrder_Typehash_Height_Six = (
    0x1c19f71958cdd8f081b4c31f7caf5c010b29d12950be2fa1c95070dc47e30b55
);
uint256 constant BulkOrder_Typehash_Height_Seven = (
    0xca74fab2fece9a1d58234a274220ad05ca096a92ef6a1ca1750b9d90c948955c
);
uint256 constant BulkOrder_Typehash_Height_Eight = (
    0x7ff98d9d4e55d876c5cfac10b43c04039522f3ddfb0ea9bfe70c68cfb5c7cc14
);
uint256 constant BulkOrder_Typehash_Height_Nine = (
    0xbed7be92d41c56f9e59ac7a6272185299b815ddfabc3f25deb51fe55fe2f9e8a
);
uint256 constant BulkOrder_Typehash_Height_Ten = (
    0xd1d97d1ef5eaa37a4ee5fbf234e6f6d64eb511eb562221cd7edfbdde0848da05
);
uint256 constant BulkOrder_Typehash_Height_Eleven = (
    0x896c3f349c4da741c19b37fec49ed2e44d738e775a21d9c9860a69d67a3dae53
);
uint256 constant BulkOrder_Typehash_Height_Twelve = (
    0xbb98d87cc12922b83759626c5f07d72266da9702d19ffad6a514c73a89002f5f
);
uint256 constant BulkOrder_Typehash_Height_Thirteen = (
    0xe6ae19322608dd1f8a8d56aab48ed9c28be489b689f4b6c91268563efc85f20e
);
uint256 constant BulkOrder_Typehash_Height_Fourteen = (
    0x6b5b04cbae4fcb1a9d78e7b2dfc51a36933d023cf6e347e03d517b472a852590
);
uint256 constant BulkOrder_Typehash_Height_Fifteen = (
    0xd1eb68309202b7106b891e109739dbbd334a1817fe5d6202c939e75cf5e35ca9
);
uint256 constant BulkOrder_Typehash_Height_Sixteen = (
    0x1da3eed3ecef6ebaa6e5023c057ec2c75150693fd0dac5c90f4a142f9879fde8
);
uint256 constant BulkOrder_Typehash_Height_Seventeen = (
    0xeee9a1392aa395c7002308119a58f2582777a75e54e0c1d5d5437bd2e8bf6222
);
uint256 constant BulkOrder_Typehash_Height_Eighteen = (
    0xc3939feff011e53ab8c35ca3370aad54c5df1fc2938cd62543174fa6e7d85877
);
uint256 constant BulkOrder_Typehash_Height_Nineteen = (
    0x0efca7572ac20f5ae84db0e2940674f7eca0a4726fa1060ffc2d18cef54b203d
);
uint256 constant BulkOrder_Typehash_Height_Twenty = (
    0x5a4f867d3d458dabecad65f6201ceeaba0096df2d0c491cc32e6ea4e64350017
);
uint256 constant BulkOrder_Typehash_Height_TwentyOne = (
    0x80987079d291feebf21c2230e69add0f283cee0b8be492ca8050b4185a2ff719
);
uint256 constant BulkOrder_Typehash_Height_TwentyTwo = (
    0x3bd8cff538aba49a9c374c806d277181e9651624b3e31111bc0624574f8bca1d
);
uint256 constant BulkOrder_Typehash_Height_TwentyThree = (
    0x5d6a3f098a0bc373f808c619b1bb4028208721b3c4f8d6bc8a874d659814eb76
);
uint256 constant BulkOrder_Typehash_Height_TwentyFour = (
    0x1d51df90cba8de7637ca3e8fe1e3511d1dc2f23487d05dbdecb781860c21ac1c
);

uint256 constant receivedItemsHash_ptr = 0x60;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  data for OrderFulfilled
 *
 *   event OrderFulfilled(
 *     bytes32 orderHash,
 *     address indexed offerer,
 *     address indexed zone,
 *     address fulfiller,
 *     SpentItem[] offer,
 *       > (itemType, token, id, amount)
 *     ReceivedItem[] consideration
 *       > (itemType, token, id, amount, recipient)
 *   )
 *
 *  - 0x00: orderHash
 *  - 0x20: fulfiller
 *  - 0x40: offer offset (0x80)
 *  - 0x60: consideration offset (0x120)
 *  - 0x80: offer.length (1)
 *  - 0xa0: offerItemType
 *  - 0xc0: offerToken
 *  - 0xe0: offerIdentifier
 *  - 0x100: offerAmount
 *  - 0x120: consideration.length (1 + additionalRecipients.length)
 *  - 0x140: considerationItemType
 *  - 0x160: considerationToken
 *  - 0x180: considerationIdentifier
 *  - 0x1a0: considerationAmount
 *  - 0x1c0: considerationRecipient
 *  - ...
 */

// Minimum length of the OrderFulfilled event data.
// Must be added to the size of the ReceivedItem array for additionalRecipients
// (0xa0 * additionalRecipients.length) to calculate full size of the buffer.
uint256 constant OrderFulfilled_baseSize = 0x1e0;
uint256 constant OrderFulfilled_selector = (
    0x9d9af8e38d66c62e2c12f0225249fd9d721c54b83f48d9352c97c6cacdcb6f31
);

// Minimum offset in memory to OrderFulfilled event data.
// Must be added to the size of the EIP712 hash array for additionalRecipients
// (32 * additionalRecipients.length) to calculate the pointer to event data.
uint256 constant OrderFulfilled_baseOffset = 0x180;
uint256 constant OrderFulfilled_consideration_length_baseOffset = 0x2a0;
uint256 constant OrderFulfilled_offer_length_baseOffset = 0x200;

// Related constants used for restricted order checks on basic orders.
uint256 constant OrderFulfilled_baseDataSize = 0x160;
// uint256 constant ValidateOrder_offerDataOffset = 0x184;
// uint256 constant RatifyOrder_offerDataOffset = 0xc4;

// uint256 constant OrderFulfilled_orderHash_offset = 0x00;
uint256 constant OrderFulfilled_fulfiller_offset = 0x20;
uint256 constant OrderFulfilled_offer_head_offset = 0x40;
uint256 constant OrderFulfilled_offer_body_offset = 0x80;
uint256 constant OrderFulfilled_consideration_head_offset = 0x60;
uint256 constant OrderFulfilled_consideration_body_offset = 0x120;

// BasicOrderParameters
uint256 constant BasicOrder_parameters_cdPtr = 0x04;
uint256 constant BasicOrder_considerationToken_cdPtr = 0x24;
uint256 constant BasicOrder_considerationIdentifier_cdPtr = 0x44;
uint256 constant BasicOrder_considerationAmount_cdPtr = 0x64;
uint256 constant BasicOrder_offerer_cdPtr = 0x84;
uint256 constant BasicOrder_zone_cdPtr = 0xa4;
uint256 constant BasicOrder_offerToken_cdPtr = 0xc4;
uint256 constant BasicOrder_offerIdentifier_cdPtr = 0xe4;
uint256 constant BasicOrder_offerAmount_cdPtr = 0x104;
uint256 constant BasicOrder_basicOrderType_cdPtr = 0x124;
uint256 constant BasicOrder_startTime_cdPtr = 0x144;
uint256 constant BasicOrder_endTime_cdPtr = 0x164;
// uint256 constant BasicOrder_zoneHash_cdPtr = 0x184;
// uint256 constant BasicOrder_salt_cdPtr = 0x1a4;
uint256 constant BasicOrder_offererConduit_cdPtr = 0x1c4;
uint256 constant BasicOrder_fulfillerConduit_cdPtr = 0x1e4;
uint256 constant BasicOrder_totalOriginalAdditionalRecipients_cdPtr = 0x204;
uint256 constant BasicOrder_additionalRecipients_head_cdPtr = 0x224;
uint256 constant BasicOrder_signature_cdPtr = 0x244;
uint256 constant BasicOrder_additionalRecipients_length_cdPtr = 0x264;
uint256 constant BasicOrder_additionalRecipients_data_cdPtr = 0x284;
uint256 constant BasicOrder_parameters_ptr = 0x20;
uint256 constant BasicOrder_basicOrderType_range = 0x18; // 24 values

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for ConsiderationItem
 *   - 0x80: ConsiderationItem EIP-712 typehash (constant)
 *   - 0xa0: itemType
 *   - 0xc0: token
 *   - 0xe0: identifier
 *   - 0x100: startAmount
 *   - 0x120: endAmount
 *   - 0x140: recipient
 */
uint256 constant BasicOrder_considerationItem_typeHash_ptr = 0x80; // memoryPtr
uint256 constant BasicOrder_considerationItem_itemType_ptr = 0xa0;
uint256 constant BasicOrder_considerationItem_token_ptr = 0xc0;
uint256 constant BasicOrder_considerationItem_identifier_ptr = 0xe0;
uint256 constant BasicOrder_considerationItem_startAmount_ptr = 0x100;
uint256 constant BasicOrder_considerationItem_endAmount_ptr = 0x120;
// uint256 constant BasicOrder_considerationItem_recipient_ptr = 0x140;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for OfferItem
 *   - 0x80:  OfferItem EIP-712 typehash (constant)
 *   - 0xa0:  itemType
 *   - 0xc0:  token
 *   - 0xe0:  identifier (reused for offeredItemsHash)
 *   - 0x100: startAmount
 *   - 0x120: endAmount
 */
uint256 constant BasicOrder_offerItem_typeHash_ptr = 0x80;
uint256 constant BasicOrder_offerItem_itemType_ptr = 0xa0;
uint256 constant BasicOrder_offerItem_token_ptr = 0xc0;
// uint256 constant BasicOrder_offerItem_identifier_ptr = 0xe0;
// uint256 constant BasicOrder_offerItem_startAmount_ptr = 0x100;
uint256 constant BasicOrder_offerItem_endAmount_ptr = 0x120;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for Order
 *   - 0x80:   Order EIP-712 typehash (constant)
 *   - 0xa0:   orderParameters.offerer
 *   - 0xc0:   orderParameters.zone
 *   - 0xe0:   keccak256(abi.encodePacked(offerHashes))
 *   - 0x100:  keccak256(abi.encodePacked(considerationHashes))
 *   - 0x120:  orderType
 *   - 0x140:  startTime
 *   - 0x160:  endTime
 *   - 0x180:  zoneHash
 *   - 0x1a0:  salt
 *   - 0x1c0:  conduit
 *   - 0x1e0:  _counters[orderParameters.offerer] (from storage)
 */
uint256 constant BasicOrder_order_typeHash_ptr = 0x80;
uint256 constant BasicOrder_order_offerer_ptr = 0xa0;
// uint256 constant BasicOrder_order_zone_ptr = 0xc0;
uint256 constant BasicOrder_order_offerHashes_ptr = 0xe0;
uint256 constant BasicOrder_order_considerationHashes_ptr = 0x100;
uint256 constant BasicOrder_order_orderType_ptr = 0x120;
uint256 constant BasicOrder_order_startTime_ptr = 0x140;
// uint256 constant BasicOrder_order_endTime_ptr = 0x160;
// uint256 constant BasicOrder_order_zoneHash_ptr = 0x180;
// uint256 constant BasicOrder_order_salt_ptr = 0x1a0;
// uint256 constant BasicOrder_order_conduitKey_ptr = 0x1c0;
uint256 constant BasicOrder_order_counter_ptr = 0x1e0;
uint256 constant BasicOrder_additionalRecipients_head_ptr = 0x240;
uint256 constant BasicOrder_signature_ptr = 0x260;
uint256 constant BasicOrder_startTimeThroughZoneHash_size = 0x60;

uint256 constant ContractOrder_orderHash_offerer_shift = 0x60;

uint256 constant Counter_blockhash_shift = 0x80;

// Signature-related
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
bytes32 constant ECDSA_twentySeventhAndTwentyEighthBytesSet = (
    0x0000000000000000000000000000000000000000000000000000000101000000
);
uint256 constant ECDSA_MaxLength = 65;
uint256 constant ECDSA_signature_s_offset = 0x40;
uint256 constant ECDSA_signature_v_offset = 0x60;

bytes32 constant EIP1271_isValidSignature_selector = (
    0x1626ba7e00000000000000000000000000000000000000000000000000000000
);
uint256 constant EIP1271_isValidSignature_digest_negativeOffset = 0x40;
uint256 constant EIP1271_isValidSignature_selector_negativeOffset = 0x44;
uint256 constant EIP1271_isValidSignature_calldata_baseLength = 0x64;
uint256 constant EIP1271_isValidSignature_signature_head_offset = 0x40;

uint256 constant EIP_712_PREFIX = (
    0x1901000000000000000000000000000000000000000000000000000000000000
);

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 0x3;
uint256 constant MemoryExpansionCoefficientShift = 0x9;

uint256 constant Create2AddressDerivation_ptr = 0x0b;
uint256 constant Create2AddressDerivation_length = 0x55;

uint256 constant MaskOverByteTwelve = (
    0x0000000000000000000000ff0000000000000000000000000000000000000000
);
uint256 constant MaskOverLastTwentyBytes = (
    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
);
uint256 constant AddressDirtyUpperBitThreshold = (
    0x0000000000000000000000010000000000000000000000000000000000000000
);
uint256 constant MaskOverFirstFourBytes = (
    0xffffffff00000000000000000000000000000000000000000000000000000000
);

uint256 constant Conduit_execute_signature = (
    0x4ce34aa200000000000000000000000000000000000000000000000000000000
);

uint256 constant MaxUint8 = 0xff;
uint256 constant MaxUint120 = 0xffffffffffffffffffffffffffffff;

uint256 constant Conduit_execute_ConduitTransfer_ptr = 0x20;
uint256 constant Conduit_execute_ConduitTransfer_length = 0x01;
uint256 constant Conduit_execute_ConduitTransfer_offset_ptr = 0x04;
uint256 constant Conduit_execute_ConduitTransfer_length_ptr = 0x24;
uint256 constant Conduit_execute_transferItemType_ptr = 0x44;
uint256 constant Conduit_execute_transferToken_ptr = 0x64;
uint256 constant Conduit_execute_transferFrom_ptr = 0x84;
uint256 constant Conduit_execute_transferTo_ptr = 0xa4;
uint256 constant Conduit_execute_transferIdentifier_ptr = 0xc4;
uint256 constant Conduit_execute_transferAmount_ptr = 0xe4;

uint256 constant OneConduitExecute_size = 0x104;

// Sentinel value to indicate that the conduit accumulator is not armed.
uint256 constant AccumulatorDisarmed = 0x20;
uint256 constant AccumulatorArmed = 0x40;
uint256 constant Accumulator_conduitKey_ptr = 0x20;
uint256 constant Accumulator_selector_ptr = 0x40;
uint256 constant Accumulator_array_offset_ptr = 0x44;
uint256 constant Accumulator_array_length_ptr = 0x64;
uint256 constant Accumulator_itemSizeOffsetDifference = 0x3c;
uint256 constant Accumulator_array_offset = 0x20;

uint256 constant Conduit_transferItem_size = 0xc0;
uint256 constant Conduit_transferItem_token_ptr = 0x20;
uint256 constant Conduit_transferItem_from_ptr = 0x40;
uint256 constant Conduit_transferItem_to_ptr = 0x60;
uint256 constant Conduit_transferItem_identifier_ptr = 0x80;
uint256 constant Conduit_transferItem_amount_ptr = 0xa0;

uint256 constant Ecrecover_precompile = 0x1;
uint256 constant Ecrecover_args_size = 0x80;
uint256 constant Signature_lower_v = 27;

// Bitmask that only gives a non-zero value if masked with a non-match selector.
uint256 constant NonMatchSelector_MagicMask = (
    0x4000000000000000000000000000000000000000000000000000000000
);

// First bit indicates that a NATIVE offer items has been used and the 231st bit
// indicates that a non match selector has been called.
uint256 constant NonMatchSelector_InvalidErrorValue = (
    0x4000000000000000000000000000000000000000000000000000000001
);

/**
 * @dev Selector and offsets for generateOrder
 *
 * function generateOrder(
 *   address fulfiller,
 *   SpentItem[] calldata minimumReceived,
 *   SpentItem[] calldata maximumSpent,
 *   bytes calldata context
 * )
 */
uint256 constant generateOrder_selector = 0x98919765;
uint256 constant generateOrder_selector_offset = 0x1c;
uint256 constant generateOrder_head_offset = 0x04;
uint256 constant generateOrder_minimumReceived_head_offset = 0x20;
uint256 constant generateOrder_maximumSpent_head_offset = 0x40;
uint256 constant generateOrder_context_head_offset = 0x60;
uint256 constant generateOrder_base_tail_offset = 0x80;
uint256 constant generateOrder_maximum_returndatasize = 0xffff;

uint256 constant ratifyOrder_selector = 0xf4dd92ce;
uint256 constant ratifyOrder_selector_offset = 0x1c;
uint256 constant ratifyOrder_head_offset = 0x04;
// uint256 constant ratifyOrder_offer_head_offset = 0x00;
uint256 constant ratifyOrder_consideration_head_offset = 0x20;
uint256 constant ratifyOrder_context_head_offset = 0x40;
uint256 constant ratifyOrder_orderHashes_head_offset = 0x60;
uint256 constant ratifyOrder_contractNonce_offset = 0x80;
uint256 constant ratifyOrder_base_tail_offset = 0xa0;

uint256 constant validateOrder_selector = 0x17b1f942;
uint256 constant validateOrder_selector_offset = 0x1c;
uint256 constant validateOrder_head_offset = 0x04;
uint256 constant validateOrder_zoneParameters_offset = 0x20;

// uint256 constant ZoneParameters_orderHash_offset = 0x00;
uint256 constant ZoneParameters_fulfiller_offset = 0x20;
uint256 constant ZoneParameters_offerer_offset = 0x40;
uint256 constant ZoneParameters_offer_head_offset = 0x60;
uint256 constant ZoneParameters_consideration_head_offset = 0x80;
uint256 constant ZoneParameters_extraData_head_offset = 0xa0;
uint256 constant ZoneParameters_orderHashes_head_offset = 0xc0;
uint256 constant ZoneParameters_startTime_offset = 0xe0;
uint256 constant ZoneParameters_endTime_offset = 0x100;
uint256 constant ZoneParameters_zoneHash_offset = 0x120;
uint256 constant ZoneParameters_base_tail_offset = 0x140;
uint256 constant ZoneParameters_selectorAndPointer_length = 0x24;
uint256 constant ZoneParameters_basicOrderFixedElements_length = 0x64;

// ConsiderationDecoder Constants
uint256 constant OrderParameters_head_size = 0x0160;
uint256 constant OrderParameters_totalOriginalConsiderationItems_offset = (
    0x0140
);
uint256 constant AdvancedOrderPlusOrderParameters_head_size = 0x0200;

uint256 constant Order_signature_offset = 0x20;
uint256 constant Order_head_size = 0x40;

uint256 constant AdvancedOrder_fixed_segment_0 = 0x40;

uint256 constant CriteriaResolver_head_size = 0xa0;
uint256 constant CriteriaResolver_fixed_segment_0 = 0x80;
uint256 constant CriteriaResolver_criteriaProof_offset = 0x80;

uint256 constant FulfillmentComponent_mem_tail_size = 0x40;
uint256 constant FulfillmentComponent_mem_tail_size_shift = 0x6;
uint256 constant Fulfillment_head_size = 0x40;
uint256 constant Fulfillment_considerationComponents_offset = 0x20;

uint256 constant OrderComponents_OrderParameters_common_head_size = 0x0140;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    AdvancedOrder,
    ConsiderationItem,
    CriteriaResolver,
    Fulfillment,
    FulfillmentComponent,
    OfferItem,
    Order,
    OrderParameters,
    ReceivedItem
} from "./ConsiderationStructs.sol";

import {
    AdvancedOrder_denominator_offset,
    AdvancedOrder_extraData_offset,
    AdvancedOrder_fixed_segment_0,
    AdvancedOrder_head_size,
    AdvancedOrder_numerator_offset,
    AdvancedOrder_signature_offset,
    AdvancedOrderPlusOrderParameters_head_size,
    Common_amount_offset,
    Common_endAmount_offset,
    ConsiderationItem_size_with_length,
    ConsiderationItem_size,
    CriteriaResolver_criteriaProof_offset,
    CriteriaResolver_fixed_segment_0,
    CriteriaResolver_head_size,
    FourWords,
    FreeMemoryPointerSlot,
    Fulfillment_considerationComponents_offset,
    Fulfillment_head_size,
    FulfillmentComponent_mem_tail_size_shift,
    FulfillmentComponent_mem_tail_size,
    generateOrder_maximum_returndatasize,
    OfferItem_size_with_length,
    OfferItem_size,
    OneWord,
    OneWordShift,
    OnlyFullWordMask,
    Order_head_size,
    Order_signature_offset,
    OrderComponents_OrderParameters_common_head_size,
    OrderParameters_consideration_head_offset,
    OrderParameters_head_size,
    OrderParameters_offer_head_offset,
    OrderParameters_totalOriginalConsiderationItems_offset,
    ReceivedItem_recipient_offset,
    ReceivedItem_size,
    ReceivedItem_size_excluding_recipient,
    SpentItem_size_shift,
    SpentItem_size,
    ThirtyOneBytes,
    TwoWords
} from "./ConsiderationConstants.sol";

import {
    CalldataPointer,
    malloc,
    MemoryPointer,
    OffsetOrLengthMask
} from "../helpers/PointerLibraries.sol";

contract ConsiderationDecoder {
    /**
     * @dev Takes a bytes array from calldata and copies it into memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the bytes array in
     *                    calldata which contains the length of the array.
     *
     * @return mPtrLength A memory pointer to the start of the bytes array in
     *                    memory which contains the length of the array.
     */
    function _decodeBytes(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            // Get the current free memory pointer.
            mPtrLength := mload(FreeMemoryPointerSlot)

            // Derive the size of the bytes array, rounding up to nearest word
            // and adding a word for the length field. Note: masking
            // `calldataload(cdPtrLength)` is redundant here.
            let size := add(
                and(
                    add(calldataload(cdPtrLength), ThirtyOneBytes),
                    OnlyFullWordMask
                ),
                OneWord
            )

            // Copy bytes from calldata into memory based on pointers and size.
            calldatacopy(mPtrLength, cdPtrLength, size)

            // Store the masked value in memory. Note: the value of `size` is at
            // least 32, meaning the calldatacopy above will at least write to
            // `[mPtrLength, mPtrLength + 32)`.
            mstore(
                mPtrLength,
                and(calldataload(cdPtrLength), OffsetOrLengthMask)
            )

            // Update free memory pointer based on the size of the bytes array.
            mstore(FreeMemoryPointerSlot, add(mPtrLength, size))
        }
    }

    /**
     * @dev Takes an offer array from calldata and copies it into memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the offer array
     *                    in calldata which contains the length of the array.
     *
     * @return mPtrLength A memory pointer to the start of the offer array in
     *                    memory which contains the length of the array.
     */
    function _decodeOffer(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            // Retrieve length of array, masking to prevent potential overflow.
            let arrLength := and(calldataload(cdPtrLength), OffsetOrLengthMask)

            // Get the current free memory pointer.
            mPtrLength := mload(FreeMemoryPointerSlot)

            // Write the array length to memory.
            mstore(mPtrLength, arrLength)

            // Derive the head by adding one word to the length pointer.
            let mPtrHead := add(mPtrLength, OneWord)

            // Derive the tail by adding one word per element (note that structs
            // are written to memory with an offset per struct element).
            let mPtrTail := add(mPtrHead, shl(OneWordShift, arrLength))

            // Track the next tail, beginning with the initial tail value.
            let mPtrTailNext := mPtrTail

            // Copy all offer array data into memory at the tail pointer.
            calldatacopy(
                mPtrTail,
                add(cdPtrLength, OneWord),
                mul(arrLength, OfferItem_size)
            )

            // Track the next head pointer, starting with initial head value.
            let mPtrHeadNext := mPtrHead

            // Iterate over each head pointer until it reaches the tail.
            for {

            } lt(mPtrHeadNext, mPtrTail) {

            } {
                // Write the next tail pointer to next head pointer in memory.
                mstore(mPtrHeadNext, mPtrTailNext)

                // Increment the next head pointer by one word.
                mPtrHeadNext := add(mPtrHeadNext, OneWord)

                // Increment the next tail pointer by the size of an offer item.
                mPtrTailNext := add(mPtrTailNext, OfferItem_size)
            }

            // Update free memory pointer to allocate memory up to end of tail.
            mstore(FreeMemoryPointerSlot, mPtrTailNext)
        }
    }

    /**
     * @dev Takes a consideration array from calldata and copies it into memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the consideration
     *                    array in calldata which contains the length of the
     *                    array.
     *
     * @return mPtrLength A memory pointer to the start of the consideration
     *                    array in memory which contains the length of the
     *                    array.
     */
    function _decodeConsideration(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            // Retrieve length of array, masking to prevent potential overflow.
            let arrLength := and(calldataload(cdPtrLength), OffsetOrLengthMask)

            // Get the current free memory pointer.
            mPtrLength := mload(FreeMemoryPointerSlot)

            // Write the array length to memory.
            mstore(mPtrLength, arrLength)

            // Derive the head by adding one word to the length pointer.
            let mPtrHead := add(mPtrLength, OneWord)

            // Derive the tail by adding one word per element (note that structs
            // are written to memory with an offset per struct element).
            let mPtrTail := add(mPtrHead, shl(OneWordShift, arrLength))

            // Track the next tail, beginning with the initial tail value.
            let mPtrTailNext := mPtrTail

            // Copy all consideration array data into memory at tail pointer.
            calldatacopy(
                mPtrTail,
                add(cdPtrLength, OneWord),
                mul(arrLength, ConsiderationItem_size)
            )

            // Track the next head pointer, starting with initial head value.
            let mPtrHeadNext := mPtrHead

            // Iterate over each head pointer until it reaches the tail.
            for {

            } lt(mPtrHeadNext, mPtrTail) {

            } {
                // Write the next tail pointer to next head pointer in memory.
                mstore(mPtrHeadNext, mPtrTailNext)

                // Increment the next head pointer by one word.
                mPtrHeadNext := add(mPtrHeadNext, OneWord)

                // Increment next tail pointer by size of a consideration item.
                mPtrTailNext := add(mPtrTailNext, ConsiderationItem_size)
            }

            // Update free memory pointer to allocate memory up to end of tail.
            mstore(FreeMemoryPointerSlot, mPtrTailNext)
        }
    }

    /**
     * @dev Takes a calldata pointer and memory pointer and copies a referenced
     *      OrderParameters struct and associated offer and consideration data
     *      to memory.
     *
     * @param cdPtr A calldata pointer for the OrderParameters struct.
     * @param mPtr A memory pointer to the OrderParameters struct head.
     */
    function _decodeOrderParametersTo(
        CalldataPointer cdPtr,
        MemoryPointer mPtr
    ) internal pure {
        // Copy the full OrderParameters head from calldata to memory.
        cdPtr.copy(mPtr, OrderParameters_head_size);

        // Resolve the offer calldata offset, use that to decode and copy offer
        // from calldata, and write resultant memory offset to head in memory.
        mPtr.offset(OrderParameters_offer_head_offset).write(
            _decodeOffer(cdPtr.pptr(OrderParameters_offer_head_offset))
        );

        // Resolve consideration calldata offset, use that to copy consideration
        // from calldata, and write resultant memory offset to head in memory.
        mPtr.offset(OrderParameters_consideration_head_offset).write(
            _decodeConsideration(
                cdPtr.pptr(OrderParameters_consideration_head_offset)
            )
        );
    }

    /**
     * @dev Takes a calldata pointer to an OrderParameters struct and copies the
     *      decoded struct to memory.
     *
     * @param cdPtr A calldata pointer for the OrderParameters struct.
     *
     * @return mPtr A memory pointer to the OrderParameters struct head.
     */
    function _decodeOrderParameters(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate required memory for the OrderParameters head (offer and
        // consideration are allocated independently).
        mPtr = malloc(OrderParameters_head_size);

        // Decode and copy the order parameters to the newly allocated memory.
        _decodeOrderParametersTo(cdPtr, mPtr);
    }

    /**
     * @dev Takes a calldata pointer to an Order struct and copies the decoded
     *      struct to memory.
     *
     * @param cdPtr A calldata pointer for the Order struct.
     *
     * @return mPtr A memory pointer to the Order struct head.
     */
    function _decodeOrder(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate required memory for the Order head (OrderParameters and
        // signature are allocated independently).
        mPtr = malloc(Order_head_size);

        // Resolve OrderParameters calldata offset, use it to decode and copy
        // from calldata, and write resultant memory offset to head in memory.
        mPtr.write(_decodeOrderParameters(cdPtr.pptr()));

        // Resolve signature calldata offset, use that to decode and copy from
        // calldata, and write resultant memory offset to head in memory.
        mPtr.offset(Order_signature_offset).write(
            _decodeBytes(cdPtr.pptr(Order_signature_offset))
        );
    }

    /**
     * @dev Takes a calldata pointer to an AdvancedOrder struct and copies the
     *      decoded struct to memory.
     *
     * @param cdPtr A calldata pointer for the AdvancedOrder struct.
     *
     * @return mPtr A memory pointer to the AdvancedOrder struct head.
     */
    function _decodeAdvancedOrder(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate memory for AdvancedOrder head and OrderParameters head.
        mPtr = malloc(AdvancedOrderPlusOrderParameters_head_size);

        // Use numerator + denominator calldata offset to decode and copy
        // from calldata and write resultant memory offset to head in memory.
        cdPtr.offset(AdvancedOrder_numerator_offset).copy(
            mPtr.offset(AdvancedOrder_numerator_offset),
            AdvancedOrder_fixed_segment_0
        );

        // Get pointer to memory immediately after advanced order.
        MemoryPointer mPtrParameters = mPtr.offset(AdvancedOrder_head_size);

        // Write pptr for advanced order parameters to memory.
        mPtr.write(mPtrParameters);

        // Resolve OrderParameters calldata pointer & write to allocated region.
        _decodeOrderParametersTo(cdPtr.pptr(), mPtrParameters);

        // Resolve signature calldata offset, use that to decode and copy from
        // calldata, and write resultant memory offset to head in memory.
        mPtr.offset(AdvancedOrder_signature_offset).write(
            _decodeBytes(cdPtr.pptr(AdvancedOrder_signature_offset))
        );

        // Resolve extraData calldata offset, use that to decode and copy from
        // calldata, and write resultant memory offset to head in memory.
        mPtr.offset(AdvancedOrder_extraData_offset).write(
            _decodeBytes(cdPtr.pptr(AdvancedOrder_extraData_offset))
        );
    }

    /**
     * @dev Allocates a single word of empty bytes in memory and returns the
     *      pointer to that memory region.
     *
     * @return mPtr The memory pointer to the new empty word in memory.
     */
    function _getEmptyBytesOrArray()
        internal
        pure
        returns (MemoryPointer mPtr)
    {
        mPtr = malloc(OneWord);
        mPtr.write(0);
    }

    /**
     * @dev Takes a calldata pointer to an Order struct and copies the decoded
     *      struct to memory as an AdvancedOrder.
     *
     * @param cdPtr A calldata pointer for the Order struct.
     *
     * @return mPtr A memory pointer to the AdvancedOrder struct head.
     */
    function _decodeOrderAsAdvancedOrder(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate memory for AdvancedOrder head and OrderParameters head.
        mPtr = malloc(AdvancedOrderPlusOrderParameters_head_size);

        // Get pointer to memory immediately after advanced order.
        MemoryPointer mPtrParameters = mPtr.offset(AdvancedOrder_head_size);

        // Write pptr for advanced order parameters.
        mPtr.write(mPtrParameters);

        // Resolve OrderParameters calldata pointer & write to allocated region.
        _decodeOrderParametersTo(cdPtr.pptr(), mPtrParameters);

        // Write default Order numerator and denominator values (i.e. 1/1).
        mPtr.offset(AdvancedOrder_numerator_offset).write(1);
        mPtr.offset(AdvancedOrder_denominator_offset).write(1);

        // Resolve signature calldata offset, use that to decode and copy from
        // calldata, and write resultant memory offset to head in memory.
        mPtr.offset(AdvancedOrder_signature_offset).write(
            _decodeBytes(cdPtr.pptr(Order_signature_offset))
        );

        // Resolve extraData calldata offset, use that to decode and copy from
        // calldata, and write resultant memory offset to head in memory.
        mPtr.offset(AdvancedOrder_extraData_offset).write(
            _getEmptyBytesOrArray()
        );
    }

    /**
     * @dev Takes a calldata pointer to an array of Order structs and copies the
     *      decoded array to memory as an array of AdvancedOrder structs.
     *
     * @param cdPtrLength A calldata pointer to the start of the orders array in
     *                    calldata which contains the length of the array.
     *
     * @return mPtrLength A memory pointer to the start of the array of advanced
     *                    orders in memory which contains length of the array.
     */
    function _decodeOrdersAsAdvancedOrders(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        // Retrieve length of array, masking to prevent potential overflow.
        uint256 arrLength = cdPtrLength.readMaskedUint256();

        unchecked {
            // Derive offset to the tail based on one word per array element.
            uint256 tailOffset = arrLength << OneWordShift;

            // Add one additional word for the length and allocate memory.
            mPtrLength = malloc(tailOffset + OneWord);

            // Write the length of the array to memory.
            mPtrLength.write(arrLength);

            // Advance to first memory & calldata pointers (e.g. after length).
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();

            // Iterate over each pointer, word by word, until tail is reached.
            for (uint256 offset = 0; offset < tailOffset; offset += OneWord) {
                // Resolve Order calldata offset, use it to decode and copy from
                // calldata, and write resultant AdvancedOrder offset to memory.
                mPtrHead.offset(offset).write(
                    _decodeOrderAsAdvancedOrder(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    /**
     * @dev Takes a calldata pointer to a criteria proof, or an array bytes32
     *      types, and copies the decoded proof to memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the criteria proof
     *                    in calldata which contains the length of the array.
     *
     * @return mPtrLength A memory pointer to the start of the criteria proof
     *                    in memory which contains length of the array.
     */
    function _decodeCriteriaProof(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        // Retrieve length of array, masking to prevent potential overflow.
        uint256 arrLength = cdPtrLength.readMaskedUint256();

        unchecked {
            // Derive array size based on one word per array element and length.
            uint256 arrSize = (arrLength + 1) << OneWordShift;

            // Allocate memory equal to the array size.
            mPtrLength = malloc(arrSize);

            // Copy the array from calldata into memory.
            cdPtrLength.copy(mPtrLength, arrSize);
        }
    }

    /**
     * @dev Takes a calldata pointer to a CriteriaResolver struct and copies the
     *      decoded struct to memory.
     *
     * @param cdPtr A calldata pointer for the CriteriaResolver struct.
     *
     * @return mPtr A memory pointer to the CriteriaResolver struct head.
     */
    function _decodeCriteriaResolver(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate required memory for the CriteriaResolver head (the criteria
        // proof bytes32 array is allocated independently).
        mPtr = malloc(CriteriaResolver_head_size);

        // Decode and copy order index, side, index, and identifier from
        // calldata and write resultant memory offset to head in memory.
        cdPtr.copy(mPtr, CriteriaResolver_fixed_segment_0);

        // Resolve criteria proof calldata offset, use it to decode and copy
        // from calldata, and write resultant memory offset to head in memory.
        mPtr.offset(CriteriaResolver_criteriaProof_offset).write(
            _decodeCriteriaProof(
                cdPtr.pptr(CriteriaResolver_criteriaProof_offset)
            )
        );
    }

    /**
     * @dev Takes an array of criteria resolvers from calldata and copies it
     *      into memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the criteria
     *                    resolver array in calldata which contains the length
     *                    of the array.
     *
     * @return mPtrLength A memory pointer to the start of the criteria resolver
     *                    array in memory which contains the length of the
     *                    array.
     */
    function _decodeCriteriaResolvers(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        // Retrieve length of array, masking to prevent potential overflow.
        uint256 arrLength = cdPtrLength.readMaskedUint256();

        unchecked {
            // Derive offset to the tail based on one word per array element.
            uint256 tailOffset = arrLength << OneWordShift;

            // Add one additional word for the length and allocate memory.
            mPtrLength = malloc(tailOffset + OneWord);

            // Write the length of the array to memory.
            mPtrLength.write(arrLength);

            // Advance to first memory & calldata pointers (e.g. after length).
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();

            // Iterate over each pointer, word by word, until tail is reached.
            for (uint256 offset = 0; offset < tailOffset; offset += OneWord) {
                // Resolve CriteriaResolver calldata offset, use it to decode
                // and copy from calldata, and write resultant memory offset.
                mPtrHead.offset(offset).write(
                    _decodeCriteriaResolver(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    /**
     * @dev Takes an array of orders from calldata and copies it into memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the orders array in
     *                    calldata which contains the length of the array.
     *
     * @return mPtrLength A memory pointer to the start of the orders array
     *                    in memory which contains the length of the array.
     */
    function _decodeOrders(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        // Retrieve length of array, masking to prevent potential overflow.
        uint256 arrLength = cdPtrLength.readMaskedUint256();

        unchecked {
            // Derive offset to the tail based on one word per array element.
            uint256 tailOffset = arrLength << OneWordShift;

            // Add one additional word for the length and allocate memory.
            mPtrLength = malloc(tailOffset + OneWord);

            // Write the length of the array to memory.
            mPtrLength.write(arrLength);

            // Advance to first memory & calldata pointers (e.g. after length).
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();

            // Iterate over each pointer, word by word, until tail is reached.
            for (uint256 offset = 0; offset < tailOffset; offset += OneWord) {
                // Resolve Order calldata offset, use it to decode and copy
                // from calldata, and write resultant memory offset.
                mPtrHead.offset(offset).write(
                    _decodeOrder(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    /**
     * @dev Takes an array of fulfillment components from calldata and copies it
     *      into memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the fulfillment
     *                    components array in calldata which contains the length
     *                    of the array.
     *
     * @return mPtrLength A memory pointer to the start of the fulfillment
     *                    components array in memory which contains the length
     *                    of the array.
     */
    function _decodeFulfillmentComponents(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        assembly {
            let arrLength := and(calldataload(cdPtrLength), OffsetOrLengthMask)

            // Get the current free memory pointer.
            mPtrLength := mload(FreeMemoryPointerSlot)

            mstore(mPtrLength, arrLength)
            let mPtrHead := add(mPtrLength, OneWord)
            let mPtrTail := add(mPtrHead, shl(OneWordShift, arrLength))
            let mPtrTailNext := mPtrTail
            calldatacopy(
                mPtrTail,
                add(cdPtrLength, OneWord),
                shl(FulfillmentComponent_mem_tail_size_shift, arrLength)
            )
            let mPtrHeadNext := mPtrHead
            for {

            } lt(mPtrHeadNext, mPtrTail) {

            } {
                mstore(mPtrHeadNext, mPtrTailNext)
                mPtrHeadNext := add(mPtrHeadNext, OneWord)
                mPtrTailNext := add(
                    mPtrTailNext,
                    FulfillmentComponent_mem_tail_size
                )
            }

            // Update the free memory pointer.
            mstore(FreeMemoryPointerSlot, mPtrTailNext)
        }
    }

    /**
     * @dev Takes a nested array of fulfillment components from calldata and
     *      copies it into memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the nested
     *                    fulfillment components array in calldata which
     *                    contains the length of the array.
     *
     * @return mPtrLength A memory pointer to the start of the nested
     *                    fulfillment components array in memory which
     *                    contains the length of the array.
     */
    function _decodeNestedFulfillmentComponents(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        // Retrieve length of array, masking to prevent potential overflow.
        uint256 arrLength = cdPtrLength.readMaskedUint256();

        unchecked {
            // Derive offset to the tail based on one word per array element.
            uint256 tailOffset = arrLength << OneWordShift;

            // Add one additional word for the length and allocate memory.
            mPtrLength = malloc(tailOffset + OneWord);

            // Write the length of the array to memory.
            mPtrLength.write(arrLength);

            // Advance to first memory & calldata pointers (e.g. after length).
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();

            // Iterate over each pointer, word by word, until tail is reached.
            for (uint256 offset = 0; offset < tailOffset; offset += OneWord) {
                // Resolve FulfillmentComponents array calldata offset, use it
                // to decode and copy from calldata, and write memory offset.
                mPtrHead.offset(offset).write(
                    _decodeFulfillmentComponents(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    /**
     * @dev Takes an array of advanced orders from calldata and copies it into
     *      memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the advanced orders
     *                    array in calldata which contains the length of the
     *                    array.
     *
     * @return mPtrLength A memory pointer to the start of the advanced orders
     *                    array in memory which contains the length of the
     *                    array.
     */
    function _decodeAdvancedOrders(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        // Retrieve length of array, masking to prevent potential overflow.
        uint256 arrLength = cdPtrLength.readMaskedUint256();

        unchecked {
            // Derive offset to the tail based on one word per array element.
            uint256 tailOffset = arrLength << OneWordShift;

            // Add one additional word for the length and allocate memory.
            mPtrLength = malloc(tailOffset + OneWord);

            // Write the length of the array to memory.
            mPtrLength.write(arrLength);

            // Advance to first memory & calldata pointers (e.g. after length).
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();

            // Iterate over each pointer, word by word, until tail is reached.
            for (uint256 offset = 0; offset < tailOffset; offset += OneWord) {
                // Resolve AdvancedOrder calldata offset, use it to decode and
                // copy from calldata, and write resultant memory offset.
                mPtrHead.offset(offset).write(
                    _decodeAdvancedOrder(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    /**
     * @dev Takes a calldata pointer to a Fulfillment struct and copies the
     *      decoded struct to memory.
     *
     * @param cdPtr A calldata pointer for the Fulfillment struct.
     *
     * @return mPtr A memory pointer to the Fulfillment struct head.
     */
    function _decodeFulfillment(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate required memory for the Fulfillment head (the fulfillment
        // components arrays are allocated independently).
        mPtr = malloc(Fulfillment_head_size);

        // Resolve offerComponents calldata offset, use it to decode and copy
        // from calldata, and write resultant memory offset to head in memory.
        mPtr.write(_decodeFulfillmentComponents(cdPtr.pptr()));

        // Resolve considerationComponents calldata offset, use it to decode and
        // copy from calldata, and write resultant memory offset to memory head.
        mPtr.offset(Fulfillment_considerationComponents_offset).write(
            _decodeFulfillmentComponents(
                cdPtr.pptr(Fulfillment_considerationComponents_offset)
            )
        );
    }

    /**
     * @dev Takes an array of fulfillments from calldata and copies it into
     *      memory.
     *
     * @param cdPtrLength A calldata pointer to the start of the fulfillments
     *                    array in calldata which contains the length of the
     *                    array.
     *
     * @return mPtrLength A memory pointer to the start of the fulfillments
     *                    array in memory which contains the length of the
     *                    array.
     */
    function _decodeFulfillments(
        CalldataPointer cdPtrLength
    ) internal pure returns (MemoryPointer mPtrLength) {
        // Retrieve length of array, masking to prevent potential overflow.
        uint256 arrLength = cdPtrLength.readMaskedUint256();

        unchecked {
            // Derive offset to the tail based on one word per array element.
            uint256 tailOffset = arrLength << OneWordShift;

            // Add one additional word for the length and allocate memory.
            mPtrLength = malloc(tailOffset + OneWord);

            // Write the length of the array to memory.
            mPtrLength.write(arrLength);

            // Advance to first memory & calldata pointers (e.g. after length).
            MemoryPointer mPtrHead = mPtrLength.next();
            CalldataPointer cdPtrHead = cdPtrLength.next();

            // Iterate over each pointer, word by word, until tail is reached.
            for (uint256 offset = 0; offset < tailOffset; offset += OneWord) {
                // Resolve Fulfillment calldata offset, use it to decode and
                // copy from calldata, and write resultant memory offset.
                mPtrHead.offset(offset).write(
                    _decodeFulfillment(cdPtrHead.pptr(offset))
                );
            }
        }
    }

    /**
     * @dev Takes a calldata pointer to an OrderComponents struct and copies the
     *      decoded struct to memory as an OrderParameters struct (with the
     *      totalOriginalConsiderationItems value set equal to the length of the
     *      supplied consideration array).
     *
     * @param cdPtr A calldata pointer for the OrderComponents struct.
     *
     * @return mPtr A memory pointer to the OrderParameters struct head.
     */
    function _decodeOrderComponentsAsOrderParameters(
        CalldataPointer cdPtr
    ) internal pure returns (MemoryPointer mPtr) {
        // Allocate memory for the OrderParameters head.
        mPtr = malloc(OrderParameters_head_size);

        // Copy the full OrderComponents head from calldata to memory.
        cdPtr.copy(mPtr, OrderComponents_OrderParameters_common_head_size);

        // Resolve the offer calldata offset, use that to decode and copy offer
        // from calldata, and write resultant memory offset to head in memory.
        mPtr.offset(OrderParameters_offer_head_offset).write(
            _decodeOffer(cdPtr.pptr(OrderParameters_offer_head_offset))
        );

        // Resolve consideration calldata offset, use that to copy consideration
        // from calldata, and write resultant memory offset to head in memory.
        MemoryPointer consideration = _decodeConsideration(
            cdPtr.pptr(OrderParameters_consideration_head_offset)
        );
        mPtr.offset(OrderParameters_consideration_head_offset).write(
            consideration
        );

        // Write masked consideration length to totalOriginalConsiderationItems.
        mPtr
            .offset(OrderParameters_totalOriginalConsiderationItems_offset)
            .write(consideration.readUint256());
    }

    /**
     * @dev Decodes the returndata from a call to generateOrder, or returns
     *      empty arrays and a boolean signifying that the returndata does not
     *      adhere to a valid encoding scheme if it cannot be decoded.
     *
     * @return invalidEncoding A boolean signifying whether the returndata has
     *                         an invalid encoding.
     * @return offer           The decoded offer array.
     * @return consideration   The decoded consideration array.
     */
    function _decodeGenerateOrderReturndata()
        internal
        pure
        returns (
            uint256 invalidEncoding,
            MemoryPointer offer,
            MemoryPointer consideration
        )
    {
        assembly {
            // Check that returndatasize is at least four words: offerOffset,
            // considerationOffset, offerLength, & considerationLength
            invalidEncoding := lt(returndatasize(), FourWords)

            let offsetOffer
            let offsetConsideration
            let offerLength
            let considerationLength

            // Proceed if enough returndata is present to continue evaluation.
            if iszero(invalidEncoding) {
                // Copy first two words of returndata (the offsets to offer and
                // consideration array lengths) to scratch space.
                returndatacopy(0, 0, TwoWords)
                offsetOffer := mload(0)
                offsetConsideration := mload(OneWord)

                // If valid length, check that offsets are within returndata.
                let invalidOfferOffset := gt(offsetOffer, returndatasize())
                let invalidConsiderationOffset := gt(
                    offsetConsideration,
                    returndatasize()
                )

                // Only proceed if length (and thus encoding) is valid so far.
                invalidEncoding := or(
                    invalidOfferOffset,
                    invalidConsiderationOffset
                )
                if iszero(invalidEncoding) {
                    // Copy length of offer array to scratch space.
                    returndatacopy(0, offsetOffer, OneWord)
                    offerLength := mload(0)

                    // Copy length of consideration array to scratch space.
                    returndatacopy(OneWord, offsetConsideration, OneWord)
                    considerationLength := mload(OneWord)

                    {
                        // Calculate total size of offer & consideration arrays.
                        let totalOfferSize := shl(
                            SpentItem_size_shift,
                            offerLength
                        )
                        let totalConsiderationSize := mul(
                            ReceivedItem_size,
                            considerationLength
                        )

                        // Add 4 words to total size to cover the offset and
                        // length fields of the two arrays.
                        let totalSize := add(
                            FourWords,
                            add(totalOfferSize, totalConsiderationSize)
                        )
                        // Don't continue if returndatasize exceeds 65535 bytes
                        // or is greater than the calculated size.
                        invalidEncoding := or(
                            gt(
                                or(offerLength, considerationLength),
                                generateOrder_maximum_returndatasize
                            ),
                            gt(totalSize, returndatasize())
                        )

                        // Set first word of scratch space to 0 so length of
                        // offer/consideration are set to 0 on invalid encoding.
                        mstore(0, 0)
                    }
                }
            }

            if iszero(invalidEncoding) {
                offer := copySpentItemsAsOfferItems(
                    add(offsetOffer, OneWord),
                    offerLength
                )

                consideration := copyReceivedItemsAsConsiderationItems(
                    add(offsetConsideration, OneWord),
                    considerationLength
                )
            }

            function copySpentItemsAsOfferItems(rdPtrHead, length)
                -> mPtrLength
            {
                // Retrieve the current free memory pointer.
                mPtrLength := mload(FreeMemoryPointerSlot)

                // Allocate memory for the array.
                mstore(
                    FreeMemoryPointerSlot,
                    add(
                        mPtrLength,
                        add(OneWord, mul(length, OfferItem_size_with_length))
                    )
                )

                // Write the length of the array to the start of free memory.
                mstore(mPtrLength, length)

                // Use offset from length to minimize stack depth.
                let headOffsetFromLength := OneWord
                let headSizeWithLength := shl(OneWordShift, add(1, length))
                let mPtrTailNext := add(mPtrLength, headSizeWithLength)

                // Iterate over each element.
                for {

                } lt(headOffsetFromLength, headSizeWithLength) {

                } {
                    // Write the memory pointer to the accompanying head offset.
                    mstore(add(mPtrLength, headOffsetFromLength), mPtrTailNext)

                    // Copy itemType, token, identifier and amount.
                    returndatacopy(mPtrTailNext, rdPtrHead, SpentItem_size)

                    // Copy amount to endAmount.
                    mstore(
                        add(mPtrTailNext, Common_endAmount_offset),
                        mload(add(mPtrTailNext, Common_amount_offset))
                    )

                    // Update read pointer, next tail pointer, and head offset.
                    rdPtrHead := add(rdPtrHead, SpentItem_size)
                    mPtrTailNext := add(mPtrTailNext, OfferItem_size)
                    headOffsetFromLength := add(headOffsetFromLength, OneWord)
                }
            }

            function copyReceivedItemsAsConsiderationItems(rdPtrHead, length)
                -> mPtrLength
            {
                // Retrieve the current free memory pointer.
                mPtrLength := mload(FreeMemoryPointerSlot)

                // Allocate memory for the array.
                mstore(
                    FreeMemoryPointerSlot,
                    add(
                        mPtrLength,
                        add(
                            OneWord,
                            mul(length, ConsiderationItem_size_with_length)
                        )
                    )
                )

                // Write the length of the array to the start of free memory.
                mstore(mPtrLength, length)

                // Use offset from length to minimize stack depth.
                let headOffsetFromLength := OneWord
                let headSizeWithLength := shl(OneWordShift, add(1, length))
                let mPtrTailNext := add(mPtrLength, headSizeWithLength)

                // Iterate over each element.
                for {

                } lt(headOffsetFromLength, headSizeWithLength) {

                } {
                    // Write the memory pointer to the accompanying head offset.
                    mstore(add(mPtrLength, headOffsetFromLength), mPtrTailNext)

                    // Copy itemType, token, identifier and amount.
                    returndatacopy(
                        mPtrTailNext,
                        rdPtrHead,
                        ReceivedItem_size_excluding_recipient
                    )

                    // Copy amount and recipient.
                    returndatacopy(
                        add(mPtrTailNext, Common_endAmount_offset),
                        add(rdPtrHead, Common_amount_offset),
                        TwoWords
                    )

                    // Update read pointer, next tail pointer, and head offset.
                    rdPtrHead := add(rdPtrHead, ReceivedItem_size)
                    mPtrTailNext := add(mPtrTailNext, ConsiderationItem_size)
                    headOffsetFromLength := add(headOffsetFromLength, OneWord)
                }
            }
        }
    }

    /**
     * @dev Converts a function returning _decodeGenerateOrderReturndata types
     *      into a function returning offer and consideration types.
     *
     * @param inFn The input function, taking no arguments and returning an
     *             error buffer, spent item array, and received item array.
     *
     * @return outFn The output function, taking no arguments and returning an
     *               error buffer, offer array, and consideration array.
     */
    function _convertGetGeneratedOrderResult(
        function()
            internal
            pure
            returns (uint256, MemoryPointer, MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function()
                internal
                pure
                returns (
                    uint256,
                    OfferItem[] memory,
                    ConsiderationItem[] memory
                ) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking ReceivedItem, address, bytes32, and bytes
     *      types (e.g. the _transfer function) into a function taking
     *      OfferItem, address, bytes32, and bytes types.
     *
     * @param inFn The input function, taking ReceivedItem, address, bytes32,
     *             and bytes types (e.g. the _transfer function).
     *
     * @return outFn The output function, taking OfferItem, address, bytes32,
     *               and bytes types.
     */
    function _toOfferItemInput(
        function(ReceivedItem memory, address, bytes32, bytes memory)
            internal inFn
    )
        internal
        pure
        returns (
            function(OfferItem memory, address, bytes32, bytes memory)
                internal outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking ReceivedItem, address, bytes32, and bytes
     *      types (e.g. the _transfer function) into a function taking
     *      ConsiderationItem, address, bytes32, and bytes types.
     *
     * @param inFn The input function, taking ReceivedItem, address, bytes32,
     *             and bytes types (e.g. the _transfer function).
     *
     * @return outFn The output function, taking ConsiderationItem, address,
     *               bytes32, and bytes types.
     */
    function _toConsiderationItemInput(
        function(ReceivedItem memory, address, bytes32, bytes memory)
            internal inFn
    )
        internal
        pure
        returns (
            function(ConsiderationItem memory, address, bytes32, bytes memory)
                internal outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking a calldata pointer and returning a memory
     *      pointer into a function taking that calldata pointer and returning
     *      an OrderParameters type.
     *
     * @param inFn The input function, taking an arbitrary calldata pointer and
     *             returning an arbitrary memory pointer.
     *
     * @return outFn The output function, taking an arbitrary calldata pointer
     *               and returning an OrderParameters type.
     */
    function _toOrderParametersReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (OrderParameters memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking a calldata pointer and returning a memory
     *      pointer into a function taking that calldata pointer and returning
     *      an AdvancedOrder type.
     *
     * @param inFn The input function, taking an arbitrary calldata pointer and
     *             returning an arbitrary memory pointer.
     *
     * @return outFn The output function, taking an arbitrary calldata pointer
     *               and returning an AdvancedOrder type.
     */
    function _toAdvancedOrderReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (AdvancedOrder memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking a calldata pointer and returning a memory
     *      pointer into a function taking that calldata pointer and returning
     *      a dynamic array of CriteriaResolver types.
     *
     * @param inFn The input function, taking an arbitrary calldata pointer and
     *             returning an arbitrary memory pointer.
     *
     * @return outFn The output function, taking an arbitrary calldata pointer
     *               and returning a dynamic array of CriteriaResolver types.
     */
    function _toCriteriaResolversReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (CriteriaResolver[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking a calldata pointer and returning a memory
     *      pointer into a function taking that calldata pointer and returning
     *      a dynamic array of Order types.
     *
     * @param inFn The input function, taking an arbitrary calldata pointer and
     *             returning an arbitrary memory pointer.
     *
     * @return outFn The output function, taking an arbitrary calldata pointer
     *               and returning a dynamic array of Order types.
     */
    function _toOrdersReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (Order[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking a calldata pointer and returning a memory
     *      pointer into a function taking that calldata pointer and returning
     *      a nested dynamic array of dynamic arrays of FulfillmentComponent
     *      types.
     *
     * @param inFn The input function, taking an arbitrary calldata pointer and
     *             returning an arbitrary memory pointer.
     *
     * @return outFn The output function, taking an arbitrary calldata pointer
     *               and returning a nested dynamic array of dynamic arrays of
     *               FulfillmentComponent types.
     */
    function _toNestedFulfillmentComponentsReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (FulfillmentComponent[][] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking a calldata pointer and returning a memory
     *      pointer into a function taking that calldata pointer and returning
     *      a dynamic array of AdvancedOrder types.
     *
     * @param inFn The input function, taking an arbitrary calldata pointer and
     *             returning an arbitrary memory pointer.
     *
     * @return outFn The output function, taking an arbitrary calldata pointer
     *               and returning a dynamic array of AdvancedOrder types.
     */
    function _toAdvancedOrdersReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (AdvancedOrder[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts a function taking a calldata pointer and returning a memory
     *      pointer into a function taking that calldata pointer and returning
     *      a dynamic array of Fulfillment types.
     *
     * @param inFn The input function, taking an arbitrary calldata pointer and
     *             returning an arbitrary memory pointer.
     *
     * @return outFn The output function, taking an arbitrary calldata pointer
     *               and returning a dynamic array of Fulfillment types.
     */
    function _toFulfillmentsReturnType(
        function(CalldataPointer) internal pure returns (MemoryPointer) inFn
    )
        internal
        pure
        returns (
            function(CalldataPointer)
                internal
                pure
                returns (Fulfillment[] memory) outFn
        )
    {
        assembly {
            outFn := inFn
        }
    }

    /**
     * @dev Converts an offer item into a received item, applying a given
     *      recipient.
     *
     * @param offerItem The offer item.
     * @param recipient The recipient.
     *
     * @return receivedItem The received item.
     */
    function _fromOfferItemToReceivedItemWithRecipient(
        OfferItem memory offerItem,
        address recipient
    ) internal pure returns (ReceivedItem memory receivedItem) {
        assembly {
            receivedItem := offerItem
            mstore(add(receivedItem, ReceivedItem_recipient_offset), recipient)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    BasicOrder_additionalRecipients_length_cdPtr,
    BasicOrder_common_params_size,
    BasicOrder_startTime_cdPtr,
    BasicOrder_startTimeThroughZoneHash_size,
    Common_amount_offset,
    Common_identifier_offset,
    Common_token_offset,
    generateOrder_base_tail_offset,
    generateOrder_context_head_offset,
    generateOrder_head_offset,
    generateOrder_maximumSpent_head_offset,
    generateOrder_minimumReceived_head_offset,
    generateOrder_selector_offset,
    generateOrder_selector,
    OneWord,
    OneWordShift,
    OnlyFullWordMask,
    OrderFulfilled_baseDataSize,
    OrderFulfilled_offer_length_baseOffset,
    OrderParameters_consideration_head_offset,
    OrderParameters_endTime_offset,
    OrderParameters_offer_head_offset,
    OrderParameters_startTime_offset,
    OrderParameters_zoneHash_offset,
    ratifyOrder_base_tail_offset,
    ratifyOrder_consideration_head_offset,
    ratifyOrder_context_head_offset,
    ratifyOrder_contractNonce_offset,
    ratifyOrder_head_offset,
    ratifyOrder_orderHashes_head_offset,
    ratifyOrder_selector_offset,
    ratifyOrder_selector,
    ReceivedItem_size,
    Selector_length,
    SixtyThreeBytes,
    SpentItem_size_shift,
    SpentItem_size,
    validateOrder_head_offset,
    validateOrder_selector_offset,
    validateOrder_selector,
    validateOrder_zoneParameters_offset,
    ZoneParameters_base_tail_offset,
    ZoneParameters_basicOrderFixedElements_length,
    ZoneParameters_consideration_head_offset,
    ZoneParameters_endTime_offset,
    ZoneParameters_extraData_head_offset,
    ZoneParameters_fulfiller_offset,
    ZoneParameters_offer_head_offset,
    ZoneParameters_offerer_offset,
    ZoneParameters_orderHashes_head_offset,
    ZoneParameters_selectorAndPointer_length,
    ZoneParameters_startTime_offset,
    ZoneParameters_zoneHash_offset
} from "./ConsiderationConstants.sol";

import {
    BasicOrderParameters,
    OrderParameters
} from "./ConsiderationStructs.sol";

import {
    CalldataPointer,
    getFreeMemoryPointer,
    MemoryPointer
} from "../helpers/PointerLibraries.sol";

contract ConsiderationEncoder {
    /**
     * @dev Takes a bytes array and casts it to a memory pointer.
     *
     * @param obj A bytes array in memory.
     *
     * @return ptr A memory pointer to the start of the bytes array in memory.
     */
    function toMemoryPointer(
        bytes memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Takes an array of bytes32 types and casts it to a memory pointer.
     *
     * @param obj An array of bytes32 types in memory.
     *
     * @return ptr A memory pointer to the start of the array of bytes32 types
     *             in memory.
     */
    function toMemoryPointer(
        bytes32[] memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Takes a bytes array in memory and copies it to a new location in
     *      memory.
     *
     * @param src A memory pointer referencing the bytes array to be copied (and
     *            pointing to the length of the bytes array).
     * @param src A memory pointer referencing the location in memory to copy
     *            the bytes array to (and pointing to the length of the copied
     *            bytes array).
     *
     * @return size The size of the bytes array.
     */
    function _encodeBytes(
        MemoryPointer src,
        MemoryPointer dst
    ) internal view returns (uint256 size) {
        unchecked {
            // Mask the length of the bytes array to protect against overflow
            // and round up to the nearest word.
            // Note: `size` also includes the 1 word that stores the length.
            size = (src.readUint256() + SixtyThreeBytes) & OnlyFullWordMask;

            // Copy the bytes array to the new memory location.
            src.copy(dst, size);
        }
    }

    /**
     * @dev Takes an OrderParameters struct and a context bytes array in memory
     *      and encodes it as `generateOrder` calldata.
     *
     * @param orderParameters The OrderParameters struct used to construct the
     *                        encoded `generateOrder` calldata.
     * @param context         The context bytes array used to construct the
     *                        encoded `generateOrder` calldata.
     *
     * @return dst  A memory pointer referencing the encoded `generateOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeGenerateOrder(
        OrderParameters memory orderParameters,
        bytes memory context
    ) internal view returns (MemoryPointer dst, uint256 size) {
        // Get the memory pointer for the OrderParameters struct.
        MemoryPointer src = orderParameters.toMemoryPointer();

        // Get free memory pointer to write calldata to.
        dst = getFreeMemoryPointer();

        // Write generateOrder selector and get pointer to start of calldata.
        dst.write(generateOrder_selector);
        dst = dst.offset(generateOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(generateOrder_head_offset);

        // Write `fulfiller` to calldata.
        dstHead.write(msg.sender);

        // Initialize tail offset, used to populate the minimumReceived array.
        uint256 tailOffset = generateOrder_base_tail_offset;

        // Write offset to minimumReceived.
        dstHead.offset(generateOrder_minimumReceived_head_offset).write(
            tailOffset
        );

        // Get memory pointer to `orderParameters.offer.length`.
        MemoryPointer srcOfferPointer = src
            .offset(OrderParameters_offer_head_offset)
            .readMemoryPointer();

        // Encode the offer array as a `SpentItem[]`.
        uint256 minimumReceivedSize = _encodeSpentItems(
            srcOfferPointer,
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate maximumSpent array.
            tailOffset += minimumReceivedSize;
        }

        // Write offset to maximumSpent.
        dstHead.offset(generateOrder_maximumSpent_head_offset).write(
            tailOffset
        );

        // Get memory pointer to `orderParameters.consideration.length`.
        MemoryPointer srcConsiderationPointer = src
            .offset(OrderParameters_consideration_head_offset)
            .readMemoryPointer();

        // Encode the consideration array as a `SpentItem[]`.
        uint256 maximumSpentSize = _encodeSpentItems(
            srcConsiderationPointer,
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate context array.
            tailOffset += maximumSpentSize;
        }

        // Write offset to context.
        dstHead.offset(generateOrder_context_head_offset).write(tailOffset);

        // Get memory pointer to context.
        MemoryPointer srcContext = toMemoryPointer(context);

        // Encode context as a bytes array.
        uint256 contextSize = _encodeBytes(
            srcContext,
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment the tail offset, now used to determine final size.
            tailOffset += contextSize;

            // Derive the final size by including the selector.
            size = Selector_length + tailOffset;
        }
    }

    /**
     * @dev Takes an order hash (e.g. offerer shifted 96 bits to the left XOR'd
     *      with the contract nonce in the case of contract orders), an
     *      OrderParameters struct, context bytes array, and an array of order
     *      hashes for each order included as part of the current fulfillment
     *      and encodes it as `ratifyOrder` calldata.
     *
     * @param orderHash       The order hash (e.g. shl(0x60, offerer) ^ nonce).
     * @param orderParameters The OrderParameters struct used to construct the
     *                        encoded `ratifyOrder` calldata.
     * @param context         The context bytes array used to construct the
     *                        encoded `ratifyOrder` calldata.
     * @param orderHashes     An array of bytes32 values representing the order
     *                        hashes of all orders included as part of the
     *                        current fulfillment.
     * @param shiftedOfferer  The offerer for the order, shifted 96 bits to the
     *                        left.
     *
     * @return dst  A memory pointer referencing the encoded `ratifyOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeRatifyOrder(
        bytes32 orderHash, // e.g. shl(0x60, offerer) ^ contract nonce
        OrderParameters memory orderParameters,
        bytes memory context, // encoded based on the schemaID
        bytes32[] memory orderHashes,
        uint256 shiftedOfferer
    ) internal view returns (MemoryPointer dst, uint256 size) {
        // Get free memory pointer to write calldata to. This isn't allocated as
        // it is only used for a single function call.
        dst = getFreeMemoryPointer();

        // Write ratifyOrder selector and get pointer to start of calldata.
        dst.write(ratifyOrder_selector);
        dst = dst.offset(ratifyOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(ratifyOrder_head_offset);

        // Write contractNonce to calldata via xor(orderHash, shiftedOfferer).
        dstHead.offset(ratifyOrder_contractNonce_offset).write(
            uint256(orderHash) ^ shiftedOfferer
        );

        // Initialize tail offset, used to populate the offer array.
        uint256 tailOffset = ratifyOrder_base_tail_offset;
        MemoryPointer src = orderParameters.toMemoryPointer();

        // Write offset to `offer`.
        dstHead.write(tailOffset);

        // Get memory pointer to `orderParameters.offer.length`.
        MemoryPointer srcOfferPointer = src
            .offset(OrderParameters_offer_head_offset)
            .readMemoryPointer();

        // Encode the offer array as a `SpentItem[]`.
        uint256 offerSize = _encodeSpentItems(
            srcOfferPointer,
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate consideration array.
            tailOffset += offerSize;
        }

        // Write offset to consideration.
        dstHead.offset(ratifyOrder_consideration_head_offset).write(tailOffset);

        // Get pointer to `orderParameters.consideration.length`.
        MemoryPointer srcConsiderationPointer = src
            .offset(OrderParameters_consideration_head_offset)
            .readMemoryPointer();

        // Encode the consideration array as a `ReceivedItem[]`.
        uint256 considerationSize = _encodeConsiderationAsReceivedItems(
            srcConsiderationPointer,
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate context array.
            tailOffset += considerationSize;
        }

        // Write offset to context.
        dstHead.offset(ratifyOrder_context_head_offset).write(tailOffset);

        // Encode context.
        uint256 contextSize = _encodeBytes(
            toMemoryPointer(context),
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate orderHashes array.
            tailOffset += contextSize;
        }

        // Write offset to orderHashes.
        dstHead.offset(ratifyOrder_orderHashes_head_offset).write(tailOffset);

        // Encode orderHashes.
        uint256 orderHashesSize = _encodeOrderHashes(
            toMemoryPointer(orderHashes),
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment the tail offset, now used to determine final size.
            tailOffset += orderHashesSize;

            // Derive the final size by including the selector.
            size = Selector_length + tailOffset;
        }
    }

    /**
     * @dev Takes an order hash, OrderParameters struct, extraData bytes array,
     *      and array of order hashes for each order included as part of the
     *      current fulfillment and encodes it as `validateOrder` calldata.
     *      Note that future, new versions of this contract may end up writing
     *      to a memory region that might have been potentially dirtied by the
     *      accumulator. Since the book-keeping for the accumulator does not
     *      update the free memory pointer, it will be necessary to ensure that
     *      all bytes in the memory in the range [dst, dst+size) are fully
     *      updated/written to in this function.
     *
     * @param orderHash       The order hash.
     * @param orderParameters The OrderParameters struct used to construct the
     *                        encoded `validateOrder` calldata.
     * @param extraData       The extraData bytes array used to construct the
     *                        encoded `validateOrder` calldata.
     * @param orderHashes     An array of bytes32 values representing the order
     *                        hashes of all orders included as part of the
     *                        current fulfillment.
     *
     * @return dst  A memory pointer referencing the encoded `validateOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeValidateOrder(
        bytes32 orderHash,
        OrderParameters memory orderParameters,
        bytes memory extraData,
        bytes32[] memory orderHashes
    ) internal view returns (MemoryPointer dst, uint256 size) {
        // Get free memory pointer to write calldata to. This isn't allocated as
        // it is only used for a single function call.
        dst = getFreeMemoryPointer();

        // Write validateOrder selector and get pointer to start of calldata.
        dst.write(validateOrder_selector);
        dst = dst.offset(validateOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(validateOrder_head_offset);

        // Write offset to zoneParameters to start of calldata.
        dstHead.write(validateOrder_zoneParameters_offset);

        // Reuse `dstHead` as pointer to zoneParameters.
        dstHead = dstHead.offset(validateOrder_zoneParameters_offset);

        // Write orderHash and fulfiller to zoneParameters.
        dstHead.writeBytes32(orderHash);
        dstHead.offset(ZoneParameters_fulfiller_offset).write(msg.sender);

        // Get the memory pointer to the order parameters struct.
        MemoryPointer src = orderParameters.toMemoryPointer();

        // Copy offerer, startTime, endTime and zoneHash to zoneParameters.
        dstHead.offset(ZoneParameters_offerer_offset).write(src.readUint256());
        dstHead.offset(ZoneParameters_startTime_offset).write(
            src.offset(OrderParameters_startTime_offset).readUint256()
        );
        dstHead.offset(ZoneParameters_endTime_offset).write(
            src.offset(OrderParameters_endTime_offset).readUint256()
        );
        dstHead.offset(ZoneParameters_zoneHash_offset).write(
            src.offset(OrderParameters_zoneHash_offset).readUint256()
        );

        // Initialize tail offset, used to populate the offer array.
        uint256 tailOffset = ZoneParameters_base_tail_offset;

        // Write offset to `offer`.
        dstHead.offset(ZoneParameters_offer_head_offset).write(tailOffset);

        // Get pointer to `orderParameters.offer.length`.
        MemoryPointer srcOfferPointer = src
            .offset(OrderParameters_offer_head_offset)
            .readMemoryPointer();

        // Encode the offer array as a `SpentItem[]`.
        uint256 offerSize = _encodeSpentItems(
            srcOfferPointer,
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate consideration array.
            tailOffset += offerSize;
        }

        // Write offset to consideration.
        dstHead.offset(ZoneParameters_consideration_head_offset).write(
            tailOffset
        );

        // Get pointer to `orderParameters.consideration.length`.
        MemoryPointer srcConsiderationPointer = src
            .offset(OrderParameters_consideration_head_offset)
            .readMemoryPointer();

        // Encode the consideration array as a `ReceivedItem[]`.
        uint256 considerationSize = _encodeConsiderationAsReceivedItems(
            srcConsiderationPointer,
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate extraData array.
            tailOffset += considerationSize;
        }

        // Write offset to extraData.
        dstHead.offset(ZoneParameters_extraData_head_offset).write(tailOffset);
        // Copy extraData.
        uint256 extraDataSize = _encodeBytes(
            toMemoryPointer(extraData),
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment tail offset, now used to populate orderHashes array.
            tailOffset += extraDataSize;
        }

        // Write offset to orderHashes.
        dstHead.offset(ZoneParameters_orderHashes_head_offset).write(
            tailOffset
        );

        // Encode the order hashes array.
        uint256 orderHashesSize = _encodeOrderHashes(
            toMemoryPointer(orderHashes),
            dstHead.offset(tailOffset)
        );

        unchecked {
            // Increment the tail offset, now used to determine final size.
            tailOffset += orderHashesSize;

            // Derive final size including selector and ZoneParameters pointer.
            size = ZoneParameters_selectorAndPointer_length + tailOffset;
        }
    }

    /**
     * @dev Takes an order hash and BasicOrderParameters struct (from calldata)
     *      and encodes it as `validateOrder` calldata.
     *
     * @param orderHash  The order hash.
     * @param parameters The BasicOrderParameters struct used to construct the
     *                   encoded `validateOrder` calldata.
     *
     * @return dst  A memory pointer referencing the encoded `validateOrder`
     *              calldata.
     * @return size The size of the bytes array.
     */
    function _encodeValidateBasicOrder(
        bytes32 orderHash,
        BasicOrderParameters calldata parameters
    ) internal view returns (MemoryPointer dst, uint256 size) {
        // Get free memory pointer to write calldata to. This isn't allocated as
        // it is only used for a single function call.
        dst = getFreeMemoryPointer();

        // Write validateOrder selector and get pointer to start of calldata.
        dst.write(validateOrder_selector);
        dst = dst.offset(validateOrder_selector_offset);

        // Get pointer to the beginning of the encoded data.
        MemoryPointer dstHead = dst.offset(validateOrder_head_offset);

        // Write offset to zoneParameters to start of calldata.
        dstHead.write(validateOrder_zoneParameters_offset);

        // Reuse `dstHead` as pointer to zoneParameters.
        dstHead = dstHead.offset(validateOrder_zoneParameters_offset);

        // Write offerer, orderHash and fulfiller to zoneParameters.
        dstHead.writeBytes32(orderHash);
        dstHead.offset(ZoneParameters_fulfiller_offset).write(msg.sender);
        dstHead.offset(ZoneParameters_offerer_offset).write(parameters.offerer);

        // Copy startTime, endTime and zoneHash to zoneParameters.
        CalldataPointer.wrap(BasicOrder_startTime_cdPtr).copy(
            dstHead.offset(ZoneParameters_startTime_offset),
            BasicOrder_startTimeThroughZoneHash_size
        );

        // Initialize tail offset, used for the offer + consideration arrays.
        uint256 tailOffset = ZoneParameters_base_tail_offset;

        // Write offset to offer from event data into target calldata.
        dstHead.offset(ZoneParameters_offer_head_offset).write(tailOffset);

        unchecked {
            // Write consideration offset next (located 5 words after offer).
            dstHead.offset(ZoneParameters_consideration_head_offset).write(
                tailOffset + BasicOrder_common_params_size
            );

            // Retrieve the offset to the length of additional recipients.
            uint256 additionalRecipientsLength = CalldataPointer
                .wrap(BasicOrder_additionalRecipients_length_cdPtr)
                .readUint256();

            // Derive offset to event data using base offset & total recipients.
            uint256 offerDataOffset = OrderFulfilled_offer_length_baseOffset +
                additionalRecipientsLength *
                OneWord;

            // Derive size of offer and consideration data.
            // 2 words (lengths) + 4 (offer data) + 5 (consideration 1) + 5 * ar
            uint256 offerAndConsiderationSize = OrderFulfilled_baseDataSize +
                (additionalRecipientsLength * ReceivedItem_size);

            // Copy offer and consideration data from event data to calldata.
            MemoryPointer.wrap(offerDataOffset).copy(
                dstHead.offset(tailOffset),
                offerAndConsiderationSize
            );

            // Increment tail offset, now used to populate extraData array.
            tailOffset += offerAndConsiderationSize;
        }

        // Write empty bytes for extraData.
        dstHead.offset(ZoneParameters_extraData_head_offset).write(tailOffset);
        dstHead.offset(tailOffset).write(0);

        unchecked {
            // Increment tail offset, now used to populate orderHashes array.
            tailOffset += OneWord;
        }

        // Write offset to orderHashes.
        dstHead.offset(ZoneParameters_orderHashes_head_offset).write(
            tailOffset
        );

        // Write length = 1 to the orderHashes array.
        dstHead.offset(tailOffset).write(1);

        unchecked {
            // Write the single order hash to the orderHashes array.
            dstHead.offset(tailOffset + OneWord).writeBytes32(orderHash);

            // Final size: selector, ZoneParameters pointer, orderHashes & tail.
            size = ZoneParameters_basicOrderFixedElements_length + tailOffset;
        }
    }

    /**
     * @dev Takes a memory pointer to an array of bytes32 values representing
     *      the order hashes included as part of the fulfillment and a memory
     *      pointer to a location to copy it to, and copies the source data to
     *      the destination in memory.
     *
     * @param srcLength A memory pointer referencing the order hashes array to
     *                  be copied (and pointing to the length of the array).
     * @param dstLength A memory pointer referencing the location in memory to
     *                  copy the orderHashes array to (and pointing to the
     *                  length of the copied array).
     *
     * @return size The size of the order hashes array (including the length).
     */
    function _encodeOrderHashes(
        MemoryPointer srcLength,
        MemoryPointer dstLength
    ) internal view returns (uint256 size) {
        // Read length of the array from source and write to destination.
        uint256 length = srcLength.readUint256();
        dstLength.write(length);

        unchecked {
            // Determine head & tail size as one word per element in the array.
            uint256 headAndTailSize = length << OneWordShift;

            // Copy the tail starting from the next element of the source to the
            // next element of the destination.
            srcLength.next().copy(dstLength.next(), headAndTailSize);

            // Set size to the length of the tail plus one word for length.
            size = headAndTailSize + OneWord;
        }
    }

    /**
     * @dev Takes a memory pointer to an offer or consideration array and a
     *      memory pointer to a location to copy it to, and copies the source
     *      data to the destination in memory as a SpentItem array.
     *
     * @param srcLength A memory pointer referencing the offer or consideration
     *                  array to be copied as a SpentItem array (and pointing to
     *                  the length of the original array).
     * @param dstLength A memory pointer referencing the location in memory to
     *                  copy the offer array to (and pointing to the length of
     *                  the copied array).
     *
     * @return size The size of the SpentItem array (including the length).
     */
    function _encodeSpentItems(
        MemoryPointer srcLength,
        MemoryPointer dstLength
    ) internal pure returns (uint256 size) {
        assembly {
            // Read length of the array from source and write to destination.
            let length := mload(srcLength)
            mstore(dstLength, length)

            // Get pointer to first item's head position in the array,
            // containing the item's pointer in memory. The head pointer will be
            // incremented until it reaches the tail position (start of the
            // array data).
            let mPtrHead := add(srcLength, OneWord)

            // Position in memory to write next item for calldata. Since
            // SpentItem has a fixed length, the array elements do not contain
            // head elements in calldata, they are concatenated together after
            // the array length.
            let cdPtrData := add(dstLength, OneWord)

            // Pointer to end of array head in memory.
            let mPtrHeadEnd := add(mPtrHead, shl(OneWordShift, length))

            for {

            } lt(mPtrHead, mPtrHeadEnd) {

            } {
                // Read pointer to data for array element from head position.
                let mPtrTail := mload(mPtrHead)

                // Copy itemType, token, identifier, amount to calldata.
                mstore(cdPtrData, mload(mPtrTail))
                mstore(
                    add(cdPtrData, Common_token_offset),
                    mload(add(mPtrTail, Common_token_offset))
                )
                mstore(
                    add(cdPtrData, Common_identifier_offset),
                    mload(add(mPtrTail, Common_identifier_offset))
                )
                mstore(
                    add(cdPtrData, Common_amount_offset),
                    mload(add(mPtrTail, Common_amount_offset))
                )

                mPtrHead := add(mPtrHead, OneWord)
                cdPtrData := add(cdPtrData, SpentItem_size)
            }

            size := add(OneWord, shl(SpentItem_size_shift, length))
        }
    }

    /**
     * @dev Takes a memory pointer to an consideration array and a memory
     *      pointer to a location to copy it to, and copies the source data to
     *      the destination in memory as a ReceivedItem array.
     *
     * @param srcLength A memory pointer referencing the consideration array to
     *                  be copied as a ReceivedItem array (and pointing to the
     *                  length of the original array).
     * @param dstLength A memory pointer referencing the location in memory to
     *                  copy the consideration array to as a ReceivedItem array
     *                  (and pointing to the length of the new array).
     *
     * @return size The size of the ReceivedItem array (including the length).
     */
    function _encodeConsiderationAsReceivedItems(
        MemoryPointer srcLength,
        MemoryPointer dstLength
    ) internal view returns (uint256 size) {
        unchecked {
            // Read length of the array from source and write to destination.
            uint256 length = srcLength.readUint256();
            dstLength.write(length);

            // Get pointer to first item's head position in the array,
            // containing the item's pointer in memory. The head pointer will be
            // incremented until it reaches the tail position (start of the
            // array data).
            MemoryPointer srcHead = srcLength.next();
            MemoryPointer srcHeadEnd = srcHead.offset(length << OneWordShift);

            // Position in memory to write next item for calldata. Since
            // ReceivedItem has a fixed length, the array elements do not
            // contain offsets in calldata, they are concatenated together after
            // the array length.
            MemoryPointer dstHead = dstLength.next();
            while (srcHead.lt(srcHeadEnd)) {
                MemoryPointer srcTail = srcHead.pptr();
                srcTail.copy(dstHead, ReceivedItem_size);
                srcHead = srcHead.next();
                dstHead = dstHead.offset(ReceivedItem_size);
            }

            size = OneWord + (length * ReceivedItem_size);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED,

    // 4: contract order type
    CONTRACT
}

enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

uint256 constant Error_selector_offset = 0x1c;

/*
 *  error MissingFulfillmentComponentOnAggregation(uint8 side)
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: side
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant MissingFulfillmentComponentOnAggregation_error_selector = (
    0x375c24c1
);
uint256 constant MissingFulfillmentComponentOnAggregation_error_side_ptr = 0x20;
uint256 constant MissingFulfillmentComponentOnAggregation_error_length = 0x24;

/*
 *  error OfferAndConsiderationRequiredOnFulfillment()
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OfferAndConsiderationRequiredOnFulfillment_error_selector = (
    0x98e9db6e
);
uint256 constant OfferAndConsiderationRequiredOnFulfillment_error_length = 0x04;

/*
 *  error MismatchedFulfillmentOfferAndConsiderationComponents(
 *      uint256 fulfillmentIndex
 *  )
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: fulfillmentIndex
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant MismatchedOfferAndConsiderationComponents_error_selector = (
    0xbced929d
);
uint256 constant MismatchedOfferAndConsiderationComponents_error_idx_ptr = 0x20;
uint256 constant MismatchedOfferAndConsiderationComponents_error_length = 0x24;

/*
 *  error InvalidFulfillmentComponentData()
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidFulfillmentComponentData_error_selector = 0x7fda7279;
uint256 constant InvalidFulfillmentComponentData_error_length = 0x04;

/*
 *  error InexactFraction()
 *    - Defined in AmountDerivationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InexactFraction_error_selector = 0xc63cf089;
uint256 constant InexactFraction_error_length = 0x04;

/*
 *  error OrderCriteriaResolverOutOfRange(uint8 side)
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: side
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderCriteriaResolverOutOfRange_error_selector = 0x133c37c6;
uint256 constant OrderCriteriaResolverOutOfRange_error_side_ptr = 0x20;
uint256 constant OrderCriteriaResolverOutOfRange_error_length = 0x24;

/*
 *  error UnresolvedOfferCriteria(uint256 orderIndex, uint256 offerIndex)
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderIndex
 *    - 0x40: offerIndex
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant UnresolvedOfferCriteria_error_selector = 0xd6929332;
uint256 constant UnresolvedOfferCriteria_error_orderIndex_ptr = 0x20;
uint256 constant UnresolvedOfferCriteria_error_offerIndex_ptr = 0x40;
uint256 constant UnresolvedOfferCriteria_error_length = 0x44;

/*
 *  error UnresolvedConsiderationCriteria(
 *      uint256 orderIndex,
 *      uint256 considerationIndex
 *  )
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderIndex
 *    - 0x40: considerationIndex
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant UnresolvedConsiderationCriteria_error_selector = 0xa8930e9a;
uint256 constant UnresolvedConsiderationCriteria_error_orderIndex_ptr = 0x20;
uint256 constant UnresolvedConsiderationCriteria_error_considerationIdx_ptr = (
    0x40
);
uint256 constant UnresolvedConsiderationCriteria_error_length = 0x44;

/*
 *  error OfferCriteriaResolverOutOfRange()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OfferCriteriaResolverOutOfRange_error_selector = 0xbfb3f8ce;
// uint256 constant OfferCriteriaResolverOutOfRange_error_length = 0x04;

/*
 *  error ConsiderationCriteriaResolverOutOfRange()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant ConsiderationCriteriaResolverOutOfRange_error_selector = (
    0x6088d7de
);
uint256 constant ConsiderationCriteriaResolverOutOfRange_err_selector = (
    0x6088d7de
);
// uint256 constant ConsiderationCriteriaResolverOutOfRange_error_length = 0x04;

/*
 *  error CriteriaNotEnabledForItem()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant CriteriaNotEnabledForItem_error_selector = 0x94eb6af6;
uint256 constant CriteriaNotEnabledForItem_error_length = 0x04;

/*
 *  error InvalidProof()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidProof_error_selector = 0x09bde339;
uint256 constant InvalidProof_error_length = 0x04;

/*
 *  error InvalidRestrictedOrder(bytes32 orderHash)
 *    - Defined in ZoneInteractionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidRestrictedOrder_error_selector = 0xfb5014fc;
uint256 constant InvalidRestrictedOrder_error_orderHash_ptr = 0x20;
uint256 constant InvalidRestrictedOrder_error_length = 0x24;

/*
 *  error InvalidContractOrder(bytes32 orderHash)
 *    - Defined in ZoneInteractionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidContractOrder_error_selector = 0x93979285;
uint256 constant InvalidContractOrder_error_orderHash_ptr = 0x20;
uint256 constant InvalidContractOrder_error_length = 0x24;

/*
 *  error BadSignatureV(uint8 v)
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: v
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant BadSignatureV_error_selector = 0x1f003d0a;
uint256 constant BadSignatureV_error_v_ptr = 0x20;
uint256 constant BadSignatureV_error_length = 0x24;

/*
 *  error InvalidSigner()
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidSigner_error_selector = 0x815e1d64;
uint256 constant InvalidSigner_error_length = 0x04;

/*
 *  error InvalidSignature()
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidSignature_error_selector = 0x8baa579f;
uint256 constant InvalidSignature_error_length = 0x04;

/*
 *  error BadContractSignature()
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant BadContractSignature_error_selector = 0x4f7fb80d;
uint256 constant BadContractSignature_error_length = 0x04;

/*
 *  error InvalidERC721TransferAmount(uint256 amount)
 *    - Defined in TokenTransferrerErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: amount
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidERC721TransferAmount_error_selector = 0x69f95827;
uint256 constant InvalidERC721TransferAmount_error_amount_ptr = 0x20;
uint256 constant InvalidERC721TransferAmount_error_length = 0x24;

/*
 *  error MissingItemAmount()
 *    - Defined in TokenTransferrerErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant MissingItemAmount_error_selector = 0x91b3e514;
uint256 constant MissingItemAmount_error_length = 0x04;

/*
 *  error UnusedItemParameters()
 *    - Defined in TokenTransferrerErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant UnusedItemParameters_error_selector = 0x6ab37ce7;
uint256 constant UnusedItemParameters_error_length = 0x04;

/*
 *  error NoReentrantCalls()
 *    - Defined in ReentrancyErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant NoReentrantCalls_error_selector = 0x7fa8a987;
uint256 constant NoReentrantCalls_error_length = 0x04;

/*
 *  error OrderAlreadyFilled(bytes32 orderHash)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderAlreadyFilled_error_selector = 0x10fda3e1;
uint256 constant OrderAlreadyFilled_error_orderHash_ptr = 0x20;
uint256 constant OrderAlreadyFilled_error_length = 0x24;

/*
 *  error InvalidTime(uint256 startTime, uint256 endTime)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: startTime
 *    - 0x40: endTime
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant InvalidTime_error_selector = 0x21ccfeb7;
uint256 constant InvalidTime_error_startTime_ptr = 0x20;
uint256 constant InvalidTime_error_endTime_ptr = 0x40;
uint256 constant InvalidTime_error_length = 0x44;

/*
 *  error InvalidConduit(bytes32 conduitKey, address conduit)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: conduitKey
 *    - 0x40: conduit
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant InvalidConduit_error_selector = 0x1cf99b26;
uint256 constant InvalidConduit_error_conduitKey_ptr = 0x20;
uint256 constant InvalidConduit_error_conduit_ptr = 0x40;
uint256 constant InvalidConduit_error_length = 0x44;

/*
 *  error MissingOriginalConsiderationItems()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant MissingOriginalConsiderationItems_error_selector = 0x466aa616;
uint256 constant MissingOriginalConsiderationItems_error_length = 0x04;

/*
 *  error InvalidCallToConduit(address conduit)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: conduit
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidCallToConduit_error_selector = 0xd13d53d4;
uint256 constant InvalidCallToConduit_error_conduit_ptr = 0x20;
uint256 constant InvalidCallToConduit_error_length = 0x24;

/*
 *  error ConsiderationNotMet(
 *      uint256 orderIndex,
 *      uint256 considerationIndex,
 *      uint256 shortfallAmount
 *  )
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderIndex
 *    - 0x40: considerationIndex
 *    - 0x60: shortfallAmount
 * Revert buffer is memory[0x1c:0x80]
 */
uint256 constant ConsiderationNotMet_error_selector = 0xa5f54208;
uint256 constant ConsiderationNotMet_error_orderIndex_ptr = 0x20;
uint256 constant ConsiderationNotMet_error_considerationIndex_ptr = 0x40;
uint256 constant ConsiderationNotMet_error_shortfallAmount_ptr = 0x60;
uint256 constant ConsiderationNotMet_error_length = 0x64;

/*
 *  error InsufficientNativeTokensSupplied()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InsufficientNativeTokensSupplied_error_selector = 0x8ffff980;
uint256 constant InsufficientNativeTokensSupplied_error_length = 0x04;

/*
 *  error NativeTokenTransferGenericFailure(address account, uint256 amount)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: account
 *    - 0x40: amount
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant NativeTokenTransferGenericFailure_error_selector = 0xbc806b96;
uint256 constant NativeTokenTransferGenericFailure_error_account_ptr = 0x20;
uint256 constant NativeTokenTransferGenericFailure_error_amount_ptr = 0x40;
uint256 constant NativeTokenTransferGenericFailure_error_length = 0x44;

/*
 *  error PartialFillsNotEnabledForOrder()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant PartialFillsNotEnabledForOrder_error_selector = 0xa11b63ff;
uint256 constant PartialFillsNotEnabledForOrder_error_length = 0x04;

/*
 *  error OrderIsCancelled(bytes32 orderHash)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderIsCancelled_error_selector = 0x1a515574;
uint256 constant OrderIsCancelled_error_orderHash_ptr = 0x20;
uint256 constant OrderIsCancelled_error_length = 0x24;

/*
 *  error OrderPartiallyFilled(bytes32 orderHash)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderPartiallyFilled_error_selector = 0xee9e0e63;
uint256 constant OrderPartiallyFilled_error_orderHash_ptr = 0x20;
uint256 constant OrderPartiallyFilled_error_length = 0x24;

/*
 *  error CannotCancelOrder()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant CannotCancelOrder_error_selector = 0xfed398fc;
uint256 constant CannotCancelOrder_error_length = 0x04;

/*
 *  error BadFraction()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant BadFraction_error_selector = 0x5a052b32;
uint256 constant BadFraction_error_length = 0x04;

/*
 *  error InvalidMsgValue(uint256 value)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: value
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidMsgValue_error_selector = 0xa61be9f0;
uint256 constant InvalidMsgValue_error_value_ptr = 0x20;
uint256 constant InvalidMsgValue_error_length = 0x24;

/*
 *  error InvalidBasicOrderParameterEncoding()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidBasicOrderParameterEncoding_error_selector = 0x39f3e3fd;
uint256 constant InvalidBasicOrderParameterEncoding_error_length = 0x04;

/*
 *  error NoSpecifiedOrdersAvailable()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant NoSpecifiedOrdersAvailable_error_selector = 0xd5da9a1b;
uint256 constant NoSpecifiedOrdersAvailable_error_length = 0x04;

/*
 *  error InvalidNativeOfferItem()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidNativeOfferItem_error_selector = 0x12d3f5a3;
uint256 constant InvalidNativeOfferItem_error_length = 0x04;

/*
 *  error ConsiderationLengthNotEqualToTotalOriginal()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant ConsiderationLengthNotEqualToTotalOriginal_error_selector = (
    0x2165628a
);
uint256 constant ConsiderationLengthNotEqualToTotalOriginal_error_length = 0x04;

/*
 *  error Panic(uint256 code)
 *    - Built-in Solidity error
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: code
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant Panic_error_selector = 0x4e487b71;
uint256 constant Panic_error_code_ptr = 0x20;
uint256 constant Panic_error_length = 0x24;

uint256 constant Panic_arithmetic = 0x11;
// uint256 constant Panic_resource = 0x41;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Side } from "./ConsiderationEnums.sol";

import {
    BadFraction_error_length,
    BadFraction_error_selector,
    CannotCancelOrder_error_length,
    CannotCancelOrder_error_selector,
    ConsiderationLengthNotEqualToTotalOriginal_error_length,
    ConsiderationLengthNotEqualToTotalOriginal_error_selector,
    ConsiderationNotMet_error_considerationIndex_ptr,
    ConsiderationNotMet_error_length,
    ConsiderationNotMet_error_orderIndex_ptr,
    ConsiderationNotMet_error_selector,
    ConsiderationNotMet_error_shortfallAmount_ptr,
    CriteriaNotEnabledForItem_error_length,
    CriteriaNotEnabledForItem_error_selector,
    Error_selector_offset,
    InsufficientNativeTokensSupplied_error_length,
    InsufficientNativeTokensSupplied_error_selector,
    InvalidBasicOrderParameterEncoding_error_length,
    InvalidBasicOrderParameterEncoding_error_selector,
    InvalidCallToConduit_error_conduit_ptr,
    InvalidCallToConduit_error_length,
    InvalidCallToConduit_error_selector,
    InvalidConduit_error_conduit_ptr,
    InvalidConduit_error_conduitKey_ptr,
    InvalidConduit_error_length,
    InvalidConduit_error_selector,
    InvalidContractOrder_error_length,
    InvalidContractOrder_error_orderHash_ptr,
    InvalidContractOrder_error_selector,
    InvalidERC721TransferAmount_error_amount_ptr,
    InvalidERC721TransferAmount_error_length,
    InvalidERC721TransferAmount_error_selector,
    InvalidMsgValue_error_length,
    InvalidMsgValue_error_selector,
    InvalidMsgValue_error_value_ptr,
    InvalidNativeOfferItem_error_length,
    InvalidNativeOfferItem_error_selector,
    InvalidProof_error_length,
    InvalidProof_error_selector,
    InvalidTime_error_endTime_ptr,
    InvalidTime_error_length,
    InvalidTime_error_selector,
    InvalidTime_error_startTime_ptr,
    MismatchedOfferAndConsiderationComponents_error_idx_ptr,
    MismatchedOfferAndConsiderationComponents_error_length,
    MismatchedOfferAndConsiderationComponents_error_selector,
    MissingFulfillmentComponentOnAggregation_error_length,
    MissingFulfillmentComponentOnAggregation_error_selector,
    MissingFulfillmentComponentOnAggregation_error_side_ptr,
    MissingOriginalConsiderationItems_error_length,
    MissingOriginalConsiderationItems_error_selector,
    NoReentrantCalls_error_length,
    NoReentrantCalls_error_selector,
    NoSpecifiedOrdersAvailable_error_length,
    NoSpecifiedOrdersAvailable_error_selector,
    OfferAndConsiderationRequiredOnFulfillment_error_length,
    OfferAndConsiderationRequiredOnFulfillment_error_selector,
    OrderAlreadyFilled_error_length,
    OrderAlreadyFilled_error_orderHash_ptr,
    OrderAlreadyFilled_error_selector,
    OrderCriteriaResolverOutOfRange_error_length,
    OrderCriteriaResolverOutOfRange_error_selector,
    OrderCriteriaResolverOutOfRange_error_side_ptr,
    OrderIsCancelled_error_length,
    OrderIsCancelled_error_orderHash_ptr,
    OrderIsCancelled_error_selector,
    OrderPartiallyFilled_error_length,
    OrderPartiallyFilled_error_orderHash_ptr,
    OrderPartiallyFilled_error_selector,
    PartialFillsNotEnabledForOrder_error_length,
    PartialFillsNotEnabledForOrder_error_selector,
    UnresolvedConsiderationCriteria_error_considerationIdx_ptr,
    UnresolvedConsiderationCriteria_error_length,
    UnresolvedConsiderationCriteria_error_orderIndex_ptr,
    UnresolvedConsiderationCriteria_error_selector,
    UnresolvedOfferCriteria_error_length,
    UnresolvedOfferCriteria_error_offerIndex_ptr,
    UnresolvedOfferCriteria_error_orderIndex_ptr,
    UnresolvedOfferCriteria_error_selector,
    UnusedItemParameters_error_length,
    UnusedItemParameters_error_selector
} from "./ConsiderationErrorConstants.sol";

/**
 * @dev Reverts the current transaction with a "BadFraction" error message.
 */
function _revertBadFraction() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, BadFraction_error_selector)

        // revert(abi.encodeWithSignature("BadFraction()"))
        revert(Error_selector_offset, BadFraction_error_length)
    }
}

/**
 * @dev Reverts the current transaction with a "ConsiderationNotMet" error
 *      message, including the provided order index, consideration index, and
 *      shortfall amount.
 *
 * @param orderIndex         The index of the order that did not meet the
 *                           consideration criteria.
 * @param considerationIndex The index of the consideration item that did not
 *                           meet its criteria.
 * @param shortfallAmount    The amount by which the consideration criteria were
 *                           not met.
 */
function _revertConsiderationNotMet(
    uint256 orderIndex,
    uint256 considerationIndex,
    uint256 shortfallAmount
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, ConsiderationNotMet_error_selector)

        // Store arguments.
        mstore(ConsiderationNotMet_error_orderIndex_ptr, orderIndex)
        mstore(
            ConsiderationNotMet_error_considerationIndex_ptr,
            considerationIndex
        )
        mstore(ConsiderationNotMet_error_shortfallAmount_ptr, shortfallAmount)

        // revert(abi.encodeWithSignature(
        //     "ConsiderationNotMet(uint256,uint256,uint256)",
        //     orderIndex,
        //     considerationIndex,
        //     shortfallAmount
        // ))
        revert(Error_selector_offset, ConsiderationNotMet_error_length)
    }
}

/**
 * @dev Reverts the current transaction with a "CriteriaNotEnabledForItem" error
 *      message.
 */
function _revertCriteriaNotEnabledForItem() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, CriteriaNotEnabledForItem_error_selector)

        // revert(abi.encodeWithSignature("CriteriaNotEnabledForItem()"))
        revert(Error_selector_offset, CriteriaNotEnabledForItem_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an
 *      "InsufficientNativeTokensSupplied" error message.
 */
function _revertInsufficientNativeTokensSupplied() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InsufficientNativeTokensSupplied_error_selector)

        // revert(abi.encodeWithSignature("InsufficientNativeTokensSupplied()"))
        revert(
            Error_selector_offset,
            InsufficientNativeTokensSupplied_error_length
        )
    }
}

/**
 * @dev Reverts the current transaction with an
 *      "InvalidBasicOrderParameterEncoding" error message.
 */
function _revertInvalidBasicOrderParameterEncoding() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidBasicOrderParameterEncoding_error_selector)

        // revert(abi.encodeWithSignature(
        //     "InvalidBasicOrderParameterEncoding()"
        // ))
        revert(
            Error_selector_offset,
            InvalidBasicOrderParameterEncoding_error_length
        )
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidCallToConduit" error
 *      message, including the provided address of the conduit that was called
 *      improperly.
 *
 * @param conduit The address of the conduit that was called improperly.
 */
function _revertInvalidCallToConduit(address conduit) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidCallToConduit_error_selector)

        // Store argument.
        mstore(InvalidCallToConduit_error_conduit_ptr, conduit)

        // revert(abi.encodeWithSignature(
        //     "InvalidCallToConduit(address)",
        //     conduit
        // ))
        revert(Error_selector_offset, InvalidCallToConduit_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "CannotCancelOrder" error
 *      message.
 */
function _revertCannotCancelOrder() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, CannotCancelOrder_error_selector)

        // revert(abi.encodeWithSignature("CannotCancelOrder()"))
        revert(Error_selector_offset, CannotCancelOrder_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidConduit" error message,
 *      including the provided key and address of the invalid conduit.
 *
 * @param conduitKey    The key of the invalid conduit.
 * @param conduit       The address of the invalid conduit.
 */
function _revertInvalidConduit(bytes32 conduitKey, address conduit) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidConduit_error_selector)

        // Store arguments.
        mstore(InvalidConduit_error_conduitKey_ptr, conduitKey)
        mstore(InvalidConduit_error_conduit_ptr, conduit)

        // revert(abi.encodeWithSignature(
        //     "InvalidConduit(bytes32,address)",
        //     conduitKey,
        //     conduit
        // ))
        revert(Error_selector_offset, InvalidConduit_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidERC721TransferAmount"
 *      error message.
 *
 * @param amount The invalid amount.
 */
function _revertInvalidERC721TransferAmount(uint256 amount) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidERC721TransferAmount_error_selector)

        // Store argument.
        mstore(InvalidERC721TransferAmount_error_amount_ptr, amount)

        // revert(abi.encodeWithSignature(
        //     "InvalidERC721TransferAmount(uint256)",
        //     amount
        // ))
        revert(Error_selector_offset, InvalidERC721TransferAmount_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidMsgValue" error message,
 *      including the invalid value that was sent in the transaction's
 *      `msg.value` field.
 *
 * @param value The invalid value that was sent in the transaction's `msg.value`
 *              field.
 */
function _revertInvalidMsgValue(uint256 value) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidMsgValue_error_selector)

        // Store argument.
        mstore(InvalidMsgValue_error_value_ptr, value)

        // revert(abi.encodeWithSignature("InvalidMsgValue(uint256)", value))
        revert(Error_selector_offset, InvalidMsgValue_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidNativeOfferItem" error
 *      message.
 */
function _revertInvalidNativeOfferItem() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidNativeOfferItem_error_selector)

        // revert(abi.encodeWithSignature("InvalidNativeOfferItem()"))
        revert(Error_selector_offset, InvalidNativeOfferItem_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidProof" error message.
 */
function _revertInvalidProof() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidProof_error_selector)

        // revert(abi.encodeWithSignature("InvalidProof()"))
        revert(Error_selector_offset, InvalidProof_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidContractOrder" error
 *      message.
 *
 * @param orderHash The hash of the contract order that caused the error.
 */
function _revertInvalidContractOrder(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidContractOrder_error_selector)

        // Store arguments.
        mstore(InvalidContractOrder_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "InvalidContractOrder(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, InvalidContractOrder_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidTime" error message.
 *
 * @param startTime       The time at which the order becomes active.
 * @param endTime         The time at which the order becomes inactive.
 */
function _revertInvalidTime(uint256 startTime, uint256 endTime) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidTime_error_selector)

        // Store arguments.
        mstore(InvalidTime_error_startTime_ptr, startTime)
        mstore(InvalidTime_error_endTime_ptr, endTime)

        // revert(abi.encodeWithSignature(
        //     "InvalidTime(uint256,uint256)",
        //     startTime,
        //     endTime
        // ))
        revert(Error_selector_offset, InvalidTime_error_length)
    }
}

/**
 * @dev Reverts execution with a
 *      "MismatchedFulfillmentOfferAndConsiderationComponents" error message.
 *
 * @param fulfillmentIndex         The index of the fulfillment that caused the
 *                                 error.
 */
function _revertMismatchedFulfillmentOfferAndConsiderationComponents(
    uint256 fulfillmentIndex
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, MismatchedOfferAndConsiderationComponents_error_selector)

        // Store fulfillment index argument.
        mstore(
            MismatchedOfferAndConsiderationComponents_error_idx_ptr,
            fulfillmentIndex
        )

        // revert(abi.encodeWithSignature(
        //     "MismatchedFulfillmentOfferAndConsiderationComponents(uint256)",
        //     fulfillmentIndex
        // ))
        revert(
            Error_selector_offset,
            MismatchedOfferAndConsiderationComponents_error_length
        )
    }
}

/**
 * @dev Reverts execution with a "MissingFulfillmentComponentOnAggregation"
 *       error message.
 *
 * @param side The side of the fulfillment component that is missing (0 for
 *             offer, 1 for consideration).
 *
 */
function _revertMissingFulfillmentComponentOnAggregation(Side side) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, MissingFulfillmentComponentOnAggregation_error_selector)

        // Store argument.
        mstore(MissingFulfillmentComponentOnAggregation_error_side_ptr, side)

        // revert(abi.encodeWithSignature(
        //     "MissingFulfillmentComponentOnAggregation(uint8)",
        //     side
        // ))
        revert(
            Error_selector_offset,
            MissingFulfillmentComponentOnAggregation_error_length
        )
    }
}

/**
 * @dev Reverts execution with a "MissingOriginalConsiderationItems" error
 *      message.
 */
function _revertMissingOriginalConsiderationItems() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, MissingOriginalConsiderationItems_error_selector)

        // revert(abi.encodeWithSignature(
        //     "MissingOriginalConsiderationItems()"
        // ))
        revert(
            Error_selector_offset,
            MissingOriginalConsiderationItems_error_length
        )
    }
}

/**
 * @dev Reverts execution with a "NoReentrantCalls" error message.
 */
function _revertNoReentrantCalls() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, NoReentrantCalls_error_selector)

        // revert(abi.encodeWithSignature("NoReentrantCalls()"))
        revert(Error_selector_offset, NoReentrantCalls_error_length)
    }
}

/**
 * @dev Reverts execution with a "NoSpecifiedOrdersAvailable" error message.
 */
function _revertNoSpecifiedOrdersAvailable() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, NoSpecifiedOrdersAvailable_error_selector)

        // revert(abi.encodeWithSignature("NoSpecifiedOrdersAvailable()"))
        revert(Error_selector_offset, NoSpecifiedOrdersAvailable_error_length)
    }
}

/**
 * @dev Reverts execution with a "OfferAndConsiderationRequiredOnFulfillment"
 *      error message.
 */
function _revertOfferAndConsiderationRequiredOnFulfillment() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OfferAndConsiderationRequiredOnFulfillment_error_selector)

        // revert(abi.encodeWithSignature(
        //     "OfferAndConsiderationRequiredOnFulfillment()"
        // ))
        revert(
            Error_selector_offset,
            OfferAndConsiderationRequiredOnFulfillment_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "OrderAlreadyFilled" error message.
 *
 * @param orderHash The hash of the order that has already been filled.
 */
function _revertOrderAlreadyFilled(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderAlreadyFilled_error_selector)

        // Store argument.
        mstore(OrderAlreadyFilled_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "OrderAlreadyFilled(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, OrderAlreadyFilled_error_length)
    }
}

/**
 * @dev Reverts execution with an "OrderCriteriaResolverOutOfRange" error
 *      message.
 *
 * @param side The side of the criteria that is missing (0 for offer, 1 for
 *             consideration).
 *
 */
function _revertOrderCriteriaResolverOutOfRange(Side side) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderCriteriaResolverOutOfRange_error_selector)

        // Store argument.
        mstore(OrderCriteriaResolverOutOfRange_error_side_ptr, side)

        // revert(abi.encodeWithSignature(
        //     "OrderCriteriaResolverOutOfRange(uint8)",
        //     side
        // ))
        revert(
            Error_selector_offset,
            OrderCriteriaResolverOutOfRange_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "OrderIsCancelled" error message.
 *
 * @param orderHash The hash of the order that has already been cancelled.
 */
function _revertOrderIsCancelled(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderIsCancelled_error_selector)

        // Store argument.
        mstore(OrderIsCancelled_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "OrderIsCancelled(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, OrderIsCancelled_error_length)
    }
}

/**
 * @dev Reverts execution with an "OrderPartiallyFilled" error message.
 *
 * @param orderHash The hash of the order that has already been partially
 *                  filled.
 */
function _revertOrderPartiallyFilled(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderPartiallyFilled_error_selector)

        // Store argument.
        mstore(OrderPartiallyFilled_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "OrderPartiallyFilled(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, OrderPartiallyFilled_error_length)
    }
}

/**
 * @dev Reverts execution with a "PartialFillsNotEnabledForOrder" error message.
 */
function _revertPartialFillsNotEnabledForOrder() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, PartialFillsNotEnabledForOrder_error_selector)

        // revert(abi.encodeWithSignature("PartialFillsNotEnabledForOrder()"))
        revert(
            Error_selector_offset,
            PartialFillsNotEnabledForOrder_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "UnresolvedConsiderationCriteria" error
 *      message.
 */
function _revertUnresolvedConsiderationCriteria(
    uint256 orderIndex,
    uint256 considerationIndex
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, UnresolvedConsiderationCriteria_error_selector)

        // Store orderIndex and considerationIndex arguments.
        mstore(UnresolvedConsiderationCriteria_error_orderIndex_ptr, orderIndex)
        mstore(
            UnresolvedConsiderationCriteria_error_considerationIdx_ptr,
            considerationIndex
        )

        // revert(abi.encodeWithSignature(
        //     "UnresolvedConsiderationCriteria(uint256, uint256)",
        //     orderIndex,
        //     considerationIndex
        // ))
        revert(
            Error_selector_offset,
            UnresolvedConsiderationCriteria_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "UnresolvedOfferCriteria" error message.
 */
function _revertUnresolvedOfferCriteria(
    uint256 orderIndex,
    uint256 offerIndex
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, UnresolvedOfferCriteria_error_selector)

        // Store arguments.
        mstore(UnresolvedOfferCriteria_error_orderIndex_ptr, orderIndex)
        mstore(UnresolvedOfferCriteria_error_offerIndex_ptr, offerIndex)

        // revert(abi.encodeWithSignature(
        //     "UnresolvedOfferCriteria(uint256, uint256)",
        //     orderIndex,
        //     offerIndex
        // ))
        revert(Error_selector_offset, UnresolvedOfferCriteria_error_length)
    }
}

/**
 * @dev Reverts execution with an "UnusedItemParameters" error message.
 */
function _revertUnusedItemParameters() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, UnusedItemParameters_error_selector)

        // revert(abi.encodeWithSignature("UnusedItemParameters()"))
        revert(Error_selector_offset, UnusedItemParameters_error_length)
    }
}

/**
 * @dev Reverts execution with a "ConsiderationLengthNotEqualToTotalOriginal"
 *      error message.
 */
function _revertConsiderationLengthNotEqualToTotalOriginal() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, ConsiderationLengthNotEqualToTotalOriginal_error_selector)

        // revert(abi.encodeWithSignature(
        //     "ConsiderationLengthNotEqualToTotalOriginal()"
        // ))
        revert(
            Error_selector_offset,
            ConsiderationLengthNotEqualToTotalOriginal_error_length
        )
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    BasicOrderType,
    ItemType,
    OrderType,
    Side
} from "./ConsiderationEnums.sol";

import {
    CalldataPointer,
    MemoryPointer
} from "../helpers/PointerLibraries.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be provided to the zone if the
 *      order type is restricted and the zone is not the caller, or will be
 *      provided to the offerer as context for contract order types.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

/**
 * @dev Restricted orders are validated post-execution by calling validateOrder
 *      on the zone. This struct provides context about the order fulfillment
 *      and any supplied extraData, as well as all order hashes fulfilled in a
 *      call to a match or fulfillAvailable method.
 */
struct ZoneParameters {
    bytes32 orderHash;
    address fulfiller;
    address offerer;
    SpentItem[] offer;
    ReceivedItem[] consideration;
    bytes extraData;
    bytes32[] orderHashes;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
}

/**
 * @dev Zones and contract offerers can communicate which schemas they implement
 *      along with any associated metadata related to each schema.
 */
struct Schema {
    uint256 id;
    bytes metadata;
}

using StructPointers for OrderComponents global;
using StructPointers for OfferItem global;
using StructPointers for ConsiderationItem global;
using StructPointers for SpentItem global;
using StructPointers for ReceivedItem global;
using StructPointers for BasicOrderParameters global;
using StructPointers for AdditionalRecipient global;
using StructPointers for OrderParameters global;
using StructPointers for Order global;
using StructPointers for AdvancedOrder global;
using StructPointers for OrderStatus global;
using StructPointers for CriteriaResolver global;
using StructPointers for Fulfillment global;
using StructPointers for FulfillmentComponent global;
using StructPointers for Execution global;
using StructPointers for ZoneParameters global;

/**
 * @dev This library provides a set of functions for converting structs to
 *      pointers.
 */
library StructPointers {
    /**
     * @dev Get a MemoryPointer from OrderComponents.
     *
     * @param obj The OrderComponents object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderComponents memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderComponents.
     *
     * @param obj The OrderComponents object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderComponents calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OfferItem.
     *
     * @param obj The OfferItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OfferItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OfferItem.
     *
     * @param obj The OfferItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OfferItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ConsiderationItem.
     *
     * @param obj The ConsiderationItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ConsiderationItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ConsiderationItem.
     *
     * @param obj The ConsiderationItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ConsiderationItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from SpentItem.
     *
     * @param obj The SpentItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        SpentItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from SpentItem.
     *
     * @param obj The SpentItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        SpentItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ReceivedItem.
     *
     * @param obj The ReceivedItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ReceivedItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ReceivedItem.
     *
     * @param obj The ReceivedItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ReceivedItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from BasicOrderParameters.
     *
     * @param obj The BasicOrderParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        BasicOrderParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from BasicOrderParameters.
     *
     * @param obj The BasicOrderParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        BasicOrderParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from AdditionalRecipient.
     *
     * @param obj The AdditionalRecipient object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        AdditionalRecipient memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from AdditionalRecipient.
     *
     * @param obj The AdditionalRecipient object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        AdditionalRecipient calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OrderParameters.
     *
     * @param obj The OrderParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderParameters.
     *
     * @param obj The OrderParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Order.
     *
     * @param obj The Order object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Order memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Order.
     *
     * @param obj The Order object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Order calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from AdvancedOrder.
     *
     * @param obj The AdvancedOrder object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        AdvancedOrder memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from AdvancedOrder.
     *
     * @param obj The AdvancedOrder object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        AdvancedOrder calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OrderStatus.
     *
     * @param obj The OrderStatus object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderStatus memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderStatus.
     *
     * @param obj The OrderStatus object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderStatus calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from CriteriaResolver.
     *
     * @param obj The CriteriaResolver object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        CriteriaResolver memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from CriteriaResolver.
     *
     * @param obj The CriteriaResolver object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        CriteriaResolver calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Fulfillment.
     *
     * @param obj The Fulfillment object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Fulfillment memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Fulfillment.
     *
     * @param obj The Fulfillment object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Fulfillment calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from FulfillmentComponent.
     *
     * @param obj The FulfillmentComponent object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        FulfillmentComponent memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from FulfillmentComponent.
     *
     * @param obj The FulfillmentComponent object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        FulfillmentComponent calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Execution.
     *
     * @param obj The Execution object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Execution memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Execution.
     *
     * @param obj The Execution object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Execution calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ZoneParameters.
     *
     * @param obj The ZoneParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ZoneParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ZoneParameters.
     *
     * @param obj The ZoneParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ZoneParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ConsiderationEventsAndErrors
} from "../interfaces/ConsiderationEventsAndErrors.sol";

import { ReentrancyGuard } from "./ReentrancyGuard.sol";

import {
    Counter_blockhash_shift,
    OneWord,
    TwoWords
} from "./ConsiderationConstants.sol";

/**
 * @title CounterManager
 * @author 0age
 * @notice CounterManager contains a storage mapping and related functionality
 *         for retrieving and incrementing a per-offerer counter.
 */
contract CounterManager is ConsiderationEventsAndErrors, ReentrancyGuard {
    // Only orders signed using an offerer's current counter are fulfillable.
    mapping(address => uint256) private _counters;

    /**
     * @dev Internal function to cancel all orders from a given offerer in bulk
     *      by incrementing a counter by a large, quasi-random interval. Note
     *      that only the offerer may increment the counter. Note that the
     *      counter is incremented by a large, quasi-random interval, which
     *      makes it infeasible to "activate" signed orders by incrementing the
     *      counter.  This activation functionality can be achieved instead with
     *      restricted orders or contract orders.
     *
     * @return newCounter The new counter.
     */
    function _incrementCounter() internal returns (uint256 newCounter) {
        // Ensure that the reentrancy guard is not currently set.
        _assertNonReentrant();

        // Utilize assembly to access counters storage mapping directly. Skip
        // overflow check as counter cannot be incremented that far.
        assembly {
            // Use second half of previous block hash as a quasi-random number.
            let quasiRandomNumber := shr(
                Counter_blockhash_shift,
                blockhash(sub(number(), 1))
            )

            // Write the caller to scratch space.
            mstore(0, caller())

            // Write the storage slot for _counters to scratch space.
            mstore(OneWord, _counters.slot)

            // Derive the storage pointer for the counter value.
            let storagePointer := keccak256(0, TwoWords)

            // Derive new counter value using random number and original value.
            newCounter := add(quasiRandomNumber, sload(storagePointer))

            // Store the updated counter value.
            sstore(storagePointer, newCounter)
        }

        // Emit an event containing the new counter.
        emit CounterIncremented(newCounter, msg.sender);
    }

    /**
     * @dev Internal view function to retrieve the current counter for a given
     *      offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return currentCounter The current counter.
     */
    function _getCounter(
        address offerer
    ) internal view returns (uint256 currentCounter) {
        // Return the counter for the supplied offerer.
        currentCounter = _counters[offerer];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { OrderParameters } from "./ConsiderationStructs.sol";

import { ConsiderationBase } from "./ConsiderationBase.sol";

import {
    Create2AddressDerivation_length,
    Create2AddressDerivation_ptr,
    EIP_712_PREFIX,
    EIP712_ConsiderationItem_size,
    EIP712_DigestPayload_size,
    EIP712_DomainSeparator_offset,
    EIP712_OfferItem_size,
    EIP712_Order_size,
    EIP712_OrderHash_offset,
    FreeMemoryPointerSlot,
    information_conduitController_offset,
    information_domainSeparator_offset,
    information_length,
    information_version_cd_offset,
    information_version_offset,
    information_versionLengthPtr,
    information_versionWithLength,
    MaskOverByteTwelve,
    MaskOverLastTwentyBytes,
    OneWord,
    OneWordShift,
    OrderParameters_consideration_head_offset,
    OrderParameters_counter_offset,
    OrderParameters_offer_head_offset,
    TwoWords
} from "./ConsiderationConstants.sol";

/**
 * @title GettersAndDerivers
 * @author 0age
 * @notice ConsiderationInternal contains pure and internal view functions
 *         related to getting or deriving various values.
 */
contract GettersAndDerivers is ConsiderationBase {
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(
        address conduitController
    ) ConsiderationBase(conduitController) {}

    /**
     * @dev Internal view function to derive the order hash for a given order.
     *      Note that only the original consideration items are included in the
     *      order hash, as additional consideration items may be supplied by the
     *      caller.
     *
     * @param orderParameters The parameters of the order to hash.
     * @param counter         The counter of the order to hash.
     *
     * @return orderHash The hash.
     */
    function _deriveOrderHash(
        OrderParameters memory orderParameters,
        uint256 counter
    ) internal view returns (bytes32 orderHash) {
        // Get length of original consideration array and place it on the stack.
        uint256 originalConsiderationLength = (
            orderParameters.totalOriginalConsiderationItems
        );

        /*
         * Memory layout for an array of structs (dynamic or not) is similar
         * to ABI encoding of dynamic types, with a head segment followed by
         * a data segment. The main difference is that the head of an element
         * is a memory pointer rather than an offset.
         */

        // Declare a variable for the derived hash of the offer array.
        bytes32 offerHash;

        // Read offer item EIP-712 typehash from runtime code & place on stack.
        bytes32 typeHash = _OFFER_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
        assembly {
            // Retrieve the free memory pointer and place on the stack.
            let hashArrPtr := mload(FreeMemoryPointerSlot)

            // Get the pointer to the offers array.
            let offerArrPtr := mload(
                add(orderParameters, OrderParameters_offer_head_offset)
            )

            // Load the length.
            let offerLength := mload(offerArrPtr)

            // Set the pointer to the first offer's head.
            offerArrPtr := add(offerArrPtr, OneWord)

            // Iterate over the offer items.
            for { let i := 0 } lt(i, offerLength) {
                i := add(i, 1)
            } {
                // Read the pointer to the offer data and subtract one word
                // to get typeHash pointer.
                let ptr := sub(mload(offerArrPtr), OneWord)

                // Read the current value before the offer data.
                let value := mload(ptr)

                // Write the type hash to the previous word.
                mstore(ptr, typeHash)

                // Take the EIP712 hash and store it in the hash array.
                mstore(hashArrPtr, keccak256(ptr, EIP712_OfferItem_size))

                // Restore the previous word.
                mstore(ptr, value)

                // Increment the array pointers by one word.
                offerArrPtr := add(offerArrPtr, OneWord)
                hashArrPtr := add(hashArrPtr, OneWord)
            }

            // Derive the offer hash using the hashes of each item.
            offerHash := keccak256(
                mload(FreeMemoryPointerSlot),
                shl(OneWordShift, offerLength)
            )
        }

        // Declare a variable for the derived hash of the consideration array.
        bytes32 considerationHash;

        // Read consideration item typehash from runtime code & place on stack.
        typeHash = _CONSIDERATION_ITEM_TYPEHASH;

        // Utilize assembly so that memory regions can be reused across hashes.
        assembly {
            // Retrieve the free memory pointer and place on the stack.
            let hashArrPtr := mload(FreeMemoryPointerSlot)

            // Get the pointer to the consideration array.
            let considerationArrPtr := add(
                mload(
                    add(
                        orderParameters,
                        OrderParameters_consideration_head_offset
                    )
                ),
                OneWord
            )

            // Iterate over the consideration items (not including tips).
            for { let i := 0 } lt(i, originalConsiderationLength) {
                i := add(i, 1)
            } {
                // Read the pointer to the consideration data and subtract one
                // word to get typeHash pointer.
                let ptr := sub(mload(considerationArrPtr), OneWord)

                // Read the current value before the consideration data.
                let value := mload(ptr)

                // Write the type hash to the previous word.
                mstore(ptr, typeHash)

                // Take the EIP712 hash and store it in the hash array.
                mstore(
                    hashArrPtr,
                    keccak256(ptr, EIP712_ConsiderationItem_size)
                )

                // Restore the previous word.
                mstore(ptr, value)

                // Increment the array pointers by one word.
                considerationArrPtr := add(considerationArrPtr, OneWord)
                hashArrPtr := add(hashArrPtr, OneWord)
            }

            // Derive the consideration hash using the hashes of each item.
            considerationHash := keccak256(
                mload(FreeMemoryPointerSlot),
                shl(OneWordShift, originalConsiderationLength)
            )
        }

        // Read order item EIP-712 typehash from runtime code & place on stack.
        typeHash = _ORDER_TYPEHASH;

        // Utilize assembly to access derived hashes & other arguments directly.
        assembly {
            // Retrieve pointer to the region located just behind parameters.
            let typeHashPtr := sub(orderParameters, OneWord)

            // Store the value at that pointer location to restore later.
            let previousValue := mload(typeHashPtr)

            // Store the order item EIP-712 typehash at the typehash location.
            mstore(typeHashPtr, typeHash)

            // Retrieve the pointer for the offer array head.
            let offerHeadPtr := add(
                orderParameters,
                OrderParameters_offer_head_offset
            )

            // Retrieve the data pointer referenced by the offer head.
            let offerDataPtr := mload(offerHeadPtr)

            // Store the offer hash at the retrieved memory location.
            mstore(offerHeadPtr, offerHash)

            // Retrieve the pointer for the consideration array head.
            let considerationHeadPtr := add(
                orderParameters,
                OrderParameters_consideration_head_offset
            )

            // Retrieve the data pointer referenced by the consideration head.
            let considerationDataPtr := mload(considerationHeadPtr)

            // Store the consideration hash at the retrieved memory location.
            mstore(considerationHeadPtr, considerationHash)

            // Retrieve the pointer for the counter.
            let counterPtr := add(
                orderParameters,
                OrderParameters_counter_offset
            )

            // Store the counter at the retrieved memory location.
            mstore(counterPtr, counter)

            // Derive the order hash using the full range of order parameters.
            orderHash := keccak256(typeHashPtr, EIP712_Order_size)

            // Restore the value previously held at typehash pointer location.
            mstore(typeHashPtr, previousValue)

            // Restore offer data pointer at the offer head pointer location.
            mstore(offerHeadPtr, offerDataPtr)

            // Restore consideration data pointer at the consideration head ptr.
            mstore(considerationHeadPtr, considerationDataPtr)

            // Restore consideration item length at the counter pointer.
            mstore(counterPtr, originalConsiderationLength)
        }
    }

    /**
     * @dev Internal view function to derive the address of a given conduit
     *      using a corresponding conduit key.
     *
     * @param conduitKey A bytes32 value indicating what corresponding conduit,
     *                   if any, to source token approvals from. This value is
     *                   the "salt" parameter supplied by the deployer (i.e. the
     *                   conduit controller) when deploying the given conduit.
     *
     * @return conduit The address of the conduit associated with the given
     *                 conduit key.
     */
    function _deriveConduit(
        bytes32 conduitKey
    ) internal view returns (address conduit) {
        // Read conduit controller address from runtime and place on the stack.
        address conduitController = address(_CONDUIT_CONTROLLER);

        // Read conduit creation code hash from runtime and place on the stack.
        bytes32 conduitCreationCodeHash = _CONDUIT_CREATION_CODE_HASH;

        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Retrieve the free memory pointer; it will be replaced afterwards.
            let freeMemoryPointer := mload(FreeMemoryPointerSlot)

            // Place the control character and the conduit controller in scratch
            // space; note that eleven bytes at the beginning are left unused.
            mstore(0, or(MaskOverByteTwelve, conduitController))

            // Place the conduit key in the next region of scratch space.
            mstore(OneWord, conduitKey)

            // Place conduit creation code hash in free memory pointer location.
            mstore(TwoWords, conduitCreationCodeHash)

            // Derive conduit by hashing and applying a mask over last 20 bytes.
            conduit := and(
                // Hash the relevant region.
                keccak256(
                    // The region starts at memory pointer 11.
                    Create2AddressDerivation_ptr,
                    // The region is 85 bytes long (1 + 20 + 32 + 32).
                    Create2AddressDerivation_length
                ),
                // The address equals the last twenty bytes of the hash.
                MaskOverLastTwentyBytes
            )

            // Restore the free memory pointer.
            mstore(FreeMemoryPointerSlot, freeMemoryPointer)
        }
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     *
     * @return The domain separator.
     */
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == _CHAIN_ID
            ? _DOMAIN_SEPARATOR
            : _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to retrieve configuration information for
     *      this contract.
     *
     * @return The contract version.
     * @return The domain separator for this contract.
     * @return The conduit Controller set for this contract.
     */
    function _information()
        internal
        view
        returns (
            string memory /* version */,
            bytes32 /* domainSeparator */,
            address /* conduitController */
        )
    {
        // Derive the domain separator.
        bytes32 domainSeparator = _domainSeparator();

        // Declare variable as immutables cannot be accessed within assembly.
        address conduitController = address(_CONDUIT_CONTROLLER);

        // Return the version, domain separator, and conduit controller.
        assembly {
            mstore(information_version_offset, information_version_cd_offset)
            mstore(information_domainSeparator_offset, domainSeparator)
            mstore(information_conduitController_offset, conduitController)
            mstore(information_versionLengthPtr, information_versionWithLength)
            return(information_version_offset, information_length)
        }
    }

    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param domainSeparator The domain separator.
     * @param orderHash       The order hash.
     *
     * @return value The hash.
     */
    function _deriveEIP712Digest(
        bytes32 domainSeparator,
        bytes32 orderHash
    ) internal pure returns (bytes32 value) {
        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(0, EIP_712_PREFIX)

            // Place the domain separator in the next region of scratch space.
            mstore(EIP712_DomainSeparator_offset, domainSeparator)

            // Place the order hash in scratch space, spilling into the first
            // two bytes of the free memory pointer — this should never be set
            // as memory cannot be expanded to that size, and will be zeroed out
            // after the hash is performed.
            mstore(EIP712_OrderHash_offset, orderHash)

            // Hash the relevant region (65 bytes).
            value := keccak256(0, EIP712_DigestPayload_size)

            // Clear out the dirtied bits in the memory pointer.
            mstore(EIP712_OrderHash_offset, 0)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    CostPerWord,
    ExtraGasBuffer,
    FreeMemoryPointerSlot,
    MemoryExpansionCoefficientShift,
    OneWord,
    OneWordShift,
    ThirtyOneBytes
} from "./ConsiderationConstants.sol";

/**
 * @title LowLevelHelpers
 * @author 0age
 * @notice LowLevelHelpers contains logic for performing various low-level
 *         operations.
 */
contract LowLevelHelpers {
    /**
     * @dev Internal view function to revert and pass along the revert reason if
     *      data was returned by the last call and that the size of that data
     *      does not exceed the currently allocated memory size.
     */
    function _revertWithReasonIfOneIsReturned() internal view {
        assembly {
            // If it returned a message, bubble it up as long as sufficient gas
            // remains to do so:
            if returndatasize() {
                // Ensure that sufficient gas is available to copy returndata
                // while expanding memory where necessary. Start by computing
                // the word size of returndata and allocated memory.
                let returnDataWords := shr(
                    OneWordShift,
                    add(returndatasize(), ThirtyOneBytes)
                )

                // Note: use the free memory pointer in place of msize() to work
                // around a Yul warning that prevents accessing msize directly
                // when the IR pipeline is activated.
                let msizeWords := shr(
                    OneWordShift,
                    mload(FreeMemoryPointerSlot)
                )

                // Next, compute the cost of the returndatacopy.
                let cost := mul(CostPerWord, returnDataWords)

                // Then, compute cost of new memory allocation.
                if gt(returnDataWords, msizeWords) {
                    cost := add(
                        cost,
                        add(
                            mul(sub(returnDataWords, msizeWords), CostPerWord),
                            shr(
                                MemoryExpansionCoefficientShift,
                                sub(
                                    mul(returnDataWords, returnDataWords),
                                    mul(msizeWords, msizeWords)
                                )
                            )
                        )
                    )
                }

                // Finally, add a small constant and compare to gas remaining;
                // bubble up the revert data if enough gas is still available.
                if lt(add(cost, ExtraGasBuffer), gas()) {
                    // Copy returndata to memory; overwrite existing memory.
                    returndatacopy(0, 0, returndatasize())

                    // Revert, specifying memory region with copied returndata.
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @dev Internal view function to branchlessly select either the caller (if
     *      a supplied recipient is equal to zero) or the supplied recipient (if
     *      that recipient is a nonzero value).
     *
     * @param recipient The supplied recipient.
     *
     * @return updatedRecipient The updated recipient.
     */
    function _substituteCallerForEmptyRecipient(
        address recipient
    ) internal view returns (address updatedRecipient) {
        // Utilize assembly to perform a branchless operation on the recipient.
        assembly {
            // Add caller to recipient if recipient equals 0; otherwise add 0.
            updatedRecipient := add(recipient, mul(iszero(recipient), caller()))
        }
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReentrancyErrors } from "../interfaces/ReentrancyErrors.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import {
    _revertInvalidMsgValue,
    _revertNoReentrantCalls
} from "./ConsiderationErrors.sol";

import {
    _ENTERED_AND_ACCEPTING_NATIVE_TOKENS,
    _ENTERED,
    _NOT_ENTERED
} from "./ConsiderationConstants.sol";

/**
 * @title ReentrancyGuard
 * @author 0age
 * @notice ReentrancyGuard contains a storage variable and related functionality
 *         for protecting against reentrancy.
 */
contract ReentrancyGuard is ReentrancyErrors, LowLevelHelpers {
    // Prevent reentrant calls on protected functions.
    uint256 private _reentrancyGuard;

    /**
     * @dev Initialize the reentrancy guard during deployment.
     */
    constructor() {
        // Initialize the reentrancy guard in a cleared state.
        _reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal function to ensure that a sentinel value for the reentrancy
     *      guard is not currently set and, if not, to set a sentinel value for
     *      the reentrancy guard based on whether or not native tokens may be
     *      received during execution or not.
     *
     * @param acceptNativeTokens A boolean indicating whether native tokens may
     *                           be received during execution or not.
     */
    function _setReentrancyGuard(bool acceptNativeTokens) internal {
        // Ensure that the reentrancy guard is not already set.
        _assertNonReentrant();

        // Set the reentrancy guard. A value of 2 indicates that native tokens
        // may not be accepted during execution, whereas a value of 3 indicates
        // that they will be accepted (with any remaining native tokens returned
        // to the caller).
        unchecked {
            _reentrancyGuard = _ENTERED + _cast(acceptNativeTokens);
        }
    }

    /**
     * @dev Internal function to unset the reentrancy guard sentinel value.
     */
    function _clearReentrancyGuard() internal {
        // Clear the reentrancy guard.
        _reentrancyGuard = _NOT_ENTERED;
    }

    /**
     * @dev Internal view function to ensure that a sentinel value for the
            reentrancy guard is not currently set.
     */
    function _assertNonReentrant() internal view {
        // Ensure that the reentrancy guard is not currently set.
        if (_reentrancyGuard != _NOT_ENTERED) {
            _revertNoReentrantCalls();
        }
    }

    /**
     * @dev Internal view function to ensure that the sentinel value indicating
     *      native tokens may be received during execution is currently set.
     */
    function _assertAcceptingNativeTokens() internal view {
        // Ensure that the reentrancy guard is not currently set.
        if (_reentrancyGuard != _ENTERED_AND_ACCEPTING_NATIVE_TOKENS) {
            _revertInvalidMsgValue(msg.value);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    SignatureVerificationErrors
} from "../interfaces/SignatureVerificationErrors.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import {
    ECDSA_MaxLength,
    ECDSA_signature_s_offset,
    ECDSA_signature_v_offset,
    ECDSA_twentySeventhAndTwentyEighthBytesSet,
    Ecrecover_args_size,
    Ecrecover_precompile,
    EIP1271_isValidSignature_calldata_baseLength,
    EIP1271_isValidSignature_digest_negativeOffset,
    EIP1271_isValidSignature_selector_negativeOffset,
    EIP1271_isValidSignature_selector,
    EIP1271_isValidSignature_signature_head_offset,
    EIP2098_allButHighestBitMask,
    MaxUint8,
    OneWord,
    Signature_lower_v
} from "./ConsiderationConstants.sol";

import {
    BadContractSignature_error_length,
    BadContractSignature_error_selector,
    BadSignatureV_error_length,
    BadSignatureV_error_selector,
    BadSignatureV_error_v_ptr,
    Error_selector_offset,
    InvalidSignature_error_length,
    InvalidSignature_error_selector,
    InvalidSigner_error_length,
    InvalidSigner_error_selector
} from "./ConsiderationErrorConstants.sol";

/**
 * @title SignatureVerification
 * @author 0age
 * @notice SignatureVerification contains logic for verifying signatures.
 */
contract SignatureVerification is SignatureVerificationErrors, LowLevelHelpers {
    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer.
     *
     * @param signer                  The signer for the order.
     * @param digest                  The digest to verify signature against.
     * @param originalDigest          The original digest to verify signature
     *                                against.
     * @param originalSignatureLength The original signature length.
     * @param signature               A signature from the signer indicating
     *                                that the order has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes32 originalDigest,
        uint256 originalSignatureLength,
        bytes memory signature
    ) internal view {
        // Declare value for ecrecover equality or 1271 call success status.
        bool success;

        // Utilize assembly to perform optimized signature verification check.
        assembly {
            // Ensure that first word of scratch space is empty.
            mstore(0, 0)

            // Get the length of the signature.
            let signatureLength := mload(signature)

            // Get the pointer to the value preceding the signature length.
            // This will be used for temporary memory overrides - either the
            // signature head for isValidSignature or the digest for ecrecover.
            let wordBeforeSignaturePtr := sub(signature, OneWord)

            // Cache the current value behind the signature to restore it later.
            let cachedWordBeforeSignature := mload(wordBeforeSignaturePtr)

            // Declare lenDiff + recoveredSigner scope to manage stack pressure.
            {
                // Take the difference between the max ECDSA signature length
                // and the actual signature length. Overflow desired for any
                // values > 65. If the diff is not 0 or 1, it is not a valid
                // ECDSA signature - move on to EIP1271 check.
                let lenDiff := sub(ECDSA_MaxLength, signatureLength)

                // Declare variable for recovered signer.
                let recoveredSigner

                // If diff is 0 or 1, it may be an ECDSA signature.
                // Try to recover signer.
                if iszero(gt(lenDiff, 1)) {
                    // Read the signature `s` value.
                    let originalSignatureS := mload(
                        add(signature, ECDSA_signature_s_offset)
                    )

                    // Read the first byte of the word after `s`. If the
                    // signature is 65 bytes, this will be the real `v` value.
                    // If not, it will need to be modified - doing it this way
                    // saves an extra condition.
                    let v := byte(
                        0,
                        mload(add(signature, ECDSA_signature_v_offset))
                    )

                    // If lenDiff is 1, parse 64-byte signature as ECDSA.
                    if lenDiff {
                        // Extract yParity from highest bit of vs and add 27 to
                        // get v.
                        v := add(
                            shr(MaxUint8, originalSignatureS),
                            Signature_lower_v
                        )

                        // Extract canonical s from vs, all but the highest bit.
                        // Temporarily overwrite the original `s` value in the
                        // signature.
                        mstore(
                            add(signature, ECDSA_signature_s_offset),
                            and(
                                originalSignatureS,
                                EIP2098_allButHighestBitMask
                            )
                        )
                    }
                    // Temporarily overwrite the signature length with `v` to
                    // conform to the expected input for ecrecover.
                    mstore(signature, v)

                    // Temporarily overwrite the word before the length with
                    // `digest` to conform to the expected input for ecrecover.
                    mstore(wordBeforeSignaturePtr, digest)

                    // Attempt to recover the signer for the given signature. Do
                    // not check the call status as ecrecover will return a null
                    // address if the signature is invalid.
                    pop(
                        staticcall(
                            gas(),
                            Ecrecover_precompile, // Call ecrecover precompile.
                            wordBeforeSignaturePtr, // Use data memory location.
                            Ecrecover_args_size, // Size of digest, v, r, and s.
                            0, // Write result to scratch space.
                            OneWord // Provide size of returned result.
                        )
                    )

                    // Restore cached word before signature.
                    mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)

                    // Restore cached signature length.
                    mstore(signature, signatureLength)

                    // Restore cached signature `s` value.
                    mstore(
                        add(signature, ECDSA_signature_s_offset),
                        originalSignatureS
                    )

                    // Read the recovered signer from the buffer given as return
                    // space for ecrecover.
                    recoveredSigner := mload(0)
                }

                // Set success to true if the signature provided was a valid
                // ECDSA signature and the signer is not the null address. Use
                // gt instead of direct as success is used outside of assembly.
                success := and(eq(signer, recoveredSigner), gt(signer, 0))
            }

            // If the signature was not verified with ecrecover, try EIP1271.
            if iszero(success) {
                // Reset the original signature length.
                mstore(signature, originalSignatureLength)

                // Temporarily overwrite the word before the signature length
                // and use it as the head of the signature input to
                // `isValidSignature`, which has a value of 64.
                mstore(
                    wordBeforeSignaturePtr,
                    EIP1271_isValidSignature_signature_head_offset
                )

                // Get pointer to use for the selector of `isValidSignature`.
                let selectorPtr := sub(
                    signature,
                    EIP1271_isValidSignature_selector_negativeOffset
                )

                // Cache the value currently stored at the selector pointer.
                let cachedWordOverwrittenBySelector := mload(selectorPtr)

                // Cache the value currently stored at the digest pointer.
                let cachedWordOverwrittenByDigest := mload(
                    sub(
                        signature,
                        EIP1271_isValidSignature_digest_negativeOffset
                    )
                )

                // Write the selector first, since it overlaps the digest.
                mstore(selectorPtr, EIP1271_isValidSignature_selector)

                // Next, write the original digest.
                mstore(
                    sub(
                        signature,
                        EIP1271_isValidSignature_digest_negativeOffset
                    ),
                    originalDigest
                )

                // Call signer with `isValidSignature` to validate signature.
                success := staticcall(
                    gas(),
                    signer,
                    selectorPtr,
                    add(
                        originalSignatureLength,
                        EIP1271_isValidSignature_calldata_baseLength
                    ),
                    0,
                    OneWord
                )

                // Determine if the signature is valid on successful calls.
                if success {
                    // If first word of scratch space does not contain EIP-1271
                    // signature selector, revert.
                    if iszero(eq(mload(0), EIP1271_isValidSignature_selector)) {
                        // Revert with bad 1271 signature if signer has code.
                        if extcodesize(signer) {
                            // Bad contract signature.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, BadContractSignature_error_selector)

                            // revert(abi.encodeWithSignature(
                            //     "BadContractSignature()"
                            // ))
                            revert(
                                Error_selector_offset,
                                BadContractSignature_error_length
                            )
                        }

                        // Check if signature length was invalid.
                        if gt(sub(ECDSA_MaxLength, signatureLength), 1) {
                            // Revert with generic invalid signature error.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, InvalidSignature_error_selector)

                            // revert(abi.encodeWithSignature(
                            //     "InvalidSignature()"
                            // ))
                            revert(
                                Error_selector_offset,
                                InvalidSignature_error_length
                            )
                        }

                        // Check if v was invalid.
                        if and(
                            eq(signatureLength, ECDSA_MaxLength),
                            iszero(
                                byte(
                                    byte(
                                        0,
                                        mload(
                                            add(
                                                signature,
                                                ECDSA_signature_v_offset
                                            )
                                        )
                                    ),
                                    ECDSA_twentySeventhAndTwentyEighthBytesSet
                                )
                            )
                        ) {
                            // Revert with invalid v value.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, BadSignatureV_error_selector)
                            mstore(
                                BadSignatureV_error_v_ptr,
                                byte(
                                    0,
                                    mload(
                                        add(signature, ECDSA_signature_v_offset)
                                    )
                                )
                            )

                            // revert(abi.encodeWithSignature(
                            //     "BadSignatureV(uint8)", v
                            // ))
                            revert(
                                Error_selector_offset,
                                BadSignatureV_error_length
                            )
                        }

                        // Revert with generic invalid signer error message.
                        // Store left-padded selector with push4, mem[28:32]
                        mstore(0, InvalidSigner_error_selector)

                        // revert(abi.encodeWithSignature("InvalidSigner()"))
                        revert(
                            Error_selector_offset,
                            InvalidSigner_error_length
                        )
                    }
                }

                // Restore the cached values overwritten by selector, digest and
                // signature head.
                mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)
                mstore(selectorPtr, cachedWordOverwrittenBySelector)
                mstore(
                    sub(
                        signature,
                        EIP1271_isValidSignature_digest_negativeOffset
                    ),
                    cachedWordOverwrittenByDigest
                )
            }
        }

        // If the call failed...
        if (!success) {
            // Revert and pass reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with error indicating bad contract signature.
            assembly {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, BadContractSignature_error_selector)
                // revert(abi.encodeWithSignature("BadContractSignature()"))
                revert(Error_selector_offset, BadContractSignature_error_length)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { OrderStatus } from "./ConsiderationStructs.sol";

import { Assertions } from "./Assertions.sol";

import { SignatureVerification } from "./SignatureVerification.sol";

import {
    _revertInvalidTime,
    _revertOrderAlreadyFilled,
    _revertOrderIsCancelled,
    _revertOrderPartiallyFilled
} from "./ConsiderationErrors.sol";

import {
    BulkOrderProof_keyShift,
    BulkOrderProof_keySize,
    BulkOrderProof_lengthAdjustmentBeforeMask,
    BulkOrderProof_lengthRangeAfterMask,
    BulkOrderProof_minSize,
    BulkOrderProof_rangeSize,
    ECDSA_MaxLength,
    OneWord,
    OneWordShift,
    ThirtyOneBytes,
    TwoWords
} from "./ConsiderationConstants.sol";

/**
 * @title Verifiers
 * @author 0age
 * @notice Verifiers contains functions for performing verifications.
 */
contract Verifiers is Assertions, SignatureVerification {
    /**
     * @dev Derive and set hashes, reference chainId, and associated domain
     *      separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Assertions(conduitController) {}

    /**
     * @dev Internal view function to ensure that the current time falls within
     *      an order's valid timespan.
     *
     * @param startTime       The time at which the order becomes active.
     * @param endTime         The time at which the order becomes inactive.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order is not active.
     *
     * @return valid A boolean indicating whether the order is active.
     */
    function _verifyTime(
        uint256 startTime,
        uint256 endTime,
        bool revertOnInvalid
    ) internal view returns (bool valid) {
        // Mark as valid if order has started and has not already ended.
        assembly {
            valid := and(
                iszero(gt(startTime, timestamp())),
                gt(endTime, timestamp())
            )
        }

        // Only revert on invalid if revertOnInvalid has been supplied as true.
        if (revertOnInvalid && !valid) {
            _revertInvalidTime(startTime, endTime);
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied offerer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param offerer   The offerer for the order.
     * @param orderHash The order hash.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _verifySignature(
        address offerer,
        bytes32 orderHash,
        bytes memory signature
    ) internal view {
        // Determine whether the offerer is the caller.
        bool offererIsCaller;
        assembly {
            offererIsCaller := eq(offerer, caller())
        }

        // Skip signature verification if the offerer is the caller.
        if (offererIsCaller) {
            return;
        }

        // Derive the EIP-712 domain separator.
        bytes32 domainSeparator = _domainSeparator();

        // Derive original EIP-712 digest using domain separator and order hash.
        bytes32 originalDigest = _deriveEIP712Digest(
            domainSeparator,
            orderHash
        );

        // Read the length of the signature from memory and place on the stack.
        uint256 originalSignatureLength = signature.length;

        // Determine effective digest if signature has a valid bulk order size.
        bytes32 digest;
        if (_isValidBulkOrderSize(originalSignatureLength)) {
            // Rederive order hash and digest using bulk order proof.
            (orderHash) = _computeBulkOrderProof(signature, orderHash);
            digest = _deriveEIP712Digest(domainSeparator, orderHash);
        } else {
            // Supply the original digest as the effective digest.
            digest = originalDigest;
        }

        // Ensure that the signature for the digest is valid for the offerer.
        _assertValidSignature(
            offerer,
            digest,
            originalDigest,
            originalSignatureLength,
            signature
        );
    }

    /**
     * @dev Determines whether the specified bulk order size is valid.
     *
     * @param signatureLength The signature length of the bulk order to check.
     *
     * @return validLength True if bulk order size is valid, false otherwise.
     */
    function _isValidBulkOrderSize(
        uint256 signatureLength
    ) internal pure returns (bool validLength) {
        // Utilize assembly to validate the length; the equivalent logic is
        // (64 + x) + 3 + 32y where (0 <= x <= 1) and (1 <= y <= 24).
        assembly {
            validLength := and(
                lt(
                    sub(signatureLength, BulkOrderProof_minSize),
                    BulkOrderProof_rangeSize
                ),
                lt(
                    and(
                        add(
                            signatureLength,
                            BulkOrderProof_lengthAdjustmentBeforeMask
                        ),
                        ThirtyOneBytes
                    ),
                    BulkOrderProof_lengthRangeAfterMask
                )
            )
        }
    }

    /**
     * @dev Computes the bulk order hash for the specified proof and leaf. Note
     *      that if an index that exceeds the number of orders in the bulk order
     *      payload will instead "wrap around" and refer to an earlier index.
     *
     * @param proofAndSignature The proof and signature of the bulk order.
     * @param leaf              The leaf of the bulk order tree.
     *
     * @return bulkOrderHash The bulk order hash.
     */
    function _computeBulkOrderProof(
        bytes memory proofAndSignature,
        bytes32 leaf
    ) internal pure returns (bytes32 bulkOrderHash) {
        // Declare arguments for the root hash and the height of the proof.
        bytes32 root;
        uint256 height;

        // Utilize assembly to efficiently derive the root hash using the proof.
        assembly {
            // Retrieve the length of the proof, key, and signature combined.
            let fullLength := mload(proofAndSignature)

            // If proofAndSignature has odd length, it is a compact signature
            // with 64 bytes.
            let signatureLength := sub(ECDSA_MaxLength, and(fullLength, 1))

            // Derive height (or depth of tree) with signature and proof length.
            height := shr(OneWordShift, sub(fullLength, signatureLength))

            // Update the length in memory to only include the signature.
            mstore(proofAndSignature, signatureLength)

            // Derive the pointer for the key using the signature length.
            let keyPtr := add(proofAndSignature, add(OneWord, signatureLength))

            // Retrieve the three-byte key using the derived pointer.
            let key := shr(BulkOrderProof_keyShift, mload(keyPtr))

            /// Retrieve pointer to first proof element by applying a constant
            // for the key size to the derived key pointer.
            let proof := add(keyPtr, BulkOrderProof_keySize)

            // Compute level 1.
            let scratchPtr1 := shl(OneWordShift, and(key, 1))
            mstore(scratchPtr1, leaf)
            mstore(xor(scratchPtr1, OneWord), mload(proof))

            // Compute remaining proofs.
            for {
                let i := 1
            } lt(i, height) {
                i := add(i, 1)
            } {
                proof := add(proof, OneWord)
                let scratchPtr := shl(OneWordShift, and(shr(i, key), 1))
                mstore(scratchPtr, keccak256(0, TwoWords))
                mstore(xor(scratchPtr, OneWord), mload(proof))
            }

            // Compute root hash.
            root := keccak256(0, TwoWords)
        }

        // Retrieve appropriate typehash constant based on height.
        bytes32 rootTypeHash = _lookupBulkOrderTypehash(height);

        // Use the typehash and the root hash to derive final bulk order hash.
        assembly {
            mstore(0, rootTypeHash)
            mstore(OneWord, root)
            bulkOrderHash := keccak256(0, TwoWords)
        }
    }

    /**
     * @dev Internal view function to validate that a given order is fillable
     *      and not cancelled based on the order status.
     *
     * @param orderHash       The order hash.
     * @param orderStatus     The status of the order, including whether it has
     *                        been cancelled and the fraction filled.
     * @param onlyAllowUnused A boolean flag indicating whether partial fills
     *                        are supported by the calling function.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order has been cancelled or filled beyond the
     *                        allowable amount.
     *
     * @return valid A boolean indicating whether the order is valid.
     */
    function _verifyOrderStatus(
        bytes32 orderHash,
        OrderStatus storage orderStatus,
        bool onlyAllowUnused,
        bool revertOnInvalid
    ) internal view returns (bool valid) {
        // Ensure that the order has not been cancelled.
        if (orderStatus.isCancelled) {
            // Only revert if revertOnInvalid has been supplied as true.
            if (revertOnInvalid) {
                _revertOrderIsCancelled(orderHash);
            }

            // Return false as the order status is invalid.
            return false;
        }

        // Read order status numerator from storage and place on stack.
        uint256 orderStatusNumerator = orderStatus.numerator;

        // If the order is not entirely unused...
        if (orderStatusNumerator != 0) {
            // ensure the order has not been partially filled when not allowed.
            if (onlyAllowUnused) {
                // Always revert on partial fills when onlyAllowUnused is true.
                _revertOrderPartiallyFilled(orderHash);
            }
            // Otherwise, ensure that order has not been entirely filled.
            else if (orderStatusNumerator >= orderStatus.denominator) {
                // Only revert if revertOnInvalid has been supplied as true.
                if (revertOnInvalid) {
                    _revertOrderAlreadyFilled(orderHash);
                }

                // Return false as the order status is invalid.
                return false;
            }
        }

        // Return true as the order status is valid.
        valid = true;
    }
}