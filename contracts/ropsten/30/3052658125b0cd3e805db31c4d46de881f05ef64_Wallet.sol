/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Wallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function sendFunds(uint _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }
}