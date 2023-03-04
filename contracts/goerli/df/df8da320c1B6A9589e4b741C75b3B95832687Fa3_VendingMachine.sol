/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract VendingMachine {

    // contract deployer
    address public owner;
    mapping (address => uint) public donutBalances;

    constructor() {
        owner = msg.sender; // contract deployer address
        donutBalances[address(this)] = 100;
    }

    // view : cannot modify but read data from blockchain vs. pure : cannot modify and read data from blockchain
    function getVendingMachineBalance() public view returns (uint) {
        return donutBalances[address(this)];
    }

    // no restriction : need to modify data
    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock this machine.");
        donutBalances[address(this)] += amount;
    }

    // payable : need to receive ETH
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 100000000000000000 wei, "You must pay at least 100,000,000,000,000,000 wei per donut.");
        require(donutBalances[address(this)] >= amount, "Not enough donuts in stock to fulfill your purchase request.");
        donutBalances[address(this)] -= amount;
        donutBalances[msg.sender] += amount;
    }
}