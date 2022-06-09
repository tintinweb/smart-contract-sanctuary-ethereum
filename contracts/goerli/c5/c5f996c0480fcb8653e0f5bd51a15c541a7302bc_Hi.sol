/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Hi {
    address public owner;
    address public receiver;

    constructor() {
        owner = msg.sender;
        receiver = msg.sender;
    }

    function deposit() external payable {}

    function totalBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() external isReceiver {
        uint bal = totalBalance();
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    // event for EVM logging
    event Withdraw(address indexed from, uint value);
    
    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    modifier isReceiver() {
        require(msg.sender == receiver, "You are not the receiver");
        _;
    }

    function changeOwner(address newOwner) external isOwner {
        owner = newOwner;
    }

    function changeReceiver(address newReceiver) external isOwner {
        receiver = newReceiver;
    }
}