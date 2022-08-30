// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log

contract Lock {
    uint public test;
    address payable public owner;
    constructor(uint testValue, address payable creater) payable {
        test = testValue;
        owner = creater;
    }
    function getTestValue() public view returns (uint){
        return test;
    }
    function getowner() public view returns (address){
        return owner;
    }
}