// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// VUCA + Pellar + LightLink 2022

contract PellarStaking is Ownable {
  // Staking user data
  struct Staking {
    uint256 amount;
    uint256 accumulatedRewards;
    uint256 minusRewards; // rewards that user can not get computed by block
  }

  // Staking pool
  struct Pool {
    bool inited;
    address rewardToken; // require init
    address stakeToken; // require init
    uint256 maxStakeTokens; // require init
    uint256 startBlock; // require init
    uint256 endBlock; // require init
    uint256 rewardTokensPerBlock; // require init
    uint256 tokensStaked;
    uint256 lastRewardedBlock; // require init
    uint256 accumulatedRewardsPerShare;
    uint256 updateDelay; // blocks // default 2048 blocks = 8 hours
    // admin check
    uint256 totalUserRewards;
    uint256 rewardsWithdrew;
  }

  struct PoolChanges {
    bool applied;
    uint256 maxStakeTokens;
    uint256 endBlock;
    uint256 rewardTokensPerBlock;
    uint256 timestamp;
    uint256 blockNumber;
  }

  uint256 public constant REWARDS_PRECISION = 1e18;

  uint256 public currentPoolId;

  mapping(uint256 => Pool) public pools; // staking events

  // Mapping poolId =>
  mapping(uint256 => PoolChanges[]) public poolsChanges; // staking changes queue

  // Mapping poolId => user address => Staking
  mapping(uint256 => mapping(address => Staking)) public stakingUsersInfo;

  // Events
  event StakingChange(address indexed user, uint256 indexed poolId, Pool pool, Staking staking);
  event PoolUpdated(uint256 poolId, Pool pool, PoolChanges changes, uint256 activeBlock);

  // Constructor
  constructor() {}

  /* View */
  function getRawRewards(uint256 _poolId, address _account) public view returns (uint256) {
    Staking memory staking = stakingUsersInfo[_poolId][_account];

    (uint256 accumulatedRewardsPerShare, , ) = getPoolRewardsCheckpoint(_poolId, block.number);

    return staking.accumulatedRewards + (staking.amount * accumulatedRewardsPerShare) - staking.minusRewards;
  }

  function getRewards(uint256 _poolId, address _account) public view returns (uint256) {
    uint256 rawRewards = getRawRewards(_poolId, _account);
    Pool memory pool = getLatestPoolInfo(_poolId);

    return rawRewards / (10**IERC20(pool.stakeToken).decimals()) / REWARDS_PRECISION;
  }

  function getLatestPoolInfo(uint256 _poolId) public view returns (Pool memory) {
    Pool memory pool = pools[_poolId];

    uint256 size = poolsChanges[_poolId].length;
    for (uint256 i; i < size; i++) {
      PoolChanges memory changes = poolsChanges[_poolId][i];

      if (changes.applied) {
        continue;
      }

      uint256 updateAtBlock = changes.blockNumber + pool.updateDelay;
      if (!(pool.endBlock > updateAtBlock && block.number >= updateAtBlock)) {
        continue;
      }

      uint256 rewards;
      (pool.accumulatedRewardsPerShare, pool.lastRewardedBlock, rewards) = getPoolRewardsCheckpoint(_poolId, updateAtBlock);
      pool.totalUserRewards += rewards;

      pool.maxStakeTokens = changes.maxStakeTokens;
      pool.endBlock = changes.endBlock;
      pool.rewardTokensPerBlock = changes.rewardTokensPerBlock;
    }

    uint256 _rewards;
    (pool.accumulatedRewardsPerShare, pool.lastRewardedBlock, _rewards) = getPoolRewardsCheckpoint(_poolId, block.number);
    pool.totalUserRewards += _rewards;

    return pool;
  }

  function getRewardsWithdrawable(uint256 _poolId) public view returns (uint256) {
    Pool memory pool = getLatestPoolInfo(_poolId);

    uint256 contractBalance = IERC20(pool.rewardToken).balanceOf(address(this));
    if (pool.endBlock > block.number || contractBalance == 0) {
      return 0;
    }

    uint256 totalUserRewards = pool.totalUserRewards / (10**IERC20(pool.stakeToken).decimals()) / REWARDS_PRECISION;
    uint256 rewardsWithdrew = pool.rewardsWithdrew / (10**IERC20(pool.stakeToken).decimals()) / REWARDS_PRECISION;
    return contractBalance + rewardsWithdrew - totalUserRewards;
  }

  /* User */
  function stake(uint256 _poolId, uint256 _amount) external {
    updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.startBlock <= block.number, "Staking inactive");
    require(pool.endBlock >= block.number, "Staking ended");
    require(_amount > 0, "Invalid amount");
    require(_amount + pool.tokensStaked <= pool.maxStakeTokens, "Exceed max stake tokens");

    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];

    updatePoolRewards(_poolId, block.number);
    // Update user
    staking.accumulatedRewards = getRawRewards(_poolId, msg.sender);
    staking.amount += _amount;
    staking.minusRewards = staking.amount * pool.accumulatedRewardsPerShare;

    // Update pool
    pool.tokensStaked += _amount;

    // Deposit tokens
    emit StakingChange(msg.sender, _poolId, pool, staking);
    IERC20(pool.stakeToken).transferFrom(address(msg.sender), address(this), _amount);
  }

  function emergencyWithdraw(uint256 _poolId) external {
    updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];
    uint256 amount = staking.amount;
    require(staking.amount > 0, "Insufficient funds");

    updatePoolRewards(_poolId, block.number);
    // Update pool
    if (pool.tokensStaked >= amount) {
      pool.tokensStaked -= amount;
    }

    staking.amount = 0;

    // Withdraw tokens
    IERC20(pool.stakeToken).transfer(address(msg.sender), amount);

    emit StakingChange(msg.sender, _poolId, pool, staking);

    // Update staker
    staking.accumulatedRewards = 0;
    staking.minusRewards = 0;
  }

  function unStake(uint256 _poolId) external {
    updatePoolInfo(_poolId);
    Pool storage pool = pools[_poolId];
    require(pool.endBlock <= block.number, "Staking active");

    Staking storage staking = stakingUsersInfo[_poolId][msg.sender];
    uint256 amount = staking.amount;
    require(staking.amount > 0, "Insufficient funds");

    updatePoolRewards(_poolId, block.number);
    // Pay rewards
    uint256 rewards = getRewards(_poolId, msg.sender);
    IERC20(pool.rewardToken).transfer(msg.sender, rewards);

    // Update pool
    pool.rewardsWithdrew += getRawRewards(_poolId, msg.sender);
    if (pool.tokensStaked >= amount) {
      pool.tokensStaked -= amount;
    }

    // Withdraw tokens
    IERC20(pool.stakeToken).transfer(address(msg.sender), amount);

    emit StakingChange(msg.sender, _poolId, pool, staking);

    // Update staker
    staking.accumulatedRewards = 0;
    staking.minusRewards = 0;
    staking.amount = 0;
  }

  function updatePoolInfo(uint256 _poolId) internal {
    Pool storage pool = pools[_poolId];

    uint256 size = poolsChanges[_poolId].length;
    for (uint256 i; i < size; i++) {
      PoolChanges storage changes = poolsChanges[_poolId][i];

      if (changes.applied) {
        continue;
      }

      uint256 updateAtBlock = changes.blockNumber + pool.updateDelay;
      if (!(pool.endBlock > updateAtBlock && block.number >= updateAtBlock)) {
        continue;
      }

      updatePoolRewards(_poolId, updateAtBlock);
      pool.maxStakeTokens = changes.maxStakeTokens;
      pool.endBlock = changes.endBlock;
      pool.rewardTokensPerBlock = changes.rewardTokensPerBlock;
      changes.applied = true;
    }
  }

  function updatePoolRewards(uint256 _poolId, uint256 _blockNumber) internal {
    Pool storage pool = pools[_poolId];

    if (pool.tokensStaked == 0 && _blockNumber < pool.endBlock) {
      pool.lastRewardedBlock = _blockNumber;
      return;
    }

    uint256 rewards;
    (pool.accumulatedRewardsPerShare, pool.lastRewardedBlock, rewards) = getPoolRewardsCheckpoint(_poolId, _blockNumber);
    pool.totalUserRewards += rewards;
  }

  function getPoolRewardsCheckpoint(uint256 _poolId, uint256 _blockNumber)
    public
    view
    returns (
      uint256 accumulatedRewardsPerShare,
      uint256 lastRewardedBlock,
      uint256 rewards
    )
  {
    Pool memory pool = pools[_poolId];

    uint256 floorBlock = _blockNumber <= pool.endBlock ? _blockNumber : pool.endBlock;

    uint256 blocksSinceLastReward;
    if (floorBlock >= pool.lastRewardedBlock) {
      blocksSinceLastReward = floorBlock - pool.lastRewardedBlock;
    }
    rewards = blocksSinceLastReward * pool.rewardTokensPerBlock;
    if (pool.tokensStaked > 0) {
      accumulatedRewardsPerShare = pool.accumulatedRewardsPerShare + (rewards / pool.tokensStaked);
    }
    lastRewardedBlock = floorBlock;
  }

  /* Admin */
  function createPool(
    address _rewardToken,
    address _stakeToken,
    uint256 _maxStakeTokens,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _rewardTokensPerBlock,
    uint256 _updateDelay
  ) external onlyOwner {
    require(_startBlock > 0 && _startBlock < _endBlock, "Invalid start/end block");
    require(_rewardToken != address(0), "Invalid reward token");
    require(_stakeToken != address(0), "Invalid reward token");

    pools[currentPoolId].inited = true;
    pools[currentPoolId].rewardToken = _rewardToken;
    pools[currentPoolId].stakeToken = _stakeToken;

    pools[currentPoolId].maxStakeTokens = _maxStakeTokens;
    pools[currentPoolId].startBlock = _startBlock;
    pools[currentPoolId].endBlock = _endBlock;

    pools[currentPoolId].rewardTokensPerBlock = _rewardTokensPerBlock * (10**IERC20(_stakeToken).decimals()) * REWARDS_PRECISION;
    pools[currentPoolId].lastRewardedBlock = _startBlock;
    pools[currentPoolId].updateDelay = _updateDelay; // = 8 hours;

    PoolChanges memory changes;

    emit PoolUpdated(currentPoolId, pools[currentPoolId], changes, block.number);
    currentPoolId += 1;
  }

  function updateMaxStakeTokens(uint256 _poolId, uint256 _maxStakeTokens) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");

    PoolChanges memory changes = PoolChanges({ applied: false, rewardTokensPerBlock: pools[_poolId].rewardTokensPerBlock, endBlock: pools[_poolId].endBlock, maxStakeTokens: _maxStakeTokens, timestamp: block.timestamp, blockNumber: block.number });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(_poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  function updateRewardTokensPerBlock(uint256 _poolId, uint256 _rewardTokensPerBlock) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");

    uint256 rewardTokensPerBlock = _rewardTokensPerBlock * (10**IERC20(pools[_poolId].stakeToken).decimals()) * REWARDS_PRECISION;

    PoolChanges memory changes = PoolChanges({ applied: false, rewardTokensPerBlock: rewardTokensPerBlock, endBlock: pools[_poolId].endBlock, maxStakeTokens: pools[_poolId].maxStakeTokens, timestamp: block.timestamp, blockNumber: block.number });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(_poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  function updateEndBlock(uint256 _poolId, uint256 _endBlock) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");
    require(block.number <= _endBlock, "Invalid input");
    require(block.number + pools[_poolId].updateDelay < pools[_poolId].endBlock, "Exceed Blocks");

    PoolChanges memory changes = PoolChanges({ applied: false, rewardTokensPerBlock: pools[_poolId].rewardTokensPerBlock, endBlock: _endBlock, maxStakeTokens: pools[_poolId].maxStakeTokens, timestamp: block.timestamp, blockNumber: block.number });
    poolsChanges[_poolId].push(changes);

    emit PoolUpdated(_poolId, pools[_poolId], changes, block.number + pools[_poolId].updateDelay);
  }

  /* @Dev only, remove in prod */
  function updateChangesDelayBlocks(uint256 _poolId, uint256 _blocks) external onlyOwner {
    require(pools[_poolId].inited, "Invalid Pool");

    pools[_poolId].updateDelay = _blocks;
    PoolChanges memory changes;

    emit PoolUpdated(_poolId, pools[_poolId], changes, block.number);
  }

  function failureWithdrawERC20(
    uint256 _poolId,
    address _to,
    uint256 _amount
  ) external onlyOwner {
    updatePoolInfo(_poolId);
    Pool memory pool = pools[_poolId];
    require(pool.endBlock <= block.number, "Staking active");

    updatePoolRewards(_poolId, block.number);
    pool = pools[_poolId];

    uint256 totalUserRewards = pool.totalUserRewards / (10**IERC20(pool.stakeToken).decimals()) / REWARDS_PRECISION;
    uint256 rewardsWithdrew = pool.rewardsWithdrew / (10**IERC20(pool.stakeToken).decimals()) / REWARDS_PRECISION;
    uint256 contractBalance = IERC20(pool.rewardToken).balanceOf(address(this));

    require(_amount + totalUserRewards <= contractBalance + rewardsWithdrew);

    IERC20(pool.rewardToken).transfer(_to, _amount);
  }

  function withdrawERC20(
    uint256 _poolId,
    address _to,
    uint256 _amount
  ) external onlyOwner {
    updatePoolInfo(_poolId);
    Pool memory pool = pools[_poolId];
    require(pool.endBlock <= block.number, "Staking active");
    require(pool.tokensStaked == 0, "Not allowed");

    IERC20(pool.rewardToken).transfer(_to, _amount);
  }
}

interface IERC20 {
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function transfer(address to, uint256 amount) external returns (bool);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);
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