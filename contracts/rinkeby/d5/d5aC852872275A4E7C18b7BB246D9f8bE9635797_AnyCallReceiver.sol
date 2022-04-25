//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AnyCallReceiver {
  event LogInc();

  uint256 public number = 0;
  function inc() external {
    number = number + 1;
    emit LogInc();
  }

  function die() external {
    number = number;
    require(false, "die");
  }
}