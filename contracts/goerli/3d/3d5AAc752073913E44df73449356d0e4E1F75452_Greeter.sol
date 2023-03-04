// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Greeter {
    event GreetingsFrom(address, string);

    function greet(string memory msgVal) public {
        require(msg.sender.code.length > 0, "caller must be a contract");
        emit GreetingsFrom(msg.sender, msgVal);
    }
}