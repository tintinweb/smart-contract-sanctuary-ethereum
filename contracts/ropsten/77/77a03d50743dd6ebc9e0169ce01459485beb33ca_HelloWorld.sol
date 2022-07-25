/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

pragma solidity ^0.4.24;

contract HelloWorld {

   string public message;

   constructor (string memory initMessage) {
      message = initMessage;
   }

   function update (string memory newMessage) public {
      message = newMessage;
   }

}