// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {

    uint256 public counter = 0;

    function inc() external {
        counter++;
    }

    function dec() external {
        counter--;
    }

}