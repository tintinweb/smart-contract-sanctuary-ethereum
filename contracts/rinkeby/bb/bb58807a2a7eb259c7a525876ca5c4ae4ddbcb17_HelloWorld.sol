/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HelloWorld {

    string public message = "Hello World";

    function setMessage(string memory _message) public {
        message = _message;
    }

    function viewMessage() public view returns(string memory) {
        return message;
    }
}