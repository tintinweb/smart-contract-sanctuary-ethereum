//SPDX-License-Identifier
pragma solidity ^0.8.0;

contract BoxV2{
    uint256 private value;

    event ValueChanged(uint256 newValue);
    
    //storing the new value
    function store(uint256 newValue) public{
        value = newValue;
        emit ValueChanged(newValue); 
    }

    //retrieving the new value
    function retrieve() public view returns (uint256){
        return value;
    }

    //increment the function
    function increment() public{
        value = value + 1;
        emit ValueChanged(value);
    }
}