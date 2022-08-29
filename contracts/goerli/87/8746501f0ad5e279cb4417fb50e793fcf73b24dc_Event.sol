/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Event {
    // Event declaration
    // Up to 3 parameters can be indexed.
    // Indexed parameters helps you filter the logs by the indexed parameter
    event Log(address indexed sender, string message);
    mapping(address => string) public greeting;


    function greet(string memory _msg) public {
        greeting[msg.sender] = _msg;
        emit Log(msg.sender, _msg);
    }
}