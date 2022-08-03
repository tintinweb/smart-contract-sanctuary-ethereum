// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract HackCoinFlip {
    ICoinFlip collection;

    constructor (address _collection) {
        collection = ICoinFlip(_collection);
    }

    function bulkFlip() external {
        for (uint256 i = 0; i < 10; i++) {
            collection.flip(true);
        }
        for (uint256 i = 0; i < 10; i++) {
            collection.flip(false);
        }
    }
}