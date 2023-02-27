// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract HelloWorld {
    string hello = "Hello, buddy!";

    function helloWorld() public view returns (string memory) {
        return hello;
    }
}