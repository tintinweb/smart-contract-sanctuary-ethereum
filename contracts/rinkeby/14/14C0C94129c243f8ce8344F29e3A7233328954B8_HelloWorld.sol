/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

/**
 * Sample test from "HelloWorld tutorial"
*/

pragma solidity ^0.8.12;

contract HelloWorld {

   event UpdatedMessages(string oldStr, string newStr);

   string public message;

   constructor(string memory initMessage) {

      message = initMessage;
   }

   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}