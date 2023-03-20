// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Faucet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {}

    function transfer(address payable recipient, uint256 amount) public {
        require(msg.sender == owner, "Only contract owner can call this function");
        require(address(this).balance >= amount, "Insufficient balance");
        recipient.transfer(amount);
    }

    function airDrop(address payable[] memory recipients, uint256[] memory amounts) public payable {
        require(msg.sender == owner, "Only contract owner can call this function.");
        require(recipients.length == amounts.length, "Recipients and amounts arrays must have the same length.");
        require(address(this).balance >= msg.value, "Insufficient contract balance.");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amounts[i]);
        }
    }

    function airDrop(address payable[] memory recipients) public payable {
        require(msg.sender == owner, "Only contract owner can call this function.");
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(msg.value/recipients.length);
        }
    }

    function mint() payable public{}

    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Only contract owner can call this function.");
        require(amount <= address(this).balance, "Insufficient contract balance.");
        payable(owner).transfer(amount);
    }

    function withdraw() payable public {
        require(msg.sender == owner, "Only contract owner can call this function.");
        require(msg.value <= address(this).balance, "Insufficient contract balance.");
        payable(owner).transfer(msg.value);
    }
}