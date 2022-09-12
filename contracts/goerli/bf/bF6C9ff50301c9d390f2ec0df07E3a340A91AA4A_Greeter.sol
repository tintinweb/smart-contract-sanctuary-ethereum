//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

error InvalidGreeting(uint256 len, string str);

contract Greeter {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        if (bytes(_greeting).length <= 3) revert InvalidGreeting(bytes(_greeting).length, _greeting);
        greeting = _greeting;
    }
}