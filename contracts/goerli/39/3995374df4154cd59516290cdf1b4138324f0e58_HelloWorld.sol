/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
contract HelloWorld {

   string message;

   constructor() {
       message = "Hello to me";
   }

   function sayTheMessage() public view returns (string memory) {
       return message;
   }

   function changeMessage(string memory _message) public {
       message = _message;
   }
}