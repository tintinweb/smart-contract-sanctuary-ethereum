//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Counter {
    uint counter;
    address owner;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    function count() public {
        require(msg.sender == owner, 'You are not the owner!');
        counter = counter + 1;
    }

    function get() public view returns (uint) {
        return counter;
    }

    function add(uint amount) public {
        require(msg.sender == owner, 'You are not the owner!');
        counter = counter + amount;
    }
}