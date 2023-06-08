// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WithdrawalContract {
    address private owner;
    uint public contractBalance;

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        contractBalance += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        contractBalance = 0;
        payable(msg.sender).transfer(address(this).balance);
    }
}