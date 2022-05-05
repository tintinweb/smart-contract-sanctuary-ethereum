/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    uint256 public _test = 0;
    constructor(uint256 test){
        _test = test;
    }

    function setTest(uint256 test) public{
        _test = test;
    }
}