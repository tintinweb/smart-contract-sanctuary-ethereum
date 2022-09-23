// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Greeting {
    function sayHello() external pure returns (string memory) {
        return "Hello world";
    }

    // pure functions - doesn't access the state of a contract
    // view functions
    // fallback functions
}