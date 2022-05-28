pragma solidity ^0.8.2;

contract HelloWorld {
	string public greetings = "Hello World";
    
    function setGreetings(string memory _greetings) public {
    	greetings = _greetings;
    }
}