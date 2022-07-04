/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract Test{

    string message;

    constructor()  {
        message = "Davide puppigno"; 
    }

    function get() public view returns(string memory) {
        return message;
    }

    function set(string memory newMessage) public {
        message = newMessage;
    }
}