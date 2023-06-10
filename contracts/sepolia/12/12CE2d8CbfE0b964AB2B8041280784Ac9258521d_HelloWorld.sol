/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract HelloWorld {

   string public message;

   constructor(string memory initMessage) {

      message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
   }
}