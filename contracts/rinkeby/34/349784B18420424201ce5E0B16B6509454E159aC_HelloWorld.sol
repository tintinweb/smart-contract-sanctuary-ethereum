/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    string private name;

    constructor(string memory _name) {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }
    function setName(string memory _name) public {
        name = _name;
    }
}