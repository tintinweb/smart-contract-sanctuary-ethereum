/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// Solidity program to
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Example {
  // declaring a state variable
  uint i = 0;

  // creating to function to use while loop
  function whileLoop() public returns(uint) {
    // creating a while loop
    while (i < 5) {
      i++;
    }

    // return i
    return i;
  }
}