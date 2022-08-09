// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256[] public nums;

    function store(uint256 _number) public {
        nums.push(_number);
    }
}