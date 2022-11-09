/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// Simple smart contract to GREET user with USERNAME provided.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GreetUser{

    // sets greeting sting to "Enter Your Name" in public scope.
    string public username = "Enter Your Username...";

    // function to return value of greeting .
    // view only no gas.
    function greet() public view returns(string memory) {
        return string.concat("Hello ", username);
    }

    // function to set new value of greeting and display it.
    // storing in memory (requires gas).
    function setGreeting(string memory word) public {
        username = word;
    }
}