/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: UNLICENSED
// Doing a youtube example for learning purposes.

pragma solidity 0.8.9;

contract HelloWorld {
   event UpdatedMessages(string oldStr, string newstr);

   string public message;

   constructor (string memory initMessage) {
      message = initMessage;
   }

   function update(string memory NewMessage) public {
      string memory OldMessage = message;
      message = NewMessage;
      emit UpdatedMessages(OldMessage,NewMessage);
   }

}