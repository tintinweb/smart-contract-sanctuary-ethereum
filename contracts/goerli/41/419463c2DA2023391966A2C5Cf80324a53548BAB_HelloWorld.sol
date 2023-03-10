/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


contract HelloWorld {
    string public message;

    constructor() {
        message = "Hello World";
    }

    function updateMessage(string memory _newMe) public {
        message = _newMe;
    }
}