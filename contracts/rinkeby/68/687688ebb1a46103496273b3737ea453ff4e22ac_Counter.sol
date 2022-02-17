/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

contract Counter {
  uint256 private count;

  constructor(uint256 _initialNumber) {
    count = _initialNumber;
  }

  function currentCounter() public view returns (uint) {
    return count;
  }

  function increment() public {
    count++;
  }

  function decrement() public {
    count--;
  }

}