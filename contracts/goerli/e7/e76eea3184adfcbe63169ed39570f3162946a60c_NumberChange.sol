/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract NumberChange {
  uint number;

  function changeNumber(uint _n) public {
    number = _n;
  }

  function getNumber() public view returns(uint) {
    return number;
  }
}