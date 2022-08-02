// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }
}