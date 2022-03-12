/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// File: contracts/Hello World.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

contract HelloWorld {
    string public name;
    string public greetingprefix = "Hello World ";

    constructor(string memory initialName) {
        name = initialName;
    }
    
    function setName(string memory newName) public {
        name = newName;
    }
    
    function getGreeting() public view returns (string memory) {
        return string(abi.encodePacked(greetingprefix, name));
    }
 }