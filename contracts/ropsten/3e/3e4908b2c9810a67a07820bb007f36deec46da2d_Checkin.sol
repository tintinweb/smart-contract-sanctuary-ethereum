/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Checkin {
    string CheckinStr;
    event pass(string info);

    constructor(string memory _checkin_str) {
        CheckinStr = _checkin_str;
    }

    function getCheckinStr() public view returns (string memory) {
        return CheckinStr;
    }

    function setCheckinStr(string memory _checkin_str) public {
        CheckinStr = _checkin_str;
    }

    function isCheckin() public returns (bool) {
        string memory key = "Welcome to Checkin";
        bool ok = keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked(CheckinStr));
        if (ok == true) {
            emit pass(key);
        }
        return ok;
    }
}