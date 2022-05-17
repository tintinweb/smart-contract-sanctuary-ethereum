/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract calc {
    int private num;
    function add(int a , int b) public returns (int) {
        num = a + b;
        return num;
    }
    
}