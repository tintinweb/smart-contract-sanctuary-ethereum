/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract GreetingContract {

    address private owner;

    string public greeting = "Hello ";

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; 
    }

    function setGreeting(string memory newGreeting) public isOwner {
        greeting = newGreeting;
    }


    function greet(string memory name) public view returns (string memory) {
        return string(abi.encodePacked(greeting, name));
    }

}