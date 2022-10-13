/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Simple {

    string public message;

    constructor(){}

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory newMessage) public returns(bool) {
        message = newMessage;
        return true;
    }

}