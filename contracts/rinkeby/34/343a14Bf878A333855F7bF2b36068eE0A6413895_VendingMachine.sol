/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract VendingMachine {
    address public owner;
    mapping (address => uint) public donutBalances;             // donuts holding per adress

    constructor() {                                             // automatic getter functions for global variables
        owner = msg.sender;                                     // msg => global variable => Address of person who deployed the contract
        donutBalances[address(this)] = 100;                     // intial balance assigned to owner
    }

    function getVendingMachineBalance() public view returns (uint) {           // view => no modification on blockchain, read only (pure => no modification, no read)
        return donutBalances[address(this)];                                   // returns balance of address calling the smart contract
    }             

    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock this machine."); // only owner can increase balance
        donutBalances[address(this)] += amount;
    }

    function purchase(uint amount) public payable {                             // payable => function can receive eth
        require(msg.value >= amount * 0.2 ether, "You must pay at least 0.2 ether per donut");
        require(donutBalances[address(this)] >= amount, "Not enough donuts in stock to fulfill purchase requested");
        
        donutBalances[address(this)] -= amount;
        donutBalances[msg.sender] += amount;
    }
}