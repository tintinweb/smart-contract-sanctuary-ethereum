// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "./SafeERC20.sol";
import {FeeSharingSystem} from "./FeeSharingSystem.sol";
import "./Ownable.sol";
/**
 * @title FeeSharingSetter
 * @notice It receives NovaPlanet protocol fees and owns the FeeSharingSystem contract.
 * It can plug to AMMs for converting all received currencies to WETH.
 */
contract FeeSharingManager is Ownable{
    using SafeERC20 for IERC20;


    // Min duration for each fee-sharing period (in blocks)
    uint256 public immutable MIN_REWARD_DURATION_IN_BLOCKS;

    // Max duration for each fee-sharing period (in blocks)
    uint256 public immutable MAX_REWARD_DURATION_IN_BLOCKS;

    IERC20 public immutable npcToken;

    IERC20 public immutable rewardToken;

    FeeSharingSystem public feeSharingSystem;

    // Last reward block of distribution
    uint256 public lastRewardDistributionBlock;

    // Next reward duration in blocks
    uint256 public nextRewardDurationInBlocks;

    // Reward duration in blocks
    uint256 public rewardDurationInBlocks;


    event NewFeeSharingSystemOwner(address newOwner);
    event NewRewardDurationInBlocks(uint256 rewardDurationInBlocks);

    /**
     * @notice Constructor
     * @param _feeSharingSystem address of the fee sharing system
     * @param _minRewardDurationInBlocks minimum reward duration in blocks
     * @param _maxRewardDurationInBlocks maximum reward duration in blocks
     * @param _rewardDurationInBlocks reward duration between two updates in blocks
     */
    constructor(
        address _feeSharingSystem,
        uint256 _minRewardDurationInBlocks,
        uint256 _maxRewardDurationInBlocks,
        uint256 _rewardDurationInBlocks
    ) {
        require(
            (_rewardDurationInBlocks <= _maxRewardDurationInBlocks) &&
                (_rewardDurationInBlocks >= _minRewardDurationInBlocks),
            "Owner: Reward duration in blocks outside of range"
        );

        MIN_REWARD_DURATION_IN_BLOCKS = _minRewardDurationInBlocks;
        MAX_REWARD_DURATION_IN_BLOCKS = _maxRewardDurationInBlocks;

        feeSharingSystem = FeeSharingSystem(_feeSharingSystem);

        rewardToken = feeSharingSystem.rewardToken();
        npcToken = feeSharingSystem.novaPlanetToken();

        rewardDurationInBlocks = _rewardDurationInBlocks;
        nextRewardDurationInBlocks = _rewardDurationInBlocks;

    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev It automatically retrieves the number of pending WETH and adjusts
     * based on the balance of NPC in fee-staking addresses that exist in the set.
     */
    function updateRewards() external onlyOwner {
        if (lastRewardDistributionBlock > 0) {
            require(block.number > (rewardDurationInBlocks + lastRewardDistributionBlock), "Reward: Too early to add");
        }

        // Adjust for this period
        if (rewardDurationInBlocks != nextRewardDurationInBlocks) {
            rewardDurationInBlocks = nextRewardDurationInBlocks;
        }

        lastRewardDistributionBlock = block.number;

        // Calculate the reward to distribute as the balance held by this address
        uint256 reward = rewardToken.balanceOf(address(this));

        require(reward != 0, "Reward: Nothing to distribute");

        // Transfer tokens to fee sharing system
        rewardToken.safeTransfer(address(feeSharingSystem), reward);

        // Update rewards
        feeSharingSystem.updateRewards(reward, rewardDurationInBlocks);
    }

    

    /**
     * @notice Set new reward duration in blocks for next update
     * @param _newRewardDurationInBlocks number of blocks for new reward period
     */
    function setNewRewardDurationInBlocks(uint256 _newRewardDurationInBlocks) external onlyOwner {
        require(
            (_newRewardDurationInBlocks <= MAX_REWARD_DURATION_IN_BLOCKS) &&
                (_newRewardDurationInBlocks >= MIN_REWARD_DURATION_IN_BLOCKS),
            "Owner: New reward duration in blocks outside of range"
        );

        nextRewardDurationInBlocks = _newRewardDurationInBlocks;

        emit NewRewardDurationInBlocks(_newRewardDurationInBlocks);
    }

   
    /**
     * @notice Transfer ownership of fee sharing system
     * @param _newOwner address of the new owner
     */
    function transferOwnershipOfFeeSharingSystem(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Owner: New owner cannot be null address");
        feeSharingSystem.transferOwnership(_newOwner);

        emit NewFeeSharingSystemOwner(_newOwner);
    }


}