//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Greeter2 {
    string private greet;

    function setGreet(string memory _greet) public {
        greet = _greet;
    }

    function getGreet() public view returns(string memory) {
        return greet;
    }

    // constructor(string memory _greeting) {
    //     console.log("Deploying a Greeter with greeting:", _greeting);
    //     greeting = _greeting;
    // }

    // function greet() public view returns (string memory) {
    //     return greeting;
    // }

    // function setGreeting(string memory _greeting) public {
    //     console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
    //     greeting = _greeting;
    // }
}