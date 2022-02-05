/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.11;



// File: SimpleStorage.sol

contract SimpleStorage {
    uint256 public favoriteNumber;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 _favoriteNumber) public {
        emit storedNumber(
            favoriteNumber,
            _favoriteNumber,
            favoriteNumber + _favoriteNumber,
            msg.sender
        );
        favoriteNumber = _favoriteNumber;
    }
}