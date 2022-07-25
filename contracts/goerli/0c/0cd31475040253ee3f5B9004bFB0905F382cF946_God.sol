// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract God {
    address payable public father;

    constructor() {
        father = payable(msg.sender);
    }
}