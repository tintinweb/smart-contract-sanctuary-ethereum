// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IConvexCVXRewardPool.sol";
import "../interfaces/IFurnace.sol";
import "../interfaces/ICLeverToken.sol";
import "../interfaces/IZap.sol";

// solhint-disable reason-string

contract Furnace is OwnableUpgradeable, IFurnace {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UpdateWhitelist(address indexed _whitelist, bool _status);
  event UpdateStakePercentage(uint256 _percentage);
  event UpdateStakeThreshold(uint256 _threshold);
  event UpdatePlatformFeePercentage(uint256 _feePercentage);
  event UpdateHarvestBountyPercentage(uint256 _percentage);
  event UpdatePlatform(address indexed _platform);
  event UpdateZap(address indexed _zap);
  event UpdateGovernor(address indexed _governor);

  uint256 private constant E128 = 2**128;
  uint256 private constant FEE_DENOMINATOR = 1e9;
  uint256 private constant MAX_PLATFORM_FEE = 2e8; // 20%
  uint256 private constant MAX_HARVEST_BOUNTY = 1e8; // 10%

  address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
  // The address of cvxCRV token.
  address private constant CVXCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
  address private constant CVX_REWARD_POOL = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332;

  /// @notice If the unrealised is not paid off,
  /// the realised token in n sequential distribute is
  ///    user_unrealised * (reward_1 / total_unrealised_1)
  ///  + user_unrealised * (reward_1 / total_unrealised_1) * (reward_2 / total_unrealised_2)
  ///  + ...
  /// the unrealised token in n sequential distribute is
  ///    user_unrealised * (total_unrealised_1 - reward_1) / total_unrealised_1 * (total_unrealised_2 - reward_2) / total_unrealised_2 * ...
  ///
  /// So we can maintain a variable `accUnrealisedFraction` which is a product of `(total_unrealised - reward) / total_unrealised`.
  /// And keep track of this variable on each deposit/withdraw/claim, the unrealised clevCVX of the user should be
  ///                                accUnrealisedFractionPaid
  ///                   unrealised * -------------------------
  ///                                  accUnrealisedFraction
  /// Also, the debt will paid off in some case, we record a global variable `lastPaidOffDistributeIndex` and an user
  /// specific variable `lastDistributeIndex` to check if the debt is paid off during `(lastDistributeIndex, distributeIndex]`.
  ///
  /// And to save the gas usage, an `uint128` is used to store `accUnrealisedFraction` and `accUnrealisedFractionPaid`.
  /// More specifically, it is in range [0, 2^128), means the real number `fraction / 2^128`. If the value is 0, it
  /// means the value of the faction is 1.
  struct UserInfo {
    // The total amount of clevCVX unrealised.
    uint128 unrealised;
    // The total amount of clevCVX realised.
    uint128 realised;
    // The checkpoint for global `accUnrealisedFraction`, multipled by 1e9.
    uint192 accUnrealisedFractionPaid;
    // The distribute index record when use interacted the contract.
    uint64 lastDistributeIndex;
  }

  /// @dev The address of governor
  address public governor;
  /// @dev The address of clevCVX
  address public clevCVX;
  /// @dev The total amount of clevCVX unrealised.
  uint128 public totalUnrealised;
  /// @dev The total amount of clevCVX realised.
  uint128 public totalRealised;
  /// @dev The accumulated unrealised fraction, multipled by 2^128.
  uint128 public accUnrealisedFraction;
  /// @dev The distriubed index, will be increased each time the function `distribute` is called.
  uint64 public distributeIndex;
  /// @dev The distriubed index when all clevCVX is paied off.
  uint64 public lastPaidOffDistributeIndex;
  /// @dev Mapping from user address to user info.
  mapping(address => UserInfo) public userInfo;
  /// @dev Mapping from user address to whether it is whitelisted.
  mapping(address => bool) public isWhitelisted;
  /// @dev The percentage of free CVX should be staked in CVXRewardPool, multipled by 1e9.
  uint256 public stakePercentage;
  /// @dev The minimum amount of CVX in each stake.
  uint256 public stakeThreshold;

  /// @dev The address of zap contract.
  address public zap;
  /// @dev The percentage of rewards to take for platform on harvest
  uint256 public platformFeePercentage;
  /// @dev The percentage of rewards to take for caller on harvest
  uint256 public harvestBountyPercentage;
  /// @dev The address of recipient of platform fee
  address public platform;

  modifier onlyWhitelisted() {
    require(isWhitelisted[msg.sender], "Furnace: only whitelisted");
    _;
  }

  modifier onlyGovernorOrOwner() {
    require(msg.sender == governor || msg.sender == owner(), "Furnace: only governor or owner");
    _;
  }

  function initialize(
    address _governor,
    address _clevCVX,
    address _zap,
    address _platform,
    uint256 _platformFeePercentage,
    uint256 _harvestBountyPercentage
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    require(_governor != address(0), "Furnace: zero governor address");
    require(_clevCVX != address(0), "Furnace: zero clevCVX address");
    require(_zap != address(0), "Furnace: zero zap address");
    require(_platform != address(0), "Furnace: zero platform address");
    require(_platformFeePercentage <= MAX_PLATFORM_FEE, "Furnace: fee too large");
    require(_harvestBountyPercentage <= MAX_HARVEST_BOUNTY, "Furnace: fee too large");

    governor = _governor;
    clevCVX = _clevCVX;
    zap = _zap;
    platform = _platform;
    platformFeePercentage = _platformFeePercentage;
    harvestBountyPercentage = _harvestBountyPercentage;
  }

  /********************************** View Functions **********************************/

  /// @dev Return the amount of clevCVX unrealised and realised of user.
  /// @param _account The address of user.
  /// @return unrealised The amount of clevCVX unrealised.
  /// @return realised The amount of clevCVX realised and can be claimed.
  function getUserInfo(address _account) external view override returns (uint256 unrealised, uint256 realised) {
    UserInfo memory _info = userInfo[_account];
    if (_info.lastDistributeIndex < lastPaidOffDistributeIndex) {
      // In this case, all unrealised is paid off since last operate.
      return (0, _info.unrealised + _info.realised);
    } else {
      // extra plus 1, make sure we round up in division
      uint128 _newUnrealised = _toU128(
        _muldiv128(_info.unrealised, accUnrealisedFraction, uint128(_info.accUnrealisedFractionPaid))
      ) + 1;
      if (_newUnrealised >= _info.unrealised) {
        _newUnrealised = _info.unrealised;
      }
      uint128 _newRealised = _info.unrealised - _newUnrealised + _info.realised; // never overflow here
      return (_newUnrealised, _newRealised);
    }
  }

  /// @dev Return the total amount of free CVX in this contract, including staked in CVXRewardPool.
  /// @return The amount of CVX in this contract now.
  function totalCVXInPool() public view returns (uint256) {
    return
      IERC20Upgradeable(CVX).balanceOf(address(this)).add(
        IConvexCVXRewardPool(CVX_REWARD_POOL).balanceOf(address(this))
      );
  }

  /********************************** Mutated Functions **********************************/

  /// @dev Deposit clevCVX in this contract to change for CVX.
  /// @param _amount The amount of clevCVX to deposit.
  function deposit(uint256 _amount) external override {
    require(_amount > 0, "Furnace: deposit zero clevCVX");

    // transfer token into contract
    IERC20Upgradeable(clevCVX).safeTransferFrom(msg.sender, address(this), _amount);

    _deposit(msg.sender, _amount);
  }

  /// @dev Deposit clevCVX in this contract to change for CVX for other user.
  /// @param _account The address of user you deposit for.
  /// @param _amount The amount of clevCVX to deposit.
  function depositFor(address _account, uint256 _amount) external override {
    require(_amount > 0, "Furnace: deposit zero clevCVX");

    // transfer token into contract
    IERC20Upgradeable(clevCVX).safeTransferFrom(msg.sender, address(this), _amount);

    _deposit(_account, _amount);
  }

  /// @dev Withdraw unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  /// @param _amount The amount of clevCVX to withdraw.
  function withdraw(address _recipient, uint256 _amount) external override {
    require(_amount > 0, "Furnace: withdraw zero CVX");

    _updateUserInfo(msg.sender);
    _withdraw(_recipient, _amount);
  }

  /// @dev Withdraw all unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  function withdrawAll(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _withdraw(_recipient, userInfo[msg.sender].unrealised);
  }

  /// @dev Claim all realised CVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the CVX.
  function claim(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _claim(_recipient);
  }

  /// @dev Exit the contract, withdraw all unrealised clevCVX and realised CVX of the caller.
  /// @param _recipient The address of user who will recieve the clevCVX and CVX.
  function exit(address _recipient) external override {
    _updateUserInfo(msg.sender);

    _withdraw(_recipient, userInfo[msg.sender].unrealised);
    _claim(_recipient);
  }

  /// @dev Distribute CVX from `origin` to pay clevCVX debt.
  /// @param _origin The address of the user who will provide CVX.
  /// @param _amount The amount of CVX will be provided.
  function distribute(address _origin, uint256 _amount) external override onlyWhitelisted {
    require(_amount > 0, "Furnace: distribute zero CVX");

    IERC20Upgradeable(CVX).safeTransferFrom(_origin, address(this), _amount);

    _distribute(_origin, _amount);
  }

  /// @dev Harvest the pending reward and convert to cvxCRV.
  /// @param _recipient - The address of account to receive harvest bounty.
  /// @param _minimumOut - The minimum amount of cvxCRV should get.
  /// @return the amount of CVX harvested.
  function harvest(address _recipient, uint256 _minimumOut) external returns (uint256) {
    // 1. harvest from CVXRewardPool
    IConvexCVXRewardPool(CVX_REWARD_POOL).getReward(false);

    // 2. swap all reward to CVX (cvxCRV only currently)
    uint256 _amount = IERC20Upgradeable(CVXCRV).balanceOf(address(this));
    if (_amount > 0) {
      IERC20Upgradeable(CVXCRV).safeTransfer(zap, _amount);
      _amount = IZap(zap).zap(CVXCRV, _amount, CVX, _minimumOut);
    }

    emit Harvest(msg.sender, _amount);

    if (_amount > 0) {
      uint256 _distributeAmount = _amount;
      // 3. take platform fee and harvest bounty
      uint256 _platformFee = platformFeePercentage;
      if (_platformFee > 0) {
        _platformFee = (_platformFee * _distributeAmount) / FEE_DENOMINATOR;
        IERC20Upgradeable(CVX).safeTransfer(platform, _platformFee);
        _distributeAmount = _distributeAmount - _platformFee; // never overflow here
      }
      uint256 _harvestBounty = harvestBountyPercentage;
      if (_harvestBounty > 0) {
        _harvestBounty = (_harvestBounty * _distributeAmount) / FEE_DENOMINATOR;
        _distributeAmount = _distributeAmount - _harvestBounty; // never overflow here
        IERC20Upgradeable(CVX).safeTransfer(_recipient, _harvestBounty);
      }
      // 4. distribute harvest CVX to pay clevCVX
      // @note: we may distribute all rest CVX to AladdinConvexLocker
      _distribute(address(this), _distributeAmount);
    }
    return _amount;
  }

  /********************************** Restricted Functions **********************************/

  /// @dev Update the status of a list of whitelisted accounts.
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

  /// @dev Update the address of governor.
  /// @param _governor The address to be updated
  function updateGovernor(address _governor) external onlyGovernorOrOwner {
    require(_governor != address(0), "Furnace: zero governor address");
    governor = _governor;

    emit UpdateGovernor(_governor);
  }

  /// @dev Update stake percentage for CVX in this contract.
  /// @param _percentage The stake percentage to be updated, multipled by 1e9.
  function updateStakePercentage(uint256 _percentage) external onlyGovernorOrOwner {
    require(_percentage <= FEE_DENOMINATOR, "Furnace: percentage too large");
    stakePercentage = _percentage;

    emit UpdateStakePercentage(_percentage);
  }

  /// @dev Update stake threshold for CVX.
  /// @param _threshold The stake threshold to be updated.
  function updateStakeThreshold(uint256 _threshold) external onlyGovernorOrOwner {
    stakeThreshold = _threshold;

    emit UpdateStakeThreshold(_threshold);
  }

  /// @dev Update the platform fee percentage.
  /// @param _feePercentage The fee percentage to be updated, multipled by 1e9.
  function updatePlatformFeePercentage(uint256 _feePercentage) external onlyOwner {
    require(_feePercentage <= MAX_PLATFORM_FEE, "AladdinCRV: fee too large");
    platformFeePercentage = _feePercentage;

    emit UpdatePlatformFeePercentage(_feePercentage);
  }

  /// @dev Update the harvest bounty percentage.
  /// @param _percentage - The fee percentage to be updated, multipled by 1e9.
  function updateHarvestBountyPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= MAX_HARVEST_BOUNTY, "AladdinCRV: fee too large");
    harvestBountyPercentage = _percentage;

    emit UpdateHarvestBountyPercentage(_percentage);
  }

  /// @dev Update the platform fee recipient
  /// @dev _platform The platform address to be updated.
  function updatePlatform(address _platform) external onlyOwner {
    require(_platform != address(0), "AladdinCRV: zero platform address");
    platform = _platform;

    emit UpdatePlatform(_platform);
  }

  /// @dev Update the zap contract
  /// @param _zap The zap contract to be updated.
  function updateZap(address _zap) external onlyGovernorOrOwner {
    require(_zap != address(0), "Furnace: zero zap address");
    zap = _zap;

    emit UpdateZap(_zap);
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function called when user interacts with the contract.
  /// @param _account The address of user to update.
  function _updateUserInfo(address _account) internal {
    UserInfo memory _info = userInfo[_account];
    uint128 _accUnrealisedFraction = accUnrealisedFraction;
    uint64 _distributeIndex = distributeIndex;
    if (_info.lastDistributeIndex < lastPaidOffDistributeIndex) {
      // In this case, all unrealised is paid off since last operate.
      userInfo[_account] = UserInfo({
        unrealised: 0,
        realised: _info.unrealised + _info.realised, // never overflow here
        accUnrealisedFractionPaid: 0,
        lastDistributeIndex: _distributeIndex
      });
    } else {
      // extra plus 1, make sure we round up in division
      uint128 _newUnrealised = _toU128(
        _muldiv128(_info.unrealised, _accUnrealisedFraction, uint128(_info.accUnrealisedFractionPaid))
      ) + 1;
      if (_newUnrealised >= _info.unrealised) {
        _newUnrealised = _info.unrealised;
      }
      uint128 _newRealised = _info.unrealised - _newUnrealised + _info.realised; // never overflow here
      userInfo[_account] = UserInfo({
        unrealised: _newUnrealised,
        realised: _newRealised,
        accUnrealisedFractionPaid: _accUnrealisedFraction,
        lastDistributeIndex: _distributeIndex
      });
    }
  }

  /// @dev Internal function called by `deposit` and `depositFor`.
  ///      assume that clevCVX is already transfered into this contract.
  /// @param _account The address of the user.
  /// @param _amount The amount of clevCVX to deposit.
  function _deposit(address _account, uint256 _amount) internal {
    // 1. update user info
    _updateUserInfo(_account);

    // 2. compute realised and unrelised
    uint256 _totalUnrealised = totalUnrealised;
    uint256 _totalRealised = totalRealised;
    uint256 _freeCVX = totalCVXInPool().sub(_totalRealised);

    uint256 _newUnrealised;
    uint256 _newRealised;
    if (_freeCVX >= _amount) {
      // pay all the debt with CVX in contract directly.
      _newUnrealised = 0;
      _newRealised = _amount;
    } else {
      // pay part of the debt with CVX in contract directly
      // and part of the debt with future CVX distributed to the contract.
      _newUnrealised = _amount - _freeCVX;
      _newRealised = _freeCVX;
    }

    // 3. update user and global state
    userInfo[_account].realised = _toU128(_newRealised.add(userInfo[_account].realised));
    userInfo[_account].unrealised = _toU128(_newUnrealised.add(userInfo[_account].unrealised));

    totalRealised = _toU128(_totalRealised.add(_newRealised));
    totalUnrealised = _toU128(_totalUnrealised.add(_newUnrealised));

    emit Deposit(_account, _amount);
  }

  /// @dev Internal function called by `withdraw` and `withdrawAll`.
  /// @param _recipient The address of user who will recieve the clevCVX.
  /// @param _amount The amount of clevCVX to withdraw.
  function _withdraw(address _recipient, uint256 _amount) internal {
    require(_amount <= userInfo[msg.sender].unrealised, "Furnace: clevCVX not enough");

    userInfo[msg.sender].unrealised = uint128(uint256(userInfo[msg.sender].unrealised) - _amount); // never overflow here
    totalUnrealised = uint128(uint256(totalUnrealised) - _amount); // never overflow here

    IERC20Upgradeable(clevCVX).safeTransfer(_recipient, _amount);

    emit Withdraw(msg.sender, _recipient, _amount);
  }

  /// @dev Internal function called by `claim`.
  /// @param _recipient The address of user who will recieve the CVX.
  function _claim(address _recipient) internal {
    uint256 _amount = userInfo[msg.sender].realised;
    // should not overflow, but just in case, we use safe math.
    totalRealised = uint128(uint256(totalRealised).sub(_amount));
    userInfo[msg.sender].realised = 0;

    uint256 _balanceInContract = IERC20Upgradeable(CVX).balanceOf(address(this));
    if (_balanceInContract < _amount) {
      // balance is not enough, with from reward pool
      IConvexCVXRewardPool(CVX_REWARD_POOL).withdraw(_amount - _balanceInContract, false);
    }
    IERC20Upgradeable(CVX).safeTransfer(_recipient, _amount);
    // burn realised clevCVX
    ICLeverToken(clevCVX).burn(_amount);

    emit Claim(msg.sender, _recipient, _amount);
  }

  /// @dev Internal function called by `distribute` and `harvest`.
  /// @param _origin The address of the user who will provide CVX.
  /// @param _amount The amount of CVX will be provided.
  function _distribute(address _origin, uint256 _amount) internal {
    distributeIndex += 1;

    uint256 _totalUnrealised = totalUnrealised;
    uint256 _totalRealised = totalRealised;
    uint128 _accUnrealisedFraction = accUnrealisedFraction;
    // 1. distribute CVX rewards
    if (_amount >= _totalUnrealised) {
      // In this case, all unrealised clevCVX are paid off.
      totalUnrealised = 0;
      totalRealised = _toU128(_totalUnrealised + _totalRealised);

      accUnrealisedFraction = 0;
      lastPaidOffDistributeIndex = distributeIndex;
    } else {
      totalUnrealised = uint128(_totalUnrealised - _amount);
      totalRealised = _toU128(_totalRealised + _amount);

      uint128 _fraction = _toU128(((_totalUnrealised - _amount) * E128) / _totalUnrealised); // mul never overflow
      accUnrealisedFraction = _mul128(_accUnrealisedFraction, _fraction);
    }

    // 2. stake extra CVX to cvxRewardPool
    uint256 _toStake = totalCVXInPool().mul(stakePercentage).div(FEE_DENOMINATOR);
    uint256 _balanceStaked = IConvexCVXRewardPool(CVX_REWARD_POOL).balanceOf(address(this));
    if (_balanceStaked < _toStake) {
      _toStake = _toStake - _balanceStaked;
      if (_toStake >= stakeThreshold) {
        IERC20Upgradeable(CVX).safeApprove(CVX_REWARD_POOL, 0);
        IERC20Upgradeable(CVX).safeApprove(CVX_REWARD_POOL, _toStake);
        IConvexCVXRewardPool(CVX_REWARD_POOL).stake(_toStake);
      }
    }

    emit Distribute(_origin, _amount);
  }

  /// @dev Convert uint256 value to uint128 value.
  function _toU128(uint256 _value) internal pure returns (uint128) {
    require(_value < 340282366920938463463374607431768211456, "Furnace: overflow");
    return uint128(_value);
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

pragma solidity ^0.7.6;

interface IConvexCVXRewardPool {
  function balanceOf(address account) external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function withdraw(uint256 _amount, bool claim) external;

  function withdrawAll(bool claim) external;

  function stake(uint256 _amount) external;

  function stakeAll() external;

  function stakeFor(address _for, uint256 _amount) external;

  function getReward(
    address _account,
    bool _claimExtras,
    bool _stake
  ) external;

  function getReward(bool _stake) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IFurnace {
  event Deposit(address indexed _account, uint256 _amount);
  event Withdraw(address indexed _account, address _recipient, uint256 _amount);
  event Claim(address indexed _account, address _recipient, uint256 _amount);
  event Distribute(address indexed _origin, uint256 _amount);
  event Harvest(address indexed _caller, uint256 _amount);

  /// @dev Return the amount of clevCVX unrealised and realised of user.
  /// @param _account The address of user.
  /// @return unrealised The amount of clevCVX unrealised.
  /// @return realised The amount of clevCVX realised and can be claimed.
  function getUserInfo(address _account) external view returns (uint256 unrealised, uint256 realised);

  /// @dev Deposit clevCVX in this contract to change for CVX.
  /// @param _amount The amount of clevCVX to deposit.
  function deposit(uint256 _amount) external;

  /// @dev Deposit clevCVX in this contract to change for CVX for other user.
  /// @param _account The address of user you deposit for.
  /// @param _amount The amount of clevCVX to deposit.
  function depositFor(address _account, uint256 _amount) external;

  /// @dev Withdraw unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  /// @param _amount The amount of clevCVX to withdraw.
  function withdraw(address _recipient, uint256 _amount) external;

  /// @dev Withdraw all unrealised clevCVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the clevCVX.
  function withdrawAll(address _recipient) external;

  /// @dev Claim all realised CVX of the caller from this contract.
  /// @param _recipient The address of user who will recieve the CVX.
  function claim(address _recipient) external;

  /// @dev Exit the contract, withdraw all unrealised clevCVX and realised CVX of the caller.
  /// @param _recipient The address of user who will recieve the clevCVX and CVX.
  function exit(address _recipient) external;

  /// @dev Distribute CVX from `origin` to pay clevCVX debt.
  /// @param _origin The address of the user who will provide CVX.
  /// @param _amount The amount of CVX will be provided.
  function distribute(address _origin, uint256 _amount) external;
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

interface IZap {
  function zap(
    address _fromToken,
    uint256 _amountIn,
    address _toToken,
    uint256 _minOut
  ) external payable returns (uint256);
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