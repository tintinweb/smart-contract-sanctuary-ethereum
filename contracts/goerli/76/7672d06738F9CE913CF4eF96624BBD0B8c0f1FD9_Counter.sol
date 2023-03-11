// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

error Unauthorized();

contract Counter {
    uint256 public counter;
    address public owner;

    constructor(uint256 value) {
        counter = value;
        owner = msg.sender;
    }

    function count() public returns (uint256) {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        uint256 result = counter + 1;
        counter = result;

        return result;
    }
}