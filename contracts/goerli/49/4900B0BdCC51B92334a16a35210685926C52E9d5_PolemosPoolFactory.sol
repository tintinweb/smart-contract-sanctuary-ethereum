// SPDX-License-Identifier: MIT

/*
|   _____            _                                    |
|  |  __ \          | |                                   |
|  | |__) |   ___   | |   ___   _ __ ___     ___    ___   |
|  |  ___/   / _ \  | |  / _ \ | '_ ` _ \   / _ \  / __|  |
|  | |      | (_) | | | |  __/ | | | | | | | (_) | \__ \  |
|  |_|       \___/  |_|  \___| |_| |_| |_|  \___/  |___/  |
|                                                         |
|                                                         |
*/

pragma solidity ^0.8.0;

import './interface/IPoolBase.sol';
import './interface/IPolemos.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

/**
 * @title PolemosPoolFactory
 *
 * @notice PLMS Pool Factory manage Polemos staking pools:
 *      create and register staking pools, distribute yield rewards, access pool-related info, update weights, etc.
 *
 * @notice only owner can register new pools, change weights of the existing pools
 *
 */
contract PolemosPoolFactory is Ownable {
  address public immutable plms;

  /// @dev data structure for staking pool
  struct PoolData {
    address stakingToken; // token to stake in the pool
    address stakingPoolAddress; //deployed staking pool
    uint32 stakingPoolWeight; // staking pool weight (200 for PLMS pools, 800 for PLMS/ETH pools - set during deployment)
  }

  /**
   * @dev Address of master contract which will be cloned
   */
  address public masterPool;

  /**
   * @dev PLMS/block determines yield farming reward base
   *      used by the yield pools controlled by the factory
   */
  uint192 public plmsPerBlock;

  /**
   * @dev The yield is distributed proportionally to pool weights;
   *      total weight is here to help in determining the proportion
   */
  uint32 public totalWeight;

  /**
   * @dev PLMS/block decreases by 1% every blocks/update (set to 45626 blocks during deployment);
   *      an update is triggered by executing `updateEmissionRate` public function
   */
  uint32 public immutable blocksPerUpdate;

  /**
   * @dev End block is the last block when PLMS/block can be decreased;
   *      it is implied that yield farming stops after that block
   */
  uint32 public endBlock;

  /**
   * @dev Each time the PLMS/block ratio gets updated, the block number
   *      when the operation has occurred gets recorded into `lastRatioUpdate`
   * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
   *      has passed when decreasing yield reward by 1%
   */
  uint32 public lastRatioUpdate;

  /// @dev Maps pool token address (like PLMS) -> pool address (like core pool instance)
  mapping(address => address) public stakingPools;

  /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
  mapping(address => bool) public stakingPoolRegistered;

  /**
   * @dev Emitted in newStakingPool() and registerStakingPool()
   *
   * @param _by address of the factory owner
   * @param stakingToken pool token address (like PLMS)
   * @param stakingPoolAddress deployed pool instance address
   * @param stakingPoolWeight pool weight
   */
  event PoolRegistered(
    address indexed _by,
    address indexed stakingToken,
    address indexed stakingPoolAddress,
    uint64 stakingPoolWeight
  );

  /**
   * @dev Emitted in updateStakingPoolWeight()
   *
   * @param _by address of the factory owner
   * @param stakingPoolAddress deployed pool instance address
   * @param stakingPoolWeight new pool weight
   */
  event WeightUpdated(address indexed _by, address indexed stakingPoolAddress, uint32 stakingPoolWeight);

  /**
   * @dev Emitted in updateEmissionRate()
   *
   * @param _by an address which executed an action
   * @param newplmsPerBlock new PLMS/block value
   */
  event PlmsRationUpdated(address indexed _by, uint256 newplmsPerBlock);

  /**
   * @dev Creates/deploys a factory instance
   *
   * @param _plms PLMS ERC20 token address
   * @param _plmsPerBlock initial PLMS/block value for rewards
   * @param _blocksPerUpdate how frequently the rewards gets updated (decreased by 1%), blocks
   * @param _ratioStartBlock block number to measure _blocksPerUpdate from
   * @param _endBlock block number when farming stops and rewards cannot be updated anymore
   */
  constructor(
    address _plms,
    uint192 _plmsPerBlock,
    uint32 _blocksPerUpdate,
    uint32 _ratioStartBlock,
    uint32 _endBlock,
    address _masterPool
  ) {
    // verify the inputs are set
    require(_plms != address(0), 'PLMS address not set');
    require(_plmsPerBlock > 0, 'PLMS/block not set');
    require(_blocksPerUpdate > 0, 'blocks/update not set');
    require(_ratioStartBlock > 0, 'init block not set');
    require(_endBlock > _ratioStartBlock, 'invalid end block: must be greater than init block');

    plms = _plms;
    plmsPerBlock = _plmsPerBlock;
    blocksPerUpdate = _blocksPerUpdate;
    lastRatioUpdate = _ratioStartBlock;
    endBlock = _endBlock;
    masterPool = _masterPool;
  }

  /**
   * @dev Creates a core pool (PolemosCorePool) and registers it within the factory
   *
   * @dev Can be executed by the pool factory owner only
   *
   * @param stakingToken pool token address (like PLMS, or PLMS/ETH pair)
   * @param stakingStartBlock init block to be used for the pool created
   * @param stakingPoolWeight weight of the staking pool to be created
   */
  function newStakingPool(
    address stakingToken,
    uint64 stakingStartBlock,
    uint32 stakingPoolWeight
  ) external virtual onlyOwner {
    // create/deploy new core pool instance
    IPoolBase pool = IPoolBase(Clones.clone(address(masterPool)));
    pool.initialize(plms, address(this), stakingToken, stakingStartBlock, stakingPoolWeight);

    // register it within a factory
    registerStakingPool(address(pool));
  }

  /**
   * @notice Decreases PLMS/block reward by 1%, can be executed
   *      no more than once per `blocksPerUpdate` blocks
   */
  function updateEmissionRate() external {
    // checks if ratio can be updated i.e. if blocks/update (45626 blocks) have passed
    require(timeToUpdateRatio(), 'too frequent');

    // decreases PLMS/block reward by 1%
    plmsPerBlock = (plmsPerBlock * 99) / 100;

    // set `the last ratio update block` = `the last ratio update block` + `blocksPerUpdate`
    lastRatioUpdate += blocksPerUpdate;

    // emit an event
    emit PlmsRationUpdated(msg.sender, plmsPerBlock);
  }

  /**
   * @dev Registers an already deployed pool instance within the factory
   *
   * @dev Can be executed by the pool factory owner only
   *
   * @param poolAddr address of the already deployed pool instance
   */
  function registerStakingPool(address poolAddr) public onlyOwner {
    // read pool information from the pool smart contract
    // via the pool interface (IPoolBase)
    address stakingToken = IPoolBase(poolAddr).stakingToken();
    uint32 weight = IPoolBase(poolAddr).stakingPoolWeight();

    // ensure that the pool is not already registered within the factory
    require(stakingPools[stakingToken] == address(0), 'this pool is already registered');

    // create pool structure, register it within the factory
    stakingPools[stakingToken] = poolAddr;
    stakingPoolRegistered[poolAddr] = true;
    // update total pool weight of the factory
    totalWeight += weight;

    // emit an event
    emit PoolRegistered(msg.sender, stakingToken, poolAddr, weight);
  }

  /**
   * @dev Changes the weight of the pool;
   *      executed by the pool itself or by the factory owner
   *
   * @param stakingPoolAddr address of the pool to change weight for
   * @param poolWeight new weight value to set to
   */
  function updateStakingPoolWeight(address stakingPoolAddr, uint32 poolWeight) external onlyOwner {
    // recalculate total weight
    totalWeight = totalWeight + poolWeight - IPoolBase(stakingPoolAddr).stakingPoolWeight();

    // set the new pool weight
    IPoolBase(stakingPoolAddr).setPoolWeight(poolWeight);

    // emit an event
    emit WeightUpdated(msg.sender, stakingPoolAddr, poolWeight);
  }

  /**
   * @notice Given a pool token retrieves corresponding pool address
   *
   * @dev A shortcut for `stakingPools` mapping
   *
   * @param stakingToken pool token address (like PLMS) to query pool address for
   * @return pool address for the token specified
   */
  function getStakingPoolAddress(address stakingToken) external view returns (address) {
    // read the mapping and return
    return stakingPools[stakingToken];
  }

  /**
   * @notice Reads pool information for the pool defined by its pool token address,
   *
   * @param _stakingToken pool token address to query pool information for
   * @return pool information packed in a PoolData struct
   */
  function getStakingPoolData(address _stakingToken) external view returns (PoolData memory) {
    // get the pool address from the mapping
    address poolAddr = stakingPools[_stakingToken];

    // throw if there is no pool registered for the token specified
    require(poolAddr != address(0), 'not registered');

    // read pool information from the pool smart contract
    // via the pool interface (IPoolBase)
    address stakingToken = IPoolBase(poolAddr).stakingToken();
    uint32 weight = IPoolBase(poolAddr).stakingPoolWeight();

    // create the in-memory structure and return it
    return PoolData({stakingToken: stakingToken, stakingPoolAddress: poolAddr, stakingPoolWeight: weight});
  }

  /**
   * @dev Verifies if `blocksPerUpdate` has passed since last PLMS/block
   *      ratio update and if PLMS/block reward can be decreased by 1%
   *
   * @return true if enough time has passed and `updateEmissionRate` can be executed
   */
  function timeToUpdateRatio() public view returns (bool) {
    // if yield farming period has ended
    if (currentBlockNumber() > endBlock) {
      // PLMS/block reward cannot be updated anymore
      return false;
    }

    // check if blocks/update (45626 blocks) have passed since last update
    return currentBlockNumber() >= lastRatioUpdate + blocksPerUpdate;
  }

  /**
   * @dev Testing time-dependent functionality is difficult and the best way of
   *      doing it is to override block number in helper test smart contracts
   *
   * @return `block.number` in mainnet, custom values in testnets (if overridden)
   */
  function currentBlockNumber() public view virtual returns (uint256) {
    return block.number;
  }
}

// SPDX-License-Identifier: MIT

/*
|   _____            _                                    |
|  |  __ \          | |                                   |
|  | |__) |   ___   | |   ___   _ __ ___     ___    ___   |
|  |  ___/   / _ \  | |  / _ \ | '_ ` _ \   / _ \  / __|  |
|  | |      | (_) | | | |  __/ | | | | | | | (_) | \__ \  |
|  |_|       \___/  |_|  \___| |_| |_| |_|  \___/  |___/  |
|                                                         |
|                                                         |
*/

pragma solidity ^0.8.0;

interface IPoolBase {
  function initialize(
    address _plms,
    address _factory,
    address _stakingToken,
    uint64 _stakingStartBlock,
    uint32 _stakingPoolWeight
  ) external;

  /// @dev token holder info in a pool
  struct UserData {
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
  }

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
    // @dev indicates if the stake was created as a yield reward
    bool isYield;
  }

  function stakingToken() external view returns (address);

  function stakingPoolWeight() external view returns (uint32);

  function lastYieldDistribution() external view returns (uint64);

  function yieldRewardsPerWeight() external view returns (uint256);

  function usersLockingWeight() external view returns (uint256);

  function calcPendingYieldRewards(address _user) external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

  function getDepositsLength(address _user) external view returns (uint256);

  function stakeToPool(uint256 _amount, uint64 _lockedUntil) external;

  function stakeToPoolFor(address account, uint256 _amount, uint64 _lockUntil) external;

  function unstakeFromPool(uint256 _depositId, uint256 _amount) external;

  function unstakeFromPool_tokemak(uint256 _depositId, uint256 _amount) external;

  function syncPoolState() external;

  function processRewards() external;

  function setPoolWeight(uint32 _weight) external;
}

// SPDX-License-Identifier: MIT

/*
|   _____            _                                    |
|  |  __ \          | |                                   |
|  | |__) |   ___   | |   ___   _ __ ___     ___    ___   |
|  |  ___/   / _ \  | |  / _ \ | '_ ` _ \   / _ \  / __|  |
|  | |      | (_) | | | |  __/ | | | | | | | (_) | \__ \  |
|  |_|       \___/  |_|  \___| |_| |_| |_|  \___/  |___/  |
|                                                         |
|                                                         |
*/

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPolemos is IERC20 {
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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