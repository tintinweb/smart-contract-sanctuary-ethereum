/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CrowdFunding {
    uint public balance = 0;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    event DonateEvent(address donator ,uint money);

    function donate() public payable {
        require(msg.value > 0, "Amount must more than 0.");
        balance += msg.value;
        emit DonateEvent(msg.sender, msg.value);
    }

    function getFund() public {
        require(msg.sender == owner, "Only owner can be receive");
        payable(owner).transfer(balance);
        balance = 0;
    }
}