// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import { IDepositToken, IBALRewardPool, AssetData } from "./interfaces/interfaces.sol";
import { IBalancerMinter } from "./interfaces/IBalancerMinter.sol";
import { IBalancerGauge } from "./interfaces/IBalancerGauge.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { DepositToken } from "./DepositToken.sol";
import { BALRewardPool } from "./BALRewardPool.sol";

/**
 * @title StakingRewards
 * @author Planetarium
 * @notice Contract to stake BPT and get rewards 
 */
contract StakingRewards is Initializable {
  using SafeMath for uint128;
  using SafeMath for uint256;  
  using SafeERC20Upgradeable for IERC20Upgradeable;
  
  /// @notice Token to stake (LP Token)
  IERC20Upgradeable public STAKED_TOKEN;

  /// @notice Token for rewards
  IERC20Upgradeable public REWARD_TOKEN;
      
  /// @notice Seconds for cooldown period
  uint128 public COOLDOWN_SECONDS;

  /// @notice Seconds available to redeem onece the cooldown period is fullfilled
  uint128 public UNSTAKE_WINDOW;

  /// @notice Address to pull the rewards for this contract
  address public REWARDS_VAULT;

  /// @notice Address for bal operation
  address public BAL_OPERATION_VAULT;

  uint128 private constant THREE_DAYS = 3 days;
  uint128 private constant TWO_WEEKS = 14 days;
  uint8 private constant PRECISION = 18;

  /// @notice Rewards to claim for each accounts
  mapping(address => uint256) public rewardsToClaim;  

  /// @notice Cooldowns for each accounts
  mapping(address => uint256) public cooldowns;

  /// @dev Balances for each accounts
  mapping(address => uint256) private balances;

  /// @dev Total Staked Amount
  uint private totalSupply;

  /// @dev Asset Data
  AssetData private assetData;

  /// @notice Operator who can manage configuration of this contract.
  address public OPERATOR;

  /// @notice Balancer token
  IERC20Upgradeable public BAL;
  
  /// @notice Balancer Pool Token Gauge.
  IBalancerGauge public balancerGauge;

  /// @notice Balancer Token Minter
  address public balancerMinter;

  /// @notice Incentive to users who spend gas to make earmark calls to harvest BAL rewards
  uint128 public earmarkIncentive; // 100 means 1%

  /// @notice Operation fee
  uint128 public operationFee; // 1900 means 19%

  /// @notice Operation fee max
  uint128 public constant operationFeeMax = 3000;

  /// @notice Earmark incentive fee max 
  uint128 public constant earmarkIncentiveMax = 300;
  
  /// @dev Fee denominator
  uint128 public constant FEE_DENOMINATOR = 10000;

  /// @dev Deposit token that will be deposited for BAL Reward pool
  address public DEPOSIT_TOKEN_ADDR;

  /// @notice Address of BAL Reward pool
  address public BAL_REWARD_POOL;

  /// @notice To pause staking
  bool public PAUSE_STAKING;

  /// @notice Use Bal Reward Pool or not
  bool public USE_BAL_REWARD_POOL;

  /* ========== EVENTS ========== */
  event FeesUpdated(uint128 _earmarkIncentive, uint128 _operationFee);
  event EmissionPerSecondUpdated(uint128 _emissionPerSecond);
  event CooldownSecondAndUnstakeWindowUpdated(uint128 _cooldownSeconds, uint128 _unstakeWindow);
  event OperatorChanged(address indexed _from, address indexed _to);
  event RewardsVaultChanged(address indexed _rewardsVault);
  event BalOperationVaultChanged(address indexed _balOperationVault);  
  event BalRewardPoolConfigured(
    address indexed _depositToken,
    address indexed _balRewardPool,
    address indexed _balGauge
  );
  event Staked(address indexed _user, uint256 _amount);
  event RewardsClaimedAll(address indexed _to);
  event RewardsClaimed_TOKEN(address indexed _to, uint256 _amount);
  event RewardsClaimed_BAL(address indexed _to, uint256 _amount);
  event RewardsAccrued(address _user, uint256 _amount);
  event UserIndexUpdated(address indexed _user, uint256 _index);
  event AssetIndexUpdated(uint256 _index);
  event Cooldown(address indexed _user);
  event Withdrawn(address indexed _user, uint256 _amount);
  event Balancer_Gauge_Staked(address indexed _user, uint256 _amount);
  event Balancer_Gauge_Unstaked(address indexed _user, uint256 _amount);
  event BALRewardPool_Staked(address indexed _user, uint256 _amount);
  event BALRewardPool_Unstaked(address indexed _user, uint256 _amount);
  event TransferredStakedBalanceToBalRewardPool(address indexed _user, uint256 _amount);
  event EarmarkRewards(address indexed _user, uint256 _balReward);
  event PauseStakingUpdated(bool _pauseStaking);
  event UseBalRewardPoolUpdated(bool _useBalRewardPool);
 
  /* ========== INITIALIZE ========== */
  function initialize(
    IERC20Upgradeable _stakedToken,
    IERC20Upgradeable _rewardToken,
    address _operator,
    address _rewardsVault,
    address _balOperationVault,      
    IERC20Upgradeable _balToken,
    address _balancerMinter
  ) external initializer {
    STAKED_TOKEN = _stakedToken;
    REWARD_TOKEN = _rewardToken;
    OPERATOR = _operator;
    REWARDS_VAULT = _rewardsVault;
    BAL_OPERATION_VAULT = _balOperationVault;    
    BAL = _balToken;
    balancerMinter = _balancerMinter;

    COOLDOWN_SECONDS = TWO_WEEKS;
    UNSTAKE_WINDOW = THREE_DAYS;
    PAUSE_STAKING = false;
    USE_BAL_REWARD_POOL = false;

    assetData.emissionPerSecond = 0;
    earmarkIncentive = 100;
    operationFee = 1900; 

  }

  modifier onlyOperator {
    require(msg.sender == OPERATOR, 'ONLY_OPERATOR');
    _;
  }

  /**
   * @dev Config deposit token, bal reward pool and bal gauge
   * @param _depositToken deposit token address
   * @param _balRewardPool bal reward pool address
   * @param _balGauge bal gauge address
   */ 
  function enableBalRewardPool(
    address _depositToken,
    address _balRewardPool,
    address _balGauge
  ) external onlyOperator {
     require(!useBalRewardPool(), "!alreadyEnabled");
     require(_depositToken != address(0) && _balRewardPool != address(0) && _balGauge != address(0), "!badParameter");

    DEPOSIT_TOKEN_ADDR = _depositToken;
    BAL_REWARD_POOL = _balRewardPool;
    balancerGauge = IBalancerGauge(_balGauge);
    USE_BAL_REWARD_POOL = true;

    // Staked Token contract that approves the Balancer Pool Gauge to transfer the staking token.
    STAKED_TOKEN.safeApprove(_balGauge, type(uint256).max);

    emit BalRewardPoolConfigured(
      _depositToken,
      _balRewardPool,
      _balGauge
    );
  }

  /**
   * @dev Config emission per second
   * @param _emissionPerSecond rate for rewards
   */ 
  function configEmissionPerSecond(
    uint128 _emissionPerSecond
  ) external onlyOperator {

    assetData.emissionPerSecond = _emissionPerSecond;

    emit EmissionPerSecondUpdated(_emissionPerSecond);
  }

  /**
   * @dev Config Cooldown Seconds and Unstake Window
   * @param _cooldownSeconds  Cooldown period in seconds
   * @param _unstakeWindow    Unstake(withdraw) window in seconds
   */ 
  function configCooldownSecondAndUnstakeWindow(
    uint128 _cooldownSeconds,
    uint128 _unstakeWindow
  ) external onlyOperator {
    require(_cooldownSeconds > 0, "!cooldownSeconds");
    require(_unstakeWindow > 0, "!unstakeWindow");

    COOLDOWN_SECONDS = _cooldownSeconds;
    UNSTAKE_WINDOW = _unstakeWindow;
    
    emit CooldownSecondAndUnstakeWindowUpdated(_cooldownSeconds, _unstakeWindow);
  }

  /**
   * @dev Config earmark incentive and operation fees
   * @param _earmarkIncentive Earmark incentive
   * @param _operationFee     Operation fee
   */ 
  function configFees(
    uint128 _earmarkIncentive,
    uint128 _operationFee
  ) external onlyOperator {
    require(_earmarkIncentive >= 0 && _earmarkIncentive <= earmarkIncentiveMax, "!earmarkIncentive");
    require(_operationFee >= 0 && _operationFee <= operationFeeMax, "!operationFee");

    earmarkIncentive = _earmarkIncentive;
    operationFee = _operationFee;

    emit FeesUpdated(_earmarkIncentive, _operationFee);
  }

  /**
   * @dev Change Operator
   * @param _to new opertor address
   */ 
  function changeOperator(
    address _to
  ) external onlyOperator {
    OPERATOR = _to;
    emit OperatorChanged(msg.sender, _to);
  }

  /**
   * @dev Change Rewards Vault
   * @param _rewardsVault new rewards vault
   */ 
  function changeRewardsVault(
    address _rewardsVault
  ) external onlyOperator {
    REWARDS_VAULT = _rewardsVault;
    emit RewardsVaultChanged(_rewardsVault);
  }

  /**
   * @dev Change BAL Operation Vault
   * @param _balOperationVault new BAL Operation vault
   */ 
  function changeBalOperationVault(
    address _balOperationVault
  ) external onlyOperator {
    BAL_OPERATION_VAULT = _balOperationVault;
    emit BalOperationVaultChanged(_balOperationVault);
  }

  /**
   * @dev To change PAUSE_STAKING boolean value
   * @param _pauseStaking boolean value to pause staking
   */
  function changePauseStaking(
    bool _pauseStaking
  ) external onlyOperator {
    PAUSE_STAKING = _pauseStaking;
    emit PauseStakingUpdated(_pauseStaking);
  }

  /**
   * @dev Stake tokens, and earn rewards
   * @param _amount Amount to stake
   */  
  function stake(uint256 _amount) external {
    require(!PAUSE_STAKING, 'STAKING_PAUSED');
    require(_amount != 0, 'INVALID_ZERO_AMOUNT');

    uint256 accruedRewards = updateUserAssetInternal(msg.sender, balances[msg.sender]);
    if (accruedRewards != 0) {
      rewardsToClaim[msg.sender] = rewardsToClaim[msg.sender].add(accruedRewards);
      emit RewardsAccrued(msg.sender, accruedRewards);
    }
    
    cooldowns[msg.sender] = getNextCooldownTimestamp(0, _amount, msg.sender, balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].add(_amount);
    totalSupply = totalSupply.add(_amount);

    // transfer staked token to this contract
    IERC20Upgradeable(STAKED_TOKEN).safeTransferFrom(msg.sender, address(this), _amount);
    emit Staked(msg.sender, _amount);

    if (useBalRewardPool()) {
      // deposit token to the Balancer Gauge.
      balancerGauge.deposit(_amount);
      emit Balancer_Gauge_Staked(msg.sender, _amount);

      // deposit token to bal reward pool
      stakeToBalRewardPool(_amount);
      emit BALRewardPool_Staked(msg.sender, _amount);
    }
  }

  /**
   * @dev Transfer previously staked balances to Bal Reward Pool if applicable
   */
  function transferStakedBalanceToBalRewardPool() public {
    require(useBalRewardPool(), '!BAL_REWARD_POOL');
    require(balances[msg.sender] > 0, 'NOT_ENOUGH_BALANCE');

    uint256 amount = transferableBalanceToBalRewardPool(msg.sender);
    require(amount > 0, 'INVALID_BALANCE_TO_TRANSFER');

    // deposit token to the Balancer Gauge.
    balancerGauge.deposit(amount);

    // deposit token to bal reward pool
    stakeToBalRewardPool(amount);

    emit TransferredStakedBalanceToBalRewardPool(msg.sender, amount);
  }

  /**
   * @dev Withdraw staked tokens, and stop earning rewards
   * @param _amount Amount to withdraw
   * @param _isClaimAllRewards if true, it claims all rewards accumulated
   */
  function withdraw(uint256 _amount, bool _isClaimAllRewards) external returns (bool) {
    require(_amount != 0, 'INVALID_ZERO_AMOUNT');
    require(balances[msg.sender] > 0, 'NOT_ENOUGH_BALANCE');

    if (useBalRewardPool()) {
      if (transferableBalanceToBalRewardPool(msg.sender) > 0) {
        transferStakedBalanceToBalRewardPool();
      }
    }
    
    uint256 cooldownStartTimestamp = cooldowns[msg.sender];
    uint256 cooldownEndTimestamp = cooldownStartTimestamp.add(COOLDOWN_SECONDS);
    
    require(block.timestamp > cooldownEndTimestamp, 'INSUFFICIENT_COOLDOWN');    
    require(block.timestamp.sub(cooldownEndTimestamp) <= UNSTAKE_WINDOW, 'UNSTAKE_WINDOW_FINISHED');
     
    uint256 amountToWithdraw = (_amount > balances[msg.sender]) ? balances[msg.sender] : _amount;

    updateCurrentUnclaimedRewards(msg.sender, balances[msg.sender], true);
    
    balances[msg.sender] = balances[msg.sender].sub(amountToWithdraw);
    totalSupply = totalSupply.sub(amountToWithdraw);

    if (balances[msg.sender] == 0) {
      cooldowns[msg.sender] = 0;
    }

    if (useBalRewardPool()) {
      // withdraw deposit token from bal reward pool
      withdrawFromBalRewardPool(amountToWithdraw);
      emit BALRewardPool_Unstaked(msg.sender, amountToWithdraw);

      // unstake from the Balancer Gauge
      balancerGauge.withdraw(amountToWithdraw);
      emit Balancer_Gauge_Unstaked(address(this), amountToWithdraw);
    }

    // transfer staked token to the user
    IERC20Upgradeable(STAKED_TOKEN).safeTransfer(msg.sender, amountToWithdraw);
    emit Withdrawn(msg.sender, amountToWithdraw);

    // claim all rewards if true
    if(_isClaimAllRewards) {
      claimAllRewards();
    }
    
    return true;
  }

  /**
   * @dev Calculates new cooldown timestamp depending on the sender/receiver situation
   *  - If the timestamp of the sender is "better" or the timestamp of the recipient is 0, we take the one of the recipient
   *  - Weighted average of from/to cooldown timestamps if:
   *    # The sender doesn't have the cooldown activated (timestamp 0).
   *    # The sender timestamp is expired
   *    # The sender has a "worse" timestamp
   *  - If the receiver's cooldown timestamp expired (too old), the next is 0
   * @param _fromCooldownTimestamp Cooldown timestamp of the sender
   * @param _amountToReceive Amount
   * @param _toAddress Address of the recipient
   * @param _toBalance Current balance of the receiver
   * @return The new cooldown timestamp
   */
  function getNextCooldownTimestamp(
    uint256 _fromCooldownTimestamp,
    uint256 _amountToReceive,
    address _toAddress,
    uint256 _toBalance
  ) public view returns (uint256) {
    uint256 toCooldownTimestamp = cooldowns[_toAddress];
    if (toCooldownTimestamp == 0) {
      return 0;
    }

    uint256 minimalValidCooldownTimestamp = block.timestamp.sub(COOLDOWN_SECONDS).sub(UNSTAKE_WINDOW);

    if (minimalValidCooldownTimestamp > toCooldownTimestamp) {
      toCooldownTimestamp = 0;
    } else {
      uint256 timestamp = 
        (minimalValidCooldownTimestamp > _fromCooldownTimestamp)
          ? block.timestamp
          : _fromCooldownTimestamp;

      if (timestamp < toCooldownTimestamp) {
        return toCooldownTimestamp;
      } else {
        toCooldownTimestamp = (
          _amountToReceive.mul(timestamp).add(_toBalance.mul(toCooldownTimestamp))
          ).div(_amountToReceive.add(_toBalance));
      }
    }
    return toCooldownTimestamp;
  }   

  /**
   * @dev Activates the cooldown period to unstake
   * - It can't be called if the user is not staking
   */
  function cooldown() external {
    require(balances[msg.sender] != 0, 'INVALID_BALANCE_ON_COOLDOWN');    

    cooldowns[msg.sender] = block.timestamp;

    emit Cooldown(msg.sender);
  }

  /**
   * @dev Claim Reward Token
   * @param _amount Amount to receive. If the amount is uint256.max vaule, receive all Rewards accumulated
   */
  function claimTokenRewards(uint256 _amount) public {
    uint256 newTotalRewards = updateCurrentUnclaimedRewards(msg.sender, balances[msg.sender], false);
    uint256 amountToClaim = (_amount == type(uint256).max) ? newTotalRewards : _amount;
    
    rewardsToClaim[msg.sender] = newTotalRewards.sub(amountToClaim, 'INVALID_AMOUNT');
    REWARD_TOKEN.safeTransferFrom(REWARDS_VAULT, msg.sender, amountToClaim);

    emit RewardsClaimed_TOKEN(msg.sender, amountToClaim);
  }

  /**
   * @dev Claim BAL Rewards (all BAL rewards from the BAL Reward Pool)
   */
  function claimBALRewards() public {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');

    uint256 amountToClaim = IBALRewardPool(BAL_REWARD_POOL).earned(msg.sender);
    IBALRewardPool(BAL_REWARD_POOL).getReward(msg.sender);
    emit RewardsClaimed_BAL(msg.sender, amountToClaim);
  }

  /**
   * @dev Claim Token Rewards and BAL Rewards
   */
  function claimAllRewards() public {    
    claimTokenRewards(type(uint256).max);
    if (useBalRewardPool()) {
      claimBALRewards();
    }
    emit RewardsClaimedAll(msg.sender);
  }

  /**
   * @dev Stake Deposit Token to BAL_REWARD_POOL
   * @param _amount amount to stake
   */
  function stakeToBalRewardPool(uint256 _amount) internal {
    require(DEPOSIT_TOKEN_ADDR != address(0), 'INVALID_DEPOSIT_TOKEN_ADDR');
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');

    // mint deposit token and stake deposit token to Bal Reward Pool for the user
    IDepositToken(DEPOSIT_TOKEN_ADDR).mint(address(this), _amount);
    IERC20Upgradeable(DEPOSIT_TOKEN_ADDR).safeApprove(BAL_REWARD_POOL, _amount);
    IBALRewardPool(BAL_REWARD_POOL).stakeFor(msg.sender, _amount);
  }

  /**
   * @dev Withdraw Deposit Token from BAL_REWARD_POOL
   * @param _amount amount to withdraw
   */
  function withdrawFromBalRewardPool(uint256 _amount) internal {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');
    require(DEPOSIT_TOKEN_ADDR != address(0), 'INVALID_DEPOSIT_TOKEN_ADDR');

    // burn deposit token and withdraw for the user
    IBALRewardPool(BAL_REWARD_POOL).withdrawFor(msg.sender, _amount);
    IDepositToken(DEPOSIT_TOKEN_ADDR).burn(address(this), _amount);
  }

  /**
   * @dev Updates current unclaimed rewards
   * @param _user Address of the user
   * @param _userBalance The current balance of the user
   * @param _updateStorage Boolean flag used to update or not for rewardsToclaim of the user
   * @return The unclaimed rewards that were added to the total accrued
   */
  function updateCurrentUnclaimedRewards(
    address _user,
    uint256 _userBalance,
    bool _updateStorage
  ) internal returns (uint256) {
    uint256 accruedRewards = updateUserAssetInternal(_user, _userBalance);
    uint256 unclaimedRewards = rewardsToClaim[_user].add(accruedRewards);

    if (accruedRewards != 0) {
      if (_updateStorage) {
        rewardsToClaim[_user] = unclaimedRewards;
      }
      emit RewardsAccrued(_user, accruedRewards);
    }

    return unclaimedRewards;
  }

  /**
   * @dev Updates the state of an user in a distribution
   * @param _user The user's address
   * @param _stakedAmountByUser Amount of tokens staked by the user in the distribution at the moment
   * @return The accrued rewards for the user until the moment
   */
  function updateUserAssetInternal(
    address _user,
    uint256 _stakedAmountByUser
  ) internal returns (uint256) {
    uint256 userIndex = assetData.users[_user];
    uint256 accruedRewards = 0;

    uint256 newIndex = updateAssetStateInternal();

    if (userIndex != newIndex) {
      if (_stakedAmountByUser != 0) {
        accruedRewards = getRewards(_stakedAmountByUser, newIndex, userIndex);
      }

      assetData.users[_user] = newIndex;
      emit UserIndexUpdated(_user, newIndex);
    }

    return accruedRewards;
  }

  /**
   * @dev Updates the state of one distribution, mainly rewards index and timestamp
   * @return The new distribution index
   */
  function updateAssetStateInternal() internal returns (uint256) {
    uint256 oldIndex = assetData.index;
    uint128 lastUpdateTimestamp = assetData.lastUpdateTimestamp;

    if (block.timestamp == lastUpdateTimestamp) {
      return oldIndex;
    }

    uint256 newIndex = getAssetIndex(oldIndex, assetData.emissionPerSecond, lastUpdateTimestamp);

    if (newIndex != oldIndex) {
      assetData.index = newIndex;
      emit AssetIndexUpdated(newIndex);
    }

    assetData.lastUpdateTimestamp = SafeCast.toUint128(block.timestamp);

    return newIndex;
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param _currentIndex Current index of the distribution
   * @param _emissionPerSecond Representing the total rewards distributed per second per asset unit, on the distribution
   * @param _lastUpdateTimestamp Last moment this distribution was updated
   * @return The new index.
   */
  function getAssetIndex(
    uint256 _currentIndex,
    uint256 _emissionPerSecond,
    uint128 _lastUpdateTimestamp
  ) internal view returns (uint256) {
    uint256 currentTimestamp = block.timestamp;
    if (
      _emissionPerSecond == 0 ||
      totalSupply == 0 ||
      _lastUpdateTimestamp == currentTimestamp
    ) {
      return _currentIndex;
    }
    
    uint256 timeDelta = currentTimestamp.sub(_lastUpdateTimestamp);
    return _emissionPerSecond.mul(timeDelta).mul(10**uint256(PRECISION)).div(totalSupply).add(_currentIndex);
  }

  /**
   * @dev Internal function for the calculation of user's rewards on a distribution
   * @param _principalUserBalance Amount staked by the user on a distribution
   * @param _reserveIndex Current index of the distribution
   * @param _userIndex Index stored for the user, representation his staking moment
   * @return The rewards
   */
  function getRewards(
    uint256 _principalUserBalance,
    uint256 _reserveIndex,
    uint256 _userIndex
  ) internal pure returns (uint256) {
    return _principalUserBalance.mul(_reserveIndex.sub(_userIndex)).div(10**uint256(PRECISION));
  }

  /**
   * @dev Return the accrued rewards for an user over a list of distribution
   * @param _user The address of the user
   * @return The accrued rewards for the user until the moment
   */
  function getUnclaimedRewards(
    address _user
  ) internal view returns (uint256) {
    uint256 accruedRewards = 0;
    uint256 assetIndex = getAssetIndex(assetData.index, assetData.emissionPerSecond, assetData.lastUpdateTimestamp);
    accruedRewards = accruedRewards.add(getRewards(balances[msg.sender], assetIndex, assetData.users[_user]));
    return accruedRewards;
  }

  /**
   * @dev Earmark Rewards 
   */
  function earmarkRewards() external returns (bool){
    require(useBalRewardPool(), '!BAL_REWARD_POOL');
    _earmarkRewards();
    return true;
  }
  
  /**
   * @dev Earmark Rewards, incentivise the user who spend gas to make earmark calls to harvest BAL Rewards
   *      Resposible for collecting the BAL from Gauge, and re-distributing to the correct place.
   */
  function _earmarkRewards() internal {
    IBalancerMinter(balancerMinter).mint(address(balancerGauge));
    
    uint256 balReward = IERC20Upgradeable(BAL).balanceOf(address(this));

    if (balReward > 0) {
      // CallIncentive = caller of this contract
      uint256 _callIncentive = balReward.mul(earmarkIncentive).div(FEE_DENOMINATOR);

      // deal with operation fee
      uint256 fee = balReward.mul(operationFee).div(FEE_DENOMINATOR);
      balReward = balReward.sub(fee);

      // send oepration fee to BAL operation vault
      IERC20Upgradeable(BAL).safeTransfer(BAL_OPERATION_VAULT, fee);

      // remove incentives from balance
      balReward = balReward.sub(_callIncentive);

      // send BAL incentive to the user
      IERC20Upgradeable(BAL).safeTransfer(msg.sender, _callIncentive);

      // send BAL to BAL reward pool contract
      IERC20Upgradeable(BAL).safeTransfer(BAL_REWARD_POOL, balReward);

      // queue new rewards
      IBALRewardPool(BAL_REWARD_POOL).queueNewRewards(balReward);
    }

    emit EarmarkRewards(msg.sender, balReward);
  }

  /**
   * @dev Processes queued rewards in BAL Reward Pool
   */
  function processIdleRewards() external {
    require(useBalRewardPool(), '!BAL_REWARD_POOL');

    IBALRewardPool(BAL_REWARD_POOL).processIdleRewards();
  }

  /* ========== EXTERNAL VIEWS ========== */

  /**
   * @dev Return earned Rewards Token of the user
   */
  function earnedTokenRewards(address _user) external view returns (uint256) {
    return rewardsToClaim[_user].add(getUnclaimedRewards(_user));
  }

  /**
   * @dev Return earned BAL of the user
   */
  function earnedBALRewards(address _user) external view returns (uint256) {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');

    return IBALRewardPool(BAL_REWARD_POOL).earned(_user);
  }

  /**
   * @dev Return total staked amount for this contact
   */
  function totalStaked() external view returns (uint256) {
    return totalSupply;
  }

  /**
   * @dev Return user's staked amount
   */
  function stakedTokenBalance(address _user) external view returns (uint256) {
    return balances[_user];
  }

  /**
   * @dev Get emission per second value
   */
  function getEmissionPerSec() external view returns (uint256) {
    return assetData.emissionPerSecond;
  }

  /**
   * @dev Get BAL Reward rate from the BAL Reward Pool
   */
  function getBALRewardRate() external view returns (uint256) {
    require(BAL_REWARD_POOL != address(0), 'INVALID_BAL_REWARD_POOL');

    return IBALRewardPool(BAL_REWARD_POOL).getRewardRate();
  }

  /**
   * @dev Get current block timestamp
   */
  function getCurrentBlockTimestamp() external view returns (uint256) {
    return block.timestamp;
  }

  /**
   * @dev Get cooldown end timestamp
   */
  function getCooldownEndTimestamp(address _user) external view returns (uint256) {    
    return cooldowns[_user].add(COOLDOWN_SECONDS);
  }

  /**
   * @dev Get withdraw end timestamp
   */
  function getWithdrawEndTimestamp(address _user) external view returns (uint256) {    
    return cooldowns[_user].add(COOLDOWN_SECONDS).add(UNSTAKE_WINDOW);
  }

  /**
   * @dev check BAL Reward Pool is being used or not
   */
  function useBalRewardPool() internal view returns (bool) {
    return USE_BAL_REWARD_POOL;
  }

  /**
   * @dev User's staked balance and BAL_REWARD_POOL balance difference
   */
  function transferableBalanceToBalRewardPool(address _user) internal view returns (uint256) {
    return balances[_user].sub(IBALRewardPool(BAL_REWARD_POOL).balanceOf(_user));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DepositToken is ERC20 {
    using SafeERC20 for IERC20;
    address public operator;
    
    constructor(address _operator) ERC20("dep-20WETH-80WNCG", "dep-20WETH-80WNCG") {
        operator =  _operator;
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");        
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");        
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @dev Balancer Minter to retrieve BAL Reward from Balancer
 */
interface IBalancerMinter{
    function mint(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import "./interfaces/interfaces.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title   BALRewardPool
 * @author  Synthetix -> ConvexFinance -> Planetarium
 * @dev     BAL is queued for rewards and the distribution only begins once the new rewards are sufficiently
            large, or the epoch has ended.
 */
contract BALRewardPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    IERC20 public immutable stakingToken;
    uint256 public constant duration = 7 days;

    address public immutable operator;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 public historicalRewards = 0;
    uint256 public constant newRewardRatio = 830;

    uint256 private _totalSupply;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) private _balances;

    event RewardAdded(uint256 reward);
    event StakedFor(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @dev This is called directly from StakingRewards
     * @param _stakingToken LP Token (DepositToken)
     * @param _rewardToken  Reward Token (BAL)
     * @param _operator     Operator of the contract (set by StakingRewards contract)
     */
    constructor(
        address _stakingToken,
        address _rewardToken,
        address _operator
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        operator = _operator;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    function getRewardRate() public view returns (uint256) {
        return rewardRate;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {        
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address _account) public view returns (uint256) {
        return
            balanceOf(_account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_account]))
                .div(1e18)
                .add(rewards[_account]);
    }

    function stakeFor(address _for, uint256 _amount) public returns (bool) {
        require(msg.sender == operator, "!authorized");
        _processStake(_amount, _for);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit StakedFor(_for, _amount);
        
        return true;
    }

    /**
     * @dev Generic internal staking function that basically does 3 things: update rewards based
     *      on previous balance, trigger also on any child contracts, then update balances.
     * @param _amount    Units to add to the users balance
     * @param _receiver  Address of user who will receive the stake
     */
    function _processStake(uint256 _amount, address _receiver) internal nonReentrant updateReward(_receiver) {
        require(_amount > 0, 'RewardPool : Cannot stake 0');

        _totalSupply = _totalSupply.add(_amount);
        _balances[_receiver] = _balances[_receiver].add(_amount);
    }
    
    function withdrawFor(address _for, uint256 _amount) public nonReentrant updateReward(_for) returns(bool) {
        require(msg.sender == operator, "!authorized");
        require(_amount > 0, 'RewardPool : Cannot withdraw 0');

        _totalSupply = _totalSupply.sub(_amount);
        _balances[_for] = _balances[_for].sub(_amount);

        stakingToken.safeTransfer(msg.sender, _amount);        
        emit Withdrawn(_for, _amount);
     
        return true;
    }

    /**
     * @dev Gives a staker their rewards
     * @param _account     Account for which to claim     
     */
    function getReward(address _account) public updateReward(_account) returns(bool){
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);            
            emit RewardPaid(_account, reward);
        }

        return true;
    }

    /**
     * @dev Processes queued rewards in isolation, providing the period has finished.
     *      This allows a cheaper way to trigger rewards on low value pools.
     */
    function processIdleRewards() external {
        if (block.timestamp >= periodFinish && queuedRewards > 0) {
            notifyRewardAmount(queuedRewards);
            queuedRewards = 0;
        }
    }

    /**
     * @dev Called by the StakingRewards Contract to allocate new BAL rewards to this pool
     *      BAL is queued for rewards and the distribution only begins once the new rewards are sufficiently
     *      large, or the epoch has ended.
     * @param _rewards  queue BAL rewards
     */
    function queueNewRewards(uint256 _rewards) external returns(bool){
        require(msg.sender == operator, "!authorized");

        _rewards = _rewards.add(queuedRewards);

        if (block.timestamp >= periodFinish) {
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
            return true;
        }

        // et = now - (finish - duration)
        uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
        uint256 currentAtNow = rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);

        if(queuedRatio < newRewardRatio){
            notifyRewardAmount(_rewards);
            queuedRewards = 0;
        }else{
            queuedRewards = _rewards;
        }
        return true;
    }

    function notifyRewardAmount(uint256 _reward)
        internal
        updateReward(address(0))
    {
        historicalRewards = historicalRewards.add(_reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            _reward = _reward.add(leftover);
            rewardRate = _reward.div(duration);
        }
        currentRewards = _reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(_reward);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Deposit Token Interface for BAL Reward Pool
 */
interface IDepositToken is IERC20 {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}

/**
 * @dev BAL Reward Pool
 */
interface IBALRewardPool {    
    function earned(address) external view returns (uint256);
    function stakeFor(address, uint256) external;
    function withdrawFor(address, uint256) external;
    function getReward(address) external;
    function getRewardRate() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function processIdleRewards() external;
    function queueNewRewards(uint256) external;    
}

/**
 * @dev Asset Data
 */
struct AssetData {
    uint128 emissionPerSecond;
    uint128 lastUpdateTimestamp; 
    uint256 index;
    mapping(address => uint256) users;
}

interface IERC20Symbol is IERC20 {
  function symbol() external view returns (string memory s);
}

struct TokenInfo {
  address addr;
  uint256 amount;
  uint256 weight;
}

interface IAsset {
     // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerPool is IERC20 {
    function getPoolId() external view returns (bytes32 poolId);
    function symbol() external view returns (string memory s);
}

interface IWeightedPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        IAsset[] memory tokens,
        uint256[] memory weights,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

interface IBalancerVault {
    enum JoinKind {INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT}

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;
}

interface IStakingRewards {
  function stake(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Deposit and Withdraw LP tokens to Balancer Gauge 
 */
interface IBalancerGauge is IERC20 {
    function deposit(uint256) external;
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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