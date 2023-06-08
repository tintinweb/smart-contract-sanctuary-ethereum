// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract TermData {
    uint256 public a = 10;
    function setData(uint256 index) public {
        a += index; 
        require(a > 1000, "ERROR: INDEX");
    }
}