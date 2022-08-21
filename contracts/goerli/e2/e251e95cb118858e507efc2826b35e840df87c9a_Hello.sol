/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

/*
SPDX-License-Identifier: UNLICENSED
*/

pragma solidity ^0.8.16;

contract Hello {
    string public name;
    
    constructor() {
        name = unicode"我是一個智能合約！";
    }
    
    function setName(string memory _name) public {
        name = _name;
    }
}