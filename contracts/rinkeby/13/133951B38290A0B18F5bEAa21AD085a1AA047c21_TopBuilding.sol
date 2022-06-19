// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IElevator {
    function goTo(uint _floor) external;
} 

contract TopBuilding {
    uint256 floor;
    bool top;

    function goTo(address elevator) external {
        IElevator(elevator).goTo(1);
    }

    function isLastFloor(uint _floor) public returns (bool) {
        floor = _floor;
        if (top) {
            return true;
        }
        top = !top;
        return false;
    }
}