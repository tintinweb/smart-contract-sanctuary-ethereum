/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PoofToken is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IDEXRouter private _dexRouter;

    mapping (address => uint) private _cooldown;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => bool) public humanVerified;

    bool public tradingOpen;
    bool private _swapping;
    bool public swapEnabled = false;
    bool public cooldownEnabled = false;
    bool public feesEnabled = true;
    bool public transferFeesEnabled = true;
    bool private humanVerificationRequired = true;

    uint256 private constant _tSupply = 100_000_000 ether;

    uint256 public maxBuyAmount = _tSupply;
    uint256 public maxSellAmount = _tSupply;
    uint256 public maxWalletAmount = _tSupply;

    uint256 public tradingOpenBlock = 0;
    uint256 private _blocksToBlacklist = 0;
    uint256 private _cooldownBlocks = 1;

    uint256 public constant FEE_DIVISOR = 1000;

    uint256 private _totalFees;
    uint256 private _marketingFee;
    uint256 private _dreamFee;
    uint256 private _liquidityFee;

    uint256 public buyMarketingFee = 20;
    uint256 private _previousBuyMarketingFee = buyMarketingFee;
    uint256 public buyDREAMFee = 10;
    uint256 private _previousBuyDREAMFee = buyDREAMFee;
    uint256 public buyLiquidityFee = 30;
    uint256 private _previousBuyLiquidityFee = buyLiquidityFee;

    uint256 public sellMarketingFee = 20;
    uint256 private _previousSellMktgFee = sellMarketingFee;
    uint256 public sellDREAMFee = 10;
    uint256 private _previousSellDevFee = sellDREAMFee;
    uint256 public sellLiquidityFee = 30;
    uint256 private _previousSellLiqFee = sellLiquidityFee;

    uint256 public transferMarketingFee = 20;
    uint256 private _previousTransferMarketingFee = transferMarketingFee;
    uint256 public transferDREAMFee = 10;
    uint256 private _previousTransferDREAMFee = transferDREAMFee;
    uint256 public transferLiquidityFee = 30;
    uint256 private _previousTransferLiquidityFee = transferLiquidityFee;

    uint256 private _tokensForMarketing;
    uint256 private _tokensForDREAM;
    uint256 private _tokensForLiquidity;
    uint256 private _swapTokensAtAmount = 0;

    address payable public marketingWalletAddress;
    address payable public dreamWalletAddress;
    address payable public liquidityWalletAddress;
    address private _signerAddress;

    address private _dexPair;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant private ZERO = 0x0000000000000000000000000000000000000000;

    enum TransactionType {
        BUY,
        SELL,
        TRANSFER
    }

    event OpenTrading(uint256 tradingOpenBlock, uint256 _blocksToBlacklist);
    event SetMaxBuyAmount(uint256 newMaxBuyAmount);
    event SetMaxSellAmount(uint256 newMaxSellAmount);
    event SetMaxWalletAmount(uint256 newMaxWalletAmount);
    event SetSwapTokensAtAmount(uint256 newSwapTokensAtAmount);
    event SetBuyFee(uint256 buyMarketingFee, uint256 buyDREAMFee, uint256 buyLiquidityFee);
	event SetSellFee(uint256 sellMarketingFee, uint256 sellDREAMFee, uint256 sellLiquidityFee);
    event SetTransferFee(uint256 transferMarketingFee, uint256 transferDREAMFee, uint256 transferLiquidityFee);
    event VerifyHuman(address signer);
    
    constructor (address payable _marketingWalletAddress, address payable _dreamWalletAddress, address payable _liquidityWalletAddress, address signerAddress) ERC20("Poof Token", "POOF") payable {
        require(_marketingWalletAddress != ZERO, "_marketingWalletAddress cannot be 0");
        require(_dreamWalletAddress != ZERO, "_dreamWalletAddress cannot be 0");
        require(_liquidityWalletAddress != ZERO, "_liquidityWalletAddress cannot be 0");
        require(signerAddress != ZERO, "_signerAddress cannot be 0");

        marketingWalletAddress = _marketingWalletAddress;
        dreamWalletAddress = _dreamWalletAddress;
        liquidityWalletAddress = _liquidityWalletAddress;
        _signerAddress = signerAddress;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[marketingWalletAddress] = true;
        _isExcludedFromFees[dreamWalletAddress] = true;
        _isExcludedFromFees[liquidityWalletAddress] = true;
        _isExcludedFromFees[_signerAddress] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;
        _isExcludedMaxTransactionAmount[marketingWalletAddress] = true;
        _isExcludedMaxTransactionAmount[dreamWalletAddress] = true;
        _isExcludedMaxTransactionAmount[liquidityWalletAddress] = true;
        _isExcludedMaxTransactionAmount[_signerAddress] = true;

        humanVerified[owner()] = true;
        humanVerified[address(this)] = true;
        humanVerified[DEAD] = true;
        humanVerified[marketingWalletAddress] = true;
        humanVerified[dreamWalletAddress] = true;
        humanVerified[liquidityWalletAddress] = true;
        humanVerified[_signerAddress] = true;

        _mint(address(this), _tSupply.mul(5).div(100));
        _mint(owner(), _tSupply.mul(95).div(100));
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        TransactionType txType = (from == _dexPair) ? TransactionType.BUY : (to == _dexPair) ? TransactionType.SELL : TransactionType.TRANSFER;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) {
            require(!_isBlacklisted[from] && !_isBlacklisted[to], "Blacklisted.");

            if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not allowed yet.");

            if (cooldownEnabled) {
                if (to != address(_dexRouter) && to != address(_dexPair)) {
                    require(_cooldown[tx.origin] < block.number - _cooldownBlocks && _cooldown[to] < block.number - _cooldownBlocks, "Transfer delay enabled. Try again later.");
                    _cooldown[tx.origin] = block.number;
                    _cooldown[to] = block.number;
                }
            }

            if (txType == TransactionType.BUY && to != address(_dexRouter) && !_isExcludedMaxTransactionAmount[to]) {
                if (humanVerificationRequired) require(humanVerified[to] == true, "Human not verified.");
                
                require(amount <= maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (txType == TransactionType.SELL && from != address(_dexRouter) && !_isExcludedMaxTransactionAmount[from]) require(amount <= maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !feesEnabled || (!transferFeesEnabled && txType == TransactionType.TRANSFER)) takeFee = false;

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = (contractBalance > _swapTokensAtAmount) && (txType == TransactionType.SELL);

        if (canSwap && swapEnabled && !_swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            _swapping = true;
            _swapBack(contractBalance);
            _swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee, txType);
    }

    function _swapBack(uint256 contractBalance) internal {
        uint256 totalTokensToSwap =  _tokensForMarketing.add(_tokensForDREAM).add(_tokensForLiquidity);
        bool success;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) return;

        if (contractBalance > _swapTokensAtAmount.mul(5)) contractBalance = _swapTokensAtAmount.mul(5);

        uint256 liquidityTokens = contractBalance.mul(_tokensForLiquidity).div(totalTokensToSwap).div(2);
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForETH(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMktg = ethBalance.mul(_tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(_tokensForDREAM).div(totalTokensToSwap);
        uint256 ethForLiq = ethBalance.sub(ethForMktg).sub(ethForDev);
        
        _tokensForMarketing = 0;
        _tokensForDREAM = 0;
        _tokensForLiquidity = 0;

        if(liquidityTokens > 0 && ethForLiq > 0) _addLiquidity(liquidityTokens, ethForLiq);

        (success,) = address(dreamWalletAddress).call{value: ethForDev}("");
        (success,) = address(marketingWalletAddress).call{value: address(this).balance}("");
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWalletAddress,
            block.timestamp
        );
    }
        
    function _sendETHToFee(uint256 amount) internal {
        marketingWalletAddress.transfer(amount.div(2));
        dreamWalletAddress.transfer(amount.div(2));
    }

    function isBlacklisted(address wallet) external view returns (bool) {
        return _isBlacklisted[wallet];
    }

    function openTrading(uint256 blocks) public onlyOwner {
        require(!tradingOpen, "Trading is already open");
        require(blocks <= 10, "Invalid blocks count.");

        if (block.chainid == 1 || block.chainid == 5) _dexRouter = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH: Uniswap V2
        else if (block.chainid == 56) _dexRouter = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // ETH Chain: PCS V2
        else if (block.chainid == 97) _dexRouter = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // ETH Chain Testnet: PCS V2
        else if (block.chainid == 137 || block.chainid == 80001) _dexRouter = IDEXRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff); // Polygon: Quickswap 
        else revert("Chain not set.");

        _approve(address(this), address(_dexRouter), totalSupply());
        _dexPair = IDEXFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _dexRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_dexPair).approve(address(_dexRouter), type(uint).max);

        maxBuyAmount = totalSupply().mul(2).div(1000);
        maxSellAmount = totalSupply().mul(2).div(1000);
        maxWalletAmount = totalSupply().mul(1).div(100);
        _swapTokensAtAmount = totalSupply().mul(2).div(10000);
        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;
        tradingOpenBlock = block.number;
        _blocksToBlacklist = blocks;
        emit OpenTrading(tradingOpenBlock, _blocksToBlacklist);
    }

    function setCooldownEnabled(bool onoff) public onlyOwner {
        cooldownEnabled = onoff;
    }

    function setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function setFeesEnabled(bool onoff) public onlyOwner {
        feesEnabled = onoff;
    }

    function setTransferFeesEnabled(bool onoff) public onlyOwner {
        transferFeesEnabled = onoff;
    }

    function setHumanVerificationRequired(bool onoff) public onlyOwner {
        humanVerificationRequired = onoff;
    }

    function setMaxBuyAmount(uint256 _maxBuyAmount) public onlyOwner {
        require(_maxBuyAmount >= (totalSupply().mul(1).div(1000)), "Max buy amount cannot be lower than 0.1% total supply.");
        maxBuyAmount = _maxBuyAmount;
        emit SetMaxBuyAmount(maxBuyAmount);
    }

    function setMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(_maxSellAmount >= (totalSupply().mul(1).div(1000)), "Max sell amount cannot be lower than 0.1% total supply.");
        maxSellAmount = _maxSellAmount;
        emit SetMaxSellAmount(maxSellAmount);
    }
    
    function setMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        require(_maxWalletAmount >= (totalSupply().mul(1).div(1000)), "Max wallet amount cannot be lower than 0.1% total supply.");
        maxWalletAmount = _maxWalletAmount;
        emit SetMaxWalletAmount(maxWalletAmount);
    }
    
    function setSwapTokensAtAmount(uint256 swapTokensAtAmount) public onlyOwner {
        require(swapTokensAtAmount >= (totalSupply().mul(1).div(1000000)), "Swap amount cannot be lower than 0.0001% total supply.");
        require(swapTokensAtAmount <= (totalSupply().mul(5).div(1000)), "Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = swapTokensAtAmount;
        emit SetSwapTokensAtAmount(_swapTokensAtAmount);
    }

    function setMarketingWalletAddress(address _marketingWalletAddress) public onlyOwner {
        require(_marketingWalletAddress != ZERO, "marketingWalletAddress cannot be 0");
        _isExcludedFromFees[marketingWalletAddress] = false;
        _isExcludedMaxTransactionAmount[marketingWalletAddress] = false;
        marketingWalletAddress = payable(_marketingWalletAddress);
        _isExcludedFromFees[marketingWalletAddress] = true;
        _isExcludedMaxTransactionAmount[marketingWalletAddress] = true;
    }

    function setDREAMWalletAddress(address _dreamWalletAddress) public onlyOwner {
        require(_dreamWalletAddress != ZERO, "dreamWalletAddress cannot be 0");
        _isExcludedFromFees[dreamWalletAddress] = false;
        _isExcludedMaxTransactionAmount[dreamWalletAddress] = false;
        dreamWalletAddress = payable(_dreamWalletAddress);
        _isExcludedFromFees[dreamWalletAddress] = true;
        _isExcludedMaxTransactionAmount[dreamWalletAddress] = true;
    }

    function setLiquidityWalletAddress(address _liquidityWalletAddress) public onlyOwner {
        require(_liquidityWalletAddress != ZERO, "liquidityWalletAddress cannot be 0");
        _isExcludedFromFees[liquidityWalletAddress] = false;
        _isExcludedMaxTransactionAmount[liquidityWalletAddress] = false;
        liquidityWalletAddress = payable(_liquidityWalletAddress);
        _isExcludedFromFees[liquidityWalletAddress] = true;
        _isExcludedMaxTransactionAmount[liquidityWalletAddress] = true;
    }

    function setSignerAddress(address signerAddress) public onlyOwner {
        require(signerAddress != ZERO, "_signerAddress cannot be 0");
        _signerAddress = signerAddress;
    }

    function setExcludedFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = isEx;
    }
    
    function setExcludeFromMaxTransaction(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedMaxTransactionAmount[accounts[i]] = isEx;
    }
    
    function setBlacklisted(address[] memory accounts, bool isBL) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            if((accounts[i] != _dexPair) && (accounts[i] != address(_dexRouter)) && (accounts[i] != address(this))) _isBlacklisted[accounts[i]] = isBL;
        }
    }

    function setBuyFee(uint256 _buyMarketingFee, uint256 _buyDREAMFee, uint256 _buyLiquidityFee) public onlyOwner {
        require(_buyMarketingFee.add(_buyDREAMFee).add(_buyLiquidityFee) <= 120, "Must keep buy taxes below 12%");
        buyMarketingFee = _buyMarketingFee;
        buyDREAMFee = _buyDREAMFee;
        buyLiquidityFee = _buyLiquidityFee;
        emit SetBuyFee(buyMarketingFee, buyDREAMFee, buyLiquidityFee);
    }

    function setSellFee(uint256 _sellMarketingFee, uint256 _sellDREAMFee, uint256 _sellLiquidityFee) public onlyOwner {
        require(_sellMarketingFee.add(_sellDREAMFee).add(_sellLiquidityFee) <= 120, "Must keep sell taxes below 12%");
        sellMarketingFee = _sellMarketingFee;
        sellDREAMFee = _sellDREAMFee;
        sellLiquidityFee = _sellLiquidityFee;
        emit SetSellFee(sellMarketingFee, sellDREAMFee, sellLiquidityFee);
    }

    function setTransferFee(uint256 _transferMarketingFee, uint256 _transferDREAMFee, uint256 _transferLiquidityFee) public onlyOwner {
        require(_transferMarketingFee.add(_transferDREAMFee).add(_transferLiquidityFee) <= 250, "Must keep transfer taxes below 25%");
        transferMarketingFee = _transferMarketingFee;
        transferDREAMFee = _transferDREAMFee;
        transferLiquidityFee = _transferLiquidityFee;
        emit SetTransferFee(transferMarketingFee, transferDREAMFee, transferLiquidityFee);
    }

    function setCooldownBlocks(uint256 blocks) public onlyOwner {
        require(blocks <= 10, "Invalid blocks count.");
        _cooldownBlocks = blocks;
    }

    function _removeAllFee() internal {
        if (buyMarketingFee == 0 && buyDREAMFee == 0 && buyLiquidityFee == 0 && 
        sellMarketingFee == 0 && sellDREAMFee == 0 && sellLiquidityFee == 0 &&
        transferMarketingFee == 0 && transferDREAMFee == 0 && transferLiquidityFee == 0) return;

        _previousBuyMarketingFee = buyMarketingFee;
        _previousBuyDREAMFee = buyDREAMFee;
        _previousBuyLiquidityFee = buyLiquidityFee;
        _previousSellMktgFee = sellMarketingFee;
        _previousSellDevFee = sellDREAMFee;
        _previousSellLiqFee = sellLiquidityFee;
        _previousTransferMarketingFee = transferMarketingFee;
        _previousTransferDREAMFee = transferDREAMFee;
        _previousTransferLiquidityFee = transferLiquidityFee;
        
        buyMarketingFee = 0;
        buyDREAMFee = 0;
        buyLiquidityFee = 0;
        sellMarketingFee = 0;
        sellDREAMFee = 0;
        sellLiquidityFee = 0;
        transferMarketingFee = 0;
        transferDREAMFee = 0;
        transferLiquidityFee = 0;
    }
    
    function _restoreAllFee() internal {
        buyMarketingFee = _previousBuyMarketingFee;
        buyDREAMFee = _previousBuyDREAMFee;
        buyLiquidityFee = _previousBuyLiquidityFee;
        sellMarketingFee = _previousSellMktgFee;
        sellDREAMFee = _previousSellDevFee;
        sellLiquidityFee = _previousSellLiqFee;
        transferMarketingFee = _previousTransferMarketingFee;
        transferDREAMFee = _previousTransferDREAMFee;
        transferLiquidityFee = _previousTransferLiquidityFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, TransactionType txType) internal {
        if (!takeFee) _removeAllFee();
        else amount = _takeFees(sender, amount, txType);

        super._transfer(sender, recipient, amount);
        
        if (!takeFee) _restoreAllFee();
    }

    function _takeFees(address sender, uint256 amount, TransactionType txType) internal returns (uint256) {
        if(tradingOpenBlock + _blocksToBlacklist >= block.number) _setBot();
        else if (txType == TransactionType.SELL) _setSell();
        else if (txType == TransactionType.BUY) _setBuy();
        else if (txType == TransactionType.TRANSFER) _setTransfer();
        else revert("Invalid transaction type.");
        
        uint256 fees;
        if (_totalFees > 0) {
            fees = amount.mul(_totalFees).div(FEE_DIVISOR);
            _tokensForMarketing += fees * _marketingFee / _totalFees;
            _tokensForDREAM += fees * _dreamFee / _totalFees;
            _tokensForLiquidity += fees * _liquidityFee / _totalFees;
        }

        if (fees > 0) super._transfer(sender, address(this), fees);

        return amount -= fees;
    }

    function _setBot() internal {
        _marketingFee = 333;
        _dreamFee = 333;
        _liquidityFee = 333;
        _totalFees = _marketingFee.add(_dreamFee).add(_liquidityFee);
    }

    function _setSell() internal {
        _marketingFee = sellMarketingFee;
        _dreamFee = sellDREAMFee;
        _liquidityFee = sellLiquidityFee;
        _totalFees = _marketingFee.add(_dreamFee).add(_liquidityFee);
    }

    function _setBuy() internal {
        _marketingFee = buyMarketingFee;
        _dreamFee = buyDREAMFee;
        _liquidityFee = buyLiquidityFee;
        _totalFees = _marketingFee.add(_dreamFee).add(_liquidityFee);
    }

    function _setTransfer() internal {
        _marketingFee = transferMarketingFee;
        _dreamFee = transferDREAMFee;
        _liquidityFee = transferLiquidityFee;
        _totalFees = _marketingFee.add(_dreamFee).add(_liquidityFee);
    }
    
    function unclog() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        _swapTokensForETH(contractBalance);
    }
    
    function distributeFees() public onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        _sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        require(tkn != address(this), "Cannot withdraw own token");
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function removeLimits() public onlyOwner {
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWalletAmount = totalSupply();
        cooldownEnabled = false;
    }

    function verifyHuman(uint8 _v, bytes32 _r, bytes32 _s) public {
        require(tradingOpen, "Trading is not allowed yet.");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(address(this), _msgSender(), "POOF!"));
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address recovered = ecrecover(prefixedHash, _v, _r, _s);

        if (recovered == _signerAddress) {
            humanVerified[_msgSender()] = true;
            emit VerifyHuman(_msgSender());
        } else {
            revert("Human not verified.");
        }
    }

    receive() external payable {}
    fallback() external payable {}

}