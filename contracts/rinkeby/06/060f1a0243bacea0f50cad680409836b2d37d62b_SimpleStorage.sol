/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7 <0.9;


contract SimpleStorage{
    mapping(string => uint256) public nameToNum;

    function addPerson(string memory name, uint256 num) public {
        nameToNum[name] = num;
    }
}