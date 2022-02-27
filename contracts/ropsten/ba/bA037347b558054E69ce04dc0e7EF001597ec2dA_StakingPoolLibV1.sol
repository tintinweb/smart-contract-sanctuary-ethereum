// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";
import "./ProtoUtilV1.sol";
import "./NTransferUtilV2.sol";
import "./ValidationLibV1.sol";
import "./StakingPoolCoreLibV1.sol";

library StakingPoolLibV1 {
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using RegistryLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using StakingPoolCoreLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Gets the info of a given staking pool by key
   * @param s Specify the store instance
   * @param key Provide the staking pool key to fetch info for
   * @param you Specify the address to customize the info for
   * @param name Returns the name of the staking pool
   * @param addresses[0] stakingToken --> Returns the address of the token which is staked in this pool
   * @param addresses[1] stakingTokenStablecoinPair --> Returns the pair address of the staking token and stablecoin
   * @param addresses[2] rewardToken --> Returns the address of the token which is rewarded in this pool
   * @param addresses[3] rewardTokenStablecoinPair --> Returns the pair address of the reward token and stablecoin
   * @param values[0] totalStaked --> Returns the total units of staked tokens
   * @param values[1] target --> Returns the target amount to stake (as staking token unit)
   * @param values[2] maximumStake --> Returns the maximum amount of staking token units that can be added at a time
   * @param values[3] stakeBalance --> Returns the amount of staking token currently locked in the pool
   * @param values[4] cumulativeDeposits --> Returns the total amount tokens which were deposited in this pool
   * @param values[5] rewardPerBlock --> Returns the unit of reward tokens awarded on each block for each unit of staking token
   * @param values[6] platformFee --> Returns the % rate (multipled by ProtoUtilV1.MULTIPLIER) charged by protocol on rewards
   * @param values[7] lockupPeriod --> Returns the period until when a stake can't be withdrawn
   * @param values[8] rewardTokenBalance --> Returns the balance of the reward tokens still left in the pool
   * @param values[9] accountStakeBalance --> Returns your stake amount
   * @param values[10] totalBlockSinceLastReward --> Returns the number of blocks since your last reward
   * @param values[11] rewards --> The amount of reward tokens you have accumulated till this block
   * @param values[12] canWithdrawFromBlockHeight --> The block height after which you are allowed to withdraw your stake
   * @param values[13] lastDepositHeight --> Returns the block number of your last deposit
   * @param values[14] lastRewardHeight --> Returns the block number of your last reward
   */
  function getInfoInternal(
    IStore s,
    bytes32 key,
    address you
  )
    external
    view
    returns (
      string memory name,
      address[] memory addresses,
      uint256[] memory values
    )
  {
    addresses = new address[](4);
    values = new uint256[](15);

    name = s.getStringByKeys(StakingPoolCoreLibV1.NS_POOL, key);

    addresses[0] = s.getStakingTokenAddressInternal(key);
    addresses[1] = s.getStakingTokenStablecoinPairAddressInternal(key);
    addresses[2] = s.getRewardTokenAddressInternal(key);
    addresses[3] = s.getRewardTokenStablecoinPairAddressInternal(key);

    values[0] = s.getTotalStaked(key);
    values[1] = s.getTarget(key);
    values[2] = s.getMaximumStakeInternal(key);
    values[3] = getPoolStakeBalanceInternal(s, key);
    values[4] = getPoolCumulativeDeposits(s, key);
    values[5] = s.getRewardPerBlock(key);
    values[6] = s.getRewardPlatformFee(key);
    values[7] = s.getLockupPeriodInBlocks(key);
    values[8] = s.getRewardTokenBalance(key);
    values[9] = getAccountStakingBalanceInternal(s, key, you);
    values[10] = getTotalBlocksSinceLastRewardInternal(s, key, you);
    values[11] = calculateRewardsInternal(s, key, you);
    values[12] = canWithdrawFromBlockHeightInternal(s, key, you);
    values[13] = getLastDepositHeight(s, key, you);
    values[14] = getLastRewardHeight(s, key, you);
  }

  function getPoolStakeBalanceInternal(IStore s, bytes32 key) public view returns (uint256) {
    uint256 totalStake = s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key);
    return totalStake;
  }

  function getPoolCumulativeDeposits(IStore s, bytes32 key) public view returns (uint256) {
    uint256 totalStake = s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_CUMULATIVE_STAKING_AMOUNT, key);
    return totalStake;
  }

  function getAccountStakingBalanceInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    return s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, account);
  }

  function getTotalBlocksSinceLastRewardInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    uint256 from = getLastRewardHeight(s, key, account);

    if (from == 0) {
      return 0;
    }

    return block.number - from;
  }

  function canWithdrawFromBlockHeightInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    uint256 lastDepositHeight = getLastDepositHeight(s, key, account);

    if (lastDepositHeight == 0) {
      return 0;
    }

    uint256 lockupPeriod = s.getLockupPeriodInBlocks(key);

    return lastDepositHeight + lockupPeriod;
  }

  function getLastDepositHeight(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    return s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_DEPOSIT_HEIGHTS, key, account);
  }

  function getLastRewardHeight(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    return s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_HEIGHTS, key, account);
  }

  function getStakingPoolRewardTokenBalance(IStore s, bytes32 key) public view returns (uint256) {
    IERC20 rewardToken = IERC20(s.getAddressByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_TOKEN, key));
    address stakingPool = s.getStakingPoolAddress();

    return rewardToken.balanceOf(stakingPool);
  }

  function calculateRewardsInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    uint256 totalBlocks = getTotalBlocksSinceLastRewardInternal(s, key, account);

    if (totalBlocks == 0) {
      return 0;
    }

    uint256 rewardPerBlock = s.getRewardPerBlock(key);
    uint256 myStake = getAccountStakingBalanceInternal(s, key, account);
    uint256 rewards = (myStake * rewardPerBlock * totalBlocks) / 1 ether;

    uint256 poolBalance = getStakingPoolRewardTokenBalance(s, key);

    return rewards > poolBalance ? poolBalance : rewards;
  }

  function withdrawRewardsInternal(
    IStore s,
    bytes32 key,
    address account
  )
    public
    returns (
      address rewardToken,
      uint256 rewards,
      uint256 platformFee
    )
  {
    rewards = calculateRewardsInternal(s, key, account);

    s.setUintByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_HEIGHTS, key, account, block.number);

    if (rewards == 0) {
      return (address(0), 0, 0);
    }

    rewardToken = s.getAddressByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_TOKEN, key);

    // Update (decrease) the balance of reward token
    s.subtractUintByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_TOKEN_BALANCE, key, rewards);

    // Update total rewards given
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_TOTAL_REWARD_GIVEN, key, account, rewards); // To this account
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_TOTAL_REWARD_GIVEN, key, rewards); // To everyone

    platformFee = (rewards * s.getRewardPlatformFee(key)) / ProtoUtilV1.MULTIPLIER;

    IERC20(rewardToken).ensureTransfer(msg.sender, rewards - platformFee);
    IERC20(rewardToken).ensureTransfer(s.getTreasury(), platformFee);
  }

  function depositInternal(
    IStore s,
    bytes32 key,
    uint256 amount
  ) external returns (address stakingToken) {
    require(key > 0, "Invalid key");
    require(amount > 0, "Enter an amount");
    require(amount <= s.getMaximumStakeInternal(key), "Stake too high");
    require(amount <= s.getAvailableToStakeInternal(key), "Target achieved or cap exceeded");

    stakingToken = s.getStakingTokenAddressInternal(key);

    // First withdraw your rewards
    withdrawRewardsInternal(s, key, msg.sender);

    // Individual state
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, msg.sender, amount);
    s.setUintByKeys(StakingPoolCoreLibV1.NS_POOL_DEPOSIT_HEIGHTS, key, msg.sender, block.number);

    // Global state
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, amount);
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_CUMULATIVE_STAKING_AMOUNT, key, amount);

    IERC20(stakingToken).ensureTransferFrom(msg.sender, address(this), amount);
  }

  function withdrawInternal(
    IStore s,
    bytes32 key,
    uint256 amount
  ) external returns (address stakingToken) {
    require(key > 0, "Invalid key");
    require(amount > 0, "Enter an amount");

    require(getAccountStakingBalanceInternal(s, key, msg.sender) >= amount, "Insufficient balance");
    require(block.number > canWithdrawFromBlockHeightInternal(s, key, msg.sender), "Withdrawal too early");

    stakingToken = s.getStakingTokenAddressInternal(key);

    // First withdraw your rewards
    withdrawRewardsInternal(s, key, msg.sender);

    // Individual state
    s.subtractUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, msg.sender, amount);

    // Global state
    s.subtractUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, amount);

    IERC20(stakingToken).ensureTransfer(msg.sender, amount);
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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
// solhint-disable func-order
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";

library StoreKeyUtil {
  function setUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.setUint(key, value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2, account), value);
  }

  function addUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.addUint(key, value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.addUint(_getKey(key1, key2), value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.addUint(_getKey(key1, key2, account), value);
  }

  function subtractUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.subtractUint(key, value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.subtractUint(_getKey(key1, key2), value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.subtractUint(_getKey(key1, key2, account), value);
  }

  function setStringByKey(
    IStore s,
    bytes32 key,
    string memory value
  ) external {
    require(key > 0, "Invalid key");
    s.setString(key, value);
  }

  function setStringByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    string memory value
  ) external {
    return s.setString(_getKey(key1, key2), value);
  }

  function setBytes32ByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    s.setBytes32(key, value);
  }

  function setBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    return s.setBytes32(_getKey(key1, key2), value);
  }

  function setBoolByKey(
    IStore s,
    bytes32 key,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setBool(key, value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bool value
  ) external {
    return s.setBool(_getKey(key1, key2), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    return s.setBool(_getKey(key, account), value);
  }

  function setAddressByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddress(key, value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.setAddress(_getKey(key1, key2), value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.setAddress(_getKey(key1, key2, key3), value);
  }

  function setAddressArrayByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddressArrayItem(key, value);
  }

  function setAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.setAddressArrayItem(_getKey(key1, key2), value);
  }

  function setAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.setAddressArrayItem(_getKey(key1, key2, key3), value);
  }

  function setAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddressBoolean(key, account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    bool value
  ) external {
    return s.setAddressBoolean(_getKey(key1, key2), account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account,
    bool value
  ) external {
    return s.setAddressBoolean(_getKey(key1, key2, key3), account, value);
  }

  function deleteUintByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteUint(key);
  }

  function deleteUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteUint(_getKey(key1, key2));
  }

  function deleteBytes32ByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    s.deleteBytes32(key);
  }

  function deleteBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteBytes32(_getKey(key1, key2));
  }

  function deleteBoolByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteBool(key);
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteBool(_getKey(key1, key2));
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external {
    return s.deleteBool(_getKey(key, account));
  }

  function deleteAddressByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteAddress(key);
  }

  function deleteAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteAddress(_getKey(key1, key2));
  }

  function deleteAddressArrayByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteAddressArrayItem(key, value);
  }

  function deleteAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.deleteAddressArrayItem(_getKey(key1, key2), value);
  }

  function deleteAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.deleteAddressArrayItem(_getKey(key1, key2, key3), value);
  }

  function deleteAddressArrayByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteAddressArrayItemByIndex(key, index);
  }

  function deleteAddressArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external {
    return s.deleteAddressArrayItemByIndex(_getKey(key1, key2), index);
  }

  function deleteAddressArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external {
    return s.deleteAddressArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function getUintByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getUint(key);
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2, account));
  }

  function getStringByKey(IStore s, bytes32 key) external view returns (string memory) {
    require(key > 0, "Invalid key");
    return s.getString(key);
  }

  function getStringByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (string memory) {
    return s.getString(_getKey(key1, key2));
  }

  function getBytes32ByKey(IStore s, bytes32 key) external view returns (bytes32) {
    require(key > 0, "Invalid key");
    return s.getBytes32(key);
  }

  function getBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bytes32) {
    return s.getBytes32(_getKey(key1, key2));
  }

  function getBoolByKey(IStore s, bytes32 key) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getBool(key);
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bool) {
    return s.getBool(_getKey(key1, key2));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    return s.getBool(_getKey(key, account));
  }

  function getAddressByKey(IStore s, bytes32 key) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddress(key);
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address) {
    return s.getAddress(_getKey(key1, key2));
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address) {
    return s.getAddress(_getKey(key1, key2, key3));
  }

  function getAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getAddressBoolean(key, account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (bool) {
    return s.getAddressBoolean(_getKey(key1, key2), account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account
  ) external view returns (bool) {
    return s.getAddressBoolean(_getKey(key1, key2, key3), account);
  }

  function countAddressArrayByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.countAddressArrayItems(key);
  }

  function countAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.countAddressArrayItems(_getKey(key1, key2));
  }

  function countAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.countAddressArrayItems(_getKey(key1, key2, key3));
  }

  function getAddressArrayByKey(IStore s, bytes32 key) external view returns (address[] memory) {
    require(key > 0, "Invalid key");
    return s.getAddressArray(key);
  }

  function getAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address[] memory) {
    return s.getAddressArray(_getKey(key1, key2));
  }

  function getAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address[] memory) {
    return s.getAddressArray(_getKey(key1, key2, key3));
  }

  function getAddressArrayItemPositionByKey(
    IStore s,
    bytes32 key,
    address addressToFind
  ) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getAddressArrayItemPosition(key, addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPosition(_getKey(key1, key2), addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPosition(_getKey(key1, key2, key3), addressToFind);
  }

  function getAddressArrayItemByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddressArrayItemByIndex(key, index);
  }

  function getAddressArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndex(_getKey(key1, key2), index);
  }

  function getAddressArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function _getKey(bytes32 key1, bytes32 key2) private pure returns (bytes32) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return keccak256(abi.encodePacked(key1, key2));
  }

  function _getKey(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) private pure returns (bytes32) {
    require(key1 > 0 && key2 > 0 && key3 > 0, "Invalid key(s)");
    return keccak256(abi.encodePacked(key1, key2, key3));
  }

  function _getKey(bytes32 key, address account) private pure returns (bytes32) {
    require(key > 0 && account != address(0), "Invalid key(s)");
    return keccak256(abi.encodePacked(key, account));
  }

  function _getKey(
    bytes32 key1,
    bytes32 key2,
    address account
  ) private pure returns (bytes32) {
    require(key1 > 0 && key2 > 0 && account != address(0), "Invalid key(s)");
    return keccak256(abi.encodePacked(key1, key2, account));
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";
import "../interfaces/IProtocol.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";

library ProtoUtilV1 {
  using StoreKeyUtil for IStore;

  uint256 public constant MULTIPLIER = 10_000;

  /// @dev Protocol contract namespace
  bytes32 public constant CNS_CORE = "cns:core";

  /// @dev The address of NPM token available in this blockchain
  bytes32 public constant CNS_NPM = "cns:core:npm:instance";

  /// @dev Key prefix for creating a new cover product on chain
  bytes32 public constant CNS_COVER = "cns:cover";

  bytes32 public constant CNS_UNISWAP_V2_ROUTER = "cns:core:uni:v2:router";
  bytes32 public constant CNS_UNISWAP_V2_FACTORY = "cns:core:uni:v2:factory";
  bytes32 public constant CNS_REASSURANCE_VAULT = "cns:core:reassurance:vault";
  bytes32 public constant CNS_PRICE_DISCOVERY = "cns:core:price:discovery";
  bytes32 public constant CNS_TREASURY = "cns:core:treasury";
  bytes32 public constant CNS_COVER_REASSURANCE = "cns:cover:reassurance";
  bytes32 public constant CNS_POOL_BOND = "cns:pool:bond";
  bytes32 public constant CNS_COVER_POLICY = "cns:cover:policy";
  bytes32 public constant CNS_COVER_POLICY_MANAGER = "cns:cover:policy:manager";
  bytes32 public constant CNS_COVER_POLICY_ADMIN = "cns:cover:policy:admin";
  bytes32 public constant CNS_COVER_STAKE = "cns:cover:stake";
  bytes32 public constant CNS_COVER_VAULT = "cns:cover:vault";
  bytes32 public constant CNS_COVER_STABLECOIN = "cns:cover:sc";
  bytes32 public constant CNS_COVER_CXTOKEN_FACTORY = "cns:cover:cxtoken:factory";
  bytes32 public constant CNS_COVER_VAULT_FACTORY = "cns:cover:vault:factory";
  bytes32 public constant CNS_BOND_POOL = "cns:pools:bond";
  bytes32 public constant CNS_STAKING_POOL = "cns:pools:staking";
  bytes32 public constant CNS_LIQUIDITY_ENGINE = "cns:liquidity:engine";
  bytes32 public constant CNS_STRATEGY_AAVE = "cns:strategy:aave";
  bytes32 public constant CNS_STRATEGY_COMPOUND = "cns:strategy:compound";

  /// @dev Governance contract address
  bytes32 public constant CNS_GOVERNANCE = "cns:gov";

  /// @dev Governance:Resolution contract address
  bytes32 public constant CNS_GOVERNANCE_RESOLUTION = "cns:gov:resolution";

  /// @dev Claims processor contract address
  bytes32 public constant CNS_CLAIM_PROCESSOR = "cns:claim:processor";

  /// @dev The address where `burn tokens` are sent or collected.
  /// The collection behavior (collection) is required if the protocol
  /// is deployed on a sidechain or a layer-2 blockchain.
  /// &nbsp;\n
  /// The collected NPM tokens are will be periodically bridged back to Ethereum
  /// and then burned.
  bytes32 public constant CNS_BURNER = "cns:core:burner";

  /// @dev Namespace for all protocol members.
  bytes32 public constant NS_MEMBERS = "ns:members";

  /// @dev Namespace for protocol contract members.
  bytes32 public constant NS_CONTRACTS = "ns:contracts";

  /// @dev Key prefix for creating a new cover product on chain
  bytes32 public constant NS_COVER = "ns:cover";

  bytes32 public constant NS_COVER_CREATION_FEE = "ns:cover:creation:fee";
  bytes32 public constant NS_COVER_CREATION_MIN_STAKE = "ns:cover:creation:min:stake";
  bytes32 public constant NS_COVER_REASSURANCE = "ns:cover:reassurance";
  bytes32 public constant NS_COVER_REASSURANCE_TOKEN = "ns:cover:reassurance:token";
  bytes32 public constant NS_COVER_REASSURANCE_WEIGHT = "ns:cover:reassurance:weight";
  bytes32 public constant NS_COVER_FEE_EARNING = "ns:cover:fee:earning";
  bytes32 public constant NS_COVER_INFO = "ns:cover:info";
  bytes32 public constant NS_COVER_OWNER = "ns:cover:owner";

  bytes32 public constant NS_VAULT_STRATEGY_OUT = "ns:vault:strategy:out";
  bytes32 public constant NS_COVER_LIQUIDITY = "ns:cover:liquidity";
  bytes32 public constant NS_COVER_LIQUIDITY_LENDING_PERIOD = "ns:cover:liquidity:len:p";
  bytes32 public constant NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW = "ns:cover:liquidity:ww";
  bytes32 public constant NS_COVER_LIQUIDITY_MIN_STAKE = "ns:cover:liquidity:min:stake";
  bytes32 public constant NS_COVER_LIQUIDITY_STAKE = "ns:cover:liquidity:stake";
  bytes32 public constant NS_COVER_LIQUIDITY_ADDED = "ns:cover:liquidity:add";
  bytes32 public constant NS_COVER_LIQUIDITY_REMOVED = "ns:cover:liquidity:rem";
  bytes32 public constant NS_COVER_LIQUIDITY_COMMITTED = "ns:cover:liquidity:committed";
  bytes32 public constant NS_COVER_LIQUIDITY_NAME = "ns:cover:liquidityName";
  bytes32 public constant NS_COVER_LIQUIDITY_RELEASE_DATE = "ns:cover:liquidity:release";
  bytes32 public constant NS_COVER_STABLECOIN_LENT_TOTAL = "ns:cover:sc:total:lent";

  bytes32 public constant NS_COVER_HAS_FLASH_LOAN = "ns:cover:has:fl";
  bytes32 public constant NS_COVER_LIQUIDITY_FLASH_LOAN_FEE = "ns:cover:liquidity:fl:fee";
  bytes32 public constant NS_COVER_LIQUIDITY_FLASH_LOAN_FEE_PROTOCOL = "ns:proto:cover:liquidity:fl:fee";

  bytes32 public constant NS_COVER_POLICY_RATE_FLOOR = "ns:cover:policy:rate:floor";
  bytes32 public constant NS_COVER_POLICY_RATE_CEILING = "ns:cover:policy:rate:ceiling";
  bytes32 public constant NS_COVER_PROVISION = "ns:cover:provision";

  bytes32 public constant NS_COVER_STAKE = "ns:cover:stake";
  bytes32 public constant NS_COVER_STAKE_OWNED = "ns:cover:stake:owned";
  bytes32 public constant NS_COVER_STATUS = "ns:cover:status";
  bytes32 public constant NS_COVER_CXTOKEN = "ns:cover:cxtoken";
  bytes32 public constant NS_COVER_WHITELIST = "ns:cover:whitelist";

  /// @dev Resolution timestamp = timestamp of first reporting + reporting period
  bytes32 public constant NS_GOVERNANCE_RESOLUTION_TS = "ns:gov:resolution:ts";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_GOVERNANCE_UNSTAKEN = "ns:gov:unstaken";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_TS = "ns:gov:unstake:ts";

  /// @dev The reward received by the winning camp
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_REWARD = "ns:gov:unstake:reward";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_BURNED = "ns:gov:unstake:burned";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_REPORTER_FEE = "ns:gov:unstake:rep:fee";

  bytes32 public constant NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE = "ns:gov:rep:min:first:stake";

  /// @dev An approximate date and time when trigger event or cover incident occurred
  bytes32 public constant NS_GOVERNANCE_REPORTING_INCIDENT_DATE = "ns:gov:rep:incident:date";

  /// @dev A period (in solidity timestamp) configurable by cover creators during
  /// when NPM tokenholders can vote on incident reporting proposals
  bytes32 public constant NS_GOVERNANCE_REPORTING_PERIOD = "ns:gov:rep:period";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who saw incident to have happened
  /// 2. For address --> The address of the first reporter
  bytes32 public constant NS_GOVERNANCE_REPORTING_WITNESS_YES = "ns:gov:rep:witness:yes";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who disagreed with and disputed an incident reporting
  /// 2. For address --> The address of the first disputing reporter (disputer / candidate reporter)
  bytes32 public constant NS_GOVERNANCE_REPORTING_WITNESS_NO = "ns:gov:rep:witness:no";

  /// @dev Stakes guaranteed by an individual witness supporting the "incident happened" camp
  bytes32 public constant NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES = "ns:gov:rep:stake:owned:yes";

  /// @dev Stakes guaranteed by an individual witness supporting the "false reporting" camp
  bytes32 public constant NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO = "ns:gov:rep:stake:owned:no";

  /// @dev The percentage rate (x MULTIPLIER) of amount of reporting/unstake reward to burn.
  /// Note that the reward comes from the losing camp after resolution is achieved.
  bytes32 public constant NS_GOVERNANCE_REPORTING_BURN_RATE = "ns:gov:rep:burn:rate";

  /// @dev The percentage rate (x MULTIPLIER) of amount of reporting/unstake
  /// reward to provide to the final reporter.
  bytes32 public constant NS_GOVERNANCE_REPORTER_COMMISSION = "ns:gov:reporter:commission";

  bytes32 public constant NS_CLAIM_PERIOD = "ns:claim:period";

  /// @dev A 24-hour delay after a governance agent "resolves" an actively reported cover.
  bytes32 public constant NS_CLAIM_BEGIN_TS = "ns:claim:begin:ts";

  /// @dev Claim expiry date = Claim begin date + claim duration
  bytes32 public constant NS_CLAIM_EXPIRY_TS = "ns:claim:expiry:ts";

  bytes32 public constant NS_RESOLUTION_DEADLINE = "ns:resolution:deadline";

  /// @dev Claim expiry date = Claim begin date + claim duration
  bytes32 public constant NS_RESOLUTION_COOL_DOWN_PERIOD = "ns:resolution:cdp";

  /// @dev The percentage rate (x MULTIPLIER) of amount deducted by the platform
  /// for each successful claims payout
  bytes32 public constant NS_CLAIM_PLATFORM_FEE = "ns:claim:platform:fee";

  /// @dev The percentage rate (x MULTIPLIER) of amount provided to the first reporter
  /// upon favorable incident resolution. This amount is a commission of the
  /// 'ns:claim:platform:fee'
  bytes32 public constant NS_CLAIM_REPORTER_COMMISSION = "ns:claim:reporter:commission";

  bytes32 public constant NS_LP_RESERVE0 = "ns:uni:lp:reserve0";
  bytes32 public constant NS_LP_RESERVE1 = "ns:uni:lp:reserve1";
  bytes32 public constant NS_LP_TOTAL_SUPPLY = "ns:uni:lp:totalSupply";

  bytes32 public constant NS_TOKEN_PRICE_LAST_UPDATE = "ns:token:price:last:update";
  bytes32 public constant NS_LENDING_STRATEGY_ACTIVE = "ns:lending:strategy:active";
  bytes32 public constant NS_LENDING_STRATEGY_DISABLED = "ns:lending:strategy:disabled";
  bytes32 public constant NS_LENDING_STRATEGY_DEPOSITS = "ns:lending:strategy:deposits";
  bytes32 public constant NS_LENDING_STRATEGY_WITHDRAWAL_START = "ns:lending:strategy:w:start";
  bytes32 public constant NS_LENDING_STRATEGY_WITHDRAWAL_END = "ns:lending:strategy:w:end";

  bytes32 public constant CNAME_PROTOCOL = "Neptune Mutual Protocol";
  bytes32 public constant CNAME_TREASURY = "Treasury";
  bytes32 public constant CNAME_POLICY = "Policy";
  bytes32 public constant CNAME_POLICY_ADMIN = "PolicyAdmin";
  bytes32 public constant CNAME_POLICY_MANAGER = "PolicyManager";
  bytes32 public constant CNAME_BOND_POOL = "BondPool";
  bytes32 public constant CNAME_STAKING_POOL = "StakingPool";
  bytes32 public constant CNAME_POD_STAKING_POOL = "PODStakingPool";
  bytes32 public constant CNAME_CLAIMS_PROCESSOR = "ClaimsProcessor";
  bytes32 public constant CNAME_PRICE_DISCOVERY = "PriceDiscovery";
  bytes32 public constant CNAME_COVER = "Cover";
  bytes32 public constant CNAME_GOVERNANCE = "Governance";
  bytes32 public constant CNAME_RESOLUTION = "Resolution";
  bytes32 public constant CNAME_VAULT_FACTORY = "VaultFactory";
  bytes32 public constant CNAME_CXTOKEN_FACTORY = "cxTokenFactory";
  bytes32 public constant CNAME_COVER_PROVISION = "CoverProvision";
  bytes32 public constant CNAME_COVER_STAKE = "CoverStake";
  bytes32 public constant CNAME_COVER_REASSURANCE = "CoverReassurance";
  bytes32 public constant CNAME_LIQUIDITY_VAULT = "Vault";
  bytes32 public constant CNAME_STRATEGY_AAVE = "AaveStrategy";
  bytes32 public constant CNAME_STRATEGY_COMPOUND = "CompoundStrategy";

  function getProtocol(IStore s) external view returns (IProtocol) {
    return IProtocol(getProtocolAddress(s));
  }

  function getProtocolAddress(IStore s) public view returns (address) {
    return s.getAddressByKey(CNS_CORE);
  }

  function getContract(IStore s, bytes32 name) external view returns (address) {
    return _getContract(s, name);
  }

  function isProtocolMember(IStore s, address contractAddress) external view returns (bool) {
    return _isProtocolMember(s, contractAddress);
  }

  /**
   * @dev Reverts if the caller is one of the protocol members.
   */
  function mustBeProtocolMember(IStore s, address contractAddress) external view {
    bool isMember = _isProtocolMember(s, contractAddress);
    require(isMember, "Not a protocol member");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   * @param sender Enter the `msg.sender` value
   */
  function mustBeExactContract(
    IStore s,
    bytes32 name,
    address sender
  ) public view {
    address contractAddress = _getContract(s, name);
    require(sender == contractAddress, "Access denied");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   */
  function callerMustBeExactContract(IStore s, bytes32 name) external view {
    return mustBeExactContract(s, name, msg.sender);
  }

  function npmToken(IStore s) external view returns (IERC20) {
    return IERC20(getNpmTokenAddress(s));
  }

  function getNpmTokenAddress(IStore s) public view returns (address) {
    address npm = s.getAddressByKey(CNS_NPM);
    return npm;
  }

  function getUniswapV2Router(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_UNISWAP_V2_ROUTER);
  }

  function getUniswapV2Factory(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_UNISWAP_V2_FACTORY);
  }

  function getTreasury(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_TREASURY);
  }

  function getReassuranceVault(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_REASSURANCE_VAULT);
  }

  function getStablecoin(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_COVER_STABLECOIN);
  }

  function getBurnAddress(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_BURNER);
  }

  function _isProtocolMember(IStore s, address contractAddress) private view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, contractAddress);
  }

  function _getContract(IStore s, bytes32 name) private view returns (address) {
    return s.getAddressByKeys(NS_CONTRACTS, name);
  }

  function addContractInternal(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) external {
    // @suppress-address-trust-issue This feature can only be accessed internally within the protocol.
    _addContract(s, namespace, contractAddress);
  }

  function _addContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) private {
    s.setAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, contractAddress);
    _addMember(s, contractAddress);
  }

  // function deleteContractInternal(
  //   IStore s,
  //   bytes32 namespace,
  //   address contractAddress
  // ) external {
  //   // @suppress-address-trust-issue This feature can only be accessed internally within the protocol.
  //   _deleteContract(s, namespace, contractAddress);
  // }

  function _deleteContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) private {
    s.deleteAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace);
    _removeMember(s, contractAddress);
  }

  function upgradeContractInternal(
    IStore s,
    bytes32 namespace,
    address previous,
    address current
  ) external {
    // @suppress-address-trust-issue This feature can only be accessed internally within the protocol.
    bool isMember = _isProtocolMember(s, previous);
    require(isMember, "Not a protocol member");

    _deleteContract(s, namespace, previous);
    _addContract(s, namespace, current);
  }

  function addMemberInternal(IStore s, address member) external {
    // @suppress-address-trust-issue This feature can only be accessed internally within the protocol.
    _addMember(s, member);
  }

  function removeMemberInternal(IStore s, address member) external {
    // @suppress-address-trust-issue This feature can only be accessed internally within the protocol.
    _removeMember(s, member);
  }

  function _addMember(IStore s, address member) private {
    require(s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, member) == false, "Already exists");
    s.setBoolByKeys(ProtoUtilV1.NS_MEMBERS, member, true);
  }

  function _removeMember(IStore s, address member) private {
    s.deleteBoolByKeys(ProtoUtilV1.NS_MEMBERS, member);
  }
}

/* solhint-disable */

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

library NTransferUtilV2 {
  using SafeERC20 for IERC20;

  function ensureApproval(
    IERC20 malicious,
    address spender,
    uint256 amount
  ) external {
    // @suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
    // @suppress-address-trust-issue The address `recipient` can be trusted as we're not treating (or calling) it as a contract.
    require(address(malicious) != address(0), "Invalid address");
    require(spender != address(0), "Invalid spender");
    require(amount > 0, "Invalid transfer amount");

    malicious.safeIncreaseAllowance(spender, amount);
  }

  function ensureTransfer(
    IERC20 malicious,
    address recipient,
    uint256 amount
  ) external {
    // @suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
    // @suppress-address-trust-issue The address `recipient` can be trusted as we're not treating (or calling) it as a contract.
    require(address(malicious) != address(0), "Invalid address");
    require(recipient != address(0), "Invalid recipient");
    require(amount > 0, "Invalid transfer amount");

    uint256 pre = malicious.balanceOf(recipient);
    malicious.safeTransfer(recipient, amount);

    uint256 post = malicious.balanceOf(recipient);

    // slither-disable-next-line incorrect-equality
    require(post - pre == amount, "Invalid transfer");
  }

  function ensureTransferFrom(
    IERC20 malicious,
    address sender,
    address recipient,
    uint256 amount
  ) external {
    // @suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
    // @suppress-address-trust-issue The address `recipient` can be trusted as we're not treating (or calling) it as a contract.
    require(address(malicious) != address(0), "Invalid address");
    require(recipient != address(0), "Invalid recipient");
    require(amount > 0, "Invalid transfer amount");

    uint256 pre = malicious.balanceOf(recipient);
    malicious.safeTransferFrom(sender, recipient, amount);
    uint256 post = malicious.balanceOf(recipient);

    // slither-disable-next-line incorrect-equality
    require(post - pre == amount, "Invalid transfer");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./CoverUtilV1.sol";
import "./GovernanceUtilV1.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/ICxToken.sol";

library ValidationLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using CoverUtilV1 for IStore;
  using GovernanceUtilV1 for IStore;
  using RegistryLibV1 for IStore;

  /*********************************************************************************************
    _______ ______    ________ ______
    |      |     |\  / |______|_____/
    |_____ |_____| \/  |______|    \_
                                  
   *********************************************************************************************/

  /**
   * @dev Reverts if the protocol is paused
   */
  function mustNotBePaused(IStore s) public view {
    address protocol = s.getProtocolAddress();
    require(IPausable(protocol).paused() == false, "Protocol is paused");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract
   * or if the cover is under governance.
   * @param key Enter the cover key to check
   */
  function mustHaveNormalCoverStatus(IStore s, bytes32 key) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, key), "Cover does not exist");
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.Normal, "Status not normal");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract
   * or if the cover is under governance.
   * @param key Enter the cover key to check
   */
  function mustHaveStoppedCoverStatus(IStore s, bytes32 key) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, key), "Cover does not exist");
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.Stopped, "Cover isn't stopped");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract.
   * @param key Enter the cover key to check
   */
  function mustBeValidCoverKey(IStore s, bytes32 key) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, key), "Cover does not exist");
  }

  /**
   * @dev Reverts if the sender is not the cover owner
   * @param key Enter the cover key to check
   * @param sender The `msg.sender` value
   */
  function mustBeCoverOwner(
    IStore s,
    bytes32 key,
    address sender
  ) external view {
    bool isCoverOwner = s.getCoverOwner(key) == sender;
    require(isCoverOwner, "Forbidden");
  }

  /**
   * @dev Reverts if the sender is not the cover owner or the cover contract
   * @param key Enter the cover key to check
   * @param sender The `msg.sender` value
   */
  function mustBeCoverOwnerOrCoverContract(
    IStore s,
    bytes32 key,
    address sender
  ) external view {
    bool isCoverOwner = s.getCoverOwner(key) == sender;
    bool isCoverContract = address(s.getCoverContract()) == sender;

    require(isCoverOwner || isCoverContract, "Forbidden");
  }

  function callerMustBePolicyContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.CNS_COVER_POLICY);
  }

  function callerMustBePolicyManagerContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.CNS_COVER_POLICY_MANAGER);
  }

  function callerMustBeCoverContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.CNS_COVER);
  }

  function callerMustBeVaultContract(IStore s, bytes32 key) external view {
    address vault = s.getVaultAddress(key);
    require(msg.sender == vault, "Forbidden");
  }

  function callerMustBeGovernanceContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.CNS_GOVERNANCE);
  }

  function callerMustBeClaimsProcessorContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.CNS_CLAIM_PROCESSOR);
  }

  function callerMustBeStrategyContract(IStore s) external view {
    bool callerIsStrategyContract = s.getBoolByKey(_getIsActiveStrategyKey(msg.sender));
    require(callerIsStrategyContract == true, "Not a strategy contract");
  }

  function _getIsActiveStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, strategyAddress));
  }

  function callerMustBeProtocolMember(IStore s) external view {
    require(s.isProtocolMember(msg.sender), "Forbidden");
  }

  /*********************************************************************************************
   ______  _____  _    _ _______  ______ __   _ _______ __   _ _______ _______
  |  ____ |     |  \  /  |______ |_____/ | \  | |_____| | \  | |       |______
  |_____| |_____|   \/   |______ |    \_ |  \_| |     | |  \_| |_____  |______

  *********************************************************************************************/

  function mustBeReporting(IStore s, bytes32 key) external view {
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.IncidentHappened, "Not reporting");
  }

  function mustBeDisputed(IStore s, bytes32 key) external view {
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.FalseReporting, "Not disputed");
  }

  function mustBeClaimable(IStore s, bytes32 key) public view {
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.Claimable, "Not claimable");
  }

  function mustBeClaimingOrDisputed(IStore s, bytes32 key) external view {
    CoverUtilV1.CoverStatus status = s.getCoverStatus(key);

    bool claiming = status == CoverUtilV1.CoverStatus.Claimable;
    bool falseReporting = status == CoverUtilV1.CoverStatus.FalseReporting;

    require(claiming || falseReporting, "Not reported nor disputed");
  }

  function mustBeReportingOrDisputed(IStore s, bytes32 key) external view {
    CoverUtilV1.CoverStatus status = s.getCoverStatus(key);
    bool incidentHappened = status == CoverUtilV1.CoverStatus.IncidentHappened;
    bool falseReporting = status == CoverUtilV1.CoverStatus.FalseReporting;

    require(incidentHappened || falseReporting, "Not reported nor disputed");
  }

  function mustBeBeforeResolutionDeadline(IStore s, bytes32 key) external view {
    uint256 deadline = s.getResolutionDeadlineInternal(key);

    if (deadline > 0) {
      require(block.timestamp < deadline, "Emergency resolution deadline over"); // solhint-disable-line
    }
  }

  function mustBeAfterResolutionDeadline(IStore s, bytes32 key) public view {
    uint256 deadline = s.getResolutionDeadlineInternal(key);
    require(block.timestamp > deadline, "Still unresolved"); // solhint-disable-line
  }

  function mustBeValidIncidentDate(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public view {
    require(s.getLatestIncidentDate(key) == incidentDate, "Invalid incident date");
  }

  function mustNotHaveDispute(IStore s, bytes32 key) external view {
    address reporter = s.getAddressByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, key);
    require(reporter == address(0), "Already disputed");
  }

  function mustBeDuringReportingPeriod(IStore s, bytes32 key) external view {
    require(s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, key) >= block.timestamp, "Reporting window closed"); // solhint-disable-line
  }

  function mustBeAfterReportingPeriod(IStore s, bytes32 key) public view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, key), "Reporting still active"); // solhint-disable-line
  }

  function mustBeValidCxToken(
    IStore s,
    bytes32 key,
    address cxToken,
    uint256 incidentDate
  ) public view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER_CXTOKEN, cxToken) == true, "Unknown cxToken");

    bytes32 coverKey = ICxToken(cxToken).coverKey();
    require(coverKey == key, "Invalid cxToken");

    uint256 expires = ICxToken(cxToken).expiresOn();
    require(expires > incidentDate, "Invalid or expired cxToken");
  }

  function mustBeValidClaim(
    IStore s,
    bytes32 key,
    address cxToken,
    uint256 incidentDate
  ) external view {
    s.mustBeProtocolMember(cxToken);
    mustBeValidCxToken(s, key, cxToken, incidentDate);
    mustBeClaimable(s, key);
    mustBeValidIncidentDate(s, key, incidentDate);
    mustBeDuringClaimPeriod(s, key);
  }

  function mustNotHaveUnstaken(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  ) public view {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_TS, key, incidentDate, account));
    uint256 withdrawal = s.getUintByKey(k);

    require(withdrawal == 0, "Already unstaken");
  }

  function validateUnstakeWithoutClaim(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) external view {
    mustNotBePaused(s);
    mustNotHaveUnstaken(s, msg.sender, key, incidentDate);

    // Before the deadline, emergency resolution can still happen
    // that may have an impact on the final decision. We, therefore, have to wait.
    mustBeAfterResolutionDeadline(s, key);

    // @note: when this reporting gets finalized, the emergency resolution deadline resets to 0
    // The above code is not useful after finalization but it helps avoid
    // people calling unstake before a decision is obtained
  }

  function validateUnstakeWithClaim(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) external view {
    mustNotBePaused(s);
    mustNotHaveUnstaken(s, msg.sender, key, incidentDate);

    // If this reporting gets finalized, incident date will become invalid
    // meaning this execution will revert thereby restricting late comers
    // to access this feature. But they can still access `unstake` feature
    // to withdraw their stake.
    mustBeValidIncidentDate(s, key, incidentDate);

    // Before the deadline, emergency resolution can still happen
    // that may have an impact on the final decision. We, therefore, have to wait.
    mustBeAfterResolutionDeadline(s, key);

    bool incidentHappened = s.getCoverStatus(key) == CoverUtilV1.CoverStatus.IncidentHappened;

    if (incidentHappened) {
      // Incident occurred. Must unstake with claim during the claim period.
      mustBeDuringClaimPeriod(s, key);
      return;
    }

    // Incident did not occur.
    mustBeAfterReportingPeriod(s, key);
  }

  function mustBeDuringClaimPeriod(IStore s, bytes32 key) public view {
    uint256 beginsFrom = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_BEGIN_TS, key);
    uint256 expiresAt = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, key);

    require(beginsFrom > 0, "Invalid claim begin date");
    require(expiresAt > beginsFrom, "Invalid claim period");

    require(block.timestamp >= beginsFrom, "Claim period hasn't begun"); // solhint-disable-line
    require(block.timestamp <= expiresAt, "Claim period has expired"); // solhint-disable-line
  }

  function mustBeAfterClaimExpiry(IStore s, bytes32 key) external view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, key), "Claim still active"); // solhint-disable-line
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";
import "./ProtoUtilV1.sol";
import "./NTransferUtilV2.sol";

library StakingPoolCoreLibV1 {
  using StoreKeyUtil for IStore;
  using NTransferUtilV2 for IERC20;

  bytes32 public constant NS_POOL = "ns:pool:staking";
  bytes32 public constant NS_POOL_NAME = "ns:pool:staking:name";
  bytes32 public constant NS_POOL_LOCKED = "ns:pool:staking:locked";
  bytes32 public constant NS_POOL_LOCKUP_PERIOD_IN_BLOCKS = "ns:pool:staking:lockup:period";
  bytes32 public constant NS_POOL_STAKING_TARGET = "ns:pool:staking:target";
  bytes32 public constant NS_POOL_CUMULATIVE_STAKING_AMOUNT = "ns:pool:staking:cum:amount";
  bytes32 public constant NS_POOL_STAKING_TOKEN = "ns:pool:staking:token";
  bytes32 public constant NS_POOL_STAKING_TOKEN_UNI_STABLECOIN_PAIR = "ns:pool:staking:token:uni:pair";
  bytes32 public constant NS_POOL_REWARD_TOKEN = "ns:pool:reward:token";
  bytes32 public constant NS_POOL_REWARD_TOKEN_UNI_STABLECOIN_PAIR = "ns:pool:reward:token:uni:pair";
  bytes32 public constant NS_POOL_STAKING_TOKEN_BALANCE = "ns:pool:staking:token:balance";
  bytes32 public constant NS_POOL_REWARD_TOKEN_DEPOSITS = "ns:pool:reward:token:deposits";
  bytes32 public constant NS_POOL_REWARD_TOKEN_DISTRIBUTION = "ns:pool:reward:token:distrib";
  bytes32 public constant NS_POOL_MAX_STAKE = "ns:pool:reward:token";
  bytes32 public constant NS_POOL_REWARD_PER_BLOCK = "ns:pool:reward:per:block";
  bytes32 public constant NS_POOL_REWARD_PLATFORM_FEE = "ns:pool:reward:platform:fee";
  bytes32 public constant NS_POOL_REWARD_TOKEN_BALANCE = "ns:pool:reward:token:balance";

  bytes32 public constant NS_POOL_DEPOSIT_HEIGHTS = "ns:pool:deposit:heights";
  bytes32 public constant NS_POOL_REWARD_HEIGHTS = "ns:pool:reward:heights";
  bytes32 public constant NS_POOL_TOTAL_REWARD_GIVEN = "ns:pool:reward:total:given";

  /**
   * @dev Reports the remaining amount of tokens that can be staked in this pool
   */
  function getAvailableToStakeInternal(IStore s, bytes32 key) external view returns (uint256) {
    uint256 totalStaked = getTotalStaked(s, key);
    uint256 target = getTarget(s, key);

    if (totalStaked >= target) {
      return 0;
    }

    return target - totalStaked;
  }

  function getTarget(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(NS_POOL_STAKING_TARGET, key);
  }

  function getRewardPlatformFee(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_REWARD_PLATFORM_FEE, key);
  }

  function getTotalStaked(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(NS_POOL_CUMULATIVE_STAKING_AMOUNT, key);
  }

  function getRewardPerBlock(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_REWARD_PER_BLOCK, key);
  }

  function getLockupPeriodInBlocks(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_LOCKUP_PERIOD_IN_BLOCKS, key);
  }

  function getRewardTokenBalance(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_REWARD_TOKEN_BALANCE, key);
  }

  function getMaximumStakeInternal(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_MAX_STAKE, key);
  }

  function getStakingTokenAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_STAKING_TOKEN, key);
  }

  function getStakingTokenStablecoinPairAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_STAKING_TOKEN_UNI_STABLECOIN_PAIR, key);
  }

  function getRewardTokenAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_REWARD_TOKEN, key);
  }

  function getRewardTokenStablecoinPairAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_REWARD_TOKEN_UNI_STABLECOIN_PAIR, key);
  }

  function ensureValidStakingPool(IStore s, bytes32 key) external view {
    require(s.getBoolByKeys(NS_POOL, key), "Pool invalid or closed");
  }

  function validateAddOrEditPoolInternal(
    IStore s,
    bytes32 key,
    string memory name,
    address[] memory addresses,
    uint256[] memory values
  ) public view returns (bool) {
    require(key > 0, "Invalid key");

    bool exists = s.getBoolByKeys(NS_POOL, key);

    if (exists == false) {
      require(bytes(name).length > 0, "Invalid name");
      require(addresses[0] != address(0), "Invalid staking token");
      // require(addresses[1] != address(0), "Invalid staking token pair"); // A POD doesn't have any pair with stablecion
      require(addresses[2] != address(0), "Invalid reward token");
      require(addresses[3] != address(0), "Invalid reward token pair");
      require(values[4] > 0, "Provide lockup period in blocks");
      require(values[5] > 0, "Provide reward token balance");
      require(values[3] > 0, "Provide reward per block");
      require(values[0] > 0, "Please provide staking target");
    }

    return exists;
  }

  /**
   * @dev Adds or edits the pool by key
   * @param key Enter the key of the pool you want to create or edit
   * @param name Enter a name for this pool
   * @param addresses[0] stakingToken The token which is staked in this pool
   * @param addresses[1] uniStakingTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param addresses[2] rewardToken The token which is rewarded in this pool
   * @param addresses[3] uniRewardTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param values[0] stakingTarget Specify the target amount in the staking token. You can not exceed the target.
   * @param values[1] maxStake Specify the maximum amount that can be staken at a time.
   * @param values[2] platformFee Enter the platform fee which is deducted on reward and on the reward token
   * @param values[3] rewardPerBlock Specify the amount of reward token awarded per block
   * @param values[4] lockupPeriodInBlocks Enter a lockup period during when the staked tokens can't be withdrawn
   * @param values[5] rewardTokenDeposit Enter the value of reward token you are depositing in this transaction.
   */
  function addOrEditPoolInternal(
    IStore s,
    bytes32 key,
    string memory name,
    address[] memory addresses,
    uint256[] memory values
  ) external {
    bool poolExists = validateAddOrEditPoolInternal(s, key, name, addresses, values);

    if (poolExists == false) {
      _initializeNewPool(s, key, addresses);
    }

    if (bytes(name).length > 0) {
      s.setStringByKeys(NS_POOL, key, name);
    }

    _updatePoolValues(s, key, values);

    // If `values[5] --> rewardTokenDeposit` is specified, the contract
    // pulls the reward tokens to this contract address
    if (values[5] > 0) {
      IERC20(addresses[2]).ensureTransferFrom(msg.sender, address(this), values[5]);
    }
  }

  /**
   * @dev Updates the values of a staking pool by the given key
   * @param s Provide an instance of the store
   * @param key Enter the key of the pool you want to create or edit
   * @param values[0] stakingTarget Specify the target amount in the staking token. You can not exceed the target.
   * @param values[1] maxStake Specify the maximum amount that can be staken at a time.
   * @param values[2] platformFee Enter the platform fee which is deducted on reward and on the reward token
   * @param values[3] rewardPerBlock Specify the amount of reward token awarded per block
   * @param values[4] lockupPeriodInBlocks Enter a lockup period during when the staked tokens can't be withdrawn
   * @param values[5] rewardTokenDeposit Enter the value of reward token you are depositing in this transaction.
   */
  function _updatePoolValues(
    IStore s,
    bytes32 key,
    uint256[] memory values
  ) private {
    if (values[0] > 0) {
      s.setUintByKeys(NS_POOL_STAKING_TARGET, key, values[0]);
    }

    if (values[1] > 0) {
      s.setUintByKeys(NS_POOL_MAX_STAKE, key, values[1]);
    }

    if (values[2] > 0) {
      s.setUintByKeys(NS_POOL_REWARD_PLATFORM_FEE, key, values[2]);
    }

    if (values[3] > 0) {
      s.setUintByKeys(NS_POOL_REWARD_PER_BLOCK, key, values[3]);
    }

    if (values[4] > 0) {
      s.setUintByKeys(NS_POOL_LOCKUP_PERIOD_IN_BLOCKS, key, values[4]);
    }

    if (values[5] > 0) {
      s.addUintByKeys(NS_POOL_REWARD_TOKEN_DEPOSITS, key, values[5]);
      s.addUintByKeys(NS_POOL_REWARD_TOKEN_BALANCE, key, values[5]);
    }
  }

  /**
   * @dev Initializes a new pool by the given key. Assumes that the pool does not exist.
   * Warning: this feature should not be accessible outside of this library.
   * @param s Provide an instance of the store
   * @param key Enter the key of the pool you want to create or edit
   * @param addresses[0] stakingToken The token which is staked in this pool
   * @param addresses[1] uniStakingTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param addresses[2] rewardToken The token which is rewarded in this pool
   * @param addresses[3] uniRewardTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   */
  function _initializeNewPool(
    IStore s,
    bytes32 key,
    address[] memory addresses
  ) private {
    s.setAddressByKeys(NS_POOL_STAKING_TOKEN, key, addresses[0]);
    s.setAddressByKeys(NS_POOL_STAKING_TOKEN_UNI_STABLECOIN_PAIR, key, addresses[1]);
    s.setAddressByKeys(NS_POOL_REWARD_TOKEN, key, addresses[2]);
    s.setAddressByKeys(NS_POOL_REWARD_TOKEN_UNI_STABLECOIN_PAIR, key, addresses[3]);

    s.setBoolByKeys(NS_POOL, key, true);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IStore {
  function setAddress(bytes32 k, address v) external;

  function setAddressBoolean(
    bytes32 k,
    address a,
    bool v
  ) external;

  function setUint(bytes32 k, uint256 v) external;

  function addUint(bytes32 k, uint256 v) external;

  function subtractUint(bytes32 k, uint256 v) external;

  function setUints(bytes32 k, uint256[] memory v) external;

  function setString(bytes32 k, string calldata v) external;

  function setBytes(bytes32 k, bytes calldata v) external;

  function setBool(bytes32 k, bool v) external;

  function setInt(bytes32 k, int256 v) external;

  function setBytes32(bytes32 k, bytes32 v) external;

  function setAddressArrayItem(bytes32 k, address v) external;

  function deleteAddress(bytes32 k) external;

  function deleteUint(bytes32 k) external;

  function deleteUints(bytes32 k) external;

  function deleteString(bytes32 k) external;

  function deleteBytes(bytes32 k) external;

  function deleteBool(bytes32 k) external;

  function deleteInt(bytes32 k) external;

  function deleteBytes32(bytes32 k) external;

  function deleteAddressArrayItem(bytes32 k, address v) external;

  function deleteAddressArrayItemByIndex(bytes32 k, uint256 i) external;

  function getAddressValues(bytes32[] memory keys) external view returns (address[] memory values);

  function getAddress(bytes32 k) external view returns (address);

  function getAddressBoolean(bytes32 k, address a) external view returns (bool);

  function getUintValues(bytes32[] memory keys) external view returns (uint256[] memory values);

  function getUint(bytes32 k) external view returns (uint256);

  function getUints(bytes32 k) external view returns (uint256[] memory);

  function getString(bytes32 k) external view returns (string memory);

  function getBytes(bytes32 k) external view returns (bytes memory);

  function getBool(bytes32 k) external view returns (bool);

  function getInt(bytes32 k) external view returns (int256);

  function getBytes32(bytes32 k) external view returns (bytes32);

  function countAddressArrayItems(bytes32 k) external view returns (uint256);

  function getAddressArray(bytes32 k) external view returns (address[] memory);

  function getAddressArrayItemPosition(bytes32 k, address toFind) external view returns (uint256);

  function getAddressArrayItemByIndex(bytes32 k, uint256 i) external view returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./IMember.sol";

interface IProtocol is IMember, IAccessControl {
  event ContractAdded(bytes32 namespace, address contractAddress);
  event ContractUpgraded(bytes32 namespace, address indexed previous, address indexed current);
  event MemberAdded(address member);
  event MemberRemoved(address member);

  function addContract(bytes32 namespace, address contractAddress) external;

  function initialize(address[] memory addresses, uint256[] memory values) external;

  function upgradeContract(
    bytes32 namespace,
    address previous,
    address current
  ) external;

  function addMember(address member) external;

  function removeMember(address member) external;

  event Initialized(address[] addresses, uint256[] values);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IMember {
  /**
   * @dev Version number of this contract
   */
  function version() external pure returns (bytes32);

  /**
   * @dev Name of this contract
   */
  function getName() external pure returns (bytes32);
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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "../interfaces/ICover.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/IBondPool.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/IPriceDiscovery.sol";
import "../interfaces/ICxTokenFactory.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IGovernance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";

library RegistryLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getPriceDiscoveryContract(IStore s) external view returns (IPriceDiscovery) {
    return IPriceDiscovery(s.getContract(ProtoUtilV1.CNS_PRICE_DISCOVERY));
  }

  function getGovernanceContract(IStore s) external view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.CNS_GOVERNANCE));
  }

  function getResolutionContract(IStore s) external view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.CNS_GOVERNANCE_RESOLUTION));
  }

  function getStakingContract(IStore s) external view returns (ICoverStake) {
    return ICoverStake(s.getContract(ProtoUtilV1.CNS_COVER_STAKE));
  }

  function getCxTokenFactory(IStore s) external view returns (ICxTokenFactory) {
    return ICxTokenFactory(s.getContract(ProtoUtilV1.CNS_COVER_CXTOKEN_FACTORY));
  }

  function getPolicyContract(IStore s) external view returns (IPolicy) {
    return IPolicy(s.getContract(ProtoUtilV1.CNS_COVER_POLICY));
  }

  function getReassuranceContract(IStore s) external view returns (ICoverReassurance) {
    return ICoverReassurance(s.getContract(ProtoUtilV1.CNS_COVER_REASSURANCE));
  }

  function getBondPoolContract(IStore s) external view returns (IBondPool) {
    return IBondPool(s.getContract(ProtoUtilV1.CNS_POOL_BOND));
  }

  function getCoverContract(IStore s) external view returns (ICover) {
    address vault = s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.CNS_COVER);
    return ICover(vault);
  }

  function getVault(IStore s, bytes32 key) external view returns (IVault) {
    return IVault(getVaultAddress(s, key));
  }

  function getVaultAddress(IStore s, bytes32 key) public view returns (address) {
    address vault = s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.CNS_COVER_VAULT, key);
    return vault;
  }

  function getStakingPoolAddress(IStore s) public view returns (address) {
    address vault = s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.CNS_STAKING_POOL);
    return vault;
  }

  function getBondPoolAddress(IStore s, bytes32 key) public view returns (address) {
    address vault = s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.CNS_BOND_POOL, key);
    return vault;
  }

  function getVaultFactoryContract(IStore s) external view returns (IVaultFactory) {
    address factory = s.getContract(ProtoUtilV1.CNS_COVER_VAULT_FACTORY);
    return IVaultFactory(factory);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./AccessControlLibV1.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./NTransferUtilV2.sol";
import "../interfaces/ICxToken.sol";

library CoverUtilV1 {
  using RegistryLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using AccessControlLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  enum CoverStatus {
    Normal,
    Stopped,
    IncidentHappened,
    FalseReporting,
    Claimable
  }

  function getCoverOwner(IStore s, bytes32 key) external view returns (address) {
    return _getCoverOwner(s, key);
  }

  function _getCoverOwner(IStore s, bytes32 key) private view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, key);
  }

  function getCoverFee(IStore s)
    external
    view
    returns (
      uint256 fee,
      uint256 minCoverCreationStake,
      uint256 minStakeToAddLiquidity
    )
  {
    fee = s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_FEE);
    minCoverCreationStake = getMinCoverCreationStake(s);
    minStakeToAddLiquidity = getMinStakeToAddLiquidity(s);
  }

  function getMinCoverCreationStake(IStore s) public view returns (uint256) {
    uint256 value = s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_MIN_STAKE);

    if (value == 0) {
      // Fallback to 250 NPM
      value = 250 ether;
    }

    return value;
  }

  function getMinStakeToAddLiquidity(IStore s) public view returns (uint256) {
    uint256 value = s.getUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_MIN_STAKE);

    if (value == 0) {
      // Fallback to 250 NPM
      value = 250 ether;
    }

    return value;
  }

  function getClaimPeriod(IStore s, bytes32 key) external view returns (uint256) {
    uint256 fromKey = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_PERIOD, key);
    uint256 fallbackValue = s.getUintByKey(ProtoUtilV1.NS_CLAIM_PERIOD);

    return fromKey > 0 ? fromKey : fallbackValue;
  }

  /**
   * @dev Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] The total amount of NPM provision
   * @param _values[3] NPM price
   * @param _values[4] The total amount of reassurance tokens
   * @param _values[5] Reassurance token price
   * @param _values[6] Reassurance pool weight
   */
  function getCoverPoolSummaryInternal(IStore s, bytes32 key) external view returns (uint256[] memory _values) {
    IPriceDiscovery discovery = s.getPriceDiscoveryContract();

    _values = new uint256[](7);

    _values[0] = getCoverPoolLiquidity(s, key);
    _values[1] = getCoverLiquidityCommitted(s, key);
    _values[2] = s.getUintByKeys(ProtoUtilV1.NS_COVER_PROVISION, key);
    _values[3] = discovery.getTokenPriceInStableCoin(address(s.npmToken()), 1 ether);
    _values[4] = s.getUintByKeys(ProtoUtilV1.NS_COVER_REASSURANCE, key);
    _values[5] = discovery.getTokenPriceInStableCoin(address(s.getAddressByKeys(ProtoUtilV1.NS_COVER_REASSURANCE_TOKEN, key)), 1 ether);
    _values[6] = s.getUintByKeys(ProtoUtilV1.NS_COVER_REASSURANCE_WEIGHT, key);
  }

  /**
   * @dev Gets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function getCoverStatus(IStore s, bytes32 key) external view returns (CoverStatus) {
    return CoverStatus(getStatus(s, key));
  }

  function getStatus(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STATUS, key);
  }

  function getCoverPoolLiquidity(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKey(getCoverLiquidityKey(key));
  }

  function getCoverLiquidityKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY, coverKey));
  }

  function getCoverLiquidityAddedKey(bytes32 coverKey, address account) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_ADDED, coverKey, account));
  }

  function getCoverLiquidityReleaseDateKey(bytes32 coverKey, address account) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_RELEASE_DATE, coverKey, account));
  }

  function getCoverLiquidityStakeKey(bytes32 coverKey) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_STAKE, coverKey));
  }

  function getCoverLiquidityStakeIndividualKey(bytes32 coverKey, address account) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_STAKE, coverKey, account));
  }

  function getCoverTotalLentKey(bytes32 coverKey) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_STABLECOIN_LENT_TOTAL, coverKey));
  }

  function getCommitmentKey(bytes32 coverKey, uint256 expiryDate) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_COMMITTED, coverKey, expiryDate));
  }

  function getCoverLiquidityCommitted(IStore s, bytes32 key) public view returns (uint256) {
    (uint256 reporting, uint256 active) = getCoverLiquidityCommitmentInfo(s, key);
    return reporting + active;
  }

  function getCoverLiquidityCommitmentInfo(IStore s, bytes32 key) public view returns (uint256 reporting, uint256 active) {
    reporting = getCommitmentsUnderReporting(s, key);
    active = getCurrentCommitments(s, key);
  }

  function getCommitmentsUnderReporting(IStore s, bytes32 key) public view returns (uint256) {
    uint256 incidentDateIfAny = getActiveIncidentDateInternal(s, key);

    // There isn't any incident for this cover
    // and therefore no need to pay
    if (incidentDateIfAny == 0) {
      return 0;
    }

    uint256 expiryDate = _getMonthEndDate(incidentDateIfAny);
    ICxToken cxToken = ICxToken(getCxTokenByExpiryDateInternal(s, key, expiryDate));

    if (address(cxToken) != address(0)) {
      return cxToken.totalSupply();
    }

    return 0;
  }

  function getCurrentCommitments(IStore s, bytes32 key) public view returns (uint256 sum) {
    uint256 maxMonthsToProtect = 3;

    for (uint256 i = 0; i < maxMonthsToProtect; i++) {
      uint256 expiryDate = _getNextMonthEndDate(block.timestamp, i); // solhint-disable-line
      ICxToken cxToken = ICxToken(getCxTokenByExpiryDateInternal(s, key, expiryDate));

      if (address(cxToken) != address(0)) {
        sum += cxToken.totalSupply();
      }
    }
  }

  function getStake(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE, key);
  }

  /**
   * @dev Sets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function setStatus(
    IStore s,
    bytes32 key,
    CoverStatus status
  ) external {
    s.setUintByKeys(ProtoUtilV1.NS_COVER_STATUS, key, uint256(status));
  }

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   * @param key Enter the cover key
   */
  function getReassuranceAmountInternal(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_REASSURANCE, key);
  }

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDateInternal(uint256 today, uint256 coverDuration) external pure returns (uint256) {
    // Get the day of the month
    (, , uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(today);

    // Cover duration of 1 month means current month
    // unless today is the 25th calendar day or later
    uint256 monthToAdd = coverDuration - 1;

    if (day >= 25) {
      // Add one month
      monthToAdd += 1;
    }

    return _getNextMonthEndDate(today, monthToAdd);
  }

  // function _getPreviousMonthEndDate(uint256 date, uint256 monthsToSubtract) private pure returns (uint256) {
  //   uint256 pastDate = BokkyPooBahsDateTimeLibrary.subMonths(date, monthsToSubtract);
  //   return _getMonthEndDate(pastDate);
  // }

  function _getNextMonthEndDate(uint256 date, uint256 monthsToAdd) private pure returns (uint256) {
    uint256 futureDate = BokkyPooBahsDateTimeLibrary.addMonths(date, monthsToAdd);
    return _getMonthEndDate(futureDate);
  }

  function _getMonthEndDate(uint256 date) private pure returns (uint256) {
    // Get the year and month from the date
    (uint256 year, uint256 month, ) = BokkyPooBahsDateTimeLibrary.timestampToDate(date);

    // Count the total number of days of that month and year
    uint256 daysInMonth = BokkyPooBahsDateTimeLibrary._getDaysInMonth(year, month);

    // Get the month end date
    return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, daysInMonth, 23, 59, 59);
  }

  function getActiveIncidentDateInternal(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, key);
  }

  function getCxTokenByExpiryDateInternal(
    IStore s,
    bytes32 key,
    uint256 expiryDate
  ) public view returns (address cxToken) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_CXTOKEN, key, expiryDate));
    cxToken = s.getAddress(k);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/IPriceDiscovery.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./RoutineInvokerLibV1.sol";
import "./StoreKeyUtil.sol";
import "./CoverUtilV1.sol";

library GovernanceUtilV1 {
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ProtoUtilV1 for IStore;
  using RoutineInvokerLibV1 for IStore;

  function getReportingPeriod(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_PERIOD, key);
  }

  function getReportingBurnRate(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE);
  }

  function getGovernanceReporterCommission(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION);
  }

  function getClaimPlatformFee(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_CLAIM_PLATFORM_FEE);
  }

  function getClaimReporterCommission(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_CLAIM_REPORTER_COMMISSION);
  }

  function getMinReportingStake(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, key);
  }

  function getLatestIncidentDate(IStore s, bytes32 key) external view returns (uint256) {
    return _getLatestIncidentDate(s, key);
  }

  function getResolutionTimestamp(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, key);
  }

  function getReporter(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) external view returns (address) {
    (uint256 yes, uint256 no) = getStakes(s, key, incidentDate);

    bytes32 prefix = yes >= no ? ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES : ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO;
    return s.getAddressByKeys(prefix, key);
  }

  function getStakes(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, key, incidentDate));
    yes = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, key, incidentDate));
    no = s.getUintByKey(k);
  }

  function getStakesOf(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES, key, incidentDate, account));
    yes = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO, key, incidentDate, account));
    no = s.getUintByKey(k);
  }

  function getResolutionInfoFor(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  )
    public
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp
    )
  {
    (uint256 yes, uint256 no) = getStakes(s, key, incidentDate);
    (uint256 myYes, uint256 myNo) = getStakesOf(s, account, key, incidentDate);

    totalStakeInWinningCamp = yes > no ? yes : no;
    totalStakeInLosingCamp = yes > no ? no : yes;
    myStakeInWinningCamp = yes > no ? myYes : myNo;
  }

  function getUnstakeInfoForInternal(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  )
    external
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp,
      uint256 toBurn,
      uint256 toReporter,
      uint256 myReward
    )
  {
    (totalStakeInWinningCamp, totalStakeInLosingCamp, myStakeInWinningCamp) = getResolutionInfoFor(s, account, key, incidentDate);

    require(myStakeInWinningCamp > 0, "Nothing to unstake");

    uint256 rewardRatio = (myStakeInWinningCamp * ProtoUtilV1.MULTIPLIER) / totalStakeInWinningCamp;

    uint256 reward = 0;

    // Incident dates are reset when a reporting is finalized.
    // This check ensures only the people who come to unstake
    // before the finalization will receive rewards
    if (_getLatestIncidentDate(s, key) == incidentDate) {
      // slither-disable-next-line divide-before-multiply
      reward = (totalStakeInLosingCamp * rewardRatio) / ProtoUtilV1.MULTIPLIER;
    }

    toBurn = (reward * getReportingBurnRate(s)) / ProtoUtilV1.MULTIPLIER;
    toReporter = (reward * getGovernanceReporterCommission(s)) / ProtoUtilV1.MULTIPLIER;
    myReward = reward - toBurn - toReporter;
  }

  function updateUnstakeDetails(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate,
    uint256 originalStake,
    uint256 reward,
    uint256 burned,
    uint256 reporterFee
  ) external {
    // Unstake timestamp of the account
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_TS, key, incidentDate, account));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // Last unstake timestamp
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_TS, key, incidentDate));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // ---------------------------------------------------------------------

    // Amount unstaken by the account
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, key, incidentDate, account));
    s.setUintByKey(k, originalStake);

    // Amount unstaken by everyone
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, key, incidentDate));
    s.addUintByKey(k, originalStake);

    // ---------------------------------------------------------------------

    if (reward > 0) {
      // Reward received by the account
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REWARD, key, incidentDate, account));
      s.setUintByKey(k, reward);

      // Total reward received
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REWARD, key, incidentDate));
      s.addUintByKey(k, reward);
    }

    // ---------------------------------------------------------------------

    if (burned > 0) {
      // Total burned
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_BURNED, key, incidentDate));
      s.addUintByKey(k, burned);
    }

    if (reporterFee > 0) {
      // Total fee paid to the final reporter
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REPORTER_FEE, key, incidentDate));
      s.addUintByKey(k, reporterFee);
    }
  }

  function updateCoverStatus(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, key, incidentDate));
    uint256 yes = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, key, incidentDate));
    uint256 no = s.getUintByKey(k);

    if (no > yes) {
      s.setStatus(key, CoverUtilV1.CoverStatus.FalseReporting);
      return;
    }

    s.setStatus(key, CoverUtilV1.CoverStatus.IncidentHappened);
  }

  function addAttestation(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    // @suppress-address-trust-issue The address `who` can be trusted here because we are not performing any direct calls to it.
    // Add individual stake of the reporter
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES, key, incidentDate, who));
    s.addUintByKey(k, stake);

    // All "incident happened" camp witnesses combined
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, key, incidentDate));
    uint256 currentStake = s.getUintByKey(k);

    // No has reported yet, this is the first report
    if (currentStake == 0) {
      s.setAddressByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, key, msg.sender);
    }

    s.addUintByKey(k, stake);
    updateCoverStatus(s, key, incidentDate);

    s.updateStateAndLiquidity(key);
  }

  function getAttestation(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES, key, incidentDate, who));
    myStake = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, key, incidentDate));
    totalStake = s.getUintByKey(k);
  }

  function addDispute(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    // @suppress-address-trust-issue The address `who` can be trusted here because we are not performing any direct calls to it.

    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO, key, incidentDate, who));
    s.addUintByKey(k, stake);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, key, incidentDate));
    uint256 currentStake = s.getUintByKey(k);

    if (currentStake == 0) {
      // The first reporter who disputed
      s.setAddressByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, key, msg.sender);
    }

    s.addUintByKey(k, stake);

    updateCoverStatus(s, key, incidentDate);

    s.updateStateAndLiquidity(key);
  }

  function getDispute(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO, key, incidentDate, who));
    myStake = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, key, incidentDate));
    totalStake = s.getUintByKey(k);
  }

  function _getLatestIncidentDate(IStore s, bytes32 key) private view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, key);
  }

  function getCoolDownPeriodInternal(IStore s, bytes32 key) external view returns (uint256) {
    uint256 fromKey = s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD, key);
    uint256 fallbackValue = s.getUintByKey(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD);

    return fromKey > 0 ? fromKey : fallbackValue;
  }

  function getResolutionDeadlineInternal(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_DEADLINE, key);
  }

  function isResolvedInternal(IStore s, bytes32 key) external view returns (bool) {
    return getResolutionDeadlineInternal(s, key) > block.timestamp; // solhint-disable-line
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IPausable {
  function paused() external view returns (bool);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.0;

interface ICxToken is IERC20 {
  event Finalized(uint256 amount);

  function mint(
    bytes32 key,
    address to,
    uint256 amount
  ) external;

  function burn(uint256 amount) external;

  function createdOn() external view returns (uint256);

  function expiresOn() external view returns (uint256);

  function coverKey() external view returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface ICover is IMember {
  event CoverCreated(bytes32 key, bytes32 info);
  event CoverUpdated(bytes32 key, bytes32 info);
  event CoverStopped(bytes32 indexed coverKey, address indexed deletedBy, string reason);
  event VaultDeployed(bytes32 indexed coverKey, address vault);

  event WhitelistUpdated(address account, bool status);
  event CoverFeeSet(uint256 previous, uint256 current);
  event MinCoverCreationStakeSet(uint256 previous, uint256 current);
  event MinStakeToAddLiquiditySet(uint256 previous, uint256 current);
  event CoverInitialized(address indexed stablecoin, bytes32 withName);

  /**
   * @dev Initializes this contract
   * @param liquidityToken Provide the address of the token this cover will be quoted against.
   * @param liquidityName Enter a description or ENS name of your liquidity token.
   *
   */
  function initialize(address liquidityToken, bytes32 liquidityName) external;

  /**
   * @dev Adds a new coverage pool or cover contract.
   * To add a new cover, you need to pay cover creation fee
   * and stake minimum amount of NPM in the Vault. <br /> <br />
   *
   * Through the governance portal, projects will be able redeem
   * the full cover fee at a later date. <br /> <br />
   *
   * **Apply for Fee Redemption** <br />
   * https://docs.neptunemutual.com/covers/cover-fee-redemption <br /><br />
   *
   * As the cover creator, you will earn a portion of all cover fees
   * generated in this pool. <br /> <br />
   *
   * Read the documentation to learn more about the fees: <br />
   * https://docs.neptunemutual.com/covers/contract-creators
   *
   * @param key Enter a unique key for this cover
   * @param info IPFS info of the cover contract
   * @param reassuranceToken **Optional.** Token added as an reassurance of this cover. <br /><br />
   *
   * Reassurance tokens can be added by a project to demonstrate coverage support
   * for their own project. This helps bring the cover fee down and enhances
   * liquidity provider confidence. Along with the NPM tokens, the reassurance tokens are rewarded
   * as a support to the liquidity providers when a cover incident occurs.
   * @param values[0] stakeWithFee Enter the total NPM amount (stake + fee) to transfer to this contract.
   * @param values[1] initialReassuranceAmount **Optional.** Enter the initial amount of
   * @param values[2] minStakeToReport A cover creator can override default min NPM stake to avoid spam reports
   * @param values[3] reportingPeriod The period during when reporting happens.
   * reassurance tokens you'd like to add to this pool.
   * @param values[4] cooldownperiod Enter the cooldown period for governance.
   * @param values[5] claimPeriod Enter the claim period.
   * @param values[6] floor Enter the policy floor rate.
   * @param values[7] ceiling Enter the policy ceiling rate.
   */
  function addCover(
    bytes32 key,
    bytes32 info,
    address reassuranceToken,
    uint256[] memory values
  ) external;

  function deployVault(bytes32 key) external returns (address);

  /**
   * @dev Updates the cover contract.
   * This feature is accessible only to the cover owner or protocol owner (governance).
   *
   * @param key Enter the cover key
   * @param info Enter a new IPFS URL to update
   */
  function updateCover(bytes32 key, bytes32 info) external;

  function updateWhitelist(address account, bool whitelisted) external;

  /**
   * @dev Get info of a cover contract by key
   * @param key Enter the cover key
   * @param coverOwner Returns the address of the cover creator
   * @param info Gets the IPFS hash of the cover info
   * @param values Array of uint256 values. See `CoverUtilV1.getCoverInfo`.
   */
  function getCover(bytes32 key)
    external
    view
    returns (
      address coverOwner,
      bytes32 info,
      uint256[] memory values
    );

  function stopCover(bytes32 key, string memory reason) external;

  function checkIfWhitelisted(address account) external view returns (bool);

  function setCoverFees(uint256 value) external;

  function setMinCoverCreationStake(uint256 value) external;

  function setMinStakeToAddLiquidity(uint256 value) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface IPolicy is IMember {
  event CoverPurchased(bytes32 key, address indexed account, address indexed cxToken, uint256 fee, uint256 amountToCover, uint256 expiresOn);

  /**
   * @dev Purchase cover for the specified amount. <br /> <br />
   * When you purchase covers, you recieve equal amount of cxTokens back.
   * You need the cxTokens to claim the cover when resolution occurs.
   * Each unit of cxTokens are fully redeemable at 1:1 ratio to the given
   * stablecoins (like wxDai, DAI, USDC, or BUSD) based on the chain.
   * @param key Enter the cover key you wish to purchase the policy for
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin `liquidityToken` to cover.
   */
  function purchaseCover(
    bytes32 key,
    uint256 coverDuration,
    uint256 amountToCover
  ) external returns (address);

  /**
   * @dev Gets the cover fee info for the given cover key, duration, and amount
   * @param key Enter the cover key
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin `liquidityToken` to cover.
   */
  function getCoverFeeInfo(
    bytes32 key,
    uint256 coverDuration,
    uint256 amountToCover
  )
    external
    view
    returns (
      uint256 fee,
      uint256 utilizationRatio,
      uint256 totalAvailableLiquidity,
      uint256 coverRatio,
      uint256 floor,
      uint256 ceiling,
      uint256 rate
    );

  /**
   * @dev Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] The total amount of NPM provision
   * @param _values[3] NPM price
   * @param _values[4] The total amount of reassurance tokens
   * @param _values[5] Reassurance token price
   * @param _values[6] Reassurance pool weight
   */
  function getCoverPoolSummary(bytes32 key) external view returns (uint256[] memory _values);

  function getCxToken(bytes32 key, uint256 coverDuration) external view returns (address cxToken, uint256 expiryDate);

  function getCxTokenByExpiryDate(bytes32 key, uint256 expiryDate) external view returns (address cxToken);

  /**
   * Gets the sum total of cover commitment that haven't expired yet.
   */
  function getCommitment(bytes32 key) external view returns (uint256);

  /**
   * Gets the available liquidity in the pool.
   */
  function getAvailableLiquidity(bytes32 key) external view returns (uint256);

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDate(uint256 today, uint256 coverDuration) external pure returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface IBondPool is IMember {
  event BondPoolSetup(address[] addresses, uint256[] values);
  event BondCreated(address indexed account, uint256 lpTokens, uint256 npmToVest, uint256 unlockDate);
  event BondClaimed(address indexed account, uint256 amount);

  function setup(address[] memory addresses, uint256[] memory values) external;

  function createBond(uint256 lpTokens, uint256 minNpmDesired) external;

  function claimBond() external;

  function getNpmMarketPrice() external view returns (uint256);

  function calculateTokensForLp(uint256 lpTokens) external view returns (uint256);

  function getInfo(address forAccount) external view returns (address[] memory addresses, uint256[] memory values);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface ICoverStake is IMember {
  event StakeAdded(bytes32 key, uint256 amount);
  event StakeRemoved(bytes32 key, uint256 amount);
  event FeeBurned(bytes32 key, uint256 amount);

  /**
   * @dev Increase the stake of the given cover pool
   * @param key Enter the cover key
   * @param account Enter the account from where the NPM tokens will be transferred
   * @param amount Enter the amount of stake
   * @param fee Enter the fee amount. Note: do not enter the fee if you are directly calling this function.
   */
  function increaseStake(
    bytes32 key,
    address account,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @dev Decreases the stake from the given cover pool
   * @param key Enter the cover key
   * @param account Enter the account to decrease the stake of
   * @param amount Enter the amount of stake to decrease
   */
  function decreaseStake(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  /**
   * @dev Gets the stake of an account for the given cover key
   * @param key Enter the cover key
   * @param account Specify the account to obtain the stake of
   * @return Returns the total stake of the specified account on the given cover key
   */
  function stakeOf(bytes32 key, address account) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface IPriceDiscovery is IMember {
  event PriceUpdated(address token, address stablecoin, uint256 price);

  function getTokenPriceInStableCoin(address token, uint256 multiplier) external view returns (uint256);

  function getTokenPriceInLiquidityToken(
    address token,
    address liquidityToken,
    uint256 multiplier
  ) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface ICxTokenFactory is IMember {
  event CxTokenDeployed(bytes32 indexed key, address cxToken, uint256 expiryDate);

  function deploy(
    IStore s,
    bytes32 key,
    uint256 expiryDate
  ) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface ICoverReassurance is IMember {
  event ReassuranceAdded(bytes32 key, uint256 amount);

  /**
   * @dev Adds reassurance to the specified cover contract
   * @param key Enter the cover key
   * @param amount Enter the amount you would like to supply
   */
  function addReassurance(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  function setWeight(bytes32 key, uint256 weight) external;

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   * @param key Enter the cover key
   */
  function getReassurance(bytes32 key) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IReporter.sol";
import "./IWitness.sol";
import "./IMember.sol";

interface IGovernance is IMember, IReporter, IWitness {}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IVault is IMember, IERC20 {
  event GovernanceTransfer(address indexed to, uint256 amount);
  event StrategyTransfer(address indexed token, address indexed strategy, bytes32 indexed name, uint256 amount);
  event StrategyReceipt(address indexed token, address indexed strategy, bytes32 indexed name, uint256 amount);
  event PodsIssued(address indexed account, uint256 issued, uint256 liquidityAdded);
  event PodsRedeemed(address indexed account, uint256 redeemed, uint256 liquidityReleased);
  event FlashLoanBorrowed(address indexed lender, address indexed borrower, address indexed stablecoin, uint256 amount, uint256 fee);

  function key() external view returns (bytes32);

  function lqt() external view returns (address);

  /**
   * @dev Adds liquidity to the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to supply.
   * @param npmStake Enter the amount of NPM token to stake.
   */
  function addLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake
  ) external;

  /**
   * @dev Removes liquidity from the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to remove.
   * @param npmStake Enter the amount of NPM stake to remove.
   */
  function removeLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake
  ) external;

  /**
   * @dev Transfers liquidity to governance contract.
   * @param coverKey Enter the cover key
   * @param to Enter the destination account
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferGovernance(
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev Transfers liquidity to strategy contract.
   * @param coverKey Enter the cover key
   * @param strategyName Enter the strategy's name
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferToStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  /**
   * @dev Receives from strategy contract.
   * @param coverKey Enter the cover key
   * @param strategyName Enter the strategy's name
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function receiveFromStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  function calculatePods(uint256 forStablecoinUnits) external view returns (uint256);

  function calculateLiquidity(uint256 podsToBurn) external view returns (uint256);

  function getInfo(address forAccount) external view returns (uint256[] memory result);

  /**
   * @dev Returns the stablecoin balance of this vault
   * This also includes amounts lent out in lending strategies
   */
  function getStablecoinBalanceOf() external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface IVaultFactory is IMember {
  event VaultDeployed(bytes32 indexed key, address vault);

  function deploy(IStore s, bytes32 key) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IReporter {
  event Reported(bytes32 indexed key, address indexed reporter, uint256 incidentDate, bytes32 info, uint256 initialStake, uint256 resolutionTimestamp);
  event Disputed(bytes32 indexed key, address indexed reporter, uint256 incidentDate, bytes32 info, uint256 initialStake);

  event ReportingBurnRateSet(uint256 previous, uint256 current);
  event FirstReportingStakeSet(uint256 previous, uint256 current);
  event ReporterCommissionSet(uint256 previous, uint256 current);

  function report(
    bytes32 key,
    bytes32 info,
    uint256 stake
  ) external;

  function dispute(
    bytes32 key,
    uint256 incidentDate,
    bytes32 info,
    uint256 stake
  ) external;

  function getActiveIncidentDate(bytes32 key) external view returns (uint256);

  function getReporter(bytes32 key, uint256 incidentDate) external view returns (address);

  function getResolutionDate(bytes32 key) external view returns (uint256);

  function setFirstReportingStake(uint256 value) external;

  function getFirstReportingStake() external view returns (uint256);

  function getFirstReportingStake(bytes32 key) external view returns (uint256);

  function setReportingBurnRate(uint256 value) external;

  function setReporterCommission(uint256 value) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IWitness {
  event Attested(bytes32 indexed key, address indexed witness, uint256 incidentDate, uint256 stake);
  event Refuted(bytes32 indexed key, address indexed witness, uint256 incidentDate, uint256 stake);

  function attest(
    bytes32 key,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function refute(
    bytes32 key,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function getStatus(bytes32 key) external view returns (uint256);

  function getStakes(bytes32 key, uint256 incidentDate) external view returns (uint256, uint256);

  function getStakesOf(
    bytes32 key,
    uint256 incidentDate,
    address account
  ) external view returns (uint256, uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./ProtoUtilV1.sol";

library AccessControlLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  bytes32 public constant NS_ROLES_ADMIN = 0x00; // SAME AS "DEFAULT_ADMIN_ROLE"
  bytes32 public constant NS_ROLES_COVER_MANAGER = "role:cover:manager";
  bytes32 public constant NS_ROLES_LIQUIDITY_MANAGER = "role:liquidity:manager";
  bytes32 public constant NS_ROLES_GOVERNANCE_AGENT = "role:governance:agent";
  bytes32 public constant NS_ROLES_GOVERNANCE_ADMIN = "role:governance:admin";
  bytes32 public constant NS_ROLES_UPGRADE_AGENT = "role:upgrade:agent";
  bytes32 public constant NS_ROLES_RECOVERY_AGENT = "role:recovery:agent";
  bytes32 public constant NS_ROLES_PAUSE_AGENT = "role:pause:agent";
  bytes32 public constant NS_ROLES_UNPAUSE_AGENT = "role:unpause:agent";

  /**
   * @dev Reverts if the sender is not the protocol admin.
   */
  function mustBeAdmin(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_ADMIN);
  }

  /**
   * @dev Reverts if the sender is not the cover manager.
   */
  function mustBeCoverManager(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_COVER_MANAGER);
  }

  /**
   * @dev Reverts if the sender is not the cover manager.
   */
  function senderMustBeWhitelisted(IStore s) external view {
    require(s.getAddressBooleanByKey(ProtoUtilV1.NS_COVER_WHITELIST, msg.sender), "Not whitelisted");
  }

  /**
   * @dev Reverts if the sender is not the liquidity manager.
   */
  function mustBeLiquidityManager(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_LIQUIDITY_MANAGER);
  }

  /**
   * @dev Reverts if the sender is not a governance agent.
   */
  function mustBeGovernanceAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_AGENT);
  }

  /**
   * @dev Reverts if the sender is not a governance admin.
   */
  function mustBeGovernanceAdmin(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_ADMIN);
  }

  /**
   * @dev Reverts if the sender is not an upgrade agent.
   */
  function mustBeUpgradeAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_UPGRADE_AGENT);
  }

  /**
   * @dev Reverts if the sender is not a recovery agent.
   */
  function mustBeRecoveryAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_RECOVERY_AGENT);
  }

  /**
   * @dev Reverts if the sender is not the pause agent.
   */
  function mustBePauseAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_PAUSE_AGENT);
  }

  /**
   * @dev Reverts if the sender is not the unpause agent.
   */
  function mustBeUnpauseAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_UNPAUSE_AGENT);
  }

  /**
   * @dev Reverts if the sender does not have access to the given role.
   */
  function _mustHaveAccess(IStore s, bytes32 role) private view {
    require(hasAccess(s, role, msg.sender), "Forbidden");
  }

  /**
   * @dev Checks if a given user has access to the given role
   * @param role Specify the role name
   * @param user Enter the user account
   * @return Returns true if the user is a member of the specified role
   */
  function hasAccess(
    IStore s,
    bytes32 role,
    address user
  ) public view returns (bool) {
    address protocol = s.getProtocolAddress();

    // The protocol is not deployed yet. Therefore, no role to check
    if (protocol == address(0)) {
      return false;
    }

    // You must have the same role in the protocol contract if you're don't have this role here
    return IAccessControl(protocol).hasRole(role, user);
  }
}

/* solhint-disable private-vars-leading-underscore, reason-string */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint256 internal constant SECONDS_PER_HOUR = 60 * 60;
  uint256 internal constant SECONDS_PER_MINUTE = 60;
  int256 internal constant OFFSET19700101 = 2440588;

  uint256 internal constant DOW_MON = 1;
  uint256 internal constant DOW_TUE = 2;
  uint256 internal constant DOW_WED = 3;
  uint256 internal constant DOW_THU = 4;
  uint256 internal constant DOW_FRI = 5;
  uint256 internal constant DOW_SAT = 6;
  uint256 internal constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 _days) {
    require(year >= 1970);
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function timestampFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
  }

  function timestampToDate(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > 0 && day <= daysInMonth) {
        valid = true;
      }
    }
  }

  function isValidDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) {
        valid = true;
      }
    }
  }

  function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
    (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
    leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
    (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  function getYear(uint256 timestamp) internal pure returns (uint256 year) {
    (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
    (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint256 timestamp) internal pure returns (uint256 day) {
    (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
    uint256 secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year += _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    month += _months;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    require(newTimestamp >= timestamp);
  }

  function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    require(newTimestamp >= timestamp);
  }

  function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp >= timestamp);
  }

  function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _seconds;
    require(newTimestamp >= timestamp);
  }

  function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year -= _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 yearMonth = year * 12 + (month - 1) - _months;
    year = yearMonth / 12;
    month = (yearMonth % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }

  function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    require(newTimestamp <= timestamp);
  }

  function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp <= timestamp);
  }

  function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _seconds;
    require(newTimestamp <= timestamp);
  }

  function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _years = toYear - fromYear;
  }

  function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
    require(fromTimestamp <= toTimestamp);
    _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
    require(fromTimestamp <= toTimestamp);
    _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
    require(fromTimestamp <= toTimestamp);
    _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
    require(fromTimestamp <= toTimestamp);
    _seconds = toTimestamp - fromTimestamp;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/ILendingStrategy.sol";
import "./PriceLibV1.sol";
import "./ProtoUtilV1.sol";
import "./CoverUtilV1.sol";
import "./StrategyLibV1.sol";

// @todo: before launch, refactor this to be invoked manually
// A misconfiguration or issue on an external protocol may take the whole system down
library RoutineInvokerLibV1 {
  using PriceLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using StrategyLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  enum Action {
    Deposit,
    Withdraw
  }

  function updateStateAndLiquidity(IStore s, bytes32 key) external {
    _invoke(s, key, address(0));
  }

  function updateStateAndLiquidity(
    IStore s,
    bytes32 key,
    address token
  ) external {
    _invoke(s, key, token);
  }

  function _invoke(
    IStore s,
    bytes32 key,
    address token
  ) private {
    _updateKnownTokenPrices(s, token);

    if (key > 0) {
      _invokeAssetManagement(s, key);
    }
  }

  function _executeIsWithdrawalPeriod(IStore s, bytes32 coverKey) private returns (bool) {
    (uint256 lendingPeriod, uint256 withdrawalWindow) = s.getLendingPeriodsInternal(coverKey);

    // Without a lending period and withdrawal window, deposit is not possible
    if (lendingPeriod == 0 || withdrawalWindow == 0) {
      return true;
    }

    // Get the withdrawal period of this cover liquidity
    uint256 start = s.getUintByKey(getNextWithdrawalStartKey(coverKey));
    uint256 end = s.getUintByKey(getNextWithdrawalEndKey(coverKey));

    // solhint-disable-next-line
    if (block.timestamp >= start && block.timestamp <= end) {
      return true;
    }

    // The withdrawal period is now over.
    // Deposits can be performed again.
    // Set the next withdrawal cycle
    if (block.timestamp > end) {
      // solhint-disable-previous-line

      // Next Withdrawal Cycle

      // Withdrawals can start after the lending period
      start = block.timestamp + lendingPeriod; // solhint-disable
      // Withdrawals can be performed until the end of the next withdrawal cycle
      end = start + withdrawalWindow;

      s.setUintByKey(getNextWithdrawalStartKey(coverKey), start);
      s.setUintByKey(getNextWithdrawalEndKey(coverKey), end);
    }

    return false;
  }

  function getNextWithdrawalStartKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_WITHDRAWAL_START, coverKey));
  }

  function getNextWithdrawalEndKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_WITHDRAWAL_END, coverKey));
  }

  function mustBeDuringWithdrawalPeriod(IStore s, bytes32 coverKey) external view {
    // Get the withdrawal period of this cover liquidity
    uint256 start = s.getUintByKey(getNextWithdrawalStartKey(coverKey));
    uint256 end = s.getUintByKey(getNextWithdrawalEndKey(coverKey));

    require(block.timestamp >= start, "Withdrawal period has not started");
    require(block.timestamp < end, "Withdrawal period has already ended");
  }

  function _executeAndGetAction(
    IStore s,
    ILendingStrategy,
    bytes32 coverKey
  ) private returns (Action) {
    // If the cover is undergoing reporting, withdraw everything
    CoverUtilV1.CoverStatus status = s.getCoverStatus(coverKey);

    if (status != CoverUtilV1.CoverStatus.Normal) {
      // Reset the withdrawal window
      s.setUintByKey(getNextWithdrawalStartKey(coverKey), 0);
      s.setUintByKey(getNextWithdrawalEndKey(coverKey), 0);

      return Action.Withdraw;
    }

    if (_executeIsWithdrawalPeriod(s, coverKey)) {
      return Action.Withdraw;
    }

    return Action.Deposit;
  }

  function _canDeposit(
    IStore s,
    ILendingStrategy strategy,
    uint256 totalStrategies,
    bytes32 key
  ) private view returns (uint256) {
    address vault = s.getVaultAddress(key);
    IERC20 stablecoin = IERC20(s.getStablecoin());

    uint256 maximumAllowed = (stablecoin.balanceOf(vault) * StrategyLibV1.MAX_LENDING_RATIO) / ProtoUtilV1.MULTIPLIER;
    uint256 allocation = maximumAllowed / totalStrategies;
    uint256 weight = strategy.getWeight();
    uint256 canDeposit = (allocation * weight) / ProtoUtilV1.MULTIPLIER;
    uint256 alreadyDeposited = _getTotalInDeposits(s, strategy, key);

    if (alreadyDeposited >= canDeposit) {
      return 0;
    }

    return canDeposit - alreadyDeposited;
  }

  function _getTotalInDeposits(
    IStore s,
    ILendingStrategy strategy,
    bytes32 key
  ) private view returns (uint256) {
    bytes32 k = _getStrategyDepositKey(key, strategy);
    return s.getUintByKey(k);
  }

  function _invokeAssetManagement(IStore s, bytes32 key) private {
    address vault = s.getVaultAddress(key);
    _withdrawFromDisabled(s, key, vault);

    address[] memory strategies = s.getActiveStrategiesInternal();

    for (uint256 i = 0; i < strategies.length; i++) {
      ILendingStrategy strategy = ILendingStrategy(strategies[i]);
      _executeStrategy(s, strategy, strategies.length, vault, key);
    }
  }

  function _executeStrategy(
    IStore s,
    ILendingStrategy strategy,
    uint256 totalStrategies,
    address vault,
    bytes32 key
  ) private {
    uint256 canDeposit = _canDeposit(s, strategy, totalStrategies, key);
    uint256 balance = IERC20(s.getStablecoin()).balanceOf(vault);

    if (canDeposit > balance) {
      canDeposit = balance;
    }

    Action action = _executeAndGetAction(s, strategy, key);

    if (action == Action.Deposit && canDeposit == 0) {
      return;
    }

    if (action == Action.Withdraw) {
      uint256 stablecoinWithdrawn = _withdrawAllFromStrategy(strategy, vault, key);
      _clearDeposits(s, key, strategy, stablecoinWithdrawn);
    } else {
      _depositToStrategy(strategy, key, canDeposit);
      _setDeposit(s, key, strategy, canDeposit);
    }
  }

  function _setDeposit(
    IStore s,
    bytes32 key,
    ILendingStrategy strategy,
    uint256 amount
  ) private {
    bytes32 k = _getStrategyDepositKey(key, strategy);
    s.addUintByKey(k, amount);
    s.addUintByKey(CoverUtilV1.getCoverTotalLentKey(key), amount);
  }

  function _clearDeposits(
    IStore s,
    bytes32 key,
    ILendingStrategy strategy,
    uint256 withdrawn
  ) private {
    uint256 deposited = _getTotalInDeposits(s, strategy, key);
    uint256 difference = 0;

    if (deposited >= withdrawn) {
      difference = deposited - withdrawn;
      s.subtractUint(CoverUtilV1.getCoverLiquidityKey(key), difference);
    } else {
      difference = withdrawn - deposited;
      s.addUint(CoverUtilV1.getCoverLiquidityKey(key), difference);
    }

    bytes32 k = _getStrategyDepositKey(key, strategy);
    s.deleteUintByKey(k);

    s.subtractUintByKey(CoverUtilV1.getCoverTotalLentKey(key), deposited);
  }

  function _getStrategyDepositKey(bytes32 key, ILendingStrategy strategy) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_DEPOSITS, key, strategy.getKey()));
  }

  function _depositToStrategy(
    ILendingStrategy strategy,
    bytes32 key,
    uint256 amount
  ) private {
    strategy.deposit(key, amount);
  }

  function _withdrawAllFromStrategy(
    ILendingStrategy strategy,
    address vault,
    bytes32 key
  ) private returns (uint256 stablecoinWithdrawn) {
    uint256 balance = IERC20(strategy.getDepositCertificate()).balanceOf(vault);

    if (balance > 0) {
      stablecoinWithdrawn = strategy.withdraw(key);
    }
  }

  function _withdrawFromDisabled(
    IStore s,
    bytes32 key,
    address onBehalfOf
  ) private {
    address[] memory strategies = s.getDisabledStrategiesInternal();

    for (uint256 i = 0; i < strategies.length; i++) {
      ILendingStrategy strategy = ILendingStrategy(strategies[i]);
      uint256 balance = IERC20(strategy.getDepositCertificate()).balanceOf(onBehalfOf);

      if (balance > 0) {
        strategy.withdraw(key);
      }
    }
  }

  function _updateKnownTokenPrices(IStore s, address token) private {
    address npm = s.getNpmTokenAddress();

    if (token != address(0) && token != npm) {
      PriceLibV1.setTokenPriceInStablecoinInternal(s, token);
    }

    PriceLibV1.setTokenPriceInStablecoinInternal(s, npm);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IMember.sol";

pragma solidity 0.8.0;

interface ILendingStrategy is IMember {
  event Deposited(bytes32 indexed key, address indexed onBehalfOf, uint256 stablecoinDeposited);
  event Withdrawn(bytes32 indexed key, address indexed sendTo, uint256 stablecoinWithdrawn);
  event Drained(IERC20 indexed asset, uint256 amount);

  function getKey() external pure returns (bytes32);

  function getWeight() external pure returns (uint256);

  function getDepositAsset() external view returns (IERC20);

  function getDepositCertificate() external view returns (IERC20);

  /**
   * @dev Gets info of this strategy by cover key
   * @param coverKey Enter the cover key
   * @param values[0] deposits Total amount deposited
   * @param values[1] withdrawals Total amount withdrawn
   */
  function getInfo(bytes32 coverKey) external view returns (uint256[] memory values);

  function deposit(bytes32 coverKey, uint256 amount) external returns (uint256 certificateReceived);

  function withdraw(bytes32 coverKey) external returns (uint256 stablecoinWithdrawn);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/external/IUniswapV2RouterLike.sol";
import "../interfaces/external/IUniswapV2PairLike.sol";
import "../interfaces/external/IUniswapV2FactoryLike.sol";
import "./NTransferUtilV2.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./ValidationLibV1.sol";
import "./RegistryLibV1.sol";
import "hardhat/console.sol";

// @todo: use an oracle service
library PriceLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  uint256 public constant UPDATE_INTERVAL = 15 minutes;

  function setTokenPriceInStablecoinInternal(IStore s, address token) internal {
    if (token == address(0)) {
      return;
    }

    address stablecoin = s.getStablecoin();
    setTokenPriceInternal(s, token, stablecoin);
  }

  function setTokenPriceInternal(
    IStore s,
    address token,
    address stablecoin
  ) internal {
    IUniswapV2PairLike pair = _getPair(s, token, stablecoin);
    _setTokenPrice(s, token, stablecoin, pair);
  }

  /**
   * @dev Returns the last persisted pair info
   * @param s Provide store instance
   * @param pair Provide pair instance
   * @param values[0] reserve0
   * @param values[1] reserve1
   * @param values[2] totalSupply
   */
  function getLastKnownPairInfoInternal(IStore s, IUniswapV2PairLike pair) public view returns (uint256[] memory values) {
    values = new uint256[](3);

    values[0] = s.getUintByKey(_getReserve0Key(pair));
    values[1] = s.getUintByKey(_getReserve1Key(pair));
    values[2] = s.getUintByKey(_getPairTotalSupplyKey(pair));
  }

  function _setTokenPrice(
    IStore s,
    address token,
    address stablecoin,
    IUniswapV2PairLike pair
  ) private {
    if (token == stablecoin) {
      return;
    }

    // solhint-disable-next-line
    if (getLastUpdateOnInternal(s, token, stablecoin) + UPDATE_INTERVAL > block.timestamp) {
      return;
    }

    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

    s.setUintByKey(_getReserve0Key(pair), reserve0);
    s.setUintByKey(_getReserve1Key(pair), reserve1);
    s.setUintByKey(_getPairTotalSupplyKey(pair), pair.totalSupply());

    _setLastUpdateOn(s, token, stablecoin);
  }

  function getPairLiquidityInStablecoin(
    IStore s,
    IUniswapV2PairLike pair,
    uint256 lpTokens
  ) external view returns (uint256) {
    uint256[] memory values = getLastKnownPairInfoInternal(s, pair);

    uint256 reserve0 = values[0];
    uint256 reserve1 = values[1];
    uint256 supply = values[2];

    address stablecoin = s.getStablecoin();

    if (pair.token0() == stablecoin) {
      return (2 * reserve0 * lpTokens) / supply;
    }

    return (2 * reserve1 * lpTokens) / supply;
  }

  function getLastUpdateOnInternal(
    IStore s,
    address token,
    address liquidityToken
  ) public view returns (uint256) {
    bytes32 key = _getLastUpdateKey(token, liquidityToken);
    return s.getUintByKey(key);
  }

  function _setLastUpdateOn(
    IStore s,
    address token,
    address liquidityToken
  ) private {
    bytes32 key = _getLastUpdateKey(token, liquidityToken);
    s.setUintByKey(key, block.timestamp); // solhint-disable-line
  }

  function _getLastUpdateKey(address token0, address token1) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_TOKEN_PRICE_LAST_UPDATE, token0, token1));
  }

  function getPriceInternal(
    IStore s,
    address token,
    address stablecoin,
    uint256 multiplier
  ) public view returns (uint256) {
    IUniswapV2PairLike pair = _getPair(s, token, stablecoin);
    IUniswapV2RouterLike router = IUniswapV2RouterLike(s.getUniswapV2Router());

    uint256[] memory values = getLastKnownPairInfoInternal(s, pair);
    uint256 reserve0 = values[0];
    uint256 reserve1 = values[1];

    if (pair.token0() == stablecoin) {
      return router.getAmountIn(multiplier, reserve0, reserve1);
    }

    return router.getAmountIn(multiplier, reserve1, reserve0);
  }

  function getNpmPriceInternal(IStore s, uint256 multiplier) external view returns (uint256) {
    return getPriceInternal(s, s.getNpmTokenAddress(), s.getStablecoin(), multiplier);
  }

  function _getReserve0Key(IUniswapV2PairLike pair) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LP_RESERVE0, pair));
  }

  function _getReserve1Key(IUniswapV2PairLike pair) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LP_RESERVE1, pair));
  }

  function _getPairTotalSupplyKey(IUniswapV2PairLike pair) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LP_TOTAL_SUPPLY, pair));
  }

  function _getPair(
    IStore s,
    address token,
    address stablecoin
  ) private view returns (IUniswapV2PairLike) {
    IUniswapV2FactoryLike factory = IUniswapV2FactoryLike(s.getUniswapV2Factory());
    IUniswapV2PairLike pair = IUniswapV2PairLike(factory.getPair(token, stablecoin));

    return pair;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/ILendingStrategy.sol";
import "./PriceLibV1.sol";
import "./ProtoUtilV1.sol";

library StrategyLibV1 {
  using StoreKeyUtil for IStore;

  // @todo
  // 1. Configure this magic number.
  // 2. Decrease the value of % divisor to avoid overflow.
  uint256 public constant MAX_LENDING_RATIO = 500; // 5% (divided by 10,000)

  function _deleteStrategy(IStore s, address toFind) private {
    bytes32 key = ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE;

    uint256 pos = s.getAddressArrayItemPosition(key, toFind);
    require(pos > 1, "Invalid strategy");

    s.deleteAddressArrayItem(key, toFind);
    s.setBoolByKey(_getIsActiveStrategyKey(toFind), false);
  }

  function _getIsActiveStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, strategyAddress));
  }

  function disableStrategyInternal(IStore s, address toFind) external {
    _deleteStrategy(s, toFind);

    s.setAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED, toFind);
  }

  function addStrategiesInternal(IStore s, address[] memory strategies) external {
    for (uint256 i = 0; i < strategies.length; i++) {
      address strategy = strategies[i];
      _addStrategy(s, strategy);
    }
  }

  function getLendingPeriodsInternal(IStore s, bytes32 coverKey) external view returns (uint256 lendingPeriod, uint256 withdrawalWindow) {
    lendingPeriod = s.getUintByKey(getLendingPeriodKey(coverKey, true));
    withdrawalWindow = s.getUintByKey(getWithdrawalWindowKey(coverKey, true));

    if (lendingPeriod == 0) {
      lendingPeriod = s.getUintByKey(getLendingPeriodKey(0, true));
      withdrawalWindow = s.getUintByKey(getWithdrawalWindowKey(0, true));
    }
  }

  function setLendingPeriodsInternal(
    IStore s,
    bytes32 coverKey,
    uint256 lendingPeriod,
    uint256 withdrawalWindow
  ) external {
    s.setUintByKey(getLendingPeriodKey(coverKey, true), lendingPeriod);
    s.setUintByKey(getWithdrawalWindowKey(coverKey, true), withdrawalWindow);
  }

  function getLendingPeriodKey(bytes32 coverKey, bool ignoreMissingKey) public pure returns (bytes32) {
    if (ignoreMissingKey == false) {
      require(coverKey > 0, "Invalid Cover Key");
    }

    if (coverKey > 0) {
      return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_LENDING_PERIOD, coverKey));
    }

    return ProtoUtilV1.NS_COVER_LIQUIDITY_LENDING_PERIOD;
  }

  function getWithdrawalWindowKey(bytes32 coverKey, bool ignoreMissingKey) public pure returns (bytes32) {
    if (ignoreMissingKey == false) {
      require(coverKey > 0, "Invalid Cover Key");
    }

    if (coverKey > 0) {
      return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW, coverKey));
    }

    return ProtoUtilV1.NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW;
  }

  function _addStrategy(IStore s, address deployedOn) private {
    ILendingStrategy strategy = ILendingStrategy(deployedOn);
    require(strategy.getWeight() <= ProtoUtilV1.MULTIPLIER, "Weight too much");

    s.setBoolByKey(_getIsActiveStrategyKey(deployedOn), true);
    s.setAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, deployedOn);
  }

  function getDisabledStrategiesInternal(IStore s) external view returns (address[] memory strategies) {
    return s.getAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED);
  }

  function getActiveStrategiesInternal(IStore s) external view returns (address[] memory strategies) {
    return s.getAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IUniswapV2RouterLike {
  function factory() external view returns (address);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IUniswapV2PairLike {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function totalSupply() external view returns (uint256);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IUniswapV2FactoryLike {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}