// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract myContract {
    int256 num;

    function get() public view returns (int256) {
        return num;
    }

    function set(int256 _num) public {
        num = _num;
    }
}