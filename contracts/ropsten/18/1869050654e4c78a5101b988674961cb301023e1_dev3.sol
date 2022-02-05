/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract dev3 {
    int256 public a = -45;
    uint8 public b = 150;

    function plus(int256 x) public view returns(int256){
        return a + x;
    }
}