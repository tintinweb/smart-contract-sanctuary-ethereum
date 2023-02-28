/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;


contract Greeter {
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