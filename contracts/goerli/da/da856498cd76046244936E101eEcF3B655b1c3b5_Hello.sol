// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Hello {
    string hello = "Hello";
    function sayHello() public returns (string memory) {
        return hello;
    }
}