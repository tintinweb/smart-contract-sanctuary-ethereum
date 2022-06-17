// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;




contract WhatIsTimeDeposit {

    event Deposit(address indexed from, address indexed to, uint256 indexed amount);

    address immutable owner = 0x3aF62191AEAdDE80188d86597fB57CaDaA919DdF;

    function BuyTime(uint256 amount) external payable {
        emit Deposit(msg.sender, owner, amount);
    }
}