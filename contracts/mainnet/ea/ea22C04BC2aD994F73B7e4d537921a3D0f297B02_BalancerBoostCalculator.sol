// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "../third_party/curve/IVotingEscrow.sol";
import "../third_party/curve/IGauge.sol";
import "../openzeppelin/IERC20.sol";
import "../base/interface/ISmartVault.sol";
import "../base/interface/IStrategy.sol";

interface IBalancerStrategy {
  function gauge() external view returns (address);
}

contract BalancerBoostCalculator {

  address internal constant BAL_LOCKER = 0x9cC56Fa7734DA21aC88F6a816aF10C5b898596Ce;
  address internal constant VE_BAL = 0xC128a9954e6c874eA3d62ce62B468bA073093F25;
  address internal constant BAL_TOKEN = 0xba100000625a3754423978a60c9317c58a424e3D;


  function getBalancerBoostInfo(address vault) external view returns (
    uint derivedBalanceBoost,
    uint ableToBoost,
    uint gaugeBalance
  ) {
    if (block.chainid != 1) {
      return (0, 0, 0);
    }

    address strategy = ISmartVault(vault).strategy();

    if (IStrategy(strategy).platform() != IStrategy.Platform.BALANCER) {
      return (0, 0, 0);
    }

    address gauge = IBalancerStrategy(strategy).gauge();

    IVotingEscrow ve = IVotingEscrow(VE_BAL);
    uint veBalance = ve.balanceOf(BAL_LOCKER);
    uint veTotalSupply = ve.totalSupply();

    gaugeBalance = IERC20(gauge).balanceOf(BAL_LOCKER);
    uint gaugeBalanceBase = gaugeBalance * 4 / 10;
    uint gaugeTotalSupply = IERC20(gauge).totalSupply();

    uint bonusBalance = gaugeTotalSupply * veBalance / veTotalSupply * 6 / 10;

    uint gaugeDerivedBalance = gaugeBalance;
    ableToBoost = 0;
    if (gaugeBalanceBase + bonusBalance < gaugeBalance) {
      gaugeDerivedBalance = gaugeBalanceBase + bonusBalance;
    } else {
      ableToBoost = (gaugeBalanceBase + bonusBalance) - gaugeBalance;
    }

    derivedBalanceBoost = gaugeDerivedBalance * 1e18 / gaugeBalanceBase;
  }

}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

interface IVotingEscrow {

  struct Point {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts;
    uint256 blk; // block
  }

  function balanceOf(address addr) external view returns (uint);

  function balanceOfAt(address addr, uint block_) external view returns (uint);

  function totalSupply() external view returns (uint);

  function totalSupplyAt(uint block_) external view returns (uint);

  function locked(address user) external view returns (uint amount, uint end);

  function create_lock(uint value, uint unlock_time) external;

  function increase_amount(uint value) external;

  function increase_unlock_time(uint unlock_time) external;

  function withdraw() external;

  function commit_smart_wallet_checker(address addr) external;

  function apply_smart_wallet_checker() external;

  function user_point_history(address user, uint256 timestamp) external view returns (Point memory);

  function user_point_epoch(address user) external view returns (uint256);

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IGauge {

  struct Reward {
    address token;
    address distributor;
    uint256 period_finish;
    uint256 rate;
    uint256 last_update;
    uint256 integral;
  }

  /// @notice Deposit `_value` LP tokens
  /// @dev Depositting also claims pending reward tokens
  /// @param _value Number of tokens to deposit
  function deposit(uint _value) external;

  function deposit(uint _value, address receiver, bool claim) external;

  /// @notice Get the number of claimable reward tokens for a user
  /// @dev This call does not consider pending claimable amount in `reward_contract`.
  ///      Off-chain callers should instead use `claimable_rewards_write` as a
  ///      view method.
  /// @param _addr Account to get reward amount for
  /// @param _token Token to get reward amount for
  /// @return uint256 Claimable reward token amount
  function claimable_reward(address _addr, address _token) external view returns (uint256);

  /// @notice Get the number of already-claimed reward tokens for a user
  /// @param _addr Account to get reward amount for
  /// @param _token Token to get reward amount for
  /// @return uint256 Total amount of `_token` already claimed by `_addr`
  function claimed_reward(address _addr, address _token) external view returns (uint256);

  /// @notice Get the number of claimable reward tokens for a user
  /// @dev This function should be manually changed to "view" in the ABI
  ///     Calling it via a transaction will claim available reward tokens
  /// @param _addr Account to get reward amount for
  /// @param _token Token to get reward amount for
  /// @return uint256 Claimable reward token amount
  function claimable_reward_write(address _addr, address _token) external returns (uint256);

  /// @notice Withdraw `_value` LP tokens
  /// @dev Withdrawing also claims pending reward tokens
  /// @param _value Number of tokens to withdraw
  function withdraw(uint _value, bool) external;

  function claim_rewards(address _addr) external;

  function claim_rewards(address _addr, address receiver) external;

  function balanceOf(address) external view returns (uint);

  function lp_token() external view returns (address);

  function deposit_reward_token(address reward_token, uint256 amount) external;

  function add_reward(address reward_token, address distributor) external;

  function reward_tokens(uint id) external view returns (address);

  function reward_data(address token) external view returns (Reward memory);

  function reward_count() external view returns (uint);

  function working_supply() external view returns (uint);

  function initialize(address lp) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface ISmartVault {

  function DEPOSIT_FEE_DENOMINATOR() external view returns (uint256);

  function LOCK_PENALTY_DENOMINATOR() external view returns (uint256);

  function TO_INVEST_DENOMINATOR() external view returns (uint256);

  function VERSION() external view returns (string memory);

  function active() external view returns (bool);

  function addRewardToken(address rt) external;

  function alwaysInvest() external view returns (bool);

  function availableToInvestOut() external view returns (uint256);

  function changeActivityStatus(bool _active) external;

  function changeAlwaysInvest(bool _active) external;

  function changeDoHardWorkOnInvest(bool _active) external;

  function changePpfsDecreaseAllowed(bool _value) external;

  function changeProtectionMode(bool _active) external;

  function deposit(uint256 amount) external;

  function depositAndInvest(uint256 amount) external;

  function depositFeeNumerator() external view returns (uint256);

  function depositFor(uint256 amount, address holder) external;

  function disableLock() external;

  function doHardWork() external;

  function doHardWorkOnInvest() external view returns (bool);

  function duration() external view returns (uint256);

  function earned(address rt, address account)
  external
  view
  returns (uint256);

  function earnedWithBoost(address rt, address account)
  external
  view
  returns (uint256);

  function exit() external;

  function getAllRewards() external;

  function getAllRewardsAndRedirect(address owner) external;

  function getPricePerFullShare() external view returns (uint256);

  function getReward(address rt) external;

  function getRewardTokenIndex(address rt) external view returns (uint256);

  function initializeSmartVault(
    string memory _name,
    string memory _symbol,
    address _controller,
    address __underlying,
    uint256 _duration,
    bool _lockAllowed,
    address _rewardToken,
    uint256 _depositFee
  ) external;

  function lastTimeRewardApplicable(address rt)
  external
  view
  returns (uint256);

  function lastUpdateTimeForToken(address) external view returns (uint256);

  function lockAllowed() external view returns (bool);

  function lockPenalty() external view returns (uint256);

  function notifyRewardWithoutPeriodChange(
    address _rewardToken,
    uint256 _amount
  ) external;

  function notifyTargetRewardAmount(address _rewardToken, uint256 amount)
  external;

  function overrideName(string memory value) external;

  function overrideSymbol(string memory value) external;

  function periodFinishForToken(address) external view returns (uint256);

  function ppfsDecreaseAllowed() external view returns (bool);

  function protectionMode() external view returns (bool);

  function rebalance() external;

  function removeRewardToken(address rt) external;

  function rewardPerToken(address rt) external view returns (uint256);

  function rewardPerTokenStoredForToken(address)
  external
  view
  returns (uint256);

  function rewardRateForToken(address) external view returns (uint256);

  function rewardTokens() external view returns (address[] memory);

  function rewardTokensLength() external view returns (uint256);

  function rewardsForToken(address, address) external view returns (uint256);

  function setLockPenalty(uint256 _value) external;

  function setRewardsRedirect(address owner, address receiver) external;

  function setLockPeriod(uint256 _value) external;

  function setStrategy(address newStrategy) external;

  function setToInvest(uint256 _value) external;

  function stop() external;

  function strategy() external view returns (address);

  function toInvest() external view returns (uint256);

  function underlying() external view returns (address);

  function underlyingBalanceInVault() external view returns (uint256);

  function underlyingBalanceWithInvestment() external view returns (uint256);

  function underlyingBalanceWithInvestmentForHolder(address holder)
  external
  view
  returns (uint256);

  function underlyingUnit() external view returns (uint256);

  function userBoostTs(address) external view returns (uint256);

  function userLastDepositTs(address) external view returns (uint256);

  function userLastWithdrawTs(address) external view returns (uint256);

  function userLockTs(address) external view returns (uint256);

  function userRewardPerTokenPaidForToken(address, address)
  external
  view
  returns (uint256);

  function withdraw(uint256 numberOfShares) external;

  function withdrawAllToVault() external;

  function getAllRewardsFor(address rewardsReceiver) external;

  function lockPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IStrategy {

  enum Platform {
    UNKNOWN, // 0
    TETU, // 1
    QUICK, // 2
    SUSHI, // 3
    WAULT, // 4
    IRON, // 5
    COSMIC, // 6
    CURVE, // 7
    DINO, // 8
    IRON_LEND, // 9
    HERMES, // 10
    CAFE, // 11
    TETU_SWAP, // 12
    SPOOKY, // 13
    AAVE_LEND, //14
    AAVE_MAI_BAL, // 15
    GEIST, //16
    HARVEST, //17
    SCREAM_LEND, //18
    KLIMA, //19
    VESQ, //20
    QIDAO, //21
    SUNFLOWER, //22
    NACHO, //23
    STRATEGY_SPLITTER, //24
    TOMB, //25
    TAROT, //26
    BEETHOVEN, //27
    IMPERMAX, //28
    TETU_SF, //29
    ALPACA, //30
    MARKET, //31
    UNIVERSE, //32
    MAI_BAL, //33
    UMA, //34
    SPHERE, //35
    BALANCER, //36
    OTTERCLAM, //37
    MESH, //38
    D_FORCE, //39
    DYSTOPIA, //40
    CONE, //41
    SLOT_42, //42
    SLOT_43, //43
    SLOT_44, //44
    SLOT_45, //45
    SLOT_46, //46
    SLOT_47, //47
    SLOT_48, //48
    SLOT_49, //49
    SLOT_50 //50
  }

  // *************** GOVERNANCE ACTIONS **************
  function STRATEGY_NAME() external view returns (string memory);

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function salvage(address recipient, address token, uint256 amount) external;

  function doHardWork() external;

  function investAllUnderlying() external;

  function emergencyExit() external;

  function pauseInvesting() external;

  function continueInvesting() external;

  // **************** VIEWS ***************
  function rewardTokens() external view returns (address[] memory);

  function underlying() external view returns (address);

  function underlyingBalance() external view returns (uint256);

  function rewardPoolBalance() external view returns (uint256);

  function buyBackRatio() external view returns (uint256);

  function unsalvageableTokens(address token) external view returns (bool);

  function vault() external view returns (address);

  function investedUnderlyingBalance() external view returns (uint256);

  function platform() external view returns (Platform);

  function assets() external view returns (address[] memory);

  function pausedInvesting() external view returns (bool);

  function readyToClaim() external view returns (uint256[] memory);

  function poolTotalAmount() external view returns (uint256);
}