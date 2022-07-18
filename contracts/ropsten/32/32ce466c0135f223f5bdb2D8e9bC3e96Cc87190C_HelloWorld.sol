// We will be using Solidity version 0.8.15 
pragma solidity 0.8.15;

contract HelloWorld {
    string private message = "hello world";

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}