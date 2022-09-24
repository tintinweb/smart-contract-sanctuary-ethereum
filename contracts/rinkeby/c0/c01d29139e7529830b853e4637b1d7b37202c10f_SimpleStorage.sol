/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    function store (uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        favoriteNumber += 1;
    }

    function f1 (string memory name) public pure returns (string memory) {
        string memory surname = "Agayev";
        return string.concat(name, surname);
    }
}

// Storage 0xd9145CCE52D386f254917e481eB44e9943F39138