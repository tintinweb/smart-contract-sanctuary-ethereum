/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract name_index {
    // State variable to store a number
    mapping(address => string) public names;

    constructor() {
        names[0x0000000000000000000000000000000000000000] = "string";
    }

    // You need to send a transaction to write to a state variable.
    function set(string calldata _text) public {
        names[msg.sender] = _text;
    }

    }