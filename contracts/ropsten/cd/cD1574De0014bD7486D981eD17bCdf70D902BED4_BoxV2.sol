/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier : MIT
pragma solidity 0.8.17;

contract BoxV2 {
  uint public val;

  function inc() external {
    val += 1;
  }
}