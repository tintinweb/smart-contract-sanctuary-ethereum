// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Box {

    uint256 private value;

    event ValueChanged(uint256 value);
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrive() public view returns(uint256){
        return value;
    }

}