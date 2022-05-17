/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Hello {
    string public name;
    constructor() {
        name = "HelloWorld!";
    }
    function setName(string memory _name) public {
        name = _name;
    }
}