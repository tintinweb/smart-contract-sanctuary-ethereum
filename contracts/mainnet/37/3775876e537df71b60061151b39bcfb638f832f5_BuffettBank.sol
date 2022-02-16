/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0-solc-0.7/contracts/token/ERC20/ERC20.sol";
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


contract Ownable {
    address public _owner;
    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}



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


// pragma solidity >=0.5.0;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;
    mapping (address => uint256) public lastBought;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDividendForReward;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor () {
        _token = msg.sender;
    }

    function notifyJustBuyRecently(address buyer) public onlyToken {
        lastBought[buyer] = block.timestamp;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDividendForReward) external override onlyToken {
        minPeriod = _minPeriod;
        minDividendForReward = _minDividendForReward;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        uint256 dividendAmount = amount;
        if(amount >= minDividendForReward && shares[shareholder].amount == 0){
            addShareholder(shareholder);
            dividendAmount = amount;
        }else if(amount < minDividendForReward){
            dividendAmount = 0;
            if(shares[shareholder].amount > 0)
                removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(dividendAmount);
        shares[shareholder].amount = dividendAmount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    receive() external payable { 
        deposit();
    }

    function deposit() public payable override {
        totalDividends = totalDividends.add(msg.value);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(msg.value).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > 0 && (lastBought[shareholder] + (12 hours)) < block.timestamp;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            (bool success,) = payable(shareholder).call{value: amount, gas: 3000}("");
            if(success){
                totalDistributed = totalDistributed.add(amount);
                shareholderClaims[shareholder] = block.timestamp;
                shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            }
        }
    }
    
    function claimDividend(address shareholder) external {
        if(shouldDistribute(shareholder)){
            distributeDividend(shareholder);
        }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function getLastTimeClaim(address shareholder)public view returns (uint256) {
        return shareholderClaims[shareholder];
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol
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
     * by making the `nonReentrant` function external, and make it call a
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


contract Staking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public token;
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    uint256 public totalRewardUsdtDistributed;
    uint256 public amountUsdtForReward;
    uint256 public limitRewardUsdtPerSecond;
    uint256 public accUsdtPerShare;

    uint256 public totalRewardEthDistributed;
    uint256 public amountEthForReward;
    uint256 public accEthPerShare;

    uint256 public requiredTimeForReward;
    uint256 public lastRewardTime;
    uint256 public PRECISION_FACTOR;
    uint256 public totalStakedAmount;

    uint256 public currentUsdtPerSecond;
    uint256 public currentEthPerSecond;

    uint256 lastEthBalance;

    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount;
        uint256 depositTime;
        uint256 rewardUsdtDebt;
        uint256 pendingUsdtReward;

        uint256 rewardEthDebt;
        uint256 pendingEthReward;
    }

    IUniswapV2Router02 uniswapV2Router;

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        token = IERC20(msg.sender);
        PRECISION_FACTOR = uint256(10**36);
        limitRewardUsdtPerSecond = 20000; // 50000 USDT/month - Warning: USDT decimals = 6
        requiredTimeForReward = 30 days;
        lastRewardTime = block.timestamp;
    }

    receive() external payable {}

    function distributeUsdtToStaking() public payable {
        uint256 balanceBefore = USDT.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(USDT);

        uniswapV2Router.swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amount = USDT.balanceOf(address(this)).sub(balanceBefore);

        amountUsdtForReward = amountUsdtForReward.add(amount);
    }    
    
    function setLimitRewardUsdtPerSecond(uint256 _limitRewardEthPerSecond) public onlyOwner{
        limitRewardUsdtPerSecond = _limitRewardEthPerSecond;
    }

    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "Can't deposit zero amount");

        _updatePool();

        if (user.amount > 0) {
            user.pendingUsdtReward = user.pendingUsdtReward.add(user.amount.mul(accUsdtPerShare).div(PRECISION_FACTOR).sub(user.rewardUsdtDebt));
            user.pendingEthReward = user.pendingEthReward.add(user.amount.mul(accEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt));
        }

        user.depositTime = user.depositTime > 0 ? user.depositTime : block.timestamp;
        
        user.amount = user.amount.add(_amount);
        token.transferFrom(address(msg.sender), address(this), _amount);

        totalStakedAmount = totalStakedAmount.add(_amount);
        user.rewardUsdtDebt = user.amount.mul(accUsdtPerShare).div(PRECISION_FACTOR);
        user.rewardEthDebt = user.amount.mul(accEthPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, _amount);
    }

    function setTimeRequireForRewardStaking(uint256 _second) public onlyOwner{
        require(_second <= 90 days);
        requiredTimeForReward = _second;
    }

    function withdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= 0, "You havent invested yet");

        _updatePool();

        uint256 pendingUsdt = user.pendingUsdtReward.add(user.amount.mul(accUsdtPerShare).div(PRECISION_FACTOR).sub(user.rewardUsdtDebt));
        uint256 pendingEth = user.pendingEthReward.add(user.amount.mul(accEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt));

        token.transfer(address(msg.sender), user.amount);

        if(block.timestamp > user.depositTime.add(requiredTimeForReward)){
            if (pendingUsdt > 0) {
                USDT.transfer(address(msg.sender), pendingUsdt);
            }
            if(pendingEth > 0){
                payable(msg.sender).transfer(pendingEth);
                lastEthBalance = address(this).balance;
            }
        }else {
            amountUsdtForReward = amountUsdtForReward.add(pendingUsdt);
            amountEthForReward = amountEthForReward.add(pendingEth);
        }
        totalStakedAmount = totalStakedAmount.sub(user.amount);
        user.amount = 0;
        user.depositTime = 0;
        user.rewardUsdtDebt = 0;
        user.pendingUsdtReward = 0;
        user.rewardEthDebt = 0;
        user.pendingEthReward = 0;

        emit Withdraw(msg.sender, user.amount);
    }

    function harvest() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= 0, "You havent invested yet");
        require(block.timestamp > user.depositTime.add(requiredTimeForReward), "Check locking time require");

        _updatePool();

        uint256 pendingUsdt = user.pendingUsdtReward.add(user.amount.mul(accUsdtPerShare).div(PRECISION_FACTOR).sub(user.rewardUsdtDebt));
        if (pendingUsdt > 0) {
            USDT.transfer(address(msg.sender), pendingUsdt);
            user.pendingUsdtReward = 0;
            user.rewardUsdtDebt = user.amount.mul(accUsdtPerShare).div(PRECISION_FACTOR);
            emit Harvest(msg.sender, pendingUsdt);
        }

        uint256 pendingEth = user.pendingEthReward.add(user.amount.mul(accEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt));
        if (pendingEth > 0) {
            payable(msg.sender).transfer(pendingEth);
            user.pendingEthReward = 0;
            user.rewardEthDebt = user.amount.mul(accEthPerShare).div(PRECISION_FACTOR);

            lastEthBalance = address(this).balance;
            emit Harvest(msg.sender, pendingEth);
        }
    }

    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.depositTime = 0;
        totalStakedAmount = totalStakedAmount.sub(amountToTransfer);

        user.rewardUsdtDebt = 0;
        amountUsdtForReward = amountUsdtForReward.add(user.pendingUsdtReward);
        user.pendingUsdtReward = 0;

        user.rewardEthDebt = 0;
        amountEthForReward = amountEthForReward.add(user.pendingEthReward);
        user.pendingEthReward = 0;

        if (amountToTransfer > 0) {
            token.transfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    function pendingReward(address _user) public view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 pendingUsdt;
        uint256 pendingEth;
        
        if (block.timestamp > lastRewardTime && totalStakedAmount != 0) {
            uint256 multiplier = block.timestamp.sub(lastRewardTime);
            uint256 usdtReward = multiplier.mul(limitRewardUsdtPerSecond);
            if(usdtReward > amountUsdtForReward){
                usdtReward = amountUsdtForReward;
            }
            uint256 adjustedUsdtPerShare = accUsdtPerShare.add(usdtReward.mul(PRECISION_FACTOR).div(totalStakedAmount));
            pendingUsdt =  user.pendingUsdtReward.add(user.amount.mul(adjustedUsdtPerShare).div(PRECISION_FACTOR).sub(user.rewardUsdtDebt));

            // ETH reflection
            uint256 additionEthReflection = address(this).balance.sub(lastEthBalance);
            uint256 currentEthForReward = amountEthForReward.add(additionEthReflection);
            uint256 adjustedEthPerShare = accEthPerShare.add(currentEthForReward.mul(PRECISION_FACTOR).div(totalStakedAmount));
            pendingEth =  user.pendingEthReward.add(user.amount.mul(adjustedEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt));
        } else {
            pendingUsdt = user.pendingUsdtReward.add(user.amount.mul(accUsdtPerShare).div(PRECISION_FACTOR).sub(user.rewardUsdtDebt));
            pendingEth = user.pendingEthReward.add(user.amount.mul(accEthPerShare).div(PRECISION_FACTOR).sub(user.rewardEthDebt));
        }

        return (pendingUsdt, pendingEth);
    }

    function ableToHarvestReward(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];
        (uint256 usdtAmount, ) = pendingReward(_user);
        if(block.timestamp > user.depositTime.add(requiredTimeForReward) && usdtAmount > 0){
            return true;
        }else
            return false;
    }

    function _updatePool() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }

        if (totalStakedAmount == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        
        uint256 multiplier = block.timestamp.sub(lastRewardTime);
        uint256 usdtReward = multiplier.mul(limitRewardUsdtPerSecond);
        if(usdtReward > amountUsdtForReward){
            usdtReward = amountUsdtForReward;
        }
        currentUsdtPerSecond = usdtReward.div(multiplier);

        accUsdtPerShare = accUsdtPerShare.add(usdtReward.mul(PRECISION_FACTOR).div(totalStakedAmount));
        amountUsdtForReward = amountUsdtForReward.sub(usdtReward);
        totalRewardUsdtDistributed = totalRewardUsdtDistributed.add(usdtReward);

        // ETH reflection
        uint256 additionEthReflection = address(this).balance.sub(lastEthBalance);
        amountEthForReward = amountEthForReward.add(additionEthReflection);
        lastEthBalance = address(this).balance;

        accEthPerShare = accEthPerShare.add(amountEthForReward.mul(PRECISION_FACTOR).div(totalStakedAmount));
        totalRewardEthDistributed = totalRewardEthDistributed.add(amountEthForReward);
        currentEthPerSecond = amountEthForReward.div(multiplier);
        amountEthForReward = 0;

        lastRewardTime = block.timestamp;
    }
}


contract BuffettBank is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    uint256 public _liquidityFee;
    uint256 public _ethReflectionFee;
    uint256 public _stakingFee;
    uint256 public _marketingFee;

    // exlcude from fees and max transaction amount
    mapping (address => bool) public _isFeesExempt;
    mapping (address => bool) public _isDividendExempt;
    mapping (address => bool) public _isMaxPerWalletExempt;
    mapping (address => bool) public _isMaxBuyExempt;
    mapping (address => bool) public isInBlacklist;

    mapping (address => uint256) public _lastSellingTime;

    uint256 private _totalSupply = 69000000000 * (10**18);
    uint256 public numTokensSellToAddToLiquidity = _totalSupply / 10000;
    uint256 public numMaxPerWalletPercent = 15; // 1.5%
    uint256 public numMaxPerBuyPercent = 1; // 0.1%
    uint256 public maxrouterpercent = 10;

    

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public maxrouterlimitenabled = true;

    DividendDistributor public distributor;
    uint256 distributorGas = 300000;

    Staking public staking;

    address public marketingWallet = 0xa6b441E882c02f665afCA7650FA1F228232C166E;
    address public developmentWallet = 0x93eEFc4862D0f2d1b131221808713392c96CFD28;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () ERC20("BuffettBank", "BBANK") {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        distributor = new DividendDistributor();
        setDistributionCriteria(3600, _totalSupply/10000);

        staking = new Staking();
        staking.transferOwnership(owner());

        updateTaxFees(15, 65, 0, 30);

        setIsFeeExempt(owner(), true);
        setIsFeeExempt(address(this), true);
        setIsFeeExempt(address(staking), true);

        setMaxPerWalletExempt(address(this), true);
        setMaxPerWalletExempt(address(uniswapV2Pair), true);
        setMaxPerWalletExempt(owner(), true);
        setMaxPerWalletExempt(address(staking), true);

        setIsDividendExempt(address(this), true);
        setIsDividendExempt(uniswapV2Pair, true);

        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    function setMarketingWallet(address _marketingWallet) external onlyOwner() {
        require(_marketingWallet != address(0), "Marketing wallet can't be the zero address");
        marketingWallet = _marketingWallet;
    }

    function setDevelopmentgWallet(address _developmentWallet) external onlyOwner() {
        require(_developmentWallet != address(0), "Development wallet can't be the zero address");
        developmentWallet = _developmentWallet;
    }
    
    function setMaxPerWalletPercent(uint256 _percentTime10) public onlyOwner {
        require(_percentTime10 >= 10, "Minimum is 1%");
        numMaxPerWalletPercent = _percentTime10;
    }

    function setRouterSellLimitpercent(uint256 amount) public onlyOwner() {
        maxrouterpercent = amount;
    }

    function setMaxPerBuyPercent(uint256 _percentTime10) public onlyOwner {
        require(_percentTime10 >= 1, "Minimum is 0.1%");
        numMaxPerBuyPercent = _percentTime10;
    }

    function setMaxPerWalletExempt(address account, bool exempt) public onlyOwner {
        _isMaxPerWalletExempt[account] = exempt;
    }

    function setMaxPerBuyExempt(address account, bool exempt) public onlyOwner {
        _isMaxBuyExempt[account] = exempt;
    }

    function setIsFeeExempt(address account, bool exempt) public onlyOwner {
        _isFeesExempt[account] = exempt;
    }

    function setIsDividendExempt(address account, bool exempt) public onlyOwner() {
        _isDividendExempt[account] = exempt;
        if(exempt){
            distributor.setShare(account, 0);
        }else {
            distributor.setShare(account, balanceOf(account));
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function setmaxrouterlimitenabled(bool _enabled) public onlyOwner {
        maxrouterlimitenabled = _enabled;
    }

    function manualswap() external lockTheSwap  onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external onlyOwner() {
        uint256 amount = address(this).balance;

        uint256 ethMarketing = amount.mul(7).div(10);
        uint256 ethDev = amount.mul(3).div(10);

        //Send out fees
        if(ethDev > 0)
            payable(developmentWallet).transfer(ethDev);
        if(ethMarketing > 0)
            payable(marketingWallet).transfer(ethMarketing);
    }

    function manualswapcustom(uint256 percentage) external lockTheSwap  onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        uint256 swapbalance = contractBalance.div(10**5).mul(percentage);
        swapTokensForEth(swapbalance);
    }
    function setBlacklistWallet(address account, bool blacklisted) public onlyOwner {
        isInBlacklist[account] = blacklisted;
    }

    function updateTaxFees(uint256 _liquid, uint256 _ethReflection, uint256 _staking, uint256 _marketing) public onlyOwner {
        require(_liquid + _ethReflection + _staking + _marketing <= 900, "Total tax must less then 90");
        _liquidityFee = _liquid;
        _ethReflectionFee = _ethReflection;
        _stakingFee = _staking;
        _marketingFee = _marketing;
    }

    function getUnpaidEth(address account)  public view returns (uint256){
        return distributor.getUnpaidEarnings(account);
    }

    function getLastTimeClaim(address account)  public view returns (uint256){
        return distributor.getLastTimeClaim(account);
    }

    function claimEthReward() public {
        distributor.claimDividend(msg.sender);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minTokenForReceiveReward) public onlyOwner{
        distributor.setDistributionCriteria(_minPeriod, _minTokenForReceiveReward);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(isInBlacklist[from] == false, "You're in blacklist");

        // Check max buy amount
        if(from == address(uniswapV2Pair) && !_isMaxBuyExempt[to]){
            require(amount <= _totalSupply.mul(numMaxPerBuyPercent).div(1000), "Check max per buy percent");
        }

        if(from != owner() && from != address(this) && to == address(uniswapV2Pair)){
            require(block.timestamp >= _lastSellingTime[from].add(1 hours), "Only sell once ");
            _lastSellingTime[from] = block.timestamp;
        }

        if(from == address(uniswapV2Pair)){
            distributor.notifyJustBuyRecently(to);
        }

        bool swapped = false;
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndSend();
            swapped = true;
        }

        bool takeFee = true;
        if(_isFeesExempt[from] || _isFeesExempt[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(_liquidityFee.add(_ethReflectionFee).add(_stakingFee).add(_marketingFee)).div(1000);
        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        if(!_isMaxPerWalletExempt[to]){
            require(balanceOf(to).add(amount) <= _totalSupply.mul(numMaxPerWalletPercent).div(1000), "Check max per wallet percent");
        }

        super._transfer(from, to, amount);

        if(!_isDividendExempt[from]){ try distributor.setShare(from, balanceOf(from)) {} catch {} }
        if(!_isDividendExempt[to]){ try distributor.setShare(to, balanceOf(to)) {} catch {} }

        if(!swapped)
            try distributor.process(distributorGas) {} catch {}
    }

    function swapAndSend() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        
        uint256 maxroutersell = _totalSupply.div(1000).mul(maxrouterpercent);

        if(contractTokenBalance > maxroutersell && maxrouterlimitenabled) {
          contractTokenBalance = contractTokenBalance.div(10);
        }
        
        uint256 _totalFee = _liquidityFee.add(_ethReflectionFee).add(_stakingFee).add(_marketingFee);

        uint256 amountForLiquidity = contractTokenBalance.mul(_liquidityFee).div(_totalFee);
        uint256 amountForEthReflection = contractTokenBalance.mul(_ethReflectionFee).div(_totalFee);
        uint256 amountForStaking = contractTokenBalance.mul(_stakingFee).div(_totalFee);
        uint256 amountForMarketingAndDev = contractTokenBalance.sub(amountForLiquidity).sub(amountForEthReflection).sub(amountForStaking);

        // split the contract balance into halves
        uint256 half = amountForLiquidity.div(2);
        uint256 otherHalf = amountForLiquidity.sub(half);

        // swap
        uint256 swapAmount = half.add(amountForEthReflection).add(amountForStaking).add(amountForMarketingAndDev);
        swapTokensForEth(swapAmount);
        uint256 ethBalance = address(this).balance;

        // send out
        uint256 ethLiquid = ethBalance.mul(half).div(swapAmount);
        uint256 ethReflection = ethBalance.mul(amountForEthReflection).div(swapAmount);
        uint256 ethStaking = ethBalance.mul(amountForStaking).div(swapAmount);
        uint256 ethMarketingAndDev = ethBalance.sub(ethLiquid).sub(ethReflection).sub(ethStaking);

        if(ethMarketingAndDev > 0){
            payable(marketingWallet).transfer(ethMarketingAndDev.mul(70).div(100));
            payable(developmentWallet).transfer(ethMarketingAndDev.mul(30).div(100));
        }

        if(ethReflection > 0)
            try distributor.deposit{value: ethReflection}() {} catch {}
        
        if(ethStaking > 0){
            try staking.distributeUsdtToStaking{value: ethStaking}() {} catch {}
        }

        if(ethLiquid > 0)
            addLiquidity(otherHalf, ethLiquid);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

}