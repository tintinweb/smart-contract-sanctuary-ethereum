/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-07
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    mapping (address => bool) _oMap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _oMap[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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
     * - `account` cannot be the zero address.
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
     * will be to transferred to `to`.
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    // function WOKT() external pure returns (address);
    // function WHT() external pure returns (address);
    
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

interface ITokenDividendTracker {
    function excludeFromDividends(address account) external;

    function owner() external view returns (address);

    function setRewardCoin(address _coin) external;

    function updateClaimWait(uint256 newClaimWait) external;

    function claimWait() external view returns (uint256);

    function totalDividendsDistributed() external view returns (uint256);

    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getAccount(address _account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAccountAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function process(uint256 gas)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function processAccount(address payable account, bool automatic)
        external
        returns (bool);

    function getLastProcessedIndex() external view returns (uint256);

    function getNumberOfTokenHolders() external view returns (uint256);

    function setBalance(address payable account, uint256 newBalance) external;

    function processWithNum(uint256 num)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function distributeRewardCoinDividends(uint256 amount) external;
}

contract Token is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    ITokenDividendTracker public dividendTracker;
    
    uint8 private _decimals = 6;
    uint256 private _total = 10**16 * (10**decimals());
    
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    address public RewardCoin; //RewardCoin   //分红代币 token
    
    uint256 public maxSellTransactionAmount = _total;   //最大交易
    uint256 public swapTokensAtAmount = 1000000 * (10**decimals());  //最大兑换数量
    
    uint256 public maxSwapTokensAtAmount = 1 * (10**decimals());

    bool poolState = true;  //交易池状态
    uint256 maxBuyLimit;   
    uint256 maxSellLimit;   
    bool tryState = false;
    
    bool public swapAndLiquifyEnabled = true;
    
    mapping(address => bool) public _isBlacklisted;

    address public tokenB;

    uint256 public TokenRewardsFee = 300;
    uint256 public liquidityFee = 0;
    uint256 public marketingFee = 200;

    uint256 public burnFee = 500;
    uint256 public genFee = 500;
    uint256[5] public genFeeList = [200, 100, 100, 50, 50];

    mapping(address => address) public _referrerByAddr;

    address public _marketingWalletAddress;
    
    bool public swapEnabled = true;

    uint256 public launchedAt = 0;
    uint256 public launchedAtTime = 0;
    uint256 public _protectTime = 0;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;
    // use by default 10 num to process auto-claiming dividends
    uint256 public numForProcessing = 10;
    
    bool gasRewardEnable = true;
    bool numRewardEnable = false;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    AutoSwap public _autoSwap;
    address[] public _rewardPath;
    
    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event SetBalance(address account, uint256 amount);
    address private _prevSender;
    address private _prevRecipient;

    uint256 public autoBurnIndex = 0;
    uint256 public autoBurnNum = 5*(10**4)*(10**8)*((10**decimals()));
    uint256 public autoLPNum = autoBurnNum.div(2);
    uint256 public autoBurnTotal = 0;
    uint256 public prevBurn = 0;
                        //name    symol
    constructor() ERC20("TBBST TOKEN", "TBBST") {
        
     
            //测试链  ETH Rinkeby Router02=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D USDT=0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02
            uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);    
            tokenB = address(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02);   
       
        
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), tokenB);

        uniswapV2Pair = _uniswapV2Pair;

        //Rinkeby=0xF8b8a7dB0E2754272a90e1028Ed0c8EF06d06987
        _marketingWalletAddress = address(0xF8b8a7dB0E2754272a90e1028Ed0c8EF06d06987);   

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        _autoSwap = new AutoSwap(address(this));
        excludeFromFees(address(_autoSwap), true);

        _mint(owner(), _total.mul(75).div(100));
        _mint(address(_autoSwap), _total.sub(totalSupply()));
        maxBuyLimit = totalSupply();
        maxSellLimit = totalSupply();

        
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    receive() external payable {}

    function activeDividend(address newAddress) public onlyOwner { 
        //rinkeby  持币 分红的代币 token  RSB=0x6089af0e10Ba5691871f1634C1458C1Bb4ee3DCF
        address _rewardCoin = address(0x6089af0e10Ba5691871f1634C1458C1Bb4ee3DCF);  
       
        
        dividendTracker = ITokenDividendTracker(payable(newAddress));
        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(deadWallet));
        dividendTracker.excludeFromDividends(address(uniswapV2Router));

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
        
        updateRewardCoin(_rewardCoin);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "Fortuna: The dividend tracker already has that address"
        );

        ITokenDividendTracker newDividendTracker = ITokenDividendTracker(
            payable(newAddress)
        );

        require(
            newDividendTracker.owner() == address(this),
            "Fortuna: The new dividend tracker must be owned by the Fortuna token contract"
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }
    
    function updateRewardCoin(address newRewardCoin) public onlyOwner {
        require(newRewardCoin != address(0), "newRewardCoin is zero");
        require(RewardCoin != newRewardCoin, "Fortuna: The RewardCoin already has that address");
        RewardCoin = newRewardCoin;
        dividendTracker.setRewardCoin(RewardCoin);
        _rewardPath = [address(this), address(tokenB), address(RewardCoin)];
    }
    
    function updateUniswapV2Router(address newAddress, address newTokenB) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "Fortuna: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
        .createPair(address(this), newTokenB);
        uniswapV2Pair = _uniswapV2Pair;
        tokenB = newTokenB;
    }

    function updateUniswapV2Router(address newAddress, address newPair, address newTokenB) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "Fortuna: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        uniswapV2Pair = newPair;
        tokenB = newTokenB;
    }

    function updateRewardPath(address[] memory _path) public onlyOwner {
        _rewardPath = _path;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Fortuna: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function updatePoolState(bool enabled) public onlyOwner {
        poolState = enabled;
    }

    function updateTryState(bool enabled) public onlyOwner {
        tryState = enabled;
    }

    function lockedPool() public onlyOwner {
        poolState = false;
    }

    function unlockedPool() public onlyOwner {
        poolState = true;
    }

    function updateMaxBuyLimit(uint256 value) public onlyOwner {
        maxBuyLimit = value;
    }

    function updateMaxSellLimit(uint256 value) public onlyOwner {
        maxSellLimit = value;
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        _marketingWalletAddress = wallet;
    }
    
    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
    }
    
    function setMaxSwapTokensAtAmount(uint256 value) external onlyOwner {
        maxSwapTokensAtAmount = value;
    }
    
    function setSwapTokensAtAmount(uint256 value) external onlyOwner {
        swapTokensAtAmount = value;
    }

    function setTokenRewardsFee(uint256 value) external onlyOwner {
        TokenRewardsFee = value;
    }

    function setLiquidityFeeFee(uint256 value) external onlyOwner {
        liquidityFee = value;
    }

    function setMarketingFee(uint256 value) external onlyOwner {
        marketingFee = value;
    }
    
    function setBurnFee(uint256 value) external onlyOwner {
        burnFee = value;
    }

    function setGenFee(uint256 value) external onlyOwner {
        genFee = value;
    }

    function setLaunchedAt(uint256 value) external onlyOwner {
        launchedAt = value;
    }
    
    function setLaunchedAtTime(uint256 value) external onlyOwner {
        launchedAtTime = value;
    }
    
    function setMaxSellTransactionAmount(uint256 value) public onlyOwner {
        maxSellTransactionAmount = value;
    }
    
    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "Fortuna: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
        if (value) {
            dividendTracker.excludeFromDividends(account);
        }
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Fortuna: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000,
            "Fortuna: gasForProcessing must be between 200,000 and 500,000"
        );
        require(
            newValue != gasForProcessing,
            "Fortuna: Cannot update gasForProcessing to same value"
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        launchedAtTime = block.timestamp;
    }
    
    function launchCheck(address sender, address recipient) internal {
        if (block.number > launchedAt + 3) {
            return;
        }
        if (sender == address(uniswapV2Router)||sender == address(uniswapV2Pair)) {
            _isBlacklisted[recipient] = true;
            dividendTracker.excludeFromDividends(recipient);
        } if (recipient == address(uniswapV2Router)||recipient == address(uniswapV2Pair)) {
            _isBlacklisted[sender] = true;
            dividendTracker.excludeFromDividends(sender);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[from], "Blacklisted address"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            balanceOf(to) == 0 &&
            _referrerByAddr[to] == address(0) &&
            !isContract(from) &&
            !isContract(to)
        ) {
            _referrerByAddr[to] = from;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        // if (contractTokenBalance > maxSwapTokensAtAmount) {
        //     contractTokenBalance = maxSwapTokensAtAmount;
        // }
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        
        if (
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            from != owner() &&
            to != owner() && 
            from != address(this) &&
            to != address(this) &&
            swapEnabled
        ) {
            _swap();
        }

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            if (to == address(uniswapV2Pair)) {
                if (!launched()) {
                    launch();
                }
            }
        }
        if (takeFee && !poolState) {
            takeFee = false;
            require(from != address(uniswapV2Pair) && to != address(uniswapV2Pair), "locked");
        }
        
        uint256 tokens = amount;

        if (takeFee) {
            if (from == address(uniswapV2Pair)) {
                require(amount <= maxBuyLimit, "maxBuyLimit");
            } else if (to == address(uniswapV2Pair)) {
                require(amount <= maxSellLimit, "maxSellLimit");
            }

            launchCheck(from, to);

            if (liquidityFee > 0) {
                uint256 liquidityFees = amount.mul(liquidityFee).div(10000);
                super._transfer(from, address(this), liquidityFees);
                tokens = tokens.sub(liquidityFees);
            }

            if (TokenRewardsFee > 0) {
                uint256 tokenRewardsFees = amount.mul(TokenRewardsFee).div(10000);
                super._transfer(from, address(this), tokenRewardsFees);
                tokens = tokens.sub(tokenRewardsFees);
            }

            if (burnFee > 0) {
                uint256 burnFees = amount.mul(burnFee).div(10000);
                super._transfer(from, address(deadWallet), burnFees);
                tokens = tokens.sub(burnFees);
            }

            if (marketingFee > 0) {
                uint256 marketingFees = amount.mul(marketingFee).div(10000);
                super._transfer(from, address(this), marketingFees);
                tokens = tokens.sub(marketingFees);
            }

            if (genFee > 0) {
                uint256 genFees = amount.mul(genFee).div(10000);

                address taxer = from;
                if (from == uniswapV2Pair) {
                    taxer = to;
                }
                
                for (uint256 i = 0; i < genFeeList.length; i++) {
                    taxer = _referrerByAddr[taxer];
                    if (taxer == address(0)) {
                        taxer = address(_marketingWalletAddress);
                    }
                    uint256 oGenFee = genFeeList[i];
                    uint256 oGenFees = genFees.mul(oGenFee).div(genFee);
                    super._transfer(from, address(taxer), oGenFees);

                    tokens = tokens.sub(oGenFees);
                }
            }

        }

        super._transfer(from, to, tokens);
        if (tryState) {
            try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        } else {
            dividendTracker.setBalance(payable(from), balanceOf(from));
        }

        if (tryState) {
            try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        } else {
            dividendTracker.setBalance(payable(to), balanceOf(to));
        }
        

        if (!swapping) {
            if (gasRewardEnable) {
                uint256 gas = gasForProcessing;

                try dividendTracker.process(gas) returns (
                    uint256 iterations,
                    uint256 claims,
                    uint256 lastProcessedIndex
                ) {
                    emit ProcessedDividendTracker(
                        iterations,
                        claims,
                        lastProcessedIndex,
                        true,
                        gas,
                        tx.origin
                    );
                } catch {}
            } else if (numRewardEnable) {
                uint256 num = numForProcessing;

            try dividendTracker.processWithNum(num) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    num,
                    tx.origin
                );
            } catch {}
            }
        }
    }
    
    function swapAll() public {
        if (!swapping) {
            _swap();
        }
    }

    function _swap() private lockSwap {

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 tokens = contractTokenBalance;

        uint256 halfFee = liquidityFee.div(2);

        uint256 taxTotalFees = TokenRewardsFee.add(marketingFee).add(liquidityFee);
        uint256 taxBalanceFees = TokenRewardsFee.add(marketingFee).add(halfFee);
        uint256 otherHalf = tokens.mul(halfFee).div(taxTotalFees);

        tokens = tokens.sub(otherHalf);
        swapTokensForRewardCoin(tokens, address(_autoSwap));
        _autoSwap.withdraw(address(RewardCoin));
        uint256 RewardCoinBalance = IERC20(RewardCoin).balanceOf(address(this));
        if (RewardCoinBalance == 0) {
            return;
        }

        if (marketingFee > 0) {
            uint256 marketingBalance = RewardCoinBalance.mul(marketingFee).div(taxBalanceFees);
            IERC20(RewardCoin).transfer(_marketingWalletAddress, marketingBalance);
        }
        
        if (TokenRewardsFee > 0) {
            uint256 dividends = RewardCoinBalance.mul(TokenRewardsFee).div(taxBalanceFees);
            uint256 currentBalance = IERC20(RewardCoin).balanceOf(address(this));
            if (dividends > currentBalance) {
                dividends = currentBalance;
            }
            bool success = IERC20(RewardCoin).transfer(
                address(dividendTracker),
                dividends
            );

            if (success) {
                dividendTracker.distributeRewardCoinDividends(dividends);
                emit SendDividends(tokens, dividends);
            }
        }
        
        if (swapAndLiquifyEnabled && liquidityFee > 0) {
            addLiquidityForTokenB(otherHalf, IERC20(tokenB).balanceOf(address(this)));
        }
        
        
        if (balanceOf(deadWallet).sub(prevBurn) >= autoBurnNum && balanceOf(address(_autoSwap)) >= autoBurnNum ) {
            super._transfer(address(_autoSwap), address(deadWallet), autoLPNum);
            prevBurn = balanceOf(deadWallet);
            autoBurnTotal = autoBurnTotal.add(autoLPNum);

            if (balanceOf(address(_autoSwap)) >= autoLPNum && swapAndLiquifyEnabled) {
                super._transfer(address(_autoSwap), address(this), autoLPNum);
                uint256 half = autoLPNum.div(2);
                otherHalf = autoLPNum.sub(half);
                swapTokensForTokenB(half, address(_autoSwap));
                _autoSwap.withdraw(address(tokenB));
                addLiquidityForTokenB(otherHalf, IERC20(tokenB).balanceOf(address(this)));
            }
        }
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        if (tokens == 0) {
            return;
        }
        swapTokensForRewardCoin(tokens, address(_autoSwap));
        uint256 dividends = IERC20(RewardCoin).balanceOf(address(_autoSwap));
        bool success = _autoSwap.withdraw(
            address(RewardCoin),
            address(dividendTracker),
            dividends
        );

        if (success) {
            dividendTracker.distributeRewardCoinDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }

    function swapTokensForTokenB(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(tokenB);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    function swapTokensForRewardCoin(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path;
        
        if (address(tokenB) == address(RewardCoin)) {
            path = new address[](2);
            path[0] = address(this);
            path[1] = address(tokenB);
        } else {
            path = new address[](3);
            path[0] = address(this);
            path[1] = address(tokenB);
            path[2] = address(RewardCoin);
        }
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }

    function addLiquidityForTokenB(uint256 tokenAmount, uint256 tokenBAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20(tokenB).approve(address(uniswapV2Router), tokenBAmount);
        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            address(tokenB),
            tokenAmount,
            tokenBAmount,
            0,
            0,
            address(_marketingWalletAddress),
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
            address(_marketingWalletAddress),
            block.timestamp
        );
    }

    function _tokenToBnbValue(
        address sender,
        address recipient,
        uint256 tokenAmount
        ) public view returns (uint256) {
        if (sender == uniswapV2Pair) {
            address[] memory _path = new address[](2);
            _path[0] = address(this);
            _path[1] = uniswapV2Router.WETH();
            uint[] memory amounts = uniswapV2Router.getAmountsOut(tokenAmount, _path);
            if (amounts.length > 0) {
                uint256 bnbValue = amounts[amounts.length - 1];
                return bnbValue;
            }
        }
        recipient;
        return 0;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function transferForeignToken(address _token, address _to) public onlyOwner returns(bool _sent){
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
    
    function Sweep(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function withdrawAutoSwap(address token) external onlyOwner {
        _autoSwap.withdraw(token);
    }

    modifier lockSwap() {
        swapping = true;
        _;
        swapping = false;
    }

}

contract AutoSwap {
    using SafeMath for uint256;

    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    receive() external payable {}

    function withdraw(address token) public payable {
        require(msg.sender == owner, "caller is not owner");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(msg.sender, balance);
        } 
    }

    function withdraw(address token, address _to) public payable {
        require(msg.sender == owner, "caller is not owner");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(_to, balance);
        } 
    }

    function withdraw(address token, address _to, uint256 _balance) public returns (bool) {
        require(msg.sender == owner, "caller is not owner");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance >= _balance) {
            return IERC20(token).transfer(_to, _balance);
        } 
        return false;
    }

}