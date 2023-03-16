// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {
    uint256 private counter;
    address private owner;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function count(uint256 _value) public onlyOwner returns(uint256) {
        counter += _value;
        return counter;
    }

    function getCounter() public view returns(uint256) {
        return counter;
    }
}