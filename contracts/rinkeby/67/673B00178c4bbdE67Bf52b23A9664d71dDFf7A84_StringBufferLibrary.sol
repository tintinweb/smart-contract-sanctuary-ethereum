//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Holds a string that can expand dynamically.
 */
struct StringBuffer {
    string[] buffer;
    uint numberOfStrings;
    uint totalStringLength;
}

library StringBufferLibrary {
    /**
     * @dev Copies 32 bytes of `src` starting at `srcIndex` into `dst` starting at `dstIndex`.
     */
    function memcpy32(string memory src, uint srcIndex, bytes memory dst, uint dstIndex) internal pure {
        assembly {
            mstore(add(add(dst, 32), dstIndex), mload(add(add(src, 32), srcIndex)))
        }
    }

    /**
     * @dev Copies 1 bytes of `src` at `srcIndex` into `dst` at `dstIndex`.
     *      This uses the same amount of gas as `memcpy32`, so prefer `memcpy32` if at all possible.
     */
    function memcpy1(string memory src, uint srcIndex, bytes memory dst, uint dstIndex) internal pure {
        assembly {
            mstore8(add(add(dst, 32), dstIndex), shr(248, mload(add(add(src, 32), srcIndex))))
        }
    }

    /**
     * @dev Copies a string into `dst` starting at `dstIndex` with a maximum length of `dstLen`.
     *      This function will not write beyond `dstLen`. However, if `dstLen` is not reached, it may write zeros beyond the length of the string.
     */
    function copyString(string memory src, bytes memory dst, uint dstIndex, uint dstLen) internal pure returns (uint) {
        uint srcIndex;
        uint srcLen = bytes(src).length;

        for (; srcLen > 31 && srcIndex < srcLen && srcIndex < dstLen - 31; srcIndex += 32) {
            memcpy32(src, srcIndex, dst, dstIndex + srcIndex);
        }
        for (; srcIndex < srcLen && srcIndex < dstLen; ++srcIndex) {
            memcpy1(src, srcIndex, dst, dstIndex + srcIndex);
        }

        return dstIndex + srcLen;
    }

    /**
     * @dev Adds `str` to the end of the internal buffer.
     */
    function pushToStringBuffer(StringBuffer memory self, string memory str) internal pure returns (StringBuffer memory) {
        if (self.buffer.length == self.numberOfStrings) {
            string[] memory newBuffer = new string[](self.buffer.length * 2);
            for (uint i = 0; i < self.buffer.length; ++i) {
                newBuffer[i] = self.buffer[i];
            }
            self.buffer = newBuffer;
        }

        self.buffer[self.numberOfStrings] = str;
        self.numberOfStrings++;
        self.totalStringLength += bytes(str).length;

        return self;
    }

    /**
     * @dev Concatenates `str` to the end of the last string in the internal buffer.
     */
    function concatToLastString(StringBuffer memory self, string memory str) internal pure {
        if (self.numberOfStrings == 0) {
            self.numberOfStrings++;
        }
        uint idx = self.numberOfStrings - 1;
        self.buffer[idx] = string(abi.encodePacked(self.buffer[idx], str));

        self.totalStringLength += bytes(str).length;
    }

    /**
     * @notice Creates a new empty StringBuffer
     * @dev The initial capacity is 16 strings
     */
    function empty() external pure returns (StringBuffer memory) {
        return StringBuffer(new string[](16), 0, 0);
    }

    /**
     * @notice Converts the contents of the StringBuffer into a string.
     * @dev This runs in O(n) time.
     */
    function get(StringBuffer memory self) internal pure returns (string memory) {
        bytes memory output = new bytes(self.totalStringLength);

        uint ptr = 0;
        for (uint i = 0; i < self.numberOfStrings; ++i) {
            ptr = copyString(self.buffer[i], output, ptr, self.totalStringLength);
        }

        return string(output);
    }

    /**
     * @notice Appends a string to the end of the StringBuffer
     * @dev Internally the StringBuffer keeps a `string[]` that doubles in size when extra capacity is needed.
     */
    function append(StringBuffer memory self, string memory str) internal pure {
        uint idx = self.numberOfStrings == 0 ? 0 : self.numberOfStrings - 1;
        if (bytes(self.buffer[idx]).length + bytes(str).length <= 1024) {
            concatToLastString(self, str);
        } else {
            pushToStringBuffer(self, str);
        }
    }
}