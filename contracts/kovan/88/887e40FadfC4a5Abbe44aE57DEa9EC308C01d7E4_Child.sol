pragma solidity ^0.8.0;

contract Child {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}