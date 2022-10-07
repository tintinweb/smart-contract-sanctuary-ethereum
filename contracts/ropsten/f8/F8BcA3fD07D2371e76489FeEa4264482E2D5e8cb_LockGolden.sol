// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (lock/LockGolden.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract LockGolden {
    struct staker {
        uint256 amount;
        uint256 pendingReward;
        uint256 lockedTime;
        uint256 expireTime;
    }

    event Withdraw(address account, uint256 amount);
    event Stake(address account, uint256 amount, uint256 unlocktime);

    IERC20 public golden = IERC20(0x261b75ceDe05A03586ebe27C49969361CeB4Fc82);
    //this: 0xF8BcA3fD07D2371e76489FeEa4264482E2D5e8cb
    mapping(address => staker) public _stakers;

    function stake(
        address account,
        uint256 amount,
        uint8 unlockTime
    ) public returns (uint256 currentBalance, staker memory currentStaker) {
        require(amount != 0, "amount must not 0");
        require(
            unlockTime == 10 || unlockTime == 20 || unlockTime == 30,
            "unlockTime must be 10, 20 or 30."
        );

        if (unlockTime == 10)
            require(amount >= 500 * 10 ** 18, "Too little money, bet more!");
        if (unlockTime == 20)
            require(amount >= 1000 * 10 ** 18, "Too little money, bet more!");
        if (unlockTime == 30)
            require(amount >= 3000 * 10 ** 18, "Too little money, bet more!");
        staker storage _staker = _stakers[account];
        require(
            _staker.amount == 0,
            "You have already bet. Wait until current bet expires."
        );
        _staker.amount = amount;
        _staker.pendingReward = amount * 2;
        _staker.lockedTime = block.timestamp;
        _staker.expireTime = block.timestamp + unlockTime;

        if (golden.transferFrom(msg.sender, address(this), amount)) {
            emit Stake(account, amount, block.timestamp + unlockTime);
            return (golden.balanceOf(account), _staker);
        }
    }

    function withdraw(address account) public returns (uint256 currentBalance) {
        staker memory currentStaker = _stakers[account];
        require(currentStaker.amount != 0, "You didn't bet yet.");
        require(
            block.timestamp > currentStaker.expireTime,
            "Please wait until bet expires."
        );

        if (
            golden.transfer(account, currentStaker.pendingReward)
        ) {
            _stakers[account].amount = 0;
            emit Withdraw(account, currentStaker.amount);
            return golden.balanceOf(account);
        }
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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