// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ElevatorInterface {
  function goTo(uint _floor) external;
}

contract MyBuilding {
  bool public lastFloorRequested = false;

  constructor() payable public {
  }

  function isLastFloor(uint _floor) external returns (bool) {
    if(lastFloorRequested) {
      return true;
    } else {
      lastFloorRequested = true;
      return false;
    }
  }

  function takeElevatorTo(address _elevator, uint _floor) public {
    ElevatorInterface elevator = ElevatorInterface(_elevator);
    elevator.goTo(_floor);
  }
}