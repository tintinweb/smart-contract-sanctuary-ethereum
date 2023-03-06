// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { mload8, memmove, memcmp, memeq, leftMask } from "./utils/mem.sol";
import { memchr, memrchr } from "./utils/memchr.sol";
import { PackPtrLen } from "./utils/PackPtrLen.sol";

import { SliceIter, SliceIter__ } from "./SliceIter.sol";

/**
 * @title A view into a contiguous sequence of 1-byte items.
 */
type Slice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error Slice__OutOfBounds();
error Slice__LengthMismatch();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library Slice__ {
    /**
     * @dev Converts a `bytes` to a `Slice`.
     * The bytes are not copied.
     * `Slice` points to the memory of `bytes`, right after the length word.
     */
    function from(bytes memory b) internal pure returns (Slice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(b, 0x20)
        }
        return fromRawParts(_ptr, b.length);
    }

    /**
     * @dev Creates a new `Slice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (Slice slice) {
        return Slice.wrap(PackPtrLen.pack(_ptr, _len));
    }

    /**
     * @dev Like `fromRawParts`, but does NO validity checks.
     * _ptr and _len MUST fit into uint128.
     * The caller MUST guarantee memory-safety.
     * Primarily for internal use.
     */
    function fromUnchecked(uint256 _ptr, uint256 _len) internal pure returns (Slice slice) {
        return Slice.wrap(
            (_ptr << 128) | (_len & PackPtrLen.MASK_LEN)
        );
    }
}

/**
 * @dev Alternative to Slice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for bytes;
 * ```
 */
function toSlice(bytes memory b) pure returns (Slice slice) {
    return Slice__.from(b);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    ptr, len, isEmpty,
    // conversion
    toBytes, toBytes32,
    keccak,
    // concatenation
    add, join,
    // copy
    copyFromSlice,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    get, first, last,
    splitAt, getSubslice, getBefore, getAfter, getAfterStrict,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    // iteration
    iter
} for Slice global;

/**
 * @dev Returns the pointer to the start of an in-memory slice.
 */
function ptr(Slice self) pure returns (uint256) {
    return Slice.unwrap(self) >> 128;
}

/**
 * @dev Returns the length in bytes.
 */
function len(Slice self) pure returns (uint256) {
    return Slice.unwrap(self) & PackPtrLen.MASK_LEN;
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(Slice self) pure returns (bool) {
    return Slice.unwrap(self) & PackPtrLen.MASK_LEN == 0;
}

/**
 * @dev Copies `Slice` to a new `bytes`.
 * The `Slice` will NOT point to the new `bytes`.
 */
function toBytes(Slice self) view returns (bytes memory b) {
    b = new bytes(self.len());
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memmove(bPtr, self.ptr(), self.len());
    return b;
}

/**
 * @dev Fills a `bytes32` (value type) with the first 32 bytes of `Slice`.
 * Goes from left(MSB) to right(LSB).
 * If len < 32, the leftover bytes are zeros.
 */
function toBytes32(Slice self) pure returns (bytes32 b) {
    uint256 selfPtr = self.ptr();

    // mask removes any trailing bytes
    uint256 selfLen = self.len();
    uint256 mask = leftMask(selfLen);

    /// @solidity memory-safe-assembly
    assembly {
        b := and(mload(selfPtr), mask)
    }
    return b;
}

/**
 * @dev Returns keccak256 of all the bytes of `Slice`.
 * Note that for any `bytes memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(Slice self) pure returns (bytes32 result) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    /// @solidity memory-safe-assembly
    assembly {
        result := keccak256(selfPtr, selfLen)
    }
}

/**
 * @dev Concatenates two `Slice`s into a newly allocated `bytes`.
 */
function add(Slice self, Slice other) view returns (bytes memory b) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();

    b = new bytes(selfLen + otherLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memmove(bPtr, self.ptr(), selfLen);
    memmove(bPtr + selfLen, other.ptr(), otherLen);
    return b;
}

/**
 * @dev Flattens an array of `Slice`s into a single newly allocated `bytes`,
 * placing `self` as the separator between each.
 *
 * TODO this is the wrong place for this method, but there are no other places atm
 * (since there's no proper chaining/reducers/anything)
 */
function join(Slice self, Slice[] memory slices) view returns (bytes memory b) {
    uint256 slicesLen = slices.length;
    if (slicesLen == 0) return "";

    uint256 selfLen = self.len();
    uint256 repetitionLen;
    // -1 is safe because of ==0 check earlier
    unchecked {
        repetitionLen = slicesLen - 1;
    }
    // add separator repetitions length
    uint256 totalLen = selfLen * repetitionLen;
    // add slices length
    for (uint256 i; i < slicesLen; i++) {
        totalLen += slices[i].len();
    }

    b = new bytes(totalLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }
    for (uint256 i; i < slicesLen; i++) {
        Slice slice = slices[i];
        // copy slice
        memmove(bPtr, slice.ptr(), slice.len());
        bPtr += slice.len();
        // copy separator (skips the last cycle)
        if (i < repetitionLen) {
            memmove(bPtr, self.ptr(), selfLen);
            bPtr += selfLen;
        }
    }
}

/**
 * @dev Copies all elements from `src` into `self`.
 * The length of `src` must be the same as `self`.
 */
function copyFromSlice(Slice self, Slice src) view {
    uint256 selfLen = self.len();
    if (selfLen != src.len()) revert Slice__LengthMismatch();

    memmove(self.ptr(), src.ptr(), selfLen);
}

/**
 * @dev Compare slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(Slice self, Slice other) pure returns (int256 result) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();
    uint256 minLen = selfLen;
    if (otherLen < minLen) {
        minLen = otherLen;
    }

    result = memcmp(self.ptr(), other.ptr(), minLen);
    if (result == 0) {
        // the longer slice is greater than its prefix
        // (lengths take only 16 bytes, so signed sub is safe)
        unchecked {
            return int256(selfLen) - int256(otherLen);
        }
    }
    // if not equal, return the diff sign
    return result;
}

/// @dev self == other
/// Note more efficient than cmp
function eq(Slice self, Slice other) pure returns (bool) {
    uint256 selfLen = self.len();
    if (selfLen != other.len()) return false;
    return memeq(self.ptr(), other.ptr(), selfLen);
}

/// @dev self != other
/// Note more efficient than cmp
function ne(Slice self, Slice other) pure returns (bool) {
    uint256 selfLen = self.len();
    if (selfLen != other.len()) return true;
    return !memeq(self.ptr(), other.ptr(), selfLen);
}

/// @dev `self` < `other`
function lt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Returns the byte at `index`.
 * Reverts if index is out of bounds.
 */
function get(Slice self, uint256 index) pure returns (uint8 item) {
    if (index >= self.len()) revert Slice__OutOfBounds();

    // ptr and len are uint128 (because PackPtrLen); index < len
    unchecked {
        return mload8(self.ptr() + index);
    }
}

/**
 * @dev Returns the first byte of the slice.
 * Reverts if the slice is empty.
 */
function first(Slice self) pure returns (uint8 item) {
    if (self.len() == 0) revert Slice__OutOfBounds();
    return mload8(self.ptr());
}

/**
 * @dev Returns the last byte of the slice.
 * Reverts if the slice is empty.
 */
function last(Slice self) pure returns (uint8 item) {
    uint256 selfLen = self.len();
    if (selfLen == 0) revert Slice__OutOfBounds();
    // safe because selfLen > 0 (ptr+len is implicitly safe)
    unchecked {
        return mload8(self.ptr() + (selfLen - 1));
    }
}

/**
 * @dev Divides one slice into two at an index.
 */
function splitAt(Slice self, uint256 mid) pure returns (Slice, Slice) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    if (mid > selfLen) revert Slice__OutOfBounds();
    return (Slice__.fromUnchecked(selfPtr, mid), Slice__.fromUnchecked(selfPtr + mid, selfLen - mid));
}

/**
 * @dev Returns a subslice [start:end] of `self`.
 * Reverts if start/end are out of bounds.
 */
function getSubslice(Slice self, uint256 start, uint256 end) pure returns (Slice) {
    if (!(start <= end && end <= self.len())) revert Slice__OutOfBounds();
    // selfPtr + start is safe because start <= selfLen (pointers are implicitly safe)
    // end - start is safe because start <= end
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + start, end - start);
    }
}

/**
 * @dev Returns a subslice [:index] of `self`.
 * Reverts if `index` > length.
 */
function getBefore(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    return Slice__.fromUnchecked(self.ptr(), index);
}

/**
 * @dev Returns a subslice [index:] of `self`.
 * Reverts if `index` > length.
 */
function getAfter(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    // safe because index <= selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns a non-zero subslice [index:] of `self`.
 * Reverts if `index` >= length.
 */
function getAfterStrict(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index >= selfLen) revert Slice__OutOfBounds();
    // safe because index < selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromUnchecked(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(Slice self, Slice pattern) pure returns (uint256) {
    // offsetLen == selfLen initially, then starts shrinking
    uint256 offsetLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (offsetLen == 0 || patLen > offsetLen) {
        return type(uint256).max;
    }

    uint256 offsetPtr = self.ptr();
    uint256 patPtr = pattern.ptr();
    // low-level alternative to `first()` (safe because patLen != 0)
    uint8 patFirst = mload8(patPtr);

    while (true) {
        uint256 index = memchr(offsetPtr, offsetLen, patFirst);
        // not found
        if (index == type(uint256).max) return type(uint256).max;

        // move pointer to the found byte
        // safe because index < offsetLen (ptr+len is implicitly safe)
        unchecked {
            offsetPtr += index;
            offsetLen -= index;
        }
        // can't find, pattern won't fit after index
        if (patLen > offsetLen) {
            return type(uint256).max;
        }

        if (memeq(offsetPtr, patPtr, patLen)) {
            // found, return offset index
            return (offsetPtr - self.ptr());
        } else if (offsetLen == 1) {
            // not found and this was the last character
            return type(uint256).max;
        } else {
            // not found and can keep going;
            // increment pointer, memchr shouldn't receive what it returned (otherwise infinite loop)
            unchecked {
                // safe because offsetLen > 1 (see offsetLen -= index, and index < offsetLen)
                offsetPtr++;
                offsetLen--;
            }
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(Slice self, Slice pattern) pure returns (uint256) {
    // offsetLen == selfLen initially, then starts shrinking
    uint256 offsetLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (offsetLen == 0 || patLen > offsetLen) {
        return type(uint256).max;
    }

    uint256 selfPtr = self.ptr();
    uint256 patPtr = pattern.ptr();
    uint8 patLast = pattern.last();
    // using indexes instead of lengths saves some gas on redundant increments/decrements
    uint256 patLastIndex;
    // safe because of patLen == 0 check earlier
    unchecked {
        patLastIndex = patLen - 1;
    }

    while (true) {
        uint256 endIndex = memrchr(selfPtr, offsetLen, patLast);
        // not found
        if (endIndex == type(uint256).max) return type(uint256).max;
        // can't find, pattern won't fit after index
        if (patLastIndex > endIndex) return type(uint256).max;

        // (endIndex - patLastIndex is safe because of the check just earlier)
        // (selfPtr + startIndex is safe because startIndex <= endIndex < offsetLen <= selfLen)
        // (ptr+len is implicitly safe)
        unchecked {
            // need startIndex, but memrchr returns endIndex
            uint256 startIndex = endIndex - patLastIndex;

            if (memeq(selfPtr + startIndex, patPtr, patLen)) {
                // found, return index
                return startIndex;
            } else if (endIndex > 0) {
                // not found and can keep going;
                // "decrement pointer", memrchr shouldn't receive what it returned
                // (index is basically a decremented length already, saves an op)
                // (I could even use 1 variable for both, but that'd be too confusing)
                offsetLen = endIndex;
                // an explicit continue is better for optimization here
                continue;
            } else {
                // not found and this was the last character
                return type(uint256).max;
            }
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this `bytes` slice.
 */
function contains(Slice self, Slice pattern) pure returns (bool) {
    return self.find(pattern) != type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a prefix of this slice.
 */
function startsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice prefix = self;
    // make prefix's length equal patLen
    if (selfLen > patLen) {
        prefix = self.getBefore(patLen);
    }
    return prefix.eq(pattern);
}

/**
 * @dev Returns true if the given pattern matches a suffix of this slice.
 */
function endsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice suffix = self;
    // make suffix's length equal patLen
    if (selfLen > patLen) {
        suffix = self.getAfter(selfLen - patLen);
    }
    return suffix.eq(pattern);
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(Slice self, Slice pattern) pure returns (Slice) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen > selfLen) return self;

    (Slice prefix, Slice suffix) = self.splitAt(patLen);

    if (prefix.eq(pattern)) {
        return suffix;
    } else {
        return self;
    }
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(Slice self, Slice pattern) pure returns (Slice) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (patLen > selfLen) return self;

    uint256 index;
    // safe because selfLen >= patLen
    unchecked {
        index = selfLen - patLen;
    }
    (Slice prefix, Slice suffix) = self.splitAt(index);

    if (suffix.eq(pattern)) {
        return prefix;
    } else {
        return self;
    }
}

/**
 * @dev Returns an iterator over the slice.
 * The iterator yields items from either side.
 */
function iter(Slice self) pure returns (SliceIter memory) {
    return SliceIter__.from(self);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { mload8 } from "./utils/mem.sol";
import { Slice, Slice__ } from "./Slice.sol";

/**
 * @title Slice iterator.
 * @dev This struct is created by the iter method on `Slice`.
 * Iterates only 1 byte (uint8) at a time.
 */
struct SliceIter {
    uint256 _ptr;
    uint256 _len;
}

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error SliceIter__StopIteration();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library SliceIter__ {
    /**
     * @dev Creates a new `SliceIter` from `Slice`.
     * Note the `Slice` is assumed to be memory-safe.
     */
    function from(Slice slice) internal pure returns (SliceIter memory) {
        return SliceIter(slice.ptr(), slice.len());
    }
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { asSlice, ptr, len, isEmpty, next, nextBack } for SliceIter global;

/**
 * @dev Views the underlying data as a subslice of the original data.
 */
function asSlice(SliceIter memory self) pure returns (Slice slice) {
    return Slice__.fromUnchecked(self._ptr, self._len);
}

/**
 * @dev Returns the pointer to the start of an in-memory slice.
 */
function ptr(SliceIter memory self) pure returns (uint256) {
    return self._ptr;
}

/**
 * @dev Returns the length in bytes.
 */
function len(SliceIter memory self) pure returns (uint256) {
    return self._len;
}

/**
 * @dev Returns true if the iterator is empty.
 */
function isEmpty(SliceIter memory self) pure returns (bool) {
    return self._len == 0;
}

/**
 * @dev Advances the iterator and returns the next value.
 * Reverts if len == 0.
 */
function next(SliceIter memory self) pure returns (uint8 value) {
    uint256 selfPtr = self._ptr;
    uint256 selfLen = self._len;
    if (selfLen == 0) revert SliceIter__StopIteration();

    // safe because selfLen != 0 (ptr+len is implicitly safe and 1<=len)
    unchecked {
        // advance the iterator
        self._ptr = selfPtr + 1;
        self._len = selfLen - 1;
    }

    return mload8(selfPtr);
}

/**
 * @dev Advances the iterator from the back and returns the next value.
 * Reverts if len == 0.
 */
function nextBack(SliceIter memory self) pure returns (uint8 value) {
    uint256 selfPtr = self._ptr;
    uint256 selfLen = self._len;
    if (selfLen == 0) revert SliceIter__StopIteration();

    // safe because selfLen != 0 (ptr+len is implicitly safe)
    unchecked {
        // advance the iterator
        self._len = selfLen - 1;

        return mload8(selfPtr + (selfLen - 1));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { isValidUtf8 as _isValidUtf8, utf8CharWidth } from "./utils/utf8.sol";
import { decodeUtf8, encodeUtf8 } from "./utils/unicode.sol";
import { leftMask } from "./utils/mem.sol";

/**
 * @title A single UTF-8 encoded character.
 * @dev Internally it is stored as UTF-8 encoded bytes starting from left/MSB.
 */
type StrChar is bytes32;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrChar__InvalidUTF8();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrChar__ {
    /**
     * @dev Converts the first 1-4 bytes of `bytes32` to a `StrChar`.
     * Starts from left/MSB, reverts if not valid UTF-8.
     * @param b UTF-8 encoded character in the most significant bytes.
     */
    function from(bytes32 b) internal pure returns (StrChar char) {
        uint256 charLen = _isValidUtf8(b);
        if (charLen == 0) revert StrChar__InvalidUTF8();
        return fromUnchecked(b, charLen);
    }

    /**
    * @dev Converts a unicode code point to a `StrChar`.
    * E.g. for '€' code point = 0x20AC; wheareas UTF-8 = 0xE282AC.
    */
    function fromCodePoint(uint256 code) internal pure returns (StrChar char) {
        return StrChar.wrap(encodeUtf8(code));
    }

    /**
     * @dev Like `from`, but does NO validity checks.
     * Uses provided `_len` instead of calculating it. This allows invalid/malformed characters.
     *
     * MSB of `bytes32` SHOULD be valid UTF-8.
     * And `bytes32` SHOULD be zero-padded after the first UTF-8 character.
     * Primarily for internal use.
     */
    function fromUnchecked(bytes32 b, uint256 _len) internal pure returns (StrChar char) {
        return StrChar.wrap(bytes32(
            // zero-pad after the character
            uint256(b) & leftMask(_len)
        ));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { 
    len,
    toBytes32, toString, toCodePoint,
    cmp, eq, ne, lt, lte, gt, gte,
    isValidUtf8
} for StrChar global;

/**
 * @dev Returns the character's length in bytes (1-4).
 * Returns 0 for some (not all!) invalid characters (e.g. due to unsafe use of fromUnchecked).
 */
function len(StrChar self) pure returns (uint256) {
    return utf8CharWidth(
        // extract the leading byte
        uint256(uint8(StrChar.unwrap(self)[0]))
    );
}

/**
 * @dev Converts a `StrChar` to its underlying bytes32 value.
 */
function toBytes32(StrChar self) pure returns (bytes32) {
    return StrChar.unwrap(self);
}

/**
 * @dev Converts a `StrChar` to a newly allocated `string`.
 */
function toString(StrChar self) pure returns (string memory str) {
    uint256 _len = self.len();
    str = new string(_len);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(add(str, 0x20), self)
    }
    return str;
}

/**
 * @dev Converts a `StrChar` to its unicode code point (aka unicode scalar value).
 */
function toCodePoint(StrChar self) pure returns (uint256) {
    return decodeUtf8(StrChar.unwrap(self));
}

/**
 * @dev Compare characters lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrChar self, StrChar other) pure returns (int256 result) {
    uint256 selfUint = uint256(StrChar.unwrap(self));
    uint256 otherUint = uint256(StrChar.unwrap(other));
    if (selfUint > otherUint) {
        return 1;
    } else if (selfUint < otherUint) {
        return -1;
    } else {
        return 0;
    }
}

/// @dev `self` == `other`
function eq(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) == uint256(StrChar.unwrap(other));
}

/// @dev `self` != `other`
function ne(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) != uint256(StrChar.unwrap(other));
}

/// @dev `self` < `other`
function lt(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) < uint256(StrChar.unwrap(other));
}

/// @dev `self` <= `other`
function lte(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) <= uint256(StrChar.unwrap(other));
}

/// @dev `self` > `other`
function gt(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) > uint256(StrChar.unwrap(other));
}

/// @dev `self` >= `other`
function gte(StrChar self, StrChar other) pure returns (bool) {
    return uint256(StrChar.unwrap(self)) >= uint256(StrChar.unwrap(other));
}

/**
 * @dev Returns true if `StrChar` is valid UTF-8.
 * Can be false if it was formed with an unsafe method (fromUnchecked, wrap).
 */
function isValidUtf8(StrChar self) pure returns (bool) {
    return _isValidUtf8(StrChar.unwrap(self)) != 0;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice, Slice__ } from "./Slice.sol";
import { StrSlice } from "./StrSlice.sol";
import { SliceIter, SliceIter__, SliceIter__StopIteration } from "./SliceIter.sol";
import { StrChar, StrChar__, StrChar__InvalidUTF8 } from "./StrChar.sol";
import { isValidUtf8, utf8CharWidth } from "./utils/utf8.sol";
import { leftMask } from "./utils/mem.sol";

/**
 * @title String chars iterator.
 * @dev This struct is created by the iter method on `StrSlice`.
 * Iterates 1 UTF-8 encoded character at a time (which may have 1-4 bytes).
 *
 * Note StrCharsIter iterates over UTF-8 encoded codepoints, not unicode scalar values.
 * This is mostly done for simplicity, since solidity doesn't care about unicode anyways.
 *
 * TODO think about actually adding char and unicode awareness?
 * https://github.com/devstein/unicode-eth attempts something like that
 */
struct StrCharsIter {
    uint256 _ptr;
    uint256 _len;
}

/*//////////////////////////////////////////////////////////////////////////
                                STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrCharsIter__ {
    /**
     * @dev Creates a new `StrCharsIter` from `StrSlice`.
     * Note the `StrSlice` is assumed to be memory-safe.
     */
    function from(StrSlice slice) internal pure returns (StrCharsIter memory) {
        return StrCharsIter(slice.ptr(), slice.len());

        // TODO I'm curious about gas differences
        // return StrCharsIter(SliceIter__.from(str.asSlice()));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asStr,
    ptr, len, isEmpty,
    next, nextBack, unsafeNext,
    count, validateUtf8, unsafeCount
} for StrCharsIter global;

/**
 * @dev Views the underlying data as a subslice of the original data.
 */
function asStr(StrCharsIter memory self) pure returns (StrSlice slice) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice()
    ));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrCharsIter memory self) pure returns (uint256) {
    return self._ptr;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrCharsIter memory self) pure returns (uint256) {
    return self._len;
}

/**
 * @dev Returns true if the iterator is empty.
 */
function isEmpty(StrCharsIter memory self) pure returns (bool) {
    return self._len == 0;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Reverts if len == 0.
 * Reverts on invalid UTF-8.
 */
function next(StrCharsIter memory self) pure returns (StrChar) {
    if (self._len == 0) revert SliceIter__StopIteration();
    (bytes32 b, uint256 charLen) = self._nextRaw(true);
    // safe because _nextRaw guarantees charLen <= selfLen as long as selfLen != 0.
    unchecked {
        // charLen > 0 because of `revertOnInvalid` flag
        self._len -= charLen;
    }
    // safe because _nextRaw reverts on invalid UTF-8
    return StrChar__.fromUnchecked(b, charLen);
}

/**
 * @dev Advances the iterator from the back and returns the next character.
 * Reverts if len == 0.
 * Reverts on invalid UTF-8.
 */
function nextBack(StrCharsIter memory self) pure returns (StrChar char) {
    if (self._len == 0) revert SliceIter__StopIteration();

    // _self shares memory with self!
    SliceIter memory _self = self._sliceIter();

    bool isValid;
    uint256 b;
    for (uint256 i; i < 4; i++) {
        // an example of what's going on in the loop:
        // b = 0x0000000000..00
        // nextBack = 0x80
        // b = 0x8000000000..00 (not valid UTF-8)
        // nextBack = 0x92
        // b = 0x9280000000..00 (not valid UTF-8)
        // nextBack = 0x9F
        // b = 0x9F92800000..00 (not valid UTF-8)
        // nextBack = 0xF0
        // b = 0xF09F928000..00 (valid UTF-8, break)

        // safe because i < 4
        unchecked {
            // free the space in MSB
            b = (b >> 8) | (
                // get 1 byte in LSB
                uint256(_self.nextBack())
                // flip it to MSB
                << (31 * 8)
            );
        }
        // break if the char is valid
        if (isValidUtf8(bytes32(b)) != 0) {
            isValid = true;
            break;
        }
    }
    if (!isValid) revert StrChar__InvalidUTF8();

    // construct the character;
    // wrap is safe, because UTF-8 was validated,
    // and the trailing bytes are 0 (since the loop went byte-by-byte)
    char = StrChar.wrap(bytes32(b));
    // the iterator was already advanced by `_self.nextBack()`
    return char;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Does NOT validate iterator length. It could underflow!
 * Does NOT revert on invalid UTF-8.
 * WARNING: for invalid UTF-8 bytes, advances by 1 and returns an invalid `StrChar` with len 0!
 */
function unsafeNext(StrCharsIter memory self) pure returns (StrChar char) {
    // _nextRaw guarantees charLen <= selfLen IF selfLen != 0
    (bytes32 b, uint256 charLen) = self._nextRaw(false);
    if (charLen > 0) {
        // safe IF the caller ensures that self._len != 0
        unchecked {
            self._len -= charLen;
        }
        // ALWAYS produces a valid character
        return StrChar__.fromUnchecked(b, charLen);
    } else {
        // safe IF the caller ensures that self._len != 0
        unchecked {
            self._len -= 1;
        }
        // NEVER produces a valid character (this is always a single 0x80-0xFF byte)
        return StrChar__.fromUnchecked(b, 1);
    }
}

/**
 * @dev Consumes the iterator, counting the number of UTF-8 characters.
 * Note O(n) time!
 * Reverts on invalid UTF-8.
 */
function count(StrCharsIter memory self) pure returns (uint256 result) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        self._nextRaw(true);
        // +1 is safe because 2**256 cycles are impossible
        unchecked {
            result += 1;
        }
    }
    // _nextRaw does NOT modify len to allow optimizations like setting it once at the end
    self._len = 0;
    return result;
}

/**
 * @dev Consumes the iterator, validating UTF-8 characters.
 * Note O(n) time!
 * Returns true if all are valid; otherwise false on the first invalid UTF-8 character.
 */
function validateUtf8(StrCharsIter memory self) pure returns (bool) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        (, uint256 charLen) = self._nextRaw(false);
        if (charLen == 0) return false;
    }
    return true;
}

/**
 * @dev VERY UNSAFE - a single invalid UTF-8 character can severely alter the result!
 * Consumes the iterator, counting the number of UTF-8 characters.
 * Significantly faster than safe `count`, especially for long mutlibyte strings.
 *
 * Note `count` is actually a bit more efficient than `validateUtf8`.
 * `count` is much more efficient than calling `validateUtf8` and `unsafeCount` together.
 * Use `unsafeCount` only when you are already certain that UTF-8 is valid.
 * If you want speed and no validation, just use byte length, it's faster and more predictably wrong.
 *
 * Some gas usage metrics:
 * 1 ascii char:
 *   count:       571 gas
 *   unsafeCount: 423 gas
 * 100 ascii chars:
 *   count:       27406 gas
 *   unsafeCount: 12900 gas
 * 1000 chinese chars (3000 bytes):
 *   count:       799305 gas
 *   unsafeCount: 178301 gas
 */
function unsafeCount(StrCharsIter memory self) pure returns (uint256 result) {
    uint256 endPtr;
    // (ptr+len is implicitly safe)
    unchecked {
        endPtr = self._ptr + self._len;
    }
    while (self._ptr < endPtr) {
        // unchecked mload
        // (unsafe, the last character could move the pointer past the boundary, but only once)
        /// @solidity memory-safe-assembly
        uint256 leadingByte;
        assembly {
            leadingByte := byte(0, mload(
                // load self._ptr (this is an optimization trick, since it's 1st in the struct)
                mload(self)
            ))
        }
        unchecked {
            // this is a very unsafe version of `utf8CharWidth`,
            // basically 1 invalid UTF-8 character can severely change the count result
            // (no real infinite loop risks, only one potential corrupt memory read)
            if (leadingByte < 0x80) {
                self._ptr += 1;
            } else if (leadingByte < 0xE0) {
                self._ptr += 2;
            } else if (leadingByte < 0xF0) {
                self._ptr += 3;
            } else {
                self._ptr += 4;
            }
            // +1 is safe because 2**256 cycles are impossible
            result += 1;
        }
    }
    self._len = 0;

    return result;
}

/*//////////////////////////////////////////////////////////////////////////
                            FILE-LEVEL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { asSlice, _nextRaw, _sliceIter } for StrCharsIter;

/**
 * @dev Views the underlying data as a `bytes` subslice of the original data.
 */
function asSlice(StrCharsIter memory self) pure returns (Slice slice) {
    return Slice__.fromUnchecked(self._ptr, self._len);
}

/**
 * @dev Used internally to efficiently reuse iteration logic. Has a lot of caveats.
 * NEITHER checks NOR modifies iterator length.
 * (Caller MUST guarantee that len != 0. Caller MUST modify len correctly themselves.)
 * Does NOT form the character properly, and returns raw unmasked bytes and length.
 * Does advance the iterator pointer.
 *
 * Validates UTF-8.
 * For valid chars advances the pointer by charLen.
 * For invalid chars behaviour depends on `revertOnInvalid`:
 * revertOnInvalid == true: revert.
 * revertOnInvalid == false: advance the pointer by 1, but return charLen 0.
 *
 * @return b raw unmasked bytes; if not discarded, then charLen SHOULD be used to mask it.
 * @return charLen length of a valid UTF-8 char; 0 for invalid chars.
 * Guarantees that charLen <= self._len (as long as self._len != 0, which is the caller's guarantee)
 */
function _nextRaw(StrCharsIter memory self, bool revertOnInvalid)
    pure
    returns (bytes32 b, uint256 charLen)
{
    // unchecked mload
    // (isValidUtf8 only checks the 1st character, which exists since caller guarantees len != 0)
    /// @solidity memory-safe-assembly
    assembly {
        b := mload(
            // load self._ptr (this is an optimization trick, since it's 1st in the struct)
            mload(self)
        )
    }
    // validate character (0 => invalid; 1-4 => valid)
    charLen = isValidUtf8(b);

    if (charLen > self._len) {
        // mload didn't check bounds,
        // so a character that goes out of bounds could've been seen as valid.
        if (revertOnInvalid) revert StrChar__InvalidUTF8();
        // safe because caller guarantees _len != 0
        unchecked {
            self._ptr += 1;
        }
        // invalid
        return (b, 0);
    } else if (charLen == 0) {
        if (revertOnInvalid) revert StrChar__InvalidUTF8();
        // safe because caller guarantees _len != 0
        unchecked {
            self._ptr += 1;
        }
        // invalid
        return (b, 0);
    } else {
        // safe because of the `charLen > self._len` check earlier
        unchecked {
            self._ptr += charLen;
        }
        // valid
        return (b, charLen);
    }
}

/**
 * @dev Returns the underlying `SliceIter`.
 * AVOID USING THIS EXTERNALLY!
 * Advancing the underlying slice could lead to invalid UTF-8 for StrCharsIter.
 */
function _sliceIter(StrCharsIter memory self) pure returns (SliceIter memory result) {
    assembly {
        result := self
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice, Slice__, Slice__OutOfBounds } from "./Slice.sol";
import { StrChar, StrChar__ } from "./StrChar.sol";
import { StrCharsIter, StrCharsIter__ } from "./StrCharsIter.sol";
import { isValidUtf8 } from "./utils/utf8.sol";
import { PackPtrLen } from "./utils/PackPtrLen.sol";

/**
 * @title A string slice.
 * @dev String slices must always be valid UTF-8.
 * Internally `StrSlice` uses `Slice`, adding only UTF-8 related logic on top.
 */
type StrSlice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrSlice__InvalidCharBoundary();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrSlice__ {
    /**
     * @dev Converts a `string` to a `StrSlice`.
     * The string is not copied.
     * `StrSlice` points to the memory of `string`, right after the length word.
     */
    function from(string memory str) internal pure returns (StrSlice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(str, 0x20)
        }
        return fromRawParts(_ptr, bytes(str).length);
    }

    /**
     * @dev Creates a new `StrSlice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (StrSlice slice) {
        return StrSlice.wrap(Slice.unwrap(
            Slice__.fromRawParts(_ptr, _len)
        ));
    }

    /**
     * @dev Returns true if the byte slice starts with a valid UTF-8 character.
     * Note this does not validate the whole slice.
     */
    function isBoundaryStart(Slice slice) internal pure returns (bool) {
        bytes32 b = slice.toBytes32();
        return isValidUtf8(b) != 0;
    }
}

/**
 * @dev Alternative to StrSlice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for string;
 * ```
 */
function toSlice(string memory str) pure returns (StrSlice slice) {
    return StrSlice__.from(str);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asSlice,
    ptr, len, isEmpty,
    // conversion
    toString,
    keccak,
    // concatenation
    add, join,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    isCharBoundary,
    get,
    splitAt, getSubslice,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    splitOnce, rsplitOnce,
    replacen,
    // iteration
    chars
} for StrSlice global;

/**
 * @dev Returns the underlying `Slice`.
 * WARNING: manipulating `Slice`s can break UTF-8 for related `StrSlice`s!
 */
function asSlice(StrSlice self) pure returns (Slice) {
    return Slice.wrap(StrSlice.unwrap(self));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) >> 128;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrSlice self) pure returns (uint256) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN;
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(StrSlice self) pure returns (bool) {
    return StrSlice.unwrap(self) & PackPtrLen.MASK_LEN == 0;
}

/**
 * @dev Copies `StrSlice` to a newly allocated string.
 * The `StrSlice` will NOT point to the new string.
 */
function toString(StrSlice self) view returns (string memory) {
    return string(self.asSlice().toBytes());
}

/**
 * @dev Returns keccak256 of all the bytes of `StrSlice`.
 * Note that for any `string memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(StrSlice self) pure returns (bytes32 result) {
    return self.asSlice().keccak();
}

/**
 * @dev Concatenates two `StrSlice`s into a newly allocated string.
 */
function add(StrSlice self, StrSlice other) view returns (string memory) {
    return string(self.asSlice().add(other.asSlice()));
}

/**
 * @dev Flattens an array of `StrSlice`s into a single newly allocated string,
 * placing `self` as the separator between each.
 */
function join(StrSlice self, StrSlice[] memory strs) view returns (string memory) {
    Slice[] memory slices;
    assembly {
        slices := strs
    }
    return string(self.asSlice().join(slices));
}

/**
 * @dev Compare string slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrSlice self, StrSlice other) pure returns (int256 result) {
    return self.asSlice().cmp(other.asSlice());
}

/// @dev `self` == `other`
/// Note more efficient than cmp
function eq(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().eq(other.asSlice());
}

/// @dev `self` != `other`
/// Note more efficient than cmp
function ne(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().ne(other.asSlice());
}

/// @dev `self` < `other`
function lt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Checks that `index`-th byte is safe to split on.
 * The start and end of the string (when index == self.len()) are considered to be boundaries.
 * Returns false if index is greater than self.len().
 */
function isCharBoundary(StrSlice self, uint256 index) pure returns (bool) {
    if (index < self.len()) {
        return isValidUtf8(self.asSlice().getAfter(index).toBytes32()) != 0;
    } else if (index == self.len()) {
        return true;
    } else {
        return false;
    }
}

/**
 * @dev Returns the character at `index` (in bytes).
 * Reverts if index is out of bounds.
 */
function get(StrSlice self, uint256 index) pure returns (StrChar char) {
    bytes32 b = self.asSlice().getAfterStrict(index).toBytes32();
    uint256 charLen = isValidUtf8(b);
    if (charLen == 0) revert StrSlice__InvalidCharBoundary();
    return StrChar__.fromUnchecked(b, charLen);
}

/**
 * @dev Divides one string slice into two at an index.
 * Reverts when splitting on a non-boundary (use isCharBoundary).
 */
function splitAt(StrSlice self, uint256 mid) pure returns (StrSlice, StrSlice) {
    (Slice lSlice, Slice rSlice) = self.asSlice().splitAt(mid);
    if (!StrSlice__.isBoundaryStart(lSlice) || !StrSlice__.isBoundaryStart(rSlice)) {
        revert StrSlice__InvalidCharBoundary();
    }
    return (
        StrSlice.wrap(Slice.unwrap(lSlice)),
        StrSlice.wrap(Slice.unwrap(rSlice))
    );
}

/**
 * @dev Returns a subslice [start..end) of `self`.
 * Reverts when slicing a non-boundary (use isCharBoundary).
 */
function getSubslice(StrSlice self, uint256 start, uint256 end) pure returns (StrSlice) {
    Slice subslice = self.asSlice().getSubslice(start, end);
    if (!StrSlice__.isBoundaryStart(subslice)) revert StrSlice__InvalidCharBoundary();
    if (end != self.len()) {
        (, Slice nextSubslice) = self.asSlice().splitAt(end);
        if (!StrSlice__.isBoundaryStart(nextSubslice)) revert StrSlice__InvalidCharBoundary();
    }
    return StrSlice.wrap(Slice.unwrap(subslice));
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().find(pattern.asSlice());
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().rfind(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this string slice.
 */
function contains(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().contains(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a prefix of this string slice.
 */
function startsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().startsWith(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a suffix of this string slice.
 */
function endsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().endsWith(pattern.asSlice());
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripPrefix(pattern.asSlice())
    ));
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripSuffix(pattern.asSlice())
    ));
}

/**
 * @dev Splits a slice into 2 on the first match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be the entire string and `suffix` will be empty.
 */
function splitOnce(StrSlice self, StrSlice pattern)
    pure
    returns (bool found, StrSlice prefix, StrSlice suffix)
{
    uint256 index = self.asSlice().find(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, self, StrSlice.wrap(0));
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * @dev Splits a slice into 2 on the last match of `pattern`.
 * If found == true, `prefix` and `suffix` will be strictly before and after the match.
 * If found == false, `prefix` will be empty and `suffix` will be the entire string.
 */
function rsplitOnce(StrSlice self, StrSlice pattern)
    pure
    returns (bool found, StrSlice prefix, StrSlice suffix)
{
    uint256 index = self.asSlice().rfind(pattern.asSlice());
    if (index == type(uint256).max) {
        // not found
        return (false, StrSlice.wrap(0), self);
    } else {
        // found
        return self._splitFound(index, pattern.len());
    }
}

/**
 * *EXPERIMENTAL*
 * @dev Replaces first `n` matches of a pattern with another string slice.
 * Returns the result in a newly allocated string.
 * Note this does not modify the string `self` is a slice of.
 * WARNING: Requires 0 < pattern.len() <= to.len()
 */
function replacen(
    StrSlice self,
    StrSlice pattern,
    StrSlice to,
    uint256 n
) view returns (string memory str) {
    uint256 patLen = pattern.len();
    uint256 toLen = to.len();
    // TODO dynamic string; atm length can be reduced but not increased
    assert(patLen >= toLen);
    assert(patLen > 0);

    str = new string(self.len());
    Slice iterSlice = self.asSlice();
    Slice resultSlice = Slice__.from(bytes(str));

    uint256 matchNum;
    while (matchNum < n) {
        uint256 index = iterSlice.find(pattern.asSlice());
        // break if no more matches
        if (index == type(uint256).max) break;
        // copy prefix
        if (index > 0) {
            resultSlice
                .getBefore(index)
                .copyFromSlice(
                    iterSlice.getBefore(index)
                );
        }

        uint256 indexToEnd;
        // TODO this is fine atm only because patLen <= toLen
        unchecked {
            indexToEnd = index + toLen;
        }

        // copy replacement
        resultSlice
            .getSubslice(index, indexToEnd)
            .copyFromSlice(to.asSlice());

        // advance slices past the match
        iterSlice = iterSlice.getAfter(index + patLen);
        resultSlice = resultSlice.getAfter(indexToEnd);

        // break if iterSlice is done
        if (iterSlice.len() == 0) {
            break;
        }
        // safe because of `while` condition
        unchecked {
            matchNum++;
        }
    }

    uint256 realLen = resultSlice.ptr() - StrSlice__.from(str).ptr();
    // copy suffix
    uint256 iterLen = iterSlice.len();
    if (iterLen > 0) {
        resultSlice
            .getBefore(iterLen)
            .copyFromSlice(iterSlice);
        realLen += iterLen;
    }
    // remove extra length
    if (bytes(str).length != realLen) {
        // TODO atm only accepting patLen <= toLen
        assert(realLen <= bytes(str).length);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, realLen)
        }
    }
    return str;
}

/**
 * @dev Returns an character iterator over the slice.
 * The iterator yields items from either side.
 */
function chars(StrSlice self) pure returns (StrCharsIter memory) {
    return StrCharsIter(self.ptr(), self.len());
}

/*//////////////////////////////////////////////////////////////////////////
                              FILE FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { _splitFound } for StrSlice;

/**
 * @dev Splits a slice into [:index] and [index+patLen:].
 * CALLER GUARANTEE: `index` < self.len()
 * For internal use by split/rsplit.
 *
 * This is mostly just a faster alternative to `getBefore`+`getAfter`.
 */
function _splitFound(StrSlice self, uint256 index, uint256 patLen)
    pure
    returns (bool, StrSlice prefix, StrSlice suffix)
{
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    uint256 indexAfterPat;
    // safe because caller guarantees index to be < selfLen
    unchecked {
        indexAfterPat = index + patLen;
        if (indexAfterPat > selfLen) revert Slice__OutOfBounds();
    }
    // [:index] (inlined `getBefore`)
    prefix = StrSlice.wrap(Slice.unwrap(
        Slice__.fromUnchecked(selfPtr, index)
    ));
    // [(index+patLen):] (inlined `getAfter`)
    // safe because indexAfterPat <= selfLen
    unchecked {
        suffix = StrSlice.wrap(Slice.unwrap(
            Slice__.fromUnchecked(selfPtr + indexAfterPat, selfLen - indexAfterPat)
        ));
    }
    return (true, prefix, suffix);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error PackedPtrLen__PtrOverflow();
error PackedPtrLen__LenOverflow();

/**
 * @title Pack ptr and len uint128 values into 1 uint256.
 * @dev ptr is left/MSB. len is right/LSB.
 */
library PackPtrLen {
    uint256 constant MAX = type(uint128).max;

    uint256 constant MASK_PTR = uint256(type(uint128).max) << 128;
    uint256 constant MASK_LEN = uint256(type(uint128).max);

    function pack(uint256 ptr, uint256 len) internal pure returns (uint256 packed) {
        if (ptr > MAX) revert PackedPtrLen__PtrOverflow();
        if (len > MAX) revert PackedPtrLen__LenOverflow();
        return (ptr << 128) | (len & MASK_LEN);
    }

    function getPtr(uint256 packed) internal pure returns (uint256) {
        return packed >> 128;
    }

    function getLen(uint256 packed) internal pure returns (uint256) {
        return packed & MASK_LEN;
    }

    function setPtr(uint256 packed, uint256 ptr) internal pure returns (uint256) {
        return (packed & MASK_PTR) | (ptr << 128);
    }

    function setLen(uint256 packed, uint256 len) internal pure returns (uint256) {
        return (packed & MASK_LEN) | (len);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 */

/**
 * @dev Load 1 byte from the pointer.
 * The result is in the least significant byte, hence uint8.
 */
function mload8(uint256 ptr) pure returns (uint8 item) {
    /// @solidity memory-safe-assembly
    assembly {
        item := byte(0, mload(ptr))
    }
    return item;
}

/**
 * @dev Copy `n` memory bytes.
 * WARNING: Does not handle pointer overlap!
 */
function memcpy(uint256 ptrDest, uint256 ptrSrc, uint256 length) pure {
    // copy 32-byte chunks
    while (length >= 32) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(ptrDest, mload(ptrSrc))
        }
        // safe because total addition will be <= length (ptr+len is implicitly safe)
        unchecked {
            ptrDest += 32;
            ptrSrc += 32;
            length -= 32;
        }
    }
    // copy the 0-31 length tail
    // (the rest is an inlined `mstoreN`)
    uint256 mask = leftMask(length);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(ptrDest,
            or(
                // store the left part
                and(mload(ptrSrc), mask),
                // preserve the right part
                and(mload(ptrDest), not(mask))
            )
        )
    }
}

/**
 * @dev mstore `n` bytes (left-aligned) of `data`
 */
function mstoreN(uint256 ptrDest, bytes32 data, uint256 n) pure {
    uint256 mask = leftMask(n);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(ptrDest,
            or(
                // store the left part
                and(data, mask),
                // preserve the right part
                and(mload(ptrDest), not(mask))
            )
        )
    }
}

/**
 * @dev Copy `n` memory bytes using identity precompile.
 */
function memmove(uint256 ptrDest, uint256 ptrSrc, uint256 n) view {
    /// @solidity memory-safe-assembly
    assembly {
        pop(
            staticcall(
                gas(),   // gas (unused is returned)
                0x04,    // identity precompile address
                ptrSrc,  // argsOffset
                n,       // argsSize: byte size to copy
                ptrDest, // retOffset
                n        // retSize: byte size to copy
            )
        )
    }
}

/**
 * @dev Compare `n` memory bytes lexicographically.
 * Returns 0 for equal, < 0 for less than and > 0 for greater than.
 *
 * https://doc.rust-lang.org/std/cmp/trait.Ord.html#lexicographical-comparison
 */
function memcmp(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (int256) {
    // binary search for the first inequality
    while (n >= 32) {
        // safe because total addition will be <= n (ptr+len is implicitly safe)
        unchecked {
            uint256 nHalf = n / 2;
            if (memeq(ptrSelf, ptrOther, nHalf)) {
                ptrSelf += nHalf;
                ptrOther += nHalf;
                // (can't do n /= 2 instead of nHalf, some bytes would be skipped)
                n -= nHalf;
                // an explicit continue is better for optimization here
                continue;
            } else {
                n -= nHalf;
            }
        }
    }

    uint256 mask = leftMask(n);
    int256 diff;
    /// @solidity memory-safe-assembly
    assembly {
        // for <32 bytes subtraction can be used for comparison,
        // just need to shift away from MSB
        diff := sub(
            shr(8, and(mload(ptrSelf), mask)),
            shr(8, and(mload(ptrOther), mask))
        )
    }
    return diff;
}

/**
 * @dev Returns true if `n` memory bytes are equal.
 *
 * It's faster (up to 4x) than memcmp, especially on medium byte lengths like 32-320.
 * The benefit gets smaller for larger lengths, for 10000 it's only 30% faster.
 */
function memeq(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (bool result) {
    /// @solidity memory-safe-assembly
    assembly {
        result := eq(keccak256(ptrSelf, n), keccak256(ptrOther, n))
    }
}

/**
 * @dev Left-aligned byte mask (e.g. for partial mload/mstore).
 * For length >= 32 returns type(uint256).max
 *
 * length 0:   0x000000...000000
 * length 1:   0xff0000...000000
 * length 2:   0xffff00...000000
 * ...
 * length 30:  0xffffff...ff0000
 * length 31:  0xffffff...ffff00
 * length 32+: 0xffffff...ffffff
 */
function leftMask(uint256 length) pure returns (uint256) {
    unchecked {
        return ~(
            type(uint256).max >> (length * 8)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 *
 * Loosely based on https://doc.rust-lang.org/1.65.0/core/slice/memchr/
 */

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256 index) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memchrWord(ptrText, lenText, x);
    }

    uint256 ptrStart = ptrText;
    uint256 lenTail;
    uint256 ptrEnd;
    // safe because lenTail <= lenText (ptr+len is implicitly safe)
    unchecked {
        // (unchecked % saves a little gas)
        lenTail = lenText % 32;
        ptrEnd = ptrText + (lenText - lenTail);
    }
    uint256 repeatedX = repeatByte(x);
    while (ptrText < ptrEnd) {
        // any bytes equal to `x` become zeros
        // (this helps find `x` faster, values of non-zero bytes don't matter)
        uint256 chunkXZero;
        /// @solidity memory-safe-assembly
        assembly {
            chunkXZero := xor(mload(ptrText), repeatedX)
        }
        // break if there is a matching byte
        if (nonZeroIfXcontainsZeroByte(chunkXZero) != 0) {
            // - is safe because ptrText >= ptrStart (ptrText = ptrStart + 32*n)
            // + is safe because index + offsetLen < lenText
            // (ptr+len is implicitly safe)
            unchecked {
                return
                    // index
                    memchrWord(ptrText, 32, x)
                    // + offsetLen
                    + (ptrText - ptrStart);
            }
        }

        // safe because ptrText < ptrEnd, and ptrEnd = ptrText + n*32 (see lenTail)
        unchecked {
            ptrText += 32;
        }
    }

    if (lenTail == 0) return type(uint256).max;

    index = memchrWord(ptrEnd, lenTail, x);
    if (index == type(uint256).max) {
        return type(uint256).max;
    } else {
        // - is safe because ptrEnd >= ptrStart (ptrEnd = ptrStart + lenText - lenTail)
        // + is safe because index + offsetLen < lenText
        // (ptr+len is implicitly safe)
        unchecked {
            return index
                // + offsetLen
                + (ptrEnd - ptrStart);
        }
    }
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memrchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memrchrWord(ptrText, lenText, x);
    }

    uint256 lenTail;
    uint256 offsetPtr;
    // safe because pointers are guaranteed to be valid by the caller
    unchecked {
        // (unchecked % saves a little gas)
        lenTail = lenText % 32;
        offsetPtr = ptrText + lenText;
    }

    if (lenTail != 0) {
        // remove tail length
        // - is safe because lenTail <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= lenTail;
        }
        // return if there is a matching byte
        uint256 index = memrchrWord(offsetPtr, lenTail, x);
        if (index != type(uint256).max) {
            // - is safe because offsetPtr > ptrText (offsetPtr = ptrText + lenText - lenTail)
            // + is safe because index + offsetLen < lenText
            unchecked {
                return index
                    // + offsetLen
                    + (offsetPtr - ptrText);
            }
        }
    }

    uint256 repeatedX = repeatByte(x);
    while (offsetPtr > ptrText) {
        // - is safe because 32 <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= 32;
        }

        // any bytes equal to `x` become zeros
        // (this helps find `x` faster, values of non-zero bytes don't matter)
        uint256 chunkXZero;
        /// @solidity memory-safe-assembly
        assembly {
            chunkXZero := xor(mload(offsetPtr), repeatedX)
        }
        // break if there is a matching byte
        if (nonZeroIfXcontainsZeroByte(chunkXZero) != 0) {
            // - is safe because offsetPtr > ptrText (see the while condition)
            // + is safe because index + offsetLen < lenText
            unchecked {
                return
                    // index
                    memrchrWord(offsetPtr, 32, x)
                    // + offsetLen
                    + (offsetPtr - ptrText);
            }
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memchr after its chunk search.
 */
function memchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }

    uint256 i;
    if (lenText > 32) {
        lenText = 32;
    }

    ////////binary search start
    // Some manual binary searches, cost ~50gas, could save up to ~1500
    // (comment them out and the function will work fine)
    if (lenText >= 16 + 2) {
        uint256 repeatedX = chunk ^ repeatByte(x);

        if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint128).max) == 0) {
            i = 16;

            if (lenText >= 24 + 2) {
                if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint64).max) == 0) {
                    i = 24;
                }
            }
        } else if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint192).max) == 0) {
            i = 8;
        }
    } else if (lenText >= 8 + 2) {
        uint256 repeatedX = chunk ^ repeatByte(x);

        if (nonZeroIfXcontainsZeroByte(repeatedX | type(uint192).max) == 0) {
            i = 8;
        }
    }
    ////////binary search end
    
    // ++ is safe because lenText <= 32
    unchecked {
        for (i; i < lenText; i++) {
            uint8 b;
            assembly {
                b := byte(i, chunk)
            }
            if (b == x) return i;
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memrchr after its chunk search.
 */
function memrchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText > 32) {
        lenText = 32;
    }
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }

    while (lenText > 0) {
        // -- is safe because lenText > 0
        unchecked {
            lenText--;
        }
        uint8 b;
        assembly {
            b := byte(lenText, chunk)
        }
        if (b == x) return lenText;
    }
    // not found
    return type(uint256).max;
}

/// @dev repeating low bit for containsZeroByte
uint256 constant LO_U256 = 0x0101010101010101010101010101010101010101010101010101010101010101;
/// @dev repeating high bit for containsZeroByte
uint256 constant HI_U256 = 0x8080808080808080808080808080808080808080808080808080808080808080;

/**
 * @dev Returns a non-zero value if `x` contains any zero byte.
 * (returning a bool would be less efficient)
 *
 * From *Matters Computational*, J. Arndt:
 *
 * "The idea is to subtract one from each of the bytes and then look for
 * bytes where the borrow propagated all the way to the most significant bit."
 */
function nonZeroIfXcontainsZeroByte(uint256 x) pure returns (uint256) {
    unchecked {
        return (x - LO_U256) & (~x) & HI_U256;
    }
    /*
     * An example of how it works:
     *                                              here is 00
     * x    0x0101010101010101010101010101010101010101010101000101010101010101
     * x-LO 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
     * ~x   0xfefefefefefefefefefefefefefefefefefefefefefefefffefefefefefefefe
     * &1   0xfefefefefefefefefefefefefefefefefefefefefefefeff0000000000000000
     * &2   0x8080808080808080808080808080808080808080808080800000000000000000
     */
}

/// @dev Repeat byte `b` 32 times
function repeatByte(uint8 b) pure returns (uint256) {
    // safe because uint8 can't cause overflow:
    // e.g. 0x5A * 0x010101..010101 = 0x5A5A5A..5A5A5A
    // and  0xFF * 0x010101..010101 = 0xFFFFFF..FFFFFF
    unchecked {
        return b * (type(uint256).max / type(uint8).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { utf8CharWidth } from "./utf8.sol";

/*
 * IMPORTANT: Here `uint256` represents 1 code point (aka unicode scalar values),
 * NOT a UTF-8 encoded character!
 * E.g. for '€' code point = 0x20AC; wheareas UTF-8 encoding = 0xE282AC.
 *
 * Only conversion to/from UTF-8 is addressed here.
 * Note that UTF-16 surrogate halves are invalid code points even if UTF-16 was supported.
 */

error Unicode__InvalidCode();

/// @dev The highest valid code point.
uint256 constant MAX = 0x10FFFF;

// UTF-8 ranges
uint256 constant MAX_ONE_B = 0x80;
uint256 constant MAX_TWO_B = 0x800;
uint256 constant MAX_THREE_B = 0x10000;
// and tags for encoding characters
uint256 constant TAG_CONT = 0x80;
uint256 constant TAG_TWO_B = 0xC0;
uint256 constant TAG_THREE_B = 0xE0;
uint256 constant TAG_FOUR_B = 0xF0;
// and continuation byte mask
uint256 constant MASK_CONT = 0x3F;

/**
 * @dev Encodes a unicode code point as UTF-8.
 * Reverts if the code point is invalid.
 * The result is 1-4 bytes starting at MSB.
 */
function encodeUtf8(uint256 code) pure returns (bytes32) {
    if (code < MAX_ONE_B) {
        return bytes32(
            (code                                ) << (31 * 8)
        );
    } else if (code < MAX_TWO_B) {
        return bytes32(
            (code >> 6              | TAG_TWO_B  ) << (31 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (30 * 8)
        );
    } else if (code < MAX_THREE_B) {
        if (code & 0xF800 == 0xD800) {
            // equivalent to `code >= 0xD800 && code <= 0xDFFF`
            // U+D800–U+DFFF are invalid UTF-16 surrogate halves
            revert Unicode__InvalidCode();
        }
        return bytes32(
            (code >> 12             | TAG_THREE_B) << (31 * 8) |
            (code >> 6  & MASK_CONT | TAG_CONT   ) << (30 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (29 * 8)
        );
    } else if (code <= MAX) {
        return bytes32(
            (code >> 18             | TAG_FOUR_B ) << (31 * 8) |
            (code >> 12 & MASK_CONT | TAG_CONT   ) << (30 * 8) |
            (code >> 6  & MASK_CONT | TAG_CONT   ) << (29 * 8) |
            (code       & MASK_CONT | TAG_CONT   ) << (28 * 8)
        );
    } else {
        revert Unicode__InvalidCode();
    }
}

/**
 * @dev Decodes a UTF-8 character into its code point.
 * Validates ONLY the leading byte, use `isValidCodePoint` on the result if UTF-8 wasn't validated.
 * The input is 1-4 bytes starting at MSB.
 */
function decodeUtf8(bytes32 str) pure returns (uint256) {
    uint256 leadingByte = uint256(uint8(str[0]));
    uint256 width = utf8CharWidth(leadingByte);

    if (width == 1) {
        return leadingByte;
    } else if (width == 2) {
        uint256 byte1 = uint256(uint8(str[1]));
        return uint256(
            // 0x1F = 0001_1111
            (leadingByte & 0x1F     ) << 6 |
            (byte1       & MASK_CONT)
        );
    } else if (width == 3) {
        uint256 byte1 = uint256(uint8(str[1]));
        uint256 byte2 = uint256(uint8(str[2]));
        return uint256(
            // 0x0F = 0000_1111
            (leadingByte & 0x0F     ) << 12 |
            (byte1       & MASK_CONT) << 6  |
            (byte2       & MASK_CONT)
        );
    } else if (width == 4) {
        uint256 byte1 = uint256(uint8(str[1]));
        uint256 byte2 = uint256(uint8(str[2]));
        uint256 byte3 = uint256(uint8(str[3]));
        return uint256(
            // 0x07 = 0000_0111
            (leadingByte & 0x07     ) << 18 |
            (byte1       & MASK_CONT) << 12 |
            (byte2       & MASK_CONT) << 6  |
            (byte3       & MASK_CONT)
        );
    } else {
        revert Unicode__InvalidCode();
    }
}

/**
 * @dev Returns the length of a code point in UTF-8 encoding.
 * Does NOT validate it.
 * WARNING: atm this function is neither used nor tested in this repo
 */
function lenUtf8(uint256 code) pure returns (uint256) {
    if (code < MAX_ONE_B) {
        return 1;
    } else if (code < MAX_TWO_B) {
        return 2;
    } else if (code < MAX_THREE_B) {
        return 3;
    } else {
        return 4;
    }
}

/**
 * @dev Returns true if the code point is valid.
 * WARNING: atm this function is neither used nor tested in this repo
 */
function isValidCodePoint(uint256 code) pure returns (bool) {
    // U+D800–U+DFFF are invalid UTF-16 surrogate halves
    if (code < 0xD800) {
        return true;
    } else {
        return code > 0xDFFF && code <= MAX;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Returns the byte length for a UTF-8 character with the leading byte.
 * Returns 0 for invalid leading bytes.
 */
function utf8CharWidth(uint256 leadingByte) pure returns (uint256) {
    if (leadingByte < 0x80) {
        return 1;
    } else if (leadingByte < 0xC2) {
        return 0;
    } else if (leadingByte < 0xE0) {
        return 2;
    } else if (leadingByte < 0xF0) {
        return 3;
    } else if (leadingByte < 0xF5) {
        return 4;
    } else {
        return 0;
    }
}

/**
 * @dev Returns true if `b` is a valid UTF-8 leading byte.
 */
function isLeadingByte(uint256 b) pure returns (bool) {
    return utf8CharWidth(b) > 0;
}

/**
 * @dev Returns character length if the 1-4 bytes at MSB are a valid UTF-8 encoded character.
 * Returns 0 for invalid characters.
 * (utf8CharWidth validates ONLY the leading byte, not the whole character)
 *
 * Note if MSB is 0x00, this will return 1, since 0x00 is valid UTF-8.
 * Works faster for smaller code points.
 *
 * https://www.rfc-editor.org/rfc/rfc3629#section-4
 * UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
 * UTF8-1      = %x00-7F
 * UTF8-2      = %xC2-DF UTF8-tail
 * UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
 *               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
 * UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
 *               %xF4 %x80-8F 2( UTF8-tail )
 * UTF8-tail   = %x80-BF
 */
function isValidUtf8(bytes32 b) pure returns (uint256) {
    // TODO you can significantly optimize comparisons with bitmasks,
    // some stuff to look at:
    // https://github.com/zwegner/faster-utf8-validator/blob/master/z_validate.c
    // https://github.com/websockets/utf-8-validate/blob/master/src/validation.c
    // https://github.com/simdutf/simdutf/blob/master/src/scalar/utf8.h

    uint8 first = uint8(b[0]);
    // UTF8-1 = %x00-7F
    if (first <= 0x7F) {
        // fast path for ascii
        return 1;
    }

    uint256 w = utf8CharWidth(first);
    if (w == 2) {
        // UTF8-2
        if (
            // %xC2-DF UTF8-tail
            0xC2 <= first && first <= 0xDF
            && _utf8Tail(uint8(b[1]))
        ) {
            return 2;
        } else {
            return 0;
        }
    } else if (w == 3) {
        uint8 second = uint8(b[1]);
        // UTF8-3
        bool valid12 =
            // = %xE0 %xA0-BF UTF8-tail
            first == 0xE0
            && 0xA0 <= second && second <= 0xBF
            // / %xE1-EC 2( UTF8-tail )
            || 0xE1 <= first && first <= 0xEC
            && _utf8Tail(second)
            // / %xED %x80-9F UTF8-tail
            || first == 0xED
            && 0x80 <= second && second <= 0x9F
            // / %xEE-EF 2( UTF8-tail )
            || 0xEE <= first && first <= 0xEF
            && _utf8Tail(second);

        if (valid12 && _utf8Tail(uint8(b[2]))) {
            return 3;
        } else {
            return 0;
        }
    } else if (w == 4) {
        uint8 second = uint8(b[1]);
        // UTF8-4
        bool valid12 =
            // = %xF0 %x90-BF 2( UTF8-tail )
            first == 0xF0
            && 0x90 <= second && second <= 0xBF
            // / %xF1-F3 3( UTF8-tail )
            || 0xF1 <= first && first <= 0xF3
            && _utf8Tail(second)
            // / %xF4 %x80-8F 2( UTF8-tail )
            || first == 0xF4
            && 0x80 <= second && second <= 0x8F;

        if (valid12 && _utf8Tail(uint8(b[2])) && _utf8Tail(uint8(b[3]))) {
            return 4;
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

/// @dev UTF8-tail = %x80-BF
function _utf8Tail(uint256 b) pure returns (bool) {
    // and,cmp should be faster than cmp,cmp,and
    // 0xC0 = 0b1100_0000, 0x80 = 0b1000_0000
    return b & 0xC0 == 0x80;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "base64/base64.sol";
import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/LibString.sol";
import {IERC5192} from "src/interfaces/IERC5192.sol";
import {PinkyPromiseSvg} from "src/PinkyPromiseSvg.sol";

/// @title PinkyPromise
/// @author Pierre Bertet
/// @notice A contract to create and sign "promises", which are soulbound NFTs.
/// @dev ERC721 & IERC5192 compliant. The NFT contract is also ownable
contract PinkyPromise is ERC721, IERC5192, Owned {
    using LibString for uint256;

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The latest promise ID.
    /// Note that the promise ID is NOT equivalent to a token ID, as a promise can have many signees,
    /// and each one of them will receive a separate NFT, corresponding to the promise.
    uint256 public latestPromiseId; // 0
    /// @notice The latest token ID.
    uint256 public latestTokenId; // 0

    mapping(uint256 => Promise) public promises;
    /// @notice Mapping of a certain token ID to the promise it's associated with.
    mapping(uint256 => uint256) public promiseIdsByTokenId;
    /// @notice Mapping of a certain signee address to the promises he's associated with.
    mapping(address => uint256[]) public promiseIdsBySignee;

    /// @notice promiseId => signer => SigningState
    /// We use SigningState rather than a boolean in this mapping,
    /// so we can rely on SigningState.None (the default) to ensure that
    /// Promise.signees only contain unique signatures (see newPromise()).
    mapping(uint256 => mapping(address => SigningState)) public signingStatesByPromise;

    /// @notice The ENS registry address.
    address public ensRegistry;

    /// @notice The BPBDateTime library address.
    /// See: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    address public bpbDateTime;

    string networkPrefix;

    struct PromiseData {
        PromiseColor color;
        uint16 height;
        string title;
        string body;
    }

    struct Promise {
        PromiseData data;
        address[] signees;
        uint256[] tokenIds;
        uint256 signedOn;
        /// The promise state. This works using a counter,
        /// with several values representing different states:
        /// state <  signees.length         => contract just created
        /// state >= signees.length         => contract signed
        /// state == signees.length * 2     => contract nullified
        /// state == signees.length * 2 + 1 => contract discarded
        ///
        /// See also state(promiseId).
        ///
        uint256 state;
    }

    enum PromiseColor {
        Pinky,
        Electric,
        RedAlert,
        Solemn
    }

    enum PromiseState {
        None,
        Draft,
        Final,
        Nullified,
        Discarded
    }

    enum SigningState {
        None, // default state is only used to enforce unique signees, see newPromise()
        Pending, // awaiting signature
        Signed,
        NullRequest // nullification requested (implies signed)
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Indicates if the minting has stopped.
    /// Creation of new promises can be stopped, making it possible to deploy a new version of the contract without ID conflicts.
    bool public stopped = false;

    /// @dev Emits when a promise is updated.
    /// This event is emitted when a promise is created, finalized (all signees have signed), nullified or discarded.
    event PromiseUpdate(uint256 indexed promiseId, PromiseState state);
    /// @dev Emits when a single signature is added
    event AddSignature(uint256 indexed promiseId, address indexed signer);
    /// @dev Emitted when a signee requests to nullify the promise
    event NullifyRequest(uint256 indexed promiseId, address indexed signer);
    /// @dev Emitted when a signe cancels a request to nullify the promise.
    event CancelNullifyRequest(uint256 indexed promiseId, address indexed signer);

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier notStopped() {
        require(!stopped, "PinkyPromise: the contract has been stopped and promises cannot be created anymore");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory networkPrefix_,
        address ensRegistry_,
        address bpbDateTime_
    ) ERC721(name_, symbol_) Owned(msg.sender) {
        networkPrefix = networkPrefix_;
        ensRegistry = ensRegistry_;
        bpbDateTime = bpbDateTime_;
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new promise.
    /// @dev If one of the signees is msg.sender, the promise is automatically signed. Each signee receives an NFT with the promise.
    /// @param promiseData The promise metadata to put in the NFT.
    /// @param signees The signees of the promise.
    /// @return promiseId The promise ID.
    function newPromise(PromiseData calldata promiseData, address[] calldata signees)
        external
        notStopped
        returns (uint256 promiseId)
    {
        require(signees.length > 0, "PinkyPromise: a promise requires at least one signee");

        promiseId = ++latestPromiseId;

        Promise storage promise_ = promises[promiseId];

        // Populate the signing states
        for (uint256 i = 0; i < signees.length; i++) {
            require(
                signingStatesByPromise[promiseId][signees[i]] == SigningState.None,
                "PinkyPromise: each signee must be unique"
            );

            // Sign if the sender is one of the promise signees
            if (signees[i] == msg.sender) {
                promise_.state++;
                signingStatesByPromise[promiseId][msg.sender] = SigningState.Signed;
                emit AddSignature(promiseId, msg.sender);
            } else {
                signingStatesByPromise[promiseId][signees[i]] = SigningState.Pending;
            }

            // Used to retreive the promises where a given account is participating
            promiseIdsBySignee[signees[i]].push(promiseId);
        }

        promise_.data = promiseData;

        if (promise_.data.height < 800) {
            promise_.data.height = 800;
        }

        promise_.signees = signees;

        emit PromiseUpdate(promiseId, PromiseState.Draft);

        // If msg.sender is the sole signer, finalize the promise
        if (_promiseState(promise_) == PromiseState.Final) {
            _finalizeAndMint(promiseId, promise_.signees);
        }
    }

    /// @notice Add a signature to a promise draft.
    /// @dev Reverts if the signee has signed already or if the promise is already discarded or nullified.
    /// @param promiseId The promise ID.
    function sign(uint256 promiseId) external {
        Promise storage promise_ = promises[promiseId];

        require(
            _promiseState(promise_) == PromiseState.Draft,
            "PinkyPromise: only non-discarded drafts can receive signatures"
        );
        require(
            signingStatesByPromise[promiseId][msg.sender] != SigningState.None,
            "PinkyPromise: drafts can only get signed by signees"
        );
        require(signingStatesByPromise[promiseId][msg.sender] == SigningState.Pending, "PinkyPromise: already signed");

        promise_.state++;
        signingStatesByPromise[promiseId][msg.sender] = SigningState.Signed;
        emit AddSignature(promiseId, msg.sender);

        // Last signer creates the NFTs
        // on the above function as well
        if (_promiseState(promise_) == PromiseState.Final) {
            _finalizeAndMint(promiseId, promise_.signees);
        }
    }

    /// @notice Discard a promise.
    /// @dev This is only possible when the promise is a draft, and it can get called by any of the signees.
    /// @param promiseId The promise ID.
    function discard(uint256 promiseId) external {
        Promise storage promise_ = promises[promiseId];

        require(_promiseState(promise_) == PromiseState.Draft, "PinkyPromise: only drafts can get discarded");
        require(
            signingStatesByPromise[promiseId][msg.sender] != SigningState.None,
            "PinkyPromise: drafts can only get discarded by signees"
        );

        // discarded state, see Promise.state
        promise_.state = promise_.signees.length * 2 + 1;
        emit PromiseUpdate(promiseId, PromiseState.Discarded);
    }

    /// @notice Request to nullify a promise. Once all the signees have requested to
    /// nullify, the promise becomes nullified. This is only possible when the
    /// promise has been signed by all signees. Reverts if the signee has
    /// requested to nullify already.
    /// @param promiseId The promise ID.
    function nullify(uint256 promiseId) external {
        Promise storage promise_ = promises[promiseId];

        require(_promiseState(promise_) == PromiseState.Final, "PinkyPromise: only signed promises can get nullified");
        require(
            signingStatesByPromise[promiseId][msg.sender] == SigningState.Signed,
            "PinkyPromise: invalid nullification request"
        );

        signingStatesByPromise[promiseId][msg.sender] = SigningState.NullRequest;

        promise_.state++;
        emit NullifyRequest(promiseId, msg.sender);

        if (_promiseState(promise_) == PromiseState.Nullified) {
            for (uint256 i = 0; i < promise_.tokenIds.length; i++) {
                _burn(promise_.tokenIds[i]);
            }
            emit PromiseUpdate(promiseId, PromiseState.Nullified);
        }
    }

    /// @notice Cancel a single nullification request. This is so that signees having requested a
    /// nullification can change their mind before the others do it as well.
    /// @dev This is only possible if the promise is signed by all signees AND the current signee has tried to nullify the promise.
    function cancelNullify(uint256 promiseId) external {
        Promise storage promise_ = promises[promiseId];

        require(_promiseState(promise_) == PromiseState.Final, "PinkyPromise: only signed promises can get nullified");
        require(
            signingStatesByPromise[promiseId][msg.sender] == SigningState.NullRequest,
            "PinkyPromise: nullification cancel not needed"
        );

        signingStatesByPromise[promiseId][msg.sender] = SigningState.Signed;

        promise_.state--;
        emit CancelNullifyRequest(promiseId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC721/5192 FUNCTION OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override (ERC721) returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }

    function transferFrom(address, address, uint256) public pure override {
        revert("PinkyPromise: transfers disallowed");
    }

    function safeTransferFrom(address, address, uint256) public pure override {
        revert("PinkyPromise: transfers disallowed");
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override {
        revert("PinkyPromise: transfers disallowed");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require((_ownerOf[tokenId]) != address(0), "PinkyPromise: tokenId not assigned");
        return promiseMetadataURI(promiseIdsByTokenId[tokenId]);
    }

    /// @notice Check if the token is soulbound. In the case of Pinky Promises, they always are..
    function locked(uint256 tokenId) external view returns (bool) {
        require(_ownerOf[tokenId] != address(0), "PinkyPromise: tokenId not assigned");
        return true; // always locked
    }

    /*//////////////////////////////////////////////////////////////
                   PinkyPromise SPECIFIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Compute the metadata URI for a promise.
    /// @param promiseId The promise ID.
    /// @return The metadata URI.
    function promiseMetadataURI(uint256 promiseId) public view returns (string memory) {
        Promise storage promise_ = promises[promiseId];
        string memory name = promise_.data.title;
        string memory image = promiseImageURI(promiseId);
        string memory description = "";
        string memory external_url = string.concat("https://pp/promise/", promiseId.toString());
        string memory background_color = PinkyPromiseSvg.promiseContentColor(promise_.data.color);
        string memory flavor = PinkyPromiseSvg.promiseColorName(promise_.data.color);
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        "{",
                        '"name":"',
                        name,
                        '", "description":"',
                        description,
                        '", "image":"',
                        image,
                        '", "external_url":"',
                        external_url,
                        '", "background_color":"',
                        background_color,
                        '", "attributes": [{ "trait_type": "Flavor", "value": "',
                        flavor,
                        '" }]',
                        "}"
                    )
                )
            )
        );
    }

    /// @notice Renders the promise as an SVG.
    /// @dev This uses the PinkyPromiseSvg library to render the promise.
    /// @return The SVG as a string.
    function promiseAsSvg(uint256 promiseId) public view returns (string memory) {
        Promise storage promise_ = promises[promiseId];
        require(_promiseState(promise_) != PromiseState.None, "PinkyPromise: non existant promise");

        PinkyPromiseSvg.Contracts memory contracts;
        contracts.ensRegistry = ensRegistry;
        contracts.bpbDateTime = bpbDateTime;

        PinkyPromiseSvg.PinkyPromiseSvgData memory svgData;
        svgData.networkPrefix = networkPrefix;
        svgData.promiseId = promiseId;
        svgData.promiseState = promiseState(promiseId);
        svgData.promiseData = promise_.data;
        svgData.signedOn = promise_.signedOn;
        svgData.signees = promise_.signees;

        SigningState[] memory signingStates;
        (, signingStates) = promiseSignees(promiseId);

        return PinkyPromiseSvg.promiseAsSvg(contracts, svgData, signingStates);
    }

    /// @notice Renders the promise as an SVG and returns it as a data URI.
    /// @param promiseId The promise ID.
    /// @return The SVG as a data URI.
    function promiseImageURI(uint256 promiseId) public view returns (string memory) {
        return string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(promiseAsSvg(promiseId))));
    }

    /// @notice Get the promise signees and their signing states.
    /// @param promiseId The promise ID.
    /// @return signees The signees addresses.
    /// @return signingStates The signing states corresponding to the signees.
    function promiseSignees(uint256 promiseId)
        public
        view
        returns (address[] memory signees, SigningState[] memory signingStates)
    {
        Promise storage promise_ = promises[promiseId];
        require(_promiseState(promise_) != PromiseState.None, "PinkyPromise: non existant promise");

        signees = promise_.signees;
        signingStates = new SigningState[](signees.length);
        for (uint256 i = 0; i < signees.length; i++) {
            signingStates[i] = signingStatesByPromise[promiseId][signees[i]];
        }
    }

    /// @notice Get the promises a signee is involved in.
    /// @param signee The signee address.
    /// @return promiseIds The promise IDs.
    function signeePromises(address signee) public view returns (uint256[] memory promiseIds) {
        promiseIds = promiseIdsBySignee[signee];
    }

    /// @notice Get the state of a promise.
    /// @param promiseId The promise ID.
    /// @return The promise state.
    function promiseState(uint256 promiseId) public view returns (PromiseState) {
        return _promiseState(promises[promiseId]);
    }

    /// @notice Get all relevant information about a promise, including its data, state, signees, signing states and signed on date.
    /// @param promiseId The promise ID.
    /// @return data The PromiseData attached to the promise.
    /// @return state The PromiseState.
    /// @return signees The signees.
    /// @return signingStates The signing state of every signee.
    /// @return signedOn The date and time the promise was signed on.
    function promiseInfo(uint256 promiseId)
        public
        view
        returns (
            PromiseData memory data,
            PromiseState state,
            address[] memory signees,
            SigningState[] memory signingStates,
            uint256 signedOn
        )
    {
        Promise storage promise_ = promises[promiseId];
        require(_promiseState(promise_) != PromiseState.None, "PinkyPromise: non existant promise");

        data = promise_.data;
        state = _promiseState(promise_);
        signedOn = promise_.signedOn;

        (signees, signingStates) = promiseSignees(promiseId);
    }

    /// @notice Get the total number of promises.
    /// @dev This is NOT equal to the amount of NFTs minted.
    /// @return The total number of promises.
    function total() public view returns (uint256) {
        return latestPromiseId;
    }

    /*//////////////////////////////////////////////////////////////
                           ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function stop() public onlyOwner {
        stopped = true;
    }

    function setEnsRegistry(address ensRegistry_) public onlyOwner {
        ensRegistry = ensRegistry_;
    }

    function setBpbDateTime(address bpbDateTime_) public onlyOwner {
        bpbDateTime = bpbDateTime_;
    }

    /*//////////////////////////////////////////////////////////////
                      INTERNAL/PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Get the promise state, based on promise.signees and promise.state
    function _promiseState(Promise storage promise_) internal view returns (PromiseState) {
        // signees cannot be empty except when the promise does not exist (default value)
        if (promise_.signees.length == 0) {
            return PromiseState.None;
        }
        if (promise_.state < promise_.signees.length) {
            return PromiseState.Draft;
        }
        if (promise_.state < promise_.signees.length * 2) {
            return PromiseState.Final;
        }
        if (promise_.state == promise_.signees.length * 2 + 1) {
            return PromiseState.Discarded;
        }
        return PromiseState.Nullified;
    }

    // Mint a single promise NFT
    function _mintPromiseNft(uint256 promiseId, address signee) internal returns (uint256) {
        uint256 tokenId = ++latestTokenId;
        _mint(signee, tokenId);
        promiseIdsByTokenId[tokenId] = promiseId;
        emit Locked(tokenId);
        return tokenId;
    }

    function _finalizeAndMint(uint256 promiseId, address[] storage signees) internal {
        Promise storage promise_ = promises[promiseId];

        promise_.tokenIds = new uint256[](signees.length);
        for (uint256 i = 0; i < signees.length; i++) {
            promise_.tokenIds[i] = _mintPromiseNft(promiseId, signees[i]);
        }

        promise_.signedOn = block.timestamp;

        emit PromiseUpdate(promiseId, PromiseState.Final);
    }
}

// FILE GENERATED, DO NOT EDIT DIRECTLY

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/LibString.sol";
import {StrSlice, toSlice} from "dk1a-stringutils/StrSlice.sol";
import {DateUtils} from "src/lib/DateUtils.sol";
import {EnsUtils} from "src/lib/EnsUtils.sol";
import {AddressUtils} from "src/lib/AddressUtils.sol";
import {PinkyPromise} from "src/PinkyPromise.sol";

library PinkyPromiseSvg {
    using LibString for uint16;
    using LibString for uint256;
    using AddressUtils for address;

    struct Contracts {
        address ensRegistry;
        address bpbDateTime;
    }

    struct PinkyPromiseSvgData {
        PinkyPromise.PromiseData promiseData;
        PinkyPromise.PromiseState promiseState;
        address[] signees;
        uint256 promiseId;
        uint256 signedOn;
        string networkPrefix;
    }

    function promiseAsSvg(
        Contracts calldata contracts,
        PinkyPromiseSvgData calldata svgData,
        PinkyPromise.SigningState[] calldata signingStates
    ) public view returns (string memory) {
        return promiseSvgWrapper(svgData.promiseData, promiseSvgContent(contracts, svgData, signingStates));
    }

    function promiseSvgWrapper(PinkyPromise.PromiseData calldata promiseData, string memory content)
        public
        pure
        returns (string memory)
    {
        string memory color = string.concat("#", promiseColor(promiseData.color));
        string memory contentColor = string.concat("#", promiseContentColor(promiseData.color));
        string memory height = promiseData.height.toString();
        string memory fingers = promiseSvgFingers(promiseData.height, contentColor);
        return string.concat(
            '<svg height="',
            height,
            '" viewBox="0 0 800 ',
            height,
            '" width="800" xmlns="http://www.w3.org/2000/svg"><foreignObject x="0" y="0" width="800" height="100%"><div class="root" xmlns="http://www.w3.org/1999/xhtml"><style>svg{--color:',
            color,
            ";--contentColor:",
            contentColor,
            ";contain:layout}svg *{box-sizing:border-box;word-break:break-word}svg .root{height:",
            height,
            "px;color:var(--contentColor);background:var(--color);padding:40px 40px 32px;font:400 19px/28px Courier New,monospace}svg a{color:var(--contentColor);text-decoration:none}svg .main{width:720px;height:100%;flex-direction:column;display:flex;overflow:hidden}svg .header{width:100%;height:70px;text-transform:uppercase;border-bottom:2px solid var(--contentColor);flex-grow:0;flex-shrink:0;justify-content:space-between;padding-bottom:16px;font-size:18px;display:flex}svg .header>div+div{text-align:right}svg .content{width:100%;height:100%;flex-direction:column;flex-grow:1;display:flex}svg .title{flex-grow:0;flex-shrink:0;padding-top:40px;font-size:32px;font-weight:400;line-height:38px}svg .body{flex-grow:1;flex-shrink:0;padding-top:24px;overflow:hidden}svg .body p{margin:24px 0}svg .body p:first-child{margin-top:0}svg .body h1{margin:32px 0;padding-bottom:5px;font-size:26px;font-weight:400;line-height:36px;position:relative}svg .body h2{margin:24px 0;font-size:22px;font-weight:400;line-height:32px}svg .signees{flex-direction:column;flex-grow:0;flex-shrink:0;padding-top:0;padding-bottom:112px;display:flex;overflow:hidden}svg .signee{height:40px;justify-content:space-between;align-items:center;gap:12px;display:flex}svg .signee a{text-decoration:none}svg .signee>div:first-child{text-overflow:ellipsis;white-space:nowrap;overflow:hidden}svg .signature{color:var(--contentColor);white-space:nowrap;flex-shrink:0;justify-content:flex-end;align-items:center;gap:12px;font-weight:500;display:flex}svg .signature>div:first-child{width:50px;height:28px;background:var(--contentColor);border-radius:64px;justify-content:center;align-items:center;display:flex}svg .signature svg path{fill:var(--color)}svg .signature b{color:var(--contentColor)}</style>",
            content,
            "</div></foreignObject>",
            fingers,
            "</svg>"
        );
    }

    function promiseSvgFingers(uint16 promiseHeight, string memory color) public pure returns (string memory) {
        string memory fingersY = (promiseHeight - 112).toString();
        return string.concat(
            '<svg fill="',
            color,
            '" height="80" width="80" x="360" y="',
            fingersY,
            '"><path clip-rule="evenodd" fill-rule="evenodd" d="M44.356 79.302c-.333.036-.667.069-1.002.097-.068-.325-.14-.664-.218-1.019l-.358-1.673c-.55-2.578-1.086-5.083-1.77-7.584l-4.304 10.28c-11.142-.919-20.973-6.458-27.575-14.696l.025.032c.29-2.179.6-4.648.804-6.65.196-1.92.36-4.113.476-5.823a275.543 275.543 0 0 0 .17-2.727l.013-.219-.5-.028-.499-.027-.012.218-.036.608c-.03.52-.076 1.254-.134 2.107-.115 1.707-.279 3.887-.473 5.789a217.926 217.926 0 0 1-.67 5.638 39.357 39.357 0 0 1-7.83-23.204c1.295-.495 2.845-.514 4.04-.334.737.111 1.833.412 2.99 1.574 1.036 1.043 2.095 2.752 3.006 5.573a8.152 8.152 0 0 1 1.45-1.056c.794-.466 1.586-.894 2.472-1.128.9-.238 1.873-.27 3.038.014 1.163.283 1.815.69 2.32 1.228.234.248.43.517.618.777l.016.022c.197.272.399.548.66.842.343.385.62.936.857 1.614.24.684.449 1.533.637 2.544.375 2.023.673 4.743.937 8.193l.002.022v.023c-.011.791.05 2.064.267 3.287.108.611.253 1.198.442 1.7.1.264.207.496.322.692a88.67 88.67 0 0 0 4.222-5.644c1.701-2.482 3.272-5.098 3.986-7.1l.005-.013.006-.013c.219-.517.416-.987.595-1.417-.895-1.94-1.943-4.495-3.24-8.157-2.919-8.236-1.542-17.05-1.064-20.105.064-.416.113-.725.131-.912l.002-.013c.268-2.138 1.324-4.49 2.742-6.214 1.397-1.699 3.288-2.947 5.23-2.491.845.198 1.504.604 2.032 1.263.514.641.886 1.5 1.214 2.572.071.235.215.816.364 1.644a4.292 4.292 0 0 1 2.044-1.744c.83-.347 1.674-.417 2.17-.299.944.225 3.374 1.6 3.944 5.88.708 4.651 1.6 16.426-.79 26.789l-.007.031-.14.377.054.074.076.105c1.464 2.008 2.528 3.78 3.369 5.19l.023.038c.845 1.416 1.428 2.392 1.96 2.929.3.3.533.526.737.683.206.16.33.207.402.216.046.005.12.003.257-.104.153-.118.347-.338.6-.72.438-.66.544-1.046.71-1.653l.016-.055.033-.12c.206-.742.514-1.735 1.453-3.556 1.503-2.915 3.347-4.192 4.223-4.48a13.233 13.233 0 0 1 3.734-.93c.919-.08 1.904-.043 2.785.251a23.343 23.343 0 0 1 .914-3.083c.366-.974.846-2.017 1.458-2.929.61-.908 1.373-1.719 2.32-2.182 1.313-.643 2.457-.665 3.58-.547.353.038.693.086 1.033.135.587.084 1.172.167 1.82.191V40c0 .3-.004.597-.01.895-.737-.027-1.418-.124-2.04-.212-.318-.046-.621-.089-.907-.12-1.02-.107-1.955-.079-3.036.451-.73.357-1.373 1.013-1.93 1.842-.555.826-1.002 1.792-1.353 2.724a22.354 22.354 0 0 0-.935 3.237l-.012.056 4.44 5.33 1.966 2.767c-.163.342-.33.682-.503 1.018l-.915-1.286-.931-1.277-.015-.028-.07-.125-.326-.458-4.507-5.412c-.751-.352-1.714-.437-2.738-.346a12.228 12.228 0 0 0-3.453.863l-.022.01-.023.006c-.539.17-2.224 1.21-3.658 3.992-.905 1.756-1.19 2.684-1.379 3.366l-.017.062-.03.111c-.172.629-.313 1.144-.841 1.94-.274.414-.54.74-.82.958-.295.228-.625.35-.99.306-.34-.041-.637-.218-.895-.418a9.212 9.212 0 0 1-.833-.77c-.622-.625-1.258-1.691-2.036-2.995l-.098-.164c-.839-1.407-1.883-3.145-3.317-5.112-1.167-1.6-1.967-2.828-2.494-3.716-.494-.834-.765-1.396-.862-1.694-1.331-2.773-2.97-7.12-3.701-11.95-.305-2.01-.27-3.548-.178-5.056.017-.294.037-.585.057-.877.083-1.211.168-2.445.115-3.967-.104-3.032-.66-5.428-.802-5.895-.314-1.03-.642-1.745-1.038-2.238a2.503 2.503 0 0 0-1.39-.893c.044.684.03 1.572-.118 2.5-.195 1.222-.632 2.567-1.53 3.593-1.109 1.268-2.43 1.755-3.486 1.927a6.986 6.986 0 0 1-1.328.085c-.167-.005-.305-.014-.402-.02h-.008c-.027.195-.065.443-.11.737-.485 3.143-1.796 11.631 1.022 19.583 2.036 5.744 3.442 8.717 4.597 10.86a81.3 81.3 0 0 0 1.009 1.803c.731 1.28 1.415 2.477 2.152 4.19 2.655 5.585 3.777 10.843 4.943 16.307.119.557.238 1.117.36 1.679.086.396.166.774.242 1.133Zm-21.371-3.601c-.315-.15-.626-.304-.936-.462.409-2.361 1.142-5.996 2.02-8.649l.95.315c-.894 2.698-1.642 6.478-2.034 8.796Zm22.161-51.474c-.227-.863-.349-2.415-.248-5.545.142.026.308.068.486.132.55.196 1.229.606 1.735 1.48.25.433.456 1.057.62 1.782.162.719.274 1.503.353 2.234a32.714 32.714 0 0 1 .157 2.206 3.682 3.682 0 0 1-.851-.124c-.505-.134-.969-.367-1.266-.683-.086-.093-.175-.18-.253-.257l-.003-.003-.077-.076a3.028 3.028 0 0 1-.257-.282c-.142-.183-.28-.427-.396-.864Z"></path><path d="M65.97 69.815c.252-.22.5-.441.746-.667a79.868 79.868 0 0 1-1.318-1.477c-1.017-1.176-2.06-2.593-2.853-3.722a72.259 72.259 0 0 1-1.228-1.808l-.07-.11-.018-.027-.006-.009-.841.541.007.01.019.03.035.054.037.058.275.415c.235.353.57.85.972 1.42.667.952 1.52 2.12 2.395 3.185-1.588.36-2.775.362-3.854-.006-1.258-.429-2.45-1.387-3.977-3.081l-.742.669c1.556 1.727 2.889 2.844 4.397 3.358 1.444.493 2.978.408 4.901-.087.346.395.73.822 1.124 1.254Z"></path></svg>'
        );
    }

    function promiseSvgContent(
        Contracts calldata contracts,
        PinkyPromiseSvgData calldata svgData,
        PinkyPromise.SigningState[] calldata signingStates
    ) public view returns (string memory) {
        string memory body = promiseTextToHtml(svgData.promiseData.body);
        string memory id = string.concat(svgData.networkPrefix, "-", svgData.promiseId.toString());
        string memory signees = signeesAsHtml(contracts.ensRegistry, svgData.signees, signingStates);
        string memory status = promiseStatusLabel(svgData.promiseState);
        string memory title = svgData.promiseData.title;

        string memory signedOn = unicode"−";
        if (svgData.signedOn > 0) {
            signedOn = DateUtils.formatDate(contracts.bpbDateTime, svgData.signedOn);
        }

        return string.concat(
            '<div class="main"><div class="header"><div><div>Pinky Promise</div><div><strong>',
            id,
            "</strong></div></div><div><div>",
            signedOn,
            "</div><div><strong>",
            status,
            '</strong></div></div></div><div class="content"><div class="title">',
            title,
            '</div><div class="body">',
            body,
            '</div><div class="signees">',
            signees,
            "</div></div></div>"
        );
    }

    function signeesAsHtml(
        address ensRegistry,
        address[] calldata signees,
        PinkyPromise.SigningState[] calldata signingStates
    ) public view returns (string memory) {
        string memory html = "";
        for (uint256 i = 0; i < signees.length; i++) {
            html = string.concat(
                html,
                signeeAsHtml(
                    ensRegistry,
                    signees[i],
                    signingStates[i] == PinkyPromise.SigningState.Signed
                        || signingStates[i] == PinkyPromise.SigningState.NullRequest
                )
            );
        }
        return html;
    }

    function signeeAsHtml(address ensRegistry, address signee, bool signed) public view returns (string memory) {
        string memory addressHtml = EnsUtils.nameOrAddress(ensRegistry, signee);
        string memory signature = "";
        if (signed) {
            signature =
                '<div class="signature"><div><svg width="38" height="14" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="m.516 9.758-.118-1.05L0 6.592l.317-1.057.459-.302-.023-.314.201.197.224-.147 1.115.126.725.66.77 1.138L4.8 8.631l.594-1.26.697-1.308.538-.855.6-.799.667-.673.848-.551.843-.223.627.045.486.15.557.35.444.432.406.57.455.842.733 1.932.637 2.071 1.65-2.232 1.357-1.631.823-.781.892-.692.825-.485 1.017-.422.792-.204.797-.082 1.056.058.72.18.922.457.45.375.136-.183.957-1.182.527-.573.784-.68.754-.525.774-.379 1.071-.296.85-.077.689.047.808.169.76.257.702.357.762.532.577.487.555.622.841.062.757.669.237 1.004-.374.978-1.011.603-.38.18-.987-.038-.804-.74-.126-.528-.118-.341-.213-.334-.293-.338-.373-.302-.404-.262-.426-.193-.705-.2-.384-.044-.677.07-.65.204-.543.315-.574.478-.505.564-.553.772-.675 1.171-.716 1.52-.852.487-.903-.065-.726-.643-.194-.819.08-.576-.007-.017-.158-.224-.212-.156-.506-.196-.42-.046-.64.048-.69.19-.527.225-.636.378-.498.393-.657.62-.6.7-.717.944-2.322 3.489-.493.476-.756.385-.919-.138-.61-.558-.233-.448-1.077-3.74-.39-1.123-.315-.769-.478-.825-.067-.075-.115.041-.24.177L9 6.32l-.556.8-.42.757-.476.989-.965 2.266-.476.687-.768.502-1.017-.088-.71-.628-.18-.286-.068.2-.861.567-1-.074-.77-.681-.18-.766-.037-.807Z"></path></svg></div><span>signed</span></div>';
        }
        return string.concat('<div class="signee"><div>', addressHtml, "</div>", signature, "</div>");
    }

    function promiseColor(PinkyPromise.PromiseColor color) public pure returns (string memory) {
        if (color == PinkyPromise.PromiseColor.Pinky) {
            return "ED9AC9";
        }
        if (color == PinkyPromise.PromiseColor.Electric) {
            return "0007B0";
        }
        if (color == PinkyPromise.PromiseColor.RedAlert) {
            return "F6F6F6";
        }
        if (color == PinkyPromise.PromiseColor.Solemn) {
            return "F6F6F6";
        }
        revert("Incorrect PromiseColor value in promiseColor()");
    }

    function promiseContentColor(PinkyPromise.PromiseColor color) public pure returns (string memory) {
        if (color == PinkyPromise.PromiseColor.Pinky) {
            return "FFFFFF";
        }
        if (color == PinkyPromise.PromiseColor.Electric) {
            return "FFFFFF";
        }
        if (color == PinkyPromise.PromiseColor.RedAlert) {
            return "FF5262";
        }
        if (color == PinkyPromise.PromiseColor.Solemn) {
            return "1E1E1E";
        }
        revert("Incorrect PromiseColor value in promiseContentColor()");
    }

    function promiseColorName(PinkyPromise.PromiseColor color) public pure returns (string memory) {
        if (color == PinkyPromise.PromiseColor.Pinky) {
            return "Pinky";
        }
        if (color == PinkyPromise.PromiseColor.Electric) {
            return "Electric";
        }
        if (color == PinkyPromise.PromiseColor.RedAlert) {
            return "Red Alert";
        }
        if (color == PinkyPromise.PromiseColor.Solemn) {
            return "Solemn";
        }
        revert("Incorrect PromiseColor value in promiseColorName()");
    }

    function promiseStatusLabel(PinkyPromise.PromiseState state) public pure returns (string memory) {
        if (state == PinkyPromise.PromiseState.None) {
            return "N/A";
        }
        if (state == PinkyPromise.PromiseState.Draft) {
            return "Draft";
        }
        if (state == PinkyPromise.PromiseState.Final) {
            return "Signed";
        }
        if (state == PinkyPromise.PromiseState.Nullified) {
            return "Nullified";
        }
        if (state == PinkyPromise.PromiseState.Discarded) {
            return "Discarded";
        }
        revert("PromiseState value missing from promiseStatusLabel()");
    }

    function textBlockToHtml(StrSlice textBlock) public view returns (string memory) {
        StrSlice h1Tag = toSlice("# ");
        StrSlice h2Tag = toSlice("## ");

        if (textBlock.startsWith(h1Tag)) {
            // stripPrefix
            return
                string.concat("<h1>", lineBreaksToHtml(textBlock.getSubslice(2, textBlock.len()).toString()), "</h1>");
        }

        if (textBlock.startsWith(h2Tag)) {
            return
                string.concat("<h2>", lineBreaksToHtml(textBlock.getSubslice(3, textBlock.len()).toString()), "</h2>");
        }

        return string.concat("<p>", lineBreaksToHtml(textBlock.toString()), "</p>");
    }

    function lineBreaksToHtml(string memory text) public view returns (string memory) {
        string memory html;
        StrSlice remaining = toSlice(text);
        StrSlice brSeparator = toSlice("\n");

        while (remaining.contains(brSeparator)) {
            (, StrSlice part, StrSlice _remaining) = remaining.splitOnce(brSeparator);
            remaining = _remaining;
            html = string.concat(html, part.toString(), "<br/>");
        }

        return string.concat(html, remaining.toString());
    }

    function promiseTextToHtml(string memory text) public view returns (string memory) {
        string memory html;
        StrSlice remaining = toSlice(text);
        StrSlice blockSeparator = toSlice("\n\n");

        while (remaining.contains(blockSeparator)) {
            (, StrSlice textBlock, StrSlice _remaining) = remaining.splitOnce(blockSeparator);
            remaining = _remaining;
            html = string.concat(html, "\n\n", textBlockToHtml(textBlock));
        }

        return string.concat(html, textBlockToHtml(remaining));
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

interface IERC5192 {
    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 indexed tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 indexed tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HexStrings} from "src/lib/HexStrings.sol";

library AddressUtils {
    using HexStrings for uint160;

    function toString(address value) internal pure returns (string memory) {
        return uint160(value).toHexString(20);
    }

    function toStringNoPrefix(address value) internal pure returns (string memory) {
        return uint160(value).toHexStringNoPrefix(20);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/utils/LibString.sol";
import {StringPad} from "src/lib/StringPad.sol";

interface BokkyPooBahsDateTimeContract {
    function getYear(uint256 timestamp) external pure returns (uint256 year);
    function getMonth(uint256 timestamp) external pure returns (uint256 month);
    function getDay(uint256 timestamp) external pure returns (uint256 day);
}

library DateUtils {
    using LibString for uint256;
    using StringPad for string;

    function formatDate(address bpbDateTimeAddress, uint256 timestamp)
        public
        view
        returns (string memory formattedDate)
    {
        if (bpbDateTimeAddress.code.length == 0) {
            return "";
        }

        BokkyPooBahsDateTimeContract bpbDateTime = BokkyPooBahsDateTimeContract(bpbDateTimeAddress);

        try bpbDateTime.getYear(timestamp) returns (uint256 year) {
            formattedDate = year.toString();
        } catch {
            return "";
        }

        try bpbDateTime.getMonth(timestamp) returns (uint256 month) {
            formattedDate = string.concat(formattedDate, ".", month.toString().padStart(2, "0"));
        } catch {
            return "";
        }

        try bpbDateTime.getDay(timestamp) returns (uint256 day) {
            return string.concat(formattedDate, ".", day.toString().padStart(2, "0"));
        } catch {
            return "";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AddressUtils} from "src/lib/AddressUtils.sol";

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}

interface IENSReverseResolver {
    function name(bytes32 node) external view returns (string memory name);
}

library EnsUtils {
    using AddressUtils for address;

    function nameOrAddress(address registry, address address_) public view returns (string memory) {
        if (registry.code.length == 0) {
            return address_.toString();
        }

        bytes32 node = reverseResolveNameHash(address_);

        address resolverAddress;
        try IENS(registry).resolver(node) returns (address resolverAddress_) {
            if (resolverAddress_.code.length == 0) {
                return address_.toString();
            }
            resolverAddress = resolverAddress_;
        } catch {
            return address_.toString();
        }

        try IENSReverseResolver(resolverAddress).name(node) returns (string memory name) {
            return name;
        } catch {
            return address_.toString();
        }
    }

    function reverseResolveNameHash(address address_) public pure returns (bytes32 namehash) {
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked("reverse"))));
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked("addr"))));
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(address_.toStringNoPrefix()))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// HexStrings.sol from Uniswap v3 (MIT) https://github.com/Uniswap/v3-periphery/blob/6cce88e63e176af1ddb6cc56e029110289622317/contracts/libraries/HexStrings.sol

library HexStrings {
    bytes16 internal constant ALPHABET = "0123456789abcdef";

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library StringPad {
    function padStart(string memory value, uint256 targetLength, string memory padString)
        public
        pure
        returns (string memory paddedValue)
    {
        uint256 diff = targetLength - bytes(value).length;
        if (diff < 1) {
            return value;
        }

        paddedValue = value;
        for (; diff > 0; diff--) {
            paddedValue = string.concat(padString, paddedValue);
        }
        return paddedValue;
    }
}