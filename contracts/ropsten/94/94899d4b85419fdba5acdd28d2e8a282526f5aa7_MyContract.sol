/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {

    uint256 public startTime = 1651434180;

    function test() external payable {
        if (block.timestamp < startTime) {
            revert('Too early');
        }
    }

    function changeTime(uint256 ts) external {
        startTime = ts;
    }
}