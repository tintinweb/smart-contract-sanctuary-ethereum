/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Calculator{
     uint256 public result;

    function add(uint256 x, uint256 y) external{
        result = x+y;
    }

}