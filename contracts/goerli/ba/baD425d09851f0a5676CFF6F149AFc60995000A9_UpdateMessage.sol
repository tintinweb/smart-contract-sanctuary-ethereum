// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.3;

contract UpdateMessage {

    string public message; 

    constructor(string memory initMessage) {
        message = initMessage; 
    }

    function update(string memory newMessage) public {
        message = newMessage; 
    }

}