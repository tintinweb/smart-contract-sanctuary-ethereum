/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Web03{
    constructor() {

    }
    string public constant url = 'web03.cn';
    mapping (uint => string) public names;
    uint public namesN;
    function addName(string memory _name) public {
        names[namesN++] = _name;
    }
}