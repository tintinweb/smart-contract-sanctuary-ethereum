/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract VendingMachine {

    address public owner;
    mapping (address => uint) public donutBalances;

    constructor() {
        owner = msg.sender;
        donutBalances[address(this)] = 100;
    }

    function getVendingMachineBalance () public view returns (uint) {
        return donutBalances[address(this)];
    }

    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner of VM can restock VM!");
        donutBalances[address(this)] += amount;
    }

    function purchase(uint donutAmount) public payable { // payable for function that needs to have ability for receiving eth
        require(msg.value >= donutAmount * 0.02 ether, "You must pay at least 0,02 ether per donut!"); //msg.value represents eth value send to this function
        require(donutBalances[address(this)] >= donutAmount, "Not enough donuts.");
        donutBalances[address(this)] -= donutAmount;
        donutBalances[msg.sender] += donutAmount; //here msg.sender represents a address of someone who call this function
    }

}