// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private val;

    event ValueChanged(uint256 val);

    function store(uint256 _val) public {
        val = _val;
        emit ValueChanged(_val);
    }

    function retrieve() public view returns(uint256) {
        return val;
    }

    function increment() public {
        val++;
        emit ValueChanged(val);
    }
}