/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.16;

/// @dev Array function to delete element at index and re-organize the array.
library RemovableStringArray {
    function remove(string[] storage arr, uint256 index) public {
        require(arr.length > 0, "RemovableStringArray: 0");
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }
}