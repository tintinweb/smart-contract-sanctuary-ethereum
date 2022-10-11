// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

contract Counter {
    uint256 public count = 0;

    function increment() public returns (uint256) {
        count += 1;
        return count;
    }

    function addInteger(uint256 intToAdd) public returns (uint256) {
        count += intToAdd;
        return count;
    }

    function reset() public returns (uint256) {
        count = 0;
        return count;
    }
}