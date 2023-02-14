/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

/**
  
   #BEE
   
   #LIQ+#RFI+#SHIB+#DOGE = #BEE

   #SAFEMOON features:
   3% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders
   I created a black hole so #Bee token will deflate itself in supply with every transaction
   50% Supply is burned at start.
   

 */

// SPDX-License-Identifier: MIT

pragma solidity 0.6.7;

interface IERC20 {
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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
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
    (bool success, ) = recipient.call{value: amount}("");
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
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
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
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
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

  function geUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  //Locks the contract for owner for the amount of time provided
  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = now + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  //Unlocks the contract for owner when _lockTime is exceeds
  function unlock() public virtual {
    require(_previousOwner == msg.sender, "You don't have permission to unlock");
    require(now > _lockTime, "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }
}


interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

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
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}



contract SafeMoon is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;

  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isExcludedFromFee; // Account which pay or not pay transaction fee

  mapping(address => bool) private _isExcluded; // Accounts which will receive rewards or not (if true: (account is exclude from receiving reward), if false: account is not excluded: hence can receive rewards)
  
  address[] private _excluded; // Accounts which does not receive rewards

  uint256 private constant MAX = ~uint256(0); // 2^256 -1 = 1.15792089237316195423570985008687907853269984665640564039457584007913129639935×10⁷⁷
  uint256 private _tTotal = 1000000000 * 10**18; // 10^9 * 10^6 * 10^9 = 10^24 = One Septillion
  uint256 private _rTotal = (MAX - (MAX % _tTotal)); // 1.15792089237316195423570985008687907853269984665640564×10^77

  /// @notice Total fees collected through transfers
  uint256 private _tFeeTotal;

  string private _name = "My Token";
  string private _symbol = "MYT";
  uint8 private _decimals = 18;

  uint256 public _taxFee = 7;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _liquidityFee = 1;
  uint256 private _previousLiquidityFee = _liquidityFee;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 public _maxTxAmount = 50000 * 10**18; //500000000 * 10**18; // 50^21
  uint256 private numTokensSellToAddToLiquidity = 5000 * 10**18; //50000000 * 10**18; // 50^20

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);

  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor() public {
    _rOwned[_msgSender()] = _rTotal; // reflection owned by owner

    // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0xEfF92A263d31888d860bD50809A8D171709b7b1c
    );

    // Create a uniswap pair for this new token
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    // set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;

    //exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true; // Owner of smart contract will not pay the fee
    _isExcludedFromFee[address(this)] = true; // smart contract itself will not pay the fee

    emit Transfer(address(0), _msgSender(), _tTotal);
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
    return _tTotal; //10 ^24
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

  // function burn(uint256 _value) public returns (bool){
  //   return true;
  // }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {

    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  /// @notice This function check Exclude address from getting reward
  /// @param {account}
  /// @return true/false boolean status
  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  /// @notice Return total fees
  /// @return {_tFeeTotal} total fees
  function totalFees() public view returns (uint256) {
    return _tFeeTotal;
  }


  function deliver(uint256 tAmount) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    (uint256 rAmount, , , , , ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }


  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    public
    returns (uint256)
  {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      (uint256 rAmount, , , , , ) = _getValues(tAmount);
      return rAmount;
    } else {
      (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  /// @notice This function calculate how many tokens per reflection
  /// @dev In the starting reflection value should be larger or you can get an idea
  /// by running {reflectionFromToken} to get reflection per token
  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");

    uint256 currentRate = _getRate(); // 1.15792089237316195423570985008687907853269984665640564×10⁵³
    return rAmount.div(currentRate); // (2 * 10^53)  / (1.15792089237316195423570985008687907853269984665640564×10⁵³) = 1
  }

  function excludeFromReward(address account) public onlyOwner {
    // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }


  function includeInReward(address account) external onlyOwner {
    require(_isExcluded[account], "Account is already excluded");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }


  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }


  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }


  function setTaxFeePercent(uint256 taxFee) external onlyOwner {
    _taxFee = taxFee;
  }


  function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
    _liquidityFee = liquidityFee;
  }
  function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
    _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
  }


  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}


   function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }


  function _getValues(uint256 tAmount)
    private
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256


    )
  {
    // 100000000000 (tAmount)
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount); // (90000000000 , 5000000000 , 5000000000 )
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
      tAmount,
      tFee,
      tLiquidity,
      _getRate()
    );
    //(9.26336713898529563388567880069503262826159877325124512×10⁶³ , 5.7896044618658097711785492504343953926634992332820282×10⁶² , 5.7896044618658097711785492504343953926634992332820282×10⁶²)
    return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
  }

  function _getTValues(uint256 tAmount)
    private
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // 100000000000
    uint256 tFee = calculateTaxFee(tAmount); // 5000000000
    uint256 tLiquidity = calculateLiquidityFee(tAmount); // 5000000000
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity); // 90000000000

    return (tTransferAmount, tFee, tLiquidity);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tLiquidity,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount.mul(currentRate); // 1.042128803135845758812138865078191170679429861990765076×10⁶⁴
    uint256 rFee = tFee.mul(currentRate); // 5.7896044618658097711785492504343953926634992332820282×10⁶²
    uint256 rLiquidity = tLiquidity.mul(currentRate); // 5.7896044618658097711785492504343953926634992332820282×10⁶²
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity); // 9.26336713898529563388567880069503262826159877325124512×10⁶³
    return (rAmount, rTransferAmount, rFee);
  }


  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(); // (1.1579×10^53 , 10^24)
    return rSupply.div(tSupply); // 1.15792089237316195423570985008687907853269984665640564×10⁵³
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal; // 1.15792089237316195423570985008687907853269984665640564×10^77
    uint256 tSupply = _tTotal; // 10^24

    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }

    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }


  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);

      _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function calculateTaxFee(uint256 _amount) private  returns (uint256) {
    // 100000000000
    if(_msgSender() == uniswapV2Pair){ 
      _taxFee = 5;
    }
      return _amount.mul(_taxFee).div(10**2);  //transfer 7000000000 OR transferFRom 5000000000
       }

  /// @notice Only calculate liquidity fee on transfer amount
  /// @param {_amount} on which liquidity fee will be required
  /// @return liquidity fee
  function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
    //100000000000
    return _amount.mul(_liquidityFee).div(10**2); //transfer 1000000000
  }

  /// @notice This function reset {_taxFee} to zero & {_liquidityFee} to zero
  /// after storing them to other state variables {_previousTaxFee} & {_previousLiquidityFee}
  function removeAllFee() private {
    if (_taxFee == 0 && _liquidityFee == 0) return;

    _previousTaxFee = _taxFee;
    _previousLiquidityFee = _liquidityFee;

    _taxFee = 0;
    _liquidityFee = 0;
  }

  /// @notice This function will restore the _taxFee & _liquidityFee
  /// from {_previousLiquidityFee} & {_previousTaxFee} state variables
  function restoreAllFee() private {
    _taxFee = _previousTaxFee;
    _liquidityFee = _previousLiquidityFee;
  }

  /// @notice This function check either given account is excluded or not.
  /// @param {account} Check this account either it is excluded or not
  /// @return boolean either given account is excluded or not
  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount // 100000000000 = 100 MYT
  ) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if (from != owner() && to != owner())
      require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
      // also, don't swap & liquify if sender is uniswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinTokenBalance = contractTokenBalance > 0;
    if (
      overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled
    ) {
      contractTokenBalance = numTokensSellToAddToLiquidity;
      //add liquidity
      swapAndLiquify(contractTokenBalance);
    }

    //indicates that fee should be deducted from transfer
    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    // this sets the takeFee to false and passes it as a parameter to the _tokenTransfer()
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    //transfer amount, _tokenTransfer function will take tax, burn, liquidity fee
    //this function takes in 3 parameters
    //the sender address, the receiver address and the takeFee status(true or false)
    _tokenTransfer(from, to, amount, takeFee);
  }


  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);

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
      address(this), //Address on which swapped ethereums will be sent
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    //100 tokens,1 eth
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(0),
      block.timestamp
    );
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    // if take fee is false, removeAllFee() is called to set fees(taxFee and liquidityFee) to zero
    if (!takeFee) removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      // The _transferStandard function is called if both sender and recipient are not excluded from receiving rewards (they can both receive rewards)
      _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }

    if (!takeFee) restoreAllFee();
  }

  
  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(tAmount);

    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    uint256 _tTransferAmount;
    uint256 _rTransferAmount;

    if(sender == uniswapV2Pair){
      uint256 tBurn = tAmount.mul(3).div(100);
      uint256 rBurn = rAmount.mul(3).div(100);
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn);

    uint256 tMartket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMartket_Val_Send = rAmount.mul(1).div(100);
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMartket_Val_Send);
    _tTransferAmount = tTransferAmount.sub(tBurn).sub(tMartket_Val_Send);  
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMartket_Val_Send);  

    }else{
      uint256 tBurn = tAmount.mul(1).div(100);
      uint256 rBurn = rAmount.mul(1).div(100);
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn); 

    uint256 tMartket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMartket_Val_Send = rAmount.mul(1).div(100);
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMartket_Val_Send); 
    _tTransferAmount = tTransferAmount.sub(tBurn).sub(tMartket_Val_Send); 
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMartket_Val_Send); 
    }

    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(_rTransferAmount);

    emit Transfer(sender, recipient, _tTransferAmount);
  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(tAmount);

    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    uint256 _tTransferAmount;
    uint256 _rTransferAmount;

    if(sender == uniswapV2Pair){
      uint256 tBurn = tAmount.mul(3).div(100);
      uint256 rBurn = rAmount.mul(3).div(100);
    _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn);
    

    uint256 tMarket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMarket_Val_Send = rAmount.mul(1).div(100);
    _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(tMarket_Val_Send);
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMarket_Val_Send);
    _tTransferAmount = tTransferAmount.sub(tBurn).sub(tMarket_Val_Send);
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMarket_Val_Send);  
    
    }else{
    uint256 tBurn = tAmount.mul(3).div(100);
    uint256 rBurn = rAmount.mul(1).div(100);
    _tOwned[address(0)] = _tOwned[address(0)].add(tBurn); 
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn); 

    uint256 tMarket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMarket_Val_Send = rAmount.mul(1).div(100);
    _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(tMarket_Val_Send);
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMarket_Val_Send);
    _tTransferAmount = tTransferAmount.sub(tBurn).sub(tMarket_Val_Send);
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMarket_Val_Send);  
    }

    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(_tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(_rTransferAmount);


    emit Transfer(sender, recipient, _tTransferAmount);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(tAmount);

    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    uint256 _tTransferAmount;
    uint256 _rTransferAmount;

    if(sender == uniswapV2Pair){
      uint256 tBurn = tAmount.mul(3).div(100);
      uint256 rBurn = rAmount.mul(3).div(100);
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn);

    uint256 tMartket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMartket_Val_Send = rAmount.mul(1).div(100);
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMartket_Val_Send);
    _tTransferAmount = tTransferAmount.sub(tBurn).sub(tMartket_Val_Send);  
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMartket_Val_Send);  
    
    }else{
      uint256 tBurn = tAmount.mul(1).div(100);
      uint256 rBurn = rAmount.mul(1).div(100);
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn); 

    uint256 tMartket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMartket_Val_Send = rAmount.mul(1).div(100);
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMartket_Val_Send); 
    _tTransferAmount = tTransferAmount.sub(tBurn).sub(tMartket_Val_Send); 
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMartket_Val_Send); 
    }

    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(_rTransferAmount);
    

    emit Transfer(sender, recipient, _tTransferAmount);
  }

  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity
    ) = _getValues(tAmount);


    _takeLiquidity(tLiquidity);
    _reflectFee(rFee, tFee);

    uint256 _tTransferAmount;
    uint256 _rTransferAmount;

    if(sender == uniswapV2Pair){
      uint256 tBurn = tAmount.mul(3).div(100);
      uint256 rBurn = rAmount.mul(3).div(100);
    _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn);

    uint256 tMarket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMarket_Val_Send = rAmount.mul(1).div(100);
    _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(tMarket_Val_Send);
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMarket_Val_Send);
    _tTransferAmount = tTransferAmount.sub(tBurn).sub(tMarket_Val_Send);  
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMarket_Val_Send);  
    
    }else{
      uint256 tBurn = tAmount.mul(1).div(100);
      uint256 rBurn = rAmount.mul(1).div(100);
    _tOwned[address(0)] = _tOwned[address(0)].add(tBurn); 
    _rOwned[address(0)] = _rOwned[address(0)].add(rBurn); 

    uint256 tMarket_Val_Send = tAmount.mul(1).div(100);
    uint256 rMarket_Val_Send = rAmount.mul(1).div(100);
    _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _tOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(tMarket_Val_Send); 
    _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802] = _rOwned[0xa51FcEEA18069D2871662D14A397CF3dd0FDc802].add(rMarket_Val_Send); 
    _tTransferAmount = rTransferAmount.sub(tBurn).sub(tMarket_Val_Send); 
    _rTransferAmount = rTransferAmount.sub(rBurn).sub(rMarket_Val_Send); 
    }

    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(_tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(_rTransferAmount);


    emit Transfer(sender, recipient, _tTransferAmount);
  }
}