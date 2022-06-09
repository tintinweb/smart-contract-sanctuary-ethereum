// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts-0.8/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";
import { AuraMath, AuraMath32, AuraMath112, AuraMath224 } from "./AuraMath.sol";
import "./Interfaces.sol";

interface IRewardStaking {
    function stakeFor(address, uint256) external;
}

/**
 * @title   AuraLocker
 * @author  ConvexFinance
 * @notice  Effectively allows for rolling 16 week lockups of CVX, and provides balances available
 *          at each epoch (1 week). Also receives cvxCrv from `CvxStakingProxy` and redistributes
 *          to depositors.
 * @dev     Invdividual and delegatee vote power lookups both use independent accounting mechanisms.
 */
contract AuraLocker is ReentrancyGuard, Ownable, IAuraLocker {
    using AuraMath for uint256;
    using AuraMath224 for uint224;
    using AuraMath112 for uint112;
    using AuraMath32 for uint32;
    using SafeERC20 for IERC20;

    /* ==========     STRUCTS     ========== */

    struct RewardData {
        /// Timestamp for current period finish
        uint32 periodFinish;
        /// Last time any user took action
        uint32 lastUpdateTime;
        /// RewardRate for the rest of the period
        uint96 rewardRate;
        /// Ever increasing rewardPerToken rate, based on % of total supply
        uint96 rewardPerTokenStored;
    }
    struct UserData {
        uint128 rewardPerTokenPaid;
        uint128 rewards;
    }
    struct EarnedData {
        address token;
        uint256 amount;
    }
    struct Balances {
        uint112 locked;
        uint32 nextUnlockIndex;
    }
    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }
    struct Epoch {
        uint224 supply;
        uint32 date; //epoch start date
    }
    struct DelegateeCheckpoint {
        uint224 votes;
        uint32 epochStart;
    }

    /* ========== STATE VARIABLES ========== */

    // Rewards
    address[] public rewardTokens;
    mapping(address => uint256) public queuedRewards;
    uint256 public constant newRewardRatio = 830;
    //     Core reward data
    mapping(address => RewardData) public rewardData;
    //     Reward token -> distributor -> is approved to add rewards
    mapping(address => mapping(address => bool)) public rewardDistributors;
    //     User -> reward token -> amount
    mapping(address => mapping(address => UserData)) public userData;
    //     Duration that rewards are streamed over
    uint256 public constant rewardsDuration = 86400 * 7;
    //     Duration of lock/earned penalty period
    uint256 public constant lockDuration = rewardsDuration * 17;

    // Balances
    //     Supplies and historic supply
    uint256 public lockedSupply;
    //     Epochs contains only the tokens that were locked at that epoch, not a cumulative supply
    Epoch[] public epochs;
    //     Mappings for balance data
    mapping(address => Balances) public balances;
    mapping(address => LockedBalance[]) public userLocks;

    // Voting
    //     Stored delegations
    mapping(address => address) private _delegates;
    //     Checkpointed votes
    mapping(address => DelegateeCheckpoint[]) private _checkpointedVotes;
    //     Delegatee balances (user -> unlock timestamp -> amount)
    mapping(address => mapping(uint256 => uint256)) public delegateeUnlocks;

    // Config
    //     Blacklisted smart contract interactions
    mapping(address => bool) public blacklist;
    //     Tokens
    IERC20 public immutable stakingToken;
    address public immutable cvxCrv;
    //     Denom for calcs
    uint256 public constant denominator = 10000;
    //     Staking cvxCrv
    address public immutable cvxcrvStaking;
    //     Incentives
    uint256 public kickRewardPerEpoch = 100;
    uint256 public kickRewardEpochDelay = 3;
    //     Shutdown
    bool public isShutdown = false;

    // Basic token data
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    /* ========== EVENTS ========== */

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateCheckpointed(address indexed delegate);

    event Recovered(address _token, uint256 _amount);
    event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
    event Staked(address indexed _user, uint256 _paidAmount, uint256 _lockedAmount);
    event Withdrawn(address indexed _user, uint256 _amount, bool _relocked);
    event KickReward(address indexed _user, address indexed _kicked, uint256 _reward);
    event RewardAdded(address indexed _token, uint256 _reward);

    event BlacklistModified(address account, bool blacklisted);
    event KickIncentiveSet(uint256 rate, uint256 delay);
    event Shutdown();

    /***************************************
                    CONSTRUCTOR
    ****************************************/

    /**
     * @param _nameArg          Token name, simples
     * @param _symbolArg        Token symbol
     * @param _stakingToken     CVX (0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B)
     * @param _cvxCrv           cvxCRV (0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7)
     * @param _cvxCrvStaking    cvxCRV rewards (0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e)
     */
    constructor(
        string memory _nameArg,
        string memory _symbolArg,
        address _stakingToken,
        address _cvxCrv,
        address _cvxCrvStaking
    ) Ownable() {
        _name = _nameArg;
        _symbol = _symbolArg;
        _decimals = 18;

        stakingToken = IERC20(_stakingToken);
        cvxCrv = _cvxCrv;
        cvxcrvStaking = _cvxCrvStaking;

        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        epochs.push(Epoch({ supply: 0, date: uint32(currentEpoch) }));
    }

    /***************************************
                    MODIFIER
    ****************************************/

    modifier updateReward(address _account) {
        {
            Balances storage userBalance = balances[_account];
            uint256 rewardTokensLength = rewardTokens.length;
            for (uint256 i = 0; i < rewardTokensLength; i++) {
                address token = rewardTokens[i];
                uint256 newRewardPerToken = _rewardPerToken(token);
                rewardData[token].rewardPerTokenStored = newRewardPerToken.to96();
                rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish).to32();
                if (_account != address(0)) {
                    userData[_account][token] = UserData({
                        rewardPerTokenPaid: newRewardPerToken.to128(),
                        rewards: _earned(_account, token, userBalance.locked).to128()
                    });
                }
            }
        }
        _;
    }

    modifier notBlacklisted(address _sender, address _receiver) {
        require(!blacklist[_sender], "blacklisted");

        if (_sender != _receiver) {
            require(!blacklist[_receiver], "blacklisted");
        }

        _;
    }

    /***************************************
                    ADMIN
    ****************************************/

    function modifyBlacklist(address _account, bool _blacklisted) external onlyOwner {
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(_account)
        }
        require(cs != 0, "Must be contract");

        blacklist[_account] = _blacklisted;
        emit BlacklistModified(_account, _blacklisted);
    }

    // Add a new reward token to be distributed to stakers
    function addReward(address _rewardsToken, address _distributor) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime == 0, "Reward already exists");
        require(_rewardsToken != address(stakingToken), "Cannot add StakingToken as reward");
        require(rewardTokens.length < 5, "Max rewards length");

        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = uint32(block.timestamp);
        rewardData[_rewardsToken].periodFinish = uint32(block.timestamp);
        rewardDistributors[_rewardsToken][_distributor] = true;
    }

    // Modify approval for an address to call notifyRewardAmount
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime > 0, "Reward does not exist");
        rewardDistributors[_rewardsToken][_distributor] = _approved;
    }

    //set kick incentive
    function setKickIncentive(uint256 _rate, uint256 _delay) external onlyOwner {
        require(_rate <= 500, "over max rate"); //max 5% per epoch
        require(_delay >= 2, "min delay"); //minimum 2 epochs of grace
        kickRewardPerEpoch = _rate;
        kickRewardEpochDelay = _delay;

        emit KickIncentiveSet(_rate, _delay);
    }

    //shutdown the contract. unstake all tokens. release all locks
    function shutdown() external onlyOwner {
        isShutdown = true;
        emit Shutdown();
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakingToken), "Cannot withdraw staking token");
        require(rewardData[_tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    // Set approvals for staking cvx and cvxcrv
    function setApprovals() external {
        IERC20(cvxCrv).safeApprove(cvxcrvStaking, 0);
        IERC20(cvxCrv).safeApprove(cvxcrvStaking, type(uint256).max);
    }

    /***************************************
                    ACTIONS
    ****************************************/

    // Locked tokens cannot be withdrawn for lockDuration and are eligible to receive stakingReward rewards
    function lock(address _account, uint256 _amount) external nonReentrant updateReward(_account) {
        //pull tokens
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        //lock
        _lock(_account, _amount);
    }

    //lock tokens
    function _lock(address _account, uint256 _amount) internal notBlacklisted(msg.sender, _account) {
        require(_amount > 0, "Cannot stake 0");
        require(!isShutdown, "shutdown");

        Balances storage bal = balances[_account];

        //must try check pointing epoch first
        _checkpointEpoch();

        //add user balances
        uint112 lockAmount = _amount.to112();
        bal.locked = bal.locked.add(lockAmount);

        //add to total supplies
        lockedSupply = lockedSupply.add(_amount);

        //add user lock records or add to current
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        uint256 unlockTime = currentEpoch.add(lockDuration);
        uint256 idx = userLocks[_account].length;
        if (idx == 0 || userLocks[_account][idx - 1].unlockTime < unlockTime) {
            userLocks[_account].push(LockedBalance({ amount: lockAmount, unlockTime: uint32(unlockTime) }));
        } else {
            LockedBalance storage userL = userLocks[_account][idx - 1];
            userL.amount = userL.amount.add(lockAmount);
        }

        address delegatee = delegates(_account);
        if (delegatee != address(0)) {
            delegateeUnlocks[delegatee][unlockTime] += lockAmount;
            _checkpointDelegate(delegatee, lockAmount, 0);
        }

        //update epoch supply, epoch checkpointed above so safe to add to latest
        Epoch storage e = epochs[epochs.length - 1];
        e.supply = e.supply.add(lockAmount);

        emit Staked(_account, lockAmount, lockAmount);
    }

    // claim all pending rewards
    function getReward(address _account) external {
        getReward(_account, false);
    }

    // Claim all pending rewards
    function getReward(address _account, bool _stake) public nonReentrant updateReward(_account) {
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i; i < rewardTokensLength; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = userData[_account][_rewardsToken].rewards;
            if (reward > 0) {
                userData[_account][_rewardsToken].rewards = 0;
                if (_rewardsToken == cvxCrv && _stake && _account == msg.sender) {
                    IRewardStaking(cvxcrvStaking).stakeFor(_account, reward);
                } else {
                    IERC20(_rewardsToken).safeTransfer(_account, reward);
                }
                emit RewardPaid(_account, _rewardsToken, reward);
            }
        }
    }

    function getReward(address _account, bool[] calldata _skipIdx) external nonReentrant updateReward(_account) {
        uint256 rewardTokensLength = rewardTokens.length;
        require(_skipIdx.length == rewardTokensLength, "!arr");
        for (uint256 i; i < rewardTokensLength; i++) {
            if (_skipIdx[i]) continue;
            address _rewardsToken = rewardTokens[i];
            uint256 reward = userData[_account][_rewardsToken].rewards;
            if (reward > 0) {
                userData[_account][_rewardsToken].rewards = 0;
                IERC20(_rewardsToken).safeTransfer(_account, reward);
                emit RewardPaid(_account, _rewardsToken, reward);
            }
        }
    }

    function checkpointEpoch() external {
        _checkpointEpoch();
    }

    //insert a new epoch if needed. fill in any gaps
    function _checkpointEpoch() internal {
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);

        //first epoch add in constructor, no need to check 0 length
        //check to add
        uint256 nextEpochDate = uint256(epochs[epochs.length - 1].date);
        if (nextEpochDate < currentEpoch) {
            while (nextEpochDate != currentEpoch) {
                nextEpochDate = nextEpochDate.add(rewardsDuration);
                epochs.push(Epoch({ supply: 0, date: uint32(nextEpochDate) }));
            }
        }
    }

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function processExpiredLocks(bool _relock) external nonReentrant {
        _processExpiredLocks(msg.sender, _relock, msg.sender, 0);
    }

    function kickExpiredLocks(address _account) external nonReentrant {
        //allow kick after grace period of 'kickRewardEpochDelay'
        _processExpiredLocks(_account, false, msg.sender, rewardsDuration.mul(kickRewardEpochDelay));
    }

    // Withdraw without checkpointing or accruing any rewards, providing system is shutdown
    function emergencyWithdraw() external nonReentrant {
        require(isShutdown, "Must be shutdown");

        LockedBalance[] memory locks = userLocks[msg.sender];
        Balances storage userBalance = balances[msg.sender];

        uint256 amt = userBalance.locked;
        require(amt > 0, "Nothing locked");

        userBalance.locked = 0;
        userBalance.nextUnlockIndex = locks.length.to32();
        lockedSupply -= amt;

        emit Withdrawn(msg.sender, amt, false);

        stakingToken.safeTransfer(msg.sender, amt);
    }

    // Withdraw all currently locked tokens where the unlock time has passed
    function _processExpiredLocks(
        address _account,
        bool _relock,
        address _rewardAddress,
        uint256 _checkDelay
    ) internal updateReward(_account) {
        LockedBalance[] storage locks = userLocks[_account];
        Balances storage userBalance = balances[_account];
        uint112 locked;
        uint256 length = locks.length;
        uint256 reward = 0;
        uint256 expiryTime = _checkDelay == 0 && _relock
            ? block.timestamp.add(rewardsDuration)
            : block.timestamp.sub(_checkDelay);
        require(length > 0, "no locks");
        // e.g. now = 16
        // if contract is shutdown OR latest lock unlock time (e.g. 17) <= now - (1)
        // e.g. 17 <= (16 + 1)
        if (isShutdown || locks[length - 1].unlockTime <= expiryTime) {
            //if time is beyond last lock, can just bundle everything together
            locked = userBalance.locked;

            //dont delete, just set next index
            userBalance.nextUnlockIndex = length.to32();

            //check for kick reward
            //this wont have the exact reward rate that you would get if looped through
            //but this section is supposed to be for quick and easy low gas processing of all locks
            //we'll assume that if the reward was good enough someone would have processed at an earlier epoch
            if (_checkDelay > 0) {
                uint256 currentEpoch = block.timestamp.sub(_checkDelay).div(rewardsDuration).mul(rewardsDuration);
                uint256 epochsover = currentEpoch.sub(uint256(locks[length - 1].unlockTime)).div(rewardsDuration);
                uint256 rRate = AuraMath.min(kickRewardPerEpoch.mul(epochsover + 1), denominator);
                reward = uint256(locked).mul(rRate).div(denominator);
            }
        } else {
            //use a processed index(nextUnlockIndex) to not loop as much
            //deleting does not change array length
            uint32 nextUnlockIndex = userBalance.nextUnlockIndex;
            for (uint256 i = nextUnlockIndex; i < length; i++) {
                //unlock time must be less or equal to time
                if (locks[i].unlockTime > expiryTime) break;

                //add to cumulative amounts
                locked = locked.add(locks[i].amount);

                //check for kick reward
                //each epoch over due increases reward
                if (_checkDelay > 0) {
                    uint256 currentEpoch = block.timestamp.sub(_checkDelay).div(rewardsDuration).mul(rewardsDuration);
                    uint256 epochsover = currentEpoch.sub(uint256(locks[i].unlockTime)).div(rewardsDuration);
                    uint256 rRate = AuraMath.min(kickRewardPerEpoch.mul(epochsover + 1), denominator);
                    reward = reward.add(uint256(locks[i].amount).mul(rRate).div(denominator));
                }
                //set next unlock index
                nextUnlockIndex++;
            }
            //update next unlock index
            userBalance.nextUnlockIndex = nextUnlockIndex;
        }
        require(locked > 0, "no exp locks");

        //update user balances and total supplies
        userBalance.locked = userBalance.locked.sub(locked);
        lockedSupply = lockedSupply.sub(locked);

        //checkpoint the delegatee
        _checkpointDelegate(delegates(_account), 0, 0);

        emit Withdrawn(_account, locked, _relock);

        //send process incentive
        if (reward > 0) {
            //reduce return amount by the kick reward
            locked = locked.sub(reward.to112());

            //transfer reward
            stakingToken.safeTransfer(_rewardAddress, reward);
            emit KickReward(_rewardAddress, _account, reward);
        }

        //relock or return to user
        if (_relock) {
            _lock(_account, locked);
        } else {
            stakingToken.safeTransfer(_account, locked);
        }
    }

    /***************************************
            DELEGATION & VOTE BALANCE
    ****************************************/

    /**
     * @dev Delegate votes from the sender to `newDelegatee`.
     */
    function delegate(address newDelegatee) external virtual nonReentrant {
        // Step 1: Get lock data
        LockedBalance[] storage locks = userLocks[msg.sender];
        uint256 len = locks.length;
        require(len > 0, "Nothing to delegate");
        require(newDelegatee != address(0), "Must delegate to someone");

        // Step 2: Update delegatee storage
        address oldDelegatee = delegates(msg.sender);
        require(newDelegatee != oldDelegatee, "Must choose new delegatee");
        _delegates[msg.sender] = newDelegatee;

        emit DelegateChanged(msg.sender, oldDelegatee, newDelegatee);

        // Step 3: Move balances around
        //         Delegate for the upcoming epoch
        uint256 upcomingEpoch = block.timestamp.add(rewardsDuration).div(rewardsDuration).mul(rewardsDuration);
        uint256 i = len - 1;
        uint256 futureUnlocksSum = 0;
        LockedBalance memory currentLock = locks[i];
        // Step 3.1: Add future unlocks and sum balances
        while (currentLock.unlockTime > upcomingEpoch) {
            futureUnlocksSum += currentLock.amount;

            if (oldDelegatee != address(0)) {
                delegateeUnlocks[oldDelegatee][currentLock.unlockTime] -= currentLock.amount;
            }
            delegateeUnlocks[newDelegatee][currentLock.unlockTime] += currentLock.amount;

            if (i > 0) {
                i--;
                currentLock = locks[i];
            } else {
                break;
            }
        }

        // Step 3.2: Checkpoint old delegatee
        _checkpointDelegate(oldDelegatee, 0, futureUnlocksSum);

        // Step 3.3: Checkpoint new delegatee
        _checkpointDelegate(newDelegatee, futureUnlocksSum, 0);
    }

    function _checkpointDelegate(
        address _account,
        uint256 _upcomingAddition,
        uint256 _upcomingDeduction
    ) internal {
        // This would only skip on first checkpointing
        if (_account != address(0)) {
            uint256 upcomingEpoch = block.timestamp.add(rewardsDuration).div(rewardsDuration).mul(rewardsDuration);
            DelegateeCheckpoint[] storage ckpts = _checkpointedVotes[_account];
            if (ckpts.length > 0) {
                DelegateeCheckpoint memory prevCkpt = ckpts[ckpts.length - 1];
                // If there has already been a record for the upcoming epoch, no need to deduct the unlocks
                if (prevCkpt.epochStart == upcomingEpoch) {
                    ckpts[ckpts.length - 1] = DelegateeCheckpoint({
                        votes: (prevCkpt.votes + _upcomingAddition - _upcomingDeduction).to224(),
                        epochStart: upcomingEpoch.to32()
                    });
                }
                // else if it has been over 16 weeks since the previous checkpoint, all locks have since expired
                // e.g. week 1 + 17 <= 18
                else if (prevCkpt.epochStart + lockDuration <= upcomingEpoch) {
                    ckpts.push(
                        DelegateeCheckpoint({
                            votes: (_upcomingAddition - _upcomingDeduction).to224(),
                            epochStart: upcomingEpoch.to32()
                        })
                    );
                } else {
                    uint256 nextEpoch = upcomingEpoch;
                    uint256 unlocksSinceLatestCkpt = 0;
                    // Should be maximum 18 iterations
                    while (nextEpoch > prevCkpt.epochStart) {
                        unlocksSinceLatestCkpt += delegateeUnlocks[_account][nextEpoch];
                        nextEpoch -= rewardsDuration;
                    }
                    ckpts.push(
                        DelegateeCheckpoint({
                            votes: (prevCkpt.votes - unlocksSinceLatestCkpt + _upcomingAddition - _upcomingDeduction)
                                .to224(),
                            epochStart: upcomingEpoch.to32()
                        })
                    );
                }
            } else {
                ckpts.push(
                    DelegateeCheckpoint({
                        votes: (_upcomingAddition - _upcomingDeduction).to224(),
                        epochStart: upcomingEpoch.to32()
                    })
                );
            }
            emit DelegateCheckpointed(_account);
        }
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) external view returns (uint256) {
        return getPastVotes(account, block.timestamp);
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) external view virtual returns (DelegateeCheckpoint memory) {
        return _checkpointedVotes[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) external view virtual returns (uint32) {
        return _checkpointedVotes[account].length.to32();
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     */
    function getPastVotes(address account, uint256 timestamp) public view returns (uint256 votes) {
        require(timestamp <= block.timestamp, "ERC20Votes: block not yet mined");
        uint256 epoch = timestamp.div(rewardsDuration).mul(rewardsDuration);
        DelegateeCheckpoint memory ckpt = _checkpointsLookup(_checkpointedVotes[account], epoch);
        votes = ckpt.votes;
        if (votes == 0 || ckpt.epochStart + lockDuration <= epoch) {
            return 0;
        }
        while (epoch > ckpt.epochStart) {
            votes -= delegateeUnlocks[account][epoch];
            epoch -= rewardsDuration;
        }
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `timestamp`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     */
    function getPastTotalSupply(uint256 timestamp) external view returns (uint256) {
        require(timestamp < block.timestamp, "ERC20Votes: block not yet mined");
        return totalSupplyAtEpoch(findEpochId(timestamp));
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     *      Copied from oz/ERC20Votes.sol
     */
    function _checkpointsLookup(DelegateeCheckpoint[] storage ckpts, uint256 epochStart)
        private
        view
        returns (DelegateeCheckpoint memory)
    {
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = AuraMath.average(low, high);
            if (ckpts[mid].epochStart > epochStart) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? DelegateeCheckpoint(0, 0) : ckpts[high - 1];
    }

    /***************************************
                VIEWS - BALANCES
    ****************************************/

    // Balance of an account which only includes properly locked tokens as of the most recent eligible epoch
    function balanceOf(address _user) external view returns (uint256 amount) {
        return balanceAtEpochOf(findEpochId(block.timestamp), _user);
    }

    // Balance of an account which only includes properly locked tokens at the given epoch
    function balanceAtEpochOf(uint256 _epoch, address _user) public view returns (uint256 amount) {
        uint256 epochStart = uint256(epochs[0].date).add(uint256(_epoch).mul(rewardsDuration));
        require(epochStart < block.timestamp, "Epoch is in the future");

        uint256 cutoffEpoch = epochStart.sub(lockDuration);

        LockedBalance[] storage locks = userLocks[_user];

        //need to add up since the range could be in the middle somewhere
        //traverse inversely to make more current queries more gas efficient
        uint256 locksLength = locks.length;
        for (uint256 i = locksLength; i > 0; i--) {
            uint256 lockEpoch = uint256(locks[i - 1].unlockTime).sub(lockDuration);
            //lock epoch must be less or equal to the epoch we're basing from.
            //also not include the current epoch
            if (lockEpoch < epochStart) {
                if (lockEpoch > cutoffEpoch) {
                    amount = amount.add(locks[i - 1].amount);
                } else {
                    //stop now as no futher checks matter
                    break;
                }
            }
        }

        return amount;
    }

    // Information on a user's locked balances
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
                locked = locked.add(locks[i].amount);
            } else {
                unlockable = unlockable.add(locks[i].amount);
            }
        }
        return (userBalance.locked, unlockable, locked, lockData);
    }

    // Supply of all properly locked balances at most recent eligible epoch
    function totalSupply() external view returns (uint256 supply) {
        return totalSupplyAtEpoch(findEpochId(block.timestamp));
    }

    // Supply of all properly locked balances at the given epoch
    function totalSupplyAtEpoch(uint256 _epoch) public view returns (uint256 supply) {
        uint256 epochStart = uint256(epochs[0].date).add(uint256(_epoch).mul(rewardsDuration));
        require(epochStart < block.timestamp, "Epoch is in the future");

        uint256 cutoffEpoch = epochStart.sub(lockDuration);
        uint256 lastIndex = epochs.length - 1;

        uint256 epochIndex = _epoch > lastIndex ? lastIndex : _epoch;

        for (uint256 i = epochIndex + 1; i > 0; i--) {
            Epoch memory e = epochs[i - 1];
            if (e.date == epochStart) {
                continue;
            } else if (e.date <= cutoffEpoch) {
                break;
            } else {
                supply += e.supply;
            }
        }
    }

    // Get an epoch index based on timestamp
    function findEpochId(uint256 _time) public view returns (uint256 epoch) {
        return _time.sub(epochs[0].date).div(rewardsDuration);
    }

    /***************************************
                VIEWS - GENERAL
    ****************************************/

    // Number of epochs
    function epochCount() external view returns (uint256) {
        return epochs.length;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /***************************************
                VIEWS - REWARDS
    ****************************************/

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards) {
        userRewards = new EarnedData[](rewardTokens.length);
        Balances storage userBalance = balances[_account];
        uint256 userRewardsLength = userRewards.length;
        for (uint256 i = 0; i < userRewardsLength; i++) {
            address token = rewardTokens[i];
            userRewards[i].token = token;
            userRewards[i].amount = _earned(_account, token, userBalance.locked);
        }
        return userRewards;
    }

    function lastTimeRewardApplicable(address _rewardsToken) external view returns (uint256) {
        return _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish);
    }

    function rewardPerToken(address _rewardsToken) external view returns (uint256) {
        return _rewardPerToken(_rewardsToken);
    }

    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance
    ) internal view returns (uint256) {
        UserData memory data = userData[_user][_rewardsToken];
        return _balance.mul(_rewardPerToken(_rewardsToken).sub(data.rewardPerTokenPaid)).div(1e18).add(data.rewards);
    }

    function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns (uint256) {
        return AuraMath.min(block.timestamp, _finishTime);
    }

    function _rewardPerToken(address _rewardsToken) internal view returns (uint256) {
        if (lockedSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            uint256(rewardData[_rewardsToken].rewardPerTokenStored).add(
                _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish)
                    .sub(rewardData[_rewardsToken].lastUpdateTime)
                    .mul(rewardData[_rewardsToken].rewardRate)
                    .mul(1e18)
                    .div(lockedSupply)
            );
    }

    /***************************************
                REWARD FUNDING
    ****************************************/

    function queueNewRewards(address _rewardsToken, uint256 _rewards) external nonReentrant {
        require(rewardDistributors[_rewardsToken][msg.sender], "!authorized");
        require(_rewards > 0, "No reward");

        RewardData storage rdata = rewardData[_rewardsToken];

        IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), _rewards);

        _rewards = _rewards.add(queuedRewards[_rewardsToken]);
        require(_rewards < 1e25, "!rewards");

        if (block.timestamp >= rdata.periodFinish) {
            _notifyReward(_rewardsToken, _rewards);
            queuedRewards[_rewardsToken] = 0;
            return;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(rdata.periodFinish.sub(rewardsDuration.to32()));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rdata.rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
        if (queuedRatio < newRewardRatio) {
            _notifyReward(_rewardsToken, _rewards);
            queuedRewards[_rewardsToken] = 0;
        } else {
            queuedRewards[_rewardsToken] = _rewards;
        }
    }

    function _notifyReward(address _rewardsToken, uint256 _reward) internal updateReward(address(0)) {
        RewardData storage rdata = rewardData[_rewardsToken];

        if (block.timestamp >= rdata.periodFinish) {
            rdata.rewardRate = _reward.div(rewardsDuration).to96();
        } else {
            uint256 remaining = uint256(rdata.periodFinish).sub(block.timestamp);
            uint256 leftover = remaining.mul(rdata.rewardRate);
            rdata.rewardRate = _reward.add(leftover).div(rewardsDuration).to96();
        }

        // Equivalent to 10 million tokens over a weeks duration
        require(rdata.rewardRate < 1e20, "!rewardRate");
        require(lockedSupply >= 1e20, "!balance");

        rdata.lastUpdateTime = block.timestamp.to32();
        rdata.periodFinish = block.timestamp.add(rewardsDuration).to32();

        emit RewardAdded(_rewardsToken, _reward);
    }
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
pragma solidity 0.8.11;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library AuraMath {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "AuraMath: uint224 Overflow");
        c = uint224(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "AuraMath: uint128 Overflow");
        c = uint128(a);
    }

    function to112(uint256 a) internal pure returns (uint112 c) {
        require(a <= type(uint112).max, "AuraMath: uint112 Overflow");
        c = uint112(a);
    }

    function to96(uint256 a) internal pure returns (uint96 c) {
        require(a <= type(uint96).max, "AuraMath: uint96 Overflow");
        c = uint96(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "AuraMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library AuraMath32 {
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        c = a - b;
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint112.
library AuraMath112 {
    function add(uint112 a, uint112 b) internal pure returns (uint112 c) {
        c = a + b;
    }

    function sub(uint112 a, uint112 b) internal pure returns (uint112 c) {
        c = a - b;
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library AuraMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        c = a + b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IPriceOracle {
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }
    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);
}

interface IVault {
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for ManagedPool
    }
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IAuraLocker {
    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;
}

interface IExtraRewardsDistributor {
    function addReward(address _token, uint256 _amount) external;
}

interface ICrvDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(
        uint256,
        uint256,
        bool,
        address _stakeAddress
    ) external;
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