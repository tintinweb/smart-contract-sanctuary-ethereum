/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract Greeter {
    event SetGreeting (address indexed from, string msg);
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting (string memory _greeting) public {
        greeting = _greeting;

        emit SetGreeting(msg.sender, _greeting);
    }
}