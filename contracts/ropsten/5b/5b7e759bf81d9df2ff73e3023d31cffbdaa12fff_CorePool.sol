// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "./PoolBase.sol";

/**
 * @title Metamars Core Pool
 *
 * @notice Core pools represent permanent pools like MMC or MMC/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See PoolBase for more details
  */
contract CorePool is PoolBase {
    /// @dev Flag indicating pool type, false means "core pool"
    bool public constant override isFlashPool = false;

    /// @dev Link to deployed MetamarsVault instance
    address public vault;

    /// @dev Used to calculate vault rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public vaultRewardsPerWeight;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are MMC (MMC core pool) or MMC/ETH pair (LP core pool)
    /// @dev For LP core pool this value doesnt' count for MMC tokens received as Vault rewards
    ///      while for MMC core pool it does count for such tokens as well
    uint256 public poolTokenReserve;

    /**
     * @dev Fired in receiveVaultRewards()
     *
     * @param _by an address that sent the rewards, always a vault
     * @param amount amount of tokens received
     */
    event VaultRewardsReceived(address indexed _by, uint256 amount);

    /**
     * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
     *
     * @param _by an address which executed the function
     * @param _to an address which received a reward
     * @param amount amount of reward received
     */
    event VaultRewardsClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in setVault()
     *
     * @param _by an address which executed the function, always a factory owner
     */
    event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

    /**
     * @dev Creates/deploys an instance of the core pool
     *
     * @param _mmc MMC ERC20 Metamars Token address
     * @param _factory Pool factory PoolFactory instance/address
     * @param _poolToken token the pool operates on, for example MMC or MMC/ETH pair
     * @param _initBlock initial block used to calculate the rewards
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    function initialize(
        address _mmc,
        PoolFactory _factory,
        address _poolToken,
        uint64 _initBlock,
        uint32 _weight
    ) public initializer {
        PoolBase.__PoolBase_init(_mmc, _factory, _poolToken, _initBlock, _weight);
    }
    /**
     * @notice Calculates current vault rewards value available for address specified
     *
     * @dev Performs calculations based on current smart contract state only,
     *      not taking into account any additional time/blocks which might have passed
     *
     * @param _staker an address to calculate vault rewards value for
     * @return pending calculated vault reward value for the given address
     */
    function pendingVaultRewards(address _staker) public view returns (uint256 pending) {
        User memory user = users[_staker];

        return weightToReward(user.totalWeight, vaultRewardsPerWeight) - user.subVaultRewards;
    }

    /**
     * @dev Executed only by the factory owner to Set the vault
     *
     * @param _vault an address of deployed MetamarsVault instance
     */
    function setVault(address _vault) external {
        // verify function is executed by the factory owner
        require(factory.owner() == msg.sender, "access denied");

        // verify input is set
        require(_vault != address(0), "zero input");

        // emit an event
        emit VaultUpdated(msg.sender, vault, _vault);

        // update vault address
        vault = _vault;
    }

    /**
     * @dev Executed by the vault to transfer vault rewards MMC from the vault
     *      into the pool
     *
     * @dev This function is executed only for MMC core pools
     *
     * @param _rewardsAmount amount of MMC rewards to transfer into the pool
     */
    function receiveVaultRewards(uint256 _rewardsAmount) external {
        require(msg.sender == vault, "access denied");
        // return silently if there is no reward to receive
        if (_rewardsAmount == 0) {
            return;
        }
        require(usersLockingWeight > 0, "zero locking weight");

        transferMtlFrom(msg.sender, address(this), _rewardsAmount);

        vaultRewardsPerWeight += rewardToWeight(_rewardsAmount, usersLockingWeight);

        // update `poolTokenReserve` only if this is a MMC Core Pool
        if (poolToken == mmc) {
            poolTokenReserve += _rewardsAmount;
        }

        emit VaultRewardsReceived(msg.sender, _rewardsAmount);
    }

    /**
     * @notice Service function to calculate and pay pending vault and yield rewards to the sender
     *
     * @dev Internally executes similar function `_processRewards` from the parent smart contract
     *      to calculate and pay yield rewards; adds vault rewards processing
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function processRewards() external override {
        _processRewards(msg.sender, true);
    }

    /**
     * @inheritdoc PoolBase
     *
     * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
     *      and updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockedUntil
    ) internal override {
        super._stake(_staker, _amount, _lockedUntil);
        User storage user = users[_staker];
        user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

        poolTokenReserve += _amount;
    }

    /*
     * @inheritdoc MetamarsPoolBase
     *
     * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
     *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal override {
        User storage user = users[_staker];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(stakeDeposit.lockedFrom == 0 || now256() > stakeDeposit.lockedUntil, "deposit not yet unlocked");
        poolTokenReserve -= _amount;
        super._unstake(_staker, _depositId, _amount);
        user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);
    }

    function _force_unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount,
        bool _immediate
    ) internal override {
        User storage user = users[_staker];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(
            stakeDeposit.lockedFrom > 0 &&
            (
                (_immediate && now256() < stakeDeposit.lockedUntil) ||
                now256() < (stakeDeposit.lockedUntil - 14 days)
            ),
            "deposit not locked"
        );
        poolTokenReserve -= _amount;
        super._force_unstake(_staker, _depositId, _amount, _immediate);
        user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);
    }

    /**
     * @inheritdoc PoolBase
     *
     * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
     *      and for MMC pool updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal override returns (uint256 pendingYield) {
        _processVaultRewards(_staker);
        pendingYield = super._processRewards(_staker, _withUpdate);

        // update `poolTokenReserve` only if this is a MMC Core Pool
        if (poolToken == mmc) {
            poolTokenReserve += pendingYield;
        }
    }

    /**
     * @dev Used internally to process vault rewards for the staker
     *
     * @param _staker address of the user (staker) to process rewards for
     */
    function _processVaultRewards(address _staker) private {
        User storage user = users[_staker];
        uint256 pendingVaultClaim = pendingVaultRewards(_staker);
        if (pendingVaultClaim == 0) return;
        // read MMC token balance of the pool via standard ERC20 interface
        uint256 mmcBalance = IERC20Upgradeable(mmc).balanceOf(address(this));
        require(mmcBalance >= pendingVaultClaim, "contract MMC balance too low");

        // update `poolTokenReserve` only if this is a MMC Core Pool
        if (poolToken == mmc) {
            // protects against rounding errors
            poolTokenReserve -= pendingVaultClaim > poolTokenReserve ? poolTokenReserve : pendingVaultClaim;
        }

        user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

        // transfer fails if pool MMC balance is not enough - which is a desired behavior
        transferMtl(_staker, pendingVaultClaim);

        emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IMetamarsToken is IERC20Upgradeable {
    function mint(address _to, uint256 _value) external;
    function burn(uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "./IPool.sol";
import "./Aware.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Pool Factory
 *
 * @notice MMC Pool Factory manages Metamars Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_MINTER permission on the MMC token to mint yield
 *      (see `mintYieldTo` function)
 */
contract PoolFactory is OwnableUpgradeable, Aware {
    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like MMC)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for MMC pools, 800 for MMC/ETH pools - set during deployment)
        uint32 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    /**
     * @dev MMC/block determines yield farming reward base
     *      used by the yield pools controlled by the factory
     */
    uint192 public mmcPerBlock;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion
     */
    uint32 public totalWeight;

    /**
     * @dev MMC/block decreases by 3% every blocks/update (set to 91252 blocks during deployment);
     *      an update is triggered by executing `updateMMCPerBlock` public function
     */
    uint32 public blocksPerUpdate;

    /**
     * @dev End block is the last block when MMC/block can be decreased;
     *      it is implied that yield farming stops after that block
     */
    uint32 public endBlock;

    /**
     * @dev Each time the MMC/block ratio gets updated, the block number
     *      when the operation has occurred gets recorded into `lastRatioUpdate`
     * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
     *      has passed when decreasing yield reward by 3%
     */
    uint32 public lastRatioUpdate;

    /// @dev Maps pool token address (like MMC) -> pool address (like core pool instance)
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
    mapping(address => bool) public poolExists;

    /**
     * @dev Fired in createPool() and registerPool()
     *
     * @param _by an address which executed an action
     * @param poolToken pool token address (like MMC)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event PoolRegistered(
        address indexed _by,
        address indexed poolToken,
        address indexed poolAddress,
        uint64 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in changePoolWeight()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event WeightUpdated(address indexed _by, address indexed poolAddress, uint32 weight);

    /**
     * @dev Fired in updateMMCPerBlock()
     *
     * @param _by an address which executed an action
     * @param newMtlPerBlock new MMC/block value
     */
    event MtlRatioUpdated(address indexed _by, uint256 newMtlPerBlock);

    function initialize(
        address _mmc,
        uint192 _mmcPerBlock,
        uint32 _blocksPerUpdate,
        uint32 _initBlock,
        uint32 _endBlock
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        Aware.__Aware_init(_mmc);

        // verify the inputs are set
        require(_mmcPerBlock > 0, "MMC/block not set");
        require(_blocksPerUpdate > 0, "blocks/update not set");
        require(_initBlock > 0, "init block not set");
        require(_endBlock > _initBlock, "invalid end block: must be greater than init block");

        // save the inputs into internal state variables
        mmcPerBlock = _mmcPerBlock;
        blocksPerUpdate = _blocksPerUpdate;
        lastRatioUpdate = _initBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address
     *
     * @dev A shortcut for `pools` mapping
     *
     * @param poolToken pool token address (like MMC) to query pool address for
     * @return pool address for the token specified
     */
    function getPoolAddress(address poolToken) external view returns (address) {
        // read the mapping and return
        return pools[poolToken];
    }

    /**
     * @notice Reads pool information for the pool defined by its pool token address,
     *      designed to simplify integration with the front ends
     *
     * @param _poolToken pool token address to query pool information for
     * @return pool information packed in a PoolData struct
     */
    function getPoolData(address _poolToken) public view returns (PoolData memory) {
        // get the pool address from the mapping
        address poolAddr = pools[_poolToken];

        // throw if there is no pool registered for the token specified
        require(poolAddr != address(0), "pool not found");

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint32 weight = IPool(poolAddr).weight();

        // create the in-memory structure and return it
        return PoolData({ poolToken: poolToken, poolAddress: poolAddr, weight: weight, isFlashPool: isFlashPool });
    }

    /**
     * @dev Verifies if `blocksPerUpdate` has passed since last MMC/block
     *      ratio update and if MMC/block reward can be decreased by 3%
     *
     * @return true if enough time has passed and `updateMMCPerBlock` can be executed
     */
    function shouldUpdateRatio() public view returns (bool) {
        // if yield farming period has ended
        if (block.number > endBlock) {
            // MMC/block reward cannot be updated anymore
            return false;
        }

        // check if blocks/update (91252 blocks) have passed since last update
        return block.number >= lastRatioUpdate + blocksPerUpdate;
    }

    /**
     * @dev Registers an already deployed pool instance within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolAddr address of the already deployed pool instance
     */
    function registerPool(address poolAddr) public onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isFlashPool = IPool(poolAddr).isFlashPool();
        uint32 weight = IPool(poolAddr).weight();

        // ensure that the pool is not already registered within the factory
        require(pools[poolToken] == address(0), "this pool is already registered");

        // create pool structure, register it within the factory
        pools[poolToken] = poolAddr;
        poolExists[poolAddr] = true;
        // update total pool weight of the factory
        totalWeight += weight;

        // emit an event
        emit PoolRegistered(msg.sender, poolToken, poolAddr, weight, isFlashPool);
    }

    /**
     * @notice Decreases MMC/block reward by 3%, can be executed
     *      no more than once per `blocksPerUpdate` blocks
     */
    function updateMMCPerBlock() external {
        // checks if ratio can be updated i.e. if blocks/update (91252 blocks) have passed
        require(shouldUpdateRatio(), "too frequent");

        // decreases MMC/block reward by 3%
        mmcPerBlock = (mmcPerBlock * 97) / 100;

        // set current block as the last ratio update block
        lastRatioUpdate = uint32(block.number);

        // emit an event
        emit MtlRatioUpdated(msg.sender, mmcPerBlock);
    }

    /**
     * @dev Mints MMC tokens; executed by MMC Pool only
     *
     * @dev Requires factory to have ROLE_TOKEN_MINTER permission
     *      on the MMC ERC20 token instance
     *
     * @param _to an address to mint tokens to
     * @param _amount amount of MMC tokens to mint
     */
    function mintYieldTo(address _to, uint256 _amount) external {
        // verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "access denied");

        // mint MMC tokens as required
        mintMtc(_to, _amount);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner
     *
     * @param poolAddr address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address poolAddr, uint32 weight) external {
        // verify function is executed either by factory owner or by the pool itself
        require(msg.sender == owner() || poolExists[msg.sender]);

        // recalculate total weight
        totalWeight = totalWeight + weight - IPool(poolAddr).weight();

        // set the new pool weight
        IPool(poolAddr).setWeight(weight);

        // emit an event
        emit WeightUpdated(msg.sender, poolAddr, weight);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./IPool.sol";
import "./PoolFactory.sol";

/**
 * @title Pool Base
 *
 * @notice An abstract contract containing common logic for any pool,
 *      be it a flash pool (temporary pool like SNX) or a core pool (permanent pool like MMC/ETH or MMC pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (MetamarsPoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - MMC token address
 *          - pool token address, it can be MMC token address, MMC/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 10% for MMC pool and 90% for MMC/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For MMC Pool we use 100 as weight and for MMC/ETH pool - 900.
  */
abstract contract PoolBase is IPool, Aware, ReentrancyGuardUpgradeable {
    /// @dev Data structure representing token holder using a pool
    struct User {
        // @dev Total staked amount
        uint256 tokenAmount;
        // @dev Total weight
        uint256 totalWeight;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev Auxiliary variable for vault rewards calculation
        uint256 subVaultRewards;
        // @dev An array of holder's deposits
        Deposit[] deposits;
        // @dev An array of holder's deactive stake(withdraw before maturity)
        DeactiveStake[] deactiveStakes;
    }

    struct DeactiveStake {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev locking period - until: default: 14 days
        uint64 lockedUntil;
    }

    // @dev Link to treasury
    address public treasury;

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool factory MetamarsPoolFactory instance
    PoolFactory public factory;

    /// @dev Link to the pool token instance, for example MMC or MMC/ETH pair
    address public override poolToken;

    /// @dev Pool weight, 100 for MMC pool or 900 for MMC/ETH
    uint32 public override weight;

    /// @dev Block number of the last yield distribution event
    uint64 public override lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public override yieldRewardsPerWeight;

    /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
    uint256 public override usersLockingWeight;

    /**
     * @dev Stake weight is proportional to deposit amount and time locked, precisely
     *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer
     * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
     * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
     *      weight is a deposit amount multiplied by 2 * 1e6
     */
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;

    /**
     * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
     *      we use simplified calculation and use the following constant instead previos one
     */
    uint256 internal constant YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

    /**
     * @dev Rewards per weight are stored multiplied by 1e12, as integers.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount);

    /**
     * @dev Fired in _updateStakeLock() and updateStakeLock()
     *
     * @param _by an address which performed an operation
     * @param depositId updated deposit ID
     * @param lockedFrom deposit locked from value
     * @param lockedUntil updated deposit locked until value
     */
    event StakeLockUpdated(address indexed _by, uint256 depositId, uint64 lockedFrom, uint64 lockedUntil);

    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(address indexed _by, uint256 yieldRewardsPerWeight, uint64 lastYieldDistribution);

    /**
     * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param _to an address which claimed the yield reward
     * @param amount amount of yield paid
     */
    event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in setWeight()
     *
     * @param _by an address which performed an operation, always a factory
     * @param _fromVal old pool weight value
     * @param _toVal new pool weight value
     */
    event PoolWeightUpdated(address indexed _by, uint32 _fromVal, uint32 _toVal);

    /**
     * @dev Fired in setTreasury()
     *
     * @param _by an address which executed the function, always a factory owner
     */
    event TreasuryUpdated(address indexed _by, address _fromVal, address _toVal);

    /**
     * @dev Overridden in sub-contracts to construct the pool
     *
     * @param _mmc MMC ERC20 Metamars Token address
     * @param _factory Pool factory MetamarsPoolFactory instance/address
     * @param _poolToken token the pool operates on, for example MMC or MMC/ETH pair
     * @param _initBlock initial block used to calculate the rewards
     *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */

    function __PoolBase_init(
        address _mmc,
        PoolFactory _factory,
        address _poolToken,
        uint64 _initBlock,
        uint32 _weight) internal onlyInitializing {
        Aware.__Aware_init(_mmc);
        // verify the inputs are set
        require(address(_factory) != address(0), "MMC Pool fct address not set");
        require(_poolToken != address(0), "pool token address not set");
        require(_initBlock > 0, "init block not set");
        require(_weight > 0, "pool weight not set");

        // save the inputs into internal state variables
        factory = _factory;
        poolToken = _poolToken;
        weight = _weight;
        treasury = msg.sender;

        // init the dependent internal state variables
        lastYieldDistribution = _initBlock;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param _staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address _staker) external view override returns (uint256) {
        // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber() > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 endBlock = factory.endBlock();
            uint256 multiplier =
                blockNumber() > endBlock ? endBlock - lastYieldDistribution : blockNumber() - lastYieldDistribution;
            uint256 mmcRewards = (multiplier * weight * factory.mmcPerBlock()) / factory.totalWeight();

            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight = rewardToWeight(mmcRewards, usersLockingWeight) + yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        // based on the rewards per weight value, calculate pending rewards;
        User memory user = users[_staker];
        uint256 pending = weightToReward(user.totalWeight, newYieldRewardsPerWeight) - user.subYieldRewards;

        return pending;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view override returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address _user, uint256 _depositId) external view override returns (Deposit memory) {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    }

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user) external view override returns (uint256) {
        // read deposits array length and return
        return users[_user].deposits.length;
    }

    function getDeposits(address _user) external view returns (Deposit[] memory) {
        return users[_user].deposits;
    }

    function getDeactiveStakes(address _user) external view returns (DeactiveStake[] memory) {
        return users[_user].deactiveStakes;
    }

    /**
     * @notice Stakes specified amount of tokens for the specified amount of time,
     *      and pays pending yield rewards if any
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     */
    function stake(
        uint256 _amount,
        uint64 _lockUntil
    ) external override {
        // delegate call to an internal function
        _stake(msg.sender, _amount, _lockUntil);
    }

    /**
     * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external override {
        // delegate call to an internal function
        _unstake(msg.sender, _depositId, _amount);
    }

    function force_unstake(
        uint256 _depositId,
        uint256 _amount,
        bool _immediate
    ) external {
        // delegate call to an internal function
        _force_unstake(msg.sender, _depositId, _amount, _immediate);
    }

    /**
     * @notice Extends locking period for a given deposit
     *
     * @dev Requires new lockedUntil value to be:
     *      higher than the current one, and
     *      in the future, but
     *      no more than 1 year in the future
     *
     * @param depositId updated deposit ID
     * @param lockedUntil updated deposit locked until value
     */
    function updateStakeLock(
        uint256 depositId,
        uint64 lockedUntil
    ) external {
        // sync and call processRewards
        _sync();
        _processRewards(msg.sender, false);
        // delegate call to an internal function
        _updateStakeLock(msg.sender, depositId, lockedUntil);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function sync() external override {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function processRewards() external virtual override {
        // delegate call to an internal function
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating
     *
     * @dev Set weight to zero to disable the pool
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint32 _weight) external override {
        // verify function is executed by the factory
        require(msg.sender == address(factory), "access denied");

        // emit an event logging old and new weight values
        emit PoolWeightUpdated(msg.sender, weight, _weight);

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockUntil
    ) internal virtual {
        // validate the inputs
        require(_amount > 0, "zero amount");
        require(
            _lockUntil == 0 || (_lockUntil > now256() && _lockUntil - now256() <= 365 days),
            "invalid lock interval"
        );

        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }

        // in most of the cases added amount `addedAmount` is simply `_amount`
        // however for deflationary tokens this can be different

        // read the current balance
        uint256 previousBalance = IERC20Upgradeable(poolToken).balanceOf(address(this));
        // transfer `_amount`; note: some tokens may get burnt here
        transferPoolTokenFrom(address(msg.sender), address(this), _amount);
        // read new balance, usually this is just the difference `previousBalance - _amount`
        uint256 newBalance = IERC20Upgradeable(poolToken).balanceOf(address(this));
        // calculate real amount taking into account deflation
        uint256 addedAmount = newBalance - previousBalance;

        // set the `lockFrom` and `lockUntil` taking into account that
        // zero value for `_lockUntil` means "no locking" and leads to zero values
        // for both `lockFrom` and `lockUntil`
        uint64 lockFrom = _lockUntil > 0 ? uint64(now256()) : 0;
        uint64 lockUntil = _lockUntil;

        // stake weight formula rewards for locking
        uint256 stakeWeight =
            (((lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / 365 days + WEIGHT_MULTIPLIER) * addedAmount;

        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit =
            Deposit({
                tokenAmount: addedAmount,
                weight: stakeWeight,
                lockedFrom: lockFrom,
                lockedUntil: lockUntil
            });
        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);

        // update user record
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update global variable
        usersLockingWeight += stakeWeight;

        // emit an event
        emit Staked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight =
            (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
                365 days +
                WEIGHT_MULTIPLIER) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount == _amount) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update global variable
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // just return tokens back to holder
        transferPoolToken(msg.sender, _amount);

        // emit an event
        emit Unstaked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _force_unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount,
        bool _immediate
    ) internal virtual {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // do not process the rewards

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight =
            (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
                365 days +
                WEIGHT_MULTIPLIER) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount == _amount) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update global variable
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        if(_immediate) {
            // take 10% away: burns 50%
            uint256 takeAway = _amount / 10; // 10%
            uint256 burningAmount = takeAway/2; // 50%
            uint256 treasuryAmount = takeAway - burningAmount;

            // burn tokens
            if(poolToken == mmc) {
                burnMtc(burningAmount);
            }
            else {
                transferPoolToken(address(0), burningAmount);
            }

            require(treasury != address(0), "Treasury address not set");
            transferPoolToken(treasury, treasuryAmount);

            uint256 remainingAmount = _amount - takeAway;
            // otherwise just return tokens back to holder
            transferPoolToken(msg.sender, remainingAmount);
        }
        else {
            DeactiveStake memory deactiveStake =
                DeactiveStake({
                    tokenAmount: _amount,
                    lockedUntil: uint64(now256() + 14 days) // lock in 14 days
                });
            user.deactiveStakes.push(deactiveStake);
        }

        // emit an event
        emit Unstaked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updateMMCPerBlock`
     */
    function _sync() internal virtual {
        // update MMC per block value in factory if required
        if (factory.shouldUpdateRatio()) {
            factory.updateMMCPerBlock();
        }

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endBlock = factory.endBlock();
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingWeight == 0) {
            lastYieldDistribution = uint64(blockNumber());
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock ? endBlock : blockNumber();
        uint256 blocksPassed = currentBlock - lastYieldDistribution;
        uint256 mmcPerBlock = factory.mmcPerBlock();

        // calculate the reward
        uint256 mmcReward = (blocksPassed * mmcPerBlock * weight) / factory.totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += rewardToWeight(mmcReward, usersLockingWeight);
        lastYieldDistribution = uint64(currentBlock);

        // emit an event
        emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @return pendingYield the rewards calculated and optionally re-staked
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal virtual returns (uint256 pendingYield) {
        // update smart contract state if required
        if (_withUpdate) {
            _sync();
        }

        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);

        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        // direct transfer reward to staker
        factory.mintYieldTo(_staker, pendingYield);

        // update users's record for `subYieldRewards` if requested
        if (_withUpdate) {
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
        }

        // emit an event
        emit YieldClaimed(msg.sender, _staker, pendingYield);
    }

    /**
     * @dev See updateStakeLock()
     *
     * @param _staker an address to update stake lock
     * @param _depositId updated deposit ID
     * @param _lockedUntil updated deposit locked until value
     */
    function _updateStakeLock(
        address _staker,
        uint256 _depositId,
        uint64 _lockedUntil
    ) internal {
        // validate the input time
        require(_lockedUntil > now256(), "lock should be in the future");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        // validate the input against deposit structure
        require(_lockedUntil > stakeDeposit.lockedUntil, "invalid new lock");

        // verify locked from and locked until values
        if (stakeDeposit.lockedFrom == 0) {
            require(_lockedUntil - now256() <= 365 days, "max lock period is 365 days");
            stakeDeposit.lockedFrom = uint64(now256());
        } else {
            require(_lockedUntil - stakeDeposit.lockedFrom <= 365 days, "max lock period is 365 days");
        }

        // update locked until value, calculate new weight
        stakeDeposit.lockedUntil = _lockedUntil;
        uint256 newWeight =
            (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
                365 days +
                WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

        // save previous weight
        uint256 previousWeight = stakeDeposit.weight;
        // update weight
        stakeDeposit.weight = newWeight;

        // update user total weight and global locking weight
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // emit an event
        emit StakeLockUpdated(_staker, _depositId, stakeDeposit.lockedFrom, _lockedUntil);
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      MMC reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight MMC reward per weight
     * @return reward value normalized to 10^12
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the formula and return
        return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward MMC value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward MMC value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the reverse formula and return
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    /**
     * @dev Staker withdraws tokens from locked deposit
     */
    function withdraw(
        uint256 _deactiveStakeId
    ) external {
        address staker = msg.sender;

        User storage user = users[staker];
        DeactiveStake memory deactiveStake = user.deactiveStakes[_deactiveStakeId];
        require(deactiveStake.tokenAmount > 0, "all tokens has been withdrawn");
        require(now256() > deactiveStake.lockedUntil, "deposit not yet unlocked");

        // just return tokens back to holder
        transferPoolToken(msg.sender, deactiveStake.tokenAmount);

        delete user.deactiveStakes[_deactiveStakeId];
    }

    /**
     * @dev Executed only by the owner to Set the treasury address
     *
     * @param _treasury an address
     */
    function setTreasury(address _treasury) external {
        // verify function is executed by the factory owner
        require(factory.owner() == msg.sender, "access denied");

        // verify input is set
        require(_treasury != address(0), "zero input");

        // emit an event
        emit TreasuryUpdated(msg.sender, treasury, _treasury);

        // update vault address
        treasury = _treasury;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferPoolToken(address _to, uint256 _value) internal nonReentrant {
        // just delegate call to the target
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(poolToken), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal nonReentrant {
        // just delegate call to the target
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(poolToken), _from, _to, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

/**
 * @title Metamars Pool
 *
 * @notice An abstraction representing a pool, see MetamarsPoolBase for details
   */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
    }

    // for the rest of the functions see Soldoc in MetamarsPoolBase

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function pendingYieldRewards(address _user) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function stake(
        uint256 _amount,
        uint64 _lockedUntil
    ) external;

    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external;

    function sync() external;

    function processRewards() external;

    function setWeight(uint32 _weight) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../token/IMetamarsToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Metamars Aware
 *
 * @notice Helper smart contract to be inherited by other smart contracts requiring to
 *      be linked to verified Metamars Token instance and performing some basic tasks on it
 */
abstract contract Aware is Initializable  {
  /// @dev Link to MMC ERC20 Token Metamars Token instance
  address public mmc;

  function __Aware_init(address _mmc) internal onlyInitializing {
    // verify MMC address is set and is correct
    require(_mmc != address(0), "MMC address not set");

    // write MMC address
    mmc = _mmc;
  }

  /**
   * @dev Executes MetamarsToken.safeTransferFrom(address(this), _to, _value, "")
   *      on the bound Metamars Token instance
   *
   * @dev Reentrancy safe due to the Metamars Token design
   */
  function transferMtl(address _to, uint256 _value) internal {
    // just delegate call to the target
    transferMtlFrom(address(this), _to, _value);
  }

  /**
   * @dev Executes MetamarsToken.transferFrom(_from, _to, _value)
   *      on the bound MetamarsToken instance
   *
   * @dev Reentrancy safe due to the MetamarsToken design
   */
  function transferMtlFrom(address _from, address _to, uint256 _value) internal {
    // just delegate call to the target
    IMetamarsToken(mmc).transferFrom(_from, _to, _value);
  }

  /**
   * @dev Executes MetamarsToken.mint(_to, _values)
   *      on the bound MetamarsToken instance
   *
   * @dev Reentrancy safe due to the MetamarsToken design
   */
  function mintMtc(address _to, uint256 _value) internal {
    // just delegate call to the target
    IMetamarsToken(mmc).mint(_to, _value);
  }

  /**
   * @dev Executes MetamarsToken.burn(_values)
   *      on the bound MetamarsToken instance
   *
   * @dev Reentrancy safe due to the MetamarsToken design
   */
  function burnMtc(uint256 _value) internal {
    // just delegate call to the target
    IMetamarsToken(mmc).burn(_value);
  }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}