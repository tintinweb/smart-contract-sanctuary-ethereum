// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GreetingsContract {
    string[] private greetings;

    function addGreeting(string memory newGreeting) public {
        greetings.push(newGreeting);
    }

    function getGreetings() public view returns (string[] memory) {
        return greetings;
    }
}