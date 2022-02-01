// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Wallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    receive() external payable {}

    function sendFunds(uint _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function getBal() external view returns (uint) {
        return address(this).balance;
    }
}