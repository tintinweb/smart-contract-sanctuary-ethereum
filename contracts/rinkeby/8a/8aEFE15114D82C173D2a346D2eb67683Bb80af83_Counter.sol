// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Counter {
    uint256 public count;

    function increment() public {
        count = ++count;
    }

    function decrement() public {
        require(count >= 1, "Is not possible decrement");
        count = --count;
    }

    function resetCount() public {
        count = 0;
    }
}