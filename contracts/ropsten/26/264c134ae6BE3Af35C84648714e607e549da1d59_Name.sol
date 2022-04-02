/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Name {
    event SayHi(string name);
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    function getName() public returns (string memory) {
        emit SayHi(name);
        return name;
    }
}