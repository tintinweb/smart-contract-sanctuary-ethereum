/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

// File: Rastacoin.sol


pragma solidity ^0.8.7;

// Import OpenZeppelin Libraries





contract Token is ERC20, ERC20Burnable, Ownable {

    bool mintCompleted = false;

    constructor() ERC20("RastaCoin", "RCOIN") {}

    function mint(address stakingVestingContractAddress, 
                address teamVestingContractAddress,
                address marketingVestingContractAddress,
                address advisorVestingContractAddress,
                address liquidityContractAddress,
                address partnershipsVestingContractAddress) external onlyOwner {
        
        require(mintCompleted == false, "Mint already completed");

        // Pre-sales, ICO and Whitelist Tokens for Distribution
        _mint(0xcA918d355Bfb9b554B1D513fa1b0D4Df97A4B96a, 6000000000000000000000000);

        // Mint Staking Incentives Tokens with vesting over 10 years - 
        _mint(stakingVestingContractAddress, 8000000000000000000000000);

        // Mint Team and Founders Tokens with vesting over 5 years
        _mint(teamVestingContractAddress, 4000000000000000000000000);

        // Mint Marketing Tokens with vesting over 5 years
        _mint(marketingVestingContractAddress, 6000000000000000000000000);

        // Mint Advisor Tokens with vesting over 5 years
        _mint(advisorVestingContractAddress, 2000000000000000000000000);

        // Liquidity and tokens for DEX and Exchange Listing with vesting over 2 years
        _mint(liquidityContractAddress, 8000000000000000000000000);

        // Mint Tokens  Reserved for Institucional Investor and Strategic Partnerships 
        _mint(partnershipsVestingContractAddress, 6000000000000000000000000);

        mintCompleted = true;
    }
}




/** 
 *  Start of Vesting contracts. 
 *  Six different contracts with same code changing only variables names 
 *  for _beneficiaries, _tokenAmounts, _releaseTimes, _releasePercentages



/**
 * Staking vesting contract. Tokens released over 10 years.
 * 
 */
contract StakingVesting {
    using SafeMath for uint256;
    // ERC20 basic token contract being held
    address public immutable tokenAddress;

    uint256 public totalTokensRequired;
    
    // beneficiary of tokens after they are released
    mapping(address => uint256) public tokenAmounts;

    // beneficiary of tokens after they are released
    mapping(address => uint256) public totalPercentageWithdrawn;

    // struct to store the vesting release timestamps (in unix format) and the respective release percentages
    struct Vest {
        uint256 releaseTime;
        uint256 releasePercentage;
    }

    // struct instance to store the vesting variables
    Vest[10] public vesting_array;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        address _token,
        address[] memory _beneficiaries,
        uint256[] memory _tokenAmounts,
        uint256[] memory _releaseTimes,
        uint256[] memory _releasePercentages
    ) {
        require(_releaseTimes[0] > block.timestamp, "TokenTimelock: release time is before current time"); // check if the first vesting release time is greater than timestamp for current block 
        require(_beneficiaries.length == _tokenAmounts.length); // check if each beneficiary has a corresponding tokenAmount
        require(_releaseTimes.length == _releasePercentages.length); // check if each releaseTime has a corresponding release percentage
        require(_token != address(0)); // check if the token address is a valid contract address

        tokenAddress = _token; // record the contract address for the tokens being vested

        uint8 maxLen = _tokenAmounts.length > _releaseTimes.length ? uint8(_tokenAmounts.length) : uint8(_releaseTimes.length); // variable to avoid two different loops
        for (uint8 i = 0; i < maxLen; i++) {

            if(i < _tokenAmounts.length) { // check if the complete token Beneficiary arrays have been completely recorded
                require(_tokenAmounts[i] > 0 && _beneficiaries[i] != address(0)); // check if all beneficiaries are valid addresses and token amounts are valid
                tokenAmounts[_beneficiaries[i]] = _tokenAmounts[i]; // record total tokenAmounts for each beneficiary
                totalTokensRequired = totalTokensRequired.add(_tokenAmounts[i]); // record Total Tokens Required as a sum of token amounts for all beneficiaries
            } 

            if(i < _releaseTimes.length) { // check if the vesting arrays have been completely recorded
                require(_releasePercentages[i] > 0); // check if the vesting release percentage is a valid number
                if (i != 0) {
                    require(_releaseTimes[i] > _releaseTimes[i-1]); // check if all vesting release times are in ascending order, i.e. year 1, year 2, etc.
                }
                vesting_array[i].releaseTime = _releaseTimes[i]; // record the vesting release times
                vesting_array[i].releasePercentage = _releasePercentages[i]; // record the vesting release percentages
            }
        }
    }
    
    function fundingComplete() public view returns (bool) { // function to check if the vesting contract has the total tokens required for withdrawal later. Contract is invalid if this is not true (only until before the first vesting release time) 
        return Token(tokenAddress).balanceOf(address(this)) == totalTokensRequired;
    }

    function currentVestingRelease() public view returns (uint256 vestingPercentage) { //function to check the current vesting release percentage. Consecutive vesting percentages keep adding up as each vesting period elapses
        for (uint8 i = 0; i < vesting_array.length; i++) {
            if (block.timestamp > vesting_array[i].releaseTime) {
                vestingPercentage = vestingPercentage.add(vesting_array[i].releasePercentage); // at year 2, user should be able to retrieve vested tokens for year 1 + year 2
            }
        }
        return vestingPercentage;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        uint256 releasePercentage = currentVestingRelease().sub(totalPercentageWithdrawn[msg.sender]); // check how much the beneficiary has already withdrawn, and only allow retrival of remaining amount
        require(releasePercentage > 0, "TokenTimelock: current time is before release time"); // release percerntage is 0 when the vesting period hasnt started yet.
        require(totalPercentageWithdrawn[msg.sender] < 100, "TokenTimelock: no tokens to release"); // check if the user has any tokens to withdraw

        uint256 amount = tokenAmounts[msg.sender].mul(releasePercentage).div(100); // calculate the token amount that the user can withdraw
        require(amount > 0, "TokenTimelock: no tokens to release"); // check if the user has any tokens to withdraw

        totalPercentageWithdrawn[msg.sender] = totalPercentageWithdrawn[msg.sender].add(releasePercentage); // record total vesting percentage that the beneficiary has already withdrawn
        Token(tokenAddress).transfer(msg.sender, amount); // Transfer the  vested token amount as per current release horizon to the beneficiary
    }
}




/**
 * Team and founders vesting contract. Tokens released over 5 years.
 * 
 */
contract TeamVesting {
    using SafeMath for uint256;
    // ERC20 basic token contract being held
    address public immutable tokenAddress;

    uint256 public totalTokensRequired;
    
    // beneficiary of tokens after they are released
    mapping(address => uint256) public tokenAmounts2;

    // beneficiary of tokens after they are released
    mapping(address => uint256) public totalPercentageWithdrawn;

    // struct to store the vesting release timestamps (in unix format) and the respective release percentages
    struct Vest {
        uint256 releaseTime;
        uint256 releasePercentage;
    }

    // struct instance to store the vesting variables
    Vest[10] public vesting_array;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        address _token,
        address[] memory _beneficiaries2,
        uint256[] memory _tokenAmounts2,
        uint256[] memory _releaseTimes2,
        uint256[] memory _releasePercentages2
    ) {
        require(_releaseTimes2[0] > block.timestamp, "TokenTimelock: release time is before current time"); // check if the first vesting release time is greater than timestamp for current block 
        require(_beneficiaries2.length == _tokenAmounts2.length); // check if each beneficiary has a corresponding tokenAmount
        require(_releaseTimes2.length == _releasePercentages2.length); // check if each releaseTime has a corresponding release percentage
        require(_token != address(0)); // check if the token address is a valid contract address

        tokenAddress = _token; // record the contract address for the tokens being vested

        uint8 maxLen = _tokenAmounts2.length > _releaseTimes2.length ? uint8(_tokenAmounts2.length) : uint8(_releaseTimes2.length); // variable to avoid two different loops
        for (uint8 i = 0; i < maxLen; i++) {

            if(i < _tokenAmounts2.length) { // check if the complete token Beneficiary arrays have been completely recorded
                require(_tokenAmounts2[i] > 0 && _beneficiaries2[i] != address(0)); // check if all beneficiaries are valid addresses and token amounts are valid
                tokenAmounts2[_beneficiaries2[i]] = _tokenAmounts2[i]; // record total tokenAmounts for each beneficiary
                totalTokensRequired = totalTokensRequired.add(_tokenAmounts2[i]); // record Total Tokens Required as a sum of token amounts for all beneficiaries
            } 

            if(i < _releaseTimes2.length) { // check if the vesting arrays have been completely recorded
                require(_releasePercentages2[i] > 0); // check if the vesting release percentage is a valid number
                if (i != 0) {
                    require(_releaseTimes2[i] > _releaseTimes2[i-1]); // check if all vesting release times are in ascending order, i.e. year 1, year 2, etc.
                }
                vesting_array[i].releaseTime = _releaseTimes2[i]; // record the vesting release times
                vesting_array[i].releasePercentage = _releasePercentages2[i]; // record the vesting release percentages
            }
        }
    }
    
    function fundingComplete() public view returns (bool) { // function to check if the vesting contract has the total tokens required for withdrawal later. Contract is invalid if this is not true (only until before the first vesting release time) 
        return Token(tokenAddress).balanceOf(address(this)) == totalTokensRequired;
    }

    function currentVestingRelease() public view returns (uint256 vestingPercentage) { //function to check the current vesting release percentage. Consecutive vesting percentages keep adding up as each vesting period elapses
        for (uint8 i = 0; i < vesting_array.length; i++) {
            if (block.timestamp > vesting_array[i].releaseTime) {
                vestingPercentage = vestingPercentage.add(vesting_array[i].releasePercentage); // at year 2, user should be able to retrieve vested tokens for year 1 + year 2
            }
        }
        return vestingPercentage;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        uint256 releasePercentage = currentVestingRelease().sub(totalPercentageWithdrawn[msg.sender]); // check how much the beneficiary has already withdrawn, and only allow retrival of remaining amount
        require(releasePercentage > 0, "TokenTimelock: current time is before release time"); // release percerntage is 0 when the vesting period hasnt started yet.
        require(totalPercentageWithdrawn[msg.sender] < 100, "TokenTimelock: no tokens to release"); // check if the user has any tokens to withdraw

        uint256 amount = tokenAmounts2[msg.sender].mul(releasePercentage).div(100); // calculate the token amount that the user can withdraw

        totalPercentageWithdrawn[msg.sender] = totalPercentageWithdrawn[msg.sender].add(releasePercentage); // record total vesting percentage that the beneficiary has already withdrawn
        Token(tokenAddress).transfer(msg.sender, amount); // Transfer the  vested token amount as per current release horizon to the beneficiary
    }
}






/**
 * Vesting contract for Tokens for Marketing, Affiliates and Airdrps . Tokens released over 5 years.
 * 
 */
contract MarketingVesting {
    using SafeMath for uint256;
    // ERC20 basic token contract being held
    address public immutable tokenAddress;

    uint256 public totalTokensRequired;
    
    // beneficiary of tokens after they are released
    mapping(address => uint256) public tokenAmounts3;

    // beneficiary of tokens after they are released
    mapping(address => uint256) public totalPercentageWithdrawn;

    // struct to store the vesting release timestamps (in unix format) and the respective release percentages
    struct Vest {
        uint256 releaseTime;
        uint256 releasePercentage;
    }

    // struct instance to store the vesting variables
    Vest[10] public vesting_array;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        address _token,
        address[] memory _beneficiaries3,
        uint256[] memory _tokenAmounts3,
        uint256[] memory _releaseTimes3,
        uint256[] memory _releasePercentages3
    ) {
        require(_releaseTimes3[0] > block.timestamp, "TokenTimelock: release time is before current time"); // check if the first vesting release time is greater than timestamp for current block 
        require(_beneficiaries3.length == _tokenAmounts3.length); // check if each beneficiary has a corresponding tokenAmount
        require(_releaseTimes3.length == _releasePercentages3.length); // check if each releaseTime has a corresponding release percentage
        require(_token != address(0)); // check if the token address is a valid contract address

        tokenAddress = _token; // record the contract address for the tokens being vested

        uint8 maxLen = _tokenAmounts3.length > _releaseTimes3.length ? uint8(_tokenAmounts3.length) : uint8(_releaseTimes3.length); // variable to avoid two different loops
        for (uint8 i = 0; i < maxLen; i++) {

            if(i < _tokenAmounts3.length) { // check if the complete token Beneficiary arrays have been completely recorded
                require(_tokenAmounts3[i] > 0 && _beneficiaries3[i] != address(0)); // check if all beneficiaries are valid addresses and token amounts are valid
                tokenAmounts3[_beneficiaries3[i]] = _tokenAmounts3[i]; // record total tokenAmounts for each beneficiary
                totalTokensRequired = totalTokensRequired.add(_tokenAmounts3[i]); // record Total Tokens Required as a sum of token amounts for all beneficiaries
            } 

            if(i < _releaseTimes3.length) { // check if the vesting arrays have been completely recorded
                require(_releasePercentages3[i] > 0); // check if the vesting release percentage is a valid number
                if (i != 0) {
                    require(_releaseTimes3[i] > _releaseTimes3[i-1]); // check if all vesting release times are in ascending order, i.e. year 1, year 2, etc.
                }
                vesting_array[i].releaseTime = _releaseTimes3[i]; // record the vesting release times
                vesting_array[i].releasePercentage = _releasePercentages3[i]; // record the vesting release percentages
            }
        }
    }
    
    function fundingComplete() public view returns (bool) { // function to check if the vesting contract has the total tokens required for withdrawal later. Contract is invalid if this is not true (only until before the first vesting release time) 
        return Token(tokenAddress).balanceOf(address(this)) == totalTokensRequired;
    }

    function currentVestingRelease() public view returns (uint256 vestingPercentage) { //function to check the current vesting release percentage. Consecutive vesting percentages keep adding up as each vesting period elapses
        for (uint8 i = 0; i < vesting_array.length; i++) {
            if (block.timestamp > vesting_array[i].releaseTime) {
                vestingPercentage = vestingPercentage.add(vesting_array[i].releasePercentage); // at year 2, user should be able to retrieve vested tokens for year 1 + year 2
            }
        }
        return vestingPercentage;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        uint256 releasePercentage = currentVestingRelease().sub(totalPercentageWithdrawn[msg.sender]); // check how much the beneficiary has already withdrawn, and only allow retrival of remaining amount
        require(releasePercentage > 0, "TokenTimelock: current time is before release time"); // release percerntage is 0 when the vesting period hasnt started yet.
        require(totalPercentageWithdrawn[msg.sender] < 100, "TokenTimelock: no tokens to release"); // check if the user has any tokens to withdraw

        uint256 amount = tokenAmounts3[msg.sender].mul(releasePercentage).div(100); // calculate the token amount that the user can withdraw

        totalPercentageWithdrawn[msg.sender] = totalPercentageWithdrawn[msg.sender].add(releasePercentage); // record total vesting percentage that the beneficiary has already withdrawn
        Token(tokenAddress).transfer(msg.sender, amount); // Transfer the  vested token amount as per current release horizon to the beneficiary
    }
}






/**
 * Vesting contract for Advisor Tokens. Tokens released over 5 years.
 * 
 */

contract AdvisorVesting {
    using SafeMath for uint256;
    // ERC20 basic token contract being held
    address public immutable tokenAddress;

    uint256 public totalTokensRequired;
    
    // beneficiary of tokens after they are released
    mapping(address => uint256) public tokenAmounts4;

    // beneficiary of tokens after they are released
    mapping(address => uint256) public totalPercentageWithdrawn;

    // struct to store the vesting release timestamps (in unix format) and the respective release percentages
    struct Vest {
        uint256 releaseTime;
        uint256 releasePercentage;
    }

    // struct instance to store the vesting variables
    Vest[10] public vesting_array;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        address _token,
        address[] memory _beneficiaries4,
        uint256[] memory _tokenAmounts4,
        uint256[] memory _releaseTimes4,
        uint256[] memory _releasePercentages4
    ) {
        require(_releaseTimes4[0] > block.timestamp, "TokenTimelock: release time is before current time"); // check if the first vesting release time is greater than timestamp for current block 
        require(_beneficiaries4.length == _tokenAmounts4.length); // check if each beneficiary has a corresponding tokenAmount
        require(_releaseTimes4.length == _releasePercentages4.length); // check if each releaseTime has a corresponding release percentage
        require(_token != address(0)); // check if the token address is a valid contract address

        tokenAddress = _token; // record the contract address for the tokens being vested

        uint8 maxLen = _tokenAmounts4.length > _releaseTimes4.length ? uint8(_tokenAmounts4.length) : uint8(_releaseTimes4.length); // variable to avoid two different loops
        for (uint8 i = 0; i < maxLen; i++) {

            if(i < _tokenAmounts4.length) { // check if the complete token Beneficiary arrays have been completely recorded
                require(_tokenAmounts4[i] > 0 && _beneficiaries4[i] != address(0)); // check if all beneficiaries are valid addresses and token amounts are valid
                tokenAmounts4[_beneficiaries4[i]] = _tokenAmounts4[i]; // record total tokenAmounts for each beneficiary
                totalTokensRequired = totalTokensRequired.add(_tokenAmounts4[i]); // record Total Tokens Required as a sum of token amounts for all beneficiaries
            } 

            if(i < _releaseTimes4.length) { // check if the vesting arrays have been completely recorded
                require(_releasePercentages4[i] > 0); // check if the vesting release percentage is a valid number
                if (i != 0) {
                    require(_releaseTimes4[i] > _releaseTimes4[i-1]); // check if all vesting release times are in ascending order, i.e. year 1, year 2, etc.
                }
                vesting_array[i].releaseTime = _releaseTimes4[i]; // record the vesting release times
                vesting_array[i].releasePercentage = _releasePercentages4[i]; // record the vesting release percentages
            }
        }
    }
    
    function fundingComplete() public view returns (bool) { // function to check if the vesting contract has the total tokens required for withdrawal later. Contract is invalid if this is not true (only until before the first vesting release time) 
        return Token(tokenAddress).balanceOf(address(this)) == totalTokensRequired;
    }

    function currentVestingRelease() public view returns (uint256 vestingPercentage) { //function to check the current vesting release percentage. Consecutive vesting percentages keep adding up as each vesting period elapses
        for (uint8 i = 0; i < vesting_array.length; i++) {
            if (block.timestamp > vesting_array[i].releaseTime) {
                vestingPercentage = vestingPercentage.add(vesting_array[i].releasePercentage); // at year 2, user should be able to retrieve vested tokens for year 1 + year 2
            }
        }
        return vestingPercentage;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        uint256 releasePercentage = currentVestingRelease().sub(totalPercentageWithdrawn[msg.sender]); // check how much the beneficiary has already withdrawn, and only allow retrival of remaining amount
        require(releasePercentage > 0, "TokenTimelock: current time is before release time"); // release percerntage is 0 when the vesting period hasnt started yet.
        require(totalPercentageWithdrawn[msg.sender] < 100, "TokenTimelock: no tokens to release"); // check if the user has any tokens to withdraw

        uint256 amount = tokenAmounts4[msg.sender].mul(releasePercentage).div(100); // calculate the token amount that the user can withdraw

        totalPercentageWithdrawn[msg.sender] = totalPercentageWithdrawn[msg.sender].add(releasePercentage); // record total vesting percentage that the beneficiary has already withdrawn
        Token(tokenAddress).transfer(msg.sender, amount); // Transfer the  vested token amount as per current release horizon to the beneficiary
    }
}



/**
 * Pre-sales vesting contract. Tokens released over 1 years.
 * 
 */
contract LiquidityVesting {
    using SafeMath for uint256;
    // ERC20 basic token contract being held
    address public immutable tokenAddress;

    uint256 public totalTokensRequired;
    
    // beneficiary of tokens after they are released
    mapping(address => uint256) public tokenAmounts5;

    // beneficiary of tokens after they are released
    mapping(address => uint256) public totalPercentageWithdrawn;

    // struct to store the vesting release timestamps (in unix format) and the respective release percentages
    struct Vest {
        uint256 releaseTime;
        uint256 releasePercentage;
    }

    // struct instance to store the vesting variables
    Vest[10] public vesting_array;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        address _token,
        address[] memory _beneficiaries5,
        uint256[] memory _tokenAmounts5,
        uint256[] memory _releaseTimes5,
        uint256[] memory _releasePercentages5
    ) {
        require(_releaseTimes5[0] > block.timestamp, "TokenTimelock: release time is before current time"); // check if the first vesting release time is greater than timestamp for current block 
        require(_beneficiaries5.length == _tokenAmounts5.length); // check if each beneficiary has a corresponding tokenAmount
        require(_releaseTimes5.length == _releasePercentages5.length); // check if each releaseTime has a corresponding release percentage
        require(_token != address(0)); // check if the token address is a valid contract address

        tokenAddress = _token; // record the contract address for the tokens being vested

        uint8 maxLen = _tokenAmounts5.length > _releaseTimes5.length ? uint8(_tokenAmounts5.length) : uint8(_releaseTimes5.length); // variable to avoid two different loops
        for (uint8 i = 0; i < maxLen; i++) {

            if(i < _tokenAmounts5.length) { // check if the complete token Beneficiary arrays have been completely recorded
                require(_tokenAmounts5[i] > 0 && _beneficiaries5[i] != address(0)); // check if all beneficiaries are valid addresses and token amounts are valid
                tokenAmounts5[_beneficiaries5[i]] = _tokenAmounts5[i]; // record total tokenAmounts for each beneficiary
                totalTokensRequired = totalTokensRequired.add(_tokenAmounts5[i]); // record Total Tokens Required as a sum of token amounts for all beneficiaries
            } 

            if(i < _releaseTimes5.length) { // check if the vesting arrays have been completely recorded
                require(_releasePercentages5[i] > 0); // check if the vesting release percentage is a valid number
                if (i != 0) {
                    require(_releaseTimes5[i] > _releaseTimes5[i-1]); // check if all vesting release times are in ascending order, i.e. year 1, year 2, etc.
                }
                vesting_array[i].releaseTime = _releaseTimes5[i]; // record the vesting release times
                vesting_array[i].releasePercentage = _releasePercentages5[i]; // record the vesting release percentages
            }
        }
    }
    
    function fundingComplete() public view returns (bool) { // function to check if the vesting contract has the total tokens required for withdrawal later. Contract is invalid if this is not true (only until before the first vesting release time) 
        return Token(tokenAddress).balanceOf(address(this)) == totalTokensRequired;
    }

    function currentVestingRelease() public view returns (uint256 vestingPercentage) { //function to check the current vesting release percentage. Consecutive vesting percentages keep adding up as each vesting period elapses
        for (uint8 i = 0; i < vesting_array.length; i++) {
            if (block.timestamp > vesting_array[i].releaseTime) {
                vestingPercentage = vestingPercentage.add(vesting_array[i].releasePercentage); // at year 2, user should be able to retrieve vested tokens for year 1 + year 2
            }
        }
        return vestingPercentage;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        uint256 releasePercentage = currentVestingRelease().sub(totalPercentageWithdrawn[msg.sender]); // check how much the beneficiary has already withdrawn, and only allow retrival of remaining amount
        require(releasePercentage > 0, "TokenTimelock: current time is before release time"); // release percerntage is 0 when the vesting period hasnt started yet.
        require(totalPercentageWithdrawn[msg.sender] < 100, "TokenTimelock: no tokens to release"); // check if the user has any tokens to withdraw

        uint256 amount = tokenAmounts5[msg.sender].mul(releasePercentage).div(100); // calculate the token amount that the user can withdraw

        totalPercentageWithdrawn[msg.sender] = totalPercentageWithdrawn[msg.sender].add(releasePercentage); // record total vesting percentage that the beneficiary has already withdrawn
        Token(tokenAddress).transfer(msg.sender, amount); // Transfer the  vested token amount as per current release horizon to the beneficiary
    }
}




/**
 * Vesting contract reserved for strategic partnerships. Tokens released over 2 years.
 * 
 */
contract PartnershipsVesting {
    using SafeMath for uint256;
    // ERC20 basic token contract being held
    address public immutable tokenAddress;

    uint256 public totalTokensRequired;
    
    // beneficiary of tokens after they are released
    mapping(address => uint256) public tokenAmounts6;

    // beneficiary of tokens after they are released
    mapping(address => uint256) public totalPercentageWithdrawn;

    // struct to store the vesting release timestamps (in unix format) and the respective release percentages
    struct Vest {
        uint256 releaseTime;
        uint256 releasePercentage;
    }

    // struct instance to store the vesting variables
    Vest[10] public vesting_array;

    /**
     * @dev Deploys a timelock instance that is able to hold the token specified, and will only release it to
     * `beneficiary_` when {release} is invoked after `releaseTime_`. The release time is specified as a Unix timestamp
     * (in seconds).
     */
    constructor(
        address _token,
        address[] memory _beneficiaries6,
        uint256[] memory _tokenAmounts6,
        uint256[] memory _releaseTimes6,
        uint256[] memory _releasePercentages6
    ) {
        require(_releaseTimes6[0] > block.timestamp, "TokenTimelock: release time is before current time"); // check if the first vesting release time is greater than timestamp for current block 
        require(_beneficiaries6.length == _tokenAmounts6.length); // check if each beneficiary has a corresponding tokenAmount
        require(_releaseTimes6.length == _releasePercentages6.length); // check if each releaseTime has a corresponding release percentage
        require(_token != address(0)); // check if the token address is a valid contract address

        tokenAddress = _token; // record the contract address for the tokens being vested

        uint8 maxLen = _tokenAmounts6.length > _releaseTimes6.length ? uint8(_tokenAmounts6.length) : uint8(_releaseTimes6.length); // variable to avoid two different loops
        for (uint8 i = 0; i < maxLen; i++) {

            if(i < _tokenAmounts6.length) { // check if the complete token Beneficiary arrays have been completely recorded
                require(_tokenAmounts6[i] > 0 && _beneficiaries6[i] != address(0)); // check if all beneficiaries are valid addresses and token amounts are valid
                tokenAmounts6[_beneficiaries6[i]] = _tokenAmounts6[i]; // record total tokenAmounts for each beneficiary
                totalTokensRequired = totalTokensRequired.add(_tokenAmounts6[i]); // record Total Tokens Required as a sum of token amounts for all beneficiaries
            } 

            if(i < _releaseTimes6.length) { // check if the vesting arrays have been completely recorded
                require(_releasePercentages6[i] > 0); // check if the vesting release percentage is a valid number
                if (i != 0) {
                    require(_releaseTimes6[i] > _releaseTimes6[i-1]); // check if all vesting release times are in ascending order, i.e. year 1, year 2, etc.
                }
                vesting_array[i].releaseTime = _releaseTimes6[i]; // record the vesting release times
                vesting_array[i].releasePercentage = _releasePercentages6[i]; // record the vesting release percentages
            }
        }
    }
    
    function fundingComplete() public view returns (bool) { // function to check if the vesting contract has the total tokens required for withdrawal later. Contract is invalid if this is not true (only until before the first vesting release time) 
        return Token(tokenAddress).balanceOf(address(this)) == totalTokensRequired;
    }

    function currentVestingRelease() public view returns (uint256 vestingPercentage) { //function to check the current vesting release percentage. Consecutive vesting percentages keep adding up as each vesting period elapses
        for (uint8 i = 0; i < vesting_array.length; i++) {
            if (block.timestamp > vesting_array[i].releaseTime) {
                vestingPercentage = vestingPercentage.add(vesting_array[i].releasePercentage); // at year 2, user should be able to retrieve vested tokens for year 1 + year 2
            }
        }
        return vestingPercentage;
    }

    /**
     * @dev Transfers tokens held by the timelock to the beneficiary. Will only succeed if invoked after the release
     * time.
     */
    function release() public virtual {
        uint256 releasePercentage = currentVestingRelease().sub(totalPercentageWithdrawn[msg.sender]); // check how much the beneficiary has already withdrawn, and only allow retrival of remaining amount
        require(releasePercentage > 0, "TokenTimelock: current time is before release time"); // release percerntage is 0 when the vesting period hasnt started yet.
        require(totalPercentageWithdrawn[msg.sender] < 100, "TokenTimelock: no tokens to release"); // check if the user has any tokens to withdraw

        uint256 amount = tokenAmounts6[msg.sender].mul(releasePercentage).div(100); // calculate the token amount that the user can withdraw

        totalPercentageWithdrawn[msg.sender] = totalPercentageWithdrawn[msg.sender].add(releasePercentage); // record total vesting percentage that the beneficiary has already withdrawn
        Token(tokenAddress).transfer(msg.sender, amount); // Transfer the  vested token amount as per current release horizon to the beneficiary
    }
}