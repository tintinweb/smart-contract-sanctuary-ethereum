// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
    uint private value;
    event ValueChanged(uint256 newValue);

    function store(uint256 new_value) public {
        value= new_value;
        emit ValueChanged(new_value);
    }
    function retrieve() public view returns(uint256) {
        return value;
    }
    function increment() public {
        value+=1;
        emit ValueChanged(value);
    }
}