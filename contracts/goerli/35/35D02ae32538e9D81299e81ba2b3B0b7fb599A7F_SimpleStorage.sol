/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function setFavoriteNumber(uint256 _favoritaNumber) public {
        favoriteNumber = _favoritaNumber;
    }
}