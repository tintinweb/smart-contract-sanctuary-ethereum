// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 fav;

    function store(uint256 num) public virtual {
        fav = num;
    }

    function retrieve() public view returns (uint256) {
        return fav;
    }
}