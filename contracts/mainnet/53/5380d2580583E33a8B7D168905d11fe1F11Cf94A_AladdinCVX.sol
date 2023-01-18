// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/ICurveGauge.sol";
import "../interfaces/ICurveMinter.sol";
import "../interfaces/ILegacyFurnace.sol";
import "../interfaces/ILegacyFurnace.sol";
import "../interfaces/ICLeverAMOStrategy.sol";
import "../../../interfaces/ICurveFactoryPlainPool.sol";

import "../CLeverAMOBase.sol";
import "../math/AMOMath.sol";

// solhint-disable reason-string
// solhint-disable var-name-mixedcase

contract AladdinCVX is CLeverAMOBase {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the zap contract is updated.
  /// @param _zap The address of the zap contract.
  event UpdateZap(address _zap);

  /// @notice Emitted when pool assets migrated.
  /// @param _oldStrategy The address of old strategy.
  /// @param _newStrategy The address of current strategy.
  event MigrateStrategy(address _oldStrategy, address _newStrategy);

  /// @dev The base token index in curve pool.
  int128 private immutable baseIndex;

  /// @dev The debt token index in curve pool.
  int128 private immutable debtIndex;

  /// @notice The address of zap contract.
  address public zap;

  /// @notice The address of strategy to manage the curve lp token.
  address public strategy;

  constructor(
    address _baseToken,
    address _debtToken,
    address _curvePool,
    address _curveLpToken,
    address _furnace
  ) CLeverAMOBase(_baseToken, _debtToken, _curvePool, _curveLpToken, _furnace) {
    address _coin0 = ICurveFactoryPlainPool(_curvePool).coins(0);
    debtIndex = _coin0 == _baseToken ? 1 : 0;
    baseIndex = _coin0 == _baseToken ? 0 : 1;
  }

  function initialize(
    address _zap,
    address _strategy,
    uint256 _initialRatio,
    address[] memory _rewards
  ) external initializer {
    CLeverAMOBase._initialize("Aladdin CVX", "abcCVX", _initialRatio);
    RewardClaimable._initialize(_rewards);

    IERC20Upgradeable(baseToken).safeApprove(curvePool, uint256(-1));
    IERC20Upgradeable(debtToken).safeApprove(curvePool, uint256(-1));
    IERC20Upgradeable(debtToken).safeApprove(furnace, uint256(-1));

    zap = _zap;
    strategy = _strategy;
  }

  /********************************** Mutated Functions **********************************/

  /********************************** Restricted Functions **********************************/

  /// @inheritdoc ICLeverAMO
  function rebalance(
    uint256 _withdrawAmount,
    uint256 _minOut,
    uint256 _targetRangeLeft,
    uint256 _targetRangeRight
  ) external override onlyOwner {
    _checkpoint(0);

    AMOConfig memory _config = config;
    {
      uint256 _ratio = ratio();
      require(_config.minLPRatio <= _ratio && _ratio <= _config.maxLPRatio, "abcCVX: ratio out of range");
    }

    uint256 _debtInPool = ICurveFactoryPlainPool(curvePool).balances(uint256(debtIndex));
    uint256 _baseInPool = ICurveFactoryPlainPool(curvePool).balances(uint256(baseIndex));
    uint256 _startPoolRatio = (_debtInPool * PRECISION) / _baseInPool;
    if (_debtInPool * PRECISION < _config.minAMO * _baseInPool) {
      // _debtInPool/_baseInPool < minAMO/PRECISION
      // withdraw clevCVX from Furnace
      ILegacyFurnace(furnace).withdraw(address(this), _withdrawAmount);

      // add liquidity to curve pool
      uint256[2] memory _addAmounts;
      _addAmounts[uint256(debtIndex)] = _withdrawAmount;
      uint256 _lpTokenOut = ICurveFactoryPlain2Pool(curvePool).add_liquidity(_addAmounts, _minOut);

      // deposit to gauge
      _depositLpToken(_lpTokenOut);
    } else if (_debtInPool * PRECISION > _config.maxAMO * _baseInPool) {
      // _debtInPool/_baseInPool > maxAMO/PRECISION
      // withdraw clevCVX/CVX lp from gauge
      _withdrawLpToken(_withdrawAmount, address(this));

      // withdraw clevCVX from curve pool
      uint256 _debtTokenOut = ICurveFactoryPlainPool(curvePool).remove_liquidity_one_coin(
        _withdrawAmount,
        debtIndex,
        _minOut
      );

      // deposit into Furnace
      ILegacyFurnace(furnace).deposit(_debtTokenOut);
    } else {
      revert("abcCVX: amo in range");
    }

    // make sure the final ratio is in target range.
    _debtInPool = ICurveFactoryPlainPool(curvePool).balances(uint256(debtIndex));
    _baseInPool = ICurveFactoryPlainPool(curvePool).balances(uint256(baseIndex));
    uint256 _targetPoolRatio = (_debtInPool * PRECISION) / _baseInPool;
    // _targetRangeLeft/PRECISION <= _debtInPool/_baseInPool <= _targetRangeRight/PRECISION
    require(_targetRangeLeft * _baseInPool <= _debtInPool * PRECISION, "abcCVX: final ratio below target range");
    require(_targetRangeRight * _baseInPool >= _debtInPool * PRECISION, "abcCVX: final ratio above target range");

    emit Rebalance(ratio(), _startPoolRatio, _targetPoolRatio);
  }

  /// @notice Update the zap contract
  /// @param _zap The address of the zap contract.
  function updateZap(address _zap) external onlyOwner {
    require(_zap != address(0), "abcCVX: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /// @notice Migrate pool assets to new strategy.
  /// @dev harvest should be called before migrate.
  /// @param _newStrategy The address of new strategy.
  function migrateStrategy(address _newStrategy) external onlyOwner {
    require(_newStrategy != address(0), "abcCVX: zero strategy address");

    uint256 _totalCurveLpToken = _lpBalanceInContract();
    address _oldStrategy = strategy;

    strategy = _newStrategy;

    IConcentratorStrategy(_oldStrategy).prepareMigrate(_newStrategy);
    IConcentratorStrategy(_oldStrategy).withdraw(_newStrategy, _totalCurveLpToken);
    IConcentratorStrategy(_oldStrategy).finishMigrate(_newStrategy);

    IConcentratorStrategy(_newStrategy).deposit(address(0), _totalCurveLpToken);

    emit MigrateStrategy(_oldStrategy, _newStrategy);
  }

  /********************************** Internal Functions **********************************/

  /// @inheritdoc ERC20Upgradeable
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256
  ) internal override {
    _checkpointUser(_from);
    _checkpointUser(_to);
  }

  /// @inheritdoc CLeverAMOBase
  function _debtBalanceInContract() internal view override returns (uint256) {
    (uint256 _unrealised, ) = ILegacyFurnace(furnace).getUserInfo(address(this));
    return _unrealised;
  }

  /// @inheritdoc CLeverAMOBase
  function _lpBalanceInContract() internal view override returns (uint256) {
    return ICLeverAMOStrategy(strategy).strategyBalance();
  }

  /// @inheritdoc CLeverAMOBase
  function _convertFromBaseToken(uint256 _amount)
    internal
    override
    returns (
      uint256 _debtTokenOut,
      uint256 _lpTokenOut,
      uint256 _ratio
    )
  {
    uint256 _debtBalance;
    uint256 _lpBalance;
    uint256 _addLiquidityAmount;
    // compute split amount
    {
      if (totalSupply() == 0) {
        _addLiquidityAmount = _searchSplit(_amount, initialRatio, PRECISION);
      } else {
        _debtBalance = _debtBalanceInContract();
        _lpBalance = _lpBalanceInContract();
        _addLiquidityAmount = _searchSplit(_amount, _lpBalance, _debtBalance);
      }
    }
    // do add liquidity and swap
    {
      uint256[2] memory amounts;
      amounts[uint256(baseIndex)] = _addLiquidityAmount;
      _lpTokenOut = ICurveFactoryPlain2Pool(curvePool).add_liquidity(amounts, 0);
      _debtTokenOut = ICurveFactoryPlainPool(curvePool).exchange(
        baseIndex,
        debtIndex,
        _amount - _addLiquidityAmount,
        0,
        address(this)
      );
    }
    // compute the new ratio
    _ratio = ((_lpBalance + _lpTokenOut) * PRECISION) / (_debtBalance + _debtTokenOut);
  }

  /// @inheritdoc CLeverAMOBase
  function _convertToBaseToken(uint256 _debtTokenAmount, uint256 _lpTokenAmount)
    internal
    override
    returns (uint256 _baseTokenOut)
  {
    // swap then remove liquidity
    _baseTokenOut = ICurveFactoryPlainPool(curvePool).exchange(
      debtIndex,
      baseIndex,
      _debtTokenAmount,
      0,
      address(this)
    );
    _baseTokenOut += ICurveFactoryPlainPool(curvePool).remove_liquidity_one_coin(_lpTokenAmount, baseIndex, 0);
  }

  /// @inheritdoc CLeverAMOBase
  function _depositDebtToken(uint256 _amount) internal override {
    ILegacyFurnace(furnace).deposit(_amount);
  }

  /// @inheritdoc CLeverAMOBase
  function _withdrawDebtToken(uint256 _amount, address _recipient) internal override {
    ILegacyFurnace(furnace).withdraw(_recipient, _amount);
  }

  /// @inheritdoc CLeverAMOBase
  function _claimBaseFromFurnace() internal override returns (uint256 _baseTokenOut) {
    uint256 _before = IERC20Upgradeable(baseToken).balanceOf(address(this));
    ILegacyFurnace(furnace).claim(address(this));
    _baseTokenOut = IERC20Upgradeable(baseToken).balanceOf(address(this)) - _before;
  }

  /// @inheritdoc CLeverAMOBase
  function _depositLpToken(uint256 _amount) internal override {
    address _strategy = strategy;
    IERC20Upgradeable(curveLpToken).safeTransfer(_strategy, _amount);
    IConcentratorStrategy(_strategy).deposit(address(0), _amount);
  }

  /// @inheritdoc CLeverAMOBase
  function _withdrawLpToken(uint256 _amount, address _recipient) internal override {
    IConcentratorStrategy(strategy).withdraw(_recipient, _amount);
  }

  /// @inheritdoc CLeverAMOBase
  function _harvest() internal override returns (uint256) {
    uint256 _length = rewards.length;
    uint256[] memory _amounts = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      address _token = rewards[i];
      _amounts[i] = IERC20Upgradeable(_token).balanceOf(address(this));
    }

    uint256 _baseHarvested = IConcentratorStrategy(strategy).harvest(zap, baseToken);

    uint256 _totalSupply = totalSupply();
    for (uint256 i = 0; i < _length; i++) {
      address _token = rewards[i];
      _amounts[i] = IERC20Upgradeable(_token).balanceOf(address(this)) - _amounts[i];
      if (_amounts[i] > 0) {
        rewardPerShare[_token] += (_amounts[i] * REWARD_PRECISION) / _totalSupply;
      }
    }

    return _baseHarvested;
  }

  /// @inheritdoc RewardClaimable
  function _getShares(address _user) internal view override returns (uint256) {
    return balanceOf(_user);
  }

  /// @dev Search the split between swap and add liquidity
  /// @param dx The input amount of base token.
  /// @param num The numerator of ratio between lp/debt
  /// @param den The denominator of ratio between lp/debt
  function _searchSplit(
    uint256 dx,
    uint256 num,
    uint256 den
  ) internal view returns (uint256) {
    uint256 fee = ICurveFactoryPlainPool(curvePool).fee();
    uint256 amp = ICurveFactoryPlainPool(curvePool).A_precise();
    uint256 supply = IERC20Upgradeable(curveLpToken).totalSupply();
    uint256 x = ICurveFactoryPlainPool(curvePool).balances(uint256(baseIndex));
    uint256 y = ICurveFactoryPlainPool(curvePool).balances(uint256(debtIndex));
    uint256 left;
    uint256 right = dx / AMOMath.UNIT;
    while (left < right) {
      uint256 mid = (left + right + 1) / 2;
      uint256 swap_out = dx - mid * AMOMath.UNIT;
      (uint256 new_x, uint256 new_y, uint256 add_out) = AMOMath.addLiquidity(
        amp,
        fee,
        supply,
        x,
        y,
        mid * AMOMath.UNIT,
        0
      );
      swap_out = AMOMath.swap(amp, fee, new_x, new_y, swap_out);
      // add_out/swap_out <= num/den => left = mid
      // add_out/swap_out > num/den => right = mid - 1
      if (add_out * den <= num * swap_out) {
        left = mid;
      } else {
        right = mid - 1;
      }
    }
    return left * AMOMath.UNIT;
  }
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

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase

interface ICurveGauge {
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

interface ILegacyFurnace {
  function getUserInfo(address _account) external view returns (uint256 unrealised, uint256 realised);

  function deposit(uint256 _amount) external;

  function withdraw(address _recipient, uint256 _amount) external;

  function claim(address _recipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/ICLeverAMO.sol";

import "./RewardClaimable.sol";

// solhint-disable contract-name-camelcase
// solhint-disable not-rely-on-time
// solhint-disable reason-string

abstract contract CLeverAMOBase is OwnableUpgradeable, RewardClaimable, ERC20Upgradeable, ICLeverAMO {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when harvest bounty percentage is updated.
  /// @param _bountyPercentage The new harvest bounty percentage updated.
  event UpdateBountyPercentage(uint32 _bountyPercentage);

  /// @notice Emitted when owner update AMO configuration.
  /// @param _minAMO The minimum ratio of debt/base in curve pool updated.
  /// @param _maxAMO The maximum ratio of debt/base in curve pool updated.
  /// @param _minLPRatio The minimum ratio of lp/debt in contract updated.
  /// @param _maxLPRatio The maximum ratio of lp/debt in contract updated.
  event UpdateAMOConfig(uint64 _minAMO, uint64 _maxAMO, uint64 _minLPRatio, uint64 _maxLPRatio);

  /// @notice Emitted when owner update lock period.
  /// @param _lockPeriod The lock period updated.
  event UpdateLockPeriod(uint256 _lockPeriod);

  /// @notice Emitted when owner update minimum deposit amount.
  /// @param _minimumDeposit The minimum deposit amount updated.
  event UpdateMinimumDeposit(uint256 _minimumDeposit);

  /// @dev The precision used to compute various ratio.
  uint256 internal constant PRECISION = 1e18;

  /// @dev The precision used to compute various fees.
  uint256 private constant FEE_PRECISION = 1e9;

  /// @dev The maximum value of harvest bounty percentage.
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  /// @dev The number of seconds in 1 day.
  uint256 private constant DAY = 1 days;

  /// @inheritdoc ICLeverAMO
  address public immutable override baseToken;

  /// @inheritdoc ICLeverAMO
  address public immutable override debtToken;

  /// @inheritdoc ICLeverAMO
  address public immutable override curvePool;

  /// @inheritdoc ICLeverAMO
  address public immutable override curveLpToken;

  /// @inheritdoc ICLeverAMO
  address public immutable override furnace;

  /// @dev Compiler will pack this into single `uint256`.
  struct AMOConfig {
    // The minimum ratio of debt/base in curve pool.
    uint64 minAMO;
    // The maximum ratio of debt/base in curve pool.
    uint64 maxAMO;
    // The minimum ratio of lp/debt in contract.
    uint64 minLPRatio;
    // The maximum ratio of lp/debt in contract.
    uint64 maxLPRatio;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct LockBalance {
    // The amount of base token locked.
    uint128 balance;
    // The timestamp when the base token is unlocked.
    uint64 unlockAt;
    // Reserved field for future use.
    // solhint-disable-next-line var-name-mixedcase
    uint64 _;
  }

  /// @notice The initial ratio of lp/debt in contract, with precision 1e18.
  uint256 public initialRatio;

  /// @notice The config for AMO.
  AMOConfig public config;

  /// @notice The length of lock period in seconds.
  uint256 public lockPeriod;

  /// @notice The harvest bounty percentage, with precision 1e9.
  uint256 public bountyPercentage;

  /// @notice The amount of pending base token to convert.
  /// @dev This may come from donation.
  uint256 public pendingBaseToken;

  /// @notice The minimum amount of base token to deposit.
  uint256 public minimumDeposit;

  /// @dev Mapping from user address to a list of locked base tokens.
  mapping(address => LockBalance[]) private locks;

  /// @dev Mapping from user address to next lock index to process.
  mapping(address => uint256) private nextIndex;

  /// @dev reserved slots.
  uint256[20] private __gap;

  modifier NonZeroAmount(uint256 _amount) {
    require(_amount > 0, "CLeverAMO: amount is zero");
    _;
  }

  /********************************** Constructor **********************************/

  constructor(
    address _baseToken,
    address _debtToken,
    address _curvePool,
    address _curveLpToken,
    address _furnace
  ) {
    baseToken = _baseToken;
    debtToken = _debtToken;
    curvePool = _curvePool;
    curveLpToken = _curveLpToken;
    furnace = _furnace;
  }

  function _initialize(
    string memory _name,
    string memory _symbol,
    uint256 _initialRatio
  ) internal {
    OwnableUpgradeable.__Ownable_init();
    ERC20Upgradeable.__ERC20_init(_name, _symbol);

    initialRatio = _initialRatio;
    config = AMOConfig({
      minAMO: uint64(PRECISION),
      maxAMO: uint64(PRECISION * 3),
      minLPRatio: uint64(PRECISION / 2),
      maxLPRatio: uint64(PRECISION)
    });

    lockPeriod = 1 days; // default lock 1 day
    minimumDeposit = 10**18; // default 1 base token.
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc ICLeverAMO
  function totalDebtToken() external view override returns (uint256) {
    return _debtBalanceInContract();
  }

  /// @inheritdoc ICLeverAMO
  function totalCurveLpToken() external view override returns (uint256) {
    return _lpBalanceInContract();
  }

  /// @inheritdoc ICLeverAMO
  function ratio() public view override returns (uint256) {
    uint256 _debtBalance = _debtBalanceInContract();
    uint256 _lpBalance = _lpBalanceInContract();

    if (_debtBalance == 0) return initialRatio;
    else return (_lpBalance * PRECISION) / _debtBalance;
  }

  /// @notice Query the list of locked balance of the user.
  /// @param _user The address of user to query.
  /// @return _locks The list of locked balance.
  function getUserLocks(address _user) external view returns (LockBalance[] memory _locks) {
    uint256 _length = locks[_user].length;
    uint256 _startIndex = nextIndex[_user];

    _locks = new LockBalance[](_length - _startIndex);
    for (uint256 i = _startIndex; i < _length; i++) {
      _locks[i - _startIndex] = locks[_user][i];
    }
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc ICLeverAMO
  function deposit(uint256 _amount, address _recipient) external override {
    if (_amount == uint256(-1)) {
      _amount = IERC20Upgradeable(baseToken).balanceOf(msg.sender);
    }

    require(_amount >= minimumDeposit, "CLeverAMO: deposit amount too small");

    IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 _unlockAt = ((block.timestamp + lockPeriod + DAY - 1) / DAY) * DAY;
    uint256 _length = locks[_recipient].length;
    if (_length == 0 || locks[_recipient][_length - 1].unlockAt != _unlockAt) {
      locks[_recipient].push(LockBalance(uint128(_amount), uint64(_unlockAt), 0));
    } else {
      locks[_recipient][_length - 1].balance += uint128(_amount);
    }

    emit Deposit(msg.sender, _recipient, _amount, _unlockAt);
  }

  /// @inheritdoc ICLeverAMO
  function unlock(uint256 _minShareOut) external override returns (uint256 _shares) {
    // unlock base token
    uint256 _length = locks[msg.sender].length;
    uint256 _nextIndex = nextIndex[msg.sender];
    uint256 _unlocked;
    for (uint256 i = _nextIndex; i < _length; i++) {
      LockBalance memory _b = locks[msg.sender][i];
      if (_b.unlockAt <= block.timestamp) {
        _unlocked += _b.balance;
        delete locks[msg.sender][i];
      }
    }
    require(_unlocked > 0, "CLeverAMO: no unlocks");
    // update next index
    while (_nextIndex < _length) {
      LockBalance memory _b = locks[msg.sender][_nextIndex];
      if (_b.balance == 0) _nextIndex += 1;
      else break;
    }
    nextIndex[msg.sender] = _nextIndex;

    // convert to debt token and lp token
    (uint256 _total, uint256 _debtOut, uint256 _lpOut) = _checkpoint(_unlocked);
    _debtOut = (_debtOut * _unlocked) / _total;
    _lpOut = (_lpOut * _unlocked) / _total;

    uint256 _totalSupply = totalSupply();
    if (_totalSupply == 0) {
      // choose max(_debtOut, _lpOut) as initial supply
      _shares = _debtOut > _lpOut ? _debtOut : _lpOut;
    } else {
      // This already contains the user converted amount, we need to subtract it when computing shares.
      uint256 _debtBalance = _debtBalanceInContract();
      uint256 _lpBalance = _lpBalanceInContract();

      _debtOut = (_debtOut * _totalSupply) / (_debtBalance - _debtOut);
      _lpOut = (_lpOut * _totalSupply) / (_lpBalance - _lpOut);

      // use min(debt share, lp share) as new minted sharey
      _shares = _debtOut < _lpOut ? _debtOut : _lpOut;
    }

    require(_shares >= _minShareOut, "CLeverAMO: insufficient shares");

    _mint(msg.sender, _shares);

    emit Unlock(msg.sender, _unlocked, _shares, ratio());
  }

  /// @inheritdoc ICLeverAMO
  function withdraw(
    uint256 _shares,
    address _recipient,
    uint256 _minLpOut,
    uint256 _minDebtOut
  ) external override NonZeroAmount(_shares) returns (uint256 _lpTokenOut, uint256 _debtTokenOut) {
    _checkpoint(0);
    _checkpointUser(msg.sender);

    if (_shares == uint256(-1)) {
      _shares = balanceOf(msg.sender);
    }

    uint256 _totalSupply = totalSupply();
    _burn(msg.sender, _shares);

    _lpTokenOut = (_lpBalanceInContract() * _shares) / _totalSupply;
    _debtTokenOut = (_debtBalanceInContract() * _shares) / _totalSupply;

    require(_lpTokenOut >= _minLpOut, "CLeverAMO: insufficient lp token output");
    require(_debtTokenOut >= _minDebtOut, "CLeverAMO: insufficient debt token output");

    _withdrawDebtToken(_debtTokenOut, _recipient);
    _withdrawLpToken(_lpTokenOut, _recipient);

    emit Withdraw(msg.sender, _recipient, _shares, _debtTokenOut, _lpTokenOut, ratio());
  }

  /// @inheritdoc ICLeverAMO
  function withdrawToBase(
    uint256 _shares,
    address _recipient,
    uint256 _minBaseOut
  ) external override NonZeroAmount(_shares) returns (uint256 _baseTokenOut) {
    _checkpoint(0);
    _checkpointUser(msg.sender);

    if (_shares == uint256(-1)) {
      _shares = balanceOf(msg.sender);
    }

    uint256 _totalSupply = totalSupply();
    _burn(msg.sender, _shares);

    uint256 _lpTokenOut = (_lpBalanceInContract() * _shares) / _totalSupply;
    uint256 _debtTokenOut = (_debtBalanceInContract() * _shares) / _totalSupply;

    _withdrawDebtToken(_debtTokenOut, address(this));
    _withdrawLpToken(_lpTokenOut, address(this));

    emit Withdraw(msg.sender, _recipient, _shares, _debtTokenOut, _lpTokenOut, ratio());

    _baseTokenOut = _convertToBaseToken(_debtTokenOut, _lpTokenOut);
    require(_baseTokenOut >= _minBaseOut, "CLeverAMO: insufficient base token output");

    IERC20Upgradeable(baseToken).safeTransfer(_recipient, _baseTokenOut);
  }

  /// @inheritdoc ICLeverAMO
  function harvest(address _recipient, uint256 _minBaseOut) external override returns (uint256 _baseTokenOut) {
    // claim from furnace
    _baseTokenOut = _claimBaseFromFurnace();
    // harvest external rewards
    _baseTokenOut += _harvest();
    require(_baseTokenOut >= _minBaseOut, "CLeverAMO: insufficient harvested");

    uint256 _bounty = (_baseTokenOut * bountyPercentage) / FEE_PRECISION;

    (uint256 _debtAmount, uint256 _lpAmount, uint256 _ratio) = _convertFromBaseToken(_baseTokenOut - _bounty);
    _depositDebtToken(_debtAmount);
    _depositLpToken(_lpAmount);

    emit Harvest(_recipient, _baseTokenOut, _bounty, _debtAmount, _lpAmount, _ratio);

    if (_bounty > 0) {
      IERC20Upgradeable(baseToken).safeTransfer(_recipient, _bounty);
    }
  }

  /// @inheritdoc ICLeverAMO
  function checkpoint() external override {
    _checkpoint(0);
  }

  /// @inheritdoc ICLeverAMO
  function donate(uint256 _amount) external override {
    IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), _amount);

    pendingBaseToken += _amount;
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the harvest bounty percentage.
  /// @param _bountyPercentage The harvest bounty percentage to be updated, multipled by 1e9.
  function updateBountyPercentage(uint32 _bountyPercentage) external onlyOwner {
    require(_bountyPercentage <= MAX_HARVEST_BOUNTY, "CLeverAMO: fee too large");

    bountyPercentage = _bountyPercentage;

    emit UpdateBountyPercentage(_bountyPercentage);
  }

  /// @notice Update the AMO configuration.
  /// @param _minAMO The minimum ratio of debt/base in curve pool.
  /// @param _maxAMO The maximum ratio of debt/base in curve pool.
  /// @param _minLPRatio The minimum ratio of lp/debt in contract.
  /// @param _maxLPRatio The maximum ratio of lp/debt in contract.
  function updateAMOConfig(
    uint64 _minAMO,
    uint64 _maxAMO,
    uint64 _minLPRatio,
    uint64 _maxLPRatio
  ) external onlyOwner {
    require(_minAMO <= _maxAMO, "CLeverAMO: invalid amo ratio");
    require(_minLPRatio <= _maxLPRatio, "CLeverAMO: invalid lp ratio");

    config = AMOConfig(_minAMO, _maxAMO, _minLPRatio, _maxLPRatio);

    emit UpdateAMOConfig(_minAMO, _maxAMO, _minLPRatio, _maxLPRatio);
  }

  /// @notice Update the minimum deposit amount.
  /// @param _minimumDeposit The lock period in seconds to update.
  function updateMinimumDeposit(uint256 _minimumDeposit) external onlyOwner {
    require(_minimumDeposit >= 10**18, "CLeverAMO: invalid minimum deposit amount");
    minimumDeposit = _minimumDeposit;

    emit UpdateMinimumDeposit(_minimumDeposit);
  }

  /// @notice Update lock period for base token.
  /// @param _lockPeriod The lock period in seconds to update.
  function updateLockPeriod(uint256 _lockPeriod) external onlyOwner {
    require(_lockPeriod > 0 && _lockPeriod % DAY == 0, "CLeverAMO: invalid lock period");
    lockPeriod = _lockPeriod;

    emit UpdateLockPeriod(_lockPeriod);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to checkpoint AMO state before actions.
  /// @param _userSupply The delta amount of user supply.
  /// @return _baseAmount The total amount of base token used to convert.alias
  /// @return _debtTokenOut The total amount of debt token converted.
  /// @return _lpTokenOut The total amount of lp token converted.
  function _checkpoint(uint256 _userSupply)
    internal
    returns (
      uint256 _baseAmount,
      uint256 _debtTokenOut,
      uint256 _lpTokenOut
    )
  {
    _baseAmount = _claimBaseFromFurnace() + _userSupply;

    if (pendingBaseToken > 0) {
      _baseAmount += pendingBaseToken;
      pendingBaseToken = 0;
    }

    if (_baseAmount > 0) {
      uint256 _ratio;
      (_debtTokenOut, _lpTokenOut, _ratio) = _convertFromBaseToken(_baseAmount);

      _depositDebtToken(_debtTokenOut);
      _depositLpToken(_lpTokenOut);

      emit Checkpoint(_baseAmount, _debtTokenOut, _lpTokenOut, _ratio);
    }
  }

  /// @dev Internal function to return the current amount of debt token in contract.
  function _debtBalanceInContract() internal view virtual returns (uint256);

  /// @dev Internal function to return the current amount of lp token in contract.
  function _lpBalanceInContract() internal view virtual returns (uint256);

  /// @dev Internal function to convert base token to debt token and curve lp token.
  /// @param _amount The amount of base token to convert.
  /// @return _debtTokenOut The amount of debt token received.
  /// @return _lpTokenOut The amount of lp token received.
  /// @return _ratio The ratio between lp token and debt token after the convertion.
  function _convertFromBaseToken(uint256 _amount)
    internal
    virtual
    returns (
      uint256 _debtTokenOut,
      uint256 _lpTokenOut,
      uint256 _ratio
    );

  /// @dev Internal function to convert debt token and lp token to base token.
  /// @param _debtTokenAmount The amount of debt token to convert.
  /// @param _lpTokenAmount The amount of lp token to convert.
  /// @return _baseTokenOut The amount of base token received.
  function _convertToBaseToken(uint256 _debtTokenAmount, uint256 _lpTokenAmount)
    internal
    virtual
    returns (uint256 _baseTokenOut);

  /// @dev Internal function to deposit debt token into furnace.
  /// @param _amount The amount of debt token to deposit.
  function _depositDebtToken(uint256 _amount) internal virtual;

  /// @dev Internal function to withdraw debt token from furnace.
  /// @param _amount The amount of debt token to withdraw.
  /// @param _recipient The address recipient who will receive the debt token.
  function _withdrawDebtToken(uint256 _amount, address _recipient) internal virtual;

  /// @dev Internal function to claim converted base token from furnace.
  /// @return _baseTokenOut The amount of base token received.
  function _claimBaseFromFurnace() internal virtual returns (uint256 _baseTokenOut);

  /// @dev Internal function to deposit lp token to external protocol to earn rewards.
  /// @param _amount The amount of lp token to deposit.
  function _depositLpToken(uint256 _amount) internal virtual;

  /// @dev Internal function to withdraw lp token from external protocol.
  /// @param _amount The amount of lp token to withdraw.
  /// @param _recipient The address recipient who will receive the lp token.
  function _withdrawLpToken(uint256 _amount, address _recipient) internal virtual;

  /// @dev Internal function to harvest rewards from external protocol and convert to base token.
  /// @return _baseTokenOut The amount of base token harvested.
  function _harvest() internal virtual returns (uint256 _baseTokenOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase

interface ICurveMinter {
  function mint(address gauge_addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "../../strategies/ConcentratorStrategyBase.sol";

interface ICLeverAMOStrategy is IConcentratorStrategy {
  function strategyBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase

library AMOMath {
  /// @dev The precision used to compute invariant and sap output.
  uint256 private constant A_PRECISION = 100;

  /// @dev The denominator used to compute swap fee.
  uint256 private constant FEE_DENOMINATOR = 10**10;

  /// @dev The base unit of input amount.
  uint256 internal constant UNIT = 10**9;

  /// @dev Compute invariant for curve stable swap.
  /// See function `get_D` in https://etherscan.io/address/0xf9078fb962a7d13f55d40d49c8aa6472abd1a5a6#code
  /// @param amp The amplification parameter equals: A n^(n-1)
  /// @param x The balance of token0.
  /// @param y The balance of token1.
  function getInvariant(
    uint256 amp,
    uint256 x,
    uint256 y
  ) private pure returns (uint256) {
    // A * (x + y) * n^n + D = A * D * n^n + D^(n+1) / (n^n * x * y)
    // assume amp = A * n^(n-1), then
    // D^3 + (amp * n - 1) * 4xy * D = amp * n * (x + y) * 4 * x * y
    //
    // let f(D) = D^3 + (amp * n - 1) * 4xy * D - amp * n * (x + y) * 4 * x * y
    // f'(D) = 3D^2 + (amp * n - 1) * 4xy
    //
    // D' = D - f(D) / f'(D) =>
    // D' = ((2D^3)/(4xy) + amp * n * (x + y)) / (amp * n - 1 + 3D^2 / (4xy))
    //
    // assume dp = D^3 / (4xy), ann = amp * n, then
    // D' = (2dp + ann * (x + y)) * D / ((ann - 1) * D + 3dp)
    uint256 sum = x + y;
    if (sum == 0) {
      return 0;
    }
    uint256 invariant = sum;
    amp *= 2;
    for (uint256 i = 0; i < 255; i++) {
      uint256 dp = (((invariant * invariant) / x) * invariant) / y / 4;
      uint256 prev_invariant = invariant;
      invariant =
        (((amp * sum) / A_PRECISION + dp * 2) * invariant) /
        (((amp - A_PRECISION) * invariant) / A_PRECISION + 3 * dp);
      if (invariant > prev_invariant) {
        if (invariant - prev_invariant <= 1) {
          return invariant;
        }
      } else {
        if (prev_invariant - invariant <= 1) {
          return invariant;
        }
      }
    }
    revert("invariant not converging");
  }

  /// @dev Compute token output given invariant and balance
  /// @param amp The amplification parameter equals: A n^(n-1)
  /// @param invariant The invariant for curve stable swap.
  /// @param x The balance of input token with input amount.
  function getTokenOut(
    uint256 amp,
    uint256 invariant,
    uint256 x
  ) private pure returns (uint256) {
    // A * (x + y) * n^n + D = A * D * n^n + D^(n+1) / (n^n * x * y) =>
    // y + x + D/(A * n^n) = D + D^(n+1) / (n^(2n) * x * y * A)
    //
    // assume amp = A * n^(n-1), then
    // y^2 + (x + D/(amp * n) - D) * y = D^3 / (4 * x * amp * n)
    //
    // f(y) = y^2 + (x + D/(amp * n) - D) * y - D^3 / (4 * x * amp * n)
    // f'(y) = 2y + (x + D/(amp * n) - D)
    //
    // assume ann = amp * n, b = x + D/ann, c = D^3/(4x * ann)
    // y' = (y^2 + c) / (2y + b - D)
    amp *= 2;
    uint256 b = x + (invariant * A_PRECISION) / amp;
    uint256 c = (invariant * invariant) / (x * 2);
    c = (c * invariant * A_PRECISION) / (amp * 2);

    uint256 y = invariant;
    for (uint256 i = 0; i < 255; i++) {
      uint256 prev_y = y;
      y = (y * y + c) / (2 * y + b - invariant);
      if (y > prev_y) {
        if (y - prev_y <= 1) {
          return y;
        }
      } else {
        if (prev_y - y <= 1) {
          return y;
        }
      }
    }
    revert("y not converging");
  }

  /// @dev Compute the result of add liquidity, including (new_x, new_y, new_minted).
  /// See function `add_liquidity` in https://etherscan.io/address/0xf9078fb962a7d13f55d40d49c8aa6472abd1a5a6#code
  /// @param amp The amplification parameter equals: A n^(n-1)
  /// @param fee The swap fee from curve pool.
  /// @param supply The current total supply of curve pool
  /// @param x The balance of token0.
  /// @param y The balance of token1.
  /// @param dx The input amount of token0.
  /// @param dy The input amount of token1.
  function addLiquidity(
    uint256 amp,
    uint256 fee,
    uint256 supply,
    uint256 x,
    uint256 y,
    uint256 dx,
    uint256 dy
  )
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    fee = fee / 2; // the base_fee for each token
    uint256 invariant0 = getInvariant(amp, x, y);

    dx += x;
    dy += y;
    uint256 invariant1 = getInvariant(amp, dx, dy);

    // compute the difference between new balance and ideal balance
    uint256 diff_x = (invariant1 * x) / invariant0;
    uint256 diff_y = (invariant1 * y) / invariant0;
    if (diff_x > dx) {
      diff_x = diff_x - dx;
    } else {
      diff_x = dx - diff_x;
    }
    if (diff_y > dy) {
      diff_y = diff_y - dy;
    } else {
      diff_y = dy - diff_y;
    }

    // compute new balances after fee
    diff_x = (diff_x * fee) / FEE_DENOMINATOR;
    diff_y = (diff_y * fee) / FEE_DENOMINATOR;
    // reuse `x` and `y` for new reserves to avoid stack too deep.
    x = dx - diff_x / 2; // this is real new balance 0
    y = dy - diff_y / 2; // this is real new balance 1

    // compute new minted
    dx -= diff_x;
    dy -= diff_y;
    invariant1 = getInvariant(amp, dx, dy);
    // reuse `supply` as new minted lp to avoid stack too deep
    supply = (supply * (invariant1 - invariant0)) / invariant0;

    return (x, y, supply);
  }

  /// @dev Compute the result of swap
  /// @param amp The amplification parameter equals: A n^(n-1)
  /// @param fee The swap fee from curve pool.
  /// @param x The balance of token0.
  /// @param y The balance of token1.
  /// @param dx The input amount of token0.
  function swap(
    uint256 amp,
    uint256 fee,
    uint256 x,
    uint256 y,
    uint256 dx
  ) internal pure returns (uint256) {
    uint256 invariant = getInvariant(amp, x, y);
    uint256 dy = y - getTokenOut(amp, invariant, x + dx) - 1;
    return dy - (dy * fee) / FEE_DENOMINATOR;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

abstract contract RewardClaimable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when someone claim pending rewards.
  /// @param token The address of reward token.
  /// @param owner The address of reward token owner.
  /// @param recipient The address of reward token recipient.
  /// @param amount The amount of reward token claimed.
  event Claim(address indexed token, address indexed owner, address indexed recipient, uint256 amount);

  struct AccountRewardInfo {
    uint256 pending;
    uint256 rewardPerSharePaid;
  }

  /// @dev The precision used to compute reward tokens.
  uint256 internal constant REWARD_PRECISION = 1e18;

  /// @notice The list of rewards token.
  address[] public rewards;

  /// @notice Mapping from reward token address to reward per share.
  mapping(address => uint256) public rewardPerShare;

  /// @dev Mapping from account address to reward token address to reward info.
  mapping(address => mapping(address => AccountRewardInfo)) private accountRewards;

  function _initialize(address[] memory _rewards) internal {
    rewards = _rewards;
  }

  /// @notice Return the list amount of claimable reward tokens.
  function claimable(address _user) external view returns (uint256[] memory) {
    uint256 _length = rewards.length;
    uint256 _share = _getShares(_user);
    uint256[] memory _amounts = new uint256[](_length);
    for (uint256 i = 0; i < _length; i++) {
      address _token = rewards[i];
      AccountRewardInfo memory _info = accountRewards[_user][_token];

      _amounts[i] = _info.pending + ((rewardPerShare[_token] - _info.rewardPerSharePaid) * _share) / REWARD_PRECISION;
    }
    return _amounts;
  }

  /// @notice claim pending rewards from the contract.
  /// @dev If `_user` is not the caller, `_user` and `_recipient` should be the same.
  /// @param _user The address of account to claim.
  /// @param _recipient The address recipient who will receive the pending rewards.
  function claim(address _user, address _recipient) external {
    if (_user != msg.sender) {
      require(_user == _recipient, "forbid claim other to other");
    }

    _checkpointUser(_user);

    uint256 _length = rewards.length;
    for (uint256 i = 0; i < _length; i++) {
      address _token = rewards[i];
      uint256 _pending = accountRewards[_user][_token].pending;
      accountRewards[_user][_token].pending = 0;
      if (_pending > 0) {
        IERC20Upgradeable(_token).safeTransfer(_recipient, _pending);
      }

      emit Claim(_token, _user, _recipient, _pending);
    }
  }

  /// @notice External call to checkpoint user state.
  /// @param _user The address of user to update.
  function checkpointUser(address _user) external {
    _checkpointUser(_user);
  }

  /// @dev Internal function to checkpoint user state change.
  /// @param _user The address of user to update.
  function _checkpointUser(address _user) internal {
    uint256 _share = _getShares(_user);
    uint256 _length = rewards.length;
    for (uint256 i = 0; i < _length; i++) {
      address _token = rewards[i];
      uint256 _rewardPerShare = rewardPerShare[_token];
      AccountRewardInfo memory _info = accountRewards[_user][_token];

      _info.pending += ((_rewardPerShare - _info.rewardPerSharePaid) * _share) / REWARD_PRECISION;
      _info.rewardPerSharePaid = _rewardPerShare;
      accountRewards[_user][_token] = _info;
    }
  }

  /// @dev Internal function to return user shares.
  /// @param _user The address of user to query.
  function _getShares(address _user) internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ICLeverAMO {
  /// @notice Emitted when someone deposit base token to the contract.
  /// @param owner The owner of the base token.
  /// @param recipient The recipient of the locked base token.
  /// @param amount The amount of base token deposited.
  /// @param unlockAt The timestamp in second when the pool share is unlocked.
  event Deposit(address indexed owner, address indexed recipient, uint256 amount, uint256 unlockAt);

  /// @notice Emitted when someone unlock base token to pool share.
  /// @param owner The owner of the locked base token.
  /// @param amount The amount of base token unlocked.
  /// @param share The amount of pool share received.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Unlock(address indexed owner, uint256 amount, uint256 share, uint256 ratio);

  /// @notice Emitted when someone withdraw pool share.
  /// @param owner The owner of the pool share.
  /// @param recipient The recipient of the withdrawn debt token and lp token.
  /// @param shares The amount of pool share to withdraw.
  /// @param debtAmount The current amount of debt token received.
  /// @param lpAmount The current amount of lp token received.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Withdraw(
    address indexed owner,
    address indexed recipient,
    uint256 shares,
    uint256 debtAmount,
    uint256 lpAmount,
    uint256 ratio
  );

  /// @notice Emitted when someone call harvest.
  /// @param caller The address of the caller.
  /// @param baseAmount The amount of base token harvested.
  /// @param bounty The amount of base token as harvest bounty.
  /// @param debtAmount The current amount of debt token harvested.
  /// @param lpAmount The current amount of lp token harvested.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Harvest(
    address indexed caller,
    uint256 baseAmount,
    uint256 bounty,
    uint256 debtAmount,
    uint256 lpAmount,
    uint256 ratio
  );

  /// @notice Emitted when someone checkpoint AMO state.
  /// @param baseAmount The amount of base token used to convert.
  /// @param debtAmount The current amount of debt token converted.
  /// @param lpAmount The current amount of lp token converted.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Checkpoint(uint256 baseAmount, uint256 debtAmount, uint256 lpAmount, uint256 ratio);

  /// @notice Emitted when someone donate base token to the contract.
  /// @param caller The address of the caller.
  /// @param amount The amount of base token donated.
  event Donate(address indexed caller, uint256 amount);

  /// @notice Emitted when someone call rebalance.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  /// @param startPoolRatio The ratio between debt token and base token in curve pool before rebalance.
  /// @param targetPoolRatio The ratio between debt token and base token in curve pool after rebalance.
  event Rebalance(uint256 ratio, uint256 startPoolRatio, uint256 targetPoolRatio);

  /// @notice The address of base token.
  function baseToken() external view returns (address);

  /// @notice The address of debt token.
  function debtToken() external view returns (address);

  /// @notice The address of Curve base/debt pool.
  function curvePool() external view returns (address);

  /// @notice The address of Curve base/debt lp token.
  function curveLpToken() external view returns (address);

  /// @notice The address of furnace contract for debt token.
  function furnace() external view returns (address);

  /// @notice The total amount of debt token in contract.
  function totalDebtToken() external view returns (uint256);

  /// @notice The total amount of curve lp token in contract.
  function totalCurveLpToken() external view returns (uint256);

  /// @notice The current ratio between curve lp token and debt token, with precision 1e18.
  function ratio() external view returns (uint256);

  /// @notice Deposit base token to the contract.
  /// @dev Use `_amount` when caller wants to deposit all his base token.
  /// @param _amount The amount of base token to deposit.
  /// @param _recipient The address recipient who will receive the base token.
  function deposit(uint256 _amount, address _recipient) external;

  /// @notice Unlock pool share from the contract.
  /// @param _minShareOut The minimum amount of shares should receive.
  /// @return shares The amount of shares received.
  function unlock(uint256 _minShareOut) external returns (uint256 shares);

  /// @notice Burn shares and withdraw to debt token and lp token according to current ratio.
  /// @dev Use `_shares` when caller wants to withdraw all his shares.
  /// @param _shares The amount of pool shares to burn.
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _minLpOut The minimum of lp token should receive.
  /// @param _minDebtOut The minimum of debt token should receive.
  /// @return lpTokenOut The amount of lp token received.
  /// @return debtTokenOut The amount of debt token received.
  function withdraw(
    uint256 _shares,
    address _recipient,
    uint256 _minLpOut,
    uint256 _minDebtOut
  ) external returns (uint256 lpTokenOut, uint256 debtTokenOut);

  /// @notice Burn shares and withdraw to base token.
  /// @dev Use `_shares` when caller wants to withdraw all his shares.
  /// @param _shares The amount of pool shares to burn.
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _minBaseOut The minimum of base token should receive.
  /// @return baseTokenOut The amount of base token received.
  function withdrawToBase(
    uint256 _shares,
    address _recipient,
    uint256 _minBaseOut
  ) external returns (uint256 baseTokenOut);

  /// @notice Someone donate base token to the contract.
  /// @param _amount The amount of base token to donate.
  function donate(uint256 _amount) external;

  /// @notice rebalance the curve pool based on tokens in curve pool.
  /// @param _withdrawAmount The amount of debt token or lp token to withdraw.
  /// @param _minOut The minimum output token to control slippage.
  /// @param _targetRangeLeft The left end point of the target range, multiplied by 1e18.
  /// @param _targetRangeRight The right end point of the target range, multiplied by 1e18.
  function rebalance(
    uint256 _withdrawAmount,
    uint256 _minOut,
    uint256 _targetRangeLeft,
    uint256 _targetRangeRight
  ) external;

  /// @notice harvest the pending rewards and reinvest to the pool.
  /// @param _recipient The address of recipient who will receive the harvest bounty.
  /// @param _minBaseOut The minimum of base token should harvested.
  /// @return baseTokenOut The amount of base token harvested.
  function harvest(address _recipient, uint256 _minBaseOut) external returns (uint256 baseTokenOut);

  /// @notice External call to checkpoint AMO state.
  function checkpoint() external;
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

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../interfaces/IConcentratorStrategy.sol";

// solhint-disable reason-string
// solhint-disable no-empty-blocks

abstract contract ConcentratorStrategyBase is IConcentratorStrategy, Initializable {
  /// @notice The address of operator.
  address public operator;

  /// @notice The list of rewards token.
  address[] public rewards;

  /// @dev reserved slots.
  uint256[48] private __gap;

  modifier onlyOperator() {
    require(msg.sender == operator, "ConcentratorStrategy: only operator");
    _;
  }

  // fallback function to receive eth.
  receive() external payable {}

  function _initialize(address _operator, address[] memory _rewards) internal {
    _checkRewards(_rewards);

    operator = _operator;
    rewards = _rewards;
  }

  /// @inheritdoc IConcentratorStrategy
  function updateRewards(address[] memory _rewards) public virtual override onlyOperator {
    _checkRewards(_rewards);

    delete rewards;
    rewards = _rewards;
  }

  /// @inheritdoc IConcentratorStrategy
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external payable override onlyOperator returns (bool, bytes memory) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }

  /// @inheritdoc IConcentratorStrategy
  function prepareMigrate(address _newStrategy) external virtual override onlyOperator {}

  /// @inheritdoc IConcentratorStrategy
  function finishMigrate(address _newStrategy) external virtual override onlyOperator {}

  /// @dev Internal function to validate rewards list.
  /// @param _rewards The address list of reward tokens.
  function _checkRewards(address[] memory _rewards) internal pure {
    for (uint256 i = 0; i < _rewards.length; i++) {
      require(_rewards[i] != address(0), "ConcentratorStrategy: zero reward token");
      for (uint256 j = 0; j < i; j++) {
        require(_rewards[i] != _rewards[j], "ConcentratorStrategy: duplicated reward token");
      }
    }
  }
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