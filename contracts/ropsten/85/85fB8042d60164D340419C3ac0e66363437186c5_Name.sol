/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Name {
    event SayHi(string name);
    string private name;

    constructor(string memory _name) {
        name = _name;
    }

    function getName() public view returns (string memory) {
        
        return name;
    }

    function setName(string memory _name) public {
        emit SayHi(name);
        name = _name;
    }
}