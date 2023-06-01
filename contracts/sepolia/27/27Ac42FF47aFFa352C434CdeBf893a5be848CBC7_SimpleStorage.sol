// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;
 
contract SimpleStorage {
   uint private number;

   constructor(uint _number) payable {
       number = _number;
   }

   function setNumber(uint _number) public {
       number = _number;
   }
 
   function getNumber() public view returns (uint) {
       return number;
   }
}