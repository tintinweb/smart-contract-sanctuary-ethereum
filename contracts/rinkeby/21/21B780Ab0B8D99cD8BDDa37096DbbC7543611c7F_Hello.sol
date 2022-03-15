/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// File: hello.sol


// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Hello{
    string public greeting = "Hello world!";

    function setGreeting(string memory _greeting) public{
        greeting = _greeting;
    }

    function greet() public view returns(string memory){
        return greeting;
    }
}