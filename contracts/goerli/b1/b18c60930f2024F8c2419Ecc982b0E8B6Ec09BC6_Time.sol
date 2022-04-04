// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Time {
    uint256 public nextExec;

    function increaseTime(uint256 _interval) external {
        require(nextExec + _interval > block.timestamp);

        nextExec = block.timestamp;
    }
}