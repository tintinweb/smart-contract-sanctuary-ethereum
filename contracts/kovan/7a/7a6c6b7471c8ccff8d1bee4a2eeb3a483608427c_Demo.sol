/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
 
contract Demo {
   address payable public owner;
   mapping (address => uint) accountAllowances;
   mapping (address => uint) accountAmounts;
   mapping (address => uint) accountDebts;
 
   event Log(address from, string operation, uint amount);
 
   constructor() {
       owner = payable(msg.sender);
   }
 
   receive() external payable {}

    function deposits() external payable {
       accountAmounts[msg.sender] = multiplyByRate(msg.value);
       emit Log(msg.sender, "deposits", msg.value);
   }
 
   function withdraw(uint amount) external payable {
       require(accountAmounts[msg.sender] >= amount, "Balance is not enough");
       accountAmounts[msg.sender] -= amount;
       payable(msg.sender).transfer(amount);
       emit Log(msg.sender, "withdraw", msg.value);
   }
 
   function borrow(uint amount) external payable {
       require(accountAllowances[msg.sender] >= amount, "Need approve");
       accountAllowances[msg.sender] -= amount;
       accountDebts[msg.sender] += multiplyByRate(amount);
       payable(msg.sender).transfer(amount);
       emit Log(msg.sender, "borrow", msg.value);
   }
 
   function payBack() external payable {
       accountDebts[msg.sender] -= msg.value;
       emit Log(msg.sender, "payBack", msg.value);
   }
 
   function getContractBalance() external view returns (uint) {
       return address(this).balance;
   }
 
   function getBalance() external view returns (uint) {
       return accountAmounts[msg.sender];
   }
 
   function getAllowance() external view returns (uint) {
       return accountAllowances[msg.sender];
   }
 
   function getDebt() external view returns (uint) {
       return accountDebts[msg.sender];
   }
 
   function approve(address user, uint amount) external payable {
       require(msg.sender == owner, "Need permission");
       accountAllowances[user] = amount;
       emit Log(user, "approve", msg.value);
   }
 
   function multiplyByRate(uint amount) internal pure returns (uint) {
       return amount / 10 * 11;
   }
}