/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract KeeperTimeBase {
    uint256 public counter = 0;

    event Log(uint256 timestamp, uint256 counter);

    function timeBaseCallback() external {
        counter++;
        emit Log(block.timestamp, counter++);
    }
}