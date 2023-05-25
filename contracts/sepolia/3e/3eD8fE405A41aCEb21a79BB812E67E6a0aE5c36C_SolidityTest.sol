/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: GPL-3.0;
pragma solidity ^0.8.7;

contract SolidityTest {
   uint age; // variable
   constructor() public {
      age = 60;   
   }
   function checkAge() public view returns(bool) {
      if( age > 60) {   
        return true;
      }
  
}
}