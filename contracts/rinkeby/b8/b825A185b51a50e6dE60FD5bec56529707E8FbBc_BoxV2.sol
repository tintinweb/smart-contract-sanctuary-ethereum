//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2  {
    uint256 private value;

    event ValeuChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValeuChanged((newValue));
    }
    function retrieve() public view returns(uint256){
        return value;
    }
    function increment() public{
        value= value + 1;
        emit ValeuChanged(value);
    }
}