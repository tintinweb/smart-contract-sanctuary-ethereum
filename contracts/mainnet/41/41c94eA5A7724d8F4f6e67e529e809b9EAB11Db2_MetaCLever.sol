// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "../../interfaces/IERC20Metadata.sol";
import "../interfaces/IMetaCLever.sol";
import "../interfaces/IMetaFurnace.sol";
import "../interfaces/ICLeverToken.sol";
import "../interfaces/IYieldStrategy.sol";

// solhint-disable not-rely-on-time, max-states-count, reason-string

contract MetaCLever is OwnableUpgradeable, ReentrancyGuardUpgradeable, IMetaCLever {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UpdateFeeInfo(
    address indexed _platform,
    uint32 _platformPercentage,
    uint32 _bountyPercentage,
    uint32 _repayPercentage
  );
  event MigrateYieldStrategy(uint256 _index, address _oldStrategy, address _newStrategy);
  event AddYieldStrategy(uint256 _index, address _strategy);
  event SetStrategyActive(uint256 _index, bool _isActive);
  event UpdateReserveRate(uint256 _reserveRate);
  event UpdateFurnace(address _furnace);

  // The precision used to calculate accumulated rewards.
  uint256 private constant PRECISION = 1e18;
  // The denominator used for fee calculation.
  uint256 private constant FEE_PRECISION = 1e9;
  // The maximum value of repay fee percentage.
  uint256 private constant MAX_REPAY_FEE = 1e8; // 10%
  // The maximum value of platform fee percentage.
  uint256 private constant MAX_PLATFORM_FEE = 2e8; // 20%
  // The maximum value of harvest bounty percentage.
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  struct YieldStrategyInfo {
    // Whether the strategy is active.
    bool isActive;
    // The address of yield strategy contract.
    address strategy;
    // The address of underlying token.
    address underlyingToken;
    // The address of yield token.
    address yieldToken;
    // The total share of yield token of this strategy.
    uint256 totalShare;
    // The total amount of active yield tokens in CLever.
    uint256 activeYieldTokenAmount;
    // The total amount of yield token could be harvested.
    uint256 harvestableYieldTokenAmount;
    // The expected amount of underlying token should be deposited to this strategy.
    uint256 expectedUnderlyingTokenAmount;
    // The list of extra reward tokens.
    address[] extraRewardTokens;
    // The accRewardPerShare for each reward token.
    mapping(address => uint256) accRewardPerShare;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct FeeInfo {
    // The address of recipient of platform fee
    address platform;
    // The percentage of rewards to take for platform on harvest, multipled by 1e9.
    uint32 platformPercentage;
    // The percentage of rewards to take for caller on harvest, multipled by 1e9.
    uint32 bountyPercentage;
    // The percentage of repayed underlying/debt token to take on repay, multipled by 1e9.
    uint32 repayPercentage;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct UserInfo {
    // A signed value which represents the current amount of debt or credit that the account has accrued.
    // Positive values indicate debt, negative values indicate credit.
    int128 totalDebt;
    // The bitmask indicates the strategy that the user has deposited into the system.
    // If the i-th bit is 1, it means the user has deposited.
    // The corresponding bit will be cleared if the user takes all token from the strategy.
    uint128 depositMask;
    // The share balances for each yield strategy.
    mapping(uint256 => uint256) share;
    // The pending rewards for each extra reward token in each yield strategy.
    mapping(uint256 => mapping(address => uint256)) pendingRewards;
    // The last accRewardPerShare for each extra reward token in each yield strategy.
    mapping(uint256 => mapping(address => uint256)) accRewardPerSharePaid;
  }

  /// @notice The address of debtToken contract.
  address public debtToken;

  /// @dev Mapping from user address to user info.
  mapping(address => UserInfo) private userInfo;

  /// @notice Mapping from strategy index to YieldStrategyInfo.
  mapping(uint256 => YieldStrategyInfo) public yieldStrategies;

  /// @notice The total number of available yield strategies.
  uint256 public yieldStrategyIndex;

  /// @notice The address of Furnace Contract.
  address public furnace;

  /// @notice The debt reserve rate to borrow debtToken for each user.
  uint256 public reserveRate;

  /// @notice The fee information, including platform fee, bounty fee and repay fee.
  FeeInfo public feeInfo;

  modifier onlyExistingStrategy(uint256 _strategyIndex) {
    require(_strategyIndex < yieldStrategyIndex, "CLever: strategy not exist");
    _;
  }

  modifier onlyActiveStrategy(uint256 _strategyIndex) {
    require(yieldStrategies[_strategyIndex].isActive, "CLever: strategy not active");
    _;
  }

  function initialize(address _debtToken, address _furnace) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    require(_debtToken != address(0), "CLever: zero address");
    require(_furnace != address(0), "CLever: zero address");
    require(IERC20Metadata(_debtToken).decimals() == 18, "CLever: decimal mismatch");

    // The Furnace is maintained by our team, it's safe to approve uint256.max.
    IERC20Upgradeable(_debtToken).safeApprove(_furnace, uint256(-1));

    debtToken = _debtToken;
    furnace = _furnace;
    reserveRate = 500_000_000; // 50%
  }

  /********************************** View Functions **********************************/

  /// @notice Return all active yield strategies.
  ///
  /// @return _indices The indices of all active yield strategies.
  /// @return _strategies The list of strategy addresses for corresponding yield strategy.
  /// @return _underlyingTokens The list of underlying token addresses for corresponding yield strategy.
  /// @return _yieldTokens The list of yield token addresses for corresponding yield strategy.
  function getActiveYieldStrategies()
    external
    view
    returns (
      uint256[] memory _indices,
      address[] memory _strategies,
      address[] memory _underlyingTokens,
      address[] memory _yieldTokens
    )
  {
    uint256 _yieldStrategyIndex = yieldStrategyIndex;
    uint256 _totalActiveStrategies;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      if (yieldStrategies[i].isActive) _totalActiveStrategies += 1;
    }

    _indices = new uint256[](_totalActiveStrategies);
    _strategies = new address[](_totalActiveStrategies);
    _underlyingTokens = new address[](_totalActiveStrategies);
    _yieldTokens = new address[](_totalActiveStrategies);

    _totalActiveStrategies = 0;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      if (yieldStrategies[i].isActive) {
        _indices[_totalActiveStrategies] = i;
        _strategies[_totalActiveStrategies] = yieldStrategies[i].strategy;
        _underlyingTokens[_totalActiveStrategies] = yieldStrategies[i].underlyingToken;
        _yieldTokens[_totalActiveStrategies] = yieldStrategies[i].yieldToken;
        _totalActiveStrategies += 1;
      }
    }
  }

  /// @notice Return the amount of yield token per share.
  /// @param _strategyIndex The index of yield strategy to query.
  function getYieldTokenPerShare(uint256 _strategyIndex)
    external
    view
    onlyExistingStrategy(_strategyIndex)
    returns (uint256)
  {
    return _getYieldTokenPerShare(_strategyIndex);
  }

  /// @notice Return the amount of underlying token per share.
  /// @param _strategyIndex The index of yield strategy to query.
  function getUnderlyingTokenPerShare(uint256 _strategyIndex)
    external
    view
    onlyExistingStrategy(_strategyIndex)
    returns (uint256)
  {
    return _getUnderlyingTokenPerShare(_strategyIndex);
  }

  /// @notice Return user info in this contract.
  ///
  /// @param _account The address of user.
  ///
  /// @return _totalDebt A signed value which represents the current amount of debt or credit that the account has accrued.
  /// @return _totalValue The total amount of collateral deposited, multipled by 1e18.
  /// @return _indices The indices of each yield strategy deposited.
  /// @return _shares The user shares of each yield strategy deposited.
  function getUserInfo(address _account)
    external
    view
    returns (
      int256 _totalDebt,
      uint256 _totalValue,
      uint256[] memory _indices,
      uint256[] memory _shares
    )
  {
    _totalDebt = userInfo[_account].totalDebt;
    _totalValue = _getTotalValue(_account);

    uint256 _totalDepositedStrategies;
    uint256 _yieldStrategyIndex = yieldStrategyIndex;
    uint256 _depositMask = userInfo[_account].depositMask;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      _totalDepositedStrategies += (_depositMask >> i) & 1;
    }

    _indices = new uint256[](_totalDepositedStrategies);
    _shares = new uint256[](_totalDepositedStrategies);
    _totalDepositedStrategies = 0;

    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      if (_depositMask & 1 == 1) {
        uint256 _share = userInfo[_account].share[i];
        address _underlyingToken = yieldStrategies[i].underlyingToken;
        uint256 _accRewardPerShare = yieldStrategies[i].accRewardPerShare[_underlyingToken];
        uint256 _accRewardPerSharePaid = userInfo[_account].accRewardPerSharePaid[i][_underlyingToken];
        if (_accRewardPerShare > _accRewardPerSharePaid) {
          uint256 _scale = 10**(18 - IERC20Metadata(_underlyingToken).decimals());
          _totalDebt -= SafeCastUpgradeable.toInt256(
            (_share.mul(_accRewardPerShare - _accRewardPerSharePaid)).div(PRECISION).mul(_scale)
          );
        }

        _indices[_totalDepositedStrategies] = i;
        _shares[_totalDepositedStrategies] = _share;
        _totalDepositedStrategies += 1;
      }
      _depositMask >>= 1;
    }
  }

  /// @notice Return user info by strategy index.
  ///
  /// @param _account The address of user.
  /// @param _strategyIndex The index of yield strategy to query.
  ///
  /// @return _share The amount of yield token share of the user.
  /// @return _underlyingTokenAmount The amount of underlying token of the user.
  /// @return _yieldTokenAmount The amount of yield token of the user.
  function getUserStrategyInfo(address _account, uint256 _strategyIndex)
    external
    view
    onlyExistingStrategy(_strategyIndex)
    returns (
      uint256 _share,
      uint256 _underlyingTokenAmount,
      uint256 _yieldTokenAmount
    )
  {
    UserInfo storage _userInfo = userInfo[_account];

    _share = _userInfo.share[_strategyIndex];
    _underlyingTokenAmount = _share.mul(_getUnderlyingTokenPerShare(_strategyIndex)) / PRECISION;
    _yieldTokenAmount = _share.mul(_getYieldTokenPerShare(_strategyIndex)) / PRECISION;
  }

  /// @notice Return the pending extra rewards for user.
  ///
  /// @param _strategyIndex The index of yield strategy to query.
  /// @param _account The address of user.
  /// @param _token The address of extra reward token.
  ///
  /// @return _rewards The amount of pending extra rewards.
  function getUserPendingExtraReward(
    uint256 _strategyIndex,
    address _account,
    address _token
  ) external view onlyExistingStrategy(_strategyIndex) returns (uint256 _rewards) {
    _rewards = userInfo[_account].pendingRewards[_strategyIndex][_token];

    uint256 _accRewardPerShare = yieldStrategies[_strategyIndex].accRewardPerShare[_token];
    uint256 _accRewardPerSharePaid = userInfo[_account].accRewardPerSharePaid[_strategyIndex][_token];

    if (_accRewardPerSharePaid < _accRewardPerShare) {
      uint256 _share = userInfo[_account].share[_strategyIndex];
      _rewards += _share.mul(_accRewardPerShare - _accRewardPerSharePaid) / PRECISION;
    }
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IMetaCLever
  function deposit(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _amount,
    uint256 _minShareOut,
    bool _isUnderlying
  ) external override nonReentrant onlyActiveStrategy(_strategyIndex) returns (uint256 _shares) {
    require(_amount > 0, "CLever: deposit zero amount");

    YieldStrategyInfo storage _yieldStrategy = yieldStrategies[_strategyIndex];
    UserInfo storage _userInfo = userInfo[_recipient];

    // 1. transfer token to yield strategy
    address _strategy = _yieldStrategy.strategy;
    address _token = _isUnderlying ? _yieldStrategy.underlyingToken : _yieldStrategy.yieldToken;
    {
      // common practice to handle all kinds of ERC20 token
      uint256 _beforeBalance = IERC20Upgradeable(_token).balanceOf(_strategy);
      IERC20Upgradeable(_token).safeTransferFrom(msg.sender, _strategy, _amount);
      _amount = IERC20Upgradeable(_token).balanceOf(_strategy).sub(_beforeBalance);
    }
    // @note reuse `_amount` to store the actual yield token deposited.
    _amount = IYieldStrategy(_strategy).deposit(_recipient, _amount, _isUnderlying);

    // 2. update harvestable yield token
    _updateHarvestable(_strategyIndex);

    // 3. update account rewards
    _updateReward(_strategyIndex, _recipient);

    // 4. compute new deposited shares
    // @note The value is already updated in step 2, it's safe to use storage value directly.
    uint256 _activeYieldTokenAmount = _yieldStrategy.activeYieldTokenAmount;
    uint256 _totalShare = _yieldStrategy.totalShare;
    if (_activeYieldTokenAmount == 0) {
      _shares = _amount;
    } else {
      _shares = _amount.mul(_totalShare) / _activeYieldTokenAmount;
    }
    require(_shares >= _minShareOut, "CLever: insufficient shares");

    // 5. update yield strategy info
    _yieldStrategy.totalShare = _totalShare.add(_shares);
    _updateActiveBalance(_strategyIndex, int256(_amount));

    // 6. update account info
    // @note reuse `_totalShare` to store total user shares.
    _totalShare = _userInfo.share[_strategyIndex];
    _userInfo.share[_strategyIndex] = _totalShare + _shares; // safe to do addition
    if (_totalShare == 0) {
      _userInfo.depositMask |= uint64(1 << _strategyIndex);
    }

    emit Deposit(_strategyIndex, _recipient, _shares, _amount);
  }

  /// @inheritdoc IMetaCLever
  function withdraw(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _share,
    uint256 _minAmountOut,
    bool _asUnderlying
  ) external override nonReentrant onlyActiveStrategy(_strategyIndex) returns (uint256) {
    require(_share > 0, "CLever: withdraw zero share");

    UserInfo storage _userInfo = userInfo[msg.sender];
    require(_share <= _userInfo.share[_strategyIndex], "CLever: withdraw exceed balance");

    YieldStrategyInfo storage _yieldStrategy = yieldStrategies[_strategyIndex];

    // 1. update harvestable yield token
    _updateHarvestableByMask(_userInfo.depositMask);

    // 2. update account rewards
    _updateReward(msg.sender);

    // 3. compute actual amount of yield token to withdraw
    // @note The value is already updated in step 1, it's safe to use storage value directly.
    uint256 _totalShare = _yieldStrategy.totalShare;
    uint256 _activeYieldTokenAmount = _yieldStrategy.activeYieldTokenAmount;
    uint256 _amount = _share.mul(_activeYieldTokenAmount) / _totalShare;

    // 4. update yield yield strategy info
    _yieldStrategy.totalShare = _totalShare - _share; // safe to do subtract
    _updateActiveBalance(_strategyIndex, -int256(_amount));

    // 5. update account info
    // @note `_totalShare` is resued to store user share.
    _totalShare = _userInfo.share[_strategyIndex];
    _userInfo.share[_strategyIndex] = _totalShare - _share; // safe to do subtract
    if (_totalShare == _share) {
      _userInfo.depositMask ^= uint64(1 << _strategyIndex);
    }

    // 6. validate account health
    _checkAccountHealth(msg.sender);

    // 7. withdraw token from yield strategy
    // @note The variable `_amount` is reused as the amount of token received after withdraw.
    _amount = IYieldStrategy(_yieldStrategy.strategy).withdraw(_recipient, _amount, _asUnderlying);
    require(_amount >= _minAmountOut, "CLever: insufficient output");

    emit Withdraw(_strategyIndex, msg.sender, _share, _amount);

    return _amount;
  }

  /// @inheritdoc IMetaCLever
  function repay(
    address _underlyingToken,
    address _recipient,
    uint256 _amount
  ) external override nonReentrant {
    require(_amount > 0, "CLever: repay zero amount");

    // check token is valid
    {
      uint256 _yieldStrategyIndex = yieldStrategyIndex;
      bool _found;
      for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
        if (yieldStrategies[i].isActive && yieldStrategies[i].underlyingToken == _underlyingToken) {
          _found = true;
          break;
        }
      }
      require(_found, "CLever: invalid underlying token");
    }

    UserInfo storage _userInfo = userInfo[_recipient];

    // 1. update reward info
    _updateReward(_recipient);

    // 2. check debt and update debt
    {
      int256 _debt = _userInfo.totalDebt;
      require(_debt > 0, "CLever: no debt to repay");
      uint256 _scale = 10**(18 - IERC20Metadata(_underlyingToken).decimals());
      uint256 _maximumAmount = uint256(_debt) / _scale;
      if (_amount > _maximumAmount) _amount = _maximumAmount;
      uint256 _debtPaid = _amount * _scale;
      _userInfo.totalDebt = int128(_debt - int256(_debtPaid)); // safe to do cast
    }

    // 3. take fee and transfer token to Furnace
    FeeInfo memory _feeInfo = feeInfo;
    if (_feeInfo.repayPercentage > 0) {
      uint256 _fee = (_amount * _feeInfo.repayPercentage) / FEE_PRECISION;
      IERC20Upgradeable(_underlyingToken).safeTransferFrom(msg.sender, _feeInfo.platform, _fee);
    }
    address _furnace = furnace;
    IERC20Upgradeable(_underlyingToken).safeTransferFrom(msg.sender, _furnace, _amount);
    IMetaFurnace(_furnace).distribute(address(this), _underlyingToken, _amount);

    emit Repay(_recipient, _underlyingToken, _amount);
  }

  /// @inheritdoc IMetaCLever
  function mint(
    address _recipient,
    uint256 _amount,
    bool _depositToFurnace
  ) external override nonReentrant {
    require(_amount > 0, "CLever: mint zero amount");

    UserInfo storage _userInfo = userInfo[msg.sender];

    // 1. update harvestable for each yield strategy deposited
    _updateHarvestableByMask(_userInfo.depositMask);

    // 2. update reward info
    _updateReward(msg.sender);

    // 3. update user debt
    int256 _debt = _userInfo.totalDebt;
    _debt += SafeCastUpgradeable.toInt128(SafeCastUpgradeable.toInt256(_amount));
    _userInfo.totalDebt = SafeCastUpgradeable.toInt128(_debt);

    // 4. validate account health
    _checkAccountHealth(msg.sender);

    // 5. mint token to user or deposit to Furnace
    if (_depositToFurnace) {
      ICLeverToken(debtToken).mint(address(this), _amount);
      IMetaFurnace(furnace).deposit(_recipient, _amount);
    } else {
      ICLeverToken(debtToken).mint(_recipient, _amount);
    }

    emit Mint(msg.sender, _recipient, _amount);
  }

  /// @inheritdoc IMetaCLever
  function burn(address _recipient, uint256 _amount) external override nonReentrant {
    require(_amount > 0, "CLever: burn zero amount");

    UserInfo storage _userInfo = userInfo[_recipient];

    // 1. update reward info
    _updateReward(_recipient);

    // 2. check debt and update debt
    int256 _debt = _userInfo.totalDebt;
    require(_debt > 0, "CLever: no debt to burn");
    if (_amount > uint256(_debt)) _amount = uint256(_debt);
    _userInfo.totalDebt = int128(_debt - int256(_amount)); // safe to cast

    // 3. take fee and burn token
    FeeInfo memory _feeInfo = feeInfo;
    if (_feeInfo.repayPercentage > 0) {
      uint256 _fee = (_amount * _feeInfo.repayPercentage) / FEE_PRECISION;
      IERC20Upgradeable(debtToken).safeTransferFrom(msg.sender, _feeInfo.platform, _fee);
    }
    ICLeverToken(debtToken).burnFrom(msg.sender, _amount);

    emit Burn(msg.sender, _recipient, _amount);
  }

  /// @inheritdoc IMetaCLever
  function claim(uint256 _strategyIndex, address _recipient) public override nonReentrant {
    _claim(_strategyIndex, msg.sender, _recipient);
  }

  /// @inheritdoc IMetaCLever
  function claimAll(address _recipient) external override nonReentrant {
    uint256 _yieldStrategyIndex = yieldStrategyIndex;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      _claim(i, msg.sender, _recipient);
    }
  }

  /// @inheritdoc IMetaCLever
  function harvest(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _minimumOut
  ) external override nonReentrant onlyActiveStrategy(_strategyIndex) returns (uint256) {
    YieldStrategyInfo storage _yieldStrategy = yieldStrategies[_strategyIndex];

    // 1. update harvestable yield token
    _updateHarvestable(_strategyIndex);

    uint256 _harvestedUnderlyingTokenAmount;
    // 2. withdraw some yield token as rewards
    {
      uint256 _harvestable = _yieldStrategy.harvestableYieldTokenAmount;
      if (_harvestable > 0) {
        _harvestedUnderlyingTokenAmount = IYieldStrategy(_yieldStrategy.strategy).withdraw(
          address(this),
          _harvestable,
          true
        );
        _yieldStrategy.harvestableYieldTokenAmount = 0;
      }
    }

    // 3. harvest rewards from yield strategy and distribute extra rewards to users.
    {
      (
        uint256 _extraHarvestedUnderlyingTokenAmount,
        address[] memory _rewardTokens,
        uint256[] memory _amounts
      ) = IYieldStrategy(_yieldStrategy.strategy).harvest();

      _harvestedUnderlyingTokenAmount += _extraHarvestedUnderlyingTokenAmount;
      _distributeExtraRewards(_strategyIndex, _rewardTokens, _amounts);
    }

    require(_harvestedUnderlyingTokenAmount >= _minimumOut, "CLever: insufficient harvested amount");

    // 4. take fee
    address _underlyingToken = IYieldStrategy(_yieldStrategy.strategy).underlyingToken();
    FeeInfo memory _feeInfo = feeInfo;
    uint256 _platformFee;
    uint256 _harvestBounty;
    uint256 _toDistribute = _harvestedUnderlyingTokenAmount;
    if (_feeInfo.platformPercentage > 0) {
      _platformFee = (_feeInfo.platformPercentage * _toDistribute) / FEE_PRECISION;
      IERC20Upgradeable(_underlyingToken).safeTransfer(_feeInfo.platform, _platformFee);
      _toDistribute -= _platformFee;
    }
    if (_feeInfo.bountyPercentage > 0) {
      _harvestBounty = (_feeInfo.bountyPercentage * _toDistribute) / FEE_PRECISION;
      IERC20Upgradeable(_underlyingToken).safeTransfer(_recipient, _harvestBounty);
      _toDistribute -= _harvestBounty;
    }

    // 5. distribute underlying token to users
    if (_toDistribute > 0) {
      _distribute(_strategyIndex, _toDistribute);
    }

    emit Harvest(_strategyIndex, _toDistribute, _platformFee, _harvestBounty);

    return _harvestedUnderlyingTokenAmount;
  }

  /// @notice Update the reward info for specific account.
  ///
  /// @param _account The address of account to update.
  function updateReward(address _account) external nonReentrant {
    UserInfo storage _userInfo = userInfo[_account];

    _updateHarvestableByMask(_userInfo.depositMask);
    _updateReward(_account);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the fee information.
  /// @param _platform The platform address to be updated.
  /// @param _platformPercentage The platform fee percentage to be updated, multipled by 1e9.
  /// @param _bountyPercentage The harvest bounty percentage to be updated, multipled by 1e9.
  /// @param _repayPercentage The repay fee percentage to be updated, multipled by 1e9.
  function updateFeeInfo(
    address _platform,
    uint32 _platformPercentage,
    uint32 _bountyPercentage,
    uint32 _repayPercentage
  ) external onlyOwner {
    require(_platform != address(0), "CLever: zero address");
    require(_platformPercentage <= MAX_PLATFORM_FEE, "CLever: platform fee too large");
    require(_bountyPercentage <= MAX_HARVEST_BOUNTY, "CLever: bounty fee too large");
    require(_repayPercentage <= MAX_REPAY_FEE, "CLever: repay fee too large");

    feeInfo = FeeInfo(_platform, _platformPercentage, _bountyPercentage, _repayPercentage);

    emit UpdateFeeInfo(_platform, _platformPercentage, _bountyPercentage, _repayPercentage);
  }

  /// @notice Add new yield strategy
  ///
  /// @param _strategy The address of the new strategy.
  function addYieldStrategy(address _strategy, address[] memory _extraRewardTokens) external onlyOwner {
    require(_strategy != address(0), "CLever: add empty strategy");

    uint256 _yieldStrategyIndex = yieldStrategyIndex;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      require(yieldStrategies[i].strategy != _strategy, "CLever: add duplicated strategy");
    }

    require(IERC20Metadata(IYieldStrategy(_strategy).underlyingToken()).decimals() <= 18, "CLever: decimals too large");

    yieldStrategies[_yieldStrategyIndex].strategy = _strategy;
    yieldStrategies[_yieldStrategyIndex].underlyingToken = IYieldStrategy(_strategy).underlyingToken();
    yieldStrategies[_yieldStrategyIndex].yieldToken = IYieldStrategy(_strategy).yieldToken();
    yieldStrategies[_yieldStrategyIndex].isActive = true;
    yieldStrategies[_yieldStrategyIndex].extraRewardTokens = _extraRewardTokens;
    yieldStrategyIndex = _yieldStrategyIndex + 1;

    emit AddYieldStrategy(_yieldStrategyIndex, _strategy);
  }

  /// @notice Active or deactive an existing yield strategy.
  ///
  /// @param _strategyIndex The index of yield strategy to update.
  /// @param _isActive The status to update.
  function setIsActive(uint256 _strategyIndex, bool _isActive) external onlyExistingStrategy(_strategyIndex) onlyOwner {
    yieldStrategies[_strategyIndex].isActive = _isActive;

    emit SetStrategyActive(_strategyIndex, _isActive);
  }

  /// @notice Migrate an existing yield stategy to a new address.
  ///
  /// @param _strategyIndex The index of yield strategy to migrate.
  /// @param _newStrategy The address of the new strategy.
  function migrateYieldStrategy(uint256 _strategyIndex, address _newStrategy)
    external
    onlyExistingStrategy(_strategyIndex)
    onlyOwner
  {
    address _oldStrategy = yieldStrategies[_strategyIndex].strategy;
    require(_oldStrategy != _newStrategy, "CLever: migrate to same strategy");
    require(
      IYieldStrategy(_oldStrategy).yieldToken() == IYieldStrategy(_newStrategy).yieldToken(),
      "CLever: yield token mismatch"
    );
    require(
      IYieldStrategy(_oldStrategy).underlyingToken() == IYieldStrategy(_newStrategy).underlyingToken(),
      "CLever: underlying token mismatch"
    );

    // 1. update harvestable
    _updateHarvestable(_strategyIndex);

    // 2. do migration
    uint256 _oldYieldAmount = IYieldStrategy(_oldStrategy).totalYieldToken();
    uint256 _newYieldAmount = IYieldStrategy(_oldStrategy).migrate(_newStrategy);
    IYieldStrategy(_newStrategy).onMigrateFinished(_newYieldAmount);

    // 3. update yield strategy
    yieldStrategies[_strategyIndex].strategy = _newStrategy;
    if (_oldYieldAmount > 0) {
      yieldStrategies[_strategyIndex].activeYieldTokenAmount =
        (yieldStrategies[_strategyIndex].activeYieldTokenAmount * _newYieldAmount) /
        _oldYieldAmount;
      yieldStrategies[_strategyIndex].harvestableYieldTokenAmount =
        (yieldStrategies[_strategyIndex].harvestableYieldTokenAmount * _newYieldAmount) /
        _oldYieldAmount;
    }

    emit MigrateYieldStrategy(_strategyIndex, _oldStrategy, _newStrategy);
  }

  /// @notice Update the reserve rate for the system.
  ///
  /// @param _reserveRate The reserve rate to update.
  function updateReserveRate(uint256 _reserveRate) external onlyOwner {
    require(_reserveRate <= FEE_PRECISION, "CLever: invalid reserve rate");
    reserveRate = _reserveRate;

    emit UpdateReserveRate(_reserveRate);
  }

  /// @notice Update the furnace contract.
  ///
  /// @param _furnace The new furnace address to update.
  function updateFurnace(address _furnace) external onlyOwner {
    require(_furnace != address(0), "CLever: zero furnace address");

    address _debtToken = debtToken;
    // revoke approve from old furnace
    IERC20Upgradeable(_debtToken).safeApprove(furnace, uint256(0));
    // approve max to new furnace
    IERC20Upgradeable(_debtToken).safeApprove(_furnace, uint256(-1));

    furnace = _furnace;

    emit UpdateFurnace(_furnace);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to claim pending extra rewards.
  ///
  /// @param _strategyIndex The index of yield strategy to claim.
  /// @param _account The address of account to claim reward.
  /// @param _recipient The address of recipient to receive the reward.
  function _claim(
    uint256 _strategyIndex,
    address _account,
    address _recipient
  ) internal {
    UserInfo storage _userInfo = userInfo[_account];
    YieldStrategyInfo storage _yieldStrategy = yieldStrategies[_strategyIndex];

    // 1. update reward info
    _updateReward(_strategyIndex, _account);

    // 2. claim rewards
    uint256 _length = _yieldStrategy.extraRewardTokens.length;
    address _rewardToken;
    uint256 _rewardAmount;
    for (uint256 i = 0; i < _length; i++) {
      _rewardToken = _yieldStrategy.extraRewardTokens[i];
      _rewardAmount = _userInfo.pendingRewards[_strategyIndex][_rewardToken];
      if (_rewardAmount > 0) {
        IERC20Upgradeable(_rewardToken).safeTransfer(_recipient, _rewardAmount);
        _userInfo.pendingRewards[_strategyIndex][_rewardToken] = 0;
        emit Claim(_strategyIndex, _rewardToken, _rewardAmount);
      }
    }
  }

  /// @dev Internal function to update `harvestableYieldTokenAmount` according to bitmask.
  /// If the correspond bit is set to `1`, we should update the corresponding yield strategy.
  ///
  /// @param _mask The bitmask used to update `harvestableYieldTokenAmount` for each yield strategy.
  function _updateHarvestableByMask(uint256 _mask) internal {
    uint256 _yieldStrategyIndex = yieldStrategyIndex;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      if (_mask & 1 == 1) {
        _updateHarvestable(i);
      }
      _mask >>= 1;
    }
  }

  /// @dev Internal function to update `harvestableYieldTokenAmount` for corresponding yield strategy.
  ///
  /// @param _strategyIndex The index of yield strategy to update.
  function _updateHarvestable(uint256 _strategyIndex) internal {
    uint256 _activeYieldTokenAmount = yieldStrategies[_strategyIndex].activeYieldTokenAmount;
    if (_activeYieldTokenAmount == 0) return;

    uint256 _rate = IYieldStrategy(yieldStrategies[_strategyIndex].strategy).underlyingPrice();

    uint256 _currentUnderlyingTokenAmount = _activeYieldTokenAmount.mul(_rate) / PRECISION;
    uint256 _expectedUnderlyingTokenAmount = yieldStrategies[_strategyIndex].expectedUnderlyingTokenAmount;
    if (_currentUnderlyingTokenAmount <= _expectedUnderlyingTokenAmount) return;

    uint256 _harvestable = (_currentUnderlyingTokenAmount - _expectedUnderlyingTokenAmount).mul(PRECISION) / _rate;

    if (_harvestable > 0) {
      yieldStrategies[_strategyIndex].activeYieldTokenAmount = _activeYieldTokenAmount.sub(_harvestable);
      yieldStrategies[_strategyIndex].harvestableYieldTokenAmount += _harvestable;
    }
  }

  /// @dev Internal function to update `activeYieldTokenAmount` and `expectedUnderlyingTokenAmount` for
  /// corresponding yield strategy.
  ///
  /// @param _strategyIndex The index of yield strategy to update.
  /// @param _delta The delta amount of yield token.
  function _updateActiveBalance(uint256 _strategyIndex, int256 _delta) internal {
    uint256 _activeYieldTokenAmount = yieldStrategies[_strategyIndex].activeYieldTokenAmount;
    uint256 _expectedUnderlyingTokenAmount = yieldStrategies[_strategyIndex].expectedUnderlyingTokenAmount;

    uint256 _rate = IYieldStrategy(yieldStrategies[_strategyIndex].strategy).underlyingPrice();

    if (_delta > 0) {
      _activeYieldTokenAmount = _activeYieldTokenAmount.add(uint256(_delta));
      _expectedUnderlyingTokenAmount = _expectedUnderlyingTokenAmount.add(uint256(_delta).mul(_rate) / PRECISION);
    } else {
      _activeYieldTokenAmount = _activeYieldTokenAmount.sub(uint256(-_delta));
      _expectedUnderlyingTokenAmount = _expectedUnderlyingTokenAmount.sub(uint256(-_delta).mul(_rate) / PRECISION);
    }

    yieldStrategies[_strategyIndex].activeYieldTokenAmount = _activeYieldTokenAmount;
    yieldStrategies[_strategyIndex].expectedUnderlyingTokenAmount = _expectedUnderlyingTokenAmount;
  }

  /// @dev Internal function to update rewards for user in all yield strategies.
  ///
  /// @param _account The address of account to update reward info.
  function _updateReward(address _account) internal {
    uint256 _depositMask = userInfo[_account].depositMask;
    uint256 _yieldStrategyIndex = yieldStrategyIndex;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      if (_depositMask & 1 == 1) {
        _updateReward(i, _account);
      }
      _depositMask >>= 1;
    }
  }

  /// @dev Internal function to update rewards for user in specific yield strategy.
  ///
  /// @param _strategyIndex The index of yield strategy to update.
  /// @param _account The address of account to update reward info.
  function _updateReward(uint256 _strategyIndex, address _account) internal {
    UserInfo storage _userInfo = userInfo[_account];
    YieldStrategyInfo storage _yieldStrategyInfo = yieldStrategies[_strategyIndex];

    uint256 _share = _userInfo.share[_strategyIndex];

    // 1. update user debt
    address _token = _yieldStrategyInfo.underlyingToken;
    uint256 _accRewardPerShare = _yieldStrategyInfo.accRewardPerShare[_token];
    uint256 _accRewardPerSharePaid = _userInfo.accRewardPerSharePaid[_strategyIndex][_token];
    if (_accRewardPerSharePaid < _accRewardPerShare) {
      uint256 _scale = 10**(18 - IERC20Metadata(_token).decimals());
      uint256 _rewards = (_share.mul(_accRewardPerShare - _accRewardPerSharePaid) / PRECISION).mul(_scale);
      _userInfo.totalDebt -= SafeCastUpgradeable.toInt128(SafeCastUpgradeable.toInt256(_rewards));
      _userInfo.accRewardPerSharePaid[_strategyIndex][_token] = _accRewardPerShare;
    }

    // 2. update extra rewards
    uint256 _length = _yieldStrategyInfo.extraRewardTokens.length;
    for (uint256 i = 0; i < _length; i++) {
      _token = _yieldStrategyInfo.extraRewardTokens[i];
      _accRewardPerShare = _yieldStrategyInfo.accRewardPerShare[_token];
      _accRewardPerSharePaid = _userInfo.accRewardPerSharePaid[_strategyIndex][_token];
      if (_accRewardPerSharePaid < _accRewardPerShare) {
        uint256 _rewards = _share.mul(_accRewardPerShare - _accRewardPerSharePaid) / PRECISION;
        _userInfo.pendingRewards[_strategyIndex][_token] += _rewards;
        _userInfo.accRewardPerSharePaid[_strategyIndex][_token] = _accRewardPerShare;
      }
    }
  }

  /// @dev Internal function to underlying token rewards to all depositors.
  ///
  /// @param _strategyIndex The index of yield strategy to update.
  /// @param _amount The amount of underlying token to distribute.
  function _distribute(uint256 _strategyIndex, uint256 _amount) internal {
    address _furnace = furnace;
    address _underlyingToken = yieldStrategies[_strategyIndex].underlyingToken;

    IERC20Upgradeable(_underlyingToken).safeTransfer(_furnace, _amount);
    IMetaFurnace(_furnace).distribute(address(this), _underlyingToken, _amount);

    uint256 _totalShare = yieldStrategies[_strategyIndex].totalShare;
    if (_totalShare == 0) return;

    uint256 _accRewardPerShare = yieldStrategies[_strategyIndex].accRewardPerShare[_underlyingToken];
    yieldStrategies[_strategyIndex].accRewardPerShare[_underlyingToken] = _accRewardPerShare.add(
      _amount.mul(PRECISION) / _totalShare
    );
  }

  /// @dev Internal function to distribute extra reward tokens to all depositors.
  ///
  /// @param _strategyIndex The index of yield strategy to update.
  /// @param _rewardTokens The list of addresses of extra reward tokens to distribute.
  /// @param _amounts The list of amount of extra reward tokens to distribute.
  function _distributeExtraRewards(
    uint256 _strategyIndex,
    address[] memory _rewardTokens,
    uint256[] memory _amounts
  ) internal {
    uint256 _totalShare = yieldStrategies[_strategyIndex].totalShare;
    if (_totalShare == 0) return;
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      address _token = _rewardTokens[i];
      uint256 _accRewardPerShare = yieldStrategies[_strategyIndex].accRewardPerShare[_token];
      yieldStrategies[_strategyIndex].accRewardPerShare[_token] = _accRewardPerShare.add(
        _amounts[i].mul(PRECISION) / _totalShare
      );
    }
  }

  /// @dev Internal function to return the amount of yield token per share.
  /// @param _strategyIndex The index of yield strategy to query.
  function _getYieldTokenPerShare(uint256 _strategyIndex) internal view returns (uint256) {
    uint256 _totalShare = yieldStrategies[_strategyIndex].totalShare;
    if (_totalShare == 0) return 0;

    uint256 _activeYieldTokenAmount = _calculateActiveYieldTokenAmount(_strategyIndex);

    return (_activeYieldTokenAmount * PRECISION) / _totalShare;
  }

  /// @dev Internal function to return the amount of underlying token per share.
  /// @param _strategyIndex The index of yield strategy to query.
  function _getUnderlyingTokenPerShare(uint256 _strategyIndex) internal view returns (uint256) {
    uint256 _totalShare = yieldStrategies[_strategyIndex].totalShare;
    if (_totalShare == 0) return 0;

    uint256 _activeYieldTokenAmount = _calculateActiveYieldTokenAmount(_strategyIndex);
    uint256 _rate = IYieldStrategy(yieldStrategies[_strategyIndex].strategy).underlyingPrice();
    uint256 _activeUnderlyingTokenAmount = (_activeYieldTokenAmount * _rate) / PRECISION;

    return (_activeUnderlyingTokenAmount * PRECISION) / _totalShare;
  }

  /// @dev Internal function to calculate the real `activeYieldTokenAmount` for corresponding yield strategy.
  ///
  /// @param _strategyIndex The index of yield strategy to calculate.
  function _calculateActiveYieldTokenAmount(uint256 _strategyIndex) internal view returns (uint256) {
    uint256 _activeYieldTokenAmount = yieldStrategies[_strategyIndex].activeYieldTokenAmount;
    if (_activeYieldTokenAmount == 0) return 0;

    uint256 _rate = IYieldStrategy(yieldStrategies[_strategyIndex].strategy).underlyingPrice();

    uint256 _currentUnderlyingTokenAmount = _activeYieldTokenAmount.mul(_rate) / PRECISION;
    uint256 _expectedUnderlyingTokenAmount = yieldStrategies[_strategyIndex].expectedUnderlyingTokenAmount;
    if (_currentUnderlyingTokenAmount <= _expectedUnderlyingTokenAmount) return _activeYieldTokenAmount;

    uint256 _harvestable = (_currentUnderlyingTokenAmount - _expectedUnderlyingTokenAmount).mul(PRECISION) / _rate;

    return _activeYieldTokenAmount.sub(_harvestable);
  }

  /// @dev Gets the total value of the deposit collateral measured in debt tokens of the account owned by `owner`.
  ///
  /// @param _account The address of the account.
  ///
  /// @return The total value.
  function _getTotalValue(address _account) internal view returns (uint256) {
    UserInfo storage _userInfo = userInfo[_account];

    uint256 totalValue = 0;

    uint256 _yieldStrategyIndex = yieldStrategyIndex;
    uint256 _depositMask = _userInfo.depositMask;
    for (uint256 i = 0; i < _yieldStrategyIndex; i++) {
      if (_depositMask & 1 == 1) {
        uint256 _share = _userInfo.share[i];
        uint256 _underlyingTokenPerShare = _getUnderlyingTokenPerShare(i);
        uint256 _underlyingTokenAmount = _share.mul(_underlyingTokenPerShare) / PRECISION;
        uint256 _scale = 10**(18 - IERC20Metadata(yieldStrategies[i].underlyingToken).decimals());
        totalValue = totalValue.add(_underlyingTokenAmount.mul(_scale));
      }
      _depositMask >>= 1;
    }

    return totalValue;
  }

  /// @dev Internal function to check the health of account.
  ///      And account is health if and only if
  ///                                         borrowed
  ///                      sum deposited >= ------------
  ///                                       reserve_rate
  function _checkAccountHealth(address _account) internal view {
    uint256 _totalValue = _getTotalValue(_account);
    int256 _totalDebt = userInfo[_account].totalDebt;
    if (_totalDebt > 0) {
      require(
        _totalValue.mul(reserveRate) >= uint256(_totalDebt).mul(FEE_PRECISION),
        "CLever: account undercollateralized"
      );
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20Metadata {
  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IMetaCLever {
  event Deposit(uint256 indexed _strategyIndex, address indexed _account, uint256 _share, uint256 _amount);
  event Withdraw(uint256 indexed _strategyIndex, address indexed _account, uint256 _share, uint256 _amount);
  event Repay(address indexed _account, address indexed _underlyingToken, uint256 _amount);
  event Mint(address indexed _account, address indexed _recipient, uint256 _amount);
  event Burn(address indexed _account, address indexed _recipient, uint256 _amount);
  event Claim(uint256 indexed _strategyIndex, address indexed _rewardToken, uint256 _rewardAmount);
  event Harvest(uint256 indexed _strategyIndex, uint256 _reward, uint256 _platformFee, uint256 _harvestBounty);

  /// @notice Deposit underlying token or yield token as credit to this contract.
  ///
  /// @param _strategyIndex The yield strategy to deposit.
  /// @param _recipient The address of recipient who will receive the credit.
  /// @param _amount The number of token to deposit.
  /// @param _minShareOut The minimum share of yield token should be received.
  /// @param _isUnderlying Whether it is underlying token or yield token.
  ///
  /// @return _shares Return the amount of yield token shares received.
  function deposit(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _amount,
    uint256 _minShareOut,
    bool _isUnderlying
  ) external returns (uint256 _shares);

  /// @notice Withdraw underlying token or yield token from this contract.
  ///
  /// @param _strategyIndex The yield strategy to withdraw.
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _share The number of yield token share to withdraw.
  /// @param _minAmountOut The minimum amount of token should be receive.
  /// @param _asUnderlying Whether to receive underlying token or yield token.
  ///
  /// @return The amount of token sent to `_recipient`.
  function withdraw(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _share,
    uint256 _minAmountOut,
    bool _asUnderlying
  ) external returns (uint256);

  /// @notice Repay debt with underlying token.
  ///
  /// @dev If the repay exceed current debt amount, a refund will be executed and only
  /// sufficient amount for debt plus fee will be taken.
  ///
  /// @param _underlyingToken The address of underlying token.
  /// @param _recipient The address of the recipient who will receive credit.
  /// @param _amount The amount of underlying token to repay.
  function repay(
    address _underlyingToken,
    address _recipient,
    uint256 _amount
  ) external;

  /// @notice Mint certern amount of debt tokens from caller's account.
  ///
  /// @param _recipient The address of the recipient who will receive the debt tokens.
  /// @param _amount The amount of debt token to mint.
  /// @param _depositToFurnace Whether to deposit the debt tokens to Furnace contract.
  function mint(
    address _recipient,
    uint256 _amount,
    bool _depositToFurnace
  ) external;

  /// @notice Burn certern amount of debt tokens from caller's balance to pay debt for someone.
  ///
  /// @dev If the repay exceed current debt amount, a refund will be executed and only
  /// sufficient amount for debt plus fee will be burned.
  ///
  /// @param _recipient The address of the recipient.
  /// @param _amount The amount of debt token to burn.
  function burn(address _recipient, uint256 _amount) external;

  /// @notice Claim extra rewards from strategy.
  ///
  /// @param _strategyIndex The yield strategy to claim.
  /// @param _recipient The address of recipient who will receive the rewards.
  function claim(uint256 _strategyIndex, address _recipient) external;

  /// @notice Claim extra rewards from all deposited strategies.
  ///
  /// @param _recipient The address of recipient who will receive the rewards.
  function claimAll(address _recipient) external;

  /// @notice Harvest rewards from corresponding yield strategy.
  ///
  /// @param _strategyIndex The yield strategy to harvest.
  /// @param _recipient The address of recipient who will receive the harvest bounty.
  /// @param _minimumOut The miminim amount of rewards harvested.
  ///
  /// @return The actual amount of reward tokens harvested.
  function harvest(
    uint256 _strategyIndex,
    address _recipient,
    uint256 _minimumOut
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IMetaFurnace {
  event Deposit(address indexed _account, uint256 _amount);
  event Withdraw(address indexed _account, address _recipient, uint256 _amount);
  event Claim(address indexed _account, address _recipient, uint256 _amount);
  event Distribute(address indexed _origin, uint256 _amount);
  event Harvest(address indexed _caller, uint256 _amount);

  /// @notice Return the address of base token.
  function baseToken() external view returns (address);

  /// @notice Return the address of debt token.
  function debtToken() external view returns (address);

  /// @notice Return the amount of debtToken unrealised and realised of user.
  /// @param _account The address of user.
  /// @return unrealised The amount of debtToken unrealised.
  /// @return realised The amount of debtToken realised and can be claimed.
  function getUserInfo(address _account) external view returns (uint256 unrealised, uint256 realised);

  /// @notice Deposit debtToken in this contract to change for baseToken for other user.
  /// @param _recipient The address of user you deposit for.
  /// @param _amount The amount of debtToken to deposit.
  function deposit(address _recipient, uint256 _amount) external;

  /// @notice Withdraw unrealised debtToken of the caller from this contract.
  /// @param _recipient The address of user who will recieve the debtToken.
  /// @param _amount The amount of debtToken to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;

  /// @notice Withdraw all unrealised debtToken of the caller from this contract.
  /// @param _recipient The address of user who will recieve the debtToken.
  function withdrawAll(address _recipient) external;

  /// @notice Claim all realised baseToken of the caller from this contract.
  /// @param _recipient The address of user who will recieve the baseToken.
  function claim(address _recipient) external;

  /// @notice Exit the contract, withdraw all unrealised debtToken and realised baseToken of the caller.
  /// @param _recipient The address of user who will recieve the debtToken and baseToken.
  function exit(address _recipient) external;

  /// @notice Distribute baseToken from `origin` to pay debtToken debt.
  /// @dev Requirements:
  /// + Caller should make sure the token is transfered to this contract before call.
  /// + Caller should make sure the amount be greater than zero.
  ///
  /// @param _origin The address of the user who will provide baseToken.
  /// @param _token The address of token distributed.
  /// @param _amount The amount of baseToken will be provided.
  function distribute(
    address _origin,
    address _token,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICLeverToken is IERC20 {
  function mint(address _recipient, uint256 _amount) external;

  function burn(uint256 _amount) external;

  function burnFrom(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IYieldStrategy {
  /// @notice Return the the address of the yield token.
  function yieldToken() external view returns (address);

  /// @notice Return the the address of the underlying token.
  /// @dev The underlying token maybe the same as the yield token.
  function underlyingToken() external view returns (address);

  /// @notice Return the number of underlying token for each yield token worth, multiplied by 1e18.
  function underlyingPrice() external view returns (uint256);

  /// @notice Return the total number of underlying token in the contract.
  function totalUnderlyingToken() external view returns (uint256);

  /// @notice Return the total number of yield token in the contract.
  function totalYieldToken() external view returns (uint256);

  /// @notice Deposit underlying token or yield token to corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the token is already transfered into the strategy contract.
  ///   + Caller should make sure the deposit amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the share.
  /// @param _amount The amount of token to deposit.
  /// @param _isUnderlying Whether the deposited token is underlying token.
  ///
  /// @return _yieldAmount The amount of yield token deposited.
  function deposit(
    address _recipient,
    uint256 _amount,
    bool _isUnderlying
  ) external returns (uint256 _yieldAmount);

  /// @notice Withdraw underlying token or yield token from corresponding strategy.
  /// @dev Requirements:
  ///   + Caller should make sure the withdraw amount is greater than zero.
  ///
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _amount The amount of yield token to withdraw.
  /// @param _asUnderlying Whether the withdraw as underlying token.
  ///
  /// @return _returnAmount The amount of token sent to `_recipient`.
  function withdraw(
    address _recipient,
    uint256 _amount,
    bool _asUnderlying
  ) external returns (uint256 _returnAmount);

  /// @notice Harvest possible rewards from strategy.
  /// @dev Part of the reward tokens will be sold to underlying token.
  ///
  /// @return _underlyingAmount The amount of underlying token harvested.
  /// @return _rewardTokens The address list of extra reward tokens.
  /// @return _amounts The list of amount of corresponding extra reward token.
  function harvest()
    external
    returns (
      uint256 _underlyingAmount,
      address[] memory _rewardTokens,
      uint256[] memory _amounts
    );

  /// @notice Migrate all yield token in current strategy to another strategy.
  /// @param _strategy The address of new yield strategy.
  function migrate(address _strategy) external returns (uint256 _yieldAmount);

  /// @notice Notify the target strategy that the migration is finished.
  /// @param _yieldAmount The amount of yield token migrated.
  function onMigrateFinished(uint256 _yieldAmount) external;

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