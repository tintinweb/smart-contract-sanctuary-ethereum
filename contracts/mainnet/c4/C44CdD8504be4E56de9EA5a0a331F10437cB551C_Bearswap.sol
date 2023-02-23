/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: GPL-2.0-or-later




/*******   This is Hex Bear   *******
 The Buy Button of Hex turned into an ERC20. 

 */


pragma solidity =0.8.18;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3swapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}




pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IswapRouter is IUniswapV3swapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}



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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}



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

// File: https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;


library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (abi.decode(data, (bool))), "Safe Transfer Failed.");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 8;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}



// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }   
}

// The 'Staker' inflation is intended for a seperate staking contract.

contract Bearswap is ERC20, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public startTime;
    uint256 public endTime;
    ERC20 public claimToken;
    ERC20 public claimToken2;
    ERC20 public claimToken3;
    uint256 public swapCounter;
    address public StakersAdd;
    uint256 private stakerAmount;
    uint256 private requiredAmount;
    uint256 lastMintTimestamp;

    mapping(address => User) public users;
struct User {
    uint256 lastMintTime;
    uint256 heldHexTimestamp;
    uint256 receivedHex;
    uint256 mintCount;
    bool initialswapComplete;
}
Global private global;
struct Global {
    uint256 waitTime;
    uint256 missedMinting;
    uint256 stakeRate;
}
    event eventreceivedHex(address user, uint receivedHex);
    event Mint(address _address);
    mapping(address => uint256) private balances;
    
      // pool fee 0.3%.
      uint24 public constant poolFee = 3000;
      address private constant routerAddress =
      0xE592427A0AEce92De3Edee1F18E0157C05861564;
      IswapRouter public immutable swapRouter = IswapRouter(routerAddress);
   
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant HEX = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;

    ERC20 public hex_token = ERC20(HEX);
    ERC20 public usdc_token = ERC20(USDC);

    // pool fee 0.3%.
    constructor(address _StakersAdd, uint256 _startTime, uint256 _endTime,address _ClaimToken, address _ClaimToken2, address _ClaimToken3) ERC20("Hex Bear", "HXBR") {
    _mint(msg.sender, 500000000);
    lastMintTimestamp = block.timestamp;    
    StakersAdd = _StakersAdd;
    startTime = _startTime;
    endTime = _endTime;
    claimToken = ERC20(_ClaimToken);
    claimToken2 = ERC20(_ClaimToken2);
    claimToken3 = ERC20(_ClaimToken3);
    global = Global({
        waitTime: 86400,
        missedMinting: 0,
        stakeRate: 25
    }); }

    function AllowedToMint(address _address) public view returns (bool) {

    uint256 waitingTime = (global.waitTime.mul(users[_address].mintCount)).mul(2);

    if(users[_address].lastMintTime == 0) {
        return true;
    } else if(block.timestamp >= users[_address].lastMintTime.add(waitingTime)) {
        return true;
    }
    return false;
    }

/// This function swaps USDC for Hex and Mints an adjusted amount of Hex Bear
///
    function swap(uint256 amountIn) external nonReentrant returns (uint256 amountOut) {
    require(AllowedToMint(msg.sender),"WAIT");     
    require(usdc_token.allowance(msg.sender, address(this)) >= amountIn && amountIn > 0, "INUSDAL.");
    require(amountIn <= usdc_token.balanceOf(msg.sender) && amountIn > 0, "INUSDBAL");  
    require(hex_token.balanceOf(msg.sender) >= requiredAmount.add(500 * 10 ** 8).add(users[msg.sender].receivedHex), "RAMNT.");
    require (amountIn >= (swapCounter.mul(10 ** 2)), "MINUSDC");
    swapCounter++;
    User storage userData = users[msg.sender];
    userData.mintCount++;
    TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amountIn);
    TransferHelper.safeApprove(USDC, address(swapRouter), amountIn);
    IswapRouter.ExactInputSingleParams memory params = IswapRouter.ExactInputSingleParams({
        tokenIn: USDC,
        tokenOut: HEX,
        fee: poolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountOutMinimum: 0,
        amountIn: amountIn,
        sqrtPriceLimitX96: 0
    });
    amountOut = swapRouter.exactInputSingle(params);
    requiredAmount += (swapCounter).add(10 ** 4);
    userData.receivedHex += amountOut;
    uint256 mintUpdateTime = (global.waitTime.mul(userData.mintCount)).mul(2);
    uint256 StatAmount = amountOut.sub(swapCounter.mul(amountOut.div(10000000)));
    if (swapCounter >= 10000000) {
        if (amountOut.sub(swapCounter.mul(amountOut.div(10000000))) < 1) {
            StatAmount = 1;
        }
    }
    // Get the current mint count for the user
  uint256 count = userData.mintCount;
// Determine the mint amount based on the current mint count
  uint256 amount = StatAmount;
  if (count > 1 && count <= 5) {
    amount = StatAmount.mul(25).div(100);
  } else if (count > 5 && count <= 10) {
    amount = StatAmount.mul(50).div(100);
  } else if (count > 10 && count <= 20) {
    amount = StatAmount.mul(75).div(100);   
  } else if (count > 20 && count <= 25) {
    amount = StatAmount.mul(110).div(100); 
  } else if (count > 25 && count <= 40) {
    amount = StatAmount.mul(125).div(100); 
  } else if (count > 40 && count <= 55) {
    amount = StatAmount.mul(130).div(100); 
  } else if (count > 55 && count <= 100) {
    amount = StatAmount.mul(150).div(100); 
  } else {
    amount = StatAmount;
  }
// Get the maximum allowed value for amountOut on initial mint
  uint256 maxAmount = 100000000;
// If the initial swap has not been completed and amountOut is greater than the maximum allowed value, set it to the maximum allowed value
  if (!userData.initialswapComplete && amountOut > maxAmount) {
    amount = maxAmount;
  }
// Set the initialswapComplete value for the user to true
  userData.initialswapComplete = true;
// Require that the initial swap has been completed for the user if they are trying to mint more than 1 Hex Bear tokens
  require(userData.initialswapComplete || amountOut <= maxAmount);
// Calculate the amount of Hex tokens to mint
  // Calculate the staker's amount based on the specified staker's rate
    uint256 stakeAmount = amount.mul(global.stakeRate).div(100);
  // Mint tokens, subtracting the staker's amount from the total amount
    _mint(msg.sender, amount.sub(stakeAmount));
    _mint(StakersAdd, stakeAmount);
  // Update the balance of the recipient in the balances mapping
    balances[msg.sender] = balances[msg.sender] += amount.sub(stakeAmount);
    balances[StakersAdd] = balances[StakersAdd] += stakeAmount;
  // Update the userData struct with the latest information
    userData.lastMintTime = block.timestamp.add(global.waitTime).add(mintUpdateTime);
    userData.heldHexTimestamp = block.timestamp;
    users[msg.sender].receivedHex = users[msg.sender].receivedHex.add(amountOut);
  // Emit events to track the user's minting information
    emit Mint(msg.sender);
    // Making sure that currentMintAmount is not set to zero or a negative value
    require(amountIn > 0, "MORE0THAN");

    }
    


    // Gives the user their total wait period atm 

    function getWaitingTime(address _address) public view returns (uint256) {
    User storage userData = users[_address];
    uint256 waitingTime = (global.waitTime.mul(userData.mintCount)).mul(2);
    return waitingTime;
    }

    // Gives the user their amount of time left before they can mint
    function getRemainingTime(address _address) public view returns (uint256) {
    User storage userData = users[_address];
    // Get the waiting time for the user
    uint256 waitingTime = global.waitTime.mul(userData.mintCount).mul(2);
    // Get the time of the user's last mint
    uint256 lastMint = userData.heldHexTimestamp;
    // Calculate the time when the user is allowed to mint again
    uint256 allowedMintTime = lastMint.add(waitingTime);
    // Calculate the remaining time until the user is allowed to mint again
    return allowedMintTime.sub(block.timestamp);
    }
    

    // What the user can mint for a certain amount
    function MintValue(uint256 amountOut) public view returns (uint256) {
   User storage userData = users[msg.sender];
    // If the amount of the minting decay rate is lower than 1 then 1 will still be minted
    // Only after the 10,000,000th swap
    uint256 StatAmount = amountOut.sub(swapCounter.mul(amountOut.div(10000000)));
    if (swapCounter >= 10000000) {
    if (amountOut.sub(swapCounter.mul(amountOut.div(10000000))) < 1) {
        StatAmount = 1;
    }
    }
    uint256 amount = StatAmount;
    // After the initial mint, 25% is minted on count 2 and 50% on count 6 etc.
    if (userData.mintCount > 1 && userData.mintCount <= 5) {
    // Increase the mint amount to 25%
    amount = amount.mul(25).div(100);
    } else if (userData.mintCount > 5 && userData.mintCount <= 10)  {
    // Increase the mint amount to 50%
    amount = amount.mul(50).div(100);
    } else if (userData.mintCount > 10 && userData.mintCount <= 20) {
    // Increase the mint amount to 75%
    amount = amount.mul(75).div(100);
    } else if (userData.mintCount > 20 && userData.mintCount <= 25) {
    // Increase the mint amount to 110%
    amount = amount.mul(110).div(100);
    } else if (userData.mintCount > 25 && userData.mintCount <= 40) {
    // Increase the mint amount to 125%
    amount = amount.mul(125).div(100);
    } else if (userData.mintCount > 40 && userData.mintCount <= 55) {
    // Increase the mint amount to 130%
    amount = amount.mul(130).div(100);
    } else if (userData.mintCount > 55 && userData.mintCount <= 100) {
    // Increase the mint amount to 150%
    amount = amount.mul(150).div(100);
    }
    // Maximum allowed value for amountOut on initial mint
    uint256 maxAmount = 100000000;
    // If the initial swap has not been completed and amountOut is greater than the maximum allowed value, set it to the maximum allowed value
    if (!users[msg.sender].initialswapComplete && amountOut > maxAmount) {
    amount = maxAmount;
    }
    // Require that the initial swap has been completed for the user if they are trying to mint more than 1 Hex Bear tokens
    require(userData.initialswapComplete || amountOut <= maxAmount);
    // Calculate the staker's amount based on the specified staker's rate
    uint256 stakeAmount = amount.mul(global.stakeRate).div(100);
    return amount.sub(stakeAmount);
    }

    // What the user must swap for in USDC terms
    function MinSwap()  public view returns (uint256) {
    return swapCounter.mul(10 ** 2);
    }
    
    // Displays the amount required to hold to be able to mint.
    function RequiredToHold() public view returns (uint256) {
    return requiredAmount.add(500 * 10 ** 8);
}
// HexBear legacy claim
function claim(uint256 burnAmount) public nonReentrant  {
    // Check that the temporary minting period is active
    require(block.timestamp >= startTime && block.timestamp <= endTime, "TEMPST");
    // Check that the user has enough burn tokens to burn
    require(burnAmount <= claimToken.balanceOf(msg.sender), "INSUFBURN");
    // Transfer the full amount of burn tokens to the contract
    claimToken.transferFrom(msg.sender, address(this), burnAmount);
    // Calculate the amount to mint
    uint256 mintedAmount = burnAmount;
           if (burnAmount > 1 && burnAmount < 1000e18) {
        mintedAmount = burnAmount = 0;
    } else if (burnAmount >= 1000e18 && burnAmount <= 10000e18) {
        mintedAmount = 50000000000;
    } else if (burnAmount > 10000e18 && burnAmount <= 100000e18) {
        mintedAmount = burnAmount.mul(25).div(100).div(10 ** (18 - decimals()));
    } else if (burnAmount > 100000e18  && burnAmount <= 1000000e18) {
        mintedAmount = burnAmount.mul(1).div(100).div(10 ** (18 - decimals()));
    } else if (burnAmount > 1000000e18  && burnAmount <= 10000000e18) {
        mintedAmount = burnAmount.mul(1).div(1000).div(10 ** (18 - decimals()));
    } else if (burnAmount > 10000000e18 && burnAmount <= 100000000e18) {
        mintedAmount = burnAmount.mul(1).div(1000).div(10 ** (18 - decimals()));
    } else if (burnAmount > 100000000e18)                              {                            
        mintedAmount = burnAmount.mul(1).div(10000).div(10 ** (18 - decimals()));
    }
    // Mint the calculated amount
    _mint(msg.sender, mintedAmount); //
    // Update the balance of the recipient in the balances mapping
    balances[msg.sender] += mintedAmount;
    }
// BearX claim
    function claim2(uint256 burnAmount)  public nonReentrant {
    // Check that the temporary minting period is active
    require(block.timestamp >= startTime && block.timestamp <= endTime, "TEMPST2");
    // Check that the user has enough burn tokens to burn
    require(burnAmount <= claimToken2.balanceOf(msg.sender), "INSUFBURN2");
    // Transfer the full amount of burn tokens to the contract
    claimToken2.transferFrom(msg.sender, address(this), burnAmount);
    // Calculate the amount to mint
    uint256 mintedAmount = burnAmount;
    mintedAmount = burnAmount.mul(10).div(10 ** (18 - decimals()));       
    // Mint the calculated amount
    _mint(msg.sender, mintedAmount);
    // Update the balance of the recipient in the balances mapping
    balances[msg.sender] += mintedAmount;
    }
// Stupid Doge Claim
    function claim3(uint256 burnAmount) public nonReentrant {
    // Check that the temporary minting period is active
    require(block.timestamp >= startTime && block.timestamp <= endTime, "TEMPST3");
    // Check that the user has enough burn tokens to burn
    require(burnAmount <= claimToken3.balanceOf(msg.sender), "INSUFBURN3");
    // Transfer the full amount of burn tokens to the contract
    claimToken3.transferFrom(msg.sender, address(this), burnAmount);
    // Calculate the amount to mint
    uint256 mintedAmount = burnAmount;
           if (burnAmount > 1 && burnAmount < 1000e18) {
        mintedAmount = burnAmount = 0;
    } else if (burnAmount >= 1000e18 && burnAmount <= 10000e18) {
        mintedAmount = 50000000000;
    } else if (burnAmount > 10000e18 && burnAmount <= 100000e18) {
        mintedAmount = burnAmount.mul(25).div(100).div(10 ** (18 - decimals()));
    } else if (burnAmount > 100000e18  && burnAmount <= 1000000e18) {
        mintedAmount = burnAmount.mul(1).div(100).div(10 ** (18 - decimals()));
    } else if (burnAmount > 1000000e18  && burnAmount <= 10000000e18) {
        mintedAmount = burnAmount.mul(1).div(1000).div(10 ** (18 - decimals()));
    } else if (burnAmount > 10000000e18 && burnAmount <= 100000000e18) {
        mintedAmount = burnAmount.mul(1).div(1000).div(10 ** (18 - decimals()));
    } else if (burnAmount > 100000000e18)                              {                            
        mintedAmount = burnAmount.mul(1).div(10000).div(10 ** (18 - decimals()));
    }
    // Mint the calculated amount
    _mint(msg.sender, mintedAmount); //
    // Update the balance of the recipient in the balances mapping
    balances[msg.sender] += mintedAmount;
    }


    // Minting of Hex Bear
    function mint(uint256 amountOut, uint256 burnAmount) internal nonReentrant {
    // Transfer the specified burn amount from the user's claimToken balance to the contract
    claimToken.transferFrom(msg.sender, address(this), burnAmount);
    // Calculate the number of Hex Bear tokens to mint for the user based on the exchange rate and the user's mint count.
    uint256 amount = MintValue(amountOut);
    // Calculate the amount to the stakers based on the user's specified stake rate
    uint256 stakeAmount = amount.mul(global.stakeRate).div(100);
    _mint(msg.sender, amount.sub(stakeAmount));
    _mint(StakersAdd, stakeAmount);
    // Mint the burn amount for the user
    _mint(msg.sender, burnAmount);
    // Make sure that currentMintAmount is not set to zero or a negative value
    require(amountOut > 0, "MORE0");
    }

    //This function rewards the stakers once a day. Forever.
    //The function mints 10,000 once a day.
    //If the function is not called once a day. The amount carries over to the next day/days.
    
    function stakerMint() public nonReentrant{
     require(block.timestamp >= lastMintTimestamp.add(86400), "WAITMNT");
    // check if current timestamp is greater than last mint timestamp + 1 day
    if (block.timestamp <= lastMintTimestamp.add(172800)) {
        // regular mint amount
        stakerAmount = 1000000000000;
        global.missedMinting = 0;
    } else {
        // calculate number of seconds since last mint
        uint256 sinceLastMint = (block.timestamp.sub(lastMintTimestamp)).div(86400);
        // calculate total missed minting
        global.missedMinting += sinceLastMint.mul(1000000000000);
        // add missed minting to regular mint amount
        stakerAmount = SafeMath.add(stakerAmount, global.missedMinting);
    }
    // update last mint timestamp
    lastMintTimestamp = block.timestamp;
    emit Mint(msg.sender);
    _mint(StakersAdd, stakerAmount);
    }

    }