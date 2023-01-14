// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Counter {
    uint256 public count;

    function increaseCount(uint256 _step, uint256 _value) external {
        count = _value * _step;
    }
}