/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {

    string public message;
    string public messageContent = "My name is Oluwasanmi";

    constructor(string memory _message) {                 
        message = _message;       
    }  

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }

    function viewMessage() public view returns(string memory) {
        return string(abi.encodePacked(message, messageContent));
    }

}