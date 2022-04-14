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

import "./interfaces/IPermissions.sol";

contract MDAO is ERC20, Ownable {
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

    /// @notice Buy taxes in BPS
    uint256[3] public buyTaxes = [600, 500, 100];
    /// @notice Sell taxes in BPS
    uint256[3] public sellTaxes = [800, 600, 100];
    /// @notice Buy autoLiquidityTax in BPS
    uint256 public buyAutoLiquidityTax = 0;
    /// @notice Sell autoLiquidityTax in BPS
    uint256 public sellAutoLiquidityTax = 0;

    /// @notice Contract MDAO balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    bool public swapFees = true;

    /// @notice tokens that are allocated for each tax
    uint256[3] public totalTaxes;
    /// @notice tokens that are allocated for auto liquidity tax
    uint256 public totalAutoLiquidityTax;

    /// @notice addresses that each tax is sent to
    address payable[3] public taxWallets;

    /// @notice Mapping from address to tax exlcusion status
    mapping(address => bool) public taxExcluded;

    /// @notice Permissions module
    IPermissions public permissions;

    /// @notice Flag indicating whether buys/sells are permitted
    bool public tradingActive = false;

    uint256 internal _totalSupply = 0;
    mapping(address => uint256) private _balances;

    IUniswapV2Router02 internal immutable _router;
    address internal immutable _pair;

    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;

    event TaxWalletsChanged(
        address payable[3] previousWallets,
        address payable[3] nextWallets
    );
    event BuyTaxesChanged(uint256[3] previousTaxes, uint256[3] nextTaxes);
    event SellTaxesChanged(uint256[3] previousTaxes, uint256[3] nextTaxes);
    event BuyAutoLiquidityTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellAutoLiquidityTaxChanged(uint256 previousTax, uint256 nextTax);
    event MinTokenBalanceChanged(uint256 previousMin, uint256 nextMin);
    event TaxesRescued(uint256 index, uint256 amount);
    event AutoLiquidityTaxRescued(uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event SwapFeesChanged(bool enabled);
    event PermissionsChanged(
        address previousPermissions,
        address nextPermissions
    );

    constructor(IUniswapV2Router02 _uniswapRouter)
        ERC20("Meme DAO", "MDAO")
        Ownable()
    {
        taxExcluded[owner()] = true;
        taxExcluded[address(0)] = true;
        taxExcluded[address(this)] = true;

        _router = _uniswapRouter;
        _pair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );
    }

    /// @notice Change the address of the tax wallets
    /// @param _taxWallets The new address of the tax wallets
    function setTaxWallets(address payable[3] memory _taxWallets)
        external
        onlyOwner
    {
        emit TaxWalletsChanged(taxWallets, _taxWallets);
        taxWallets = _taxWallets;
    }

    /// @notice Change the buy tax rates
    /// @param _buyTaxes The new buy tax rates
    function setBuyTaxes(uint256[3] memory _buyTaxes) external onlyOwner {
        require(
            _buyTaxes[0] <= BPS_DENOMINATOR &&
                _buyTaxes[1] <= BPS_DENOMINATOR &&
                _buyTaxes[2] <= BPS_DENOMINATOR,
            "_buyTaxes cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTaxesChanged(buyTaxes, _buyTaxes);
        buyTaxes = _buyTaxes;
    }

    /// @notice Change the sell tax rates
    /// @param _sellTaxes The new sell tax rates
    function setSellTaxes(uint256[3] memory _sellTaxes) external onlyOwner {
        require(
            _sellTaxes[0] <= BPS_DENOMINATOR &&
                _sellTaxes[1] <= BPS_DENOMINATOR &&
                _sellTaxes[2] <= BPS_DENOMINATOR,
            "_sellTaxes cannot exceed BPS_DENOMINATOR"
        );
        emit SellTaxesChanged(sellTaxes, _sellTaxes);
        sellTaxes = _sellTaxes;
    }

    /// @notice Change the buy autoLiquidityTax rate
    /// @param _buyAutoLiquidityTax The new buy autoLiquidityTax rate
    function setBuyAutoLiquidityTax(uint256 _buyAutoLiquidityTax)
        external
        onlyOwner
    {
        require(
            _buyAutoLiquidityTax <= BPS_DENOMINATOR,
            "_buyAutoLiquidityTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyAutoLiquidityTaxChanged(
            buyAutoLiquidityTax,
            _buyAutoLiquidityTax
        );
        buyAutoLiquidityTax = _buyAutoLiquidityTax;
    }

    /// @notice Change the sell autoLiquidityTax rate
    /// @param _sellAutoLiquidityTax The new sell autoLiquidityTax rate
    function setSellAutoLiquidityTax(uint256 _sellAutoLiquidityTax)
        external
        onlyOwner
    {
        require(
            _sellAutoLiquidityTax <= BPS_DENOMINATOR,
            "_sellAutoLiquidityTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellAutoLiquidityTaxChanged(
            sellAutoLiquidityTax,
            _sellAutoLiquidityTax
        );
        sellAutoLiquidityTax = _sellAutoLiquidityTax;
    }

    /// @notice Change the minimum contract MDAO balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner {
        emit MinTokenBalanceChanged(minTokenBalance, _minTokenBalance);
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Change the permissions
    /// @param _permissions The new permissions contract
    function setPermissions(IPermissions _permissions) external onlyOwner {
        emit PermissionsChanged(address(permissions), address(_permissions));
        permissions = _permissions;
    }

    /// @notice Rescue MDAO from the taxes
    /// @dev Should only be used in an emergency
    /// @param _index The tax allocation to rescue from
    /// @param _amount The amount of MDAO to rescue
    /// @param _recipient The recipient of the rescued MDAO
    function rescueTaxTokens(
        uint256 _index,
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        require(0 <= _index && _index < totalTaxes.length, "_index OOB");
        require(
            _amount <= totalTaxes[_index],
            "Amount cannot be greater than totalTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit TaxesRescued(_index, _amount);
        totalTaxes[_index] -= _amount;
    }

    /// @notice Rescue MDAO from the autoLiquidityTax amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of BBI to rescue
    /// @param _recipient The recipient of the rescued BBI
    function rescueAutoLiquidityTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalAutoLiquidityTax,
            "Amount cannot be greater than totalAutoLiquidityTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit AutoLiquidityTaxRescued(_amount);
        totalAutoLiquidityTax -= _amount;
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
        external
        onlyOwner
    {
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
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

        uint256 swapAmount = totalTaxes[0].add(totalTaxes[1]).add(
            totalTaxes[2]
        );
        bool overMinTokenBalance = swapAmount >= minTokenBalance;

        if (overMinTokenBalance && !_inSwap && sender != _pair && swapFees) {
            _swap();
        }

        uint256 send = amount;
        uint256[3] memory taxes;
        uint256 autoLiquidityTax;
        if (sender == _pair) {
            if (address(permissions) != address(0)) {
                require(
                    permissions.isWhitelisted(recipient),
                    "User is not whitelisted to buy"
                );
                require(
                    amount <= permissions.buyLimit(recipient),
                    "User buying more than his/her buyLimit"
                );
            }
            require(tradingActive, "Trading is not yet active");
            (send, taxes, autoLiquidityTax) = _getTaxAmounts(amount, true);
        } else if (recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            if (address(permissions) != address(0)) {
                require(
                    permissions.isWhitelisted(sender),
                    "User is not whitelisted to sell"
                );
            }
            (send, taxes, autoLiquidityTax) = _getTaxAmounts(amount, false);
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, taxes, autoLiquidityTax);
    }

    /// @notice Perform a Uniswap v2 swap from MDAO to ETH and handle tax distribution
    function _swap() internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        uint256 autoLiquidityAmount = totalAutoLiquidityTax.div(2);
        uint256 walletTaxes = totalTaxes[0].add(totalTaxes[1]).add(
            totalTaxes[2]
        );
        uint256 totalSwapAmount = walletTaxes.add(autoLiquidityAmount);

        _approve(
            address(this),
            address(_router),
            totalAutoLiquidityTax.add(walletTaxes)
        );
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            totalSwapAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        uint256 contractEthBalance = address(this).balance;

        uint256 tax0Eth = contractEthBalance.mul(totalTaxes[0]).div(
            totalSwapAmount
        );
        uint256 tax1Eth = contractEthBalance.mul(totalTaxes[1]).div(
            totalSwapAmount
        );
        uint256 tax2Eth = contractEthBalance.mul(totalTaxes[2]).div(
            totalSwapAmount
        );
        uint256 autoLiquidityEth = contractEthBalance
            .mul(autoLiquidityAmount)
            .div(totalSwapAmount);
        totalTaxes = [0, 0, 0];
        totalAutoLiquidityTax = 0;

        if (tax0Eth > 0) {
            taxWallets[0].transfer(tax0Eth);
        }
        if (tax1Eth > 0) {
            taxWallets[1].transfer(tax1Eth);
        }
        if (tax2Eth > 0) {
            taxWallets[2].transfer(tax2Eth);
        }
        if (autoLiquidityEth > 0) {
            _router.addLiquidityETH{value: autoLiquidityEth}(
                address(this),
                autoLiquidityAmount,
                0,
                0,
                address(0),
                block.timestamp
            );
        }
    }

    function swapAll() external {
        if (!_inSwap) {
            _swap();
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers MDAO from an account to this contract for taxes
    /// @param _account The account to transfer MDAO from
    /// @param _taxAmounts The amount for each tax
    /// @param _autoLiquidityTaxAmount The amount of auto liquidity tax
    function _takeTaxes(
        address _account,
        uint256[3] memory _taxAmounts,
        uint256 _autoLiquidityTaxAmount
    ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _taxAmounts[0]
            .add(_taxAmounts[1])
            .add(_taxAmounts[2])
            .add(_autoLiquidityTaxAmount);
        _rawTransfer(_account, address(this), totalAmount);
        totalTaxes[0] += _taxAmounts[0];
        totalTaxes[1] += _taxAmounts[1];
        totalTaxes[2] += _taxAmounts[2];
        totalAutoLiquidityTax += _autoLiquidityTaxAmount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return taxes The raw tax amounts
    /// @return autoLiquidityTax The raw auto liquidity tax amount
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (
            uint256 send,
            uint256[3] memory taxes,
            uint256 autoLiquidityTax
        )
    {
        if (buying) {
            taxes = [
                amount.mul(buyTaxes[0]).div(BPS_DENOMINATOR),
                amount.mul(buyTaxes[1]).div(BPS_DENOMINATOR),
                amount.mul(buyTaxes[2]).div(BPS_DENOMINATOR)
            ];
            autoLiquidityTax = amount.mul(buyAutoLiquidityTax).div(
                BPS_DENOMINATOR
            );
        } else {
            taxes = [
                amount.mul(sellTaxes[0]).div(BPS_DENOMINATOR),
                amount.mul(sellTaxes[1]).div(BPS_DENOMINATOR),
                amount.mul(sellTaxes[2]).div(BPS_DENOMINATOR)
            ];
            autoLiquidityTax = amount.mul(sellAutoLiquidityTax).div(
                BPS_DENOMINATOR
            );
        }
        send = amount.sub(taxes[0]).sub(taxes[1]).sub(taxes[2]).sub(
            autoLiquidityTax
        );
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

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPermissions {
    function isWhitelisted(address user) external view returns (bool);

    function buyLimit(address user) external view returns (uint256);
}