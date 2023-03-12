// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract Shukla {
    uint256 public value=10;

    function getValue()public view returns(uint256){
        return value;
    }

    function setValue(uint256 data) public{
        value =data;
    }

}