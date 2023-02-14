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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IMintableToken.sol";

/** @dev
 * This is a practice exercise for a simple staking contract.
 * Users can lock up MungToken for 10 minutes to receive FarmTokens.
 * When the lock-up is unlocked, 10% of the MungToken lock-up amount
 * will be minted as FarmTokens and sent to the staker.
 */

contract MungStaker {
  error MungStaker__InvalidAmount();
  error MungStaker__LockUpAlreadyExists();
  error MungStaker__LockUpDoesNotExists();
  error MungStaker__LockUpHasNotMatured();

  IMintableToken public mungToken; // Token to be staked
  IMintableToken public farmToken; // Token to be farmed

  uint256 public constant LOCK_UP_DURATION = 600; // 10 minutes
  uint256 public constant FARMING_RATIO = 1000; // 1,000bp = 10% of lockUp amount

  // Gas saving
  // REF: https://medium.com/@novablitz/774da988895e
  struct LockUp {
    uint40 lockedAt;
    uint216 amount;
  }
  // To make it simple, a wallet can only have one lockUp at the same time
  mapping (address => LockUp) public userLockUp;
  uint256 public activeLockUpCount;

  event LockedUp(address indexed user, uint216 amount);
  event Unlocked(address indexed user, uint216 amount);

  constructor(address mungToken_, address farmToken_) {
    mungToken = IMintableToken(mungToken_);
    farmToken = IMintableToken(farmToken_); // must have the ownership
  }

  function lockUp(uint216 amount) external {
    if (amount == 0) revert MungStaker__InvalidAmount();

    LockUp storage ul = userLockUp[msg.sender];
    if (ul.lockedAt > 0) revert MungStaker__LockUpAlreadyExists();

    mungToken.transferFrom(msg.sender, address(this), amount);

    ul.lockedAt = uint40(block.timestamp);
    ul.amount = amount;
    activeLockUpCount += 1;

    emit LockedUp(msg.sender, amount);
  }

  function unlock() external {
    LockUp storage ul = userLockUp[msg.sender];

    if (ul.lockedAt == 0) revert MungStaker__LockUpDoesNotExists();
    if (ul.lockedAt + LOCK_UP_DURATION >= block.timestamp) revert MungStaker__LockUpHasNotMatured();

    uint256 amountToSend = ul.amount;
    ul.lockedAt = 0;
    ul.amount = 0;
    activeLockUpCount -= 1;

    mungToken.transfer(msg.sender, amountToSend);
    // Distribute farming tokens to the staker, 10% of the MUNG token lock-up amount
    farmToken.mint(msg.sender, amountToSend * FARMING_RATIO / 10000);

    emit Unlocked(msg.sender, uint216(amountToSend));
  }

  function lockUpExists(address user) external view returns(bool) {
    return userLockUp[user].lockedAt > 0;
  }
}