/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Indentifier: Unlicensed
pragma solidity 0.8.12;

contract Box {
    uint256 public val;

    function initialize(uint256 _val) external {
        val = _val;
    }
}