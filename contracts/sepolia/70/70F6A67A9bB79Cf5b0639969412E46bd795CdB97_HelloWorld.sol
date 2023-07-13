// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    // Event declaration
    // Up to 3 parameters can be indexed.
    // Indexed parameters helps you filter the logs by the indexed parameter
    event Log(address indexed sender, string message);

    address owner;
    
    constructor() {
        owner = msg.sender;
    }

    function test() external {
        emit Log(msg.sender, "Hello EVM!");
    }

    function get() external view returns(string memory greeting){      
        if(owner == msg.sender) {   
        return greeting = "Hello, world!";
        }       
    }
}