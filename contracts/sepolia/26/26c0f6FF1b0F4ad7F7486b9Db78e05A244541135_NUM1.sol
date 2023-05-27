// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract NUM1 {
    uint256 private num;

    function update(uint256 _num) public {
        num = _num;
    }

    function get() public view returns (uint256) {
        return num;
    }
}