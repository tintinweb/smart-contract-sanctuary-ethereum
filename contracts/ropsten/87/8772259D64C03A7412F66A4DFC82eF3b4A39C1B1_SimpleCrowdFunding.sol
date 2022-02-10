/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract SimpleCrowdFunding{
    uint public balance=0;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    event DonateEvent(address donater ,uint money);

    function Donate()public payable{
        balance+=msg.value;
        emit DonateEvent(msg.sender,msg.value);
    }

    function getMoney()public {
        require(msg.sender==owner,"You aren't a owner.");
        payable(owner).transfer(balance);
        balance=0;
    }
}