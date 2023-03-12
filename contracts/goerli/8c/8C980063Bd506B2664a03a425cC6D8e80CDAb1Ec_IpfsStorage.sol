// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract IpfsStorage {
    mapping (address => string) public userFiles;

    function setFile(string memory file) external {
        userFiles[msg.sender] = file;
    }
}