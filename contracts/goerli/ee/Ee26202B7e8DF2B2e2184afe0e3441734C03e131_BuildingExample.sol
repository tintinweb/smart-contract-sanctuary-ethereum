/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Elevator {
  function goTo(uint _floor) public {}
}

interface Building {
    function isLastFloor(uint) external returns (bool);
}

contract BuildingExample is Building {
    Elevator public elevator;

    constructor() {
        elevator = Elevator(0xA231534E8B2Bfca2c9c4E26Db948472eAC692526);
    }

    function isLastFloor(uint _floor) external override returns (bool) {
        return true;
    }

    function goToElevator(uint _floor) public {
        elevator.goTo(_floor);
    }
}