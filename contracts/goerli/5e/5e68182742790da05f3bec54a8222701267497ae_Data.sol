/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Data {
    uint constant luckyNum = 7;
    uint num;

    function addluck() public {
        num += luckyNum;
    }

    function viewNum() public view returns (uint) {
        return num;
    }
}