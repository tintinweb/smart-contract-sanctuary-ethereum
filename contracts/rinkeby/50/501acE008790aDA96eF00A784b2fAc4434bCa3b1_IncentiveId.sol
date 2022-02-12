// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.6;

/// @param rewardToken The token being distributed as a reward
/// @param pool The Uniswap V3 pool
/// @param startTime The time when the incentive program begins
/// @param endTime The time when rewards stop accruing
/// @param refundee The address which receives any remaining reward tokens when the incentive is ended
struct IncentiveKey {
    address rewardToken;
    address pool;
    uint256 startTime;
    uint256 endTime;
    address refundee;
}

contract IncentiveId {
    /// @notice Calculate the key for a staking incentive
    /// @param key The components used to compute the incentive identifier
    /// @return incentiveId The identifier for the incentive
    function compute(IncentiveKey memory key) external pure returns (bytes32 incentiveId) {
        return keccak256(abi.encode(key));
    }
}