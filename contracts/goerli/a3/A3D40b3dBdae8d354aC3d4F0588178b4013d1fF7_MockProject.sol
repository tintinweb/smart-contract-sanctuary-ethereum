//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockProject {

    event Deposit(address indexed user, uint8 tableId);

    constructor() {}

    function deposit(uint8 tableId) external {
        emit Deposit(msg.sender, tableId);
    }
}