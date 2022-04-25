//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract HelloWorld{
    string greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }
    function getGreeting() public view returns (string memory){
        return greeting;
    }
    function setGreet(string memory _greeting) public {
        // string memory greet = _greeting;
        greeting = _greeting;
    }
}