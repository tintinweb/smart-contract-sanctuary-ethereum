/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract simple_storage {
    uint num;

    function store(uint x) public {
        num = x;
    }

    function retrieve() public view returns (uint) {
        return num;
    }
}