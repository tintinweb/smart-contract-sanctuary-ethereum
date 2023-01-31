// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IStakeDAOCRVDepositor.sol";
import "./interfaces/IStakeDAOCRVVault.sol";
import "../../interfaces/ICurveFactoryPlainPool.sol";

import "./SdCRVLocker.sol";
import "./StakeDAOVaultBase.sol";

// solhint-disable not-rely-on-time

contract StakeDAOCRVVault is StakeDAOVaultBase, SdCRVLocker, IStakeDAOCRVVault {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev The minimum number of seconds needed to lock.
  uint256 private constant MIN_WITHDRAW_LOCK_TIME = 86400;

  /// @dev The address of CRV Token.
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  /// @dev The address of legacy sdveCRV Token.
  address private constant SD_VE_CRV = 0x478bBC744811eE8310B461514BDc29D03739084D;

  /// @dev The address of StakeDAO CRV Depositor contract.
  address private constant DEPOSITOR = 0xc1e3Ca8A3921719bE0aE3690A0e036feB4f69191;

  /// @dev The address of Curve CRV/sdCRV factory plain pool.
  address private constant CURVE_POOL = 0xf7b55C3732aD8b2c2dA7c24f30A69f55c54FB717;

  /// @notice The name of the vault.
  // solhint-disable-next-line const-name-snakecase
  string public constant name = "Concentrator sdCRV Vault";

  /// @notice The symbol of the vault.
  // solhint-disable-next-line const-name-snakecase
  string public constant symbol = "CTR-sdCRV-Vault";

  /// @notice The decimal of the vault share.
  // solhint-disable-next-line const-name-snakecase
  uint8 public constant decimals = 18;

  /// @dev The number of seconds to lock for withdrawing assets from the contract.
  uint256 private _withdrawLockTime;

  /********************************** Constructor **********************************/

  constructor(address _stakeDAOProxy, address _delegation) StakeDAOVaultBase(_stakeDAOProxy, _delegation) {}

  function initialize(address _gauge, uint256 __withdrawLockTime) external initializer {
    require(__withdrawLockTime >= MIN_WITHDRAW_LOCK_TIME, "lock time too small");

    StakeDAOVaultBase._initialize(_gauge);

    _withdrawLockTime = __withdrawLockTime;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc SdCRVLocker
  function withdrawLockTime() public view override returns (uint256) {
    return _withdrawLockTime;
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IStakeDAOCRVVault
  function depositWithCRV(
    uint256 _amount,
    address _recipient,
    uint256 _minOut
  ) external override returns (uint256 _amountOut) {
    if (_amount == uint256(-1)) {
      _amount = IERC20Upgradeable(CRV).balanceOf(msg.sender);
    }
    require(_amount > 0, "deposit zero amount");

    IERC20Upgradeable(CRV).safeTransferFrom(msg.sender, address(this), _amount);

    // swap to sdCRV
    uint256 _lockReturn = _amount + IStakeDAOCRVDepositor(DEPOSITOR).incentiveToken();
    uint256 _swapReturn = ICurveFactoryPlainPool(CURVE_POOL).get_dy(0, 1, _amount);
    if (_lockReturn >= _swapReturn) {
      IERC20Upgradeable(CRV).safeApprove(DEPOSITOR, 0);
      IERC20Upgradeable(CRV).safeApprove(DEPOSITOR, _amount);
      IStakeDAOCRVDepositor(DEPOSITOR).deposit(_amount, true, false, stakeDAOProxy);
      _amountOut = _lockReturn;
    } else {
      IERC20Upgradeable(CRV).safeApprove(CURVE_POOL, 0);
      IERC20Upgradeable(CRV).safeApprove(CURVE_POOL, _amount);
      _amountOut = ICurveFactoryPlainPool(CURVE_POOL).exchange(0, 1, _amount, 0, stakeDAOProxy);
    }
    require(_amountOut >= _minOut, "insufficient amount out");

    // deposit
    _deposit(_amountOut, _recipient);
  }

  /// @inheritdoc IStakeDAOCRVVault
  function depositWithSdVeCRV(uint256 _amount, address _recipient) external override {
    if (_amount == uint256(-1)) {
      _amount = IERC20Upgradeable(SD_VE_CRV).balanceOf(msg.sender);
    }
    require(_amount > 0, "deposit zero amount");

    IERC20Upgradeable(SD_VE_CRV).safeTransferFrom(msg.sender, address(this), _amount);

    // lock to sdCRV
    IERC20Upgradeable(SD_VE_CRV).safeApprove(DEPOSITOR, 0);
    IERC20Upgradeable(SD_VE_CRV).safeApprove(DEPOSITOR, _amount);
    IStakeDAOCRVDepositor(DEPOSITOR).lockSdveCrvToSdCrv(_amount);

    // transfer to proxy
    IERC20Upgradeable(stakingToken).safeTransfer(stakeDAOProxy, _amount);

    // deposit
    _deposit(_amount, _recipient);
  }

  /// @inheritdoc IStakeDAOVault
  function withdraw(uint256 _amount, address _recipient) external override(StakeDAOVaultBase, IStakeDAOVault) {
    _checkpoint(msg.sender);

    uint256 _balance = userInfo[msg.sender].balance;
    if (_amount == uint256(-1)) {
      _amount = _balance;
    }
    require(_amount <= _balance, "insufficient staked token");
    require(_amount > 0, "withdraw zero amount");

    userInfo[msg.sender].balance = _balance - _amount;
    totalSupply -= _amount;

    // take withdraw fee here
    uint256 _withdrawFee = getFeeRate(WITHDRAW_FEE_TYPE, msg.sender);
    if (_withdrawFee > 0) {
      _withdrawFee = (_amount * _withdrawFee) / FEE_PRECISION;
      withdrawFeeAccumulated += _withdrawFee;
      _amount -= _withdrawFee;
    } else {
      _withdrawFee = 0;
    }

    _lockToken(_amount, _recipient);

    emit Withdraw(msg.sender, _recipient, _amount, _withdrawFee);
  }

  /// @inheritdoc IStakeDAOCRVVault
  function harvestBribes(IStakeDAOMultiMerkleStash.claimParam[] memory _claims) external override {
    IStakeDAOLockerProxy(stakeDAOProxy).claimBribeRewards(_claims, address(this));

    FeeInfo memory _fee = feeInfo;
    uint256[] memory _amounts = new uint256[](_claims.length);
    address[] memory _tokens = new address[](_claims.length);
    for (uint256 i = 0; i < _claims.length; i++) {
      address _token = _claims[i].token;
      uint256 _reward = _claims[i].amount;
      uint256 _platformFee = uint256(_fee.platformPercentage) * 100;
      uint256 _boostFee = uint256(_fee.boostPercentage) * 100;

      // Currently, we will only receive SDT as bribe rewards.
      // If there are other tokens, we will transfer all of them to platform contract.
      if (_token != SDT) {
        _platformFee = FEE_PRECISION;
        _boostFee = 0;
      }
      if (_platformFee > 0) {
        _platformFee = (_reward * _platformFee) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(_fee.platform, _platformFee);
      }
      if (_boostFee > 0) {
        _boostFee = (_reward * _boostFee) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(delegation, _boostFee);
      }
      emit HarvestBribe(_token, _reward, _platformFee, _boostFee);

      _amounts[i] = _reward - _platformFee - _boostFee;
      _tokens[i] = _token;
    }
    _distribute(_tokens, _amounts);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the withdraw lock time.
  /// @param __withdrawLockTime The new withdraw lock time in seconds.
  function updateWithdrawLockTime(uint256 __withdrawLockTime) external onlyOwner {
    require(__withdrawLockTime >= MIN_WITHDRAW_LOCK_TIME, "lock time too small");

    _withdrawLockTime = __withdrawLockTime;

    emit UpdateWithdrawLockTime(_withdrawLockTime);
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc StakeDAOVaultBase
  function _checkpoint(address _user) internal override returns (bool) {
    bool _hasSDT = StakeDAOVaultBase._checkpoint(_user);
    if (!_hasSDT) {
      _checkpoint(SDT, userInfo[_user], userInfo[_user].balance);
    }
    return true;
  }

  /// @inheritdoc SdCRVLocker
  function _unlockToken(uint256 _amount, address _recipient) internal override {
    IStakeDAOLockerProxy(stakeDAOProxy).withdraw(gauge, stakingToken, _amount, _recipient);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IStakeDAOGauge.sol";
import "./interfaces/IStakeDAOLockerProxy.sol";
import "./interfaces/IStakeDAOVault.sol";

import "../../common/FeeCustomization.sol";

// solhint-disable not-rely-on-time

abstract contract StakeDAOVaultBase is OwnableUpgradeable, FeeCustomization, IStakeDAOVault {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint256;

  /// @notice Emitted when the fee information is updated.
  /// @param _platform The address of platform contract.
  /// @param _platformPercentage The new platform fee percentage.
  /// @param _bountyPercentage The new harvest bounty fee percentage.
  /// @param _boostPercentage The new veSDT boost fee percentage.
  /// @param _withdrawPercentage The new withdraw fee percentage.
  event UpdateFeeInfo(
    address indexed _platform,
    uint32 _platformPercentage,
    uint32 _bountyPercentage,
    uint32 _boostPercentage,
    uint32 _withdrawPercentage
  );

  /// @notice Emitted when the length of reward period is updated.
  /// @param _token The address of token updated.
  /// @param _period The new reward period.
  event UpdateRewardPeriod(address indexed _token, uint32 _period);

  /// @notice Emitted when owner take withdraw fee from contract.
  /// @param _amount The amount of fee withdrawn.
  event TakeWithdrawFee(uint256 _amount);

  /// @dev Compiler will pack this into two `uint256`.
  struct RewardData {
    // The current reward rate per second.
    uint128 rate;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    // The timesamp in seconds when reward is updated.
    uint48 lastUpdate;
    // The finish timestamp in seconds of current reward period.
    uint48 finishAt;
    // The accumulated acrv reward per share, with 1e9 precision.
    uint256 accRewardPerShare;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct FeeInfo {
    // The address of recipient of platform fee
    address platform;
    // The percentage of rewards to take for platform on harvest, multipled by 1e7.
    uint24 platformPercentage;
    // The percentage of rewards to take for caller on harvest, multipled by 1e7.
    uint24 bountyPercentage;
    // The percentage of rewards to take for veSDT boost on harvest, multipled by 1e7.
    uint24 boostPercentage;
    // The percentage of staked token to take on withdraw, multipled by 1e7.
    uint24 withdrawPercentage;
  }

  struct UserInfo {
    // The total amount of staking token deposited.
    uint256 balance;
    // Mapping from reward token address to pending rewards.
    mapping(address => uint256) rewards;
    // Mapping from reward token address to reward per share paid.
    mapping(address => uint256) rewardPerSharePaid;
  }

  /// @dev The type for withdraw fee, used in FeeCustomization.
  bytes32 internal constant WITHDRAW_FEE_TYPE = keccak256("StakeDAOVaultBase.WithdrawFee");

  /// @dev The denominator used for reward calculation.
  uint256 private constant REWARD_PRECISION = 1e18;

  /// @dev The maximum value of repay fee percentage.
  uint256 private constant MAX_WITHDRAW_FEE = 1e6; // 10%

  /// @dev The maximum value of veSDT boost fee percentage.
  uint256 private constant MAX_BOOST_FEE = 2e6; // 20%

  /// @dev The maximum value of platform fee percentage.
  uint256 private constant MAX_PLATFORM_FEE = 2e6; // 20%

  /// @dev The maximum value of harvest bounty percentage.
  uint256 private constant MAX_HARVEST_BOUNTY = 1e6; // 10%

  /// @dev The number of seconds in one week.
  uint256 internal constant WEEK = 86400 * 7;

  /// @dev The address of Stake DAO: SDT Token.
  address internal constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;

  /// @notice The address of StakeDaoLockerProxy contract.
  address public immutable stakeDAOProxy;

  /// @notice The address of VeSDTDelegation contract.
  address public immutable delegation;

  /// @notice The address of StakeDAO gauge.
  address public gauge;

  /// @notice The address of staking token.
  address public stakingToken;

  /// @notice The list of reward tokens from StakeDAO gauge.
  address[] public rewardTokens;

  /// @notice Mapping from reward token to reward information.
  mapping(address => RewardData) public rewardInfo;

  /// @inheritdoc IStakeDAOVault
  uint256 public override totalSupply;

  /// @dev Mapping from user address to user information.
  mapping(address => UserInfo) internal userInfo;

  /// @notice The accumulated amount of unclaimed withdraw fee.
  uint256 public withdrawFeeAccumulated;

  /// @notice The fee information, including platform fee, bounty fee and withdraw fee.
  FeeInfo public feeInfo;

  /********************************** Constructor **********************************/

  constructor(address _stakeDAOProxy, address _delegation) {
    stakeDAOProxy = _stakeDAOProxy;
    delegation = _delegation;
  }

  function _initialize(address _gauge) internal {
    OwnableUpgradeable.__Ownable_init();

    gauge = _gauge;
    stakingToken = IStakeDAOGauge(_gauge).staking_token();

    uint256 _count = IStakeDAOGauge(_gauge).reward_count();
    for (uint256 i = 0; i < _count; i++) {
      rewardTokens.push(IStakeDAOGauge(_gauge).reward_tokens(i));
    }
  }

  /********************************** View Functions **********************************/

  struct UserRewards {
    // The total amount of staking token deposited.
    uint256 balance;
    // The list of reward tokens
    address[] tokens;
    // The list of pending reward amounts.
    uint256[] rewards;
  }

  /// @notice Return aggregated user information for single user.
  /// @param _user The address of user to query.
  /// @return _info The aggregated user information to return.
  function getUserInfo(address _user) external view returns (UserRewards memory _info) {
    _info.balance = userInfo[_user].balance;

    uint256 _count = rewardTokens.length;
    _info.tokens = rewardTokens;
    _info.rewards = new uint256[](_count);
    for (uint256 i = 0; i < _count; i++) {
      _info.rewards[i] = userInfo[_user].rewards[_info.tokens[i]];
    }
  }

  /// @inheritdoc IStakeDAOVault
  function balanceOf(address _user) external view override returns (uint256) {
    return userInfo[_user].balance;
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IStakeDAOVault
  function deposit(uint256 _amount, address _recipient) external virtual override {
    address _token = stakingToken;
    if (_amount == uint256(-1)) {
      _amount = IERC20Upgradeable(_token).balanceOf(msg.sender);
    }
    require(_amount > 0, "deposit zero amount");

    IERC20Upgradeable(_token).safeTransferFrom(msg.sender, stakeDAOProxy, _amount);
    _deposit(_amount, _recipient);
  }

  /// @inheritdoc IStakeDAOVault
  function withdraw(uint256 _amount, address _recipient) external virtual override {
    _checkpoint(msg.sender);

    uint256 _balance = userInfo[_recipient].balance;
    if (_amount == uint256(-1)) {
      _amount = _balance;
    }
    require(_amount <= _balance, "insufficient staked token");
    require(_amount > 0, "withdraw zero amount");

    userInfo[_recipient].balance = _balance - _amount;
    totalSupply -= _amount;

    uint256 _withdrawFee = getFeeRate(WITHDRAW_FEE_TYPE, msg.sender);
    if (_withdrawFee > 0) {
      _withdrawFee = (_amount * _withdrawFee) / FEE_PRECISION;
      withdrawFeeAccumulated += _withdrawFee;
      _amount -= _withdrawFee;
    }

    IStakeDAOLockerProxy(stakeDAOProxy).withdraw(gauge, stakingToken, _amount, _recipient);

    emit Withdraw(msg.sender, _recipient, _amount, _withdrawFee);
  }

  /// @inheritdoc IStakeDAOVault
  function claim(address _user, address _recipient) external override returns (uint256[] memory _amounts) {
    if (_user != msg.sender) {
      require(_recipient == _user, "claim from others to others");
    }

    _checkpoint(_user);

    UserInfo storage _info = userInfo[_user];
    uint256 _count = rewardTokens.length;
    _amounts = new uint256[](_count);
    for (uint256 i = 0; i < _count; i++) {
      address _token = rewardTokens[i];
      _amounts[i] = _info.rewards[_token];
      if (_amounts[i] > 0) {
        IERC20Upgradeable(_token).safeTransfer(_recipient, _amounts[i]);
        _info.rewards[_token] = 0;
      }
    }

    emit Claim(_user, _recipient, _amounts);
  }

  /// @inheritdoc IStakeDAOVault
  function harvest(address _recipient) external override {
    // 1. checkpoint pending rewards
    _checkpoint(address(0));

    // 2. claim rewards from gauge
    address[] memory _tokens = rewardTokens;
    uint256[] memory _amounts = IStakeDAOLockerProxy(stakeDAOProxy).claimRewards(gauge, _tokens);

    // 3. distribute platform fee, harvest bounty and boost fee
    uint256[] memory _platformFees = new uint256[](_tokens.length);
    uint256[] memory _harvestBounties = new uint256[](_tokens.length);
    uint256 _boostFee;
    FeeInfo memory _fee = feeInfo;
    for (uint256 i = 0; i < _tokens.length; i++) {
      address _token = _tokens[i];
      if (_fee.platformPercentage > 0) {
        _platformFees[i] = (_amounts[i] * uint256(_fee.platformPercentage) * 100) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(_fee.platform, _platformFees[i]);
      }
      if (_fee.bountyPercentage > 0) {
        _harvestBounties[i] = (_amounts[i] * uint256(_fee.bountyPercentage) * 100) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(_recipient, _harvestBounties[i]);
      }
      if (_tokens[i] == SDT && _fee.boostPercentage > 0) {
        _boostFee = (_amounts[i] * uint256(_fee.boostPercentage) * 100) / FEE_PRECISION;
        IERC20Upgradeable(_token).safeTransfer(delegation, _boostFee);
      }
      _amounts[i] -= _platformFees[i] + _harvestBounties[i];
      if (_tokens[i] == SDT) {
        _amounts[i] -= _boostFee;
      }
    }

    emit Harvest(msg.sender, _amounts, _harvestBounties, _platformFees, _boostFee);

    // 4. distribute remaining rewards to users
    _distribute(_tokens, _amounts);
  }

  /// @inheritdoc IStakeDAOVault
  function checkpoint(address _user) external override {
    _checkpoint(_user);
  }

  /// @notice Helper function to reset reward tokens according to StakeDAO gauge.
  function resetRewardTokens() external {
    delete rewardTokens;

    address _gauge = gauge;
    uint256 _count = IStakeDAOGauge(_gauge).reward_count();
    for (uint256 i = 0; i < _count; i++) {
      rewardTokens.push(IStakeDAOGauge(_gauge).reward_tokens(i));
    }
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Withdraw and reset all pending withdraw fee from the contract.
  /// @param _recipient The address of recipient who will receive the withdraw fee.
  function takeWithdrawFee(address _recipient) external onlyOwner {
    uint256 _amount = withdrawFeeAccumulated;
    if (_amount > 0) {
      IStakeDAOLockerProxy(stakeDAOProxy).withdraw(gauge, stakingToken, _amount, _recipient);
      withdrawFeeAccumulated = 0;

      emit TakeWithdrawFee(_amount);
    }
  }

  /// @notice Update the fee information.
  /// @param _platform The platform address to be updated.
  /// @param _platformPercentage The platform fee percentage to be updated, multipled by 1e7.
  /// @param _bountyPercentage The harvest bounty percentage to be updated, multipled by 1e7.
  /// @param _boostPercentage The new veSDT boost fee percentage, multipled by 1e7.
  /// @param _withdrawPercentage The withdraw fee percentage to be updated, multipled by 1e7.
  function updateFeeInfo(
    address _platform,
    uint24 _platformPercentage,
    uint24 _bountyPercentage,
    uint24 _boostPercentage,
    uint24 _withdrawPercentage
  ) external onlyOwner {
    require(_platform != address(0), "zero address");
    require(_platformPercentage <= MAX_PLATFORM_FEE, "platform fee too large");
    require(_bountyPercentage <= MAX_HARVEST_BOUNTY, "bounty fee too large");
    require(_boostPercentage <= MAX_BOOST_FEE, "boost fee too large");
    require(_withdrawPercentage <= MAX_WITHDRAW_FEE, "withdraw fee too large");

    feeInfo = FeeInfo(_platform, _platformPercentage, _bountyPercentage, _boostPercentage, _withdrawPercentage);

    emit UpdateFeeInfo(_platform, _platformPercentage, _bountyPercentage, _boostPercentage, _withdrawPercentage);
  }

  /// @notice Update reward period length for some token.
  /// @param _token The address of token to update.
  /// @param _period The length of the period
  function updateRewardPeriod(address _token, uint32 _period) external onlyOwner {
    require(_period <= WEEK, "reward period too long");

    rewardInfo[_token].periodLength = _period;

    emit UpdateRewardPeriod(_token, _period);
  }

  /// @notice Update withdraw fee for certain user.
  /// @param _user The address of user to update.
  /// @param _percentage The withdraw fee percentage to be updated, multipled by 1e9.
  function setWithdrawFeeForUser(address _user, uint32 _percentage) external onlyOwner {
    require(_percentage <= MAX_WITHDRAW_FEE * 100, "withdraw fee too large");

    _setFeeCustomization(WITHDRAW_FEE_TYPE, _user, _percentage);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to update the user information.
  /// @param _user The address of user to update.
  /// @return _hasSDT Whether the reward tokens contain SDT.
  function _checkpoint(address _user) internal virtual returns (bool _hasSDT) {
    UserInfo storage _userInfo = userInfo[_user];
    uint256 _balance = _userInfo.balance;

    uint256 _count = rewardTokens.length;
    for (uint256 i = 0; i < _count; i++) {
      address _token = rewardTokens[i];
      _checkpoint(_token, _userInfo, _balance);

      if (_token == SDT) _hasSDT = true;
    }
  }

  /// @dev Internal function to update the user information for specific token.
  /// @param _token The address of token to update.
  /// @param _userInfo The UserInfor struct to update.
  /// @param _balance The total amount of staking token staked for the user.
  function _checkpoint(
    address _token,
    UserInfo storage _userInfo,
    uint256 _balance
  ) internal {
    RewardData memory _rewardInfo = rewardInfo[_token];
    if (_rewardInfo.periodLength > 0) {
      uint256 _currentTime = _rewardInfo.finishAt;
      if (_currentTime > block.timestamp) {
        _currentTime = block.timestamp;
      }
      uint256 _duration = _currentTime >= _rewardInfo.lastUpdate ? _currentTime - _rewardInfo.lastUpdate : 0;
      if (_duration > 0) {
        _rewardInfo.lastUpdate = uint48(block.timestamp);
        _rewardInfo.accRewardPerShare = _rewardInfo.accRewardPerShare.add(
          _duration.mul(_rewardInfo.rate).mul(REWARD_PRECISION) / totalSupply
        );

        rewardInfo[_token] = _rewardInfo;
      }
    }

    // update user information
    if (_balance > 0) {
      _userInfo.rewards[_token] = uint256(_userInfo.rewards[_token]).add(
        _rewardInfo.accRewardPerShare.sub(_userInfo.rewardPerSharePaid[_token]).mul(_balance) / REWARD_PRECISION
      );
      _userInfo.rewardPerSharePaid[_token] = _rewardInfo.accRewardPerShare;
    }
  }

  /// @dev Internal function to deposit staking token to proxy.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  function _deposit(uint256 _amount, address _recipient) internal {
    _checkpoint(_recipient);

    uint256 _staked = IStakeDAOLockerProxy(stakeDAOProxy).deposit(gauge, stakingToken);
    require(_staked >= _amount, "staked amount mismatch");

    userInfo[_recipient].balance += _amount;
    totalSupply += _amount;

    emit Deposit(msg.sender, _recipient, _amount);
  }

  /// @dev Internal function to distribute new harvested rewards.
  /// @param _tokens The list of reward tokens to update.
  /// @param _amounts The list of corresponding reward token amounts.
  function _distribute(address[] memory _tokens, uint256[] memory _amounts) internal {
    uint256 _totalSupply = totalSupply;
    for (uint256 i = 0; i < _tokens.length; i++) {
      if (_amounts[i] == 0) continue;
      RewardData memory _info = rewardInfo[_tokens[i]];

      if (_info.periodLength == 0) {
        // distribute intermediately
        _info.accRewardPerShare = _info.accRewardPerShare.add(_amounts[i].mul(REWARD_PRECISION) / _totalSupply);
      } else {
        // distribute linearly
        if (block.timestamp >= _info.finishAt) {
          _info.rate = uint128(_amounts[i] / _info.periodLength);
        } else {
          uint256 _remaining = _info.finishAt - block.timestamp;
          uint256 _leftover = _remaining * _info.rate;
          _info.rate = uint128((_amounts[i] + _leftover) / _info.periodLength);
        }

        _info.lastUpdate = uint48(block.timestamp);
        _info.finishAt = uint48(block.timestamp + _info.periodLength);
      }

      rewardInfo[_tokens[i]] = _info;
    }
  }

  /// @inheritdoc FeeCustomization
  function _defaultFeeRate(bytes32) internal view override returns (uint256) {
    return uint256(feeInfo.withdrawPercentage) * 100;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

// solhint-disable not-rely-on-time

abstract contract SdCRVLocker {
  /// @notice Emmited when someone withdraw staking token from contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the locked staking token.
  /// @param _amount The amount of staking token withdrawn.
  /// @param _expiredAt The timestamp in second then the lock expired
  event Lock(address indexed _owner, address indexed _recipient, uint256 _amount, uint256 _expiredAt);

  /// @notice Emitted when someone withdraw expired locked staking token.
  /// @param _owner The address of the owner of the locked staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token withdrawn.
  event WithdrawExpired(address indexed _owner, address indexed _recipient, uint256 _amount);

  /// @dev Compiler will pack this into single `uint256`.
  struct LockedBalance {
    // The amount of staking token locked.
    uint128 amount;
    // The timestamp in seconds when the lock expired.
    uint128 expireAt;
  }

  /// @dev The number of seconds in 1 day.
  uint256 private constant DAYS = 86400;

  /// @dev Mapping from user address to list of locked staking tokens.
  mapping(address => LockedBalance[]) private locks;

  /// @dev Mapping from user address to next index in `LockedBalance` lists.
  mapping(address => uint256) private nextLockIndex;

  /// @notice The number of seconds to lock for withdrawing assets from the contract.
  function withdrawLockTime() public view virtual returns (uint256);

  /// @notice Return the list of locked staking token in the contract.
  /// @param _user The address of user to query.
  /// @return _locks The list of `LockedBalance` of the user.
  function getUserLocks(address _user) external view returns (LockedBalance[] memory _locks) {
    uint256 _nextIndex = nextLockIndex[_user];
    uint256 _length = locks[_user].length;
    _locks = new LockedBalance[](_length - _nextIndex);
    for (uint256 i = _nextIndex; i < _length; i++) {
      _locks[i - _nextIndex] = locks[_user][i];
    }
  }

  /// @notice Withdraw all expired locks from contract.
  /// @param _user The address of user to withdraw.
  /// @param _recipient The address of recipient who will receive the token.
  /// @return _amount The amount of staking token withdrawn.
  function withdrawExpired(address _user, address _recipient) external returns (uint256 _amount) {
    if (_user != msg.sender) {
      require(_recipient == _user, "withdraw from others to others");
    }

    LockedBalance[] storage _locks = locks[_user];
    uint256 _nextIndex = nextLockIndex[_user];
    uint256 _length = _locks.length;
    while (_nextIndex < _length) {
      LockedBalance memory _lock = _locks[_nextIndex];
      // The list may not be ordered by expireAt, since `withdrawLockTime` could be changed.
      // However, we will still wait the first one to expire just for the sake of simplicity.
      if (_lock.expireAt > block.timestamp) break;
      _amount += _lock.amount;

      delete _locks[_nextIndex]; // clear to refund gas
      _nextIndex += 1;
    }
    nextLockIndex[_user] = _nextIndex;

    _unlockToken(_amount, _recipient);

    emit WithdrawExpired(_user, _recipient, _amount);
  }

  /// @dev Internal function to lock staking token.
  /// @param _amount The amount of staking token to lock.
  /// @param _recipient The address of recipient who will receive the locked token.
  function _lockToken(uint256 _amount, address _recipient) internal {
    uint256 _expiredAt = block.timestamp + withdrawLockTime();
    // ceil up to 86400 seconds
    _expiredAt = ((_expiredAt + DAYS - 1) / DAYS) * DAYS;

    uint256 _length = locks[_recipient].length;
    if (_length == 0 || locks[_recipient][_length - 1].expireAt != _expiredAt) {
      locks[_recipient].push(LockedBalance({ amount: uint128(_amount), expireAt: uint128(_expiredAt) }));
    } else {
      locks[_recipient][_length - 1].amount += uint128(_amount);
    }

    emit Lock(msg.sender, _recipient, _amount, _expiredAt);
  }

  /// @dev Internal function to unlock staking token.
  /// @param _amount The amount of staking token to unlock.
  /// @param _recipient The address of recipient who will receive the unlocked token.
  function _unlockToken(uint256 _amount, address _recipient) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStakeDAOMultiMerkleStash.sol";
import "./IStakeDAOVault.sol";

interface IStakeDAOCRVVault is IStakeDAOVault {
  /// @notice Emitted when the withdraw lock time is updated.
  /// @param _withdrawLockTime The new withdraw lock time in seconds.
  event UpdateWithdrawLockTime(uint256 _withdrawLockTime);

  /// @notice Emitted when someone harvest pending sdCRV bribe rewards.
  /// @param _token The address of the reward token.
  /// @param _reward The amount of harvested rewards.
  /// @param _platformFee The amount of platform fee taken.
  /// @param _boostFee The amount SDT for veSDT boost delegation fee.
  event HarvestBribe(address _token, uint256 _reward, uint256 _platformFee, uint256 _boostFee);

  /// @notice Deposit some CRV to the contract.
  /// @dev use `_amount=-1` to deposit all tokens.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  /// @param _minOut The minimum amount of sdCRV should received.
  /// @return _amountOut The amount of sdCRV received.
  function depositWithCRV(
    uint256 _amount,
    address _recipient,
    uint256 _minOut
  ) external returns (uint256 _amountOut);

  /// @notice Deposit some CRV to the contract.
  /// @dev use `_amount=-1` to deposit all tokens.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  function depositWithSdVeCRV(uint256 _amount, address _recipient) external;

  /// @notice Harvest sdCRV bribes.
  /// @dev No harvest bounty when others call this function.
  /// @param _claims The claim parameters passing to StakeDAOMultiMerkleStash contract.
  function harvestBribes(IStakeDAOMultiMerkleStash.claimParam[] memory _claims) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IStakeDAOCRVDepositor {
  function incentiveToken() external view returns (uint256);

  /// @notice Deposit & Lock Token
  /// @dev User needs to approve the contract to transfer the token
  /// @param _amount The amount of token to deposit
  /// @param _lock Whether to lock the token
  /// @param _stake Whether to stake the token
  /// @param _user User to deposit for
  function deposit(
    uint256 _amount,
    bool _lock,
    bool _stake,
    address _user
  ) external;

  /// @notice Deposits all the token of a user & locks them based on the options choosen
  /// @dev User needs to approve the contract to transfer Token tokens
  /// @param _lock Whether to lock the token
  /// @param _stake Whether to stake the token
  /// @param _user User to deposit for
  function depositAll(
    bool _lock,
    bool _stake,
    address _user
  ) external;

  /// @notice Lock forever (irreversible action) old sdveCrv to sdCrv with 1:1 rate
  /// @dev User needs to approve the contract to transfer Token tokens
  /// @param _amount amount to lock
  function lockSdveCrvToSdCrv(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase, func-name-mixedcase
interface ICurveFactoryPlainPool {
  function remove_liquidity_one_coin(
    uint256 token_amount,
    int128 i,
    uint256 min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 _dx,
    uint256 _min_dy,
    address _receiver
  ) external returns (uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(uint256 index) external view returns (address);

  function balances(uint256 index) external view returns (uint256);

  function A_precise() external view returns (uint256);

  function fee() external view returns (uint256);
}

/// @dev This is the interface of Curve Factory Plain Pool with 2 tokens, examples:
interface ICurveFactoryPlain2Pool is ICurveFactoryPlainPool {
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool _is_deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve Factory Plain Pool with 3 tokens, examples:
interface ICurveFactoryPlain3Pool is ICurveFactoryPlainPool {
  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[3] memory amounts, bool _is_deposit) external view returns (uint256);
}

/// @dev This is the interface of Curve Factory Plain Pool with 4 tokens, examples:
interface ICurveFactoryPlain4Pool is ICurveFactoryPlainPool {
  function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external returns (uint256);

  function calc_token_amount(uint256[4] memory amounts, bool _is_deposit) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.7.6;

// solhint-disable no-inline-assembly

abstract contract FeeCustomization {
  /// @notice Emitted when a fee customization is set.
  /// @param _feeType The type of fee to set.
  /// @param _user The address of user to set.
  /// @param _rate The fee rate for the user.
  event CustomizeFee(bytes32 _feeType, address _user, uint256 _rate);

  /// @notice Emitted when a fee customization is cancled.
  /// @param _feeType The type of fee to cancle.
  /// @param _user The address of user to cancle.
  event CancleCustomizeFee(bytes32 _feeType, address _user);

  /// @dev The fee denominator used for rate calculation.
  uint256 internal constant FEE_PRECISION = 1e9;

  /// @dev The salt used to compute storage slot.
  bytes32 private constant SALT = keccak256("FeeCustomization");

  /// @notice Return the fee rate for the user
  /// @param _feeType The type of fee to query.
  /// @param _user The address of user to query.
  /// @return rate The rate of fee for the user, multiplied by 1e9
  function getFeeRate(bytes32 _feeType, address _user) public view returns (uint256 rate) {
    rate = _defaultFeeRate(_feeType);

    (uint8 _customized, uint32 _rate) = _loadFeeCustomization(_feeType, _user);
    if (_customized == 1) {
      rate = _rate;
    }
  }

  /// @dev Internal function to set customized fee for user.
  /// @param _feeType The type of fee to update.
  /// @param _user The address of user to update.
  /// @param _rate The fee rate to update.
  function _setFeeCustomization(
    bytes32 _feeType,
    address _user,
    uint32 _rate
  ) internal {
    require(_rate <= FEE_PRECISION, "rate too large");

    uint256 _slot = _computeStorageSlot(_feeType, _user);
    uint256 _encoded = _encode(1, _rate);
    assembly {
      sstore(_slot, _encoded)
    }

    emit CustomizeFee(_feeType, _user, _rate);
  }

  /// @dev Internal function to cancel fee customization.
  /// @param _feeType The type of fee to update.
  /// @param _user The address of user to update.
  function _cancleFeeCustomization(bytes32 _feeType, address _user) internal {
    uint256 _slot = _computeStorageSlot(_feeType, _user);
    assembly {
      sstore(_slot, 0)
    }

    emit CancleCustomizeFee(_feeType, _user);
  }

  /// @dev Return the default fee rate for certain type.
  /// @param _feeType The type of fee to query.
  /// @return rate The default rate of fee, multiplied by 1e9
  function _defaultFeeRate(bytes32 _feeType) internal view virtual returns (uint256 rate);

  /// @dev Internal function to load fee customization from storage.
  /// @param _feeType The type of fee to query.
  /// @param _user The address of user to query.
  /// @return customized Whether there is a customization.
  /// @return rate The customized fee rate, multiplied by 1e9.
  function _loadFeeCustomization(bytes32 _feeType, address _user) private view returns (uint8 customized, uint32 rate) {
    uint256 _slot = _computeStorageSlot(_feeType, _user);
    uint256 _encoded;
    assembly {
      _encoded := sload(_slot)
    }
    (customized, rate) = _decode(_encoded);
  }

  /// @dev Internal function to compute storage slot for fee storage.
  /// @param _feeType The type of fee.
  /// @param _user The address of user.
  /// @return slot The destination storage slot.
  function _computeStorageSlot(bytes32 _feeType, address _user) private pure returns (uint256 slot) {
    bytes32 salt = SALT;
    assembly {
      mstore(0x00, _feeType)
      mstore(0x20, xor(_user, salt))
      slot := keccak256(0x00, 0x40)
    }
  }

  /// @dev Internal function to encode customized fee data. The encoding is
  /// low ---------------------> high
  /// |   8 bits   | 32 bits | 216 bits |
  /// | customized |   rate  | reserved |
  ///
  /// @param customized If it is 0, there is no customization; if it is 1, there is customization.
  /// @param rate The customized fee rate, multiplied by 1e9.
  function _encode(uint8 customized, uint32 rate) private pure returns (uint256 encoded) {
    encoded = (uint256(rate) << 8) | uint256(customized);
  }

  /// @dev Internal function to decode data.
  /// @param _encoded The data to decode.
  /// @return customized Whether there is a customization.
  /// @return rate The customized fee rate, multiplied by 1e9.
  function _decode(uint256 _encoded) private pure returns (uint8 customized, uint32 rate) {
    customized = uint8(_encoded & 0xff);
    rate = uint32((_encoded >> 8) & 0xffffffff);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStakeDAOMultiMerkleStash.sol";

interface IStakeDAOLockerProxy {
  /// @notice Deposit staked token to StakeDAO gauge.
  /// @dev The caller should make sure the token is already transfered to the contract.
  /// @param _gauge The address of gauge.
  /// @param _token The address token to deposit.
  /// @return _amount The amount of token deposited. This can be used for cross validation.
  function deposit(address _gauge, address _token) external returns (uint256 _amount);

  /// @notice Withdraw staked token from StakeDAO gauge.
  /// @param _gauge The address of gauge.
  /// @param _token The address token to withdraw.
  /// @param _amount The amount of token to withdraw.
  /// @param _recipient The address of recipient who will receive the staked token.
  function withdraw(
    address _gauge,
    address _token,
    uint256 _amount,
    address _recipient
  ) external;

  /// @notice Claim pending rewards from StakeDAO gauge.
  /// @dev Be careful that the StakeDAO gauge supports `claim_rewards_for`. Currently,
  /// it is fine since only owner can call the function through `ClaimRewards` contract.
  /// @param _gauge The address of gauge to claim.
  /// @param _tokens The list of reward tokens to claim.
  /// @return _amounts The list of amount of rewards claim for corresponding tokens.
  function claimRewards(address _gauge, address[] calldata _tokens) external returns (uint256[] memory _amounts);

  /// @notice Claim bribe rewards for sdCRV.
  /// @param _claims The claim parameters passing to StakeDAOMultiMerkleStash contract.
  /// @param _recipient The address of recipient who will receive the bribe rewards.
  function claimBribeRewards(IStakeDAOMultiMerkleStash.claimParam[] memory _claims, address _recipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase

interface IStakeDAOGauge {
  function deposit(uint256) external;

  function balanceOf(address) external view returns (uint256);

  function withdraw(uint256) external;

  function claim_rewards() external;

  function reward_tokens(uint256) external view returns (address); //v2

  function rewarded_token() external view returns (address); //v1

  function reward_count() external view returns (uint256);

  function staking_token() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IStakeDAOVault {
  /// @notice Emitted when user deposit staking token to the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token deposited.
  event Deposit(address indexed _owner, address indexed _recipient, uint256 _amount);

  /// @notice Emitted when user withdraw staking token from the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token withdrawn.
  /// @param _fee The amount of withdraw fee.
  event Withdraw(address indexed _owner, address indexed _recipient, uint256 _amount, uint256 _fee);

  /// @notice Emitted when user claim pending rewards from the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the pending rewards.
  /// @param _amounts The list of pending reward amounts.
  event Claim(address indexed _owner, address indexed _recipient, uint256[] _amounts);

  /// @notice Emitted when someone harvest pending rewards.
  /// @param _caller The address of the caller.
  /// @param _rewards The list of harvested rewards.
  /// @param _bounties The list of harvest bounty given to caller.
  /// @param _platformFees The list of platform fee taken.
  /// @param _boostFee The amount SDT for veSDT boost delegation fee.
  event Harvest(
    address indexed _caller,
    uint256[] _rewards,
    uint256[] _bounties,
    uint256[] _platformFees,
    uint256 _boostFee
  );

  /// @notice Return the amount of staking token staked in the contract.
  function totalSupply() external view returns (uint256);

  /// @notice Return the amount of staking token staked in the contract for some user.
  /// @param _user The address of user to query.
  function balanceOf(address _user) external view returns (uint256);

  /// @notice Deposit some staking token to the contract.
  /// @dev use `_amount=-1` to deposit all tokens.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  function deposit(uint256 _amount, address _recipient) external;

  /// @notice Withdraw some staking token from the contract.
  /// @dev use `_amount=-1` to withdraw all tokens.
  /// @param _amount The amount of staking token to withdraw.
  /// @param _recipient The address of recipient who will receive the withdrawn staking token.
  function withdraw(uint256 _amount, address _recipient) external;

  /// @notice Claim all pending rewards from some user.
  /// @param _user The address of user to claim.
  /// @param _recipient The address of recipient who will receive the rewards.
  /// @return _amounts The list of amount of rewards claimed.
  function claim(address _user, address _recipient) external returns (uint256[] memory _amounts);

  /// @notice Harvest pending reward from the contract.
  /// @param _recipient The address of recipient who will receive the harvest bounty.
  function harvest(address _recipient) external;

  /// @notice Update the user information.
  /// @param _user The address of user to update.
  function checkpoint(address _user) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IStakeDAOMultiMerkleStash {
  // solhint-disable-next-line contract-name-camelcase
  struct claimParam {
    address token;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function isClaimed(address token, uint256 index) external view returns (bool);

  function merkleRoot(address token) external returns (address);

  function claim(
    address token,
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  function claimMulti(address account, claimParam[] calldata claims) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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