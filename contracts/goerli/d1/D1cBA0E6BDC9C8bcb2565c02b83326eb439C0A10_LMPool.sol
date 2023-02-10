// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract LMPool {
    event UpdatePosition();
    event AccumulateReward();

    function updatePosition(
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta
    ) external {
        emit UpdatePosition();
    }

    function getRewardGrowthInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint256 rewardGrowthInsideX128)
    {
        return block.timestamp;
    }

    function accumulateReward(uint32 currTimestamp) external {
        emit AccumulateReward();
    }
}