//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HelloWorld {
    string hello = "hello";

    function helloWorld() public returns (string memory) {
        return hello;
    }
}