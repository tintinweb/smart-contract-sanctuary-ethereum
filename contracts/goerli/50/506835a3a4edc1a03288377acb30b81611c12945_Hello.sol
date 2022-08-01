/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

contract Hello {
    string public name;
    
    constructor() {
        name = "\u6211\u662f\u4e00\u500b\u667a\u80fd\u5408\u7d04\uff01";
    }
    
    function setName(string memory _name) public returns(string memory) {
        name = _name;
    }
}