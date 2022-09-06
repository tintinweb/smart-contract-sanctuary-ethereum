// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Greeter {
  string private greeting = "gm, world!";

    function greet() public view returns(string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}