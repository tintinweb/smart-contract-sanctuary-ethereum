// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;




contract WhatIsTimeDeposit {

    event Deposit(address indexed from, address indexed to, uint256 indexed amount);

    address immutable owner = 0x334e503aec46D57E1E2b3B4f754F387895F0197c;

    function BuyTime() external payable {
        emit Deposit(msg.sender, owner, msg.value);
    }
}