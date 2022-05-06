// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "ERC20.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import "Ownable.sol";


/// @title Vinci Staking V1
/// @notice A smart contract to handle staking of Vinci ERC20 token across multiple artist pools. Picasso club tiers information also handled by this contract
/// @dev Jacobo Lansac
contract VinciStakingV1 is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public vinciERC20;

    struct Pool {
        address poolOwner;
        uint poolFeeInGwei;  // stored as a (0-100) number * gwei. Needs to be devided by 100 gwei to get a usable fraction
        uint totalStaked;
        uint ownerClaimable;
        uint ownerUnclaimable;
        uint ownerNextCheckpoint;
        uint ownerNextCPmultiplier;
        uint ownerLastCheckpointRevision;
        address[] stakeholders;
        mapping(address => uint) activeStaking;  // tokens staked that are not scheduled to unstake in next checkpoint. Generate rewards
        mapping(address => uint) scheduledUnstaking;  // tokens that are staked (and generating rewards) but that are scheduled to unstake in next checkpoint
        mapping(address => uint) currentlyUnstaking;  // tokesn that have been unstaked, but are not yet claimable as there is a 2-week locking period
        mapping(address => uint) unclaimable;  // staking rewards / airdrops / penalty distributions that are not claimable yet (until next checkpoint)
        mapping(address => uint) claimable;  // staking rewards / airdrops / penalty distributions that are claimable right now (generated before previous checkpoint)
        mapping(address => uint) lastUpdated;  // last time the user balances were updated in this pool (to avoid repetitions, wasted gas)
        mapping(address => uint) emergencyUnlock;  // timestam when the unstaked tokens become available for claiming
        mapping(address => uint) movementLock;  // from time a user can move funds between pools. Only activated once they move them
    }

    struct User {
        bool registered;
        bool superstaker;
        uint totalStaked;
        uint lastFullStateUpdateTimestamp;
        uint lastCheckpointRevision;
        uint nextCheckpointTimestamp;
        uint[] everActvePools;
        mapping(uint => bool) activePoolsMap;
        uint delayMultiplier;  // a multiplier that decreases every checkpoint crossed. The next checkpoint is calculated as the multiplier times the checkpointBlockDuration (for isntance, 6 * 30 days)
    }

    // configs
    uint public constant genesisSundayTimestamp = 1648944000;  // Sun Apr 3rd, 2022 00:00:00 GMT
    uint public unstakeHardUnlockTimestamp; // = 1653998400;  // Tue May 31 2022 12:00:00 GMT (14:00 CET)
    uint public APRrate = 5.5 gwei;  // stored as a (0-100) number * gwei. Needs to be devided by 100 gwei to get a usable fraction
    uint public minimumTierForPenaltyPot = 2;
    uint public epochDuration;

    uint public checkpointBlockDuration;
    // overall contract staking data
    uint public stakingRewardsFunds;
    uint public totalStakedInContract;
    uint public penaltyPot;

    // pools management
    uint[] public existingPoolIds;
    mapping(uint => Pool) pools;

    // users management
    address[] public stakeholders;
    mapping(address => User) users;

    // Tiers info
    uint[] public tiersThresholdsInVinci;  // length of the threshold array determines how many tiers there are
    mapping(address => uint) usersTiers;
    mapping(uint => uint) totalStakedPerTier; // total staked per tier regardless of the superstaker status

    // reentrancy lock
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'reentrancy guard locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // Events
    event Staked(address indexed user, uint256 amount, uint poolid);
    event Unstaked(address indexed user, uint256 amount, uint poolid);
    event ScheduledUnstake(address indexed user, uint256 amount, uint poolid, uint currentNextCheckpoint);
    event CancelScheduledUnstake(address indexed user, uint poolid);
    event Claimed(address indexed user, uint256 amount);
    event Reallocated(address indexed user, uint256 amount, uint fromPoolId, uint toPoolId);
    event VinciTransferredToContract(address from, uint amount);
    event FundedStakingRewardsFund(uint _amount);
    event Airdropped(address indexed user, uint amount);
    event PenaltyPotDistributed();
    event TiersThresholdsUpdated(uint[] _vinciThresholds);
    event PoolCreated(uint indexed _poolId, address _poolOwner, uint _poolFeeInGwei);
    event PoolFeeUpdated(uint indexed _poolId, uint _newFeeInGwei);
    event PoolOwnershipTransferred(uint indexed _poolId, address _newOwner);
    event NewStakeHolderRegistered(address indexed _user);
    event UserTierReset(address indexed _user, uint oldTier, uint newTier);
    event UserCheckpointReset(address indexed _user, uint oldCheckpoint, uint newCheckpoint);
    event PoolOwnerCheckpointReset(uint indexed _poolId, uint oldCheckpoint, uint newCheckpoint);
    event UserPoolBalancesUpdated(uint indexed _poolId, address indexed _user);

    /**
    @dev The constructor creates also the default vinci pool
    @param _vinciTokenAddress is the address of the ERC20 vinci token already deployed
    @param _tiersThresholdsInVinci should come with all decimals (as a uint). Example: 100 vinci would be 100 * 1e18
    */
    constructor(
        address _vinciTokenAddress,
        uint[] memory _tiersThresholdsInVinci,
        uint _epochDuration,
        uint _checkpointBlockDuration,
        uint _unstakeHardUnlockTimestamp
    ) {
        vinciERC20 = IERC20(_vinciTokenAddress);
        tiersThresholdsInVinci = _tiersThresholdsInVinci;
        epochDuration = _epochDuration;
        checkpointBlockDuration = _checkpointBlockDuration;
        unstakeHardUnlockTimestamp = _unstakeHardUnlockTimestamp;
        // lets create vinci default pool. Fee=0 so that artists have to justify their fee in terms of value
        _createStakingPool(0, _msgSender());
    }

    // ---------------------------------------------------------- //
    //                       User functions                       //
    // ---------------------------------------------------------- //

    /**
    @dev Emits a {Staked} event.

    Requirements: see _stake() requirements

    @notice stake vinci tokens into a specific pool into the msgSender staking balance.

    */
    function stake(
        uint _poolId,
        uint _amount
    ) external {
        _stake(_poolId, _amount, _msgSender());
    }

    /**
    @dev Unstaking is blocked by a hardcoded timestamp.

    Emits an {Unstaked} event.

    Requirements:
        timestamp has passed the hardcoded lock timestamp
        amount to unstake needs to be higher than active staking and greater than 0 (therefore, active staking must be greater than 0)
        _poolId exists (non zero address as owner)

    @notice This function ALWAYS imposes a penalty on the unrealized staking rewards (unclaimable balance). To avoid this, use the scheduleUnstake() function instead

    A proportional amount to the unstaked amount / total stake is lost as a penalization. Unstaked tokens stop generating staking rewards
    */
    function unstake(
        uint _poolId,
        uint _amount
    ) external {
        require(block.timestamp >= unstakeHardUnlockTimestamp, 'unstaking locked until token launch');

        // let's ensure first that the rewards from the amount to be unstaked are updated before updating other balances
        updateUserState(_msgSender());

        // only activeStakig balance can be unstaked. The already scheduledUnstake cannot be unstaked. It has to be first unscheduled
        require(_amount <= pools[_poolId].activeStaking[_msgSender()], 'not enough active staking to unstake');
        require(_amount > 0, 'not allowed to unstake 0 tokens');
        uint prevStakedBalance = pools[_poolId].activeStaking[_msgSender()] + pools[_poolId].scheduledUnstaking[_msgSender()];

        pools[_poolId].activeStaking[_msgSender()] -= _amount;
        pools[_poolId].currentlyUnstaking[_msgSender()] += _amount;
        pools[_poolId].totalStaked -= _amount;
        users[_msgSender()].totalStaked -= _amount;
        totalStakedPerTier[usersTiers[_msgSender()]] -= _amount;
        totalStakedInContract -= _amount;

        // penalization is calculated based on the total staked generating rewards (active + scheduled unstake)
        uint penalization;
        // prevStakedBalance is > 0, otherwise the function requirements would revert the transaction
        penalization = _amount * pools[_poolId].unclaimable[_msgSender()] / prevStakedBalance;

        // the penalty pot holds the penalizations taken from emergency unstake
        pools[_poolId].unclaimable[_msgSender()] -= penalization;
        penaltyPot += penalization;

        // set the emergencyLock timestamp. Tokens can only be retrieved after this timestamp
        // Note that this timestamp is overwritten if a user unstakes again while previous tokens have not been uncloked
        pools[_poolId].emergencyUnlock[_msgSender()] = block.timestamp + (2 * epochDuration);

        // if they unstake, the tier is reevaluated, but checkpoint is not postponed
        _resetUserTier(_msgSender());
        _attemptDeactivatePoolForUser(_poolId, _msgSender());

        emit Unstaked(_msgSender(), _amount, _poolId);
    }

    /**
    @dev Emits an {ScheduledUnstake} event.

    Requirements:
        _amount higher than active staking
        _poolId exists (non zero address as owner)

    @notice Schedules the unstaking to happen on the next user Checkpoint. This unstaking does NOT imply any penalization for the unstaker
    */
    function scheduleUnstake(
        uint _poolId,
        uint _amount
    ) external {
        // make sure staking rewards are first updated
        updateUserState(_msgSender());

        require(_amount <= pools[_poolId].activeStaking[_msgSender()], 'not enough active staking to unstake');
        // there is no penalization because of being scheduled
        pools[_poolId].activeStaking[_msgSender()] -= _amount;
        pools[_poolId].scheduledUnstaking[_msgSender()] += _amount;

        _attemptDeactivatePoolForUser(_poolId, _msgSender());
        emit ScheduledUnstake(_msgSender(), _amount, _poolId, users[_msgSender()].nextCheckpointTimestamp);
    }

    /**
    @dev

    Requirements:
        _poolId exists (non zero address as owner)

    Emits a {CancelScheduledUnstake} event

    @notice cancels the scheduled unstaking in the pool for a user, regardless of the amount.
    */
    function cancelScheduledUnstaking(
        uint _poolId
    ) external {
        // update pool balances in case user has crossed checkpoint and scheduledUnstake balances need an update
        updateUserState(_msgSender());

        // when cancelling there is no option of selecting amount. All scheduled goes back to active staking
        pools[_poolId].activeStaking[_msgSender()] += pools[_poolId].scheduledUnstaking[_msgSender()];
        delete pools[_poolId].scheduledUnstaking[_msgSender()];
        emit CancelScheduledUnstake(_msgSender(), _poolId);
    }

    /**
    @dev reentrancy lock is used as there is calls to external contracts

    Requires
        ERC20 token approvals
        _poolId exists (non zero address as owner)

    Emits a {Claimed} event

    @notice sends the claimable vinci tokens to the user's wallet. Note that claimable is only the staking rewards / airdrops that happened before the last checkpoint
    */
    function claim(uint _poolId) external lock {
        // make sure staking rewards are first updated
        updateUserState(_msgSender());
        uint _amount = pools[_poolId].claimable[_msgSender()];
        // get some gas back by using delete
        delete pools[_poolId].claimable[_msgSender()];
        // No need to make an ERC20 transfer if amount is zero. Gas saving
        if (_amount > 0) {
            vinciERC20.transfer(_msgSender(), _amount);
        }
        emit Claimed(_msgSender(), _amount);
    }

    /**
    @dev Staking balances are not updated, as funds are just moved from one pool to another.

    Emits a {Reallocated} event

    Requirements:
        both destination and origin poolIds exists
        positive balance in _originPoolId
        last time funds where moved away from _originPoolId, it was more than one epoch ago
    @notice Move the staked tokens from one pool to another without getting penalized for doing so
    */
    function moveFunds(
        uint _originPoolId,
        uint _destinationPoolId,
        uint _amount
    ) external {
        require(poolExists(_originPoolId), 'destination poolId not found');
        require(poolExists(_destinationPoolId), 'destination poolId not found');
        require(_amount <= pools[_originPoolId].activeStaking[_msgSender()], '_amount higher than unstakable balance in origin pool');
        require(block.timestamp >= pools[_originPoolId].movementLock[_msgSender()], 'cannot reallocate more funds from _originPoolId in this epoch');

        // make sure staking rewards from the funds to be moved are updated before the movement
        updateUserState(_msgSender());

        _registerUserInPool(_destinationPoolId, _msgSender());

        pools[_originPoolId].activeStaking[_msgSender()] -= _amount;
        pools[_destinationPoolId].activeStaking[_msgSender()] += _amount;

        pools[_originPoolId].totalStaked -= _amount;
        pools[_destinationPoolId].totalStaked += _amount;

        _attemptDeactivatePoolForUser(_originPoolId, _msgSender());

        // this locking is to avoid that people move funds continuously from pool to pool. We need commitment with brand pools
        _movementLock(_destinationPoolId, _msgSender());

        emit Reallocated(_msgSender(), _amount, _originPoolId, _destinationPoolId);
    }

    /**
    @notice A user can reevaluate the tier based on the current thresholds and the user staked balance.
    As a penalization, the next checkpoint is delayed another X months
    */
    function relock() external {
        updateUserState(_msgSender());
        // This function updates user staking rewards and balances then update tiers, postpone checkpoint etc
        _resetUserTier(_msgSender());
        _resetUserCheckpoint(_msgSender(), true);
    }

    // ---------------------------------------------------------- //
    //            Contract Management functions                   //
    // ---------------------------------------------------------- //

    /**
    @dev reentrancy lock is used as calls an external contract (ERC20).
    onlyOwner is not used here to allow any wallet funding the contract

    Requires ERC20 token approvals

    @notice Fund the staking contract with Vinci tokens for staking rewards. Funds cannot be ever retrieved
    */
    function fundContractWithVinci(uint _amount) external lock {
        require(_amount > 0, 'Only non-zero fund allowed');
        _transferVinciToContract(_amount);
        stakingRewardsFunds += _amount;
        emit FundedStakingRewardsFund(_amount);
    }

    /**
    @dev The function checks first if there will be enough StaingRewards
    @notice Updates the staking rewards of all users in all pools, checks if any user/poolOwner has crossed a checkpoint lately and in that case, updates balances accordingly

    WARNING: this transaction can run out of gas for too many users and pools. To avoid it, the logic can be split offchain in the following way:

    for user in stakeholders:
        updateUserState(user)
        evaluateUserCheckpoints(user)

    for pool in existingPoolIds:
        evaluatePoolOwnerCheckpoint(poolid)
    */
    function updateSystemState() external {
        // estimate first if there is enough StakingRewardsFunds to update all _updateUserPoolBalances
        uint neededFunds = totalStakedInContract * APRrate / (100 gwei);
        require(neededFunds <= stakingRewardsFunds, 'not enough StakingRewardsFunds to update all balances');

        for (uint i = 0; i < stakeholders.length; i++) {
            // we split these two instead of calling directly updateUserState to keep visibility as external and save gas
            updateUserState(stakeholders[i]);
            evaluateUserCheckpoints(stakeholders[i]);
        }

        for (uint i = 0; i < existingPoolIds.length; i++) {
            evaluatePoolOwnerCheckpoint(existingPoolIds[i]);
        }
    }

    /**
    @notice updates all user balances regarding staking rewards and pending unstakings. Then it evaluates if the user needs a checkpoint update, and if so, it performs the update
    @dev updateUserBalacnes updates all staking pools and ALSO updates potential checkpoints crossings
    */
    function updateUserState(address _user) public {
        // save into memory to save gas
        uint[] memory userPools = users[_user].everActvePools;

        // avoid updating user state more than once per block to save gas
        if (block.timestamp > users[_user].lastFullStateUpdateTimestamp) {
            for (uint i = 0; i < userPools.length; i++) {
                // only update active pools to save gas
                if (users[_user].activePoolsMap[userPools[i]]) {
                    _updateUserPoolBalances(userPools[i], _user);
                }
            }
            users[_user].lastFullStateUpdateTimestamp = block.timestamp;
            evaluateUserCheckpoints(_user);

            // evaluate if user is still loyal
            if (users[_user].totalStaked == 0) {
                users[_user].superstaker = false;
                users[_user].delayMultiplier = 6;
            }
        }
    }

    /**
    @notice Evaluates if a user needs a checkpoint reset, and if so, it performs the checkpoint update.
    @dev Checks if a user has crossed a checkpoint. The function avoids unnecessary computation by checking that the check was conducted recently
    */
    function evaluateUserCheckpoints(address _user) public {
        // max 1 day of checkpoint miss management
        if (block.timestamp - users[_user].lastCheckpointRevision > uint(epochDuration / 7)) {
            if (block.timestamp > users[_user].nextCheckpointTimestamp) {
                _resetUserCheckpoint(_user, true);
            }
        }
        users[_user].lastCheckpointRevision = block.timestamp;
    }

    /**
    @dev OnlyOwner is not imposed, as anyone could decide to airdrop to another address

    Requires ERC20 approvals for vinci token

    @notice airdrops an amount of vinci tokens to a specific user. The tokens are airdropped to the vinci pool, on the unclaimable balance
    Tokens are taken from the msg senders wallet
    */
    function airdropToUser(
        uint _amount,
        address _user
    ) external lock {
        require(_amount > 0, 'airdropping 0 amount is not allowed');
        // if user is not registered in default vinci pool, it means user is not registered at all
        if (!users[_user].registered) {
            // this registration also registers the user into the default vinci pool where the airdrops go
            _registerNewStakeholder(_user);
        }
        // vinci comes from the sender wallet, not from the StakingRewardsFunds
        _transferVinciToContract(_amount);
        // update balances first in case some of the unclaimable needs to be moved to claimable before mixing with new airdrop
        updateUserState(_user);
        // update only the unclaimable balances, as all airdrops can only be claimed once checkpoint has passed
        pools[0].unclaimable[_user] += _amount;
        emit Airdropped(_user, _amount);
    }

    /**
    @dev OnlyOwner is not imposed, as anyone could decide to airdrop to another address

    Requires ERC20 approvals for vinci token

    @notice Airdrop tokens to all users with a certain tier or above, in a weighted fashion. The amount airdropped to a user is proportional to their stake compared to the total staking
    Tokens are taken from the msg senders wallet
    */
    function weightedAirdropFromSendersWallet(
        uint _amount,
        uint _minimumTier
    ) external lock {
        // vinci comes from the sender wallet, not from the StakingRewardsFunds
        _transferVinciToContract(_amount);
        // do a weighted distribution based on stake. Staking rewards are updated inside the function below
        _weightedTokenDistribution(_amount, _minimumTier);
    }

    /**
    @dev reentrancy lock is used as there is calls to external contracts
    OnlyOwner is not imposed, to allow anyone to stake on behalf to other user

    Requirements: see _stake() requirements

    Emits a {Staked} event.

    @notice stake vinci tokens into a specific pool into the _user parameter staking balance. Any wallet can stake on behalf of another user
    */
    function stakeToUser(
        uint _poolId,
        uint _amount,
        address _user
    ) external {
        _stake(_poolId, _amount, _user);
    }

    // ---------------------------------------------------------- //
    //               Management - Only owner functions            //
    // ---------------------------------------------------------- //

    /**
    @dev onlyOnwer modifier imposed as it is distributing contract funds

    Requirements: only owner

    Emits {PenaltyPotDistributed} event
    @notice function to distribute the current penalty pot among tier2 users
    */
    function distributePenaltyPot() external onlyOwner {
        uint _penaltyPot = penaltyPot;
        // delete to get some gas back
        delete penaltyPot;
        // no need to worry about reentrancy as there is no interactions outside the contract
        // penalty pot distribution is only for super stakers
        _weightedTokenDistribution(_penaltyPot, minimumTierForPenaltyPot);

        emit PenaltyPotDistributed();
    }

    /**
    @dev distributes tokens on a weighted manner, but Tokens are subtracted from the contract StakingRewardsFunds
    so no ERC20 approvals required

    Requirements:
        only owner
        tokens to airdrop must be lower or equal to the remaining stakingRewardsFunds

    @notice airdrops tokens to all users above a certain tier

    */
    function weightedAirdropFromStakingRewardsFund(
        uint _amount,
        uint _minimumTier
    ) external onlyOwner {
        require(_amount <= stakingRewardsFunds, 'not enough StakingRewards funds');
        stakingRewardsFunds -= _amount;
        _weightedTokenDistribution(_amount, _minimumTier);
    }

    /**
    @dev input as many thresholds as tiers are needed
    Requirement:
        only owner
        the tier thresholds array should be sorted (increasing values)

    @param _vinciMinimumAmounts An array of thresholds to enter the tiers. [tier1thresh, tier2thresh... tierNthresh]

    @notice Sets new thresholds for the Picasso club tiers (measured in Vinci tokens)
    */
    function updatePicassoTierThresholds(uint[] memory _vinciMinimumAmounts) external onlyOwner {
        require(_vinciMinimumAmounts.length > 0, 'input at least one threshold');
        for (uint t = 1; t < _vinciMinimumAmounts.length; t++) {
            require(_vinciMinimumAmounts[t] > _vinciMinimumAmounts[t - 1], 'thresholds array should have increasing values');
        }
        tiersThresholdsInVinci = _vinciMinimumAmounts;
        emit TiersThresholdsUpdated(_vinciMinimumAmounts);
    }


    /**
    @dev pools are created only by contract owner. This might be reviewed in future versions
    the function is a wrapper of _createStakingPool to allow this function to be external

    Emits {PoolCreated} event

    Requires that the poolId does not exist yet

    @param _poolPercFeeInGwei percentage , where 1 gwei == 1 % fee
    @param _poolOwner address
    */
    function createStakingPool(
        uint _poolPercFeeInGwei,
        address _poolOwner
    ) external onlyOwner returns (uint){
        uint _poolId = _createStakingPool(_poolPercFeeInGwei, _poolOwner);
        return _poolId;
    }

    // ---------------------------------------------------------- //
    //                       View functions                       //
    // ---------------------------------------------------------- //

    /// ......... [view] but potentially used by contract functions .........

    /**
    @notice Checks if a pool exists with a given poolId.
    @dev A pool 'exists' when it has a non-zero owner address
    */
    function poolExists(uint poolId) public view returns (bool) {
        // only requirement for a pool to exist is to have a non zero owner address
        return (pools[poolId].poolOwner != address(0));
    }

    /**
    @notice Evaluates if a user has active staking/claimable/unclaimable balance in a pool
    */
    function isUserInPool(uint _poolId, address _user) public view returns (bool){
        return users[_user].activePoolsMap[_poolId];
    }

    /// ........... view functions only used externally .............

    function isUserStateUpdated(address _user) external view returns (bool) {
        return block.timestamp - users[_user].lastFullStateUpdateTimestamp < epochDuration;
    }

    function readUserLastFullUpdateTimestamp(address _user) external view returns (uint) {
        return users[_user].lastFullStateUpdateTimestamp;
    }

    function isUserCheckpointUpdated(address _user) external view returns (bool) {
        return users[_user].nextCheckpointTimestamp > block.timestamp;
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function totalStakedInPool(uint _poolId) external view returns (uint) {
        return pools[_poolId].totalStaked;
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function userStakedBalanceInPool(uint _poolId, address _user) external view returns (uint){
        return pools[_poolId].activeStaking[_user] + pools[_poolId].scheduledUnstaking[_user];
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function unclaimableBalance(uint _poolId, address _user) public view returns (uint) {
        return pools[_poolId].unclaimable[_user];
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function claimableBalance(uint _poolId, address _user) public view returns (uint){
        return pools[_poolId].claimable[_user];
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function currentlyUnstakingBalance(uint _poolId, address _user) public view returns (uint) {
        return pools[_poolId].currentlyUnstaking[_user];
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function unscheduledUnstakeBalance(uint _poolId, address _user) external view returns (uint) {
        return pools[_poolId].scheduledUnstaking[_user];
    }

    function poolUserLastUpdated(uint _poolId, address _user) external view returns (uint) {
        return pools[_poolId].lastUpdated[_user];
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function unstakableBalance(uint _poolId, address _user) external view returns (uint) {
        return pools[_poolId].activeStaking[_user];
    }

    /**
    @notice The information provided by this function is only fully True if isUserStateUpdated()==true
    */
    function userTotalStake(address _user) external view returns (uint) {
        return users[_user].totalStaked;
    }

    function readNextUserCheckpoint(address _user) external view returns (uint) {
        return users[_user].nextCheckpointTimestamp;
    }

    function getPoolOwner(uint _poolId) external view returns (address) {
        return pools[_poolId].poolOwner;
    }

    /**
    @notice the pool fee is in gwei. In order to get a meaningfull fraction in (0-1) range, divide by 100 gwei.
    */
    function getPoolFeeInGwei(uint _poolId) external view returns (uint) {
        return pools[_poolId].poolFeeInGwei;
    }

    function isPoolOwnerCheckpointUpdated(uint _poolId) external view returns (bool) {
        return pools[_poolId].ownerNextCheckpoint < block.timestamp;
    }

    function poolOwnerUnclaimableBalance(uint _poolId) external view returns (uint) {
        return pools[_poolId].ownerUnclaimable;
    }

    function poolOwnerClaimableBalance(uint _poolId) external view returns (uint) {
        return pools[_poolId].ownerClaimable;
    }

    // -------------- Tier related info ----------------------------

    /**
    @dev This function does not re-evaluate the user tier. Only reads the last stored tier evaluation for the user
    @return uint indicating (the last evaluated) user tier
    */
    function readUserTier(address _user) external view returns (uint){
        return usersTiers[_user];
    }

    /**
    @dev [tier1, tier2, ... tierN]
    @return a list of increasing thresholds for the Picasso Club tiers
     */
    function readTierThresholdsInVinci() external view returns (uint[] memory){
        return tiersThresholdsInVinci;
    }


    /**
    * @dev _tier is not the index in the tiers but the actual number of the tier (1 for tier1, 2 for tier2..., N for tierN)
    * @param _tier uint tier to check threshold
    * @return minimum of vinci needed to qualify as _tier (inclusive threshold)
    */
    function readTierThresholdInVinci(uint _tier) external view returns (uint) {
        require(_tier <= tiersThresholdsInVinci.length, "Input _tier too high");
        return tiersThresholdsInVinci[_tier - 1];
    }

    // ---------------------------------------------------------- //
    //                  Pool management functions                  //
    // ---------------------------------------------------------- //

    /**
    @notice Allows the pool owner to change the pool fee. This fee is charged on the staking rewards.

    @dev This function only updates balances of the users in the pool. This creates a slightly inconsistent state between pools.
    However that this function does not update the user.lastFullStateUpdateTimestamp, so any other user operation will fix this inconsistent state
    Moreover the isUserStateUpdated() function will return that user is not updated

    Requirements:
        only current pool owner can execute
        new fee must be > 0 .
    */
    function setPoolFee(uint _poolId, uint _newFeeInGwei) external {
        // the owner check already checks if pool exists
        require(pools[_poolId].poolOwner == _msgSender(), 'only pool owner can change the pool ownership');
        require(_newFeeInGwei >= 0, 'negative values not allowed for _newFeePercInGwei');
        // update balances of all users in pool, which charges also pool fees on existing rewards, befor setting new fee
        // store stakeholders in memory to avoid gas cost of storage reading
        address[] memory _poolStakeholders = pools[_poolId].stakeholders;
        for (uint u; u < pools[_poolId].stakeholders.length; u++) {
            _updateUserPoolBalances(_poolId, _poolStakeholders[u]);
        }
        pools[_poolId].poolFeeInGwei = _newFeeInGwei;
        emit PoolFeeUpdated(_poolId, _newFeeInGwei);
    }

    /**
    @notice transfers the pool ownership to a new address

    @dev Emits a {PoolOwnershipTransferred} event

    Requirements:
        only current pool owner can execute
        _newOwner address is not null

    */
    function transferPoolOwnership(uint _poolId, address _newOwner) external {
        require(_newOwner != address(0), 'null address cannot be pool owner');
        require(poolExists(_poolId), '_poolId does not exist yet');
        require(_msgSender() == pools[_poolId].poolOwner, 'only current owner can transfer ownership');

        // pool fees should be updated everytime a user gets staking rewards updated. Should be ready to go
        pools[_poolId].poolOwner = _newOwner;
        emit PoolOwnershipTransferred(_poolId, _newOwner);
    }

    /**
    @notice Allows the pool owner to claim staking rewards given to the pool. Note that only the claimable balance will be sent, which is only the rewards generated before the last checkpoint.
    @dev Requirements:
        ERC20 approved token
        poolid must exist
        only pool owner can execute
    */
    function claimPoolRewards(uint _poolId) external lock {
        require(poolExists(_poolId), '_poolId does not exist yet');
        require(_msgSender() == pools[_poolId].poolOwner, 'only current owner can transfer ownership');

        uint _amount = pools[_poolId].ownerClaimable;
        delete pools[_poolId].ownerClaimable;
        vinciERC20.transfer(_msgSender(), _amount);
    }

    /**
    @notice Checks if the checkpoint of a pool owner has passed, and if so, it updates the balances (unclaimable becomes claimable)

    @dev Any wallet can execute this function, which means the contract owner can update this for the pool owners
    */
    function evaluatePoolOwnerCheckpoint(uint _poolId) public {
        // max 1 day of checkpoint miss management
        if (block.timestamp - pools[_poolId].ownerLastCheckpointRevision > (1 days)) {
            if (block.timestamp > pools[_poolId].ownerNextCheckpoint) {
                _resetPoolOwnerCheckpoint(_poolId, true);
            }
        }
        pools[_poolId].ownerLastCheckpointRevision = block.timestamp;
    }

    // ---------------------------------------------------------- //
    //                 Internal functions                         //
    // ---------------------------------------------------------- //

    /**
    @dev Creates a new user and initializes some relevant storage variables

    emits {NewStakeHolderRegistered} event
    */
    function _registerNewStakeholder(address _user) internal {
        // add address to stakeholders
        users[_user].registered = true;
        users[_user].lastFullStateUpdateTimestamp = block.timestamp;

        // airdrops go to default vinci pool, so poolid=0 must be active for all users from the start
        _registerUserInPool(0, _user);
        stakeholders.push(_user);

        // 6 months until next staing. Storing in memory to save gas
        uint _delayMultiplier = 6;
        users[_user].delayMultiplier = _delayMultiplier;
        users[_user].nextCheckpointTimestamp = block.timestamp + _delayMultiplier * checkpointBlockDuration;
        emit NewStakeHolderRegistered(_user);
    }

    /**
    @dev This handles an ERC20 transfer of vinci from msgSender's wallet to the contract
    WARNING: this function receives the vinci tokens, but they are NOT accounted in any balance. It is responsibility of the function invoking this method to update the necessary balances

    Requires vinci ERC20 approvals

    Requires non zero balance of vinci in the msg.sender wallet
    */
    function _transferVinciToContract(uint _amount) internal {
        // the below require also checks _amount > 0
        require(vinciERC20.balanceOf(_msgSender()) >= _amount, 'not enough vinci tokens in msg.sender wallet');
        vinciERC20.transferFrom(_msgSender(), address(this), _amount);
        emit VinciTransferredToContract(_msgSender(), _amount);
    }

    /**
    @dev Simply stores pool information as users attributes
    */
    function _registerUserInPool(uint _poolId, address _user) internal {
        if (!users[_user].activePoolsMap[_poolId]) {
            users[_user].everActvePools.push(_poolId);
            users[_user].activePoolsMap[_poolId] = true;
        }
    }

    /**
    @dev re-evaluates the tier of a user based on the current vinci balance and current tier thresholds
    A new tier is set, overwriting the current one. No updates to checkpoints are done here

    Emits {UserTierReset} event
    */
    function _resetUserTier(address _user) internal {
        // realise first staking rewards in all pools before calculating tier incase they have scheduled unstake
        updateUserState(_user);

        // if balance is not above none of the thresholds, return tier 0
        uint userStakedBalance = users[_user].totalStaked;
        uint oldTier = usersTiers[_user];

        // update memory variable recursively and keep the highest one
        uint newTier;
        for (uint t = 1; t <= tiersThresholdsInVinci.length; t++) {
            if (userStakedBalance >= tiersThresholdsInVinci[t - 1]) {
                newTier = t;
            }
        }

        // update tier balances for penalty pot calculations if user tier changes
        if (oldTier != newTier) {
            totalStakedPerTier[oldTier] -= userStakedBalance;
            totalStakedPerTier[newTier] += userStakedBalance;
        }
        usersTiers[_user] = newTier;
        emit UserTierReset(_user, oldTier, newTier);
    }

    /**
    @dev Updates the timestamp of the next checkpoint for the user and takes care of unstaking the scheduled unstaking
    Converts the unclaimable & scheduledUnstake balance into claimable (accessible via claim())
    If not zero, it also decreases the multiplier for the next checkpoint. This allows to go from 6 months checkpoints to 5 months, 4, 3  ... Mimimum multiplier is 1 (1 month checkpoints
    This function does NOT update pool balances. It is responsability of other functions to do that

    Emits {UserCheckpointReset} event

    @param _decreaseCheckpointMultiplier amount to decrease the multiplier. If 0, nothing is changed and next checkpoint comes after the same amount of time
    */
    function _resetUserCheckpoint(address _user, bool _decreaseCheckpointMultiplier) internal {
        // add all the scheduled unstakes in memory instead of modifying storage variables (gas savings)
        uint totalScheduledUnstake;
        uint[] memory everActivePools = users[_user].everActvePools;
        for (uint i = 0; i < everActivePools.length; i++) {

            // the the activePoolsMap saves gas if pool is no longer active
            if (users[_user].activePoolsMap[everActivePools[i]]) {
                uint _poolId = everActivePools[i];
                uint poolScheduleUnstaking = pools[_poolId].scheduledUnstaking[_user];

                // when tokens are moved to claimbable, they are accessible to the user via the claim() function
                pools[_poolId].claimable[_user] += pools[_poolId].unclaimable[_user];
                pools[_poolId].claimable[_user] += poolScheduleUnstaking;

                // delete balances to get some gas back whilte resetting them to 0
                delete pools[_poolId].scheduledUnstaking[_user];
                delete pools[_poolId].unclaimable[_user];

                totalScheduledUnstake += poolScheduleUnstaking;
                pools[_poolId].totalStaked -= poolScheduleUnstaking;
            }
        }
        // update tiers and total contract staked
        users[_user].totalStaked -= totalScheduledUnstake;
        totalStakedPerTier[usersTiers[_user]] -= totalScheduledUnstake;
        totalStakedInContract -= totalScheduledUnstake;

        uint oldCheckpoint = users[_user].nextCheckpointTimestamp;
        users[_user].nextCheckpointTimestamp += (checkpointBlockDuration * users[_user].delayMultiplier);
        // after every checkpoint, the number of 30day blocks is reduced by one until a minimum of 1
        if ((_decreaseCheckpointMultiplier) && (users[_user].delayMultiplier > 1)) {
            users[_user].delayMultiplier -= 1;
        }

        // grant super staker stataus when they cross a checkpoint with some staking left
        if (users[_user].totalStaked > 0) {
            users[_user].superstaker = true;
        }

        // reevaluate tier in case they had some scheduled unstaking
        _resetUserTier(_user);

        emit UserCheckpointReset(_user, oldCheckpoint, users[_user].nextCheckpointTimestamp);
    }

    /**
    @dev distributes tokens to all users with a certain tier or above, in a weighted fashion. The amount airdropped to a user is proportional to their stake compared to the total staking
    This function does NOT update users state to avoid running out of gas

    Requirements:
        positive amount and _minimumTier
        _minimumTier must also be below the current thresholds length to exist
        Note that this internal function does NOT request an ERC20 token to fund the contract, so the tokens MUST be already in the contract

    Emits {Airdropped} event
    */
    function _weightedTokenDistribution(uint _amount, uint _minimumTier) internal {
        // rewards/claimable/unclaimable are not relevant to calculate the weights --> no need to update balances yet
        require(_amount > 0, 'Only non-zero _amount allowed');
        require((_minimumTier >= 0) && (_minimumTier < tiersThresholdsInVinci.length), 'Tier non existing');

        // the total stake to calculate weights is the sum of the stakes of all tiers above _minimumTier
        uint totalElegibleStaked = 0;
        for (uint tier = _minimumTier; tier < tiersThresholdsInVinci.length; tier++) {
            totalElegibleStaked += totalStakedPerTier[tier];
        }

        if (totalElegibleStaked > 0) {
            for (uint a = 0; a < stakeholders.length; a++) {
                if (usersTiers[stakeholders[a]] >= _minimumTier) {
                    uint userAirdropAmount = _amount * users[stakeholders[a]].totalStaked / totalElegibleStaked;
                    // update only the unclaimable balances, as all airdrops can only be claimed once checkpoint has passed
                    pools[0].unclaimable[stakeholders[a]] += userAirdropAmount;
                    emit Airdropped(stakeholders[a], userAirdropAmount);
                }
            }
        } else {
            stakingRewardsFunds += _amount;
            emit FundedStakingRewardsFund(_amount);
        }
    }

    /**
    @dev internal function to perform the stake into a pool. If user is not registered yet, it will be registered
    Requirements
        ERC20 token approvals
        poolId exists
        positive staked amount
    Emits {Staked} event
    */
    function _stake(uint _poolId, uint _amount, address _user) internal lock {
        require(poolExists(_poolId), 'poolId not found');
        require(_amount > 0, 'stake amount cannot be 0');
        // check if the user is a newcomer before registering it in pool or updating any balances
        bool firstTimeStaker = !users[_user].registered;

        // make sure staking rewards are first updated
        _updateUserPoolBalances(_poolId, _user);

        // the _registerUserInPool function is smart enough to check first if the user is already registered there
        _registerUserInPool(_poolId, _user);

        // transfer tokens to contract
        _transferVinciToContract(_amount);

        // update balances
        pools[_poolId].activeStaking[_user] += _amount;
        pools[_poolId].totalStaked += _amount;
        users[_user].totalStaked += _amount;
        totalStakedPerTier[usersTiers[_user]] += _amount;
        totalStakedInContract += _amount;

        // register user if not registered and sets tier and first checkpoint
        if (firstTimeStaker) {
            _registerNewStakeholder(_user);
            _resetUserTier(_user);
        }
        // user will not be able to move funds out of this pool for a little bit (unstaking is fine)
        _movementLock(_poolId, _user);

        emit Staked(_user, _amount, _poolId);
    }

    /**
    @dev imposes a lock that impedes the fund movements out of this pool for a certain period. Does not affect unstakinge
    */
    function _movementLock(uint _poolId, address _user) internal {
        // we dont care about vinci default pool, they can move it away from this one at any time
        if (_poolId != 0) {
            pools[_poolId].movementLock[_user] = block.timestamp + epochDuration;
        }
    }
    /**
    @dev Updates the staking rewqards balances of a user in a pool.
    staking rewards tokens come out of the StakingRewardsFunds balance of the contract
    The pool fees are taken from the staking rewards before they reach the unclaimable balance. In that way, what the user sees in the unclaimble balance it has already discounted the pool fees
    Also, the tokens that were unstaked in previous blocks, are check to see if they can be unlocked, and therefore moved to the claimable balance as well
    Note that the lastUpdated timestamp of a user in a pool must be older than an epoch. Otherwise no update is performed.

    This function does not update the checkpoint information. Thus, if the function is called when needsCheckpointUpdate()=True, the new unclaimable rewards will mix with the current unclaimable, which will become claimable as soon as checkpoint is updated
    It is the off-chain responsibility to keep the checkpoints up to date for all users by using updateUserState()

    Emits {UserPoolBalancesUpdated} event

    */
    function _updateUserPoolBalances(uint _poolId, address _user) internal {
        require(poolExists(_poolId), 'poolId not found');

        // no need to spend more gas if user has never staked here before
        if (pools[_poolId].lastUpdated[_user] == 0) {
            pools[_poolId].lastUpdated[_user] = block.timestamp;
        } else if (block.timestamp > pools[_poolId].lastUpdated[_user]) {
            // update regardless of when was last update (except if it was in the same block). We only stop from updatimg multiple times in the same block
            uint timeSinceLastReward = block.timestamp - pools[_poolId].lastUpdated[_user];

            uint staking = (pools[_poolId].activeStaking[_user] + pools[_poolId].scheduledUnstaking[_user]);
            uint rewards = (staking * APRrate * timeSinceLastReward) / (365 days * 100 gwei);
            // staking rewards come out of the stakingRewardsFunds!
            require(stakingRewardsFunds >= rewards, 'not enough vinci funds in contract to update rewards');
            stakingRewardsFunds -= rewards;

            uint poolFeeTaken = rewards * pools[_poolId].poolFeeInGwei / (100 gwei);
            pools[_poolId].ownerUnclaimable += poolFeeTaken;
            pools[_poolId].unclaimable[_user] += (rewards - poolFeeTaken);

            // update this update tracker for next times
            pools[_poolId].lastUpdated[_user] = block.timestamp;

        }
        // update claimable with unstaking tokens if the lock has passed
        if (block.timestamp > pools[_poolId].emergencyUnlock[_user]) {
            pools[_poolId].claimable[_user] += pools[_poolId].currentlyUnstaking[_user];
            delete pools[_poolId].currentlyUnstaking[_user];
            pools[_poolId].emergencyUnlock[_user] = block.timestamp + (100 * 365 days);
        }

        emit UserPoolBalancesUpdated(_poolId, _user);
    }

    /**
    @dev if all balances of a user in a certain pool are zero, we can deactivate that pool to save gas when iterating through the user's pool
    */
    function _attemptDeactivatePoolForUser(uint _poolId, address _user) internal {
        if (pools[_poolId].activeStaking[_user] + pools[_poolId].scheduledUnstaking[_user] + pools[_poolId].currentlyUnstaking[_user] + pools[_poolId].unclaimable[_user] + pools[_poolId].claimable[_user] == 0) {
            users[_user].activePoolsMap[_poolId] = false;
        }
    }

    /**
    @dev converts the unclaimable balances of a pool owner into claimable and postpones the checkpoint
    Note that if the users have not their state updated, the rewards converted into claimable will not be complete. These rewards will come on the next checkpoint

    Emits {PoolOwnerCheckpointReset} event

    Requirements: poolId exists
    */
    function _resetPoolOwnerCheckpoint(uint _poolId, bool _decreaseMultiplier) internal {
        require(poolExists(_poolId), 'poolId not found');

        pools[_poolId].ownerClaimable += pools[_poolId].ownerUnclaimable;
        delete pools[_poolId].ownerUnclaimable;

        uint oldCheckpoint = pools[_poolId].ownerNextCheckpoint;
        pools[_poolId].ownerNextCheckpoint += checkpointBlockDuration * pools[_poolId].ownerNextCPmultiplier;

        // after every checkpoint, the number of 30day blocks is reduced by one until a minimum of 1
        if ((_decreaseMultiplier) && (pools[_poolId].ownerNextCPmultiplier > 1)) {
            pools[_poolId].ownerNextCPmultiplier -= 1;
        }
        emit PoolOwnerCheckpointReset(_poolId, oldCheckpoint, pools[_poolId].ownerNextCheckpoint);
    }

    /**
    @dev pools are created only by contract owner. This might be reviewed in future versions

    Emits {PoolCreated} event

    @param _poolPercFeeInGwei percentage , where 1 gwei == 1 % fee
    @param _poolOwner address
    */
    function _createStakingPool(
        uint _poolPercFeeInGwei,
        address _poolOwner
    ) public onlyOwner returns (uint){
        uint _poolId = existingPoolIds.length;
        require(!poolExists(_poolId), 'poolId already exists');
        pools[_poolId].poolOwner = _poolOwner;
        pools[_poolId].poolFeeInGwei = _poolPercFeeInGwei;
        existingPoolIds.push(_poolId);

        // update pool owner checkpoint information (store multiplier in memory variable to save gas cost)
        uint multiplier = 6;
        pools[_poolId].ownerNextCPmultiplier = multiplier;
        pools[_poolId].ownerNextCheckpoint = multiplier * checkpointBlockDuration;

        emit PoolCreated(_poolId, _poolOwner, _poolPercFeeInGwei);
        return _poolId;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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