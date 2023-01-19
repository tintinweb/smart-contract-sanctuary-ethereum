// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// This contract generates a random number between 1 and 100000

contract RandomNumberGenerator {

    // The generated random number

    uint public randomNumber;

    constructor() {
        randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000 + 1;
    }
}