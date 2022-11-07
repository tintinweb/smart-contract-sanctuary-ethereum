// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IInterestStrategy {
    function interestPerSecond() external view returns (uint64);

    function lastAccrued() external view returns (uint64);

    function pendingFeeEarned() external view returns (uint128);

    function principal() external view returns (uint256);
}

contract InterestStrategyLens {
    function previewAccrue(IInterestStrategy strategy) external view returns (uint128, uint128) {
        uint64 lastAccrued = strategy.lastAccrued();
        uint64 interestPerSecond = strategy.interestPerSecond();
        uint128 pendingFeeEarned = strategy.pendingFeeEarned();
        uint128 interest;
        uint256 principal = strategy.principal();

        if (lastAccrued == 0) {
            if (principal > 0) {
                lastAccrued = uint64(block.timestamp);
            }
            return (interest, pendingFeeEarned);
        }

        uint256 elapsedTime = block.timestamp - lastAccrued;
        if (elapsedTime == 0) {
            return (interest, pendingFeeEarned);
        }

        lastAccrued = uint64(block.timestamp);

        if (principal == 0) {
            return (interest, pendingFeeEarned);
        }

        interest = uint128((principal * interestPerSecond * elapsedTime) / 1e18);
        pendingFeeEarned += interest;

        return (interest, pendingFeeEarned);
    }
}