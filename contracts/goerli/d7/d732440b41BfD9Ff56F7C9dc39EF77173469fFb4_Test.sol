//simple smart contract that changes the value of a variable with solidity 0.8.10

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Test {
    uint256 public value;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setValue(uint256 _value) public {
        value = _value;
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function getSender() public view returns (address) {
        return msg.sender;
    }
}