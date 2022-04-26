/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {
  uint256 private _myNum;

  error MyError();

  function a() external {
    _myNum = 1;
    require(1 > 10, "You are idiot");
  }

  function b() external {
    _myNum = 2;
    if (1 < 10) {
      revert MyError();
    }
  }
}