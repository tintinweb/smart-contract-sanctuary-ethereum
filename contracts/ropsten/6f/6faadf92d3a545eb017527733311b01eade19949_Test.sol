/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {

    uint test = 0;

    function uslessShift(uint32 value) external{
        test++;
        twentyPercentOfWithShift(value);
    }

    function uslessMul(uint32 value) external{
        test++;
        twentyPercentOfWithMult(value);
    }

    function twentyPercentOfWithShift(uint32 value) public pure returns (uint256) {
        return (value << 1) / 10;
    }

    function twentyPercentOfWithMult(uint32 value) public pure returns (uint256) {
        return (value * 2) / 10;
    }
}