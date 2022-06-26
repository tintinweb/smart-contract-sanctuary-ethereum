/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Loan {

   address admin;
   uint age;

   constructor() {
      admin = msg.sender;
    }
   function getMsgSender() public view returns(address){
      return admin;
    }
   function setAge(uint _age) public {
      require(msg.sender == admin);
      age = _age;
   }
   function getAge() public view returns(uint) {
      return age;
   }
}