/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Counter{

  uint public num = 0;
  uint256 public updatedAt = 0;

  constructor() {}

  function add(uint _addAmount) external {
    num += _addAmount;
    updatedAt = block.timestamp;
  }

  function minus(uint _minusAmount) external {
    num -= _minusAmount;
    updatedAt = block.timestamp;
  }

}