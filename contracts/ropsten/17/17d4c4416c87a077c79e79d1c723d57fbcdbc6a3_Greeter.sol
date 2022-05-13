pragma solidity ^0.4.21;

contract Greeter {
    string public greeting;
    string public a;
    function Greeter(string aa) public {
        greeting = 'Hello';
        a = aa;
    }

    function setGreeting(string _greeting) public {
        greeting = _greeting;
    }

    function greet() view public returns (string) {
        return greeting;
    }
}