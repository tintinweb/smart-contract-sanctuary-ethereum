// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Counter {
    uint256 private _counter;

    function getCount() external view returns (uint256) {
        return _counter;
    }

    function increase() external {
        _counter += 1;
    }
}