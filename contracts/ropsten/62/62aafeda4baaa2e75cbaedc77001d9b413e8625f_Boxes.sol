/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier : MIT
pragma solidity 0.8.17;

contract Boxes {
  uint public val;

  function initialize(uint _val) external {
    val = _val;
  }
}