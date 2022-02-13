// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
  function isLastFloor(uint256) external returns (bool);
}

interface Elevator {
  function goTo(uint256 _floor) external;
}

contract BuildingWithElevator is Building {
  bool public top = true;
  uint256 public floor;

  function isLastFloor(uint256 _floor) external override returns (bool) {
    top = !top;

    if (top) {
      floor = _floor;
    }

    return top;
  }

  function goTo(Elevator elevator, uint256 _floor) external {
    elevator.goTo(_floor);
  }
}