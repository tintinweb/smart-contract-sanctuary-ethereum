/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract SimpleStorage {
    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
}