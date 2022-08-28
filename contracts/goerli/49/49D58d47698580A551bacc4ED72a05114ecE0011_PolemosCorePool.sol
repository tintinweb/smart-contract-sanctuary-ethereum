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

import './PolemosPoolBase.sol';

/**
 * @title PolemosCorePool
 *
 * @notice handle Common logic for staking pools: stake, unstake, processRewards
 *
 * @notice have vault reward supported
 */
contract PolemosCorePool is PolemosPoolBase {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 public vaultRewardsPerWeight;
  uint256 public poolTokenReserve;

  /// @dev total tokens in this pool for yield reward
  uint256 public totalTokensForVaultReward;

  /// @dev total tokens claimed by users for yield reward
  uint256 public totalVaultRewardClaimed;

  event VaultRewardsReceived(address indexed _by, uint256 amount);
  event VaultRewardsClaimed(address indexed _by, address indexed _to, uint256 amount);
  event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

  function initialize(
    address _tPLMS,
    address _PLMS,
    address _stakingToken,
    uint64 _stakingStartBlock,
    uint192 _tPLMSPerBlock,
    uint32 _blocksPerUpdate,
    uint32 _ratioStartBlock,
    uint32 _endBlock
  ) external override initializer {
    __PolemosPoolBase_init(
      _tPLMS,
      _PLMS,
      _stakingToken,
      _stakingStartBlock,
      _tPLMSPerBlock,
      _blocksPerUpdate,
      _ratioStartBlock,
      _endBlock
    );
  }

  /**
   * @dev Executed by the anyone to add vault rewards tPLMS
   *
   * @dev This function is executed only for tPLMS core pools
   *
   * @param _rewardsAmount amount of tPLMS rewards
   */
  function addTokenForVaultReward(uint256 _rewardsAmount) external {
    // return silently if there is no reward to receive
    if (_rewardsAmount == 0) {
      return;
    }
    require(usersLockingWeight > 0, 'zero locking weight');
    IERC20Upgradeable(tPLMS).safeTransferFrom(msg.sender, address(this), _rewardsAmount);
    totalTokensForVaultReward += _rewardsAmount;

    vaultRewardsPerWeight += rewardToWeight(_rewardsAmount, usersLockingWeight);

    // update `poolTokenReserve` only if this is a tPLMS Core Pool
    if (stakingToken == tPLMS) {
      poolTokenReserve += _rewardsAmount;
    }

    emit VaultRewardsReceived(msg.sender, _rewardsAmount);
  }

  function processRewards() external override {
    _processRewards(msg.sender, true);
  }

  /**
   * @notice Calculates current vault rewards value available for address specified
   *
   * @dev Performs calculations based on current smart contract state only,
   *      not taking into account any additional time/blocks which might have passed
   *
   * @param _user an address to calculate vault rewards value for
   * @return pending calculated vault reward value for the given address
   */
  function calcPendingVaultRewards(address _user) public view returns (uint256 pending) {
    UserData memory user = usersData[_user];

    return weightToReward(user.totalWeight, vaultRewardsPerWeight) - user.subVaultRewards;
  }

  /**
   * @inheritdoc PolemosPoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _stakeToPool(
    address account,
    uint256 _amount,
    uint64 _lockedUntil,
    bool _isYield,
    bool _isPLMS
  ) internal override {
    super._stakeToPool(account, _amount, _lockedUntil, _isYield, _isPLMS);
    UserData storage user = usersData[account];
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

    poolTokenReserve += _amount;
  }

  /**
   * @inheritdoc PolemosPoolBase
   *
   * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
   *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
   */
  function _unstakeFromPool(
    uint256 _depositId,
    uint256 _amount,
    bool _is_tokemak
  ) internal override {
    UserData storage user = usersData[msg.sender];
    Deposit memory stakeDeposit = user.deposits[_depositId];
    require(stakeDeposit.lockedFrom == 0 || currentTS() > stakeDeposit.lockedUntil, 'deposit not yet unlocked');
    poolTokenReserve -= _amount;
    super._unstakeFromPool(_depositId, _amount, _is_tokemak);
    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);
  }

  /**
   * @inheritdoc PolemosPoolBase
   *
   * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
   *      and for tPLMS pool updates (increases) pool token reserve (pool tokens value available in the pool)
   */
  function _processRewards(address _staker, bool _withUpdate) internal override returns (uint256 pendingYield) {
    _processVaultRewards(_staker);
    pendingYield = super._processRewards(_staker, _withUpdate);

    // update `poolTokenReserve` only if this is a tPLMS Core Pool
    if (stakingToken == tPLMS) {
      poolTokenReserve += pendingYield;
    }
  }

  /**
   * @dev Used internally to process vault rewards for the staker
   *
   * @param _staker address of the user (staker) to process rewards for
   */
  function _processVaultRewards(address _staker) private {
    UserData storage user = usersData[_staker];
    uint256 pendingVaultClaim = calcPendingVaultRewards(_staker);
    if (pendingVaultClaim == 0) return;
    if (totalTokensForVaultReward < (totalVaultRewardClaimed + pendingVaultClaim)) {
      // not enough tokens for vault reward
      return;
    }

    // update `stakingTokenReserve` only if this is a tPLMS Core Pool
    if (stakingToken == tPLMS) {
      // protects against rounding errors
      poolTokenReserve -= pendingVaultClaim > poolTokenReserve ? poolTokenReserve : pendingVaultClaim;
    }

    user.subVaultRewards = weightToReward(user.totalWeight, vaultRewardsPerWeight);

    IERC20Upgradeable(tPLMS).safeTransfer(_staker, pendingVaultClaim);
    totalVaultRewardClaimed += pendingVaultClaim;

    emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
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

import './interface/IPoolBase.sol';
import './interface/IPolemosCorePool.sol';
import './interface/ITokemakPool.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

/**
 * @title PolemosPoolBase
 *
 * @notice handle Common logic for staking pools: stake, unstake, processRewards
 *
 */
abstract contract PolemosPoolBase is IPoolBase, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public tPLMS;

  address public PLMS;

  /// @dev Token holder storage, maps token holder address to their data record
  mapping(address => UserData) public usersData;

  address public override stakingToken;

  uint64 public override lastYieldDistribution;

  /// @dev Used to calculate yield rewards
  /// @dev This value is different from "reward per token" used in locked pool
  /// @dev Note: stakes are different in duration and "weight" reflects that
  uint256 public override yieldRewardsPerWeight;

  /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
  uint256 public override usersLockingWeight;

  /// @dev total tokens in this pool for yield reward
  uint256 public totalTokensForYieldReward;

  /// @dev total tokens claimed by users for yield reward
  uint256 public totalYieldRewardClaimed;

  /**
   * @dev tPLMS/block determines yield farming reward base
   *      used by the yield pools controlled by the factory
   */
  uint192 public tPLMSPerBlock;

  /**
   * @dev tPLMS/block decreases by 1% every blocks/update (set to 45626 blocks during deployment);
   *      an update is triggered by executing `updateEmissionRate` public function
   */
  uint32 public blocksPerUpdate;

  /**
   * @dev End block is the last block when tPLMS/block can be decreased;
   *      it is implied that yield farming stops after that block
   */
  uint32 public endBlock;

  /**
   * @dev Each time the tPLMS/block ratio gets updated, the block number
   *      when the operation has occurred gets recorded into `lastRatioUpdate`
   * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
   *      has passed when decreasing yield reward by 1%
   */
  uint32 public lastRatioUpdate;

  mapping(address => bool) plmsDepositWhitelist;
  uint256 public totalPlmsStakingAmount;
  uint256 public totalPlmsSwapAmount;

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

  uint64 public constant PERMANENT_LOCK_TIME = type(uint64).max;
  uint256 public constant PERMANENT_LOCK_WEIGHT_MULTIPLIER = 3;

  /**
   * @dev Emitted in _stakeToPool()
   *
   * @param _by an address who staked tokens
   * @param amount amount of tokens staked
   */
  event Staked(address indexed _by, uint256 amount);

  /**
   * @dev Emitted in _extendLockTime() and extendLockTime()
   *
   * @param _by an address which performed an operation
   * @param depositId updated deposit ID
   * @param lockedFrom deposit locked from value
   * @param lockedUntil updated deposit locked until value
   */
  event StakeLockUpdated(address indexed _by, uint256 depositId, uint64 lockedFrom, uint64 lockedUntil);

  /**
   * @dev Emitted in _unstakeFromPool()
   *
   * @param _by an address who unstaked tokens
   * @param amount amount of tokens unstaked
   */
  event Unstaked(address indexed _by, uint256 amount);

  /**
   * @dev Emitted in _syncPoolState(), syncPoolState() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param yieldRewardsPerWeight updated yield rewards per weight value
   * @param lastYieldDistribution usually, current block number
   */
  event Synchronized(address indexed _by, uint256 yieldRewardsPerWeight, uint64 lastYieldDistribution);

  /**
   * @dev Emitted in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
   *
   * @param _by an address which performed an operation
   * @param _to an address which claimed the yield reward
   * @param amount amount of yield paid
   */
  event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

  /**
   * @dev Emitted in updateEmissionRate()
   *
   * @param _by an address which executed an action
   * @param newtPLMSPerBlock new tPLMS/block value
   */
  event PlmsRationUpdated(address indexed _by, uint256 newtPLMSPerBlock);

  event PlmsDeposited(address indexed _by, uint256 amount);

  function initialize(
    address _tPLMS,
    address _PLMS,
    address _stakingToken,
    uint64 _stakingStartBlock,
    uint192 _tPLMSPerBlock,
    uint32 _blocksPerUpdate,
    uint32 _ratioStartBlock,
    uint32 _endBlock
  ) external virtual override initializer {
    __PolemosPoolBase_init(
      _tPLMS,
      _PLMS,
      _stakingToken,
      _stakingStartBlock,
      _tPLMSPerBlock,
      _blocksPerUpdate,
      _ratioStartBlock,
      _endBlock
    );
  }

  function __PolemosPoolBase_init(
    address _tPLMS,
    address _PLMS,
    address _stakingToken,
    uint64 _stakingStartBlock,
    uint192 _tPLMSPerBlock,
    uint32 _blocksPerUpdate,
    uint32 _ratioStartBlock,
    uint32 _endBlock
  ) internal onlyInitializing {
    __ReentrancyGuard_init();
    __Ownable_init();
    require(_tPLMS != address(0), 'tPLMS address not set');
    require(_stakingToken != address(0), 'pool token address not set');
    require(_stakingStartBlock > 0, 'init block not set');

    tPLMS = _tPLMS;
    stakingToken = _stakingToken;
    PLMS = _PLMS;

    // init the dependent internal state variables
    lastYieldDistribution = _stakingStartBlock;

    tPLMSPerBlock = _tPLMSPerBlock;
    blocksPerUpdate = _blocksPerUpdate;
    lastRatioUpdate = _ratioStartBlock;
    endBlock = _endBlock;
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
  function stakeToPool(uint256 _amount, uint64 _lockUntil) external override {
    // delegate call to an internal function
    transferStakingTokenFrom(address(msg.sender), address(this), _amount);
    _stakeToPool(msg.sender, _amount, _lockUntil, false, false);
  }

  function stakePLMSToPool(uint256 _amount, uint64 _lockUntil) external {
    stakePlmsForTPlms(_amount);
    // delegate call to an internal function
    _stakeToPool(msg.sender, _amount, _lockUntil, false, true);
    totalPlmsStakingAmount += _amount;
  }

  function stakeToPoolFor(
    address account,
    uint256 _amount,
    uint64 _lockUntil
  ) external override {
    // delegate call to an internal function
    transferStakingTokenFrom(address(msg.sender), address(this), _amount);
    _stakeToPool(account, _amount, _lockUntil, false, false);
  }

  function stakePLMSToPoolFor(
    address account,
    uint256 _amount,
    uint64 _lockUntil
  ) external {
    stakePlmsForTPlms(_amount);
    // delegate call to an internal function
    _stakeToPool(account, _amount, _lockUntil, false, true);
    totalPlmsStakingAmount += _amount;
  }

  /**
   * @notice add tokens for yield rewards.
   *
   * @dev Can be executed by anyone at any time.
   *
   * @param _amount amount of tokens to add
   */
  function addTokenForYieldReward(uint256 _amount) external {
    IERC20Upgradeable(tPLMS).safeTransferFrom(msg.sender, address(this), _amount);
    totalTokensForYieldReward += _amount;
  }

  /**
   * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
   *
   * @dev Requires amount to unstake to be greater than zero
   *
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   */
  function unstakeFromPool(uint256 _depositId, uint256 _amount) external override {
    // delegate call to an internal function
    _unstakeFromPool(_depositId, _amount, false);
  }

  function unstakePlmsFromPool(uint256 _depositId, uint256 _amount) external override {
    // delegate call to an internal function
    _unstakeFromPool(_depositId, _amount, true);
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
  function extendLockTime(uint256 depositId, uint64 lockedUntil) external {
    // sync and call processRewards
    _syncPoolState();
    _processRewards(msg.sender, false);

    UserData storage user = usersData[msg.sender];
    // update usersData's record for `subYieldRewards` if requested
    user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

    // delegate call to an internal function
    _extendLockTime(msg.sender, depositId, lockedUntil);
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
  function syncPoolState() external override {
    // delegate call to an internal function
    _syncPoolState();
  }

  /**
   * @notice Service function to calculate and pay pending yield rewards to the sender
   *
   * @dev Can be executed by anyone at any time, but has an effect only when
   *      executed by deposit holder and when at least one block passes from the
   *      previous reward processing
   * @dev Executed internally when staking and unstaking, executes syncPoolState() under the hood
   *      before making further calculations and payouts
   * @dev When timing conditions are not met (executed too frequently, or after factory
   *      end block), function doesn't throw and exits silently
   *
   */
  function processRewards() external virtual override {
    // delegate call to an internal function
    _processRewards(msg.sender, true);
  }

  /**
   * @notice Calculates current yield rewards value available for address specified
   *
   * @param _staker an address to calculate yield rewards value for
   * @return calculated yield reward value for the given address
   */
  function calcPendingYieldRewards(address _staker) external view override returns (uint256) {
    // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
    uint256 newYieldRewardsPerWeight;

    // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
    // is outdated and we need to recalculate it in order to calculate pending rewards correctly
    if (currentBlockNumber() > lastYieldDistribution && usersLockingWeight != 0) {
      uint256 multiplier = currentBlockNumber() > endBlock
        ? endBlock - lastYieldDistribution
        : currentBlockNumber() - lastYieldDistribution;
      uint256 tPLMSRewards = (multiplier * tPLMSPerBlock);

      // recalculated value for `yieldRewardsPerWeight`
      newYieldRewardsPerWeight = rewardToWeight(tPLMSRewards, usersLockingWeight) + yieldRewardsPerWeight;
    } else {
      // if smart contract state is up to date, we don't recalculate
      newYieldRewardsPerWeight = yieldRewardsPerWeight;
    }

    // based on the rewards per weight value, calculate pending rewards;
    UserData memory user = usersData[_staker];
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
    return usersData[_user].tokenAmount;
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
    return usersData[_user].deposits[_depositId];
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
    return usersData[_user].deposits.length;
  }

  /**
   * @dev Similar to public pendingYieldRewards, but performs calculations based on
   *      current smart contract state only, not taking into account any additional
   *      time/blocks which might have passed
   *
   * @param _staker an address to calculate yield rewards value for
   * @return pending calculated yield reward value for the given address
   */
  function _calcPendingYieldRewards(address _staker) internal view returns (uint256 pending) {
    // read user data structure into memory
    UserData memory user = usersData[_staker];

    // and perform the calculation using the values read
    return weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
  }

  /**
   * @dev Used internally, mostly by children implementations, see stakeToPool()
   *
   * @param _amount amount of tokens to stake
   * @param _lockUntil stake period as unix timestamp; zero means no locking
   * @param _isYield a flag indicating if that stake is created to store yield reward
   *      from the previously unstaked stake
   */
  function _stakeToPool(
    address account,
    uint256 _amount,
    uint64 _lockUntil,
    bool _isYield,
    bool _isPLMS
  ) internal virtual {
    // validate the inputs
    require(_amount > 0, 'zero amount');
    require(
      _lockUntil == 0 ||
        (_lockUntil > currentTS() && _lockUntil - currentTS() <= 360 days) ||
        _lockUntil == PERMANENT_LOCK_TIME,
      'invalid lock interval'
    );

    // update smart contract state
    _syncPoolState();

    // get a link to user data struct, we will write to it later
    UserData storage user = usersData[account];
    // process current pending rewards if any
    if (user.tokenAmount > 0) {
      _processRewards(account, false);
    }

    // set the `lockFrom` and `lockUntil` taking into account that
    // zero value for `_lockUntil` means "no locking" and leads to zero values
    // for both `lockFrom` and `lockUntil`
    uint64 lockFrom = _lockUntil > 0 ? uint64(currentTS()) : 0;
    uint64 lockUntil = _lockUntil;

    uint256 stakeWeight;
    if (lockUntil == PERMANENT_LOCK_TIME) {
      stakeWeight = PERMANENT_LOCK_WEIGHT_MULTIPLIER * WEIGHT_MULTIPLIER * _amount;
    } else {
      // stake weight formula rewards for locking
      stakeWeight = (((lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / 360 days + WEIGHT_MULTIPLIER) * _amount;
    }

    // makes sure stakeWeight is valid
    assert(stakeWeight > 0);

    // create and save the deposit (append it to deposits array)
    Deposit memory deposit = Deposit({
      tokenAmount: _amount,
      weight: stakeWeight,
      lockedFrom: lockFrom,
      lockedUntil: lockUntil,
      isYield: _isYield,
      isPLMS: _isPLMS
    });
    // deposit ID is an index of the deposit in `deposits` array
    user.deposits.push(deposit);

    // update user record
    user.tokenAmount += _amount;
    user.totalWeight += stakeWeight;
    user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

    // update global variable
    usersLockingWeight += stakeWeight;

    // emit an event
    emit Staked(account, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see unstakeFromPool()
   *
   * @param _depositId deposit ID to unstake from, zero-indexed
   * @param _amount amount of tokens to unstake
   * @param _isPLMS unstake PLMS token
   */
  function _unstakeFromPool(
    uint256 _depositId,
    uint256 _amount,
    bool _isPLMS
  ) internal virtual {
    // verify an amount is set
    require(_amount > 0, 'zero amount');

    // get a link to user data struct, we will write to it later
    UserData storage user = usersData[msg.sender];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];
    // deposit structure may get deleted, so we save isYield flag to be able to use it
    bool isYield = stakeDeposit.isYield;

    // verify available balance
    // if staker address ot deposit doesn't exist this check will fail as well
    require(stakeDeposit.tokenAmount >= _amount, 'amount exceeds stake');
    require(stakeDeposit.isPLMS == _isPLMS, 'not PLMS');

    // update smart contract state
    _syncPoolState();
    // and process current pending rewards if any
    _processRewards(msg.sender, false);

    // recalculate deposit weight
    uint256 previousWeight = stakeDeposit.weight;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
      360 days +
      WEIGHT_MULTIPLIER) * (stakeDeposit.tokenAmount - _amount);

    // update the deposit, or delete it if its depleted
    if (stakeDeposit.tokenAmount - _amount == 0) {
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

    // if the deposit was created by the pool itself as a yield reward
    if (isYield) {
      totalYieldRewardClaimed += _amount;
      require(totalTokensForYieldReward >= totalYieldRewardClaimed, 'not enough for yield reward');
    }

    if (_isPLMS) {
      // users should get PLMS
      IERC20Upgradeable(PLMS).safeTransfer(msg.sender, _amount);
    } else {
      transferStakingToken(msg.sender, _amount);
    }

    // emit an event
    emit Unstaked(msg.sender, _amount);
  }

  /**
   * @dev Used internally, mostly by children implementations, see syncPoolState()
   *
   * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
   *      updates factory state via `updateEmissionRate`
   */
  function _syncPoolState() internal virtual {
    if (timeToUpdateRatio()) {
      updateEmissionRate();
    }

    // check bound conditions and if these are not met -
    // exit silently, without emitting an event
    if (lastYieldDistribution >= endBlock) {
      return;
    }
    if (currentBlockNumber() <= lastYieldDistribution) {
      return;
    }
    // if locking weight is zero - update only `lastYieldDistribution` and exit
    if (usersLockingWeight == 0) {
      lastYieldDistribution = uint64(currentBlockNumber());
      return;
    }

    // to calculate the reward we need to know how many blocks passed, and reward per block
    uint256 currentBlock = currentBlockNumber() > endBlock ? endBlock : currentBlockNumber();
    uint256 blocksPassed = currentBlock - lastYieldDistribution;

    // calculate the reward
    uint256 tPLMSReward = blocksPassed * tPLMSPerBlock;

    // update rewards per weight and `lastYieldDistribution`
    yieldRewardsPerWeight += rewardToWeight(tPLMSReward, usersLockingWeight);
    lastYieldDistribution = uint64(currentBlock);

    // emit an event
    emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
  }

  /**
   * @dev Used internally, mostly by children implementations, see processRewards()
   *
   * @param _staker an address which receives the reward (which has staked some tokens earlier)
   * @param _withUpdate flag allowing to disable synchronization (see syncPoolState()) if set to false
   * @return pendingYield the rewards calculated and re-staked
   */
  function _processRewards(address _staker, bool _withUpdate) internal virtual returns (uint256 pendingYield) {
    // update smart contract state if required
    if (_withUpdate) {
      _syncPoolState();
    }

    // calculate pending yield rewards, this value will be returned
    pendingYield = _calcPendingYieldRewards(_staker);

    // if pending yield is zero - just return silently
    if (pendingYield == 0) return 0;

    // get link to a user data structure, we will write into it later
    UserData storage user = usersData[_staker];

    {
      // calculate pending yield weight,
      // 2e6 is the bonus weight when staking for 1 year
      uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

      // if the pool is tPLMS Pool - create new tPLMS deposit
      // and save it - push it into deposits array
      Deposit memory newDeposit = Deposit({
        tokenAmount: pendingYield,
        lockedFrom: uint64(currentTS()),
        lockedUntil: uint64(currentTS() + 360 days), // staking yield for 1 year
        weight: depositWeight,
        isYield: true,
        isPLMS: false
      });
      user.deposits.push(newDeposit);

      // update user record
      user.tokenAmount += pendingYield;
      user.totalWeight += depositWeight;

      // update global variable
      usersLockingWeight += depositWeight;
    }

    // update usersData's record for `subYieldRewards` if requested
    if (_withUpdate) {
      user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
    }

    // emit an event
    emit YieldClaimed(msg.sender, _staker, pendingYield);
  }

  /**
   * @dev See extendLockTime()
   *
   * @param _staker an address to update stake lock
   * @param _depositId updated deposit ID
   * @param _lockedUntil updated deposit locked until value
   */
  function _extendLockTime(
    address _staker,
    uint256 _depositId,
    uint64 _lockedUntil
  ) internal {
    // validate the input time
    require(_lockedUntil > currentTS(), 'lock should be in the future');

    // get a link to user data struct, we will write to it later
    UserData storage user = usersData[_staker];
    // get a link to the corresponding deposit, we may write to it later
    Deposit storage stakeDeposit = user.deposits[_depositId];

    // validate the input against deposit structure
    require(_lockedUntil > stakeDeposit.lockedUntil, 'invalid new lock');

    // verify locked from and locked until values
    if (stakeDeposit.lockedFrom == 0) {
      require(_lockedUntil - currentTS() <= 360 days, 'max lock period is 360 days');
      stakeDeposit.lockedFrom = uint64(currentTS());
    } else {
      require(_lockedUntil - stakeDeposit.lockedFrom <= 360 days, 'max lock period is 360 days');
    }

    // update locked until value, calculate new weight
    stakeDeposit.lockedUntil = _lockedUntil;
    uint256 newWeight = (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
      360 days +
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
   *      tPLMS reward value, applying the 10^12 division on weight
   *
   * @param _weight stake weight
   * @param rewardPerWeight tPLMS reward per weight
   * @return reward value normalized to 10^12
   */
  function weightToReward(uint256 _weight, uint256 rewardPerWeight) public pure returns (uint256) {
    // apply the formula and return
    return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
  }

  /**
   * @dev Converts reward tPLMS value to stake weight (not to be mixed with the pool weight),
   *      applying the 10^12 multiplication on the reward
   *      - OR -
   * @dev Converts reward tPLMS value to reward/weight if stake weight is supplied as second
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
   * @dev Testing time-dependent functionality is difficult and the best way of
   *      doing it is to override block number in helper test smart contracts
   *
   * @return `block.number` in mainnet, custom values in testnets (if overridden)
   */
  function currentBlockNumber() public view virtual returns (uint256) {
    // return current block number
    return block.number;
  }

  /**
   * @dev Testing time-dependent functionality is difficult and the best way of
   *      doing it is to override time in helper test smart contracts
   *
   * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
   */
  function currentTS() public view virtual returns (uint256) {
    // return current block timestamp
    return block.timestamp;
  }

  /**
   * @dev Executes IERC20Upgradeable.safeTransfer on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferStakingToken(address _to, uint256 _value) internal nonReentrant {
    // just delegate call to the target
    IERC20Upgradeable(stakingToken).safeTransfer(_to, _value);
  }

  /**
   * @dev Executes IERC20Upgradeable.safeTransferFrom on a pool token
   *
   * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
   */
  function transferStakingTokenFrom(
    address _from,
    address _to,
    uint256 _value
  ) internal nonReentrant {
    // just delegate call to the target
    IERC20Upgradeable(stakingToken).safeTransferFrom(_from, _to, _value);
  }

  function stakePlmsForTPlms(uint256 _amount) internal {
    IERC20Upgradeable(PLMS).safeTransferFrom(msg.sender, address(this), _amount);
    IERC20Upgradeable(PLMS).safeApprove(address(tPLMS), _amount);
    IPool(tPLMS).deposit(_amount);
  }

  /**
   * @notice Decreases tPLMS/block reward by 1%, can be executed
   *      no more than once per `blocksPerUpdate` blocks
   */
  function updateEmissionRate() internal {
    // checks if ratio can be updated i.e. if blocks/update (45626 blocks) have passed
    require(timeToUpdateRatio(), 'too frequent');

    // decreases tPLMS/block reward by 1%
    tPLMSPerBlock = (tPLMSPerBlock * 99) / 100;

    // set `the last ratio update block` = `the last ratio update block` + `blocksPerUpdate`
    lastRatioUpdate += blocksPerUpdate;

    // emit an event
    emit PlmsRationUpdated(msg.sender, tPLMSPerBlock);
  }

  /**
   * @dev Verifies if `blocksPerUpdate` has passed since last tPLMS/block
   *      ratio update and if tPLMS/block reward can be decreased by 1%
   *
   * @return true if enough time has passed and `updateEmissionRate` can be executed
   */
  function timeToUpdateRatio() internal view returns (bool) {
    // if yield farming period has ended
    if (currentBlockNumber() > endBlock) {
      // tPLMS/block reward cannot be updated anymore
      return false;
    }

    // check if blocks/update (45626 blocks) have passed since last update
    return currentBlockNumber() >= lastRatioUpdate + blocksPerUpdate;
  }

  /**
   * @dev authorized users can deposit swap PLMS for tPLMS
   */
  function depositPLMS(uint256 _amount) external {
    require(plmsDepositWhitelist[msg.sender], 'auth error');
    totalPlmsSwapAmount += _amount;
    require(totalPlmsSwapAmount <= totalPlmsStakingAmount, 'too much');
    IERC20Upgradeable(PLMS).safeTransferFrom(msg.sender, address(this), _amount);
    IERC20Upgradeable(tPLMS).safeTransfer(msg.sender, _amount);
    emit PlmsDeposited(msg.sender, _amount);
  }

  function setPlmsDepositWhitelist(address[] memory addrs, bool value) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) {
      plmsDepositWhitelist[addrs[i]] = value;
    }
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
    address _PLMS,
    address _stakingToken,
    uint64 _stakingStartBlock,
    uint192 _plmsPerBlock,
    uint32 _blocksPerUpdate,
    uint32 _ratioStartBlock,
    uint32 _endBlock
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
    // @dev indicates if the stake was created for staking PLMS
    bool isPLMS;
  }

  function stakingToken() external view returns (address);

  function lastYieldDistribution() external view returns (uint64);

  function yieldRewardsPerWeight() external view returns (uint256);

  function usersLockingWeight() external view returns (uint256);

  function calcPendingYieldRewards(address _user) external view returns (uint256);

  function balanceOf(address _user) external view returns (uint256);

  function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

  function getDepositsLength(address _user) external view returns (uint256);

  function stakeToPool(uint256 _amount, uint64 _lockedUntil) external;

  function stakeToPoolFor(
    address account,
    uint256 _amount,
    uint64 _lockUntil
  ) external;

  // unstake tPLMS
  function unstakeFromPool(uint256 _depositId, uint256 _amount) external;

  // unstake PLMS
  function unstakePlmsFromPool(uint256 _depositId, uint256 _amount) external;

  function syncPoolState() external;

  function processRewards() external;
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

import './IPoolBase.sol';

interface IPolemosCorePool is IPoolBase {
  function poolTokenReserve() external view returns (uint256);

  function poolSelfStake(address _staker, uint256 _amount) external;

  function addTokenForVaultReward(uint256 _rewardsAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {
  function underlyer() external returns (address);

  function deposit(uint256 amount) external;

  function depositFor(address account, uint256 amount) external;

  function withdraw(uint256 requestedAmount) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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