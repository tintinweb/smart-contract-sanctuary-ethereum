// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Greeter {
    string greet;

    function setGreet(string memory _greet) public {
        greet = _greet;
    }

    function getGreet() public view returns(string memory) {
        return greet;
    }
}