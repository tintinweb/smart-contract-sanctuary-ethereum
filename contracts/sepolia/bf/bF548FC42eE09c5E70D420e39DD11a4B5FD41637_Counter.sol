// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract Counter {
    uint256 private count;

    function increment() public {
        count += 1;
    }

    function decrement() public {
        require(count > 0, "Counter is already at 0");
        count -= 1;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}