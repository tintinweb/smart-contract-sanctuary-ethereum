// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Counter {
    uint public counter;
    address public owner;

    constructor(uint x) {
        counter = x;
        owner = msg.sender;
    }

    function count() external onlyOwner {
        counter = counter + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
}