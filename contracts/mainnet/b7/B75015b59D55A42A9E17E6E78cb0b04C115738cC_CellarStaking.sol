// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Errors.sol";
import "./interfaces/ICellarStaking.sol";

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
 *    The contract collects the distribution token from the owner to fund the
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
    using SafeERC20 for ERC20;

    // ============================================ STATE ==============================================

    // ============== Constants ==============

    uint256 public constant ONE = 1e18;
    uint256 public constant ONE_DAY = 60 * 60 * 24;
    uint256 public constant ONE_WEEK = ONE_DAY * 7;
    uint256 public constant TWO_WEEKS = ONE_WEEK * 2;
    uint256 public constant MAX_UINT = 2**256 - 1;

    uint256 public immutable SHORT_BOOST;
    uint256 public immutable MEDIUM_BOOST;
    uint256 public immutable LONG_BOOST;

    uint256 public immutable SHORT_BOOST_TIME;
    uint256 public immutable MEDIUM_BOOST_TIME;
    uint256 public immutable LONG_BOOST_TIME;

    // ============ Global State =============

    ERC20 public immutable override stakingToken;
    ERC20 public immutable override distributionToken;
    uint256 public override epochDuration;

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

    /// @notice Tracks if an address can call notifyReward()
    mapping(address => bool) public override isRewardDistributor;

    // ============= User State ==============

    /// @notice user => all user's staking positions
    mapping(address => UserStake[]) public stakes;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @param _owner                The owner of the staking contract - will immediately receive ownership.
     * @param _rewardsDistribution  The address allowed to schedule new rewards.
     * @param _stakingToken         The token users will deposit in order to stake.
     * @param _distributionToken    The token the staking contract will distribute as rewards.
     * @param _epochDuration        The length of a reward schedule.
     */
    constructor(
        address _owner,
        address _rewardsDistribution,
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
        isRewardDistributor[_rewardsDistribution] = true;
        distributionToken = _distributionToken;
        epochDuration = _epochDuration;

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
        if (block.timestamp > endTimestamp) revert STATE_NoRewardsLeft();

        // Do share accounting and populate user stake information
        (uint256 boost, ) = _getBoost(lock);
        uint256 amountWithBoost = amount + ((amount * boost) / ONE);

        stakes[msg.sender].push(UserStake({
            amount: amount,
            amountWithBoost: amountWithBoost,
            rewardPerTokenPaid: rewardPerTokenStored,
            rewards: 0,
            unbondTimestamp: 0,
            lock: lock
        }));

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

        s.amountWithBoost = depositAmount;
        s.unbondTimestamp = block.timestamp + lockDuration;

        totalDepositsWithBoost -= depositAmountReduced;

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
        uint256 amountWithBoost = s.amount + (s.amount * boost) / ONE;
        uint256 depositAmountIncreased = amountWithBoost - s.amountWithBoost;

        s.amountWithBoost = amountWithBoost;
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
        uint256 amountWithBoost = s.amountWithBoost;
        reward = s.rewards;

        s.amount = 0;
        s.amountWithBoost = 0;
        s.rewards = 0;

        // Update global state
        totalDeposits -= depositAmount;
        totalDepositsWithBoost -= amountWithBoost;

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
            UserStake storage s = userStakes[i];
            uint256 amount = s.amount;

            if (amount > 0) {
                s.amount = 0;

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
     * @notice Specify a new schedule for staking rewards.
     * @dev    Can only be called by reward distributor. Owner must approve distributionToken for withdrawal.
     *
     * @param reward                The amount of rewards to distribute per second.
     */
    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateRewards {
        if (reward < epochDuration) revert USR_ZeroRewardsPerEpoch();

        if (block.timestamp >= endTimestamp) {
            // Set new rate bc previous has already expired
            rewardRate = reward / epochDuration;
        } else {
            uint256 remaining = endTimestamp - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / epochDuration;
        }

        // prevent overflow when computing rewardPerToken
        if (rewardRate >= ((type(uint256).max / ONE) / epochDuration)) {
            revert USR_RewardTooLarge();
        }

        endTimestamp = block.timestamp + epochDuration;

        // Source rewards
        distributionToken.safeTransferFrom(msg.sender, address(this), reward);

        emit Funding(reward, endTimestamp);
    }

    /**
     * @notice Change the length of a reward epoch for future reward schedules.
     *
     * @param _epochDuration        The new duration for reward schedules.
     */
    function setRewardsDuration(uint256 _epochDuration) external override onlyOwner {
        epochDuration = _epochDuration;
        emit EpochDurationChange(epochDuration);
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
        if (ended) revert STATE_AlreadyStopped();

        // Update state and put in irreversible emergency mode
        ended = true;
        claimable = makeRewardsClaimable;

        if (!claimable) {
            // Send distribution token back to owner
            distributionToken.transfer(msg.sender, distributionToken.balanceOf(address(this)));
        }

        emit EmergencyStop(msg.sender, makeRewardsClaimable);
    }

    /**
     * @notice Set the EOA or contract allowed to call 'notifyRewardAmount' to schedule
     *         new rewards.
     *
     * @param _rewardsDistribution  The new reward distributor.
     * @param _set                  Whether the address should be allowed to distribute.
     */
    function setRewardsDistribution(address _rewardsDistribution, bool _set) external override onlyOwner {
        isRewardDistributor[_rewardsDistribution] = _set;

        emit DistributorSet(_rewardsDistribution, _set);
    }

    // ======================================= STATE INFORMATION =======================================

    /**
     * @notice Returns the latest time to account for in the reward program.
     *
     * @return timestamp           The latest time to calculate.
     */
    function latestRewardsTimestamp() public view override returns (uint256) {
        return
            block.timestamp < endTimestamp
                ? block.timestamp
                : endTimestamp;
    }

    /**
     * @notice Returns the amount of reward to distribute per currently-depostied token.
     *         Will update on changes to total deposit balance or reward rate.
     * @dev    Sets rewardPerTokenStored.
     *
     *
     * @return rewardPerToken           The latest time to calculate.
     */
    function rewardPerToken() public view override returns (uint256) {
        if (totalDeposits == 0) return rewardPerTokenStored;

        uint256 timeElapsed = latestRewardsTimestamp() - lastAccountingTimestamp;
        uint256 rewardsForTime = timeElapsed * rewardRate;
        uint256 newRewardsPerToken = rewardsForTime * ONE / totalDepositsWithBoost;

        return rewardPerTokenStored + newRewardsPerToken;
    }

    /**
     * @notice Returns the number of stakes for a user. Can be used off-chain to
     *         make iterating through user stakes easier.
     *
     * @param user                      The user to count stakes for.
     *
     * @return stakes                   The number of stakes for the user.
     */
    function numStakes(address user) public view override returns (uint256) {
        return stakes[user].length;
    }

    // ============================================ HELPERS ============================================

    /**
     * @dev Can only be called by the designated reward distributor
     */
    modifier onlyRewardsDistribution() {
        if (!isRewardDistributor[msg.sender]) revert USR_NotDistributor();

        _;
    }

    /**
     * @dev Update reward accounting for the global state totals.
     */
    modifier updateRewards() {
        rewardPerTokenStored = rewardPerToken();
        lastAccountingTimestamp = latestRewardsTimestamp();

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
     * @dev Update reward for a specific user stake.
     */
    function _updateRewardForStake(address user, uint256 depositId) internal {
        UserStake storage s = stakes[user][depositId];
        if (s.amount == 0) return;

        uint256 earned = _earned(s);
        s.rewards += earned;

        s.rewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @dev Return how many rewards a stake has earned and has claimable.
     */
    function _earned(UserStake memory s) internal view returns (uint256) {
        uint256 rewardPerTokenAcc = rewardPerTokenStored - s.rewardPerTokenPaid;
        uint256 newRewards = s.amountWithBoost * (rewardPerTokenAcc / ONE);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// ==================================================================================================
// ===========================                USER ERRORS                ============================
// ==================================================================================================
/// These errors represent invalid user input to functions.
///
/// Where appropriate, the invalid value is specified along with constraints.
///
/// These errors can be resolved by callers updating their arguments.

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
 * @notice The caller attempted to call a reward distribution function,
 *         but was not the designated distributor.
 *
 */
error USR_NotDistributor();

// ==================================================================================================
// ===========================                STATE ERRORS               ============================
// ==================================================================================================
/// These errors represent actions that are being prevented due to current contract state.
///
/// These errors do not relate to user input, and may or may not be resolved by other actions
///     or the progression of time.

/**
 * @notice The caller attempted to change the epoch length, but current reward epochs were active.
 */
error STATE_RewardsOngoing();

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
 * @notice The owner attempted to place the contract in emergency mode, but emergency
 *         mode was already enabled.
 */
error STATE_AlreadyStopped();

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
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
    event DistributorSet(address indexed distributor, bool isSet);

    // ===================== Structs ======================

    enum Lock {
        short,
        medium,
        long
    }

    struct UserStake {
        uint256 amount;
        uint256 amountWithBoost;
        uint256 rewardPerTokenPaid;
        uint256 rewards;
        uint256 unbondTimestamp;
        Lock lock;
    }

    // ============== Public State Variables ==============

    function stakingToken() external returns (ERC20);

    function distributionToken() external returns (ERC20);

    function epochDuration() external returns (uint256);

    function minimumDeposit() external returns (uint256);

    function endTimestamp() external returns (uint256);

    function totalDeposits() external returns (uint256);

    function totalDepositsWithBoost() external returns (uint256);

    function rewardRate() external returns (uint256);

    function rewardPerTokenStored() external returns (uint256);

    function paused() external returns (bool);

    function ended() external returns (bool);

    function claimable() external returns (bool);

    function isRewardDistributor(address user) external returns (bool);

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

    function setRewardsDistribution(address _rewardsDistribution, bool _set) external;

    function setMinimumDeposit(uint256 _minimum) external;

    function setPaused(bool _paused) external;

    function emergencyStop(bool makeRewardsClaimable) external;

    // ================ View Functions ================

    function latestRewardsTimestamp() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function numStakes(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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