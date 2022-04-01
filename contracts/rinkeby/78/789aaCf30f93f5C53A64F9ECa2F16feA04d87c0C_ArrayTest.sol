/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract ArrayTest {
    mapping(uint256 => bool) public flags;

    function setFlags(uint16[] memory values) public {
        for (uint256 i = 0; i < values.length; i++) {
            flags[values[i]] = true;
        }
    }
}