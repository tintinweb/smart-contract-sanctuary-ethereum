/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// Sources flattened with hardhat v2.12.4 https://hardhat.org

// File contracts/CokeMachine.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


contract CokeMachine{

    // state variables
    address public owner;
    mapping (address => uint) public cokeBalances;

    modifier onlyOwner(){
        require(owner==msg.sender,"Not the owner");
        _;
    }

    // set the owner as th address that deployed the contract
    // set the initial vending machine balance to 100
    constructor() {
        owner = msg.sender;
        cokeBalances[address(this)] = 100;
    }

    function getVendingMachineBalance() public view returns (uint) {
        return cokeBalances[address(this)];
    }

    // Let the owner restock the vending machine
    function restock(uint amount) public onlyOwner{
        require(msg.sender == owner, "Only the owner can restock.");
        cokeBalances[address(this)] += amount;
    }

    // Purchase cokes from the vending machine
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 0.001 ether, "You must pay at least 0.001 ETH per donut");
        require(cokeBalances[address(this)] >= amount, "Not enough donuts in stock to complete this purchase");
        cokeBalances[address(this)] -= amount;
        cokeBalances[msg.sender] += amount;
    }
}