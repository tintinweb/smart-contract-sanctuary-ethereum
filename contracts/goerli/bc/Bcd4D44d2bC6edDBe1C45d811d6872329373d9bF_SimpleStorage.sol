// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 FavNumber;
    
    function store(uint256 _FavNumber) public {
        FavNumber = _FavNumber;
    } 

    function retrieve() public view returns (uint256) {
        return FavNumber;
    }
}