/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract AAA {
    string[] nameArray;

    function addName(string memory a) public {
        nameArray.push(a);
    }

    function findName(uint a) public view returns(string memory) {
        return nameArray[a-1];
    }
}