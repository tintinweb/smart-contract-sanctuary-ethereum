/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// Solidity program to
// demonstrate addition
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract Example {
  // declaring a state variable
  uint i = 0;

  // creating to function to use for loop
  function forLoop() public returns(uint) {
    // creating a for loop
    for (uint j = 0; j < 5; j++) {
      i++;
    }

    // return i
    return i;
  }
}