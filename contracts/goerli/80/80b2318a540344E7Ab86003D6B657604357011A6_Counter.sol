//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Counter {
    string private greeting;
    uint256 public counter = 0;

    // constructor(string memory _greeting) {
    //     greeting = _greeting;
    // }

    // function greet() public view returns (string memory) {
    //     return greeting;
    // }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function setCounter(uint256 _counter) public {
        counter = _counter;
    }
}