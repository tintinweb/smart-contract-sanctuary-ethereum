/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.9;

// author:littlefox
contract Lock {

    uint public unlockTime;
    address payable public owner;

    event Withdrawal(uint mount, uint when);

    constructor(uint _unlockTime) payable {
        require(block.timestamp < _unlockTime, "unlock time should be in the future");
        owner = payable(msg.sender);
        unlockTime = _unlockTime;
    }

    function withdraw() public {
        require(block.timestamp >= unlockTime, "you can't withdraw yet");
        require(msg.sender == owner, "you aren't the owner");
        emit Withdrawal(address(this).balance, block.timestamp);
        owner.transfer(address(this).balance);
    }
}