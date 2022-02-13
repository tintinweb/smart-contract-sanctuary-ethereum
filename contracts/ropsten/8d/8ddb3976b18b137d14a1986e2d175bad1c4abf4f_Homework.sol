/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;contract Homework {
mapping(address => string) public submitters;
function store(string memory BSON352116) public {
submitters[msg.sender] = BSON352116;
}
}