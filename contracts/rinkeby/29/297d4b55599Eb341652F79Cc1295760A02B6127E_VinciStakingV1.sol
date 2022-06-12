// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14 <0.9.0;

import "ERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";


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
/// @dev VINCI
contract VinciStakingV1 is Ownable {
    using SafeERC20 for ERC20;

    /// ERC20 vinci token address
    ERC20 public vinciERC20;

    /// array of vinci stakeholders. Added when they stake, removed when they fully unstake (or cross a checkpoint with full scheduled unstake)
    address[] public stakeholders;
    /// index of each user in the stakeholders array
    mapping(address => uint) public indexStakeholders;

    /// user tokens that are staked (earning APR), and not scheduled to be unstaked in next checkpoint
    mapping(address => uint) public activeStaking;
    /// user tokens that are staked (earning APR), but are scheduled to be unstaked in next checkpoint
    mapping(address => uint) public scheduledUnstaking;
    /// user tokens that are currently retrievable via the claim() function
    mapping(address => uint) public claimable;
    /// user tokens earned that are not yet claimable. They will become claimable when crossing a checkpoint. These come from staking APR, airdrops or penaltyPot distributions
    mapping(address => uint) public unclaimable;
    /// user last timestamp when the staking rewards were updated in the user balances
    mapping(address => uint) public lastStakingRewardsUpdate;
    /// user tokens that are currently unstaking, and will become available 14 days after the last unstake action
    mapping(address => uint) public currentlyUnstaking;
    /// timestamp when currentlyUnstaking tokens will become available for the user (if they do not unstake again)
    mapping(address => uint) public unlockTime; // Time from unstaking to claimable
    /// percentage (with 1e9 decimals) of APR rewards that the user gives to the pool owners. By default it is 0, which means that 100% goes to the user APR
    mapping(address => uint) public pledgeShare;
    /// user timestam when next checkpoint can be crossed
    mapping(address => uint) public checkpoint;
    /// checkpoints are postponed in multiples of 30 days. The checkpointReduction is how many blocks of 30 days the current checkpoint has been reduced from the baseCheckpointMultplier.
    mapping(address => uint) public checkpointMultiplierReduction; // Initialized at 0, increasing up to 5
    /// defines if a user has the sueprstaker status or not. This status is granted for users crossing a checkpoint with non-zero stake
    mapping(address => bool) public superstaker;
    /// user tier which is granted according to the tier thresholds in vinci. Tiers are re-evaluated in certain occasions (unstake, relock, crossing a checkpoint)
    mapping(address => uint) public tier;

    /// base APR earned via staking. This APR is shared between the user and the pool owners, and the distribution depends on the pledgeShare
    /// expressed in percentage with 1e9 decimals
    uint public baseAPR = 5.5 gwei;
    /// contract funds of vinci tokens to be used for staking rewards
    uint public stakingRewardsFunds;
    /// balance of vinci tokens collected via the penalization happening when executing unstake() function
    uint public penaltyPot;
    /// balance of vinci tokens fees collected for the pool owners, based on the stakes, the baseAPR and the pledgeShare
    uint public ownersPot;

    /// the checkpoint multiplier is reduced by 1 block every time a user crosses a checkpoint. The starting multiplier is this
    uint internal constant baseCheckpointMultiplier = 6;
    /// the duration of the checkpoint block, which is meant to be 30 days
    uint public checkpointBlockDuration;
    /// how long a user must wait from the moment of unstaking until the tokens are claimable
    uint public unstakingDuration;

    /// an array of thresholds which defines the minimum vinci to be staked by a user in order to have certain tiers
    uint[] public tiersThresholdsInVinci;

    // Events
    event Staked(address indexed user, uint256 amount, uint poolid);
    event Unstaked(address indexed user, uint256 amount, uint poolid);
    event CanceledUnstaking(address indexed user);
    event ScheduledUnstake(address indexed user, uint256 amount, uint poolid, uint currentNextCheckpoint);
    event ScheduledUnstakeComplete(address indexed user, uint256 amount);
    event ScheduledUnstakeCancelled(address indexed user);
    event Claimed(address indexed user, uint256 amount);
    event Reallocated(address indexed user, uint256 amount, uint fromPoolId, uint toPoolId);
    event VinciTransferredToContract(address from, uint amount);
    event FundedStakingRewardsFund(uint amount);
    event AirdroppedFromPenaltyPot(uint totalAmount, uint nUsers);
    event AirdroppedFromRewardsFund(address indexed user, uint amount);
    event AirdroppedFromWallet(address indexed user, uint amount);
    event TiersThresholdsUpdated(uint[] vinciThresholds);
    event TierSet(address indexed user, uint newTier);
    event CheckpointSet(address indexed user, uint newCheckpoint);
    event NotEnoughFundsToGiveRewards(uint rewards, uint stakingRewardsFund);
    event CollectedFeesWithdrawn(address to, uint amount);
    event SuperstakerGranted(address indexed user);
    event SuperstakerRemoved(address indexed user);
    event OwnersPotUpdated(uint poolFeeTaken, address user);
    event UserPledgeShareUpdated(address indexed user, uint percentage);
    event RelockTokens(address indexed user);
    event UserBalancesUpdated(address indexed user);
    event CheckpointCrossed(address indexed user);

    /**
    @dev    deploys the vinci staking contract. Needs funding to work properly,
            in order to interact with the contract, the users need to approve vinci ERC20 tokens in advance
    @param  _vinciTokenAddress          vinci erc20 token contract address
    @param  _tiersThresholdsInVinci     an array of thresholds defining the tiers in vinci values
    @param  _checkpointBlockDuration    duration (in seconds) of the checkpoint blocks (meant to be 30 days)
    @param  _unstakingDuration          duration (in seconds) from when a user unstakes until the tokens are claimable
    */
    constructor(
        ERC20 _vinciTokenAddress,
        uint[] memory _tiersThresholdsInVinci,
        uint _checkpointBlockDuration,
        uint _unstakingDuration
    ) {
        vinciERC20 = _vinciTokenAddress;
        tiersThresholdsInVinci = _tiersThresholdsInVinci;
        checkpointBlockDuration = _checkpointBlockDuration;
        unstakingDuration = _unstakingDuration;
    }

    // reentrancy lock
    uint private locked = 0;
    modifier lock() {
        require(locked == 0, 'reentrancy guard locked');
        locked = 1;
        _;
        locked = 0;
    }

    /// ================ Modifiers ================

    /// ensures that user balances are updated (staking rewards and unstaking tokens)
    modifier updateBalances(address sender) {
        // Also as function so as to be called externally
        updateUserBalances(sender);
        _;
    }

    /// ensures that a user checkpoint is always updated before executing other sensible functions
    modifier checkpointUpdated(address _user) {
        if (_existingUser(_user) && (block.timestamp > checkpoint[_user])) {
            _crossCheckpoint(_user);
        }
        _;
    }

    /// ================== User functions =============================
    /**
    @dev    Emits a {Staked} event.
            Requirements: see _stake() requirements
            staking rewards, unstaking tokens and checkpoints need to be updated, so the corresponding modifiers are used
    @notice stake vinci tokens into a specific pool into the msgSender staking balance.
    @param  _amount      amount of vinci tokens
    @param  _poolId      unique id of the pool to stake to
    */
    function stake(
        uint _amount,
        uint _poolId
    ) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        _stake(_msgSender(), _amount, _poolId);
    }

    /**
    @dev    essentially the same as stake(), but with the onlyOwner modifier.
            emits a {Staked} event
            staking rewards, unstaking tokens and checkpoints need to be updated, so the corresponding modifiers are used
    @notice The owner can stake tokens to users using this function to allow them to stake before the token distribution
    @param _amount      amount of vinci tokens
    @param _poolId      unique id of the pool to stake to.
    @param _to          user receiving the stake
    */
    function stakeTo(
        uint _amount,
        uint _poolId,
        address _to
    ) external onlyOwner updateBalances(_to) checkpointUpdated(_to) {
        // cannot use checkpointUpdated modifier here, because it is not msg.sender we want to update
        _stake(_to, _amount, _poolId);
    }

    /**
    @dev    emits an {Unstaked} event
            staking rewards, unstaking tokens and checkpoints need to be updated, so the corresponding modifiers are used
    @notice a function to unstake staked tokens by taking a penalty in the unclaimable balance. After executing the
            function, the tokens are locked for two weeks before the user can actually claim them
    @param  _amount     amount of vinci tokens
    @param  _poolId     unique id of the pool to unstake from.
    */
    function unstake(
        uint _amount,
        uint _poolId
    ) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        _unstake(_msgSender(), _amount, _poolId);
    }

    /**
    @dev    emits {CancelScheduledUnstake} event
            staking rewards, unstaking tokens and checkpoints need to be updated, so the corresponding modifiers are used
    @notice allows the user to schedule some tokens to be unstaked in the next checkpoint. As soon as the checkpoint is crossed, the tokens are claimable
    @param  _amount     amount of vinci tokens
    @param  _poolId     unique id of the pool to unstake from.
    */
    function scheduleUnstake(
        uint _amount,
        uint _poolId
    ) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        require(_amount <= activeStaking[sender], 'Not enough active staking to schedule to unstake');

        scheduledUnstaking[sender] += _amount;
        activeStaking[sender] -= _amount;

        emit ScheduledUnstake(sender, _amount, _poolId, checkpoint[sender]);
    }

    /**
    @dev    the scheduled tickets to unstake cannot be directly unstake using unstake(). First they need to be cancelled with this function
            emits {ScheduledUnstakeCancelled} event
            staking rewards, unstaking tokens and checkpoints need to be updated, so the corresponding modifiers are used
    @notice allows a user to cancel the scheduled tickets to unstake. When doing this, there is no possibility of canceling a specific amount, but all scheduled amount is cancelled
    */
    function cancelScheduledUnstake() external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        require(scheduledUnstaking[sender] > 0, 'User must have scheduled unstaking > 0');
        activeStaking[sender] += scheduledUnstaking[sender];
        delete scheduledUnstaking[sender];

        emit ScheduledUnstakeCancelled(sender);
    }

    /**
    @dev    lock is used due to interaction with external contracts
            emits {Claimed}
            staking rewards, unstaking tokens and checkpoints need to be updated, so the corresponding modifiers are used
    @notice user can claim tokens to be received in the wallet. Only the tokens that are under claimableBalance() are subject to be claimed
    */
    function claim() external lock updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        uint amount = claimable[sender];
        if (amount > 0) {
            delete claimable[sender];
            vinciERC20.safeTransfer(sender, amount);
        }
        // Emit event even if amount = 0.
        emit Claimed(sender, amount);
    }

    /**
    @dev    requires that the user exists to avoid conflicts with the _finishStakeholder function
            If user has no stake, it is terminated (removed tier, superstaker status, checkpoint is reset)
            emits {RelockTokens} event
    @notice user tier is reevaluated, allowing user to upgrade (or downgrade) at the cost of postponing the checkpoint the same number of months as the current multiplier
    */
    function relock() external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        address sender = _msgSender();
        require(_existingUser(sender), 'Not authorized to run this function with zero stake');
        _setTier(sender, calculateTier(stakingBalance(sender)));
        _postponeCheckpoint(sender, false);
        emit RelockTokens(sender);
    }

    /**
    @dev    This has no on-chain effect as the branded pools are managed offchain. This function only emits events for transparency and traceability
            emits {UserBalancesUpdated} event
    @notice allows a user to move staked tokens from one branded pool to another.
    @param  _originPool         unique id of the pool from which tokens are removed
    @param  _destinationPool    unique id of the pool to which tokens are moved
    @param  _amount             number of tokens to move
    */
    function moveFunds(
        uint _originPool,
        uint _destinationPool,
        uint _amount
    ) external updateBalances(msg.sender) checkpointUpdated(msg.sender) {
        // this function is intended to only emit an event
        // we cannot check the actual balance in the pool, only the total balance
        require(activeStaking[_msgSender()] > 0, 'no staking funds');
        require(_amount <= activeStaking[_msgSender()], 'Amount should not exceed active staking balance');
        emit Reallocated(_msgSender(), _amount, _originPool, _destinationPool);
    }

    /**
    @dev    Checkpoints are not evaluated in this function, only staking rewards balances and currently unstaking tokens
    @notice this function updates the staking rewards balances of a user, taking the tokes from the staking rewards
    fund, and also updates if tokens that are currently unstaking have passed the unlock time, then these become claimable
    */
    function updateUserBalances(address _user) public {

        if (lastStakingRewardsUpdate[_user] == block.timestamp) return;

        bool rewardsUpdated = true;
        uint baseStakingRewards;

        if (stakingBalance(_user) > 0)
            baseStakingRewards = _calculateBaseStakingRewardsSinceLastUpdate(_user);

        if (baseStakingRewards > 0) {// avoid update state variables if there is no rewards
            // staking rewards come out of the stakingRewardsFund!
            if (baseStakingRewards > stakingRewardsFunds) {
                emit NotEnoughFundsToGiveRewards(baseStakingRewards, stakingRewardsFunds);
                // dont update lastStakingRewardsUpdate on purpose, as rewards have not been updated
                rewardsUpdated = false;
            } else {
                stakingRewardsFunds -= baseStakingRewards;
                uint poolFeeTaken = (baseStakingRewards * pledgeShare[_user]) / (100 gwei);
                uint userRewards = baseStakingRewards - poolFeeTaken;

                if (poolFeeTaken > 0) {
                    ownersPot += poolFeeTaken;
                    emit OwnersPotUpdated(poolFeeTaken, _user);
                }
                if (userRewards > 0) {
                    unclaimable[_user] += userRewards;
                }
            }
        }
        if (rewardsUpdated) {
            lastStakingRewardsUpdate[_user] = block.timestamp;
        }

        // Unstaking -> claimable if lock has passed
        _currentlyUnstakingToClaimable(_user);

        emit UserBalancesUpdated(_user);

    }

    /// ==================== View functions should expose the potential realizations =================
    /**
    @dev    note that this function calculates the balance, but dont change the EVM state
    @notice Includes both the active staking and the scheduled tokens to be unstaked in next checkpoint
    @param  _user user to read balances from
    @return total staking generating rewards
    */
    function stakingBalance(address _user) public view returns (uint) {
        return activeStaking[_user] + scheduledUnstaking[_user];
    }

    /**
    @dev    note that this function calculates the balance, but dont change the EVM state
    @param  _user user to read balances from
    @notice It also subtracts the pool fees
    @return Estimates the staking rewards of a user since the last time the rewards were updated
    */
    function estimateStakingRewardsSinceLastUpdate(address _user) external view returns (uint) {
        return _calculateUserStakingRewardsSinceLastUpdate(_user);
    }

    /**
    @dev    note that this function calculates the balance, but dont change the EVM state
    @notice includes both the generated user staking rewards and the current unclaimable balance
    @param  _user user to read balances from
    @return total tokens that are not claimable yet until crossing next checkpoint
    */
    function unclaimableBalance(address _user) public view returns (uint) {
        uint userRewards = _calculateUserStakingRewardsSinceLastUpdate(_user);
        return unclaimable[_user] + userRewards;
    }

    /**
    @dev    note that this function calculates the balance, but dont change the EVM state
    @notice includes multiple balances that were converted to claimable after crossing a checkpoint
            scheduled tokens after crossing a checkpoint and the rewards that became claimable
    @param  _user user to read balances from
    @return tokens that can be claimed at the moment.
    */
    function claimableBalance(address _user) public view returns (uint) {
        uint _claimable = claimable[_user];
        // Unstaking that is potentially unlocked should show here, as it will be updated in updateBalances()
        if ((block.timestamp > unlockTime[_user]) && (currentlyUnstaking[_user] > 0)) {
            _claimable += currentlyUnstaking[_user];
        }
        return _claimable;
    }

    /**
    @dev    if the user unstakes during the unstaking process, the unlock time is postponed for ALL tokens
    @notice Tokens that the user has currently on the unstaking process. They will be unlocked for 2 weeks since the last unstake action
    @param  _user user wallet address
    @return amount of tokens currently unstaking
    */
    function currentlyUnstakingBalance(address _user) public view returns (uint) {
        if (block.timestamp > unlockTime[_user]) return 0;
        return currentlyUnstaking[_user];
    }

    /**
    @dev    the effect is the same as reading the mapping scheduleUnstaking(user)
    @notice user tokens that are scheduled to be unstaked when the next checkpoint is crossed
    @return number of tokens scheduled to unstake
    */
    function scheduledUnstakingBalance(address _user) public view returns (uint) {
        return scheduledUnstaking[_user];
    }

    /**
    @dev    it also returns true for a non-existing user as checkpoint=0
            Checkpoint info updated means that the checkpoint is in the future and it is not possible to cross it
    @notice informs if a user can cross a checkpoint right now
    @param  _user user wallet address
    @return returns False if the user can cross a checkpoint at the moment. Else returns True
    */
    function isUserCheckpointUpdated(address _user) public view returns (bool) {
        return !_existingUser(_user) ? true : checkpoint[_user] > block.timestamp;
    }

    /**
    @notice     The length of the array determines the number of tiers. First element is tier1, second element tier2, etc
    @return     an array of the minimum vinci amounts for each tier
    */
    function readTierThresholdsInVinci() external view returns (uint[] memory) {
        return tiersThresholdsInVinci;
    }

    /**
    @notice Allows to read one specific tier threshold
    @param _tier must be greater than zero and max value is the current number of tiers
    @return the minimum amount of vinci required to enter in _tier
    */
    function readTierThresholdInVinci(uint _tier) external view returns (uint) {
        require(_tier <= tiersThresholdsInVinci.length, 'Non existing tier');
        return (_tier > 0) ? tiersThresholdsInVinci[_tier - 1] : 0;
    }

    /**
    @dev    function visibility is external to avoid being used inside the contract
    @notice calculates the total tokens staked across all stakeholders
    @return total vinci staked in the contract across all stakeholders
    */
    function readTotalStaked(bool _requireSuperstaker) external view returns (uint){
        uint totalStaked = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
            if ((!_requireSuperstaker) || (_requireSuperstaker && superstaker[stakeholders[i]])) {
                totalStaked += activeStaking[stakeholders[i]] + scheduledUnstaking[stakeholders[i]];
            }
        }
        return totalStaked;
    }

    /**
    @dev    function visibility is external to avoid being used inside the contract
    @notice returns the total stake. It allows to filter based on the superstaker status to return only the total stake among superstakers
    @param  _requireSuperstaker if True, only superstakers are used for calculating the total
    @return total staked tokens or total staked tokens among superstaker class
    */
    function readTotalActiveStaking(bool _requireSuperstaker) external view returns (uint){
        uint totalActive = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
            if ((!_requireSuperstaker) || (_requireSuperstaker && superstaker[stakeholders[i]])) {
                totalActive += activeStaking[stakeholders[i]];
            }
        }
        return totalActive;
    }

    /**
    @dev    function visibility is external to avoid being used inside the contract
            the veracity of this results depends on each user checkpoints being updated
    @notice calculates the total tokens staked across all stakeholders
    @return total vinci staked in the contract across all stakeholders
    */
    function readTotalScheduledUnstaking() external view returns (uint){
        uint totalStaked = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
            totalStaked += scheduledUnstaking[stakeholders[i]];
        }
        return totalStaked;
    }

    /**
    @notice Returns the tier associated to the given amount
    @param  _amount number of vinci tokens
    */
    function calculateTier(uint _amount) public view returns (uint) {
        uint newTier;
        if (_amount < tiersThresholdsInVinci[0]) {
            return 0;
        } else {
            for (uint tier = 1; tier <= tiersThresholdsInVinci.length; tier++) {
                if (_amount >= tiersThresholdsInVinci[tier - 1]) {
                    newTier = tier;
                }
            }
            return newTier;
        }
    }

    /// ================ Contact management =============
    /**
    @dev    reentrancy lock is used as calls an external contract (ERC20).
            onlyOwner is not used here to allow any wallet funding the contract
            Requires ERC20 token approvals
    @notice Fund the staking contract with Vinci tokens for staking rewards. Funds cannot be ever retrieved
    @param  _amount     amount of vinci tokens to be transferred to the contract
    */
    function fundContractWithVinci(uint _amount) external {
        _transferVinciToContract(_amount);
        stakingRewardsFunds += _amount;
        emit FundedStakingRewardsFund(_amount);
    }

    /**
    @dev    requires ERC20 approvals
            emits {AirdroppedFromWallet} event
            checkpointUpdated() modifier not used to save gas in pool airdrops
    @notice allows airdropping vinci tokens from the senders wallet to a user unclaimable balance
    @param  _amount     number of tokens to airdrop
    @param  _to         user address that will receive the tokens
    */
    function airdropFromWallet(uint _amount, address _to) external {
        _transferVinciToContract(_amount);
        unclaimable[_to] += _amount;
        emit AirdroppedFromWallet(_to, _amount);
    }

    /**
    @dev    emits {AirdroppedFromRewardsFund} event
            checkpointUpdated() modifier not used to save gas in pool airdrops
            only owner can execute, as it manages the stakingRewardsFund
    @notice allows airdropping vinci tokens from the staking rewards fund to a user unclaimable balance
    @param  _amount     number of tokens to airdrop
    @param  _to         user address that will receive the tokens
    */
    function airdropFromRewardsFund(uint _amount, address _to) external onlyOwner {
        require(stakingRewardsFunds >= _amount, 'Not enough StakingRewardsFunds in contract');
        stakingRewardsFunds -= _amount;
        unclaimable[_to] += _amount;
        emit AirdroppedFromRewardsFund(_to, _amount);
    }

    /**
    @dev Only valid during penalty pot distribution time window.

    @notice Similar to claimFromPenaltyPot, but to be called from owner to specifically distribute targeted users
    */

    /**
    @dev    requires ERC20 approvals
            emits {AirdroppedFromPenaltyPot} event
            checkpointUpdated() modifier not used to save gas
            only owner can execute, as it manages the penaltyPot
            At the end of the function, it checks that the total amount does not exceed the penalty pot
    @notice allows distributing the penalty pot in batches of max 50 users
    @param  _amounts    an array of amounts
    @param  _users      an array of users (matching the amounts)
    */
    function airdropFromPenaltyPot(uint[] calldata _amounts, address[] calldata _users) external onlyOwner {
        require(_users.length == _amounts.length, 'array lengths must match');
        require(_users.length < 50, "exceeded max batch size of 50");

        // we dont need to subtract from penaltyPot every time. Store in variable to save gas
        uint _totalAmount;
        for (uint i = 0; i < _users.length; i++) {
            // do not check if user is superstaker on purpose. Perhaps it was when the snapshot was taken but not anymore
            _totalAmount += _amounts[i];
            unclaimable[_users[i]] += _amounts[i];
        }
        // even though the requirement is after the whole loop is completed, if it is not met, the whole transaction will revert anyway
        // and in this way we avoid making two loops, so saves gas
        require(_totalAmount <= penaltyPot, 'sum of amounts exceeds penalty pot');
        penaltyPot -= _totalAmount;

        emit AirdroppedFromPenaltyPot(_totalAmount, _users.length);
    }

    /**
    @dev    requires that the user exists to avoid messing up the stakeholders array
            can only be crossed if the checkpoint timestamp has passed
            updates balances before crossing checkpoint, to udate the staking rewards and currently unstaking tokens
            it potentially emits {CheckpointSet}, {TierSet}, {SuperstakerGranted} if conditions are met
    @notice     triggers a checkpoint crossing for a user. This converts the unclaimable and scheduled-unstaking into
                claimable, reevaluates tier, and grants superstaker if user has non-zero stake at crossing
    @param      _user  user to cross the checkpoint
    */
    function crossCheckpoint(address _user) external {
        require(_existingUser(_user), 'Not allowed to cross checkpoint');
        require(block.timestamp > checkpoint[_user], 'user cannot cross checkpoint yet');
        updateUserBalances(_user);
        _crossCheckpoint(_user);
    }

    /**
    @dev    The contract owner will execute this periodically to follow the vinci price in usd
            emits {TiersThresholdsUpdated} event
            only owner can execute
    @notice allows the contract owner to change the tier thresholds (in vinci values). This is meant to be used to adapt the thresholds to the value in usd without the need of an oracle
    @param  thresholds an array of thresholds in vinci values
    */
    function updateTierThresholds(uint[] memory thresholds) external onlyOwner {
        require(thresholds.length > 0, 'input at least one threshold');
        delete tiersThresholdsInVinci;
        for (uint t = 1; t < thresholds.length; t++) {
            require(thresholds[t] > thresholds[t - 1], 'thresholds should be sorted ascending');
        }
        tiersThresholdsInVinci = thresholds;
        emit TiersThresholdsUpdated(thresholds);
    }

    /**
    @dev    The fees are collected and distributed to the different pool owners offchain
    @notice retrieves the fees collected from the staking rewards into the ownersPot and sends it to an external wallet
    @param  _amount number of vinci tokens to withdraw
    @param  _to     wallet to receive the withdrawal
    */
    function withdrawCollectedFees(uint _amount, address _to) external lock onlyOwner {
        require(_amount <= ownersPot, 'amount must be lower than owners pot');
        ownersPot -= _amount;
        vinciERC20.transfer(_to, _amount);
        emit CollectedFeesWithdrawn(_to, _amount);
    }

    /**
    @notice
    _percentage is a uint, that should represent a number between 0 and 100 but have 9 extra digits for decimals.
    Example _percentage = 80000000000 == 80% going for the pool owner and 20% ofr the user

    @dev
    The balances are updated before changing the pledge share, otherwise the calculated staking rewards would change
    emits {UserPledgeShareUpdated} event

    This function is only owner, because the pledge handling is partly centralized. contract owner sets the user pledge
    share based on how much he/she pledges into different artists pools, which they choose form the platform UI.
    Although the pledges logic is centralized, the staking functions emit events in the transactions signed by the users
    to mimic a recept of the user's intentions.
    This brings the problem of failed transactions: if a user has not enough amount in a pool, and tries to unstake from
    the pool, we have no way to require that onchain, so the event will be emitted anyway.
    @param  _percentage  percentage of APR rewards that a user pledges to the owners pot (expressed with 9 decimals. )
                         if _percentage=0, the full APR goes to the user (this is the default)
                         if _percentage=100*1e9, that is 100%, and that means tha the full APR goes to the ownersPot
    */
    function setUserPledgeShare(
        uint _percentage,
        address _user
    ) external updateBalances(_user) onlyOwner {
        require(((_percentage >= 0) && (_percentage < 100 gwei)), 'percentage should have 9 digits for decimals');
        // staking rewards need to be updated, otherwise, the calculated rewards change retrospectively
        require(lastStakingRewardsUpdate[_user] == block.timestamp, 'cannot update pledge if staking rewards are not updated');
        pledgeShare[_user] = _percentage;
        emit UserPledgeShareUpdated(_user, _percentage);
    }

    /// This is only an emergency function in case somebody sends by accident other ERC20 tokens to the contract
    /**
    @dev    Without this function, the tokens would be locked here forever.
            However, vinci token address is excluded from this function for obvious reasons  as it would bypass all
            other withdraw logic in the contract
    @notice emergency function to return funds to any moron sending ERC20 directly to the contract by mistake.
    @param  _tokenAddress address of the erc20 token to recover
    @param   _amount number of tokens to send back
    @param   _to    wallet receiving the tokens
    */
    function returnLostFunds(
        ERC20 _tokenAddress,
        uint _amount,
        address _to
    ) external onlyOwner lock {
        require(_tokenAddress != vinciERC20, 'only non-vinci ERC20 tokens can be removed with this method');
        _tokenAddress.safeTransfer(_to, _amount);
    }

    /// ================= Internal - View ====================

    /// Calculates the base APR generated by a user at a given time, WITHOUT discounting the pool fees
    function _calculateBaseStakingRewardsSinceLastUpdate(address _user) internal view returns (uint) {
        uint timeSinceLastReward = block.timestamp - lastStakingRewardsUpdate[_user];
        uint staking = activeStaking[_user] + scheduledUnstaking[_user];
        uint baseRewards = (staking * baseAPR * timeSinceLastReward) / (365 days * 100 gwei);
        return baseRewards;
    }

    /// Calculates the base APR rewards that a user would receive, after discounting the pool fees
    function _calculateUserStakingRewardsSinceLastUpdate(address _user) internal view returns (uint) {
        uint baseRewards = _calculateBaseStakingRewardsSinceLastUpdate(_user);
        uint poolFees = baseRewards * pledgeShare[_user] / (100 gwei);
        return baseRewards - poolFees;
    }

    /// A user checkpoint=0 until the user is registered and it is set back to zero when is _finalized
    function _existingUser(address _user) internal view returns (bool) {
        return checkpoint[_user] > 0;
    }

    /// ================= Internal ====================

    function _currentlyUnstakingToClaimable(address _user) internal {
        if (block.timestamp > unlockTime[_user] && currentlyUnstaking[_user] > 0) {
            claimable[_user] += currentlyUnstaking[_user];
            delete currentlyUnstaking[_user];
        }
    }

    function _stake(
        address _user,
        uint _amount,
        uint _poolId
    ) internal {
        require(_amount > 0, 'stake amount cannot be 0');

        _transferVinciToContract(_amount);
        activeStaking[_user] += _amount;

        // set tier info for fist time stakeholders
        if (!_existingUser(_user)) {
            _initializeStakeholder(_user);
        }

        emit Staked(_user, _amount, _poolId);
    }

    function _unstake(
        address _user,
        uint _amount,
        uint _poolId
    ) internal {
        require(_amount > 0, 'amount must be positive');
        require(_amount <= activeStaking[_user], 'Not enough active staking to unstake');

        bool fullUnstake = (_amount == activeStaking[_user]);
        uint totalStaked = activeStaking[_user] + scheduledUnstaking[_user];
        uint penalization = unclaimable[_user] * _amount / totalStaked;

        unclaimable[_user] -= penalization;
        penaltyPot += penalization;

        activeStaking[_user] -= _amount;
        currentlyUnstaking[_user] += _amount;
        unlockTime[_user] = block.timestamp + unstakingDuration;

        // store emergency state in case they want to cancel the unstake
        if (fullUnstake) {
            _finishStakeholder(_user);
        } else {
            // if they unstake, the tier is reevaluated only if new tier would be lower, but checkpoint is not postponed
            uint _potentialTier = calculateTier(stakingBalance(_user));
            if (_potentialTier < tier[_user]) {
                _setTier(_user, _potentialTier);
            }
        }

        emit Unstaked(_user, _amount, _poolId);
    }

    /**
    @dev This handles an ERC20 transfer of vinci from msgSender's wallet to the contract
    WARNING: this function receives the vinci tokens, but they are NOT accounted in any balance. It is responsibility of the function invoking this method to update the necessary balances
    Requires vinci ERC20 approvals
    Requires non zero balance of vinci in the msg.sender wallet
    */
    function _transferVinciToContract(uint _amount) internal lock {
        address sender = _msgSender();
        // transferFrom already checks that _amount is non zero and that there is enough balance
        // we dont need SafeTransfer here because we know the receiver is a smart contract (this)
        vinciERC20.transferFrom(sender, address(this), _amount);
        emit VinciTransferredToContract(sender, _amount);
    }

    function _checkpointMultiplier(address _user) internal returns (uint) {
        return baseCheckpointMultiplier - checkpointMultiplierReduction[_user];
    }

    function _postponeCheckpoint(address _user, bool _decreaseMultiplier) internal {
        uint _prevCheckpoint = !_existingUser(_user) ? block.timestamp : checkpoint[_user];
        // the minimum multiplier is 1, so that the time between checkpoints is at least 30 days.
        // thus, the checkpointMultiplierReduction can only increase up to 5 = (baseCheckpointMultiplier - 1)
        if (_decreaseMultiplier && (checkpointMultiplierReduction[_user] < baseCheckpointMultiplier - 1)) {
            checkpointMultiplierReduction[_user] += 1;
        }
        checkpoint[_user] = _prevCheckpoint + _checkpointMultiplier(_user) * checkpointBlockDuration;
        emit CheckpointSet(_user, checkpoint[_user]);
    }

    function _initCheckpoint(address _user) internal {
        uint userCheckpoint = block.timestamp + _checkpointMultiplier(_user) * checkpointBlockDuration;
        checkpoint[_user] = userCheckpoint;
        emit CheckpointSet(_user, userCheckpoint);
    }

    function _initializeStakeholder(address _user) internal {
        indexStakeholders[_user] = stakeholders.length;
        stakeholders.push(_user);
        _initCheckpoint(_user);
        lastStakingRewardsUpdate[_user] = block.timestamp;
        _setTier(_user, calculateTier(stakingBalance(_user)));
    }

    function _finishStakeholder(address _user) internal {
        require(_existingUser(_user), 'user must exist');
        _removeSuperstaker(_user);
        _removeStakeholderFromArray(_user);
        _setTier(_user, 0);
        checkpoint[_user] = 0;
        delete checkpointMultiplierReduction[_user];
    }

    function _removeStakeholderFromArray(address _user) internal {
        uint index = indexStakeholders[_user];
        address _lastStakeholder = stakeholders[stakeholders.length - 1];
        stakeholders[index] = _lastStakeholder;
        indexStakeholders[_lastStakeholder] = index;
        stakeholders.pop();
    }

    function _setTier(address _user, uint _newTier) internal {
        if (_newTier != tier[_user]) {
            tier[_user] = _newTier;
            emit TierSet(_user, _newTier);
        }
    }

    function _grantSuperstaker(address _user) internal {
        if (!superstaker[_user]) {
            superstaker[_user] = true;
            emit SuperstakerGranted(_user);
        }
    }

    function _removeSuperstaker(address _user) internal {
        if (superstaker[_user]) {
            superstaker[_user] = false;
            emit SuperstakerRemoved(_user);
        }
    }

    function _crossCheckpoint(address _user) internal {

        if (unclaimable[_user] > 0) {
            claimable[_user] += unclaimable[_user];
            delete unclaimable[_user];
        }

        if (scheduledUnstaking[_user] > 0) {
            uint scheduledAmount = scheduledUnstaking[_user];
            claimable[_user] += scheduledAmount;
            delete scheduledUnstaking[_user];
            // unfortunately at this point the poolId is unknown, so we put 0.
            // This info could be extracted from a previously emitted ScheduledUnstake event
            emit ScheduledUnstakeComplete(_user, scheduledAmount);
        }

        // evaluate staking balances and finish superstaker if it is 0, with no cancel possibility
        uint userStaking = stakingBalance(_user);

        if (userStaking == 0) {
            _finishStakeholder(_user);
        } else {
            // no need to update currentlyUnstaking as it is taken care of in the updateBalances() modifier
            _postponeCheckpoint(_user, true);
            // mandatory to reevaluate tier when crossing checkpoint
            _setTier(_user, calculateTier(userStaking));
            // if they cross a checkpoint with non zero staking, superstaker status is granted (if not already given)
            _grantSuperstaker(_user);
        }

        emit CheckpointCrossed(_user);
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