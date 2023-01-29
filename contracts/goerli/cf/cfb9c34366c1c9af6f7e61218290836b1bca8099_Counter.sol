/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: GPL-3.0
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