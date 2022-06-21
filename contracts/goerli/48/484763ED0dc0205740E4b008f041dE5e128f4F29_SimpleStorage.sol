// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleStorage {
    uint256 public favNumber = 0;

    function retrive() public view returns (uint256) {
        return favNumber;
    }

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }
}