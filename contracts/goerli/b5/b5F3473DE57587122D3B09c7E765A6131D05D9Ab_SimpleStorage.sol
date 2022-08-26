//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

//Author : Duminda Piumwardena

contract SimpleStorage {
    uint256 favouriteNumber;

    constructor() {}

    function getFavNumber() public view returns (uint256) {
        return favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }
}