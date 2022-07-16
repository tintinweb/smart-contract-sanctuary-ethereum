//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public num;

    function store(uint256 _num) public {
        num = _num;
    }
}