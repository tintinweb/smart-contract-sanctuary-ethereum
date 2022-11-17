/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Bank {
    event Receive(address indexed donater, uint amount);
    event Withdraw(address indexed owner, uint amount);

    address owner;
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }
    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
    function showMoney() view public returns(uint) {
        return address(this).balance;
    }
    function withdraw() external payable onlyOwner {
        address payable Receiver = payable(owner);
        uint amount = address(this).balance;
        Receiver.transfer(amount);
        emit Withdraw(owner, amount);
    }
}