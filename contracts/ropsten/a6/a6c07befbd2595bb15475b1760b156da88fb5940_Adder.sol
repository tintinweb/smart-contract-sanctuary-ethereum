/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Adder {
    uint public l;
    uint public r;
    uint public sum;

    function add(uint l_, uint r_) external returns (uint) {
        l = l_;
        r = r_;
        sum = l_ + r_;
        return sum;
    }
}