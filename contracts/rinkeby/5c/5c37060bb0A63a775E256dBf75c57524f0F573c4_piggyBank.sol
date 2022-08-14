// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract piggyBank {

    address public owner;

    modifier onlyOwner(){
        require(owner == msg.sender, "Not owner of this fund.");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    event Receive(uint indexed amount);
    event Withdraw(uint indexed amount);
    
    receive() external payable{
        emit Receive(msg.value);
    }

    function withdraw() external onlyOwner payable{
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }
}