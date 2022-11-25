// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UserContract {
    string checksum;
    constructor() {
        checksum = "";
    }
    function setChecksum(string memory _checksum) public {
        checksum = _checksum;
    }
    function getChecksum() public view returns(string memory) {
        return checksum;
    }
}