// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../ConcentratorGeneralVault.sol";
import "../interfaces/IAladdinCompounder.sol";
import "../../interfaces/ICurveETHPool.sol";
import "../../interfaces/IZap.sol";

// solhint-disable reason-string

contract ConcentratorAladdinETHVault is ConcentratorGeneralVault {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev The address of aladdinETH token.
  address private aladdinETH;

  /// @dev The address of underlying token for aladdinETH.
  address private aladdinETHUnderlying;

  function initialize(
    address _aladdinETH,
    address _zap,
    address _platform
  ) external initializer {
    require(_aladdinETH != address(0), "Concentrator: zero aladdinETH address");
    ConcentratorGeneralVault._initialize(_zap, _platform);

    address _aladdinETHUnderlying = IAladdinCompounder(_aladdinETH).asset();
    IERC20Upgradeable(_aladdinETHUnderlying).safeApprove(_aladdinETH, uint256(-1));

    aladdinETH = _aladdinETH;
    aladdinETHUnderlying = _aladdinETHUnderlying;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IConcentratorGeneralVault
  function rewardToken() public view virtual override returns (address) {
    return aladdinETH;
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc ConcentratorGeneralVault
  function _claim(
    uint256 _amount,
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) internal virtual override returns (uint256) {
    address _aladdinETH = aladdinETH;
    uint256 _amountOut;
    if (_claimAsToken == _aladdinETH) {
      _amountOut = _amount;
    } else {
      _amountOut = IAladdinCompounder(_aladdinETH).redeem(_amount, address(this), address(this));
      address _aladdinETHUnderlying = aladdinETHUnderlying;
      if (_claimAsToken != _aladdinETHUnderlying) {
        address _zap = zap;
        IERC20Upgradeable(_aladdinETHUnderlying).safeTransfer(_zap, _amountOut);
        _amountOut = IZap(_zap).zap(_aladdinETHUnderlying, _amountOut, _claimAsToken, 0);
      }
    }

    require(_amountOut >= _minOut, "Concentrator: insufficient rewards");

    if (_claimAsToken == address(0)) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool _success, ) = msg.sender.call{ value: _amount }("");
      require(_success, "Concentrator: transfer ETH failed");
    } else {
      IERC20Upgradeable(_claimAsToken).safeTransfer(_recipient, _amountOut);
    }

    return _amountOut;
  }

  /// @inheritdoc ConcentratorGeneralVault
  function _harvest(uint256 _pid) internal virtual override returns (uint256) {
    address _strategy = poolInfo[_pid].strategy.strategy;
    address _zap = zap;
    uint256 _amountETH = IConcentratorStrategy(_strategy).harvest(_zap, address(0));

    uint256 _amount = IZap(_zap).zap{ value: _amountETH }(address(0), _amountETH, aladdinETHUnderlying, 0);

    return IAladdinCompounder(aladdinETH).deposit(_amount, address(this));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "./interfaces/IConcentratorGeneralVault.sol";
import "./interfaces/IConcentratorStrategy.sol";

import "../common/FeeCustomization.sol";

// solhint-disable no-empty-blocks
// solhint-disable reason-string
// solhint-disable not-rely-on-time

abstract contract ConcentratorGeneralVault is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  FeeCustomization,
  IConcentratorGeneralVault
{
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when pool fee ratios are updated.
  /// @param _pid The pool id to update.
  /// @param _withdrawFeeRatio The new withdraw fee ratio updated.
  /// @param _platformFeeRatio The new platform fee ratio updated.
  /// @param _harvestBountyRatio The new harvest bounty ratio updated.
  event UpdatePoolFeeRatio(
    uint256 indexed _pid,
    uint32 _withdrawFeeRatio,
    uint32 _platformFeeRatio,
    uint32 _harvestBountyRatio
  );

  /// @notice Emitted when the platform address is updated.
  /// @param _platform The new platform address.
  event UpdatePlatform(address indexed _platform);

  /// @notice Emitted when the zap contract is updated.
  /// @param _zap The address of the zap contract.
  event UpdateZap(address indexed _zap);

  /// @notice Emitted when pool assets migrated.
  /// @param _pid The pool id to migrate.
  /// @param _oldStrategy The address of old strategy.
  /// @param _newStrategy The address of current strategy.
  event Migrate(uint256 indexed _pid, address _oldStrategy, address _newStrategy);

  /// @notice Emitted when the length of reward period is updated.
  /// @param _pid The pool id to update.
  /// @param _period The new reward period.
  event UpdateRewardPeriod(uint256 indexed _pid, uint32 _period);

  /// @notice Emitted when the list of reward tokens is updated.
  /// @param _pid The pool id to update.
  /// @param _rewardTokens The new list of reward tokens.
  event UpdatePoolRewardTokens(uint256 indexed _pid, address[] _rewardTokens);

  /// @notice Emitted when a new pool is added.
  /// @param _pid The pool id added.
  /// @param _underlying The corresponding convex pool id.
  /// @param _strategy The list of reward tokens.
  event AddPool(uint256 indexed _pid, address _underlying, address _strategy);

  /// @notice Emitted when deposit is paused for the pool.
  /// @param _pid The pool id to update.
  /// @param _status The new status.
  event PausePoolDeposit(uint256 indexed _pid, bool _status);

  /// @notice Emitted when withdraw is paused for the pool.
  /// @param _pid The pool id to update.
  /// @param _status The new status.
  event PausePoolWithdraw(uint256 indexed _pid, bool _status);

  /// @dev Compiler will pack this into two `uint256`.
  struct PoolRewardInfo {
    // The current reward rate per second.
    uint128 rate;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    // The timesamp in seconds when reward is updated.
    uint48 lastUpdate;
    // The finish timestamp in seconds of current reward period.
    uint48 finishAt;
    // The accumulated acrv reward per share, with 1e18 precision.
    uint256 accRewardPerShare;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct PoolSupplyInfo {
    // The amount of total deposited token.
    uint128 totalUnderlying;
    // The amount of total deposited shares.
    uint128 totalShare;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct PoolFeeInfo {
    // The withdraw fee rate, with 1e9 precision.
    uint32 withdrawFeeRatio;
    // The platform fee rate, with 1e9 precision.
    uint32 platformFeeRatio;
    // The harvest bounty rate, with 1e9 precision.
    uint32 harvestBountyRatio;
    // reserved entry for future use.
    uint160 reserved;
  }

  /// @dev Compiler will pack this into two `uint256`.
  struct PoolStrategyInfo {
    // The address of staking token.
    address token;
    // The address of strategy contract.
    address strategy;
    // Whether deposit for the pool is paused.
    bool pauseDeposit;
    // Whether withdraw for the pool is paused.
    bool pauseWithdraw;
  }

  struct PoolInfo {
    PoolSupplyInfo supply; // 1 uint256
    PoolStrategyInfo strategy; // 2 uint256
    PoolRewardInfo reward; // 2 uint256
    PoolFeeInfo fee; // 1 uint256
  }

  struct UserInfo {
    // The amount of shares the user deposited.
    uint128 shares;
    // The amount of current accrued rewards.
    uint128 rewards;
    // The reward per share already paid for the user, with 1e18 precision.
    uint256 rewardPerSharePaid;
    // mapping from spender to allowance.
    mapping(address => uint256) allowances;
  }

  /// @dev The type for withdraw fee, used in FeeCustomization.
  bytes32 internal constant WITHDRAW_FEE_TYPE = keccak256("ConcentratorGeneralVault.WithdrawFee");

  /// @dev The precision used to calculate accumulated rewards.
  uint256 internal constant REWARD_PRECISION = 1e18;

  /// @dev The maximum percentage of withdraw fee.
  uint256 internal constant MAX_WITHDRAW_FEE = 1e8; // 10%

  /// @dev The maximum percentage of platform fee.
  uint256 internal constant MAX_PLATFORM_FEE = 2e8; // 20%

  /// @dev The maximum percentage of harvest bounty.
  uint256 internal constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  /// @dev The number of seconds in one week.
  uint256 internal constant WEEK = 86400 * 7;

  /// @notice Mapping from pool id to pool information.
  mapping(uint256 => PoolInfo) public poolInfo;

  /// @notice Mapping from pool id to account address to user share info.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @dev The next unused pool id.
  uint256 private poolIndex;

  /// @notice The address of recipient of platform fee
  address public platform;

  /// @notice The address of ZAP contract, will be used to swap tokens.
  address public zap;

  /// @dev The reserved slots.
  uint256[45] private __gap;

  modifier onlyExistPool(uint256 _pid) {
    require(_pid < poolIndex, "Concentrator: pool not exist");
    _;
  }

  // fallback function to receive eth.
  receive() external payable {}

  function _initialize(address _zap, address _platform) internal {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    require(_zap != address(0), "Concentrator: zero zap address");
    require(_platform != address(0), "Concentrator: zero platform address");

    platform = _platform;
    zap = _zap;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IConcentratorGeneralVault
  function rewardToken() public view virtual override returns (address) {}

  /// @notice Returns the number of pools.
  function poolLength() external view returns (uint256 pools) {
    pools = poolIndex;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function pendingReward(uint256 _pid, address _account) public view override returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];
    PoolRewardInfo memory _reward = _pool.reward;
    PoolSupplyInfo memory _supply = _pool.supply;

    if (_reward.periodLength > 0) {
      uint256 _currentTime = _reward.finishAt;
      if (_currentTime > block.timestamp) _currentTime = block.timestamp;
      uint256 _duration = _currentTime >= _reward.lastUpdate ? _currentTime - _reward.lastUpdate : 0;
      if (_duration > 0 && _supply.totalShare > 0) {
        _reward.accRewardPerShare = _reward.accRewardPerShare.add(
          _duration.mul(_reward.rate).mul(REWARD_PRECISION) / _supply.totalShare
        );
      }
    }

    return _pendingReward(_pid, _account, _reward.accRewardPerShare);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function pendingRewardAll(address _account) external view override returns (uint256) {
    uint256 _length = poolIndex;
    uint256 _pending;
    for (uint256 i = 0; i < _length; i++) {
      _pending += pendingReward(i, _account);
    }
    return _pending;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function getUserShare(uint256 _pid, address _account) external view override returns (uint256) {
    return userInfo[_pid][_account].shares;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function underlying(uint256 _pid) external view override returns (address) {
    return poolInfo[_pid].strategy.token;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function getTotalUnderlying(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].supply.totalUnderlying;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function getTotalShare(uint256 _pid) external view override returns (uint256) {
    return poolInfo[_pid].supply.totalShare;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function allowance(
    uint256 _pid,
    address _owner,
    address _spender
  ) external view override returns (uint256) {
    UserInfo storage _info = userInfo[_pid][_owner];
    return _info.allowances[_spender];
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IConcentratorGeneralVault
  function approve(
    uint256 _pid,
    address _spender,
    uint256 _amount
  ) external override {
    _approve(_pid, msg.sender, _spender, _amount);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function deposit(
    uint256 _pid,
    address _recipient,
    uint256 _assetsIn
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    PoolStrategyInfo memory _strategy = poolInfo[_pid].strategy;
    require(!_strategy.pauseDeposit, "Concentrator: deposit paused");

    if (_assetsIn == uint256(-1)) {
      _assetsIn = IERC20Upgradeable(_strategy.token).balanceOf(msg.sender);
    }
    require(_assetsIn > 0, "Concentrator: deposit zero amount");

    // 1. update rewards
    _updateRewards(_pid, _recipient);

    // 2. transfer user token
    uint256 _before = IERC20Upgradeable(_strategy.token).balanceOf(_strategy.strategy);
    IERC20Upgradeable(_strategy.token).safeTransferFrom(msg.sender, _strategy.strategy, _assetsIn);
    _assetsIn = IERC20Upgradeable(_strategy.token).balanceOf(_strategy.strategy) - _before;

    // 3. deposit
    return _deposit(_pid, _recipient, _assetsIn);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function withdraw(
    uint256 _pid,
    uint256 _sharesIn,
    address _recipient,
    address _owner
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    if (_sharesIn == uint256(-1)) {
      _sharesIn = userInfo[_pid][_owner].shares;
    }
    require(_sharesIn > 0, "Concentrator: withdraw zero share");

    if (msg.sender != _owner) {
      UserInfo storage _info = userInfo[_pid][_owner];
      uint256 _allowance = _info.allowances[msg.sender];
      require(_allowance >= _sharesIn, "Concentrator: withdraw exceeds allowance");
      if (_allowance != uint256(-1)) {
        // decrease allowance if it is not max
        _approve(_pid, _owner, msg.sender, _allowance - _sharesIn);
      }
    }

    // 1. update rewards
    PoolInfo storage _pool = poolInfo[_pid];
    require(!_pool.strategy.pauseWithdraw, "Concentrator: withdraw paused");
    _updateRewards(_pid, _owner);

    // 2. withdraw lp token
    return _withdraw(_pid, _sharesIn, _owner, _recipient);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function claim(
    uint256 _pid,
    address _recipient,
    uint256 _minOut,
    address _claimAsToken
  ) public override onlyExistPool(_pid) nonReentrant returns (uint256) {
    _updateRewards(_pid, msg.sender);

    UserInfo storage _userInfo = userInfo[_pid][msg.sender];
    uint256 _rewards = _userInfo.rewards;
    _userInfo.rewards = 0;

    emit Claim(_pid, msg.sender, _recipient, _rewards);

    _rewards = _claim(_rewards, _minOut, _recipient, _claimAsToken);
    return _rewards;
  }

  /// @inheritdoc IConcentratorGeneralVault
  function claimMulti(
    uint256[] memory _pids,
    address _recipient,
    uint256 _minOut,
    address _claimAsToken
  ) public override nonReentrant returns (uint256) {
    uint256 _poolIndex = poolIndex;
    uint256 _rewards;
    for (uint256 i = 0; i < _pids.length; i++) {
      uint256 _pid = _pids[i];
      require(_pid < _poolIndex, "Concentrator: pool not exist");

      UserInfo storage _userInfo = userInfo[_pid][msg.sender];
      // update if user has share
      if (_userInfo.shares > 0) {
        _updateRewards(_pid, msg.sender);
      }
      // withdraw if user has reward
      if (_userInfo.rewards > 0) {
        _rewards = _rewards.add(_userInfo.rewards);
        emit Claim(_pid, msg.sender, _recipient, _userInfo.rewards);

        _userInfo.rewards = 0;
      }
    }

    return _claim(_rewards, _minOut, _recipient, _claimAsToken);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function claimAll(
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) external override nonReentrant returns (uint256) {
    uint256 _length = poolIndex;
    uint256 _rewards;
    for (uint256 _pid = 0; _pid < _length; _pid++) {
      UserInfo storage _userInfo = userInfo[_pid][msg.sender];
      // update if user has share
      if (_userInfo.shares > 0) {
        _updateRewards(_pid, msg.sender);
      }
      // withdraw if user has reward
      if (_userInfo.rewards > 0) {
        _rewards = _rewards.add(_userInfo.rewards);
        emit Claim(_pid, msg.sender, _recipient, _userInfo.rewards);

        _userInfo.rewards = 0;
      }
    }

    return _claim(_rewards, _minOut, _recipient, _claimAsToken);
  }

  /// @inheritdoc IConcentratorGeneralVault
  function harvest(
    uint256 _pid,
    address _recipient,
    uint256 _minOut
  ) external virtual override onlyExistPool(_pid) nonReentrant returns (uint256) {
    // 1. update global pending rewards
    _updateRewards(_pid, address(0));

    // 2. harvest rewards from strategy
    uint256 _rewards = _harvest(_pid);
    require(_rewards >= _minOut, "Concentrator: insufficient rewards");

    // 3. distribute rewards to platform and _recipient
    address _token = rewardToken();
    PoolFeeInfo memory _fees = poolInfo[_pid].fee;
    uint256 _platformFee;
    uint256 _harvestBounty;
    if (_fees.platformFeeRatio > 0) {
      _platformFee = (uint256(_fees.platformFeeRatio) * _rewards) / FEE_PRECISION;
      IERC20Upgradeable(_token).safeTransfer(platform, _platformFee);
    }
    if (_fees.harvestBountyRatio > 0) {
      _harvestBounty = (uint256(_fees.harvestBountyRatio) * _rewards) / FEE_PRECISION;
      IERC20Upgradeable(_token).safeTransfer(_recipient, _harvestBounty);
    }

    emit Harvest(_pid, msg.sender, _recipient, _rewards, _platformFee, _harvestBounty);

    // 4. distribute rest rewards to users
    _notifyHarvestedReward(_pid, _rewards - _platformFee - _harvestBounty);

    return _rewards;
  }

  /// @notice Checkpoint account state.
  /// @param _pid The pool id.
  /// @param _account The address of user to checkpoint.
  function checkpoint(uint256 _pid, address _account) external {
    _updateRewards(_pid, _account);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the pool fee ratios.
  /// @param _pid The pool id.
  /// @param _withdrawFeeRatio The withdraw fee ratio to update.
  /// @param _platformFeeRatio The platform fee ratio to update.
  /// @param _harvestBountyRatio The harvest bounty fee ratio to update.
  function updatePoolFeeRatio(
    uint256 _pid,
    uint32 _withdrawFeeRatio,
    uint32 _platformFeeRatio,
    uint32 _harvestBountyRatio
  ) external onlyExistPool(_pid) onlyOwner {
    require(_withdrawFeeRatio <= MAX_WITHDRAW_FEE, "Concentrator: withdraw fee too large");
    require(_platformFeeRatio <= MAX_PLATFORM_FEE, "Concentrator: platform fee too large");
    require(_harvestBountyRatio <= MAX_HARVEST_BOUNTY, "Concentrator: harvest bounty too large");

    poolInfo[_pid].fee = PoolFeeInfo({
      withdrawFeeRatio: _withdrawFeeRatio,
      platformFeeRatio: _platformFeeRatio,
      harvestBountyRatio: _harvestBountyRatio,
      reserved: 0
    });

    emit UpdatePoolFeeRatio(_pid, _withdrawFeeRatio, _platformFeeRatio, _harvestBountyRatio);
  }

  /// @notice Update withdraw fee for certain user.
  /// @param _pid The pool id.
  /// @param _user The address of user to update.
  /// @param _ratio The withdraw fee ratio to be updated, multipled by 1e9.
  function setWithdrawFeeForUser(
    uint256 _pid,
    address _user,
    uint32 _ratio
  ) external onlyExistPool(_pid) onlyOwner {
    require(_ratio <= MAX_WITHDRAW_FEE, "Concentrator: withdraw fee too large");

    _setFeeCustomization(_getWithdrawFeeType(_pid), _user, _ratio);
  }

  /// @notice Update the recipient for platform fee.
  /// @param _platform The address of new platform.
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "Concentrator: zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @dev Update the zap contract
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "Concentrator: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /// @notice Add new Convex pool.
  /// @param _underlying The address of staking token.
  /// @param _strategy The address of corresponding strategy.
  /// @param _withdrawFeeRatio The default withdraw fee ratio of the pool.
  /// @param _platformFeeRatio The platform fee ratio of the pool.
  /// @param _harvestBountyRatio The harvest bounty ratio of the pool.
  function addPool(
    address _underlying,
    address _strategy,
    uint32 _withdrawFeeRatio,
    uint32 _platformFeeRatio,
    uint32 _harvestBountyRatio
  ) external onlyOwner {
    require(_withdrawFeeRatio <= MAX_WITHDRAW_FEE, "Concentrator: withdraw fee too large");
    require(_platformFeeRatio <= MAX_PLATFORM_FEE, "Concentrator: platform fee too large");
    require(_harvestBountyRatio <= MAX_HARVEST_BOUNTY, "Concentrator: harvest bounty too large");

    uint256 _pid = poolIndex;
    poolIndex = _pid + 1;

    poolInfo[_pid].strategy = PoolStrategyInfo({
      token: _underlying,
      strategy: _strategy,
      pauseDeposit: false,
      pauseWithdraw: false
    });

    poolInfo[_pid].fee = PoolFeeInfo({
      withdrawFeeRatio: _withdrawFeeRatio,
      platformFeeRatio: _platformFeeRatio,
      harvestBountyRatio: _harvestBountyRatio,
      reserved: 0
    });

    emit AddPool(_pid, _underlying, _strategy);
  }

  /// @notice update reward period
  /// @param _pid The pool id.
  /// @param _period The length of the period
  function updateRewardPeriod(uint256 _pid, uint32 _period) external onlyExistPool(_pid) onlyOwner {
    require(_period <= WEEK, "Concentrator: reward period too long");

    poolInfo[_pid].reward.periodLength = _period;

    emit UpdateRewardPeriod(_pid, _period);
  }

  /// @notice update reward tokens
  /// @param _pid The pool id.
  /// @param _rewardTokens The address list of new reward tokens.
  function updatePoolRewardTokens(uint256 _pid, address[] memory _rewardTokens) external onlyExistPool(_pid) onlyOwner {
    IConcentratorStrategy(poolInfo[_pid].strategy.strategy).updateRewards(_rewardTokens);

    emit UpdatePoolRewardTokens(_pid, _rewardTokens);
  }

  /// @notice Pause withdraw for specific pool.
  /// @param _pid The pool id.
  /// @param _status The status to update.
  function pausePoolWithdraw(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].strategy.pauseWithdraw = _status;

    emit PausePoolWithdraw(_pid, _status);
  }

  /// @notice Pause deposit for specific pool.
  /// @param _pid The pool id.
  /// @param _status The status to update.
  function pausePoolDeposit(uint256 _pid, bool _status) external onlyExistPool(_pid) onlyOwner {
    poolInfo[_pid].strategy.pauseDeposit = _status;

    emit PausePoolDeposit(_pid, _status);
  }

  /// @notice Migrate pool assets to new strategy.
  /// @param _pid The pool id.
  /// @param _newStrategy The address of new strategy.
  function migrateStrategy(uint256 _pid, address _newStrategy) external onlyExistPool(_pid) onlyOwner {
    uint256 _totalUnderlying = poolInfo[_pid].supply.totalUnderlying;
    address _oldStrategy = poolInfo[_pid].strategy.strategy;
    poolInfo[_pid].strategy.strategy = _newStrategy;

    IConcentratorStrategy(_oldStrategy).prepareMigrate(_newStrategy);
    IConcentratorStrategy(_oldStrategy).withdraw(_newStrategy, _totalUnderlying);
    IConcentratorStrategy(_oldStrategy).finishMigrate(_newStrategy);
    IConcentratorStrategy(_newStrategy).deposit(address(this), _totalUnderlying);

    emit Migrate(_pid, _oldStrategy, _newStrategy);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to return the amount of pending rewards.
  /// @param _pid The pool id to query.
  /// @param _account The address of account to query.
  /// @param _accRewardPerShare Hint used to compute rewards.
  function _pendingReward(
    uint256 _pid,
    address _account,
    uint256 _accRewardPerShare
  ) internal view returns (uint256) {
    UserInfo storage _userInfo = userInfo[_pid][_account];
    return
      uint256(_userInfo.rewards).add(
        _accRewardPerShare.sub(_userInfo.rewardPerSharePaid).mul(_userInfo.shares) / REWARD_PRECISION
      );
  }

  /// @dev Internal function to reward checkpoint.
  /// @param _pid The pool id to update.
  /// @param _account The address of account to update.
  function _updateRewards(uint256 _pid, address _account) internal virtual {
    PoolInfo storage _pool = poolInfo[_pid];

    // 1. update global information
    PoolRewardInfo memory _poolRewardInfo = _pool.reward;
    PoolSupplyInfo memory _supply = _pool.supply;
    if (_poolRewardInfo.periodLength > 0) {
      uint256 _currentTime = _poolRewardInfo.finishAt;
      if (_currentTime > block.timestamp) {
        _currentTime = block.timestamp;
      }
      uint256 _duration = _currentTime >= _poolRewardInfo.lastUpdate ? _currentTime - _poolRewardInfo.lastUpdate : 0;
      if (_duration > 0) {
        _poolRewardInfo.lastUpdate = uint48(block.timestamp);
        if (_supply.totalShare > 0) {
          _poolRewardInfo.accRewardPerShare = _poolRewardInfo.accRewardPerShare.add(
            _duration.mul(_poolRewardInfo.rate).mul(REWARD_PRECISION) / _supply.totalShare
          );
        }

        _pool.reward = _poolRewardInfo;
      }
    }

    // 2. update user information
    if (_account != address(0)) {
      uint256 _rewards = _pendingReward(_pid, _account, _poolRewardInfo.accRewardPerShare);
      UserInfo storage _userInfo = userInfo[_pid][_account];

      _userInfo.rewards = SafeCastUpgradeable.toUint128(_rewards);
      _userInfo.rewardPerSharePaid = _poolRewardInfo.accRewardPerShare;
    }
  }

  /// @dev Internal function to deposit token to strategy.
  /// @param _pid The pool id to deposit.
  /// @param _recipient The address of the recipient.
  /// @param _assetsIn The amount of underlying assets to deposit.
  /// @return The amount of pool shares received.
  function _deposit(
    uint256 _pid,
    address _recipient,
    uint256 _assetsIn
  ) internal returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    IConcentratorStrategy(_pool.strategy.strategy).deposit(_recipient, _assetsIn);

    PoolSupplyInfo memory _supply = _pool.supply;
    uint256 _sharesOut;
    if (_supply.totalShare == 0) {
      _sharesOut = _assetsIn;
    } else {
      _sharesOut = _assetsIn.mul(_supply.totalShare) / _supply.totalUnderlying;
    }
    _supply.totalShare = _supply.totalShare + uint128(_sharesOut);
    _supply.totalUnderlying = _supply.totalUnderlying + uint128(_assetsIn);
    _pool.supply = _supply;

    UserInfo storage _userInfo = userInfo[_pid][_recipient];
    _userInfo.shares = uint128(_sharesOut + _userInfo.shares);

    emit Deposit(_pid, msg.sender, _recipient, _assetsIn, _sharesOut);
    return _sharesOut;
  }

  /// @dev Internal function to withdraw underlying assets from convex booster.
  /// @param _pid The pool id to deposit.
  /// @param _sharesIn The amount of pool shares to withdraw.
  /// @param _owner The address of user to withdraw from.
  /// @param _recipient The address of the recipient.
  /// @return The amount of underlying assets received.
  function _withdraw(
    uint256 _pid,
    uint256 _sharesIn,
    address _owner,
    address _recipient
  ) internal returns (uint256) {
    PoolInfo storage _pool = poolInfo[_pid];

    // 2. withdraw lp token
    UserInfo storage _userInfo = userInfo[_pid][_owner];
    require(_sharesIn <= _userInfo.shares, "Concentrator: exceed user shares");

    PoolSupplyInfo memory _supply = _pool.supply;
    uint256 _assetsOut;
    if (_sharesIn == _supply.totalShare) {
      // If user is last to withdraw, don't take withdraw fee.
      // And there may still have some pending rewards, we just simple ignore it now.
      // If we want the reward later, we can upgrade the contract.
      _assetsOut = _supply.totalUnderlying;
    } else {
      uint256 _withdrawFeeRatio = getFeeRate(_getWithdrawFeeType(_pid), _owner);
      // take withdraw fee here
      _assetsOut = _sharesIn.mul(_supply.totalUnderlying) / _supply.totalShare;
      uint256 _fee = _assetsOut.mul(_withdrawFeeRatio) / FEE_PRECISION;
      _assetsOut = _assetsOut - _fee; // never overflow
    }

    _supply.totalShare = _supply.totalShare - uint128(_sharesIn);
    _supply.totalUnderlying = _supply.totalUnderlying - uint128(_assetsOut);
    _pool.supply = _supply;

    _userInfo.shares = _userInfo.shares - uint128(_sharesIn);

    IConcentratorStrategy(_pool.strategy.strategy).withdraw(_recipient, _assetsOut);

    emit Withdraw(_pid, msg.sender, _owner, _recipient, _sharesIn, _assetsOut);

    return _assetsOut;
  }

  /// @dev Internal function to update allowance.
  /// @param _pid The pool id to query.
  /// @param _owner The address of the owner.
  /// @param _spender The address of the spender.
  /// @param _amount The amount of allowance.
  function _approve(
    uint256 _pid,
    address _owner,
    address _spender,
    uint256 _amount
  ) internal {
    require(_owner != address(0), "Concentrator: approve from the zero address");
    require(_spender != address(0), "Concentrator: approve to the zero address");

    UserInfo storage _info = userInfo[_pid][_owner];
    _info.allowances[_spender] = _amount;
    emit Approval(_pid, _owner, _spender, _amount);
  }

  /// @dev Internal function to notify harvested rewards.
  /// @dev The caller should make sure `_updateRewards` is called before.
  /// @param _pid The pool id to notify.
  /// @param _amount The amount of harvested rewards.
  function _notifyHarvestedReward(uint256 _pid, uint256 _amount) internal virtual {
    require(_amount < uint128(-1), "Concentrator: harvested amount overflow");
    PoolRewardInfo memory _info = poolInfo[_pid].reward;

    if (_info.periodLength == 0) {
      _info.accRewardPerShare = _info.accRewardPerShare.add(
        _amount.mul(REWARD_PRECISION) / poolInfo[_pid].supply.totalShare
      );
    } else {
      if (block.timestamp >= _info.finishAt) {
        _info.rate = uint128(_amount / _info.periodLength);
      } else {
        uint256 _remaining = _info.finishAt - block.timestamp;
        uint256 _leftover = _remaining * _info.rate;
        _info.rate = uint128((_amount + _leftover) / _info.periodLength);
      }

      _info.lastUpdate = uint48(block.timestamp);
      _info.finishAt = uint48(block.timestamp + _info.periodLength);
    }

    poolInfo[_pid].reward = _info;
  }

  /// @dev Internal function to get the withdraw fee type for pool.
  /// @param _pid The pool id.
  function _getWithdrawFeeType(uint256 _pid) internal pure returns (bytes32) {
    return bytes32(uint256(WITHDRAW_FEE_TYPE) + _pid);
  }

  /// @inheritdoc FeeCustomization
  function _defaultFeeRate(bytes32 _feeType) internal view override returns (uint256 rate) {
    uint256 _pid = uint256(_feeType) - uint256(WITHDRAW_FEE_TYPE);
    rate = poolInfo[_pid].fee.withdrawFeeRatio;
  }

  /// @dev Internal function to claim reward token.
  /// @param _amount The amount of to claim
  /// @param _minOut The minimum amount of pending reward to receive.
  /// @param _recipient The address of account who will receive the rewards.
  /// @param _claimAsToken The address of token to claim as. Use address(0) if claim as ETH.
  /// @return The amount of reward sent to the recipient.
  function _claim(
    uint256 _amount,
    uint256 _minOut,
    address _recipient,
    address _claimAsToken
  ) internal virtual returns (uint256) {}

  /// @dev Internal function to harvest strategy rewards to reward token.
  /// @param _pid The pool id to harvest.
  /// @return The amount of reward token harvested.
  function _harvest(uint256 _pid) internal virtual returns (uint256) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IZap {
  function zap(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);

  function zapWithRoutes(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256[] calldata _routes,
    uint256 _minOut
  ) external payable returns (uint256);

  function zapFrom(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/// @title IAladdinCompounder
/// @notice The interface for AladdinCompounder like aCRV, aFXS, and is also EIP4646 compatible.
interface IAladdinCompounder {
  /// @notice Emitted when someone deposits asset into this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param sender The address who sends underlying asset.
  /// @param owner The address who will receive the pool shares.
  /// @param assets The amount of asset deposited.
  /// @param shares The amounf of pool shares received.
  event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

  /// @notice Emitted when someone withdraws asset from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param sender The address who call the function.
  /// @param receiver The address who will receive the assets.
  /// @param owner The address who owns the assets.
  /// @param assets The amount of asset withdrawn.
  /// @param shares The amounf of pool shares to withdraw.
  event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  /// @notice Emitted when someone harvests rewards.
  /// @param caller The address who call the function.
  /// @param recipient The address of account to recieve the harvest bounty.
  /// @param assets The total amount of underlying asset harvested.
  /// @param platformFee The amount of harvested assets as platform fee.
  /// @param harvestBounty The amount of harvested assets as harvest bounty.
  event Harvest(
    address indexed caller,
    address indexed recipient,
    uint256 assets,
    uint256 platformFee,
    uint256 harvestBounty
  );

  /// @notice Return the address of underlying assert.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  function asset() external view returns (address assetTokenAddress);

  /// @notice Return the total amount of underlying assert mananged by the contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  function totalAssets() external view returns (uint256 totalManagedAssets);

  /// @notice Return the amount of pool shares given the amount of asset.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of asset to convert.
  function convertToShares(uint256 assets) external view returns (uint256 shares);

  /// @notice Return the amount of asset given the amount of pool share.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of pool shares to convert.
  function convertToAssets(uint256 shares) external view returns (uint256 assets);

  /// @notice Return the maximum amount of asset that the user can deposit.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param receiver The address of user to receive the pool share.
  function maxDeposit(address receiver) external view returns (uint256 maxAssets);

  /// @notice Return the amount of pool shares will receive, if perform a deposit.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of asset to deposit.
  function previewDeposit(uint256 assets) external view returns (uint256 shares);

  /// @notice Deposit assets into this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of asset to deposit.
  /// @param receiver The address of account who will receive the pool share.
  /// @return shares The amount of pool shares received.
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);

  /// @notice Return the maximum amount of pool shares that the user can mint.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param receiver The address of user to receive the pool share.
  function maxMint(address receiver) external view returns (uint256 maxShares);

  /// @notice Return the amount of assets needed, if perform a mint.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to mint.
  function previewMint(uint256 shares) external view returns (uint256 assets);

  /// @notice Mint pool shares from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to mint.
  /// @param receiver The address of account who will receive the pool share.
  /// @return assets The amount of assets deposited to the contract.
  function mint(uint256 shares, address receiver) external returns (uint256 assets);

  /// @notice Return the maximum amount of assets that the user can withdraw.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param owner The address of user to withdraw from.
  function maxWithdraw(address owner) external view returns (uint256 maxAssets);

  /// @notice Return the amount of shares needed, if perform a withdraw.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of assets to withdraw.
  function previewWithdraw(uint256 assets) external view returns (uint256 shares);

  /// @notice Withdraw assets from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of assets to withdraw.
  /// @param receiver The address of account who will receive the assets.
  /// @param owner The address of user to withdraw from.
  /// @return shares The amount of pool shares burned.
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external returns (uint256 shares);

  /// @notice Return the maximum amount of pool shares that the user can redeem.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param owner The address of user to redeem from.
  function maxRedeem(address owner) external view returns (uint256 maxShares);

  /// @notice Return the amount of assets to be received, if perform a redeem.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to redeem.
  function previewRedeem(uint256 shares) external view returns (uint256 assets);

  /// @notice Redeem assets from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to burn.
  /// @param receiver The address of account who will receive the assets.
  /// @param owner The address of user to withdraw from.
  /// @return assets The amount of assets withdrawn.
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256 assets);

  /// @notice Harvest rewards and convert to underlying asset.
  /// @param recipient The address of account to recieve the harvest bounty.
  /// @param minAssets The minimum amount of underlying asset harvested.
  /// @return assets The total amount of underlying asset harvested.
  function harvest(address recipient, uint256 minAssets) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase, var-name-mixedcase

/// @dev This is the interface of Curve ETH Pools (including Factory Pool), examples:
/// + steth: https://curve.fi/steth
/// + seth: https://curve.fi/seth
/// + reth: https://curve.fi/reth
/// + ankreth: https://curve.fi/ankreth
/// + alETH [Factory]: https://curve.fi/factory/38
/// + Ankr Reward-Earning Staked ETH [Factory]: https://curve.fi/factory/56
interface ICurveETHPool {
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);

  function coins(uint256 index) external view returns (address);

  function lp_token() external view returns (address);
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

interface IConcentratorGeneralVault {
  /// @notice Emitted when someone change allowance.
  /// @param pid The pool id.
  /// @param owner The address of the owner.
  /// @param spender The address of the spender.
  /// @param value The new value of allowance.
  event Approval(uint256 indexed pid, address indexed owner, address indexed spender, uint256 value);

  /// @notice Emitted when someone deposits asset into this contract.
  /// @param pid The pool id.
  /// @param sender The address who sends underlying asset.
  /// @param recipient The address who will receive the pool shares.
  /// @param assetsIn The amount of asset deposited.
  /// @param sharesOut The amounf of pool shares received.
  event Deposit(
    uint256 indexed pid,
    address indexed sender,
    address indexed recipient,
    uint256 assetsIn,
    uint256 sharesOut
  );

  /// @notice Emitted when someone withdraws asset from this contract.
  /// @param pid The pool id.
  /// @param sender The address who call the function.
  /// @param owner The address who owns the assets.
  /// @param recipient The address who will receive the assets.
  /// @param assetsOut The amount of asset withdrawn.
  /// @param sharesIn The amounf of pool shares to withdraw.
  event Withdraw(
    uint256 indexed pid,
    address indexed sender,
    address indexed owner,
    address recipient,
    uint256 sharesIn,
    uint256 assetsOut
  );

  /// @notice Emitted when someone claim rewards from this contract.
  /// @param pid The pool id.
  /// @param sender The address who call the function.
  /// @param recipient The address who will receive the rewards;
  /// @param rewards The amount of reward received.
  event Claim(uint256 indexed pid, address indexed sender, address indexed recipient, uint256 rewards);

  /// @notice Emitted when someone harvests rewards.
  /// @param pid The pool id.
  /// @param caller The address who call the function.
  /// @param recipient The address of account to recieve the harvest bounty.
  /// @param rewards The total amount of rewards harvested.
  /// @param platformFee The amount of harvested assets as platform fee.
  /// @param harvestBounty The amount of harvested assets as harvest bounty.
  event Harvest(
    uint256 indexed pid,
    address indexed caller,
    address indexed recipient,
    uint256 rewards,
    uint256 platformFee,
    uint256 harvestBounty
  );

  /// @notice The address of reward token.
  function rewardToken() external view returns (address);

  /// @notice Return the amount of pending rewards for specific pool.
  /// @param pid The pool id.
  /// @param account The address of user.
  function pendingReward(uint256 pid, address account) external view returns (uint256);

  /// @notice Return the amount of pending AladdinCRV rewards for all pool.
  /// @param account The address of user.
  function pendingRewardAll(address account) external view returns (uint256);

  /// @notice Return the user share for specific user.
  /// @param pid The pool id to query.
  /// @param account The address of user.
  function getUserShare(uint256 pid, address account) external view returns (uint256);

  /// @notice Return the address of underlying token.
  /// @param pid The pool id to query.
  function underlying(uint256 pid) external view returns (address);

  /// @notice Return the total underlying token deposited.
  /// @param pid The pool id to query.
  function getTotalUnderlying(uint256 pid) external view returns (uint256);

  /// @notice Return the total pool share deposited.
  /// @param pid The pool id to query.
  function getTotalShare(uint256 pid) external view returns (uint256);

  /// @notice Returns the remaining number of shares that `spender` will be allowed to spend on behalf of `owner`.
  /// @param pid The pool id to query.
  /// @param owner The address of the owner.
  /// @param spender The address of the spender.
  function allowance(
    uint256 pid,
    address owner,
    address spender
  ) external view returns (uint256);

  /// @notice Sets `amount` as the allowance of `spender` over the caller's share.
  /// @param pid The pool id to query.
  /// @param spender The address of the spender.
  /// @param amount The amount of allowance.
  function approve(
    uint256 pid,
    address spender,
    uint256 amount
  ) external;

  /// @notice Deposit some token to specific pool for someone.
  /// @param pid The pool id.
  /// @param recipient The address of recipient who will recieve the token.
  /// @param assets The amount of token to deposit. -1 means deposit all.
  /// @return share The amount of share after deposit.
  function deposit(
    uint256 pid,
    address recipient,
    uint256 assets
  ) external returns (uint256 share);

  /// @notice Withdraw some token from specific pool and zap to token.
  /// @param pid The pool id.
  /// @param shares The share of token want to withdraw. -1 means withdraw all.
  /// @param recipient The address of account who will receive the assets.
  /// @param owner The address of user to withdraw from.
  /// @return assets The amount of token sent to recipient.
  function withdraw(
    uint256 pid,
    uint256 shares,
    address recipient,
    address owner
  ) external returns (uint256 assets);

  /// @notice claim pending rewards from specific pool.
  /// @param pid The pool id.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claim(
    uint256 pid,
    address recipient,
    uint256 minOut,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice claim pending rewards from multiple pools.
  /// @param pids The list of pool id to claim.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claimMulti(
    uint256[] memory pids,
    address recipient,
    uint256 minOut,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice claim pending rewards from all pools.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claimAll(
    uint256 minOut,
    address recipient,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice Harvest the pending reward and convert to aCRV.
  /// @param pid The pool id.
  /// @param recipient The address of account to receive harvest bounty.
  /// @param minOut The minimum amount of cvxCRV should get.
  /// @return harvested The amount of cvxCRV harvested after zapping all other tokens to it.
  function harvest(
    uint256 pid,
    address recipient,
    uint256 minOut
  ) external returns (uint256 harvested);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConcentratorStrategy {
  /// @notice Return then name of the strategy.
  function name() external view returns (string memory);

  /// @notice Update the list of reward tokens.
  /// @param _rewards The address list of reward tokens to update.
  function updateRewards(address[] memory _rewards) external;

  /// @notice Deposit token to corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the token is already transfered into the strategy contract.
  ///   + Caller should make sure the deposit amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the share.
  /// @param _amount The amount of token to deposit.
  function deposit(address _recipient, uint256 _amount) external;

  /// @notice Withdraw underlying token or yield token from corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the withdraw amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _amount The amount of token to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;

  /// @notice Harvest possible rewards from strategy.
  ///
  /// @param _zapper The address of zap contract used to zap rewards.
  /// @param _intermediate The address of intermediate token to zap.
  /// @return amount The amount of corresponding reward token.
  function harvest(address _zapper, address _intermediate) external returns (uint256 amount);

  /// @notice Emergency function to execute arbitrary call.
  /// @dev This function should be only used in case of emergency. It should never be called explicitly
  ///  in any contract in normal case.
  ///
  /// @param _to The address of target contract to call.
  /// @param _value The value passed to the target contract.
  /// @param _data The calldata pseed to the target contract.
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable returns (bool, bytes memory);

  /// @notice Do some extra work before migration.
  /// @param _newStrategy The address of new strategy.
  function prepareMigrate(address _newStrategy) external;

  /// @notice Do some extra work after migration.
  /// @param _newStrategy The address of new strategy.
  function finishMigrate(address _newStrategy) external;
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

pragma solidity ^0.7.0;


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
library SafeCastUpgradeable {

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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
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
import "../proxy/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
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