/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/ico_iquantum_v4.sol


pragma solidity ^0.8.0;





contract TokenEconomics is ERC20, Ownable {
    using SafeMath for uint256;

    // We can also take these address in constructor 
    // address private ecoSystemFund = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;  // Address of ecoSystem Fund
    // address private stakingReward = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;  // Address of staking Reward
    // address private exchangeLiquidity = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB; // Address of exchange Liquidity

    address private ecoSystemFund = 0xAb84d58D03923747577074439a8EEfc2f88bC22a;  // Address of ecoSystem Fund
    address private stakingReward = 0x9A66DB61C07Ae68Aa56b72306E7905981507BA58;  // Address of staking Reward
    address private exchangeLiquidity = 0x3854b3f41A4e53B1b355d90850d01eEA8724161E; // Address of exchange Liquidity
    
    string public floatingTokensPercentage;

    // Mapping to store the sum of all tokens in a month
    mapping(uint256 => uint256) public tokensInMonth;

    // Mapping to store the market capital in a month
    mapping(uint256 => uint256) public marketCapInMonth;

    // Mapping to store the cumulative sum of all tokens in a month
    mapping(uint256 => uint256) public cumulativeSupply;
    mapping(uint256 => bool) private monthCheck;

    // Variable to keep track of the current month
    uint256 public currentMonth = 1;
    uint256 public lastMonthUpdateTimestamp;
    uint256 currentTime;
    uint256 public constant SECONDS_PER_MONTH = 1 minutes; // 30 days; 1 minutes

    // Variable to store the total supply
    uint256 private totalSupplyAmount;

    // Vesting information
    struct TokenAllocation {
        uint256 percentageShare;
        uint256 lockPeriodMonths;
        uint256 vestingMonths;
        uint256 vestingStartTime;
        uint256 withdrawanAmount;
        uint256 linearPercentage;
        uint256 tokenPrice;
        uint256 marketCap;
    }
    mapping(address => TokenAllocation) public tokenAllocations;

    // Events
    // Here indexed keyword is used to get the events related to the specific addrss only. 
    // In Golang we can use this in FilterQuery -> Topic
    // indexedParam := common.HexToHash("0x123456789ABCDEF...") // Replace with the value of indexedParam you want to filter by
    // query := ethereum.FilterQuery{
    //     Addresses: []common.Address{contractAddress},
    //     Topics:    [][]common.Hash{{common.BytesToHash(eventSignature)}, {indexedParam}},
    // }
    event TokensMinted(address indexed to, uint256 amount);
    event TokenAllocationAdded(address indexed entity, uint256 percentageShare, uint256 lockPeriodMonths, uint256 vestingMonths, uint256 vestingStartTime, uint256 linearPercentage);
    event AmountConsole(uint256 vestingStartTime, uint256 vestingMonths, uint256 elapsedMonths, uint256 totalVestedAmount, uint256 alreadyWithdrawn, uint256 withdrawableAmount);
    event ConsoleLog(string attributeName, uint256 number);
    event Withdrawal(address indexed to, uint256 withdrawableAmount, string floatingTokensPercentage);
    event VestingCompleted(address indexed to, uint256 remainingVestedTokens); 
    // Constructor
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _tokenTotalSupply)  ERC20(_name, _symbol) {
        require(_decimals >= 0, "Decimals should be greater than or equals to zero.");
        require(_decimals <= 18, "Decimals cannot be greater than 18.");
        totalSupplyAmount = _tokenTotalSupply * (10 ** uint256(_decimals));
        // Adjust the minted amount based on the token decimals
        _mint(msg.sender, _tokenTotalSupply * (10 ** uint256(_decimals)));
        distributeInicialTokens(msg.sender);
        
        emit TokensMinted(msg.sender, _tokenTotalSupply);

        // After distribute Inicial Tokens transfering the remaining tokens to the contract
        uint256 remainingAmt = balanceOf(msg.sender);
        _transfer(msg.sender, address(this), remainingAmt);
        emit Transfer(msg.sender, address(this), remainingAmt);
        lastMonthUpdateTimestamp = block.timestamp;
    }

    // To update the currentMonth variable with the next month in sequence.
    function updateCurrentMonth() internal {
        currentTime = block.timestamp;
        uint256 elapsedMonths = currentTime.sub(lastMonthUpdateTimestamp).div(SECONDS_PER_MONTH);
        if (elapsedMonths > 0) {
            currentMonth = currentMonth.add(elapsedMonths);
            lastMonthUpdateTimestamp = lastMonthUpdateTimestamp.add(elapsedMonths.mul(SECONDS_PER_MONTH));
        }
    }

    // Token functions
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balanceOf(msg.sender) >= _value, "Insufficient balance");
        
        // Update the sum of all tokens in a month for the sender
        tokensInMonth[currentMonth] = tokensInMonth[currentMonth].sub(_value);
        
        // Update the sum of all tokens in a month for the receiver
        tokensInMonth[currentMonth] = tokensInMonth[currentMonth].add(_value);
    
        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function distributeInicialTokens(address owner) internal {
        uint256 tokenTotalSupply = totalSupply();
        // Distribute tokens based on percentage shares
        _transfer(owner, ecoSystemFund, tokenTotalSupply.mul(13).div(100)); // 13% allocation for ecoSystemFund

        _transfer(owner, stakingReward, tokenTotalSupply.mul(11).div(100)); // 11% allocation for stakingReward

        _transfer(owner, exchangeLiquidity, tokenTotalSupply.mul(10).div(100)); // 10% allocation for exchangeLiquidity
    }

    function burnTokens(uint256 _amount) public {
        _burn(msg.sender, _amount);
        tokensInMonth[currentMonth] = tokensInMonth[currentMonth].sub(_amount);
        cumulativeSupply[currentMonth] = cumulativeSupply[currentMonth].sub(_amount);
    }

    // Vesting functions
    function setTokenAllocation(address entity, uint256 percentageShare, uint256 lockPeriodMonths, uint256 vestingMonths, uint256 linearPercentage, uint256 tokenPrice, uint256 marketCap) public onlyOwner {
        require(entity != address(0), "Invalid address: Entity cannot be the zero address");
        require(percentageShare > 0, "Percentage Share must be greater than zero");
        require(vestingMonths > 0 || linearPercentage <= 100, "Invalid vesting or linear percentage");

        TokenAllocation storage tokenAllocationObj = tokenAllocations[entity];
        require(tokenAllocationObj.vestingStartTime == 0, "Allocation already set for the entity");

        tokenAllocationObj.percentageShare = percentageShare;
        tokenAllocationObj.lockPeriodMonths = lockPeriodMonths;
        tokenAllocationObj.vestingMonths = vestingMonths;
        tokenAllocationObj.vestingStartTime = block.timestamp;
        tokenAllocationObj.linearPercentage = linearPercentage;
        tokenAllocationObj.tokenPrice = tokenPrice;
        tokenAllocationObj.marketCap = marketCap;

        // Setting marketCap as 70 which is 0.70 * 10.
        tokenAllocationObj.marketCap = 70;
        
        // Update the Current Month with the new allocation
        updateCurrentMonth(); // Call the function to update the current month
    
        emit TokenAllocationAdded(entity, percentageShare, lockPeriodMonths, vestingMonths, tokenAllocationObj.vestingStartTime, linearPercentage);
    }

    function checkWithdraw() public view returns (uint256, uint256, uint256, uint256, uint256) {
        TokenAllocation storage tokenAllocationObj = tokenAllocations[msg.sender];
        require(tokenAllocationObj.vestingStartTime > 0, "No vesting schedule found");
        uint256 vestingStartTime = tokenAllocationObj.vestingStartTime.add(tokenAllocationObj.lockPeriodMonths.mul(SECONDS_PER_MONTH));
        uint256 vestingMonths = tokenAllocationObj.vestingMonths; 
        // string memory monthErrMsg;
        // if (vestingStartTime >= block.timestamp){
        //     monthErrMsg = calculateRemainingTime(vestingStartTime);
        // }
        // require(vestingStartTime < block.timestamp, string(abi.encodePacked("Vesting Month not yet started. Starting in ", monthErrMsg)));
        // Calculate the elapsed months since the vesting start time
        uint256 elapsedMonths = ((block.timestamp.sub(vestingStartTime)).div(SECONDS_PER_MONTH)).add(1); 
        // Check if all tokens are already withdrawn
        
        // Calculate the total vested amount based on the elapsed months
        uint256 totalVestedAmount = tokenAllocationObj.percentageShare.mul(totalSupply()).div(100);
        

        uint256 withdrawableAmount;
        
        // Check if linear percentage is 100 or not
        // If it is 100 and vesting month is provided, calculate the withdrawable Amount based on the elapsed month and vesting month
        // But if it is not 100 and vesting month is zero, calculate the withdrawable Amount based on the linear percentage.
        if (tokenAllocationObj.linearPercentage == 100 && vestingMonths > 0) {            
            // Calculate the withdrawable amount based on the already withdrawn tokens and the vesting months
            withdrawableAmount = totalVestedAmount.mul(elapsedMonths).div(vestingMonths).sub(balanceOf(msg.sender));
        } else {
            // Calculate the withdrawable amount based on the already withdrawn tokens
            // and based on the linearPercentage
            require(tokenAllocationObj.vestingMonths == 0, "If Linear Percentage is provided then vesting months should be zero.");
            require(tokenAllocationObj.linearPercentage <= 100, "Linear Percentage cannot be greater than 100.");
            withdrawableAmount = totalVestedAmount.mul(tokenAllocationObj.linearPercentage).div(100);
        }
        return (vestingStartTime, vestingMonths, elapsedMonths, totalVestedAmount, withdrawableAmount);
    }

    // This mapping is to keep track of the last withdrawal timestamp for each beneficiary
    mapping(address => uint256) lastWithdrawalTimestamp;

    // TODO: If we miss any month calling withdraw, we miss that month transaction
    function withdraw() external {
        TokenAllocation storage tokenAllocationObj = tokenAllocations[msg.sender];
        require(tokenAllocationObj.vestingStartTime > 0, "No vesting schedule found");
        // Assuming a month has 30 days
        uint256 oneMonth = 1 minutes;  // 30 days  1 minutes
        uint256 vestingStartTime = tokenAllocationObj.vestingStartTime.add(tokenAllocationObj.lockPeriodMonths.mul(oneMonth));
        uint256 vestingMonths = tokenAllocationObj.vestingMonths; 
        updateCurrentMonth(); // Call the function to update the current month
        string memory monthErrMsg;
        if (vestingStartTime > block.timestamp){
            monthErrMsg = calculateRemainingTime(vestingStartTime);
        }
        require(vestingStartTime <= block.timestamp, string(abi.encodePacked("Vesting Month not yet started. Starting in ", monthErrMsg)));
        // Calculate the elapsed months since the vesting start time
        uint256 elapsedMonths = ((block.timestamp.sub(vestingStartTime)).div(oneMonth)).add(1); 
        // Check if all tokens are already withdrawn
        
        // Calculate the total vested amount based on the elapsed months
        uint256 totalVestedAmount = tokenAllocationObj.percentageShare.mul(totalSupply()).div(100);
        

        uint256 withdrawableAmount;
        
        // Check if linear percentage is 100 or not
        // If it is 100 and vesting month is provided, calculate the withdrawable Amount based on the elapsed month and vesting month
        // But if it is not 100 and vesting month is zero, calculate the withdrawable Amount based on the linear percentage.
        if (tokenAllocationObj.linearPercentage == 100 && vestingMonths > 0) {            
            // Calculate the withdrawable amount based on the already withdrawn tokens and the vesting months
            withdrawableAmount = totalVestedAmount.mul(elapsedMonths).div(vestingMonths).sub(balanceOf(msg.sender));
        } else {
            // Calculate the withdrawable amount based on the already withdrawn tokens
            // and based on the linearPercentage
            require(tokenAllocationObj.vestingMonths == 0, "If Linear Percentage is provided then vesting months should be zero.");
            require(tokenAllocationObj.linearPercentage <= 100, "Linear Percentage cannot be greater than 100.");
            withdrawableAmount = totalVestedAmount.mul(tokenAllocationObj.linearPercentage).div(100);
        }

        emit AmountConsole(vestingStartTime, vestingMonths, elapsedMonths, totalVestedAmount, tokenAllocationObj.withdrawanAmount, withdrawableAmount);
        
        // string memory monthErrMsg2;

        // Check if the withdrawal is allowed for the current month
        require(withdrawableAmount > 0, "No tokens available for withdrawal");
        require(balanceOf(address(this)) >= withdrawableAmount, "Insufficient balance in vesting contract");
        
        uint256 totalAmt = balanceOf(msg.sender).add(withdrawableAmount);
        require((elapsedMonths < vestingMonths) || (tokenAllocationObj.withdrawanAmount < totalVestedAmount), "All tokens have already been withdrawn");
        require(block.timestamp > lastWithdrawalTimestamp[msg.sender].add(oneMonth), "Withdraw already done for this month");

        // If Calculated tokens are more than the total vested amount
        // Than set the withdrawable amount as the remaining amount to be transfered
        if (totalAmt >= totalVestedAmount){
            withdrawableAmount = totalVestedAmount - tokenAllocationObj.withdrawanAmount;
        }

        // Update the last withdrawal timestamp for the beneficiary
        lastWithdrawalTimestamp[msg.sender] = block.timestamp;

        // Transfer the withdrawable amount to the beneficiary
        tokenAllocationObj.withdrawanAmount = tokenAllocationObj.withdrawanAmount.add(withdrawableAmount);

        _transfer(address(this), msg.sender, withdrawableAmount);
        emit Transfer(address(this), msg.sender, withdrawableAmount);

        // Update the tokensInMonth mapping and calculate the cumulative circulating supply
        tokensInMonth[currentMonth] = tokensInMonth[currentMonth].add(withdrawableAmount);        
        
        if (monthCheck[currentMonth] == false) {
            
            cumulativeSupply[currentMonth] = cumulativeSupply[currentMonth].add(recursiveCheck(currentMonth-1));
            
            // if (cumulativeSupply[currentMonth-1] != 0) {
            //     cumulativeSupply[currentMonth] = cumulativeSupply[currentMonth].add(cumulativeSupply[currentMonth-1]);
            // }
            monthCheck[currentMonth] = true;
        }

        // Calculate the cumulative Supply
        cumulativeSupply[currentMonth] = cumulativeSupply[currentMonth].add(withdrawableAmount);

        // Calculate the Market Cap In Month
        marketCapInMonth[currentMonth] = cumulativeSupply[currentMonth].mul(tokenAllocationObj.marketCap).div(100);
        
        // Calculate the floating tokens percentage
        //cumulativeSupply[currentMonth].mul(100).div(totalSupply());
        floatingTokensPercentage = calculatePercentage(cumulativeSupply[currentMonth].mul(100), totalSupply()); 

        emit Withdrawal(msg.sender, withdrawableAmount, floatingTokensPercentage);

        // Check if all months are over
        if (elapsedMonths >= vestingMonths) {
            // Perform additional logic here for all months being over
            // For example, you can transfer any remaining vested tokens to the beneficiary
            
            // Calculate the remaining vested tokens
            uint256 remainingVestedTokens = totalVestedAmount.sub(tokenAllocationObj.withdrawanAmount);

            // Transfer the remaining vested tokens to the beneficiary
            if (remainingVestedTokens > 0) {
                tokenAllocationObj.withdrawanAmount = tokenAllocationObj.withdrawanAmount.add(remainingVestedTokens);
                _transfer(address(this), msg.sender, remainingVestedTokens);
                emit Transfer(address(this), msg.sender, remainingVestedTokens);
            }
            
            // Update any necessary state variables or mappings to reflect the completion of the vesting period
            
            // For example, you might want to update the cumulative supply and market cap for the final month
            cumulativeSupply[currentMonth] = cumulativeSupply[currentMonth].add(remainingVestedTokens);
            marketCapInMonth[currentMonth] = cumulativeSupply[currentMonth].mul(tokenAllocationObj.marketCap).div(100);
            
            // Set the floating tokens percentage to 100% since all tokens are vested
            floatingTokensPercentage = calculatePercentage(cumulativeSupply[currentMonth].mul(100), totalSupply()); 
            
            // Emit an event to indicate the completion of the vesting period
            emit VestingCompleted(msg.sender, remainingVestedTokens);
        }
    }

    function recursiveCheck(uint256 index) private view returns (uint256) {
        if (cumulativeSupply[index] == 0 && index > 0) {
            return recursiveCheck(index - 1);
        } else {
            return cumulativeSupply[index];
        }
    }

    function calculatePercentage(uint256 numerator, uint256 denominator)  internal pure returns (string memory) {
        // Calculate the percentage as a fraction with decimal places
        uint256 precision = 100;
        uint256 percentage = (numerator * precision) / denominator;
        
        // Convert the percentage to a string with 2 decimal places
        string memory result = formatDecimal(percentage);
        return result;
    }

    function formatDecimal(uint256 number) internal pure returns (string memory) {
        // Calculate the divisor based on the decimal value
        uint256 divisor = 100;
        
        // Divide the number by the divisor to move the decimal point
        uint256 quotient = number / divisor;
        
        // Calculate the remainder after division
        uint256 remainder = number % divisor;
        
        // Convert the quotient and remainder to strings
        string memory quotientString = uintToString(quotient);
        string memory remainderString = uintToString(remainder);
        // Append leading zeros to the remainder if necessary
        remainderString = appendLeadingZeros(remainderString);
        
        // Handle the case when the number is a single digit
        if (quotient == 0) {
            quotientString = "0";
        }
        
        // Concatenate the strings with a dot (.) between them
        string memory formattedNumber = string(abi.encodePacked(quotientString, ".", remainderString));
        return formattedNumber;
    }
    
    // Helper function to convert uint to string
    function uintToString(uint256 number) internal pure returns (string memory) {
        if (number == 0) {
            return "0";
        }
        
        uint256 length;
        uint256 temp = number;
        
        while (temp != 0) {
            length++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(length);
        
        while (number != 0) {
            length -= 1;
            buffer[length] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        
        return string(buffer);
    }
    
    // Helper function to append leading zeros to a string
    function appendLeadingZeros(string memory str) internal pure returns (string memory) {
        uint256 length = bytes(str).length;
        if (length == 1){
            bytes memory buffer = new bytes(2);
            buffer[0] =  "0";
            buffer[1] = bytes(str)[0];
            return string(abi.encodePacked(buffer));
        } else {
            return str;
        }
    }

    function calculateRemainingTime(uint256 startTime) internal view returns (string memory) {
        require(startTime >= block.timestamp, "Invalid start time"); // Ensure startTime is in the future

        uint256 remainingTime = startTime - block.timestamp;
        
        uint256 daysRemaining = remainingTime / 1 days;
        remainingTime -= daysRemaining * 1 days;
        
        uint256 hoursRemaining = remainingTime / 1 hours;
        remainingTime -= hoursRemaining * 1 hours;
        
        uint256 minutesRemaining = remainingTime / 1 minutes;
        remainingTime -= minutesRemaining * 1 minutes;
        
        uint256 secondsRemaining = remainingTime;
        
        // Construct the remaining time string
        string memory timeString = string(abi.encodePacked(
            uintToString(daysRemaining), " days, ",
            uintToString(hoursRemaining), " hours, ",
            uintToString(minutesRemaining), " minutes, ",
            uintToString(secondsRemaining), " seconds"
        ));
        
        return timeString;
    }

}