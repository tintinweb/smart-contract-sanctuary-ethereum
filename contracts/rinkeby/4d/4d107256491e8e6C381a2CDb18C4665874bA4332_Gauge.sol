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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./RewardTokenWrapper.sol";

contract Gauge is RewardTokenWrapper, ReentrancyGuard {
  /**
   * @notice The reward token address
   */
  IERC20 public rewardToken;

  /**
   * @notice The token amount per second distributed to lockers
   */
  uint256 public rewardRate;

  /**
   * @notice The epoch time in seconds when reward finishes
   */
  uint256 public periodFinish;

  /**
   * @notice The last epoch time in seconds when the gauge has been updated
   */
  uint256 public lastUpdateTime;

  /**
   * @notice The reward token amount per 1 locked token
   */
  uint256 public rewardPerTokenStored;

  /**
   * @notice The reward distribution cycle.
   * It defines how long the protocol distributes the rewards to lockers
   */
  uint256 public immutable REWARD_DURATION = 7 days;

  /**
   * @notice The address to operate the protocol
   */
  address public immutable OPERATOR;

  /**
   * @notice This is the data struture to store reward information for each locker
   * @param userRewardPerTokenPaid - The reward token amount per token which has been already paid
   * @param reward - The reward token amount earned by the lockers
   */
  struct UserRewards {
    uint256 userRewardPerTokenPaid;
    uint256 rewards;
  }

  /**
   * @notice Used to store user reward information. msg.sender => UserRewards
   */
  mapping(address => UserRewards) public userRewards;

  /**
   * @notice Emitted when reward is added by the operator
   * @param reward - The reward token amount to pay lockers
   */
  event RewardAdded(uint256 reward);

  /**
   * @notice Emitted when reward is paid to the locker
   * @param user - The locker address to pay to
   * @param reward- The token amount to pay the user
   */
  event RewardPaid(address indexed user, uint256 reward);

  /**
   * @notice Throws if called by any account other than the operator
   */
  modifier onlyOperator() {
    require(msg.sender == OPERATOR, "Caller is not the operator");
    _;
  }

  /**
   * @notice Updates reward information for the user
   * @param account - The locker address you're going to update for
   */
  modifier updateReward(address account) {
    uint256 _rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    rewardPerTokenStored = _rewardPerTokenStored;
    userRewards[account].rewards = earned(account);
    userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
    _;
  }

  // ========== Initializer ============

  constructor(address _rewardToken) {
    rewardToken = IERC20(_rewardToken);
    OPERATOR = msg.sender;
  }

  // ========== Operator Functions ============

  /**
   * @notice Creates a lock for the account `forWhom` to give rewards
   * @dev Updates user's reward information before creating a lock
   * @param forWhom - The address you're going to give rewards to
   * @param amount - The amount you're going to put for the `forWhom`
   */
  function lockFor(address forWhom, uint256 amount)
    public
    updateReward(forWhom)
    onlyOperator
  {
    super._lockFor(forWhom, amount);
  }

  /**
   * @notice Unlocks the lock for the account `forWhom`
   * @dev Updates user's reward information before creating a lock
   * @param forWhom - The address you're going to unlock for
   */
  function unlockFor(address forWhom)
    public
    updateReward(forWhom)
    onlyOperator
  {
    super._unlockFor(forWhom);
  }

  /**
   * @notice Puts reward params for the protocol
   * @param reward - The reward amount you're going to distribute for the protocol
   */
  function setRewardParams(uint256 reward) external onlyOperator {
    unchecked {
      require(reward > 0);
      rewardPerTokenStored = rewardPerToken();
      uint256 blockTimestamp = uint256(block.timestamp);
      uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
      uint256 leftover = 0;
      if (blockTimestamp >= periodFinish) {
        rewardRate = reward / REWARD_DURATION;
      } else {
        uint256 remaining = periodFinish - blockTimestamp;
        leftover = remaining * rewardRate;
        rewardRate = (reward + leftover) / REWARD_DURATION;
      }
      require(reward + leftover <= maxRewardSupply, "not enough tokens");
      lastUpdateTime = blockTimestamp;
      periodFinish = blockTimestamp + REWARD_DURATION;
      emit RewardAdded(reward);
    }
  }

  /**
   * @notice Withdraws the remaing reward to the `recipient`
   * @param recipient - The address you're going to transfer the rest balance
   */
  function withdrawReward(address recipient) external onlyOperator {
    uint256 rewardSupply = rewardToken.balanceOf(address(this));
    require(rewardToken.transfer(recipient, rewardSupply));
    rewardRate = 0;
    periodFinish = uint256(block.timestamp);
  }

  // ========== Public View Functions ============

  /**
   * @notice Returns last epoch time that lockers can get rewarded
   */
  function lastTimeRewardApplicable() public view returns (uint256) {
    uint256 blockTimestamp = uint256(block.timestamp);
    return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
  }

  /**
   * @notice Returns reward token amount per lock amount
   */
  function rewardPerToken() public view returns (uint256) {
    uint256 totalLockedSupply = totalSupply;
    if (totalLockedSupply == 0) {
      return rewardPerTokenStored;
    }
    unchecked {
      uint256 rewardDuration = lastTimeRewardApplicable() - lastUpdateTime;
      return
        uint256(
          rewardPerTokenStored +
            (rewardDuration * rewardRate * 1e18) /
            totalLockedSupply
        );
    }
  }

  /**
   * @notice Returns the reward amount locker can claim
   */
  function earned(address account) public view returns (uint256) {
    unchecked {
      return
        uint256(
          (balanceOf(account) *
            (rewardPerToken() - userRewards[account].userRewardPerTokenPaid)) /
            1e18 +
            userRewards[account].rewards
        );
    }
  }

  // ========== Public Functions ============

  /**
   * @notice Claims reward earned
   * @dev Once the operator puts locking information for user, user can claim reward
   */
  function getReward() public updateReward(msg.sender) {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      userRewards[msg.sender].rewards = 0;
      require(
        rewardToken.transfer(msg.sender, reward),
        "reward transfer failed"
      );
      emit RewardPaid(msg.sender, reward);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardTokenWrapper {
  /**
   * @notice Total locking amount settled by the operator
   */
  uint256 public totalSupply;

  /**
   * @dev Stores account => lock balance
   */
  mapping(address => uint256) private _balances;

  /**
   * @notice Emitted when the operator creates a lock for `user`
   * @param user - The address the operator creates a lock for
   * @param amount - The amount the operator creates a lock for `user`
   */
  event Locked(address indexed user, uint256 amount);

  /**
   * @notice Emitted when the operator unlocks for `user`
   * @param user - The address the operator releases a lock for
   * @param amount - The amount the operator releases a lock for `user`
   */
  event Unlocked(address indexed user, uint256 amount);

  /**
   * @notice Returns the locking amount of `account`
   */
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  /**
   * @notice Creates a lock for `forWhom` with `amount`
   * @param forWhom - The address you're going to create a lock for
   * @param amount - The amount you're going to lock for `forWhom`
   */
  function _lockFor(address forWhom, uint256 amount) internal virtual {
    require(amount > 0, "Cannot lock 0");
    unchecked {
      totalSupply += amount;
      _balances[forWhom] += amount;
    }
    emit Locked(forWhom, amount);
  }

  /**
   * @notice Releases a lock for `forWhom`
   * @dev Unlocks all the amount locked by the operator
   * @param account - The address you're going to release for
   */
  function _unlockFor(address account) internal virtual {
    uint256 userBalance = _balances[account];
    unchecked {
      totalSupply = totalSupply - userBalance;
    }
    emit Unlocked(account, userBalance);
  }
}