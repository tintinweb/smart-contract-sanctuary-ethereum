/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract VendingMachine{
    address public owner;
    mapping(address => uint) public donutBalances;

    constructor(){
        owner = msg.sender;
        donutBalances[address(this)] = 100;
    }
    
    function getVendingMachineBalance() public view returns (uint) {
        return donutBalances[address(this)];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function purchase(uint amount) public payable {
        require(msg.value >= amount * 2 ether, "You must pay at least 2 ETH per donut");
        require(donutBalances[address(this)] >= amount, "Not enough donuts in stock to complete this purchase");
        donutBalances[address(this)] -= amount;
        donutBalances[msg.sender] += amount;
    }

    function reStock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock this machine.");
        donutBalances[address(this)] += amount;
    }

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "Only owner can withdraw the funds!");
        payable(msg.sender).transfer(_amount);
    } 
}