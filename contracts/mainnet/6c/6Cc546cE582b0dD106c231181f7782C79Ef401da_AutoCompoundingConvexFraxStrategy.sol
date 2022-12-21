// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "../../interfaces/IConvexFraxBooster.sol";
import "../../interfaces/IFraxUnifiedFarm.sol";
import "../../interfaces/IStakingProxyConvex.sol";
import "../../interfaces/IZap.sol";

import "./AutoCompoundingStrategyBase.sol";

// solhint-disable reason-string
// solhint-disable not-rely-on-time
// solhint-disable no-empty-blocks

contract AutoCompoundingConvexFraxStrategy is OwnableUpgradeable, PausableUpgradeable, AutoCompoundingStrategyBase {
  using SafeERC20 for IERC20;

  /// @inheritdoc IConcentratorStrategy
  // solhint-disable const-name-snakecase
  string public constant override name = "AutoCompoundingConvexFrax";

  /// @dev The address of Convex Booster for Frax vault.
  address private constant BOOSTER = 0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa;

  /// @dev Compiler will pack this into two `uint256`.
  struct LockData {
    // The amount of lock time, in seconds.
    uint64 duration;
    // Next unlock time, in seconds.
    uint64 unlockAt;
    // The amount of token should be unlocked at next unlock time.
    uint128 pendingToUnlock;
    // The key of locked items in frax vault.
    bytes32 key;
  }

  struct UserLockedBalance {
    // The amount of token locked.
    uint128 balance;
    // Next unlock time, in seconds.
    uint64 unlockAt;
    // reserved slot.
    uint64 _unused;
  }

  LockData public locks;

  /// @notice The pid of Convex reward pool.
  uint256 public pid;

  /// @notice The address of staking token.
  address public token;

  /// @notice The address of personal vault.
  address public vault;

  /// @notice The amount of token are going to be locked.
  /// @dev The value will be non-zero only when contract is paused.
  uint256 public pendingToLock;

  /// @notice Mapping from user address to user locked data.
  mapping(address => UserLockedBalance[]) public userLocks;

  /// @dev Mapping from user address to next index in `userLocks`.
  mapping(address => uint256) private nextIndex;

  function initialize(
    address _operator,
    address _token,
    uint256 _pid,
    address[] memory _rewards
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
    ConcentratorStrategyBase._initialize(_operator, _rewards);

    address _vault = IConvexFraxBooster(BOOSTER).createVault(_pid);
    IERC20(_token).safeApprove(_vault, uint256(-1));

    pid = _pid;
    token = _token;
    vault = _vault;

    locks.duration = 86400 * 7; // default 7 days
  }

  /********************************** View Functions **********************************/

  /// @notice Query the list of locked balance.
  /// @param _account The address of user to query.
  function getUserLocks(address _account) external view returns (UserLockedBalance[] memory _list) {
    UserLockedBalance[] storage _locks = userLocks[_account];
    uint256 _length = _locks.length;
    uint256 _nextIndex = nextIndex[_account];
    _list = new UserLockedBalance[](_length - _nextIndex);
    for (uint256 i = _nextIndex; i < _length; ++i) {
      _list[i - _nextIndex] = _locks[i];
    }
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IConcentratorStrategy
  /// @dev You are not allowed to deposit when contract is paused.
  function deposit(address, uint256 _amount) external override onlyOperator whenNotPaused {
    if (_amount > 0) {
      _createOrLockMore(vault, _amount);
    }
  }

  /// @inheritdoc IConcentratorStrategy
  function withdraw(address _recipient, uint256 _amount) external override onlyOperator {
    if (_amount > 0) {
      LockData memory _locks = locks;

      // add lock record
      userLocks[_recipient].push(
        UserLockedBalance({ balance: uint128(_amount), unlockAt: _locks.unlockAt, _unused: 0 })
      );

      // increase the pending unlocks.
      _locks.pendingToUnlock = uint128(uint256(_locks.pendingToUnlock) + _amount);

      // try extend lock duration
      _extend(vault, _locks);

      // update storage
      locks = _locks;
    }
  }

  /// @inheritdoc IConcentratorStrategy
  function harvest(address _zapper, address _intermediate) external override onlyOperator returns (uint256 _amount) {
    address _vault = vault;

    // 1. claim rewards from Convex rewards contract.
    address[] memory _rewards = rewards;
    uint256[] memory _amounts = new uint256[](rewards.length);
    for (uint256 i = 0; i < rewards.length; i++) {
      _amounts[i] = IERC20(_rewards[i]).balanceOf(address(this));
    }
    IStakingProxyConvex(_vault).getReward(true, _rewards);
    for (uint256 i = 0; i < rewards.length; i++) {
      _amounts[i] = IERC20(_rewards[i]).balanceOf(address(this)) - _amounts[i];
    }

    // 2. zap all rewards to staking token.
    _amount = _harvest(_zapper, _intermediate, token, _rewards, _amounts);

    // 3. deposit into convex
    if (_amount > 0) {
      if (paused()) pendingToLock += _amount;
      else _createOrLockMore(_vault, _amount);
    }
  }

  /// @inheritdoc IConcentratorStrategy
  function finishMigrate(address _newStrategy) external override onlyOperator {
    claim(_newStrategy);

    require(
      nextIndex[_newStrategy] == userLocks[_newStrategy].length,
      "AutoCompoundingConvexFraxStrategy: migration failed"
    );
  }

  /// @notice Claim unlocked token from contract.
  /// @param _account The address of user to claim.
  function claim(address _account) public {
    {
      LockData memory _locks = locks;
      // try to trigger the unlock and extend.
      _extend(vault, _locks);
      locks = _locks;
    }

    UserLockedBalance[] storage _userLocks = userLocks[_account];
    uint256 _length = _userLocks.length;
    uint256 _nextIndex = nextIndex[_account];
    uint256 _unlocked;
    while (_nextIndex < _length) {
      UserLockedBalance memory _lock = _userLocks[_nextIndex];
      if (_lock.unlockAt <= block.timestamp) {
        _unlocked += _lock.balance;
        delete _userLocks[_nextIndex];
      } else {
        break;
      }
      _nextIndex += 1;
    }
    nextIndex[_account] = _nextIndex;

    IERC20(token).safeTransfer(_account, _unlocked);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Pause contract or not.
  /// @param _status The pause status.
  function setPaused(bool _status) external onlyOwner {
    if (_status) _pause();
    else _unpause();
  }

  /// @notice Update current lock duration.
  function updateLockDuration(uint64 _duraion) external onlyOwner {
    address _farm = IStakingProxyConvex(vault).stakingAddress();

    uint256 _minDuration = IFraxUnifiedFarm(_farm).lock_time_min();
    uint256 _maxDuration = IFraxUnifiedFarm(_farm).lock_time_for_max_multiplier();
    require(_minDuration <= _duraion && _duraion <= _maxDuration, "ConcentratorStrategy: invalid duration");

    locks.duration = _duraion;
  }

  /********************************** Internal Functions **********************************/

  /// @dev Internal function to create lock or lock more.
  /// @param _vault The address of the vault.
  /// @param _amount The amount of token to lock.
  function _createOrLockMore(address _vault, uint256 _amount) internal {
    LockData memory _locks = locks;

    // We have some pending token to lock, usually happens when the paused contract is opened.
    uint256 _pendingToLock = pendingToLock;
    if (_pendingToLock > 0) {
      pendingToLock = 0;
      _amount += _pendingToLock;
    }

    if (_locks.key == bytes32(0)) {
      // we don't have a lock yet, create one
      _locks.key = IStakingProxyConvex(_vault).stakeLockedCurveLp(_amount, _locks.duration);
      _locks.unlockAt = uint64(block.timestamp + _locks.duration);
    } else {
      // we already have a lock, lock more
      IStakingProxyConvex(_vault).lockAdditionalCurveLp(_locks.key, _amount);

      // try extend our lock.
      _extend(_vault, _locks);
    }

    locks = _locks;
  }

  /// @dev Internal function to extend lock duration.
  /// @param _vault The address of the vault.
  /// @param _locks The lock data in memory.
  function _extend(address _vault, LockData memory _locks) internal {
    // no need to extend now
    if (_locks.unlockAt > block.timestamp) return;

    if (_locks.pendingToUnlock > 0) {
      // unlock pending tokens
      _unlock(_vault, _locks, _locks.pendingToUnlock);
      _locks.pendingToUnlock = 0;
    } else if (!paused() && _locks.key != bytes32(0)) {
      // Don't extend lock duration when paused or no lock exists
      // _locks.key = bytes32(0) will happen when
      // 1. setPause(true)
      // 2. withdraw
      // 3. setPause(false)
      // 4. claim
      IStakingProxyConvex(_vault).lockLonger(_locks.key, block.timestamp + _locks.duration);
      _locks.unlockAt = uint64(block.timestamp + _locks.duration);
    }
  }

  /// @dev Internal function to unlock some staking token from frax vault.
  /// @param _vault The address of the vault.
  /// @param _locks The lock data in memory.
  /// @param _amount The amount of token to unlock.
  function _unlock(
    address _vault,
    LockData memory _locks,
    uint256 _amount
  ) internal {
    // all are unlocked.
    if (_locks.key == bytes32(0)) {
      // unlock token when paused
      pendingToLock -= _amount;
      return;
    }

    address _token = token;
    uint256 _unlocked = IERC20(_token).balanceOf(address(this));
    IStakingProxyConvex(_vault).withdrawLockedAndUnwrap(_locks.key);
    _unlocked = IERC20(_token).balanceOf(address(this)) - _unlocked;
    require(_amount <= _unlocked, "ConcentratorStrategy: withdraw more than locked");

    if (_unlocked != _amount && !paused()) {
      // don't extend lock duration when paused or all tokens are withdrawn
      _locks.key = IStakingProxyConvex(_vault).stakeLockedCurveLp(_unlocked - _amount, _locks.duration);
      _locks.unlockAt = uint64(block.timestamp + _locks.duration);
    } else {
      pendingToLock += _unlocked - _amount;
      _locks.key = bytes32(0);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

// solhint-disable var-name-mixedcase
// solhint-disable func-name-mixedcase

interface IFraxUnifiedFarm {
  // Struct for the stake
  struct LockedStake {
    bytes32 kek_id;
    uint256 start_timestamp;
    uint256 liquidity;
    uint256 ending_timestamp;
    uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
  }

  function lock_time_min() external view returns (uint256);

  function lock_time_for_max_multiplier() external view returns (uint256);

  // Total locked liquidity / LP tokens
  function lockedLiquidityOf(address account) external view returns (uint256);

  // Total 'balance' used for calculating the percent of the pool the account owns
  // Takes into account the locked stake time multiplier and veFXS multiplier
  function combinedWeightOf(address account) external view returns (uint256);

  // Calculate the combined weight for an account
  function calcCurCombinedWeight(address account)
    external
    view
    returns (
      uint256 old_combined_weight,
      uint256 new_vefxs_multiplier,
      uint256 new_combined_weight
    );

  function veFXSMultiplier(address account) external view returns (uint256 vefxs_multiplier);

  // All the locked stakes for a given account
  function lockedStakesOf(address account) external view returns (LockedStake[] memory);

  function calcCurrLockMultiplier(address account, uint256 stake_idx)
    external
    view
    returns (uint256 midpoint_lock_multiplier);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase

interface IStakingProxyConvex {
  function stakingAddress() external view returns (address);

  //create a new locked state of _secs timelength with a Curve LP token
  function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

  //create a new locked state of _secs timelength with a Convex deposit token
  function stakeLockedConvexToken(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

  //create a new locked state of _secs timelength
  function stakeLocked(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

  //add to a current lock
  function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;

  //add to a current lock
  function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external;

  //add to a current lock
  function lockAdditionalConvexToken(bytes32 _kek_id, uint256 _addl_liq) external;

  // Extends the lock of an existing stake
  function lockLonger(bytes32 _kek_id, uint256 new_ending_ts) external;

  //withdraw a staked position
  //frax farm transfers first before updating farm state so will checkpoint during transfer
  function withdrawLocked(bytes32 _kek_id) external;

  //withdraw a staked position
  //frax farm transfers first before updating farm state so will checkpoint during transfer
  function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

  //helper function to combine earned tokens on staking contract and any tokens that are on this vault
  function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned);

  /*
    claim flow:
        claim rewards directly to the vault
        calculate fees to send to fee deposit
        send fxs to a holder contract for fees
        get reward list of tokens that were received
        send all remaining tokens to owner

    A slightly less gas intensive approach could be to send rewards directly to a holder contract and have it sort everything out.
    However that makes the logic a bit more complex as well as runs a few future proofing risks
    */
  function getReward() external;

  //get reward with claim option.
  //_claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
  //there are tokens on this vault for cases such as withdraw() also calling claim.
  //can also be used to rescue tokens on the vault
  function getReward(bool _claim) external;

  //auxiliary function to supply token list(save a bit of gas + dont have to claim everything)
  //_claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
  //there are tokens on this vault for cases such as withdraw() also calling claim.
  //can also be used to rescue tokens on the vault
  function getReward(bool _claim, address[] calldata _rewardTokenList) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexFraxBooster {
  function createVault(uint256 _pid) external returns (address);
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/IZap.sol";

import "./ConcentratorStrategyBase.sol";

abstract contract AutoCompoundingStrategyBase is ConcentratorStrategyBase {
  using SafeERC20 for IERC20;

  function _harvest(
    address _zapper,
    address _intermediate,
    address _target,
    address[] memory _rewards,
    uint256[] memory _amounts
  ) internal returns (uint256 _harvested) {
    // 1. zap all rewards to intermediate token.
    for (uint256 i = 0; i < rewards.length; i++) {
      address _rewardToken = _rewards[i];
      uint256 _amount = _amounts[i];
      if (_rewardToken == _intermediate) {
        _harvested += _amount;
      } else if (_amount > 0) {
        IERC20(_rewardToken).safeTransfer(_zapper, _amount);
        _harvested += IZap(_zapper).zap(_rewardToken, _amount, _intermediate, 0);
      }
    }

    // 2. add liquidity to staking token.
    if (_harvested > 0) {
      if (_intermediate == address(0)) {
        _harvested = IZap(_zapper).zap{ value: _harvested }(_intermediate, _harvested, _target, 0);
      } else {
        IERC20(_intermediate).safeTransfer(_zapper, _harvested);
        _harvested = IZap(_zapper).zap(_intermediate, _harvested, _target, 0);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
  function updateRewards(address[] memory _rewards) external override onlyOperator {
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
library SafeMath {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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