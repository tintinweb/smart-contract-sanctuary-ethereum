/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

// starts the contract
contract VendingMachine {
//
    address public owner;
    mapping (address => uint) public donutBalances;

    constructor() {
        owner = msg.sender;
        donutBalances[address(this)] = 100;
    }
    function getVendingMachineBalance() public view returns (uint) {
return donutBalances[address(this)];
    }

    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock the machine");
        donutBalances[address(this)] += amount;
    }
function purchase(uint amount) public payable {
    require(msg.value >= amount * 0.001 ether, "You must pay at least 2 ether per donut");
    require(donutBalances[address(this)] >= amount, "Not enough donuts in stock to fulfil purchase request");
    donutBalances[address(this)] -= amount;
    donutBalances[msg.sender] += amount;
}

}