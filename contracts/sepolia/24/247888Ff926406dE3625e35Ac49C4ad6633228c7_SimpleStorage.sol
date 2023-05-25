// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9; // >=0.8.7 <0.9.0   ^0.8.7

contract SimpleStorage {
    uint256 public favNumber;

    function set(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    function get() public view returns (uint256) {
        return favNumber;
    }
}