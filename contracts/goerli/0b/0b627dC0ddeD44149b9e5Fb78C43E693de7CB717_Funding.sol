// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Funding {
    mapping(address => uint256) public funds;

    event Deposit(address token, uint256 amount);
    event Withdrawal(address token, uint256 amount);

    function deposit(address token, uint256 amount) public {
        funds[token] += amount;
        emit Deposit(token, amount);
    }

    function withdraw(address token, uint256 amount) public {
        require(funds[token] >= amount, "funds not enough!");
        funds[token] -= amount;
        emit Withdrawal(token, amount);
    }
}