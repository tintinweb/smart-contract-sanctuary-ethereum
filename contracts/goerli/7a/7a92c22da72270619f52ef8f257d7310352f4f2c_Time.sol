/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.15;

contract Time {
    uint256 public time;

    function set() public {
        time = block.timestamp;
    }

    function get() public view returns (uint256, uint256) {
        return (block.timestamp, block.number);
    }
}