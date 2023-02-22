// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Greeter {
    string public greeting;

    constructor()  {
        greeting = 'Hello';
    }

     function  setGreeting(string memory _greeting)  public payable {
        greeting = _greeting;
    }

    function greet() view public returns (string memory) {
        return greeting;
    }
}