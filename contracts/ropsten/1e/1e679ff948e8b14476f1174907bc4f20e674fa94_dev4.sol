/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract dev4 {
    int256 public a = -45;
    uint8 public b = 150;

    function plus(int256 x) public returns(int256){
        a += x;
        return a;
    }

    function setA(int256 _a) public {
        a = _a;
    }

    function setB(uint8 _b) public {
        b = _b;
    }
}