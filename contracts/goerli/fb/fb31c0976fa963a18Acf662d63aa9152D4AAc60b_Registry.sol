// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Registry {
    mapping(address => uint256) public values;

    function register(address owner, uint256 value) external {
        values[owner] = value;
    }
}