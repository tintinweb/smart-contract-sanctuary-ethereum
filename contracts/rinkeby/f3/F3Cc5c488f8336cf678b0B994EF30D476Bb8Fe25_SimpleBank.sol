/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.11; 

contract SimpleBank {   
   address payable public owner; 

   constructor () {   
     owner = payable(msg.sender);   
   } 

   function sendMoney () public payable {   
   } 

   function sendMoneyTo (uint _amount, address _to) public payable {
     payable(_to).transfer(_amount);   
   } 

   function withdrawMoney(uint _amount) external {   
     require(msg.sender==owner,"Only owner can do this."); 
     payable(msg.sender).transfer(_amount);   
   } 

   function getBalance () external view returns (uint) {   
     return address(this).balance;   
   }

}