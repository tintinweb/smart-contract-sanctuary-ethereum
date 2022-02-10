/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: Unlicensed

// BUSD lock not working with AAA
// CHECK MAX SENDING AMOUNT LIMIT
// STATE UPDATE CHeck

// onlyowner func
// context, ownable libs check
// check setNumTokensSellToAddToLiquidity

// check locked liquidity with other tokens

// add pausable function
// add liquidity providers from shikage contract

pragma solidity ^0.8.4;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
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
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Only owner can access!");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

contract Final is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "Final";
    string private _symbol = "FFF";
    uint256 private _decimals = 18;

    mapping(address => uint256) private _reflectionBalances;
    mapping(address => uint256) private _tokenBalances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcludedFromReward;
    address[] private _excluded;

    uint256 private _reflectionTotal;
    uint256 private _totalSupply = 100 * (10**6) * (10**_decimals);

    uint256 private _totalRewarded;

    uint8 public _taxReward = 10;
    uint8 public _taxLiquify = 70;
    uint8 public _devTax = 10;

    uint256 public _minTokensBeforeSwap = 5 * (10**6) * (10**_decimals);

    IPancakeRouter02 internal _pancakeRouter;
    address internal _pancakePair;

    uint256 public _totalTokensLockedInLiquidity;
    uint256 public _totalETHLockedInLiquidity;

    bool public _autoSwapAndLiquifyEnabled;
    bool public _rewardEnabled;
    bool public _devFeeEnabled;

    struct ValuesFromAmount {
        // Amount of tokens for to transfer.
        uint256 amount;
        // Amount tokens charged for development.
        uint256 tDevFee;
        // Amount tokens charged to reward.
        uint256 tRewardFee;
        // Amount tokens charged to add to liquidity.
        uint256 tLiquifyFee;
        // Amount tokens after fees.
        uint256 tTransferAmount;
        // Reflection of amount.
        uint256 rAmount;
        // Reflection of dev fee.
        uint256 rDevFee;
        // Reflection of reward fee.
        uint256 rRewardFee;
        // Reflection of liquify fee.
        uint256 rLiquifyFee;
        // Reflection of transfer amount.
        uint256 rTransferAmount;
    }

    event MinTokensBeforeSwapUpdated(
        uint256 previousMinTokensBeforeSwap,
        uint256 minTokensBeforeSwap_
    );
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event ExcludeAccountFromFee(address account);
    event IncludeAccountInFee(address account);
    event ExcludeAccountFromReward(address account);
    event IncludeAccountInReward(address account);
    event SetTaxFeePercent(uint256);
    event SetNumTokensSellToAddLiquidity(uint256);
    event EnabledDevFee();
    event EnabledReward();
    event EnabledAutoSwapAndLiquify();
    event DevFeeUpdate(uint8 previousTax, uint8 currentTax);
    event TaxRewardUpdate(uint8 previousTax, uint8 currentTax);
    event TaxLiquifyUpdate(uint8 previousTax, uint8 currentTax);
    event DisabledDevFee();
    event DisabledReward();
    event DisabledAutoSwapAndLiquify();

    bool _inSwapAndLiquify;
    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    address _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;

    address private constant burnAccount =
        0x000000000000000000000000000000000000dEaD;

    address private constant zeroAddress =
        0x0000000000000000000000000000000000000000;

    address private constant marketingReceiver =
        0x9Dcd3212FD95dA843D4EE2Ec00BfE71D0d201Db9;

    address private constant liquidityReceiver =
        0x9Dcd3212FD95dA843D4EE2Ec00BfE71D0d201Db9;

    constructor() {
        enableDevFee(_devTax);
        enableReward(_taxReward);
        enableAutoSwapAndLiquify(
            _taxLiquify,
            _routerAddress,
            _minTokensBeforeSwap
        );

        //exclude owner and this contract from fee
        // _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _reflectionTotal = (~uint256(0) - (~uint256(0) % _totalSupply));
        _reflectionBalances[_msgSender()] = _reflectionTotal;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function totalRewarded() public view returns (uint256) {
        return _totalRewarded;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tokenBalances[account];
        return tokenFromReflection(_reflectionBalances[account]);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
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
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        ValuesFromAmount memory values = _getValues(
            amount,
            _isExcludedFromFee[sender]
        );
        if (
            _isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]
        ) {
            _transferFromExcluded(sender, recipient, values);
        } else if (
            !_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferToExcluded(sender, recipient, values);
        } else if (
            !_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]
        ) {
            _transferStandard(sender, recipient, values);
        } else if (
            _isExcludedFromReward[sender] && _isExcludedFromReward[recipient]
        ) {
            _transferBothExcluded(sender, recipient, values);
        } else {
            _transferStandard(sender, recipient, values);
        }
        emit Transfer(sender, recipient, values.tTransferAmount);

        if (!_isExcludedFromFee[sender]) {
            _afterTokenTransfer(values);
        }
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        ValuesFromAmount memory values
    ) private {
        _tokenBalances[sender] = _tokenBalances[sender] - values.amount;
        _reflectionBalances[sender] =
            _reflectionBalances[sender] -
            values.rAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            values.rTransferAmount;
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        ValuesFromAmount memory values
    ) private {
        _reflectionBalances[sender] =
            _reflectionBalances[sender] -
            values.rAmount;
        _tokenBalances[recipient] =
            _tokenBalances[recipient] +
            values.tTransferAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            values.rTransferAmount;
    }

    function _transferStandard(
        address sender,
        address recipient,
        ValuesFromAmount memory values
    ) private {
        _reflectionBalances[sender] =
            _reflectionBalances[sender] -
            values.rAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            values.rTransferAmount;
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        ValuesFromAmount memory values
    ) private {
        _tokenBalances[sender] = _tokenBalances[sender] - values.amount;
        _reflectionBalances[sender] =
            _reflectionBalances[sender] -
            values.rAmount;
        _tokenBalances[recipient] =
            _tokenBalances[recipient] +
            values.tTransferAmount;
        _reflectionBalances[recipient] =
            _reflectionBalances[recipient] +
            values.rTransferAmount;
    }

    function _afterTokenTransfer(ValuesFromAmount memory values)
        internal
        virtual
    {
        /*Burn
        if (_autoBurnEnabled) {
            _tokenBalances[address(this)] += values.tBurnFee;
            _reflectionBalances[address(this)] += values.rBurnFee;
            _approve(address(this), _msgSender(), values.tBurnFee);
            burnFrom(address(this), values.tBurnFee);
        }*/
        // Dev Fee
        if (_devFeeEnabled) {
            _tokenBalances[marketingReceiver] += values.tDevFee;
            _reflectionBalances[marketingReceiver] += values.rDevFee;
        }
        // Reflect
        if (_rewardEnabled) {
            _distributeFee(values.rRewardFee, values.tRewardFee);
        }

        // Add to liquidity pool
        if (_autoSwapAndLiquifyEnabled) {
            // add liquidity fee to this contract.
            _tokenBalances[address(this)] += values.tLiquifyFee;
            _reflectionBalances[address(this)] += values.rLiquifyFee;

            uint256 contractBalance = _tokenBalances[address(this)];

            // whether the current contract balances makes the threshold to swap and liquify.
            bool overMinTokensBeforeSwap = contractBalance >=
                _minTokensBeforeSwap;

            if (
                overMinTokensBeforeSwap &&
                !_inSwapAndLiquify &&
                _msgSender() != _pancakePair &&
                _autoSwapAndLiquifyEnabled
            ) {
                contractBalance = _minTokensBeforeSwap;
                swapAndLiquify(contractBalance);
            }
        }
    }

    function _getValues(uint256 amount, bool deductTransferFee)
        private
        view
        returns (ValuesFromAmount memory)
    {
        ValuesFromAmount memory values;
        values.amount = amount;
        _getTValues(values, deductTransferFee);
        _getRValues(values, _getRate(), deductTransferFee);
        return (values);
    }

    function _getTValues(ValuesFromAmount memory values, bool deductTransferFee)
        private
        view
    {
        if (deductTransferFee) {
            values.tTransferAmount = values.amount;
        } else {
            values.tDevFee = calculateDevFee(values.amount);
            values.tRewardFee = calculateTaxFee(values.amount);
            values.tLiquifyFee = calculateLiquidityFee(values.amount);
            values.tTransferAmount =
                values.amount -
                values.tRewardFee -
                values.tLiquifyFee;
        }
    }

    function _getRValues(
        ValuesFromAmount memory values,
        uint256 currentRate,
        bool deductTransferFee
    ) private pure {
        values.rAmount = values.amount * currentRate;
        if (deductTransferFee) {
            values.rTransferAmount = values.rAmount;
        } else {
            values.rAmount = values.amount * currentRate;
            values.rDevFee = values.tDevFee * currentRate;
            values.rRewardFee = values.tRewardFee * currentRate;
            values.rLiquifyFee = values.tLiquifyFee * currentRate;
            values.rTransferAmount =
                values.rAmount -
                values.rRewardFee -
                values.rLiquifyFee;
        }
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _reflectionTotal;
        uint256 tSupply = _totalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalances[_excluded[i]] > rSupply ||
                _tokenBalances[_excluded[i]] > tSupply
            ) return (_reflectionTotal, _totalSupply);
            rSupply = rSupply.sub(_reflectionBalances[_excluded[i]]);
            tSupply = tSupply.sub(_tokenBalances[_excluded[i]]);
        }
        if (rSupply < _reflectionTotal.div(_totalSupply))
            return (_reflectionTotal, _totalSupply);
        return (rSupply, tSupply);
    }

    function swapAndLiquify(uint256 contractBalance) private lockTheSwap {
        // Split the contract balance into two halves.
        uint256 tokensToSwap = contractBalance / 2;
        uint256 tokensAddToLiquidity = contractBalance - tokensToSwap;

        // Contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // Swap half of the tokens to ETH.
        swapTokensForEth(tokensToSwap);

        // Figure out the exact amount of tokens received from swapping.
        uint256 ethAddToLiquify = address(this).balance - initialBalance;

        // Add to the LP of this token and WETH pair (half ETH and half this token).
        addLiquidity(ethAddToLiquify, tokensAddToLiquidity);

        _totalETHLockedInLiquidity = address(this).balance - initialBalance;
        _totalTokensLockedInLiquidity =
            contractBalance -
            balanceOf(address(this));

        emit SwapAndLiquify(
            tokensToSwap,
            ethAddToLiquify,
            tokensAddToLiquidity
        );
    }

    function swapTokensForEth(uint256 amount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _approve(address(this), address(_pancakeRouter), amount);

        // Swap tokens to ETH
        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this), // this contract will receive the eth that were swapped from the token
            block.timestamp + 60 * 1000
        );
    }

    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) private {
        _approve(address(this), address(_pancakeRouter), tokenAmount);

        _pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver, // the LP is sent to burnAccount.
            block.timestamp + 60 * 1000
        );
    }

    function reflectionFromToken(uint256 amount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        ValuesFromAmount memory values = _getValues(amount, deductTransferFee);
        return values.rTransferAmount;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _distributeFee(uint256 rRewardFee, uint256 tRewardFee) private {
        // This would decrease rate, thus increase amount reward receive based on one's balance.
        _reflectionTotal = _reflectionTotal - rRewardFee;
        _totalRewarded = _totalRewarded + tRewardFee;
    }

    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _devTax) / (10**2);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxReward) / (10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * _taxLiquify) / (10**2);
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if (_reflectionBalances[account] > 0) {
            _tokenBalances[account] = tokenFromReflection(
                _reflectionBalances[account]
            );
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
        emit ExcludeAccountFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalances[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit IncludeAccountInReward(account);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeAccountFromFee(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeAccountInFee(account);
    }

    function enableDevFee(uint8 devTax_) public onlyOwner {
        require(!_devFeeEnabled, "Dev Fee feature is already enabled.");
        require(devTax_ > 0, "Tax must be greater than 0.");

        _devFeeEnabled = true;
        setDevFee(devTax_);

        emit EnabledDevFee();
    }

    function setDevFee(uint8 devTax_) public onlyOwner {
        require(
            _devFeeEnabled,
            "Dev feature must be enabled. Try the EnableDevFee function."
        );
        require(_taxReward + _taxLiquify + devTax_ < 100, "Tax fee too high.");

        uint8 previousTax = _devTax;
        _devTax = devTax_;

        emit DevFeeUpdate(previousTax, devTax_);
    }

    function disableDevFee() public onlyOwner {
        require(_devFeeEnabled, "Dev Fee feature is already disabled.");

        setDevFee(0);
        _devFeeEnabled = false;

        emit DisabledDevFee();
    }

    function enableReward(uint8 taxReward_) public onlyOwner {
        require(!_rewardEnabled, "Reward feature is already enabled.");
        require(taxReward_ > 0, "Tax must be greater than 0.");

        _rewardEnabled = true;
        excludeFromReward(burnAccount);
        excludeFromReward(zeroAddress);
        setTaxReward(taxReward_);

        emit EnabledReward();
    }

    function setTaxReward(uint8 taxReward_) public onlyOwner {
        require(
            _rewardEnabled,
            "Reward feature must be enabled. Try the EnableReward function."
        );
        require(taxReward_ + _taxLiquify + _devTax < 100, "Tax fee too high.");

        uint8 previousTax = _taxReward;
        _taxReward = taxReward_;

        emit TaxRewardUpdate(previousTax, taxReward_);
    }

    function disableReward() public onlyOwner {
        require(_rewardEnabled, "Reward feature is already disabled.");

        setTaxReward(0);
        _rewardEnabled = false;

        emit DisabledReward();
    }

    function enableAutoSwapAndLiquify(
        uint8 taxLiquify_,
        address routerAddress,
        uint256 minTokensBeforeSwap_
    ) public onlyOwner {
        require(
            !_autoSwapAndLiquifyEnabled,
            "Auto swap and liquify feature is already enabled."
        );
        require(taxLiquify_ > 0, "Tax must be greater than 0.");

        _minTokensBeforeSwap = minTokensBeforeSwap_;

        // init Router
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        _pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );

        _pancakeRouter = pancakeRouter;

        // exclude PancakeRouter from receiving reward.
        excludeFromReward(address(pancakeRouter));
        // exclude WETH and this Token Pair from receiving reward.
        excludeFromReward(_pancakePair);

        excludeFromFee(owner());

        // exclude PancakeRouter from paying fees.
        excludeFromFee(address(pancakeRouter));
        // exclude WETH and this Token Pair from paying fees.
        excludeFromFee(_pancakePair);

        // enable
        _autoSwapAndLiquifyEnabled = true;
        setTaxLiquify(taxLiquify_);

        emit EnabledAutoSwapAndLiquify();
    }

    function setMinTokensBeforeSwap(uint256 minTokensBeforeSwap_)
        public
        onlyOwner
    {
        require(
            _autoSwapAndLiquifyEnabled,
            "Auto swap and liquify feature must be enabled. Try the EnableAutoSwapAndLiquify function."
        );
        uint256 previousMinTokensBeforeSwap = minTokensBeforeSwap_;
        _minTokensBeforeSwap = minTokensBeforeSwap_;
        emit MinTokensBeforeSwapUpdated(
            previousMinTokensBeforeSwap,
            minTokensBeforeSwap_
        );
    }

    function setTaxLiquify(uint8 taxLiquify_) public onlyOwner {
        require(
            _autoSwapAndLiquifyEnabled,
            "Auto swap and liquify feature must be enabled. Try the EnableAutoSwapAndLiquify function."
        );
        require(_taxReward + taxLiquify_ + _devTax < 100, "Tax fee too high.");
        uint8 previousTax = _taxLiquify;
        _taxLiquify = taxLiquify_;
        emit TaxLiquifyUpdate(previousTax, taxLiquify_);
    }

    function disableAutoSwapAndLiquify() public onlyOwner {
        require(
            _autoSwapAndLiquifyEnabled,
            "Auto swap and liquify feature is already disabled."
        );
        setTaxLiquify(0);
        _autoSwapAndLiquifyEnabled = false;
        emit DisabledAutoSwapAndLiquify();
    }
}