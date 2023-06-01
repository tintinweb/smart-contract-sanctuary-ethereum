/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
contract Counter {
   uint8 public variable;
 
   constructor() {
       variable = 5;
   }
   function decrement() public {
       variable--;
   }
   function increment() public {
       variable++;
   }
}