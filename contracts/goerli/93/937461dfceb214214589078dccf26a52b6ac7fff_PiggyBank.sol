// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PiggyBank {
    event Deposit(address indexed depositor, uint256 value);
    address public owner = msg.sender;

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not the owner"); 
        selfdestruct(payable(msg.sender));
    }
}