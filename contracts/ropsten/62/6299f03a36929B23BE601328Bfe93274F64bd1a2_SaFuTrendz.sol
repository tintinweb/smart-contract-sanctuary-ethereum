/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

/**
    *** Token information 
        - name: SaFuTrendz
        - Supply: 1,000,000,000  => 1B (= 10 ** 9)
        - Decimal: 9
        - Symbol: STZ

    *** Tokenomics
        * Fees
            - BuyTax 12%
                => Liquidity Wallet: 2%
                => Marketing Wallet: 5%
                => Owner     Wallet: 3%
                => Buyback   Wallet: 1%
                => Salary    Wallet: 1%

            - SellTax 15%
                => Liquidity Wallet: 3%
                => Marketing Wallet: 5%
                => Owner     Wallet: 3%
                => Buyback   Wallet: 1%
                => Salary    Wallet: 2%

            - MaxTransactionPercent: 
            - MaxWalletPercent: 
        * Token Features

**/

pragma solidity ^0.8.6;
// SPDX-License-Identifier: Unlicensed

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

// // CAUTION
// // This version of SafeMath should only be used with Solidity 0.8 or later,
// // because it relies on the compiler's built in overflow checks.

// /**
//  * @dev Wrappers over Solidity's arithmetic operations.
//  *
//  * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
//  * now has built in overflow checking.
//  */
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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

// /*
//  * @dev Provides information about the current execution context, including the
//  * sender of the transaction and its data. While these are generally available
//  * via msg.sender and msg.data, they should not be accessed in such a direct
//  * manner, since when dealing with meta-transactions the account sending and
//  * paying for execution may not be the actual sender (as far as an application
//  * is concerned).
//  *
//  * This contract is only required for intermediate, library-like contracts.
//  */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

contract SaFuTrendz is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _iswhitelisted;
    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxTX;
    mapping (address => bool) public _isExcludedMaxWallet;

    string private _name = "SaFuTrendz";
    string private _symbol = "STZ";
  
    uint256 private _totalSupply = 1 * 10**9 * 10**9;
    uint8 private _decimals = 9;

    // Initialize buy fee
    uint256 private _liqudityFeeBuy = 2;
    uint256 private _marketingFeeBuy = 5;
    uint256 private _ownerFeeBuy = 3;
    uint256 private _buybackFeeBuy = 1;
    uint256 private _salaryFeeBuy = 1;
    uint256 private _buyFee = 12;
    uint256 private _maxBuyFee = 15;

    // Initialize sell fee
    uint256 private _liqudityFeeSell = 3;
    uint256 private _marketingFeeSell = 6;
    uint256 private _ownerFeeSell = 3;
    uint256 private _buybackFeeSell = 1;
    uint256 private _salaryFeeSell = 2;
    uint256 private _sellFee = 15;
    uint256 private _maxSellFee = 15;

    // Initialize fee address
    address public _liquidityFeeAddress = 0x4282A52beB9d65a01D500D22127a92f47f1FF37A;
    address public _marketingFeeAddress = 0x4282A52beB9d65a01D500D22127a92f47f1FF37A;
    address public _ownerFeeAddress = 0x4282A52beB9d65a01D500D22127a92f47f1FF37A;
    address public _buybackFeeAddress = 0x4282A52beB9d65a01D500D22127a92f47f1FF37A;
    address public _salaryFeeAddress = 0x4282A52beB9d65a01D500D22127a92f47f1FF37A;

    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
    //IUniswapV2Router02 private uniswapV2Router;
    IUniswapV2Router02 private _uniswapV2Router;
    // (BSC testnet) 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // (BSC mainnet) V2 0x10ED43C718714eb63d5aA57B78B54704E256024E
    // (Uniswap) V2 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    //address public _uniswapV2RouterAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _uniswapV2Pair;

    bool public swapAndLiquifyEnabled = false;

    // Initialize trading and stop fee flag
    bool public tradable = true;
    bool private stopFee = false;
    bool private _isBuyAllow = false;

    uint256 public _buyFeeAmount;
    uint256 public _buyFeeWithdrawed;
    uint256 public _sellFeeAmount;
    uint256 public _sellFeeWithdrawed;
    uint256 private _feeWithdrawInterval = 10 * 24 * 60 * 60; //10 days
    uint256 private _lastfeeWithrawed = block.timestamp;

    uint256 public _swapFeeEnableLimitPercentageRate = 200;
    uint256 private _swapFeeEnableLimit = _totalSupply.div(_swapFeeEnableLimitPercentageRate);

    uint256 public _maxTxPercent = 1;
    uint256 public _maxWalletPercent = 5;
    uint256 private _maxTxAmount = _totalSupply * _maxTxPercent / 10**2;
    uint256 private _maxWalletAmount = _totalSupply * _maxWalletPercent / (10**2);

    //bool private _removeLpFlag = false;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 buysellFlag
    );

    event StuckTokensRecovered(
        address tokenAddress,
        uint256 amount,
        address indexed target
    );

    constructor (address routerAddress) {
         _balances[_msgSender()] = _totalSupply;

        setUniswapRouterAddress(routerAddress);
        // // Create a uniswap pair for this new token
        //_uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_burnAddress] = true;
        
        _isExcludedMaxWallet[owner()] = true;
        _isExcludedMaxWallet[address(this)] = true;
        _isExcludedMaxWallet[_burnAddress] = true;

        excludeFromMaxTX(owner());
        excludeFromMaxTX(address(this));

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function setUniswapRouterAddress(address routerAddress) public onlyOwner{
        require(routerAddress != address(0));
        _uniswapV2Router = IUniswapV2Router02(routerAddress);
        
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromFee(_uniswapV2Pair);
        excludeFromFee(routerAddress);
        _isExcludedMaxWallet[_uniswapV2Pair] = true;
        _isExcludedMaxWallet[routerAddress] = true;
    }

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

    function OpenTrading() public onlyOwner{
        require(!tradable, "Already enabled");
        tradable = true;
    }
    
    function stopTrading() public onlyOwner{
        require(tradable, "Already disabled");
        tradable = false;
    }

    function swapFeeEnableLimitPercentRate(uint256 rate) public onlyOwner
    {
        require(rate >= 100 && rate <= 2000000);
        _swapFeeEnableLimitPercentageRate = rate;
        _swapFeeEnableLimit = _totalSupply.div(_swapFeeEnableLimitPercentageRate);    
    }

    function recoverStuckTokens(address tokenAddress, uint256 amount, address target) external onlyOwner()
    {
        //require(IERC20(target).transfer(msg.sender, amount), "transfer failed");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount);
        IERC20(tokenAddress).approve(target, IERC20(tokenAddress).balanceOf(address(this)));
        IERC20(tokenAddress).transfer(target, amount);
        
        emit StuckTokensRecovered(tokenAddress, amount, target);
    }

    function setMaxBuyFee(uint256 maxBuyFee) public onlyOwner {
        _maxBuyFee = maxBuyFee;
    }

    function setMaxSellFee(uint256 maxSellFee) public onlyOwner {
        _maxSellFee = maxSellFee;
    }

    function changeBuyTax(uint256 liquidityFeeBuy, uint256 marketingFeeBuy, uint256 ownerFeeBuy, uint256 buybackFeeBuy, uint256 salaryFeeBuy) public onlyOwner
    {   
        _buyFee = liquidityFeeBuy + marketingFeeBuy + ownerFeeBuy + buybackFeeBuy + salaryFeeBuy;
        require(_buyFee <= _maxBuyFee, "Buy fee is too high");
        _liqudityFeeBuy = liquidityFeeBuy;
        _marketingFeeBuy = marketingFeeBuy;
        _ownerFeeBuy = ownerFeeBuy;
        _buybackFeeBuy = buybackFeeBuy;
        _salaryFeeBuy = salaryFeeBuy;
        
    }

    function changeSellTax(uint256 liqudityFeeSell, uint256 marketingFeeSell, uint256 ownerFeeSell, uint256 buybackFeeSell, uint256 salaryFeeSell) public onlyOwner
    {
        _sellFee = liqudityFeeSell + marketingFeeSell + ownerFeeSell + buybackFeeSell + salaryFeeSell;
        require(_sellFee <= _maxSellFee, "Sell fee is too high");
        _liqudityFeeSell = liqudityFeeSell;
        _marketingFeeSell = marketingFeeSell;
        _ownerFeeSell = ownerFeeSell;
        _buybackFeeSell = buybackFeeSell;
        _salaryFeeSell = salaryFeeSell;
    }

    function changeBuySellTaxAddress(address liquidityWalletAddr, address marketingWalletAddr, address ownerWalletAddr, address buybackWalletAddr, address salaryWalletAddr) public onlyOwner
    {
        _liquidityFeeAddress = liquidityWalletAddr;
        _marketingFeeAddress = marketingWalletAddr;
        _ownerFeeAddress = ownerWalletAddr;
        _buybackFeeAddress = buybackWalletAddr;
        _salaryFeeAddress = salaryWalletAddr;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromMaxTX(address account) public onlyOwner {
        _isExcludedFromMaxTX[account] = true;
    }

    function includeInMaxTX(address account) public onlyOwner {
        _isExcludedFromMaxTX[account] = false;
    }

    function excludeFromMaxWallet(address account) public onlyOwner {
        _isExcludedMaxWallet[account] = true;
    }

    function includeInMaxWallet(address account) public onlyOwner {
        _isExcludedMaxWallet[account] = false;
    }


    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxPercent = maxTxPercent;
        _maxTxAmount = _totalSupply.mul(_maxTxPercent).div(10**2);
    }
    
    function setMaxWalletPercent(uint256 maxWalletPercent) external onlyOwner {
        _maxWalletPercent = maxWalletPercent;
        _maxWalletAmount = _totalSupply.mul(_maxWalletPercent).div(10**2);
    }

    function setSwapAndLiquifyFlag(bool enableFlag) public onlyOwner {
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        require(_uniswapV2Pair != address(0));
        swapAndLiquifyEnabled = enableFlag;
        emit SwapAndLiquifyEnabledUpdated(enableFlag);
    }

    // to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function TransferEthToExternalAddress(address recipient, uint256 amount) private {
        payable(recipient).transfer(amount);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxTX(address account) public view returns(bool) {
        return _isExcludedFromMaxTX[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setBlacklistAddress(address account, bool flag) public onlyOwner {
        _isBlacklisted[account] = flag;
    }

    function setWhitelistAddress(address account, bool flag) public onlyOwner {
        _iswhitelisted[account] = flag;
    }

    function sendAirdrop(address[] memory to, uint256[] memory amount) public onlyOwner returns (bool) {
        require(tradable, "trading disabled");
        //require(amount[i] <= _maxTxAmount, "overflow maxTxAmount");
        //require(_balances[msg.sender] >= amount.mul(to.length), "not enough token for airdrop");
        for (uint i = 0; i < to.length; i++) {
            if(_isExcludedMaxWallet[to[i]] == false &&  balanceOf(to[i]) + amount[i] <= _maxWalletAmount)
            {
               continue;
            }
          if(to[i] != address(0) && !_isBlacklisted[to[i]]){   
                _balances[msg.sender] -= amount[i];
                _balances[to[i]] += amount[i];
                emit Transfer(owner(), to[i], amount[i]);
            }
        }
        return true;
    }

    function takeFeesOnBuyAndSell() public view returns(uint256, uint256)
    {
        if(stopFee){
            return (0, 0);
        }
        else{
            uint256 tBuyTax = _liqudityFeeBuy + _marketingFeeBuy + _ownerFeeBuy + _buybackFeeBuy + _salaryFeeBuy;
            uint256 tSellTax = _liqudityFeeSell + _marketingFeeSell + _ownerFeeSell + _buybackFeeSell + _salaryFeeSell;
            return (tBuyTax, tSellTax);
        }
    }

    function stopFeesOnBuyAndSell() public onlyOwner{
        require(!stopFee, "Already stopped");
        stopFee = true; // Stop enabled
    }

    function setFeesOnBuyAndSell() public onlyOwner{
        require(stopFee, "Already stopped");
        stopFee = false; // Stop disabled
    }

    function setBuyAllowFlag(bool allowFlag) public onlyOwner{
        _isBuyAllow = allowFlag;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0) && to != address(0));
        require(tradable, "Trading is disabled");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isBlacklisted[from] == false || _isBlacklisted[to] == false, "Blacklisted addresses can't do buy or sell");
        
        if(!_isExcludedFromMaxTX[from])
        {   
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        if( _isExcludedMaxWallet[to] == false )
            require(balanceOf(to) + amount <= _maxWalletAmount, "Exceeds maximum wallet token amount");
        
        require(from != _uniswapV2Pair ||  _isBuyAllow, "Buying is not allowed");
   
        uint256 feeAmount = 0;
        if(!stopFee && from == _uniswapV2Pair){ // Buy Fee
            if(_isExcludedFromFee[to] == false)
            {
                feeAmount = amount.mul(_buyFee).div(100);
                _buyFeeAmount += feeAmount;
            }
        }

        else if(!stopFee && to == _uniswapV2Pair) // Sell Fee
        {   
            if(_isExcludedFromFee[from] == false)
            {   
                feeAmount = amount.mul(_sellFee).div(100);
                _sellFeeAmount += feeAmount;
            }  
        }

        _tokenTransfer(from, to, amount, feeAmount);
    }

    function burnTokenWithPercentage(uint256 burnPercent) public onlyOwner
    {
        require(burnPercent >= 1 && burnPercent <= 5);
        _transfer(msg.sender, _burnAddress, _totalSupply.mul(burnPercent).div(100));
    }

    function setFeeWithdrawInterval(uint256 interval) public onlyOwner{
        _feeWithdrawInterval = interval;
    }

    function feeWithdrawExecute() public onlyOwner
    {
        require(tradable && swapAndLiquifyEnabled);
        require(block.timestamp - _lastfeeWithrawed >= _feeWithdrawInterval);
        if(_sellFeeAmount - _sellFeeWithdrawed >= _swapFeeEnableLimit)
        {
            swapAndLiquify(2);
        }
        else if(_buyFeeAmount - _buyFeeWithdrawed >= _swapFeeEnableLimit)
        {
            swapAndLiquify(1);
        }
        _lastfeeWithrawed = block.timestamp;
    }   

    function swapAndLiquify(uint256 flag) private {
        
        uint256 initialBalance = address(this).balance;
        // swap tokens for ETH
        swapTokensForEth(_swapFeeEnableLimit);
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        if(flag == 1) // Buy
        {
            TransferEthToExternalAddress(_liquidityFeeAddress, newBalance.div(_buyFee).mul(_liqudityFeeBuy));
            TransferEthToExternalAddress(_marketingFeeAddress, newBalance.div(_buyFee).mul(_marketingFeeBuy));
            TransferEthToExternalAddress(_ownerFeeAddress, newBalance.div(_buyFee).mul(_ownerFeeBuy));
            TransferEthToExternalAddress(_buybackFeeAddress, newBalance.div(_buyFee).mul(_buybackFeeBuy));
            TransferEthToExternalAddress(_salaryFeeAddress, newBalance.div(_buyFee).mul(_salaryFeeBuy));
            _buyFeeWithdrawed += _swapFeeEnableLimit;
        }
        else if(flag == 2) //Sell
        {           
            TransferEthToExternalAddress(_liquidityFeeAddress, newBalance.div(_sellFee).mul(_liqudityFeeSell));
            TransferEthToExternalAddress(_marketingFeeAddress, newBalance.div(_sellFee).mul(_marketingFeeSell));
            TransferEthToExternalAddress(_ownerFeeAddress, newBalance.div(_sellFee).mul(_ownerFeeSell));
            TransferEthToExternalAddress(_buybackFeeAddress, newBalance.div(_sellFee).mul(_buybackFeeSell));
            TransferEthToExternalAddress(_salaryFeeAddress, newBalance.div(_sellFee).mul(_salaryFeeSell));
            _sellFeeWithdrawed += _swapFeeEnableLimit;
        }
        
        emit SwapAndLiquify(flag);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);
       
        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(address from, address to, uint256 value, uint256 feeAmount) private {       
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value - feeAmount);
        _balances[address(this)] += feeAmount;
        
        //emit Transfer(from, to, value - feeAmount);
        if (feeAmount != 0)
        {
            emit Transfer(from, to, value - feeAmount);
        }
        emit Transfer(from, address(this), feeAmount);
    }
}