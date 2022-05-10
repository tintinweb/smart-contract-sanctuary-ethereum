/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleContract {
    string public _name;
    address public _owner;

    constructor(string memory name, address owner) {
        _name = name;
        _owner = owner;
    }
}