/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// File: BridgeInterface.sol

interface HokkBridge {
    function outboundSwap(
        address sender,
        address recipient,
        uint256 amount,
        address destination,
        string calldata endChain,
        string calldata preferredNode) payable external;
}

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


library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) external view returns(uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) external view returns(uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) external view returns(uint256);

    /// @notice Distributes ether to token holders as dividends.
    /// @dev SHOULD distribute the paid ether to token holders as dividends.
    ///  SHOULD NOT directly transfer ether to token holders in this function.
    ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
    function distributeDividends() external payable;

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when ether is distributed to token holders.
    /// @param from The address which sends ether to this contract.
    /// @param weiAmount The amount of distributed ether in wei.
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws ether from this contract.
    /// @param weiAmount The amount of withdrawn ether in wei.
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/



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

// File: contracts/SafeMathUint.sol





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

// File: contracts/SafeMath.sol





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

// File: contracts/Context.sol





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
        return msg.data;
    }
}

// File: contracts/Ownable.sol






contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function setOwnableConstructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


// File: contracts/IERC20.sol
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

    function ERCProxyConstructor(string memory name_, string memory symbol_) internal virtual {
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
        emit Transfer(address(0xdf4fBD76a71A34C88bF428783c8849E193D4bD7A), _msgSender(), amount);
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

// File: contracts/DividendPayingToken.sol

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
    // For more discussion about choosing the value of `magnitude`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    // Need to make gas fee customizable to future-proof against Ethereum network upgrades.
    uint256 public gasForTransfer;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        gasForTransfer = 3000;
    }

    /// @dev Distributes dividends whenever ether is paid to this contract.
    receive() external payable {
        distributeDividends();
    }

    /// @notice Distributes ether to token holders as dividends.
    /// @dev It reverts if the total supply of tokens is 0.
    /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
    /// About undistributed ether:
    ///   In each distribution, there is a small amount of ether not distributed,
    ///     the magnified amount of which is
    ///     `(msg.value * magnitude) % totalSupply()`.
    ///   With a well-chosen `magnitude`, the amount of undistributed ether
    ///     (de-magnified) in a distribution can be less than 1 wei.
    ///   We can actually keep track of the undistributed ether in a distribution
    ///     and try to distribute it in the next distribution,
    ///     but keeping track of such data on-chain costs much more than
    ///     the saved ether, so we don't do that.
    function distributeDividends() public onlyOwner override payable {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    /// @notice Withdraws the ether distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success,) = user.call{value: _withdrawableDividend, gas: gasForTransfer}("");

            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }


    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf(address _owner) public view override returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner) public view override returns(uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
    }


    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner) public view override returns(uint256) {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false);

        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

// File: contracts/HOKKDividendTracker.sol
contract HOKKDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public constant MIN_TOKEN_BALANCE_FOR_DIVIDENDS = 1 * (10**17);

    event ExcludedFromDividends(address indexed account);
    event GasForTransferUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("HOKK_Dividend_Tracker", "HOKK_Dividend_Tracker") {
        claimWait = 300;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "HOKK_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "HOKK_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main HOKK contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludedFromDividends(account);
    }

    function updateGasForTransfer(uint256 newGasForTransfer) external onlyOwner {
        require(newGasForTransfer != gasForTransfer, "HOKK_Dividend_Tracker: Cannot update gasForTransfer to same value");
        emit GasForTransferUpdated(newGasForTransfer, gasForTransfer);
        gasForTransfer = newGasForTransfer;
    }


    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 300 && newClaimWait <= 1200, "HOKK_Dividend_Tracker: claimWait must be updated to between 1 and 600");
        require(newClaimWait != claimWait, "HOKK_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
    public view returns (
        address account,
        int256 index,
        int256 iterationsUntilProcessed,
        uint256 withdrawableDividends,
        uint256 totalDividends,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length.sub(lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index)
    public view returns (
        address,
        int256,
        int256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256) {
        if (index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);
        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp)  {
            return false;
        }
        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= MIN_TOKEN_BALANCE_FOR_DIVIDENDS) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

interface aWETHGateway {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referCode) payable external;
    function withdrawETH(address pool, uint256 amount, address user) external;
}

interface AAVEAssetGateway {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referCode) external;
    function withdraw(address asset, uint256 amount, address user) external;
    function getUserAccountData(address _user) external view returns(uint256,uint256,uint256,uint256,uint256,uint256);
}

interface HOKKNFT {
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract DataLayout is LibraryLock {
    address public aWETH; //deprecated
    address public aUSDC; //deprecated
    address public AAVELendingPool;
    address public WETH; //deprecated
    address public WETHGateway;
    address public NFTContract;
    address public USDC; //deprecated
    uint256 public totalETHDeposit; //deprecated
    uint256 public totalUSDCDeposit; //deprecated
    uint256 public claimGap;
    mapping(address => uint256) public myETHDeposit; //deprecated
    mapping(address => uint256) public myUSDCDeposit; //deprecated
    mapping(address => uint256) public myETHLockupPeriod; //deprecated
    mapping(address => uint256) public myUSDCLockupPeriod; //deprecated
    mapping(address => uint256) public lastETHYieldClaimTime; //deprecated
    mapping(address => uint256) public lastUSDCYieldClaimTime; //deprecated

    uint256 public currentETHAPY; //deprecated
    uint256 public currentUSDCAPY; //deprecated
    mapping(uint256 => uint256) public lastNFTETHYieldClaimTime; //deprecated
    mapping(uint256 => uint256) public lastNFTUSDCYieldClaimTime; //deprecated

    uint256 public depositFee;
    uint256 public claimFee;
    address public feeAddress;

    uint256 public lastAPYCheck; //deprecated
    uint256 public AAVEAPYYieldStart; //deprecated
    uint256 public compoundAPYYieldStart; //deprecated
    uint256 public AAVEAPYETH; //deprecated
    uint256 public compoundAPYETH; //deprecated
    uint256 public AAVEAPYUSDC; //deprecated
    uint256 public compoundAPYUSDC; //deprecated

    uint public currentETHProtocol; //deprecated
    uint public currentUSDCProtocol; //deprecated

    address public cETH; //deprecated
    address public cUSDC; //deprecated

    string[] public tokenNames;
    address[] public tokenAddresses;

    address[] public compoundAddresses;
    uint256[] public lockedCompoundAPYAmount;
    address[] public compoundAPYs;

    address[] public AAVEAddresses;
    address[] public lockedAAVEAPYAmount;
    address[] public AAVEAPYs;

    uint public currentAPYTokenIndex;
    mapping(uint => uint256) public lastTokenAPYCheck;
    uint[] public tokenProtocol;
    mapping(uint => uint256) public currentTokenAPYRate;

    mapping(uint => uint256) public totalTokenDeposit;
    mapping(address => mapping(uint =>  uint256)) public myTokenDeposit;
    mapping(address => mapping(uint =>  uint256)) public myTokenLockupPeriod;
    mapping(address => mapping(uint =>  uint256)) public lastTokenYieldClaimTime;
    mapping(uint256 => uint256) public lastNFTTokenYieldClaimTime;
}


contract HokkPremium is Ownable, Proxiable, DataLayout {
    using SafeMath for uint256;

    modifier updateAPYProtocol() {
        updateTokenAPY();
        _;
    }

    constructor() {

    }

    function proxyConstructor(
            address _NFTContract,
            address _USDC,
            address _aWETH,
            address _aUSDC,
            address _WETH,
            address _lendingPool) public {
        require(!initialized, "Contract is already initialized");
        setOwnableConstructor();
        NFTContract = _NFTContract;
        USDC = _USDC;
        WETH = _WETH;
        aUSDC = _aUSDC;
        aWETH = _aWETH;
        AAVELendingPool = _lendingPool;
        claimGap = 600;
        initialize();
    }

    function updateCode(address newCode) public onlyOwner delegatedOnly  {
        updateCodeAddress(newCode);

    }

    receive() external payable {
        catchETH(msg.value, msg.sender);
    }

    function updateNFTContract(address _contract) public onlyOwner {
        NFTContract = _contract;
    }

    function setTokenInfo(string memory name, address tokenAddress, address compoundAddress, address AAVEAddress) public onlyOwner {
        tokenNames.push(name);
        tokenAddresses.push(tokenAddress);
        compoundAddresses.push(compoundAddress);
        AAVEAddresses.push(AAVEAddress);
    }

    function setAllTokenNames(string[] memory _names) public onlyOwner {
        tokenNames = _names;
    }

    function setTokenNameAtIndex(string memory _name, uint index) public onlyOwner {
        tokenNames[index] = _name;
    }

    function setAllCompoundAddresses(address[] memory _addresses) public onlyOwner {
        compoundAddresses = _addresses;
    }

    function setCompoundAddressAtIndex(address _address, uint index) public onlyOwner {
        compoundAddresses[index] = _address;
    }

    function setAllAAVEAddresses(address[] memory _addresses) public onlyOwner {
        AAVEAddresses = _addresses;
    }

    function setAAVEAddressAtIndex(address _address, uint index) public onlyOwner {
        AAVEAddresses[index] = _address;
    }

    function updateAAVEAddresses(address _aWETH, address _aUSDC, address _lendingPool, address _WETHGateway) public onlyOwner {
        aWETH = _aWETH;
        aUSDC = _aUSDC;
        AAVELendingPool = _lendingPool;
        WETHGateway = _WETHGateway;
    }

    function setFees(uint256 _claimFee, uint256 _depositFee) public onlyOwner {
        claimFee = _claimFee;
        depositFee = _depositFee;
    }

    function setFeeAddress(address _feeAddress) public {
        feeAddress = _feeAddress;
    }

    function setClaimGap(uint256 time) public onlyOwner {
        claimGap = time;
    }

    function depositTokenAPYAmount(uint index, uint256 amount) public payable onlyOwner {
        if (keccak256(abi.encodePacked((tokenNames[index]))) == keccak256(abi.encodePacked(("ETH")))) {
            require(amount == 0, "ETH deposits use msg.value");
            //deposit value to protocols
            depositToProtocol(tokenProtocol[index], msg.value.div(2), address(this), index, 0);
        } else {
            //deposit amount
            depositToProtocol(tokenProtocol[index], amount.div(2), address(this), index, 0);
        }
    }

    function manualAPYTrigger() public {
        updateTokenAPY();
    }

    function withdrawFromProtocol(uint _protocol, uint256 amount, uint _index, address user, uint256 fees) internal {
        if (_protocol == 0) {
            if (keccak256(abi.encodePacked((tokenNames[_index]))) == keccak256(abi.encodePacked(("ETH")))) {
                IERC20(AAVEAddresses[_index]).approve(WETHGateway, amount);
                aWETHGateway(WETHGateway)
                    .withdrawETH(
                        AAVELendingPool,
                        amount,
                        address(this));
                (bool sent, bytes memory data) = user.call{value: amount.sub(fees)}("");
            } else {
                IERC20(AAVEAddresses[_index]).approve(AAVELendingPool, amount);
                AAVEAssetGateway(AAVELendingPool)
                    .withdraw(
                        tokenAddresses[_index],
                        amount,
                        address(this)
                    );
            }
        }
        if (_protocol == 1) {
            if (keccak256(abi.encodePacked((tokenNames[_index]))) == keccak256(abi.encodePacked(("ETH")))) {
                IERC20(compoundAddresses[_index]).approve(compoundAddresses[_index], IERC20(compoundAddresses[_index]).balanceOf(address(this)));
                CompoundETH(compoundAddresses[_index])
                    .redeem(IERC20(compoundAddresses[_index]).balanceOf(address(this)));
            } else {

            }
        }

        myTokenDeposit[user][_index] = myTokenDeposit[user][_index].sub(amount);
        totalTokenDeposit[_index] = totalTokenDeposit[_index].sub(amount);
    }

    function depositToProtocol(uint _protocol, uint256 amount, address _user, uint _index, uint256 fees) internal {
        if (_protocol == 0) {
            if (keccak256(abi.encodePacked((tokenNames[_index]))) == keccak256(abi.encodePacked(("ETH")))) {
                uint256 startingAWETH = IERC20(tokenAddresses[_index]).balanceOf(address(this));
                aWETHGateway(WETHGateway)
                    .depositETH{ value: amount.sub(fees) }(
                        AAVELendingPool,
                        _user,
                        93);
                uint256 currentAWETH = IERC20(tokenAddresses[_index]).balanceOf(address(this));
                myTokenDeposit[_user][_index] = myTokenDeposit[_user][_index].add(currentAWETH.sub(startingAWETH));
                totalTokenDeposit[_index] = totalTokenDeposit[_index].add(currentAWETH.sub(startingAWETH));
            } else {
                uint256 startingAmount = IERC20(AAVEAddresses[_index]).balanceOf(address(this));
                IERC20(AAVEAddresses[_index]).approve(AAVELendingPool, IERC20(AAVEAddresses[_index]).balanceOf(address(this)));
                AAVEAssetGateway(AAVELendingPool)
                .deposit(
                    tokenAddresses[_index],
                    amount.sub(fees),
                    address(this), 93
                );
                uint256 currentAmount = IERC20(AAVEAddresses[_index]).balanceOf(address(this));
                //how to manage user balances??
                myTokenDeposit[_user][_index] = myTokenDeposit[_user][_index].add(currentAmount.sub(startingAmount));
                totalTokenDeposit[_index] = totalTokenDeposit[_index].add(currentAmount.sub(startingAmount));
            }
        }
        if (_protocol == 1) {
            if (keccak256(abi.encodePacked((tokenNames[_index]))) == keccak256(abi.encodePacked(("ETH"))))  {
                uint256 startingCETH = IERC20(compoundAddresses[_index]).balanceOf(address(this));
                CompoundETH(compoundAddresses[_index])
                    .mint{value: amount.sub(fees)}();
                uint256 currentCETH = IERC20(compoundAddresses[_index]).balanceOf(address(this));
                myTokenDeposit[_user][_index] = myTokenDeposit[_user][_index].add(currentCETH.sub(startingCETH));
                totalTokenDeposit[_index] = totalTokenDeposit[_index].add(currentCETH.sub(startingCETH));
            } else {
                uint256 startingAmount = IERC20(compoundAddresses[_index]).balanceOf(address(this));
                IERC20(tokenAddresses[_index]).approve(compoundAddresses[_index], totalUSDCDeposit);
                CompoundUSD(compoundAddresses[_index])
                    .mint(
                        amount.sub(fees)
                    );
                uint256 currentAmount = IERC20(compoundAddresses[_index]).balanceOf(address(this));
                myTokenDeposit[_user][_index] = myTokenDeposit[_user][_index].add(amount.sub(fees));
                totalTokenDeposit[_index] = totalTokenDeposit[_index].add(amount.sub(fees));
            }
        }
    }

    function updateTokenAPY() public {
        if (block.timestamp.sub(lastTokenAPYCheck[currentAPYTokenIndex]) > 600) {
            uint256 currentAAVEAPYYield;
            uint256 currentCompoundAPYYield;
            uint256 AAVERate;
            uint topProtocol;
            uint256 topRate;
            if (compoundAddresses[currentAPYTokenIndex] != address(0)) {
                currentCompoundAPYYield = determineUserTokenYield(address(this), 1, currentAPYTokenIndex);
                if (topRate < (uint256(600).div(600))*((lockedCompoundAPYAmount[currentAPYTokenIndex]+currentCompoundAPYYield).mul(100)/(lockedCompoundAPYAmount[currentAPYTokenIndex]) - 1)) {
                    topProtocol = 1;
                    topRate = (uint256(600).div(600))*((compoundAPYETH+currentCompoundAPYYield).mul(100)/(AAVEAPYETH) - 1);
                }
            }
            if (AAVEAddresses[currentAPYTokenIndex] != address(0)) {
                currentAAVEAPYYield = determineUserTokenYield(address(this), 0,  currentAPYTokenIndex);
                if (topRate < (uint256(600).div(600))*((lockedCompoundAPYAmount[currentAPYTokenIndex]+currentAAVEAPYYield).mul(100)/(lockedCompoundAPYAmount[currentAPYTokenIndex]) - 1)) {
                    topProtocol = 0;
                    topRate = (uint256(600).div(600))*((lockedCompoundAPYAmount[currentAPYTokenIndex]+currentAAVEAPYYield).mul(100)/(lockedCompoundAPYAmount[currentAPYTokenIndex]) - 1);
                }
            }

            if (topProtocol == tokenProtocol[currentAPYTokenIndex]) {
                return;
            }

            withdrawFromProtocol(tokenProtocol[currentAPYTokenIndex], totalTokenDeposit[currentAPYTokenIndex], currentAPYTokenIndex, address(this), 0);
            depositToProtocol(
                topProtocol, IERC20(tokenAddresses[currentAPYTokenIndex]).balanceOf(address(this)),
                address(this), currentAPYTokenIndex, 0);
            tokenProtocol[currentAPYTokenIndex] = topProtocol;
            currentTokenAPYRate[currentAPYTokenIndex] = topRate;
            currentAPYTokenIndex = currentAPYTokenIndex+1;
            if (currentAPYTokenIndex > tokenNames.length-1) {
                currentAPYTokenIndex = 0;
            }
        }
    }

    function deposit(uint256 lockupPeriod, uint tokenIndex, uint256 amount) public payable updateAPYProtocol {
        require(lockupPeriod >= 100 , "Longer Lockup period required");
        myTokenLockupPeriod[msg.sender][tokenIndex] = block.timestamp.add(lockupPeriod);
        uint256 fees;
        if (keccak256(abi.encodePacked((tokenNames[tokenIndex]))) == keccak256(abi.encodePacked(("ETH")))) {
            IERC20(tokenAddresses[tokenIndex]).transferFrom(msg.sender, address(this), amount);
            if (depositFee > 0) {
                fees = amount.mul(depositFee).div(10000);
                (bool sent, bytes memory data) = feeAddress.call{value: fees}("");
            }
            depositToProtocol(tokenProtocol[tokenIndex], amount, msg.sender, tokenIndex, fees);
        } else {
            if (depositFee > 0) {
                fees = msg.value.mul(depositFee).div(10000);
                (bool sent, bytes memory data) = feeAddress.call{value: fees}("");
            }
            depositToProtocol(tokenProtocol[tokenIndex], msg.value, msg.sender, tokenIndex, fees);
        }

        if (myTokenLockupPeriod[msg.sender][tokenIndex] < block.timestamp) {
            myTokenLockupPeriod[msg.sender][tokenIndex] = lockupPeriod;
        }

    }

    function depositNFTTokens(uint256 amount, uint tokenIndex) public payable updateAPYProtocol {
        myTokenLockupPeriod[msg.sender][tokenIndex] = block.timestamp.add(52 weeks);
        if (keccak256(abi.encodePacked((tokenNames[tokenIndex]))) == keccak256(abi.encodePacked(("ETH")))) {
            IERC20(tokenAddresses[tokenIndex]).transferFrom(msg.sender, address(this), amount);
            depositToProtocol(tokenProtocol[tokenIndex], amount, NFTContract, tokenIndex, 0);
        } else {
            depositToProtocol(tokenProtocol[tokenIndex], msg.value, NFTContract, tokenIndex, 0);
        }

        uint256 startingAmount = IERC20(aUSDC).balanceOf(address(this));
        myUSDCLockupPeriod[NFTContract] = block.timestamp.add(52 weeks);
        //send to current USDC protocol
        depositToProtocol(tokenProtocol[tokenIndex], msg.value, NFTContract, tokenIndex, 0);
    }

    function withdraw(uint256 amount, uint tokenIndex) public updateAPYProtocol {
        require(myTokenDeposit[msg.sender][tokenIndex] > 0, "Deposit amount must be greater than 0");
        require(myTokenLockupPeriod[msg.sender][tokenIndex] < block.timestamp, "Lockup has not expired");
        require(myTokenDeposit[msg.sender][tokenIndex] >= amount, "Insufficient amount");
        withdrawFromProtocol(tokenProtocol[tokenIndex], amount, tokenIndex, msg.sender, tokenIndex);
    }


    function catchETH(uint256 amount, address user) internal {
        myETHLockupPeriod[user] = block.timestamp.add(12 weeks);
        myETHDeposit[user] = myETHDeposit[user] + amount;
        totalETHDeposit = totalETHDeposit.add(amount);

        depositToProtocol(tokenProtocol[0], msg.value, NFTContract, 0, 0);
    }

    function getMyTokenDeposit(uint index, address user) public view returns(uint256) {
        return(myTokenDeposit[user][index]);
    }

    function getTokenCurrentAPY(uint tokenIndex) public view returns(uint256) {
        //get token's protocol
        //return token's APY in protocol
        return currentTokenAPYRate[tokenIndex];
    }

    function getUserNFTIDs(address user) public view returns(uint256[] memory) {
        uint256 userBalance = HOKKNFT(NFTContract).balanceOf(user);
        uint256[] memory tokenIDs = new uint[](userBalance);
        for (uint256 i; (i < userBalance); i++) {

            tokenIDs[i] = HOKKNFT(NFTContract).tokenOfOwnerByIndex(user, i);
        }
        return tokenIDs;
    }

    function getUserData(address user) public view returns(
        uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        return(
            getUserTokenDeposits(user),
            getCurrentTokenAPYRates(user),
            getUserTokenLockupPeriod(user),
            getUserTokenYields(user),
            getUserNFTIDs(user)
        );
    }

    function getUserTokenDeposits(address user) public view returns(uint256[] memory) {
        uint256[] memory deposits = new uint256[](tokenNames.length);
        for (uint i; i < tokenNames.length; i++) {
            deposits[i] = myTokenDeposit[user][i];
        }
        return deposits;
    }

    function getUserTokenLockupPeriod(address user) public view returns(uint256[] memory) {
        uint256[] memory lockups = new uint256[](tokenNames.length);
        for (uint i; i < tokenNames.length; i++) {
            lockups[i] = myTokenLockupPeriod[user][i];
        }
        return lockups;
    }

    function getCurrentTokenAPYRates(address user) public view returns(uint256[] memory) {
        uint256[] memory rates = new uint256[](tokenNames.length);
        for (uint i; i < tokenNames.length; i++) {
            rates[i] = currentTokenAPYRate[i];
        }
        return rates;
    }

    function getUserTokenYields(address user) public view returns(
        uint256[] memory
    ) {
        uint256[] memory yield = new uint256[](tokenNames.length);
        for (uint i; i < tokenNames.length; i++) {
            yield[i] = determineUserTokenYield(user, tokenProtocol[i], i);
        }
        return(
            yield
        );
    }

    function determineUserTokenYield(address user, uint protocol, uint index) public view returns(uint256) {
        //determine address yield using user deposit and total deposit amount/current protocol amount
        if (protocol == 0) {
            uint256 contractDeposit = IERC20(AAVEAddresses[index]).balanceOf(address(this));
            //get user ratio of amount in protocol - total deposited
            if (contractDeposit > 0 && myTokenDeposit[user][index] > 0 && totalTokenDeposit[index] > 0) {
                return myTokenDeposit[user][index].mul(contractDeposit.sub(totalTokenDeposit[index])).div(totalTokenDeposit[index]);
            } else {
                return 0;
            }
        }
        if (protocol == 1) {
            uint256 contractDeposit = IERC20(compoundAddresses[index]).balanceOf(address(this));
            //get user ratio of amount in protocol - total deposited
            if (contractDeposit > 0 && myTokenDeposit[user][index] > 0 && totalTokenDeposit[index] > 0) {
                //get current EXP mantissa and truncate(1e18)
                uint256 mantissa;
                uint256 underlyingAmount = contractDeposit.mul(mantissa) / 1e18;
                return myTokenDeposit[user][index].mul(underlyingAmount).div(totalTokenDeposit[index]);
            } else {
                return 0;
            }
        }
        return 0;
    }

    function getNFTTokenYield(uint256 tokenID, uint tokenIndex) public view returns(uint256) {
        uint256 currentNFTYield = determineUserTokenYield(NFTContract, tokenProtocol[tokenIndex], tokenIndex);
        if (currentNFTYield > HOKKNFT(NFTContract).totalSupply()) {
            currentNFTYield = currentNFTYield.div(HOKKNFT(NFTContract).totalSupply());
            if (block.timestamp.sub(lastNFTTokenYieldClaimTime[tokenID]) > claimGap) {
                return currentNFTYield;
            }

        }
        return 0;
    }

    function claimTokenYield(uint tokenIndex) public {
        uint256 yieldAmount = determineUserTokenYield(msg.sender, tokenProtocol[tokenIndex], tokenIndex);
        if (yieldAmount > 0 && (block.timestamp.sub(lastTokenYieldClaimTime[msg.sender][tokenIndex]) > claimGap)) {
            withdraw(yieldAmount, tokenIndex);
            lastTokenYieldClaimTime[msg.sender][tokenIndex] = block.timestamp;
        }
    }

    function claimNFTTokenYield(uint256[] memory tokenIDs, uint tokenIndex) public {
        for (uint256 i; i < tokenIDs.length; i++) {
            uint256 yieldAmount = determineUserTokenYield(NFTContract, tokenProtocol[tokenIndex], tokenIndex);
            uint256 NFTSupply = HOKKNFT(NFTContract).totalSupply();
            if (yieldAmount > NFTSupply) {
                if (block.timestamp.sub(lastNFTTokenYieldClaimTime[tokenIDs[i]]) > claimGap) {
                    withdraw(yieldAmount, tokenIndex);
                    lastNFTTokenYieldClaimTime[tokenIDs[i]] = block.timestamp;
                }
            }
        }
    }


}

interface CompoundUSD {
    function mint(uint256 mintAmount) external returns(uint);
    function redeem(uint redeemTokens) external returns(uint);
}

interface CompoundETH {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
}