/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
contract Lock {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Troniex";
    string public symbol = "Tnx";
    uint8 public decimals = 18;
}