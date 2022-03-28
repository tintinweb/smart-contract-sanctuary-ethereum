// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Balance {

    uint private balance;
    uint private opCounter;

    constructor() {
        balance = 100;
        opCounter = 0;
    }

    function updateVarA(uint minusA) public returns (uint) {
        
        somefunctionA();

        incrementCounter();
        
        minusVarA(minusA);

        somefunctionB();

        return balance;
    }

    function incrementCounter() private {
        opCounter++;
    }
    
    function minusVarA(uint minusVal) private {
        balance = balance - minusVal;
    }

    function somefunctionA() private {}

    function somefunctionB() private {}

    function getBalance() public view returns (uint) {
        return balance;
    }
}