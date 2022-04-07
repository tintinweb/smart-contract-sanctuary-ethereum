/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
contract balance {
    address owner;
    uint a = 0;
    uint b = 1;
    mapping(address => uint) public balanc;
    function balancecosh() public returns (uint) {
    a = a + b;
    return a;
    }
}