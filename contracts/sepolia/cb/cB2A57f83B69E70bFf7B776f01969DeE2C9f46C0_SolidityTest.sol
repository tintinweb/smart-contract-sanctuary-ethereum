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
   function checkAge() public view returns(string memory) {
      if( age > 60) {   
        return "60";
      } else {
       return "less than 60";
      }       
      return "default"; 
   }
  
}