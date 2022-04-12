/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.24;

contract SimpleStorage {
    string str;

    constructor(string _str) public {
        str = _str;
    }

    function setValue(string _str) public {
        str = _str;
    }

    function getValue() public view returns (string) {
        return str;
    }
}