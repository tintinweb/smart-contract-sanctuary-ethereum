// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld {
    string hello = "hello";

    function helloWorld() public view returns (string memory) {
        return hello;
    }
}