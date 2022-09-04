// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {

    uint256 public FavNumber;
    constructor() {
        FavNumber = 100;
    }
    function retrieve() public view returns(uint256) {

        return FavNumber;
        
    }

    function store(uint256 no) public {
        FavNumber  = no;
    }
}