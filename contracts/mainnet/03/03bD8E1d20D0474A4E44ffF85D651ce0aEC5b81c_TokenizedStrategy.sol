/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
        return 18;
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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IFactory {
    function protocol_fee_config() external view returns (uint16, address);
}

interface IBaseTokenizedStrategy {
    /*//////////////////////////////////////////////////////////////
                            IMMUTABLE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function asset() external view returns (address);

    function availableDepositLimit(
        address _owner
    ) external view returns (uint256);

    function availableWithdrawLimit(
        address _owner
    ) external view returns (uint256);

    function deployFunds(uint256 _assets) external;

    function freeFunds(uint256 _amount) external;

    function harvestAndReport() external returns (uint256);

    function tendThis(uint256 _totalIdle) external;

    function shutdownWithdraw(uint256 _amount) external;

    function tendTrigger() external view returns (bool);
}

/**
 * @title YearnV3 Tokenized Strategy
 * @author yearn.finance
 * @notice
 *  This TokenizedStrategy can be used by anyone wishing to easily build
 *  and deploy their own custom ERC4626 compliant single strategy Vault.
 *
 *  The TokenizedStrategy contract is meant to be used as a proxy style
 *  implementation contract that will hanle all logic, storage and
 *  mangement for a custom strategy that inherits the `BaseTokenizedStrategy`.
 *  Any function calls to the strategy that are not defined withen that
 *  strategy will be forwarded through a delegateCall to this contract.

 *  A strategist only needs to override a few simple functions that are
 *  focused entirely on the strategy specific needs to easily and cheaply
 *  deploy their own permisionless 4626 compliant vault.
 */
contract TokenizedStrategy {
    using Math for uint256;
    using SafeERC20 for ERC20;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted whent the 'mangement' address is updtaed to 'newManagement'.
     */
    event UpdateManagement(address indexed newManagement);

    /**
     * @notice Emitted whent the 'keeper' address is updtaed to 'newKeeper'.
     */
    event UpdateKeeper(address indexed newKeeper);

    /**
     * @notice Emitted whent the 'performaneFee' is updtaed to 'newPerformanceFee'.
     */
    event UpdatePerformanceFee(uint16 newPerformanceFee);

    /**
     * @notice Emitted whent the 'performanceFeeRecipient' address is
     * updtaed to 'newPerformanceFeeRecipient'.
     */
    event UpdatePerformanceFeeRecipient(
        address indexed newPerformanceFeeRecipient
    );

    /**
     * @notice Emitted whent the 'profitMaxUnlockTime' is updtaed to 'newProfitMaxUnlockTime'.
     */
    event UpdateProfitMaxUnlockTime(uint256 newProfitMaxUnlockTime);

    /**
     * @notice Emitted when a strategy is shutdown.
     */
    event StrategyShutdown();

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Emitted when the `caller` has exchanged `assets` for `shares`,
     * and transferred those `shares` to `owner`.
     */
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Emitted when the `caller` has exchanged `owner`s `shares` for `assets`,
     * and transferred those `assets` to `receiver`.
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Emitted when the strategy reports `profit` or `loss` and
     * `performanceFees` and `protocolFees` are paid out.
     */
    event Reported(
        uint256 profit,
        uint256 loss,
        uint256 protocolFees,
        uint256 performanceFees
    );

    /**
     * @dev Emitted on the initialization of any new `strategy` that uses `asset`
     * with this specific `apiVersion`.
     */
    event NewTokenizedStrategy(
        address indexed strategy,
        address indexed asset,
        string apiVersion
    );

    /*//////////////////////////////////////////////////////////////
                        STORAGE STRUCT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The struct that will hold all the data for each strategy that
     * uses this implementation.
     *
     * This replaces all state variables for a traditional contract. This
     * full struct will be initiliazed on the createion of the strategy
     * and continually updated and read from for the life of the contract.
     *
     * We combine all the variables into one struct to limit the amount of
     * times the custom storage slots need to be loaded during complex functions.
     *
     * Loading the corresponding storage slot for the struct does not
     * load any of the contents of the struct into memory. So the size
     * has no effect on gas usage.
     */
    // prettier-ignore
    struct StrategyData {
        // The ERC20 compliant underlying asset that will be
        // used by the Strategy. We can keep this as an ERC20 
        // instance because the `BaseTokenizedStrategy` holds 
        // the addres of `asset` as an immutable variable to
        // meet the 4626 standard.
        ERC20 asset;
        

        // These are the corresponding ERC20 variables needed for the
        // strategies token that is issued and burned on each deposit or withdraw.
        uint8 decimals; // The amount of decimals that `asset` and strategy use.
        string name; // The name of the token for the strategy.
        uint256 totalSupply; // The total amount of shares currently issued.
        uint256 INITIAL_CHAIN_ID; // The intitial chain id when the strategy was created.
        bytes32 INITIAL_DOMAIN_SEPARATOR; // The domain seperator used for permits on the intitial chain.
        mapping(address => uint256) nonces; // Mapping of nonces used for permit functions.
        mapping(address => uint256) balances; // Mapping to track current balances for each account that holds shares.
        mapping(address => mapping(address => uint256)) allowances; // Mapping to track the allowances for the strategies shares.
        

        // Assets data to track totals the strategy holds.
        // We manually track idle instead of relying on asset.balanceOf(address(this))
        // to prevent PPS manipulation through airdrops.
        uint256 totalIdle; // The total amount of loose `asset` the strategy holds.
        uint256 totalDebt; // The total amount `asset` that is currently deployed by the strategy.
        

        // Variables for profit reporting and locking.
        // We use uint128 for time stamps which is 1,025 years in the future.
        uint256 profitUnlockingRate; // The rate at which locked profit is unlocking.
        uint128 fullProfitUnlockDate; // The timestamp at which all locked shares will unlock.
        uint128 lastReport; // The last time a {report} was called.
        uint32 profitMaxUnlockTime; // The amount of seconds that the reported profit unlocks over.
        uint16 performanceFee; // The percent in basis points of profit that is charged as a fee.
        address performanceFeeRecipient; // The address to pay the `performanceFee` to.

        // Access management variables.
        address management; // Main address that can set all configurable variables.
        address keeper; // Address given permission to call {report} and {tend}.
        bool entered; // Bool to prevent reentrancy.
        bool shutdown; // Bool that can be used to stop deposits into the strategy.
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Require that the call is coming from the strategies mangement.
     */
    modifier onlyManagement() {
        isManagement(msg.sender);
        _;
    }

    /**
     * @dev Require that the call is coming from either the strategies
     * management or the keeper.
     */
    modifier onlyKeepers() {
        isKeeperOrManagement(msg.sender);
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Placed over all state changing functions for increased safety.
     */
    modifier nonReentrant() {
        StrategyData storage S = _strategyStorage();
        // On the first call to nonReentrant, `entered` will be false
        require(!S.entered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        S.entered = true;

        _;

        // Reset to false once call has finished
        S.entered = false;
    }

    /**
     * @dev Will stop new deposits if the strategy has been shutdown.
     * This will not effect withdraws which can never be paused or stopped.
     */
    modifier notShutdown() {
        require(!isShutdown(), "shutdown");
        _;
    }

    /**
     * @notice To check if a sender is the management for a specific strategy.
     * @dev Is left public so that it can be used by the Strategy.
     *
     * When the Strategy calls this the msg.sender would be the
     * address of the strategy so we need to specify the sender.
     */
    function isManagement(address _sender) public view {
        require(_sender == _strategyStorage().management, "!Authorized");
    }

    /**
     * @notice To check if a sender is the keeper or management
     * for a specific strategy.
     * @dev Is left public so that it can be used by the Strategy.
     *
     * When the Strategy calls this the msg.sender would be the
     * address of the strategy so we need to specify the sender.
     */
    function isKeeperOrManagement(address _sender) public view {
        StrategyData storage S = _strategyStorage();
        require(_sender == S.keeper || _sender == S.management, "!Authorized");
    }

    /**
     * @notice To check if the strategy has been shutdown.
     * @dev Is left public so that it can be used by the Strategy.
     *
     * We don't revert here so this can be used for the external getter
     * for the `shutdown` variable as well.
     */
    function isShutdown() public view returns (bool) {
        return _strategyStorage().shutdown;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // Api version this TokenizedStrategy implements.
    string private constant API_VERSION = "3.0.1-beta";

    // Used for fee calculations.
    uint256 private constant MAX_BPS = 10_000;
    // Used for profit unlocking rate calculations.
    uint256 private constant MAX_BPS_EXTENDED = 1_000_000_000_000;

    // Minimum in Basis points the Performance fee can be set to.
    // Used to disenctevize forking strategies just to lower fees.
    uint16 private constant MIN_FEE = 500; // 5%

    // Address of the previously deployed Vault factory that the
    // protocl fee config is retrieved from.
    address private constant FACTORY =
        0x85E2861b3b1a70c90D28DfEc30CE6E07550d83e9;

    /**
     * @dev Custom storgage slot that will be used to store the
     * `StrategyData` struct that holds each strategies
     * specific storage variables.
     *
     * Any storage updates done by the TokenizedStrategy actually update
     * the storage of the calling contract. This variable points
     * to the specic location that will be used to store the
     * struct that holds all that data.
     *
     * We use a custom string in order to get a random
     * storage slot that will allow for stratgists to use any
     * amount of storage in their strategy without worrying
     * about collisions.
     */
    bytes32 private constant BASE_STRATEGY_STORAGE =
        bytes32(uint256(keccak256("yearn.base.strategy.storage")) - 1);

    /*//////////////////////////////////////////////////////////////
                    STORAGE GETTER FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev will return the actaul storage slot where the strategy
     * sepcific `StrategyData` struct is stored for both read
     * and write operations.
     *
     * This loads just the slot location, not the full struct
     * so it can be used in a gas effecient manner.
     */
    function _strategyStorage() private pure returns (StrategyData storage S) {
        // Since STORAGE_SLOT is a constant, we have to put a variable
        // on the stack to access it from an inline assembly block.
        bytes32 slot = BASE_STRATEGY_STORAGE;
        assembly {
            S.slot := slot
        }
    }

    /*//////////////////////////////////////////////////////////////
                INITILIZATION OF DEFAULT STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Used to initialize storage for a newly deployed strategy.
     * @dev This should be called atomically whenever a new strategy is
     * deployed and can only be called once for each strategy.
     *
     * This will set all the default storage that must be set for a
     * strategy to function. Any changes can be made post deployment
     * through external calls from `management`.
     *
     * The function will also emit an event that off chain indexers can
     * look for to track any new deployments using this TokenizedStrategy.
     *
     * This is called through a lowelevel call in the BaseTokenizedStrategy
     * so any reverts will return the "init failed" string.
     *
     * @param _asset Address of the underlying asset.
     * @param _name Name the strategy will use.
     * @param _management Address to set as the strategies `management`.
     * @param _performanceFeeRecipient Address to receive performance fees.
     * @param _keeper Address to set as strategies `keeper`.
     */
    function init(
        address _asset,
        string memory _name,
        address _management,
        address _performanceFeeRecipient,
        address _keeper
    ) external {
        // Cache storage pointer
        StrategyData storage S = _strategyStorage();

        // Make sure we aren't initiliazed.
        require(address(S.asset) == address(0));

        // Set the strategys underlying asset
        S.asset = ERC20(_asset);
        // Set the Strategy Tokens name.
        S.name = _name;
        // Set decimals based off the `asset`.
        S.decimals = ERC20(_asset).decimals();
        // Set initial chain id for permit replay protection
        S.INITIAL_CHAIN_ID = block.chainid;
        // Set the inital domain seperator for permit functions
        S.INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

        // Default to a 10 day profit unlock period
        S.profitMaxUnlockTime = 10 days;
        // Set address to receive performance fees.
        // Can't be address(0) or we will be burning fees.
        require(_performanceFeeRecipient != address(0));
        // Can't mint shares to its self because of profit locking.
        require(_performanceFeeRecipient != address(this));
        S.performanceFeeRecipient = _performanceFeeRecipient;
        // Default to a 10% performance fee.
        S.performanceFee = 1_000;
        // Set last report to this block.
        S.lastReport = uint128(block.timestamp);

        // Set the default management address. Can't be 0.
        require(_management != address(0));
        S.management = _management;
        // Set the keeper address
        S.keeper = _keeper;

        // Emit event to signal a new strategy has been initialized.
        emit NewTokenizedStrategy(address(this), _asset, API_VERSION);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints `shares` of strategy shares to `receiver` by
     * depositing exactly `assets` of underlying tokens.
     * @param assets The amount of underlying to deposit in.
     * @param receiver The address to receive the `shares`.
     * @return shares The actual amount of shares issued.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) external notShutdown nonReentrant returns (uint256 shares) {
        // Check for rounding error.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        _deposit(receiver, assets, shares);
    }

    /**
     * @notice Mints exactly `shares` of strategy shares to
     * `receiver` by depositing `assets` of underlying tokens.
     * @param shares The amount of strategy shares mint.
     * @param receiver The address to receive the `shares`.
     * @return assets The actual amount of asset deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) external notShutdown nonReentrant returns (uint256 assets) {
        // Check for rounding error.
        require((assets = previewMint(shares)) != 0, "ZERO_ASSETS");

        _deposit(receiver, assets, shares);
    }

    /**
     * @notice Redeems `shares` from `owner` and sends `assets`
     * of underlying tokens to `receiver`.
     * @param assets The amount of underlying to withdraw.
     * @param receiver The address to receive `assets`.
     * @param owner The address whose shares are burnt.
     * @return shares The actual amount of shares burnt.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 shares) {
        // Check for rounding error.
        require((shares = previewWithdraw(assets)) != 0, "ZERO_SHARES");

        _withdraw(receiver, owner, assets, shares);
    }

    /**
     * @notice Redeems exactly `shares` from `owner` and
     * sends `assets` of underlying tokens to `receiver`.
     * @param shares The amount of shares burnt.
     * @param receiver The address to receive `assets`.
     * @param owner The address whose shares are burnt.
     * @return assets The actual amount of underlying withdrawn.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256) {
        uint256 assets;
        // Check for rounding error.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        // We need to return the actual amount withdrawn in case of a loss.
        return _withdraw(receiver, owner, assets, shares);
    }

    /**
     * @notice The amount of shares that the strategy would
     *  exchange for the amount of assets provided, in an
     * ideal scenario where all the conditions are met.
     *
     * @param assets The amount of underlying.
     * @return . Expected shares that `assets` repersents.
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        // Saves an extra SLOAD if totalAssets() is non-zero.
        uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();

        // If assets are 0 but supply is not PPS = 0.
        if (_totalAssets == 0) return _totalSupply == 0 ? assets : 0;

        return assets.mulDiv(_totalSupply, _totalAssets, Math.Rounding.Down);
    }

    /**
     * @notice The amount of assets that the strategy would
     * exchange for the amount of shares provided, in an
     * ideal scenario where all the conditions are met.
     *
     * @param shares The amount of the strategies shares.
     * @return . Expected amount of `asset` the shares repersent.
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply() is non-zero.
        uint256 supply = totalSupply();

        return
            supply == 0
                ? shares
                : shares.mulDiv(totalAssets(), supply, Math.Rounding.Down);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their deposit at the current block, given
     * current on-chain conditions.
     * @dev This will round down.
     */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their mint at the current block, given
     * current on-chain conditions.
     * @dev This is used instead of convertToAssets so that it can
     * round up for safer mints.
     */
    function previewMint(uint256 shares) public view returns (uint256) {
        // Saves an extra SLOAD if totalSupply() is non-zero.
        uint256 supply = totalSupply();

        return
            supply == 0
                ? shares
                : shares.mulDiv(totalAssets(), supply, Math.Rounding.Up);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     * @dev This is used instead of convertToShares so that it can
     * round up for safer withdraws.
     */
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        // Saves an extra SLOAD if totalAssets() is non-zero.
        uint256 _totalAssets = totalAssets();
        uint256 _totalSupply = totalSupply();

        // If assets are 0 but supply is not, then PPS = 0.
        if (_totalAssets == 0) return _totalSupply == 0 ? assets : 0;

        return assets.mulDiv(_totalSupply, _totalAssets, Math.Rounding.Up);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate
     * the effects of their redeemption at the current block,
     * given current on-chain conditions.
     * @dev This will round down.
     */
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    /**
     * @notice Total number of underlying assets that can
     * be deposited by `_owner` into the strategy, where `_owner`
     * corresponds to the msg.sender of a {deposit} call.
     */
    function maxDeposit(address _owner) public view returns (uint256) {
        if (_strategyStorage().shutdown) return 0;

        return
            IBaseTokenizedStrategy(address(this)).availableDepositLimit(_owner);
    }

    /**
     * @notice Total number of shares that can be minted by `_owner`
     * into the strategy, where `_owner` corresponds to the msg.sender
     * of a {mint} call.
     */
    function maxMint(address _owner) public view returns (uint256 _maxMint) {
        if (_strategyStorage().shutdown) return 0;

        _maxMint = IBaseTokenizedStrategy(address(this)).availableDepositLimit(
            _owner
        );
        if (_maxMint != type(uint256).max) {
            _maxMint = convertToShares(_maxMint);
        }
    }

    /**
     * @notice Total number of underlying assets that can be
     * withdrawn from the strategy by `owner`, where `owner`
     * corresponds to the msg.sender of a {redeem} call.
     */
    function maxWithdraw(
        address _owner
    ) public view returns (uint256 _maxWithdraw) {
        _maxWithdraw = IBaseTokenizedStrategy(address(this))
            .availableWithdrawLimit(_owner);
        if (_maxWithdraw == type(uint256).max) {
            // Saves a min check if there is no withdrawal limit.
            _maxWithdraw = convertToAssets(balanceOf(_owner));
        } else {
            _maxWithdraw = Math.min(
                convertToAssets(balanceOf(_owner)),
                _maxWithdraw
            );
        }
    }

    /**
     * @notice Total number of strategy shares that can be
     * redeemed from the strategy by `owner`, where `owner`
     * corresponds to the msg.sender of a {redeem} call.
     */
    function maxRedeem(
        address _owner
    ) public view returns (uint256 _maxRedeem) {
        _maxRedeem = IBaseTokenizedStrategy(address(this))
            .availableWithdrawLimit(_owner);
        // Conversion would overflow and saves a min check if there is no withdrawal limit.
        if (_maxRedeem == type(uint256).max) {
            _maxRedeem = balanceOf(_owner);
        } else {
            _maxRedeem = Math.min(
                // Use preview withdraw to round up
                previewWithdraw(_maxRedeem),
                balanceOf(_owner)
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view returns (uint256) {
        StrategyData storage S = _strategyStorage();
        unchecked {
            return S.totalIdle + S.totalDebt;
        }
    }

    function totalSupply() public view returns (uint256) {
        return _strategyStorage().totalSupply - _unlockedShares();
    }

    /**
     * @dev Function to be called during {deposit} and {mint}.
     *
     * This function handles all logic including transfers,
     * minting and accounting.
     *
     * We do all external calls before updating any internal
     * values to prevent view re-entrancy issues from the token
     * transfers or the _deployFunds() calls.
     */
    function _deposit(
        address receiver,
        uint256 assets,
        uint256 shares
    ) private {
        require(receiver != address(this), "ERC4626: mint to self");
        // Saves a redundant "shutdown" check to manually retreive deposit limit.
        require(
            assets <=
                IBaseTokenizedStrategy(address(this)).availableDepositLimit(
                    msg.sender
                ),
            "ERC4626: deposit more than max"
        );

        // Cache storage variables used more than once.
        StrategyData storage S = _strategyStorage();
        ERC20 _asset = S.asset;

        // Need to transfer before minting or ERC777s could reenter.
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        // We will deposit up to current idle plus the new amount added
        uint256 toDeploy = S.totalIdle + assets;

        // Cache for post {deployFunds} checks.
        uint256 beforeBalance = _asset.balanceOf(address(this));

        // Deploy up to all loose funds.
        IBaseTokenizedStrategy(address(this)).deployFunds(toDeploy);

        // Always get the actual amount deployed. We double check the
        // diff agianst toDeploy for complete accuracy.
        uint256 deployed = Math.min(
            beforeBalance - _asset.balanceOf(address(this)),
            toDeploy
        );

        // Adjust total Assets.
        S.totalDebt += deployed;
        unchecked {
            // Cant't underflow due to previous min check.
            S.totalIdle = toDeploy - deployed;
        }

        // mint shares
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @dev To be called during {redeem} and {withdraw}.
     *
     * This will handle all logic, transfers and accounting
     * in order to service the withdraw request.
     *
     * If we are not able to withdraw the full amount needed, it will
     * be counted as a loss and passed on to the user.
     */
    function _withdraw(
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) private returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: withdraw more than max");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        StrategyData storage S = _strategyStorage();
        // Expected beharvior is to need to free funds so we cache `_asset`.
        ERC20 _asset = S.asset;

        uint256 idle = S.totalIdle;

        // Check if we need to withdraw funds.
        if (idle < assets) {
            // Cache before balance for diff checks.
            uint256 before = _asset.balanceOf(address(this));

            // Tell Strategy to free what we need.
            unchecked {
                IBaseTokenizedStrategy(address(this)).freeFunds(assets - idle);
            }

            // Return the actual amount withdrawn. Adjust for potential overwithdraws.
            uint256 withdrawn = Math.min(
                _asset.balanceOf(address(this)) - before,
                S.totalDebt
            );

            unchecked {
                idle += withdrawn;
            }

            uint256 loss;
            // If we didn't get enough out then we have a loss.
            if (idle < assets) {
                unchecked {
                    loss = assets - idle;
                }
                // Lower the amount to be withdrawn.
                assets = idle;
            }

            // Update debt storage.
            S.totalDebt -= (withdrawn + loss);
        }

        // Update idle based on how much we took.
        S.totalIdle = idle - assets;

        _burn(owner, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        // Return the actual amount of assets withdrawn.
        return assets;
    }

    /*//////////////////////////////////////////////////////////////
                        PROFIT LOCKING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Function for keepers to call to harvest and record all
     * profits accrued.
     *
     * @dev This should be called through protected relays if swaps
     * are likely occur.
     *
     * This will account for any gains/losses since the last report
     * and charge fees accordingly.
     *
     * Any profit over the fees charged will be immediatly locked
     * so there is no change in PricePerShare. Then slowly unlocked
     * over the `maxProfitUnlockTime` each second based on the
     * calculated `profitUnlockingRate`.
     *
     * In case of a loss it will first attempt to offset the loss
     * with any remaining locked shares from the last report in
     * order to reduce any negative impact to PPS.
     *
     * Will then recalculate the new time to unlock profits over and the
     * rate based on a weighted average of any remaining time from the
     * last report and the new amount of shares to be locked.
     *
     * @return profit The notional amount of gain if any since the last
     * report in terms of `asset`.
     * @return loss The notional amount of loss if any since the last
     * report in terms of `asset`.
     */
    function report()
        external
        nonReentrant
        onlyKeepers
        returns (uint256 profit, uint256 loss)
    {
        // Cache storage pointer since its used repeatedly.
        StrategyData storage S = _strategyStorage();

        uint256 oldTotalAssets;
        unchecked {
            // Manuaully calculate totalAssets to save a SLOAD.
            oldTotalAssets = S.totalIdle + S.totalDebt;
        }

        // Tell the strategy to report the real total assets it has.
        // It should do all reward selling and redepositing now and
        // account for deployed and loose `asset` so we can accuratly
        // account for all funds including those potentially airdropped
        // by a trade factory. It is safe here to use asset.balanceOf()
        // instead of totalIdle because any profits are immediatly locked.
        uint256 newTotalAssets = IBaseTokenizedStrategy(address(this))
            .harvestAndReport();

        // Burn unlocked shares.
        _burnUnlockedShares();

        uint256 totalFees;
        uint256 protocolFees;
        uint256 sharesToLock;
        // Calculate profit/loss.
        if (newTotalAssets > oldTotalAssets) {
            // We have a profit.
            unchecked {
                profit = newTotalAssets - oldTotalAssets;
                // Asses performance fees.
                totalFees = (profit * S.performanceFee) / MAX_BPS;
            }

            address protocolFeesRecipient;
            uint256 performanceFeeShares;
            uint256 protocolFeeShares;
            // If performance fees are 0 so will protocol fees.
            if (totalFees > 0) {
                // Get the config from the factory.
                uint16 protocolFeeBps;
                (protocolFeeBps, protocolFeesRecipient) = IFactory(FACTORY)
                    .protocol_fee_config();

                // Check if there is a protocol fee to charge.
                if (protocolFeeBps > 0) {
                    // Calculate protocol fees based on the performance Fees.
                    protocolFees = (totalFees * protocolFeeBps) / MAX_BPS;
                }

                // We need to get the shares to issue for the fees at
                // current PPS before any minting or burning.
                unchecked {
                    performanceFeeShares = convertToShares(
                        totalFees - protocolFees
                    );
                }
                if (protocolFees > 0) {
                    protocolFeeShares = convertToShares(protocolFees);
                }
            }

            // we have a net profit
            // lock (profit - fees)
            unchecked {
                sharesToLock = convertToShares(profit - totalFees);
            }
            // Mint the shares to lock the strategy.
            _mint(address(this), sharesToLock);

            // Mint fees shares to recipients.
            if (performanceFeeShares > 0) {
                _mint(S.performanceFeeRecipient, performanceFeeShares);
            }

            if (protocolFeeShares > 0) {
                _mint(protocolFeesRecipient, protocolFeeShares);
            }
        } else {
            // We have a loss.
            unchecked {
                loss = oldTotalAssets - newTotalAssets;
            }

            // Check in case else was due to being equal.
            if (loss > 0) {
                // We will try and burn shares from any pending profit still unlocking
                // to offset the loss to prevent any PPS decline post report.
                uint256 sharesToBurn = Math.min(
                    convertToShares(loss),
                    S.balances[address(this)]
                );

                // Check if there is anything to burn.
                if (sharesToBurn > 0) {
                    _burn(address(this), sharesToBurn);
                }
            }
        }

        // Update unlocking rate and time to fully unlocked.
        uint256 totalLockedShares = S.balances[address(this)];
        if (totalLockedShares > 0) {
            uint256 previouslyLockedTime;
            uint128 _fullProfitUnlockDate = S.fullProfitUnlockDate;
            // Check if we need to account for shares still unlocking.
            if (_fullProfitUnlockDate > block.timestamp) {
                unchecked {
                    // There will only be previously locked shares if time remains.
                    // We calculate this here since it should be rare.
                    previouslyLockedTime =
                        (_fullProfitUnlockDate - block.timestamp) *
                        (totalLockedShares - sharesToLock);
                }
            }

            // newProfitLockingPeriod is a weighted average between the remaining
            // time of the previously locked shares and the profitMaxUnlockTime.
            uint256 newProfitLockingPeriod = (previouslyLockedTime +
                sharesToLock *
                S.profitMaxUnlockTime) / totalLockedShares;

            // Calculate how many shares unlock per second.
            S.profitUnlockingRate =
                (totalLockedShares * MAX_BPS_EXTENDED) /
                newProfitLockingPeriod;

            // Calculate how long until the full amount of shares is unlocked.
            S.fullProfitUnlockDate = uint128(
                block.timestamp + newProfitLockingPeriod
            );
        } else {
            // Only setting this to 0 will turn in the desired effect,
            // no need to update fullProfitUnlockDate.
            S.profitUnlockingRate = 0;
        }

        // Update storage we use the actual loose here since it should have
        // been accounted for in `harvestAndReport` and any airdropped amounts
        // would have been locked to prevent PPS manipulation.
        uint256 newIdle = S.asset.balanceOf(address(this));
        S.totalIdle = newIdle;
        S.totalDebt = newTotalAssets - newIdle;

        S.lastReport = uint128(block.timestamp);

        // Emit event with info
        emit Reported(
            profit,
            loss,
            protocolFees, // Protocol fees
            totalFees - protocolFees // Performance Fees
        );
    }

    function _burnUnlockedShares() private {
        uint256 unlcokdedShares = _unlockedShares();
        if (unlcokdedShares == 0) {
            return;
        }

        // update variables (done here to keep _unlockedShares() as a view function)
        if (_strategyStorage().fullProfitUnlockDate > block.timestamp) {
            _strategyStorage().lastReport = uint128(block.timestamp);
        }

        _burn(address(this), unlcokdedShares);
    }

    function _unlockedShares() private view returns (uint256 unlockedShares) {
        // should save 2 extra calls for most scenarios.
        StrategyData storage S = _strategyStorage();
        uint128 _fullProfitUnlockDate = S.fullProfitUnlockDate;
        if (_fullProfitUnlockDate > block.timestamp) {
            unchecked {
                unlockedShares =
                    (S.profitUnlockingRate * (block.timestamp - S.lastReport)) /
                    MAX_BPS_EXTENDED;
            }
        } else if (_fullProfitUnlockDate != 0) {
            // All shares have been unlocked.
            unlockedShares = S.balances[address(this)];
        }
    }

    /*//////////////////////////////////////////////////////////////
                        TENDING LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice For a 'keeper' to 'tend' the strategy if a custom
     * tendTrigger() is implemented.
     *
     * @dev Both 'tendTrigger' and '_tend' will need to be overridden
     * for this to be used.
     *
     * This will callback the internal '_tend' call in the BaseTokenizedStrategy
     * with the total current amount available to the strategy to deploy.
     *
     * Keepers are expected to use protected relays in tend calls so this
     * can be used for illiquid or manipulatable strategies to compound
     * rewards, perform maintence or deposit/withdraw funds.
     *
     * All accounting for totalDebt and totalIdle updates will be done
     * here post '_tend'.
     *
     * This should never cause an increase in PPS. Total assets should
     * be the same before and after
     *
     * A report() call will be needed to record the profit.
     */
    function tend() external nonReentrant onlyKeepers {
        StrategyData storage S = _strategyStorage();
        // Expected Behavior is this will get used twice so we cache it
        uint256 _totalIdle = S.totalIdle;
        ERC20 _asset = S.asset;

        uint256 beforeBalance = _asset.balanceOf(address(this));
        IBaseTokenizedStrategy(address(this)).tendThis(_totalIdle);
        uint256 afterBalance = _asset.balanceOf(address(this));

        // Adjust storage according to the changes without adjusting totalAssets().
        if (beforeBalance > afterBalance) {
            // Idle funds were deposited.
            uint256 deposited = Math.min(
                beforeBalance - afterBalance,
                _totalIdle
            );

            unchecked {
                S.totalIdle -= deposited;
                S.totalDebt += deposited;
            }
        } else if (afterBalance > beforeBalance) {
            // We default to use any funds freed as idle for cheaper withdraw/redeems.
            uint256 harvested = Math.min(
                afterBalance - beforeBalance,
                S.totalDebt
            );

            unchecked {
                S.totalIdle += harvested;
                S.totalDebt -= harvested;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        STRATEGY SHUTDOWN
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Used to shutdown the strategy preventing any further deposits.
     * @dev Can only be called by the current `management`.
     *
     * This will stop any new {deposit} or {mint} calls but will
     * not prevent {withdraw} or {redeem}. It will also still allow for
     * {tend} and {report} so that management can report any last losses
     * in an emergency as well as provide any maintence to allow for full
     * withdraw.
     *
     * This is a one way switch and can never be set back once shutdown.
     */
    function shutdownStrategy() external onlyManagement {
        _strategyStorage().shutdown = true;

        emit StrategyShutdown();
    }

    /**
     * @notice To manually withdraw funds from the yield source after a
     * strategy has been shutdown.
     * @dev This can only be called post {shutdownStrategy}.
     *
     * This will update totalDebt and totalIdle based on the amount of
     * loose `asset` after the withdraw leaving `totalAssets` unchanged.
     *
     * A strategist will need to override the {_emergencyWithdraw} function
     * in their strategy for this to work.
     *
     * @param _amount The amount of asset to attempt to free.
     */
    function emergencyWithdraw(
        uint256 _amount
    ) external nonReentrant onlyManagement {
        StrategyData storage S = _strategyStorage();
        // Make sure the strategy has been shutdown.
        require(S.shutdown, "not shutdown");

        // Cache current assets for post withdraw updates.
        uint256 _totalAssets = totalAssets();

        // Tell the strategy to try and withdraw the `_amount`.
        IBaseTokenizedStrategy(address(this)).shutdownWithdraw(_amount);

        // Record the updated totalAssets based on the new amounts.
        uint256 looseBalance = S.asset.balanceOf(address(this));

        // If we have enough loose to cover all assets.
        if (looseBalance >= _totalAssets) {
            // Set idle to totalAssets.
            S.totalIdle = _totalAssets;
            // Set debt to 0.
            S.totalDebt = 0;
        } else {
            // Otherwise idle is the actual loose balance.
            S.totalIdle = looseBalance;
            unchecked {
                // And debt is the difference.
                S.totalDebt = _totalAssets - looseBalance;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        Getter FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the api version for this TokenizedStrategy.
     * @return . The api version for this TokenizedStrategy
     */
    function apiVersion() external pure returns (string memory) {
        return API_VERSION;
    }

    /**
     * @notice Get the current total idle for a strategy.
     * @return . The current amount of idle funds.
     */
    function totalIdle() external view returns (uint256) {
        return _strategyStorage().totalIdle;
    }

    /**
     * @notice Get the current total debt for a strategy.
     * @return . The current amount of debt.
     */
    function totalDebt() external view returns (uint256) {
        return _strategyStorage().totalDebt;
    }

    /**
     * @notice Get the current address that controls the strategy.
     * @return . Address of management
     */
    function management() external view returns (address) {
        return _strategyStorage().management;
    }

    /**
     * @notice Get the current address that can call tend and report.
     * @return . Address of the keeper
     */
    function keeper() external view returns (address) {
        return _strategyStorage().keeper;
    }

    /**
     * @notice Get the current performance fee charged on profits.
     * denominated in Basis Points wehere 10_000 == 100%
     * @return . Current performance fee.
     */
    function performanceFee() external view returns (uint16) {
        return _strategyStorage().performanceFee;
    }

    /**
     * @notice Get the current address that receives the performance fees.
     * @return . Address of performanceFeeRecipient
     */
    function performanceFeeRecipient() external view returns (address) {
        return _strategyStorage().performanceFeeRecipient;
    }

    /**
     * @notice Gets the timestamp at which all profits will be unlocked.
     * @return . The full profit unlocking timestamp
     */
    function fullProfitUnlockDate() external view returns (uint256) {
        return uint256(_strategyStorage().fullProfitUnlockDate);
    }

    /**
     * @notice The per second rate at which profits are unlocking.
     * @dev This is denominated in EXTENDED_BPS decimals.
     * @return . The current profit unlocking rate.
     */
    function profitUnlockingRate() external view returns (uint256) {
        return _strategyStorage().profitUnlockingRate;
    }

    /**
     * @notice Gets the current time profits are set to unlock over.
     * @return . The current profit max unlock time.
     */
    function profitMaxUnlockTime() external view returns (uint256) {
        return _strategyStorage().profitMaxUnlockTime;
    }

    /**
     * @notice The timestamp of the last time protocol fees were charged.
     * @return . The last report.
     */
    function lastReport() external view returns (uint256) {
        return uint256(_strategyStorage().lastReport);
    }

    /**
     * @notice Get the price per share.
     * @dev This value offers limited precision. Integrations that require
     * exact precision should use convertToAssets or convertToShares instead.
     *
     * @return . The price per share.
     */
    function pricePerShare() external view returns (uint256) {
        return convertToAssets(10 ** _strategyStorage().decimals);
    }

    /*//////////////////////////////////////////////////////////////
                        SETTER FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets a new address to be in charge of the stategy.
     * @dev Can only be called by the current `management`.
     *
     * Cannot set `management` to address(0).
     *
     * @param _management New address to set `management` to.
     */
    function setManagement(address _management) external onlyManagement {
        require(_management != address(0), "ZERO ADDRESS");
        _strategyStorage().management = _management;

        emit UpdateManagement(_management);
    }

    /**
     * @notice Sets a new address to be in charge of tend and reports.
     * @dev Can only be called by the current `management`.
     *
     * @param _keeper New address to set `keeper` to.
     */
    function setKeeper(address _keeper) external onlyManagement {
        _strategyStorage().keeper = _keeper;

        emit UpdateKeeper(_keeper);
    }

    /**
     * @notice Sets the performance fee to be charged on reported gains.
     * @dev Can only be called by the current `management`.
     *
     * Denominated in Basis Points. So 100% == 10_000.
     * Cannot be set less than the MIN_FEE.
     * Cannot set greater than to 5_000 (50%).
     *
     * @param _performanceFee New performance fee.
     */
    function setPerformanceFee(uint16 _performanceFee) external onlyManagement {
        require(_performanceFee >= MIN_FEE, "MIN FEE");
        require(_performanceFee <= 5_000, "MAX FEE");
        _strategyStorage().performanceFee = _performanceFee;

        emit UpdatePerformanceFee(_performanceFee);
    }

    /**
     * @notice Sets a new address to recieve performance fees.
     * @dev Can only be called by the current `management`.
     *
     * Cannot set to address(0).
     *
     * @param _performanceFeeRecipient New address to set `management` to.
     */
    function setPerformanceFeeRecipient(
        address _performanceFeeRecipient
    ) external onlyManagement {
        require(_performanceFeeRecipient != address(0), "ZERO ADDRESS");
        require(_performanceFeeRecipient != address(this), "Can't be self");
        _strategyStorage().performanceFeeRecipient = _performanceFeeRecipient;

        emit UpdatePerformanceFeeRecipient(_performanceFeeRecipient);
    }

    /**
     * @notice Sets the time for profits to be unlocked over.
     * @dev Can only be called by the current `management`.
     *
     * Denominated in seconds and cannot be greater than 1 year.
     *
     * `profitMaxUnlockTime` is stored as a uint32 for packing but can
     * be passed in as uint256 for simplicity.
     *
     * @param _profitMaxUnlockTime New `profitMaxUnlockTime`.
     */
    function setProfitMaxUnlockTime(
        uint256 _profitMaxUnlockTime
    ) external onlyManagement {
        require(_profitMaxUnlockTime > 0, "to short");
        require(_profitMaxUnlockTime <= 31_556_952, "to long");
        _strategyStorage().profitMaxUnlockTime = uint32(_profitMaxUnlockTime);

        emit UpdateProfitMaxUnlockTime(_profitMaxUnlockTime);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC20 FUNCIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the name of the token.
     * @return . The name the strategy is using for its token.
     */
    function name() public view returns (string memory) {
        return _strategyStorage().name;
    }

    /**
     * @notice Returns the symbol of the strategies token.
     * @dev Will be 'ys + asset symbol'.
     * @return . The symbol the strategy is using for its tokens.
     */
    function symbol() public view returns (string memory) {
        return
            string(abi.encodePacked("ys", _strategyStorage().asset.symbol()));
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * @return . The decimals used for the strategy and `asset`.
     */
    function decimals() public view returns (uint8) {
        return _strategyStorage().decimals;
    }

    /**
     * @notice Returns the current balance for a given '_account'.
     * @dev If the '_account` is the strategy then this will subtract
     * the amount of shares that have been unlocked since the last profit first.
     * @param account the address to return the balance for.
     * @return . The current balance in y shares of the '_account'.
     */
    function balanceOf(address account) public view returns (uint256) {
        if (account == address(this)) {
            return _strategyStorage().balances[account] - _unlockedShares();
        }
        return _strategyStorage().balances[account];
    }

    /**
     * @notice Transfer '_amount` of shares from `msg.sender` to `to`.
     * @dev
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `to` cannot be the address of the strategy.
     * - the caller must have a balance of at least `_amount`.
     *
     * @param to The address shares will be transferred to.
     * @param amount The amount of shares to be transferred from sender.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     * @param owner The address who owns the shares.
     * @param spender The address who would be moving the owners shares.
     * @return . The remaining amount of shares of `owner` that could be moved by `spender`.
     */
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _strategyStorage().allowances[owner][spender];
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @dev
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     *
     * @param spender the address to allow the shares to be moved by.
     * @param amount the amount of shares to allow `spender` to move.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * @dev
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `to` cannot be the address of the strategy.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     *
     * Emits a {Transfer} event.
     *
     * @param from the address to be moving shares from.
     * @param to the address to be moving shares to.
     * @param amount the quantity of shares to move.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - cannot give spender over uint256.max allowance
     *
     * @param spender the account that will be able to move the senders shares.
     * @param addedValue the extra amount to add to the current allowance.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     *
     * @param spender the account that will be able to move less of the senders shares.
     * @param subtractedValue the amount to decrease the current allowance by.
     * @return . a boolean value indicating whether the operation succeeded.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) - subtractedValue);
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
     * - `to` cannot be the strategies address
     * - `from` must have a balance of at least `amount`.
     *
     */
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != address(this), "ERC20 transfer to strategy");
        StrategyData storage S = _strategyStorage();

        S.balances[from] -= amount;
        unchecked {
            S.balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     *
     */
    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");
        StrategyData storage S = _strategyStorage();

        S.totalSupply += amount;
        unchecked {
            S.balances[account] += amount;
        }
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
    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");
        StrategyData storage S = _strategyStorage();

        S.balances[account] -= amount;
        unchecked {
            S.totalSupply -= amount;
        }
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
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _strategyStorage().allowances[owner][spender] = amount;
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
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * @dev Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * @param _owner the address of the account to return the nonce for.
     * @return . the current nonce for the account.
     */
    function nonces(address _owner) external view returns (uint256) {
        return _strategyStorage().nonces[_owner];
    }

    /**
     * @notice Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * @dev IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "ERC20: PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                _strategyStorage().nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "ERC20: INVALID_SIGNER"
            );

            _approve(recoveredAddress, spender, value);
        }
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature
     * for {permit}, as defined by {EIP712}.
     *
     * @dev This checks that the current chain id is the same as when the contract was deployed to
     * prevent replay attacks. If false it will calculate a new domain seperator based on the new chain id.
     *
     * @return . The domain seperator that will be used for any {permit} calls.
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        StrategyData storage S = _strategyStorage();
        return
            block.chainid == S.INITIAL_CHAIN_ID
                ? S.INITIAL_DOMAIN_SEPARATOR
                : _computeDomainSeparator();
    }

    /**
     * @dev Calculates and returns the domain seperator to be used in any
     * permit functions for the strategies {permit} calls.
     *
     * This will be used at the initilization of each new strategies storage.
     * It would then be used in the future in the case of any forks in which
     * the current chain id is not the same as the origin al.
     *
     */
    function _computeDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(_strategyStorage().name)),
                    keccak256(bytes(API_VERSION)),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev On contract creation we set `asset` for this contract to address(1).
     * This prevents it from ever being intialized in the future.
     */
    constructor() {
        _strategyStorage().asset = ERC20(address(1));
    }
}