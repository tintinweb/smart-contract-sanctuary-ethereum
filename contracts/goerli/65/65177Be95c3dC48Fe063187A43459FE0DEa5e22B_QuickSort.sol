// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Source: https://gist.github.com/Amxx/d3a99fcb79abbe3c76a2f2a5773b3815
library QuickSort {
    function sort(uint256[] memory array) public pure returns (uint256[] memory) {
        _quickSort(array, 0, array.length);
        return array;
    }

    function _quickSort(uint256[] memory array, uint256 i, uint256 j) private pure {
        if (j - i < 2) return;

        uint256 p = i;
        for (uint256 k = i + 1; k < j; ++k) {
            if (array[i] > array[k]) {
                _swap(array, ++p, k);
            }
        }
        _swap(array, i, p);
        _quickSort(array, i, p);
        _quickSort(array, p + 1, j);
    }

    function _swap(uint256[] memory array, uint256 i, uint256 j) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }
}