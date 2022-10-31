/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
contract calculator{
    
        uint Num1;
        uint Num2;
        
    
    
    uint public result;
     
    
    function add(uint N1,uint N2) public{
         result = N1+N2;
    
    
    }
   function subtract(uint N1,uint N2) public{
     result = N1-N2;
   }
   function multiply(uint N1,uint N2) public{
     result = N1*N2;
   }
   function divide(uint N1,uint N2) public{
      result = N1/N2;
   }
    }