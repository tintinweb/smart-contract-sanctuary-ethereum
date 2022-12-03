// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Simplestorage {
    uint256 favNumber;

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    function retrive() public view returns (uint256) {
        return favNumber;
    }
}