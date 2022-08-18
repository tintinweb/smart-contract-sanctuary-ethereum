// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number = 3;

    function increment() public {
        number++;
    }

    function backdoor(uint256 x) public {
        if (x == 69) {
            number = 2;
        }
    }
}