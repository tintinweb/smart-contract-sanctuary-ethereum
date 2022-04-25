// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Greeter {
    error BOBO();

    string private greeting;

    constructor(string memory _greeting) {
        if(bytes(_greeting).length == 0) revert BOBO();
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        if(bytes(_greeting).length == 0) revert BOBO();
        greeting = _greeting;
    }
}