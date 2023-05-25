// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./inheritables/tiers.sol";
import "./inheritables/checkpoints.sol";
import "./inheritables/penaltyPot.sol";

//                          &&&&&%%%%%%%%%%#########*
//                      &&&&&&&&%%%%%%%%%%##########(((((
//                   @&&&&&&&&&%%%%%%%%%##########((((((((((
//                @@&&&&&&&&&&%%%%%%%%%#########(((((((((((((((
//              @@@&&&&&&&&%%%%%%%%%%##########((((((((((((((///(
//            %@@&&&&&&               ######(                /////.
//           @@&&&&&&&&&           #######(((((((       ,///////////
//          @@&&&&&&&&%%%           ####((((((((((*   .//////////////
//         @@&&&&&&&%%%%%%          ##((((((((((((/  ////////////////*
//         &&&&&&&%%%%%%%%%          *(((((((((//// //////////////////
//         &&&&%%%%%%%%%####          .((((((/////,////////////////***
//        %%%%%%%%%%%########.          ((/////////////////***********
//         %%%%%##########((((/          /////////////****************
//         ##########((((((((((/          ///////*********************
//         #####((((((((((((/////          /*************************,
//          #(((((((((////////////          *************************
//           (((((//////////////***          ***********************
//            ,//////////***********        *************,*,,*,,**
//              ///******************      *,,,,,,,,,,,,,,,,,,,,,
//                ******************,,    ,,,,,,,,,,,,,,,,,,,,,
//                   ****,,*,,,,,,,,,,,  ,,,,,,,,,,,,,,,,,,,
//                      ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                          .,,,,,,,,,,,,,,,,,,,,,,,

/// @title Version 1 of Vinci staking pool
/// @notice A smart contract to handle staking of Vinci ERC20 token and grant Picasso club tiers and superstaker status
/// @dev The correct functioning of the contract having a positive funds for staking rewards
contract VinciStakingV1 is AccessControl, TierManager, Checkpoints, PenaltyPot {
    bytes32 public constant CONTRACT_OPERATOR_ROLE = keccak256("CONTRACT_OPERATOR_ROLE");
    bytes32 public constant CONTRACT_FUNDER_ROLE = keccak256("CONTRACT_FUNDER_ROLE");

    using SafeERC20 for IERC20;

    // balances
    uint256 public vinciStakingRewardsFunds;
    // Tokens that are staked and actively earning rewards
    mapping(address => uint256) public activeStaking;
    // Tokens that have been unstaked, but are not claimable yet (2 weeks delay)
    mapping(address => uint256) public currentlyUnstakingBalance;
    // Timestamp when the currentlyUnstakingBalance is available for claim
    mapping(address => uint256) public unstakingReleaseTime;
    // Total vinci rewards at the end of the current staking period of each user
    mapping(address => uint256) public fullPeriodAprRewards;
    // Airdropped tokens of each user. They are unclaimable until crossing the next period
    mapping(address => uint256) public airdroppedBalance;
    // Tokens that have been unlocked in previous checkpoints and are now claimable
    mapping(address => uint256) public claimableBalance;

    // constants
    uint256 public constant UNSTAKING_LOCK_TIME = 14 days;
    uint256 public constant BASE_APR = 550; // 5.5%
    uint256 public constant BASIS_POINTS = 10000;

    event Staked(address indexed user, uint256 amount);
    event UnstakingInitiated(address indexed user, uint256 amount);
    event UnstakingCompleted(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event AirdroppedBatch(address[] users, uint256[] amounts);
    event StakingRewardsFunded(address indexed funder, uint256 amount);
    event NonAllocatedStakingRewardsFundsRetrieved(address indexed funder, uint256 amount);
    event MissedRewardsPayout(address indexed user, uint256 entitledPayout, uint256 actualPayout);
    event MissedRewardsAllocation(address indexed user, uint256 entitledPayout, uint256 actualPayout);
    event StakingRewardsAllocated(address indexed user, uint256 amount);
    event StakeholderFinished(address indexed user);
    event Relocked(address indexed user);
    event CheckpointCrossed(address indexed user);
    event NotifyCannotCrossCheckpointYet(address indexed user);

    error NothingToClaim();
    error NothingToWithdraw();
    error InvalidAmount();
    error CannotCrossCheckpointYet();
    error NonExistingStaker();
    error UnstakedAmountNotReleasedYet();
    error NotEnoughStakingBalance();
    error ArrayTooLong();
    error CantRelockBeforeCrossingCheckpoint();
    error CheckpointHasToBeCrossedFirst();

    // Aggregation of all VINCI staked in the contract by all stakers
    uint256 public totalVinciStaked;

    /// ERC20 vinci token
    IERC20 public immutable vinciToken;

    constructor(ERC20 _vinciTokenAddress, uint128[] memory _tierThresholdsInVinci)
        TierManager(_tierThresholdsInVinci)
    {
        vinciToken = IERC20(_vinciTokenAddress);

        // note that the deployer of the contract is automatically granted the DEFAULT_ADMIN_ROLE but not CONTRACT_FUNDER_ROLE
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTRACT_OPERATOR_ROLE, msg.sender);
    }

    /// ================== User functions =============================

    /// @dev Stake VINCI tokens to the contract
    function stake(uint256 amount) external {
        _stake(msg.sender, amount);
    }

    /// @dev Contract operator can stake tokens on behalf of users
    function batchStakeTo(address[] calldata users, uint256[] calldata amounts)
        external
        onlyRole(CONTRACT_OPERATOR_ROLE)
    {
        require(users.length == amounts.length, "Input lengths must match");
        // This is gas inefficient, as the ERC20 transaction takes place for every stake, instead of grouping the
        // total amount and making a single transfer. However, this function is meant to be used only once at the
        // beginning and the saved gas  doesn't compensate the added contract complexity
        for (uint256 i = 0; i < amounts.length; i++) {
            _stake(users[i], amounts[i]);
        }
    }

    /// @dev Unstake VINCI tokens from the contract
    function unstake(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        // unstaking has a high cost in this echosystem:
        // - loosing already earned staking rewards,
        // - being downgraded in tier
        // - a lockup of 2 weeks before the unstake can be completed
        // - potentially losing your staking streak if too much is unstaked
        address sender = msg.sender;
        // when unstaking, a percentage of the rewards, proportional to the current stake will be withdrawn as a penalty
        // from all the difference rewards sources: baseAPR, airdrops, penaltyPot.
        // This penalty is distributed to the penalty pot
        uint256 stakedBefore = activeStaking[sender];
        if (amount > stakedBefore) revert NotEnoughStakingBalance();
        // force users to cross checkpoint if timestamp allows it to avoid undesired contract states
        uint256 _checkpoint = checkpoint[sender];
        if (block.timestamp > _checkpoint) revert CheckpointHasToBeCrossedFirst();
        uint256 _userFullPeriodRewards = fullPeriodAprRewards[sender];
        // These rewards are rounded up due to BASIS_POINTS. Rounding issues may arise from there
        uint256 earnedRewards =
            _getCurrentUnclaimableRewardsFromBaseAPR(stakedBefore, _checkpoint, _userFullPeriodRewards);
        // the ratio between the penalization to the fullperiod and the penalization to the earned rewards is the same
        // the earned rewards (_getCurrentUnclaimableRewardsFromBaseAPR()) is calculated using the full period
        // as a baseline. Therefore, updating the fullperiod rewards is enough to also update the earned rewards
        uint256 fullPeriodRewardsReduction = _userFullPeriodRewards * amount / stakedBefore;
        uint256 penaltyToEarnedRewards = earnedRewards * amount / stakedBefore;
        // This always holds: fullPeriodRewardsReduction >= penaltyToEarnedRewards
        uint256 toRewardsFund = fullPeriodRewardsReduction - penaltyToEarnedRewards;
        // fullPeriodRewardsReduction will always be lower than fullPeriodAprRewards[sender] because it is taken as a ratio
        fullPeriodAprRewards[sender] -= fullPeriodRewardsReduction;
        // of the penalizatoin to the fullPeriodAprRewards, the part corresponding to the earned rewards goes to the
        // penaltyPot, while the rest goes back to the rewards fund
        vinciStakingRewardsFunds += toRewardsFund;

        uint256 penaltyToAirdrops = airdroppedBalance[sender] * amount / stakedBefore;
        airdroppedBalance[sender] -= penaltyToAirdrops;

        uint256 penaltyToPenaltyPot = _penalizePenaltyPotShare(sender, amount, stakedBefore);

        uint256 totalPenalization = penaltyToEarnedRewards + penaltyToAirdrops + penaltyToPenaltyPot;

        if (_isSuperstaker(sender)) {
            // we only reduce the amount eligible for penaltyPotRewards if already a superstaker
            // no need to _bufferPenaltyPot here, as it is already done by _penalizePenaltyPotShare() above
            _removeFromEligibleSupplyForPenaltyPot(amount);
        }

        // It is OK that the penalized user also gets back a small fraction of its own penalty.
        // the fraction might not be so small if the staker is large ...
        _depositToPenaltyPot(totalPenalization);

        // modify these ones only after the modifications to penalty pot
        totalVinciStaked -= amount;
        activeStaking[sender] -= amount;
        currentlyUnstakingBalance[sender] += amount;
        unstakingReleaseTime[sender] = block.timestamp + UNSTAKING_LOCK_TIME;

        // in case of unstaking all the amount, the user looses tier, checkpoint history etc
        if (amount == stakedBefore) {
            // finished stakeholders can still claim pending claims or pending unstaking tokens
            _setTier(sender, 0);
            // deleting the checkpointMultiplierReduction will also remove the superstaker status
            _resetCheckpointInfo(sender);
            emit StakeholderFinished(sender);
        } else {
            uint256 currentTier = userTier[sender];
            // if current tier is 0, there is no need to update anything as it can only be downgraded
            if ((currentTier > 0) && (thresholds[currentTier - 1] > stakedBefore - amount)) {
                _setTier(sender, _calculateTier(stakedBefore - amount));
            }
        }
        emit UnstakingInitiated(sender, amount);
    }

    /// @notice Function to claim rewards in the claimable balance
    function claim() external {
        // finished stakeholders should also be able to claim their tokens also after being finished as stakeholders
        address sender = msg.sender;

        uint256 amount = claimableBalance[sender];
        if (amount == 0) revert NothingToClaim();

        delete claimableBalance[sender];
        emit Claimed(sender, amount);
        _sendVinci(sender, amount);
    }

    /// @notice Function to withdraw unstaked tokens, only after the lockup period has passed
    function withdraw() external {
        // finished stakeholders should also be able to withdraw their tokens also after being finished as stakeholders
        address sender = msg.sender;

        if (block.timestamp < unstakingReleaseTime[sender]) revert UnstakedAmountNotReleasedYet();

        uint256 amount = currentlyUnstakingBalance[sender];
        if (amount == 0) revert NothingToWithdraw();

        // delele storage variables to get gas refund
        delete currentlyUnstakingBalance[sender];
        delete unstakingReleaseTime[sender];
        emit UnstakingCompleted(sender, amount);
        _sendVinci(sender, amount);
    }

    /// @notice Function to relock the stake, which will reevaluate tier and postpone the checkpoint by the same amount
    ///         of months as the current period
    function relock() external {
        address sender = msg.sender;
        if (!_existingUser(sender)) revert NonExistingStaker();
        if (_canCrossCheckpoint(sender)) revert CantRelockBeforeCrossingCheckpoint();

        uint256 staked = activeStaking[sender];
        uint256 previousNextCheckpoint = checkpoint[sender];

        _setTier(sender, _calculateTier(staked));
        uint newCheckpoint = _postponeCheckpointFromCurrentTimestamp(sender);

        // extend the baseAprBalanceNextCP with the length from current next checkpoint until new next checkpoint
        // if checkpoing[sender] < previousNextCheckpoint, tx would revert above due to _canCrossCheckpoint() = true
        uint256 extraRewards = _estimatePeriodRewards(staked, newCheckpoint - previousNextCheckpoint);
        uint256 currentFunds = vinciStakingRewardsFunds;
        if (extraRewards > currentFunds) {
            emit MissedRewardsAllocation(sender, extraRewards, currentFunds);
            extraRewards = currentFunds;
        }
        if (extraRewards > 0) {
            fullPeriodAprRewards[sender] += extraRewards;
            vinciStakingRewardsFunds -= extraRewards;
        }

        emit Relocked(sender);
    }

    /// @notice Allows a user to cross the checkpoint, and turn all the unvested rewards into claimable rewards
    function crossCheckpoint() external {
        if (!_canCrossCheckpoint(msg.sender)) revert CannotCrossCheckpointYet();
        _crossCheckpoint(msg.sender);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// Contract Management Functions

    function distributePenaltyPot() external onlyRole(CONTRACT_OPERATOR_ROLE) {
        _distributePenaltyPot();
    }

    /// @notice Allows the contract operator to cross the checkpoint in behalf of a user
    function crossCheckpointTo(address[] calldata to) external onlyRole(CONTRACT_OPERATOR_ROLE) {
        if (to.length > 250) revert ArrayTooLong();
        // here we don't revert if one of them cannot cross, we simply skip it but throw an event
        for (uint256 i = 0; i < to.length; i++) {
            if (_canCrossCheckpoint(to[i])) {
                _crossCheckpoint(to[i]);
            } else {
                emit NotifyCannotCrossCheckpointYet(to[i]);
            }
        }
    }

    /// @notice Allows airdropping vinci to multiple current stakers. IMPORTANT: if any address is not a current
    ///         staker, the whole transaction will revert. All addresses must have an active staking at the time of the
    ///         airdrop.
    function batchAirdrop(address[] calldata users, uint256[] calldata amount)
        external
        onlyRole(CONTRACT_OPERATOR_ROLE)
    {
        if (users.length != amount.length) revert("Lengths must match");
        uint256 n = users.length;

        uint256 total;
        for (uint256 i = 0; i < n; i++) {
            require(_existingUser(users[i]), "Users must have active stake to receive airdrops");
            airdroppedBalance[users[i]] += amount[i];
            total += amount[i];
        }

        emit AirdroppedBatch(users, amount);
        _receiveVinci(total);
    }

    // only the vinci team can fund the staking rewards, because they can retrieve it later
    function fundContractWithVinciForRewards(uint256 amount) external onlyRole(CONTRACT_FUNDER_ROLE) {
        if (amount == 0) revert InvalidAmount();
        vinciStakingRewardsFunds += amount;
        emit StakingRewardsFunded(msg.sender, amount);
        _receiveVinci(amount);
    }

    function removeNonAllocatedStakingRewards(uint256 amount) external onlyRole(CONTRACT_FUNDER_ROLE) {
        vinciStakingRewardsFunds -= amount;
        emit NonAllocatedStakingRewardsFundsRetrieved(msg.sender, amount);
        _sendVinci(msg.sender, amount);
    }

    //

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// View functions

    /// @notice All unvested rewards that are not claimable yet. They can come from 3 different sources:
    ///         - airdoprs,
    ///         - corresponding share of the penaltyPot
    ///         - basic staking rewards (5.5% APR on the user's staking balance)
    function getTotalUnclaimableBalance(address user) public view returns (uint256) {
        uint256 stakingbalance = activeStaking[user];
        return airdroppedBalance[user] + _getAllocatedSharePenaltyPot(user, stakingbalance)
            + _getCurrentUnclaimableRewardsFromBaseAPR(stakingbalance, checkpoint[user], fullPeriodAprRewards[user]);
    }

    /// @notice Part of the unvested rewards that come from airdrops
    function getUnclaimableFromAirdrops(address user) external view returns (uint256) {
        return airdroppedBalance[user];
    }

    /// @notice Part of the unvested rewards that come from the basic staking rewards (5.5% on the staking balance)
    function getUnclaimableFromBaseApr(address user) external view returns (uint256) {
        return
            _getCurrentUnclaimableRewardsFromBaseAPR(activeStaking[user], checkpoint[user], fullPeriodAprRewards[user]);
    }

    /// @notice Part of the unvested rewards that are the user's share of the current penalty pot
    ///         This unclaimable does not account for the buffered decimals. These are 'postponed' until next distribution
    function getUnclaimableFromPenaltyPot(address user) external view returns (uint256) {
        return _getAllocatedSharePenaltyPot(user, activeStaking[user]);
    }

    /// @notice Estimates the unvested rewards comming from the penalty pot, including the tokens from the pot that
    ///         have not been distributed yet
    function estimatedShareOfPenaltyPot(address user) external view returns (uint256) {
        return _estimateUserShareOfPenaltyPot(user, activeStaking[user]);
    }

    /// @notice Returns the current supply eligible for penalty pot rewards
    function getSupplyEligibleForPenaltyPot() external view returns (uint256) {
        return _getSupplyEligibleForAllocation();
    }

    /// @notice When a user unstakes, those tokens are locked for 15 days, not earning rewards. Once the lockup period
    ///         ends, these toknes are available for withdraw. This function returns the amount of tokens available
    ///         for withdraw.
    function getUnstakeAmountAvailableForWithdrawal(address user) external view returns (uint256) {
        return (unstakingReleaseTime[user] > block.timestamp) ? 0 : currentlyUnstakingBalance[user];
    }

    /// @notice When a user unstakes, a penalization is imposed on the three different sources of unvested rewards.
    ///         This function returns what would be the potential loss (aggregation of the three sources)
    ///         This will help being transparent with the user and let them know how much they will lose if they
    ///         actually unstake
    function estimateRewardsLossIfUnstaking(address user, uint256 unstakeAmount) external view returns (uint256) {
        return getTotalUnclaimableBalance(user) * unstakeAmount / activeStaking[user];
    }

    /// @notice Total VINCI collected in the penalty pot from penalizations to unstakers
    function penaltyPot() external view returns (uint256) {
        return _getTotalPenaltyPot();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice Timestamp of the next checkpoint for the user
    function nextCheckpointTimestamp(address user) external view returns (uint256) {
        return checkpoint[user];
    }

    /// @notice Duration in months of the current checkpoint period (it reduces every time a checkpoint is crossed)
    function currentCheckpointDurationInMonths(address user) external view returns (uint256) {
        return _checkpointMultiplier(user);
    }

    /// @notice Returns if the checkpoint information of `user` is up-to-date
    ///         If the user does not exist, it also returns true, as there is no info to be updated
    function canCrossCheckpoint(address user) external view returns (bool) {
        return _canCrossCheckpoint(user);
    }

    /// @notice Returns True if the user has earned the status of SuperStaker. This is gained once the user has
    ///         crossed at least one checkpoint with non-zero staking. The SuperStaker status is lost when all the
    ///          balance is unstaked
    function isSuperstaker(address user) external view returns (bool) {
        return _isSuperstaker(user);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice Returns the minimum amount of VINCI to enter in `tier`
    function getTierThreshold(uint256 tier) external view returns (uint256) {
        return _tierThreshold(tier);
    }

    /// @notice Returns the number of current tiers
    function getNumberOfTiers() external view returns (uint256) {
        return _numberOfTiers();
    }

    /// @notice Returns the potential tier for a given `balance` of VINCI tokens if evaluated now
    function calculateTier(uint256 vinciBalance) external view returns (uint256) {
        return _calculateTier(vinciBalance);
    }

    /// @notice Updates the thresholds to access each tier
    function updateTierThresholds(uint128[] memory tierThresholds) external onlyRole(CONTRACT_OPERATOR_ROLE) {
        _updateTierThresholds(tierThresholds);
    }

    function getUserTier(address user) external view returns (uint256) {
        return _getUserTier(user);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// INTERNAL FUNCTIONS

    function _stake(address user, uint256 amount) internal {
        if (amount == 0) revert InvalidAmount();

        uint256 stakingBalance = activeStaking[user];

        if (stakingBalance == 0) {
            // initiate stakers that have never staked before (or they unstaked everything)
            _initCheckpoint(user);
            _setTier(user, _calculateTier(amount));
        } else if (_canCrossCheckpoint(user)) {
            revert CheckpointHasToBeCrossedFirst();
        } else if (_isSuperstaker(user)) {
            // no need to track the supplyEligibleForPenaltyPot specific of a user, because that is exactly the activeStaking
            // We only need to buffer any penalty pot earned so far, before changing the activeStaking
            _bufferPenaltyPotAllocation(user, stakingBalance);
            // This addition is not specific for the user, but for the entire penalty pot supply
            _addToEligibleSupplyForPenaltyPot(amount);
        }

        // we save the rewards for the entire period since now until next checkpoint here because they will only be
        // unlocked in the next checkpoint anyways
        uint256 rewards = _estimatePeriodRewards(amount, checkpoint[user] - block.timestamp);
        uint256 availableFunds = vinciStakingRewardsFunds;
        if (rewards > availableFunds) {
            // only one reading from storage to save gas
            emit MissedRewardsAllocation(user, rewards, availableFunds);
            rewards = availableFunds;
        } else {
            emit StakingRewardsAllocated(user, rewards);
        }

        activeStaking[user] += amount;
        totalVinciStaked += amount;
        fullPeriodAprRewards[user] += rewards;
        vinciStakingRewardsFunds -= rewards;

        emit Staked(user, amount);
        _receiveVinci(amount);
    }

    // @dev The callers of this function need to make sure that the checkpoint can be crossed
    function _crossCheckpoint(address user) internal {
        uint256 activeStake = activeStaking[user];
        uint256 penaltyPotShare = _isSuperstaker(user) ? _redeemPenaltyPot(user, activeStake) : 0;
        uint256 _rewardsFunds = vinciStakingRewardsFunds;

        uint256 claimableAddition = fullPeriodAprRewards[user] + airdroppedBalance[user] + penaltyPotShare;

        delete airdroppedBalance[user];

        // user will automatically become superStaker after the call to _postponeCheckpoint()
        if (!_isSuperstaker(user)) {
            _bufferPenaltyPotAllocation(user, 0);
            _addToEligibleSupplyForPenaltyPot(activeStake);
        }

        // we store newCheckpoint in memory to avoid reading it in the rest of this function (to save gas)
        (uint256 missedPeriod, uint256 currentPeriodStartTime, uint256 newCheckpoint) = _postponeCheckpoint(user);

        if (missedPeriod > 0) {
            // if the user missed a checkpoint, we need to allocate the rewards for the missed period
            // however, we need to update the rewardsPeriodStartTime to not double count the rewards
            uint256 missedRewards = _estimatePeriodRewards(activeStake, missedPeriod);
            // no need to be gas efficient here as this will happen very rarely
            if (missedRewards > _rewardsFunds) {
                // this is a missed PAYOUT because it goes directly into claimable
                emit MissedRewardsPayout(user, missedRewards, _rewardsFunds);
                missedRewards = _rewardsFunds;
            }

            // these missed rewards would go straight into claimable, as they come from old uncrossed checkpoints
            claimableAddition += missedRewards;
            _rewardsFunds -= missedRewards;
        }

        // only update storage variable if gt 0 to save gas
        if (claimableAddition > 0) {
            claimableBalance[user] += claimableAddition;
        }

        // set the rewards that will be accrued during the next period. Do this only after postponing checkpoint
        uint256 rewards = _estimatePeriodRewards(activeStake, newCheckpoint - currentPeriodStartTime);
        if (rewards > _rewardsFunds) {
            emit MissedRewardsAllocation(user, rewards, _rewardsFunds);
            rewards = _rewardsFunds;
        }
        // when there are no funds in the contract, the rewards allocated are smaller, and that means that the rewards
        // will be smaller over the entier period
        fullPeriodAprRewards[user] = rewards;
        _rewardsFunds -= rewards;

        // only update storage variable at the end with the new value after all modifications
        vinciStakingRewardsFunds = _rewardsFunds;

        // Evaluate new tier every time the checkpoint is crossed
        _setTier(user, _calculateTier(activeStake));
        emit CheckpointCrossed(user);
    }

    function _receiveVinci(uint256 amount) internal {
        vinciToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function _sendVinci(address to, uint256 amount) internal {
        vinciToken.safeTransfer(to, amount);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    /// Internal view/pure functions

    function _estimatePeriodRewards(uint256 amount, uint256 duration) internal pure returns (uint256) {
        // This should never ever happen, but we put this to avoid underflows
        return amount * BASE_APR * duration / (BASIS_POINTS * 365 days);
    }

    /// A user checkpoint=0 until the user is registered and it is set back to zero when is _finalized
    function _existingUser(address _user) internal view returns (bool) {
        return (checkpoint[_user] > 0) && (_user != address(0));
    }

    function _getCurrentUnclaimableRewardsFromBaseAPR(
        uint256 stakingBalance,
        uint256 _checkpoint,
        uint256 _userFullPeriodRewards
    ) internal view returns (uint256) {
        // This is tricky as the rewards schedule can change with stakes and unstakes from users. However:
        // we know the final rewards because that is the `baseAprBalance` and we know how much time until the next checkpoint
        // Therefore, the rewards earned so far are the total minus the ones not earned yet, that will be earned from
        // now until the next checkpoint
        if (stakingBalance == 0) return 0;
        // if checkpoint can be crossed already, the total APR is the one accumulated in the full period
        if (_checkpoint <= block.timestamp) return _userFullPeriodRewards;
        // block.timestamp is always < checkpoint[user] because otherwise it could cross checkpoint
        uint256 futureRewards = _estimatePeriodRewards(stakingBalance, _checkpoint - block.timestamp);
        // this subtraction can underflow due to rounding issues in _estimatePeriodRewards()
        return futureRewards > _userFullPeriodRewards ? 0 : _userFullPeriodRewards - futureRewards;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/AccessControl.sol";

error NonExistingTier();
error TooManyTiers();

contract TierManager is AccessControl {
    uint256 public constant MAX_NUMBER_OF_TIERS = 10;

    /// User tier which is granted according to the tier thresholds in vinci.
    /// Tiers are re-evaluated in certain occasions (unstake, relock, crossing a checkpoint)
    mapping(address => uint256) public userTier;

    // uint128 should be more than enough for the highest tier threshold at the lowest price possible
    uint128[] thresholds;

    event TiersThresholdsUpdated(uint128[] vinciThresholds);
    event TierSet(address indexed user, uint256 newTier);

    error NoTiersSet();

    constructor(uint128[] memory _tierThresholdsInVinci) {
        _updateTierThresholds(_tierThresholdsInVinci);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // View functions

    /// @notice Returns the minimum amount of VINCI to enter in `tier`
    function _tierThreshold(uint256 tier) internal view returns (uint256) {
        if (tier == 0) return 0;
        if (tier > thresholds.length) revert NonExistingTier();
        return thresholds[tier - 1];
    }

    /// @notice Returns the number of current tiers
    function _numberOfTiers() internal view returns (uint256) {
        return thresholds.length;
    }

    /// @notice Returns the potential tier for a given `balance` of VINCI tokens if evaluated now
    function _calculateTier(uint256 vinciAmount) internal view returns (uint256 _tier) {
        if (thresholds.length == 0) revert NoTiersSet();
        if (vinciAmount == 0) return 0;

        uint256 numberOfTiers = thresholds.length;
        uint256 tier = 0;
        for (uint256 i = 0; i < numberOfTiers + 1; i++) {
            if (tier == numberOfTiers) break;
            if (vinciAmount < thresholds[i]) break;
            tier += 1;
        }
        return tier;
    }

    /// @notice Returns the current tier for a given user. It manages the edge case in which a user has the top tier,
    ///         and later the number of tiers is reduced. In this case the user should get the top tier. However, if
    ///         the number of tiers is increased again, it should get back the old tier
    function _getUserTier(address _user) internal view returns (uint256) {
        uint256 _tier = userTier[_user];
        uint256 nTiers = _numberOfTiers();
        return _tier > nTiers ? nTiers : _tier;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Management functions

    /// @notice Allows to update the tier threholds in VINCI
    /// @dev    The contract owner will have execute this periodically to mimic the vinci price in usd for thresholds
    function _updateTierThresholds(uint128[] memory _tierThresholdsInVinci) internal {
        if (_tierThresholdsInVinci.length > MAX_NUMBER_OF_TIERS) revert TooManyTiers();
        require(_tierThresholdsInVinci.length > 0, "input at least one threshold");
        thresholds = _tierThresholdsInVinci;
        emit TiersThresholdsUpdated(_tierThresholdsInVinci);
    }

    // @dev Sets the tier for a given user
    function _setTier(address _user, uint256 _newTier) internal {
        userTier[_user] = _newTier;
        emit TierSet(_user, _newTier);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Checkpoints {
    /// user timestamp when next checkpoint can be crossed
    mapping(address => uint256) internal checkpoint;
    /// checkpoints are postponed in multiples of 30 days. The checkpointReduction is how many blocks of 30 days the current checkpoint has been reduced from the BASE_CHECKPOINT_MULTIPLIER.
    mapping(address => uint256) internal checkpointMultiplierReduction; // Initialized at 0, increasing up to 5

    /// the checkpoint multiplier is reduced by 1 block every time a user crosses a checkpoint. The starting multiplier is this
    uint256 internal constant BASE_CHECKPOINT_MULTIPLIER = 6;
    uint256 internal constant BASE_CHECKPOINT_DURATION = 30 days;

    event CheckpointSet(address indexed user, uint256 newCheckpoint);

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // Internal functions (inheritable by VinciStaking)

    function _checkpointMultiplier(address user) internal view returns (uint256) {
        return BASE_CHECKPOINT_MULTIPLIER - checkpointMultiplierReduction[user];
    }

    /// @dev    This function will update as many checkpoints as crossed
    ///         It will return the length of the missed period, the start of this checkpoint-period and the next checkpoint
    function _postponeCheckpoint(address user) internal returns (uint256, uint256, uint256) {
        bool reductorNeedsUpdate = false;
        uint256 missedPeriod;
        uint256 checkpointPeriodStart;
        uint256 nextCheckpoint = checkpoint[user];

        // store these in memory for gas savings
        uint256 _reduction = checkpointMultiplierReduction[user];
        while (nextCheckpoint < block.timestamp) {
            // the checkpoint multiplier cannot be less than 1, so the reduction cannot be more than (BASE_CHECKPOINT_MULTIPLIER - 1)
            if (_reduction + 1 < BASE_CHECKPOINT_MULTIPLIER) {
                _reduction += 1;
                reductorNeedsUpdate = true;
            }
            // addition to the current checkpoint to ignore the delay from the time when it is possible and the moment when crossing is actually executed
            uint256 timeAddition = (BASE_CHECKPOINT_MULTIPLIER - _reduction) * BASE_CHECKPOINT_DURATION;
            nextCheckpoint += timeAddition;
            // if a user misses multiple periods, we need to compensate the APR lost from those periods
            if (nextCheckpoint < block.timestamp) {
                missedPeriod += timeAddition;
            }
        }
        // we only need to overwrite checkpointMultiplierReduction if it has actually changed
        if (reductorNeedsUpdate) {
            checkpointMultiplierReduction[user] = _reduction;
        }
        checkpoint[user] = nextCheckpoint;
        checkpointPeriodStart = nextCheckpoint - (BASE_CHECKPOINT_MULTIPLIER - _reduction) * BASE_CHECKPOINT_DURATION;

        emit CheckpointSet(user, nextCheckpoint);
        return (missedPeriod, checkpointPeriodStart, nextCheckpoint);
    }

    function _postponeCheckpointFromCurrentTimestamp(address user) internal returns (uint256) {
        // this does not postpone using the previous checkpoint as a starting point, but the current timestamp
        // It's onlhy meant to be used by relock()
        uint256 newCheckpoint = block.timestamp + _checkpointMultiplier(user) * BASE_CHECKPOINT_DURATION;
        checkpoint[user] = newCheckpoint;
        emit CheckpointSet(user, newCheckpoint);
        return newCheckpoint;
    }

    function _initCheckpoint(address user) internal {
        uint256 userCheckpoint = block.timestamp + _checkpointMultiplier(user) * BASE_CHECKPOINT_DURATION;
        checkpoint[user] = userCheckpoint;
        emit CheckpointSet(user, userCheckpoint);
    }

    function _resetCheckpointInfo(address _user) internal {
        // either of the following variables can be used to identify a 'finished' stakeholder
        delete checkpoint[_user];
        // deleting the checkpointMultiplierReduction will also remove the superstaker status
        delete checkpointMultiplierReduction[_user];
        emit CheckpointSet(_user, 0);
    }

    /// @dev    The condition for being a super staker is to have crossed at least one checkpoint
    function _isSuperstaker(address user) internal view returns (bool) {
        return checkpointMultiplierReduction[user] > 0;
    }

    function _canCrossCheckpoint(address user) internal view returns (bool) {
        // only allows existing users
        return (checkpoint[user] != 0) && (block.timestamp > checkpoint[user]);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// This contract handles the penalty pot.
/// There are two stages of the balance
/// Vinci tokens are first deposited into the penaltyPool
/// Regularly, the contract owner will 'distribute' the penaltyPool between users, allocating the amounts proportional
/// to their share of the supplyEligibleForAllocation
/// However, none of the two above are 'claimable' until a checkpoint is crossed and they go to the claimable balance

contract PenaltyPot {
    // Supply is tracked with limited number of decimals. This is done to avoid losing decimals in _distributePenaltyPot()
    uint256 public constant PENALTYPOT_SUPPLY_DECIMALS = 3;
    uint256 public constant PENALTYPOT_ROUNDING_FACTOR = 10 ** (18 - PENALTYPOT_SUPPLY_DECIMALS);
    uint256 internal supplyEligibleForAllocation;
    // The amount of vinci tokens that are allocated to each staked vinci token belonging to eligible supply
    uint256 internal allocationPerStakedVinci;

    // The actual pool tracking all deposited tokens from penalized stakers
    uint256 internal penaltyPool;
    // In every distribution, some decimals would be lost, so they are buffered here
    uint256 internal bufferedVinci;

    // These variables are used to track the decimals lost in supplyEligibleForAllocation in additions and removals
    uint256 internal bufferedDecimalsInSupplyAdditions;
    uint256 internal bufferedDecimalsInSupplyRemovals;

    mapping(address => uint256) internal individualAllocationTracker;
    mapping(address => uint256) internal individualBuffer;

    event DepositedToPenaltyPot(address user, uint256 amountDeposited);
    event PenaltyPotDistributed(uint256 amountDistributed, uint256 bufferedDecimals);

    function _depositToPenaltyPot(uint256 amount) internal {
        penaltyPool += amount;
        emit DepositedToPenaltyPot(msg.sender, amount);
    }

    /// @dev    Here the pool is distributed into individual allocations (not claimable yet)
    function _distributePenaltyPot() internal {
        uint256 eligibleSupply = supplyEligibleForAllocation;

        if (eligibleSupply == 0) {
            bufferedVinci += penaltyPool;
            penaltyPool = 0;
            emit PenaltyPotDistributed(0, bufferedVinci);
            return;
        }

        uint256 totalToDistribute = penaltyPool + bufferedVinci;

        // eligible supply is divided by the PENALTYPOT_ROUNDING_FACTOR, so distributePerVinci (and therefore allocationPerStakedVinci)
        // are artificially boosted
        uint256 distributePerVinci = totalToDistribute / eligibleSupply;
        uint256 lostDecimals = totalToDistribute % eligibleSupply;
        // overwriting bufferedDecimals is intentional, as the old decimals are included in `totalToDistribute`
        bufferedVinci = lostDecimals;
        allocationPerStakedVinci += distributePerVinci;
        penaltyPool = 0;

        emit PenaltyPotDistributed(distributePerVinci * eligibleSupply, lostDecimals);
    }

    function _bufferPenaltyPotAllocation(address user, uint256 _stakingBalance) internal returns (uint256) {
        // the individualBuffer is already converted to the right amount of decimals
        // here we store the newBuffer in memory to save gas, to avoid read and writes of individualBuffer from storage
        uint256 newBuffer = _getAllocatedSharePenaltyPot(user, _stakingBalance);

        individualBuffer[user] = newBuffer;
        individualAllocationTracker[user] = allocationPerStakedVinci;
        return newBuffer;
    }

    function _addToEligibleSupplyForPenaltyPot(uint256 amount) internal {
        uint256 amountToAdd = amount + bufferedDecimalsInSupplyAdditions;
        supplyEligibleForAllocation += (amountToAdd / PENALTYPOT_ROUNDING_FACTOR);
        // overwriting is intentional, as the old decimals are included in `amountToAdd`
        bufferedDecimalsInSupplyAdditions = amountToAdd % PENALTYPOT_ROUNDING_FACTOR;
    }

    function _removeFromEligibleSupplyForPenaltyPot(uint256 amount) internal {
        uint256 amountToRemove = amount + bufferedDecimalsInSupplyRemovals;
        supplyEligibleForAllocation -= (amountToRemove / PENALTYPOT_ROUNDING_FACTOR);
        // overwriting is intentional, as the old decimals are included in `amountToRemove`
        bufferedDecimalsInSupplyRemovals = amountToRemove % PENALTYPOT_ROUNDING_FACTOR;
    }

    // @dev The penalization only needs to be done on the amount that has been already distributed. The non distribtued
    //      one is penalized automatically because of decreasing the share by unstaking
    function _penalizePenaltyPotShare(address user, uint256 unstakeAmount, uint256 stakingBalanceBefPenalization)
        internal
        returns (uint256)
    {
        // once buffered, there is no other allocation for user besides the `individualBuffer`
        uint256 updatedBuffer = _bufferPenaltyPotAllocation(user, stakingBalanceBefPenalization);
        uint256 penalization = updatedBuffer * unstakeAmount / stakingBalanceBefPenalization;
        updatedBuffer -= penalization;
        individualBuffer[user] = updatedBuffer;
        return penalization;
    }

    // @dev This only redeems the amount that has been already distributed
    function _redeemPenaltyPot(address user, uint256 _stakingBalance) internal returns (uint256) {
        uint256 updatedBuffer = _getAllocatedSharePenaltyPot(user, _stakingBalance);
        individualAllocationTracker[user] = allocationPerStakedVinci;
        delete individualBuffer[user];
        return updatedBuffer;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // @dev This one only shows the allocated penalty pot. The one that is actually asigned to a user
    //      The allocated is the one showing as unclaimable balance in VinciStaking
    function _getAllocatedSharePenaltyPot(address user, uint256 _stakingBalance) internal view returns (uint256) {
        return individualBuffer[user]
            + _stakingBalance * (allocationPerStakedVinci - individualAllocationTracker[user]) / PENALTYPOT_ROUNDING_FACTOR;
    }

    // @dev This estimation takes into account both the distributed and the non-distributed amounts
    //      Note however that the distributed is not claimable yet either. This value however is not final until
    //      distributed.
    function _estimateUserShareOfPenaltyPot(address user, uint256 _stakingBalance) internal view returns (uint256) {
        if (supplyEligibleForAllocation == 0) return 0;

        return _getAllocatedSharePenaltyPot(user, _stakingBalance)
            + (_stakingBalance * penaltyPool) / (supplyEligibleForAllocation * PENALTYPOT_ROUNDING_FACTOR);
    }

    // @dev This is the penalty pot that has not been distributed yet
    function _getTotalPenaltyPot() internal view returns (uint256) {
        return penaltyPool + bufferedVinci;
    }

    function _getSupplyEligibleForAllocation() internal view returns (uint256) {
        return (supplyEligibleForAllocation * PENALTYPOT_ROUNDING_FACTOR) + bufferedDecimalsInSupplyAdditions
            - bufferedDecimalsInSupplyRemovals;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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