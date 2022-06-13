/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract inbox {
    string public message;


    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    // although we have created the getMessage function to return some value, it was actually not required because if we declare /// a public variable with the constructor, the system creates a function by default with the same name as of the variable
    // which acts as a return function...in this case it is message().
    function getMessage() public view returns(string memory) {
        return message;
    }
}