// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

contract EfficientQuicksort {
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
}

contract SuccinctQuicksort {
    uint256[] public seq;

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
            if (start + pivotIdx == i) continue; // simple way skip the pivotIdx
            if (input[i] >= pivotVal) {
                result[j++] = input[i];
            } else {
                result[len - 1 - k++] = input[i];
            }
        }
        result[j] = pivotVal;
        uint256[] memory smallerSorted = _quicksortHelper(result, 0, j, rand);
        uint256[] memory biggerSorted =  _quicksortHelper(result, j + 1, k, rand);
        for (uint i = 0; i < j; ++i) result[i] = smallerSorted[i];
        for (uint i = 0; i < k; ++i) result[j + 1 + i] = biggerSorted[i];
        return result;
    }

    function genRandomSeq(uint n, uint range) public {
        delete seq;
        for (uint i = 0; i < n; ++i) seq.push(random(i, range));
    }

    function quicksortTest1() public view returns (uint256[] memory result) {
        result = _quicksortHelper(seq, 0, seq.length, random(0, type(uint256).max));
    }

    function quicksortTest2() public {
        quicksortTest1();
    }

    function random(uint seed, uint mod) private view returns (uint256) {
        uint randomHash = uint(keccak256(abi.encode(block.difficulty, seed)));
        return randomHash % mod;
    }
}