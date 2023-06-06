// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {TypeAndVersionInterface} from "./interfaces/TypeAndVersionInterface.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {IStakingOwner} from "./interfaces/IStakingOwner.sol";
import {INodeStaking} from "./interfaces/INodeStaking.sol";
import {IMigratable} from "./interfaces/IMigratable.sol";
import {StakingPoolLib} from "./libraries/StakingPoolLib.sol";
import {RewardLib, SafeCast} from "./libraries/RewardLib.sol";
import {IMigrationTarget} from "./interfaces/IMigrationTarget.sol";

contract Staking is IStaking, IStakingOwner, INodeStaking, IMigratable, Ownable, TypeAndVersionInterface, Pausable {
    using StakingPoolLib for StakingPoolLib.Pool;
    using RewardLib for RewardLib.Reward;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /// @notice This struct defines the params required by the Staking contract's
    /// constructor.
    struct PoolConstructorParams {
        /// @notice The ARPA Token
        IERC20 arpa;
        /// @notice The initial maximum total stake amount across all stakers
        uint256 initialMaxPoolSize;
        /// @notice The initial maximum stake amount for a single community staker
        uint256 initialMaxCommunityStakeAmount;
        /// @notice The minimum stake amount that a community staker can stake
        uint256 minCommunityStakeAmount;
        /// @notice The stake amount that an operator should stake
        uint256 operatorStakeAmount;
        /// @notice The minimum number of node operators required to initialize the
        /// staking pool.
        uint256 minInitialOperatorCount;
        /// @notice The minimum reward duration after pool config updates and pool
        /// reward extensions
        uint256 minRewardDuration;
        /// @notice Used to calculate delegated stake amount
        /// = amount / delegation rate denominator = 100% / 100 = 1%
        uint256 delegationRateDenominator;
        /// @notice The freezing duration for stakers after unstaking
        uint256 unstakeFreezingDuration;
    }

    IERC20 internal immutable _arpa;
    StakingPoolLib.Pool internal _pool;
    RewardLib.Reward internal _reward;
    /// @notice The address of the controller contract
    address internal _controller;
    /// @notice The proposed address stakers will migrate funds to
    address internal _proposedMigrationTarget;
    /// @notice The timestamp of when the migration target was proposed at
    uint256 internal _proposedMigrationTargetAt;
    /// @notice The address stakers can migrate their funds to
    address internal _migrationTarget;

    /// @notice The stake amount that a node operator should stake
    uint256 internal immutable _operatorStakeAmount;
    /// @notice The minimum stake amount that a community staker can stake
    uint256 internal immutable _minCommunityStakeAmount;
    /// @notice The minimum number of node operators required to initialize the
    /// staking pool.
    uint256 internal immutable _minInitialOperatorCount;
    /// @notice The minimum reward duration after pool config updates and pool
    /// reward extensions
    uint256 internal immutable _minRewardDuration;
    /// @notice Used to calculate delegated stake amount
    /// = amount / delegation rate denominator = 100% / 100 = 1%
    uint256 internal immutable _delegationRateDenominator;
    /// @notice The freeze duration for stakers after unstaking
    uint256 internal immutable _unstakeFreezingDuration;

    event StakingConfigSet(
        address arpaAddress,
        uint256 initialMaxPoolSize,
        uint256 initialMaxCommunityStakeAmount,
        uint256 minCommunityStakeAmount,
        uint256 operatorStakeAmount,
        uint256 minInitialOperatorCount,
        uint256 minRewardDuration,
        uint256 delegationRateDenominator,
        uint256 unstakeFreezingDuration
    );

    constructor(PoolConstructorParams memory params) {
        if (address(params.arpa) == address(0)) revert InvalidZeroAddress();
        if (params.delegationRateDenominator == 0) revert InvalidDelegationRate();
        if (RewardLib.REWARD_PRECISION % params.delegationRateDenominator > 0) {
            revert InvalidDelegationRate();
        }
        if (params.operatorStakeAmount == 0) {
            revert InvalidOperatorStakeAmount();
        }
        if (params.minCommunityStakeAmount > params.initialMaxCommunityStakeAmount) {
            revert InvalidMinCommunityStakeAmount();
        }

        _pool._setConfig(params.initialMaxPoolSize, params.initialMaxCommunityStakeAmount);
        _arpa = params.arpa;
        _operatorStakeAmount = params.operatorStakeAmount;
        _minCommunityStakeAmount = params.minCommunityStakeAmount;
        _minInitialOperatorCount = params.minInitialOperatorCount;
        _minRewardDuration = params.minRewardDuration;
        _delegationRateDenominator = params.delegationRateDenominator;
        _unstakeFreezingDuration = params.unstakeFreezingDuration;

        emit StakingConfigSet(
            address(params.arpa),
            params.initialMaxPoolSize,
            params.initialMaxCommunityStakeAmount,
            params.minCommunityStakeAmount,
            params.operatorStakeAmount,
            params.minInitialOperatorCount,
            params.minRewardDuration,
            params.delegationRateDenominator,
            params.unstakeFreezingDuration
        );
    }

    // =======================
    // TypeAndVersionInterface
    // =======================

    /// @inheritdoc TypeAndVersionInterface
    function typeAndVersion() external pure override returns (string memory) {
        return "Staking 0.1.0";
    }

    // =============
    // IStakingOwner
    // =============

    /// @inheritdoc IStakingOwner
    function setController(address controller) external override(IStakingOwner) onlyOwner {
        if (controller == address(0)) revert InvalidZeroAddress();
        _controller = controller;

        emit ControllerSet(controller);
    }

    /// @inheritdoc IStakingOwner
    function setPoolConfig(uint256 maxPoolSize, uint256 maxCommunityStakeAmount)
        external
        override(IStakingOwner)
        onlyOwner
        whenActive
    {
        _pool._setConfig(maxPoolSize, maxCommunityStakeAmount);
    }

    /// @inheritdoc IStakingOwner
    function start(uint256 amount, uint256 rewardDuration) external override(IStakingOwner) onlyOwner {
        if (_reward.startTimestamp != 0) revert AlreadyInitialized();

        _pool._open(_minInitialOperatorCount);

        // We need to transfer ARPA balance before we initialize the reward to
        // calculate the new reward expiry timestamp.
        _arpa.safeTransferFrom(msg.sender, address(this), amount);

        _reward._initialize(_minRewardDuration, amount, rewardDuration);
    }

    /// @inheritdoc IStakingOwner
    function newReward(uint256 amount, uint256 rewardDuration)
        external
        override(IStakingOwner)
        onlyOwner
        whenInactive
    {
        _reward._accumulateBaseRewards(getTotalCommunityStakedAmount());
        _reward._accumulateDelegationRewards(getTotalDelegatedAmount(), getTotalCommunityStakedAmount());

        _arpa.safeTransferFrom(msg.sender, address(this), amount);

        _reward._initialize(_minRewardDuration, amount, rewardDuration);
    }

    /// @inheritdoc IStakingOwner
    function addReward(uint256 amount, uint256 rewardDuration) external override(IStakingOwner) onlyOwner whenActive {
        _reward._accumulateBaseRewards(getTotalCommunityStakedAmount());
        _reward._accumulateDelegationRewards(getTotalDelegatedAmount(), getTotalCommunityStakedAmount());

        _arpa.safeTransferFrom(msg.sender, address(this), amount);

        _reward._updateReward(amount, rewardDuration, _minRewardDuration);

        emit RewardLib.RewardAdded(amount, block.timestamp + rewardDuration);
    }

    /// @dev Required conditions for adding operators:
    /// - Operators can only be added to the pool if they have no prior stake.
    /// - Operators cannot be added to the pool after staking ends.
    /// @inheritdoc IStakingOwner
    function addOperators(address[] calldata operators) external override(IStakingOwner) onlyOwner {
        // If reward was initialized (meaning the pool was active) but the pool is
        // no longer active we want to prevent adding new operators.
        if (_reward.startTimestamp > 0 && !isActive()) {
            revert StakingPoolLib.InvalidPoolStatus(false, true);
        }

        _pool._addOperators(operators);
    }

    /// @inheritdoc IStakingOwner
    function emergencyPause() external override(IStakingOwner) onlyOwner {
        _pause();
    }

    /// @inheritdoc IStakingOwner
    function emergencyUnpause() external override(IStakingOwner) onlyOwner {
        _unpause();
    }

    // ===========
    // IMigratable
    // ===========

    /// @inheritdoc IMigratable
    function getMigrationTarget() external view override(IMigratable) returns (address) {
        return _migrationTarget;
    }

    /// @inheritdoc IMigratable
    function proposeMigrationTarget(address migrationTarget) external override(IMigratable) onlyOwner {
        if (
            migrationTarget.code.length == 0 || migrationTarget == address(this)
                || _proposedMigrationTarget == migrationTarget || _migrationTarget == migrationTarget
                || !IERC165(migrationTarget).supportsInterface(IMigrationTarget.migrateFrom.selector)
        ) {
            revert InvalidMigrationTarget();
        }

        _migrationTarget = address(0);
        _proposedMigrationTarget = migrationTarget;
        _proposedMigrationTargetAt = block.timestamp;
        emit MigrationTargetProposed(migrationTarget);
    }

    /// @inheritdoc IMigratable
    function acceptMigrationTarget() external override(IMigratable) onlyOwner {
        if (_proposedMigrationTarget == address(0)) {
            revert InvalidMigrationTarget();
        }

        if (block.timestamp < (uint256(_proposedMigrationTargetAt) + 7 days)) {
            revert AccessForbidden();
        }

        _migrationTarget = _proposedMigrationTarget;
        _proposedMigrationTarget = address(0);
        emit MigrationTargetAccepted(_migrationTarget);
    }

    /// @inheritdoc IMigratable
    function migrate(bytes calldata data) external override(IMigratable) whenInactive {
        if (_migrationTarget == address(0)) revert InvalidMigrationTarget();

        (uint256 amount, uint256 baseReward, uint256 delegationReward) = _exit(msg.sender);

        _arpa.safeTransfer(_migrationTarget, uint256(amount + baseReward + delegationReward));

        // call migrate function
        IMigrationTarget(_migrationTarget).migrateFrom(
            uint256(amount + baseReward + delegationReward), abi.encode(msg.sender, data)
        );

        emit Migrated(msg.sender, amount, baseReward, delegationReward, data);
    }

    // ========
    // INodeStaking
    // ========

    /// @inheritdoc INodeStaking
    function lock(address staker, uint256 amount) external override(INodeStaking) onlyController {
        StakingPoolLib.Staker storage stakerAccount = _pool.stakers[staker];
        if (!stakerAccount.isOperator) {
            revert StakingPoolLib.OperatorDoesNotExist(staker);
        }
        if (stakerAccount.stakedAmount < amount) {
            revert StakingPoolLib.InsufficientStakeAmount(amount);
        }
        stakerAccount.lockedStakeAmount += amount._toUint96();
        emit Locked(staker, amount);
    }

    /// @inheritdoc INodeStaking
    function unlock(address staker, uint256 amount) external override(INodeStaking) onlyController {
        StakingPoolLib.Staker storage stakerAccount = _pool.stakers[staker];
        if (!stakerAccount.isOperator) {
            revert StakingPoolLib.OperatorDoesNotExist(staker);
        }
        if (stakerAccount.lockedStakeAmount < amount) {
            revert INodeStaking.InadequateOperatorLockedStakingAmount(stakerAccount.lockedStakeAmount);
        }
        stakerAccount.lockedStakeAmount -= amount._toUint96();
        emit Unlocked(staker, amount);
    }

    /// @inheritdoc INodeStaking
    function slashDelegationReward(address staker, uint256 amount) external override(INodeStaking) onlyController {
        StakingPoolLib.Staker memory stakerAccount = _pool.stakers[staker];
        if (!stakerAccount.isOperator) {
            revert StakingPoolLib.OperatorDoesNotExist(staker);
        }
        uint256 earnedRewards = _reward._getOperatorEarnedDelegatedRewards(
            staker, getTotalDelegatedAmount(), getTotalCommunityStakedAmount()
        );
        // max capped by earnings
        uint256 slashedRewards = Math.min(amount, earnedRewards);
        _reward.missed[staker].delegated += slashedRewards._toUint96();

        _arpa.safeTransfer(owner(), slashedRewards);

        emit DelegationRewardSlashed(staker, slashedRewards);
    }

    /// @inheritdoc INodeStaking
    function getLockedAmount(address staker) external view override(INodeStaking) returns (uint256) {
        return _pool.stakers[staker].lockedStakeAmount;
    }

    // ========
    // IStaking
    // ========

    /// @inheritdoc IStaking
    function stake(uint256 amount) external override(IStaking) whenNotPaused {
        if (amount < RewardLib.REWARD_PRECISION) {
            revert StakingPoolLib.InsufficientStakeAmount(RewardLib.REWARD_PRECISION);
        }

        // Round down input amount to avoid cumulative rounding errors.
        uint256 remainder = amount % RewardLib.REWARD_PRECISION;
        if (remainder > 0) {
            amount -= remainder;
        }

        if (_pool._isOperator(msg.sender)) {
            _stakeAsOperator(msg.sender, amount);
        } else {
            _stakeAsCommunityStaker(msg.sender, amount);
        }

        _arpa.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IStaking
    function unstake(uint256 amount) external override(IStaking) whenNotPaused {
        // Round down unstake amount to avoid cumulative rounding errors.
        uint256 remainder = amount % RewardLib.REWARD_PRECISION;
        if (remainder > 0) {
            amount -= remainder;
        }

        (uint256 baseReward, uint256 delegationReward) = _exit(msg.sender, amount, false);

        _arpa.safeTransfer(msg.sender, baseReward + delegationReward);

        emit Unstaked(msg.sender, amount, baseReward, delegationReward);
    }

    /// @inheritdoc IStaking
    function claim() external override(IStaking) whenNotPaused {
        claimReward();
        if (_pool.stakers[msg.sender].frozenPrincipals.length > 0) {
            claimFrozenPrincipal();
        }
    }

    /// @inheritdoc IStaking
    function claimReward() public override(IStaking) whenNotPaused {
        StakingPoolLib.Staker memory stakerAccount = _pool.stakers[msg.sender];
        if (stakerAccount.isOperator) {
            revert StakingPoolLib.NoBaseRewardForOperator();
        }

        uint256 accruedReward = _reward._calculateAccruedBaseRewards(
            RewardLib._getNonDelegatedAmount(stakerAccount.stakedAmount, _delegationRateDenominator),
            getTotalCommunityStakedAmount()
        );

        uint256 claimingReward = accruedReward - uint256(_reward.missed[msg.sender].base);

        _reward.missed[msg.sender].base = accruedReward._toUint96();

        _arpa.safeTransfer(msg.sender, claimingReward);

        emit RewardClaimed(msg.sender, claimingReward);
    }

    /// @inheritdoc IStaking
    function claimFrozenPrincipal() public override(IStaking) whenNotPaused {
        StakingPoolLib.FrozenPrincipal[] storage frozenPrincipals = _pool.stakers[msg.sender].frozenPrincipals;
        if (frozenPrincipals.length == 0) revert StakingPoolLib.FrozenPrincipalDoesNotExist(msg.sender);

        uint256 claimingPrincipal = 0;
        uint256 popCount = 0;
        for (uint256 i = 0; i < frozenPrincipals.length; i++) {
            StakingPoolLib.FrozenPrincipal storage frozenPrincipal = frozenPrincipals[i];
            if (frozenPrincipals[i].unlockTimestamp <= block.timestamp) {
                claimingPrincipal += frozenPrincipal.amount;
                _pool.totalFrozenAmount -= frozenPrincipal.amount;
                popCount++;
            } else {
                break;
            }
        }
        if (popCount > 0) {
            for (uint256 i = 0; i < frozenPrincipals.length - popCount; i++) {
                frozenPrincipals[i] = frozenPrincipals[i + popCount];
            }
            for (uint256 i = 0; i < popCount; i++) {
                frozenPrincipals.pop();
            }
        }

        if (claimingPrincipal > 0) {
            _arpa.safeTransfer(msg.sender, claimingPrincipal);
        }

        emit FrozenPrincipalClaimed(msg.sender, claimingPrincipal);
    }

    /// @inheritdoc IStaking
    function getStake(address staker) public view override(IStaking) returns (uint256) {
        return _pool.stakers[staker].stakedAmount;
    }

    /// @inheritdoc IStaking
    function isOperator(address staker) external view override(IStaking) returns (bool) {
        return _pool._isOperator(staker);
    }

    /// @inheritdoc IStaking
    function isActive() public view override(IStaking) returns (bool) {
        return _pool.state.isOpen && !_reward._isDepleted();
    }

    /// @inheritdoc IStaking
    function getMaxPoolSize() external view override(IStaking) returns (uint256) {
        return uint256(_pool.limits.maxPoolSize);
    }

    /// @inheritdoc IStaking
    function getCommunityStakerLimits() external view override(IStaking) returns (uint256, uint256) {
        return (_minCommunityStakeAmount, uint256(_pool.limits.maxCommunityStakeAmount));
    }

    /// @inheritdoc IStaking
    function getOperatorLimit() external view override(IStaking) returns (uint256) {
        return _operatorStakeAmount;
    }

    /// @inheritdoc IStaking
    function getRewardTimestamps() external view override(IStaking) returns (uint256, uint256) {
        return (uint256(_reward.startTimestamp), uint256(_reward.endTimestamp));
    }

    /// @inheritdoc IStaking
    function getRewardRate() external view override(IStaking) returns (uint256) {
        return uint256(_reward.rate);
    }

    /// @inheritdoc IStaking
    function getDelegationRateDenominator() external view override(IStaking) returns (uint256) {
        return _delegationRateDenominator;
    }

    /// @inheritdoc IStaking
    function getAvailableReward() public view override(IStaking) returns (uint256) {
        return _arpa.balanceOf(address(this)) - getTotalStakedAmount() - _pool.totalFrozenAmount;
    }

    /// @inheritdoc IStaking
    function getBaseReward(address staker) public view override(IStaking) returns (uint256) {
        uint256 stakedAmount = _pool.stakers[staker].stakedAmount;
        if (stakedAmount == 0) return 0;

        if (_pool._isOperator(staker)) {
            return 0;
        }

        return _reward._calculateAccruedBaseRewards(
            RewardLib._getNonDelegatedAmount(stakedAmount, _delegationRateDenominator), getTotalCommunityStakedAmount()
        ) - uint256(_reward.missed[staker].base);
    }

    /// @inheritdoc IStaking
    function getDelegationReward(address staker) public view override(IStaking) returns (uint256) {
        StakingPoolLib.Staker memory stakerAccount = _pool.stakers[staker];
        if (!stakerAccount.isOperator) return 0;
        if (stakerAccount.stakedAmount == 0) return 0;
        return _reward._getOperatorEarnedDelegatedRewards(
            staker, getTotalDelegatedAmount(), getTotalCommunityStakedAmount()
        );
    }

    /// @inheritdoc IStaking
    function getTotalDelegatedAmount() public view override(IStaking) returns (uint256) {
        return RewardLib._getDelegatedAmount(_pool.state.totalCommunityStakedAmount, _delegationRateDenominator);
    }

    /// @inheritdoc IStaking
    function getDelegatesCount() external view override(IStaking) returns (uint256) {
        return uint256(_reward.delegated.delegatesCount);
    }

    function getCommunityStakersCount() external view returns (uint256) {
        return uint256(_reward.base.communityStakersCount);
    }

    /// @inheritdoc IStaking
    function getTotalStakedAmount() public view override(IStaking) returns (uint256) {
        return _pool._getTotalStakedAmount();
    }

    /// @inheritdoc IStaking
    function getTotalCommunityStakedAmount() public view override(IStaking) returns (uint256) {
        return _pool.state.totalCommunityStakedAmount;
    }

    /// @inheritdoc IStaking
    function getTotalFrozenAmount() external view override(IStaking) returns (uint256) {
        return _pool.totalFrozenAmount;
    }

    /// @inheritdoc IStaking
    function getFrozenPrincipal(address staker)
        external
        view
        override(IStaking)
        returns (uint96[] memory amounts, uint256[] memory unlockTimestamps)
    {
        StakingPoolLib.FrozenPrincipal[] memory frozenPrincipals = _pool.stakers[staker].frozenPrincipals;
        amounts = new uint96[](frozenPrincipals.length);
        unlockTimestamps = new uint256[](frozenPrincipals.length);
        for (uint256 i = 0; i < frozenPrincipals.length; i++) {
            amounts[i] = frozenPrincipals[i].amount;
            unlockTimestamps[i] = frozenPrincipals[i].unlockTimestamp;
        }
    }

    /// @inheritdoc IStaking
    function getClaimablePrincipalAmount(address) external view returns (uint256 claimingPrincipal) {
        StakingPoolLib.FrozenPrincipal[] storage frozenPrincipals = _pool.stakers[msg.sender].frozenPrincipals;
        if (frozenPrincipals.length == 0) return 0;

        for (uint256 i = 0; i < frozenPrincipals.length; i++) {
            StakingPoolLib.FrozenPrincipal storage frozenPrincipal = frozenPrincipals[i];
            if (frozenPrincipals[i].unlockTimestamp <= block.timestamp) {
                claimingPrincipal += frozenPrincipal.amount;
            } else {
                break;
            }
        }
    }

    /// @inheritdoc IStaking
    function getArpaToken() public view override(IStaking) returns (address) {
        return address(_arpa);
    }

    /// @inheritdoc IStaking
    function getController() external view override(IStaking) returns (address) {
        return _controller;
    }

    // =======
    // Internal
    // =======

    /// @notice Helper function for when a community staker enters the pool
    /// @param staker The staker address
    /// @param amount The amount of principal staked
    function _stakeAsCommunityStaker(address staker, uint256 amount) internal whenActive {
        uint256 currentStakedAmount = _pool.stakers[staker].stakedAmount;
        uint256 newStakedAmount = currentStakedAmount + amount;
        // Check that the amount is greater than or equal to the minimum required
        if (newStakedAmount < _minCommunityStakeAmount) {
            revert StakingPoolLib.InsufficientStakeAmount(_minCommunityStakeAmount);
        }

        // Check that the amount is less than or equal to the maximum allowed
        uint256 maxCommunityStakeAmount = uint256(_pool.limits.maxCommunityStakeAmount);
        if (newStakedAmount > maxCommunityStakeAmount) {
            revert StakingPoolLib.ExcessiveStakeAmount(maxCommunityStakeAmount - currentStakedAmount);
        }

        // Check if the amount supplied increases the total staked amount above
        // the maximum pool size
        uint256 remainingPoolSpace = _pool._getRemainingPoolSpace();
        if (amount > remainingPoolSpace) {
            revert StakingPoolLib.ExcessiveStakeAmount(remainingPoolSpace);
        }

        _reward._accumulateBaseRewards(getTotalCommunityStakedAmount());
        _reward._accumulateDelegationRewards(getTotalDelegatedAmount(), getTotalCommunityStakedAmount());

        // On first stake
        if (currentStakedAmount == 0) {
            _reward.base.communityStakersCount += 1;
        }

        uint256 extraNonDelegatedAmount = RewardLib._getNonDelegatedAmount(amount, _delegationRateDenominator);
        _reward.missed[staker].base +=
            _reward._calculateAccruedBaseRewards(extraNonDelegatedAmount, getTotalCommunityStakedAmount())._toUint96();
        _pool.state.totalCommunityStakedAmount += amount._toUint96();
        _pool.stakers[staker].stakedAmount = newStakedAmount._toUint96();
        emit Staked(staker, amount, newStakedAmount);
    }

    /// @notice Helper function for when an operator enters the pool
    /// @param staker The staker address
    /// @param amount The amount of principal staked
    function _stakeAsOperator(address staker, uint256 amount) internal {
        StakingPoolLib.Staker storage operator = _pool.stakers[staker];
        uint256 currentStakedAmount = operator.stakedAmount;
        uint256 newStakedAmount = currentStakedAmount + amount;

        // Check that the amount is greater than or less than the required
        if (newStakedAmount < _operatorStakeAmount) {
            revert StakingPoolLib.InsufficientStakeAmount(_operatorStakeAmount);
        }
        if (newStakedAmount > _operatorStakeAmount) {
            revert StakingPoolLib.ExcessiveStakeAmount(newStakedAmount - _operatorStakeAmount);
        }

        // On first stake
        if (currentStakedAmount == 0) {
            _reward._accumulateDelegationRewards(getTotalDelegatedAmount(), getTotalCommunityStakedAmount());
            uint8 delegatesCount = _reward.delegated.delegatesCount;

            // Prior to the first operator staking, we reset the accumulated value
            // so it doesn't count towards missed rewards.
            if (delegatesCount == 0) {
                delete _reward.delegated.cumulativePerDelegate;
            }

            _reward.delegated.delegatesCount = delegatesCount + 1;

            _reward.missed[staker].delegated = _reward.delegated.cumulativePerDelegate;
        }

        _pool.state.totalOperatorStakedAmount += amount._toUint96();
        _pool.stakers[staker].stakedAmount = newStakedAmount._toUint96();
        emit Staked(staker, amount, newStakedAmount);
    }

    /// @notice Helper function when staker exits the pool
    /// @param staker The staker address
    function _exit(address staker) internal returns (uint256, uint256, uint256) {
        StakingPoolLib.Staker memory stakerAccount = _pool.stakers[staker];
        if (stakerAccount.stakedAmount == 0) {
            revert StakingPoolLib.StakeNotFound(staker);
        }
        if (stakerAccount.lockedStakeAmount > 0) {
            revert StakingPoolLib.ExistingLockedStakeFound(staker);
        }
        (uint256 baseReward, uint256 delegationReward) = _exit(staker, stakerAccount.stakedAmount, true);
        return (stakerAccount.stakedAmount, baseReward, delegationReward);
    }

    /// @notice Helper function when staker exits the pool
    /// @param staker The staker address
    function _exit(address staker, uint256 amount, bool isMigrate) internal returns (uint256, uint256) {
        StakingPoolLib.Staker memory stakerAccount = _pool.stakers[staker];
        if (amount == 0) {
            revert StakingPoolLib.UnstakeWithZeroAmount(staker);
        }
        if (stakerAccount.stakedAmount < amount) {
            revert StakingPoolLib.InadequateStakingAmount(stakerAccount.stakedAmount);
        }

        _reward._accumulateBaseRewards(getTotalCommunityStakedAmount());
        _reward._accumulateDelegationRewards(getTotalDelegatedAmount(), getTotalCommunityStakedAmount());

        if (stakerAccount.isOperator) {
            if (amount != _operatorStakeAmount) {
                revert StakingPoolLib.UnstakeOperatorWithPartialAmount(staker);
            }

            if (stakerAccount.lockedStakeAmount > 0) {
                revert StakingPoolLib.ExistingLockedStakeFound(staker);
            }

            uint256 delegationReward = _reward._getOperatorEarnedDelegatedRewards(
                staker, getTotalDelegatedAmount(), getTotalCommunityStakedAmount()
            );

            _pool.state.totalOperatorStakedAmount -= amount._toUint96();
            _pool.stakers[staker].stakedAmount -= amount._toUint96();

            if (!isMigrate) {
                _pool.totalFrozenAmount += amount._toUint96();
                _pool.stakers[staker].frozenPrincipals.push(
                    StakingPoolLib.FrozenPrincipal(amount._toUint96(), block.timestamp + _unstakeFreezingDuration)
                );
            }
            _reward.delegated.delegatesCount -= 1;

            _reward.missed[staker].delegated = _reward.delegated.cumulativePerDelegate;

            return (0, delegationReward);
        } else {
            uint256 baseReward = _reward._calculateAccruedBaseRewards(
                RewardLib._getNonDelegatedAmount(stakerAccount.stakedAmount, _delegationRateDenominator),
                getTotalCommunityStakedAmount()
            ) - uint256(_reward.missed[staker].base);

            _pool.state.totalCommunityStakedAmount -= amount._toUint96();
            _pool.stakers[staker].stakedAmount -= amount._toUint96();

            if (_pool.stakers[staker].stakedAmount == 0) {
                _reward.base.communityStakersCount -= 1;
            }

            if (!isMigrate) {
                _pool.totalFrozenAmount += amount._toUint96();
                _pool.stakers[staker].frozenPrincipals.push(
                    StakingPoolLib.FrozenPrincipal(amount._toUint96(), block.timestamp + _unstakeFreezingDuration)
                );
            }

            _reward.missed[staker].base = _reward._calculateAccruedBaseRewards(
                RewardLib._getNonDelegatedAmount(_pool.stakers[staker].stakedAmount, _delegationRateDenominator),
                getTotalCommunityStakedAmount()
            )._toUint96();

            return (baseReward, 0);
        }
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
    modifier onlyController() {
        if (msg.sender != _controller) revert SenderNotController();

        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract TypeAndVersionInterface {
    function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStaking {
    /// @notice This event is emitted when the controller is set.
    /// @param controller Controller address
    event ControllerSet(address controller);

    /// @notice This event is emitted when a staker adds stake to the pool.
    /// @param staker Staker address
    /// @param newStake New principal amount staked
    /// @param totalStake Total principal amount staked
    event Staked(address staker, uint256 newStake, uint256 totalStake);
    /// @notice This event is emitted when a staker exits the pool.
    /// @param staker Staker address
    /// @param principal Principal amount frozen after unstaking
    /// @param baseReward base reward earned
    /// @param delegationReward delegation reward earned, if any
    event Unstaked(address staker, uint256 principal, uint256 baseReward, uint256 delegationReward);

    /// @notice This event is emitted when a staker claims base reward.
    /// @param staker Staker address
    /// @param baseReward Base reward amount claimed
    event RewardClaimed(address staker, uint256 baseReward);

    /// @notice This event is emitted when a staker claims frozen principal.
    /// @param staker Staker address
    /// @param principal Principal amount claimed
    event FrozenPrincipalClaimed(address staker, uint256 principal);

    /// @notice This error is thrown whenever an address does not have access
    /// to successfully execute a transaction
    error AccessForbidden();

    /// @notice This error is thrown whenever a zero-address is supplied when
    /// a non-zero address is required
    error InvalidZeroAddress();

    /// @notice This error is thrown whenever the sender is not controller contract
    error SenderNotController();

    /// @notice This function allows stakers to stake.
    function stake(uint256 amount) external;

    /// @notice This function allows stakers to unstake.
    /// It returns base and delegation rewards, and makes principle frozen for later claiming.
    function unstake(uint256 amount) external;

    /// @notice This function allows community stakers to claim base rewards and frozen principals(if any).
    function claim() external;

    /// @notice This function allows stakers to claim base rewards.
    function claimReward() external;

    /// @notice This function allows stakers to claim frozen principals.
    function claimFrozenPrincipal() external;

    /// @return address ARPA token contract's address that is used by the pool
    function getArpaToken() external view returns (address);

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

    /// @return uint256 amount that should be staked by an operator
    function getOperatorLimit() external view returns (uint256);

    /// @return uint256 reward initialization timestamp
    /// @return uint256 reward expiry timestamp
    function getRewardTimestamps() external view returns (uint256, uint256);

    /// @return uint256 current reward rate, expressed in arpa weis per second
    function getRewardRate() external view returns (uint256);

    /// @return uint256 current delegation rate
    function getDelegationRateDenominator() external view returns (uint256);

    /// @return uint256 total amount of ARPA tokens made available for rewards in
    /// ARPA wei
    /// @dev This reflects how many rewards were made available over the
    /// lifetime of the staking pool.
    function getAvailableReward() external view returns (uint256);

    /// @return uint256 amount of base rewards earned by a staker in ARPA wei
    function getBaseReward(address) external view returns (uint256);

    /// @return uint256 amount of delegation rewards earned by an operator in ARPA wei
    function getDelegationReward(address) external view returns (uint256);

    /// @notice Total delegated amount is calculated by dividing the total
    /// community staker staked amount by the delegation rate, i.e.
    /// totalDelegatedAmount = pool.totalCommunityStakedAmount / delegationRateDenominator
    /// @return uint256 staked amount that is used when calculating delegation rewards in ARPA wei
    function getTotalDelegatedAmount() external view returns (uint256);

    /// @notice Delegates count increases after an operator is added to the list
    /// of operators and stakes the required amount.
    /// @return uint256 number of staking operators that are eligible for delegation rewards
    function getDelegatesCount() external view returns (uint256);

    /// @notice This count all community stakers that have a staking balance greater than 0.
    /// @return uint256 number of staking community stakers that are eligible for base rewards
    function getCommunityStakersCount() external view returns (uint256);

    /// @return uint256 total amount staked by community stakers and operators in ARPA wei
    function getTotalStakedAmount() external view returns (uint256);

    /// @return uint256 total amount staked by community stakers in ARPA wei
    function getTotalCommunityStakedAmount() external view returns (uint256);

    /// @return uint256 the sum of frozen operator principals that have not been
    /// withdrawn from the staking pool in ARPA wei.
    /// @dev Used to make sure that contract's balance is correct.
    /// total staked amount + total frozen amount + available rewards = current balance
    function getTotalFrozenAmount() external view returns (uint256);

    /// @return amounts total amounts of ARPA wei that is currently frozen by the staker
    /// @return unlockTimestamps timestamps when the frozen principal can be withdrawn
    function getFrozenPrincipal(address)
        external
        view
        returns (uint96[] memory amounts, uint256[] memory unlockTimestamps);

    /// @return uint256 amount of ARPA wei that can be claimed as frozen principal by a staker
    function getClaimablePrincipalAmount(address) external view returns (uint256);

    /// @return address controller contract's address that is used by the pool
    function getController() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @notice Owner functions restricted to the setup and maintenance
/// of the staking contract by the owner.
interface IStakingOwner {
    /// @notice This error is thrown when an zero delegation rate is supplied
    error InvalidDelegationRate();

    /// @notice This error is thrown when an invalid operator stake amount is
    /// supplied
    error InvalidOperatorStakeAmount();

    /// @notice This error is thrown when an invalid min community stake amount
    /// is supplied
    error InvalidMinCommunityStakeAmount();

    /// @notice This error is thrown when the reward is already initialized
    error AlreadyInitialized();

    /// @notice Adds one or more operators to a list of operators
    /// @dev Should only callable by the Owner
    /// @param operators A list of operator addresses to add
    function addOperators(address[] calldata operators) external;

    /// @notice This function can be called to add rewards to the pool when the reward is depleted
    /// @dev Should only callable by the Owner
    /// @param amount The amount of rewards to add to the pool
    /// @param rewardDuration The duration of the reward
    function newReward(uint256 amount, uint256 rewardDuration) external;

    /// @notice This function can be called to add rewards to the pool when the reward is not depleted
    /// @dev Should only be callable by the owner
    /// @param amount The amount of rewards to add to the pool
    /// @param rewardDuration The duration of the reward
    function addReward(uint256 amount, uint256 rewardDuration) external;

    /// @notice Set the pool config
    /// @param maxPoolSize The max amount of staked ARPA by community stakers allowed in the pool
    /// @param maxCommunityStakeAmount The max amount of ARPA a community staker can stake
    function setPoolConfig(uint256 maxPoolSize, uint256 maxCommunityStakeAmount) external;

    /// @notice Set controller contract address
    /// @dev Should only be callable by the owner
    /// @param controller The address of the controller contract
    function setController(address controller) external;

    /// @notice Transfers ARPA tokens and initializes the reward
    /// @dev Uses ERC20 approve + transferFrom flow
    /// @param amount rewards amount in ARPA
    /// @param rewardDuration rewards duration in seconds
    function start(uint256 amount, uint256 rewardDuration) external;

    /// @notice This function pauses staking
    /// @dev Sets the pause flag to true
    function emergencyPause() external;

    /// @notice This function unpauses staking
    /// @dev Sets the pause flag to false
    function emergencyUnpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INodeStaking {
    /// @notice This event is emitted when a node locks stake in the pool.
    /// @param staker Staker address
    /// @param newLock New principal amount locked
    event Locked(address staker, uint256 newLock);

    /// @notice This event is emitted when a node unlocks stake in the pool.
    /// @param staker Staker address
    /// @param newUnlock New principal amount unlocked
    event Unlocked(address staker, uint256 newUnlock);

    /// @notice This event is emitted when a node gets delegation reward slashed.
    /// @param staker Staker address
    /// @param amount Amount slashed
    event DelegationRewardSlashed(address staker, uint256 amount);

    /// @notice This error is raised when attempting to unlock with more than the current locked staking amount
    /// @param currentLockedStakingAmount Current locked staking amount
    error InadequateOperatorLockedStakingAmount(uint256 currentLockedStakingAmount);

    /// @notice This function allows controller to lock staking amount for a node.
    /// @param staker Node address
    /// @param amount Amount to lock
    function lock(address staker, uint256 amount) external;

    /// @notice This function allows controller to unlock staking amount for a node.
    /// @param staker Node address
    /// @param amount Amount to unlock
    function unlock(address staker, uint256 amount) external;

    /// @notice This function allows controller to slash delegation reward of a node.
    /// @param staker Node address
    /// @param amount Amount to slash
    function slashDelegationReward(address staker, uint256 amount) external;

    /// @notice This function returns the locked amount of a node.
    /// @param staker Node address
    function getLockedAmount(address staker) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
    event Migrated(address staker, uint256 principal, uint256 baseReward, uint256 delegationReward, bytes data);

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
pragma solidity ^0.8.18;

import {SafeCast} from "./SafeCast.sol";

library StakingPoolLib {
    using SafeCast for uint256;

    /// @notice This event is emitted when the staking pool is opened for stakers
    event PoolOpened();
    /// @notice This event is emitted when the staking pool's maximum size is
    /// increased
    /// @param maxPoolSize the new maximum pool size
    event PoolSizeIncreased(uint256 maxPoolSize);
    /// @notice This event is emitted when the maximum stake amount
    // for community stakers is increased
    /// @param maxStakeAmount the new maximum stake amount
    event MaxCommunityStakeAmountIncreased(uint256 maxStakeAmount);
    /// @notice This event is emitted when an operator is added
    /// @param operator address of the operator that was added to the staking pool
    event OperatorAdded(address operator);

    /// @notice Surfaces the required pool status to perform an operation
    /// (true if open / false if closed)
    /// @param currentStatus current status of the pool
    /// @param requiredStatus required status of the pool to proceed
    error InvalidPoolStatus(bool currentStatus, bool requiredStatus);
    /// @notice This error is raised when attempting to decrease maximum pool size.
    /// @param maxPoolSize the current maximum pool size
    error InvalidPoolSize(uint256 maxPoolSize);
    /// @notice This error is raised when attempting to decrease maximum stake amount
    /// for community stakers or node operators
    /// @param maxStakeAmount the current maximum stake amount
    error InvalidMaxStakeAmount(uint256 maxStakeAmount);
    /// @param requiredAmount minimum required stake amount
    error InsufficientStakeAmount(uint256 requiredAmount);
    /// @notice This error is raised when stakers attempt to stake past pool limits.
    /// @param remainingAmount maximum remaining amount that can be staked. This is
    /// the difference between the existing staked amount and the individual and global limits.
    error ExcessiveStakeAmount(uint256 remainingAmount);
    /// @notice This error is raised when stakers attempt to exit the pool.
    /// @param staker address of the staker who attempted to withdraw funds
    error StakeNotFound(address staker);
    /// @notice This error is raised when addresses with existing stake is added as an operator.
    /// @param staker address of the staker who is being added as an operator
    error ExistingStakeFound(address staker);
    /// @notice This error is raised when an address is duplicated in the supplied list of operators.
    /// This can happen in addOperators and setFeedOperators functions.
    /// @param operator address of the operator
    error OperatorAlreadyExists(address operator);
    /// @notice This error is raised when lock/unlock/slash is called on an operator that does not exist.
    /// @param operator address of the operator
    error OperatorDoesNotExist(address operator);
    /// @notice This error is raised when attempting to claim rewards by an operator.
    error NoBaseRewardForOperator();
    /// @notice This error is raised when attempting to start staking with less
    /// than the minimum required node operators
    /// @param currentOperatorsCount The current number of operators in the staking pool
    /// @param minInitialOperatorsCount The minimum required number of operators
    /// in the staking pool before opening
    error InadequateInitialOperatorsCount(uint256 currentOperatorsCount, uint256 minInitialOperatorsCount);
    /// @notice This error is raised when attempting to unstake with more than the current staking amount.
    error InadequateStakingAmount(uint256 currentStakingAmount);
    /// @notice This error is raised when attempting to claim frozen principal that does not exist.
    error FrozenPrincipalDoesNotExist(address staker);
    /// @notice This error is raised when attempting to unstake with zero amount.
    error UnstakeWithZeroAmount(address staker);
    /// @notice This error is raised when attempting to unstake with partial amount by an operator.
    error UnstakeOperatorWithPartialAmount(address operator);
    /// @notice This error is raised when attempting to unstake with existing locked staking amount.
    error ExistingLockedStakeFound(address operator);

    struct PoolLimits {
        // The max amount of staked ARPA by community stakers allowed in the pool
        uint96 maxPoolSize;
        // The max amount of ARPA a community staker can stake
        uint96 maxCommunityStakeAmount;
    }

    struct PoolState {
        // Flag that signals if the staking pool is open for staking
        bool isOpen;
        // Total number of operators added to the staking pool
        uint8 operatorsCount;
        // Total amount of ARPA staked by community stakers
        uint96 totalCommunityStakedAmount;
        // Total amount of ARPA staked by operators
        uint96 totalOperatorStakedAmount;
    }

    struct FrozenPrincipal {
        // Amount of ARPA frozen after unstaking
        uint96 amount;
        // Timestamp when the principal is unlocked
        uint256 unlockTimestamp;
    }

    struct Staker {
        // Flag that signals whether a staker is an operator
        bool isOperator;
        // Amount of ARPA staked by a staker
        uint96 stakedAmount;
        // Frozen principals of a staker
        FrozenPrincipal[] frozenPrincipals;
        // Locked staking amount of an operator
        uint96 lockedStakeAmount;
    }

    struct Pool {
        mapping(address => Staker) stakers;
        PoolState state;
        PoolLimits limits;
        // Sum of frozen principals that have not been withdrawn.
        // Used to make sure that contract's balance is correct.
        // total staked amount + total frozen amount + available rewards = current balance
        uint256 totalFrozenAmount;
    }

    /// @notice Sets staking pool parameters
    /// @param maxPoolSize Maximum total stake amount across all stakers
    /// @param maxCommunityStakeAmount Maximum stake amount for a single community staker
    function _setConfig(Pool storage pool, uint256 maxPoolSize, uint256 maxCommunityStakeAmount) internal {
        if (pool.limits.maxPoolSize > maxPoolSize) {
            revert InvalidPoolSize(maxPoolSize);
        }
        if (pool.limits.maxCommunityStakeAmount > maxCommunityStakeAmount) {
            revert InvalidMaxStakeAmount(maxCommunityStakeAmount);
        }

        if (pool.limits.maxPoolSize != maxPoolSize) {
            pool.limits.maxPoolSize = maxPoolSize._toUint96();
            emit PoolSizeIncreased(maxPoolSize);
        }
        if (pool.limits.maxCommunityStakeAmount != maxCommunityStakeAmount) {
            pool.limits.maxCommunityStakeAmount = maxCommunityStakeAmount._toUint96();
            emit MaxCommunityStakeAmountIncreased(maxCommunityStakeAmount);
        }
    }

    /// @notice Opens the staking pool
    function _open(Pool storage pool, uint256 minInitialOperatorCount) internal {
        if (uint256(pool.state.operatorsCount) < minInitialOperatorCount) {
            revert InadequateInitialOperatorsCount(pool.state.operatorsCount, minInitialOperatorCount);
        }
        pool.state.isOpen = true;
        emit PoolOpened();
    }

    /// @notice Returns true if a supplied staker address is in the operators list
    /// @param staker Address of a staker
    /// @return bool
    function _isOperator(Pool storage pool, address staker) internal view returns (bool) {
        return pool.stakers[staker].isOperator;
    }

    /// @notice Returns the sum of all principal staked in the pool
    /// @return totalStakedAmount
    function _getTotalStakedAmount(Pool storage pool) internal view returns (uint256) {
        StakingPoolLib.PoolState memory poolState = pool.state;
        return uint256(poolState.totalCommunityStakedAmount) + uint256(poolState.totalOperatorStakedAmount);
    }

    /// @notice Returns the amount of remaining space available in the pool for
    /// community stakers. Community stakers can only stake up to this amount
    /// even if they are within their individual limits.
    /// @return remainingPoolSpace
    function _getRemainingPoolSpace(Pool storage pool) internal view returns (uint256) {
        StakingPoolLib.PoolState memory poolState = pool.state;
        return uint256(pool.limits.maxPoolSize) - uint256(poolState.totalCommunityStakedAmount);
    }

    /// @dev Required conditions for adding operators:
    /// - Operators can only been added to the pool if they have no prior stake.
    /// - Operators cannot be added to the pool after staking ends.
    function _addOperators(Pool storage pool, address[] calldata operators) internal {
        for (uint256 i; i < operators.length; i++) {
            if (pool.stakers[operators[i]].isOperator) {
                revert OperatorAlreadyExists(operators[i]);
            }
            if (pool.stakers[operators[i]].stakedAmount > 0) {
                revert ExistingStakeFound(operators[i]);
            }
            pool.stakers[operators[i]].isOperator = true;
            emit OperatorAdded(operators[i]);
        }

        // Safely update operators count with respect to the maximum of 255 operators
        pool.state.operatorsCount = pool.state.operatorsCount + operators.length._toUint8();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SafeCast} from "./SafeCast.sol";
import {StakingPoolLib} from "./StakingPoolLib.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

library RewardLib {
    using SafeCast for uint256;

    /// @notice emitted when the reward is initialized for the first time
    /// @param available the amount of rewards available for distribution in the
    /// staking pool
    /// @param startTimestamp the start timestamp when rewards are started
    /// @param endTimestamp the timestamp when the reward will run out
    event RewardInitialized(uint256 available, uint256 startTimestamp, uint256 endTimestamp);
    /// @notice emitted when owner adds more rewards to the pool
    /// @param amountAdded the amount of ARPA rewards added to the pool
    /// @param endTimestamp the timestamp when the reward will run out
    event RewardAdded(uint256 amountAdded, uint256 endTimestamp);
    /// @notice emitted when owner withdraws leftover rewards
    /// @param amount the amount of rewards withdrawn
    event RewardWithdrawn(uint256 amount);
    /// @notice emitted when an  operator gets slashed.
    /// Node operators are not slashed more than the amount of rewards they
    /// have earned.
    event RewardSlashed(address[] operator, uint256[] slashedDelegatedRewards);

    /// @notice This error is thrown when the updated reward duration is too short
    error RewardDurationTooShort();

    /// @notice This is the reward calculation precision variable. ARPA token has the
    /// 1e18 multiplier which means that rewards are floored after 6 decimals
    /// points. Micro ARPA is the smallest unit that is eligible for rewards.
    uint256 internal constant REWARD_PRECISION = 1e12;

    struct DelegatedRewards {
        // Count of delegates who are eligible for a share of a reward
        uint8 delegatesCount;
        // Tracks base reward amounts that goes to an operator as delegation rewards.
        // Used to correctly account for any changes in operator count, delegated amount, or reward rate.
        uint96 cumulativePerDelegate;
        // Timestamp of the last time accumulate was called
        // `startTimestamp` <= `delegated.lastAccumulateTimestamp`
        uint32 lastAccumulateTimestamp;
    }

    struct BaseRewards {
        // Count of community stakers who are eligible for a share of a reward
        uint32 communityStakersCount;
        // The cumulative ARPA accrued per stake from past reward rates
        // expressed in ARPA wei per micro ARPA
        uint96 cumulativePerShare;
        // Timestamp of the last time the base reward rate was accumulated
        uint32 lastAccumulateTimestamp;
    }

    struct MissedRewards {
        // Tracks missed base rewards that are deducted from late stakers
        uint96 base;
        // Tracks missed delegation rewards that are deducted from late delegates
        uint96 delegated;
    }

    struct Reward {
        mapping(address => MissedRewards) missed;
        DelegatedRewards delegated;
        BaseRewards base;
        // Reward rate expressed in arpa weis per second
        uint80 rate;
        // Timestamp when the reward stops accumulating. Has to support a very long
        // duration for scenarios with low reward rate.
        // `endTimestamp` >= `startTimestamp`
        uint32 endTimestamp;
        // Timestamp when the reward comes into effect
        // `startTimestamp` <= `endTimestamp`
        uint32 startTimestamp;
    }

    /// @notice initializes the reward with the defined parameters
    /// @param minRewardDuration the minimum duration rewards need to last for
    /// @param newReward the amount of rewards to be added to the pool
    /// @param rewardDuration the duration for which the reward will be distributed
    function _initialize(Reward storage reward, uint256 minRewardDuration, uint256 newReward, uint256 rewardDuration)
        internal
    {
        uint32 blockTimestamp = block.timestamp._toUint32();
        reward.startTimestamp = blockTimestamp;

        reward.delegated.lastAccumulateTimestamp = blockTimestamp;
        reward.base.lastAccumulateTimestamp = blockTimestamp;

        _updateReward(reward, newReward, rewardDuration, minRewardDuration);

        emit RewardInitialized(newReward, reward.startTimestamp, reward.endTimestamp);
    }

    /// @return bool true if the reward is expired (end <= now)
    function _isDepleted(Reward storage reward) internal view returns (bool) {
        return reward.endTimestamp <= block.timestamp;
    }

    /// @notice Helper function to accumulate base rewards
    /// Accumulate reward per micro ARPA before changing reward rate.
    /// This keeps rewards prior to rate change unaffected.
    function _accumulateBaseRewards(Reward storage reward, uint256 totalStakedAmount) internal {
        reward.base.cumulativePerShare = _calculateCumulativeBaseRewards(reward, totalStakedAmount)._toUint96();
        reward.base.lastAccumulateTimestamp = _getCappedTimestamp(reward)._toUint32();
    }

    /// @notice Helper function to accumulate delegation rewards
    /// @dev This function is necessary to correctly account for any changes in
    /// eligible operators, delegated amount or reward rate.
    function _accumulateDelegationRewards(
        Reward storage reward,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal {
        reward.delegated.cumulativePerDelegate =
            _calculateCumulativeDelegatedRewards(reward, totalDelegatedAmount, totalStakedAmount)._toUint96();
        reward.delegated.lastAccumulateTimestamp = _getCappedTimestamp(reward)._toUint32();
    }

    function _calculateCumulativeBaseRewards(Reward storage reward, uint256 totalStakedAmount)
        internal
        view
        returns (uint256)
    {
        if (totalStakedAmount == 0) return reward.base.cumulativePerShare;
        uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
            ? (uint256(reward.endTimestamp) - uint256(reward.base.lastAccumulateTimestamp))
            : block.timestamp - uint256(reward.base.lastAccumulateTimestamp);

        return reward.base.cumulativePerShare
            + (uint256(reward.rate) * elapsedDurationSinceLastAccumulate * REWARD_PRECISION / totalStakedAmount)._toUint96();
    }

    function _calculateCumulativeDelegatedRewards(
        Reward storage reward,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal view returns (uint256) {
        if (totalStakedAmount == 0) return reward.delegated.cumulativePerDelegate;
        uint256 elapsedDurationSinceLastAccumulate = _isDepleted(reward)
            ? uint256(reward.endTimestamp) - uint256(reward.delegated.lastAccumulateTimestamp)
            : block.timestamp - uint256(reward.delegated.lastAccumulateTimestamp);

        return reward.delegated.cumulativePerDelegate
            + (
                uint256(reward.rate) * elapsedDurationSinceLastAccumulate * totalDelegatedAmount / totalStakedAmount
                    / Math.max(uint256(reward.delegated.delegatesCount), 1)
            )._toUint96();
    }

    /// @notice Calculates the amount of delegated rewards accumulated so far.
    /// @dev This function takes into account the amount of delegated
    /// rewards accumulated from previous delegate counts and amounts and
    /// the latest additional value.
    function _calculateAccruedDelegatedRewards(
        Reward storage reward,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal view returns (uint256) {
        return _calculateCumulativeDelegatedRewards(reward, totalDelegatedAmount, totalStakedAmount);
    }

    /// @notice Calculates the amount of rewards accrued so far.
    /// @dev This function takes into account the amount of
    /// rewards accumulated from previous rates in addition to
    /// the rewards that will be accumulated based off the current rate
    /// over a given duration.
    function _calculateAccruedBaseRewards(Reward storage reward, uint256 amount, uint256 totalStakedAmount)
        internal
        view
        returns (uint256)
    {
        return amount * _calculateCumulativeBaseRewards(reward, totalStakedAmount) / REWARD_PRECISION;
    }

    /// @notice calculates an amount that community stakers have to delegate to operators
    /// @param amount base staked amount to calculate delegated amount against
    /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
    function _getDelegatedAmount(uint256 amount, uint256 delegationRateDenominator) internal pure returns (uint256) {
        return amount / delegationRateDenominator;
    }

    /// @notice calculates the amount of stake that remains after accounting for delegation requirement
    /// @param amount base staked amount to calculate non-delegated amount against
    /// @param delegationRateDenominator Delegation rate used to calculate delegated stake amount
    function _getNonDelegatedAmount(uint256 amount, uint256 delegationRateDenominator)
        internal
        pure
        returns (uint256)
    {
        return amount - _getDelegatedAmount(amount, delegationRateDenominator);
    }

    /// @notice This function is called when the staking pool is initialized,
    /// rewards are added, TODO and an alert is raised
    /// @param newReward new reward amount
    /// @param rewardDuration duration of the reward
    function _updateReward(Reward storage reward, uint256 newReward, uint256 rewardDuration, uint256 minRewardDuration)
        internal
    {
        uint256 remainingRewards =
            (_isDepleted(reward) ? 0 : (reward.rate * (uint256(reward.endTimestamp) - block.timestamp))) + newReward;

        // Validate that the new reward duration is at least the min reward duration.
        // This is a safety mechanism to guard against operational mistakes.
        if (rewardDuration < minRewardDuration) {
            revert RewardDurationTooShort();
        }

        reward.endTimestamp = (block.timestamp + rewardDuration)._toUint32();
        reward.rate = (remainingRewards / rewardDuration)._toUint80();
    }

    /// @return The amount of delegated rewards an operator
    /// has earned.
    function _getOperatorEarnedDelegatedRewards(
        Reward storage reward,
        address operator,
        uint256 totalDelegatedAmount,
        uint256 totalStakedAmount
    ) internal view returns (uint256) {
        return _calculateAccruedDelegatedRewards(reward, totalDelegatedAmount, totalStakedAmount)
            - uint256(reward.missed[operator].delegated);
    }

    /// @return The current timestamp or, if the current timestamp has passed reward
    /// end timestamp, reward end timestamp.
    /// @dev This is necessary to ensure that rewards are calculated correctly
    /// after the reward is depleted.
    function _getCappedTimestamp(Reward storage reward) internal view returns (uint256) {
        return Math.min(uint256(reward.endTimestamp), block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IMigrationTarget {
    /// @notice This function allows stakers to migrate funds from an old staking pool.
    /// @param amount Amount of tokens to migrate
    /// @param data Migration path details
    function migrateFrom(uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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