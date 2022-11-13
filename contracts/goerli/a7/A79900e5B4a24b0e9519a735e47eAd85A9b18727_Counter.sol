// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {
    uint8 private count;

    function getCount() public view returns (uint8) {
        return count;
    }

    function increment() public {
        count += 1;
    }

    function decrement() public {
        count -= 1;
    }
}