/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/PolyMaximus.sol


pragma solidity ^0.8.4;









/// Contract Interfaces and Abstract contracts
    // this interface comes directly from the Icosa contract. Many of these are not used in Poly Maximus
    interface HedronContract {
        struct LiquidationStore{
            uint256 liquidationStart;
            address hsiAddress;
            uint96  bidAmount;
            address liquidator;
            uint88  endOffset;
            bool    isActive;
        }
        struct HEXStakeMinimal {
        uint40 stakeId;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        }
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
        event Claim(uint256 data, address indexed claimant, uint40 indexed stakeId);
        event LoanEnd(
            uint256 data,
            address indexed borrower,
            uint40 indexed stakeId
        );
        event LoanLiquidateBid(
            uint256 data,
            address indexed bidder,
            uint40 indexed stakeId,
            uint40 indexed liquidationId
        );
        event LoanLiquidateExit(
            uint256 data,
            address indexed liquidator,
            uint40 indexed stakeId,
            uint40 indexed liquidationId
        );
        event LoanLiquidateStart(
            uint256 data,
            address indexed borrower,
            uint40 indexed stakeId,
            uint40 indexed liquidationId
        );
        event LoanPayment(
            uint256 data,
            address indexed borrower,
            uint40 indexed stakeId
        );
        event LoanStart(
            uint256 data,
            address indexed borrower,
            uint40 indexed stakeId
        );
        event Mint(uint256 data, address indexed minter, uint40 indexed stakeId);
        event Transfer(address indexed from, address indexed to, uint256 value);

        function allowance(address owner, address spender)
            external
            view
            returns (uint256);

        function approve(address spender, uint256 amount) external returns (bool);

        function balanceOf(address account) external view returns (uint256);

        function calcLoanPayment(
            address borrower,
            uint256 hsiIndex,
            address hsiAddress
        ) external view returns (uint256, uint256);

        function calcLoanPayoff(
            address borrower,
            uint256 hsiIndex,
            address hsiAddress
        ) external view returns (uint256, uint256);

        function claimInstanced(
            uint256 hsiIndex,
            address hsiAddress,
            address hsiStarterAddress
        ) external;

        function claimNative(uint256 stakeIndex, uint40 stakeId)
            external
            returns (uint256);

        function currentDay() external view returns (uint256);

        function dailyDataList(uint256)
            external
            view
            returns (
                uint72 dayMintedTotal,
                uint72 dayLoanedTotal,
                uint72 dayBurntTotal,
                uint32 dayInterestRate,
                uint8 dayMintMultiplier
            );

        function decimals() external view returns (uint8);

        function decreaseAllowance(address spender, uint256 subtractedValue)
            external
            returns (bool);

        function hsim() external view returns (address);

        function increaseAllowance(address spender, uint256 addedValue)
            external
            returns (bool);

        function liquidationList(uint256)
            external
            view
            returns (LiquidationStore memory);
            /*
            returns (
                uint256 liquidationStart,
                address hsiAddress,
                uint96 bidAmount,
                address liquidator,
                uint88 endOffset,
                bool isActive
            );*/

        function loanInstanced(uint256 hsiIndex, address hsiAddress)
            external
            returns (uint256);

        function loanLiquidate(
            address owner,
            uint256 hsiIndex,
            address hsiAddress
        ) external returns (uint256);

        function loanLiquidateBid(uint256 liquidationId, uint256 liquidationBid)
            external
            returns (uint256);

        function loanLiquidateExit(uint256 hsiIndex, uint256 liquidationId)
            external
            returns (address);

        function loanPayment(uint256 hsiIndex, address hsiAddress)
            external
            returns (uint256);

        function loanPayoff(uint256 hsiIndex, address hsiAddress)
            external
            returns (uint256);

        function loanedSupply() external view returns (uint256);

        function mintInstanced(uint256 hsiIndex, address hsiAddress)
            external
            returns (uint256);

        function mintNative(uint256 stakeIndex, uint40 stakeId)
            external
            returns (uint256);

        function name() external view returns (string memory);

        function proofOfBenevolence(uint256 amount) external;

        function shareList(uint256)
            external
            view
            returns (
                HEXStakeMinimal memory stake,
                uint16 mintedDays,
                uint8 launchBonus,
                uint16 loanStart,
                uint16 loanedDays,
                uint32 interestRate,
                uint8 paymentsMade,
                bool isLoaned
            );

        function symbol() external view returns (string memory);

        function totalSupply() external view returns (uint256);

        function transfer(address recipient, uint256 amount)
            external
            returns (bool);

        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) external returns (bool);
    }
    // this comes from the icosa contract. Used for staking HDRN
    interface IcosaInterface {
        event Approval(
            address indexed owner,
            address indexed spender,
            uint256 value
        );
        event HDRNStakeAddCapital(uint256 data, address indexed staker);
        event HDRNStakeEnd(uint256 data, address indexed staker);
        event HDRNStakeStart(uint256 data, address indexed staker);
        event HDRNStakingStats(
            uint256 data,
            uint256 payout,
            uint256 indexed stakeDay
        );
        event HSIBuyBack(
            uint256 price,
            address indexed seller,
            uint40 indexed stakeId
        );
        event ICSAStakeAddCapital(uint256 data, address indexed staker);
        event ICSAStakeEnd(uint256 data0, uint256 data1, address indexed staker);
        event ICSAStakeStart(uint256 data, address indexed staker);
        event ICSAStakingStats(
            uint256 data,
            uint256 payoutIcsa,
            uint256 payoutHdrn,
            uint256 indexed stakeDay
        );
        event NFTStakeEnd(
            uint256 data,
            address indexed staker,
            uint96 indexed nftId
        );
        event NFTStakeStart(
            uint256 data,
            address indexed staker,
            uint96 indexed nftId,
            address indexed tokenAddress
        );
        event NFTStakingStats(
            uint256 data,
            uint256 payout,
            uint256 indexed stakeDay
        );
        event Transfer(address indexed from, address indexed to, uint256 value);

        function allowance(address owner, address spender)
            external
            view
            returns (uint256);

        function approve(address spender, uint256 amount) external returns (bool);

        function balanceOf(address account) external view returns (uint256);

        function currentDay() external view returns (uint256);

        function decimals() external view returns (uint8);

        function decreaseAllowance(address spender, uint256 subtractedValue)
            external
            returns (bool);

        function hdrnPoolIcsaCollected() external view returns (uint256);

        function hdrnPoolPayout(uint256) external view returns (uint256);

        function hdrnPoolPoints(uint256) external view returns (uint256);

        function hdrnPoolPointsRemoved() external view returns (uint256);

        function hdrnSeedLiquidity(uint256) external view returns (uint256);

        function hdrnStakeAddCapital(uint256 amount) external returns (uint256);

        function hdrnStakeEnd()
            external
            returns (
                uint256,
                uint256,
                uint256
            );

        function hdrnStakeStart(uint256 amount) external returns (uint256);

        function hdrnStakes(address)
            external
            view
            returns (
                uint64 stakeStart,
                uint64 capitalAdded,
                uint120 stakePoints,
                bool isActive,
                uint80 payoutPreCapitalAddIcsa,
                uint80 payoutPreCapitalAddHdrn,
                uint80 stakeAmount,
                uint16 minStakeLength
            );

        function hexStakeSell(uint256 tokenId) external returns (uint256);

        function icsaPoolHdrnCollected() external view returns (uint256);

        function icsaPoolIcsaCollected() external view returns (uint256);

        function icsaPoolPayoutHdrn(uint256) external view returns (uint256);

        function icsaPoolPayoutIcsa(uint256) external view returns (uint256);

        function icsaPoolPoints(uint256) external view returns (uint256);

        function icsaPoolPointsRemoved() external view returns (uint256);

        function icsaSeedLiquidity(uint256) external view returns (uint256);

        function icsaStakeAddCapital(uint256 amount) external returns (uint256);

        function icsaStakeEnd()
            external
            returns (
                uint256,
                uint256,
                uint256,
                uint256,
                uint256
            );

        function icsaStakeStart(uint256 amount) external returns (uint256);

        function icsaStakedSupply() external view returns (uint256);

        function icsaStakes(address)
            external
            view
            returns (
                uint64 stakeStart,
                uint64 capitalAdded,
                uint120 stakePoints,
                bool isActive,
                uint80 payoutPreCapitalAddIcsa,
                uint80 payoutPreCapitalAddHdrn,
                uint80 stakeAmount,
                uint16 minStakeLength
            );

        function increaseAllowance(address spender, uint256 addedValue)
            external
            returns (bool);

        function injectSeedLiquidity(uint256 amount, uint256 seedDays) external;

        function launchDay() external view returns (uint256);

        function name() external view returns (string memory);

        function nftPoolIcsaCollected() external view returns (uint256);

        function nftPoolPayout(uint256) external view returns (uint256);

        function nftPoolPoints(uint256) external view returns (uint256);

        function nftPoolPointsRemoved() external view returns (uint256);

        function nftStakeEnd(uint256 nftId) external returns (uint256);

        function nftStakeStart(uint256 amount, address tokenAddress)
            external
            payable
            returns (uint256);

        function nftStakes(uint256)
            external
            view
            returns (
                uint64 stakeStart,
                uint64 capitalAdded,
                uint120 stakePoints,
                bool isActive,
                uint80 payoutPreCapitalAddIcsa,
                uint80 payoutPreCapitalAddHdrn,
                uint80 stakeAmount,
                uint16 minStakeLength
            );

        function symbol() external view returns (string memory);

        function totalSupply() external view returns (uint256);

        function transfer(address to, uint256 amount) external returns (bool);

        function transferFrom(
            address from,
            address to,
            uint256 amount
        ) external returns (bool);

        function waatsa() external view returns (address);
    }
    // used in ThankYouTeam escrow contract
    contract TEAMContract {
        function getCurrentPeriod() public view returns (uint256) {}
    }
    contract HEXContract {
        function currentDay() external view returns (uint256){}
        function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external {}
        function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external {}
    }
    contract HedronContracts {
        struct HEXStakeMinimal {
        uint40 stakeId;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        }

        struct ShareStore {
            HEXStakeMinimal stake;
            uint16          mintedDays;
            uint8           launchBonus;
            uint16          loanStart;
            uint16          loanedDays;
            uint32          interestRate;
            uint8           paymentsMade;
            bool            isLoaned;
        }
        struct LiquidationStore{
            uint256 liquidationStart;
            address hsiAddress;
            uint96  bidAmount;
            address liquidator;
            uint88  endOffset;
            bool    isActive;
        }

    function currentDay() external view returns (uint256) {}
    function liquidationList(uint256 index) public view returns (LiquidationStore memory) {}
    function shareList(uint256 hshi_id) public view returns (ShareStore memory) {}
    function mintInstanced(uint256 hsiIndex,address hsiAddress) external returns (uint256){}
    function mintNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256){}
    function loanLiquidate(address owner,uint256 hsiIndex,address hsiAddress) external returns (uint256) {}
    function loanLiquidateBid (uint256 liquidationId,uint256 liquidationBid) external returns (uint256) {}
    function loanLiquidateExit(uint256 hsiIndex, uint256 liquidationId) external returns (address) {}
    }
    contract HSIContract{
        struct HEXStakeMinimal {
        uint40 stakeId;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        }

        struct ShareStore {
            HEXStakeMinimal stake;
            uint16          mintedDays;
            uint8           launchBonus;
            uint16          loanStart;
            uint16          loanedDays;
            uint32          interestRate;
            uint8           paymentsMade;
            bool            isLoaned;
        }
        struct HEXStake {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool   isAutoStake;
        }
    
        function share() public view returns (ShareStore memory) {}
        function goodAccounting() external {}
        function stakeDataFetch(
        ) 
            external
            view
            returns(HEXStake memory)
        {}
    }
    contract HSIManagerContract {
        mapping(address => address[]) public  hsiLists;
        function hexStakeDetokenize (uint256 tokenId) external returns (address) {}
        function hexStakeStart ( uint256 amount, uint256 length) external returns (address) {}
        function hexStakeEnd (uint256 hsiIndex,address hsiAddress) external returns (uint256) {}
        function ownerOf(uint256 tokenId) public view virtual returns (address) {}
        function hsiToken(uint256 hsiIndex) public view returns (address) {}
        function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual  returns (uint256) {}
        function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
        ) public virtual  {}
        function transferFrom(
            address from,
            address to,
            uint256 tokenId
        ) external {}
    }





contract PolyMaximus is ERC20, ERC20Burnable, ReentrancyGuard {

    /*
    Poly Maximus is a HDRN pool for bidding in the HSIs available in the Hedron Liquidation Auctions.

    * Minting and Redemption Rules:
        - Mint 1 POLY per 1 HDRN deposited to the contract before or on the LAST_POSSIBLE_MINTING_DAY.
        - When minting, users vote for their recommended Bidding Budget as a percent of the entire Poly Maximus HDRN Treasury. Votes on LAST_POSSIBLE_MINTING_DAY default to 100%.
        - When there are less than 2 days left in minting, someone needs to run finalizeMinting() which activates bidding phase, stakes HDRN, and allocates the bidding budget. Then after minting someone needs to run flushLateMint
        - All HDRN deposited on the Late Minting Day is added to the bidding budget.
        - The redemption phase begins once all stakes are ended. Users run redeemPoly() which burns POLY and transfers them the corresponding HEX, HDRN, and ICSA per the REDEMPTION_RATE values.
    
    * HSI Auction Executor
        - The Executor is an address, or set of addresses which are able to run the bid() function completely at their discretion.
        - Poly Maximus Participants agree to not have any expectations of the performance of The Executor. 
        - If the executor does not make any bids over any 30 day period, the bidding is considered done and the remaining HDRN gets staked via Icosa.
    
    * HSI Management:
        - As HSIs enter the contract after succesful auctions, someone needs to run processHSI() which records information about the stake and schedules the ending of the stakes.
        - After each HSI ends, someone needs to run endHSIStake() to mint the HDRN and end the HEX stake. If it is the last scheduled HSI, it activates the redemption period.
        - if one of the HSIs ends with at least a year left until the LAST_ACTIVE_HSI ends, the HEX is restaked until right before the LAST_ACTIVE_HSI ends and the HDRN is added to the Icosa Hedron stake.

    * Thank You Maximus Team:
        - As an expression of gratitude for the outsized benefits of participating in Poly Maximus, 1% of the incoming HDRN and 1% of the outgoing HEX is gifted to TEAM
            - Before or on MINTING_PHASE_END
            -of the 1% of the incoming HDRN:
                - 33% is distributed to TEAM stakers during year 1
                - 33% is distributed to TEAM stakers during year 2
                - 34% is sent to the Mystery Box Hot Address
            - The 1% of the outgoing HEX after all the stakes end is distributed to TEAM stakers during whichever year the last HSI ends.
    */





    /// Data Structures

        struct HEXStakeMinimal {
        uint40 stakeId;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        }

        struct ShareStore {
            HEXStakeMinimal stake;
            uint16          mintedDays;
            uint8           launchBonus;
            uint16          loanStart;
            uint16          loanedDays;
            uint32          interestRate;
            uint8           paymentsMade;
            bool            isLoaned;
        }
        struct LiquidationStore{
            uint256 liquidationStart;
            address hsiAddress;
            uint96  bidAmount;
            address liquidator;
            uint88  endOffset;
            bool    isActive;
        }

        struct LiquidationData {
            uint16          mintedDays;
            uint8           launchBonus;
            uint16          loanStart;
            uint16          loanedDays;
            uint32          interestRate;
            uint8           paymentsMade;
            bool            isLoaned;
            uint256 liquidationStart;
            address hsiAddress;
            uint96  bidAmount;
            address liquidator;
            uint88  endOffset;
            bool    isActive;
        }
        struct HEXStake {
                uint40 stakeId;
                uint72 stakedHearts;
                uint72 stakeShares;
                uint16 lockedDay;
                uint16 stakedDays;
                uint16 unlockedDay;
                bool   isAutoStake;
            }
    
    /// Events
        event Mint (address indexed user,uint256 amount);
        event Redeem (address indexed user, uint256 amount, uint256 hex_redeemed, uint256 hedron_redeemed, uint256 icosa_redeemed);
        event Bid(uint256 liquidationId, uint256 liquidationBid);
        event ProcessHSI(address indexed hsi_address, uint256 hsi_id);
   

    /// Contract interfaces
        address constant HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
        HEXContract hex_contract = HEXContract(HEX_ADDRESS);
        address constant HEDRON_ADDRESS=0x3819f64f282bf135d62168C1e513280dAF905e06;
        HedronContract hedron_contract = HedronContract(HEDRON_ADDRESS); 
        address constant HSI_MANAGER_ADDRESS =0x8BD3d1472A656e312E94fB1BbdD599B8C51D18e3;
        HSIManagerContract HSI_manager_contract = HSIManagerContract(HSI_MANAGER_ADDRESS); 
        address public ICOSA_CONTRACT_ADDRESS = 0xfc4913214444aF5c715cc9F7b52655e788A569ed; 
        IcosaInterface icosa_contract = IcosaInterface(ICOSA_CONTRACT_ADDRESS);
        address constant TEAM_ADDRESS = 0xB7c9E99Da8A857cE576A830A9c19312114d9dE02;
    /// Minting Variables

        uint256 public MINTING_PHASE_START;
        uint256 public MINTING_PHASE_END;
        uint256 public LAST_POSSIBLE_MINTING_DAY;
        uint256 public late_thank_you_team; // late thank you team amount
        address mystery_box_hot =0x00C055Ee792B5bC9AeB06ced73bB71ce7E5773Ce;
        bool HAS_LATE_FLUSHED;
    /// Redemption Variables
        bool public IS_REDEMPTION_ACTIVE;
        uint256 public HEX_REDEMPTION_RATE; // Number of HEX units redeemable per POLY
        uint256 public HEDRON_REDEMPTION_RATE; // Number of HEDRON units redeemable per POLY
        uint256 public ICOSA_REDEMPTION_RATE; // Number of ICSA units redeemable per POLY
        uint256 div_scalar = 10**8;
    
    /// HSI Variables
        mapping (address => bool) public END_STAKERS; // Addresses of the users who end HSI stakes on Poly Community's behalf, may be used in future gas pooling contracts
        uint256 public LAST_STAKE_START_DAY;
        uint256 public LATEST_STAKE_END_DAY;
        mapping (address => HEXStake) public HEXStakes;
        address public LAST_ACTIVE_HSI;
        
        
    
    /// Bid Execution Variables
        mapping (address => bool) public IS_EXECUTOR; // mapping of addresses authorized to run executor functions
        bool public IS_BIDDING_ACTIVE;
        // BIDDING_BUDGET_TRACKER and STAKING_BUDGET_TRACKER are used to calculate the bidding_budget_percent, updated as each user mints and votes.
        uint256 public BIDDING_BUDGET_TRACKER; 
        uint256 public STAKING_BUDGET_TRACKER;
        uint256 TOTAL_BIDDING_BUDGET; // amount of HDRN able to be bid
        uint256 public HDRN_STAKING_BUDGET; // amount of HDRN allocated for staking
        uint256 public bidding_budget_percent; // percent of total HDRN able to be bid
        address public THANK_YOU_TEAM; // contract address for the ThankYouTeam Escrow contract
        uint256 public LAST_BID_PLACED_DAY; // Updated as each bid is placed, used to declare bidding deadline
        address public EXECUTOR_MAIN = 0x07D48f521e11B3824808397A1E57177821de2b61;
        address public EXECUTOR_AUX = 0xc9534Ca2B339bbfC3435e24B93bD1239A898cB28;
        address public POLY_WATER_ADDRESS;
        

        

    constructor() ERC20("Poly Maximus", "POLY") ReentrancyGuard() {
        uint256 start_day=hex_contract.currentDay();
        MINTING_PHASE_START = start_day;
        MINTING_PHASE_END = 1075;
        LAST_POSSIBLE_MINTING_DAY = MINTING_PHASE_END + 2;
        LAST_BID_PLACED_DAY=MINTING_PHASE_END; // set to first eligible day to prevent stake_leftover_hdrn() from being run before first bid is placed
        LAST_STAKE_START_DAY= MINTING_PHASE_END+10; // HSIs must have started before this deadline in order to be processed.
        IS_EXECUTOR[EXECUTOR_MAIN]=true;
        IS_EXECUTOR[EXECUTOR_AUX]=true; 

        PolyWater poly_water_contract = new PolyWater(address(this), EXECUTOR_MAIN); // deploys the gas fee donation pool contract
        POLY_WATER_ADDRESS = address(poly_water_contract);  
       
    }
    
    /// Utilities
        /**
        * @dev Sets decimals to 9 - to be equal to that of HDRN.
        */
        function decimals() public view virtual override returns (uint8) {return 9;}
        function mint(uint256 amount) private {_mint(msg.sender, amount);}
        /**
        * @dev Gets the current HEX Day.
        * @return hex_day current day per the HEX Contract.
        */
        function getCurrentDay() public view returns (uint256 hex_day) {return hex_contract.currentDay();} 
        
    /// Minting Phase Functions
        /**
        * @dev Checks that mint phase is ongoing and that the user inputted bid budget percent is within the allowed range. Then it updates the global bidding_budget_percent value, transfers the amount of HDRN to the Poly contract, then mints the user the same number of POLY.
        * @param amount amount of HDRN minted into POLY.
        * @param bid_budget_percent percent of total HDRN the user thinks should be bid on HSIs.
        */
        function mintPoly(uint256 amount, uint256 bid_budget_percent) nonReentrant external {
            uint256 today = getCurrentDay();
            require(today <= LAST_POSSIBLE_MINTING_DAY, "Minting Phase must still be ongoing to mint POLY.");
            require(bid_budget_percent <= 100, "Bid Budget must not be greater than 100 percent.");
            require(bid_budget_percent >= 50, "Bid Budget Percent must not be less than 50 percent.");
            IERC20(HEDRON_ADDRESS).transferFrom(msg.sender, address(this), amount); // sends HDRN to the Poly Contract
            if (today==LAST_POSSIBLE_MINTING_DAY || today == LAST_POSSIBLE_MINTING_DAY-1){
                require(IS_BIDDING_ACTIVE==true, "Run finalizeMinting() to resume minting today.");  // prevent double-thanking team (even though team should get way more)
                late_thank_you_team = late_thank_you_team + (amount / 200); 
                bid_budget_percent = 100;
            }
            BIDDING_BUDGET_TRACKER = BIDDING_BUDGET_TRACKER + ((bid_budget_percent * amount)/100); // increments weighted running total bidding budget tracker
            STAKING_BUDGET_TRACKER = STAKING_BUDGET_TRACKER + (((100-bid_budget_percent) * amount)/100); // increments weighted running total staking budget tracker
            bidding_budget_percent = 100 * BIDDING_BUDGET_TRACKER / (BIDDING_BUDGET_TRACKER + STAKING_BUDGET_TRACKER); // calculates percent of total to be bid
            mint(amount); // Mints 1 POLY per 1 HDRN
            emit Mint(msg.sender, amount);
        }

        /*
        * @dev This function is run at the end of the minting phase to kick off the bidding phase. It checks if the minting phase is still ongoing, deploys the ThankYouTeam escrow contract, allocates the amount used to Thank TEAM, calculates the Bidding and Staking budgets, and stakes the HDRN staking budget.
        */
        function finalizeMinting() external nonReentrant {
            require(getCurrentDay() > MINTING_PHASE_END, "Minting Phase must be over.");
            require(IS_BIDDING_ACTIVE ==false);
            ThankYouTeam tyt = new ThankYouTeam();
            THANK_YOU_TEAM = address(tyt);
            uint256 total_hdrn = IERC20(HEDRON_ADDRESS).balanceOf(address(this));
            uint256 thank_you_team = 100 * total_hdrn / 10000; // Poly thanks TEAM for saving them 99% on gas fees and letting them have HDRN staking bonuses with 1% of the total HDRN pledged.
            IERC20(HEDRON_ADDRESS).transfer(THANK_YOU_TEAM, thank_you_team);
            TOTAL_BIDDING_BUDGET = (total_hdrn - thank_you_team) * bidding_budget_percent/100;
            HDRN_STAKING_BUDGET = (total_hdrn - thank_you_team) - TOTAL_BIDDING_BUDGET;
            IERC20(HEDRON_ADDRESS).approve(ICOSA_CONTRACT_ADDRESS, HDRN_STAKING_BUDGET);
            icosa_contract.hdrnStakeStart(HDRN_STAKING_BUDGET);
            IS_BIDDING_ACTIVE = true;
        }
        
        /* 
        @dev Anyone can run the function which sends the late poly minters' thanks to TEAM and Mystery Box. Half of it gets distributed to Year 1 TEAM stakers. Half of it gets distributed to the Mystery Box Hot address collected from the Mystery Bx Contract.
        
        */
        function flushLateMint() nonReentrant external {
            require(getCurrentDay()>LAST_POSSIBLE_MINTING_DAY, "Late Mint Phase must be over");
            require(HAS_LATE_FLUSHED==false);
            IERC20(HEDRON_ADDRESS).transfer(TEAM_ADDRESS, late_thank_you_team);
            IERC20(HEDRON_ADDRESS).transfer(mystery_box_hot, late_thank_you_team);
            HAS_LATE_FLUSHED = true;
        }
        

    /// Redemption Functions
        /**
        * @dev Checks that redemption phase is ongoing and that the amount requested is less than the user's POLY balance. Then it calculates the amount of HEX, HDRN, and ICOSA that is redeemable for the amount input by the user, burns that amount and transfers them their alloted HEX, HDRN, and ICOSA.
        * @param amount amount of POLY being redeemed.
        */
        function redeemPoly(uint256 amount) nonReentrant external {
            require(IS_REDEMPTION_ACTIVE==true, "Redemption can only happen at end.");
            uint256 current_balance = balanceOf(msg.sender);
            require(amount<=current_balance, "insufficient balance");
            uint256 redeemable_hex = amount * HEX_REDEMPTION_RATE / div_scalar;
            uint256 redeemable_hedron = amount * HEDRON_REDEMPTION_RATE / div_scalar;
            uint256 redeemable_icosa = amount * ICOSA_REDEMPTION_RATE / div_scalar;
            burn(amount);
            if (redeemable_hex > 0 ) {
                IERC20(HEX_ADDRESS).transfer(msg.sender, redeemable_hex);
            }
            if (redeemable_hedron > 0 ) {
                IERC20(HEDRON_ADDRESS).transfer(msg.sender, redeemable_hedron);
            }
            if (redeemable_icosa > 0 ) {
                IERC20(ICOSA_CONTRACT_ADDRESS).transfer(msg.sender, redeemable_icosa);
            }
            emit Redeem(msg.sender, amount, redeemable_hex, redeemable_hedron, redeemable_icosa);
        }
        

        function calculate_redemption_rate(uint256 balance, uint256 supply) public view returns (uint256 redemption_rate) {
            uint256 scaled_redemption_rate = balance * div_scalar / supply;
            return scaled_redemption_rate;
        }
 
        function set_redemption_rate() private {
            HEX_REDEMPTION_RATE = calculate_redemption_rate(IERC20(HEX_ADDRESS).balanceOf(address(this)), totalSupply());
            HEDRON_REDEMPTION_RATE = calculate_redemption_rate(IERC20(HEDRON_ADDRESS).balanceOf(address(this)), totalSupply());
            ICOSA_REDEMPTION_RATE =  calculate_redemption_rate(IERC20(ICOSA_CONTRACT_ADDRESS).balanceOf(address(this)), totalSupply());
        }
    /// Liquidation Auction Management
        /*
        * @dev Bids on existing liquidations. It checks to make sure the bid is within the maximum bid allowance, ensures that bidding is still active, and that the caller of this function is in the whitelisted executor list. Then it places the bid via the Hedron contract.
        * @param liquidationId - unique identifier for the liquidation
        * @param liquidationBid - bid amount determined by executor.
        */
        function bid(uint256 liquidationId, uint256 liquidationBid) external nonReentrant {
            require(IS_BIDDING_ACTIVE);
            require(getCurrentDay() <= LAST_BID_PLACED_DAY + 30, "If 30 Days go by without a bid placed, bidding phase ends.");
            require(IS_EXECUTOR[msg.sender]);
            hedron_contract.loanLiquidateBid(liquidationId, liquidationBid);
            LAST_BID_PLACED_DAY = getCurrentDay();
            emit Bid(liquidationId, liquidationBid);
        }
        
        /*
        * @dev Allows the executor to start the liquidation process.
        * @param owner HSI contract owner address.
        * @param hsiIndex Index of the HSI contract address in the owner's HSI list.
        * @param hsiAddress Address of the HSI contract.
        */
        function startBid(address owner, uint256 hsiIndex, address hsiAddress) external nonReentrant {
            require(getCurrentDay() <= LAST_BID_PLACED_DAY + 30, "If 30 Days go by without a bid placed, bidding phase ends.");
            require(IS_EXECUTOR[msg.sender]);
            hedron_contract.loanLiquidate(owner, hsiIndex, hsiAddress);
            LAST_BID_PLACED_DAY = getCurrentDay();
        }
        /**
            * @dev Allows any address to exit a completed liquidation, granting control of the
                    HSI to the highest bidder. Included here for UI simplicity, but may be called directly to hedron contract.
            * @param hsiIndex Index of the HSI contract address in the zero address's HSI list.
            *                 (see hsiLists -> HEXStakeInstanceManager.sol)
            * @param liquidationId ID number of the liquidation to exit.
          
     */
        function collectWinnings(uint256 hsiIndex, uint256 liquidationId) external {
            hedron_contract.loanLiquidateExit(hsiIndex, liquidationId);
        }

        
        /*
        * @dev Gets the information about the liquidation, and the HSI.
        * @param liquidation_index Hedron liquidation auction identifier
        * return liquidation_data Liquidation information including: mintedDays, launchBonus, loanStart , loanedDays, interestRate, paymentsMade, isLoaned, liquidationStart, hsiAddress, bidAmount, liquidator, endOffset, isActive
        */
        function getLiquidation(uint256 liquidation_index) public view returns (LiquidationData memory liquidation_data) {
            
            uint256 liquidationStart=hedron_contract.liquidationList(liquidation_index).liquidationStart; 
            address hsiAddress=hedron_contract.liquidationList(liquidation_index).hsiAddress;
            uint96  bidAmount=hedron_contract.liquidationList(liquidation_index).bidAmount;
            address liquidator=hedron_contract.liquidationList(liquidation_index).liquidator;
            uint88  endOffset=hedron_contract.liquidationList(liquidation_index).endOffset;
            bool    isActive=hedron_contract.liquidationList(liquidation_index).isActive;
            uint16         mintedDays=  HSIContract(hsiAddress).share().mintedDays;
            uint8          launchBonus = HSIContract(hsiAddress).share().launchBonus;
            uint16         loanStart =  HSIContract(hsiAddress).share().loanStart;
            uint16         loanedDays =HSIContract(hsiAddress).share().loanedDays;
            uint32         interestRate= HSIContract(hsiAddress).share().interestRate;
            uint8          paymentsMade = HSIContract(hsiAddress).share().paymentsMade;
            bool           isLoaned = HSIContract(hsiAddress).share().isLoaned;
            LiquidationData memory liquidation = LiquidationData(
            mintedDays, launchBonus, loanStart , loanedDays, interestRate, paymentsMade, isLoaned,
            liquidationStart, hsiAddress, bidAmount, liquidator, endOffset, isActive
            );
            return liquidation;
        }
        

        
    /// HSI Management
        /*
        * @dev Run this function when a new HSI is won by the contract. It saves a new entry in the HEXStake mapping and determines if the HSI is the one that ends on the latest day.
        * @param hsi_id Unique ID for the HSI.
        */
        function processHSI(uint256 hsi_id) external nonReentrant {
            address hsi_address = HSI_manager_contract.hsiToken(hsi_id);
            address hsi_owner = HSI_manager_contract.ownerOf(hsi_id);
            require(hsi_owner==address(this), "Can only process HSIs owned by Poly Contract.");
            HSIContract hsi = HSIContract(hsi_address);
            require(hsi.stakeDataFetch().lockedDay<LAST_STAKE_START_DAY);
            HEXStake storage stake = HEXStakes[hsi_address];
            stake.stakeId = hsi.stakeDataFetch().stakeId;
            stake.stakedHearts =hsi.stakeDataFetch().stakedHearts;
            stake.stakeShares = hsi.stakeDataFetch().stakeShares;
            stake.lockedDay = hsi.stakeDataFetch().lockedDay;
            stake.stakedDays = hsi.stakeDataFetch().stakedDays;
            stake.unlockedDay = hsi.stakeDataFetch().stakedDays;
            stake.isAutoStake = hsi.stakeDataFetch().isAutoStake;
            uint256 end_day= stake.lockedDay + stake.stakedDays;
            if (end_day>LATEST_STAKE_END_DAY) {
                LATEST_STAKE_END_DAY = end_day;
                LAST_ACTIVE_HSI = hsi_address;
            }
            HSI_manager_contract.hexStakeDetokenize(hsi_id);
            emit ProcessHSI(hsi_address, hsi_id);
        }
        /*
        * @dev Ends the HSI stake, if it is eligible to end. If it is the last active HSI in the list, it activates the redemption period and sends a HEX tip to TEAM. if it is not the last one and there is more than a year until the last active HSI, it restakes the HEX and HDRN. Then it calculates the redemption rates.
        * @param hsiIndex HSI identifier
        * @param hsiAddress HSI unique contract address
        */
        function endHSIStake(uint256 hsiIndex, address hsiAddress) external nonReentrant {
            HEXStake storage stake = HEXStakes[hsiAddress];
            require(stake.lockedDay + stake.stakedDays < getCurrentDay(), "This stake has not ended yet");
            HSI_manager_contract.hexStakeEnd(hsiIndex, hsiAddress);
            if (hsiAddress == LAST_ACTIVE_HSI) {
                icosa_contract.hdrnStakeEnd();
                IS_REDEMPTION_ACTIVE = true;
                uint256 thank_you_team = 100 * IERC20(HEX_ADDRESS).balanceOf(address(this)) / 10000;
                IERC20(HEX_ADDRESS).transfer(TEAM_ADDRESS, thank_you_team);
            }
            set_redemption_rate();
            END_STAKERS[msg.sender]=true;
        }
        /*
        * @dev mints the HDRN from HSIs held by Poly Contract
        
        */
        function hedronMintInstanced(uint256 hsiIndex, address hsiAddress) external nonReentrant {
            hedron_contract.mintInstanced(hsiIndex, hsiAddress);
            set_redemption_rate();

        }

             /*
        * @dev Mints the HDRN from the stake, ends the stake, and calculates the redemption rate.
        * @param stakeIndex - index among list of users stakes
        * @param stakeIdParam - unique ID for hex stake
        */ 
        function endNativeStake(uint256 stakeIndex, uint40 stakeIdParam) external nonReentrant {
            require(getCurrentDay() >= LATEST_STAKE_END_DAY - 2);
            hex_contract.stakeEnd(stakeIndex, stakeIdParam);
            set_redemption_rate();
        }
        /*
        * @dev Mints the HDRN from the stake, ends the stake, and calculates the redemption rate.
        * @param stakeIndex - index among list of users stakes
        * @param stakeIdParam - unique ID for hex stake
        */ 
        function hedronMintNative(uint256 stakeIndex, uint40 stakeIdParam) external nonReentrant {
            hedron_contract.mintNative(stakeIndex, stakeIdParam);
            set_redemption_rate();
        }
        /*
        @dev Checks if the bidding phase is over is adequate time left and restakes leftover HEX and HDRN.
        */
        function stakeLeftover() external nonReentrant {
            require(getCurrentDay() > LAST_BID_PLACED_DAY + 30, "Must be 30 days after LAST_BID_PLACED");
            require(IS_REDEMPTION_ACTIVE == false, "Can not run during redemption phase.");
            uint256 days_til_redemption = LATEST_STAKE_END_DAY - getCurrentDay();
            require(days_til_redemption > 366, "Can not run in the last year leading up to end of last stake.");
            if (IERC20(HEX_ADDRESS).balanceOf(address(this))> 100000*10**8 ) {
                    hex_contract.stakeStart(IERC20(HEX_ADDRESS).balanceOf(address(this)), days_til_redemption - 3);
                    set_redemption_rate();
                }
            if (IERC20(HEDRON_ADDRESS).balanceOf(address(this)) > 0) {
                IERC20(HEDRON_ADDRESS).approve(ICOSA_CONTRACT_ADDRESS, IERC20(HEDRON_ADDRESS).balanceOf(address(this)));
                icosa_contract.hdrnStakeAddCapital(IERC20(HEDRON_ADDRESS).balanceOf(address(this)));
                set_redemption_rate();
            }
        }

   
        
        

        
    
        
        

}

contract ThankYouTeam {
    // THIS CONTRACT IS AN EXPRESSION OF GRATITUDE TO MAXIMUS TEAM FOR SAVING THE HSI BIDDERS FROM HOLDING THE BAG ON HSIs IMPACTED BY GAS FEES
    address TEAM_ADDRESS =0xB7c9E99Da8A857cE576A830A9c19312114d9dE02;
    address constant HEDRON_ADDRESS=0x3819f64f282bf135d62168C1e513280dAF905e06;
    address mystery_box_hot =0x00C055Ee792B5bC9AeB06ced73bB71ce7E5773Ce;
    mapping (uint => uint256) public schedule;
    uint256 percent_year_one = 33;
    uint256 percent_year_two = 33;
    bool IS_SCHEDULED;
    constructor() {
    }
    /*
    * @dev This schedules the distributions allocated to TEAM stakers during years one and two, and sends the Mystery Box hot address a reward.
    */
    function schedule_distribution() public {
        require(IS_SCHEDULED==false);
        schedule[1]=IERC20(HEDRON_ADDRESS).balanceOf(address(this)) * percent_year_one / 100;
        schedule[3]=IERC20(HEDRON_ADDRESS).balanceOf(address(this)) * percent_year_two / 100;
        uint256 mb_amt = IERC20(HEDRON_ADDRESS).balanceOf(address(this)) - (schedule[1]+schedule[3]);
        IERC20(HEDRON_ADDRESS).transfer(mystery_box_hot, mb_amt);
        IS_SCHEDULED=true;
    }
    /*
    * @dev This sends the funds to the TEAM contract during the qualified years, then prevents it from being sent again that year.
    */
    function distribute() public {
        require(IS_SCHEDULED, "The distributions have not been scheduled yet, run schedule_distribution() first.");
        uint256 current_period = TEAMContract(TEAM_ADDRESS).getCurrentPeriod();
        uint256 amt = schedule[current_period];
        require(amt>0, "There are no available funds to be distributed this year. Either it is not a qualified year, or it has already been run this year.");
        IERC20(HEDRON_ADDRESS).transfer(TEAM_ADDRESS, amt);
        schedule[current_period]=0;
    }
     
}

contract PolyWater is ERC20, ReentrancyGuard {
    
    address public executor; 
    address constant HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    HEXContract hex_contract = HEXContract(HEX_ADDRESS);

    address public POLY_ADDRESS;
    uint ds = 10**8; // division scalar
    uint256 public launch_day;
    constructor(address poly_address, address executor_address) ERC20("Poly Water", "WATER") ReentrancyGuard() {
        executor = executor_address;
        POLY_ADDRESS=poly_address; 
        launch_day = hex_contract.currentDay();
    }
    function mint(uint256 amount) private {
        _mint(msg.sender, amount);
    }
    event Mint(address indexed minter, uint mint_rate, uint amount);
    event Flush(address indexed flusher, uint amount);
    receive() external payable nonReentrant {
        uint mint_rate = current_mint_rate(); //get current mint rate
        require(mint_rate>0, "Minting Phase is over."); // ensure the mint phase is ongoing.
        mint(mint_rate*msg.value); // mint WATER to sender
        emit Mint(msg.sender,mint_rate, msg.value);
    }
    /*
    @dev calculates the mint rate. Starting at 369, and decreasing by 1/3 every 36 days.
    */
    function current_mint_rate() public view returns (uint) {
        uint256 months = ((hex_contract.currentDay() - launch_day) * ds)/(36 * ds); 
        return 369 * ds / ( 3**months * ds );
    }
    function flush() public  {
        require(msg.sender==executor, "Only Executor can run this function.");
        uint256 amount = address(this).balance;
        (bool sent, bytes memory data) = payable(executor).call{value: amount}(""); // send ETH to the Executor 
        require(sent, "Failed to send Ether");
        emit Flush(msg.sender, amount);
    }
    function flush_erc20(address token_contract_address) public  {
        require(msg.sender==executor, "Only Executor can run this function.");
        IERC20 tc = IERC20(token_contract_address);
        tc.transfer(executor, tc.balanceOf(address(this)));

    }
    
   
}