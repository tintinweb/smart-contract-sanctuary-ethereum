/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: GPL-3.0
// Solidity program to implement
// if-else statement
pragma solidity ^0.8.15;
 
// Declaring contract
contract Example {
     
  // Declaring one variable
  uint public value;
     
  // Declaring function with argument
  function setValue(uint newValue) public {
     
    // if value is greater than 10
    // value will be assigned as newValue
    if (newValue > 0)
    {
      value = newValue;
         
      // else value will be zero.
    } else
    {
      value = 0;
    }
  }
}