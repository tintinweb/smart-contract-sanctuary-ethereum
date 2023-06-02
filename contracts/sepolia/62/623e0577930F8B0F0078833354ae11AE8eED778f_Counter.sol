// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
contract Counter {

    uint public value; 

    constructor(uint _initialValue) {
        value = _initialValue;
    }

    function increment() external {
        value++;
    }
    
}