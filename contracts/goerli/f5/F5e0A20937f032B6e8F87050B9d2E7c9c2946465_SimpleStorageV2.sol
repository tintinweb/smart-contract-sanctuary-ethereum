// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract SimpleStorageV2 {
    uint256 favoriteNumber;
    bool favoriteBool;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function increment() public {
        favoriteNumber += 1;
    }
}