/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "hardhat/console.sol";



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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}
library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}
interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}
interface IWETH9 {
    function deposit() external payable ;
    function withdraw(uint wad) external ;
}
interface IQuoter {
    
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}


contract InsuranceDao {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //hardhat
    //address public constant USDT =  0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

    //rinkinby
    // address public constant USDT = 	0xB61d1dB83E6478e3daDf22caEb79D1ceC613ab0e;
    // address public constant USDC = 	0x0C41477f886F910d285f6d0893780f4D92A8cEE1;
    // address public constant WETH = 	0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // address public constant WBTC = 	0x577D296678535e4903D59A4C929B718e1D575e0A;

    //main
    address public constant USDT = 	0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 	0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 	0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WBTC = 	0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address public constant SWAPROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address public constant ORACLE_ETH = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant ORACLE_BTC = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;


    bool private _initialized = false;
    uint256 private _coverageAmount;
    uint8 private _premium;
    IERC20 private _insuredDao;
    uint256 public _insureFee;
    uint256 public _payOut;

    /*遍历成员*/
    mapping(address => bool) private _inserted;
    address[] public _members;
    
    mapping(address => mapping(address => uint256)) public _stakeBalances;
    mapping(address => uint256) public _stakeTotal;
    mapping(string => address) public _stakeName;
    address[] public _stakeTokens;

    
    IWETH9 private _weth9;
    ISwapRouter private swapRouter;
    IQuoter private quoter;
    AggregatorInterface private oracleEth;
    AggregatorInterface private oracleBtc;

    
    

    event Staking(address insureDaoAddress, address lpAddress, string symbol, uint256 amount);
    

    receive() external payable {
    }

    fallback() external payable {
    }

    function init(
        address insuredAddress,
        uint256 coverageAmount,
        uint8 premium
    ) external {
        require(_initialized == false, "Daoclub:");
        _initialized = true;
        _coverageAmount = coverageAmount;
        _premium = premium;
        
        _weth9 = IWETH9(WETH);
        _stakeTokens.push(WETH);
        _stakeTokens.push(USDT);
        _stakeTokens.push(USDC);
        _stakeTokens.push(WBTC);
        _stakeName["USDT"] = USDT;
        _stakeName["USDC"] = USDC;
        _stakeName["WETH"] = WETH;
        _stakeName["WBTC"] = WBTC;
        _stakeName["ETH"] = WETH;

        swapRouter = ISwapRouter(SWAPROUTER);
        quoter = IQuoter(QUOTER);
        oracleEth = AggregatorInterface(ORACLE_ETH);
        oracleBtc = AggregatorInterface(ORACLE_BTC);

        _insuredDao = IERC20(insuredAddress);

    }

    function isMember(address lp) public view returns (bool) {
        return _inserted[lp];
    }

    function getEthPrice() public view returns (uint256) {
        return uint256(oracleEth.latestAnswer());
    }

    function getBtcPrice() public view returns (uint256) {
        return uint256(oracleBtc.latestAnswer());
    }

    function getUValue(address token, uint256 amount) private view returns (uint256)  {
        if(token == WETH ) {
            return getEthUValue(amount);
        }else if (token == WBTC) {
            return getBtcUValue(amount);
        }else {
            return amount;
        }
    }

    

    function getEthUValue(uint256 ethAmount) private view returns (uint256) {
        return ethAmount.mul(getEthPrice()).div(10**20);
    }

    function getBtcUValue(uint256 btcAmount) private view returns (uint256) {
        return btcAmount.mul(getBtcPrice()).div(10**10);
    }

    function getTotalUValue() public view returns (uint256) {
        return getEthUValue(_stakeTotal[WETH])
        .add(getBtcUValue(_stakeTotal[WBTC]))
        .add(_stakeTotal[USDT])
        .add(_stakeTotal[USDC]);
    }

    
    function amountToBeRecovered() public view returns (uint256) {
        if(_insureFee == 0) {
            return 0;
        }
        return totalDaoTokens().mul(_payOut).div(_payOut.add(_insureFee));
    }

    function totalDaoTokens() public view returns (uint256) {
        uint256 total;
        for(uint i = 0; i < _members.length; i++ ) {
            total = total.add(_insuredDao.balanceOf(_members[i]));
        }
        return total;
    }

    function active() external  {
        require(msg.sender == address(_insuredDao));
        _insureFee = _insuredDao.balanceOf(address(this));
        if(_members.length > 0) {            
            uint256 insuredToken = _insuredDao.balanceOf(address(this));
            for(uint i = 0; i < _members.length; i++ ) {
                for(uint j = 0; j < _stakeTokens.length; j++ ) {
                    if(_stakeBalances[_stakeTokens[j]][_members[i]] > 0) {
                        _insuredDao.safeTransfer(_members[i], insuredToken.mul(getUValue(_stakeTokens[j], _stakeTotal[_stakeTokens[j]])).div(getTotalUValue()).mul(_stakeBalances[_stakeTokens[j]][_members[i]]).div(_stakeTotal[_stakeTokens[j]]));  
                    }
                }
            }
        } else {
            //保险dao没人 退还保费
            _insureFee = 0;
            //变更状态 作废保险dao
        }
        //精度 或者 无人投资 burn剩余token
        _insuredDao.safeTransfer(address(0), _insuredDao.balanceOf(address(this)));

    }



    


    function addMember() private {
        if(!_inserted[msg.sender]) {
            _inserted[msg.sender] = true;
            _members.push(msg.sender);
        }
    }

    function stakingETH() external payable {
        require(_insuredDao.balanceOf(msg.sender) == 0, "");
        _stakeBalances[WETH][msg.sender] += msg.value;
        _stakeTotal[WETH] += msg.value;
        emit Staking(address(this), msg.sender, "ETH", msg.value);
        addMember();
    }

    function stakingERC20(uint256 amount, string memory symbol) external {
        require(_insuredDao.balanceOf(msg.sender) == 0, "");
        IERC20(_stakeName[symbol]).safeTransferFrom(msg.sender, address(this), amount);
        _stakeBalances[_stakeName[symbol]][msg.sender] += amount;
        _stakeTotal[_stakeName[symbol]] += amount;
        emit Staking(address(this), msg.sender, symbol, amount);
        addMember();
    }


    

    


    function insure(uint256 amount, string memory symbol, address insuredDaoLp) public returns (uint256) {
        require(msg.sender == address(_insuredDao));
        require(!isMember(insuredDaoLp));
        //处理往原始dao转账的逻辑
        _weth9.deposit{value: address(this).balance}();
        address outToken = _stakeName[symbol];
        address[] memory inTokenArr = new address[](3);
        uint inTokenIndex = 0;
        for(uint i = 0; i < _stakeTokens.length; i++) {
            if(_stakeTokens[i] != outToken) {
                inTokenArr[inTokenIndex] = _stakeTokens[i];
                inTokenIndex ++ ;
            }
        }
        if(IERC20(outToken).balanceOf(address(this)) < amount) {
            disToken(outToken, IERC20(outToken).balanceOf(address(this)), insuredDaoLp);
            //卖币逻辑
            sellToken(outToken, inTokenArr, amount.sub(IERC20(outToken).balanceOf(address(this))), insuredDaoLp);
            if(IERC20(outToken).balanceOf(address(this)) < amount) {
                amount = IERC20(outToken).balanceOf(address(this));
            }
        }else {
            disToken(outToken, amount, insuredDaoLp);
        }
        //zhifu
        _weth9.withdraw(IERC20(WETH).balanceOf(address(this)));
        if(outToken == WETH) {
            payable(address(_insuredDao)).transfer(amount);     
        }else {
            IERC20(outToken).safeTransfer(address(_insuredDao), amount);
        }
        _payOut += amount;
        return amount;
    }

    function disToken(address tokenIn, uint256 amountOut, address insuredDaoLp) private {
        for(uint i = 0; i < _members.length; i++ ) {
            if(_stakeBalances[tokenIn][_members[i]] > 0) {
                _insuredDao.safeTransferFrom(insuredDaoLp, _members[i], amountOut.mul(_stakeBalances[tokenIn][_members[i]]).div(_stakeTotal[tokenIn]));
            }
        }
    }

    

    function sellToken(address tokenOut, address[] memory tokenIns, uint256 amountOut, address insuredDaoLp) private returns(uint256 amountOut_) {
        for(uint i = 0; i < tokenIns.length; i++) {
            if(IERC20(tokenIns[i]).balanceOf(address(this)) > 0) {
                uint256 needAmountIn = quoter.quoteExactOutputSingle(tokenIns[i], tokenOut, 3000, amountOut, 0);
                if(needAmountIn < IERC20(tokenIns[i]).balanceOf(address(this))) {
                    swapExactOutputSingle(tokenIns[i], tokenOut, amountOut, IERC20(tokenIns[i]).balanceOf(address(this)));
                    disToken(tokenIns[i], amountOut, insuredDaoLp);
                    amountOut_ += amountOut;
                    break ;
                } else {
                    uint256 sellOut = swapExactInputSingle(tokenIns[i], IERC20(tokenIns[i]).balanceOf(address(this)), tokenOut);
                    disToken(tokenIns[i], sellOut, insuredDaoLp);
                    amountOut_ += sellOut;
                    amountOut -= sellOut;
                }
            }
        }
    }

    function queryStakedBalanceBySymbol(string memory symbol) public view returns (uint256) {
        return _stakeBalances[_stakeName[symbol]][msg.sender];
    }

    function queryRedeemableBalanceBySymbol(string memory symbol) public view returns (uint256) {
        return queryRedeemableBalance(_stakeName[symbol]);
    }

    function queryRedeemableBalance(address token) private view returns (uint256) {
        if(_stakeBalances[token][msg.sender] == 0) {
            return 0;
        }
        uint256 tokenTotal;
        if(token == WETH) {
            tokenTotal = address(this).balance;
        }else {
            tokenTotal = IERC20(token).balanceOf(address(this));
        }
        return tokenTotal.mul(_stakeBalances[token][msg.sender]).div(_stakeTotal[token]);
    }


    


    function lpRedemption() public {
        //todo 保险赎回清算逻辑
        require(totalDaoTokens()==0, "totalDaoTokens must be zero");
        for(uint i = 0; i < _stakeTokens.length; i++ ) {
            uint256 redeemableBalance = queryRedeemableBalance(_stakeTokens[i]);
            if(_stakeTokens[i] == WETH) {
                payable(msg.sender).transfer(redeemableBalance);
            }else {
                IERC20(_stakeTokens[i]).safeTransfer(msg.sender, redeemableBalance);
            }
            _stakeTotal[_stakeTokens[i]] -= _stakeBalances[_stakeTokens[i]][msg.sender];
            _stakeBalances[_stakeTokens[i]][msg.sender] = 0;
        }
        
    }

    /* util function */
    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        return keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str));
    }

    
    /* util function */
    function swapExactInputSingle(address _tokenIn,uint256 _amountIn,address _tokenOut) private returns (uint256 amountOut) {
          // 将资产授权给 swapRouter
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);

        // amountOutMinimum 在生产环境下应该使用 oracle 或者其他数据来源获取其值
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(address _tokenIn, address _tokenOut, uint256 amountOut, uint256 amountInMaximum) private returns (uint256 amountIn) {
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), amountInMaximum);

            ISwapRouter.ExactOutputSingleParams memory params =
                ISwapRouter.ExactOutputSingleParams({
                    tokenIn: _tokenIn,
                    tokenOut: _tokenOut,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: amountInMaximum,
                    sqrtPriceLimitX96: 0
                });

            amountIn = swapRouter.exactOutputSingle(params);

            if (amountIn < amountInMaximum) {
                TransferHelper.safeApprove(_tokenIn, address(swapRouter), 0);
                
            }
        
    } 

}