//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
  uint nonce = 653987328;

    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}