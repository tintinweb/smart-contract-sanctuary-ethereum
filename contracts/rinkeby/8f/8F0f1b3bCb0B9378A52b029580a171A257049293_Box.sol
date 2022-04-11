// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Box {
    uint256 private value; 


    event ValueChanged(uint256 newValue);


    function store(uint256 _newValue) public {
        value = _newValue;
        emit ValueChanged(_newValue);
    }

    function retrive() public view returns (uint256){
        return value;
    }
}