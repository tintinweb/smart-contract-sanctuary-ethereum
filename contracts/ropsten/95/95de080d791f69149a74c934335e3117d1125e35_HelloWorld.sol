/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.4;

contract HelloWorld {
   event UpdatedMessages(string oldStr, string newStr);
   string public _message;

   constructor(string memory initMessage) {
      _message = initMessage;
   }

   function update(string memory newMessage) public {
      string memory oldMsg = _message;
      _message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}