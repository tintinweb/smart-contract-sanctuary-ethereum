//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Store {
    uint256 public num;
    function store(uint256 newNum) public {
        num = newNum;
    }

}