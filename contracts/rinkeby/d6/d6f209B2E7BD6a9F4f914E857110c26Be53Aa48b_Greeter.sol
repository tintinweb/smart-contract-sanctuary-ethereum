//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
  uint nonce = 836827800;

    string private greeting;

    constructor() {
        greeting = "";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}