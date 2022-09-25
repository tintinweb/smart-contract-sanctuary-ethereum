/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract AAA {
    string[] nameList;

    function pushName(string memory _name) public {
        nameList.push(_name);
    }

    function getLength() public view returns(uint) {
        return nameList.length;
    }

    function getName(uint a) public view returns(string memory) {
        return nameList[a-1];
    }
}