// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
    Based on CVX Staking contract for https://www.convexfinance.com - https://github.com/convex-eth/platform/blob/main/contracts/contracts/CvxLocker.sol
    Changes:
        - upgrade to solidity 0.8.7
        - remove boosted concept
        - remove staking of locked tokens

     *** Locking mechanism ***

    This locking mechanism is based on epochs. An epoch is defined by the `epochDuration`. When locking our tokens,
    the unlock time for this lock period is set to the start of the current running epoch + `lockDuration`.
    The locked tokens of the current epoch are not eligible for voting. Therefore we need to wait for the next
    epoch until we can vote.
    All tokens locked within the same epoch share the same lock and therefore the same unlock time.


    *** Rewards ***

    Rewards are shared between users based on the total amount of locking tokens in the contract. This includes
    tokens which have been locked in the current epoch and also tokens of expired locks. To incentivize people to
    either withdraw their expired locks or re-lock, there is an incentive mechanism to kick out expired locks and
    collect a percentage of the locked tokens in return.
*/

contract FBeetsLocker is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct Epoch {
        uint256 supply; //epoch locked supply
        uint256 startTime; //epoch start date
    }

    IERC20 public immutable lockingToken;

    struct EarnedData {
        address token;
        uint256 amount;
    }

    address[] public rewardTokens;

    struct Reward {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    mapping(address => Reward) public rewardData;

    uint256 public immutable epochDuration;

    uint256 public immutable lockDuration;

    uint256 public constant denominator = 10000;

    // reward token -> distributor -> is approved to add rewards
    mapping(address => mapping(address => bool)) public rewardDistributors;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    uint256 public totalLockedSupply;
    Epoch[] public epochs;

    /*
        We keep the total locked amount and an index to the next unprocessed lock per user.
        All locks previous to this index have been either withdrawn or relocked and can be ignored.
    */

    struct Balances {
        uint256 lockedAmount;
        uint256 nextUnlockIndex;
    }

    mapping(address => Balances) public balances;

    /*
        We keep the amount locked and the unlock time (start epoch + lock duration)
        for each user
    */
    struct LockedBalance {
        uint256 locked;
        uint256 unlockTime;
    }

    mapping(address => LockedBalance[]) public userLocks;

    uint256 public kickRewardPerEpoch = 100;
    uint256 public kickRewardEpochDelay = 4;

    bool public isShutdown = false;

    //erc20-like interface
    string private constant _name = "Locked fBeets Token";
    string private constant _symbol = "lfBeets";
    uint8 private constant _decimals = 18;

    constructor(
        IERC20 _lockingToken,
        uint256 _epochDuration,
        uint256 _lockDuration
    ) {
        require(_lockDuration % _epochDuration == 0, "_epochDuration has to be a multiple of _lockDuration");
        lockingToken = _lockingToken;
        epochDuration = _epochDuration;
        lockDuration = _lockDuration;

        epochs.push(
            Epoch({
                supply: 0,
                startTime: (block.timestamp / _epochDuration) * _epochDuration
            })
        );
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    /// @notice Add a new reward token to be distributed to lockers
    /// @param _rewardToken The rewarded token by the `_distributor`
    /// @param _distributor Address of the reward token sender
    function addReward(address _rewardToken, address _distributor)
        external
        onlyOwner
    {
        require(
            rewardData[_rewardToken].lastUpdateTime == 0,
            "Reward token already added"
        );
        require(
            _rewardToken != address(lockingToken),
            "Rewarding the locking token is not allowed"
        );
        rewardTokens.push(_rewardToken);
        rewardData[_rewardToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardToken].periodFinish = block.timestamp;
        rewardDistributors[_rewardToken][_distributor] = true;
        emit RewardTokenAdded(_rewardToken);
        emit RewardDistributorApprovalChanged(_rewardToken, _distributor, true);
    }

    /// @notice Modify approval for a distributor to call `notifyRewardAmount`
    /// @param _rewardToken Reward token to change distributor approval
    /// @param _distributor Address of reward distributor
    /// @param _approved Flag to white- or blacklist the distributor for this reward token
    function approveRewardDistributor(
        address _rewardToken,
        address _distributor,
        bool _approved
    ) external onlyOwner {
        require(
            rewardData[_rewardToken].lastUpdateTime > 0,
            "Reward token has not been added"
        );
        rewardDistributors[_rewardToken][_distributor] = _approved;
        emit RewardDistributorApprovalChanged(
            _rewardToken,
            _distributor,
            _approved
        );
    }

    /// @notice Set kick incentive after epoch delay has passed
    /// @param _kickRewardPerEpoch incentive per epoch to the base of the `denominator`
    /// @param _kickRewardEpochDelay after how many epochs overdue an expired lock can be kicked out
    function setKickIncentive(
        uint256 _kickRewardPerEpoch,
        uint256 _kickRewardEpochDelay
    ) external onlyOwner {
        require(_kickRewardPerEpoch <= 500, "over max rate of 5% per epoch");
        require(_kickRewardEpochDelay >= 2, "min delay of 2 epochs required");
        kickRewardPerEpoch = _kickRewardPerEpoch;
        kickRewardEpochDelay = _kickRewardEpochDelay;

        emit SetKickIncentive(_kickRewardEpochDelay, _kickRewardPerEpoch);
    }

    /// @notice Shutdown the contract and release all locks
    function shutdown() external onlyOwner {
        isShutdown = true;
    }

    function _rewardPerToken(address _rewardToken)
        internal
        view
        returns (uint256)
    {
        Reward storage reward = rewardData[_rewardToken];

        if (totalLockedSupply == 0) {
            return reward.rewardPerTokenStored;
        }

        uint256 secondsSinceLastApplicableRewardTime = _lastTimeRewardApplicable(
                reward.periodFinish
            ) - reward.lastUpdateTime;
        return
            reward.rewardPerTokenStored +
            (((secondsSinceLastApplicableRewardTime * reward.rewardRate) *
                1e18) / totalLockedSupply);
    }

    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance
    ) internal view returns (uint256) {
        return
            (_balance *
                (_rewardPerToken(_rewardsToken) -
                    userRewardPerTokenPaid[_user][_rewardsToken])) /
            1e18 +
            rewards[_user][_rewardsToken];
    }

    function _lastTimeRewardApplicable(uint256 _finishTime)
        internal
        view
        returns (uint256)
    {
        return Math.min(block.timestamp, _finishTime);
    }

    function lastTimeRewardApplicable(address _rewardsToken)
        external
        view
        returns (uint256)
    {
        return
            _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish);
    }

    /// @notice Returns the rewards gained for the reward period per locked token
    /// @param _rewardToken The address of the reward token
    function rewardPerToken(address _rewardToken)
        external
        view
        returns (uint256)
    {
        return _rewardPerToken(_rewardToken);
    }

    /// @notice Returns rewarded amount for each token for the given address
    /// @param _user User address
    function claimableRewards(address _user)
        external
        view
        returns (EarnedData[] memory userRewards)
    {
        userRewards = new EarnedData[](rewardTokens.length);
        uint256 lockedAmount = balances[_user].lockedAmount;
        for (uint256 i = 0; i < userRewards.length; i++) {
            address token = rewardTokens[i];
            userRewards[i].token = token;
            userRewards[i].amount = _earned(_user, token, lockedAmount);
        }
        return userRewards;
    }

    /// @notice Total token balance of an account, including unlocked but not withdrawn tokens
    /// @param _user User address
    function lockedBalanceOf(address _user)
        external
        view
        returns (uint256 amount)
    {
        return balances[_user].lockedAmount;
    }

    // an epoch is always the timestamp on the start of an epoch
    function _currentEpoch() internal view returns (uint256) {
        return (block.timestamp / epochDuration) * epochDuration;
    }

    /// @notice Balance of an account which only includes properly locked tokens as of the most recent eligible epoch
    /// @param _user User address
    function balanceOf(address _user) external view returns (uint256 amount) {
        LockedBalance[] storage locks = userLocks[_user];
        Balances storage userBalance = balances[_user];
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;

        //start with current locked amount
        amount = balances[_user].lockedAmount;

        uint256 locksLength = locks.length;
        //remove old records only (will be better gas-wise than adding up)
        for (uint256 i = nextUnlockIndex; i < locksLength; i++) {
            if (locks[i].unlockTime <= block.timestamp) {
                amount = amount - locks[i].locked;
            } else {
                //stop now as no further checks are needed
                break;
            }
        }

        //also remove amount in the next (future) epoch
        if (
            locksLength > 0 &&
            locks[locksLength - 1].unlockTime - lockDuration > _currentEpoch()
        ) {
            amount = amount - locks[locksLength - 1].locked;
        }

        return amount;
    }

    /// @notice Balance of an account which only includes properly locked tokens at the given epoch
    /// @param _epoch Epoch index
    /// @param _user User address
    function balanceAtEpochOf(uint256 _epoch, address _user)
        external
        view
        returns (uint256 amount)
    {
        LockedBalance[] storage locks = userLocks[_user];

        //get timestamp of given epoch index
        uint256 epochStartTime = epochs[_epoch].startTime;
        //get timestamp of first non-inclusive epoch
        uint256 cutoffEpoch = epochStartTime - lockDuration;

        //traverse inversely to make more current queries more gas efficient
        uint256 currentLockIndex = locks.length;

        if (currentLockIndex == 0) {
            return 0;
        }
        do {
            currentLockIndex--;

            uint256 lockEpoch = locks[currentLockIndex].unlockTime -
                lockDuration;

            if (lockEpoch <= epochStartTime) {
                if (lockEpoch > cutoffEpoch) {
                    amount += locks[currentLockIndex].locked;
                } else {
                    //stop now as no further checks matter
                    break;
                }
            }
        } while (currentLockIndex > 0);

        return amount;
    }

    /// @notice returns amount of newly locked tokens in the upcoming epoch
    /// @param _user the user to check against
    function pendingLockOf(address _user)
        external
        view
        returns (uint256 amount)
    {
        LockedBalance[] storage locks = userLocks[_user];

        uint256 locksLength = locks.length;

        //return amount if latest lock is in the future
        uint256 currentEpoch = _currentEpoch();
        if (
            locksLength > 0 &&
            locks[locksLength - 1].unlockTime - lockDuration > currentEpoch
        ) {
            return locks[locksLength - 1].locked;
        }

        return 0;
    }

    /// @notice Supply of all properly locked balances at most recent eligible epoch
    function totalSupply() external view returns (uint256 supply) {
        uint256 currentEpoch = _currentEpoch();
        uint256 cutoffEpoch = currentEpoch - lockDuration;
        uint256 epochIndex = epochs.length;
        if (epochIndex == 0) {
            return 0;
        }

        // remove future epoch amount
        if (epochs[epochIndex - 1].startTime > currentEpoch) {
            epochIndex--;
        }

        //traverse inversely to make more current queries more gas efficient
        do {
            epochIndex--;
            Epoch storage epoch = epochs[epochIndex];
            if (epoch.startTime <= cutoffEpoch) {
                break;
            }
            supply += epoch.supply;
        } while (epochIndex > 0);

        return supply;
    }

    /// @notice Supply of all properly locked balances at the given epoch
    /// @param _epochIndex Epoch index
    function totalSupplyAtEpoch(uint256 _epochIndex)
        external
        view
        returns (uint256 supply)
    {
        // if its the first epoch, no locks can be active
        if (_epochIndex == 0) {
            return 0;
        }
        uint256 epochStart = epochs[_epochIndex].startTime;

        uint256 cutoffEpoch = epochStart - lockDuration;
        uint256 currentIndex = _epochIndex;

        //traverse inversely to make more current queries more gas efficient
        do {
            Epoch storage epoch = epochs[currentIndex];
            if (epoch.startTime <= cutoffEpoch) {
                break;
            }
            supply += epochs[currentIndex].supply;
            currentIndex--;
        } while (currentIndex > 0);

        return supply;
    }

    /// @notice Find an epoch index based on timestamp
    /// @param _time Timestamp
    function findEpochId(uint256 _time) external view returns (uint256 epoch) {
        uint256 max = epochs.length - 1;
        uint256 min = 0;

        //convert to start point
        _time = (_time / epochDuration) * epochDuration;

        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) break;

            uint256 mid = (min + max + 1) / 2;
            uint256 midEpochBlock = epochs[mid].startTime;
            if (midEpochBlock == _time) {
                //found
                return mid;
            } else if (midEpochBlock < _time) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    /// @notice Information on a user's locked balances per locking period
    /// @param _user User address
    function lockedBalances(address _user)
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        )
    {
        LockedBalance[] storage locks = userLocks[_user];
        Balances storage userBalance = balances[_user];
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
        uint256 idx;
        for (uint256 i = nextUnlockIndex; i < locks.length; i++) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                locked += locks[i].locked;
            } else {
                unlockable += locks[i].locked;
            }
        }
        return (userBalance.lockedAmount, unlockable, locked, lockData);
    }

    /// @notice Total number of epochs
    function epochCount() external view returns (uint256) {
        return epochs.length;
    }

    /// @notice Fills in any missing epochs until current epoch
    function checkpointEpoch() external {
        _checkpointEpoch();
    }

    //insert a new epoch if needed. fill in any gaps
    function _checkpointEpoch() internal {
        //create new epoch in the future where new non-active locks will lock to
        uint256 nextEpoch = _currentEpoch() + epochDuration;

        //check to add
        //first epoch add in constructor, no need to check 0 length
        if (epochs[epochs.length - 1].startTime < nextEpoch) {
            //fill any epoch gaps
            while (epochs[epochs.length - 1].startTime != nextEpoch) {
                uint256 nextEpochDate = epochs[epochs.length - 1].startTime +
                    epochDuration;
                epochs.push(Epoch({supply: 0, startTime: nextEpochDate}));
            }
        }
    }

    /// @notice Lockes `_amount` tokens from `_user` for lockDuration and are eligible to receive stakingReward rewards
    /// @param _user User to lock tokens from
    /// @param _amount Amount to lock
    function lock(address _user, uint256 _amount)
        external
        nonReentrant
        updateReward(_user)
    {
        //pull tokens
        lockingToken.safeTransferFrom(msg.sender, address(this), _amount);

        //lock
        _lock(_user, _amount, false);
    }

    function _lock(
        address _account,
        uint256 _amount,
        bool _relock
    ) internal {
        require(_amount > 0, "Cannot lock 0 tokens");
        require(!isShutdown, "Contract is in shutdown");

        Balances storage userBalance = balances[_account];

        //must try check pointing epoch first
        _checkpointEpoch();

        //add user balances
        userBalance.lockedAmount += _amount;
        //add to total supplies
        totalLockedSupply += _amount;

        //add user lock records or add to current
        uint256 lockStartEpoch = _currentEpoch();
        if (!_relock) {
            lockStartEpoch += epochDuration;
        }
        uint256 unlockTime = lockStartEpoch + lockDuration; // lock duration = 16 weeks + current week = 17 weeks

        uint256 idx = userLocks[_account].length;
        // if its the first lock or the last lock has shorter unlock time than this lock
        if (idx == 0 || userLocks[_account][idx - 1].unlockTime < unlockTime) {
            userLocks[_account].push(
                LockedBalance({locked: _amount, unlockTime: unlockTime})
            );
        } else {
            //if latest lock is further in the future, lower index
            //this can only happen if relocking an expired lock after creating a new lock
            if (userLocks[_account][idx - 1].unlockTime > unlockTime) {
                idx--;
            }

            //if idx points to the epoch when same unlock time, update
            //(this is always true with a normal lock but maybe not with relock)
            if (userLocks[_account][idx - 1].unlockTime == unlockTime) {
                LockedBalance storage userLock = userLocks[_account][idx - 1];
                userLock.locked += _amount;
            } else {
                //can only enter here if a relock is made after a lock and there's no lock entry
                //for the current epoch.
                //ex a list of locks such as "[...][older][current*][next]" but without a "current" lock
                //length - 1 is the next epoch
                //length - 2 is a past epoch
                //thus need to insert an entry for current epoch at the 2nd to last entry
                //we will copy and insert the tail entry(next) and then overwrite length-2 entry

                //reset idx
                idx = userLocks[_account].length;

                //get current last item
                LockedBalance storage userLock = userLocks[_account][idx - 1];

                //add a copy to end of list
                userLocks[_account].push(
                    LockedBalance({
                        locked: userLock.locked,
                        unlockTime: userLock.unlockTime
                    })
                );

                //insert current epoch lock entry by overwriting the entry at length-2
                userLock.locked = _amount;
                userLock.unlockTime = unlockTime;
            }
        }

        //update epoch supply, epoch checkpointed above so safe to add to latest
        uint256 epochIndex = epochs.length - 1;
        //if relock, epoch should be current and not next, thus need to decrease index to length-2
        if (_relock) {
            epochIndex--;
        }
        Epoch storage currentEpoch = epochs[epochIndex];
        currentEpoch.supply += _amount;

        emit Locked(_account, _amount, lockStartEpoch);
    }

    /// @notice Withdraw all currently locked tokens where the unlock time has passed
    function _processExpiredLocks(
        address _account,
        bool _relock,
        address _withdrawTo,
        address _rewardAddress,
        uint256 _checkDelay
    ) internal updateReward(_account) {
        LockedBalance[] storage locks = userLocks[_account];
        Balances storage userBalance = balances[_account];
        uint256 unlockedAmount;
        uint256 totalLocks = locks.length;
        uint256 reward = 0;

        require(totalLocks > 0, "Account has no locks");
        //if time is beyond last lock, can just bundle everything together
        if (
            isShutdown ||
            locks[totalLocks - 1].unlockTime <= block.timestamp - _checkDelay
        ) {
            unlockedAmount = userBalance.lockedAmount;

            //dont delete, just set next index
            userBalance.nextUnlockIndex = totalLocks;

            //check for kick reward
            //this wont have the exact reward rate that you would get if looped through
            //but this section is supposed to be for quick and easy low gas processing of all locks
            //we'll assume that if the reward was good enough someone would have processed at an earlier epoch
            if (_checkDelay > 0) {
                uint256 currentEpoch = ((block.timestamp - _checkDelay) /
                    epochDuration) * epochDuration;

                uint256 overdueEpochCount = (currentEpoch -
                    locks[totalLocks - 1].unlockTime) / epochDuration;

                uint256 rewardRate = Math.min(
                    kickRewardPerEpoch * (overdueEpochCount + 1),
                    denominator
                );

                reward =
                    (locks[totalLocks - 1].locked * rewardRate) /
                    denominator;
            }
        } else {
            // we start on nextUnlockIndex since everything before that has already been processed
            uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
            for (uint256 i = nextUnlockIndex; i < totalLocks; i++) {
                //unlock time must be less or equal to time
                if (locks[i].unlockTime > block.timestamp - _checkDelay) break;

                //add to cumulative amounts
                unlockedAmount += locks[i].locked;

                //check for kick reward
                //each epoch over due increases reward
                if (_checkDelay > 0) {
                    uint256 currentEpoch = ((block.timestamp - _checkDelay) /
                        epochDuration) * epochDuration;

                    uint256 overdueEpochCount = (currentEpoch -
                        locks[i].unlockTime) / epochDuration;

                    uint256 rewardRate = Math.min(
                        kickRewardPerEpoch * (overdueEpochCount + 1),
                        denominator
                    );
                    reward += (locks[i].locked * rewardRate) / denominator;
                }
                //set next unlock index
                nextUnlockIndex++;
            }
            //update next unlock index
            userBalance.nextUnlockIndex = nextUnlockIndex;
        }
        require(unlockedAmount > 0, "No expired locks present");

        //update user balances and total supplies
        userBalance.lockedAmount = userBalance.lockedAmount - unlockedAmount;
        totalLockedSupply -= unlockedAmount;

        emit Withdrawn(_account, unlockedAmount, _relock);

        //send process incentive
        if (reward > 0) {
            //reduce return amount by the kick reward
            unlockedAmount -= reward;

            lockingToken.safeTransfer(_rewardAddress, reward);

            emit KickReward(_rewardAddress, _account, reward);
        }

        //relock or return to user
        if (_relock) {
            _lock(_withdrawTo, unlockedAmount, true);
        } else {
            // transfer unlocked amount - kick reward (if present)
            lockingToken.safeTransfer(_withdrawTo, unlockedAmount);
        }
    }

    /// @notice withdraw expired locks to a different address
    /// @param _withdrawTo address to withdraw expired locks to
    function withdrawExpiredLocksTo(address _withdrawTo) external nonReentrant {
        _processExpiredLocks(msg.sender, false, _withdrawTo, msg.sender, 0);
    }

    /// @notice Withdraw/relock all currently locked tokens where the unlock time has passed
    /// @param _relock Relock all expired locks
    function processExpiredLocks(bool _relock) external nonReentrant {
        _processExpiredLocks(msg.sender, _relock, msg.sender, msg.sender, 0);
    }

    /// @notice Kick expired locks of `_user` and collect kick reward
    /// @param _user User to kick expired locks
    function kickExpiredLocks(address _user) external nonReentrant {
        //allow kick after grace period of 'kickRewardEpochDelay'
        _processExpiredLocks(
            _user,
            false,
            _user,
            msg.sender,
            epochDuration * kickRewardEpochDelay
        );
    }

    /// @notice Claim all pending rewards
    function getReward() external nonReentrant updateReward(msg.sender) {
        for (uint256 i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(msg.sender, reward);

                emit RewardPaid(msg.sender, _rewardsToken, reward);
            }
        }
    }

    function _notifyReward(address _rewardToken, uint256 _reward)
        internal
        returns (uint256 rewardRate, uint256 periodFinish)
    {
        Reward storage tokenRewardData = rewardData[_rewardToken];

        // if there has not been a reward for the duration of an epoch, the reward rate resets
        if (block.timestamp >= tokenRewardData.periodFinish) {
            tokenRewardData.rewardRate = _reward / epochDuration;
        } else {
            // adjust reward rate with additional rewards
            uint256 remaining = tokenRewardData.periodFinish - block.timestamp;

            uint256 leftover = remaining * tokenRewardData.rewardRate;
            tokenRewardData.rewardRate = (_reward + leftover) / epochDuration;
        }

        tokenRewardData.lastUpdateTime = block.timestamp;
        tokenRewardData.periodFinish = block.timestamp + epochDuration;

        return (tokenRewardData.rewardRate, tokenRewardData.periodFinish);
    }

    /// @notice Called by a reward distributor to distribute rewards
    /// @param _rewardToken The token to reward
    /// @param _amount The amount to reward
    function notifyRewardAmount(address _rewardToken, uint256 _amount)
        external
        updateReward(address(0))
    {
        require(
            rewardDistributors[_rewardToken][msg.sender],
            "Rewarder not approved"
        );
        require(_amount > 0, "No rewards provided");

        (uint256 rewardRate, uint256 periodFinish) = _notifyReward(
            _rewardToken,
            _amount
        );

        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the _reward amount
        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit RewardAdded(_rewardToken, _amount, rewardRate, periodFinish);
    }

    /// @notice Emergency function to withdraw non reward tokens
    /// @param _tokenAddress The token to withdraw
    /// @param _tokenAmount The amount to withdraw
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(lockingToken),
            "Cannot withdraw locking token"
        );
        require(
            rewardData[_tokenAddress].lastUpdateTime == 0,
            "Cannot withdraw reward token"
        );
        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    modifier updateReward(address _account) {
        {
            //stack too deep
            Balances storage userBalance = balances[_account];
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address token = rewardTokens[i];
                rewardData[token].rewardPerTokenStored = _rewardPerToken(token);
                rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(
                    rewardData[token].periodFinish
                );
                if (_account != address(0)) {
                    rewards[_account][token] = _earned(
                        _account,
                        token,
                        userBalance.lockedAmount
                    );
                    userRewardPerTokenPaid[_account][token] = rewardData[token]
                        .rewardPerTokenStored;
                }
            }
        }
        _;
    }

    event RewardAdded(
        address indexed _token,
        uint256 _reward,
        uint256 _rewardRate,
        uint256 _periodFinish
    );
    event Locked(address indexed _user, uint256 _lockedAmount, uint256 _epoch);
    event Withdrawn(address indexed _user, uint256 _amount, bool _relocked);
    event KickReward(
        address indexed _user,
        address indexed _kicked,
        uint256 _reward
    );
    event RewardPaid(
        address indexed _user,
        address indexed _rewardsToken,
        uint256 _reward
    );
    event Recovered(address _token, uint256 _amount);
    event SetKickIncentive(
        uint256 _kickRewardEpochDelay,
        uint256 _kickRewardPerEpoch
    );
    event RewardTokenAdded(address _rewardToken);
    event RewardDistributorApprovalChanged(
        address _rewardToken,
        address _distributor,
        bool _approved
    );
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