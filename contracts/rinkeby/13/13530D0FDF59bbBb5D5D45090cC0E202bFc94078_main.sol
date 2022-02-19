// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract main {
    uint256 public data_;

    function get() public view returns (uint256) {
	    return data_ + 1;
    }

    function set(uint256 data) public {
        data_ = data;
    }

}