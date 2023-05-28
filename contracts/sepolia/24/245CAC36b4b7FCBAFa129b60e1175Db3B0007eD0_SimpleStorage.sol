// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favNumber;

    function setFavNum(uint256 _favNumber) public {
        favNumber = _favNumber;
    }
}