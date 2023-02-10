pragma solidity ^0.8.9;

contract HelloWorld {
    string hello = "hello";

    function helloWorld() public view returns (string memory) {
        return hello;
    }
}