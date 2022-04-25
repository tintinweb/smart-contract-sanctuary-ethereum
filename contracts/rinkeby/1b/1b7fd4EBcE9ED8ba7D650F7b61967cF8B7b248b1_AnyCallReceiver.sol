/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AnyCallReceiver {
  uint256 public number = 0;

  function inc() external {
    number = number + 1;
  }
}