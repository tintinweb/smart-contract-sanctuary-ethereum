/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

/////////////////////////////////////////////////////////////////
///////////////////HOCUS//POCUS//////////////////
/////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender)
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


/////////////////////////////////////////////////
////////////////PULSEX//INTERFACE////////////////
/////////////////////////////////////////////////

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address lpPair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address lpPair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address lpPair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

///////////////////////////////////////////////////////////////
////////////////////CONTRACT//IMPLEMENTATION///////////////////
///////////////////////////////////////////////////////////////

contract HocusPocus is Context, IERC20 {
    // Ownership moved to in-contract for customizability.
    using SafeMath for uint256;
    using Address for address;
    address private _owner;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    mapping(address => bool) private _liquidityHolders;

    string private constant _name = "Hocus Pocus";
    string private constant _symbol = "HOC";
    uint8 private constant _decimals = 4;

    uint256 constant _totalSupply = 5_555_000_000_000 * (10**_decimals);
    uint256 private constant _tTotal = _totalSupply;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    struct Fees {
        uint16 reflect;
        uint16 burn;
        uint16 liquidity;
        uint16 treasury;
        uint16 team;
        uint16 sensFoundation;
        uint16 totalSwap;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 treasury;
        uint16 total;
    }

    Fees public _buyTaxes =
        Fees({
            reflect: 0,
            burn: 0,
            liquidity: 0,
            treasury: 0,
            sensFoundation: 100,
            team: 0,
            totalSwap: 0
        });

    Fees public _sellTaxes =
        Fees({
            reflect: 200,
            burn: 50,
            liquidity: 200,
            treasury: 350,
            sensFoundation: 0,
            team: 200,
            totalSwap: 550
        });

    Ratios public _ratios = Ratios({liquidity: 200, treasury: 350, total: 550});

    uint256 constant masterTaxDivisor = 10000;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant sensWallet =
        0x29E6d8b995C55767011adeeb1CB1d1Ed978BE451;
    address public constant teamWallet =
        0xd2642379D0D4dE718675321F7e0268E7BF4f1a47;

    struct treasuryWallet {
        address payable treasury;
    }

    treasuryWallet public _treasuryWallet =
        treasuryWallet({
            treasury: payable(0xb7e2575C7BEC6eb03D454b8510Bd33Fe335EB3e6)
        });

    bool inSwap;
    uint256 public contractSwapTimer = 0 seconds;
    uint256 private lastSwap;
    uint256 public constant swapThreshold = (_tTotal * 5) / 10000;
    uint256 public constant swapAmount = (_tTotal * 10) / 10000;

    uint256 private _maxTxAmount = (_tTotal * 100) / 100;
    uint256 private _maxWalletSize = (_tTotal * 100) / 100;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller =/= owner.");
        _;
    }

    constructor() payable {
        _rOwned[msg.sender] = _rTotal;

        // Set the owner.
        _owner = msg.sender;

        if (block.chainid == 56) {
            dexRouter = IUniswapV2Router02(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            );
            contractSwapTimer = 3 seconds;
        } else if (block.chainid == 97) {
            dexRouter = IUniswapV2Router02(
                0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
            );
            contractSwapTimer = 3 seconds;
        } else if (block.chainid == 1 || block.chainid == 4) {
            dexRouter = IUniswapV2Router02(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            );
            contractSwapTimer = 10 seconds;
        } else {
            revert();
        }

        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(
            dexRouter.WETH(),
            address(this)
        );
        lpPairs[lpPair] = true;

        _approve(msg.sender, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[owner()] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Call renounceOwnership to transfer owner to the zero address."
        );
        require(
            newOwner != DEAD,
            "Call renounceOwnership to transfer owner to the zero address."
        );
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);

        if (balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }

        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() external virtual onlyOwner {
        setExcludedFromFees(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function totalSupply() external pure override returns (uint256) {
        if (_tTotal == 0) {
            revert();
        }
        return _tTotal;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setNewRouter(address newRouter) external onlyOwner {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(
            address(this),
            _newRouter.WETH()
        );
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(
                address(this),
                _newRouter.WETH()
            );
        } else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(
                    block.timestamp - timeSinceLastPair > 3 days,
                    "3 Day cooldown.!"
                );
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function getCirculatingSupply() external view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludedFromReward(address account, bool enabled)
        external
        onlyOwner
    {
        if (enabled) {
            require(!_isExcluded[account], "Account is already excluded.");
            if (_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            if (account != lpPair) {
                _excluded.push(account);
            }
        } else if (!enabled) {
            require(_isExcluded[account], "Account is already included.");
            if (account == lpPair) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
            } else if (_excluded.length == 1) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
            } else {
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _tOwned[account] = 0;
                        _rOwned[account] = _tOwned[account] * _getRate();
                        _isExcluded[account] = false;
                        _excluded.pop();
                        break;
                    }
                }
            }
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor)
        external
        onlyOwner
    {
        require(
            (_tTotal * percent) / divisor >= (_tTotal / 1000),
            "Max Transaction amt must be above 0.1% of total supply."
        );
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor)
        external
        onlyOwner
    {
        require(
            (_tTotal * percent) / divisor >= (_tTotal / 1000),
            "Max Wallet amt must be above 0.1% of total supply."
        );
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function setExcludedFromLimits(address account, bool enabled)
        external
        onlyOwner
    {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled)
        public
        onlyOwner
    {
        _isExcludedFromFees[account] = enabled;
    }

    function getMaxTX() external view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function setWallets(address payable treasury) external onlyOwner {
        _treasuryWallet.treasury = payable(treasury);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (lpPairs[from] || lpPairs[to]) {
            if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount."
                );
            }
        }
        if (to != address(dexRouter) && !lpPairs[to]) {
            if (!_isExcludedFromLimits[to]) {
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Transfer amount exceeds the maxWalletSize."
                );
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        if (lpPairs[to]) {
            if (!inSwap) {
                if (lastSwap + contractSwapTimer < block.timestamp) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        if (contractTokenBalance >= swapAmount) {
                            contractTokenBalance = swapAmount;
                        }
                        contractSwap(contractTokenBalance);
                        lastSwap = block.timestamp;
                    }
                }
            }
        }
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function contractSwap(uint256 contractTokenBalance) private lockTheSwap {
        Ratios memory ratios = _ratios;
        if (ratios.total == 0) {
            return;
        }

        if (
            _allowances[address(this)][address(dexRouter)] != type(uint256).max
        ) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) /
            ratios.total) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }

        amtBalance -= liquidityBalance;
        ratios.total -= ratios.liquidity;
        uint256 treasuryBalance = amtBalance;
        if (ratios.treasury > 0) {
            _treasuryWallet.treasury.transfer(treasuryBalance);
        }
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;
        uint256 tBurn;
        uint256 tSens;
        uint256 tTeam;
        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
        uint256 currentRate;
    }

    function _finalizeTransfer(
        address from,
        address to,
        uint256 tAmount,
        bool takeFee
    ) private returns (bool) {
        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_isExcluded[from]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        }
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (values.rFee > 0 || values.tFee > 0) {
            _rTotal -= values.rFee;
        }

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function _getValues(
        address from,
        address to,
        uint256 tAmount,
        bool takeFee
    ) private returns (ExtraValues memory) {
        ExtraValues memory values;
        values.currentRate = _getRate();

        values.rAmount = tAmount * values.currentRate;

        if (takeFee) {
            uint256 currentReflect;
            uint256 currentSwap;
            uint256 currentBurn;
            uint256 currentSens;
            uint256 currentTeam;
            uint256 divisor = masterTaxDivisor;

            if (lpPairs[to]) {
                currentReflect = _sellTaxes.reflect;
                currentBurn = _sellTaxes.burn;
                currentSens = _sellTaxes.sensFoundation;
                currentTeam = _sellTaxes.team;
                currentSwap = _sellTaxes.totalSwap;
            } else if (lpPairs[from]) {
                currentReflect = _buyTaxes.reflect;
                currentBurn = _buyTaxes.burn;
                currentSens = _buyTaxes.sensFoundation;
                currentTeam = _buyTaxes.team;
                currentSwap = _buyTaxes.totalSwap;
            }

            values.tFee = (tAmount * currentReflect) / divisor;
            values.tSwap = (tAmount * currentSwap) / divisor;
            values.tBurn = (tAmount * currentBurn) / divisor;
            values.tSens = (tAmount * currentSens) / divisor;
            values.tTeam = (tAmount * currentTeam) / divisor;
            values.tTransferAmount =
                tAmount -
                (values.tFee +
                    values.tSwap +
                    values.tBurn +
                    values.tSens +
                    values.tTeam);

            values.rFee = values.tFee * values.currentRate;
        } else {
            values.tFee = 0;
            values.tSwap = 0;
            values.tBurn = 0;
            values.tSens = 0;
            values.tTeam = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] += values.tSwap * values.currentRate;
            if (_isExcluded[address(this)]) {
                _tOwned[address(this)] += values.tSwap;
            }
            emit Transfer(from, address(this), values.tSwap);
        }

        if (values.tBurn > 0) {
            _rOwned[DEAD] += values.tBurn * values.currentRate;
            if (_isExcluded[DEAD]) {
                _tOwned[DEAD] += values.tBurn;
            }
            emit Transfer(from, DEAD, values.tBurn);
        }

        if (values.tSens > 0) {
            _rOwned[sensWallet] += values.tSens * values.currentRate;
            if (_isExcluded[sensWallet]) {
                _tOwned[sensWallet] += values.tSens;
            }
            emit Transfer(from, sensWallet, values.tSens);
        }

        if (values.tTeam > 0) {
            _rOwned[teamWallet] += values.tTeam * values.currentRate;
            if (_isExcluded[teamWallet]) {
                _tOwned[teamWallet] += values.tTeam;
            }
            emit Transfer(from, teamWallet, values.tTeam);
        }

        values.rTransferAmount =
            values.rAmount -
            (values.rFee +
                (values.tSwap * values.currentRate) +
                (values.tBurn * values.currentRate) +
                (values.tSens * values.currentRate) +
                (values.tTeam * values.currentRate));
        return values;
    }

    function _getRate() internal view returns (uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (_isExcluded[lpPair]) {
            if (_rOwned[lpPair] > rSupply || _tOwned[lpPair] > tSupply)
                return _rTotal / _tTotal;
            rSupply -= _rOwned[lpPair];
            tSupply -= _tOwned[lpPair];
        }
        if (_excluded.length > 0) {
            for (uint8 i = 0; i < _excluded.length; i++) {
                if (
                    _rOwned[_excluded[i]] > rSupply ||
                    _tOwned[_excluded[i]] > tSupply
                ) return _rTotal / _tTotal;
                rSupply = rSupply - _rOwned[_excluded[i]];
                tSupply = tSupply - _tOwned[_excluded[i]];
            }
        }
        if (rSupply < _rTotal / _tTotal) return _rTotal / _tTotal;
        return rSupply / tSupply;
    }
}