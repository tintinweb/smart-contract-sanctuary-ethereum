// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleCounter {
    uint256 public counter;

    event IncrementCounter(uint256 newCounterValue);

    function increment() external {
        counter++;
        emit IncrementCounter(counter);
    }
}