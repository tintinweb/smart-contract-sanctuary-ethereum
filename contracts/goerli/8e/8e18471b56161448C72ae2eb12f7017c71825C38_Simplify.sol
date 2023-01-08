// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//0x8e18471b56161448C72ae2eb12f7017c71825C38
contract Simplify {
    string name;
    uint age;
    bool isYes;

    function setString(string memory val) public {
        name = val;
    }

    function getString() public view returns (string memory) {
        return name;
    }

    function setInt(uint val) public {
        age = val;
    }

    function getInt() public view returns (uint) {
        return age;
    }

    function setBool(bool val) public {
        isYes = val;
    }

    function getBool() public view returns (bool) {
        return isYes;
    }
}