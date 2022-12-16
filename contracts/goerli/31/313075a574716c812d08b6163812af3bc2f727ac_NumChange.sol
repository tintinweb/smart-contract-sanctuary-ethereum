/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract NumChange {
  uint num;
  function setNum(uint _a) public {
    num = _a;
  }
  function getNum() public view returns(uint) {
    return num;
  }
}