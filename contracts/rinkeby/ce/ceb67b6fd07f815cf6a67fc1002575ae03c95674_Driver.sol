/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Driver {
    string public firstName;
    string public lastName;
    string public DLNumber;
    string public birthday;
    bool public isDriving;
    uint256 public lastDriving;
    mapping(string => uint256) public drivingTime;

    constructor() {
        firstName = "Mike";
        lastName = "Tyson";
        DLNumber = "DL111";
        birthday = "01/01/1950";
        isDriving = false;
        lastDriving = 0;
    }

    function setFirstName(string calldata _first) external {
        firstName = _first;
    }

    function getFirstName() external view returns (string memory) {
        return firstName;
    }

    function setLastName(string calldata _last) external {
        lastName = _last;
    }

    function getLastName() external view returns (string memory) {
        return lastName;
    }

    function setDLNumber(string calldata _DL) external {
        DLNumber = _DL;
    }

    function getDLNumber() external view returns (string memory) {
        return DLNumber;
    }

    function setBirthday(string calldata _birthday) external {
        birthday = _birthday;
    }

    function getBirthday() external view returns (string memory) {
        return birthday;
    }

    function setIsDriving(bool cur) external {
        isDriving = cur;
    }

    function getIsDriving() external view returns (bool) {
        return isDriving;
    }

    function setLastDriving(uint256 _lastTime) external {
        lastDriving = _lastTime;
    }

    function getLastDriving() external view returns (uint256) {
        return lastDriving;
    }

    function addDrivingTime(string calldata day, uint256 _time) external {
        if (drivingTime[day] > 0) {
            drivingTime[day] += _time;
        } else {
            drivingTime[day] = _time;
        }
    }

    function getDrivingTime(string calldata day)
        external
        view
        returns (uint256)
    {
        return drivingTime[day];
    }
}