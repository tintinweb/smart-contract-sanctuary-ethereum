/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract UserInfo{
    mapping(address => string) userInfo;

    function setUserInfo(string memory cid) public { 
        userInfo[msg.sender] = cid;
    }

    function getUserInfo(address addr) public view returns (string memory) {
        return userInfo[addr];
    }
}