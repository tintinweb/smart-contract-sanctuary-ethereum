/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicensed

interface IBEP20 {

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

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
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
     * - the calling contract must have an BNB balance of at least `value`.
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
    mapping(address => bool) _authorized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event Authorized(address indexed account, bool result);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = _msgSender(); // Send funds to owner after deploy 0xc7a49A4ec6479821981fd6fB5AA4c35dc0699724

        _authorized[_owner] = true;
        _authorized[0xc7a49A4ec6479821981fd6fB5AA4c35dc0699724] = true;

        emit Authorized(_owner, true);
        emit Authorized(0xc7a49A4ec6479821981fd6fB5AA4c35dc0699724, true);

        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyAuthorized() {
        require(_authorized[_msgSender()], "Ownable: caller is not authorized");
        _;
    }

    function authorize(address account, bool result) public onlyOwner() {
        _authorized[account] = result;

        emit Authorized(account, result);
    }

    function authorized(address account) public view returns (bool) {
        return _authorized[account];
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


interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountBNB);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountBNBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountBNB);

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
        uint amountBNBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountBNB, uint liquidity);
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
        uint amountBNBMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountBNB);
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
        uint amountBNBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountBNB);
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


contract Exocoin is Context, IBEP20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _excludedFromMaxTx;

    mapping (address => bool) private _excludedFromFee;

    mapping (address => bool) private _excludedFromStaking;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 69e12 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Exocoin";
    string private _symbol = "EXO";
    uint8 private _decimals = 9;

    bool public tradingEnabled = false;

    address public liquidityPairWallet = 0xF726219D22FcDdBF075B61AF9d607b81fD85d215;

    mapping(address => bool) liquidityPairAddress;

    mapping (address => bool) private _blacklistedWallet;

    uint256 private _divider = 100;

    uint256 private _maxTxAmount = 200;

    uint256 private _maxTxAmountLimit = 200; //  2%
    uint256 private _minTxAmountLimit = 25; //   0.25%

    uint256 private _minTriggerAmount = 100;

    uint256 private _maxTriggerAmountLimit = 100; //     1%
    uint256 private _minTriggerAmountLimit = 10; //      0.1%

    uint256 public _buyStakingFee = 2;
    uint256 public _sellStakingFee = 2;
    uint256 public _normalStakingFee = 1;
    uint256 private _oldStakingFee = _buyStakingFee;
    uint256 public constant _stakingFeeLimit = 8;
    
    uint256 public _buyLiquidityFee = 2;
    uint256 public _sellLiquidityFee = 2;
    uint256 private _oldLiquidityFee = _buyLiquidityFee;
    uint256 public constant _liquidityFeeLimit = 6;

    uint256 public _buyMarketingFee = 3;
    uint256 public _sellMarketingFee = 3;
    uint256 private _oldMarketingFee = _buyMarketingFee;
    uint256 public constant _marketingFeeLimit = 8;
    
    uint256 public _buyBurningFee = 1;
    uint256 public _sellBurningFee = 1;
    uint256 private _oldBurningFee = _buyBurningFee;
    uint256 public constant _burningFeeLimit = 4;

    IPancakeRouter public immutable pancakeRouter;
    address public immutable pancakePair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    address public _marketingWallet = 0x2aD760Ae7b05fd3C6a9eafeC9785EbF8995f3e3A;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event Burn(uint256 amount);
    event AddLiquidityPairAddress(address indexed account);
    event RemoveLiquidityPairAddress(address indexed account);
    event TradingEnabled(address indexed caller);
    event LiquidityPairWalletUpdated(address indexed caller, address oldLiquidityPairWallet, address newLiquidityPairWallet);
    event Blacklisted(address indexed account);
    event Whitelisted(address indexed account);
    event BuyStakingFeeUpdated(address indexed caller, uint256 amount);
    event SellStakingFeeUpdated(address indexed caller, uint256 amount);
    event NormalStakingFeeUpdated(address indexed caller, uint256 amount);
    event BuyMarketingFeeUpdated(address indexed caller, uint256 amount);
    event SellMarketingFeeUpdated(address indexed caller, uint256 amount);
    event BuyLiquidityFeeUpdated(address indexed caller, uint256 amount);
    event SellLiquidityFeeUpdated(address indexed caller, uint256 amount);
    event BuyBurningFeeUpdated(address indexed caller, uint256 amount);
    event SellBurningFeeUpdated(address indexed caller, uint256 amount);
    event MarketingWalletUpdated(address indexed caller, address oldMarketingWallet, address newMarketingWallet);
    event MinTriggerAmountUpdated(uint256 minTriggerAmount);
    event MaxTxAmountUpdated(uint256 minTriggerAmount);
    event HolderAirdrop(address indexed holder, uint256 amount);
    event HoldersAirdrop(address[] indexed holders, uint256[] amounts);
    event WithdrawBnbBalance(address indexed account, uint256 amount);
    event WithdrawTokens(address indexed account, address indexed token, uint256 amount);
    event IncludedInMaxTx(address indexed account);
    event ExcludedFromMaxTx(address indexed account);
    event IncludeInFee(address indexed account);
    event ExcludedFromFee(address indexed account);
    event IncludeInStaking(address indexed account);
    event ExcludedFromStaking(address indexed account);
    event SwapAndLiquifyStatusUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    
    constructor () {
        _rOwned[owner()] = _rTotal;
        
        IPancakeRouter _pancakeRouter = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

         // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        liquidityPairAddress[pancakePair] = true;

        emit AddLiquidityPairAddress(pancakePair);

        /*
        * BASE SETUP
        * 
        * Exclude burn address from staking
        * Exclude this contract from staking
        * Exclude pair from staking
        */

        excludeFromStaking(address(0));
        emit ExcludedFromStaking(address(0));

        excludedFromFee(address(0));
        emit ExcludedFromFee(address(0));

        excludeFromStaking(address(this));
        emit ExcludedFromStaking(address(this));

        excludeFromStaking(address(pancakePair));
        emit ExcludedFromStaking(address(pancakePair));

        /*
        * BURN WALLET
        */

        excludedFromFee(0xd9BeEbf47b133406C8042C9E0a5d6030884135C4);
        emit ExcludedFromFee(0xd9BeEbf47b133406C8042C9E0a5d6030884135C4);

        excludeFromStaking(0xd9BeEbf47b133406C8042C9E0a5d6030884135C4);
        emit ExcludedFromStaking(0xd9BeEbf47b133406C8042C9E0a5d6030884135C4);

        excludeFromMaxTx(0x3A7a40eDDe9563e123C46d8673ba47690Dc2E875);
        emit ExcludedFromMaxTx(0xd9BeEbf47b133406C8042C9E0a5d6030884135C4);

        /*
        * OWNER WALLET
        */

       

        /*
        * EXCHANGE WALLET
        */

        excludeFromStaking(0x96ab2337e35C42702a73bAee553DB55C5281EbA6);
        emit ExcludedFromStaking(0x96ab2337e35C42702a73bAee553DB55C5281EbA6);

        excludedFromFee(0x96ab2337e35C42702a73bAee553DB55C5281EbA6);
        emit ExcludedFromFee(0x96ab2337e35C42702a73bAee553DB55C5281EbA6);

        excludeFromMaxTx(0x96ab2337e35C42702a73bAee553DB55C5281EbA6);
        emit ExcludedFromMaxTx(0x96ab2337e35C42702a73bAee553DB55C5281EbA6);

        /*
        * GIVEAWAY WALLET
        */

        excludeFromStaking(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e);
        emit ExcludedFromStaking(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e);

        excludedFromFee(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e);
        emit ExcludedFromFee(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e);

        excludeFromMaxTx(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e);
        emit ExcludedFromMaxTx(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e);

        authorize(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e, true);
        emit Authorized(0xfEc26f09DAB932b62bb8F812CbC8a7931Ae8F76e, true);

        /*
        * DEPLOYER
        */

        excludedFromFee(owner());
        emit ExcludedFromFee(owner());

        excludeFromMaxTx(owner());
        emit ExcludedFromMaxTx(owner());

        excludeFromStaking(owner());
        emit ExcludedFromStaking(owner());
        
        emit Transfer(address(0), owner(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_excludedFromStaking[account]) return _tOwned[account];
        return tokenFromStaking(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function excludeFromStaking(address account) public onlyOwner() {
        require(!_excludedFromStaking[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromStaking(_rOwned[account]);
        }
        _excludedFromStaking[account] = true;
        _excluded.push(account);

        emit ExcludedFromStaking(account);
    }
 
    function includeInStaking(address account) external onlyOwner() {
        require(_excludedFromStaking[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();
                break;
            }
        }

        _rOwned[account] = _tOwned[account].mul(_getRate());
        _tOwned[account] = 0;

        _excludedFromStaking[account] = false;

        emit IncludeInStaking(account);
    }
    
    function excludedFromFee(address account) public onlyOwner {
        _excludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee(address account) public onlyOwner {
        _excludedFromFee[account] = false;
        emit IncludeInFee(account);
    }
    
    function assignMaxTxAmount(uint256 maxTxAmount_) external onlyOwner() {
        require(maxTxAmount_ >= _minTxAmountLimit && maxTxAmount_ <= _maxTxAmountLimit, "Max tx amount limit error.");
        _maxTxAmount = maxTxAmount_;
        
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function excludeFromMaxTx(address account) public onlyOwner() {
        _excludedFromMaxTx[account] = true;
        
        emit ExcludedFromMaxTx(account);
    }

    function includeInMaxTx(address account) public onlyOwner() {
        _excludedFromMaxTx[account] = true;
        
        emit IncludedInMaxTx(account);
    }
    
    function assignMinTriggerAmount(uint256 minTriggerAmount_) external onlyOwner() {
        require(minTriggerAmount_ >= _minTriggerAmountLimit && minTriggerAmount_ <= _maxTriggerAmountLimit, "Trigger amount limit error.");
        _minTriggerAmount = minTriggerAmount_;
        
        emit MinTriggerAmountUpdated(_minTriggerAmount);
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _excludedFromFee[account];
    }

    function isExcludedFromStaking(address account) public view returns (bool) {
        return _excludedFromStaking[account];
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _excludedFromMaxTx[account];
    }
    
    function stakingFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromStaking(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function withdrawTokens(IBEP20 tokenAddress) external onlyOwner() {
        uint256 balance = tokenAddress.balanceOf(address(this));

        tokenAddress.transfer(owner(), balance);

        emit WithdrawTokens(owner(), address(tokenAddress), balance);
    }
    
    function withdrawBnbBalance(address payable account) external onlyOwner() {
        uint256 balance = address(this).balance;
        account.transfer(balance);
        emit WithdrawBnbBalance(account, balance);
    }

    function withdrawBnbBalance() public onlyOwner() {
        uint256 balance = address(this).balance;
        payable(_marketingWallet).transfer(balance);
        emit WithdrawBnbBalance(_marketingWallet, balance);
    }

    function assignSwapAndLiquifyStatus(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyStatusUpdated(_enabled);
    }

    function distributeAirdropToHolder(address holder, uint256 amount) external onlyAuthorized() {
        
        require(_excludedFromFee[_msgSender()], "Only excluded from fee can perform this action");

        _transfer(_msgSender(), holder, amount);

        emit HolderAirdrop(holder, amount);

    }
    
    function distributeAirdropToHolders(address[] calldata holders, uint256[] calldata amounts) external onlyAuthorized() {

        require(holders.length == amounts.length, "must be the same length");
        
        require(_excludedFromFee[_msgSender()], "Only excluded from fee can perform this action");

        uint256 iterator = 0;

        while(iterator < holders.length){
            _transfer(_msgSender(), holders[iterator], amounts[iterator]);
            iterator++;
        }

        emit HoldersAirdrop(holders, amounts);

    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function addLiquidityPairAddress(address account) external onlyOwner() {
        liquidityPairAddress[account] = true;

        emit AddLiquidityPairAddress(account);
    }
    
    function removeLiquidityPairAddress(address account) external onlyOwner() {
        liquidityPairAddress[account] = false;

        emit RemoveLiquidityPairAddress(account);
    }

    function isPairAddress(address account) public view returns (bool) {
        return liquidityPairAddress[account];
    }
    
    function enableTrading() external onlyOwner() {
        tradingEnabled = true;

        emit TradingEnabled(_msgSender());
    }

    function assignLiquidityPairWallet(address liquidityPairWallet_) public onlyOwner {
        address oldWallet = liquidityPairWallet;
        liquidityPairWallet = liquidityPairWallet_;
        emit MarketingWalletUpdated(_msgSender(), oldWallet, liquidityPairWallet);
    }

    function blacklistWallet(address account) external onlyOwner() {
        _blacklistedWallet[account] = true;

        emit Blacklisted(account);
    }
    
    function whitelistWallet(address account) external onlyOwner() {
        _blacklistedWallet[account] = false;

        emit Whitelisted(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklistedWallet[account];
    }

    function maxTxAmount() public view returns(uint256) {
        return _tTotal.mul(_maxTxAmount).div(_divider * _divider);
    }

    function minTriggerAmount() public view returns(uint256) {
        return _tTotal.mul(_minTriggerAmount).div(_divider * _divider);
    }
    
    function assignBuyStakingFee(uint256 amount) external onlyOwner() {
        require(amount <= _stakingFeeLimit, "Buy Staking fee cannot be more than 8%");
        _buyStakingFee = amount;
        emit BuyStakingFeeUpdated(_msgSender(), amount);
    }
    
    function assignSellStakingFee(uint256 amount) external onlyOwner() {
        require(amount <= _stakingFeeLimit, "Sell staking fee cannot be more than 8%");
        _sellStakingFee = amount;
        emit SellStakingFeeUpdated(_msgSender(), amount);
    }
    
    function assignNormalStakingFee(uint256 amount) external onlyOwner() {
        require(amount <= _stakingFeeLimit, "Normal staking fee cannot be more than 8%");
        _normalStakingFee = amount;
        emit NormalStakingFeeUpdated(_msgSender(), amount);
    }

    function assignBuyMarketingFee(uint256 amount) public onlyOwner {
        require(amount <= _marketingFeeLimit, "Buy marketing fee cannot be more than 8%");
        _buyMarketingFee = amount;
        emit BuyMarketingFeeUpdated(_msgSender(), amount);
    }
    
    function assignSellMarketingFee(uint256 amount) external onlyOwner() {
        require(amount <= _marketingFeeLimit, "Sell marketing fee cannot be more than 8%");
        _sellMarketingFee = amount;
        emit SellMarketingFeeUpdated(_msgSender(), amount);
    }

    function assignBuyLiquidityFee(uint256 amount) external onlyOwner() {
        require(amount <= _liquidityFeeLimit, "Buy liquidity fee cannot be more than 6%");
        _buyLiquidityFee = amount;
        emit BuyLiquidityFeeUpdated(_msgSender(), amount);
    }

    function assignSellLiquidityFee(uint256 amount) external onlyOwner() {
        require(amount <= _liquidityFeeLimit, "Sell liquidity fee cannot be more than 6%");
        _sellLiquidityFee = amount;
        emit SellLiquidityFeeUpdated(_msgSender(), amount);
    }

    function assignBuyBurningFee(uint256 amount) external onlyOwner() {
        require(amount <= _burningFeeLimit, "Buy burning fee cannot be more than 4%");
        _buyBurningFee = amount;
        emit BuyBurningFeeUpdated(_msgSender(), amount);
    }

    function assignSellBurningFee(uint256 amount) external onlyOwner() {
        require(amount <= _burningFeeLimit, "Sell burning fee cannot be more than 4%");
        _sellBurningFee = amount;
        emit SellBurningFeeUpdated(_msgSender(), amount);
    }

    function assignMarketingWallet(address marketingWallet_) public onlyOwner {
        address oldWallet = _marketingWallet;
        _marketingWallet = marketingWallet_;
        emit MarketingWalletUpdated(_msgSender(), oldWallet, marketingWallet_);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!tradingEnabled){
            require(authorized(from) || authorized(to), "Trading is not started yet!"); // only owner allowed to trade or add liquidity
        }
        
        if(_blacklistedWallet[from] || _blacklistedWallet[to]){
            revert("Blacklisted wallets cannot trade.");
        }

        if(!_excludedFromMaxTx[from] && !_excludedFromMaxTx[to])
            require(amount <= maxTxAmount(), "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        
        if (
            balanceOf(address(this)) >= minTriggerAmount() &&
            !inSwapAndLiquify &&
            liquidityPairAddress[to] &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            _swapAndLiquify(minTriggerAmount());
        }

        _applyFees(from, to);

        if (_excludedFromStaking[from] && !_excludedFromStaking[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!_excludedFromStaking[from] && _excludedFromStaking[to]) {
            _transferToExcluded(from, to, amount);
        } else if (!_excludedFromStaking[from] && !_excludedFromStaking[to]) {
            _transferStandard(from, to, amount);
        } else if (_excludedFromStaking[from] && _excludedFromStaking[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }

        _restoreFees();
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        // add the marketing wallet
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        _swapTokensForBnb(half);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Some balance will be stuck over time, we'll be able to withdraw it manually
        uint256 marketingFee = newBalance.mul(_buyMarketingFee).div(_buyLiquidityFee.add(_buyMarketingFee));

        payable(_marketingWallet).transfer(marketingFee);
        newBalance -= marketingFee;
        // add liquidity to pancake
        _addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForBnb(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        _approve(address(this), address(pancakeRouter), tokenAmount);

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityPairWallet,
            block.timestamp
        );
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rStake, uint256 tTransferAmount, uint256 tStake, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFee(tFee);
        _takeBurn(tBurn);
        _stakeFee(rStake, tStake);

        emit Transfer(sender, recipient, tTransferAmount);

        if(tBurn > 0) {
            emit Burn(tBurn);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rStake, uint256 tTransferAmount, uint256 tStake, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeFee(tFee);
        _takeBurn(tBurn);
        _stakeFee(rStake, tStake);
        emit Transfer(sender, recipient, tTransferAmount);

        if(tBurn > 0) {
            emit Burn(tBurn);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rStake, uint256 tTransferAmount, uint256 tStake, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFee(tFee);
        _takeBurn(tBurn);
        _stakeFee(rStake, tStake);
        emit Transfer(sender, recipient, tTransferAmount);

        if(tBurn > 0) {
            emit Burn(tBurn);
        }
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rStake, uint256 tTransferAmount, uint256 tStake, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _takeFee(tFee);
        _takeBurn(tBurn);
        _stakeFee(rStake, tStake);
        emit Transfer(sender, recipient, tTransferAmount);

        if(tBurn > 0) {
            emit Burn(tBurn);
        }
    }

    function _applyFees(address from, address to) private {
        if(_buyStakingFee == 0 && _buyLiquidityFee == 0 && _buyMarketingFee == 0 && _buyBurningFee == 0) return;

        if(to == address(0)) {
            _oldStakingFee = _buyStakingFee;
            _oldLiquidityFee = _buyLiquidityFee;
            _oldMarketingFee = _buyMarketingFee;
            _oldBurningFee = _buyBurningFee;

            _buyStakingFee = 0;
            _buyLiquidityFee = 0;
            _buyMarketingFee = 0;
            _buyBurningFee = 100;
        } else if(_excludedFromFee[from] || _excludedFromFee[to]) {
            _oldStakingFee = _buyStakingFee;
            _oldLiquidityFee = _buyLiquidityFee;
            _oldMarketingFee = _buyMarketingFee;
            _oldBurningFee = _buyBurningFee;

            _buyStakingFee = 0;
            _buyLiquidityFee = 0;
            _buyMarketingFee = 0;
            _buyBurningFee = 0;

        } else if(liquidityPairAddress[to]) {

            _buyStakingFee = _sellStakingFee;
            _buyLiquidityFee = _sellLiquidityFee;
            _buyMarketingFee = _sellMarketingFee;
            _buyBurningFee = _sellBurningFee;

        } else if(!from.isContract() && !to.isContract()) {
            _oldStakingFee = _buyStakingFee;
            _oldLiquidityFee = _buyLiquidityFee;
            _oldMarketingFee = _buyMarketingFee;
            _oldBurningFee = _buyBurningFee;

            _buyStakingFee = _normalStakingFee;
            _buyLiquidityFee = 0;
            _buyMarketingFee = 0;
            _buyBurningFee = 0;
        }
    }
    
    function _restoreFees() private {
        _buyStakingFee = _oldStakingFee;
        _buyLiquidityFee = _oldLiquidityFee;
        _buyMarketingFee = _oldMarketingFee;
        _buyBurningFee = _oldBurningFee;
    }
    
    function _takeFee(uint256 tFee) private {
        uint256 currentRate =  _getRate();
        uint256 rFee = tFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFee);
        if(_excludedFromStaking[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tFee);
    }
    
    function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[address(0)] = _rOwned[address(0)].add(rBurn);
        _rTotal = _rTotal.sub(rBurn);

        if(_excludedFromStaking[address(0)]) {
            _tOwned[address(0)] = _tOwned[address(0)].add(tBurn);
            _tTotal = _tTotal.sub(tBurn);
        }
    }

    function burnToken(uint256 amount) external {
        _transfer(_msgSender(), address(0), amount);
    }

    function _calculateStakingFee(uint256 _amount) private view returns (uint256) {
            return _amount.mul(_buyStakingFee).div(
                10**2
            );
    }

    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_buyLiquidityFee).div(
            10**2
        );
    }

    function _calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_buyMarketingFee).div(
            10**2
        );
    }

    function _calculateBurningFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_buyBurningFee).div(
            10**2
        );
    }    
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {

        (uint256 tTransferAmount, uint256 tStake, uint256 tFee, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rStake) = _getRValues(tAmount, tStake, tFee, tBurn, _getRate());
        return (rAmount, rTransferAmount, rStake, tTransferAmount, tStake, tFee, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tStake = _calculateStakingFee(tAmount);
        uint256 tFee = _calculateLiquidityFee(tAmount).add(_calculateMarketingFee(tAmount));
        uint256 tBurn = _calculateBurningFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tStake).sub(tFee).sub(tBurn);
        return (tTransferAmount, tStake, tFee, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tStake, uint256 tFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rStake = tStake.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rStake).sub(rFee).sub(rBurn);
        return (rAmount, rTransferAmount, rStake);
    }

    function _stakeFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
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

    receive() external payable {}
}