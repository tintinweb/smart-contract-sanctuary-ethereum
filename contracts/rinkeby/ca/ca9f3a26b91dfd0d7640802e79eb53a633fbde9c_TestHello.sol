/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^ 0.8.8;

contract TestHello{
    string public message;
    address private owner;

    constructor() {
        message = "Say Hello";
        owner = msg.sender;
    }

    function setMessage( string memory _message) public {
        message = _message;
    }

    function showOwner() view public returns(address){
        return owner;
    }
}