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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {StrSlice, toSlice} from "dk1a-stringutils/StrSlice.sol";

library StringReplace {
    function replace(string memory text, string memory pattern, string memory replacement)
        public
        view
        returns (string memory result)
    {
        StrSlice remaining = toSlice(text);
        StrSlice patternSeparator = toSlice(pattern);

        while (remaining.contains(patternSeparator)) {
            (, StrSlice part, StrSlice _remaining) = remaining.splitOnce(patternSeparator);
            remaining = _remaining;
            result = string.concat(result, part.toString(), replacement);
        }

        result = string.concat(result, remaining.toString());
    }
}