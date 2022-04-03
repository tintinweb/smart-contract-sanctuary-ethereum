// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IWhitelist.sol";
import "./interfaces/IReflectable.sol";

contract RETRO is ERC20, Ownable, IReflectable {
    using SafeMath for uint256;

    modifier lockSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd() {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Max buy amount in wei
    uint256 public buyLimit;
    /// @notice Cooldown in seconds
    uint256 public cooldown = 60;

    /// @notice Buy tax0 in BPS
    uint256 public buyTax0 = 1300;
    /// @notice Sell tax0 in BPS
    uint256 public sellTax0 = 2300;
    /// @notice Buy tax1 in BPS
    uint256 public buyTax1 = 100;
    /// @notice Sell tax1 in BPS
    uint256 public sellTax1 = 100;
    /// @notice Buy tax2 in BPS
    uint256 public buyTax2 = 100;
    /// @notice Sell tax2 in BPS
    uint256 public sellTax2 = 100;
    /// @notice Buy reflection tax in BPS
    uint256 public buyReflectionTax = 0;
    /// @notice Sell reflection tax in BPS
    uint256 public sellReflectionTax = 0;

    /// @notice Contract RETRO balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    bool public swapFees = true;

    /// @notice tokens that are allocated for tax0 tax
    uint256 public totalTax0;
    /// @notice tokens that are allocated for tax1 tax
    uint256 public totalTax1;
    /// @notice tokens that are allocated for tax2 tax
    uint256 public totalTax2;

    /// @notice Counter for all reflections collected
    uint256 public reflectionBasis;
    /// @notice Mapping of each user's last reflection basis
    mapping(address => uint256) public lastReflectionBasis;
    /// @notice Mapping of each user's owed reflections
    mapping(address => uint256) public override reflectionOwed;

    /// @notice address that tax0 is sent to
    address payable public tax0Wallet;
    /// @notice address that tax1 is sent to
    address payable public tax1Wallet;
    /// @notice address that tax2 is sent to
    address payable public tax2Wallet;

    uint256 internal _totalSupply = 0;
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    bool public tradingActive = false;

    IWhitelist public whitelist;

    mapping(address => uint256) private _balances;
    mapping(address => bool) public taxExcluded;
    mapping(address => uint256) public lastBuy;

    event Tax0WalletChanged(address previousWallet, address nextWallet);
    event Tax1WalletChanged(address previousWallet, address nextWallet);
    event Tax2WalletChanged(address previousWallet, address nextWallet);
    event BuyTax0Changed(uint256 previousTax, uint256 nextTax);
    event SellTax0Changed(uint256 previousTax, uint256 nextTax);
    event BuyTax1Changed(uint256 previousTax, uint256 nextTax);
    event SellTax1Changed(uint256 previousTax, uint256 nextTax);
    event BuyTax2Changed(uint256 previousTax, uint256 nextTax);
    event SellTax2Changed(uint256 previousTax, uint256 nextTax);
    event BuyReflectionTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellReflectionTaxChanged(uint256 previousTax, uint256 nextTax);
    event MinTokenBalanceChanged(uint256 previousMin, uint256 nextMin);
    event Tax0Rescued(uint256 amount);
    event Tax1Rescued(uint256 amount);
    event Tax2Rescued(uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event BuyLimitChanged(uint256 previousMax, uint256 nextMax);
    event SwapFeesChanged(bool enabled);
    event CooldownChanged(uint256 previousCooldown, uint256 nextCooldown);
    event WhitelistChanged(address previousWhitelist, address nextWhitelist);

    constructor(
        address _uniswapFactory,
        address _uniswapRouter,
        uint256 _buyLimit,
        address payable _tax0Wallet,
        address payable _tax1Wallet,
        address payable _tax2Wallet
    ) ERC20("Retroverse", "RETRO") Ownable() {
        taxExcluded[owner()] = true;
        taxExcluded[address(0)] = true;
        taxExcluded[_tax0Wallet] = true;
        taxExcluded[_tax1Wallet] = true;
        taxExcluded[_tax2Wallet] = true;
        taxExcluded[address(this)] = true;

        buyLimit = _buyLimit;
        tax0Wallet = _tax0Wallet;
        tax1Wallet = _tax1Wallet;
        tax2Wallet = _tax2Wallet;

        _router = IUniswapV2Router02(_uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(_uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
    }

    /// @notice Change the address of the tax0 wallet
    /// @param _tax0Wallet The new address of the tax0 wallet
    function setTax0Wallet(address payable _tax0Wallet) external onlyOwner {
        emit Tax0WalletChanged(tax0Wallet, _tax0Wallet);
        tax0Wallet = _tax0Wallet;
    }

    /// @notice Change the address of the tax1 wallet
    /// @param _tax1Wallet The new address of the tax1 wallet
    function setTax1Wallet(address payable _tax1Wallet) external onlyOwner {
        emit Tax1WalletChanged(tax1Wallet, _tax1Wallet);
        tax1Wallet = _tax1Wallet;
    }

    /// @notice Change the address of the tax2 wallet
    /// @param _tax2Wallet The new address of the tax2 wallet
    function setTax2Wallet(address payable _tax2Wallet) external onlyOwner {
        emit Tax2WalletChanged(tax2Wallet, _tax2Wallet);
        tax2Wallet = _tax2Wallet;
    }

    /// @notice Change the buy tax0 rate
    /// @param _buyTax0 The new buy tax0 rate
    function setBuyTax0(uint256 _buyTax0) external onlyOwner {
        require(
            _buyTax0 <= BPS_DENOMINATOR,
            "_buyTax0 cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTax0Changed(buyTax0, _buyTax0);
        buyTax0 = _buyTax0;
    }

    /// @notice Change the sell tax0 rate
    /// @param _sellTax0 The new sell tax0 rate
    function setSellTax0(uint256 _sellTax0) external onlyOwner {
        require(
            _sellTax0 <= BPS_DENOMINATOR,
            "_sellTax0 cannot exceed BPS_DENOMINATOR"
        );
        emit SellTax0Changed(sellTax0, _sellTax0);
        sellTax0 = _sellTax0;
    }

    /// @notice Change the buy tax1 rate
    /// @param _buyTax1 The new buy tax1 rate
    function setBuyTax1(uint256 _buyTax1) external onlyOwner {
        require(
            _buyTax1 <= BPS_DENOMINATOR,
            "_buyTax1 cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTax1Changed(buyTax1, _buyTax1);
        buyTax1 = _buyTax1;
    }

    /// @notice Change the sell tax1 rate
    /// @param _sellTax1 The new sell tax1 rate
    function setSellTax1(uint256 _sellTax1) external onlyOwner {
        require(
            _sellTax1 <= BPS_DENOMINATOR,
            "_sellTax1 cannot exceed BPS_DENOMINATOR"
        );
        emit SellTax1Changed(sellTax1, _sellTax1);
        sellTax1 = _sellTax1;
    }

    /// @notice Change the buy tax2 rate
    /// @param _buyTax2 The new buy tax2 rate
    function setBuyTax2(uint256 _buyTax2) external onlyOwner {
        require(
            _buyTax2 <= BPS_DENOMINATOR,
            "_buyTax2 cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTax2Changed(buyTax2, _buyTax2);
        buyTax2 = _buyTax2;
    }

    /// @notice Change the sell tax2 rate
    /// @param _sellTax2 The new sell tax2 rate
    function setSellTax2(uint256 _sellTax2) external onlyOwner {
        require(
            _sellTax2 <= BPS_DENOMINATOR,
            "_sellTax2 cannot exceed BPS_DENOMINATOR"
        );
        emit SellTax2Changed(sellTax2, _sellTax2);
        sellTax2 = _sellTax2;
    }

    /// @notice Change the buy reflection rate
    /// @param _buyReflectionTax The new buy reflection tax rate
    function setBuyReflectionTax(uint256 _buyReflectionTax) external onlyOwner {
        require(
            _buyReflectionTax <= BPS_DENOMINATOR,
            "_buyReflectionTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyReflectionTaxChanged(buyReflectionTax, _buyReflectionTax);
        buyReflectionTax = _buyReflectionTax;
    }

    /// @notice Change the sell reflection rate
    /// @param _sellReflectionTax The new sell reflection tax rate
    function setSellReflectionTax(uint256 _sellReflectionTax)
        external
        onlyOwner
    {
        require(
            _sellReflectionTax <= BPS_DENOMINATOR,
            "_sellReflectionTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellReflectionTaxChanged(sellReflectionTax, _sellReflectionTax);
        sellReflectionTax = _sellReflectionTax;
    }

    /// @notice Change the minimum contract RETRO balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner {
        emit MinTokenBalanceChanged(minTokenBalance, _minTokenBalance);
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Change the cooldown for buys
    /// @param _cooldown The new cooldown in seconds
    function setCooldown(uint256 _cooldown) external onlyOwner {
        emit CooldownChanged(cooldown, _cooldown);
        cooldown = _cooldown;
    }

    /// @notice Change the whitelist
    /// @param _whitelist The new whitelist contract
    function setWhitelist(IWhitelist _whitelist) external onlyOwner {
        emit WhitelistChanged(address(whitelist), address(_whitelist));
        whitelist = _whitelist;
    }

    /// @notice Rescue RETRO from the tax0 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of RETRO to rescue
    /// @param _recipient The recipient of the rescued RETRO
    function rescueTax0Tokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalTax0,
            "Amount cannot be greater than totalTax0"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax0Rescued(_amount);
        totalTax0 -= _amount;
    }

    /// @notice Rescue RETRO from the tax1 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of RETRO to rescue
    /// @param _recipient The recipient of the rescued RETRO
    function rescueTax1Tokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalTax1,
            "Amount cannot be greater than totalTax1"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax1Rescued(_amount);
        totalTax1 -= _amount;
    }

    /// @notice Rescue RETRO from the tax2 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of RETRO to rescue
    /// @param _recipient The recipient of the rescued RETRO
    function rescueTax2Tokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalTax2,
            "Amount cannot be greater than totalTax2"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax2Rescued(_amount);
        totalTax2 -= _amount;
    }

    function addLiquidity(uint256 tokens)
        external
        payable
        onlyOwner
        liquidityAdd
    {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Enables or disables trading on Uniswap
    function setTradingActive(bool _tradingActive) external onlyOwner {
        tradingActive = _tradingActive;
        emit TradingActiveChanged(_tradingActive);
    }

    /// @notice Updates tax exclusion status
    /// @param _account Account to update the tax exclusion status of
    /// @param _taxExcluded If true, exclude taxes for this user
    function setTaxExcluded(address _account, bool _taxExcluded)
        public
        onlyOwner
    {
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
    }

    /// @notice Updates the max amount allowed to buy
    /// @param _buyLimit The new buy limit
    function setBuyLimit(uint256 _buyLimit) external onlyOwner {
        emit BuyLimitChanged(buyLimit, _buyLimit);
        buyLimit = _buyLimit;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (taxExcluded[sender] || taxExcluded[recipient]) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        uint256 swapAmount = totalTax0.add(totalTax1).add(totalTax2);
        bool overMinTokenBalance = swapAmount >= minTokenBalance;

        if (overMinTokenBalance && !_inSwap && sender != _pair && swapFees) {
            _swap(swapAmount);
        }

        updateReflection(sender);
        updateReflection(recipient);

        uint256 send = amount;
        uint256 tax0;
        uint256 tax1;
        uint256 tax2;
        uint256 reflectionTax;
        if (sender == _pair) {
            if (address(whitelist) != address(0)) {
                require(
                    whitelist.isWhitelisted(recipient),
                    "User is not whitelisted to buy"
                );
            }
            require(tradingActive, "Trading is not yet active");
            require(amount <= buyLimit, "Buy limit exceeded");
            if (cooldown > 0) {
                require(
                    lastBuy[recipient] + cooldown <= block.timestamp,
                    "Cooldown still active"
                );
                lastBuy[recipient] = block.timestamp;
            }
            (send, tax0, tax1, tax2, reflectionTax) = _getTaxAmounts(
                amount,
                true
            );
        } else if (recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            if (address(whitelist) != address(0)) {
                require(
                    whitelist.isWhitelisted(sender),
                    "User is not whitelisted to sell"
                );
            }
            (send, tax0, tax1, tax2, reflectionTax) = _getTaxAmounts(
                amount,
                false
            );
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, tax0, tax1, tax2, reflectionTax);
    }

    /// @notice Perform a Uniswap v2 swap from RETRO to ETH and handle tax distribution
    /// @param amount The amount of RETRO to swap in wei
    /// @dev `amount` is always <= this contract's ETH balance. Calculate and distribute taxes
    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        uint256 contractEthBalance = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        uint256 totalTaxes = totalTax0.add(totalTax1).add(totalTax2);
        uint256 tax0Amount = amount.mul(totalTax0).div(totalTaxes);
        uint256 tax1Amount = amount.mul(totalTax1).div(totalTaxes);
        uint256 tax2Amount = amount.mul(totalTax2).div(totalTaxes);

        uint256 tax0Eth = tradeValue.mul(totalTax0).div(totalTaxes);
        uint256 tax1Eth = tradeValue.mul(totalTax1).div(totalTaxes);
        uint256 tax2Eth = tradeValue.mul(totalTax2).div(totalTaxes);

        totalTax0 = totalTax0.sub(tax0Amount);
        totalTax1 = totalTax1.sub(tax1Amount);
        totalTax2 = totalTax2.sub(tax2Amount);
        if (tax0Eth > 0) {
            tax0Wallet.transfer(tax0Eth);
        }
        if (tax1Eth > 0) {
            tax1Wallet.transfer(tax1Eth);
        }
        if (tax2Eth > 0) {
            tax2Wallet.transfer(tax2Eth);
        }
    }

    function swapAll() external {
        uint256 swapAmount = totalTax0.add(totalTax1).add(totalTax2);

        if (!_inSwap) {
            _swap(swapAmount);
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers RETRO from an account to this contract for taxes
    /// @param _account The account to transfer RETRO from
    /// @param _tax0Amount The amount of tax0 tax to transfer
    /// @param _tax1Amount The amount of tax1 tax to transfer
    /// @param _reflectionTaxAmount The amount of reflection tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _tax0Amount,
        uint256 _tax1Amount,
        uint256 _tax2Amount,
        uint256 _reflectionTaxAmount
    ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _tax0Amount.add(_tax1Amount).add(_tax2Amount).add(
            _reflectionTaxAmount
        );
        _rawTransfer(_account, address(this), totalAmount);
        totalTax0 += _tax0Amount;
        totalTax1 += _tax1Amount;
        totalTax2 += _tax2Amount;
        reflectionBasis += _reflectionTaxAmount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return tax0 The raw tax0 tax amount
    /// @return tax1 The raw tax1 tax amount
    /// @return tax2 The raw tax1 tax amount
    /// @return reflectionTax The raw tax1 tax amount
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (
            uint256 send,
            uint256 tax0,
            uint256 tax1,
            uint256 tax2,
            uint256 reflectionTax
        )
    {
        if (buying) {
            tax0 = amount.mul(buyTax0).div(BPS_DENOMINATOR);
            tax1 = amount.mul(buyTax1).div(BPS_DENOMINATOR);
            tax2 = amount.mul(buyTax2).div(BPS_DENOMINATOR);
            reflectionTax = amount.mul(buyReflectionTax).div(BPS_DENOMINATOR);
        } else {
            tax0 = amount.mul(sellTax0).div(BPS_DENOMINATOR);
            tax1 = amount.mul(sellTax1).div(BPS_DENOMINATOR);
            tax2 = amount.mul(sellTax2).div(BPS_DENOMINATOR);
            reflectionTax = amount.mul(sellReflectionTax).div(BPS_DENOMINATOR);
        }
        send = amount.sub(tax0).sub(tax1).sub(tax2).sub(reflectionTax);
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner {
        swapFees = _swapFees;
        emit SwapFeesChanged(_swapFees);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        require(_totalSupply.add(amount) <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    /// @notice Update the amount of owed reflections for a user
    /// @param addr The address to update the reflections for
    function updateReflection(address addr) public override {
        if (addr == _pair || addr == address(_router)) return;

        uint256 basisDifference = reflectionBasis.sub(
            lastReflectionBasis[addr]
        );
        reflectionOwed[addr] += basisDifference.mul(balanceOf(addr)).div(
            _totalSupply
        );

        lastReflectionBasis[addr] = reflectionBasis;
    }

    /// @notice Claim all owed reflections
    function claimReflection() public override {
        updateReflection(msg.sender);
        _rawTransfer(address(this), msg.sender, reflectionOwed[msg.sender]);
        reflectionOwed[msg.sender] = 0;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IReflectable {
    function reflectionOwed(address user) external view returns (uint256);

    function updateReflection(address user) external;

    function claimReflection() external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IWhitelist {
    function isWhitelisted(address user) external view returns (bool);
}