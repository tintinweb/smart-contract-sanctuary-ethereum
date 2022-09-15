/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IMergeOracle {
    /// Returns the earliest block on which we know the merge was already active.
    function mergeBlock() external view returns (uint256);

    /// Returns the timestamp of the recorded block.
    function mergeTimestamp() external view returns (uint256);
}

contract MergeOracle is IMergeOracle {
    uint256 public immutable override mergeBlock = block.number;
    uint256 public immutable override mergeTimestamp = block.timestamp;
}