// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello {
    function sayHello(string memory name) public pure returns (string memory){
        return string.concat("Hello, ", name, "!");
    }
}