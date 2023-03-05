// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    mapping(string => uint256) public numbers;
    
    function increment() public {
        number++;
        numbers["A"] = 1;
        numbers["B"] = 2;
        numbers["C"] = 3;
    }
}