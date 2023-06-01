// SPDX-License-Identifier: GPL-3.0
 
pragma solidity 0.8.20;
 
contract SimpleStorage {
   uint private number;

   constructor() {
      number = 0;
   }
 
   function set(uint _number) external {
       number = _number;
   }
 
   function get() external view returns (uint) {
       return number;
   }
}