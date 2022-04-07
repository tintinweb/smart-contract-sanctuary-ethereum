/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Event {
    // Event declaration
    // Up to 3 parameters can be indexed.
    // Indexed parameters helps you filter the logs by the indexed parameter
    event Log(address indexed sender, string message, uint8 number);
    event AnotherLog();

    function test(uint8 number) public {
        emit Log(msg.sender, "Hello World!",number);
        emit Log(msg.sender, "Hello EVM!",number);
        emit AnotherLog();
    }
}