/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MintToken{
   address public owner;
   mapping(address => uint) public balances;

   constructor(){
      owner = msg.sender;
   }

   function mint(address receiver, uint amount) public {
      require(msg.sender == owner, "You are not the owner"); // Only owner can mint
      balances[receiver] += amount;
   }

   function sent(address receiver, uint amount) public {
      require(amount < balances[msg.sender], "Not enough tokens avaliable");
      balances[msg.sender] -= amount;
      balances[receiver] += amount;
   }
}