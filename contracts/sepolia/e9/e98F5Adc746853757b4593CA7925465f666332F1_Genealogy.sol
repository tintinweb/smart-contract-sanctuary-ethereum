/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// File: contracts/Genealogy.sol


pragma solidity ^0.8;






contract Genealogy is Ownable, ReentrancyGuard {
    using strings for *;
    struct Partner {
        uint256 position_id;
        uint256 upline_position_id;
        address wallet_address;
        string ebr_code;
        string direction; // left or right of the upline
        uint256 balance;
        uint256 sum_left_balance;
        uint256 sum_right_balance;
        uint256 childs_count;
        uint256 full_fill_level;
        uint256 created_at;
        uint256 last_update;
        bool isValue;
    }

    function log_2(uint256 number) internal pure returns (uint8) {
        require(number > 0, "0");
        for (uint8 n = 0; n < 256; n++) {
            if (number >= 2 ** n && number < 2 ** (n + 1)) {
                return n;
            }
        }
    }

    function stringToUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }

    function createReffralString(
        string memory _invitation_ebr_code,
        string memory _refferal_ebr_code,
        uint256 _position_id
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _invitation_ebr_code,
                    "-",
                    _refferal_ebr_code,
                    "-",
                    Strings.toString(_position_id),
                    "-"
                )
            );
    }

    struct TransactionsLog {
        address from;
        uint256 amount;
        string transaction_type;
        uint256 timestamp;
    }

    mapping(uint256 => Partner) public partnersByPositionId;
    mapping(address => Partner) partnersByWalletAddress;
    mapping(string => Partner) partnersByEbrCode;
    mapping(address => TransactionsLog[]) transactionLogsByAddress;
    mapping(address => string[]) invitationLinksByreferallWalletAdress;
    mapping(address => string[]) invitationEbrPartnersByreferallWalletAddress;
    uint256[] Childs;
    uint256[] assume_full_fill_level_partners;
    uint256[] each_level_childs_number;
    string[] refferalCodes;
    uint256 position_id_from_ebr_code;
    uint256 partnerCount;
    uint256[] public position_ids;
    uint256 upline_position_id;
    address _owner;
    uint256 new_position_id;
    address public StakingContractAddress;
    address public DappTokenContractAddress;
    address[] walletAddresses;

    constructor(
        address stakeContractAddress,
        address dappTokenContractAddress
    ) payable {
        _owner = msg.sender;
        StakingContractAddress = stakeContractAddress;
        DappTokenContractAddress = dappTokenContractAddress;
        Partner memory partner = Partner(
            0,
            0,
            msg.sender,
            "admin",
            "none",
            0,
            0,
            0,
            0,
            0,
            block.timestamp,
            block.timestamp,
            true
        );
        partnersByEbrCode["admin"] = partner;
        position_ids.push(0);
        partnersByPositionId[0] = partner;
        partnersByWalletAddress[msg.sender] = partner;
        walletAddresses.push(msg.sender);
        partnerCount = 1;
    }

    function isValidEbrCode(
        string memory _ebr_code
    ) internal view returns (bool) {
        if (partnersByEbrCode[_ebr_code].isValue) {
            return true;
        } else {
            return false;
        }
    }

    function isValidPositionId(
        uint256 _position_id
    ) internal view returns (bool) {
        if (partnersByPositionId[_position_id].isValue) {
            return true;
        } else {
            return false;
        }
    }

    function isValidDirection(
        string memory _direction
    ) internal pure returns (bool) {
        if (
            keccak256(abi.encodePacked(_direction)) ==
            keccak256(abi.encodePacked("l")) ||
            keccak256(abi.encodePacked(_direction)) ==
            keccak256(abi.encodePacked("r"))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function getDirectionByPositionId(
        uint256 _position_id
    ) internal view returns (string memory) {
        if (_position_id % 2 == 0) {
            return "r";
        } else {
            return "l";
        }
    }

    function IsValidEbrCode(
        string memory _ebr_code
    ) internal view returns (bool) {
        if (partnersByEbrCode[_ebr_code].isValue) {
            return true;
        } else {
            return false;
        }
    }

    function addRefferalCode(string memory _refferalCode) internal {
        refferalCodes.push(_refferalCode);
    }

    function addInvitaionLinksByWalletAddress(
        string memory _refferalLink
    ) internal {
        invitationLinksByreferallWalletAdress[msg.sender].push(_refferalLink);
    }

    function addInvitationEbrCodesByWalletAddress(
        string memory _invitation_code
    ) internal {
        invitationEbrPartnersByreferallWalletAddress[msg.sender].push(
            _invitation_code
        );
    }

    function isValidWalletAddress() internal view returns (bool) {
        address sender = msg.sender;
        if (partnersByWalletAddress[sender].isValue == true) {
            return true;
        } else {
            return false;
        }
    }

    function myInvitationLinks() public view returns (string[] memory) {
        return invitationLinksByreferallWalletAdress[msg.sender];
    }

    function isValidInvitationLink(
        string memory _invitation_link
    ) internal view returns (bool) {
        for (uint256 i = 0; i < refferalCodes.length; i++) {
            if (
                keccak256(abi.encodePacked(refferalCodes[i])) ==
                keccak256(abi.encodePacked(_invitation_link))
            ) {
                return true;
            }
        }
        return false;
    }

    function createRefferalCode(
        string memory _invitation_ebr_code,
        uint256 _position_id
    ) public returns (string memory) {
        require(IsValidEbrCode(_invitation_ebr_code) == false, "1");
        uint256 _upline = calcUplineFromPositionId(_position_id);
        require(isValidPositionId(_upline), "2");
        require(isValidPositionId(_position_id) == false, "3");
        Partner memory refferal_partner = partnersByWalletAddress[msg.sender];
        string memory refferalCode = createReffralString(
            _invitation_ebr_code,
            refferal_partner.ebr_code,
            _position_id
        );
        addInvitaionLinksByWalletAddress(refferalCode);
        addInvitationEbrCodesByWalletAddress(_invitation_ebr_code);
        refferalCodes.push(refferalCode);
        return refferalCode;
    }

    function addPartnerFromLink(
        string memory _invitation_link // returns (string memory result)
    ) public {
        require(userIsStaker(), "4");
        string memory direction;
        string memory invitation_link = _invitation_link;
        require(isValidWalletAddress() == false, "5");
        require(isValidInvitationLink(invitation_link), "1");
        strings.slice memory s = invitation_link.toSlice();
        strings.slice memory delim = "-".toSlice();
        string[] memory parts = new string[](s.count(delim));
        for (uint256 i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }

        string memory invited_ebr_code = parts[0];
        uint256 position_id = stringToUint(parts[2]);
        require(isValidPositionId(position_id) == false, "1");
        uint256 upline_position_id = calcUplineFromPositionId(position_id);
        string memory upline_ebr_code = partnersByPositionId[upline_position_id]
            .ebr_code;
        if (position_id % 2 == 0) {
            string memory direction = "r";
        } else {
            string memory direction = "l";
        }
        uint256 balance = MyStakingBalance();
        Partner memory partner = Partner(
            position_id,
            upline_position_id,
            msg.sender,
            invited_ebr_code,
            direction,
            balance,
            0,
            0,
            0,
            0,
            block.timestamp,
            block.timestamp,
            true
        );
        // referral bonus
        uint256 _amount = (balance * 1) / 10;
        string memory _ebr_code = parts[1];
        Partner memory _referrer_partner = partnersByEbrCode[_ebr_code];
        address _referrer_partner_address = _referrer_partner.wallet_address;
        transferFromDappContract(_referrer_partner_address, _amount);
        referralBonusLogs(msg.sender, _referrer_partner_address, _amount);
        partnersByEbrCode[invited_ebr_code] = partner;
        position_ids.push(position_id);
        partnersByPositionId[position_id] = partner;
        partnersByWalletAddress[msg.sender] = partner;
        updateUplinesChildsCount(position_id);
        updateUplinesFullFillLevel(position_id);
        partnerCount++;
        // return "successfully add partner";
    }

    function generatePositionId(
        uint256 _upline_postion_id,
        string memory _direction
    ) internal view returns (uint256) {
        require(isValidDirection(_direction) == true, "6");
        require(isValidPositionId(_upline_postion_id) == true, "2");
        if (
            keccak256(abi.encodePacked(_direction)) ==
            keccak256(abi.encodePacked("r"))
        ) {
            return _upline_postion_id * 2 + 2;
        } else {
            return _upline_postion_id * 2 + 1;
        }
    }

    function getPositionIdFromEbrCode(
        string memory _ebr_code
    ) internal onlyOwner returns (string memory) {
        if (isValidEbrCode(_ebr_code) == true) {
            Partner storage partner = partnersByEbrCode[_ebr_code];
            position_id_from_ebr_code = partner.position_id;
            return Strings.toString(position_id_from_ebr_code);
        } else {
            return "none";
        }
    }

    function getPositionIdList() internal view returns (uint256[] memory) {
        return position_ids;
    }

    function countPositionIds() internal view returns (uint256) {
        return position_ids.length;
    }

    function getPartner(
        uint256 _position_id
    ) internal view onlyOwner returns (Partner memory) {
        require(isValidPositionId(_position_id), "3");
        return partnersByPositionId[_position_id];
    }

    // function calcNextChilds(uint256 _position_id)
    //     public
    //     pure
    //     returns (uint256, uint256)
    // {
    //     uint256 left_child_position = _position_id * 2 + 1;
    //     uint256 right_child_position = _position_id * 2 + 2;
    //     return (left_child_position, right_child_position);
    // }

    function calcUplineFromPositionId(
        uint256 _position_id
    ) internal pure returns (uint256) {
        if (_position_id == 1 || _position_id == 0) {
            return 0;
        }
        if (_position_id % 2 == 0) {
            return (_position_id - 2) / 2;
        } else {
            return (_position_id - 1) / 2;
        }
    }

    function getBalanceByPositionId(
        uint256 _position_id
    ) internal view onlyOwner returns (uint256) {
        Partner memory partner = partnersByPositionId[_position_id];
        require(isValidPositionId(_position_id), "3");
        return partner.balance;
    }

    function userIsStaker() internal returns (bool result) {
        bytes memory payload = abi.encodeWithSignature(
            "isStakerByAddress(address)",
            msg.sender
        );
        (bool success, bytes memory returnData) = StakingContractAddress.call(
            payload
        );
        bool result = abi.decode(returnData, (bool));
        return result;
    }

    function stakingBalance(
        address _staker_addr
    ) internal onlyOwner returns (uint256) {
        bytes memory payload = abi.encodeWithSignature(
            "BalanceOf(address)",
            _staker_addr
        );
        (bool success, bytes memory returnData) = StakingContractAddress.call(
            payload
        );
        uint256 balance = abi.decode(returnData, (uint256));
        return balance;
    }

    function MyStakingBalance() internal returns (uint256) {
        bytes memory payload = abi.encodeWithSignature(
            "BalanceOf(address)",
            msg.sender
        );
        (bool success, bytes memory returnData) = StakingContractAddress.call(
            payload
        );
        uint256 balance = abi.decode(returnData, (uint256));
        return balance;
    }

    function updateBalance(
        address _wallet_address
    ) internal onlyOwner returns (uint256) {
        Partner memory partner = partnersByWalletAddress[_wallet_address];
        uint256 new_balance = stakingBalance(_wallet_address);
        partner.balance = new_balance;
        return new_balance;
    }

    function updateBalances() public onlyOwner {
        for (uint256 i = 0; i < walletAddresses.length; i++) {
            updateBalance(walletAddresses[i]);
        }
    }

    function updatePartner(Partner memory partner) internal {
        address wallet_address = partner.wallet_address;
        uint256 position_id = partner.position_id;
        string memory ebr_code = partner.ebr_code;
        partner.last_update = block.timestamp;
        partnersByPositionId[position_id] = partner;
        partnersByWalletAddress[wallet_address] = partner;
        partnersByEbrCode[ebr_code] = partner;
    }

    function updateUplinesBalances(
        uint256 _position_id,
        uint256 amount
    ) public onlyOwner {
        require(isValidPositionId(_position_id), "3");
        bool not_done = true;
        uint256 upline_position_id = calcUplineFromPositionId(_position_id);
        if (_position_id == 1 || _position_id == 2) {
            Partner memory partner = partnersByPositionId[0];
            if (_position_id == 1) {
                uint256 old_balance = partner.sum_left_balance;
                uint256 new_balance = old_balance + amount;
                partner.sum_left_balance = new_balance;
                updatePartner(partner);
            } else {
                uint256 old_balance = partner.sum_right_balance;
                uint256 new_balance = old_balance + amount;
                partner.sum_right_balance = new_balance;
                updatePartner(partner);
            }
        } else {
            while (not_done) {
                Partner memory partner = partnersByPositionId[
                    upline_position_id
                ];
                if (
                    keccak256(
                        abi.encodePacked(getDirectionByPositionId(_position_id))
                    ) == keccak256(abi.encodePacked("r"))
                ) {
                    uint256 old_balance = partner.sum_right_balance;
                    uint256 new_balance = old_balance + amount;
                    partner.sum_right_balance = new_balance;
                    updatePartner(partner);
                } else {
                    uint256 old_balance = partner.sum_left_balance;
                    uint256 new_balance = old_balance + amount;
                    partner.sum_left_balance = new_balance;
                    updatePartner(partner);
                }
                uint256 previous_position_id = upline_position_id;
                uint256 upline_position_id = calcUplineFromPositionId(
                    upline_position_id
                );
                uint256 _position_id = upline_position_id;
                if (_position_id == 0 && upline_position_id == 0) {
                    Partner memory partner = partnersByPositionId[0];
                    if (previous_position_id == 1) {
                        uint256 old_balance = partner.sum_left_balance;
                        uint256 new_balance = old_balance + amount;
                        partner.sum_left_balance = new_balance;
                        updatePartner(partner);
                    } else {
                        uint256 old_balance = partner.sum_right_balance;
                        uint256 new_balance = old_balance + amount;
                        partner.sum_right_balance = new_balance;
                        updatePartner(partner);
                    }
                    not_done = false;
                }
            }
        }
    }

    function updateUplinesChildsCount(uint256 _position_id) internal {
        require(isValidPositionId(_position_id), "3");
        bool not_done = true;
        uint256 upline_position_id = calcUplineFromPositionId(_position_id);
        if (_position_id == 1 || _position_id == 2) {
            Partner memory partner = partnersByPositionId[0];
            uint256 old_child_count = partner.childs_count;
            uint256 new_child_count = old_child_count + 1;
            partner.childs_count = new_child_count;
            updatePartner(partner);
        } else {
            while (not_done) {
                Partner memory partner = partnersByPositionId[
                    upline_position_id
                ];
                uint256 old_child_count = partner.childs_count;
                uint256 new_child_count = old_child_count + 1;
                partner.childs_count = new_child_count;
                updatePartner(partner);
                uint256 upline_position_id = calcUplineFromPositionId(
                    upline_position_id
                );
                uint256 _position_id = upline_position_id;
                if (_position_id == 0 && upline_position_id == 0) {
                    Partner memory partner = partnersByPositionId[0];
                    uint256 old_child_count = partner.childs_count;
                    uint256 new_child_count = old_child_count + 1;
                    partner.childs_count = new_child_count;
                    updatePartner(partner);
                    not_done = false;
                }
            }
        }
    }

    function calcFirstLeftChild(uint256 _number) internal returns (uint256) {
        uint256 left_child = _number * 2 + 1;
        return left_child;
    }

    function getChildsByLevel(
        uint256 _position_id,
        uint256 _level
    ) public returns (uint256[] memory) {
        delete Childs;
        for (uint256 i = 1; i <= _level; i++) {
            uint256 left_child = calcFirstLeftChild(_position_id);
            uint256 sub_child_numbers = 2 ** i;
            for (uint256 j = 0; j < sub_child_numbers; j++) {
                uint256 sub_child = left_child + j;
                Childs.push(sub_child);
                _position_id = left_child;
            }
        }
        return Childs;
    }

    function getChildsCountByLevel(uint256 _level) internal returns (uint256) {
        delete each_level_childs_number;
        uint256 result;
        for (uint256 i = 1; i <= _level; i++) {
            uint256 _level_childs_number = 2 ** i;
            each_level_childs_number.push(_level_childs_number);
        }
        for (uint256 i = 0; i < each_level_childs_number.length; i++) {
            uint256 previous_result = each_level_childs_number[i];
            result = previous_result + result;
        }
        return result;
    }

    function getFullLevelByChildsCount(
        uint256 _childs_number
    ) internal returns (uint256 result) {
        uint256 result = log_2(_childs_number);
        return result;
    }

    function getChildsInSpecificLevel(
        uint256 _position_id,
        uint256 _level
    ) internal returns (uint256[] memory) {
        delete Childs;
        if (_level == 0) {
            Childs.push(_position_id);
            return Childs;
        }
        for (uint256 i = 1; i <= _level; i++) {
            uint256 left_child = calcFirstLeftChild(_position_id);
            _position_id = left_child;
            if (i == _level) {
                uint256 sub_child_numbers = 2 ** i;
                for (uint256 j = 0; j < sub_child_numbers; j++) {
                    uint256 sub_child = left_child + j;
                    Childs.push(sub_child);
                }
                return Childs;
            }
        }
    }

    function FullFillLevel(uint256 _position_id) internal returns (uint256) {
        delete assume_full_fill_level_partners;
        Partner memory partner = partnersByPositionId[_position_id];
        uint256 childs_count = partner.childs_count;
        if (childs_count == 0) {
            return 0;
        }
        bool not_done = true;
        uint256 assume_full_fill_level = getFullLevelByChildsCount(
            childs_count
        );
        while (not_done) {
            assume_full_fill_level_partners = getChildsInSpecificLevel(
                _position_id,
                assume_full_fill_level
            );
            for (
                uint256 i = 0;
                i < assume_full_fill_level_partners.length;
                i++
            ) {
                Partner memory child_partner = partnersByPositionId[
                    assume_full_fill_level_partners[i]
                ];
                if (child_partner.isValue == false) {
                    assume_full_fill_level = assume_full_fill_level - 1;
                }
            }
            not_done = false;
        }
        uint256 full_fill_level = assume_full_fill_level;
        return full_fill_level;
    }

    function updateUplinesFullFillLevel(uint256 _position_id) internal {
        require(isValidPositionId(_position_id), "3");
        bool not_done = true;
        uint256 upline_position_id = calcUplineFromPositionId(_position_id);
        if (_position_id == 1 || _position_id == 2) {
            Partner memory partner = partnersByPositionId[0];
            uint256 old_level = partner.full_fill_level;
            uint256 new_level = FullFillLevel(0);
            partner.full_fill_level = new_level;
            updatePartner(partner);
        } else {
            while (not_done) {
                Partner memory partner = partnersByPositionId[
                    upline_position_id
                ];
                uint256 old_level = partner.full_fill_level;
                uint256 new_level = FullFillLevel(0);
                partner.full_fill_level = new_level;
                updatePartner(partner);
                uint256 upline_position_id = calcUplineFromPositionId(
                    upline_position_id
                );
                uint256 _position_id = upline_position_id;
                if (_position_id == 0 && upline_position_id == 0) {
                    Partner memory partner = partnersByPositionId[0];
                    uint256 old_level = partner.full_fill_level;
                    uint256 new_level = FullFillLevel(0);
                    partner.full_fill_level = new_level;
                    updatePartner(partner);
                    not_done = false;
                }
            }
        }
    }

    function transferFromDappContract(address _to, uint256 _amount) internal {
        IERC20(DappTokenContractAddress).transfer(_to, _amount);
    }

    function calcPartnerStakingReward(
        address _staker_addr
    ) internal returns (uint256) {
        bytes memory payload = abi.encodeWithSignature(
            "calculateRewardsByAddress(address)",
            _staker_addr
        );
        (bool success, bytes memory returnData) = StakingContractAddress.call(
            payload
        );
        uint256 reward = abi.decode(returnData, (uint256));
        return reward;
    }

    function calcUplinesPositionIdsFromPositionId(
        uint256 _position_id
    ) internal returns (uint256[] memory) {
        delete Childs;
        require(isValidPositionId(_position_id), "3");
        bool not_done = true;
        while (not_done) {
            uint256 _upline_postion_id = calcUplineFromPositionId(_position_id);
            Childs.push(_upline_postion_id);
            _position_id = _upline_postion_id;
            if (_position_id == 0) {
                not_done = false;
            }
        }
        return Childs;
    }

    function updateUplinesUniLevelRewards(
        uint256 _position_id
    ) public payable onlyOwner {
        require(isValidPositionId(_position_id), "3");
        bool not_done = true;
        while (not_done) {
            Partner memory partner = partnersByPositionId[_position_id];
            address partner_wallet_address = partner.wallet_address;
            uint256 _reward = getStakerRewardsUpToNow(partner_wallet_address) /
                100;
            uint256[]
                memory _upline_position_ids = calcUplinesPositionIdsFromPositionId(
                    _position_id
                );
            for (uint256 i = 0; i < _upline_position_ids.length; i++) {
                if (i < 20) {
                    Partner
                        memory one_of_upline_partners = partnersByPositionId[
                            _upline_position_ids[i]
                        ];
                    address one_of_upline_partners_wallet_address = one_of_upline_partners
                            .wallet_address;
                    transferFromDappContract(
                        one_of_upline_partners_wallet_address,
                        _reward
                    );
                    TransactionsLog memory transactionslog = TransactionsLog(
                        partner_wallet_address,
                        _reward,
                        "uni_level_bonus",
                        block.timestamp
                    );
                    transactionLogsByAddress[
                        one_of_upline_partners_wallet_address
                    ].push(transactionslog);
                }
            }
            _position_id = calcUplineFromPositionId(_position_id);
            if (_position_id == 0) {
                not_done = false;
            }
        }
    }

    function getStakerRewardsUpToNow(
        address _staker_addr
    ) internal returns (uint256) {
        bytes memory payload = abi.encodeWithSignature(
            "InitialBalance(address)",
            _staker_addr
        );
        (bool success, bytes memory returnData) = StakingContractAddress.call(
            payload
        );
        uint256 _reward = abi.decode(returnData, (uint256)) / 10;
        return _reward;
    }

    function binaryBonus() public onlyOwner {
        for (uint256 i = 0; i < position_ids.length; i++) {
            Partner memory partner = partnersByPositionId[position_ids[i]];
            address partner_wallet_address = partner.wallet_address;
            uint256 left_balance = partner.sum_left_balance;
            uint256 right_balance = partner.sum_right_balance;
            if (left_balance < right_balance) {
                uint256 binary_reward = left_balance / 10;
                matchingBonus(position_ids[i], binary_reward);
                transferFromDappContract(partner_wallet_address, binary_reward);
                TransactionsLog memory transactionslog = TransactionsLog(
                    partner_wallet_address,
                    binary_reward,
                    "binary_reward",
                    block.timestamp
                );
                transactionLogsByAddress[partner_wallet_address].push(
                    transactionslog
                );
                uint256 left_and_right_balance_difference = right_balance -
                    left_balance;
                partner.sum_left_balance = 0;
                partner.sum_right_balance = left_and_right_balance_difference;
                updatePartner(partner);
            } else {
                uint256 binary_reward = right_balance / 10;
                matchingBonus(position_ids[i], binary_reward);
                transferFromDappContract(partner_wallet_address, binary_reward);
                TransactionsLog memory transactionslog = TransactionsLog(
                    partner_wallet_address,
                    binary_reward,
                    "binary_reward",
                    block.timestamp
                );
                transactionLogsByAddress[partner_wallet_address].push(
                    transactionslog
                );
                uint256 left_and_right_balance_difference = left_balance -
                    right_balance;
                partner.sum_left_balance = left_and_right_balance_difference;
                partner.sum_right_balance = 0;
                updatePartner(partner);
            }
        }
        // return "binary and matching bonuses shared successfully.";
    }

    function matchingBonus(
        uint256 _position_id,
        uint256 _binary_reward
    ) internal onlyOwner {
        uint256 _level_one_reward = (_binary_reward * 5) / 100;
        uint256 _level_two_reward = (_binary_reward * 3) / 100;
        uint256 _level_three_reward = (_binary_reward * 2) / 100;
        if (_binary_reward != 0) {
            if (_position_id > 0) {
                uint256 _first_upline = calcUplineFromPositionId(_position_id);
                Partner memory _first_upline_partner = partnersByPositionId[
                    _first_upline
                ];
                address _first_upline_partner_wallet_address = _first_upline_partner
                        .wallet_address;
                transferFromDappContract(
                    _first_upline_partner_wallet_address,
                    _level_one_reward
                );
                address _behalf_of = partnersByPositionId[_position_id]
                    .wallet_address;
                TransactionsLog memory transactionslog = TransactionsLog(
                    _behalf_of,
                    _level_one_reward,
                    "matching_bonus_being_level_one",
                    block.timestamp
                );
                transactionLogsByAddress[_first_upline_partner_wallet_address]
                    .push(transactionslog);
                if (_position_id > 2) {
                    uint256 _second_upline = calcUplineFromPositionId(
                        _first_upline
                    );
                    Partner
                        memory _second_upline_partner = partnersByPositionId[
                            _second_upline
                        ];
                    address _second_upline_partner_wallet_address = _second_upline_partner
                            .wallet_address;
                    transferFromDappContract(
                        _second_upline_partner_wallet_address,
                        _level_two_reward
                    );
                    TransactionsLog memory transactionslog = TransactionsLog(
                        _behalf_of,
                        _level_two_reward,
                        "mathing_bonus_being_level_two",
                        block.timestamp
                    );
                    transactionLogsByAddress[
                        _second_upline_partner_wallet_address
                    ].push(transactionslog);
                    if (_position_id > 6) {
                        uint256 _third_upline = calcUplineFromPositionId(
                            _second_upline
                        );
                        Partner
                            memory _third_upline_partner = partnersByPositionId[
                                _third_upline
                            ];
                        address _third_upline_partner_wallet_address = _third_upline_partner
                                .wallet_address;
                        transferFromDappContract(
                            _third_upline_partner_wallet_address,
                            _level_three_reward
                        );
                        TransactionsLog
                            memory transactionslog = TransactionsLog(
                                _behalf_of,
                                _level_three_reward,
                                "matching_bonus_being_level_three",
                                block.timestamp
                            );
                        transactionLogsByAddress[
                            _third_upline_partner_wallet_address
                        ].push(transactionslog);
                    }
                }
            }
        }
    }

    function referralBonusLogs(
        address _reffered_address,
        address _referrer_partner_address,
        uint256 _amount
    ) internal returns (string memory) {
        TransactionsLog memory transactionslog = TransactionsLog(
            msg.sender,
            _amount,
            "referral_bonus",
            block.timestamp
        );
        transactionLogsByAddress[_referrer_partner_address].push(
            transactionslog
        );
    }

    function partnerBonusesHistory() public returns (TransactionsLog[] memory) {
        require(isValidWalletAddress(), "5");
        return transactionLogsByAddress[msg.sender];
    }

    function allBonusesHistory(
        address _wallet_address
    ) public onlyOwner returns (TransactionsLog[] memory) {
        require(isValidWalletAddress(), "5");
        return transactionLogsByAddress[_wallet_address];
    }
}