/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

pragma solidity ^0.8.17;
 
//Safe Math Interface

contract Learn2Eearn {
    string public problemURI;
    string public title;
    uint256 public attemptCounter = 0;

    event Task(uint256 id, address author, string source, string lang);

    function sendTask(string memory source, string memory lang) public {
        attemptCounter = attemptCounter + 1;
        emit Task(attemptCounter, msg.sender, source, lang);
    }
    constructor() {
        problemURI = "https://lolec.com";
        title = "A+B";
    }
}
 
 contract eventExample {
 
    // Declaring state variables
    uint256 public value = 0;
 
    // Declaring an event
    event Increment(address owner);  
 
    // Defining a function for logging event
    function getValue(uint _a, uint _b) public {
        emit Increment(msg.sender);
        value = _a + _b;
    }
}