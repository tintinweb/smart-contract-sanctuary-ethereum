//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
import "./GarageUpgradeable.sol";

// A smart contract to manage liquidity pool for staking
contract GarageUpgradeableV2 is GarageUpgradeable{
    string public constant name = "Hello world";
    
    function getName() public pure returns (string memory){
        return name;
    }

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "./IERC1155.sol";
import "./IERC20.sol";

// A smart contract to manage liquidity pool for staking
contract GarageUpgradeable is Initializable, AccessControlUpgradeable, ERC1155HolderUpgradeable, UUPSUpgradeable{

    /**
    * Counters
    **/
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _nextPoolId;

    mapping(uint256 => IERC20) public ERC20;
    CountersUpgradeable.Counter public erc20Counter;

    /**
    * Pool Status
    **/
    string private constant POOL_OPEN = "open";
    string private constant POOL_CLOSE = "close";
    string private constant POOL_DISBURSE = "disburse";
    string private constant POOL_PAUSE = "pause";
    string private constant POOL_DONE = "done";
    string private constant POOL_DEFAULT = "default";

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAY_ROLE = keccak256("PAY_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /**
    * Struct
    **/
    struct LiquidityPool { 
        string title;
        string responsibleAddress;
        string status;
        uint16 periodCount;
        uint16 periodPaidCount;
        uint32 stakingRatePerYear;
        uint32 deadline;
        uint32 lateRatePerDay;
        uint32[] periodTimestamps;
        uint256 liquidity;
        uint256 valueAtClose;
        uint256 amountToPayPerTerm;
        uint256 erc20IdReward;
        uint256[] erc20IdStakeOptions;
    }

    struct PoolPeriod {
        uint32 startTime;
        uint256 claimableAmount;
        uint256 lastErc1155BalanceInPeriod;
        uint256 claimedAmount;
    }

    struct Payment {
        uint32 blockTimestamp;
        uint256 amount;
        uint256 lateFee;
        uint256 erc20Id;
    }

    /**
    * Variables
    **/
    address public bankAddress;
    address public poolErc1155Address;
    IERC1155 public poolErc1155;

    uint32 constant DAY = 1 days; // 86400 seconds
    uint32 public GRACIOUS_TIME;

    uint32 public MAXIMUM_LATE_FEE_PERCENTAGE;

    bool public globalPauseWithdrawStatus;

    mapping(uint64 => LiquidityPool) public liquidityPools;

    mapping(uint64 => mapping(uint256 => uint256)) public stakedLiquidities;

    // note the start of each staking block
    // poolId => staking start timestamp
    mapping(uint64 => uint32) public stakingStartTimeStamp;

    // note the start of each staking block
    // poolId => pool disburse mode
    mapping(uint64 => uint8) public poolDisburseMode; // 0: disburse principal and interest, 1: disburse interest only
    
    // poolId => period => available to disburse
    mapping(uint64 => mapping(uint16 => uint256)) public availableToDisburse;

    // poolId => pause withdraw status
    mapping(uint64 => bool) public pauseWithdrawStatus;

    // poolId => address => period => PoolPeriod
    mapping(uint64 => mapping(address => mapping(uint16 => PoolPeriod))) public poolPeriods;

    // poolId => period => payment
    mapping(uint64 => mapping(uint16 => Payment)) public payments;

    // poolId => default amount
    mapping(uint64 => uint256) public defaultAmount;

    // poolId => available default for claim
    mapping(uint64 => uint256) public availableDefaultToDisburse;

    /**
    * Functions for Smart contract to Hold ERC1155
    **/
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * Global variable setter
    **/
    function setGraciousTime(uint32 newGraciousTime) public {
        require(hasRole(OWNER_ROLE, msg.sender));
        GRACIOUS_TIME = newGraciousTime;
    }

    function setMaximumLateFee(uint32 newMaximumLateFee) public {
        require(hasRole(OWNER_ROLE, msg.sender));
        MAXIMUM_LATE_FEE_PERCENTAGE = newMaximumLateFee;
    }

    function setBankAddress(address _address) public {
        require(hasRole(OWNER_ROLE, msg.sender));
        bankAddress = _address;
    }

    function addErc20(address erc20Address) public {
        require(hasRole(OWNER_ROLE, msg.sender));
        ERC20[erc20Counter.current()] = IERC20(erc20Address);
        erc20Counter.increment();
    }

    /**
    * Initialize
    **/
    function initialize(address erc20Address, address _poolErc1155Address) initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        ERC20[erc20Counter.current()] = IERC20(erc20Address);
        erc20Counter.increment();

        bankAddress = msg.sender;
        _grantRole(OWNER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PAY_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // _nextPoolId is initialized to 1
        _nextPoolId.increment();

        GRACIOUS_TIME = 4 days;
        MAXIMUM_LATE_FEE_PERCENTAGE = 100 * (10 ** 6);
        
        // deploy ERC1155 contract
        poolErc1155Address = _poolErc1155Address;
        poolErc1155 = IERC1155(
            _poolErc1155Address
        );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    /**
    * Emergency functions
    **/
    function emergencyTransferToBank(uint256 amount, uint256 erc20Id) external {
        require(hasRole(OWNER_ROLE, msg.sender));
        ERC20[erc20Id].transfer(bankAddress, amount);
    }

    function togglePauseWithdraw(uint64 poolId) external {
        require(hasRole(ADMIN_ROLE, msg.sender));
        pauseWithdrawStatus[poolId] = !pauseWithdrawStatus[poolId];
    }

    function toggleEmergencyPauseWithdraw() external {
        require(hasRole(ADMIN_ROLE, msg.sender));
        globalPauseWithdrawStatus = !globalPauseWithdrawStatus;
    }

    /**
    * Liquidity Pools Getter and Setter
    **/
    function getPoolErc20(uint64 poolId) public view returns (uint256[] memory) {
        return liquidityPools[poolId].erc20IdStakeOptions;
    }

    function getPoolstakedLiquidity(uint64 poolId, uint256 erc20Id) public view returns (uint256) {
        return stakedLiquidities[poolId][erc20Id];
    }

    function getPoolPeriodTimestamps(uint64 poolId, uint16 period) public view returns (uint32) {
        return liquidityPools[poolId].periodTimestamps[period];
    }

    function setPoolPeriodTimestamps(uint64 poolId, uint16 period, uint32 timestamp) public {
        require(hasRole(ADMIN_ROLE, msg.sender));
        liquidityPools[poolId].periodTimestamps[period] = timestamp;
    }

    function totalPool() public view returns (uint256) {
        return _nextPoolId.current() - 1;
    }

    function isErc20InPoolOptions(uint64 poolId, uint256 erc20Id) private view returns (bool) {
        uint256[] memory erc20Options = liquidityPools[poolId].erc20IdStakeOptions;
        for(uint256 i = 0; i < erc20Options.length; i++) {
            if(erc20Options[i] == erc20Id) return true;
        }

        return false;
    }

    function getTotalPoolStaked(uint64 poolId) public view returns (uint256) {
        uint256[] memory erc20Id = liquidityPools[poolId].erc20IdStakeOptions;
        uint256 totalStaked = 0;
        for(uint256 i = 0; i < erc20Id.length; i++) {
            totalStaked = totalStaked + stakedLiquidities[poolId][erc20Id[i]];
        }
        
        return totalStaked;
    }

    function isPoolFulfilled(uint64 poolId) private view returns (bool) {
        uint256 totalStaked = getTotalPoolStaked(poolId);
        
        if(totalStaked == liquidityPools[poolId].liquidity) return true;

        return false;
    }

    /**
    * Create liquidity pool
    **/
    function createLiquidityPool(LiquidityPool calldata pool, uint8 disburseMode) external returns (uint256) {
        require(hasRole(ADMIN_ROLE, msg.sender));

        // create liquidity pool
        LiquidityPool storage newLiquidityPool = liquidityPools[uint64(_nextPoolId.current())];
        newLiquidityPool.title = pool.title;
        newLiquidityPool.responsibleAddress = pool.responsibleAddress;
        newLiquidityPool.liquidity = pool.liquidity;
        newLiquidityPool.stakingRatePerYear = pool.stakingRatePerYear;
        newLiquidityPool.periodCount = pool.periodCount;
        newLiquidityPool.status = POOL_OPEN;
        newLiquidityPool.deadline = pool.deadline;
        newLiquidityPool.lateRatePerDay = pool.lateRatePerDay;
        newLiquidityPool.erc20IdStakeOptions = pool.erc20IdStakeOptions;
        newLiquidityPool.erc20IdReward = pool.erc20IdReward;
        newLiquidityPool.periodTimestamps = pool.periodTimestamps;
        newLiquidityPool.amountToPayPerTerm = pool.amountToPayPerTerm;

        // set liquidity pool disburse mode
        poolDisburseMode[uint64(_nextPoolId.current())] = disburseMode;

        // create pool ERC1155
        poolErc1155.create(address(this), _nextPoolId.current(), pool.liquidity, "", "0x0");

        _nextPoolId.increment();

        return (_nextPoolId.current() - 1);
    }

    /**
    * Stake to liquidity pool
    **/
    function stakeToPool(uint256 amount, uint64 poolId, uint256 erc20Id) public {
        
        // check if the staker value is still enough
        require(keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_OPEN)), "Not open");
        require(getTotalPoolStaked(poolId) + amount <= liquidityPools[poolId].liquidity, "Too much amount");
        require(block.timestamp <= liquidityPools[poolId].deadline, "Expired");
        require(isErc20InPoolOptions(poolId, erc20Id), "ERC20 not in options");

        // transfer amount from staker to smart contract
        uint balance = ERC20[erc20Id].balanceOf(msg.sender);
        require(balance >= amount, "Balance not enough");
        ERC20[erc20Id].transferFrom(msg.sender, address(this), amount);

        // increase liquidity pool value
        stakedLiquidities[poolId][erc20Id] = stakedLiquidities[poolId][erc20Id] + amount;

        // send ERC1155 to staker
        poolErc1155.safeTransferFrom(address(this), msg.sender, uint256(poolId), amount, "0x0");

        // check if pool is fulfilled
        if(isPoolFulfilled(poolId)) {
            // transfer to bank address
            _closePool(poolId);
            _setStakingStartTimestamp(poolId, liquidityPools[poolId].deadline + GRACIOUS_TIME);
        }
    }

    /**
    * Close liquidity pool
    **/
    function _closePool(uint64 poolId) private {
        require(keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_OPEN)), "Not open");
        
        uint256[] memory erc20Id = liquidityPools[poolId].erc20IdStakeOptions;
        uint balance = 0;
        uint totalBalance = 0;
        for(uint256 i = 0; i < erc20Id.length; i++) {
            balance = stakedLiquidities[poolId][erc20Id[i]];

            // balance should be > 0
            if(balance > 0) {
                // Transfer amount tokens to the bank wallet
                ERC20[erc20Id[i]].transfer(bankAddress, balance);
                totalBalance = totalBalance + balance;

                // reset balance to 0
                stakedLiquidities[poolId][erc20Id[i]] = 0;
            }
        }

        liquidityPools[poolId].valueAtClose = totalBalance;
        liquidityPools[poolId].status = POOL_CLOSE;
    }

    function closePool(uint64 poolId) public {
        require(hasRole(ADMIN_ROLE, msg.sender));
        _closePool(poolId);
    }

    function _setStakingStartTimestamp(uint64 poolId, uint32 startTimestamp) public {
        stakingStartTimeStamp[poolId] = startTimestamp;
        liquidityPools[poolId].status = POOL_DISBURSE;
    }

    function setStakingStartTimestamp(uint64 poolId, uint32 startTimestamp) public {
        require(hasRole(ADMIN_ROLE, msg.sender));
        _setStakingStartTimestamp(poolId, startTimestamp);
    }

    function calculatePayment(uint64 poolId, uint16 period) public view returns (uint256, uint256) {

        if(payments[poolId][period].blockTimestamp > 0) {
            return (payments[poolId][period].amount, payments[poolId][period].lateFee);
        }

        if(period >= liquidityPools[poolId].periodCount) return (0,0);

        uint256 basePayment;
        basePayment = liquidityPools[poolId].amountToPayPerTerm;
        if(poolDisburseMode[poolId] == 1 && period == liquidityPools[poolId].periodCount - 1) {
            basePayment = liquidityPools[poolId].amountToPayPerTerm + liquidityPools[poolId].liquidity;
        }

        uint256 lateFee = 0;

        uint32 periodStart;
        uint32 periodEnd;
        (periodStart, periodEnd) = calculatePeriodTimestamp(poolId, period);

        if (stakingStartTimeStamp[poolId] == 0 || block.timestamp <= periodStart) {
            lateFee = 0;
        } else if (block.timestamp > periodEnd) {
            uint256 lateBlock = block.timestamp - periodEnd;
            uint256 lateDay = (lateBlock / DAY) + 1;
            lateFee = basePayment * lateDay * liquidityPools[poolId].lateRatePerDay / (100 * (10 ** 6));

            if (lateFee > basePayment * MAXIMUM_LATE_FEE_PERCENTAGE / (100 * (10 ** 6))) {
                lateFee = basePayment * MAXIMUM_LATE_FEE_PERCENTAGE / (100 * (10 ** 6));
            }
        }

        return (basePayment, lateFee);
    }

    function getTotalPayment(uint64 _poolId, uint16 _period) private view returns (uint256) {
        uint256 basePayment;
        uint256 lateFee;
        (basePayment, lateFee) = calculatePayment(_poolId, _period);
        return basePayment + lateFee;
    }

    function pay(uint amount, uint64 poolId, uint16 period) public {
        require(hasRole(PAY_ROLE, msg.sender));
        require(payments[poolId][period].blockTimestamp == 0, "Already paid");
        require(keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_DISBURSE)), "Not on disburse");
        
        uint256 basePayment;
        uint256 lateFee;
        (basePayment, lateFee) = calculatePayment(poolId, period);

        // transfer amount to this address
        uint256 erc20Id = liquidityPools[poolId].erc20IdReward;
        ERC20[erc20Id].transferFrom(msg.sender, address(this), amount);

        // add payment history
        uint16 blockNow = uint16(block.timestamp);
        payments[poolId][period] = Payment(blockNow, basePayment - lateFee, lateFee, erc20Id);

        liquidityPools[poolId].periodPaidCount += 1;

        if(liquidityPools[poolId].periodPaidCount == liquidityPools[poolId].periodCount) {
            liquidityPools[poolId].status = POOL_DONE;
        }

        // increase payment value to disburse
        availableToDisburse[poolId][period] = amount;
    }

    function calculatePeriodOfPayment(uint64 poolId) public view returns (uint16) {

        if( keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_DISBURSE)) &&
            block.timestamp > stakingStartTimeStamp[poolId]
        ) {
            uint256 blockNow = block.timestamp;
            uint32[] memory periods = liquidityPools[poolId].periodTimestamps;

            uint16 i;
            uint16 length = uint16(periods.length);
            for(i = 0; i < length; i++) {
                if(blockNow < periods[i]) return i;
            }

            return length - 1;
        }

        return 0;
    }

    function calculatePeriodTimestamp(uint64 poolId, uint16 period) public view returns (uint32, uint32) {
        
        uint32 periodStart;
        
        if(period == 0) {
            periodStart = stakingStartTimeStamp[poolId];
        } else {
            periodStart = liquidityPools[poolId].periodTimestamps[period - 1];
        }
        
        uint32 periodEnd = liquidityPools[poolId].periodTimestamps[period];
        return (periodStart, periodEnd);
    }

    function _getPoolPeriodsInPeriod(uint64 _poolId, address _address, uint16 _period) private view returns (PoolPeriod memory) {

        uint16 i = _period;
        for(i; i >= 0; i--) {
            if(poolPeriods[_poolId][_address][i].startTime > 0) {
                return poolPeriods[_poolId][_address][i];
            }
            if(i == 0) break;
        }

        PoolPeriod memory pool;
        pool.startTime = 0;
        pool.claimableAmount = 0;
        pool.lastErc1155BalanceInPeriod = 0;
        pool.claimedAmount = 0;

        return pool;
    }

    function _calculateClaimable(uint64 _poolId, address _address, uint16 _period, uint256 transferBalance ) private view returns (uint256) {
        require(_period < liquidityPools[_poolId].periodCount, "Out of periods");
        
        uint32 blockNow = uint32(block.timestamp);

        if(stakingStartTimeStamp[_poolId] == 0 || blockNow <= stakingStartTimeStamp[_poolId]) {
            return 0;
        }

        // get the starting block timestamp of the period
        uint32 periodStart;
        uint32 periodEnd;
        (periodStart, periodEnd) = calculatePeriodTimestamp(_poolId, _period);

        if(blockNow <= periodStart) {
            return 0;
        }

        PoolPeriod memory tempPoolPeriod = _getPoolPeriodsInPeriod(_poolId, _address, _period);
        
        uint256 startBlock = tempPoolPeriod.startTime;
        if(startBlock == 0) {
            return 0;
        }

        uint256 erc1155Balance = tempPoolPeriod.lastErc1155BalanceInPeriod;
        if(transferBalance > 0) {
            erc1155Balance = transferBalance;
        }

        uint256 erc1155Supply= liquidityPools[_poolId].liquidity;

        uint256 claimable = 0;
        uint256 basePayment = getTotalPayment(_poolId, _period);

        if(blockNow >= periodEnd) {
            // check if startBlock is before periodStart
            if (startBlock <= periodStart) {
                claimable = erc1155Balance * basePayment / erc1155Supply;
            } else {
                claimable = ((periodEnd - startBlock) * erc1155Balance * basePayment / erc1155Supply / (periodEnd - periodStart)) + tempPoolPeriod.claimableAmount;
            }
        }
        else {
            // check if startBlock is before periodStart
            if (startBlock <= periodStart) {
                claimable = (blockNow - periodStart) * erc1155Balance * basePayment / erc1155Supply / (periodEnd - periodStart);
            } else {
                claimable = ((blockNow - startBlock) * erc1155Balance * basePayment / erc1155Supply / (periodEnd - periodStart)) + tempPoolPeriod.claimableAmount;
            }
        }

        return claimable;
    }

    function calculateClaimable(uint64 _poolId, address _address, uint16 _period ) public view returns (uint256){
        return _calculateClaimable(_poolId, _address, _period, 0);
    }

    function _isPeriodClaimable(uint64 _poolId, uint16 period, address _address) internal view returns (bool) {
        // not yet claim time
        if(block.timestamp < liquidityPools[_poolId].periodTimestamps[period]) return false;

        // not yet paid
        if(payments[_poolId][period].blockTimestamp == 0) return false;

        // claimed
        if(poolPeriods[_poolId][_address][period].claimedAmount > 0) return false;

        return true;
    }

    function withdrawAllClaimable(uint64 poolId) external {
        require(!globalPauseWithdrawStatus, "Withdraw function is on pause.");
        require(!pauseWithdrawStatus[poolId], "This pool withdraw function is on pause.");
        
        uint32 blockNow = uint32(block.timestamp);
        uint256 totalClaimable = 0;
        uint256 claimable = 0;
        
        uint16 i;
        uint16 periodCount = liquidityPools[poolId].periodCount;
        for(i = 0; i < periodCount; i++) {
            if(_isPeriodClaimable(poolId, i, msg.sender)) {
                claimable = calculateClaimable(poolId, msg.sender, i);
                if(claimable > availableToDisburse[poolId][i]) continue;

                poolPeriods[poolId][msg.sender][i].startTime = blockNow;
                poolPeriods[poolId][msg.sender][i].claimableAmount = 0;
                poolPeriods[poolId][msg.sender][i].claimedAmount = claimable;

                availableToDisburse[poolId][i] -= claimable;

                totalClaimable += claimable;
            } else {
                continue;
            }
        }

        require(totalClaimable > 0, "No period to be claim.");

        uint256 erc20Id = liquidityPools[poolId].erc20IdReward;
        ERC20[erc20Id].transfer(msg.sender, totalClaimable);

        if (keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_DONE))) {
            // burn ERC1155
            uint256 erc1155Balance = poolErc1155.balanceOf(msg.sender, poolId);
            poolErc1155.burn(msg.sender, poolId, erc1155Balance);
        }
    }
    
    function withdrawClaimable(uint64 poolId, uint16 period) external {
        require(!globalPauseWithdrawStatus, "Withdraw on pause");
        require(!pauseWithdrawStatus[poolId], "withdraw on pause");
        require(block.timestamp > liquidityPools[poolId].periodTimestamps[period], "Not claimable");
        require(poolPeriods[poolId][msg.sender][period].claimedAmount == 0, "Claimed");

        uint256 claimable = _calculateClaimable(poolId, msg.sender, period, 0);
        
        require(claimable > 0, "Nothing to claim");
        require(claimable <= availableToDisburse[poolId][period], "Not enough available");

        poolPeriods[poolId][msg.sender][period].startTime = uint32(block.timestamp);
        poolPeriods[poolId][msg.sender][period].claimableAmount = 0;
        poolPeriods[poolId][msg.sender][period].claimedAmount = claimable;

        availableToDisburse[poolId][period] -= claimable;

        uint256 erc20Id = payments[poolId][period].erc20Id;
        ERC20[erc20Id].transfer(msg.sender, claimable);

        if (keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_DONE))) {
            // burn ERC1155
            uint256 erc1155Balance = poolErc1155.balanceOf(msg.sender, poolId);
            if(erc1155Balance > 0)
                poolErc1155.burn(msg.sender, poolId, erc1155Balance);
        }
    }

    /**
    * Liquidity Pools Default Functions
    **/
    function setPoolDefault(uint64 poolId) public {
        require(hasRole(ADMIN_ROLE, msg.sender));
        liquidityPools[poolId].status = POOL_DEFAULT;
    }

    function injectDefault(uint amount, uint64 poolId) public {
        require(hasRole(OWNER_ROLE, msg.sender));
        require(keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_DEFAULT)), "On Default");

        // transfer amount to this address
        uint256 erc20Id = liquidityPools[poolId].erc20IdReward;
        ERC20[erc20Id].transferFrom(msg.sender, address(this), amount);

        // add payment history
        defaultAmount[poolId] = amount;
        availableDefaultToDisburse[poolId] = amount;
    }

    function calculateDefaultClaimable(uint64 poolId) public view returns (uint256) {
        // calculate claimable 
        uint256 erc1155Balance = poolErc1155.balanceOf(msg.sender, poolId);
        uint256 claimable = defaultAmount[poolId] * erc1155Balance / liquidityPools[poolId].liquidity;

        return claimable;
    }

    function withdrawDefaultClaimable(uint64 poolId) public {
        require(keccak256(bytes(liquidityPools[poolId].status)) == keccak256(bytes(POOL_DEFAULT)), "On Default");
        require(!globalPauseWithdrawStatus == true, "Withdraw on pause");
        require(!pauseWithdrawStatus[poolId] == true, "Withdraw on pause");
        
        // calculate claimable 
        uint256 erc1155Balance = poolErc1155.balanceOf(msg.sender, poolId);
        uint256 claimable = defaultAmount[poolId] * erc1155Balance / liquidityPools[poolId].liquidity;

        require(claimable > 0, "Nothing to claim");
        require(claimable <= availableDefaultToDisburse[poolId], "Not enough available");

        availableDefaultToDisburse[poolId] -= claimable;

        // burn ERC1155
        if(erc1155Balance > 0) {
            poolErc1155.burn(msg.sender, poolId, erc1155Balance);
        }
        
        uint256 erc20Id = liquidityPools[poolId].erc20IdReward;
        ERC20[erc20Id].transfer(msg.sender, claimable);
    }

    /**
    * ERC1155 Transfer Functions
    **/

    function _saveClaimable(address _address, uint64 _poolId, uint16 periodOfPayment, uint32 blockNow, bool isSender, uint256 amount) internal {
        uint256 erc1155Balance = poolErc1155.balanceOf(_address, _poolId);
        uint256 claimableSender = _calculateClaimable(_poolId, _address, periodOfPayment, erc1155Balance);
        poolPeriods[_poolId][_address][periodOfPayment].claimableAmount = claimableSender;
        poolPeriods[_poolId][_address][periodOfPayment].startTime = blockNow;
        uint256 newBalance;
        if(isSender) { 
            newBalance = erc1155Balance - amount;
        } else {
            newBalance = erc1155Balance + amount;
        }
        poolPeriods[_poolId][_address][periodOfPayment].lastErc1155BalanceInPeriod = newBalance;
    }

    function _saveErc1155TransferPeriod(address _from, address _to, uint256 amount, uint64 _poolId) internal {
        uint16 periodOfPayment = calculatePeriodOfPayment(_poolId);
        uint32 blockNow = uint32(block.timestamp);

        _saveClaimable(_from, _poolId, periodOfPayment, blockNow, true, amount);
        _saveClaimable(_to, _poolId, periodOfPayment, blockNow, false, amount);
    }
    
    function transferERC1155(address _from, address _to, uint256 amount, uint256 _poolId) public {
        _saveErc1155TransferPeriod(_from, _to, amount, uint64(_poolId));
    }

    function transferBatchERC1155(address _from, address _to, uint256[] memory amounts, uint256[] memory _poolIds) public {
        for(uint256 i = 0; i < _poolIds.length; i++) {
            _saveErc1155TransferPeriod(_from, _to, amounts[i], uint64(_poolIds[i]));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC1155 {
    function create( address _initialOwner, uint256 _id, uint256 _initialSupply, string calldata _uri, bytes calldata _data ) external returns (uint256);
    function toggleBanTransfer(address banAddress) external;
    
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function burn(address account,uint256 _id,uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}