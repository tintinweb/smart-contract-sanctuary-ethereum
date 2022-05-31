/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Box {
    uint256 public val;

    function initialize(uint256 _val) external {
        val = _val;
    }
}