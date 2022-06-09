/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Test {
  bool public flag;

  constructor () {
    flag = true;
  }

  function doFlag() public {
    flag = !flag;
  }

  function  seeFlag() public view returns(bool) {
      return flag;
  }
}