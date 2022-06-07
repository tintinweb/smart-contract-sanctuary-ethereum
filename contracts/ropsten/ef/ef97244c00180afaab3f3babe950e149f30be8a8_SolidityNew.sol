/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.5.0;
contract SolidityNew {

   address public richest;
   uint public mostSent;

   mapping (address => uint) pendingWithdrawals;

   constructor() public payable {
      richest = msg.sender;
      mostSent = msg.value;
   }
   function becomeRichest() public payable returns (bool) {
      if (msg.value > mostSent) {
         pendingWithdrawals[richest] += msg.value;
         richest = msg.sender;
         mostSent = msg.value;
         return true;
      } else {
         return false;
      }
   }
   function withdraw() public {
      uint amount = pendingWithdrawals[msg.sender];
      pendingWithdrawals[msg.sender] = 0;
      msg.sender.transfer(amount);
   }
}