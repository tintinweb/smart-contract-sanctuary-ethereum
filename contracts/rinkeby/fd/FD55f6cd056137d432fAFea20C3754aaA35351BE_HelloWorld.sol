/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.8;

contract HelloWorld {
    string private name;
    string private greetingsPrefix = "Hello World";

    constructor(string memory initialName) {
        name = initialName;
    }

    function setName(string memory newName) public {
        name = newName;
    }

    function setGreetingPrefix(string memory greetingPrefix) public {
        greetingsPrefix = greetingPrefix;
    }

    function retrieveGreeting() public view returns (string memory) {
        return string(abi.encodePacked(greetingsPrefix, " ", name));
    }
}