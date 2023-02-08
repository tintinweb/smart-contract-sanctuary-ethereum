// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreservationAttacker {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    uint storedTime;

    function setTime(uint _time) public {
        storedTime = _time;
    }
}