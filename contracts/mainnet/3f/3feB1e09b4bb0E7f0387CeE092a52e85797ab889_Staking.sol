// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import {TypeAndVersionInterface} from '@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol';
import {AggregatorV3Interface} from '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import {ConfirmedOwner} from '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {IERC165} from '@openzeppelin/contracts/interfaces/IERC165.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {IStaking} from './interfaces/IStaking.sol';
import {IStakingOwner} from './interfaces/IStakingOwner.sol';
import {IMerkleAccessController} from './interfaces/IMerkleAccessController.sol';
import {IAlertsController} from './interfaces/IAlertsController.sol';
import {IMigratable} from './interfaces/IMigratable.sol';
import {StakingPoolLib} from './StakingPoolLib.sol';
import {RewardLib, SafeCast} from './RewardLib.sol';

contract Staking is
  IStaking,
  IStakingOwner,
  IMigratable,
  IMerkleAccessController,
  IAlertsController,
  ConfirmedOwner,
  TypeAndVersionInterface,
  Pausable
{
  using StakingPoolLib for StakingPoolLib.Pool;
  using RewardLib for RewardLib.Reward;
  using SafeCast for uint256;

  /// @notice This struct defines the params required by the Staking contract's
  /// constructor.
  struct PoolConstructorParams {
    /// @notice The LINK Token
    LinkTokenInterface LINKAddress;
    /// @notice The feed being monitored when raising alerts
    AggregatorV3Interface monitoredFeed;
    /// @notice The initial maximum total stake amount across all stakers
    uint256 initialMaxPoolSize;
    /// @notice The initial maximum stake amount for a single community staker
    uint256 initialMaxCommunityStakeAmount;
    /// @notice The initial maximum stake amount for a single node operator
    uint256 initialMaxOperatorStakeAmount;
    /// @notice The minimum stake amount that a community staker can stake
    uint256 minCommunityStakeAmount;
    /// @notice The minimum stake amount that an operator can stake
    uint256 minOperatorStakeAmount;
    /// @notice The number of seconds until the feed is considered stale
    /// and the priority period begins.
    uint256 priorityPeriodThreshold;
    /// @notice The number of seconds until the priority period ends
    /// and the regular period begins.
    uint256 regularPeriodThreshold;
    /// @notice The amount of LINK to reward an operator who
    /// raises an alert in the priority period.
    uint256 maxAlertingRewardAmount;
    /// @notice The minimum number of node operators required to initialize the
    /// staking pool.
    uint256 minInitialOperatorCount;
    /// @notice The minimum reward duration after pool config updates and pool
    /// reward extensions
    uint256 minRewardDuration;
    /// @notice The duration of earned rewards to slash when an alert is raised
    uint256 slashableDuration;
    /// @notice Used to calculate delegated stake amount
    /// = amount / delegation rate denominator = 100% / 100 = 1%
    uint256 delegationRateDenominator;
  }

  /// @notice The amount to divide an alerter's stake amount when
  /// calculating their reward for raising an alert.
  uint256 private constant ALERTING_REWARD_STAKED_AMOUNT_DENOMINATOR = 5;

  LinkTokenInterface private immutable i_LINK;
  StakingPoolLib.Pool private s_pool;
  RewardLib.Reward private s_reward;
  /// @notice The ETH USD feed that alerters can raise alerts for.
  AggregatorV3Interface private immutable i_monitoredFeed;
  /// @notice The proposed address stakers will migrate funds to
  address private s_proposedMigrationTarget;
  /// @notice The timestamp of when the migration target was proposed at
  uint256 private s_proposedMigrationTargetAt;
  /// @notice The address stakers can migrate their funds to
  address private s_migrationTarget;
  /// @notice The round ID of the last feed round an alert was raised
  uint256 private s_lastAlertedRoundId;
  /// @notice The merkle root of the merkle tree generated from the list
  /// of staker addresses with early acccess.
  bytes32 private s_merkleRoot;
  /// @notice The number of seconds until the feed is considered stale
  /// and the priority period begins.
  uint256 private immutable i_priorityPeriodThreshold;
  /// @notice The number of seconds until the priority period ends
  /// and the regular period begins.
  uint256 private immutable i_regularPeriodThreshold;
  /// @notice The amount of LINK to reward an operator who
  /// raises an alert in the priority period.
  uint256 private immutable i_maxAlertingRewardAmount;
  /// @notice The minimum stake amount that a node operator can stake
  uint256 private immutable i_minOperatorStakeAmount;
  /// @notice The minimum stake amount that a community staker can stake
  uint256 private immutable i_minCommunityStakeAmount;
  /// @notice The minimum number of node operators required to initialize the
  /// staking pool.
  uint256 private immutable i_minInitialOperatorCount;
  /// @notice The minimum reward duration after pool config updates and pool
  /// reward extensions
  uint256 private immutable i_minRewardDuration;
  /// @notice The duration of earned rewards to slash when an alert is raised
  uint256 private immutable i_slashableDuration;
  /// @notice Used to calculate delegated stake amount
  /// = amount / delegation rate denominator = 100% / 100 = 1%
  uint256 private immutable i_delegationRateDenominator;

  constructor(PoolConstructorParams memory params) ConfirmedOwner(msg.sender) {
    if (address(params.LINKAddress) == address(0)) revert InvalidZeroAddress();
    if (address(params.monitoredFeed) == address(0))
      revert InvalidZeroAddress();
    if (params.delegationRateDenominator == 0) revert InvalidDelegationRate();
    if (RewardLib.REWARD_PRECISION % params.delegationRateDenominator > 0)
      revert InvalidDelegationRate();
    if (params.regularPeriodThreshold <= params.priorityPeriodThreshold)
      revert InvalidRegularPeriodThreshold();
    if (params.minOperatorStakeAmount == 0)
      revert InvalidMinOperatorStakeAmount();
    if (params.minOperatorStakeAmount > params.initialMaxOperatorStakeAmount)
      revert InvalidMinOperatorStakeAmount();
    if (params.minCommunityStakeAmount > params.initialMaxCommunityStakeAmount)
      revert InvalidMinCommunityStakeAmount();
    if (params.maxAlertingRewardAmount > params.initialMaxOperatorStakeAmount)
      revert InvalidMaxAlertingRewardAmount();

    s_pool._setConfig(
      params.initialMaxPoolSize,
      params.initialMaxCommunityStakeAmount,
      params.initialMaxOperatorStakeAmount
    );
    i_LINK = params.LINKAddress;
    i_monitoredFeed = params.monitoredFeed;
    i_priorityPeriodThreshold = params.priorityPeriodThreshold;
    i_regularPeriodThreshold = params.regularPeriodThreshold;
    i_maxAlertingRewardAmount = params.maxAlertingRewardAmount;
    i_minOperatorStakeAmount = params.minOperatorStakeAmount;
    i_minCommunityStakeAmount = params.minCommunityStakeAmount;
    i_minInitialOperatorCount = params.minInitialOperatorCount;
    i_minRewardDuration = params.minRewardDuration;
    i_slashableDuration = params.slashableDuration;
    i_delegationRateDenominator = params.delegationRateDenominator;
  }

  // =======================
  // TypeAndVersionInterface
  // =======================

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return 'Staking 0.1.0';
  }

  // =================
  // IMerkleAccessController
  // =================

  /// @inheritdoc IMerkleAccessController
  function hasAccess(address staker, bytes32[] memory proof)
    external
    view
    override
    returns (bool)
  {
    if (s_merkleRoot == bytes32(0)) return true;
    return
      MerkleProof.verify(proof, s_merkleRoot, keccak256(abi.encode(staker)));
  }

  /// @inheritdoc IMerkleAccessController
  function setMerkleRoot(bytes32 newMerkleRoot) external override onlyOwner {
    s_merkleRoot = newMerkleRoot;
    emit MerkleRootChanged(newMerkleRoot);
  }

  /// @inheritdoc IMerkleAccessController
  function getMerkleRoot() external view override returns (bytes32) {
    return s_merkleRoot;
  }

  // =============
  // IStakingOwner
  // =============

  /// @inheritdoc IStakingOwner
  function setPoolConfig(
    uint256 maxPoolSize,
    uint256 maxCommunityStakeAmount,
    uint256 maxOperatorStakeAmount
  ) external override(IStakingOwner) onlyOwner whenActive {
    s_pool._setConfig(
      maxPoolSize,
      maxCommunityStakeAmount,
      maxOperatorStakeAmount
    );

    s_reward._updateDuration(
      maxPoolSize,
      s_pool._getTotalStakedAmount(),
      uint256(s_reward.base.rate),
      i_minRewardDuration,
      getAvailableReward(),
      getTotalDelegatedAmount()
    );
  }

  /// @inheritdoc IStakingOwner
  function setFeedOperators(address[] calldata operators)
    external
    override(IStakingOwner)
    onlyOwner
  {
    s_pool._setFeedOperators(operators);
  }

  /// @inheritdoc IStakingOwner
  function start(uint256 amount, uint256 initialRewardRate)
    external
    override(IStakingOwner)
    onlyOwner
  {
    if (s_merkleRoot == bytes32(0)) revert MerkleRootNotSet();

    s_pool._open(i_minInitialOperatorCount);

    // We need to transfer LINK balance before we initialize the reward to
    // calculate the new reward expiry timestamp.
    i_LINK.transferFrom(msg.sender, address(this), amount);

    s_reward._initialize(
      uint256(s_pool.limits.maxPoolSize),
      initialRewardRate,
      i_minRewardDuration,
      getAvailableReward()
    );
  }

  /// @inheritdoc IStakingOwner
  function conclude() external override(IStakingOwner) onlyOwner whenActive {
    s_reward._release(
      s_pool._getTotalStakedAmount(),
      getTotalDelegatedAmount()
    );

    s_pool._close();
  }

  /// @inheritdoc IStakingOwner
  function addReward(uint256 amount)
    external
    override(IStakingOwner)
    onlyOwner
    whenActive
  {
    // We need to transfer LINK balance before we recalculate the reward expiry
    // timestamp so the new amount is accounted for.
    i_LINK.transferFrom(msg.sender, address(this), amount);

    s_reward._updateDuration(
      uint256(s_pool.limits.maxPoolSize),
      s_pool._getTotalStakedAmount(),
      uint256(s_reward.base.rate),
      i_minRewardDuration,
      getAvailableReward(),
      getTotalDelegatedAmount()
    );

    emit RewardLib.RewardAdded(amount);
  }

  /// @inheritdoc IStakingOwner
  function withdrawUnusedReward()
    external
    override(IStakingOwner)
    onlyOwner
    whenInactive
  {
    uint256 unusedRewards = getAvailableReward() -
      uint256(s_reward.reserved.base) -
      uint256(s_reward.reserved.delegated);
    emit RewardLib.RewardWithdrawn(unusedRewards);

    // msg.sender is the owner address as only the owner can call this function
    i_LINK.transfer(msg.sender, unusedRewards);
  }

  /// @dev Required conditions for adding operators:
  /// - Operators can only be added to the pool if they have no prior stake.
  /// - Operators can only be readded to the pool if they have no removed
  /// stake.
  /// - Operators cannot be added to the pool after staking ends (either through
  /// conclusion or through reward expiry).
  /// @inheritdoc IStakingOwner
  function addOperators(address[] calldata operators)
    external
    override(IStakingOwner)
    onlyOwner
  {
    // If reward was initialized (meaning the pool was active) but the pool is
    // no longer active we want to prevent adding new operators.
    if (s_reward.startTimestamp > 0 && !isActive())
      revert StakingPoolLib.InvalidPoolStatus(false, true);

    s_pool._addOperators(operators);
  }

  /// @inheritdoc IStakingOwner
  function removeOperators(address[] calldata operators)
    external
    override(IStakingOwner)
    onlyOwner
    whenActive
  {
    // Accumulate delegation rewards before removing operators as this affects
    // rewards that are distributed to remaining operators.
    s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());

    for (uint256 i; i < operators.length; i++) {
      address operator = operators[i];
      StakingPoolLib.Staker memory staker = s_pool.stakers[operator];

      if (!staker.isOperator)
        revert StakingPoolLib.OperatorDoesNotExist(operator);

      // Operator must not be on the feed
      if (staker.isFeedOperator)
        revert StakingPoolLib.OperatorIsAssignedToFeed(operator);

      uint256 principal = staker.stakedAmount;
      // An operator with stake is a delegate
      if (principal > 0) {
        // The operator's rewards are forfeited when they are removed
        // Unreserve operator's earned base reward
        s_reward.reserved.base -= getBaseReward(operator)._toUint96();
        // Unreserve operator's future base reward
        s_reward.reserved.base -= s_reward
          ._calculateReward(principal, s_reward._getRemainingDuration())
          ._toUint96();

        // Unreserve operator's earned delegation reward. We don't need to
        // unreserve future delegation rewards because they will be split by
        // other operators.
        s_reward.reserved.delegated -= getDelegationReward(operator)
          ._toUint96();

        s_reward.delegated.delegatesCount -= 1;
        delete s_pool.stakers[operator].stakedAmount;
        uint96 castPrincipal = principal._toUint96();
        s_pool.state.totalOperatorStakedAmount -= castPrincipal;
        // Only the operator's principal is withdrawable after they are removed
        s_pool.stakers[operator].removedStakeAmount = castPrincipal;
        s_pool.totalOperatorRemovedAmount += castPrincipal;

        // We need to reset operator's missed base rewards in case they decide
        // to stake as a community staker using the same address. It's fine to
        // not reset missed delegated rewards, because a removed operator
        // cannot be re-added as operator again.
        delete s_reward.missed[operator].base;
      }

      s_pool.stakers[operator].isOperator = false;
      emit StakingPoolLib.OperatorRemoved(operator, principal);
    }

    s_pool.state.operatorsCount -= operators.length._toUint8();
  }

  /// @inheritdoc IStakingOwner
  function changeRewardRate(uint256 newRate)
    external
    override
    onlyOwner
    whenActive
  {
    if (newRate == 0) revert();

    uint256 totalDelegatedAmount = getTotalDelegatedAmount();

    s_reward._accumulateDelegationRewards(totalDelegatedAmount);
    s_reward._accumulateBaseRewards();
    s_reward._updateDuration(
      uint256(s_pool.limits.maxPoolSize),
      s_pool._getTotalStakedAmount(),
      newRate,
      i_minRewardDuration,
      getAvailableReward(),
      totalDelegatedAmount
    );

    emit RewardLib.RewardRateChanged(newRate);
  }

  /// @inheritdoc IStakingOwner
  function emergencyPause() external override(IStakingOwner) onlyOwner {
    _pause();
  }

  /// @inheritdoc IStakingOwner
  function emergencyUnpause() external override(IStakingOwner) onlyOwner {
    _unpause();
  }

  /// @inheritdoc IStakingOwner
  function getFeedOperators()
    external
    view
    override(IStakingOwner)
    returns (address[] memory)
  {
    return s_pool.feedOperators;
  }

  // ===========
  // IMigratable
  // ===========

  /// @inheritdoc IMigratable
  function getMigrationTarget()
    external
    view
    override(IMigratable)
    returns (address)
  {
    return s_migrationTarget;
  }

  /// @inheritdoc IMigratable
  function proposeMigrationTarget(address migrationTarget)
    external
    override(IMigratable)
    onlyOwner
  {
    if (
      migrationTarget.code.length == 0 ||
      migrationTarget == address(this) ||
      s_proposedMigrationTarget == migrationTarget ||
      s_migrationTarget == migrationTarget ||
      !IERC165(migrationTarget).supportsInterface(this.onTokenTransfer.selector)
    ) revert InvalidMigrationTarget();

    s_migrationTarget = address(0);
    s_proposedMigrationTarget = migrationTarget;
    s_proposedMigrationTargetAt = block.timestamp;
    emit MigrationTargetProposed(migrationTarget);
  }

  /// @inheritdoc IMigratable
  function acceptMigrationTarget() external override(IMigratable) onlyOwner {
    if (s_proposedMigrationTarget == address(0))
      revert InvalidMigrationTarget();

    if (block.timestamp < (uint256(s_proposedMigrationTargetAt) + 7 days))
      revert AccessForbidden();

    s_migrationTarget = s_proposedMigrationTarget;
    s_proposedMigrationTarget = address(0);
    emit MigrationTargetAccepted(s_migrationTarget);
  }

  /// @inheritdoc IMigratable
  function migrate(bytes calldata data)
    external
    override(IMigratable)
    whenInactive
  {
    if (s_migrationTarget == address(0)) revert InvalidMigrationTarget();

    (uint256 amount, uint256 baseReward, uint256 delegationReward) = _exit(
      msg.sender
    );

    emit Migrated(msg.sender, amount, baseReward, delegationReward, data);

    i_LINK.transferAndCall(
      s_migrationTarget,
      uint256(amount + baseReward + delegationReward),
      abi.encode(msg.sender, data)
    );
  }

  // =================
  // IAlertsController
  // =================

  /// @inheritdoc IAlertsController
  function raiseAlert() external override(IAlertsController) whenActive {
    uint256 stakedAmount = getStake(msg.sender);
    if (stakedAmount == 0) revert AccessForbidden();

    (uint256 roundId, , , uint256 lastFeedUpdatedAt, ) = i_monitoredFeed
      .latestRoundData();

    if (roundId == s_lastAlertedRoundId) revert AlertAlreadyExists(roundId);

    if (block.timestamp < lastFeedUpdatedAt + i_priorityPeriodThreshold)
      revert AlertInvalid();

    bool isInPriorityPeriod = block.timestamp <
      lastFeedUpdatedAt + i_regularPeriodThreshold;

    if (isInPriorityPeriod && !s_pool._isOperator(msg.sender))
      revert AlertInvalid();

    s_lastAlertedRoundId = roundId;

    // There is a risk that this might get us below the total amount of
    // reserved if the reward amount slashed is greater than LINK
    // balance in the pool.  This is an extreme edge case that will only occur
    /// if an alert is raised many times such that it completely depletes the
    // available rewards in the pool.  As this is an unlikely scenario, the
    // contract avoids adding an extra check to minimize gas costs.
    // There is a similar edge case when the total slashed amount is less than
    // the alerting reward. This can happen because slashed amounts are capped to
    // earned rewards so far. The result is a net outflow of rewards from the
    // staking pool up to the max alerting reward amount in the worst case.
    // This is acceptable and in practice has little to no impact to staking.
    uint256 rewardAmount = _calculateAlertingRewardAmount(
      stakedAmount,
      isInPriorityPeriod
    );

    emit AlertRaised(msg.sender, roundId, rewardAmount);

    // We need to transfer the rewards out before recalculating the new reward
    // expiry timestamp
    i_LINK.transfer(msg.sender, rewardAmount);

    s_reward._slashOnFeedOperators(
      i_minOperatorStakeAmount,
      i_slashableDuration,
      s_pool.feedOperators,
      s_pool.stakers,
      getTotalDelegatedAmount()
    );

    s_reward._updateDuration(
      uint256(s_pool.limits.maxPoolSize),
      s_pool._getTotalStakedAmount(),
      uint256(s_reward.base.rate),
      0,
      getAvailableReward(),
      getTotalDelegatedAmount()
    );
  }

  /// @inheritdoc IAlertsController
  function canAlert(address alerter)
    external
    view
    override(IAlertsController)
    returns (bool)
  {
    if (getStake(alerter) == 0) return false;
    if (!isActive()) return false;
    (uint256 roundId, , , uint256 updatedAt, ) = i_monitoredFeed
      .latestRoundData();
    if (roundId == s_lastAlertedRoundId) return false;

    // nobody can (feed is not stale)
    if (block.timestamp < updatedAt + i_priorityPeriodThreshold) return false;

    // all stakers can (regular alerters)
    if (block.timestamp >= updatedAt + i_regularPeriodThreshold) return true;
    return s_pool._isOperator(alerter); // only operators can (priority alerters)
  }

  // ========
  // IStaking
  // ========

  /// @inheritdoc IStaking
  function unstake() external override(IStaking) whenInactive {
    (uint256 amount, uint256 baseReward, uint256 delegationReward) = _exit(
      msg.sender
    );

    emit Unstaked(msg.sender, amount, baseReward, delegationReward);
    i_LINK.transfer(msg.sender, amount + baseReward + delegationReward);
  }

  /// @inheritdoc IStaking
  function withdrawRemovedStake() external override(IStaking) whenInactive {
    uint256 amount = s_pool.stakers[msg.sender].removedStakeAmount;
    if (amount == 0) revert StakingPoolLib.StakeNotFound(msg.sender);

    s_pool.totalOperatorRemovedAmount -= amount;
    delete s_pool.stakers[msg.sender].removedStakeAmount;
    emit Unstaked(msg.sender, amount, 0, 0);
    i_LINK.transfer(msg.sender, amount);
  }

  /// @inheritdoc IStaking
  function getStake(address staker)
    public
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool.stakers[staker].stakedAmount;
  }

  /// @inheritdoc IStaking
  function isOperator(address staker)
    external
    view
    override(IStaking)
    returns (bool)
  {
    return s_pool._isOperator(staker);
  }

  /// @inheritdoc IStaking
  function isActive() public view override(IStaking) returns (bool) {
    return s_pool.state.isOpen && !s_reward._isDepleted();
  }

  /// @inheritdoc IStaking
  function getMaxPoolSize() external view override(IStaking) returns (uint256) {
    return uint256(s_pool.limits.maxPoolSize);
  }

  /// @inheritdoc IStaking
  function getCommunityStakerLimits()
    external
    view
    override(IStaking)
    returns (uint256, uint256)
  {
    return (
      i_minCommunityStakeAmount,
      uint256(s_pool.limits.maxCommunityStakeAmount)
    );
  }

  /// @inheritdoc IStaking
  function getOperatorLimits()
    external
    view
    override(IStaking)
    returns (uint256, uint256)
  {
    return (
      i_minOperatorStakeAmount,
      uint256(s_pool.limits.maxOperatorStakeAmount)
    );
  }

  /// @inheritdoc IStaking
  function getRewardTimestamps()
    external
    view
    override(IStaking)
    returns (uint256, uint256)
  {
    return (uint256(s_reward.startTimestamp), uint256(s_reward.endTimestamp));
  }

  /// @inheritdoc IStaking
  function getRewardRate() external view override(IStaking) returns (uint256) {
    return uint256(s_reward.base.rate);
  }

  /// @inheritdoc IStaking
  function getDelegationRateDenominator()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return i_delegationRateDenominator;
  }

  /// @inheritdoc IStaking
  function getAvailableReward()
    public
    view
    override(IStaking)
    returns (uint256)
  {
    return
      i_LINK.balanceOf(address(this)) -
      s_pool._getTotalStakedAmount() -
      s_pool.totalOperatorRemovedAmount;
  }

  /// @inheritdoc IStaking
  function getBaseReward(address staker)
    public
    view
    override(IStaking)
    returns (uint256)
  {
    uint256 stake = s_pool.stakers[staker].stakedAmount;
    if (stake == 0) return 0;

    if (s_pool._isOperator(staker)) {
      return s_reward._getOperatorEarnedBaseRewards(staker, stake);
    }

    return
      s_reward._calculateAccruedBaseRewards(
        RewardLib._getNonDelegatedAmount(stake, i_delegationRateDenominator)
      ) - uint256(s_reward.missed[staker].base);
  }

  /// @inheritdoc IStaking
  function getDelegationReward(address staker)
    public
    view
    override(IStaking)
    returns (uint256)
  {
    StakingPoolLib.Staker memory stakerAccount = s_pool.stakers[staker];
    if (!stakerAccount.isOperator) return 0;
    if (stakerAccount.stakedAmount == 0) return 0;
    return
      s_reward._getOperatorEarnedDelegatedRewards(
        staker,
        getTotalDelegatedAmount()
      );
  }

  /// @inheritdoc IStaking
  function getTotalDelegatedAmount()
    public
    view
    override(IStaking)
    returns (uint256)
  {
    return
      RewardLib._getDelegatedAmount(
        s_pool.state.totalCommunityStakedAmount,
        i_delegationRateDenominator
      );
  }

  /// @inheritdoc IStaking
  function getDelegatesCount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return uint256(s_reward.delegated.delegatesCount);
  }

  /// @inheritdoc IStaking
  function getTotalStakedAmount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool._getTotalStakedAmount();
  }

  /// @inheritdoc IStaking
  function getTotalCommunityStakedAmount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool.state.totalCommunityStakedAmount;
  }

  /// @inheritdoc IStaking
  function getTotalRemovedAmount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool.totalOperatorRemovedAmount;
  }

  /// @inheritdoc IStaking
  function getEarnedBaseRewards()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return
      s_reward._getEarnedBaseRewards(
        s_pool._getTotalStakedAmount(),
        getTotalDelegatedAmount()
      );
  }

  /// @inheritdoc IStaking
  function getEarnedDelegationRewards()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_reward._getEarnedDelegationRewards(getTotalDelegatedAmount());
  }

  /// @inheritdoc IStaking
  function isPaused() external view override(IStaking) returns (bool) {
    return paused();
  }

  /// @inheritdoc IStaking
  function getChainlinkToken()
    public
    view
    override(IStaking)
    returns (address)
  {
    return address(i_LINK);
  }

  /// @inheritdoc IStaking
  function getMonitoredFeed() external view override returns (address) {
    return address(i_monitoredFeed);
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param sender Address of the sender
   * @param amount Amount of LINK sent (specified in wei)
   * @param data Optional payload containing a Staking Allowlist Merkle proof
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes memory data
  ) external validateFromLINK whenNotPaused whenActive {
    if (amount < RewardLib.REWARD_PRECISION)
      revert StakingPoolLib.InsufficientStakeAmount(RewardLib.REWARD_PRECISION);

    // TL;DR: Reward calculation and delegation logic requires precise numbers
    // to avoid cumulative rounding errors.
    // Long explanation:
    // When users stake amounts that are rounded down to 0 after dividing
    // by the delegation rate denominator, not enough rewards are reserved for
    // the user. When the user then stakes enough times, small rounding errors
    // accumulate. This causes an integer underflow when unreserving rewards because
    // the total delegated amount returns a larger number than what individual
    // reserved amounts sum up to.
    uint256 remainder = amount % RewardLib.REWARD_PRECISION;
    if (remainder > 0) {
      amount -= remainder;
      i_LINK.transfer(sender, remainder);
    }

    if (s_pool._isOperator(sender)) {
      _stakeAsOperator(sender, amount);
    } else {
      // If a Merkle root is set, the sender should
      // prove that they are part of the merkle tree
      if (s_merkleRoot != bytes32(0)) {
        if (data.length == 0) revert AccessForbidden();
        if (
          !MerkleProof.verify(
            abi.decode(data, (bytes32[])),
            s_merkleRoot,
            keccak256(abi.encode(sender))
          )
        ) revert AccessForbidden();
      }
      _stakeAsCommunityStaker(sender, amount);
    }
  }

  // =======
  // Private
  // =======

  /// @notice Helper function for when a community staker enters the pool
  /// @param staker The staker address
  /// @param amount The amount of principal staked
  /// @dev When an operator is removed they can stake as a community staker.
  /// We allow that because the alternative (checking for removed stake before
  /// staking) is going to unnecessarily increase gas costs in 99.99% of the
  /// cases.
  function _stakeAsCommunityStaker(address staker, uint256 amount) private {
    uint256 currentStakedAmount = s_pool.stakers[staker].stakedAmount;
    uint256 newStakedAmount = currentStakedAmount + amount;
    // Check that the amount is greater than or equal to the minimum required
    if (newStakedAmount < i_minCommunityStakeAmount)
      revert StakingPoolLib.InsufficientStakeAmount(i_minCommunityStakeAmount);

    // Check that the amount is less than or equal to the maximum allowed
    uint256 maxCommunityStakeAmount = uint256(
      s_pool.limits.maxCommunityStakeAmount
    );
    if (newStakedAmount > maxCommunityStakeAmount)
      revert StakingPoolLib.ExcessiveStakeAmount(
        maxCommunityStakeAmount - currentStakedAmount
      );

    // Check if the amount supplied increases the total staked amount above
    // the maximum pool size
    uint256 remainingPoolSpace = s_pool._getRemainingPoolSpace();
    if (amount > remainingPoolSpace)
      revert StakingPoolLib.ExcessiveStakeAmount(remainingPoolSpace);

    s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());
    uint256 extraNonDelegatedAmount = RewardLib._getNonDelegatedAmount(
      amount,
      i_delegationRateDenominator
    );
    s_reward.missed[staker].base += s_reward
      ._calculateAccruedBaseRewards(extraNonDelegatedAmount)
      ._toUint96();
    s_reward._reserve(
      extraNonDelegatedAmount,
      RewardLib._getDelegatedAmount(amount, i_delegationRateDenominator)
    );
    s_pool.state.totalCommunityStakedAmount += amount._toUint96();
    s_pool.stakers[staker].stakedAmount = newStakedAmount._toUint96();
    emit Staked(staker, amount, newStakedAmount);
  }

  /// @notice Helper function for when an operator enters the pool
  /// @dev Function skips validating whether or not the operator stake
  /// amount will cause the total stake amount to exceed the maximum pool size.
  /// This is because the pool already reserves a fixed amount of space
  /// for each operator meaning that an operator staking cannot cause the
  /// total stake amount to exceed the maximum pool size.  Each operator
  /// receives a reserved stake amount equal to the maxOperatorStakeAmount.
  /// This is done by deducting operatorCount * maxOperatorStakeAmount from the
  /// remaining pool space available for staking.
  /// @param staker The staker address
  /// @param amount The amount of principal staked
  function _stakeAsOperator(address staker, uint256 amount) private {
    StakingPoolLib.Staker storage operator = s_pool.stakers[staker];
    uint256 currentStakedAmount = operator.stakedAmount;
    uint256 newStakedAmount = currentStakedAmount + amount;

    // Check that the amount is greater than or equal to the minimum required
    if (newStakedAmount < i_minOperatorStakeAmount)
      revert StakingPoolLib.InsufficientStakeAmount(i_minOperatorStakeAmount);

    // Check that the amount is less than or equal to the maximum allowed
    uint256 maxOperatorStakeAmount = uint256(
      s_pool.limits.maxOperatorStakeAmount
    );
    if (newStakedAmount > maxOperatorStakeAmount)
      revert StakingPoolLib.ExcessiveStakeAmount(
        maxOperatorStakeAmount - currentStakedAmount
      );

    // On first stake
    if (currentStakedAmount == 0) {
      s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());
      uint8 delegatesCount = s_reward.delegated.delegatesCount;

      // We are doing this check to unreserve any unused delegated rewards
      // prior to the first operator staking. After the rewards are unreserved
      // we reset the accumulated value so it doesn't count towards missed
      // rewards.
      // There is a known edge-case where, if no operator stakes throughout the
      // duration of the pool, we wouldn't unreserve unused delegation rewards.
      // In practice this shouldn't happen and, if it does, there are
      // operational workarounds to unreserve those rewards.
      if (delegatesCount == 0) {
        s_reward.reserved.delegated -= s_reward.delegated.cumulativePerDelegate;
        delete s_reward.delegated.cumulativePerDelegate;
      }

      s_reward.delegated.delegatesCount = delegatesCount + 1;

      s_reward.missed[staker].delegated = s_reward
        .delegated
        .cumulativePerDelegate;
    }

    s_reward.missed[staker].base += s_reward
      ._calculateAccruedBaseRewards(amount)
      ._toUint96();
    s_pool.state.totalOperatorStakedAmount += amount._toUint96();
    s_reward._reserve(amount, 0);
    s_pool.stakers[staker].stakedAmount = newStakedAmount._toUint96();
    emit Staked(staker, amount, newStakedAmount);
  }

  /// @notice Helper function when staker exits the pool
  /// @param staker The staker address
  function _exit(address staker)
    private
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    StakingPoolLib.Staker memory stakerAccount = s_pool.stakers[staker];
    if (stakerAccount.stakedAmount == 0)
      revert StakingPoolLib.StakeNotFound(staker);

    // If the pool isOpen that means that we haven't concluded it and stakers
    // got here because the reward depleted. In that case, the first user to
    // unstake will accumulate delegation and base rewards to save on cost for
    // others.
    if (s_pool.state.isOpen) {
      // Accumulate base and delegation rewards before unreserving rewards to
      // save gas costs. We can use the accumulated reward per micro LINK and
      // accumulated delegation reward to simplify reward calculations.
      s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());
      s_reward._accumulateBaseRewards();
      delete s_pool.state.isOpen;
    }

    if (stakerAccount.isOperator) {
      s_pool.state.totalOperatorStakedAmount -= stakerAccount.stakedAmount;

      uint256 baseReward = s_reward._calculateConcludedBaseRewards(
        stakerAccount.stakedAmount,
        staker
      );
      uint256 delegationReward = uint256(
        s_reward.delegated.cumulativePerDelegate
      ) - uint256(s_reward.missed[staker].delegated);

      delete s_pool.stakers[staker].stakedAmount;
      s_reward.reserved.base -= baseReward._toUint96();
      s_reward.reserved.delegated -= delegationReward._toUint96();
      return (stakerAccount.stakedAmount, baseReward, delegationReward);
    } else {
      s_pool.state.totalCommunityStakedAmount -= stakerAccount.stakedAmount;

      uint256 baseReward = s_reward._calculateConcludedBaseRewards(
        RewardLib._getNonDelegatedAmount(
          stakerAccount.stakedAmount,
          i_delegationRateDenominator
        ),
        staker
      );
      delete s_pool.stakers[staker].stakedAmount;
      s_reward.reserved.base -= baseReward._toUint96();
      return (stakerAccount.stakedAmount, baseReward, 0);
    }
  }

  /// @notice Calculates the reward amount an alerter will receive for raising
  /// a successful alert in the current alerting period.
  /// @param stakedAmount Amount of LINK staked by the alerter
  /// @param isInPriorityPeriod True if it is currently in the priority period
  /// @return rewardAmount Amount of LINK rewards to be paid to the alerter
  function _calculateAlertingRewardAmount(
    uint256 stakedAmount,
    bool isInPriorityPeriod
  ) private view returns (uint256) {
    if (isInPriorityPeriod) return i_maxAlertingRewardAmount;
    return
      Math.min(
        stakedAmount / ALERTING_REWARD_STAKED_AMOUNT_DENOMINATOR,
        i_maxAlertingRewardAmount
      );
  }

  // =========
  // Modifiers
  // =========

  /// @dev Having a private function for the modifer saves on the contract size
  function _isActive() private view {
    if (!isActive()) revert StakingPoolLib.InvalidPoolStatus(false, true);
  }

  /// @dev Reverts if the staking pool is inactive (not open for staking or
  /// expired)
  modifier whenActive() {
    _isActive();

    _;
  }

  /// @dev Reverts if the staking pool is active (open for staking)
  modifier whenInactive() {
    if (isActive()) revert StakingPoolLib.InvalidPoolStatus(true, false);

    _;
  }

  /// @dev Reverts if not sent from the LINK token
  modifier validateFromLINK() {
    if (msg.sender != getChainlinkToken()) revert SenderNotLinkToken();

    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SafeCast} from './SafeCast.sol';
import {StakingPoolLib} from './StakingPoolLib.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

library RewardLib {
  using SafeCast for uint256;

  /// @notice emitted when the reward is initialized for the first time
  /// @param rate the reward rate
  /// @param available the amount of rewards available for distribution in the
  /// staking pool
  /// @param startTimestamp the start timestamp when rewards are started
  /// @param endTimestamp the timestamp when the reward will run out
  event RewardInitialized(
    uint256 rate,
    uint256 available,
    uint256 startTimestamp,
    uint256 endTimestamp
  );
  /// @notice emitted when owner changes the reward rate
  /// @param rate the new reward rate
  event RewardRateChanged(uint256 rate);
  /// @notice emitted when owner adds more rewards to the pool
  /// @param amountAdded the amount of LINK rewards added to the pool
  event RewardAdded(uint256 amountAdded);
  /// @notice emitted when owner withdraws unreserved rewards
  /// @param amount the amount of rewards withdrawn
  event RewardWithdrawn(uint256 amount);
  /// @notice emitted when an on feed operator gets slashed.
  /// Node operators are not slashed more than the amount of rewards they
  /// have earned.  This means that a node operator that has not
  /// accumulated at least two weeks of rewards will be slashed
  /// less than an operator that has accumulated at least
  /// two weeks of rewards.
  event RewardSlashed(
    address[] operator,
    uint256[] slashedBaseRewards,
    uint256[] slashedDelegatedRewards
  );

  /// @notice This error is thrown when the updated reward duration is less than a month
  error RewardDurationTooShort();

  /// @notice This is the reward calculation precision variable. LINK token has the
  /// 1e18 multiplier which means that rewards are floored after 6 decimals
  /// points. Micro LINK is the smallest unit that is eligible for rewards.
  uint256 internal constant REWARD_PRECISION = 1e12;

  struct DelegatedRewards {
    // Count of delegates who are eligible for a share of a reward
    // This is always going to be less or equal to operatorsCount
    uint8 delegatesCount;
    // Tracks base reward amounts that goes to an operator as delegation rewards.
    // Used to correctly account for any changes in operator count, delegated amount, or reward rate.
    // Formula: duration * rate * amount
    uint96 cumulativePerDelegate;
    // Timestamp of the last time accumulate was called
    // `startTimestamp` <= `delegated.lastAccumulateTimestamp`
    uint32 lastAccumulateTimestamp;
  }

  struct BaseRewards {
    // Reward rate expressed in juels per second per micro LINK
    uint80 rate;
    // The cumulative LINK accrued per stake from past reward rates
    // expressed in juels per micro LINK
    // Formula: sum of (previousRate * elapsedDurationSinceLastAccumulate)
    uint96 cumulativePerMicroLINK;
    // Timestamp of the last time the base reward rate was accumulated
    uint32 lastAccumulateTimestamp;
  }

  struct MissedRewards {
    // Tracks missed base rewards that are deducted from late stakers
    uint96 base;
    // Tracks missed delegation rewards that are deducted from late delegates
    uint96 delegated;
  }

  struct ReservedRewards {
    // Tracks base reward amount reserved for stakers. This can be used after
    // `endTimestamp` to calculate unused amount.
    // This amount accumulates as the reward is utilized.
    // Formula: duration * rate * amount
    uint96 base;
    // Tracks delegated reward amount reserved for node operators. This can
    // be used after `endTimestamp` to calculate unused amount.
    // This amount accumulates as the reward is utilized.
    // Formula: duration * rate * amount
    uint96 delegated;
  }

  struct Reward {
    mapping(address => MissedRewards) missed;
    DelegatedRewards delegated;
    BaseRewards base;
    ReservedRewards reserved;
    // Timestamp when the reward stops accumulating. Has to support a very long
    // duration for scenarios with low reward rate.
    // `endTimestamp` >= `startTimestamp`
    uint256 endTimestamp;
    // Timestamp when the reward comes into effect
    // `startTimestamp` <= `endTimestamp`
    uint32 startTimestamp;
  }

  /// @notice initializes the reward with the defined parameters
  /// @param maxPoolSize maximum pool size that the reward is initialized with
  /// @param rate reward rate
  /// @param minRewardDuration the minimum duration rewards need to last for
  /// @param availableReward available reward amount
  /// @dev can only be called once. Any future reward changes have to be done
  /// using specific functions.
  function _initialize(
    Reward storage reward,
    uint256 maxPoolSize,
    uint256 rate,
    uint256 minRewardDuration,
    uint256 availableReward
  ) internal {
    if (reward.startTimestamp != 0) revert();

    reward.base.rate = rate._toUint80();

    uint32 blockTimestamp = block.timestamp._toUint32();
    reward.startTimestamp = blockTimestamp;
    reward.delegated.lastAccumulateTimestamp = blockTimestamp;
    reward.base.lastAccumulateTimestamp = blockTimestamp;

    _updateDuration(
      reward,
      maxPoolSize,
      0,
      rate,
      minRewardDuration,
      availableReward,
      0
    );

    emit RewardInitialized(
      rate,
      availableReward,
      reward.startTimestamp,
      reward.endTimestamp
    );
  }

  /// @return bool true if the reward is expired (end <= now)
  function _isDepleted(Reward storage reward) internal view returns (bool) {
    return reward.endTimestamp <= block.timestamp;
  }

  /// @notice Helper function to accumulate base rewards
  /// Accumulate reward per micro LINK before changing reward rate.
  /// This keeps rewards prior to rate change unaffected.
  function _accumulateBaseRewards(Reward storage reward) internal {
    uint256 cappedTimestamp = _getCappedTimestamp(reward);

    reward.base.cumulativePerMicroLINK += (uint256(reward.base.rate) *
      (cappedTimestamp - uint256(reward.base.lastAccumulateTimestamp)))
      ._toUint96();
    reward.base.lastAccumulateTimestamp = cappedTimestamp._toUint32();
  }

  /// @notice Helper function to accumulate delegation rewards
  /// @dev This function is necessary to correctly account for any changes in
  /// eligible operators, delegated amount or reward rate.
  function _accumulateDelegationRewards(
    Reward storage reward,
    uint256 delegatedAmount
  ) internal {
    reward.delegated.cumulativePerDelegate = _calculateAccruedDelegatedRewards(
      reward,
      delegatedAmount
    )._toUint96();

    reward.delegated.lastAccumulateTimestamp = _getCappedTimestamp(reward)
      ._toUint32();
  }

  /// @notice Helper function to calculate rewards
  /// @param amount a staked amount to calculate rewards for
  /// @param duration a duration that the specified amount receives rewards for
  /// @return rewardsAmount
  function _calculateReward(
    Reward storage reward,
    uint256 amount,
    uint256 duration
  ) internal view returns (uint256) {
    return (amount * uint256(reward.base.rate) * duration) / REWARD_PRECISION;
  }

  /// @notice Calculates the amount of delegated rewards accumulated so far.
  /// @dev This function takes into account the amount of delegated
  /// rewards accumulated from previous delegate counts and amounts and
  /// the latest additional value.
  function _calculateAccruedDelegatedRewards(
    Reward storage reward,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
      ? uint256(reward.endTimestamp) -
        uint256(reward.delegated.lastAccumulateTimestamp)
      : block.timestamp - uint256(reward.delegated.lastAccumulateTimestamp);

    return
      uint256(reward.delegated.cumulativePerDelegate) +
      _calculateReward(
        reward,
        totalDelegatedAmount,
        elapsedDurationSinceLastAccumulate
      ) /
      // We are doing this to keep track of delegated rewards prior to the
      // first operator staking.
      Math.max(uint256(reward.delegated.delegatesCount), 1);
  }

  /// @notice Calculates the amount of rewards accrued so far.
  /// @dev This function takes into account the amount of
  /// rewards accumulated from previous rates in addition to
  /// the rewards that will be accumulated based off the current rate
  /// over a given duration.
  function _calculateAccruedBaseRewards(Reward storage reward, uint256 amount)
    internal
    view
    returns (uint256)
  {
    uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
      ? (uint256(reward.endTimestamp) -
        uint256(reward.base.lastAccumulateTimestamp))
      : block.timestamp - uint256(reward.base.lastAccumulateTimestamp);

    return
      (amount *
        (uint256(reward.base.cumulativePerMicroLINK) +
          uint256(reward.base.rate) *
          elapsedDurationSinceLastAccumulate)) / REWARD_PRECISION;
  }

  /// @notice We use a simplified reward calculation formula because we know that
  /// the reward is expired. We accumulate reward per micro LINK
  /// before concluding the pool so we can avoid reading additional storage
  /// variables.
  function _calculateConcludedBaseRewards(
    Reward storage reward,
    uint256 amount,
    address staker
  ) internal view returns (uint256) {
    return
      (amount * uint256(reward.base.cumulativePerMicroLINK)) /
      REWARD_PRECISION -
      uint256(reward.missed[staker].base);
  }

  /// @notice Reserves staker rewards. This is necessary to make sure that
  /// there are always enough available LINK tokens for all stakers until the
  /// reward end timestamp. The amount is calculated for the remaining reward
  /// duration using the current reward rate.
  /// @param baseRewardAmount The amount of base rewards to reserve
  /// or unreserve for
  /// @param delegatedRewardAmount The amount of delegated rewards to reserve
  /// or unreserve for
  /// @param isReserving true if function should reserve more rewards. false will
  /// unreserve and deduct from the reserved total
  function _updateReservedRewards(
    Reward storage reward,
    uint256 baseRewardAmount,
    uint256 delegatedRewardAmount,
    bool isReserving
  ) private {
    uint256 duration = _getRemainingDuration(reward);
    uint96 deltaBaseReward = _calculateReward(
      reward,
      baseRewardAmount,
      duration
    )._toUint96();
    uint96 deltaDelegatedReward = _calculateReward(
      reward,
      delegatedRewardAmount,
      duration
    )._toUint96();
    // add if is reserving, subtract otherwise
    if (isReserving) {
      // We round up (by adding an extra juels) if the amount includes an
      // increment below REWARD_PRECISION. We always need to reserve more than
      // the user will earn. The consequence of this is that we’ll have dust
      // LINK amounts left over in the contract after stakers exit. The amount
      // will be approximately 1 juels for every call to reserve function,
      // which translates to <1 LINK for the duration of staking v0.1 contract.
      if (baseRewardAmount % REWARD_PRECISION > 0) deltaBaseReward++;
      if (delegatedRewardAmount % REWARD_PRECISION > 0) deltaDelegatedReward++;

      reward.reserved.base += deltaBaseReward;
      reward.reserved.delegated += deltaDelegatedReward;
    } else {
      reward.reserved.base -= deltaBaseReward;
      reward.reserved.delegated -= deltaDelegatedReward;
    }
  }

  /// @notice Increase reserved staker rewards.
  /// @param baseRewardAmount The amount of base rewards to reserve
  /// or unreserve for
  /// @param delegatedRewardAmount The amount of delegated rewards to reserve
  /// or unreserve for
  function _reserve(
    Reward storage reward,
    uint256 baseRewardAmount,
    uint256 delegatedRewardAmount
  ) internal {
    _updateReservedRewards(
      reward,
      baseRewardAmount,
      delegatedRewardAmount,
      true
    );
  }

  /// @notice Decrease reserved staker rewards.
  /// @param baseRewardAmount The amount of base rewards to reserve
  /// or unreserve for
  /// @param delegatedRewardAmount The amount of delegated rewards to reserve
  /// or unreserve for
  function _unreserve(
    Reward storage reward,
    uint256 baseRewardAmount,
    uint256 delegatedRewardAmount
  ) internal {
    _updateReservedRewards(
      reward,
      baseRewardAmount,
      delegatedRewardAmount,
      false
    );
  }

  /// @notice function does multiple things:
  /// - Unreserves future staking rewards to make them available for withdrawal;
  /// - Expires the reward to stop rewards from accumulating;
  function _release(
    Reward storage reward,
    uint256 amount,
    uint256 delegatedAmount
  ) internal {
    // Accumulate base and delegation rewards before unreserving rewards to save gas costs.
    // We can use the accumulated reward per micro LINK and accumulated delegation reward
    // to simplify reward calculations in migrate() and unstake() instead of recalculating.
    _accumulateDelegationRewards(reward, delegatedAmount);
    _accumulateBaseRewards(reward);
    _unreserve(reward, amount - delegatedAmount, delegatedAmount);

    reward.endTimestamp = block.timestamp;
  }

  /// @notice calculates an amount that community stakers have to delegate to operators
  /// @param amount base staked amount to calculate delegated amount against
  /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
  function _getDelegatedAmount(
    uint256 amount,
    uint256 delegationRateDenominator
  ) internal pure returns (uint256) {
    return amount / delegationRateDenominator;
  }

  /// @notice calculates the amount of stake that remains after accounting for delegation requirement
  /// @param amount base staked amount to calculate non-delegated amount against
  /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
  function _getNonDelegatedAmount(
    uint256 amount,
    uint256 delegationRateDenominator
  ) internal pure returns (uint256) {
    return amount - _getDelegatedAmount(amount, delegationRateDenominator);
  }

  /// @return uint256 the remaining reward duration (time until end), or 0 if expired/ended.
  function _getRemainingDuration(Reward storage reward)
    internal
    view
    returns (uint256)
  {
    return _isDepleted(reward) ? 0 : reward.endTimestamp - block.timestamp;
  }

  /// @notice This function is called when the staking pool is initialized,
  /// pool size is changed, reward rates are changed, rewards are added, and an alert is raised
  /// @param maxPoolSize Current maximum staking pool size
  /// @param totalStakedAmount Currently staked amount across community stakers and operators
  /// @param newRate New reward rate if it needs to be changed
  /// @param minRewardDuration The minimum duration rewards need to last for
  /// @param availableReward available reward amount
  /// @param totalDelegatedAmount total delegated amount delegated by community stakers
  function _updateDuration(
    Reward storage reward,
    uint256 maxPoolSize,
    uint256 totalStakedAmount,
    uint256 newRate,
    uint256 minRewardDuration,
    uint256 availableReward,
    uint256 totalDelegatedAmount
  ) internal {
    uint256 earnedBaseRewards = _getEarnedBaseRewards(
      reward,
      totalStakedAmount,
      totalDelegatedAmount
    );
    uint256 earnedDelegationRewards = _getEarnedDelegationRewards(
      reward,
      totalDelegatedAmount
    );

    uint256 remainingRewards = availableReward -
      earnedBaseRewards -
      earnedDelegationRewards;

    if (newRate != uint256(reward.base.rate)) {
      reward.base.rate = newRate._toUint80();
    }

    uint256 availableRewardDuration = (remainingRewards * REWARD_PRECISION) /
      (newRate * maxPoolSize);

    // Validate that the new reward duration is at least the min reward duration.
    // This is a safety mechanism to guard against operational mistakes.
    if (availableRewardDuration < minRewardDuration)
      revert RewardDurationTooShort();

    // Because we utilize unreserved rewards we need to update reserved amounts as well.
    // Reserved amounts are set to currently earned rewards plus new future rewards
    // based on the available reward duration.
    reward.reserved.base = (earnedBaseRewards +
      // Future base rewards for currently staked amounts based on the new duration
      _calculateReward(
        reward,
        totalStakedAmount - totalDelegatedAmount,
        availableRewardDuration
      ))._toUint96();

    reward.reserved.delegated = (earnedDelegationRewards +
      // Future delegation rewards for currently staked amounts based on the new duration
      _calculateReward(reward, totalDelegatedAmount, availableRewardDuration))
      ._toUint96();

    reward.endTimestamp = block.timestamp + availableRewardDuration;
  }

  /// @return The total amount of base rewards earned by all stakers
  function _getEarnedBaseRewards(
    Reward storage reward,
    uint256 totalStakedAmount,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    return
      reward.reserved.base -
      _calculateReward(
        reward,
        totalStakedAmount - totalDelegatedAmount,
        _getRemainingDuration(reward)
      );
  }

  /// @return The total amount of delegated rewards earned by all node operators
  function _getEarnedDelegationRewards(
    Reward storage reward,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    return
      reward.reserved.delegated -
      _calculateReward(
        reward,
        totalDelegatedAmount,
        _getRemainingDuration(reward)
      );
  }

  /// @notice Slashes all on feed node operators.
  /// Node operators are slashed the minimum of either the
  /// amount of rewards they have earned or the amount
  /// of rewards earned by the minimum operator stake amount
  /// over the slashable duration.
  function _slashOnFeedOperators(
    Reward storage reward,
    uint256 minOperatorStakeAmount,
    uint256 slashableDuration,
    address[] memory feedOperators,
    mapping(address => StakingPoolLib.Staker) storage stakers,
    uint256 totalDelegatedAmount
  ) internal {
    if (reward.delegated.delegatesCount == 0) return; // Skip slashing if there are no staking operators

    uint256 slashableBaseRewards = _getSlashableBaseRewards(
      reward,
      minOperatorStakeAmount,
      slashableDuration
    );
    uint256 slashableDelegatedRewards = _getSlashableDelegatedRewards(
      reward,
      slashableDuration,
      totalDelegatedAmount
    );

    uint256 totalSlashedBaseReward;
    uint256 totalSlashedDelegatedReward;

    uint256[] memory slashedBaseAmounts = new uint256[](feedOperators.length);
    uint256[] memory slashedDelegatedAmounts = new uint256[](
      feedOperators.length
    );

    for (uint256 i; i < feedOperators.length; i++) {
      address operator = feedOperators[i];
      uint256 operatorStakedAmount = stakers[operator].stakedAmount;
      if (operatorStakedAmount == 0) continue;
      slashedBaseAmounts[i] = _slashOperatorBaseRewards(
        reward,
        slashableBaseRewards,
        operator,
        operatorStakedAmount
      );
      slashedDelegatedAmounts[i] = _slashOperatorDelegatedRewards(
        reward,
        slashableDelegatedRewards,
        operator,
        totalDelegatedAmount
      );
      totalSlashedBaseReward += slashedBaseAmounts[i];
      totalSlashedDelegatedReward += slashedDelegatedAmounts[i];
    }
    reward.reserved.base -= totalSlashedBaseReward._toUint96();
    reward.reserved.delegated -= totalSlashedDelegatedReward._toUint96();

    emit RewardSlashed(
      feedOperators,
      slashedBaseAmounts,
      slashedDelegatedAmounts
    );
  }

  /// @return The amount of base rewards to slash
  /// @notice The amount of rewards accrued over the slashable duration for a
  /// minimum node operator stake amount
  function _getSlashableBaseRewards(
    Reward storage reward,
    uint256 minOperatorStakeAmount,
    uint256 slashableDuration
  ) private view returns (uint256) {
    return _calculateReward(reward, minOperatorStakeAmount, slashableDuration);
  }

  /// @return The amount of delegated rewards to slash
  /// @dev The amount of delegated rewards accrued over the slashable duration
  function _getSlashableDelegatedRewards(
    Reward storage reward,
    uint256 slashableDuration,
    uint256 totalDelegatedAmount
  ) private view returns (uint256) {
    DelegatedRewards memory delegatedRewards = reward.delegated;

    return
      _calculateReward(reward, totalDelegatedAmount, slashableDuration) /
      // We don't validate for delegatedRewards.delegatesCount to be a
      // non-zero value as this is already checked in _slashOnFeedOperators.
      uint256(delegatedRewards.delegatesCount);
  }

  /// @notice Slashes an on feed node operator the minimum of
  /// either the total amount of base rewards they have
  /// earned or the amount of rewards earned by the
  ///  minimum operator stake amount over the slashable duration.
  function _slashOperatorBaseRewards(
    Reward storage reward,
    uint256 slashableRewards,
    address operator,
    uint256 operatorStakedAmount
  ) private returns (uint256) {
    uint256 earnedRewards = _getOperatorEarnedBaseRewards(
      reward,
      operator,
      operatorStakedAmount
    );
    uint256 slashedRewards = Math.min(slashableRewards, earnedRewards); // max capped by earnings
    reward.missed[operator].base += slashedRewards._toUint96();
    return slashedRewards;
  }

  /// @notice Slashes an on feed node operator the minimum of
  /// either the total amount of delegated rewards they have
  /// earned or the amount of delegated rewards they have
  /// earned over the slashable duration.
  function _slashOperatorDelegatedRewards(
    Reward storage reward,
    uint256 slashableRewards,
    address operator,
    uint256 totalDelegatedAmount
  ) private returns (uint256) {
    uint256 earnedRewards = _getOperatorEarnedDelegatedRewards(
      reward,
      operator,
      totalDelegatedAmount
    );
    uint256 slashedRewards = Math.min(slashableRewards, earnedRewards); // max capped by earnings
    reward.missed[operator].delegated += slashedRewards._toUint96();
    return slashedRewards;
  }

  /// @return The amount of base rewards an operator
  /// has earned.
  function _getOperatorEarnedBaseRewards(
    Reward storage reward,
    address operator,
    uint256 operatorStakedAmount
  ) internal view returns (uint256) {
    return
      _calculateAccruedBaseRewards(reward, operatorStakedAmount) -
      uint256(reward.missed[operator].base);
  }

  /// @return The amount of delegated rewards an operator
  /// has earned.
  function _getOperatorEarnedDelegatedRewards(
    Reward storage reward,
    address operator,
    uint256 totalDelegatedAmount
  ) internal view returns (uint256) {
    return
      _calculateAccruedDelegatedRewards(reward, totalDelegatedAmount) -
      uint256(reward.missed[operator].delegated);
  }

  /// @return The current timestamp or, if the current timestamp has passed reward
  /// end timestamp, reward end timestamp.
  /// @dev This is necessary to ensure that rewards are calculated correctly
  /// after the reward is depleted.
  function _getCappedTimestamp(Reward storage reward)
    internal
    view
    returns (uint256)
  {
    return Math.min(uint256(reward.endTimestamp), block.timestamp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @notice Owner functions restricted to the setup and maintenance
/// of the staking contract by the owner.
interface IStakingOwner {
  /// @notice This error is thrown when an zero delegation rate is supplied
  error InvalidDelegationRate();

  /// @notice This error is thrown when an invalid regular period threshold is supplied
  error InvalidRegularPeriodThreshold();

  /// @notice This error is thrown when an invalid min operator stake amount is
  /// supplied
  error InvalidMinOperatorStakeAmount();

  /// @notice This error is thrown when an invalid min community stake amount
  /// is supplied
  error InvalidMinCommunityStakeAmount();

  /// @notice This error is thrown when an invalid max alerting reward is
  /// supplied
  error InvalidMaxAlertingRewardAmount();

  /// @notice This error is thrown when the pool is started with an empty
  /// merkle root
  error MerkleRootNotSet();

  /// @notice Adds one or more operators to a list of operators
  /// @dev Should only callable by the Owner
  /// @param operators A list of operator addresses to add
  function addOperators(address[] calldata operators) external;

  /// @notice Removes one or more operators from a list of operators. When an
  /// operator is removed, we store their principal in a separate mapping to
  /// prevent immediate withdrawals. This is so that the removed operator can
  /// only unstake at the same time as every other staker.
  /// @dev Should only be callable by the owner when the pool is open.
  /// When an operator is removed they can stake as a community staker.
  /// We allow that because the alternative (checking for removed stake before
  /// staking) is going to unnecessarily increase gas costs in 99.99% of the
  /// cases.
  /// @param operators A list of operator addresses to remove
  function removeOperators(address[] calldata operators) external;

  /// @notice Allows the contract owner to set the list of on-feed operator addresses who are subject to slashing
  /// @dev Existing feed operators are cleared before setting the new operators.
  /// @param operators New list of on-feed operator staker addresses
  function setFeedOperators(address[] calldata operators) external;

  /// @return List of the ETH-USD feed node operators' staking addresses
  function getFeedOperators() external view returns (address[] memory);

  /// @notice This function can be called to change the reward rate for the pool.
  /// This change only affects future rewards, i.e. rewards earned at a previous
  /// rate are unaffected.
  /// @dev Should only be callable by the owner. The rate can be increased or decreased.
  /// The new rate cannot be 0.
  /// @param rate The new reward rate
  function changeRewardRate(uint256 rate) external;

  /// @notice This function can be called to add rewards to the pool
  /// @dev Should only be callable by the owner
  /// @param amount The amount of rewards to add to the pool
  function addReward(uint256 amount) external;

  /// @notice This function can be called to withdraw unused reward amount from
  /// the staking pool. It can be called before the pool is initialized, after
  /// the pool is concluded or when the reward expires.
  /// @dev Should only be callable by the owner when the pool is closed
  function withdrawUnusedReward() external;

  /// @notice Set the pool config
  /// @param maxPoolSize The max amount of staked LINK allowed in the pool
  /// @param maxCommunityStakeAmount The max amount of LINK a community staker can stake
  /// @param maxOperatorStakeAmount The max amount of LINK a Node Op can stake
  function setPoolConfig(
    uint256 maxPoolSize,
    uint256 maxCommunityStakeAmount,
    uint256 maxOperatorStakeAmount
  ) external;

  /// @notice Transfers LINK tokens and initializes the reward
  /// @dev Uses ERC20 approve + transferFrom flow
  /// @param amount rewards amount in LINK
  /// @param initialRewardRate The amount of LINK earned per second for
  /// each LINK staked.
  function start(uint256 amount, uint256 initialRewardRate) external;

  /// @notice Closes the pool, unreserving future staker rewards, expires the
  /// reward and releases unreserved rewards
  function conclude() external;

  /// @notice This function pauses staking
  /// @dev Sets the pause flag to true
  function emergencyPause() external;

  /// @notice This function unpauses staking
  /// @dev Sets the pause flag to false
  function emergencyUnpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SafeCast} from './SafeCast.sol';

library StakingPoolLib {
  using SafeCast for uint256;

  /// @notice This event is emitted when the staking pool is opened for stakers
  event PoolOpened();
  /// @notice This event is emitted when the staking pool is concluded
  event PoolConcluded();
  /// @notice This event is emitted when the staking pool's maximum size is
  /// increased
  /// @param maxPoolSize the new maximum pool size
  event PoolSizeIncreased(uint256 maxPoolSize);
  /// @notice This event is emitted when the maximum stake amount
  // for community stakers is increased
  /// @param maxStakeAmount the new maximum stake amount
  event MaxCommunityStakeAmountIncreased(uint256 maxStakeAmount);
  /// @notice This event is emitted when the maximum stake amount for node
  /// operators is increased
  /// @param maxStakeAmount the new maximum stake amount
  event MaxOperatorStakeAmountIncreased(uint256 maxStakeAmount);
  /// @notice This event is emitted when an operator is added
  /// @param operator address of the operator that was added to the staking pool
  event OperatorAdded(address operator);
  /// @notice This event is emitted when an operator is removed
  /// @param operator address of the operator that was removed from the staking pool
  /// @param amount principal amount that will be available for withdrawal when staking ends
  event OperatorRemoved(address operator, uint256 amount);
  /// @notice This event is emitted when the contract owner sets the list
  /// of feed operators subject to slashing
  /// @param feedOperators new list of feed operator staking addresses
  event FeedOperatorsSet(address[] feedOperators);
  /// @notice Surfaces the required pool status to perform an operation
  /// @param currentStatus current status of the pool (true if open / false if closed)
  /// @param requiredStatus required status of the pool to proceed
  /// (true if pool must be open / false if pool must be closed)
  error InvalidPoolStatus(bool currentStatus, bool requiredStatus);
  /// @notice This error is raised when attempting to decrease maximum pool size
  /// @param maxPoolSize the current maximum pool size
  error InvalidPoolSize(uint256 maxPoolSize);
  /// @notice This error is raised when attempting to decrease maximum stake amount
  /// for community stakers or node operators
  /// @param maxStakeAmount the current maximum stake amount
  error InvalidMaxStakeAmount(uint256 maxStakeAmount);
  /// @notice This error is raised when attempting to add more node operators without
  /// sufficient available pool space to reserve their allocations.
  /// @param remainingPoolSize the remaining pool space available to reserve
  /// @param requiredPoolSize the required reserved pool space to add new node operators
  error InsufficientRemainingPoolSpace(
    uint256 remainingPoolSize,
    uint256 requiredPoolSize
  );
  /// @param requiredAmount minimum required stake amount
  error InsufficientStakeAmount(uint256 requiredAmount);
  /// @notice This error is raised when stakers attempt to stake past pool limits
  /// @param remainingAmount maximum remaining amount that can be staked. This is
  /// the difference between the existing staked amount and the individual and global limits.
  error ExcessiveStakeAmount(uint256 remainingAmount);
  /// @notice This error is raised when stakers attempt to exit the pool
  /// @param staker address of the staker who attempted to withdraw funds
  error StakeNotFound(address staker);
  /// @notice This error is raised when addresses with existing stake is added as an operator
  /// @param staker address of the staker who is being added as an operator
  error ExistingStakeFound(address staker);
  /// @notice This error is raised when an address is duplicated in the supplied list of operators.
  /// This can happen in addOperators and setFeedOperators functions.
  /// @param operator address of the operator
  error OperatorAlreadyExists(address operator);
  /// @notice This error is thrown when the owner attempts to remove an on-feed operator.
  /// @dev The owner must remove the operator from the on-feed list first.
  error OperatorIsAssignedToFeed(address operator);
  /// @notice This error is raised when removing an operator in removeOperators
  /// and setFeedOperators
  /// @param operator address of the operator
  error OperatorDoesNotExist(address operator);
  /// @notice This error is raised when operator has been removed from the pool
  /// and is attempted to be readded
  /// @param operator address of the locked operator
  error OperatorIsLocked(address operator);
  /// @notice This error is raised when attempting to start staking with less
  /// than the minimum required node operators
  /// @param currentOperatorsCount The current number of operators in the staking pool
  /// @param minInitialOperatorsCount The minimum required number of operators
  /// in the staking pool before opening
  error InadequateInitialOperatorsCount(
    uint256 currentOperatorsCount,
    uint256 minInitialOperatorsCount
  );

  struct PoolLimits {
    // The max amount of staked LINK allowed in the pool
    uint96 maxPoolSize;
    // The max amount of LINK a community staker can stake
    uint80 maxCommunityStakeAmount;
    // The max amount of LINK a Node Op can stake
    uint80 maxOperatorStakeAmount;
  }

  struct PoolState {
    // Flag that signals if the staking pool is open for staking
    bool isOpen;
    // Total number of operators added to the staking pool
    uint8 operatorsCount;
    // Total amount of LINK staked by community stakers
    uint96 totalCommunityStakedAmount;
    // Total amount of LINK staked by operators
    uint96 totalOperatorStakedAmount;
  }

  struct Staker {
    // Flag that signals whether a staker is an operator
    bool isOperator;
    // Flag that signals whether a staker is an on-feed operator
    bool isFeedOperator;
    // Amount of LINK staked by a staker
    uint96 stakedAmount;
    // Amount of LINK staked by a removed operator that can be withdrawn
    // Removed operators can only withdraw at the end of staking.
    // Used to know which operators have been removed.
    uint96 removedStakeAmount;
  }

  struct Pool {
    mapping(address => Staker) stakers;
    address[] feedOperators;
    PoolState state;
    PoolLimits limits;
    // Sum of removed operator principals that have not been withdrawn.
    // Used to make sure that contract's balance is correct.
    // total staked amount + total removed amount + available rewards = current balance
    uint256 totalOperatorRemovedAmount;
  }

  /// @notice Sets staking pool parameters
  /// @param maxPoolSize Maximum total stake amount across all stakers
  /// @param maxCommunityStakeAmount Maximum stake amount for a single community staker
  /// @param maxOperatorStakeAmount Maximum stake amount for a single node operator
  function _setConfig(
    Pool storage pool,
    uint256 maxPoolSize,
    uint256 maxCommunityStakeAmount,
    uint256 maxOperatorStakeAmount
  ) internal {
    if (maxOperatorStakeAmount > maxPoolSize)
      revert InvalidMaxStakeAmount(maxOperatorStakeAmount);

    if (pool.limits.maxPoolSize > maxPoolSize)
      revert InvalidPoolSize(maxPoolSize);
    if (pool.limits.maxCommunityStakeAmount > maxCommunityStakeAmount)
      revert InvalidMaxStakeAmount(maxCommunityStakeAmount);
    if (pool.limits.maxOperatorStakeAmount > maxOperatorStakeAmount)
      revert InvalidMaxStakeAmount(maxOperatorStakeAmount);

    PoolState memory poolState = pool.state;
    if (
      maxPoolSize <
      (poolState.operatorsCount * maxOperatorStakeAmount) +
        poolState.totalCommunityStakedAmount
    ) revert InvalidMaxStakeAmount(maxOperatorStakeAmount);
    if (pool.limits.maxPoolSize != maxPoolSize) {
      pool.limits.maxPoolSize = maxPoolSize._toUint96();
      emit PoolSizeIncreased(maxPoolSize);
    }
    if (pool.limits.maxCommunityStakeAmount != maxCommunityStakeAmount) {
      pool.limits.maxCommunityStakeAmount = maxCommunityStakeAmount._toUint80();
      emit MaxCommunityStakeAmountIncreased(maxCommunityStakeAmount);
    }
    if (pool.limits.maxOperatorStakeAmount != maxOperatorStakeAmount) {
      pool.limits.maxOperatorStakeAmount = maxOperatorStakeAmount._toUint80();
      emit MaxOperatorStakeAmountIncreased(maxOperatorStakeAmount);
    }
  }

  /// @notice Opens the staking pool
  function _open(Pool storage pool, uint256 minInitialOperatorCount) internal {
    if (uint256(pool.state.operatorsCount) < minInitialOperatorCount)
      revert InadequateInitialOperatorsCount(
        pool.state.operatorsCount,
        minInitialOperatorCount
      );
    pool.state.isOpen = true;
    emit PoolOpened();
  }

  /// @notice Closes the staking pool
  function _close(Pool storage pool) internal {
    pool.state.isOpen = false;
    emit PoolConcluded();
  }

  /// @notice Returns true if a supplied staker address is in the operators list
  /// @param staker Address of a staker
  /// @return bool
  function _isOperator(Pool storage pool, address staker)
    internal
    view
    returns (bool)
  {
    return pool.stakers[staker].isOperator;
  }

  /// @notice Returns the sum of all principal staked in the pool
  /// @return totalStakedAmount
  function _getTotalStakedAmount(Pool storage pool)
    internal
    view
    returns (uint256)
  {
    StakingPoolLib.PoolState memory poolState = pool.state;
    return
      uint256(poolState.totalCommunityStakedAmount) +
      uint256(poolState.totalOperatorStakedAmount);
  }

  /// @notice Returns the amount of remaining space available in the pool for
  /// community stakers. Community stakers can only stake up to this amount
  /// even if they are within their individual limits.
  /// @return remainingPoolSpace
  function _getRemainingPoolSpace(Pool storage pool)
    internal
    view
    returns (uint256)
  {
    StakingPoolLib.PoolState memory poolState = pool.state;
    return
      uint256(pool.limits.maxPoolSize) -
      (uint256(poolState.operatorsCount) *
        uint256(pool.limits.maxOperatorStakeAmount)) -
      uint256(poolState.totalCommunityStakedAmount);
  }

  /// @dev Required conditions for adding operators:
  /// - Operators can only been added to the pool if they have no prior stake.
  /// - Operators can only been readded to the pool if they have no removed
  /// stake.
  /// - Operators cannot be added to the pool after staking ends (either through
  /// conclusion or through reward expiry).
  function _addOperators(Pool storage pool, address[] calldata operators)
    internal
  {
    uint256 requiredReservedPoolSpace = operators.length *
      uint256(pool.limits.maxOperatorStakeAmount);
    uint256 remainingPoolSpace = _getRemainingPoolSpace(pool);
    if (requiredReservedPoolSpace > remainingPoolSpace)
      revert InsufficientRemainingPoolSpace(
        remainingPoolSpace,
        requiredReservedPoolSpace
      );

    for (uint256 i; i < operators.length; i++) {
      if (pool.stakers[operators[i]].isOperator)
        revert OperatorAlreadyExists(operators[i]);
      if (pool.stakers[operators[i]].stakedAmount > 0)
        revert ExistingStakeFound(operators[i]);
      // Avoid edge-cases where we attempt to add an operator that has
      // locked principal (this means that the operator was previously removed).
      if (pool.stakers[operators[i]].removedStakeAmount > 0)
        revert OperatorIsLocked(operators[i]);
      pool.stakers[operators[i]].isOperator = true;
      emit OperatorAdded(operators[i]);
    }

    // Safely update operators count with respect to the maximum of 255 operators
    pool.state.operatorsCount =
      pool.state.operatorsCount +
      operators.length._toUint8();
  }

  /// @notice Helper function to set the list of on-feed Operator addresses
  /// @param operators List of Operator addresses
  function _setFeedOperators(Pool storage pool, address[] calldata operators)
    internal
  {
    for (uint256 i; i < pool.feedOperators.length; i++) {
      delete pool.stakers[pool.feedOperators[i]].isFeedOperator;
    }
    delete pool.feedOperators;

    for (uint256 i; i < operators.length; i++) {
      address newFeedOperator = operators[i];
      if (!_isOperator(pool, newFeedOperator))
        revert OperatorDoesNotExist(newFeedOperator);
      if (pool.stakers[newFeedOperator].isFeedOperator)
        revert OperatorAlreadyExists(newFeedOperator);

      pool.stakers[newFeedOperator].isFeedOperator = true;
    }
    pool.feedOperators = operators;

    emit FeedOperatorsSet(operators);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IAlertsController {
  /// @param alerter The address of an alerter
  /// @param roundId The feed's round ID that an alert has been raised for
  /// @param rewardAmount The amount of LINK rewarded to the alerter
  /// @notice Emitted when a valid alert is raised for a feed round
  event AlertRaised(address alerter, uint256 roundId, uint256 rewardAmount);

  /// @param roundId The feed's round ID that the alerter is trying to raise an alert for
  /// @notice This error is thrown when an alerter tries to raise an
  // alert for a round that has already been alerted.
  error AlertAlreadyExists(uint256 roundId);

  /// @notice This error is thrown when alerting conditions are not met and the
  /// alert is invalid.
  error AlertInvalid();

  /// @notice This function creates an alert for a stalled feed
  function raiseAlert() external;

  /// @notice This function checks to see whether the alerter may raise an alert
  /// to claim rewards
  function canAlert(address alerter) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IMigratable {
  /// @notice This event is emitted when a migration target is proposed by the contract owner.
  /// @param migrationTarget Contract address to migrate stakes to.
  event MigrationTargetProposed(address migrationTarget);
  /// @notice This event is emitted after a 7 day period has passed since a migration target is proposed, and the target is accepted.
  /// @param migrationTarget Contract address to migrate stakes to.
  event MigrationTargetAccepted(address migrationTarget);
  /// @notice This event is emitted when a staker migrates their stake to the migration target.
  /// @param staker Staker address
  /// @param principal Principal amount deposited
  /// @param baseReward Amount of base rewards withdrawn
  /// @param delegationReward Amount of delegation rewards withdrawn (if applicable)
  /// @param data Migration payload
  event Migrated(
    address staker,
    uint256 principal,
    uint256 baseReward,
    uint256 delegationReward,
    bytes data
  );

  /// @notice This error is raised when the contract owner supplies a non-contract migration target.
  error InvalidMigrationTarget();

  /// @notice This function returns the migration target contract address
  function getMigrationTarget() external view returns (address);

  /// @notice This function allows the contract owner to set a proposed
  /// migration target address. If the migration target is valid it renounces
  /// the previously accepted migration target (if any).
  /// @param migrationTarget Contract address to migrate stakes to.
  function proposeMigrationTarget(address migrationTarget) external;

  /// @notice This function allows the contract owner to accept a proposed migration target address after a waiting period.
  function acceptMigrationTarget() external;

  /// @notice This function allows stakers to migrate funds to a new staking pool.
  /// @param data Migration path details
  function migrate(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IStaking {
  /// @notice This event is emitted when a staker adds stake to the pool.
  /// @param staker Staker address
  /// @param newStake New principal amount staked
  /// @param totalStake Total principal amount staked
  event Staked(address staker, uint256 newStake, uint256 totalStake);
  /// @notice This event is emitted when a staker exits the pool.
  /// @param staker Staker address
  /// @param principal Principal amount staked
  /// @param baseReward base reward earned
  /// @param delegationReward delegation reward earned, if any
  event Unstaked(
    address staker,
    uint256 principal,
    uint256 baseReward,
    uint256 delegationReward
  );

  /// @notice This error is thrown whenever the sender is not the LINK token
  error SenderNotLinkToken();

  /// @notice This error is thrown whenever an address does not have access
  /// to successfully execute a transaction
  error AccessForbidden();

  /// @notice This error is thrown whenever a zero-address is supplied when
  /// a non-zero address is required
  error InvalidZeroAddress();

  /// @notice This function allows stakers to exit the pool after it has been
  /// concluded. It returns the principal as well as base and delegation
  /// rewards.
  function unstake() external;

  /// @notice This function allows removed operators to withdraw their original
  /// principal. Operators can only withdraw after the pool is closed, like
  /// every other staker.
  function withdrawRemovedStake() external;

  /// @return address LINK token contract's address that is used by the pool
  function getChainlinkToken() external view returns (address);

  /// @param staker address
  /// @return uint256 staker's staked principal amount
  function getStake(address staker) external view returns (uint256);

  /// @notice Returns true if an address is an operator
  function isOperator(address staker) external view returns (bool);

  /// @notice The staking pool starts closed and only allows
  /// stakers to stake once it's opened
  /// @return bool pool status
  function isActive() external view returns (bool);

  /// @return uint256 current maximum staking pool size
  function getMaxPoolSize() external view returns (uint256);

  /// @return uint256 minimum amount that can be staked by a community staker
  /// @return uint256 maximum amount that can be staked by a community staker
  function getCommunityStakerLimits() external view returns (uint256, uint256);

  /// @return uint256 minimum amount that can be staked by an operator
  /// @return uint256 maximum amount that can be staked by an operator
  function getOperatorLimits() external view returns (uint256, uint256);

  /// @return uint256 reward initialization timestamp
  /// @return uint256 reward expiry timestamp
  function getRewardTimestamps() external view returns (uint256, uint256);

  /// @return uint256 current reward rate, expressed in juels per second per micro LINK
  function getRewardRate() external view returns (uint256);

  /// @return uint256 current delegation rate
  function getDelegationRateDenominator() external view returns (uint256);

  /// @return uint256 total amount of LINK tokens made available for rewards in
  /// Juels
  /// @dev This reflects how many rewards were made available over the
  /// lifetime of the staking pool. This is not updated when the rewards are
  /// unstaked or migrated by the stakers. This means that the contract balance
  /// will dip below available amount when the reward expires and users start
  /// moving their rewards.
  function getAvailableReward() external view returns (uint256);

  /// @return uint256 amount of base rewards earned by a staker in Juels
  function getBaseReward(address) external view returns (uint256);

  /// @return uint256 amount of delegation rewards earned by an operator in Juels
  function getDelegationReward(address) external view returns (uint256);

  /// @notice Total delegated amount is calculated by dividing the total
  /// community staker staked amount by the delegation rate, i.e.
  /// totalDelegatedAmount = pool.totalCommunityStakedAmount / delegationRateDenominator
  /// @return uint256 staked amount that is used when calculating delegation rewards in Juels
  function getTotalDelegatedAmount() external view returns (uint256);

  /// @notice Delegates count increases after an operator is added to the list
  /// of operators and stakes the minimum required amount.
  /// @return uint256 number of staking operators that are eligible for delegation rewards
  function getDelegatesCount() external view returns (uint256);

  /// @return uint256 total amount of base rewards earned by all stakers in Juels
  function getEarnedBaseRewards() external view returns (uint256);

  /// @return uint256 total amount of delegated rewards earned by all node operators in Juels
  function getEarnedDelegationRewards() external view returns (uint256);

  /// @return uint256 total amount staked by community stakers and operators in Juels
  function getTotalStakedAmount() external view returns (uint256);

  /// @return uint256 total amount staked by community stakers in Juels
  function getTotalCommunityStakedAmount() external view returns (uint256);

  /// @return uint256 the sum of removed operator principals that have not been
  /// withdrawn from the staking pool in Juels.
  /// @dev Used to make sure that contract's balance is correct.
  /// total staked amount + total removed amount + available rewards = current balance
  function getTotalRemovedAmount() external view returns (uint256);

  /// @notice This function returns the pause state
  /// @return bool whether or not the pool is paused
  function isPaused() external view returns (bool);

  /// @return address The address of the feed being monitored to raise alerts for
  function getMonitoredFeed() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IMerkleAccessController {
  /// @notice Emitted when the contract owner updates the staking allowlist
  /// @param newMerkleRoot The root of a new Staking allowlist merkle tree
  event MerkleRootChanged(bytes32 newMerkleRoot);

  /// @notice Validates if a community staker has access to the private staking pool
  /// @param staker The community staker's address
  /// @param proof Merkle proof for the community staker's allowlist
  function hasAccess(address staker, bytes32[] calldata proof)
    external
    view
    returns (bool);

  /// @notice This function is called to update the staking allowlist in a private staking pool
  /// @dev Only callable by the contract owner
  /// @param newMerkleRoot Merkle Tree root, used to prove access for community stakers
  /// will be required at start but can be removed at any time by the owner when
  /// staking access will be granted to the public.
  function setMerkleRoot(bytes32 newMerkleRoot) external;

  /// @return The current root of the Staking allowlist merkle tree
  function getMerkleRoot() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library SafeCast {
  error CastError();

  /// @notice This is used to safely case timestamps to uint8
  uint256 private constant MAX_UINT_8 = type(uint8).max;
  /// @notice This is used to safely case timestamps to uint32
  uint256 private constant MAX_UINT_32 = type(uint32).max;
  /// @notice This is used to safely case timestamps to uint80
  uint256 private constant MAX_UINT_80 = type(uint80).max;
  /// @notice This is used to safely case timestamps to uint96
  uint256 private constant MAX_UINT_96 = type(uint96).max;

  function _toUint8(uint256 value) internal pure returns (uint8) {
    if (value > MAX_UINT_8) revert CastError();
    return uint8(value);
  }

  function _toUint32(uint256 value) internal pure returns (uint32) {
    if (value > MAX_UINT_32) revert CastError();
    return uint32(value);
  }

  function _toUint80(uint256 value) internal pure returns (uint80) {
    if (value > MAX_UINT_80) revert CastError();
    return uint80(value);
  }

  function _toUint96(uint256 value) internal pure returns (uint96) {
    if (value > MAX_UINT_96) revert CastError();
    return uint96(value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}