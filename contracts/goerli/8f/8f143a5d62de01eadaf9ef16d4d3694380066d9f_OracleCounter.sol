/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract OracleCounter {
    uint256 public count;

    constructor() {
    }

    // solhint-disable not-rely-on-time
    function increaseCount(uint256 amount) external {
        count += amount;
    }
}