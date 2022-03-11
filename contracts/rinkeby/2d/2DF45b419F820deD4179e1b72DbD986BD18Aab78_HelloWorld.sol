/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract HelloWorld {
    string public name;
    string public greeting = "Hello ";

    constructor(string memory initialName) {
        name = initialName;
    }

    function setName(string memory newName) public {
        name = newName;
    }

    function getGreeting() public view returns (string memory) {
        return string(abi.encodePacked(greeting, name));
    }
}