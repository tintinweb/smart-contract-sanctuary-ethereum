// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;




contract WhatIsTimeDeposit {

    event Deposit(address indexed from, address indexed to, uint256 indexed amount);

    address immutable owner = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

    function BuyTime() external payable {
        require(msg.value > 0);
        owner.call{value: msg.value};
        emit Deposit(msg.sender, owner, msg.value);
    }
}