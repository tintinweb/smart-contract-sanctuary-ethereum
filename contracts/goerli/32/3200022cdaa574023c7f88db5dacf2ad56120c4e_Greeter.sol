/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;


contract Greeter {

    address author;
    string greeting;

    // The constructor. It accepts a string input and saves it to the contract's "greeting" variable.
    function constuctor(string memory _greeting) public {
        author = msg.sender;
        greeting = _greeting;
    }

    function greet() public view returns (string memory){
        return string(abi.encodePacked(author, " says ", greeting));
    }

    function setGreeting(string memory _newgreeting) public {
        author = msg.sender;
        greeting = _newgreeting;
    }
}