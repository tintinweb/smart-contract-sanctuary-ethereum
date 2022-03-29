/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Inbox {
    string public message;

    constructor( string memory initialMessage ) {
        message = initialMessage;
    }

    function setMessage( string memory newMessage ) public {
        message = newMessage;
    }

    function getMessage () public view returns (string memory){
        return message;
    }
}