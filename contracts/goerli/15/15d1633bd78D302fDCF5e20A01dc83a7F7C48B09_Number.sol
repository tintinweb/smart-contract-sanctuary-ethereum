/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

//interfaces

//libraries

//contracts

contract Number {
    uint internal num;

    //events
    //errors
    error UnsafeDecrement();

    //storage

    constructor(uint _num) {
        num = _num;
    }

    //fallback

    //functions
    function increment() external {
        num++;
    }

    function decrement(uint _num) external {
        num -= _num;
    }

    function getNum() external view returns (uint) {
        return num;
    }
}