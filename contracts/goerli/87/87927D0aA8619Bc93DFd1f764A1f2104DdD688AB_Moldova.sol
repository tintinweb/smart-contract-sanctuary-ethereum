// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Moldova {
    address public owner;
    uint256 public counter;

    error NotOwner();

    constructor() {
        owner = msg.sender;
        counter = 0;
    }

    function addValue(uint256 value) external {
        counter = counter + value;
    }

    function reset() external {
        if (msg.sender != owner) {
             revert NotOwner();
        }
        counter = 0;
    }

}