// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract HelloWorld {
    string private _greeting;

    function setGreeting(string memory greeting) public {
        _greeting = greeting;
    }

    function getGreeting() public view returns (string memory) {
        return _greeting;
    }
}