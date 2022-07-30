/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT


pragma solidity =0.8.12;


contract myContract{
    uint256 public num = 1;
    fallback() external{
        num +=10;

    }
    function getNum() public view returns(uint256){
        return num;
    }
}