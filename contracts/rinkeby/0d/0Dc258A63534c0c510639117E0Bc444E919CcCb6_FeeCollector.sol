/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract FeeCollector { // 0x128e31e1549b2d706023E67a967aa7A05ad6c654
    address public owner;
    uint256 public balance;

    constructor() {
        owner = msg.sender;
    }

    receive() payable external {
        balance += msg.value;
    }
}