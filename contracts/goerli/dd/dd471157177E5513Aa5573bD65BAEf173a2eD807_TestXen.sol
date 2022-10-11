/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TestXen {
    uint256 public num = 0;
    function claimRank(uint256 term) external {
        num += term;
    }
}