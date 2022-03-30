/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Sample {
    function makeSum(uint256 loopCount) public pure returns (uint256){
        uint256 sum = 0;
        for (uint256 i = 0; i < loopCount; i++) {
            sum += i;
        }
        return sum;
    }
    function makeArray(uint256 loopCount) public pure returns (uint256[] memory){
        uint256[] memory resultArray = new uint256[](loopCount);
        for (uint256 i = 0; i < loopCount; i++) {
            resultArray[i] = loopCount - i;
        }
        return resultArray;
    }
}