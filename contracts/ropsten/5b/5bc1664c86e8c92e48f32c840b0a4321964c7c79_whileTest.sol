/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// Solidity program to
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
  
// for loop test
contract whileTest { 
      
    uint result = 0;

    function sum() public returns(uint data){
    for(uint i=0; i<10; i++){
        result=result+i;
     }
      return result;
    }
}