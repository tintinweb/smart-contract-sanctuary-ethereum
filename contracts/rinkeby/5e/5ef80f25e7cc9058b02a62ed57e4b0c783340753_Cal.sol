/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: GPLv3

pragma solidity >=0.7.0 <0.9.0;

contract Cal {

    uint private sum;

    function add(uint a, uint b) public returns (uint) {
        sum = a + b;
        return sum;
    }

    function mul(uint a, uint b) public returns (uint) {
        sum = a * b;
        return sum;
    }

    function show() public view returns (uint) {
        return sum;
    }
}