/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract BoxV2{
    uint private value;

    //Emitted when the store value change
    event ValueChanged(uint newValue);

    //Stores a new value in the contract 
    function store(uint newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    //reads the last stored value
    function read() public view returns (uint) {  
        return value;
    }

    function increment() public {
        value += 1;
        emit ValueChanged(value);
    }
}