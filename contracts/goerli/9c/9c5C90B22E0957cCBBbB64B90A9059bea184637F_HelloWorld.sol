pragma solidity ^0.8.0;

contract HelloWorld {
    
    address owner;
    
    constructor() {
        owner = msg.sender;
    }

    function get() external view returns(string memory){
        if(owner == msg.sender) {
        string memory greeting = "Hello, world!";
        return greeting;
        }       
    }
}