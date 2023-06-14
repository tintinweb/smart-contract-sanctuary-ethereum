/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

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

// File: contracts/DBK.sol


pragma solidity ^0.8.18;



contract DBK is ERC20, Ownable{

    /* to check if destination address is 
    valid and not of this contract
    */
    modifier validDestination(address to) {
        require(to != address(this), "Not a valid address");
        _;
    }

    /**
     * @dev Constructor, which is a function that executes once (on deployment)
     */
    constructor() ERC20("DBK", "DBK") { }

    /**
     * @dev overriding transfer function to add validDestination modifier
     */
    function transfer(
        address to,
        uint256 value
    ) public override validDestination(to) returns (bool success) {
        return super.transfer(to, value);
    }

    /**
     * @dev overriding transferFrom function to add validDestination modifier
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override validDestination(to) returns (bool success) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @notice mints amount to the to address
     * @param to address of receiver
     * @param amount asset amount to transfer
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice burns amount of the to address
     * @param from address of the account to burn from
     * @param amount asset amount to burn
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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

// File: contracts/LiquidityPool.sol


pragma solidity ^0.8.18;




interface ChainlinkOraclePriceFeed {
    function latestAnswer() external view returns (int256);
}

contract LiquidityPool is Ownable {
    /**
     * @notice Safe guarding contract from integer
     * overflow and underflow vulnerabilities.
     */
    using SafeMath for uint256;

    /**
     * @notice Enum to specify the current state of loan repayment
     */
    enum Status {
        Pending,
        Paid,
        Claimed
    }

    /**
     * @notice struct to define the characteristics of a loan
     */
    struct LoanInfo {
        uint256 loanId;
        uint256 loanedAmount;
        uint256 collateralAmount;
        uint256 repayAmount;
        address tokenAddress;
        address collateralAddress;
        uint256 blockNumber;
        Status status;
    }

    /**
     * @notice struct to define the characteristics of a Deposit
     */
    struct DepositInfo {
        uint256 amount;
        uint256 blockNumber;
        uint256 totalInterestEarned;
    }

    /**
     * @notice struct for creating a new pool
     */
    struct Pool {
        address tokenAddress;
        uint256 tokensAvailable;
        uint256 tokensBorrowed;
        uint256 depositInterestRate;
        uint256 borrowInterestRate;
        uint256 depositInterestFactor;
        uint256 borrowInterestFactor;
    }

    /**
     * @notice mapping user address to token address to deposited amount
     */
    mapping(address => mapping(address => DepositInfo)) public userTokenBal;

    /**
     * @notice mapping user address to token address to user total locked balance
     */
    mapping(address => mapping(address => uint256)) public userTokenLockedBal;

    /**
     * @notice mapping user address to total loan count
     */
    mapping(address => uint256) public userLoanCount;

    /**
     * @notice keeps track pool associated with registered tokens
     */
    mapping(address => Pool) public pools;

    /**
     * @notice mapping user address to user loan data
     */
    mapping(address => LoanInfo[]) public userLoanData;

    /**
     * @notice keeps track of chainlink oracle addresses as per token pair
     */
    mapping(address => mapping(address => address))
        public tokenPairOracleAddresses;

    /**
     * @notice block time of the network
     */
    uint256 public blockTime;

    /**
     * @notice this variable stores the governance token address
     */
    DBK public dbk;

    /**
     * @notice this event is for - when a user deposits Tokens
     */
    event Deposited(
        address indexed depositor,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice this event is for - when a user borrows tokens
     */
    event Borrowed(
        address indexed borrower,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice this event is for - when a user repays a loan
     */
    event Repaid(
        address indexed borrower,
        uint256 indexed loanId,
        uint256 amount
    );

    /**
     * @notice this event is for - when a user withdraws tokens deposited
     */
    event LendedWithdrawn(
        address indexed depositor,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice this event is for - when a user withdraws collateral tokens
     */
    event CollateralWithdrawn(
        address indexed withdrawer,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice this event is for - when a user claims the interest on deposited tokens
     */
    event InterestClaimed(address indexed user, uint256 indexed amount);

    /**
     * @notice this event is for - when an admin register a new token
     */
    event TokenRegistered(address indexed token);

    /**
     * @notice this event is for - interestcalculation
     */
    event LoanInterest(uint256 pricipalAmount, uint256 interest);

    /**
     * @notice Constructor, which is a function that executes
     * once (on deployment) sets DBK tokens supply & block time
     * @param blockGenerationTime the time period for each block generation in seconds
     * @param wethAddress address of WETh token
     * @param usdcAddress address of USDC token
     */
    constructor(
        uint256 blockGenerationTime,
        address wethAddress,
        address usdcAddress
    ) {
        blockTime = blockGenerationTime; // 14 seconds for ethereum chain
        dbk = new DBK();
        tokenPairOracleAddresses[wethAddress][
            usdcAddress
        ] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    }

    /**
     * @notice Update block time
     * @param newValue value of block time
     * @return success true if success
     */
    function updateBlocktime(
        uint256 newValue
    ) external onlyOwner returns (bool success) {
        blockTime = newValue;
        return true;
    }

    /**
     * @notice set deposit interest constant
     * @param tokenAddress address of the token
     * @param depositIntFactor constant value
     */
    function setDepositInterestFactor(
        address tokenAddress,
        uint256 depositIntFactor
    ) external onlyOwner {
        pools[tokenAddress].depositInterestFactor = depositIntFactor;
    }

    /**
     * @notice set borrow interest constant
     * @param tokenAddress address of the token
     * @param borrowIntFactor constant value
     */
    function setBorrowInterestFactor(
        address tokenAddress,
        uint256 borrowIntFactor
    ) external onlyOwner {
        pools[tokenAddress].borrowInterestFactor = borrowIntFactor;
    }

    /**
     * @notice this function is used for registering a token
     * @param tokenAddress the address of the token
     */
    function registerToken(address tokenAddress) external onlyOwner {
        pools[tokenAddress] = Pool({
            tokenAddress: tokenAddress,
            tokensAvailable: 0,
            tokensBorrowed: 0,
            depositInterestRate: 0,
            borrowInterestRate: 0,
            depositInterestFactor: 2500,
            borrowInterestFactor: 3000
        });
        emit TokenRegistered(tokenAddress);
    }

    /**
     * @notice deposit ERC20 token to the pool
     * @param tokenAddress ERC20 token address
     * @param amount token deposited amount
     * @return success true if success
     */
    function deposit(
        address tokenAddress,
        uint256 amount
    ) public returns (bool success) {
        require(amount >= 10, "Minimum amount is 10");

        // take ERC 20 token from user
        success = ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (success) {
            uint256 balance = userTokenBal[msg.sender][tokenAddress].amount.add(
                amount
            );

            // update pool tokens availability
            pools[tokenAddress].tokensAvailable = pools[tokenAddress]
                .tokensAvailable
                .add(amount);

            // update deposit and borrow interest rate
            _updateBothInterestRate(tokenAddress);

            // update user token balance
            DepositInfo memory newDeposit = DepositInfo(
                balance,
                block.number,
                userTokenBal[msg.sender][tokenAddress].totalInterestEarned
            );

            userTokenBal[msg.sender][tokenAddress] = newDeposit;

            // transfer DBK tokens to user
            dbk.mint(msg.sender, amount.mul(10).div(100));
            emit Deposited(msg.sender, tokenAddress, amount);
        }

        return success;
    }

    /**
     * @notice Withdraw deposited ERC20 token
     * @param amount amount to be withdrawn
     * @param tokenAddress address of token
     * @return success true if success
     */
    function withdrawLendedAmount(
        uint256 amount,
        address tokenAddress
    ) public returns (bool success) {
        uint256 currentBalance = userTokenBal[msg.sender][tokenAddress].amount;

        require(currentBalance >= amount, "low balance");
        require(
            ERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Pool doesn't have enough tokens"
        );

        uint256 userBalance = dbk.balanceOf(msg.sender);
        uint256 amountToBurn = amount.mul(10).div(100);

        require(userBalance >= amountToBurn, "Doesn't have enough DBK tokens");

        // burn the governance tokens
        dbk.burn(msg.sender, amountToBurn);

        // update the user's balance with amount that will be withdrawn
        userTokenBal[msg.sender][tokenAddress].amount = currentBalance.sub(
            amount
        );

        // update token availability in the pool
        pools[tokenAddress].tokensAvailable = pools[tokenAddress]
            .tokensAvailable
            .sub(amount);

        // update deposit and borrow interest rate
        _updateBothInterestRate(tokenAddress);

        emit LendedWithdrawn(msg.sender, tokenAddress, amount);

        // transfer the tokens back to the user
        return ERC20(tokenAddress).transfer(msg.sender, amount);
    }

    /**
     * @notice Withdraw borrowed amount
     * @param loanId loan to be withdrawn
     */
    function withdrawCollateralAmount(uint256 loanId) public {
        Status status = userLoanData[msg.sender][loanId - 1].status;

        if (status == Status.Claimed) {
            revert("Loan amount already claimed");
        } else if (status == Status.Pending) {
            revert("Loan repayment pending");
        } else {
            uint256 amount = userLoanData[msg.sender][loanId - 1]
                .collateralAmount;
            address collateral = userLoanData[msg.sender][loanId - 1]
                .collateralAddress;

            require(
                ERC20(collateral).balanceOf(address(this)) >= amount,
                "Pool doesn't have enough tokens"
            );

            // update the locked amount for collateral provided
            userTokenLockedBal[msg.sender][collateral] = userTokenLockedBal[
                msg.sender
            ][collateral].sub(amount);

            ERC20(collateral).transfer(msg.sender, amount);

            emit CollateralWithdrawn(msg.sender, collateral, amount);
        }
    }

    /**
     * @notice claim interest on amount lended
     * @param tokenAddress address of token
     * @return success true if success
     */
    function claimInterest(
        address tokenAddress
    ) external returns (bool success) {
        uint256 oldInterest = userTokenBal[msg.sender][tokenAddress]
            .totalInterestEarned;
        uint256 currentBlockNumber = block.number;

        // duration in seconds from deposit block to this block
        uint256 duration = currentBlockNumber
            .sub(userTokenBal[msg.sender][tokenAddress].blockNumber)
            .mul(blockTime);

        // calculating interestby (principle * APR/100 * duration in seconds) / seconds in a year
        uint256 secondsInYear = uint256(36525).mul(86400).div(100);
        uint256 amount = userTokenBal[msg.sender][tokenAddress].amount;

        uint256 interest = oldInterest.add(
            amount
                .mul(duration)
                .mul(getDepositInterestRate(tokenAddress))
                .div(100)
                .div(secondsInYear)
        );

        require(interest > 0, "Interest amount is 0");

        require(
            ERC20(tokenAddress).balanceOf(address(this)) >= interest,
            "Pool doesn't have enough tokens"
        );

        // update token availability in the pool
        pools[tokenAddress].tokensAvailable = pools[tokenAddress]
            .tokensAvailable
            .sub(interest);

        // update interest to 0
        userTokenBal[msg.sender][tokenAddress].totalInterestEarned = 0;

        // update block number to the current block
        userTokenBal[msg.sender][tokenAddress].blockNumber = currentBlockNumber;

        // update deposit and borrow interest rate
        _updateBothInterestRate(tokenAddress);

        emit InterestClaimed(msg.sender, interest);

        // transfer the tokens back to the user
        return success = ERC20(tokenAddress).transfer(msg.sender, interest);
    }

    /**
     * @notice user take loan
     * @param amount loan amount
     * @param tokenAddress loan token address
     * @param collateralAddress collateral token address
     */
    function borrow(
        uint256 amount,
        address tokenAddress,
        address collateralAddress
    ) public returns (bool success) {
        address oracleAddress = tokenPairOracleAddresses[collateralAddress][
            tokenAddress
        ];

        require(oracleAddress != address(0), "Invalid token pair");

        // transfer collateral tokens from user to the pool
        require(
            ERC20(collateralAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Failed to transfer collateral tokens"
        );

        // fetch price feed from oracle
        // uint256 priceFetched = uint256(
        //     ChainlinkOraclePriceFeed(oracleAddress).latestAnswer()
        // );

        uint256 priceFetched = 180662042831;
        uint256 loanAmount = (priceFetched * 1000000 * amount) /
            (100000000 * 1000000000000000000);

        require(loanAmount > 0, "Loan amount you will get is 0");

        // check pool has sufficient amount
        require(
            ERC20(tokenAddress).balanceOf(address(this)) >= loanAmount,
            "Pool doesn't have enough tokens"
        );

        // update the locked amount for collateral provided
        userTokenLockedBal[msg.sender][collateralAddress] = userTokenLockedBal[
            msg.sender
        ][collateralAddress].add(amount);

        // update loan id
        userLoanCount[msg.sender] = userLoanCount[msg.sender].add(1);
        uint256 loanId = userLoanCount[msg.sender];

        // add loan information
        LoanInfo memory newLoan = LoanInfo(
            loanId,
            loanAmount,
            amount,
            0,
            tokenAddress,
            collateralAddress,
            block.number,
            Status.Pending
        );

        userLoanData[msg.sender].push(newLoan);

        // update tokens borrowed
        pools[tokenAddress].tokensBorrowed = pools[tokenAddress]
            .tokensBorrowed
            .add(loanAmount);

        // update tokens available
        pools[tokenAddress].tokensAvailable = pools[tokenAddress]
            .tokensAvailable
            .sub(loanAmount);

        // update deposit and borrow interest rate
        _updateBothInterestRate(tokenAddress);

        emit Borrowed(msg.sender, tokenAddress, loanAmount);
        return ERC20(tokenAddress).transfer(msg.sender, loanAmount);
    }

    /**
     * @notice loan repay function
     * @param loanId loan id
     */
    function repay(uint256 loanId) public returns (bool) {
        // check if loan is already paid
        require(
            userLoanData[msg.sender][loanId - 1].status != Status.Paid,
            "Loan already paid"
        );

        address tokenAddress = userLoanData[msg.sender][loanId - 1]
            .tokenAddress;

        uint256 loanAmount = userLoanData[msg.sender][loanId - 1].loanedAmount;

        // duration in seconds from loan block to this block
        uint256 duration = block
            .number
            .sub(userLoanData[msg.sender][loanId - 1].blockNumber)
            .mul(blockTime);

        // calculating interest by (principle * APR/100 * duration in seconds) / seconds in a year
        uint256 secondsInYear = uint256(36525).mul(86400).div(100);

        uint256 interest = (loanAmount)
            .mul(duration)
            .mul(getBorrowerInterestRate(tokenAddress))
            .div(100)
            .div(secondsInYear);

        // total interest to be paid
        uint256 interestAmount = (
            userLoanData[msg.sender][loanId - 1].repayAmount
        ).add(interest);

        // update the repay amount
        userLoanData[msg.sender][loanId - 1].repayAmount = interestAmount;

        // update the block number
        userLoanData[msg.sender][loanId - 1].blockNumber = block.number;

        // loan amount + total interest
        uint256 totalAmountPaid = loanAmount.add(interestAmount);

        // update tokens borrowed
        pools[tokenAddress].tokensBorrowed = pools[tokenAddress]
            .tokensBorrowed
            .sub(loanAmount);

        // update available tokens in the pool
        pools[tokenAddress].tokensAvailable = pools[tokenAddress]
            .tokensAvailable
            .add(totalAmountPaid);

        // update status to Paid
        userLoanData[msg.sender][loanId - 1].status = Status.Paid;

        emit Repaid(msg.sender, loanId, totalAmountPaid);

        return
            ERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                totalAmountPaid
            );
    }

    /**
     * @notice Get the latest interest rate
     * @param tokenAddress the address of the token
     */
    function _updateBothInterestRate(address tokenAddress) internal {
        uint256 depositInterestRate = (
            pools[tokenAddress].depositInterestFactor
        ).add(checkInterestInfo(tokenAddress).mul(2));

        uint256 borrowInterestRate = (pools[tokenAddress].borrowInterestFactor)
            .add(checkInterestInfo(tokenAddress).mul(2));

        // update deposit and borrow interest rate
        pools[tokenAddress].depositInterestRate = depositInterestRate;
        pools[tokenAddress].borrowInterestRate = borrowInterestRate;
    }

    /**
     * @notice Get the latest interest rate
     * @param tokenAddress the address of the token
     * @return utilityFactor the interest rate depends on supply and demand
     */
    function checkInterestInfo(
        address tokenAddress
    ) public view returns (uint256) {
        uint256 totalBalance = pools[tokenAddress].tokensAvailable;
        uint256 totalBorrow = pools[tokenAddress].tokensBorrowed;
        uint256 utilityFactor = (totalBorrow.mul(100)).div(
            totalBalance.add(totalBorrow)
        );
        return utilityFactor;
    }

    /**
     * @notice Get the latest interest rate
     * @param tokenAddress the address of the token
     * @return depositInterestRate for depositor
     */
    function getDepositInterestRate(
        address tokenAddress
    ) public view returns (uint256) {
        uint256 interestRate = (pools[tokenAddress].depositInterestFactor).add(
            checkInterestInfo(tokenAddress).mul(2)
        );
        return interestRate;
    }

    /**
     * @notice Get the latest interest rate
     * @param tokenAddress the address of the token
     * @return borrowInterestRate for borrower
     */
    function getBorrowerInterestRate(
        address tokenAddress
    ) public view returns (uint256) {
        uint256 interestRate = (pools[tokenAddress].borrowInterestFactor).add(
            checkInterestInfo(tokenAddress).mul(2)
        );
        return interestRate;
    }

    /**
     * @notice calculates depositor's interest
     * @param tokenAddress the address of the token
     * @return deposited amount, interest and current block number
     */
    function getDepositorInterest(
        address tokenAddress
    ) external view returns (uint256, uint256, uint256) {
        // duration in seconds from deposit block to this block
        uint256 duration = block
            .number
            .sub(userTokenBal[msg.sender][tokenAddress].blockNumber)
            .mul(blockTime);

        // calculating interestby (principle * APR/100 * duration in seconds) / seconds in a year
        uint256 secondsInYear = uint256(36525).mul(86400).div(100);
        uint256 amount = userTokenBal[msg.sender][tokenAddress].amount;

        uint256 interest = amount
            .mul(duration)
            .mul(getDepositInterestRate(tokenAddress))
            .div(100)
            .div(secondsInYear);

        return (
            amount,
            (
                userTokenBal[msg.sender][tokenAddress].totalInterestEarned.add(
                    interest
                )
            ),
            block.number
        );
    }

    /**
     * @notice calculates specific loan interest and borrowers's repay amount
     * @param loanId the Loan Id of the Loan
     * @param tokenAddress the address of the token
     * @return info loan details
     */
    function getLoanInterest(
        uint256 loanId,
        address tokenAddress
    ) external view returns (LoanInfo memory info) {
        // duration in seconds from loan block to this block
        uint256 duration = block
            .number
            .sub(userLoanData[msg.sender][loanId - 1].blockNumber)
            .mul(blockTime);

        // calculating interestby (principle * APR/100 * duration in seconds) / seconds in a year
        uint256 secondsInYear = uint256(36525).mul(86400).div(100);

        uint256 principle = userLoanData[msg.sender][loanId - 1].loanedAmount;

        uint256 interest = (principle)
            .mul(duration)
            .mul(getBorrowerInterestRate(tokenAddress))
            .div(100)
            .div(secondsInYear);

        info = userLoanData[msg.sender][loanId - 1];
        info.repayAmount = interest;
        info.blockNumber = block.number;

        return info;
    }

    /**
     * @notice Fetches current token pair price
     * @param collateralAddress the address of the collateral token
     * @param tokenAddress the address of the borrowing token
     * @return current price of collateral token
     */
    function getCurrentPriceOfToken(
        address collateralAddress,
        address tokenAddress
    ) public view returns (int256) {
        address oracleAddress = tokenPairOracleAddresses[collateralAddress][
            tokenAddress
        ];
        // fetch price feed from oracle
        return ChainlinkOraclePriceFeed(oracleAddress).latestAnswer();
        // return 180662042831;
    }

    /**
     * @notice Fetches current collateral tokens locked
     * @param token the address of the collateral token
     * @return collateral tokens locked
     */
    function collateralLocked(address token) external view returns (uint256) {
        return userTokenLockedBal[msg.sender][token];
    }

    /**
     * @notice Fetches deposited amount
     * @param token the address of the collateral token
     * @return deposit details
     */
    function fetchDepositDetails(
        address token
    ) external view returns (DepositInfo memory) {
        return userTokenBal[msg.sender][token];
    }

    /**
     * @notice Fetches pool details
     * @param token the address of token
     * @return pool details
     */
    function fetchPoolDetails(
        address token
    ) external view returns (Pool memory) {
        return pools[token];
    }
}