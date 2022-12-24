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
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BZNTimelock {
    struct LockMapping {
        uint256 unlockTime;
        uint256 lockedAmount;
    }

    IERC20 public lockedToken;
    mapping(address => LockMapping) public lockedTokens;

    event TokensLocked(address recipient, uint256 amount, uint256 unlockDate);
    event TokensUnlocked(
        address recipient,
        uint256 unlockedAmount,
        uint256 remaining
    );

    constructor(IERC20 token) {
        lockedToken = token;
    }

    function lockTokensFrom(
        address from,
        address unlockRecipient,
        uint256 amount,
        uint256 duration
    ) external {
        if (lockedTokens[unlockRecipient].unlockTime == 0) {
            lockedTokens[unlockRecipient] = LockMapping(
                block.timestamp + duration,
                amount
            );
        } else {
            lockedTokens[unlockRecipient].unlockTime += duration;
            lockedTokens[unlockRecipient].lockedAmount += amount;
        }

        if (amount > 0) {
            // Transfer tokens
            require(lockedToken.allowance(from, address(this)) >= amount);
            lockedToken.transferFrom(from, address(this), amount);
        }

        emit TokensLocked(
            unlockRecipient,
            lockedTokens[unlockRecipient].lockedAmount,
            lockedTokens[unlockRecipient].unlockTime
        );
    }

    function withdraw(uint256 amount) external {
        address unlockRecipient = msg.sender;
        LockMapping storage lockData = lockedTokens[unlockRecipient];

        require(block.timestamp >= lockData.unlockTime);
        require(amount <= lockData.lockedAmount);

        lockData.lockedAmount -= amount;
        lockedToken.transfer(unlockRecipient, amount);

        emit TokensUnlocked(unlockRecipient, amount, lockData.lockedAmount);
    }
}