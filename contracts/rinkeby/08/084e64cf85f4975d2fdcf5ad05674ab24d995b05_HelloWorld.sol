/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract HelloWorld {
    string private message;
    string private anotherMessage;
    
    constructor(string memory _anotherMessage) {
        message = "The message is Hello World";
        anotherMessage = _anotherMessage;
    }

    function getMessage() external view returns(string memory) {
        return message;
    }

    function getAnotherMessage() external view returns(string memory) {
        return anotherMessage;
    }

    function setMessage(string calldata newMessage) public {
        message = newMessage;
    }
}