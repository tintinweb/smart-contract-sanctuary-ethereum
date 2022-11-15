// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Simple {
    uint256 favoriteNumber;

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}