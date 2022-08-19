/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PiggyBank {
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Not owner of this fund.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    event Receive(uint indexed amount);
    event Withdraw(uint indexed amount);

    receive() external payable {
        emit Receive(msg.value);
    }

    function withdraw() external payable onlyOwner {
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }
}