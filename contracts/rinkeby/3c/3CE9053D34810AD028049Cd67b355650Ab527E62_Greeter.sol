/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File contracts/Greeter.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;

    event NotifyGreeting(string greeting);

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public returns (string memory) {
        emit NotifyGreeting(greeting);
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}