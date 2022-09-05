/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract HelloWorld {
    string public message;

    constructor()  {
        message = "Hello, world!";
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}