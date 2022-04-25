/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AnyCallReceiver {
  event LogAnyFallback(address _to, bytes _data);
  event LogInc();

  uint256 public number = 0;

  function anyFallback(address _to, bytes calldata _data) external {
    emit LogAnyFallback(_to, _data);
  }

  function inc() external {
    number = number + 1;
    emit LogInc();
  }
}