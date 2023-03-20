/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;


contract HelloWorldCounter {
   uint256 public counter = 0;


   function say_hello() pure public returns(string memory) {
       return "Hello World!";
   }
   function increase_counter() public {
       counter = counter + 1;
   }

   function decrease_counter() public {
       counter = counter - 1;
   }
}