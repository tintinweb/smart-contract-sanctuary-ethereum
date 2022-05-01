pragma solidity ^0.7.0;

contract Invest {
   string public message;

   constructor(string memory initMessage) {
      message = initMessage;
   }

   function update(string memory newMessage) public {
      message = newMessage;
   }
}