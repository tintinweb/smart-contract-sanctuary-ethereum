/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonutVendingMachine{
    address public owner;
    mapping(address => uint) public donutBalances;

    constructor(){
        owner = msg.sender;
        donutBalances[address(this)] = 100;
    }

    function getBalance() public view returns (uint) {
        return donutBalances[address(this)];
    }

    function restock(uint amount) public {
        require(msg.sender == owner, "Only owner can restock the donuts!");
        donutBalances[address(this)]+= amount;
    }

    function purchase(uint amount) public payable{
        require(msg.value >= amount * 0.5 ether, "You must pay a minimum of 1 ether for 2 donuts");
        require(donutBalances[address(this)] >= amount, "OOPS! Not enough donuts");
        donutBalances[address(this)] -= amount;
        donutBalances[address(msg.sender)] += amount;
    }
}