// SPDX-License-Identifier: MIT
/**
    @title RFAllocationStaking
    @author farruhsydykov
 */
pragma solidity ^0.8.0;

import "./interfaces/IAdmin.sol";
import "./interfaces/IRFSaleFactory.sol";
import "./interfaces/IRFAllocationStaking.sol";

import "./UpgradeableUtils/PausableUpgradeable.sol";
import "./UpgradeableUtils/ReentrancyGuardUpgradeable.sol";
import "./UpgradeableUtils/SafeERC20Upgradeable.sol";

contract RFAllocationStaking is IRFAllocationStaking, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct TierInfo {
        Tier tier; // Current tier level.
        uint256 amount; // Total amount of RAISE staked.
        uint256 tokensUnlockTime; // When tokens will be available for withdrawal after participation in a sale.
    }

    struct UserInfo {
        uint256 amount; // How many LP/RAISE tokens the user has provided.
        uint256 claimedReward; // Amount of tokens user has already claimed.
        uint256 lastRAISEStake; // Timesatmp when RAISE were staked.
        uint256 firstRAISEStake; // Timestamp when RAISE tokens were staked in RAISE pool for the first time.
    }

    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per second.
        uint256 lastRewardTimestamp; // Last timstamp that ERC20s distribution occurs.
        uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
        uint256 totalDeposits; // Total amount of tokens deposited at the moment (staked).
        uint256 minStakingPeriod; // Minimal time period of staking. Unstaking earlier will bear a fee
    }

    struct TierUpgradePool {
        StakeStatus status; // Status of the Stake To Upgrade pool.
        Tier upgradeFrom; // User's Tier to upgrade from.
        uint256 amount; // Amount of tokens staked in STU.
        uint256 lastTierChange; // Last timestamp when tier was changed.
    }

    // Admin contract address.
    IAdmin public admin;
    // Address of the RAISE Token contract.
    IERC20Upgradeable public RAISE;
    // Total amount of RAISE staked in this contract
    uint256 public totalRAISEDeposited;
    // The timestamp when farming starts.
    uint256 public startTimestamp;
    // The timestamp when farming ends.
    uint256 public endTimestamp;
    // RAISE tokens rewarded per second.
    uint256 public rewardPerSecond;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The total amount of RAISE that's paid out as reward.
    uint256 public paidOut;
    // Total rewards added to farm.
    uint256 public totalRewards;
    // Address of sales factory contract.
    IRFSaleFactory public salesFactory;
    // Fee for early unstaking. Should be set as 100 for 1%.
    uint256 public earlyUnstakingFee;
    // Early unstaking fee precision. Will be set as 10,000 while initialisation.
    uint256 public earlyUnstakingFeePrecision;
    // Total RAISE taken back as a staking reward for premature withdrawal.
    uint256 public RAISEReturnedForStakingReward;
    // Seconds amount in 6 months. Set during initialization.
    uint32 private sixMonthPeriod;
    // Seconds amount in 12 months. Set during initialization.
    uint32 private twelveMonthPeriod;
    // Mminimum amount of time passed staking to be elligible for FAN round participation. Set during initialization.
    uint32 private minStakingPeriodForFANParticipation;
    // Amount of tokens required to get one ticket. Set as a whole token i.e. 1 - right, 1 000 000 000 000 000 000 - wrong.
    uint256 public tokensPerTicket;
    // 1e36 used as precision for calculating user's reward.
    uint256 public precisionConstant;
    // 10 ** 18 set during initialization.
    uint256 ONE;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Mapping to check if a given _pid is RAISE pool
    mapping(uint256 => bool) public isRAISEPool;
    // Info of each user that stakes RAISE
    mapping(address => TierInfo) public tierInfo;
    // Info of user's STU pool.
    mapping(address => TierUpgradePool) public upgradePool;
    // Info of each user's stake in a given pool.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    // * * * EVENTS * * * //
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 feeTaken);
    event rewardsWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    // * * * MODIFIERS * * * //
    /**
        @dev Checks if the caller is a verified sale factory.
     */
    modifier onlyVerifiedSales {
        require(salesFactory.isSaleCreatedThroughFactory(_msgSender()), "RF_SA: Sale not created through factory.");
        _;
    }

    /**
        @dev Checks if the caller is a verified sale factory.
     */
    modifier onlyAdmin {
        require(admin.isAdmin(_msgSender()), "Only Admin can deploy sales");
        _;
    }

    /**
        @dev Checks if given _pid is a valid pool id.
     */
    modifier onlyValidPoolID(uint256 _pid) {
        bool inPoolInfo = _pid >= 0 && _pid < poolInfo.length;
        require(inPoolInfo || _pid == 999999, "RF_SA: There is no pool with such pool ID");
        _;
    }

    // constructor(
    //         address _erc20,
    //         uint256 _rewardPerSecond,
    //         uint256 _startTimestamp,
    //         uint256 _earlyUnstakingFee,
    //         address _salesFactory
    // ) {
    // // __Ownable_init_unchained();
        // __ReentrancyGuard_init_unchained();
        // // Unpause contract
        // __Pausable_init_unchained();

    //     RAISE = IERC20(_erc20);
    //     rewardPerSecond = _rewardPerSecond;
    //     startTimestamp = _startTimestamp;
    //     endTimestamp = _startTimestamp;
    //     earlyUnstakingFee = _earlyUnstakingFee;
    //     salesFactory = IRFSaleFactory(_salesFactory);

    //     ONE = 1000000000000000000;
    //     precisionConstant = 1e36;
    //     earlyUnstakingFeePrecision = 10000;
    //     sixMonthPeriod = 180 * 24 * 60 * 60;
    //     twelveMonthPeriod = 360 * 24 * 60 * 60;
    //     minStakingPeriodForFANParticipation = 14 * 24 * 60 * 60;
    // }

    // * * * EXTERNAL FUNCTIONS * * * //

    /**
        @dev Initializes this contract setting main token, rewards per second,
        starting Timestamp and sales factory and the caller as an owner of this contract.
        @param _erc20 Address of the token that will be used as a reward for staking and will be used to calculate user's tier.
        @param _rewardPerSecond Reward per second value:
        @param _startTimestamp When rewards will start caclulating.
        @param _earlyUnstakingFee Fee for early unstaking. Should be set as 100 per 1%. i.e. 5000 for 50%.
        @param _salesFactory Address of the sales factory that will request user's tier or ticket amount.
        @param _tokensPerTicket Amount of tokens require to get one ticket. Set as a whole token i.e. 1 - right, 1 000 000 000 000 000 000 - wrong.
        @param _admin Admin contract address.
     */
    function initialize(
        address _erc20,
        uint256 _rewardPerSecond,
        uint256 _startTimestamp,
        uint256 _earlyUnstakingFee,
        address _salesFactory,
        uint256 _tokensPerTicket,
        address _admin
    )
    external
    initializer
    {
        require(IAdmin(_admin).isAdmin(_msgSender()), "Only Admin can initialize this contract");
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        RAISE = IERC20Upgradeable(_erc20);
        rewardPerSecond = _rewardPerSecond;
        startTimestamp = _startTimestamp;
        endTimestamp = _startTimestamp;
        earlyUnstakingFee = _earlyUnstakingFee;
        salesFactory = IRFSaleFactory(_salesFactory);
        tokensPerTicket = _tokensPerTicket;

        admin = IAdmin(_admin);
        ONE = 1000000000000000000;
        precisionConstant = 1e36;
        earlyUnstakingFeePrecision = 10000;
        sixMonthPeriod = 180 * 24 * 60 * 60;
        twelveMonthPeriod = 360 * 24 * 60 * 60;
        minStakingPeriodForFANParticipation = 14 * 24 * 60 * 60;
    }

    /**
        @dev Function to pause the contract.
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
        @dev Function to unpause the contract.
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
        @dev Sets new value of rewardPerSecond.
        @param _newRewardPerSecond New rewardPerSecond value.
     */
    function setRewardPerSecond(uint256 _newRewardPerSecond) override virtual external onlyAdmin {
        require(totalRewards != 0, "RF_SA: This contract is not funded or has not been initialized yet.");

        rewardPerSecond = _newRewardPerSecond;
        endTimestamp = block.timestamp + (totalRewards - paidOut) / rewardPerSecond;

        require(endTimestamp > block.timestamp, "RF_SA: New rewardPerSecond value would lead to an end of staking.");
    }

    /**
        @dev Sets new ealyUnstakingFee. Should be set as 100 for 1% fee.
        @param _newEarlyUnstakingFee New early unstaking fee.
     */
    function setEarlyUnstakingFee(uint256 _newEarlyUnstakingFee) override virtual external onlyAdmin {
        require(_newEarlyUnstakingFee < 10000, "RF_SA: Early unstaking fee can not be bigger than 100%.");

        earlyUnstakingFee = _newEarlyUnstakingFee;
    }

    /**
        @dev Function where owner can set sales factory in case of upgrading some of smart-contracts.
        @param _salesFactory Address of the new sales factory.
     */
    function setSalesFactory(address _salesFactory) override virtual external onlyAdmin {
        require(_salesFactory != address(0), "RF_SA: Sales Factory address is already set.");
        salesFactory = IRFSaleFactory(_salesFactory);
    }

    /**
        @dev Add a new lp to the pool. Can only be called by the owner.
        @param _allocPoint Allocation point amount of the new pool.
        @param _lpToken Address of the lpToken
        @param _minStakingPeriod Minimal staking period for RAISE pools.
        Withdrawing ealier than that will bear an early unstaking fee.
        @param _withUpdate Update or not to update pools.
     */
    function add(uint256 _allocPoint, address _lpToken, uint256 _minStakingPeriod, bool _withUpdate) override virtual external onlyAdmin {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 __minStakingPeriod;
        if (IERC20Upgradeable(_lpToken) == RAISE) __minStakingPeriod = _minStakingPeriod;

        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: IERC20Upgradeable(_lpToken),
            allocPoint: _allocPoint,
            lastRewardTimestamp: lastRewardTimestamp,
            accERC20PerShare: 0,
            totalDeposits: 0,
            minStakingPeriod: __minStakingPeriod
        }));

        // In case of adding new pool for RAISE staking
        // Save its _pid in a map to check if it's RAISE pool.
        if (IERC20Upgradeable(_lpToken) == RAISE) {
            uint256 pId_ = poolInfo.length - 1;
            isRAISEPool[pId_] = true;
        }
    }

    /**
        @dev Deposit LP or RAISE tokens to farm for RAISE rewards, tier or tickets.
        @param _pid Id of the pool in which to deposit.
        @param _amount Amount of tokens user is depositing.
     */
    function deposit(uint256 _pid, uint256 _amount) override virtual external onlyValidPoolID(_pid) whenNotPaused {
        // massUpdatePools();
        require(_amount > 0, "RF_SA: Amount to deposit can not be 0");

        if (_pid == 999999) {
            _stakeRAISEForUpgrades(_amount);
        } else _stakeLP(_pid, _amount);
    }

    /**
        @dev Update the given pool's ERC20 allocation point and/or minimal staking period. Can only be called by the owner.
        @param _pid Pool's id.
        @param _allocPoint Allocation point amount of the new pool.
        @param _minStakingPeriod Minimal staking period for RAISE pools.
        Withdrawing ealier than that will bear an early unstaking fee.
        @param _withUpdate Update or not to update pools.
     */
    function set(uint256 _pid, uint256 _allocPoint, uint256 _minStakingPeriod, bool _withUpdate) override virtual external onlyAdmin onlyValidPoolID(_pid) {
        if (_withUpdate) massUpdatePools();

        PoolInfo storage pool = poolInfo[_pid];
        if (pool.lpToken == RAISE && _minStakingPeriod != 0) pool.minStakingPeriod = _minStakingPeriod;

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
        @dev Returns number of liquidity pool exluding stake to upgrade pool.
     */
    function poolLength() override virtual external view returns (uint256) {
        return poolInfo.length;
    }

    /**
        @dev Function to fetch deposits and earnings at one call for multiple users for passed pool id.
        @param _users An array of addresses who's deposits and pending amounts to return.
        @param _pid Pool id of which to return deposits and pending amounts.
     */
    function getPendingAndDepositedForUsers(
        address[] memory _users,
        uint _pid
    )
    override
    virtual
    external
    view
    whenNotPaused
    onlyValidPoolID(_pid) 
    returns (uint256 [] memory , uint256 [] memory) {
        uint256 [] memory deposits = new uint256[](_users.length);
        uint256 [] memory earnings = new uint256[](_users.length);

        for(uint i=0; i < _users.length; i++) {
            deposits[i] = deposited(_pid , _users[i]);
            earnings[i] = pendingReward(_pid, _users[i]);
        }

        return (deposits, earnings);
    }

    /**
        @dev View function for total reward the farm has yet to pay out.
        @notice This is not necessarily the sum of all pending sums on all pools and users.
                example 1: when tokens have been wiped by emergency withdraw.
                example 2: when one pool has no LP supply.
     */
    function totalPending() override virtual external view whenNotPaused returns(uint256) {
        if (block.timestamp <= startTimestamp) {
            return 0;
        }

        uint256 lastTimestamp = block.timestamp < endTimestamp ? block.timestamp : endTimestamp;
        return rewardPerSecond * (lastTimestamp - startTimestamp) - paidOut;
    }
    
    /**
        @dev Sets RAISE token unlock time for a given user by verified sales. Meaning that while the user
        participates in a sale that has not yet ended he/she can not withdraw RAISE tokens.
        @param _user Address of the user who's tokens will be locked.
        @param _tokensUnlockTime Timestamp when tokens will be unlocked.
     */
    function setTokensUnlockTime(
        address _user,
        uint256 _tokensUnlockTime
    )
    override
    virtual
    external
    onlyVerifiedSales{
        TierInfo storage tier = tierInfo[_user];

        tier.tokensUnlockTime = _tokensUnlockTime;
    }

    /**
        @dev Fund the farm, increase the end block.
        @param _amount Token amount to fund the farm for.
     */
    function fund(uint256 _amount) override virtual external {
        require(block.timestamp < endTimestamp && endTimestamp != 0, "RF_SA: too late, the farm is closed or contract was not yet initialized.");
        RAISE.safeTransferFrom(_msgSender(), address(this), _amount);
        endTimestamp += _amount / rewardPerSecond;
        totalRewards += _amount;
    }

    /**
        @dev Function to set amount of tokens required to get a ticket.
     */
    function setTokensPerTicket(uint256 _amount) override virtual external onlyAdmin {
        require(_amount != 0, "RF_SA: New value for `tokensPerTicket` can not be zero.");
        tokensPerTicket = _amount;
    }

    /**
        @dev Function to check if user has staked for at least 2 weeks.
        @param _user Address of the user whos staking period is checked.
     */
    function fanStakedForTwoWeeks(address _user) override virtual external view whenNotPaused returns(bool isStakingRAISEForTwoWeeks_) {
        require(getCurrentTier(_user) == Tier.FAN, "RF_SA: This user is not FAN.");

        // bool isStakingRAISEForTwoWeeks;

        uint256 timePassed;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            UserInfo storage user = userInfo[i][_user];
            timePassed = block.timestamp - user.firstRAISEStake;
            if (poolInfo[i].lpToken == RAISE && timePassed > minStakingPeriodForFANParticipation && user.firstRAISEStake != 0) return true;
        }
        return false;
    }

    // * * * PUBLIC FUNCTIONS * * * //

    /**
        @dev Update reward variables for all pools.
        @notice Be careful of gas spending!
     */
    function massUpdatePools() override virtual public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
        @dev Update reward variables of the given pool to be up-to-date.
        @param _pid Id of the pool which should be upgraded.
     */
    function updatePool(uint256 _pid) override virtual public onlyValidPoolID(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        
        // check if rewards can still be calculated
        // when block.timestamp < endTimestamp it means that
        // this contract has run out of funds for rewards
        uint256 lastTimestamp = block.timestamp < endTimestamp ? block.timestamp : endTimestamp;
        
        if (lastTimestamp <= pool.lastRewardTimestamp) {
            return;
        }
        
        uint256 lpSupply = pool.totalDeposits;

        // if there are not tokens staked in the pool
        // then update lastRewardTimestamp and return 
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = lastTimestamp;
            return;
        }
        
        // calculate number of seconds since lastRewardTimestamp
        // when reward was calculated last time
        uint256 nrOfSeconds = block.timestamp - pool.lastRewardTimestamp;
        // determine how much tokens are devoted to this pool
        uint256 RAISERewardOfThePool = nrOfSeconds * rewardPerSecond * pool.allocPoint / totalAllocPoint;
        // calculate how many reward tokens are given for each token staked in this pool    
        pool.accERC20PerShare += (RAISERewardOfThePool * precisionConstant / lpSupply);
        pool.lastRewardTimestamp = lastTimestamp;
    }

    /**
        @dev View function to see deposited LP for a user.
        @param _pid Id of the pool in which to check user's deposited amount.
        @param _user Address of the user whos deposited amount is requested.
     */
    function deposited(uint256 _pid, address _user) override virtual public view whenNotPaused onlyValidPoolID(_pid) returns(uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    /**
        @dev View function to see pending amount for a user.
        @param _pid Id of the pool in which to check user's pending amount.
        @param _user Address of the user whos pending amount is requested.
     */
    function pendingReward(uint256 _pid, address _user) override virtual public view whenNotPaused onlyValidPoolID(_pid) returns(uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user]; 

        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.totalDeposits;

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 reward = rewardPerSecond * pool.allocPoint / totalAllocPoint;
            accERC20PerShare += reward * precisionConstant / lpSupply;
        }
        return user.amount * accERC20PerShare / precisionConstant - user.claimedReward;
    }

    /**
        @dev Function to withdraw LP or RAISE tokens from a given pool.
        @param _pid Id of the pool to withdraw tokens from.
        @param _amount Amount of tokens to withdraw.
     */
    function withdraw(uint256 _pid, uint256 _amount) override virtual public onlyValidPoolID(_pid) nonReentrant whenNotPaused {
        // massUpdatePools();
        // check if user participate in a sale and his tokens are locked
        if (isRAISEPool[_pid] || _pid == 999999) {
            require(
                block.timestamp > tierInfo[_msgSender()].tokensUnlockTime,
                "RF_SA: Your RAISE tokens are locked due to sale participation"
            );
        }

        if (_pid == 999999) {
            _withdrawFromUpgrades();
        } else _withdrawLP(_pid, _amount);
    }

    /**
        @dev Function to withdraw pending rewards.
        @param _pid Id of the pool to withdraw pending rewards from.
     */
    function withdrawPending(uint256 _pid) override virtual public onlyValidPoolID(_pid) whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        require(_pid != 999999, "RF_SA: There are no rewards from staking in 'Stake To Upgrade' pool");

        uint256 pending;
        if (user.amount > 0) {
            pending = user.amount * pool.accERC20PerShare / precisionConstant - user.claimedReward;
        } else return;

        user.claimedReward = user.amount * pool.accERC20PerShare / precisionConstant;

        if(pending > 0) {
            paidOut += pending;
            pool.lpToken.safeTransfer(_msgSender(), pending);
        }

        emit rewardsWithdraw(_msgSender(), _pid, pending);
    }

    /**
        @dev Function to calculate ticket amount of the given user.
        @param _user Address whos ticket amount to calculate
     */
    function getTicketAmount(address _user) override virtual public view whenNotPaused returns(uint256 ticketAmount_) {
        TierInfo storage info = tierInfo[_user];
        Tier tier = getCurrentTier(_user);
        
        require(tier < Tier.BROKER && tier > Tier.FAN, "RF_SA: Brokers, Tycoons and Fans are not elligible for tickets");

        ticketAmount_ = info.amount / (tokensPerTicket * ONE);
    }

    /**
        @dev Public function to get user's tier taking in consideration his/her upgrades.
        @param _user Address of the user whos tier is requested.
        @notice Tier might be outdated! Make sure to check for upgrades first.
     */
    function getCurrentTier(address _user) override virtual public view whenNotPaused returns(Tier tier) {
        TierInfo storage user = tierInfo[_user];
        TierUpgradePool storage stu = upgradePool[_user];

        uint256 timePassed;
        if (stu.lastTierChange != 0) {
            timePassed = block.timestamp - stu.lastTierChange;
        } else timePassed = 0;
        uint256 amountStaked = user.amount;

        require(amountStaked > 0, "RF_SA: This user does not stake any RAISE");

        if (amountStaked < 500 * ONE) return Tier.FAN;
        if (amountStaked >= 500 * ONE && amountStaked < 5000 * ONE) {
            if (timePassed >= twelveMonthPeriod + twelveMonthPeriod) return Tier.TYCOON;
            else if (timePassed >= twelveMonthPeriod) return Tier.BROKER;
            else if (timePassed >= sixMonthPeriod) return Tier.DEALER;
            else return Tier.MERCHANT;
        }
        if (amountStaked >= 5000 * ONE && amountStaked < 50000 * ONE) {
            if (timePassed >= twelveMonthPeriod + sixMonthPeriod) return Tier.TYCOON;
            else if (timePassed >= sixMonthPeriod) return Tier.BROKER;
            else return Tier.DEALER;
        }
        if (amountStaked >= 50000 * ONE && amountStaked < 100000 * ONE) {
            if (timePassed >= twelveMonthPeriod) return Tier.TYCOON;
            else return Tier.BROKER;
        }
        if (amountStaked >= 100000 * ONE) return Tier.TYCOON;
    }

    // * * * INTERNAL FUNCTIONS * * * //

    /**
        @dev Internal function to stake LP or RAISE tokens.
        @param _pid Id of the pool to which to stake tokens.
        @param _amount Amount of tokens to stake.
     */
    function _stakeLP(uint256 _pid, uint256 _amount) virtual internal {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        TierInfo storage tier = tierInfo[_msgSender()];
        TierUpgradePool storage stu = upgradePool[_msgSender()];

        uint256 depositAmount = _amount;        

        Tier prevTier = stu.upgradeFrom;

        pool.lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
        pool.totalDeposits += depositAmount;

        uint256 pending;
        if (user.amount > 0) {
            pending = user.amount * pool.accERC20PerShare / precisionConstant - user.claimedReward;
        }

        uint256 prevUserAmount = user.amount;
        user.amount += depositAmount;

        user.claimedReward = user.amount * pool.accERC20PerShare / precisionConstant;

        // If token staked is RAISE:
        if (pool.lpToken == RAISE) {
            // if RAISE tokens are staked for the first time in this pool
            // set firstRAISEStake as a current timestamp
            if (prevUserAmount == 0) {
                user.firstRAISEStake = block.timestamp;
            }
            // Increase users RAISE amount staked
            tier.amount += _amount;
            // Upgrade tier
            tier.tier = getCurrentTier(_msgSender());
            // Each new stake to RAISE pool updates user's lastRAISEStake
            user.lastRAISEStake = block.timestamp;
            // Increase total RAISE deposited to this contract
            totalRAISEDeposited +=_amount;

            // if due to this stake tier has changed, and TierUpgradePool is active for this user
            // update user's TierUpgradePool `upgradeFrom` value to new tier and set `lastTierChange` timestamp as current. 
            if (prevTier != tier.tier && stu.status == StakeStatus.ACTIVE) {
                stu.upgradeFrom = tier.tier;
                stu.lastTierChange = block.timestamp;
            }
        }

        if(pending > 0) {
            paidOut += pending;
            pool.lpToken.safeTransfer(_msgSender(), pending);
        }

        emit Deposit(_msgSender(), _pid, depositAmount);
    }

    /**
        @dev Internal function to stake RAISE to 'Stake To Upgrade' pool.
        @param _amount Amount of tokens to stake to 'Stake To Upgrade' pool.
     */
    function _stakeRAISEForUpgrades(uint256 _amount) virtual internal {
        massUpdatePools();
        TierInfo storage user = tierInfo[_msgSender()];
        TierUpgradePool storage stu = upgradePool[_msgSender()];

        // check if amount staked in this pool is >= 500 RAISE tokens
        // otherwise there is no point in staking lesser amounts in this pool
        require(
            stu.amount + _amount >= 500 * ONE,
            "RF_SA: You should stake at least 500 RAISE to qualify for tier staking upgrade"
        );

        uint256 depositAmount = _amount;

        // Increase total RAISE deposited to this contract
        totalRAISEDeposited +=_amount;
        user.amount += _amount;
        stu.amount += _amount;

        Tier prevTier = stu.upgradeFrom;

        // set tier from which upgrades will be given
        user.tier = getCurrentTier(_msgSender());
        stu.upgradeFrom = user.tier;

        // if tier changed after this stake update lastTierChange
        if (prevTier != stu.upgradeFrom) {
            stu.lastTierChange = block.timestamp;
            // if this is the first stake to this pool change its status
            if (stu.status == StakeStatus.NA) {
                stu.status = StakeStatus.ACTIVE;
            }
        }

        RAISE.safeTransferFrom(_msgSender(), address(this), _amount);

        emit Deposit(_msgSender(), 999999, depositAmount);
    }

    /**
        @dev Internal function to return early unstaking fees back to the contract as staking rewards.
        @param _amount Amount of tokens to return back to contract as staking rewards.
     */
    function _returnFeeAsReward(uint256 _amount) virtual internal {
        require(endTimestamp != 0 && block.timestamp < endTimestamp, "RF_SA: too late, the farm is closed");
        endTimestamp += _amount / rewardPerSecond;
        totalRewards += _amount;
    }

    /**
        @dev Internal function to withdraw LP and RAISE tokens from contract.
        @param _pid Id of the pool from which to withdraw LP or RAISE tokens.
        @param _amount Amount of tokens to withdraw.
        @notice RAISE tokens withdrawing from RAISE pools earlier than their minimum staking period will be subject to early unstaking fee.
     */
    function _withdrawLP(uint256 _pid, uint256 _amount) virtual internal {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        TierInfo storage tier = tierInfo[_msgSender()];

        require(tier.tokensUnlockTime <= block.timestamp, "RF_SA: Last sale you registered for is not finished yet.");
        require(user.amount >= _amount, "RF_SA: You can not withdraw more than you've deposited");

        uint256 pending;
        if (user.amount > 0) {
            pending = user.amount * pool.accERC20PerShare / precisionConstant - user.claimedReward;
        }

        pool.totalDeposits -= _amount;
        user.amount -= _amount;

        user.claimedReward = user.amount * pool.accERC20PerShare / precisionConstant;

        uint256 transferAmount = _amount;
        uint256 feeAmount;

        if (pool.lpToken == RAISE) {
            totalRAISEDeposited -= _amount;
            if (block.timestamp < pool.minStakingPeriod + user.lastRAISEStake) {
                feeAmount = _amount * earlyUnstakingFee / earlyUnstakingFeePrecision;
                transferAmount -= feeAmount;
                RAISEReturnedForStakingReward += feeAmount;
                _returnFeeAsReward(feeAmount);
            }

            tier.amount -= _amount;
            tier.tier = getCurrentTier(_msgSender());

            if (user.amount == 0) {
                user.lastRAISEStake = 0;
                user.firstRAISEStake = 0;
            }
        }

        if(pending > 0) {
            paidOut += pending;
            pool.lpToken.safeTransfer(_msgSender(), pending);
        }

        pool.lpToken.safeTransfer(address(_msgSender()), transferAmount);

        emit Withdraw(_msgSender(), _pid, transferAmount, feeAmount);
    }

    /**
        @dev Intenal function to withdraw RAISE tokens from 'Stake To Upgrade' pool.
        @notice User can withdraw only full amount of tokens staked in 'Stake To Upgrade' pool.
     */
    function _withdrawFromUpgrades() virtual internal {
        massUpdatePools();
        TierUpgradePool storage stu = upgradePool[_msgSender()];
        TierInfo storage tier = tierInfo[_msgSender()];
        
        require(stu.amount > 0, "RF_SA: There is nothing to withdraw");

        uint256 withdrawAmount = stu.amount;

        stu.amount = 0;
        tier.amount -= withdrawAmount;
        totalRAISEDeposited -= withdrawAmount;

        tier.tier = getCurrentTier(_msgSender());

        stu.lastTierChange = 0;
        stu.upgradeFrom = Tier.FAN;
        stu.status = StakeStatus.NA;

        RAISE.safeTransfer(address(_msgSender()), withdrawAmount);

        emit Withdraw(_msgSender(), 999999, withdrawAmount, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdmin {
    function isAdmin(address _user) external returns(bool _isAdmin);
    function addAdmin(address _adminAddress) external;
    function removeAdmin(address _adminAddress) external;
    function getAllAdmins() external view returns(address [] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRFSaleFactory {
    function initialize(address _adminContract, address _allocationStaking, address _saleContractImplementation)external;
    function deploySale(bytes memory _data) external;
    function changeSaleContractImplementation(address _newSaleContractImplementation) external;
    function setAllocationStaking(address _allocationStaking) external;
    function getNumberOfSalesDeployed() external view returns(uint256);
    function getLastDeployedSale() external view returns(address);
    function getSalesFromIndexToIndex(uint _startIndex, uint _endIndex) external view returns(address[] memory);
    function isSaleCreatedThroughFactory(address _sender) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Enums.sol";
import "../Utils/TestToken/IERC20.sol";

interface IRFAllocationStaking is Enums {
    function initialize(address _erc20, uint256 _rewardPerSecond, uint256 _startTimestamp, uint256 _earlyUnstakingFee, address _salesFactory, uint256 _tokensPerTicket, address _admin) external;
    function pause() external;
    function unpause() external;
    function setRewardPerSecond(uint256 _newRewardPerSecond) external;
    function setEarlyUnstakingFee(uint256 _newEarlyUnstakingFee) external;
    function setSalesFactory(address _salesFactory) external;
    function add(uint256 _allocPoint, address _lpToken, uint256 _minStakingPeriod, bool _withUpdate) external;
    function set(uint256 _pid, uint256 _allocPoint, uint256 _minStakingPeriod, bool _withUpdate) external;
    function poolLength() external view returns (uint256);
    function getPendingAndDepositedForUsers(address[] memory _users, uint _pid) external view returns (uint256 [] memory , uint256 [] memory);
    function totalPending() external view returns (uint256);
    function setTokensUnlockTime(address _user, uint256 _tokensUnlockTime) external;
    function fund(uint256 _amount) external;
    function massUpdatePools() external;
    function setTokensPerTicket(uint256 _amount) external;
    function updatePool(uint256 _pid) external;
    function deposited(uint256 _pid, address _user) external view returns(uint256);
    function pendingReward(uint256 _pid, address _user) external view returns(uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function withdrawPending(uint256 _pid) external;
    function getTicketAmount(address _user) external view returns(uint256 ticketAmount_);
    function getCurrentTier(address _user) external view returns(Tier tier);
    function fanStakedForTwoWeeks(address _user) external view returns(bool isStakingRAISEForTwoWeeks_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

interface Enums {
    // Tier levels
    enum Tier {FAN, MERCHANT, DEALER, BROKER, TYCOON}
    // Status of a stake to upgrade pool
    enum StakeStatus {NA, ACTIVE}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

import "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;
// pragma solidity 0.8.9;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
// pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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