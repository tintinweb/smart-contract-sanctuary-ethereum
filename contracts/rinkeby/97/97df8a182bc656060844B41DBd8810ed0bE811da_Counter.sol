/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

contract Counter {
  uint count = 0;

  function increment() public {
    count = count + 1;
  }

  function getCount() public view returns (uint) {
    return count;
  }
}