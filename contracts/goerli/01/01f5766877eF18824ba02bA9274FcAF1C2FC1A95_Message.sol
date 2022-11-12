pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later
contract Message {

    string message;

    function store(string memory msg_in) public {
        message = msg_in;
    }

    function retrieve() public view returns (string memory){
        return message;
    }
}