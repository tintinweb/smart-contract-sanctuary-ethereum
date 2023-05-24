// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    int256 val;

    function get() public view returns (int256) {
        return val;
    }

    function set(int256 _val) public {
        val = _val;
    }
}