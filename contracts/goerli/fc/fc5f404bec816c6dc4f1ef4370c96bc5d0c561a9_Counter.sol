// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 storedData;

    function increment() public {
        storedData++;
    }

    function decrement() public {
        if (storedData > 0) {
            storedData--;
        }
    }

    function getCurrentNumber() public view returns (uint256) {
        return storedData;
    }
}