/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// File: BDK.sol

/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/


pragma solidity ^0.6.12;


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

// 
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

// 
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

// 
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

// 
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

// 
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

// 
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

// 
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

// 
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

// 
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
//???????????????
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    //??????data.length == 0,??????????????????usdt, ?????????????????????????????????????????? ????????????U ?????????data,???????????????false!!
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract BDK is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name = "Bull Demon King";
    string private _symbol = "BDK";
    uint8 private _decimals = 10;
    uint256 private _totalSupply = 100000000000* 10**10;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;//???????????????
    
    mapping (uint256 => address) public poolUsers;//????????????
    mapping (address => uint256) public _bOwned;//???????????????????????????
    mapping (address => uint256) public _tOwned;//??????????????????????????????
    mapping (address => uint256) private lastLiquidityTime;//??????????????????????????????
    mapping (address => uint256) private bBuyLimit;//????????????BOk????????????
    mapping (address => uint256) private bUserSwap;//??????????????????????????????
    mapping (address => uint256) private dayMine;//????????????????????????BDK
    mapping (address => uint256) private totalMine;//????????????????????????BDK
    mapping (address => uint256) private dayFund;//?????????????????????????????????TRX
    mapping (address => uint256) private totalFund;//?????????????????????????????????TRX
    mapping (address => uint256) private bDraw;//???????????????BDK??????
    mapping (address => uint256) private bSurplus;//?????????????????????BDK??????
    mapping (address => uint256) private tDraw;//??????????????????TRX??????
    mapping (address => uint256) private tSurplus;//????????????????????????TRX??????
    
    mapping (address => bool) public transferEnable;//??????????????????
    mapping (address => bool) private _isExcluded;//????????????
    
    uint256 public totalPoolUser = 0;//??????????????????
    uint256 public bMineMax = 60000000000* 10**10;//????????????600???
    uint256 public bMineTotal = 0;//?????????BDk??????
    uint256 public bSwapMax = 30000000000* 10**10;//?????????????????????????????????
    uint256 public bSwapTotal = 0;//????????????????????????????????????
    uint256 public bStopBurn = 1000000000* 10**10;//????????????10??????????????????
    uint256 public bBuyMax = 100000000* 10**10;//??????????????????BDk????????????1???
    uint256 public bPoolTotal = 0;//????????????????????????BDK??????
    uint256 public tPoolTotal = 0;//????????????????????????trx??????
    uint256 public bFundTotal = 0;//??????????????????BDK?????????
    uint256 public tFundTotal = 0;//???????????????TRX?????????
    uint256 public tFundOld = 0;//??????????????????????????????TRX??????
    uint256 public lastSettlementTime = 0;//??????????????????
    uint256 public _begin = 8;//??????????????????,??????
    uint256 public _duration = 30;//??????????????????,??????
    uint256 public bTotalBurn = 0;//??????????????????

    uint256 private _bTotal = 100000000000 * 10**10;//???????????????1000???
    
    uint256 public _taxFee = 10;//?????????????????????
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 10;//??????????????????
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    // bool inSwapAndLiquify;
    bool public tradeEnabled = true;
    
    event TradeEnabled(bool enabled);//?????????????????????????????????
    event SwapAndLiquify(
        uint256 tokensSwapped,//?????????????????????
        uint256 ethReceived,//?????????ETH
        uint256 tokensIntoLiqudity////???????????????????????????
    );
    
    //?????????????????????
    /*modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }*/
    
    constructor () public {
        _mint(owner(), 30000000000 * (10**10));
        _mint(address(this), 70000000000 * (10**10));
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1F98431c8aD98523631AE4a59f267346ea31F984);//PancakeRouter?????????
        
        //??????????????????????????????????????????
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());//_uniswapV2Router.WETH()???ETH??????

        //???????????????????????????
        uniswapV2Router = _uniswapV2Router;
        
        //??????????????????????????????
        _isExcluded[owner()] = true;
        _isExcluded[address(this)] = true;
        transferEnable[owner()] = true;
        transferEnable[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _bTotal);
    }
    
    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public immutable tokenB = address(this);
    address public immutable tokenT = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
       return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
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
    
    //???????????????UNISWAPv2??????ETH
    receive() external payable {}
    
    function ownerWithdrew(uint256 amount) public  onlyOwner{
        
        amount = amount * 10 **10;
        
        uint256 dexBalance = balanceOf(address(this));
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Not enough tokens in the reserve");
        
        transfer(msg.sender, amount);
    }
    
    function ownerDeposit(uint256 amount ) public onlyOwner {
        
        amount = amount * 10 **10;

        uint256 dexBalance = balanceOf(msg.sender);
        
        require(amount > 0, "You need to send some ether");
        
        require(amount <= dexBalance, "Dont hava enough EMSC");
        
        transferFrom(msg.sender, address(this), amount);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        //????????????
        autoSetTradeEnabled();
        require(tradeEnabled,"now is limit time");
        
        //??????????????????????????????
        if(sender == owner() && !transferEnable[sender]){
                transferEnable[sender] = true;
        }
        
        if(recipient == owner() && !transferEnable[recipient]){
                transferEnable[sender] = true;
        }
        
        if(sender == uniswapV2Pair &&  recipient != owner() &&  recipient != address(this) && lastLiquidityTime[recipient] == 0){
            
            totalPoolUser ++;
            
            poolUsers[totalPoolUser] = recipient;
            
            bUserSwap[recipient] += amount;
            
            //????????????????????????
            require(_notExceedLimit(recipient),"purchase limit exceeded");
            
            // split the contract balance into halves
            uint256 half = amount.div(2);
            uint256 otherHalf = amount.sub(half);
    
            // ??????ETH?????????
            uint256 initialBalance = address(recipient).balance;//?????????ETH??????
            
            //???????????????ETH,??????
            _swapTokenForEth(recipient, otherHalf); //????????????+??????????????????????????????
    
            //??????ETH????????????
            uint256 newBalance = address(recipient).balance.sub(initialBalance);
            
            _addLiquidity(recipient, half, newBalance);
            
            lastLiquidityTime[recipient] = block.timestamp;
            
            bSwapTotal += amount;
            
        }else{
            
            if(sender == uniswapV2Pair ){
                
                require(transferEnable[recipient],"recipient is disable"); 
                
            }else{
                
                require(transferEnable[sender],"transfer is disable"); 
                
            }
            
            _beforeTokenTransfer(sender, recipient, amount);
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
            
        }
        
        emit Transfer(sender, recipient, amount);
        
    }
    
    
    //????????????????????????
    function _notExceedLimit(address user) internal virtual returns (bool){
            
        if(user == owner()){
            
            return true;
            
        }
        
        bBuyLimit[user] = _bBuyMax();
        
        if(bUserSwap[user] <= bBuyLimit[user]){
            
            return true;
            
        } else {
            
            return false;
            
        }
        
    }
    
    
    //????????????,?????????????????????10%?????????
    function userTransfer(address recipient,uint256 amount) public {
        
        if(transferEnable[msg.sender]){
            
            if(_isExcluded[msg.sender]){
                transfer(recipient,amount);
            }
        
            if(!_isExcluded[msg.sender]){
                transfer(address(this),amount.mul(_taxFee).div(100));
                bFundTotal += amount.mul(_taxFee).div(100);
                transfer(recipient,amount.mul(100-_taxFee).div(100));
            }
            
        }else{
            
            transferEnable[msg.sender] = true;
            
            if(_isExcluded[msg.sender]){
                transfer(recipient,amount);
            }
        
            if(!_isExcluded[msg.sender]){
                transfer(address(this),amount.mul(_taxFee).div(100));
                bFundTotal += amount.mul(_taxFee).div(100);
                transfer(recipient,amount.mul(100-_taxFee).div(100));
            }
            
            transferEnable[msg.sender] = false;
            
        }
        
    }
    
    //trx?????????????????????????????????
    function swapAndLiquify(uint256 amountT) public {
        
        _swapAndLiquify(msg.sender, amountT);
        
    }
    
    //trx?????????????????????????????????
    function _swapAndLiquify(address user,uint256 amountT) internal virtual {
        
        require(amountT > 0,"swap number is zore");
        
        //?????????????????????????????????
        if(lastLiquidityTime[user] == 0){
            
            totalPoolUser ++;
            
            poolUsers[totalPoolUser] = user;
            
        }
        
        lastLiquidityTime[user] = block.timestamp;
        
        // split the contract balance into halves
        uint256 half = amountT.div(2);
        uint256 otherHalf = amountT.sub(half);

        // ????????????token?????????
        uint256 initialBalance = balanceOf(user);//?????????ETH??????

        //??????ETH?????????,??????
        swapEthForToken(half); //????????????+????????????????????????

        //??????token????????????,??????????????????0.3%
        uint256 newBalance = balanceOf(user).sub(initialBalance);
        
        bUserSwap[user] += newBalance;
        
        //????????????????????????
        require(_notExceedLimit(user),"purchase limit exceeded");
        
        bSwapTotal += newBalance;
        
        if(_isExcluded[user]){
            
            if(transferEnable[user]){
            
                // add liquidity to uniswap
                _addLiquidity(user, newBalance, otherHalf);//????????????100%???????????????????????????
            
            }else {
                
                transferEnable[user] = true;
                
                // add liquidity to uniswap
                _addLiquidity(user, newBalance, otherHalf);//????????????100%???????????????????????????
                
                transferEnable[user] = false;
            }
            
            
        }else{
            
            // add liquidity to uniswap,90%
            uint256 tAmount = otherHalf.mul(100 - _liquidityFee).div(100);
            uint256 bAmount = newBalance.mul(100 - _liquidityFee).div(100);
            
            if(transferEnable[user]){
                
                if(bSwapMax - bSwapTotal > bStopBurn){//??????????????????10?????????????????????
            
                    // TransferHelper.safeTransferFrom(tokenB,msg.sender,deadWallet,newBalance.mul(_liquidityFee).div(100));//10%BDK?????????
                    transfer(deadWallet, newBalance.mul(_liquidityFee).div(100));
                
                }
                
                //????????????????????????10%TRX
                TransferHelper.safeTransferFrom(tokenT,user,address(this),otherHalf.mul(_liquidityFee).div(100));//10%TRX?????????????????????
                tFundTotal += otherHalf.mul(_liquidityFee).div(100);
                
                // add liquidity to uniswap
                _addLiquidity(user, bAmount, tAmount);//???????????????????????????????????????
            
            }else {
                
                transferEnable[user] = true;
                
                //??????????????????10?????????????????????
                if(bSwapMax - bSwapTotal >= bStopBurn){
            
                    // TransferHelper.safeTransferFrom(tokenB,msg.sender,deadWallet,newBalance.mul(_liquidityFee).div(100));//10%BDK?????????
                    transfer(deadWallet, newBalance.mul(_liquidityFee).div(100));
                
                }
                
                //????????????????????????10%TRX
                TransferHelper.safeTransferFrom(tokenT,user,address(this),otherHalf.mul(_liquidityFee).div(100));
                tFundTotal += otherHalf.mul(_liquidityFee).div(100);
                
                // add liquidity to uniswap
                _addLiquidity(user, bAmount, tAmount);
                
                transferEnable[user] = false;
            }
            
        }
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
        
    }

    // ???????????????ETH
    function swapTokenForEth(uint256 amountB) public {
        
        _swapTokenForEth(msg.sender, amountB);
        
    }
    
    // ???????????????ETH
    function _swapTokenForEth(address user, uint256 amountB) internal virtual {
        require(amountB > 0,"swap number is zore");
        require(amountB <= _bTotal, "Amount must be less than total");
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);//????????????
        path[1] = uniswapV2Router.WETH();//uniswapV2Router.WETH()???ETH??????
        
        _approve(user, address(uniswapV2Router), amountB.mul(100-_taxFee).div(100));
        
        
        // ??????ETH?????????
        uint256 initialBalance = address(this).balance;//?????????ETH??????
        
        // ????????????token????????????eth,
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountB.mul(_taxFee).div(100),
            0, // accept any amount of ETH
            path,//?????????????????????
            address(this),//???????????????
            block.timestamp
        );
        
        //??????ETH????????????
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        tFundTotal += newBalance;
        
        if(transferEnable[user]){
            
            // ????????????token????????????eth,
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountB.mul(100-_taxFee).div(100),
                0, // accept any amount of ETH
                path,//?????????????????????
                user,//???????????????
                block.timestamp
            );
            
        }else{
            
            transferEnable[user] = true;
            
            // ????????????token????????????eth,
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountB.mul(100-_taxFee).div(100),
                0, // accept any amount of ETH
                path,//?????????????????????
                user,//???????????????
                block.timestamp
            );
            
            transferEnable[user] = false;
        }
        
    }
    
     // ???????????????ETH
    function swapEthForToken(uint256 amountT) public {
        
        _swapEthForToken(msg.sender, amountT);
        
    }
    
    // ETH???????????????
    function _swapEthForToken(address user, uint256 amountT) internal virtual {
        require(amountT > 0,"swap number is zore");
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);//????????????
        path[1] = uniswapV2Router.WETH();//uniswapV2Router.WETH()???ETH??????

        _approve(user, address(uniswapV2Router), amountT);
        
        if(transferEnable[user]){
            
            // ????????????eth????????????token,
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
                amountT,
                path,//?????????????????????
                user,//???????????????
                block.timestamp
            );
            
        }else {
            
            transferEnable[user] = true;
            
            // ????????????eth????????????token,
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
                amountT,
                path,//?????????????????????
                user,//???????????????
                block.timestamp
            );
            
            transferEnable[user] = false;
        }
        
    }
    
    // ????????????????????????
    function addLiquidity(uint256 amountB, uint256 amountT) public {
        
        require(amountB > 0,"swap number is zore");
        require(amountT > 0,"swap number is zore");
        
        //?????????????????????????????????
        if(lastLiquidityTime[msg.sender] == 0){
            
            totalPoolUser ++;
            
            poolUsers[totalPoolUser] = msg.sender;
            
        }
        
        _addLiquidity(msg.sender, amountB, amountT);
        
        lastLiquidityTime[msg.sender] = block.timestamp;
        
    }
    
    // ????????????????????????
    function _addLiquidity(address user, uint256 amountB, uint256 amountT) internal virtual {
        
        require(amountB > 0,"swap number is zore");
        require(amountT > 0,"swap number is zore");
        
        // approve token transfer to cover all possible scenarios
        _approve(user, address(uniswapV2Router), amountB);
        
        if(transferEnable[user]){
            
            // add the liquidity
            uniswapV2Router.addLiquidity(
                tokenB,
                tokenT,
                amountB,
                amountT,
                0,
                0,
                user,
                block.timestamp
            );
            
        }else {
            
            transferEnable[user] = true;
            
            // add the liquidity
            uniswapV2Router.addLiquidity(
                tokenB,
                tokenT,
                amountB,
                amountT,
                0,
                0,
                user,
                block.timestamp
            );
            
            /*// add the liquidity
            uniswapV2Router.addLiquidityETH{value: ethAmount}(//???????????????????????????????????????eth
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable //eth??????????????????  ?????????Desired???msg.value
                user,//???????????????
                block.timestamp
            );*/
            
            transferEnable[msg.sender] = false;
            
        }
        
        _bOwned[user] += amountB;
        _tOwned[user] += amountT;
        bPoolTotal += amountB;
        tPoolTotal += amountT;
        
    }
    
    // ????????????????????????
    function addLiquidity(uint256 liquidity) public {
        
        _takeLiquidity(msg.sender, liquidity);
        
    }
        
    //???????????????,Liquidity????????????
    function _takeLiquidity(address user, uint256 liquidity) internal virtual {
        require(liquidity > 0,"take liquidity number is zore");
        
        autoSetTradeEnabled();
        require(!tradeEnabled,"now is limit time");//????????????
        transferEnable[user] = true;//????????????????????????
        require(lastLiquidityTime[user] > 0 || _bOwned[user] > 0 || _tOwned[user] > 0, "ERC20: approve from the zero address"); //????????????????????????,???????????????
        
        if(transferEnable[user]){
            
            (uint amountB, uint amountT) =  uniswapV2Router.removeLiquidity(
                    tokenB,
                    tokenT,
                    liquidity,
                    0,
                    0,
                    user,
                    block.timestamp
                );
                
            if(!_isExcluded[user] && lastLiquidityTime[user] + 60 days >= block.timestamp){
                
                //????????????????????????
                transfer(address(this), amountB.mul(50).div(100));
                TransferHelper.safeTransferFrom(tokenT, msg.sender, address(this), amountT.mul(50).div(100));
                
                bFundTotal += amountB.mul(50).div(100);
                tFundTotal += amountT.mul(50).div(100);
                
            }
            
            _bOwned[user] = _bOwned[user].sub(amountB);
            _tOwned[user] = _tOwned[user].sub(amountB);
            bPoolTotal = bPoolTotal.sub(amountB);
            tPoolTotal = tPoolTotal.sub(amountB);
        
        } else {
            
            transferEnable[user] = true;
            
            (uint amountB, uint amountT) =  uniswapV2Router.removeLiquidity(
                    tokenB,
                    tokenT,
                    liquidity,
                    0,
                    0,
                    user,
                    block.timestamp
                );
                
            if(!_isExcluded[user] && lastLiquidityTime[user] + 60 days >= block.timestamp){
                
                //????????????????????????
                transfer(address(this), amountB.mul(50).div(100));
                TransferHelper.safeTransferFrom(tokenT, user, address(this), amountT.mul(50).div(100));
                
                bFundTotal += amountB.mul(50).div(100);
                tFundTotal += amountT.mul(50).div(100);
                
            }
            
            _bOwned[user] = _bOwned[user].sub(amountB);
            _tOwned[user] = _tOwned[user].sub(amountB);
            bPoolTotal = bPoolTotal.sub(amountB);
            tPoolTotal = tPoolTotal.sub(amountB);
            
            transferEnable[user] = false;
            
        } 
        
    }
    
    //?????? ????????????
    function mining() public onlyOwner {
        
        require((block.timestamp/24 hours)-(lastSettlementTime/24 hours) >= 1,"");//????????????????????????????????????
        
        //?????????????????????
        autoSetTradeEnabled();
        require(!tradeEnabled,"now is limit time");
        
        require(bMineTotal < bMineMax,"up to _bMineMax,stop mining");
        
        //????????????BDK??????
        uint256 bNum = bPoolTotal.mul(_mineRate().div(100));
        
        //???????????????BDK??????
        bMineTotal += bNum;
        
        if(bMineTotal > bMineMax){//??????????????????BDK????????????600???,
            bNum = bNum - (bMineTotal - bMineMax);//?????????????????? 
            bMineTotal = bMineMax;
            
            //??????100?????????
            transferFrom(address(this), deadWallet, 10000000000* 10**10);
        }
        
        //10%BDk?????????????????????
        bFundTotal += bNum.mul(10).div(100);
        
        //??????90%BDK
        bNum = bNum.mul(90).div(100);
        
        //?????????????????????TRX??????
        uint256 _tFund = tFundTotal - tFundOld;
        
        //?????????????????????TRX?????????30%????????????
        uint256 tFundUser = _tFund.mul(30).div(100);
        
        //??????????????????
        for(uint256 i = 1; i < totalPoolUser; i++){
            
            address user = poolUsers[i];
            
            //????????????????????????BDK
            dayMine[user] = bNum.mul(_bOwned[user]).div(bPoolTotal);
            
            //????????????????????????BDK
            totalMine[user] += dayMine[user]; 
            
            //?????????????????????????????????TRX
            dayFund[user] = tFundUser.mul(_bOwned[user]).div(bPoolTotal);
            
            //?????????????????????????????????TRX
            totalFund[user] += dayFund[user];
            
            //?????????????????????BDK,TRX??????
            bSurplus[user] += dayMine[user];
            tSurplus[user] += dayFund[user]; 
        }
        
        //??????????????????
        lastSettlementTime = block.timestamp;
        
        //??????????????????????????????TRX??????
        tFundOld = tFundTotal;
    }
    
    //????????????BDK??????
    function drawB(uint256 bNum) public {
        
        //??????????????????
        autoSetTradeEnabled();
        require(tradeEnabled,"now is limit time");
        
        //????????????????????????
        require(bSurplus[msg.sender] > 0 || bSurplus[msg.sender] > bNum,"");
        
        //??????????????????BDK??????
        bDraw[msg.sender] += bNum;
        
        //??????????????????BDK??????
        bSurplus[msg.sender] = bSurplus[msg.sender].sub(bNum);
        
        if(transferEnable[msg.sender]){
            
            transferFrom(address(this), msg.sender, bNum);
            
        }else {
            
            transferEnable[msg.sender] = true;
            
            transferFrom(address(this), msg.sender, bNum);
            
            transferEnable[msg.sender] = false;
            
        }
        
    }
    
    //????????????TRX??????
    function drawT(uint256 tNum) public {
        
        //??????????????????
        autoSetTradeEnabled();
        require(tradeEnabled,"now is limit time");
        
        //????????????????????????
        require(tSurplus[msg.sender] > 0 || tSurplus[msg.sender] > tNum,"");
        
        //??????????????????TRX??????
        tDraw[msg.sender] += tNum;
        
        //??????????????????TRX??????
        tSurplus[msg.sender] = tSurplus[msg.sender].sub(tNum);
        
        //???????????????
        TransferHelper.safeTransferFrom(tokenB, address(this), msg.sender, tNum);
    }
    
    //??????????????????
    function isExcluded(address account) external onlyOwner returns (bool) {
        _isExcluded[account] = true;
        return _isExcluded[account];
    }
    
    //????????????
    function notExcluded(address account) external onlyOwner returns (bool) {
        _isExcluded[account] = false;
        return _isExcluded[account];
    }
    
    //???????????????????????????
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee >= 0 && taxFee < 100,"");
        _taxFee = taxFee;
    }
    
    //???????????????????????????
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee >= 0 && liquidityFee < 100,"");
        _liquidityFee = liquidityFee;
    }
    
    //????????????????????????
    function setTradeEnabled(bool _enabled) external onlyOwner {
        tradeEnabled = _enabled;
        emit TradeEnabled(_enabled);
    }
    
    //???????????????????????? Settlement time
    function autoSetTradeEnabled() public onlyOwner {
        // if((block.timestamp % 24 hours) > (_begin hours) && (block.timestamp % 24 hours) < ((_begin hours).add(_duration minutes)) ){
        if((block.timestamp % 24 hours) > (20 hours) && (block.timestamp % 24 hours) < (21 hours)){
            tradeEnabled = false;
        }else{
            tradeEnabled = true;
        }
        
        emit TradeEnabled(tradeEnabled);
    }
    
    //????????????????????????
    function setSettlementDuration(uint256 begin, uint256 duration)  public onlyOwner returns (uint256 _begin, uint256 _duration){
        return (begin , duration);
    }
    
    //????????????
    function removeAllFee() public onlyOwner {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    //????????????
    function restoreAllFee() public onlyOwner {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    //????????????BDK????????????
    function _bBuyMax() internal virtual returns (uint256) {
        
        if(0 <= bMineTotal && bMineTotal <= 500000000){
            bBuyMax = 100000000;
        }
        if(500000000 < bMineTotal && bMineTotal <= 2000000000){
            bBuyMax = 80000000;
        }
        if(2000000000 < bMineTotal && bMineTotal <= 10000000000){
            bBuyMax = 64000000;
        }
        if(10000000000 < bMineTotal && bMineTotal <= 20000000000){
            bBuyMax = 51000000;
        }
        if(20000000000 < bMineTotal && bMineTotal <= 30000000000){
            bBuyMax = 41000000;
        }
        if(30000000000 < bMineTotal && bMineTotal <= 40000000000){
            bBuyMax = 33000000;
        }
        if(40000000000 < bMineTotal && bMineTotal <= 50000000000){
            bBuyMax = 26000000;
        }
        if(50000000000 < bMineTotal && bMineTotal <= 60000000000){
            bBuyMax = 21000000;
        }
        // if(60000000000 < mineBDK && mineBDK <= 70000000000){
        //     mineRate = 17;
        // }
        return bBuyMax;
    }
    
    //????????????,20%??????
    function _mineRate() internal virtual returns (uint256 mineRate){
        
        if(0 <= bMineTotal && bMineTotal <= 500000000){
            mineRate = 100;
        }
        if(500000000 < bMineTotal && bMineTotal <= 2000000000){
            mineRate = 80;
        }
        if(2000000000 < bMineTotal && bMineTotal <= 10000000000){
            mineRate = 64;
        }
        if(10000000000 < bMineTotal && bMineTotal <= 20000000000){
            mineRate = 51;
        }
        if(20000000000 < bMineTotal && bMineTotal <= 30000000000){
            mineRate = 41;
        }
        if(30000000000 < bMineTotal && bMineTotal <= 40000000000){
            mineRate = 33;
        }
        if(40000000000 < bMineTotal && bMineTotal <= 50000000000){
            mineRate = 26;
        }
        if(50000000000 < bMineTotal && bMineTotal <= 60000000000){
            mineRate = 21;
        }
        if(60000000000 < bMineTotal && bMineTotal <= 70000000000){
            mineRate = 0;
        }
        return mineRate;
    }
   
}