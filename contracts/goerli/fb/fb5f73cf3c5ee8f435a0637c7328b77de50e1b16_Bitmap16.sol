// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Bitmap16 {
    function readBitAtIndexFromRight(uint16 bitmap, uint256 index) public pure returns (bool value) {
        require(15 >= index, "ERR_OUR_OF_RANGE");
        return (bitmap & (1 << index)) > 0;
    }
}