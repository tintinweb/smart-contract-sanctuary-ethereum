// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// // Import this file to use console.log
// import "hardhat/console.sol";

contract Lock {
    string message = "";

    constructor() {}

    function viewMessage() public view returns (string memory) {
        return message;
    }

    function setMesage(string memory _message) public returns (string memory) {
        return message = _message;
    }
}