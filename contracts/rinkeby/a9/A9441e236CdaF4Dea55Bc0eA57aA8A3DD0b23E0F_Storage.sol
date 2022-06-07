/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    string text;

    constructor() {
        text = "Hello World!";
    }

    function store(string memory str) public {
        text = str;
    }

    function retrieve() public view returns (string memory){
        return text;
    }
}