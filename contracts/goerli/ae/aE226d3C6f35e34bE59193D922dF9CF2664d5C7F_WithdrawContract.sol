/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WithdrawContract {
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function withdraw(uint amount, address payable recipient) public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        require(address(this).balance >= amount, "Insufficient balance in contract");

        recipient.transfer(amount);
    }
}