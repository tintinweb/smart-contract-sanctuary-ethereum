/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17.0;

contract Study_05_1 {
    address public owner;
    mapping(address => uint256) public values;

    
    function funcB(address a ,uint256 i) external{
        require(msg.sender == owner,"Owner Only");
        values[a] += i;
    }

}