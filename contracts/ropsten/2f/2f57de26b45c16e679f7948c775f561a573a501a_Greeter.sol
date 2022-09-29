/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Greeter {
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function deposit() public payable {}
}