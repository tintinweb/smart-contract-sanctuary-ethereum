/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Hello {
    string public name;

    constructor() {
        name = "abc";
    }

    function setName(string memory _name) public {
        name = _name;
    }
}