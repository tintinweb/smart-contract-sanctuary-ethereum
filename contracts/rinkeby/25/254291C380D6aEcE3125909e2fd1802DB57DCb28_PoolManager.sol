// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./interfaces/IVesting.sol";
import "./interfaces/IPool.sol";
import "./utils/Ownable.sol";

/**
 * @title Pool Manager
 *
 * @notice Pool Manager provides a single public interface to access pool-related info including vesting
 *      and provides an interface for doing any pools configurations.
 *
 * @notice The manager is authorized (via its owner) to register new pools and update any configurations.
 */
contract PoolManager is Ownable {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    uint256 public constant MANAGER_UID =
        0xc5cfd88c6e4d7e5c8a03c255f03af23c0918d8e82cac196f57466af3fd4a5ec7;

    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like AVG or LP token)
        address poolToken;
        // @dev pool address (like deployed pool instance)
        address poolAddress;
        // @dev vesting address
        address vestingAddress;
        // @dev indicate whether the pool is a Main pool or a Secondary one (LP Pool)
        bool isMainPool;
    }

    address public immutable avg;

    /// @dev Maps pool token address (like AVG) -> pool address (pool instance)
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
    mapping(address => bool) public poolExists;

    /// @dev Maps pool registered pool addresses to vesting address
    mapping(address => address) public vesting;

    /**
     * @dev Fired in registerPool()
     *
     * @param _by an address which executed an action
     * @param poolToken pool token address (like AVG or LP Token)
     * @param poolAddress deployed pool instance address
     * @param isMainPool flag indicating if pool is a main pool
     */
    event PoolRegistered(
        address indexed _by,
        address indexed poolToken,
        address indexed poolAddress,
        bool isMainPool
    );

    /**
     * @dev Fired in changePoolWeight()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weightMin new weight min for the pool
     * @param weightMax new weight max for the pool
     */
    event WeightUpdated(
        address indexed _by,
        address indexed poolAddress,
        uint32 weightMin,
        uint32 weightMax
    );

    /**
     * @dev Fired in vestRewards()
     *
     * @param _by an address which executed an action
     * @param _staker Staker address that will retrieve the rewards.
     * @param _amount Vested rewards amount that will be added to the vesting.
     */
    event VestedRewards(
        address indexed _by,
        address indexed _staker,
        uint256 _amount
    );

    event VestingConfigUpdated(
        address indexed _by,
        address indexed poolAddress,
        uint64 _vestingDuration,
        uint64 _claimFrequency,
        uint64 _cliffDuration
    );

    event VestingRevoked(
        address indexed _by,
        address indexed poolAddress,
        address _recipient,
        uint256 _depositId
    );

    event VestingTransferred(
        address indexed _by,
        address indexed poolAddress,
        address _recipient,
        uint256 _amount
    );

    /**
     * @dev Fired in changeBlocks()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param initBlock new initial block for the pool
     * @param endFarming new end farming for the pool
     * @param endStakingTime new end time for the pool
     */
    event BlocksUpdated(
        address indexed _by,
        address indexed poolAddress,
        uint64 initBlock,
        uint64 endFarming,
        uint64 endStakingTime
    );

    /**
     * @dev Fired in changeConfig()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param _apr new APR value for the pool (Main Pool)
     * @param _avgPerBlock new AVG per block rewards for the pool (Secondary/LP Pool)
     * @param _maxDeposit new max deposit value for the pool
     */
    event APRUpdated(
        address indexed _by,
        address indexed poolAddress,
        uint32 _apr,
        uint192 _avgPerBlock,
        uint256 _maxDeposit
    );

    /**
     * @dev Fired in changeDuration()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param newDurations new duration min for the pool
     * @param isAllowed new duration max for the pool
     */
    event DurationUpdated(
        address indexed _by,
        address indexed poolAddress,
        uint32[] newDurations,
        bool[] isAllowed
    );

    /**
     * @dev Creates/deploys a manager instance
     *
     * @param _avg AVG token as a reward
     */
    constructor(address _avg) {
        // verify the inputs are set
        require(_avg != address(0), "AVG token address not set");

        avg = _avg;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address
     *
     * @dev A shortcut for `pools` mapping
     *
     * @param poolToken pool token address (like AVG/LP Token) to query pool address for
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
    function getPoolData(address _poolToken)
        public
        view
        returns (PoolData memory)
    {
        // get the pool address from the mapping
        address poolAddr = pools[_poolToken];

        // throw if there is no pool registered for the token specified
        require(poolAddr != address(0), "pool not found");

        address vestingAddr = vesting[poolAddr];

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isMainPool = IPool(poolAddr).isMainPool();

        // create the in-memory structure and return it
        return
            PoolData({
                poolToken: poolToken,
                poolAddress: poolAddr,
                vestingAddress: vestingAddr,
                isMainPool: isMainPool
            });
    }

    /**
     * @dev Registers an already deployed pool and vesting instances
     *
     * @dev Can be executed by the pool manager owner only
     *
     * @param poolAddr address of the already deployed pool instance
     * @param vestingAddr address of the already deployed vesting instance
     */
    function registerPool(address poolAddr, address vestingAddr)
        public
        onlyOwner
    {
        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        bool isMainPool = IPool(poolAddr).isMainPool();

        // ensure that the pool is not already registered within the manager
        require(pools[poolToken] == address(0), "pool is already registered");

        // ensure that the vesting is not already registered within the manager
        require(
            vesting[poolAddr] == address(0),
            "vesting is already registered"
        );

        // create pool structure, register it within the manager
        pools[poolToken] = poolAddr;
        poolExists[poolAddr] = true;
        vesting[poolAddr] = vestingAddr;

        // emit an event
        emit PoolRegistered(msg.sender, poolToken, poolAddr, isMainPool);
    }

    /**
     * @dev Manager will handle the interaction between the pool and the vesting instance
     *      when the pool wants to give some vested rewards.
     *
     * @dev Can be executed by the pool instance only
     *
     * @param _staker the staker that will receive the vested rewards.
     * @param _amount vested rewards amount that will be added in the vesting instance.
     */
    function vestRewards(address _staker, uint256 _amount) external {
        require(
            msg.sender == owner() || poolExists[msg.sender],
            "access denied"
        );

        IVesting(vesting[msg.sender]).addGrantToken(_staker, _amount);

        // emit an event
        emit VestedRewards(msg.sender, _staker, _amount);
    }

    /**
     * @dev Manager will handle the interaction between the pool and the vesting instance
     *      when the pool wants to give some vested rewards.
     *
     * @dev Can be executed by the pool instance only
     *
     */
    function changeVesting(
        address poolAddr,
        uint64 _vestingDuration,
        uint64 _claimFrequency,
        uint64 _cliffDuration
    ) public onlyOwner {
        require(vesting[poolAddr] != address(0), "vesting is not registered");

        IVesting(vesting[poolAddr]).setVestingConfiguration(
            _vestingDuration,
            _claimFrequency,
            _cliffDuration
        );

        // emit an event
        emit VestingConfigUpdated(
            msg.sender,
            poolAddr,
            _vestingDuration,
            _claimFrequency,
            _cliffDuration
        );
    }

    function vestingRevoke(
        address poolAddr,
        address _recipient,
        uint256 _depositId
    ) public onlyOwner {
        require(vesting[poolAddr] != address(0), "vesting is not registered");

        IVesting(vesting[poolAddr]).removeGrantToken(_recipient, _depositId);

        // emit an event
        emit VestingRevoked(msg.sender, poolAddr, _recipient, _depositId);
    }

    function vestingTransfer(
        address poolAddr,
        address _recipient,
        uint256 _amount
    ) public onlyOwner {
        require(vesting[poolAddr] != address(0), "vesting is not registered");

        IVesting(vesting[poolAddr]).transferToken(_recipient, _amount);

        // emit an event
        emit VestingTransferred(msg.sender, poolAddr, _recipient, _amount);
    }

    /**
     * @dev Changes the weights of the pool;
     *      executed by the manager owner
     *
     * @param poolAddr address of the pool to change for
     * @param _poolWeightMin new weight value to set to
     * @param _poolWeightMax new weight value to set to
     */
    function changePoolWeight(
        address poolAddr,
        uint32 _poolWeightMin,
        uint32 _poolWeightMax
    ) external onlyOwner {
        // verify function is executed by manager owner
        require(msg.sender == owner());

        // // set the new pool weight
        IPool(poolAddr).setWeight(_poolWeightMin, _poolWeightMax);

        // emit an event
        emit WeightUpdated(
            msg.sender,
            poolAddr,
            _poolWeightMin,
            _poolWeightMax
        );
    }

    /**
     * @dev Changes the blocks (and some timestamps) of the pool;
     *      executed by the manager owner
     *
     * @param poolAddr address of the pool to change for
     * @param _initBlock new initial block for the pool
     * @param _endFarming new end farming value for the pool
     * @param _endStakingTime new timestamp when the staking is done for the pool
     */
    function changeBlocks(
        address poolAddr,
        uint64 _initBlock,
        uint64 _endFarming,
        uint64 _endStakingTime
    ) external onlyOwner {
        // verify function is executed by manager owner
        require(msg.sender == owner());

        IPool(poolAddr).setBlocks(_initBlock, _endFarming, _endStakingTime);

        // emit an event
        emit BlocksUpdated(
            msg.sender,
            poolAddr,
            _initBlock,
            _endFarming,
            _endStakingTime
        );
    }

    /**
     * @dev Changes the main configuration of the pool;
     *      executed by the manager owner
     *
     * @param poolAddr address of the pool to change for
     * @param _apr new fixed APR value for the pool (Main Pool)
     * @param _avgPerBlock new AVG per block as rewards (Secondary/LP Pool)
     * @param _maxDeposit new max deposit value for the pool
     */
    function changeConfig(
        address poolAddr,
        uint32 _apr,
        uint192 _avgPerBlock,
        uint256 _maxDeposit
    ) external onlyOwner {
        // verify function is executed by manager owner
        require(msg.sender == owner());

        IPool(poolAddr).setConfig(_apr, _avgPerBlock, _maxDeposit);

        // emit an event
        emit APRUpdated(msg.sender, poolAddr, _apr, _avgPerBlock, _maxDeposit);
    }

    /**
     * @dev Changes the duration of the pool;
     *      executed by the manager owner
     *
     * @param poolAddr address of the pool to change for
     * @param _durationMin new duration min the pool can receive
     * @param _durationMax new duration max the pool can receive
     * @param _durationStep new duration step (in weeks) for the pool
     */
    function changeDuration(
        address poolAddr,
        uint32 _durationMin,
        uint32 _durationMax,
        uint32 _durationStep
    ) external onlyOwner {
        // verify function is executed by manager owner
        require(msg.sender == owner());

        IPool(poolAddr).setDuration(_durationMin, _durationMax, _durationStep);
    }

    function changeDurations(
        address poolAddr,
        uint32[] memory newDurations,
        bool[] memory isAllowed
    ) external onlyOwner {
        // verify function is executed by manager owner
        require(msg.sender == owner());

        IPool(poolAddr).setDurations(newDurations, isAllowed);

        // emit an event
        emit DurationUpdated(msg.sender, poolAddr, newDurations, isAllowed);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title Illuvium Pool
 *
 * @notice An abstraction representing a pool, see IlluviumPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IVesting {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev track claimed amount
        uint256 totalClaimed;
        // @dev track claimed amount
        uint64 lastClaimed;
        uint16 monthsClaimed;
    }

    function poolToken() external view returns (address);

    function vestingDuration() external view returns (uint64);

    function cliffDuration() external view returns (uint64);

    function claimFrequency() external view returns (uint64);

    function secondsInMonth() external view returns (uint64);

    function totalVestedAmount() external view returns (uint256);

    function totalClaimedAmount() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _user, uint256 _depositId)
        external
        view
        returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function setVestingConfiguration(
        uint64 _vestingDuration,
        uint64 _claimFrequency,
        uint64 _cliffDuration
    ) external;

    function calculateGrantClaim(address _sender, uint256 _depositId)
        external
        view
        returns (uint16, uint256);

    function claim(uint256 _depositId) external;

    function addGrantToken(address _staker, uint256 _amount) external;

    function removeGrantToken(address _recipient, uint256 _depositId) external;

    function transferToken(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title Interface for the Staking Pool
 *
 * @notice An abstraction representing a pool, see PoolBase for details
 */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
        // @dev Track total user rewards claimed
        uint256 totalClaimed;
        // @dev Track last claimed rewards
        uint256 lastClaimed;
        // @dev stake weight - used by secondary pool
        uint256 weight;
    }

    function isMainPool() external view returns (bool);

    function apr() external view returns (uint32);

    // getters
    function getPoolWeights() external view returns (uint32, uint32);

    function getPoolDurations()
        external
        view
        returns (
            uint32,
            uint32,
            uint32
        );

    function getPoolBlocks()
        external
        view
        returns (
            uint64,
            uint64,
            uint64
        );

    function getPoolConfig()
        external
        view
        returns (
            uint32,
            uint192,
            uint256
        );

    function getDeposit(address _user, uint256 _depositId)
        external
        view
        returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function avgPerBlock() external view returns (uint192);

    function endFarming() external view returns (uint64);

    function initBlock() external view returns (uint64);

    function poolWeightMin() external view returns (uint32);

    function poolWeightMax() external view returns (uint32);

    function durationMin() external view returns (uint32);

    function maximumDuration() external view returns (uint32);

    function durationMax() external view returns (uint32);

    function durationStep() external view returns (uint32);

    function maxDeposit() external view returns (uint256);

    function endStakingTime() external view returns (uint64);

    function blockNumber() external view returns (uint256);

    function poolToken() external view returns (address);

    function getDurations() external view returns (uint32[] memory);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function usersClaimedRewards() external view returns (uint256);

    function setWeight(uint32 _poolWeightMin, uint32 _poolWeightMax) external;

    function setBlocks(
        uint64 _initBlock,
        uint64 _endBlock,
        uint64 _endStakingTime
    ) external;

    function setConfig(
        uint32 _apr,
        uint192 _avgPerBlock,
        uint256 _maxDeposit
    ) external;

    function setDurations(
        uint32[] memory newDurations,
        bool[] memory isAllowed
    ) external;

    function setDuration(
        uint32 _durationMin,
        uint32 _durationMax,
        uint32 _durationStep
    ) external;

    function pendingRewards(address _user, uint256 _depositId)
        external
        view
        returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function stake(uint256 _amount, uint64 _lockedUntil) external;

    function unstake(uint256 _depositId, uint256 _amount) external;

    function sync() external;

    function processRewards(uint256 _depositId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}