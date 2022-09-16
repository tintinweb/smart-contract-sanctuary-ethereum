/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity ^0.8.7;

contract Checkin {
    string CheckinStr;

    constructor(string memory _checkin_str) public {
        CheckinStr = _checkin_str;
    }

    function getCheckinStr() public view returns (string memory) {
        return CheckinStr;
    }

    function setCheckinStr(string memory _checkin_str) public {
        CheckinStr = _checkin_str;
    }

    function isCheckin() public view returns (bool) {
        string memory pass = "Welcome to Checkin";
        return keccak256(abi.encodePacked(pass)) == keccak256(abi.encodePacked(CheckinStr));
    }
}