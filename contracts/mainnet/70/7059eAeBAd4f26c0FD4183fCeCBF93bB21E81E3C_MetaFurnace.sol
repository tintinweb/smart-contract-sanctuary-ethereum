// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";

import "../../interfaces/IERC20Metadata.sol";
import "../interfaces/ICLeverToken.sol";
import "../interfaces/IMetaFurnace.sol";
import "../interfaces/IYieldStrategy.sol";

// solhint-disable reason-string, not-rely-on-time

contract MetaFurnace is OwnableUpgradeable, IMetaFurnace {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UpdateWhitelist(address indexed _whitelist, bool _status);
  event UpdateFeeInfo(address indexed _platform, uint32 _platformPercentage, uint32 _bountyPercentage);
  event UpdateYieldInfo(uint16 _percentage, uint80 _threshold);
  event MigrateYieldStrategy(address _oldStrategy, address _newStrategy);
  event UpdatePeriodLength(uint256 _length);

  uint256 private constant E128 = 2**128;
  uint256 private constant PRECISION = 1e9;
  uint256 private constant MAX_PLATFORM_FEE = 2e8; // 20%
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  /// @notice If the unrealised is not paid off,
  /// the realised token in n sequential distribute is
  ///    user_unrealised * (reward_1 / total_unrealised_1)
  ///  + user_unrealised * (reward_1 / total_unrealised_1) * (reward_2 / total_unrealised_2)
  ///  + ...
  /// the unrealised token in n sequential distribute is
  ///    user_unrealised * (total_unrealised_1 - reward_1) / total_unrealised_1 * (total_unrealised_2 - reward_2) / total_unrealised_2 * ...
  ///
  /// So we can maintain a variable `accUnrealisedFraction` which is a product of `(total_unrealised - reward) / total_unrealised`.
  /// And keep track of this variable on each deposit/withdraw/claim, the unrealised debtToken of the user should be
  ///                                accUnrealisedFractionPaid
  ///                   unrealised * -------------------------
  ///                                  accUnrealisedFraction
  /// Also, the debt will paid off in some case, we record a global variable `lastPaidOffDistributeIndex` and an user
  /// specific variable `lastDistributeIndex` to check if the debt is paid off during `(lastDistributeIndex, distributeIndex]`.
  ///
  /// And to save the gas usage, an `uint128` is used to store `accUnrealisedFraction` and `accUnrealisedFractionPaid`.
  /// More specifically, it is in range [0, 2^128), means the real number `fraction / 2^128`. If the value is 0, it
  /// means the value of the faction is 1.
  ///
  /// @dev Compiler will pack this into two `uint256`.
  struct UserInfo {
    // The total amount of debtToken unrealised.
    uint128 unrealised;
    // The total amount of debtToken realised.
    uint128 realised;
    // The checkpoint for global `accUnrealisedFraction`, multipled by 1e9.
    uint192 accUnrealisedFractionPaid;
    // The distribute index record when use interacted the contract.
    uint64 lastDistributeIndex;
  }

  /// @dev Compiler will pack this into two `uint256`.
  struct FurnaceInfo {
    // The total amount of debtToken unrealised.
    uint128 totalUnrealised;
    // The total amount of debtToken realised.
    uint128 totalRealised;
    // The accumulated unrealised fraction, multipled by 2^128.
    uint128 accUnrealisedFraction;
    // The distriubed index, will be increased each time the function `distribute` is called.
    uint64 distributeIndex;
    // The distriubed index when all debtToken is paied off.
    uint64 lastPaidOffDistributeIndex;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct FeeInfo {
    // The address of recipient of platform fee
    address platform;
    // The percentage of rewards to take for platform on harvest, multipled by 1e9.
    uint32 platformPercentage;
    // The percentage of rewards to take for caller on harvest, multipled by 1e9.
    uint32 bountyPercentage;
  }

  /// @dev Compiler will pack this into single `uint256`.
  struct YieldInfo {
    // The address of yield strategy.
    address strategy;
    // The percentage of token to deposit to yield strategy, multipled by 1e5.
    uint16 percentage;
    // The minimum amount to deposit to yield strategy, `uint80` should be enough for most token.
    uint80 threshold;
  }

  /// @inheritdoc IMetaFurnace
  address public override baseToken;

  /// @inheritdoc IMetaFurnace
  address public override debtToken;

  /// @notice The global furnace information.
  FurnaceInfo public furnaceInfo;

  /// @notice Mapping from user address to user info.
  mapping(address => UserInfo) public userInfo;

  /// @notice Mapping from user address to whether it is whitelisted.
  mapping(address => bool) public isWhitelisted;

  /// @notice The fee information, including platform and harvest bounty.
  FeeInfo public feeInfo;

  /// @notice The yield information for free base token in this contract.
  YieldInfo public yieldInfo;

  /// @dev Compiler will pack this into single `uint256`.
  struct LinearReward {
    // The number of debt token to pay each second.
    uint128 ratePerSecond;
    // The length of reward period in seconds.
    // If the value is zero, the reward will be distributed immediately.
    uint32 periodLength;
    // The timesamp in seconds when reward is updated.
    uint48 lastUpdate;
    // The finish timestamp in seconds of current reward period.
    uint48 finishAt;
  }

  /// @notice The reward distribute information.
  LinearReward public rewardInfo;

  modifier onlyWhitelisted() {
    require(isWhitelisted[msg.sender], "Furnace: only whitelisted");
    _;
  }

  function initialize(address _baseToken, address _debtToken) external initializer {
    OwnableUpgradeable.__Ownable_init();

    require(_baseToken != address(0), "Furnace: zero address");
    require(_debtToken != address(0), "Furnace: zero address");
    require(IERC20Metadata(_debtToken).decimals() == 18, "Furnace: decimal mismatch");
    require(IERC20Metadata(_baseToken).decimals() <= 18, "Furnace: decimal too large");

    baseToken = _baseToken;
    debtToken = _debtToken;
  }

  /********************************** View Functions **********************************/

  /// @inheritdoc IMetaFurnace
  function getUserInfo(address _account) external view override returns (uint256 unrealised, uint256 realised) {
    UserInfo memory _userInfo = userInfo[_account];
    FurnaceInfo memory _furnaceInfo = furnaceInfo;
    if (_userInfo.lastDistributeIndex < _furnaceInfo.lastPaidOffDistributeIndex) {
      // In this case, all unrealised is paid off since last operate.
      return (0, _userInfo.unrealised + _userInfo.realised);
    } else {
      // extra plus 1, make sure we round up in division
      uint128 _newUnrealised = SafeCastUpgradeable.toUint128(
        _muldiv128(
          _userInfo.unrealised,
          _furnaceInfo.accUnrealisedFraction,
          uint128(_userInfo.accUnrealisedFractionPaid)
        )
      ) + 1;
      if (_newUnrealised >= _userInfo.unrealised) {
        _newUnrealised = _userInfo.unrealised;
      }
      uint128 _newRealised = _userInfo.unrealised - _newUnrealised + _userInfo.realised; // never overflow here
      return (_newUnrealised, _newRealised);
    }
  }

  /// @notice Return the total amount of free baseToken in this contract, including staked in YieldStrategy.
  function totalBaseTokenInPool() public view returns (uint256) {
    uint256 _leftover = 0;
    LinearReward memory _rewardInfo = rewardInfo;
    if (_rewardInfo.periodLength != 0) {
      if (block.timestamp < _rewardInfo.finishAt) {
        _leftover = (_rewardInfo.finishAt - block.timestamp) * _rewardInfo.ratePerSecond;
      }
    }
    YieldInfo memory _info = yieldInfo;
    uint256 _balanceInContract = IERC20Upgradeable(baseToken).balanceOf(address(this)).sub(_leftover);
    if (_info.strategy == address(0)) {
      return _balanceInContract;
    } else {
      return _balanceInContract.add(IYieldStrategy(_info.strategy).totalUnderlyingToken());
    }
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IMetaFurnace
  function deposit(address _account, uint256 _amount) external override {
    require(_amount > 0, "Furnace: deposit zero amount");

    // transfer token into contract
    IERC20Upgradeable(debtToken).safeTransferFrom(msg.sender, address(this), _amount);

    _deposit(_account, _amount);
  }

  /// @inheritdoc IMetaFurnace
  function withdraw(address _recipient, uint256 _amount) external override {
    require(_amount > 0, "Furnace: withdraw zero amount");

    _updateUserInfo(msg.sender);
    _withdraw(_recipient, _amount);
  }

  /// @inheritdoc IMetaFurnace
  function withdrawAll(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _withdraw(_recipient, userInfo[msg.sender].unrealised);
  }

  /// @inheritdoc IMetaFurnace
  function claim(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _claim(_recipient);
  }

  /// @inheritdoc IMetaFurnace
  function exit(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _withdraw(_recipient, userInfo[msg.sender].unrealised);
    _claim(_recipient);
  }

  /// @inheritdoc IMetaFurnace
  function distribute(
    address _origin,
    address _token,
    uint256 _amount
  ) external override onlyWhitelisted {
    require(_token == baseToken, "Furnace: invalid distributed token");

    _distribute(_origin, _amount);
  }

  /// @notice Harvest the pending reward and convert to cvxCRV.
  /// @param _recipient - The address of account to receive harvest bounty.
  /// @param _minimumOut - The minimum amount of cvxCRV should get.
  /// @return the amount of baseToken harvested.
  function harvest(address _recipient, uint256 _minimumOut) external returns (uint256) {
    address _strategy = yieldInfo.strategy;
    if (_strategy == address(0)) return 0;

    // 1. harvest from yield strategy
    (uint256 _amount, , ) = IYieldStrategy(_strategy).harvest();
    require(_amount >= _minimumOut, "Furnace: insufficient harvested amount");

    emit Harvest(msg.sender, _amount);

    if (_amount > 0) {
      uint256 _distributeAmount = _amount;
      FeeInfo memory _feeInfo = feeInfo;
      // 2. take platform fee
      if (_feeInfo.platformPercentage > 0) {
        uint256 _platformFee = (_feeInfo.platformPercentage * _distributeAmount) / PRECISION;
        IERC20Upgradeable(baseToken).safeTransfer(_feeInfo.platform, _platformFee);
        _distributeAmount = _distributeAmount - _platformFee; // never overflow here
      }
      // 3. take harvest bounty
      if (_feeInfo.bountyPercentage > 0) {
        uint256 _harvestBounty = (_feeInfo.bountyPercentage * _distributeAmount) / PRECISION;
        IERC20Upgradeable(baseToken).safeTransfer(_recipient, _harvestBounty);
        _distributeAmount = _distributeAmount - _harvestBounty; // never overflow here
      }
      // 3. distribute harvest baseToken to pay debtToken
      _distribute(address(this), _distributeAmount);
    }
    return _amount;
  }

  /// @notice External helper function to update global debt.
  function updatePendingDistribution() external {
    _updatePendingDistribution();
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the status of a list of whitelisted accounts.
  /// @param _whitelists The address list of whitelisted accounts.
  /// @param _status The status to update.
  function updateWhitelists(address[] memory _whitelists, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _whitelists.length; i++) {
      // solhint-disable-next-line reason-string
      require(_whitelists[i] != address(0), "Furnace: zero whitelist address");
      isWhitelisted[_whitelists[i]] = _status;

      emit UpdateWhitelist(_whitelists[i], _status);
    }
  }

  /// @notice Update yield info for baseToken in this contract.
  /// @param _percentage The stake percentage to be updated, multipled by 1e5.
  /// @param _threshold The stake threshold to be updated.
  function updateYieldInfo(uint16 _percentage, uint80 _threshold) external onlyOwner {
    require(_percentage <= 1e5, "Furnace: percentage too large");

    yieldInfo.percentage = _percentage;
    yieldInfo.threshold = _threshold;

    emit UpdateYieldInfo(_percentage, _threshold);
  }

  /// @notice Migrate baseToken in old yield strategy contract to the given one.
  /// @dev If the given strategy is zero address, we will just withdraw all token from the current one.
  /// @param _strategy The address of new yield strategy.
  function migrateStrategy(address _strategy) external onlyOwner {
    YieldInfo memory _yieldInfo = yieldInfo;

    if (_yieldInfo.strategy != address(0)) {
      if (_strategy == address(0)) {
        IYieldStrategy(_yieldInfo.strategy).withdraw(
          address(this),
          IYieldStrategy(_yieldInfo.strategy).totalYieldToken(),
          true
        );
      } else {
        // migrate and notify
        uint256 _totalMigrate = IYieldStrategy(_yieldInfo.strategy).migrate(_strategy);
        IYieldStrategy(_strategy).onMigrateFinished(_totalMigrate);
      }
    }

    yieldInfo.strategy = _strategy;

    emit MigrateYieldStrategy(_yieldInfo.strategy, _strategy);
  }

  /// @notice Update the fee information.
  /// @param _platform The platform address to be updated.
  /// @param _platformPercentage The platform fee percentage to be updated, multipled by 1e9.
  /// @param _bountyPercentage The harvest bounty percentage to be updated, multipled by 1e9.
  function updatePlatformInfo(
    address _platform,
    uint32 _platformPercentage,
    uint32 _bountyPercentage
  ) external onlyOwner {
    require(_platform != address(0), "Furnace: zero address");
    require(_platformPercentage <= MAX_PLATFORM_FEE, "Furnace: fee too large");
    require(_bountyPercentage <= MAX_HARVEST_BOUNTY, "Furnace: fee too large");

    feeInfo = FeeInfo(_platform, _platformPercentage, _bountyPercentage);

    emit UpdateFeeInfo(_platform, _platformPercentage, _bountyPercentage);
  }

  /// @notice Update the reward period length.
  /// @dev The modification will be effictive after next reward distribution.
  /// @param _length The period length to be updated.
  function updatePeriodLength(uint32 _length) external onlyOwner {
    rewardInfo.periodLength = _length;

    emit UpdatePeriodLength(_length);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to reduce global debt based on pending rewards.
  /// This function should be called before any mutable state change.
  function _updatePendingDistribution() internal {
    LinearReward memory _info = rewardInfo;
    if (_info.periodLength > 0) {
      uint256 _currentTime = _info.finishAt;
      if (_currentTime > block.timestamp) {
        _currentTime = block.timestamp;
      }
      uint256 _duration = _currentTime >= _info.lastUpdate ? _currentTime - _info.lastUpdate : 0;
      if (_duration > 0) {
        _info.lastUpdate = uint48(block.timestamp);
        rewardInfo = _info;

        _reduceGlobalDebt(_duration.mul(_info.ratePerSecond));
      }
    }
  }

  /// @dev Internal function called when user interacts with the contract.
  /// @param _account The address of user to update.
  function _updateUserInfo(address _account) internal {
    _updatePendingDistribution();

    UserInfo memory _userInfo = userInfo[_account];
    uint128 _accUnrealisedFraction = furnaceInfo.accUnrealisedFraction;
    uint64 _distributeIndex = furnaceInfo.distributeIndex;
    if (_userInfo.lastDistributeIndex < furnaceInfo.lastPaidOffDistributeIndex) {
      // In this case, all unrealised is paid off since last operate.
      userInfo[_account] = UserInfo({
        unrealised: 0,
        realised: _userInfo.unrealised + _userInfo.realised, // never overflow here
        accUnrealisedFractionPaid: 0,
        lastDistributeIndex: _distributeIndex
      });
    } else {
      // extra plus 1, make sure we round up in division
      uint128 _newUnrealised = SafeCastUpgradeable.toUint128(
        _muldiv128(_userInfo.unrealised, _accUnrealisedFraction, uint128(_userInfo.accUnrealisedFractionPaid))
      ) + 1;
      if (_newUnrealised >= _userInfo.unrealised) {
        _newUnrealised = _userInfo.unrealised;
      }
      uint128 _newRealised = _userInfo.unrealised - _newUnrealised + _userInfo.realised; // never overflow here
      userInfo[_account] = UserInfo({
        unrealised: _newUnrealised,
        realised: _newRealised,
        accUnrealisedFractionPaid: _accUnrealisedFraction,
        lastDistributeIndex: _distributeIndex
      });
    }
  }

  /// @dev Internal function called by `deposit` and `depositFor`.
  ///      assume that debtToken is already transfered into this contract.
  /// @param _account The address of the user.
  /// @param _amount The amount of debtToken to deposit.
  function _deposit(address _account, uint256 _amount) internal {
    // 1. update user info
    _updateUserInfo(_account);

    // 2. compute realised and unrelised
    uint256 _scale = 10**(18 - IERC20Metadata(baseToken).decimals());
    uint256 _totalUnrealised = furnaceInfo.totalUnrealised;
    uint256 _totalRealised = furnaceInfo.totalRealised;
    uint256 _freeBaseToken = (totalBaseTokenInPool() * _scale).sub(_totalRealised);

    uint256 _newUnrealised;
    uint256 _newRealised;
    if (_freeBaseToken >= _amount) {
      // pay all the debt with baseToken in contract directly.
      _newUnrealised = 0;
      _newRealised = _amount;
    } else {
      // pay part of the debt with baseToken in contract directly
      // and part of the debt with future baseToken distributed to the contract.
      _newUnrealised = _amount - _freeBaseToken;
      _newRealised = _freeBaseToken;
    }

    // 3. update user and global state
    userInfo[_account].realised = SafeCastUpgradeable.toUint128(_newRealised.add(userInfo[_account].realised));
    userInfo[_account].unrealised = SafeCastUpgradeable.toUint128(_newUnrealised.add(userInfo[_account].unrealised));

    furnaceInfo.totalRealised = SafeCastUpgradeable.toUint128(_totalRealised.add(_newRealised));
    furnaceInfo.totalUnrealised = SafeCastUpgradeable.toUint128(_totalUnrealised.add(_newUnrealised));

    emit Deposit(_account, _amount);
  }

  /// @dev Internal function called by `withdraw` and `withdrawAll`.
  /// @param _recipient The address of user who will recieve the debtToken.
  /// @param _amount The amount of debtToken to withdraw.
  function _withdraw(address _recipient, uint256 _amount) internal {
    require(_amount <= userInfo[msg.sender].unrealised, "Furnace: debtToken not enough");

    userInfo[msg.sender].unrealised = uint128(uint256(userInfo[msg.sender].unrealised) - _amount); // never overflow here
    furnaceInfo.totalUnrealised = uint128(uint256(furnaceInfo.totalUnrealised) - _amount); // never overflow here

    IERC20Upgradeable(debtToken).safeTransfer(_recipient, _amount);

    emit Withdraw(msg.sender, _recipient, _amount);
  }

  /// @dev Internal function called by `claim`.
  /// @param _recipient The address of user who will recieve the baseToken.
  function _claim(address _recipient) internal {
    uint256 _debtAmount = userInfo[msg.sender].realised;
    // should not overflow, but just in case, we use safe math.
    furnaceInfo.totalRealised = uint128(uint256(furnaceInfo.totalRealised).sub(_debtAmount));
    userInfo[msg.sender].realised = 0;

    // scale to base token
    address _baseToken = baseToken;
    uint256 _scale = 10**(18 - IERC20Metadata(_baseToken).decimals());
    uint256 _baseAmount = _debtAmount / _scale;

    uint256 _balanceInContract = IERC20Upgradeable(_baseToken).balanceOf(address(this));
    if (_balanceInContract < _baseAmount) {
      address _strategy = yieldInfo.strategy;
      // balance is not enough, with from yield strategy
      uint256 _yieldAmountToWithdraw = ((_baseAmount - _balanceInContract) * 1e18) /
        IYieldStrategy(_strategy).underlyingPrice();
      uint256 _diff = IYieldStrategy(_strategy).withdraw(address(this), _yieldAmountToWithdraw, true);
      _baseAmount = _balanceInContract + _diff;
    }
    IERC20Upgradeable(_baseToken).safeTransfer(_recipient, _baseAmount);

    // burn realised debtToken
    ICLeverToken(debtToken).burn(_debtAmount);

    emit Claim(msg.sender, _recipient, _debtAmount);
  }

  /// @dev Internal function called by `distribute` and `harvest`.
  /// @param _origin The address of the user who will provide baseToken.
  /// @param _amount The amount of baseToken will be provided.
  function _distribute(address _origin, uint256 _amount) internal {
    // reduct pending debt
    _updatePendingDistribution();

    // scale to debt token
    uint256 _scale = 10**(18 - IERC20Metadata(baseToken).decimals());
    _amount *= _scale;

    // distribute clevCVX rewards
    LinearReward memory _info = rewardInfo;
    if (_info.periodLength == 0) {
      _reduceGlobalDebt(_amount);
    } else {
      if (block.timestamp >= _info.finishAt) {
        _info.ratePerSecond = SafeCastUpgradeable.toUint128(_amount / _info.periodLength);
      } else {
        uint256 _remaining = _info.finishAt - block.timestamp;
        uint256 _leftover = _remaining * _info.ratePerSecond;
        _info.ratePerSecond = SafeCastUpgradeable.toUint128((_amount + _leftover) / _info.periodLength);
      }

      _info.lastUpdate = uint48(block.timestamp);
      _info.finishAt = uint48(block.timestamp + _info.periodLength);

      rewardInfo = _info;
    }

    // 2. stake extra baseToken to yield strategy
    YieldInfo memory _yieldInfo = yieldInfo;
    if (_yieldInfo.strategy != address(0)) {
      uint256 _exepctToStake = totalBaseTokenInPool().mul(_yieldInfo.percentage) / 1e5;
      uint256 _balanceStaked = IYieldStrategy(_yieldInfo.strategy).totalUnderlyingToken();
      if (_balanceStaked < _exepctToStake) {
        _exepctToStake = _exepctToStake - _balanceStaked;
        if (_exepctToStake >= _yieldInfo.threshold) {
          IERC20Upgradeable(baseToken).safeTransfer(_yieldInfo.strategy, _exepctToStake);
          IYieldStrategy(_yieldInfo.strategy).deposit(address(this), _exepctToStake, true);
        }
      }
    }

    emit Distribute(_origin, _amount / _scale);
  }

  /// @dev Internal function to reduce global debt based on CVX rewards.
  /// @param _amount The new paid clevCVX debt.
  function _reduceGlobalDebt(uint256 _amount) internal {
    FurnaceInfo memory _furnaceInfo = furnaceInfo;

    _furnaceInfo.distributeIndex += 1;
    // 1. distribute baseToken rewards
    if (_amount >= _furnaceInfo.totalUnrealised) {
      // In this case, all unrealised debtToken are paid off.
      _furnaceInfo.totalRealised = SafeCastUpgradeable.toUint128(
        _furnaceInfo.totalUnrealised + _furnaceInfo.totalRealised
      );
      _furnaceInfo.totalUnrealised = 0;

      _furnaceInfo.accUnrealisedFraction = 0;
      _furnaceInfo.lastPaidOffDistributeIndex = _furnaceInfo.distributeIndex;
    } else {
      uint128 _fraction = SafeCastUpgradeable.toUint128(
        ((_furnaceInfo.totalUnrealised - _amount) * E128) / _furnaceInfo.totalUnrealised
      ); // mul never overflow

      _furnaceInfo.totalUnrealised = uint128(_furnaceInfo.totalUnrealised - _amount);
      _furnaceInfo.totalRealised = SafeCastUpgradeable.toUint128(_furnaceInfo.totalRealised + _amount);
      _furnaceInfo.accUnrealisedFraction = _mul128(_furnaceInfo.accUnrealisedFraction, _fraction);
    }

    furnaceInfo = _furnaceInfo;
  }

  /// @dev Compute the value of (_a / 2^128) * (_b / 2^128) with precision 2^128.
  function _mul128(uint128 _a, uint128 _b) internal pure returns (uint128) {
    if (_a == 0) return _b;
    if (_b == 0) return _a;
    return uint128((uint256(_a) * uint256(_b)) / E128);
  }

  /// @dev Compute the value of _a * (_b / 2^128) / (_c / 2^128).
  function _muldiv128(
    uint256 _a,
    uint128 _b,
    uint128 _c
  ) internal pure returns (uint256) {
    if (_b == 0) {
      if (_c == 0) return _a;
      else return _a / _c;
    } else {
      if (_c == 0) return _a.mul(_b) / E128;
      else return _a.mul(_b) / _c;
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICLeverToken is IERC20 {
  function mint(address _recipient, uint256 _amount) external;

  function burn(uint256 _amount) external;

  function burnFrom(address _account, uint256 _amount) external;
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