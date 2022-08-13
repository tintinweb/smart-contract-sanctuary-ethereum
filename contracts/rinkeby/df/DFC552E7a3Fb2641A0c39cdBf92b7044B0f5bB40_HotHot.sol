/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract HotHot {
    mapping(address => uint16) balance;

    function mint(uint8 count) public  {
        balance[msg.sender] += count;
    }
}