/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract Person {
    string public name;
    uint256 public age;

    event NameSet(string name);
    event AgeSet(uint256 age);

    constructor() {
        name = "John Doe";
        age = 35;

        emit NameSet(name);
        emit AgeSet(age);
    }
}