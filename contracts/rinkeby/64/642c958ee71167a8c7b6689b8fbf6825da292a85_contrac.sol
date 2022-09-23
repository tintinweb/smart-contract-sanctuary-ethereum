/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract contrac {
    string[] nameList;

    function pushName(string memory name) public returns(string memory){
        nameList.push(name);
        return nameList[nameList.length-1];
    }
}