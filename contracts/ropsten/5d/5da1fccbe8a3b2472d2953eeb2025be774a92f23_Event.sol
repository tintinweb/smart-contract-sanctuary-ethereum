/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Event {
    event Log(address indexed sender, string message);
    event ANotherLog();

    function test() public {
        emit Log(msg.sender, 'Hello world!');
        emit Log(msg.sender, 'Hello EVM!');
        emit ANotherLog();
    }
}