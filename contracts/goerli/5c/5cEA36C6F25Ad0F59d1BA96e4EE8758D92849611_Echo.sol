// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Echo {

    address public owner; 

    event Message(string msg);

    constructor() {
        owner = msg.sender;
    }
    function broadcast(string memory _msg) public {
        emit Message(_msg);
    }
}