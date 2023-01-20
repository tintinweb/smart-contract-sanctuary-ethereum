// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    event NumberSet(address indexed actor, uint256 number);
    event NumberIncremented(address indexed actor, uint256 number);

    function setNumber(uint256 newNumber) public returns (uint){
        number = newNumber;
        emit NumberSet(msg.sender, newNumber);
        return number;
    }

    function increment() public returns (uint){
        number++;
        emit NumberIncremented(msg.sender, number);
        return number;
    }
}