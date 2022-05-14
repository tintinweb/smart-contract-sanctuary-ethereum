// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {IStaker, Duration, StakeLevel} from '../interfaces/IStaker.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// import 'hardhat/console.sol'; // todo: remove this

contract InfinityStaker is IStaker, Ownable, Pausable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  struct StakeAmount {
    uint256 amount;
    uint256 timestamp;
  }
  mapping(address => mapping(Duration => StakeAmount)) public userstakedAmounts;
  address public INFINITY_TOKEN;
  address public INFINITY_TREASURY;
  address public INFINITY_REWARDS_CONTRACT;
  uint16 public BRONZE_STAKE_THRESHOLD = 1000;
  uint16 public SILVER_STAKE_THRESHOLD = 5000;
  uint16 public GOLD_STAKE_THRESHOLD = 10000;
  uint16 public PLATINUM_STAKE_THRESHOLD = 20000;
  uint16 public THREE_MONTH_PENALTY = 2;
  uint16 public SIX_MONTH_PENALTY = 3;
  uint16 public TWELVE_MONTH_PENALTY = 4;

  event Staked(address indexed user, uint256 amount, Duration duration);
  event DurationChanged(address indexed user, uint256 amount, Duration oldDuration, Duration newDuration);
  event UnStaked(address indexed user, uint256 amount);
  event RageQuit(address indexed user, uint256 totalToUser, uint256 penalty);

  constructor(address _tokenAddress, address _infinityTreasury) {
    INFINITY_TOKEN = _tokenAddress;
    INFINITY_TREASURY = _infinityTreasury;
  }

  // Fallback
  fallback() external payable {}

  receive() external payable {}

  // =================================================== USER FUNCTIONS =======================================================
  function stake(
    address user,
    uint256 amount,
    Duration duration
  ) external override nonReentrant whenNotPaused {
    // console.log('stake msg sender', msg.sender, 'infinity rewards contract', INFINITY_REWARDS_CONTRACT);
    require(msg.sender == user || msg.sender == INFINITY_REWARDS_CONTRACT, 'Only user or infinity rewards can stake');
    require(amount != 0, 'stake amount cant be 0');
    require(IERC20(INFINITY_TOKEN).balanceOf(user) >= amount, 'insufficient balance to stake');
    // console.log('staking for user', user, 'amount', amount);
    // update storage
    // console.log('block timestmap at stake', block.timestamp);
    userstakedAmounts[user][duration].amount += amount;
    userstakedAmounts[user][duration].timestamp = block.timestamp;
    // perform transfer
    // console.log('transferring', amount, 'from', user);
    // console.log('user balance before', IERC20(INFINITY_TOKEN).balanceOf(user));
    // console.log('contract balance before', IERC20(INFINITY_TOKEN).balanceOf(address(this)));
    if (msg.sender != INFINITY_REWARDS_CONTRACT) {
      IERC20(INFINITY_TOKEN).safeTransferFrom(user, address(this), amount);
    }
    // console.log('user balance after', IERC20(INFINITY_TOKEN).balanceOf(user));
    // console.log('contract balance after', IERC20(INFINITY_TOKEN).balanceOf(address(this)));
    // emit event
    emit Staked(user, amount, duration);
  }

  function changeDuration(
    uint256 amount,
    Duration oldDuration,
    Duration newDuration
  ) external override nonReentrant whenNotPaused {
    require(amount != 0, 'amount cant be 0');
    require(
      userstakedAmounts[msg.sender][oldDuration].amount >= amount,
      'insufficient staked amount to change duration'
    );
    require(newDuration > oldDuration, 'new duration must be greater than old duration');

    // update storage
    userstakedAmounts[msg.sender][oldDuration].amount -= amount;
    userstakedAmounts[msg.sender][newDuration].amount += amount;
    // only update timestamp for new duration
    userstakedAmounts[msg.sender][newDuration].timestamp = block.timestamp;
    // emit event
    emit DurationChanged(msg.sender, amount, oldDuration, newDuration);
  }

  function unstake(uint256 amount) external override nonReentrant whenNotPaused {
    require(amount != 0, 'stake amount cant be 0');
    uint256 noVesting = userstakedAmounts[msg.sender][Duration.NONE].amount;
    uint256 vestedThreeMonths = _getVestedAmount(msg.sender, Duration.THREE_MONTHS);
    uint256 vestedsixMonths = _getVestedAmount(msg.sender, Duration.SIX_MONTHS);
    uint256 vestedTwelveMonths = _getVestedAmount(msg.sender, Duration.TWELVE_MONTHS);
    uint256 totalVested = noVesting + vestedThreeMonths + vestedsixMonths + vestedTwelveMonths;
    require(totalVested >= amount, 'insufficient balance to unstake');

    // update storage
    _updateUserStakedAmounts(msg.sender, amount, noVesting, vestedThreeMonths, vestedsixMonths, vestedTwelveMonths);
    // perform transfer
    IERC20(INFINITY_TOKEN).safeTransfer(msg.sender, amount);
    // emit event
    emit UnStaked(msg.sender, amount);
  }

  function rageQuit() external override nonReentrant {
    (uint256 totalToUser, uint256 penalty) = _getRageQuitAmounts(msg.sender);
    // update storage
    _clearUserStakedAmounts(msg.sender);
    // perform transfers
    IERC20(INFINITY_TOKEN).safeTransfer(msg.sender, totalToUser);
    IERC20(INFINITY_TOKEN).safeTransfer(INFINITY_TREASURY, penalty);
    // emit event
    emit RageQuit(msg.sender, totalToUser, penalty);
  }

  // ====================================================== VIEW FUNCTIONS ======================================================

  function getUserTotalStaked(address user) external view override returns (uint256) {
    return _getUserTotalStaked(user);
  }

  function getUserTotalVested(address user) external view override returns (uint256) {
    return _getUserTotalVested(user);
  }

  function getRageQuitAmounts(address user) external view override returns (uint256, uint256) {
    return _getRageQuitAmounts(user);
  }

  function getUserStakeLevel(address user) external view override returns (StakeLevel) {
    uint256 totalPower = _getUserStakePower(user);
    // console.log('totalPower', totalPower);
    if (totalPower <= BRONZE_STAKE_THRESHOLD) {
      return StakeLevel.NONE;
    } else if (totalPower > BRONZE_STAKE_THRESHOLD && totalPower <= SILVER_STAKE_THRESHOLD) {
      return StakeLevel.BRONZE;
    } else if (totalPower > SILVER_STAKE_THRESHOLD && totalPower <= GOLD_STAKE_THRESHOLD) {
      return StakeLevel.SILVER;
    } else if (totalPower > GOLD_STAKE_THRESHOLD && totalPower <= PLATINUM_STAKE_THRESHOLD) {
      return StakeLevel.GOLD;
    } else {
      return StakeLevel.PLATINUM;
    }
  }

  function getUserStakePower(address user) external view override returns (uint256) {
    return _getUserStakePower(user);
  }

  function getVestingInfo(address user) external view returns (StakeAmount[] memory) {
    StakeAmount[] memory vestingInfo = new StakeAmount[](4);
    vestingInfo[0] = userstakedAmounts[user][Duration.NONE];
    vestingInfo[1] = userstakedAmounts[user][Duration.THREE_MONTHS];
    vestingInfo[2] = userstakedAmounts[user][Duration.SIX_MONTHS];
    vestingInfo[3] = userstakedAmounts[user][Duration.TWELVE_MONTHS];
    return vestingInfo;
  }

  // ====================================================== INTERNAL FUNCTIONS ================================================

  function _getUserTotalStaked(address user) internal view returns (uint256) {
    return
      userstakedAmounts[user][Duration.NONE].amount +
      userstakedAmounts[user][Duration.THREE_MONTHS].amount +
      userstakedAmounts[user][Duration.SIX_MONTHS].amount +
      userstakedAmounts[user][Duration.TWELVE_MONTHS].amount;
  }

  function _getUserTotalVested(address user) internal view returns (uint256) {
    uint256 noVesting = _getVestedAmount(user, Duration.NONE);
    uint256 vestedThreeMonths = _getVestedAmount(user, Duration.THREE_MONTHS);
    uint256 vestedsixMonths = _getVestedAmount(user, Duration.SIX_MONTHS);
    uint256 vestedTwelveMonths = _getVestedAmount(user, Duration.TWELVE_MONTHS);
    return noVesting + vestedThreeMonths + vestedsixMonths + vestedTwelveMonths;
  }

  function _getRageQuitAmounts(address user) internal view returns (uint256, uint256) {
    uint256 noLock = userstakedAmounts[user][Duration.NONE].amount;
    uint256 threeMonthLock = userstakedAmounts[user][Duration.THREE_MONTHS].amount;
    uint256 sixMonthLock = userstakedAmounts[user][Duration.SIX_MONTHS].amount;
    uint256 twelveMonthLock = userstakedAmounts[user][Duration.TWELVE_MONTHS].amount;

    uint256 threeMonthVested = _getVestedAmount(user, Duration.THREE_MONTHS);
    uint256 sixMonthVested = _getVestedAmount(user, Duration.SIX_MONTHS);
    uint256 twelveMonthVested = _getVestedAmount(user, Duration.TWELVE_MONTHS);

    uint256 totalVested = noLock + threeMonthVested + sixMonthVested + twelveMonthVested;
    uint256 totalStaked = noLock + threeMonthLock + sixMonthLock + twelveMonthLock;
    require(totalStaked >= 0, 'nothing staked to rage quit');

    uint256 totalToUser = totalVested +
      ((threeMonthLock - threeMonthVested) / THREE_MONTH_PENALTY) +
      ((sixMonthLock - sixMonthVested) / SIX_MONTH_PENALTY) +
      ((twelveMonthLock - twelveMonthVested) / TWELVE_MONTH_PENALTY);

    uint256 penalty = totalStaked - totalToUser;

    return (totalToUser, penalty);
  }

  function _getVestedAmount(address user, Duration duration) internal view returns (uint256) {
    uint256 amount = userstakedAmounts[user][duration].amount;
    uint256 timestamp = userstakedAmounts[user][duration].timestamp;
    // short circuit if no vesting for this duration
    if (timestamp == 0) {
      return 0;
    }
    uint256 durationInSeconds = _getDurationInSeconds(duration);
    uint256 secondsSinceStake = block.timestamp - timestamp;
    // console.log('====================== fetching vested amount =========================');
    // console.log('stake amount', amount);
    // console.log('durationInSeconds', durationInSeconds);
    // console.log('current block timestamp', block.timestamp);
    // console.log('stake timestamp', timestamp);
    // console.log('secondsSinceStake', secondsSinceStake);
    return secondsSinceStake >= durationInSeconds ? amount : 0;
  }

  function _getDurationInSeconds(Duration duration) internal pure returns (uint256) {
    if (duration == Duration.THREE_MONTHS) {
      return 90 days;
    } else if (duration == Duration.SIX_MONTHS) {
      return 180 days;
    } else if (duration == Duration.TWELVE_MONTHS) {
      return 360 days;
    } else {
      return 0 seconds;
    }
  }

  function _getUserStakePower(address user) internal view returns (uint256) {
    return
      ((userstakedAmounts[user][Duration.NONE].amount * 1) +
        (userstakedAmounts[user][Duration.THREE_MONTHS].amount * 2) +
        (userstakedAmounts[user][Duration.SIX_MONTHS].amount * 3) +
        (userstakedAmounts[user][Duration.TWELVE_MONTHS].amount * 4)) / (10**18);
  }

  // a recursive impl is possible but this is more gas efficient
  function _updateUserStakedAmounts(
    address user,
    uint256 amount,
    uint256 noVesting,
    uint256 vestedThreeMonths,
    uint256 vestedSixMonths,
    uint256 vestedTwelveMonths
  ) internal {
    if (amount > noVesting) {
      userstakedAmounts[user][Duration.NONE].amount = 0;
      amount = amount - noVesting;
      if (amount > vestedThreeMonths) {
        userstakedAmounts[user][Duration.THREE_MONTHS].amount = 0;
        amount = amount - vestedThreeMonths;
        if (amount > vestedSixMonths) {
          userstakedAmounts[user][Duration.SIX_MONTHS].amount = 0;
          amount = amount - vestedSixMonths;
          if (amount > vestedTwelveMonths) {
            userstakedAmounts[user][Duration.TWELVE_MONTHS].amount = 0;
          } else {
            userstakedAmounts[user][Duration.TWELVE_MONTHS].amount -= amount;
          }
        } else {
          userstakedAmounts[user][Duration.SIX_MONTHS].amount -= amount;
        }
      } else {
        userstakedAmounts[user][Duration.THREE_MONTHS].amount -= amount;
      }
    } else {
      userstakedAmounts[user][Duration.NONE].amount -= amount;
    }
  }

  function _clearUserStakedAmounts(address user) internal {
    // clear amounts
    userstakedAmounts[user][Duration.NONE].amount = 0;
    userstakedAmounts[user][Duration.THREE_MONTHS].amount = 0;
    userstakedAmounts[user][Duration.SIX_MONTHS].amount = 0;
    userstakedAmounts[user][Duration.TWELVE_MONTHS].amount = 0;

    // clear timestamps
    userstakedAmounts[user][Duration.NONE].timestamp = 0;
    userstakedAmounts[user][Duration.THREE_MONTHS].timestamp = 0;
    userstakedAmounts[user][Duration.SIX_MONTHS].timestamp = 0;
    userstakedAmounts[user][Duration.TWELVE_MONTHS].timestamp = 0;
  }

  // ====================================================== ADMIN FUNCTIONS ================================================

  function rescueTokens(
    address destination,
    address currency,
    uint256 amount
  ) external onlyOwner {
    IERC20(currency).safeTransfer(destination, amount);
  }

  function rescueETH(address destination) external payable onlyOwner {
    (bool sent, ) = destination.call{value: msg.value}('');
    require(sent, 'Failed to send Ether');
  }

  function updateStakeLevelThreshold(StakeLevel stakeLevel, uint16 threshold) external onlyOwner {
    if (stakeLevel == StakeLevel.BRONZE) {
      BRONZE_STAKE_THRESHOLD = threshold;
    } else if (stakeLevel == StakeLevel.SILVER) {
      SILVER_STAKE_THRESHOLD = threshold;
    } else if (stakeLevel == StakeLevel.GOLD) {
      GOLD_STAKE_THRESHOLD = threshold;
    } else if (stakeLevel == StakeLevel.PLATINUM) {
      PLATINUM_STAKE_THRESHOLD = threshold;
    }
  }

  function updatePenalties(
    uint16 threeMonthPenalty,
    uint16 sixMonthPenalty,
    uint16 twelveMonthPenalty
  ) external onlyOwner {
    THREE_MONTH_PENALTY = threeMonthPenalty;
    SIX_MONTH_PENALTY = sixMonthPenalty;
    TWELVE_MONTH_PENALTY = twelveMonthPenalty;
  }

  function updateInfinityTreasury(address _infinityTreasury) external onlyOwner {
    INFINITY_TREASURY = _infinityTreasury;
  }

  function updateInfinityRewardsContract(address _infinityRewardsContract) external onlyOwner {
    INFINITY_REWARDS_CONTRACT = _infinityRewardsContract;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from '../libs/OrderTypes.sol';

enum Duration {
  NONE,
  THREE_MONTHS,
  SIX_MONTHS,
  TWELVE_MONTHS
}

enum StakeLevel {
  NONE,
  BRONZE,
  SILVER,
  GOLD,
  PLATINUM
}

interface IStaker {
  function stake(address user, uint256 amount, Duration duration) external;

  function changeDuration(uint256 amount, Duration oldDuration, Duration newDuration) external;

  function unstake(uint256 amount) external;

  function rageQuit() external;

  function getUserTotalStaked(address user) external view returns (uint256);

  function getUserTotalVested(address user) external view returns (uint256);

  function getRageQuitAmounts(address user) external view returns (uint256, uint256);

  function getUserStakePower(address user) external view returns (uint256);

  function getUserStakeLevel(address user) external view returns (StakeLevel);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 */
library OrderTypes {
  struct TokenInfo {
    uint256 tokenId;
    uint256 numTokens;
  }

  struct OrderItem {
    address collection;
    TokenInfo[] tokens;
  }

  struct Order {
    // is order sell or buy
    bool isSellOrder;
    address signer;
    // total length: 7
    // in order:
    // numItems - min/max number of items in the order
    // start and end prices in wei
    // start and end times in block.timestamp
    // minBpsToSeller
    // nonce
    uint256[] constraints;
    // collections and tokenIds
    OrderItem[] nfts;
    // address of complication for trade execution (e.g. OrderBook), address of the currency (e.g., WETH)
    address[] execParams;
    // additional parameters like rarities, private sale buyer etc
    bytes extraParams;
    // uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
    bytes sig;
  }
}