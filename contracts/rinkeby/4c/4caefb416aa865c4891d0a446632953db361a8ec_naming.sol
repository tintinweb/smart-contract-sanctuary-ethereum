/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;


contract naming {
    string[] name;

    function setName(string memory n) public {
        name.push(n);
    }

    function getName(uint i) public view returns(string memory) {
        return name[i-1];
    }
}