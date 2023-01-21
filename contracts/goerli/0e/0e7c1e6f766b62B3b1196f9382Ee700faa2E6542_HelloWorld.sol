pragma solidity ^0.8.9;

contract HelloWorld{
    string hello = "hello";
    function helloWorld() view public returns(string memory) {
        return hello;

    }
}