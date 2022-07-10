/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;
contract HelloWorld {

   string public message;

   constructor(string memory initMessage) public {
      message = initMessage;
   }

   function setMessage(string memory newMessage) public {
      message = newMessage;
      }
    function getMessage()public view returns(string memory){
        return message;
    }
}