/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

/**
 *Submitted for verification at snowtrace.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: uniswap/uniswap.sol


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
// File: github/OpenZeppelin/openzeppelin-contracts/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
// File: github/OpenZeppelin/openzeppelin-contracts/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: github/OpenZeppelin/openzeppelin-contracts/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: github/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts/cuedTokenSimple.sol



/*
    Generated by CUE Launcher (https://cuelauncher.com), this token has protections in place to prevent it becoming a honeypot

    Buy and sell taxes CANNOT be changed above 25%, this feature protects holders against dev raising taxes too high.

    Max hold amount & Max transaction amount can be increased but not decreased, this protects holders against a honeypot.

    All of the above protections ensure the devs cannot change the token into a honeypot.
*/

pragma solidity ^0.6.12;







contract CUELauncherToken is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) public _rOwned;
    mapping (address => uint256) public _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address payable public _wMarketing;
    address payable public _wDev;

    //buy tax
    uint256 public _maxBuyTax = 25;   // max 25% total buy tax
    uint256 public _currentBuyTax;   // total buy tax
    uint256 public _totalBuyTax;   // total buy tax
    uint256 private _previousRefBuyTax;

    //sell tax
    uint256 public _maxSellTax = 25;   // max 25% total buy tax // format: 25 = 25%
    uint256 public _currentSellTax;   // total sell tax // format: 10 = 10%
    uint256 public _totalSellTax;   // total sell tax // format: 10 = 10%

    uint256 private _previousRefSellTax; 
    
    uint256 public _refPer; // format: 1 = 1%

    //use percentage function so value is different to refPer, these values are after reflection has been done. 
    //reflection is zero, but can be changed in the future.
    uint256 public _autoLiqPer;  // format: 20% = 2000

    uint256 public _burnPer; // format: 20% = 2000

    uint256 public _devPer;  // format: 20% = 2000

    uint256 public _marketingPer;  // format: 20% = 2000

    //stats
    uint256 public _liqAllTime;
    uint256 public _marketingAllTime;
    uint256 public _devAllTime;
    uint256 public _burnAllTime;
                                     
    uint256 public _maxHoldAmount; // format: amount of tokens in wei
    uint256 public _maxTransAmount; // format: amount of tokens in wei
    uint256 public _minTokensForLiquidity; // format: amount of tokens in wei
    uint256 public _remove_limits_time; 
    
    bool public _autoTaxEnabled = true;
    bool public _lockLiquiditiesEnabled = true;
    bool _inLockLiquidities;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    modifier lockLiquidities{
        _inLockLiquidities = true;
        _;
        _inLockLiquidities = false;
    }

    constructor (
        string memory __name,
        string memory __symbol,
        uint8 __decimals,
        uint256 __tTotal,
        address payable __wMarketing,
        address payable __wDev,
        uint256[6] memory __buy_data,    // [buy_tax, tax_reflections, tax_auto_liq, tax_dev, tax_burn, tax_marketing]
        uint256[1] memory __sell_data,   // [sell_tax]
        uint256[4] memory __data,        // [run_tokenomics, max_tx, max_hold, remove_limits_limit]
        address __router,
        address __sender
    ) public {

        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _tTotal = __tTotal;

        _wMarketing = __wMarketing;
        _wDev = __wDev;

        _currentBuyTax = __buy_data[0];
        _totalBuyTax = __buy_data[0];
        _previousRefBuyTax = 0;

        _currentSellTax = __sell_data[0];
        _totalSellTax = __sell_data[0];
        _previousRefSellTax = 12;

        _refPer = __buy_data[1];
        _autoLiqPer = __buy_data[2];
        _devPer = __buy_data[3];
        _burnPer = __buy_data[4];
        _marketingPer = __buy_data[5];

        _maxHoldAmount = __data[2];
        _maxTransAmount = __data[1];
        _minTokensForLiquidity = __data[0];
        _remove_limits_time = block.timestamp + (__data[3] * 1 minutes);
        
        _rTotal = (MAX - (MAX % _tTotal));
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(__router);

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _rOwned[__sender] = _rTotal;
        emit Transfer(address(0), __sender, _tTotal);
    }

    //to recieve BNB from uniswapV2Router when swapping
    receive() external payable {}

    function name() public view returns(string memory) {

        return _name;
    }

    function symbol() public view returns (string memory) {

        return _symbol;
    }

    function decimals() public view returns (uint8) {

        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {

        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {

        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function isExcluded(address account) public view returns (bool) {

        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {

        return _tFeeTotal;
    }
    
    function removeTax() private {
        
        if(_totalBuyTax > 0) {
        
            _previousRefBuyTax = _totalBuyTax;
            _totalBuyTax = 0;
        }

        if(_totalSellTax > 0) {
        
            _previousRefSellTax = _totalSellTax;
            _totalSellTax = 0;
        }
    }
    
    function restoreTax() private {
        
        _totalBuyTax = _previousRefBuyTax;
        _totalSellTax = _previousRefSellTax;
    }

    function reflect(uint256 tAmount) public {

        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {

        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {

        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {

        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
				uint256 currentRate = _getRate();
				_rOwned[account] = _tOwned[account].mul(currentRate);
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _isBuy(address _sender) private view returns (bool) {
        return _sender == uniswapV2Pair;
    }

    function _isSell(address _to) private view returns (bool) {
        return _to == uniswapV2Pair;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //remove hold and tx limited after _remove_limits_time is reached
        if(_remove_limits_time > 0 && block.timestamp >= _remove_limits_time) {
            _maxHoldAmount = _tTotal; 
            _maxTransAmount = _tTotal;
        }

        if(!_isExcluded[sender]) {
            require(amount <= _maxTransAmount, "Transfer amount exceeds the maxTransAmount.");
        }
        
        if(_autoTaxEnabled && !_inLockLiquidities && sender != uniswapV2Pair && !_isExcluded[sender]) {
            if(!_isBuy(sender)) {
                _doTokenomics();
            }
        }
        
        if(_isExcluded[sender] || _isExcluded[recipient]) {
            removeTax();
        } else {

            if(_isBuy(sender)) {
                uint256 recipient_balance = balanceOf(address(recipient));
                uint256 recipient_new_balance = recipient_balance.add(amount);
                require(recipient_new_balance <= _maxHoldAmount, "Transfer amount exceeds the maxHoldAmount.");
            }
        }

        //remove tax if not a buy or sell
        if(!_isBuy(sender) && !_isSell(recipient)) {
            removeTax();
        }   
            
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(_isExcluded[sender] || _isExcluded[recipient]) {
            restoreTax();
        }

        if(!_isBuy(sender) && !_isSell(recipient)) {
            restoreTax();
        }  
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        
        uint256 newTFee = tFee.mul(_refPer).div(100);
        uint256 newRFee = rFee.mul(_refPer).div(100);

        uint256 tContractFee = tFee.sub(newTFee);
        uint256 rContractFee = rFee.sub(newRFee);
        
        _tOwned[address(this)] = _tOwned[address(this)].add(tContractFee);
        _rOwned[address(this)] = _rOwned[address(this)].add(rContractFee);
        
        _rTotal = _rTotal.sub(newRFee);
        _tFeeTotal = _tFeeTotal.add(newTFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {

        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {

        //buy tax
        uint256 tFee = tAmount.mul(_totalBuyTax).div(100); 

        //sell tax
        if(!_isBuy(msg.sender)) {
            tFee = tAmount.mul(_totalSellTax).div(100);
        }

        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {

        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {

        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {

        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _setMarketingWallet(address payable wallet) public onlyOwner() {

        _wMarketing = wallet;
        emit setMarketingWallet(wallet);
    }

    function _setDevWallet(address payable wallet) public onlyOwner() {

        _wDev = wallet;
        emit setDevWallet(wallet);
    }

    function _setMaxHold(uint256 maxHoldAmount) external onlyOwner() {

        require(maxHoldAmount >= 2000000000000000000000000000000, "Max hold amount is below threshold");

        _maxHoldAmount = maxHoldAmount;
        emit setMaxHold(maxHoldAmount);
    }

    function _setMaxTrans(uint256 maxTransAmount) external onlyOwner() {

        require(maxTransAmount >= 2000000000000000000000000000000, "Max TX amount is below threshold");

        _maxTransAmount = maxTransAmount;
        emit setMaxTrans(maxTransAmount);
    }

    function _setTotalBuyTax(uint256 totalBuyTax) external onlyOwner() {

        require(totalBuyTax <= _maxBuyTax, "Buy tax too high");

        _currentBuyTax = totalBuyTax;
        _totalBuyTax = totalBuyTax;
        emit setTotalBuyTax(totalBuyTax);
    }

    function _setTotalSellTax(uint256 totalSellTax) external onlyOwner() {

        require(totalSellTax <= _maxSellTax, "Sell tax too high");

        _currentSellTax = totalSellTax;
        _totalSellTax = totalSellTax;
        emit setTotalSellTax(totalSellTax);
    }

    //format: 1 = 1%
    function _setRefPer(uint256 refPer) external onlyOwner() {

        _refPer = refPer;
        emit setRefPer(refPer);
    }

    function _setTokenomics(uint256 autoLiqPer, uint256 burnPer, uint256 devPer, uint256 marketingPer) external onlyOwner() {
        
        uint256 total = autoLiqPer.add(burnPer).add(devPer).add(marketingPer);

        if(total != 100) {
            revert("Tokenomics must equal 100%");
        }

        _autoLiqPer = autoLiqPer.mul(100);
        _burnPer = burnPer.mul(100);
        _devPer = devPer.mul(100);
        _marketingPer = marketingPer.mul(100);

         emit setTokenomics(autoLiqPer, burnPer, devPer, marketingPer);
    }

    function _setMinTokensForLiquidity(uint256 minTokensForLiquidity) external onlyOwner() {

        _minTokensForLiquidity = minTokensForLiquidity;
        emit setMinTokensForLiquidity(minTokensForLiquidity);
    }

    function _setLockLiquiditiesEnabled(bool lockLiquiditiesEnabled) external onlyOwner() {

        _lockLiquiditiesEnabled = lockLiquiditiesEnabled;
        emit setLockLiquiditiesEnabled(lockLiquiditiesEnabled);
    }
    
    function _setAutoTaxEnabled(bool AutoTaxEnabled) external onlyOwner() {

        _autoTaxEnabled = AutoTaxEnabled;
        emit setAutoTaxEnabled(AutoTaxEnabled);
    }

    function _doTokenomics() public lockLiquidities {
        
        uint256 amount = balanceOf(address(this));
        
        if(amount >= _minTokensForLiquidity && _lockLiquiditiesEnabled == true && amount > 0) {

            if(amount >= _maxTransAmount) {
                amount = _maxTransAmount;
            }

            uint256 liqAmount = _findPercent(amount, _autoLiqPer);
            uint256 burnAmount = _findPercent(amount, _burnPer);

            _doLiquidity(liqAmount, amount.sub(burnAmount), burnAmount);
        }
    }

    function _doLiquidity(uint256 liqTokensAmount, uint256 fullBalance, uint256 burnAmount) private {

        uint256 bnbHalf = liqTokensAmount.div(2);
        uint256 tokenHalf = liqTokensAmount.sub(bnbHalf);

        uint256 bnbBalance = address(this).balance; //current bnb balance

        _swapTokensForEth(fullBalance.sub(tokenHalf), address(this)); //swap liquidity and marketing to ETH in one TX to save gas

        uint256 bnbNewBalance = address(this).balance.sub(bnbBalance); //get amount swapped to bnb

        if(bnbNewBalance > 0) {
            uint256 liqBnbAmount = _findPercent(bnbNewBalance, _autoLiqPer);
            uint256 devBnbAmount = _findPercent(bnbNewBalance, _devPer);
            uint256 marketingBnbAmount = _findPercent(bnbNewBalance, _marketingPer);

            if(liqTokensAmount > 0) {
                _addLiquidity(tokenHalf, liqBnbAmount); //add liquidity using the tokens and bnb, ETH dust will be sent back for dev and marketing wallet
                _liqAllTime += liqBnbAmount;
            }

            if(devBnbAmount > 0) {
                _doDev(devBnbAmount);
            }

            if(marketingBnbAmount > 0) {
                _doMarketing(marketingBnbAmount);
            }

            if(burnAmount > 0) {
                _doBurn(burnAmount);
            }
        }
    }

    function _doMarketing(uint256 amount) private {

        Address.sendValue(_wMarketing, amount);

        _marketingAllTime += amount;
    }

    function _doDev(uint256 amount) private {

        Address.sendValue(_wDev, amount);

        _devAllTime += amount;
    }

    function _doBurn(uint256 amount) private {

        _transfer(address(this), 0x000000000000000000000000000000000000dEaD, amount);

        _burnAllTime += amount;

        emit Transfer(address(this), 0x000000000000000000000000000000000000dEaD, amount);
    }

    function _findPercent(uint256 value, uint256 basePercent) private pure returns (uint256)  {

        uint256 percent = value.mul(basePercent).div(10000);
        return percent;
    }
    
    function _swapTokensForEth(uint256 tokenAmount, address tokenContract) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenContract;
        path[1] = uniswapV2Router.WETH();

        _approve(tokenContract, address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            tokenContract,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

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

    function _setRouterAddress(address newRouter) public onlyOwner() {

        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;

        emit setRouterAddressChanged(newRouter);
    }

    event setRouterAddressChanged(address newRouter);
    event setAutoTaxEnabled(bool AutoTaxEnabled);
    event setLockLiquiditiesEnabled(bool lockLiquiditiesEnabled);
    event setMinTokensForLiquidity(uint256 minTokensForLiquidity);
    event setTokenomics(uint256 autoLiqPer, uint256 burnPer, uint256 devPer, uint256 marketingPer);
    event setRefPer(uint256 refPer);
    event setTotalSellTax(uint256 totalSellTax);
    event setTotalBuyTax(uint256 totalBuyTax);
    event setMaxTrans(uint256 maxTransAmount);
    event setMaxHold(uint256 maxHoldAmount);
    event setMarketingWallet(address wallet);
    event setDevWallet(address wallet);
}
// File: contracts/cueLauncherBuilder.sol



pragma solidity ^0.6.12;








contract CUETokenBuilder is Context, Ownable {

    using SafeMath for uint256;

    AggregatorV3Interface internal price_feed;

    CUELauncherToken public clToken;

    struct buyer {
        string name;
        string symbol;
        uint256 price;
        address token_contract;
        bytes abi_encode;
    }

    address oracle;

    uint256 builder_price_wei = 300000000000000000000;

    //buyers
    mapping(address => buyer) public buyers;
    
    //whitelist
    mapping(address => bool) private free_whitelist;
    mapping(address => uint256) private discount_whitelist;

    constructor() public {
        price_feed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    function buildToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _tTotal,
        address payable _wMarketing,
        address payable _wDev,
        uint256[6] memory _buy_data,    // [buy_tax, tax_reflections, tax_auto_liq, tax_dev, tax_burn, tax_marketing]
        uint256[1] memory _sell_data,   // [sell_tax]
        uint256[4] memory _data,        // [run_tokenomics, max_tx, max_hold, remove_limits_limit]
        bool is_renounce,
        address _router
    ) external payable {

        require(msg.value >= getPrice(msg.sender), "Fee not met");

        clToken = new CUELauncherToken(
            _name,
            _symbol,
            _decimals,
            _tTotal,
            _wMarketing,
            _wDev,
            _buy_data,
            _sell_data,
            _data,
            _router,
            msg.sender
        );

        clToken.excludeAccount(address(this));

        if(!clToken.isExcluded(msg.sender)) {
            clToken.excludeAccount(msg.sender);
        }

        if(!clToken.isExcluded(_wMarketing)) {
            clToken.excludeAccount(_wMarketing);
        }

        if(!clToken.isExcluded(_wDev)) {
            clToken.excludeAccount(_wDev);
        }

        if(!is_renounce) {
            clToken.transferOwnership(msg.sender);
        } else {
            clToken.renounceOwnership();
        }

        buyers[msg.sender].name = _name;
        buyers[msg.sender].symbol = _symbol;
        buyers[msg.sender].price = msg.value;
        buyers[msg.sender].token_contract = address(clToken);
        buyers[msg.sender].abi_encode = abi.encode(_name, _symbol, _decimals, _tTotal, _wMarketing, _wDev, _buy_data, _sell_data, _data, _router, msg.sender);
    }

    function addToFreeWhitelist(address user) external onlyOwner {
        
        free_whitelist[user] = true;
    }

    function addToDiscountWhitelist(address user, uint256 discount) external onlyOwner {
        
        discount_whitelist[user] = discount;
    }

    function removeFromFreeWhitelist(address user) external onlyOwner {
        
        free_whitelist[user] = false;
    }

    function removeFromDiscountWhitelist(address user) external onlyOwner {
        
        discount_whitelist[user] = 0;
    }
    
    function isAddressFreeWhitelisted(address _wallet) public view returns (bool) {

        return free_whitelist[_wallet];
    }

    function isAddressDiscountWhitelisted(address _wallet) public view returns (uint256) {

        return discount_whitelist[_wallet];
    }

    function getPrice(address sender) public view returns (uint256) {

        uint256 discount = isAddressDiscountWhitelisted(sender);
        bool is_free = isAddressFreeWhitelisted(sender);

        if(is_free) {
            return 0;
        }

        int price_eth_usd = get_feed_price();

        uint256 builder_price_eth = builder_price_wei.div(uint256(price_eth_usd));
        builder_price_eth = builder_price_eth * 10 ** 8;

        return builder_price_eth.sub(builder_price_eth.div(100).mul(discount));
    }

    function setOracle(address _oracle) external onlyOwner {

        oracle = _oracle;
    }
    
    function setBuilderPriceWei(uint256 _price) external onlyOwner {

        builder_price_wei = _price;
    }

    function setBuilderPriceWeiOracle(uint256 _price) external {
        
        require(msg.sender == oracle, "Oracle only access");

        builder_price_wei = _price;
    }

    function setPriceFeed(address feed) external onlyOwner {

        price_feed = AggregatorV3Interface(feed);
    }

    function get_feed_price() public view returns (int) {

        (
            uint80 feed_oundID, 
            int feed_price,
            uint feed_startedAt,
            uint feed_timeStamp,
            uint80 feed_answeredInRound
        ) = price_feed.latestRoundData();

        return feed_price;
    }

    function forceRemove(address payable receiver) external payable onlyOwner {

         receiver.transfer(address(this).balance);
    }
}