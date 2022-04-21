/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Hello{
    string public name;
    constructor() {
        name = "im a contract";
    }
    function setName(string memory _name) public{
        name = _name;
    }
}