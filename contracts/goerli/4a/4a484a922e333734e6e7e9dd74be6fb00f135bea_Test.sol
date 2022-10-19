// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Test {

    mapping(address => uint256) public values;

    event ValueUpdated(address indexed setter, uint256 value);
    event Withdrawal(address indexed withdrawer, uint256 amount, uint256 when);

    function set(uint256 value) public {
        values[msg.sender] = value;
        emit ValueUpdated(msg.sender, value);
    }

    function withdraw(uint amount) public {
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount, block.timestamp );
    }
}