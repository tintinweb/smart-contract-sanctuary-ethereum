// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract HelloWorld {
  uint256 public storedInteger;

  function increment() public {
    storedInteger += 1; 
  }
}