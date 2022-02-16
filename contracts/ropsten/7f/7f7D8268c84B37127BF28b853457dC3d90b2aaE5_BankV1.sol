// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract BankV1 {

    event Deposit(address indexed sender, uint256 value);
    mapping(address => uint256) public balances;

    function deposit() external payable{
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}