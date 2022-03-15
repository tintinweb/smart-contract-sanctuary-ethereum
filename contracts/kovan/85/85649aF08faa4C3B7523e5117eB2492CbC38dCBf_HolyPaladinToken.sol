// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../open-zeppelin/ERC20.sol";
import "../open-zeppelin/utils/ReentrancyGuard.sol";
import "../open-zeppelin/utils/Ownable.sol";
import "../open-zeppelin/interfaces/IERC20.sol";
import "../open-zeppelin/libraries/SafeERC20.sol";
import "../open-zeppelin/utils/Math.sol";

/** @title Holy Paladin Token (hPAL) contract  */
/// @author Paladin
contract HolyPaladinToken is ERC20("Holy Paladin Token", "hPAL"), Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;


    /** @notice Seconds in a Week */
    uint256 public constant WEEK = 604800;
    /** @notice Seconds in a Month */
    uint256 public constant MONTH = 2629800;
    /** @notice 1e18 scale */
    uint256 public constant UNIT = 1e18;
    /** @notice Max BPS value (100%) */
    uint256 public constant MAX_BPS = 10000;
    /** @notice Seconds in a Year */
    uint256 public constant ONE_YEAR = 31557600;

    // Period to wait before unstaking tokens
    uint256 public constant COOLDOWN_PERIOD = 864000; // 10 days
    // Duration of the unstaking period
    // After that period, unstaking cooldown is expired
    uint256 public constant UNSTAKE_PERIOD = 432000; // 5 days

    // Period to unlock/re-lock tokens without possibility of punishement 
    uint256 public constant UNLOCK_DELAY = 1209600; // 2 weeks

    // Minimum duration of a Lock
    uint256 public constant MIN_LOCK_DURATION = 7889400; // 3 months
    // Maximum duration of a Lock
    uint256 public constant MAX_LOCK_DURATION = 63115200; // 2 years

    // Address of the PAL token
    IERC20 public immutable pal;

    struct UserLock {
        // Amount of locked balance
        uint128 amount; // safe because PAL max supply is 10M tokens
        // Start of the Lock
        uint48 startTimestamp;
        // Duration of the Lock
        uint48 duration;
        // BlockNumber for the Lock
        uint32 fromBlock; // because we want to search by block number
    }

    // Array of all user Locks, ordered from oldest to newest
    mapping(address => UserLock[]) public userLocks;

    struct TotalLock {
        // Total locked Supply
        uint224 total;
        // BlockNumber for the last update
        uint32 fromBlock;
    }

    // Current Total locked Supply
    uint256 public currentTotalLocked;
    // List of TotalLocks, ordered from oldest to newest
    TotalLock[] public totalLocks;

    // User Cooldowns
    mapping(address => uint256) public cooldowns;

    // Checkpoints for users votes
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    // Checkpoints for users Delegates
    struct DelegateCheckpoint {
        uint32 fromBlock;
        address delegate;
    }

    // Delegator => Delegatee
    mapping(address => address) public delegates;

    // List of Vote checkpoints for each user
    mapping(address => Checkpoint[]) public checkpoints;

    // List of Delegate checkpoints for each user
    mapping(address => DelegateCheckpoint[]) public delegateCheckpoints;

    // Ratio (in BPS) of locked balance applied of penalty for each week over lock end
    uint256 public kickRatioPerWeek = 1000;

    // Ratio of bonus votes applied on user locked balance
    uint256 public bonusLockVoteRatio = 0.5e18;

    // Allow emergency withdraws
    bool public emergency = false;

    // Address of the vault holding the PAL rewards
    address public immutable rewardsVault;

    // Global reward index
    uint256 public rewardIndex;
    // Timstamp of last update for global reward index
    uint256 public lastRewardUpdate;

    // Amount of rewards distriubted per second at the start
    uint256 public immutable startDropPerSecond;
    // Amount of rewards distributed per second at the end of the decrease duration
    uint256 public endDropPerSecond;
    // Current amount of rewards distriubted per second
    uint256 public currentDropPerSecond;
    // Timestamp of last update for currentDropPerSecond
    uint256 public lastDropUpdate;
    // Duration (in seconds) of the DropPerSecond decrease period
    uint256 public immutable dropDecreaseDuration;
    // Timestamp: start of the DropPerSecond decrease period
    uint256 public immutable startDropTimestamp;

    // Last reward index for each user
    mapping(address => uint256) public userRewardIndex;
    // Current amount of rewards claimable for the user
    mapping(address => uint256) public claimableRewards;
    // Timestamp of last update for user rewards
    mapping(address => uint256) public rewardsLastUpdate;

    // base reward multiplier for minimum lock duration
    uint256 public immutable baseLockBonusRatio;
    // maximum reward multiplier for maximum duration
    uint256 public immutable maxLockBonusRatio;


    // Event

    event Stake(address indexed user, uint256 amount);

    event Unstake(address indexed user, uint256 amount);

    event Cooldown(address indexed user);

    event Lock(address indexed user, uint256 amount, uint256 indexed startTimestamp, uint256 indexed duration, uint256 totalLocked);

    event Unlock(address indexed user, uint256 amount, uint256 totalLocked);

    event Kick(address indexed user, address indexed kicker, uint256 amount, uint256 penalty, uint256 totalLocked);

    event ClaimRewards(address indexed user, uint256 amount);

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    event EmergencyUnstake(address indexed user, uint256 amount);

    constructor(
        address palToken,
        address _admin,
        address _rewardsVault,
        uint256 _startDropPerSecond,
        uint256 _endDropPerSecond,
        uint256 _dropDecreaseDuration,
        uint256 _baseLockBonusRatio,
        uint256 _maxLockBonusRatio
    ){
        require(palToken != address(0));
        require(_admin != address(0));

        pal = IERC20(palToken);

        transferOwnership(_admin);

        totalLocks.push(TotalLock(
            0,
            safe32(block.number)
        ));
        // Set the immutable variables
        rewardsVault = _rewardsVault;

        startDropPerSecond = _startDropPerSecond;
        endDropPerSecond = _endDropPerSecond;

        currentDropPerSecond = _startDropPerSecond;

        dropDecreaseDuration = _dropDecreaseDuration;

        baseLockBonusRatio = _baseLockBonusRatio;
        maxLockBonusRatio = _maxLockBonusRatio;

        // Set all update timestamp as contract creation timestamp
        lastRewardUpdate = block.timestamp;
        lastDropUpdate = block.timestamp;
        // Start the reward distribution & DropPerSecond decrease
        startDropTimestamp = block.timestamp;
    }



    function stake(uint256 amount) external nonReentrant returns(uint256) {
        return _stake(msg.sender, amount);
    }

    function cooldown() external nonReentrant {
        require(balanceOf(msg.sender) > 0, "hPAL: No balance");

        // Set the current timestamp as start of the user cooldown
        cooldowns[msg.sender] = block.timestamp;

        emit Cooldown(msg.sender);
    }

    function unstake(uint256 amount, address receiver) external nonReentrant returns(uint256) {
        return _unstake(msg.sender, amount, receiver);
    }

    function lock(uint256 amount, uint256 duration) external nonReentrant {
        // Update user rewards before any change on their balance (staked and locked)
        _updateUserRewards(msg.sender);
        if(delegates[msg.sender] == address(0)){
            // If the user does not deelegate currently, automatically self-delegate
            _delegate(msg.sender, msg.sender);
        }
        _lock(msg.sender, amount, duration, LockAction.LOCK);
    }

    function increaseLockDuration(uint256 duration) external nonReentrant {
        require(userLocks[msg.sender].length != 0, "hPAL: No Lock");
        // Find the current Lock
        uint256 currentUserLockIndex = userLocks[msg.sender].length - 1;
        UserLock storage currentUserLock = userLocks[msg.sender][currentUserLockIndex];
        // Update user rewards before any change on their balance (staked and locked)
        _updateUserRewards(msg.sender);
        // Call the _lock method with the current amount, and the new duration
        _lock(msg.sender, currentUserLock.amount, duration, LockAction.INCREASE_DURATION);
    }

    function increaseLock(uint256 amount) external nonReentrant {
        require(userLocks[msg.sender].length != 0, "hPAL: No Lock");
        // Find the current Lock
        uint256 currentUserLockIndex = userLocks[msg.sender].length - 1;
        UserLock storage currentUserLock = userLocks[msg.sender][currentUserLockIndex];
        // Update user rewards before any change on their balance (staked and locked)
        _updateUserRewards(msg.sender);
        // Call the _lock method with the current duration, and the new amount
        _lock(msg.sender, amount, currentUserLock.duration, LockAction.INCREASE_AMOUNT);
    }

    function unlock() external nonReentrant {
        require(userLocks[msg.sender].length != 0, "hPAL: No Lock");
        // Update user rewards before any change on their balance (staked and locked)
        _updateUserRewards(msg.sender);
        _unlock(msg.sender);
    }

    function kick(address user) external nonReentrant {
        require(msg.sender != user, "hPAL: cannot kick yourself");
        // Update user rewards before any change on their balance (staked and locked)
        // For both the user and the kicker
        _updateUserRewards(user);
        _updateUserRewards(msg.sender);
        _kick(user, msg.sender);
    }

    function stakeAndLock(uint256 amount, uint256 duration) external nonReentrant returns(uint256) {
        // Stake the given amount
        uint256 stakedAmount = _stake(msg.sender, amount);
        // No need to update user rewards since it's done through the _stake() method
        if(delegates[msg.sender] == address(0)){
            _delegate(msg.sender, msg.sender);
        }
        // And then lock it
        _lock(msg.sender, amount, duration, LockAction.LOCK);
        return stakedAmount;
    }

    function stakeAndIncreaseLock(uint256 amount, uint256 duration) external nonReentrant returns(uint256) {
        require(userLocks[msg.sender].length != 0, "hPAL: No Lock");
        // Find the current Lock
        uint256 currentUserLockIndex = userLocks[msg.sender].length - 1;
        uint256 previousLockAmount = userLocks[msg.sender][currentUserLockIndex].amount;
        // Stake the new amount
        uint256 stakedAmount = _stake(msg.sender, amount);
        // No need to update user rewards since it's done through the _stake() method
        if(delegates[msg.sender] == address(0)){
            _delegate(msg.sender, msg.sender);
        }
        // Then update the lock with the new increased amount
        _lock(msg.sender, previousLockAmount + amount, duration, LockAction.INCREASE_AMOUNT);
        return stakedAmount;
    }

    function delegate(address delegatee) external virtual {
        return _delegate(_msgSender(), delegatee);
    }

    function claim(uint256 amount) external nonReentrant {
        _claim(msg.sender, amount);
    }

    function updateRewardState() external nonReentrant{
        _updateRewardState();
    }

    function updateUserRewardState(address user) external nonReentrant{
        _updateUserRewards(user);
    }

    // ---------------

    // Find the new cooldown for the receiver depending on the sender and the amount
    function getNewReceiverCooldown(address sender, address receiver, uint256 amount) external view returns(uint256) {
        uint256 senderCooldown = cooldowns[sender];
        uint256 receiverBalance = balanceOf(receiver);

        return _getNewReceiverCooldown(
            senderCooldown,
            amount,
            receiver,
            receiverBalance
        );
    }

    // Get the total number of Locks for an user
    function getUserLockCount(address user) external view returns(uint256) {
        return userLocks[user].length;
    }

    // Get the current user Lock
    function getUserLock(address user) external view returns(UserLock memory) {
        uint256 lastUserLockIndex = userLocks[user].length - 1;
        return userLocks[user][lastUserLockIndex];
    }

    // Get the user Lock at a given block (returns empty Lock if not existing / block number too old)
    function getUserPastLock(address user, uint256 blockNumber) external view returns(UserLock memory) {
        return _getPastLock(user, blockNumber);
    }

    // Get the total count of TotalLock
    function getTotalLockLength() external view returns(uint256){
        return totalLocks.length;
    }

    // Get the latest TotalLock
    function getCurrentTotalLock() external view returns(TotalLock memory){
        return totalLocks[totalLocks.length - 1];
    }

    // Get the TotalLock at a given block
    function getPastTotalLock(uint256 blockNumber) external view returns(TotalLock memory) {
        return _getPastTotalLock(blockNumber);
    }

    // Get the user avaialble balance (staked - locked)
    function availableBalanceOf(address user) external view returns(uint256) {
        return _availableBalanceOf(user);
    }

    // Get all user balances
    function allBalancesOf(address user) external view returns(
        uint256 staked,
        uint256 locked,
        uint256 available
    ) {
        // If the user has no Lock
        // then available == staked
        if(userLocks[user].length == 0) {
            return(
                balanceOf(user),
                0,
                balanceOf(user)
            );
        }
        // If a Lock exists
        // Then return
        // total staked balance
        // locked balance
        // available balance (staked - locked)
        uint256 lastUserLockIndex = userLocks[user].length - 1;
        return(
            balanceOf(user),
            uint256(userLocks[user][lastUserLockIndex].amount),
            balanceOf(user) - uint256(userLocks[user][lastUserLockIndex].amount)
        );
    }

    function estimateClaimableRewards(address user) external view returns(uint256) {
        // no rewards for address 0x0
        if(user == address(0)) return 0;
        // If the user rewards where updated on that block, then return the last updated value
        if(rewardsLastUpdate[user] == block.timestamp) return claimableRewards[user];

        // Get the user current claimable amount
        uint256 estimatedClaimableRewards = claimableRewards[user];
        // Get the last updated reward index
        uint256 currentRewardIndex = rewardIndex;

        if(lastRewardUpdate < block.timestamp){
            // If needed, update the reward index
            currentRewardIndex = _getNewIndex(currentDropPerSecond);
        }

        estimatedClaimableRewards += _getUserAccruedRewards(user, currentRewardIndex);

        return estimatedClaimableRewards;
    }

    // current number of vote checkpoints for the user
    function numCheckpoints(address account) external view virtual returns (uint256){
        return checkpoints[account].length;
    }

    // Get the user current voting power (with bonus voting power from the Lock)
    function getCurrentVotes(address user) external view returns (uint256) {
        uint256 nbCheckpoints = checkpoints[user].length;
        // current votes with delegation
        uint256 currentVotes = nbCheckpoints == 0 ? 0 : checkpoints[user][nbCheckpoints - 1].votes;

        // check if user has a lock
        uint256 nbLocks = userLocks[user].length;

        if(nbLocks == 0) return currentVotes;

        // and if there is a lock, and user self-delegate, add the bonus voting power 
        uint256 lockAmount = userLocks[user][nbLocks - 1].amount;
        uint256 bonusVotes = delegates[user] == user && userLocks[user][nbLocks - 1].duration >= ONE_YEAR ? (lockAmount * bonusLockVoteRatio) / UNIT : 0;

        return currentVotes + bonusVotes;
    }

    // Get the user voting power for a given block (with bonus voting power from the Lock)
    function getPastVotes(address user, uint256 blockNumber) external view returns(uint256) {
        // votes with delegation for the given block
        uint256 votes = _getPastVotes(user, blockNumber);


        // check if user has a lock at that block
        UserLock memory pastLock = _getPastLock(user, blockNumber);
        // and if there is a lock, and user self-delegated, add the bonus voting power 
        uint256 bonusVotes = getPastDelegate(user, blockNumber) == user && pastLock.duration >= ONE_YEAR ? (pastLock.amount * bonusLockVoteRatio) / UNIT : 0;

        return votes + bonusVotes;
    }

    // find the user delegate at a given block
    function getPastDelegate(address account, uint256 blockNumber)
        public
        view
        returns (address)
    {
        require(
            blockNumber < block.number,
            "hPAL: invalid blockNumber"
        );

        // no checkpoints written
        uint256 nbCheckpoints = delegateCheckpoints[account].length;
        if (nbCheckpoints == 0) return address(0);

        // last checkpoint check
        if (delegateCheckpoints[account][nbCheckpoints - 1].fromBlock <= blockNumber) {
            return delegateCheckpoints[account][nbCheckpoints - 1].delegate;
        }

        // no checkpoint old enough
        if (delegateCheckpoints[account][0].fromBlock > blockNumber) {
            return address(0);
        }

        uint256 high = nbCheckpoints - 1; // last checkpoint already checked
        uint256 low = 0;
        uint256 mid;
        while (low < high) {
            mid = Math.average(low, high);
            if (delegateCheckpoints[account][mid].fromBlock == blockNumber) {
                return delegateCheckpoints[account][mid].delegate;
            }
            if (delegateCheckpoints[account][mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? address(0) : delegateCheckpoints[account][high - 1].delegate;
    }

    // ----------------

    // Find the user available balance (staked - locked) => the balance that can be transfered
    function _availableBalanceOf(address user) internal view returns(uint256) {
        if(userLocks[user].length == 0) return balanceOf(user);
        uint256 lastUserLockIndex = userLocks[user].length - 1;
        return balanceOf(user) - uint256(userLocks[user][lastUserLockIndex].amount);
    }

    // Update dropPerSecond value
    function _updateDropPerSecond() internal returns (uint256){
        // If no more need for monthly updates => decrease duration is over
        if(block.timestamp > startDropTimestamp + dropDecreaseDuration) {
            // Set the current DropPerSecond as the end value
            // Plus allows to be updated if the end value is later updated
            if(currentDropPerSecond != endDropPerSecond) {
                currentDropPerSecond = endDropPerSecond;
                lastDropUpdate = block.timestamp;
            }

            return endDropPerSecond;
        }

        if(block.timestamp < lastDropUpdate + MONTH) return currentDropPerSecond; // Update it once a month

        uint256 dropDecreasePerMonth = (startDropPerSecond - endDropPerSecond) / (dropDecreaseDuration / MONTH);
        uint256 nbMonthEllapsed = (block.timestamp - lastDropUpdate) / MONTH;

        uint256 dropPerSecondDecrease = dropDecreasePerMonth * nbMonthEllapsed;

        // We calculate the new dropPerSecond value
        // We don't want to go under the endDropPerSecond
        uint256 newDropPerSecond = currentDropPerSecond - dropPerSecondDecrease > endDropPerSecond ? currentDropPerSecond - dropPerSecondDecrease : endDropPerSecond;
    
        currentDropPerSecond = newDropPerSecond;
        lastDropUpdate = block.timestamp;

        return newDropPerSecond;
    }

    function _getNewIndex(uint256 _currentDropPerSecond) internal view returns (uint256){
        // Get the current total Supply
        uint256 currentTotalSupply = totalSupply();
        // and the seconds since the last update
        uint256 ellapsedTime = block.timestamp - lastRewardUpdate;

        // DropPerSeond without any multiplier => the base dropPerSecond for stakers
        // The multiplier for LockedBalance is applied later, accruing more rewards depending on the Lock.
        uint256 baseDropPerSecond = (_currentDropPerSecond * UNIT) / maxLockBonusRatio;

        // total base reward (without multiplier) to be distributed since last update
        uint256 accruedBaseAmount = ellapsedTime * baseDropPerSecond;

         // calculate the ratio to add to the index
        uint256 ratio = currentTotalSupply > 0 ? (accruedBaseAmount * UNIT) / currentTotalSupply : 0;

        return rewardIndex + ratio;
    }

    // Update global reward state internal
    function _updateRewardState() internal returns (uint256){
        if(lastRewardUpdate == block.timestamp) return rewardIndex; // Already updated for this block

        // Update (if needed) & get the current DropPerSecond
        uint256 _currentDropPerSecond = _updateDropPerSecond();

        // Update the index
        uint256 newIndex = _getNewIndex(_currentDropPerSecond);
        rewardIndex = newIndex;
        lastRewardUpdate = block.timestamp;

        return newIndex;
    }

    function _getUserAccruedRewards(address user, uint256 currentRewardsIndex) internal view returns(uint256 accruedRewards) {
        // Find the user last index & current balances
        uint256 userLastIndex = userRewardIndex[user];
        uint256 userStakedBalance = _availableBalanceOf(user);
        uint256 userLockedBalance = 0;

        if(userLastIndex != currentRewardsIndex){

            if(balanceOf(user) > 0){
                // calculate the base rewards for the user staked balance
                // (using avaialable balance to count the locked balance with the multiplier later in this function)
                uint256 indexDiff = currentRewardsIndex - userLastIndex;

                uint256 stakingRewards = (userStakedBalance * indexDiff) / UNIT;

                uint256 lockingRewards = 0;

                if(userLocks[user].length > 0){
                    // and if an user has a lock, calculate the locked rewards
                    uint256 lastUserLockIndex = userLocks[user].length - 1;

                    // using the locked balance, and the lock duration
                    userLockedBalance = uint256(userLocks[user][lastUserLockIndex].amount);
                    uint256 userLockedDuration = uint256(userLocks[user][lastUserLockIndex].duration);

                    // Check that the user's Lock is not empty
                    if(userLockedBalance > 0 && userLockedDuration != 0){

                        // find the reward multiplier based on the user lock duration
                        uint256 durationRatio = ((userLockedDuration - MIN_LOCK_DURATION) * UNIT) / (MAX_LOCK_DURATION - MIN_LOCK_DURATION);
                        uint256 userLockBonusRatio = baseLockBonusRatio + (((maxLockBonusRatio - baseLockBonusRatio) * durationRatio) / UNIT);

                        // and calculate the locking rewards based on the locked balance & the bonus ratio
                        lockingRewards = (userLockedBalance * ((indexDiff * userLockBonusRatio) / UNIT)) / UNIT;
                    }

                }
                // sum up the accrued rewards, and return it
                accruedRewards = stakingRewards + lockingRewards;
            }
        }
    }

    // Update user reward state internal
    function _updateUserRewards(address user) internal {
        // Update the global reward state and get the latest index
        uint256 newIndex = _updateRewardState();

        // Called for minting & burning, but we don't want to update for address 0x0
        if(user == address(0)) return;

        if(rewardsLastUpdate[user] == block.timestamp) return; // Already updated for this block

        // Update the user claimable rewards
        claimableRewards[user] += _getUserAccruedRewards(user, newIndex);
        
        // and set the current timestamp for last update, and the last used index for the user rewards
        rewardsLastUpdate[user] = block.timestamp;
        userRewardIndex[user] = newIndex;

    }

    /** @dev Hook called before any transfer */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if(from != address(0)) { //check must be skipped on minting
            // Only allow the balance that is unlocked to be transfered
            require(amount <= _availableBalanceOf(from), "hPAL: Available balance too low");
        }

        // Update user rewards before any change on their balance (staked and locked)
        _updateUserRewards(from);

        uint256 fromCooldown = cooldowns[from]; //If from is address 0x00...0, cooldown is always 0 

        if(from != to) {
            // Update user rewards before any change on their balance (staked and locked)
            _updateUserRewards(to);
            // => we don't want a self-transfer to double count new claimable rewards
            // + no need to update the cooldown on a self-transfer

            uint256 previousToBalance = balanceOf(to);
            cooldowns[to] = _getNewReceiverCooldown(fromCooldown, amount, to, previousToBalance);
        }

        // If from transfer all of its balance, reset the cooldown to 0
        uint256 previousFromBalance = balanceOf(from);
        if(previousFromBalance == amount && fromCooldown != 0) {
            cooldowns[from] = 0;
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // update delegation for the sender & the receiver if they delegate
        _moveDelegates(delegates[from], delegates[to], amount);
    }

    function _getPastLock(address account, uint256 blockNumber) internal view returns(UserLock memory) {
        require(
            blockNumber < block.number,
            "hPAL: invalid blockNumber"
        );

        UserLock memory emptyLock = UserLock(
            0,
            0,
            0,
            0
        );

        // no checkpoints written
        uint256 nbCheckpoints = userLocks[account].length;
        if (nbCheckpoints == 0) return emptyLock;

        // last checkpoint check
        if (userLocks[account][nbCheckpoints - 1].fromBlock <= blockNumber) {
            return userLocks[account][nbCheckpoints - 1];
        }

        // no checkpoint old enough
        if (userLocks[account][0].fromBlock > blockNumber) {
            return emptyLock;
        }

        uint256 high = nbCheckpoints - 1; // last checkpoint already checked
        uint256 low = 0;
        uint256 mid;
        while (low < high) {
            mid = Math.average(low, high);
            if (userLocks[account][mid].fromBlock == blockNumber) {
                return userLocks[account][mid];
            }
            if (userLocks[account][mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? emptyLock : userLocks[account][high - 1];
    }

    function _getPastTotalLock(uint256 blockNumber) internal view returns(TotalLock memory) {
        require(
            blockNumber < block.number,
            "hPAL: invalid blockNumber"
        );

        TotalLock memory emptyLock = TotalLock(
            0,
            0
        );

        uint256 nbCheckpoints = totalLocks.length;

        // last checkpoint check
        if (totalLocks[nbCheckpoints - 1].fromBlock <= blockNumber) {
            return totalLocks[nbCheckpoints - 1];
        }

        // no checkpoint old enough
        if (totalLocks[0].fromBlock > blockNumber) {
            return emptyLock;
        }

        uint256 high = nbCheckpoints - 1; // last checkpoint already checked
        uint256 low = 0;
        uint256 mid;
        while (low < high) {
            mid = Math.average(low, high);
            if (totalLocks[mid].fromBlock == blockNumber) {
                return totalLocks[mid];
            }
            if (totalLocks[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? emptyLock : totalLocks[high - 1];
    }

    function _getPastVotes(address account, uint256 blockNumber) internal view returns (uint256){
        require( blockNumber < block.number, "hPAL: invalid blockNumber");

        // no checkpoints written
        uint256 nbCheckpoints = checkpoints[account].length;
        if (nbCheckpoints == 0) return 0;

        // last checkpoint check
        if (checkpoints[account][nbCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nbCheckpoints - 1].votes;
        }

        // no checkpoint old enough
        if (checkpoints[account][0].fromBlock > blockNumber) return 0;

        uint256 high = nbCheckpoints - 1; // last checkpoint already checked
        uint256 low = 0;
        uint256 mid;
        while (low < high) {
            mid = Math.average(low, high);
            if (checkpoints[account][mid].fromBlock == blockNumber) {
                return checkpoints[account][mid].votes;
            }
            if (checkpoints[account][mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : checkpoints[account][high - 1].votes;
    }

    function _getPastDelegate(address account, uint256 blockNumber) internal view returns (address) {
        require(blockNumber < block.number, "hPAL: invalid blockNumber");

        // no checkpoints written
        uint256 nbCheckpoints = delegateCheckpoints[account].length;
        if (nbCheckpoints == 0) return address(0);

        // last checkpoint check
        if (delegateCheckpoints[account][nbCheckpoints - 1].fromBlock <= blockNumber) {
            return delegateCheckpoints[account][nbCheckpoints - 1].delegate;
        }

        // no checkpoint old enough
        if (delegateCheckpoints[account][0].fromBlock > blockNumber) return address(0);

        uint256 high = nbCheckpoints - 1; // last checkpoint already checked
        uint256 low = 0;
        uint256 mid;
        while (low < high) {
            mid = Math.average(low, high);
            if (delegateCheckpoints[account][mid].fromBlock == blockNumber) {
                return delegateCheckpoints[account][mid].delegate;
            }
            if (delegateCheckpoints[account][mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? address(0) : delegateCheckpoints[account][high - 1].delegate;
    }

    function _moveDelegates(address from, address to, uint256 amount) internal {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                // Calculate the change in voting power, then write a new checkpoint
                uint256 nbCheckpoints = checkpoints[from].length;
                uint256 oldVotes = nbCheckpoints == 0 ? 0 : checkpoints[from][nbCheckpoints - 1].votes;
                uint256 newVotes = oldVotes - amount;
                _writeCheckpoint(from, newVotes);
                emit DelegateVotesChanged(from, oldVotes, newVotes);
            }

            if (to != address(0)) {
                // Calculate the change in voting power, then write a new checkpoint
                uint256 nbCheckpoints = checkpoints[to].length;
                uint256 oldVotes = nbCheckpoints == 0 ? 0 : checkpoints[to][nbCheckpoints - 1].votes;
                uint256 newVotes = oldVotes + amount;
                _writeCheckpoint(to, newVotes);
                emit DelegateVotesChanged(to, oldVotes, newVotes);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 newVotes) internal {
        // write a new checkpoint for an user
        uint pos = checkpoints[delegatee].length;

        if (pos > 0 && checkpoints[delegatee][pos - 1].fromBlock == block.number) {
            checkpoints[delegatee][pos - 1].votes = safe224(newVotes);
        } else {
            uint32 blockNumber = safe32(block.number);
            checkpoints[delegatee].push(Checkpoint(blockNumber, safe224(newVotes)));
        }
    }

    // -----------------

    function _stake(address user, uint256 amount) internal returns(uint256) {
        require(amount > 0, "hPAL: Null amount");

        // No need to update user rewards here since the _mint() method will trigger _beforeTokenTransfer()
        // Same for the Cooldown update, as it will be handled by _beforeTokenTransfer()    

        _mint(user, amount); //We mint hPAL 1:1 with PAL

        // Pull the PAL into this contract
        pal.safeTransferFrom(user, address(this), amount);

        emit Stake(user, amount);

        return amount;
    }

    function _unstake(address user, uint256 amount, address receiver) internal returns(uint256) {
        require(amount > 0, "hPAL: Null amount");
        require(receiver != address(0), "hPAL: Address Zero");

        // Check if user in inside the allowed period base on its cooldown
        uint256 userCooldown = cooldowns[user];
        require(block.timestamp > (userCooldown + COOLDOWN_PERIOD), "hPAL: Insufficient cooldown");
        require(block.timestamp - (userCooldown + COOLDOWN_PERIOD) <= UNSTAKE_PERIOD, "hPAL: unstake period expired");

        // No need to update user rewards here since the _burn() method will trigger _beforeTokenTransfer()

        // Can only unstake was is available, need to unlock before
        uint256 userAvailableBalance = _availableBalanceOf(user);
        uint256 burnAmount = amount > userAvailableBalance ? userAvailableBalance : amount;

        // Burn the hPAL 1:1 with PAL
        _burn(user, burnAmount);

        // If all the balance is unstaked, cooldown reset is handled by _beforeTokenTransfer()

        // Then transfer the PAL to the user
        pal.safeTransfer(receiver, burnAmount);

        emit Unstake(user, burnAmount);

        return burnAmount;
    }

    // Get the new cooldown for an user receiving hPAL (mint or transfer),
    // based on receiver cooldown and sender cooldown
    // Inspired by stkAAVE cooldown system
    function _getNewReceiverCooldown(
        uint256 senderCooldown,
        uint256 amount,
        address receiver,
        uint256 receiverBalance
    ) internal view returns(uint256) {
        uint256 receiverCooldown = cooldowns[receiver];

        // If receiver has no cooldown, no need to set a new one
        if(receiverCooldown == 0) return 0;

        uint256 minValidCooldown = block.timestamp - (COOLDOWN_PERIOD + UNSTAKE_PERIOD);

        // If last receiver cooldown is expired, set it back to 0
        if(receiverCooldown < minValidCooldown) return 0;

        // In case the given senderCooldown is 0 (sender has no cooldown, or minting)
        uint256 _senderCooldown = senderCooldown < minValidCooldown ? block.timestamp : senderCooldown;

        // If the sender cooldown is better, we keep the receiver cooldown
        if(_senderCooldown < receiverCooldown) return receiverCooldown;

        // Default new cooldown, weighted average based on the amount and the previous balance
        return ((amount * _senderCooldown) + (receiverBalance * receiverCooldown)) / (amount + receiverBalance);

    }

    enum LockAction { LOCK, INCREASE_AMOUNT, INCREASE_DURATION }

    function _lock(address user, uint256 amount, uint256 duration, LockAction action) internal {
        require(user != address(0)); //Never supposed to happen, but security check
        require(amount != 0, "hPAL: Null amount");
        uint256 userBalance = balanceOf(user);
        require(amount <= userBalance, "hPAL: Amount over balance");
        require(duration >= MIN_LOCK_DURATION, "hPAL: Lock duration under min");
        require(duration <= MAX_LOCK_DURATION, "hPAL: Lock duration over max");

        if(userLocks[user].length == 0){
            //User 1st Lock

            userLocks[user].push(UserLock(
                safe128(amount),
                safe48(block.timestamp),
                safe48(duration),
                safe32(block.number)
            ));

            // Update total locked supply
            currentTotalLocked += amount;
            totalLocks.push(TotalLock(
                safe224(currentTotalLocked),
                safe32(block.number)
            ));

            emit Lock(user, amount, block.timestamp, duration, currentTotalLocked);
        } 
        else {
            // Get the current user Lock
            uint256 currentUserLockIndex = userLocks[user].length - 1;
            UserLock storage currentUserLock = userLocks[user][currentUserLockIndex];
            // Calculate the end of the user current lock
            uint256 userCurrentLockEnd = currentUserLock.startTimestamp + currentUserLock.duration;

            uint256 startTimestamp = block.timestamp;

            if(currentUserLock.amount == 0 || userCurrentLockEnd < block.timestamp) { 
                // User locked, and then unlocked
                // or user lock expired

                userLocks[user].push(UserLock(
                    safe128(amount),
                    safe48(startTimestamp),
                    safe48(duration),
                    safe32(block.number)
                ));
            }
            else {
                // Update of the current Lock : increase amount or increase duration
                // or renew with the same parameters, but starting at the current timestamp
                require(amount >=  currentUserLock.amount,"hPAL: smaller amount");
                require(duration >=  currentUserLock.duration,"hPAL: smaller duration");

                // If the method is called with INCREASE_AMOUNT, then we don't change the startTimestamp of the Lock

                userLocks[user].push(UserLock(
                    safe128(amount),
                    action == LockAction.INCREASE_AMOUNT ? currentUserLock.startTimestamp : safe48(startTimestamp),
                    safe48(duration),
                    safe32(block.number)
                ));

                startTimestamp = action == LockAction.INCREASE_AMOUNT ? currentUserLock.startTimestamp : startTimestamp;
            }
            
            // Update total locked supply
            if(amount != currentUserLock.amount){

                if(currentUserLock.amount != 0) currentTotalLocked -= currentUserLock.amount;
                
                currentTotalLocked += amount;
                totalLocks.push(TotalLock(
                    safe224(currentTotalLocked),
                    safe32(block.number)
                ));
            }

            emit Lock(user, amount, startTimestamp, duration, currentTotalLocked);
        }
    }

    function _unlock(address user) internal {
        require(user != address(0)); //Never supposed to happen, but security check
        require(userLocks[user].length > 0, "hPAL: No Lock");

        // Get the user current Lock
        // And calculate the end of the Lock
        uint256 currentUserLockIndex = userLocks[user].length - 1;
        UserLock storage currentUserLock = userLocks[user][currentUserLockIndex];
        uint256 userCurrentLockEnd = currentUserLock.startTimestamp + currentUserLock.duration;

        require(block.timestamp > userCurrentLockEnd, "hPAL: Not expired");
        require(currentUserLock.amount > 0, "hPAL: No Lock");

        // Remove amount from total locked supply
        currentTotalLocked -= currentUserLock.amount;
        totalLocks.push(TotalLock(
            safe224(currentTotalLocked),
            safe32(block.number)
        ));

        // Set the user Lock as an empty Lock
        userLocks[user].push(UserLock(
            safe128(0),
            safe48(block.timestamp),
            safe48(0),
            safe32(block.number)
        ));

        emit Unlock(user, currentUserLock.amount, currentTotalLocked);
    }

    function _kick(address user, address kicker) internal {
        require(user != address(0) && kicker != address(0), "hPAL: Address Zero");
        require(userLocks[user].length > 0, "hPAL: No Lock");

        // Get the user to kick current Lock
        // and calculate the end of the Lock
        uint256 currentUserLockIndex = userLocks[user].length - 1;
        UserLock storage currentUserLock = userLocks[user][currentUserLockIndex];
        uint256 userCurrentLockEnd = currentUserLock.startTimestamp + currentUserLock.duration;

        require(block.timestamp > userCurrentLockEnd, "hPAL: Not expired");
        require(currentUserLock.amount > 0, "hPAL: No Lock");

        require(block.timestamp > userCurrentLockEnd + UNLOCK_DELAY, "hPAL: Not kickable");

        // Remove amount from total locked supply
        currentTotalLocked -= currentUserLock.amount;
        totalLocks.push(TotalLock(
            safe224(currentTotalLocked),
            safe32(block.number)
        ));

        // Set an empty Lock for the user
        userLocks[user].push(UserLock(
            safe128(0),
            safe48(block.timestamp),
            safe48(0),
            safe32(block.number)
        ));

        // Calculate the penalty for the Lock
        uint256 nbWeeksOverLockTime = (block.timestamp - userCurrentLockEnd) / WEEK;
        uint256 penaltyPercent = nbWeeksOverLockTime * kickRatioPerWeek;
        uint256 penaltyAmount = penaltyPercent >= MAX_BPS ? 
            currentUserLock.amount : 
            (currentUserLock.amount * penaltyPercent) / MAX_BPS;

        // Send penalties to the kicker
        _transfer(user, kicker, penaltyAmount);

        emit Kick(user, kicker, currentUserLock.amount, penaltyAmount, currentTotalLocked);
    }

    function _claim(address user, uint256 amount) internal {
        // Update user rewards before any change on their balance (staked and locked)
        _updateUserRewards(user);

        require(amount > 0, "hPAL: incorrect amount");

        // Cannot claim more than accrued rewards, but we can use a higher amount to claim all the rewards
        uint256 claimAmount = amount < claimableRewards[user] ? amount : claimableRewards[user];

        // remove the claimed amount from the claimable mapping for the user, 
        // and transfer the PAL from the rewardsVault to the user
        claimableRewards[user] -= claimAmount;

        pal.safeTransferFrom(rewardsVault, user, claimAmount);

        emit ClaimRewards(user, claimAmount);
    }

    function _delegate(address delegator, address delegatee) internal {
        // Move delegation from the old delegate to the given delegate
        address oldDelegatee = delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        delegates[delegator] = delegatee;

        // update the the Delegate chekpoint for the delegatee
        delegateCheckpoints[delegator].push(DelegateCheckpoint(safe32(block.number), delegatee));

        emit DelegateChanged(delegator, oldDelegatee, delegatee);

        // and write the checkpoints for Votes
        _moveDelegates(oldDelegatee, delegatee, delegatorBalance);
    }

    // Allow to withdraw with override of the lock & cooldown in case of emergency
    function emergencyWithdraw(uint256 amount, address receiver) external nonReentrant returns(uint256) {

        require(emergency, "hPAL: Not emergency");

        require(amount > 0, "hPAL: Null amount");
        require(receiver != address(0), "hPAL: Address Zero");

        if(userLocks[msg.sender].length != 0){
            // Check if the user has a Lock, and if so, fetch it
            uint256 currentUserLockIndex = userLocks[msg.sender].length - 1;
            UserLock storage currentUserLock = userLocks[msg.sender][currentUserLockIndex];

            // To remove the Lock and update the total locked
            currentTotalLocked -= currentUserLock.amount;
            totalLocks.push(TotalLock(
                safe224(currentTotalLocked),
                safe32(block.number)
            ));

            userLocks[msg.sender].push(UserLock(
                safe128(0),
                safe48(block.timestamp),
                safe48(0),
                safe32(block.number)
            ));
        }

        // Get the user hPAL balance, and burn & send the given amount, or the user balance if the amount is bigger
        uint256 userAvailableBalance = balanceOf(msg.sender);
        uint256 burnAmount = amount > userAvailableBalance ? userAvailableBalance : amount;

        _burn(msg.sender, burnAmount);

        // Transfer the PAL to the user
        pal.safeTransfer(receiver, burnAmount);

        emit EmergencyUnstake(msg.sender, burnAmount);

        return burnAmount;

    }

    // Utils

    function safe32(uint n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "hPAL: block number exceed 32 bits");
        return uint32(n);
    }

    function safe48(uint n) internal pure returns (uint48) {
        require(n <= type(uint48).max, "hPAL: block number exceed 48 bits");
        return uint48(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        require(n <= type(uint128).max, "hPAL: amount exceed 128 bits");
        return uint128(n);
    }

    function safe224(uint n) internal pure returns (uint224) {
        require(n <= type(uint224).max, "hPAL: amount exceed 224 bits");
        return uint224(n);
    }

    // Admin methods

    function setKickRatio(uint256 newKickRatioPerWeek) external onlyOwner {
        require(newKickRatioPerWeek > 0 && newKickRatioPerWeek <= 5000, "hPAL: Incorrect parameters");
        kickRatioPerWeek = newKickRatioPerWeek;
    }

    function triggerEmergencyWithdraw(bool trigger) external onlyOwner {
        emergency = trigger;
    }

    function setEndDropPerSecond(uint256 newEndDropPerSecond) external onlyOwner {
        require(block.timestamp >= startDropTimestamp + dropDecreaseDuration ,"hPAL: Drop decrease duration not finished");
        endDropPerSecond = newEndDropPerSecond;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../utils/Address.sol";

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

pragma solidity ^0.8.0;

import "./IERC20.sol";

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