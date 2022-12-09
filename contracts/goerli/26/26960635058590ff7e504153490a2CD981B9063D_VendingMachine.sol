/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract VendingMachine {
      
      // state variables
    address public owner;
    mapping (address => uint) public candyBalances;

    // set the owner as th address that deployed the contract
    // set the initial vending machine balance to 100
    constructor() {
        owner = msg.sender;
        candyBalances[address(this)] = 100;
    }

    function getMachineBalance() public view returns (uint) {
        return candyBalances[address(this)];
    }

    // Let the owner restock the vending machine
    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock.");
        candyBalances[address(this)] += amount;
    }

    // Purchase donuts from the vending machine
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 ether, "You must pay at least 1 ETH per candy");
        require(candyBalances[address(this)] >= amount, "Not enough candy in stock to complete this purchase");
        candyBalances[address(this)] -= amount;
        candyBalances[msg.sender] += amount;
    }
}