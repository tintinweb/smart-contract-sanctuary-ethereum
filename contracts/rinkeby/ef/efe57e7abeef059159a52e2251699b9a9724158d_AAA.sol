/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 < 0.9.0;

contract AAA {
    string[] name;

    function pushName(string memory _n) public{
        name.push(_n);
    }

    function getLength() public view returns(uint) {
        return name.length;
    }

    function getName(uint _a) public view returns(string memory) {
        return name[_a];
    }
}