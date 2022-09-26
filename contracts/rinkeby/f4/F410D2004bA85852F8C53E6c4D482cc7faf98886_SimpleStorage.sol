// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    constructor() {
        favoriteNumber = 2;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}