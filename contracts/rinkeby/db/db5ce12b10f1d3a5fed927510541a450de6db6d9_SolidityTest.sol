/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract SolidityTest  {
    

    constructor() {
    }

    function getResult() 
      public 
      view 
      virtual
      returns(uint){
         uint a = 1;
         uint b = 2;
         uint result = a + b;
         return result;
      }

    
}