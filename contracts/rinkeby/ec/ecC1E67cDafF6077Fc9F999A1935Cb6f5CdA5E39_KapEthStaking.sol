// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IVotingWeightSource.sol";
import "./Staking.sol";

/**
 * @title Kapital DAO KAP-ETH LP Staking Pool
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Staking pool for Kapital DAO members to stake Uniswap V2 KAP-ETH LP
 * tokens
 */
contract KapEthStaking is Staking, ILPSource {
    constructor(
        uint256 rewardsStart,
        address asset, // KAP-ETH Uniswap V2 pair address
        address governanceRegistry,
        address rewardsLocker
    ) Staking(rewardsStart, asset, governanceRegistry, rewardsLocker) {
        /**
         * @dev Add a initial base rewards rule.
         * In the 1st 52 weeks, 4% of total supply(40,000,000) will be distributed as base rewards.
         * And up to 4% of total supply will be distributed as boost rewards(boost factor is 1).
         * Actual boost rewards amount will depend on the users' activity of restaking and claiming rewards.
         */
        _addRewardsRule(4e7 ether / uint256(52 weeks), 52 weeks);
    }

    /**
     * @notice Used to determine voting weight
     * @param voter The address voting on the governance proposal
     * @return KAP-ETH LP weight of `voter`
     */
    function weightLP(address voter) external view returns (uint256) {
        return _weightAsset(voter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interfaces for reporting Voting Weights
 * @author Playground Labs
 */

/// @notice Reports the KAP voting weight of the voter
interface IKAPSource {
    function weightKAP(address voter) external view returns (uint256);
}

/// @notice Reports the LP voting weight of the voter
interface ILPSource {
    function weightLP(address voter) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRewardsLocker.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IGovernanceRegistry.sol";
import "./libraries/Math.sol";

/**
 * @title Kapital DAO Staking Pool
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Base staking pool contract used for both the KAP staking pool and
 * the KAP-ETH Uniswap V2 liquidity staking pool
 * @notice The word "rewards" always refers to an amount of KAP given to a user
 * in return for the user's agreement to stake (and lock) an asset in the
 * staking pool
 */
contract Staking is IStaking {
    /**
     * @dev Governance Registry contract, which holds the address
     * of the current governance contract which is given permission to call
     * {addRewardsRule}, {adjustRewardsRule}, and {adjustRestakeBoostingFactor}
     */
    IGovernanceRegistry public immutable governanceRegistry;
    /**
     * @dev Rewards locker contract is called in {claimRewards} to create a
     * lock agreement for the claimed rewards
     */
    IRewardsLocker public immutable rewardsLocker;
    /**
     * @dev Asset to be staked, KAP or KAP-ETH LP token. For the KAP-ETH LP
     * token, `address(asset)` is the address of the Uniswap V2 pair.
     */
    IERC20 public immutable asset;
    /**
     * @dev Timestamp when the staking pool starts giving out rewards. Acts as
     * as delay, so that early stakers do not accumulate a large amount of
     * rewards before the total staking weight becomes reasonably large.
     */
    uint256 public immutable rewardsStart;
    /**
     * @dev If `syncdTo == block.timestamp`, then {rewardsRuleIndex} is such
     * that current rewards per second given out by the contract is
     * `rewardsRule[rewardsRuleIndex].kapPerSecond`
     */
    uint256 public rewardsRuleIndex;
    /**
     * @dev Keeps track of the total staking weight and rewards accumulation
     * state of the contract, ordered by block timestamp
     */
    Checkpoint[] public checkpoints;
    /**
     * @dev When storing the updated total rewards per weight in {sync}, we
     * multiply the rewards by {REWARDS_PER_WEIGHT_MULTIPLIER} before dividing
     * by the total staking weight in order to mitigate the loss of accuracy
     * from integer division. We keep the word "multiplied" explicit in
     * {multipliedTotalRewardsPerWeight} to emphasize that one must
     * divide by {REWARDS_PER_WEIGHT_MULTIPLIER} when converting back to
     * rewards.
     */
    uint256 public constant REWARDS_PER_WEIGHT_MULTIPLIER = 1e12;
    /**
     * @dev Usually, the timestamp of when {sync} was last called. If a rewards
     * rule was "skipped" because {sync} was not called during that rewards
     * period, then `syncdTo` is the time up to which the state data is syncd.
     * By repeatedly calling {sync}, the state will eventually sync to the
     * current block timestamp.
     */
    uint256 public syncdTo;
    /// @dev Minimum allowed value of `lockEnd - lockStart` for a {StakingAgreement}
    uint256 public constant MINIMUM_LOCK_PERIOD = 4 weeks;
    /// @dev Maximum allowed value of `lockEnd - lockStart` for a {StakingAgreement}
    uint256 public constant MAXIMUM_LOCK_PERIOD = 52 weeks;

    /**
     * @dev Conceptually,
     * `restakeRewards = pendingRewards * (1 + boost * (lockRemaining / lockPeriod) * (extendPeriod / maxExtendPeriod))`
     * where `boost = restakeBoostingFactor / RESTAKE_BOOSTING_MULTIPLIER`. In
     * practice, the order of multiplication and division is important to avoid
     * loss of accuracy. See {restake}.
     */
    uint256 public restakeBoostingFactor = 1e6;
    /**
     * @dev Multiplier of boost, in order to mitigate the loss of accuracy from integer division.
     */
    uint256 public constant RESTAKE_BOOSTING_MULTIPLIER= 1e6;

    /// @dev Organizes all {Staker}s by address
    mapping(address => Staker) public stakers;
    /**
     * @dev Timestamp of the most recent time the address called {stake}. Used
     * in {_weightAsset} to prohibit users from voting during the same
     * voting period in which they staked.
     */
    mapping(address => uint256) public lastStaked;
    /// @dev Used to keep track of current rewards emission rate
    RewardsRule[] public rewardsRules;

    /**
     * @dev Used in security monitoring to keep track of how much boosted
     * rewards are being allocated to the community.
     */
    uint256 public totalBoostedRewardsAmount;

    constructor(
        uint256 _rewardsStart,
        address _asset,
        address _governanceRegistry,
        address _rewardsLocker
    ) {
        require(_rewardsStart >= block.timestamp, "Invalid rewards start");
        require(_asset != address(0), "Zero address");
        require(_governanceRegistry != address(0), "Zero address");
        require(_rewardsLocker != address(0), "Zero address");
        
        rewardsStart = _rewardsStart;
        asset = IERC20(_asset);
        governanceRegistry = IGovernanceRegistry(_governanceRegistry);
        rewardsLocker = IRewardsLocker(_rewardsLocker);

        // Initiate a rewards rule of zero until {rewardsStart}
        _addRewardsRule(0, uint64(_rewardsStart - block.timestamp));
        // See {sync}. Below is a "pseudo-sync", so that the contract is up to
        // date at the start and the {checkpoints} zero index is guaranteed to
        // exist.
        checkpoints.push(
            Checkpoint({
                totalWeight: 0,
                multipliedTotalRewardsPerWeight: 0,
                time: block.timestamp
            })
        );
        syncdTo = block.timestamp;
    }

    /**
     * @notice Used on front-end
     * @return `rewardsRules`
     */
    function getRewardsRules() external view returns (RewardsRule[] memory) {
        return rewardsRules;
    }

    /**
     * @notice Used on the front-end
     * @param staker Address of staked user
     * @return `stakingAgreements` associated with `staker`
     */
    function getStakingAgreements(address staker)
        external
        view
        returns (StakingAgreement[] memory)
    {
        return stakers[staker].stakingAgreements;
    }

    /**
     * @notice Used on the front-end
     * @return `checkpoints`
     */
    function getCheckpoints() external view returns (Checkpoint[] memory) {
        return checkpoints;
    }

    /**
     * @dev Used by staking pools to report voting weight
     * @param voter Address of the voting user
     * @return 0 if voter has called {stake} within the current voting period,
     * otherwise return the `totalAmount` of {asset} associated with `voter`
     */
    function _weightAsset(address voter) internal view returns (uint256) {
        uint256 votingPeriod = IGovernance(governanceRegistry.governance())
            .votingPeriod();
        return
            (block.timestamp <= (lastStaked[voter] + votingPeriod))
                ? 0
                : stakers[voter].stakedAmount;
    }

    /**
     * @notice Used on the front-end and in {getPendingRewards} to determine
     * the relevant {checkpoints} index for rewards calculations
     * @param time Block timestamp at which the checkpoint Id applies
     */
    function getCheckpointId(
        uint256 time
    ) public view returns (uint256) {
        // a checkpoint at index `0` is added in the constructor
        require(
            checkpoints[0].time <= time,
            "Staking: Time too small"
        );
        // this function can only be used when `time` is less than
        // or equal to the last sync checkpoint
        require(
            time <= checkpoints[checkpoints.length - 1].time,
            "Staking: Time too large"
        );

        uint256 high = checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (checkpoints[mid].time > time) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // `high > 0`, since otherwise `checkpoints[0].time > time` which
        // contradicts the first requirement of {getCheckpointId}
        return high - 1;
    }

    /**
     * @notice Used on the front-end and in {getPendingRewards} to determine
     * the relevant {rewardsRules} index for rewards calculations
     * @param time Block timestamp at which the rewards rule Id applies
     */
    function getRewardsRuleId(uint256 time) public view returns (uint256) {
        // a {RewardsRule} at index `0` is added in the constructor
        // of implementation contracts
        require(
            rewardsRules[0].timeStart < time,
            "Staking: Time too small"
        );
        require(
            time <= rewardsRules[rewardsRules.length - 1].timeEnd,
            "Staking: Time too large"
        );

        uint256 high = rewardsRules.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            // `timeStart` will be equal to `timeEnd` of previous rewardsRule.
            // we use `>=` here instead of `>` to return the index of the
            // earlier rewards rule in the even that `time` is exactly at the
            // timestamp of a rewards rule transition.
            if (rewardsRules[mid].timeStart >= time) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // `high > 0`, since otherwise `rewardsRules[0].timeStart >= time`
        // which contradicts the first requirement of {getRewardsRuleId}
        return high - 1;
    }

    /**
     * @notice Used in {restake} and on the front-end
     * @dev Computes pending rewards in a manner similar to {claimRewards}, but
     * does not change contract state
     * @param user Address of staked user
     * @param stakingAgreementId Index of relevant staking agreement
     * @return Pending (unclaimed) rewards associated with `user`
     */
    function getPendingRewards(
        address user,
        uint256 stakingAgreementId
    ) public view returns (uint256) {
        // no rewards are accumulated before {rewardsStart}
        if (block.timestamp <= rewardsStart) {
            return 0;
        }

        require(
            block.timestamp <= rewardsRules[rewardsRuleIndex].timeEnd,
            "Need to sync"
        );

        Staker storage staker = stakers[user];
        StakingAgreement storage stakingAgreement = staker.stakingAgreements[stakingAgreementId];
        uint256 lockEnd = stakingAgreement.lockEnd;

        uint256 multipliedTotalRewardsPerWeightRelevant;
        // If position hasn't unlocked yet
        if (block.timestamp <= stakingAgreement.lockEnd) {
            Checkpoint storage checkpoint = checkpoints[checkpoints.length - 1];
            RewardsRule storage rewardsRule = rewardsRules[rewardsRuleIndex];
            multipliedTotalRewardsPerWeightRelevant =
                checkpoint.totalWeight == 0
                ? checkpoint.multipliedTotalRewardsPerWeight
                : checkpoint.multipliedTotalRewardsPerWeight
                    + rewardsRule.kapPerSecond 
                    * (block.timestamp - checkpoint.time)
                    * REWARDS_PER_WEIGHT_MULTIPLIER
                    / checkpoint.totalWeight;
        } else {
            Checkpoint storage checkpoint = checkpoints[getCheckpointId(lockEnd)];
            RewardsRule storage rewardsRule = rewardsRules[getRewardsRuleId(lockEnd)];
            // Update multipliedTotalRewardsPerWeightRelevant to lockEnd
            multipliedTotalRewardsPerWeightRelevant =
                checkpoint.totalWeight == 0
                ? checkpoint.multipliedTotalRewardsPerWeight
                : checkpoint.multipliedTotalRewardsPerWeight
                    + rewardsRule.kapPerSecond 
                    * (stakingAgreement.lockEnd - checkpoint.time)
                    * REWARDS_PER_WEIGHT_MULTIPLIER
                    / checkpoint.totalWeight;
        }
        uint256 stakingWeight = _calculateStakeWeight(
            stakingAgreement.lockEnd-stakingAgreement.lockStart, 
            stakingAgreement.amount
        );
        uint256 totalRewards = (stakingWeight *
            multipliedTotalRewardsPerWeightRelevant) /
            REWARDS_PER_WEIGHT_MULTIPLIER;
        
        return totalRewards - stakingAgreement.subtractRewards;
    }

    /**
     * @notice Used to stake {asset} in return for rewards
     * @param inputAmount Amount of {asset} to provided by user
     * @param lockPeriod Time before `amount` of {asset} can be {unstake}d
     * @dev `inputAmount` may differ from `addAmount`
     */
    function stake(uint256 inputAmount, uint256 lockPeriod) external {
        // update {checkpoints} if necessary
        if (block.timestamp > syncdTo) {
            sync();
            require(syncdTo == block.timestamp, "Staking: Multiple syncs needed");
        }
        lastStaked[msg.sender] = block.timestamp;

        Staker storage staker = stakers[msg.sender];
        StakingAgreement storage stakingAgreement = staker.stakingAgreements[
            _newStakingAgreement(staker, lockPeriod)
        ];
        uint256 addAmount = _transferFromAndReturnAddAmount(
            msg.sender,
            inputAmount
        );

        require(addAmount > 0, "Staking: Invalid amount");
        require(
            (MINIMUM_LOCK_PERIOD <= lockPeriod) &&
                (lockPeriod <= MAXIMUM_LOCK_PERIOD),
            "Staking: Invalid lock period"
        );

        staker.stakedAmount += addAmount;
        stakingAgreement.amount = Math.toUint112(addAmount);

        uint256 stakeWeight = _calculateStakeWeight(lockPeriod, addAmount);
        Checkpoint storage checkpoint = checkpoints[checkpoints.length - 1];
        checkpoint.totalWeight += stakeWeight;
        // Ignore the accumulated rewards before the user started staking.
        // See {getPendingRewards} and {claimRewards}.
        stakingAgreement.subtractRewards =
            (stakeWeight * checkpoints[checkpoints.length - 1].multipliedTotalRewardsPerWeight) /
            REWARDS_PER_WEIGHT_MULTIPLIER;

        emit Stake(msg.sender, addAmount, lockPeriod);
    }

    /**
     * @notice Used to claim deposited {asset} after lock period is complete.
     * @param stakingAgreementId Index in `msg.sender`'s `stakingAgreements`
     */
    function unstake(uint256 stakingAgreementId)
        external
    {
        // update {checkpoints} if necessary
        if (block.timestamp > syncdTo) {
            sync();
            require(syncdTo == block.timestamp, "Staking: Multiple syncs needed");
        }

        Staker storage staker = stakers[msg.sender];
        StakingAgreement storage stakingAgreement = staker.stakingAgreements[
            stakingAgreementId
        ];

        require(
            (!stakingAgreement.collected),
            "Staking: Already collected"
        );
        require(
            block.timestamp >= stakingAgreement.lockEnd,
            "Staking: Too early"
        );

        uint112 amount = stakingAgreement.amount;
        staker.stakedAmount -= amount;

        uint256 unstakeWeight = _calculateStakeWeight(
            stakingAgreement.lockEnd - stakingAgreement.lockStart,
            amount
        );
        Checkpoint storage checkpoint = checkpoints[checkpoints.length - 1];
        checkpoint.totalWeight -= unstakeWeight;
        stakingAgreement.collected = true;

        SafeERC20.safeTransfer(asset, msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    /**
     * @notice Used to extend staking period in return for boosted rewards
     * @param stakingAgreementId Index in `msg.sender`'s `stakingAgreements`
     * @param extendPeriod Lock period extension
     */
    function restake(uint256 stakingAgreementId, uint256 extendPeriod) external {
        // update {checkpoints} if necessary
        if (block.timestamp > syncdTo) {
            sync();
            require(syncdTo == block.timestamp, "Staking: Multiple syncs needed");
        }

        Staker storage staker = stakers[msg.sender];
        StakingAgreement storage stakingAgreement = staker.stakingAgreements[
            stakingAgreementId
        ];

        uint256 newLockStart = block.timestamp;

        /**
         * @dev Make sure the rewards have started, and make sure the staking
         * lock period has not ended
         */
        require(
            newLockStart > rewardsStart && newLockStart < stakingAgreement.lockEnd,
            "Staking: Invalid restake"
        );

        uint256 maximumRestakeExtendPeriod = MAXIMUM_LOCK_PERIOD - (stakingAgreement.lockEnd - newLockStart);
        require(
            extendPeriod > 0 && 
            extendPeriod <= maximumRestakeExtendPeriod &&
            (stakingAgreement.lockEnd - newLockStart + extendPeriod) >= MINIMUM_LOCK_PERIOD,
            "Staking: Invalid extension"
        );

        // calculate base pending rewards
        uint256 pendingRewards = getPendingRewards(msg.sender, stakingAgreementId);
        require(pendingRewards > 0, "No pending rewards");

        // `boostedRewardsAmount` has the property that
        // `boostedRewardsAmount < pendingRewards * boost,
        // where `boost = restakeBoostingFactor / RESTAKE_BOOSTING_MULTIPLIER`.
        // This property allows the {RewardsRule}s to be chosen carefully, so
        // that stakers are not promised more rewards than the DAO treasury can
        // handle.
        uint256 boostedRewardsAmount = 
            pendingRewards * 
            restakeBoostingFactor * 
            (stakingAgreement.lockEnd - newLockStart) *
            extendPeriod /
            (stakingAgreement.lockEnd - stakingAgreement.lockStart) /
            maximumRestakeExtendPeriod /
            RESTAKE_BOOSTING_MULTIPLIER;

        uint256 oldStakingAgreementWeight = _calculateStakeWeight(
            stakingAgreement.lockEnd - stakingAgreement.lockStart, 
            stakingAgreement.amount
        );
        uint256 newStakingAgreementWeight = _calculateStakeWeight(
            stakingAgreement.lockEnd - newLockStart + extendPeriod, 
            stakingAgreement.amount
        );

        Checkpoint storage checkpoint = checkpoints[checkpoints.length - 1];

        // update staking agreement
        stakingAgreement.subtractRewards = 
            (newStakingAgreementWeight * checkpoint.multipliedTotalRewardsPerWeight) / REWARDS_PER_WEIGHT_MULTIPLIER;
        stakingAgreement.lockStart = SafeCast.toUint64(newLockStart);
        stakingAgreement.lockEnd += SafeCast.toUint64(extendPeriod);

        // update total weight
        checkpoint.totalWeight = checkpoint.totalWeight + newStakingAgreementWeight - oldStakingAgreementWeight;

        // sum up boosted rewards amount
        totalBoostedRewardsAmount += boostedRewardsAmount;

        // rewards are made available to the user 52 weeks after {claimRewards}
        // is called, in the form of a {LockAgreement} in {RewardsLocker}
        rewardsLocker.createLockAgreement(msg.sender, pendingRewards + boostedRewardsAmount);

        // boost kapPerSecond by the leftOver rewards amount. this is the
        // difference between the current boosted claim
        // `pendingRewards + boostedRewardsAmount`, and the hypothetical
        // maximum boosted claim `pendingRewards * (1 + boost)`
        uint256 leftOverRewardsAmount = pendingRewards * restakeBoostingFactor / RESTAKE_BOOSTING_MULTIPLIER - boostedRewardsAmount;
        _boostKapPerSecondByLeftOverRewards(leftOverRewardsAmount);

        emit Restake(msg.sender, stakingAgreement.amount, extendPeriod, boostedRewardsAmount);
    }

    /**
     * @param lockPeriod Time before `amount` of {asset} can be {unstake}d
     * @param amount Amount of {asset}
     * @return Stake weight associated with `amount` and `lockPeriod`
     */
    function _calculateStakeWeight(uint256 lockPeriod, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return lockPeriod * amount;
    }

    /**
     * @notice Used to claim pending staking rewards
     * @param stakingAgreementId Index of relevant staking agreement
     * @param checkpointIdLockEnd Result of
     * `getCheckpointId(stakingAgreement.lockEnd)` when
     * `block.timestamp > lockEnd`, irrelvant otherwise
     * @param rewardsRuleIdLockEnd Result of
     * `getRewardsRuleId(stakingAgreement.lockEnd)` when
     * `block.timestamp > lockEnd`, irrelvant otherwise
     */
    function claimRewards(
        uint256 stakingAgreementId,
        uint256 checkpointIdLockEnd,
        uint256 rewardsRuleIdLockEnd
    ) external {
        // update {checkpoints} if necessary
        if (block.timestamp > syncdTo) {
            sync();
            require(syncdTo == block.timestamp, "Staking: Multiple syncs needed");
        }

        Staker storage staker = stakers[msg.sender];
        StakingAgreement storage stakingAgreement = staker.stakingAgreements[stakingAgreementId];
        uint256 claimedRewards;
        // no rewards to claim before {rewardsStart}
        if (block.timestamp <= rewardsStart) {
            claimedRewards = 0;
        } else {
            uint256 multipliedTotalRewardsPerWeightRelevant;
            // If position hasn't unlocked yet
            if (block.timestamp <= stakingAgreement.lockEnd) {
                multipliedTotalRewardsPerWeightRelevant = checkpoints[checkpoints.length - 1].multipliedTotalRewardsPerWeight;
            } else {
                // Verify Ids are the latest before lockEnd
                require(checkpointIdLockEnd < checkpoints.length, "Staking: Invalid checkpoint");
                Checkpoint storage checkpoint = checkpoints[checkpointIdLockEnd];
                require(checkpoint.time <= stakingAgreement.lockEnd, "Staking: Late checkpoint");
                
                // In this case, `block.timestamp > stakingAgreement.lockEnd`
                // and `syncdTo == block.timestamp`, so there must be a
                // checkpoint at `block.timestamp` and hence the index
                // `checkpointIdLockEnd + 1` exists in `checkpoints`.
                Checkpoint storage checkpointNext = checkpoints[checkpointIdLockEnd + 1];
                require(stakingAgreement.lockEnd < checkpointNext.time, "Staking: Early checkpoint");
                
                RewardsRule storage rewardsRule = rewardsRules[rewardsRuleIdLockEnd];
                require(rewardsRule.timeStart < stakingAgreement.lockEnd, "Staking: Late RewardsRule");
                require(stakingAgreement.lockEnd <= rewardsRule.timeEnd, "Staking: Early RewardsRule");
                
                // Update multipliedTotalRewardsPerWeightRelevant to lockEnd
                multipliedTotalRewardsPerWeightRelevant =
                    checkpoint.totalWeight == 0
                    ? checkpoint.multipliedTotalRewardsPerWeight
                    : checkpoint.multipliedTotalRewardsPerWeight
                        + rewardsRule.kapPerSecond 
                        * (stakingAgreement.lockEnd - checkpoint.time)
                        * REWARDS_PER_WEIGHT_MULTIPLIER
                        / checkpoint.totalWeight;
            }
            uint256 stakingWeight = _calculateStakeWeight(
                stakingAgreement.lockEnd-stakingAgreement.lockStart, 
                stakingAgreement.amount
            );
            uint256 totalRewards = (stakingWeight *
                multipliedTotalRewardsPerWeightRelevant) /
                REWARDS_PER_WEIGHT_MULTIPLIER;
            
            claimedRewards = totalRewards - stakingAgreement.subtractRewards;
            stakingAgreement.subtractRewards = totalRewards;
        }
        require(claimedRewards > 0, "Staking: No pending rewards");
        // rewards are made available to the user 52 weeks after {claimRewards}
        // is called, in the form of a {LockAgreement} in {RewardsLocker}
        rewardsLocker.createLockAgreement(msg.sender, claimedRewards);

        // See the similar line in {restake}.
        uint256 leftOverRewardsAmount = claimedRewards * restakeBoostingFactor / RESTAKE_BOOSTING_MULTIPLIER;
        _boostKapPerSecondByLeftOverRewards(leftOverRewardsAmount);

        emit ClaimRewards(msg.sender, claimedRewards);
    }

    /**
     * @dev Add a {Checkpoint} to {checkpoints}
     * @param rewardsSinceLastCheckpoint Total rewards accumulated by all
     * stakers since the `time` of the last checkpoint
     * @param time Time at which `multipliedTotalRewardsPerWeight` applies
     */
    function _addCheckpoint(
        uint256 rewardsSinceLastCheckpoint,
        uint256 time
    ) internal {
        // Checkpoint at index 0 added in constructor
        Checkpoint storage previousCheckpoint =
            checkpoints[checkpoints.length - 1];
        
        uint256 multipliedTotalRewardsPerWeightSinceLastCheckpoint =
            previousCheckpoint.totalWeight == 0
            ? 0
            : (rewardsSinceLastCheckpoint * REWARDS_PER_WEIGHT_MULTIPLIER) / previousCheckpoint.totalWeight;

        checkpoints.push(
            Checkpoint(
                {
                    totalWeight: previousCheckpoint.totalWeight,
                    multipliedTotalRewardsPerWeight:
                        previousCheckpoint.multipliedTotalRewardsPerWeight
                            + multipliedTotalRewardsPerWeightSinceLastCheckpoint,
                    time: time
                }
            )
        );

        Checkpoint storage checkpoint = checkpoints[checkpoints.length - 1];
        emit CheckpointAdded(
            msg.sender,
            checkpoint.totalWeight,
            checkpoint.multipliedTotalRewardsPerWeight,
            checkpoint.time
        );
    }

    /**
     * @dev Increase {kapPerSecond} in the current {RewardsRule}, with the
     * KAP amount that was not spent as boosted rewards before. Conceptually,
     * the amount added should be
     * `kapPerSecond += leftOverAmount/((1 + boost) * timeRemaining)`, so that
     * boosts on the redistributed rewards (maximum factor of `1 + boost`), can
     * still be accommodated. Multiplying through by
     * `RESTAKE_BOOSTING_MULTIPLIER`, we obtain
     * `leftOverAmount * RESTAKE_BOOSTING_MULTIPLIER / (RESTAKE_BOOSTING_MULTIPLIER + restakeBoostingFactor) / timeRemaining`
     * as implemented below.
     *
     * The leftover rewards are not necessary used in the same rewards period
     * which they are allocated to (say, if the user claims their rewards after
     * the rewards period has ended). However, assuming all users eventually
     * claim, the leftover rewards will eventually be added to the
     * `kapPerSecond` of a future {RewardsRule}.
     */
    function _boostKapPerSecondByLeftOverRewards(uint256 leftOverAmount) internal {
        /**
         * @dev In the last second of the rewards rule, just ignore the
         * leftover (otherwise there is a divide by zero error). The
         * leftover rewards in this special case are simply kept by the
         * treasury, rather than being redistributed real-time.
         */
        if (block.timestamp == rewardsRules[rewardsRuleIndex].timeEnd) {
            return;
        }
        uint256 timeRemaining = rewardsRules[rewardsRuleIndex].timeEnd - block.timestamp;
        /// @dev See description above {_boostKapPerSecondByLeftOverRewards}
        rewardsRules[rewardsRuleIndex].kapPerSecond += SafeCast.toUint96(
            leftOverAmount * 
            RESTAKE_BOOSTING_MULTIPLIER / 
            (RESTAKE_BOOSTING_MULTIPLIER + restakeBoostingFactor) / 
            timeRemaining
        );
    }

    /**
     * @dev Increase {rewardsRuleIndex} by `1` and, in the case that the new
     * index is missing, push a {RewardsRule} of `0` KAP per second persisting
     * for 1 week after the current block timestamp.
     */
    function _increaseRewardsRuleIndex() internal {
        rewardsRuleIndex += 1;
        
        RewardsRule storage previousRewardsRule =
            rewardsRules[rewardsRuleIndex - 1];
        // if there is no rewards rule at `rewardsRuleIndex`, add a rewards
        // rule of 0 kapPerSecond which persists for 1 week after the
        // current timestamp
        if (rewardsRuleIndex == rewardsRules.length) {
            _addRewardsRule(
                0,
                SafeCast.toUint64(
                    (1 weeks) + (block.timestamp - previousRewardsRule.timeEnd)
                )
            );
        }
    }

    /**
     * @dev Used to update {checkpoints} and
     * {rewardsRuleIndex}
     * @dev Front-end should ensure no more than 1 sync is required when
     * user stakes, unstakes, restakes, or claims rewards. Otherwise, those
     * calls will fail until manually synced.
     */
    function sync() public {
        require(block.timestamp > syncdTo, "Staking: Already syncd");
        RewardsRule storage rewardsRule = rewardsRules[rewardsRuleIndex];

        if (block.timestamp <= rewardsRule.timeEnd) {
            _addCheckpoint(
                // `block.timestamp > syncdTo`
                rewardsRule.kapPerSecond * (block.timestamp - syncdTo),
                block.timestamp
            );
            syncdTo = block.timestamp;
        }
        else {
            // move on to the next rewards rule
            _increaseRewardsRuleIndex();
            
            // add a checkpoint at `rewardsRule.timeEnd`, provided
            // there is not already a checkpoint there
            if (syncdTo < rewardsRule.timeEnd) {
                // `rewardsRule` is now the "old" rewards rule
                uint256 rewardsFromOldRule = rewardsRule.kapPerSecond * (rewardsRule.timeEnd - syncdTo);
                _addCheckpoint(rewardsFromOldRule, rewardsRule.timeEnd);
            }
            
            // compute rewards from new rewards rule
            RewardsRule storage newRewardsRule = rewardsRules[rewardsRuleIndex];
            // sync at most to the end of the new rewards rule
            syncdTo = block.timestamp >= newRewardsRule.timeEnd ? newRewardsRule.timeEnd : block.timestamp;
            // `newRewardsRule.timeStart == rewardsRule.timeEnd`
            // `syncdTo > newRewardsRule.timeEnd`
            uint256 rewardsFromNewRule = newRewardsRule.kapPerSecond * (syncdTo - newRewardsRule.timeStart);
            _addCheckpoint(rewardsFromNewRule, syncdTo);
        }
    }

    /**
     * @dev Called by the governance contract to adjust the boosting rewards
     * amount for restaking
     * @param newBoostingFactor New value of {restakeBoostingFactor}. Recall
     * that {restakeBoostingFactor} is divided by {RESTAKE_BOOSTING_MULTIPLIER}
     * in applications.
     */
    function adjustRestakeBoostingFactor(uint256 newBoostingFactor)
        external
        onlyGovernance
    {
        require(newBoostingFactor != restakeBoostingFactor, "Invalid boosting factor");
        restakeBoostingFactor = newBoostingFactor;

        emit AdjustRestakeBoostingFactor(restakeBoostingFactor);
    }

    /**
     * @dev Called by the governance contract to add a new rewards emission
     * rate. When `block.timestamp > rewardsRules[rewardsRuleIndex].timeEnd`,
     * the currently active {RewardsRule} changes to the next element of
     * {rewardsRules}. See the logic in {sync}.
     * @param kapPerSecond The total rewards, per second, given out to all
     * active stakers
     * @param rewardsPeriod The time over which the emission rate
     * `kapPerSecond` applies
     */
    function addRewardsRule(uint256 kapPerSecond, uint64 rewardsPeriod)
        external
        onlyGovernance
    {
        _addRewardsRule(kapPerSecond, rewardsPeriod);
    }

    /**
     * @dev Called in emergency circumstances by the governance contract to
     * adjust a previously added rewards rule emission rate
     * @param rewardsRuleId Index of the {RewardsRule} in {rewardsRules}
     * @param kapPerSecond The total rewards, per second, given out to all
     * active stakers
     */
    function adjustRewardsRule(
        uint256 rewardsRuleId,
        uint256 kapPerSecond
    ) external onlyGovernance {
        // make sure the contract is syncd, so that previously accumulated
        // rewards are not affected by the rewards rule adjustment
        if (block.timestamp > syncdTo) {
            sync();
            require(syncdTo == block.timestamp, "Staking: Multiple syncs needed");
        }

        RewardsRule storage rewardsRule = rewardsRules[rewardsRuleId];
        rewardsRule.kapPerSecond = SafeCast.toUint96(kapPerSecond);

        emit AdjustRewardsRule(
            rewardsRuleId,
            rewardsRule.kapPerSecond
        );
    }

    /**
     * @dev Concrete implementation of {addRewardsRule}
     * @param kapPerSecond Amount of KAP emitted by the contract as rewards
     * each second
     * @param rewardsPeriod The amount of time over which the emissions rate
     * shall be `kapPerSecond`
     */
    function _addRewardsRule(uint256 kapPerSecond, uint64 rewardsPeriod)
        internal
    {
        require(rewardsPeriod > 0, "Staking: Invalid rewards period");

        uint256 prevEndTime = rewardsRules.length == 0
            ? block.timestamp
            : rewardsRules[rewardsRules.length - 1].timeEnd;

        rewardsRules.push(
            RewardsRule({
                kapPerSecond: SafeCast.toUint96(kapPerSecond),
                timeStart: SafeCast.toUint64(prevEndTime),
                timeEnd: SafeCast.toUint64(prevEndTime + rewardsPeriod)
            })
        );

        emit AddRewardsRule(
            rewardsRules.length - 1,
            kapPerSecond,
            prevEndTime,
            prevEndTime + rewardsPeriod
        );
    }

    /**
     * @dev Used to cover the case when some of {asset} is burned during
     * `transferFrom`, in which case the staking contract receives less
     * of {asset} than `inputAmount`
     * @param staker The caller of {stake}
     * @param inputAmount The chosen amount of {asset} to stake. May differ
     * from return value in the case of token burning during `transferFrom`
     * @return `addAmount`, used subsequently in {stake}
     */
    function _transferFromAndReturnAddAmount(
        address staker,
        uint256 inputAmount
    ) internal returns (uint256) {
        uint256 previousBalance = asset.balanceOf(address(this));
        SafeERC20.safeTransferFrom(asset, staker, address(this), inputAmount);
        return asset.balanceOf(address(this)) - previousBalance;
    }

    /**
     * @dev Used in {stake}
     * @param staker A storage pointer to the relevant {Staker}
     * @param lockPeriod The amount of time over which {asset} is locked
     * @return Index of new {StakingAgreement} in `staker.stakingAgreements`
     */
    function _newStakingAgreement(Staker storage staker, uint256 lockPeriod)
        internal
        returns (uint256)
    {
        // cannot begin lock before {rewardsStart}
        uint256 lockStart = block.timestamp <= rewardsStart
            ? rewardsStart
            : block.timestamp;
        uint256 lockEnd = lockStart + lockPeriod;
        StakingAgreement memory memoryStakingAgreement;
        memoryStakingAgreement.lockStart = SafeCast.toUint64(lockStart);
        memoryStakingAgreement.lockEnd = SafeCast.toUint64(lockEnd);
        staker.stakingAgreements.push(memoryStakingAgreement);
        return staker.stakingAgreements.length - 1;
    }

    /**
     * @dev Used in {addRewardsRule} and {adjustRewardsRule}
     */
    modifier onlyGovernance() {
        require(
            msg.sender == governanceRegistry.governance(),
            "Staking: Only governance"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for RewardsLocker
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Interface used by staking contracts to create lock
 * agreements in RewardsLocker when KAP rewards are claimed
 */
interface IRewardsLocker {
    function createLockAgreement(address beneficiary, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for staking pools
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Used to house structs and events for staking pools
 */
interface IStaking {
    struct RewardsRule {
        // rewards emission rate
        uint96 kapPerSecond;
        // timestamp when emission rate `kapPerSecond` starts
        uint64 timeStart;
        // timestamp when emission rate `kapPerSecond` ends
        uint64 timeEnd;
    }

    struct StakingAgreement {
        // amount of {asset} staked
        uint112 amount;
        // timestamp when `lockDuration` starts
        uint64 lockStart;
        // timestamp when `lockDuration` ends
        uint64 lockEnd;
        // becomes `true` after {unstake}
        bool collected;
        // allows calculation of pending rewards from knowledge of
        // {multipliedTotalRewardsPerWeight}
        uint256 subtractRewards;
    }

    struct Staker {
        // total amount of {asset} staked
        uint256 stakedAmount;
        // array of staking {StakingAgreements}. a new {StakingAgreement} is
        // created every time a user calls {stake}
        StakingAgreement[] stakingAgreements;
    }

    struct Checkpoint {
        // Need totalStakingWeight to calc rewards from checkpoint to staking timeEnd
        uint256 totalWeight;
        // rewards accumulated by a staker with weight `1` since {rewardsStart}
        // multiplied by {REWARDS_PER_WEIGHT_MULTIPLIER} to mitigate loss of
        // accuracy from integer division
        uint256 multipliedTotalRewardsPerWeight;
        // block timestamp
        uint256 time;
    }

    /**
     * @dev Fired in {addRewardsRule}
     * @param newRewardsRuleId Index of added {RewardsRule}
     * @param kapPerSecond `kapPerSecond` of new {RewardsRule}
     * @param timeStart `timeStart` of new {RewardsRule}
     * @param timeEnd `timeEnd` of new {RewardsRule}
     */
    event AddRewardsRule(
        uint256 newRewardsRuleId,
        uint256 kapPerSecond,
        uint256 timeStart,
        uint256 timeEnd
    );

    /**
     * @dev Fired in {adjustRewardsRule}
     * @param rewardsRuleId Index of the {RewardsRule} in {rewardsRules}
     * @param kapPerSecond The total rewards, per second, given out to all
     * active stakers
     */
    event AdjustRewardsRule(
        uint256 rewardsRuleId,
        uint256 kapPerSecond
    );

    /**
     * @dev Fired in {adjustRestakeBoostingFactor}
     * @param boostingFactor New value of {restakeBoostingFactor}, multiplied by 
     * {RESTAKE_BOOSTING_MULTIPLIER} in order to mitigate loss of accuracy from division
     */
    event AdjustRestakeBoostingFactor(
        uint256 boostingFactor
    );

    /**
     * @dev Fired in {stake}
     * @param staker Address of staking user
     * @param addAmount Amount of {asset} staked
     * @param lockPeriod Time before `amount` can be {unstake}d
     */
    event Stake(address indexed staker, uint256 addAmount, uint256 lockPeriod);

    /**
     * @dev Fired in {unstake}
     * @param staker Address of unstaking user
     * @param removeAmount Amount of {asset} returned to `staker`
     */
    event Unstake(address indexed staker, uint256 removeAmount);

    /**
     * @dev Fired in {restake}
     * @param staker Address of restaking user
     * @param amount Amount of {asset} restaked
     * @param extendedPeriod Extended lock period
     * @param boostedRewards Amount of rewards boosted with {restake}
     */
    event Restake(address indexed staker, uint256 amount, uint256 extendedPeriod, uint256 boostedRewards);

    /**
     * @dev Fired in {Staking.sync}. See struct {Checkpoint}.
     */
    event CheckpointAdded(
        address indexed by,
        uint256 totalWeight,
        uint256 multipliedTotalRewardsPerWeight,
        uint256 time
    );

    /**
     * @dev Fired {claimRewards}
     * @param by Recipient of claimed rewards
     * @param claimedRewards Amount of rewards claimed
     */
    event ClaimRewards(address indexed by, uint256 claimedRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for Governance
 * @author Playground Labs
 */
interface IGovernance {
    function votingPeriod() external view returns (uint256);

    struct Proposal {
        // hash of data required for the _transact function
        uint256 transactParamsHash;
        uint64 proposeTime;
        // Counters for the for/against votes. These votes will be used to determine if proposal passes.
        uint96 yaysKAP;
        uint96 naysKAP;
        uint112 yaysLP;
        uint112 naysLP;
        // Record if proposal has been executed
        bool executed;
        // Team multisig can veto malicious proposals
        bool vetoed;
        // Record values for TWAP
        uint256 priceCumulativeLast;
        // Mapping to keep track of who's voted
        mapping(address => bool) hasVoted;
    }

    struct WaitTo {
        uint24 startVote;
        uint24 endVote;
        uint24 execute;
        uint24 expire;
    }

    struct PoolParams {
        address kapToken;
        address otherToken;
        address poolAddress;
    }

    struct WeightSources {
        // indices of weightSourcesKAP for pulling voting weight
        uint256[] kapSourceIDs;
        // indices of weightSourcesLP for pulling voting weight
        uint256[] lpSourceIDs;
    }

    event Veto(
        uint256 indexed proposalId
    );
    event ProposalCreated(
        address indexed sender,
        uint256 indexed proposalID,
        uint256 proposeTime,
        address[] targets,
        uint256[] values,
        bytes[] data,
        string description
    );
    event Voted(
        address indexed voter,
        uint256 indexed proposalID,
        bool yay,
        uint256 weightKAP,
        uint256 weightLP
    );
    event ProposalExecuted(
        address indexed sender,
        uint256 indexed proposalID,
        uint256 time
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for GovernanceRegistry
 * @author Playground Labs
 */
interface IGovernanceRegistry {
    function governance() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Math {
    /**
     * @dev from @uniswap/v2-core/contracts/libraries/Math.sol.
     * Copied here to avoid solidity-compiler version errors.
     * babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     * 
     * Copied from OpenZeppelin Math.sol
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Because {SafeCast} does not support {uint112}
     * @param value Value to be safely converted to {uint112}
     * @return {uint112} representation of `value`, if `value` is small enough
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: Overflow 112 bits");
        return uint112(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}