/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

pragma solidity 0.7.6;
// SPDX-License-Identifier: Unlicensed
pragma experimental ABIEncoderV2;

interface IERC20 {
    function decimals() external view returns (uint8);

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        //internal
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// pragma solidity >=0.6.2;

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

/// @title Wallphy Token Contract

contract Wallphy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private _tTotal = 1000000000000000 * 10**18;
    string private _name = "Wallphy";
    string private _symbol = "Wallphy";
    uint8 private _decimals = 18;
    uint256 public _taxFee = 12;
    uint256 public _liquidityFee = 3;
    uint256 public _additionalTax = 10;
    /// @notice Above this amount, the additionalTax will be charged on transfers
    uint256 public _additionalTaxThreshold = _tTotal.mul(25).div(10000); 
    address public devFeeWallet = 0x67a76c888fA3576984142227D2ea31091739853F;
    mapping(address => bool) private transferBlacklist;
    /// @notice Token transfers associated with trades on a DEX (Uniswap) are taxed
    bool public taxOnlyDex = true;
    uint256 public _maxTxAmount = _tTotal.mul(1).div(100);
    uint256 public taxYetToBeSentToDev;
    uint256 private minimumDevTaxDistributionThreshold = 0;
    uint256 public taxYetToBeLiquified;
    uint256 private numTokensSellToAddToLiquidity = 0;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool private inSwapAndSendDev;
    bool public swapAndSendDevEnabled = true;
    bool public isAirdropCompleted = false;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndSendDevEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    modifier lockSendDev() {
        inSwapAndSendDev = true;
        _;
        inSwapAndSendDev = false;
    }

    constructor() {
        //manually set owner balance so owner can provide liquidity before conducting the airdrop. Value is calculated prior to deployment and is the amount of tokens after subtracting airdrop allocations
        _tOwned[msg.sender] = 211032861142177000000000000000000;
        _tOwned[address(this)]=_tTotal.sub(_tOwned[msg.sender]);
        setRouterAddress(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uniswap V2 router
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    /// @notice Returns the token's name
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice Returns the token's symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the token's decimal precision
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice Returns the token's total supply
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    /// @notice Returns the token balance of an address
    /// @param account address to query
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    /// @notice Transfers tokens while implementing customized tax logic
    /// @param _to Recipient address
    /// @param _value amount of tokens to transfer
    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        require(_value > 0, "Value Too Low");
        require(transferBlacklist[msg.sender] == false, "Sender Blacklisted");
        require(transferBlacklist[_to] == false, "Recipient Blacklisted");
        require(_tOwned[msg.sender] >= _value, "Balance Too Low");

        if (
            _isExcludedFromFee[msg.sender] == true ||
            _isExcludedFromFee[_to] == true
        ) {
            _tOwned[msg.sender] = _tOwned[msg.sender].sub(_value);
            _tOwned[_to] = _tOwned[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        } else if (
            taxOnlyDex == true &&
            (_msgSender() == uniswapV2Pair || _to == uniswapV2Pair)
        ) {
            //Taxes direct transfers to/from LP pair
            _transfer(_msgSender(), _to, _value);
        } else {
            //transfers between regular wallets are not taxed
            _tOwned[msg.sender] = _tOwned[msg.sender].sub(_value);
            _tOwned[_to] = _tOwned[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
        }
        return true;
    }

    /// @notice Checks how many tokens an address can transfer on behalf of another address
    /// @param owner address that owns the tokens
    /// @param spender address that is allowed to transfer tokens on behalf of owner
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /// @notice Sets the amount of tokens an address can transfer on behalf of another address
    /// @param _spender address that is allowed to transfer tokens on behalf of the function caller
    /// @param _value amount of tokens that _spender is allowed to transfer
    function approve(address _spender, uint256 _value)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), _spender, _value);
        return true;
    }

    /// @notice Allows caller to transfer tokens on behalf of an address
    /// @param _from Address that sends the tokens
    /// @param _to Address that receives the tokens
    /// @param _value amount of tokens to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        require(_value > 0, "Value Too Low");
        require(transferBlacklist[_from] == false, "Sender Blacklisted");
        require(transferBlacklist[_to] == false, "Recipient Blacklisted");
        require(_value <= _tOwned[_from], "Balance Too Low");
        require(_value <= _allowances[_from][msg.sender], "Approval Too Low");

        if (
            _isExcludedFromFee[_from] == true || _isExcludedFromFee[_to] == true
        ) {
            _tOwned[_from] = _tOwned[_from].sub(_value);
            _tOwned[_to] = _tOwned[_to].add(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(
                _value
            );

            emit Transfer(_from, _to, _value);
        } else {
            _transfer(_from, _to, _value);
            _approve(
                _from,
                _msgSender(),
                _allowances[_from][_msgSender()].sub(
                    _value,
                    "ERC20: transfer amount exceeds allowance"
                )
            );
        }
        return true;
    }


    /// @notice Conducts airdrop to an array of users
    /// @param supportersAddresses Array of users
    /// @param supportersAmounts Airdrop amount corresponding to each user
    function conductAirdrop(address[] memory supportersAddresses, uint256[] memory supportersAmounts) public onlyOwner{
        require(isAirdropCompleted==false, "Airdrop Already Finished");
        isAirdropCompleted=true;

        for (uint8 i = 0; i < supportersAddresses.length; i++) {
            _tOwned[address(this)]=_tOwned[address(this)].sub(supportersAmounts[i]);
            _tOwned[supportersAddresses[i]] = _tOwned[supportersAddresses[i]].add(supportersAmounts[i]);
            emit Transfer(address(this), supportersAddresses[i], supportersAmounts[i]);
        }
        
    }

    /// @notice This function is used in case you want to migrate liquidity to another DEX, which is why using Uniswap V2 is ideal, b/c most other Dexes are forks of V2
    /// @param newRouter DEX router address
    function setRouterAddress(address newRouter) public onlyOwner {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory())
            .createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }

    /// @notice Exclude an address from being charged a tax on token transfer
    /// @param account Address to exclude
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /// @notice Include an address to be charged a tax on token transfer
    /// @param account Address to include
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /// @notice Blacklist/unblacklist an address from being able to send and receive tokens
    /// @param account Account to modify setting for
    /// @param yesOrNo Blacklist or unblacklist
    function setBlacklist(address account, bool yesOrNo) public onlyOwner {
        transferBlacklist[account] = yesOrNo;
    }

    /// @notice Set the tax rate for the Dev tax, which is sent to the Dev Wallet
    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
         require (taxFee + _liquidityFee + _additionalTax <=25, "25 is Max Tax Threshold");
        _taxFee = taxFee;
    }

    /// @notice Set the tax rate for the liquidity tax, which is used to provide liquidity for the token
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require (_taxFee + liquidityFee + _additionalTax <=25, "25 is Max Tax Threshold");
        _liquidityFee = liquidityFee;
    }

    /// @notice Set the tax rate for the additional tax, which is charged when the token transfer amount is above a certain threshold
    function setAdditionalTax(uint256 additionalTax) external onlyOwner {
        require (_taxFee + _liquidityFee + additionalTax <=25, "25 is Max Tax Threshold");
        _additionalTax = additionalTax;
    }

    /// @notice Set the token amount, above which the _additionalTax will be charged on transfers
    function setAdditionalTaxThreshold(uint256 additionalTaxThreshold)
        external
        onlyOwner
    {
        _additionalTaxThreshold = additionalTaxThreshold;
    }

    /// @notice Set the max transaction amount, in basis points relative to the total supply, above which token transfers will be rejected
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        uint newMaxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
        require(newMaxTxAmount > _tTotal.mul(5).div(10000), "MaxTxAmount Tow Low");
        _maxTxAmount = newMaxTxAmount;
    }

    /// @notice Enable or disable the process of providing liquidity with the tokens collected by the liquidity tax
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /// @notice Enable or disable the process of converting the tokens collected by the Dev tax and sending it to the Dev wallet
    function setSwapAndSendDevEnabled(bool _enabled) public onlyOwner {
        swapAndSendDevEnabled = _enabled;
        emit SwapAndSendDevEnabledUpdated(_enabled);
    }

    /// @notice To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    /// @notice Calculates tax values
    /// @param tAmount Amount to transfer before taxes
    /// @param from address to transfer from
    /// @return tTransferAmount total token amount to transfer after subtracting the tax fees
    /// @return tFee total amount that goes towards the Devs
    /// @return tLiquidity total ammount that goes towards providing liquidity
    function _getTValues(uint256 tAmount, address from)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount, from); 
        uint256 tLiquidity = calculateLiquidityFee(tAmount); 
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity); 
        return (tTransferAmount, tFee, tLiquidity);
    }

    /// @notice Calculates Dev tax amount
    /// @param _amount Amount to transfer before taxes
    /// @param _from address to transfer from
    function calculateTaxFee(uint256 _amount, address _from)
        private
        view
        returns (uint256)
    {
        if (_amount > _additionalTaxThreshold && _from != uniswapV2Pair) {
            // additional tax on SELL orders if amount is > threshold
            uint256 higherTax = _taxFee.add(_additionalTax);
            return _amount.mul(higherTax).div(10**2);
        } else {
            return _amount.mul(_taxFee).div(10**2);
        }
    }

    /// @notice Calculates liquidity tax amount
    /// @param _amount Amount to transfer before taxes
    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    /// @notice Checks if an address is excluded from being taxed on token transfers
    /// @param account Account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /// @notice Sets the amount of tokens an address can transfer on behalf of another address
    /// @param owner address that owns the tokens
    /// @param spender address that is allowed to transfer tokens on behalf of owner
    /// @param amount amount of tokens that spender is allowed to transfer
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

    /// @notice Internal token transfer logic that takes care of calculating and collecting taxes
    /// @param from address that is sending the tokens
    /// @param to address that is receiving the tokens
    /// @param amount amount of tokens that is being sent
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(amount, from);

        //add the liquidity fee into the balance of this contract address, b/c will need to use to swap later
        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity); 
        taxYetToBeLiquified = taxYetToBeLiquified.add(tLiquidity);

        if (taxYetToBeLiquified >= numTokensSellToAddToLiquidity) {
            // only liquify if above a certain threshold
            // also, don't get caught in a circular liquidity event.
            // also, don't swap & liquify if sender is uniswap pair.
            if (
                !inSwapAndLiquify &&
                from != uniswapV2Pair &&
                swapAndLiquifyEnabled
            ) {
                //add liquidity
                swapAndLiquify(taxYetToBeLiquified);
                taxYetToBeLiquified = 0;
            }
        }

        //add the dev fee into the balance of this contract address, b/c will need to use to swap later
        _tOwned[address(this)] = _tOwned[address(this)].add(tFee); 
        taxYetToBeSentToDev = taxYetToBeSentToDev.add(tFee);

        if (
            taxYetToBeSentToDev >= minimumDevTaxDistributionThreshold
        ) {
            if (
                !inSwapAndSendDev &&
                from != uniswapV2Pair &&
                swapAndSendDevEnabled
            ) {
                //convert to ETH and send to Dev
                swapAndSendToDev(taxYetToBeSentToDev);
                taxYetToBeSentToDev = 0;
            }
        }

        _tOwned[from] = _tOwned[from].sub(amount);
        _tOwned[to] = _tOwned[to].add(tTransferAmount);
        emit Transfer(from, to, tTransferAmount);
    }

    /// @notice Converts tokens into ETH and sends to Dev wallet
    /// @param tokenAmount amount of tokens to convert to ETH
    function swapAndSendToDev(uint256 tokenAmount) private lockSendDev {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        bool sent = payable(devFeeWallet).send(newBalance);
        require(sent, "ETH transfer failed");
    }

    /// @notice Uses tokens to provide liquidty by first selling half to obtain ETH
    /// @param _numTokensSellToAddToLiquidity amount of tokens to use to provide liquidity
    function swapAndLiquify(uint256 _numTokensSellToAddToLiquidity)
        private
        lockTheSwap
    {
        // split the contract balance into halves
        uint256 half = _numTokensSellToAddToLiquidity.div(2);
        uint256 otherHalf = _numTokensSellToAddToLiquidity.sub(half);

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

    /// @notice Converts tokens to ETH via the DEX router
    /// @param tokenAmount amount of tokens to convert into ETH
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

    /// @notice Add liquidity for the token via the DEX router
    /// @param tokenAmount amount of tokens to use to provide liquidity
    /// @param ethAmount amount of tokens to use to provide liquidity
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

    /// @notice Sets the address that the Dev tax is sent to
    function setDevWallet(address _devWallet) external onlyOwner {
        devFeeWallet = _devWallet;
    }

    /// @notice Sets whether token transfers associated with trades on a DEX (Uniswap) are taxed
    function setTaxOnlyDex(bool _taxOnlyDex) external onlyOwner {
        taxOnlyDex = _taxOnlyDex;
    }
}