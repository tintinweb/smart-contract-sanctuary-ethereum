// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    address public owner;

    constructor() {
        owner = (msg.sender);
    }
}