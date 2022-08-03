// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract Quicksort {
    
    // mostly copied from https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol
    struct slice {
        uint _len;
        uint _ptr;
    }

    function _toSlice(uint256[] memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(self.length * 32, ptr);
    }

    function _memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function _quicksortHelper(uint256[] memory input, uint start, uint len, uint256 rand)
        internal pure returns (uint256[] memory result) {
        result = new uint256[](len); 
        // trivial cases
        if (len == 0) return result;
        if (len == 1) { result[0] = input[start]; return result; }
        uint pivotIdx = rand % (len - 1) + 1; // find a random pivot
        uint256 pivotVal = input[start + pivotIdx];
        uint j;
        uint k;
        for (uint i = start; i < start + len; ++i) {
            if (start + pivotIdx == i) continue;
            if (input[i] >= pivotVal) {
                result[j++] = input[i];
            } else {
                result[len - 1 - k++] = input[i];
            }
        }
        slice memory resultS = _toSlice(result);
        slice memory smallerSorted = _toSlice(_quicksortHelper(result, 0, j, rand));
        slice memory biggerSorted =  _toSlice(_quicksortHelper(result, j + 1, k, rand));
        result[j] = pivotVal;
        _memcpy(resultS._ptr, smallerSorted._ptr, smallerSorted._len);
        _memcpy(resultS._ptr + smallerSorted._len + 32, biggerSorted._ptr, biggerSorted._len);
        return result;
    }

    function quicksortTest1(uint n) public view returns (
            uint256[] memory seq,
            uint256[] memory result) {
        seq = new uint256[](n);
        for (uint i = 0; i < n; ++i) seq[i] = random(i, 1000);
        result = _quicksortHelper(seq, 0, n, random(0, type(uint256).max));
    }

    function quicksortTest2(uint n) public {
        quicksortTest1(n);
    }

    function random(uint seed, uint mod) private view returns (uint256) {
        uint randomHash = uint(keccak256(abi.encode(block.difficulty, seed)));
        return randomHash % mod;
    }
}