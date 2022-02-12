/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract SimpleBank {
 
   address payable owner;
 
   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }
 
   constructor() {
       owner = payable(msg.sender);
   }
 
   // pay to smart contract
   function payToSmartcontract() external payable {}
   
   // check balance contract balance
   function getContractBalance() public view returns (uint) {
       return address(this).balance;
   }
 
   // transfer to _to address
   function payTo(address payable _to) external payable {
       _to.transfer(msg.value);
   }
 
   // withdraw from smart contract
   // Only owner modifier who can execute transfer
   function withdraw() external payable onlyOwner {
       payable(address(msg.sender)).transfer(address(this).balance);
   }
}