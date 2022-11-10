// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ICellarStaking } from "./interfaces/ICellarStaking.sol";

import "./Errors.sol";

/**
 * @title Sommelier Staking
 * @author Kevin Kennis
 *
 * Staking for Sommelier Cellars.
 *
 * This contract is inspired by the Synthetix staking rewards contract, Ampleforth's
 * token geyser, and Treasure DAO's MAGIC mine. However, there are unique improvements
 * and new features, specifically unbonding, as inspired by LP bonding on Osmosis.
 * Unbonding allows the contract to guarantee deposits for a certain amount of time,
 * increasing predictability and stickiness of TVL for Cellars.
 *
 * *********************************** Funding Flow ***********************************
 *
 * 1) The contract owner calls 'notifyRewardAmount' to specify an initial schedule of rewards
 *    The contract should hold enough the distribution token to fund the
 *    specified reward schedule, where the length of the reward schedule is defined by
 *    epochDuration. This duration can also be changed by the owner, and any change will apply
 *    to future calls to 'notifyRewardAmount' (but will not affect active schedules).
 * 2) At a future time, the contract owner may call 'notifyRewardAmount' again to extend the
 *    staking program with new rewards. These new schedules may distribute more or less
 *    rewards than previous epochs. If a previous epoch is not finished, any leftover rewards
 *    get rolled into the new schedule, increasing the reward rate. Reward schedules always
 *    end exactly 'epochDuration' seconds from the most recent time 'notifyRewardAmount' has been
 *    called.
 *
 * ********************************* Staking Lifecycle ********************************
 *
 * 1) A user may deposit a certain amount of tokens to stake, and is required to lock
 *    those tokens for a specified amount of time. There are three locking options:
 *    one day, one week, or one month. Longer locking times receive larger 'boosts',
 *    that the deposit will receive a larger proportional amount of shares. A user
 *    may not unstake until they choose to unbond, and time defined by the lock has
 *    elapsed during unbonding.
 * 2) When a user wishes to withdraw, they must first "unbond" their stake, which starts
 *    a timer equivalent to the lock time. They still receive their rewards during this
 *    time, but forfeit any locktime boosts. A user may cancel the unbonding period at any
 *    time to regain their boosts, which will set the unbonding timer back to 0.
 * 2) Once the lock has elapsed, a user may unstake their deposit, either partially
 *    or in full. The user will continue to receive the same 'boosted' amount of rewards
 *    until they unstake. The user may unstake all of their deposits at once, as long
 *    as all of the lock times have elapsed. When unstaking, the user will also receive
 *    all eligible rewards for all deposited stakes, which accumulate linearly.
 * 3) At any time, a user may claim their available rewards for their deposits. Rewards
 *    accumulate linearly and can be claimed at any time, whether or not the lock has
 *    for a given deposit has expired. The user can claim rewards for a specific deposit,
 *    or may choose to collect all eligible rewards at once.
 *
 * ************************************ Accounting ************************************
 *
 * The contract uses an accounting mechanism based on the 'rewardPerToken' model,
 * originated by the Synthetix staking rewards contract. First, token deposits are accounted
 * for, with synthetic "boosted" amounts used for reward calculations. As time passes,
 * rewardPerToken continues to accumulate, whereas the value of 'rewardPerToken' will match
 * the reward due to a single token deposited before the first ever rewards were scheduled.
 *
 * At each accounting checkpoint, rewardPerToken will be recalculated, and every time an
 * existing stake is 'touched', this value is used to calculate earned rewards for that
 * stake. Each stake tracks a 'rewardPerTokenPaid' value, which represents the 'rewardPerToken'
 * value the last time the stake calculated "earned" rewards. Every recalculation pays the difference.
 * This ensures no earning is double-counted. When a new stake is deposited, its
 * initial 'rewardPerTokenPaid' is set to the current 'rewardPerToken' in the contract,
 * ensuring it will not receive any rewards emitted during the period before deposit.
 *
 * The following example applies to a given epoch of 100 seconds, with a reward rate
 * of 100 tokens per second:
 *
 * a) User 1 deposits a stake of 50 before the epoch begins
 * b) User 2 deposits a stake of 20 at second 20 of the epoch
 * c) User 3 deposits a stake of 100 at second 50 of the epoch
 *
 * In this case,
 *
 * a) At second 20, before User 2's deposit, rewardPerToken will be 40
 *     (2000 total tokens emitted over 20 seconds / 50 staked).
 * b) At second 50, before User 3's deposit, rewardPerToken will be 82.857
 *     (previous 40 + 3000 tokens emitted over 30 seconds / 70 staked == 42.857)
 * c) At second 100, when the period is over, rewardPerToken will be 112.267
 *     (previous 82.857 + 5000 tokens emitted over 50 seconds / 170 staked == 29.41)
 *
 *
 * Then, each user will receive rewards proportional to the their number of tokens. At second 100:
 * a) User 1 will receive 50 * 112.267 = 5613.35 rewards
 * b) User 2 will receive 20 * (112.267 - 40) = 1445.34
 *       (40 is deducted because it was the current rewardPerToken value on deposit)
 * c) User 3 will receive 100 * (112.267 - 82.857) = 2941
 *       (82.857 is deducted because it was the current rewardPerToken value on deposit)
 *
 * Depending on deposit times, this accumulation may take place over multiple
 * reward periods, and the total rewards earned is simply the sum of rewards earned for
 * each period. A user may also have multiple discrete deposits, which are all
 * accounted for separately due to timelocks and locking boosts. Therefore,
 * a user's total earned rewards are a function of their rewards across
 * the proportional tokens deposited, across different ranges of rewardPerToken.
 *
 * Reward accounting takes place before every operation which may change
 * accounting calculations (minting of new shares on staking, burning of
 * shares on unstaking, or claiming, which decrements eligible rewards).
 * This is gas-intensive but unavoidable, since retroactive accounting
 * based on previous proportionate shares would require a prohibitive
 * amount of storage of historical state. On every accounting run, there
 * are a number of safety checks to ensure that all reward tokens are
 * accounted for and that no accounting time periods have been missed.
 *
 */
contract CellarStaking is ICellarStaking, Ownable {
    using SafeTransferLib for ERC20;

    // ============================================ STATE ==============================================

    // ============== Constants ==============

    uint256 public constant ONE = 1e18;
    uint256 public constant ONE_DAY = 60 * 60 * 24;
    uint256 public constant ONE_WEEK = ONE_DAY * 7;
    uint256 public constant TWO_WEEKS = ONE_WEEK * 2;

    uint256 public immutable SHORT_BOOST;
    uint256 public immutable MEDIUM_BOOST;
    uint256 public immutable LONG_BOOST;

    uint256 public immutable SHORT_BOOST_TIME;
    uint256 public immutable MEDIUM_BOOST_TIME;
    uint256 public immutable LONG_BOOST_TIME;

    // ============ Global State =============

    ERC20 public immutable override stakingToken;
    ERC20 public immutable override distributionToken;
    uint256 public override currentEpochDuration;
    uint256 public override nextEpochDuration;
    uint256 public override rewardsReady;

    uint256 public override minimumDeposit;
    uint256 public override endTimestamp;
    uint256 public override totalDeposits;
    uint256 public override totalDepositsWithBoost;
    uint256 public override rewardRate;
    uint256 public override rewardPerTokenStored;

    uint256 private lastAccountingTimestamp = block.timestamp;

    /// @notice Emergency states in case of contract malfunction.
    bool public override paused;
    bool public override ended;
    bool public override claimable;

    // ============= User State ==============

    /// @notice user => all user's staking positions
    mapping(address => UserStake[]) public stakes;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @param _owner                The owner of the staking contract - will immediately receive ownership.
     * @param _stakingToken         The token users will deposit in order to stake.
     * @param _distributionToken    The token the staking contract will distribute as rewards.
     * @param _epochDuration        The length of a reward schedule.
     * @param shortBoost            The boost multiplier for the short unbonding time.
     * @param mediumBoost           The boost multiplier for the medium unbonding time.
     * @param longBoost             The boost multiplier for the long unbonding time.
     * @param shortBoostTime        The short unbonding time.
     * @param mediumBoostTime       The medium unbonding time.
     * @param longBoostTime         The long unbonding time.
     */
    constructor(
        address _owner,
        ERC20 _stakingToken,
        ERC20 _distributionToken,
        uint256 _epochDuration,
        uint256 shortBoost,
        uint256 mediumBoost,
        uint256 longBoost,
        uint256 shortBoostTime,
        uint256 mediumBoostTime,
        uint256 longBoostTime
    ) {
        stakingToken = _stakingToken;
        distributionToken = _distributionToken;
        nextEpochDuration = _epochDuration;

        SHORT_BOOST = shortBoost;
        MEDIUM_BOOST = mediumBoost;
        LONG_BOOST = longBoost;

        SHORT_BOOST_TIME = shortBoostTime;
        MEDIUM_BOOST_TIME = mediumBoostTime;
        LONG_BOOST_TIME = longBoostTime;

        transferOwnership(_owner);
    }

    // ======================================= STAKING OPERATIONS =======================================

    /**
     * @notice  Make a new deposit into the staking contract. Longer locks receive reward boosts.
     * @dev     Specified amount of stakingToken must be approved for withdrawal by the caller.
     * @dev     Valid lock values are 0 (one day), 1 (one week), and 2 (two weeks).
     *
     * @param amount                The amount of the stakingToken to stake.
     * @param lock                  The amount of time to lock stake for.
     */
    function stake(uint256 amount, Lock lock) external override whenNotPaused updateRewards {
        if (amount == 0) revert USR_ZeroDeposit();
        if (amount < minimumDeposit) revert USR_MinimumDeposit(amount, minimumDeposit);

        if (totalDeposits == 0 && rewardsReady > 0) {
            _startProgram(rewardsReady);
            rewardsReady = 0;

            // Need to run updateRewards again
            _updateRewards();
        } else if (block.timestamp > endTimestamp) {
            revert STATE_NoRewardsLeft();
        }

        // Do share accounting and populate user stake information
        (uint256 boost, ) = _getBoost(lock);
        uint256 amountWithBoost = amount + ((amount * boost) / ONE);

        stakes[msg.sender].push(
            UserStake({
                amount: uint112(amount),
                amountWithBoost: uint112(amountWithBoost),
                unbondTimestamp: 0,
                rewardPerTokenPaid: uint112(rewardPerTokenStored),
                rewards: 0,
                lock: lock
            })
        );

        // Update global state
        totalDeposits += amount;
        totalDepositsWithBoost += amountWithBoost;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, stakes[msg.sender].length - 1, amount);
    }

    /**
     * @notice  Unbond a specified amount from a certain deposited stake.
     * @dev     After the unbond time elapses, the deposit can be unstaked.
     *
     * @param depositId             The specified deposit to unstake from.
     *
     */
    function unbond(uint256 depositId) external override whenNotPaused updateRewards {
        _unbond(depositId);
    }

    /**
     * @notice  Unbond all user deposits.
     * @dev     Different deposits may have different timelocks.
     *
     */
    function unbondAll() external override whenNotPaused updateRewards {
        // Individually unbond each deposit
        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            UserStake storage s = userStakes[i];

            if (s.amount != 0 && s.unbondTimestamp == 0) {
                _unbond(i);
            }
        }
    }

    /**
     * @dev     Contains all logic for processing an unbond operation.
     *          For the given deposit, sets an unlock time, and
     *          reverts boosts to 0.
     *
     * @param depositId             The specified deposit to unbond from.
     */
    function _unbond(uint256 depositId) internal {
        // Fetch stake and make sure it is withdrawable
        UserStake storage s = stakes[msg.sender][depositId];

        uint256 depositAmount = s.amount;
        if (depositAmount == 0) revert USR_NoDeposit(depositId);
        if (s.unbondTimestamp > 0) revert USR_AlreadyUnbonding(depositId);

        _updateRewardForStake(msg.sender, depositId);

        // Remove any lock boosts
        uint256 depositAmountReduced = s.amountWithBoost - depositAmount;
        (, uint256 lockDuration) = _getBoost(s.lock);

        s.amountWithBoost = uint112(depositAmount);
        s.unbondTimestamp = uint32(block.timestamp + lockDuration);

        totalDepositsWithBoost -= uint112(depositAmountReduced);

        emit Unbond(msg.sender, depositId, depositAmount);
    }

    /**
     * @notice  Cancel an unbonding period for a stake that is currently unbonding.
     * @dev     Resets the unbonding timer and reinstates any lock boosts.
     *
     * @param depositId             The specified deposit to unstake from.
     *
     */
    function cancelUnbonding(uint256 depositId) external override whenNotPaused updateRewards {
        _cancelUnbonding(depositId);
    }

    /**
     * @notice  Cancel an unbonding period for all stakes.
     * @dev     Only cancels stakes that are unbonding.
     *
     */
    function cancelUnbondingAll() external override whenNotPaused updateRewards {
        // Individually unbond each deposit
        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            UserStake storage s = userStakes[i];

            if (s.amount != 0 && s.unbondTimestamp != 0) {
                _cancelUnbonding(i);
            }
        }
    }

    /**
     * @dev     Contains all logic for cancelling an unbond operation.
     *          For the given deposit, resets the unbonding timer, and
     *          reverts boosts to amount determined by lock.
     *
     * @param depositId             The specified deposit to unbond from.
     */
    function _cancelUnbonding(uint256 depositId) internal {
        // Fetch stake and make sure it is withdrawable
        UserStake storage s = stakes[msg.sender][depositId];

        uint256 depositAmount = s.amount;
        if (depositAmount == 0) revert USR_NoDeposit(depositId);
        if (s.unbondTimestamp == 0) revert USR_NotUnbonding(depositId);

        _updateRewardForStake(msg.sender, depositId);

        // Reinstate
        (uint256 boost, ) = _getBoost(s.lock);
        uint256 depositAmountIncreased = (s.amount * boost) / ONE;
        uint256 amountWithBoost = s.amount + depositAmountIncreased;

        s.amountWithBoost = uint112(amountWithBoost);
        s.unbondTimestamp = 0;

        totalDepositsWithBoost += depositAmountIncreased;

        emit CancelUnbond(msg.sender, depositId);
    }

    /**
     * @notice  Unstake a specific deposited stake.
     * @dev     The unbonding time for the specified deposit must have elapsed.
     * @dev     Unstaking automatically claims available rewards for the deposit.
     *
     * @param depositId             The specified deposit to unstake from.
     *
     * @return reward               The amount of accumulated rewards since the last reward claim.
     */
    function unstake(uint256 depositId) external override whenNotPaused updateRewards returns (uint256 reward) {
        return _unstake(depositId);
    }

    /**
     * @notice  Unstake all user deposits.
     * @dev     Only unstakes rewards that are unbonded.
     * @dev     Unstaking automatically claims all available rewards.
     *
     * @return rewards              The amount of accumulated rewards since the last reward claim.
     */
    function unstakeAll() external override whenNotPaused updateRewards returns (uint256[] memory) {
        // Individually unstake each deposit
        UserStake[] storage userStakes = stakes[msg.sender];
        uint256[] memory rewards = new uint256[](userStakes.length);

        for (uint256 i = 0; i < userStakes.length; i++) {
            UserStake storage s = userStakes[i];

            if (s.amount != 0 && s.unbondTimestamp != 0 && block.timestamp >= s.unbondTimestamp) {
                rewards[i] = _unstake(i);
            }
        }

        return rewards;
    }

    /**
     * @dev     Contains all logic for processing an unstake operation.
     *          For the given deposit, does share accounting and burns
     *          shares, returns staking tokens to the original owner,
     *          updates global deposit and share trackers, and claims
     *          rewards for the given deposit.
     *
     * @param depositId             The specified deposit to unstake from.
     */
    function _unstake(uint256 depositId) internal returns (uint256 reward) {
        // Fetch stake and make sure it is withdrawable
        UserStake storage s = stakes[msg.sender][depositId];

        uint256 depositAmount = s.amount;

        if (depositAmount == 0) revert USR_NoDeposit(depositId);
        if (s.unbondTimestamp == 0 || block.timestamp < s.unbondTimestamp) revert USR_StakeLocked(depositId);

        _updateRewardForStake(msg.sender, depositId);

        // Start unstaking
        reward = s.rewards;

        s.amount = 0;
        s.amountWithBoost = 0;
        s.rewards = 0;

        // Update global state
        // Boosted amount same as deposit amount, since we have unbonded
        totalDeposits -= depositAmount;
        totalDepositsWithBoost -= depositAmount;

        // Distribute stake
        stakingToken.safeTransfer(msg.sender, depositAmount);

        // Distribute reward
        distributionToken.safeTransfer(msg.sender, reward);

        emit Unstake(msg.sender, depositId, depositAmount, reward);
    }

    /**
     * @notice  Claim rewards for a given deposit.
     * @dev     Rewards accumulate linearly since deposit.
     *
     * @param depositId             The specified deposit for which to claim rewards.
     *
     * @return reward               The amount of accumulated rewards since the last reward claim.
     */
    function claim(uint256 depositId) external override whenNotPaused updateRewards returns (uint256 reward) {
        return _claim(depositId);
    }

    /**
     * @notice  Claim all available rewards.
     * @dev     Rewards accumulate linearly.
     *
     *
     * @return rewards               The amount of accumulated rewards since the last reward claim.
     *                               Each element of the array specified rewards for the corresponding
     *                               indexed deposit.
     */
    function claimAll() external override whenNotPaused updateRewards returns (uint256[] memory rewards) {
        // Individually claim for each stake
        UserStake[] storage userStakes = stakes[msg.sender];
        rewards = new uint256[](userStakes.length);

        for (uint256 i = 0; i < userStakes.length; i++) {
            rewards[i] = _claim(i);
        }
    }

    /**
     * @dev Contains all logic for processing a claim operation.
     *      Relies on previous reward accounting done before
     *      processing external functions. Updates the amount
     *      of rewards claimed so rewards cannot be claimed twice.
     *
     *
     * @param depositId             The specified deposit to claim rewards for.
     *
     * @return reward               The amount of accumulated rewards since the last reward claim.
     */
    function _claim(uint256 depositId) internal returns (uint256 reward) {
        // Fetch stake and make sure it is valid
        UserStake storage s = stakes[msg.sender][depositId];

        _updateRewardForStake(msg.sender, depositId);

        reward = s.rewards;

        // Distribute reward
        if (reward > 0) {
            s.rewards = 0;

            distributionToken.safeTransfer(msg.sender, reward);

            emit Claim(msg.sender, depositId, reward);
        }
    }

    /**
     * @notice  Unstake and return all staked tokens to the caller.
     * @dev     In emergency mode, staking time locks do not apply.
     */
    function emergencyUnstake() external override {
        if (!ended) revert STATE_NoEmergencyUnstake();

        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (claimable) _updateRewardForStake(msg.sender, i);

            UserStake storage s = userStakes[i];
            uint256 amount = s.amount;

            if (amount > 0) {
                // Update global state
                totalDeposits -= amount;
                totalDepositsWithBoost -= s.amountWithBoost;

                s.amount = 0;
                s.amountWithBoost = 0;

                stakingToken.transfer(msg.sender, amount);

                emit EmergencyUnstake(msg.sender, i, amount);
            }
        }
    }

    /**
     * @notice  Claim any accumulated rewards in emergency mode.
     * @dev     In emergency node, no additional reward accounting is done.
     *          Rewards do not accumulate after emergency mode begins,
     *          so any earned amount is only retroactive to when the contract
     *          was active.
     */
    function emergencyClaim() external override {
        if (!ended) revert STATE_NoEmergencyUnstake();
        if (!claimable) revert STATE_NoEmergencyClaim();

        uint256 reward;

        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            _updateRewardForStake(msg.sender, i);

            UserStake storage s = userStakes[i];

            reward += s.rewards;
            s.rewards = 0;
        }

        if (reward > 0) {
            distributionToken.safeTransfer(msg.sender, reward);

            // No need for per-stake events like emergencyUnstake:
            // don't need to make sure positions were unwound
            emit EmergencyClaim(msg.sender, reward);
        }
    }

    // ======================================== ADMIN OPERATIONS ========================================

    /**
     * @notice Specify a new schedule for staking rewards. Contract must already hold enough tokens.
     * @dev    Can only be called by reward distributor. Owner must approve distributionToken for withdrawal.
     * @dev    epochDuration must divide reward evenly, otherwise any remainder will be lost.
     *
     * @param reward                The amount of rewards to distribute per second.
     */
    function notifyRewardAmount(uint256 reward) external override onlyOwner updateRewards {
        if (block.timestamp < endTimestamp) {
            uint256 remaining = endTimestamp - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward += leftover;
        }

        if (reward < nextEpochDuration) revert USR_ZeroRewardsPerEpoch();

        uint256 rewardBalance = distributionToken.balanceOf(address(this));
        uint256 pendingRewards = reward + rewardsReady;
        if (rewardBalance < pendingRewards) revert STATE_RewardsNotFunded(rewardBalance, pendingRewards);

        // prevent overflow when computing rewardPerToken
        uint256 proposedRewardRate = reward / nextEpochDuration;
        if (proposedRewardRate >= ((type(uint256).max / ONE) / nextEpochDuration)) {
            revert USR_RewardTooLarge();
        }

        if (totalDeposits == 0) {
            // No deposits yet, so keep rewards pending until first deposit
            // Incrementing in case it is called twice
            rewardsReady += reward;
        } else {
            // Ready to start
            _startProgram(reward);
        }

        lastAccountingTimestamp = block.timestamp;
    }

    /**
     * @notice Change the length of a reward epoch for future reward schedules.
     *
     * @param _epochDuration        The new duration for reward schedules.
     */
    function setRewardsDuration(uint256 _epochDuration) external override onlyOwner {
        if (rewardsReady > 0) revert STATE_RewardsReady();

        nextEpochDuration = _epochDuration;
        emit EpochDurationChange(nextEpochDuration);
    }

    /**
     * @notice Specify a minimum deposit for staking.
     * @dev    Can only be called by owner.
     *
     * @param _minimum              The minimum deposit for each new stake.
     */
    function setMinimumDeposit(uint256 _minimum) external override onlyOwner {
        minimumDeposit = _minimum;
    }

    /**
     * @notice Pause the contract. Pausing prevents staking, unstaking, claiming
     *         rewards, and scheduling new rewards. Should only be used
     *         in an emergency.
     *
     * @param _paused               Whether the contract should be paused.
     */
    function setPaused(bool _paused) external override onlyOwner {
        paused = _paused;
    }

    /**
     * @notice Stops the contract - this is irreversible. Should only be used
     *         in an emergency, for example an irreversible accounting bug
     *         or an exploit. Enables all depositors to withdraw their stake
     *         instantly. Also stops new rewards accounting.
     *
     * @param makeRewardsClaimable  Whether any previously accumulated rewards should be claimable.
     */
    function emergencyStop(bool makeRewardsClaimable) external override onlyOwner {
        if (ended) revert STATE_AlreadyShutdown();

        // Update state and put in irreversible emergency mode
        ended = true;
        claimable = makeRewardsClaimable;
        uint256 amountToReturn = distributionToken.balanceOf(address(this));

        if (makeRewardsClaimable) {
            // Update rewards one more time
            _updateRewards();

            // Return any remaining, since new calculation is stopped
            uint256 remaining = endTimestamp > block.timestamp ? (endTimestamp - block.timestamp) * rewardRate : 0;

            // Make sure any rewards except for remaining are kept for claims
            uint256 amountToKeep = rewardRate * currentEpochDuration - remaining;

            amountToReturn -= amountToKeep;
        }

        // Send distribution token back to owner
        distributionToken.transfer(msg.sender, amountToReturn);

        emit EmergencyStop(msg.sender, makeRewardsClaimable);
    }

    // ======================================= STATE INFORMATION =======================================

    /**
     * @notice Returns the latest time to account for in the reward program.
     *
     * @return timestamp           The latest time to calculate.
     */
    function latestRewardsTimestamp() public view override returns (uint256) {
        return block.timestamp < endTimestamp ? block.timestamp : endTimestamp;
    }

    /**
     * @notice Returns the amount of reward to distribute per currently-depostied token.
     *         Will update on changes to total deposit balance or reward rate.
     * @dev    Sets rewardPerTokenStored.
     *
     *
     * @return newRewardPerTokenStored  The new rewards to distribute per token.
     * @return latestTimestamp          The latest time to calculate.
     */
    function rewardPerToken() public view override returns (uint256 newRewardPerTokenStored, uint256 latestTimestamp) {
        latestTimestamp = latestRewardsTimestamp();

        if (totalDeposits == 0) return (rewardPerTokenStored, latestTimestamp);

        uint256 timeElapsed = latestTimestamp - lastAccountingTimestamp;
        uint256 rewardsForTime = timeElapsed * rewardRate;
        uint256 newRewardsPerToken = (rewardsForTime * ONE) / totalDepositsWithBoost;

        newRewardPerTokenStored = rewardPerTokenStored + newRewardsPerToken;
    }

    /**
     * @notice Gets all of a user's stakes.
     * @dev This is provided because Solidity converts public arrays into index getters,
     *      but we need a way to allow external contracts and users to access the whole array.

     * @param user                      The user whose stakes to get.
     *
     * @return stakes                   Array of all user's stakes
     */
    function getUserStakes(address user) public view override returns (UserStake[] memory) {
        return stakes[user];
    }

    // ============================================ HELPERS ============================================

    /**
     * @dev Modifier to apply reward updates before functions that change accounts.
     */
    modifier updateRewards() {
        _updateRewards();
        _;
    }

    /**
     * @dev Blocks calls if contract is paused or killed.
     */
    modifier whenNotPaused() {
        if (paused) revert STATE_ContractPaused();
        if (ended) revert STATE_ContractKilled();
        _;
    }

    /**
     * @dev Update reward accounting for the global state totals.
     */
    function _updateRewards() internal {
        (rewardPerTokenStored, lastAccountingTimestamp) = rewardPerToken();
    }

    /**
     * @dev On initial deposit, start the rewards program.
     *
     * @param reward                    The pending rewards to start distributing.
     */
    function _startProgram(uint256 reward) internal {
        // Assumptions
        // Total deposits are now (mod current tx), no ongoing program
        // Rewards are already funded (since checked in notifyRewardAmount)

        rewardRate = reward / nextEpochDuration;
        endTimestamp = block.timestamp + nextEpochDuration;
        currentEpochDuration = nextEpochDuration;

        emit Funding(reward, endTimestamp);
    }

    /**
     * @dev Update reward for a specific user stake.
     */
    function _updateRewardForStake(address user, uint256 depositId) internal {
        UserStake storage s = stakes[user][depositId];
        if (s.amount == 0) return;

        uint256 earned = _earned(s);
        s.rewards += uint112(earned);

        s.rewardPerTokenPaid = uint112(rewardPerTokenStored);
    }

    /**
     * @dev Return how many rewards a stake has earned and has claimable.
     */
    function _earned(UserStake memory s) internal view returns (uint256) {
        uint256 rewardPerTokenAcc = rewardPerTokenStored - s.rewardPerTokenPaid;
        uint256 newRewards = (s.amountWithBoost * rewardPerTokenAcc) / ONE;

        return newRewards;
    }

    /**
     * @dev Maps Lock enum values to corresponding lengths of time and reward boosts.
     */
    function _getBoost(Lock _lock) internal view returns (uint256 boost, uint256 timelock) {
        if (_lock == Lock.short) {
            return (SHORT_BOOST, SHORT_BOOST_TIME);
        } else if (_lock == Lock.medium) {
            return (MEDIUM_BOOST, MEDIUM_BOOST_TIME);
        } else if (_lock == Lock.long) {
            return (LONG_BOOST, LONG_BOOST_TIME);
        } else {
            revert USR_InvalidLockValue(uint256(_lock));
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";

/**
 * @title Sommelier Staking Interface
 * @author Kevin Kennis
 *
 * @notice Full documentation in implementation contract.
 */
interface ICellarStaking {
    // ===================== Events =======================

    event Funding(uint256 rewardAmount, uint256 rewardEnd);
    event Stake(address indexed user, uint256 depositId, uint256 amount);
    event Unbond(address indexed user, uint256 depositId, uint256 amount);
    event CancelUnbond(address indexed user, uint256 depositId);
    event Unstake(address indexed user, uint256 depositId, uint256 amount, uint256 reward);
    event Claim(address indexed user, uint256 depositId, uint256 amount);
    event EmergencyStop(address owner, bool claimable);
    event EmergencyUnstake(address indexed user, uint256 depositId, uint256 amount);
    event EmergencyClaim(address indexed user, uint256 amount);
    event EpochDurationChange(uint256 duration);

    // ===================== Structs ======================

    enum Lock {
        short,
        medium,
        long
    }

    struct UserStake {
        uint112 amount;
        uint112 amountWithBoost;
        uint32 unbondTimestamp;
        uint112 rewardPerTokenPaid;
        uint112 rewards;
        Lock lock;
    }

    // ============== Public State Variables ==============

    function stakingToken() external returns (ERC20);

    function distributionToken() external returns (ERC20);

    function currentEpochDuration() external returns (uint256);

    function nextEpochDuration() external returns (uint256);

    function rewardsReady() external returns (uint256);

    function minimumDeposit() external returns (uint256);

    function endTimestamp() external returns (uint256);

    function totalDeposits() external returns (uint256);

    function totalDepositsWithBoost() external returns (uint256);

    function rewardRate() external returns (uint256);

    function rewardPerTokenStored() external returns (uint256);

    function paused() external returns (bool);

    function ended() external returns (bool);

    function claimable() external returns (bool);

    // ================ User Functions ================

    function stake(uint256 amount, Lock lock) external;

    function unbond(uint256 depositId) external;

    function unbondAll() external;

    function cancelUnbonding(uint256 depositId) external;

    function cancelUnbondingAll() external;

    function unstake(uint256 depositId) external returns (uint256 reward);

    function unstakeAll() external returns (uint256[] memory rewards);

    function claim(uint256 depositId) external returns (uint256 reward);

    function claimAll() external returns (uint256[] memory rewards);

    function emergencyUnstake() external;

    function emergencyClaim() external;

    // ================ Admin Functions ================

    function notifyRewardAmount(uint256 reward) external;

    function setRewardsDuration(uint256 _epochDuration) external;

    function setMinimumDeposit(uint256 _minimum) external;

    function setPaused(bool _paused) external;

    function emergencyStop(bool makeRewardsClaimable) external;

    // ================ View Functions ================

    function latestRewardsTimestamp() external view returns (uint256);

    function rewardPerToken() external view returns (uint256, uint256);

    function getUserStakes(address user) external view returns (UserStake[] memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

// ========================================== USER ERRORS ===========================================

/**
 * @dev These errors represent invalid user input to functions. Where appropriate, the invalid value
 *      is specified along with constraints. These errors can be resolved by callers updating their
 *      arguments.
 */

/**
 * @notice Attempted an action with zero assets.
 */
error USR_ZeroAssets();

/**
 * @notice Attempted an action with zero shares.
 */
error USR_ZeroShares();

/**
 * @notice Attempted deposit more than the max deposit.
 * @param assets the assets user attempted to deposit
 * @param maxDeposit the max assets that can be deposited
 */
error USR_DepositRestricted(uint256 assets, uint256 maxDeposit);

/**
 * @notice Attempted to transfer more active shares than the user has.
 * @param activeShares amount of shares user has
 * @param attemptedActiveShares amount of shares user tried to transfer
 */
error USR_NotEnoughActiveShares(uint256 activeShares, uint256 attemptedActiveShares);

/**
 * @notice Attempted swap into an asset that is not the current asset of the position.
 * @param assetOut address of the asset attempted to swap to
 * @param currentAsset address of the current asset of position
 */
error USR_InvalidSwap(address assetOut, address currentAsset);

/**
 * @notice Attempted to sweep an asset that is managed by the cellar.
 * @param token address of the token that can't be sweeped
 */
error USR_ProtectedAsset(address token);

/**
 * @notice Attempted rebalance into the same position.
 * @param position address of the position
 */
error USR_SamePosition(address position);

/**
 * @notice Attempted to update the position to one that is not supported by the platform.
 * @param unsupportedPosition address of the unsupported position
 */
error USR_UnsupportedPosition(address unsupportedPosition);

/**
 * @notice Attempted an operation on an untrusted position.
 * @param position address of the position
 */
error USR_UntrustedPosition(address position);

/**
 * @notice Attempted to update a position to an asset that uses an incompatible amount of decimals.
 * @param newDecimals decimals of precision that the new position uses
 * @param maxDecimals maximum decimals of precision for a position to be compatible with the cellar
 */
error USR_TooManyDecimals(uint8 newDecimals, uint8 maxDecimals);

/**
 * @notice User attempted to stake zero amout.
 */
error USR_ZeroDeposit();

/**
 * @notice User attempted to stake an amount smaller than the minimum deposit.
 *
 * @param amount                Amount user attmpted to stake.
 * @param minimumDeposit        The minimum deopsit amount accepted.
 */
error USR_MinimumDeposit(uint256 amount, uint256 minimumDeposit);

/**
 * @notice The specified deposit ID does not exist for the caller.
 *
 * @param depositId             The deposit ID provided for lookup.
 */
error USR_NoDeposit(uint256 depositId);

/**
 * @notice The user is attempting to cancel unbonding for a deposit which is not unbonding.
 *
 * @param depositId             The deposit ID the user attempted to cancel.
 */
error USR_NotUnbonding(uint256 depositId);

/**
 * @notice The user is attempting to unbond a deposit which has already been unbonded.
 *
 * @param depositId             The deposit ID the user attempted to unbond.
 */
error USR_AlreadyUnbonding(uint256 depositId);

/**
 * @notice The user is attempting to unstake a deposit which is still timelocked.
 *
 * @param depositId             The deposit ID the user attempted to unstake.
 */
error USR_StakeLocked(uint256 depositId);

/**
 * @notice The contract owner attempted to update rewards but the new reward rate would cause overflow.
 */
error USR_RewardTooLarge();

/**
 * @notice The reward distributor attempted to update rewards but 0 rewards per epoch.
 *         This can also happen if there is less than 1 wei of rewards per second of the
 *         epoch - due to integer division this will also lead to 0 rewards.
 */
error USR_ZeroRewardsPerEpoch();

/**
 * @notice The caller attempted to stake with a lock value that did not
 *         correspond to a valid staking time.
 *
 * @param lock                  The provided lock value.
 */
error USR_InvalidLockValue(uint256 lock);

/**
 * @notice The caller attempted an signed action with an invalid signature.
 * @param signatureLength length of the signature passed in
 * @param expectedSignatureLength expected length of the signature passed in
 */
error USR_InvalidSignature(uint256 signatureLength, uint256 expectedSignatureLength);

/**
 * @notice Attempted an action by a non-custodian
 */
error USR_NotCustodian();


// ========================================== STATE ERRORS ===========================================

/**
 * @dev These errors represent actions that are being prevented due to current contract state.
 *      These errors do not relate to user input, and may or may not be resolved by other actions
 *      or the progression of time.
 */

/**
 * @notice Attempted an action when cellar is using an asset that has a fee on transfer.
 * @param assetWithFeeOnTransfer address of the asset with fee on transfer
 */
error STATE_AssetUsesFeeOnTransfer(address assetWithFeeOnTransfer);

/**
 * @notice Attempted action was prevented due to contract being shutdown.
 */
error STATE_ContractShutdown();

/**
 * @notice Attempted to shutdown the contract when it was already shutdown.
 */
error STATE_AlreadyShutdown();

/**
 * @notice The caller attempted to start a reward period, but the contract did not have enough tokens
 *         for the specified amount of rewards.
 *
 * @param rewardBalance         The amount of distributionToken held by the contract.
 * @param reward                The amount of rewards the caller attempted to distribute.
 */
error STATE_RewardsNotFunded(uint256 rewardBalance, uint256 reward);

/**
 * @notice Attempted an operation that is prohibited while yield is still being distributed from the last accrual.
 */
error STATE_AccrualOngoing();

/**
 * @notice The caller attempted to change the epoch length, but current reward epochs were active.
 */
error STATE_RewardsOngoing();

/**
 * @notice The caller attempted to change the next epoch duration, but there are rewards ready.
 */
error STATE_RewardsReady();

/**
 * @notice The caller attempted to deposit stake, but there are no remaining rewards to pay out.
 */
error STATE_NoRewardsLeft();

/**
 * @notice The caller attempted to perform an an emergency unstake, but the contract
 *         is not in emergency mode.
 */
error STATE_NoEmergencyUnstake();

/**
 * @notice The caller attempted to perform an an emergency unstake, but the contract
 *         is not in emergency mode, or the emergency mode does not allow claiming rewards.
 */
error STATE_NoEmergencyClaim();

/**
 * @notice The caller attempted to perform a state-mutating action (e.g. staking or unstaking)
 *         while the contract was paused.
 */
error STATE_ContractPaused();

/**
 * @notice The caller attempted to perform a state-mutating action (e.g. staking or unstaking)
 *         while the contract was killed (placed in emergency mode).
 * @dev    Emergency mode is irreversible.
 */
error STATE_ContractKilled();

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