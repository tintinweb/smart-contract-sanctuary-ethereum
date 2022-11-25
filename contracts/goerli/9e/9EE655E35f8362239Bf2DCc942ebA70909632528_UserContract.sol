// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UserContract {
    string checksum;
    string userId;
    constructor() {
        checksum = "";
        userId = "";
    }
    function setUserChecksum(string memory _userId, string memory _checksum) public {
        checksum = _checksum;
        userId = _userId;
    }
    function getLastChecksum() public view returns(string memory) {
        return checksum;
    }
    function getLastUserId() public view returns(string memory) {
        return userId;
    }
}