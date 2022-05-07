// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9;

contract Adder {
    event Added(uint16 oldValue, uint16 newValue);
    event Subtracted(uint16 oldValue, uint16 newValue);

    address public admin;
    uint16 public value;

    constructor(address admin_) {
        admin = admin_;
    }

    function add(uint16 toAdd) public {
        require(msg.sender == admin);
        emit Added(value, value += toAdd);
    }
    
    function subtract(uint16 toSubtract) public {
        require(msg.sender == admin);
        emit Subtracted(value, value -= toSubtract);
    }
}