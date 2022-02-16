/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract time {
    uint256 public lastBlock;
    uint256 public earnings;
    uint256 public interval;

    constructor (
        uint256 _interval
        ) {
            lastBlock = block.timestamp; 
            interval = _interval;
    }

    function startEarning() public {
        uint a = 1;
        while (a > 0 && a < 3) {
            if (block.timestamp >= lastBlock + interval) {
                earnings += 2;
                lastBlock = block.timestamp;
            }
            a += 1;
        }
    }

}