// SPDX-License-Identifier: No Liscense
pragma solidity >=0.8.0;

contract Counter {
    address public owner;
    address public implementation;
    uint256 public counter;

    function increment() public {
        counter++;
    }
}