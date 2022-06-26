// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract LearnToken {

    string public name;

    event NameChanged(string name);

    constructor() {
     name = "Arnish Gupta";   
    }

    function setName(string memory _name) public {
        name = _name;
        emit NameChanged(_name);
    }
}