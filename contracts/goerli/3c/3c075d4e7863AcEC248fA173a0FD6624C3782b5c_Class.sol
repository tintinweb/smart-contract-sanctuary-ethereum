/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Class {
  uint public a = 100;

  function setA(uint _a) public {
    a = _a;
  }

  function add(uint _a, uint _b, uint _c) public pure returns(uint) {
    return _a * _b * _c;
  }

  function getContractAddress() public view returns(address){
      return address(this);
  }
}