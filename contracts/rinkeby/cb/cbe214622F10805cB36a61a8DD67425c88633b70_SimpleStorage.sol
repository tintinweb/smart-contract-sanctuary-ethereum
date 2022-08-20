// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber = 1;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber * this.retrieve();
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}