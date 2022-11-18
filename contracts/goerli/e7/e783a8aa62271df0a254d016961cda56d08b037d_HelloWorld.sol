/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

pragma solidity ^0.8.17;

contract HelloWorld {

   string public message;

    constructor(string memory initMessage) public {

      message = initMessage;
    }

   function update(string memory newMessage) public {
      message = newMessage;
   }
}