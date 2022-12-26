// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract A {
    uint num;
    string name;
    constructor(uint _num, string memory _name) {
        num = _num;
        name = _name;
    }

    function getNumAndName() public view returns(uint, string memory) {
        return (num, name);
    }

}