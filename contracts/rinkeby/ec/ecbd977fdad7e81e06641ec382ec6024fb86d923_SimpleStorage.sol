/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage{
    uint256 public favoriteNumber; // == 0 (default)

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

}