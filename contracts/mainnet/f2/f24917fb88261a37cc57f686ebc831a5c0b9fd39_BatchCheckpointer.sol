/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface LiquidityGaugeV5 {
    function claimable_tokens(address user) external returns (uint256);
}

contract BatchCheckpointer {
    function batchCheckpoint(LiquidityGaugeV5 gauge, address[] calldata users) external {
        uint256 totalUsers = users.length;
        for (uint256 i = 0; i < totalUsers; ++i) {
            gauge.claimable_tokens(users[i]);
        }
    }
}