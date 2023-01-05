// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract Elevator {
    function goTo(uint _floor) public {}
}

contract Building {
    Elevator elevator;

    constructor(address _elevatorAddress) {
        elevator = Elevator(_elevatorAddress);
    }

    function isLastFloor(uint) external returns (bool) {
        return false;
    }

    function winnerWinnerChickenDinner(uint _floor) public {
        elevator.goTo(_floor);
    }
}