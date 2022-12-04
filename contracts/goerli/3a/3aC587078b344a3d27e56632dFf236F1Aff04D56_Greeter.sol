//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Greeter {
    // Events that allows for emitting a message
    event NewGreeting(address sender, string message);

    // Variables
    string greeting;
    
    // Main constructor run at deployment
    constructor(string memory _greeting) {
        greeting = _greeting;
        emit NewGreeting(msg.sender, _greeting);
    }
    
    // Get function
    function getGreeting() public view returns (string memory) {
        return greeting;
    }
    
    // Set function
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit NewGreeting(msg.sender, _greeting);
    }
}