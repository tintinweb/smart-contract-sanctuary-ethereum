/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract HelloWorld {
    string public name;
    string public greetingSay = "hello ";

    constructor(string memory initialName) {
        name = initialName;
    }
    function setName(string memory finalName) public {
        name = finalName;
    }

    function getGreeting() public view returns (string memory) {
return string(abi.encodePacked(greetingSay, name));
    }
}