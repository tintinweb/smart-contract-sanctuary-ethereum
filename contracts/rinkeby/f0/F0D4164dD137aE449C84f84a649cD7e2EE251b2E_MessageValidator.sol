//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {StringUtil} from "./util/StringUtil.sol";
import {IMessageValidator} from "./interface/IMessageValidator.sol";

/**
 * @dev Validation
 */
contract MessageValidator is IMessageValidator {
    using StringUtil for *;

    uint16 private _maxLenPerRow;
    uint16 private _maxRows;
    uint16 private _maxPages;

    constructor(
        uint16 maxLenPerRow,
        uint16 maxRows,
        uint16 maxPages
    ) {
        _maxLenPerRow = maxLenPerRow;
        _maxRows = maxRows;
        _maxPages = maxPages;
    }

    function validate(string memory _msg)
        external
        view
        override
        returns (Result memory)
    {
        if (!_isAllowedInput(_msg)) {
            return _asResult(false, "Validator: Invalid character found");
        }
        StringUtil.slice memory messageSlice = _msg.toSlice();
        // ページ数チェック / Check the numer of pages
        StringUtil.slice memory FF = "\x0c".toSlice();
        uint16 fFCount = uint16(messageSlice.count(FF));
        if (!(fFCount >= 0 && fFCount <= _maxPages - 1)) {
            return _asResult(false, "Validator: Too many pages");
        }

        // 各ページに対するチェック / Check for each page
        // 全体の文字数は行数と行あたりの文字数のチェックによって担保
        StringUtil.slice memory LF = "\n".toSlice();
        StringUtil.slice memory SPACE = " ".toSlice();

        uint16 lFCount;
        uint16 whiteSpaceCount;
        StringUtil.slice memory lhPage;
        StringUtil.slice memory lh;

        for (uint16 i = 0; i <= fFCount; i++) {
            lhPage = messageSlice.split(FF);
            // 空ページチェック
            if (lhPage._len == 0) {
                return _asResult(false, "Validator: Empty page");
            }
            // 行数のチェック
            lFCount = uint16(lhPage.count(LF));
            if (!(lFCount >= 0 && lFCount <= _maxRows - 1)) {
                return _asResult(false, "Validator: Too many rows");
            }
            // 改行/半角スペースのみは許可しない
            whiteSpaceCount = uint16(lhPage.count(SPACE));
            if (lFCount + whiteSpaceCount == lhPage._len) {
                return
                    _asResult(
                        false,
                        "Validator: Only line breaks or spaces are not allowed"
                    );
            }
            // 行あたりの文字数のチェック
            // 改行なしの場合は `split` では対応できないの先にチェック
            if (lFCount == 0) {
                if (lhPage._len > _maxLenPerRow) {
                    return _asResult(false, "Validator: Too long row");
                }
            }
            for (uint16 j = 0; j <= lFCount; j++) {
                lh = lhPage.split(LF);
                if (lh._len > _maxLenPerRow) {
                    return _asResult(false, "Validator: Too long row");
                }
            }
        }
        return _asResult(true, "");
    }

    function _asResult(bool isValid, string memory message)
        private
        pure
        returns (Result memory)
    {
        return Result({ isValid: isValid, message: message });
    }

    // Allowed characters: ^[[email protected]#$%&-+=/.,'<>*~:;\"()^ \n\f]+$
    function _isAllowedChar(bytes1 c) private pure returns (bool) {
        return (c[0] == bytes1(uint8(10)) || // 0x0a
            c[0] == bytes1(uint8(12)) || // 0x0c
            (c[0] >= bytes1(uint8(32)) && c[0] <= bytes1(uint8(90))) || // 0x20 .. 0x5a
            c[0] == bytes1(uint8(94)) || // 0x5e
            c[0] == bytes1(uint8(126))); // 0x7e
    }

    function _isAllowedInput(string memory input) private pure returns (bool) {
        bytes memory inputBytes = bytes(input);
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (!_isAllowedChar(inputBytes[i])) {
                return false;
            }
        }
        return true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/**
 * @dev Message Validation Interface
 */
interface IMessageValidator {
    /**
     * @dev Validation Result.
     * Contains the result and error message. If the given string value is valid, `message` should be empty.
     */
    struct Result {
        bool isValid;
        string message;
    }

    /**
     * @dev Validates given string value and returns validation result.
     */
    function validate(string memory _msg) external view returns (Result memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library StringUtil {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 _len
    ) private pure {
        // Copy word-length chunks while possible
        for (; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - _len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle)
        internal
        pure
        returns (uint256)
    {
        uint256 cnt = 0;
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
        return cnt;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }
}