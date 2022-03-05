//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract PiggyBank {

    address public owner = msg.sender; 
    event Deposit(uint amount, address depositer);
    event Withdraw(uint amount);

    receive() external payable {
    emit Deposit(msg.value, msg.sender);
    }

    function withdraw() external {
        require (msg.sender == owner, "not owner");
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }
}