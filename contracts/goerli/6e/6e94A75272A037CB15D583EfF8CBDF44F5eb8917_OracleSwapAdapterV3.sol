// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../swap/SwapAdapterV3.sol";

contract OracleSwapAdapterV3 is SwapAdapterV3 {
    using SafeERC20 for IERC20;

    address private immutable weth;
    address private immutable usdc;
    address private immutable wethUsdPriceOracle;

    constructor(
        address _weth,
        address _usdc,
        address _wethUsdPriceOracle,
        address _config
    ) SwapAdapterV3(address(0), _config) {
        weth = _weth;
        usdc = _usdc;
        wethUsdPriceOracle = _wethUsdPriceOracle;
    }

    function swapExactEthForTokens(
        address,
        uint,
        uint24
    ) external payable override returns (uint amountOut) {
        amountOut = _getUsdcAmountFromEth(msg.value);
        IERC20(usdc).safeTransfer(msg.sender, amountOut);
    }

    function swapExactTokensForEth(
        address,
        uint amountIn,
        uint,
        uint24
    ) external override returns (uint amountOut) {
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amountIn);
        amountOut = _getUsdcAmountFromEth(amountIn);
        payable(msg.sender).transfer(amountOut);
    }

    function swapExactTokensForTokens(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint,
        uint24
    ) external override returns (uint amountOut) {
        return _swapTokensForTokens(tokenIn, tokenOut, amountIn);
    }

    function swapExactTokensForTokensMult(
        bytes memory path,
        uint amountIn,
        uint
    ) external override returns (uint) {
        (address tokenIn, address tokenOut) = abi.decode(
            path,
            (address, address)
        );
        return _swapTokensForTokens(tokenIn, tokenOut, amountIn);
    }

    function swapExactTokensForTokensMultRawPath(
        address[] memory rawPath,
        uint amountIn,
        uint amountOutMin
    ) external override returns (uint) {
        return _swapTokensForTokens(rawPath[0], rawPath[1], amountIn);
    }

    function _swapTokensForTokens(
        address tokenIn,
        address,
        uint amountIn
    ) internal returns (uint amountOut) {
        if (tokenIn == usdc) return _swapUsdcForWeth(amountIn);
        else return _swapWethForUsdc(amountIn);
    }

    function _swapWethForUsdc(uint _amountWeth)
        internal
        returns (uint amountOut)
    {
        IERC20(weth).transferFrom(msg.sender, address(this), _amountWeth);
        amountOut = _getUsdcAmountFromEth(_amountWeth);
        IERC20(usdc).safeTransfer(msg.sender, amountOut);
    }

    function _swapUsdcForWeth(uint _amountUsdc)
        internal
        returns (uint amountOut)
    {
        IERC20(usdc).transferFrom(msg.sender, address(this), _amountUsdc);
        amountOut = _getEthAmountFromUsdc(_amountUsdc);
        IERC20(usdc).safeTransfer(msg.sender, amountOut);
    }

    function _getUsdcAmountFromEth(uint _amountEth)
        internal
        view
        returns (uint)
    {
        uint price = _getEthPriceInUsdc();
        return (_amountEth * (price / 10**2)) / 10**18;
    }

    function _getEthAmountFromUsdc(uint _amountUsdc)
        internal
        view
        returns (uint)
    {
        uint price = _getEthPriceInUsdc();
        return (_amountUsdc * 10**18) / (price / 10**2);
    }

    function _getEthPriceInUsdc() internal view returns (uint) {
        (, int price, , , ) = AggregatorV3Interface(wethUsdPriceOracle)
            .latestRoundData();
        return uint(price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./SwapAdapterBase.sol";
import "./SwapLibV3.sol";

/// @title SwapAdapterV3.
contract SwapAdapterV3 is SwapAdapterBase {
    /// @notice sorted LP tokens  hash =>
    mapping(bytes32 => uint24) private poolFees;

    constructor(address routerAddress, address config)
        SwapAdapterBase(routerAddress, config)
    {}

    /// @notice executes ETH -> ERC20 swap.
    /// @param tokenOut - address of output token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactEthForTokens(
        address tokenOut,
        uint amountOutMin,
        uint24 fee
    ) external payable virtual override returns (uint amountOut) {
        amountOut = SwapLibV3.swapExactEthForTokens(
            router,
            tokenOut,
            msg.sender,
            amountOutMin,
            fee
        );
        emit SwappedExactEthForTokens(
            msg.sender,
            msg.value,
            tokenOut,
            amountOut
        );
    }

    /// @notice executes ERC20 -> ETH swap.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output ETH.
    function swapExactTokensForEth(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        uint24 fee
    ) external virtual override returns (uint amountOut) {
        amountOut = SwapLibV3.swapExactTokensForEth(
            router,
            tokenIn,
            amountIn,
            msg.sender,
            amountOutMin,
            fee
        );
        emit SwappedExactTokensForEth(msg.sender, tokenIn, amountIn, amountOut);
    }

    /// @notice executes ERC20 -> ERC20 swap.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param tokenOut - address of input token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactTokensForTokens(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOutMin,
        uint24 fee
    ) external virtual override returns (uint amountOut) {
        amountOut = SwapLibV3.swapExactTokensForTokens(
            router,
            tokenIn,
            amountIn,
            tokenOut,
            msg.sender,
            amountOutMin,
            fee
        );
        emit SwappedExactTokensForTokens(
            msg.sender,
            tokenIn,
            amountIn,
            tokenOut,
            amountOut
        );
    }

    /// @notice executes any swap with some path
    /// @param path - encoded variant of path (for V2 - addresses, for V3 - addresses and fees)
    /// @param amountIn - amount of input token
    /// @param amountOutMin - min amount for transaction to not be reverted
    /// @return amountOut - amount of output token
    function swapExactTokensForTokensMult(
        bytes memory path,
        uint amountIn,
        uint amountOutMin
    ) external virtual override returns (uint) {
        return _swapExactTokensForTokensMult(path, amountIn, amountOutMin);
    }

    /// @inheritdoc ISwap
    function swapExactTokensForTokensMultRawPath(
        address[] memory rawPath,
        uint amountIn,
        uint amountOutMin
    ) external virtual override returns (uint) {
        bytes memory encodedPath;

        for (uint i; i < rawPath.length - 1; i++) {
            encodedPath = abi.encodePacked(
                encodedPath,
                rawPath[i],
                _poolFee(rawPath[i], rawPath[i + 1])
            );
        }

        encodedPath = abi.encodePacked(
            encodedPath,
            rawPath[rawPath.length - 1]
        );

        return
            _swapExactTokensForTokensMult(encodedPath, amountIn, amountOutMin);
    }

    /// @inheritdoc ISwap
    function setPoolFee(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external virtual override onlyGovernance {
        address lp = IUniswapV3Factory(IUniswapV3Router(router).factory())
            .getPool(tokenA, tokenB, fee);

        require(lp != address(0), "Invalid pool");

        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        poolFees[keccak256(abi.encodePacked(token0, token1))] = fee;

        emit SetFee(token0, token1, fee);
    }

    /// @inheritdoc ISwap
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view override returns (address) {
        return IUniswapV3Router(router).WETH9();
    }

    /// @inheritdoc ISwap
    function poolFee(address tokenA, address tokenB)
        external
        view
        override
        returns (uint24 fee)
    {
        return _poolFee(tokenA, tokenB);
    }

    function _swapExactTokensForTokensMult(
        bytes memory path,
        uint amountIn,
        uint amountOutMin
    ) internal returns (uint amountOut) {
        amountOut = SwapLibV3.swapExactTokensForTokensMult(
            router,
            path,
            amountIn,
            msg.sender,
            amountOutMin
        );
    }

    function _poolFee(address tokenA, address tokenB)
        internal
        view
        returns (uint24 fee)
    {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        return poolFees[keccak256(abi.encodePacked(token0, token1))];
    }

    function _sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        (token0, token1) = tokenA > tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../access/BAC.sol";
import "../interfaces/ISwap.sol";
import "../interfaces/IProtocolConfig.sol";

/// @title SwapAdapterBase.
abstract contract SwapAdapterBase is ISwap, BAC {
    /// @notice returns router address.
    address public override router;

    /// @param routerAddress swap router address
    /// @param config protocol config address
    constructor(address routerAddress, address config) {
        router = routerAddress;
        _setGlobalAccessController(IProtocolConfig(config).getGAC());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/// @title IUniswapV3Router.
interface IUniswapV3Router is ISwapRouter {
    /// @notice Returns UniswapV3Factory address
    function factory() external view returns (address);

    /// @notice Returns excess of ether on the swap contract.
    function refundETH() external payable;

    /// @notice Returns excess WETH9 on the swap contract.
    /// @param amountMinimum - minimium WETH9 to not be reverted.
    /// @param recipient - recipient's address of ETH.
    function unwrapWETH9(uint256 amountMinimum, address recipient)
        external
        payable;

    /// @notice Returns address of WETH9 token.
    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external view returns (address);
}

/// @title SwapLibV3.
library SwapLibV3 {
    using SafeERC20 for IERC20;

    /// @notice executes ETH -> ERC20 swap.
    /// @param router - address of swap router.
    /// @param tokenOut - address of output token.
    /// @param recipient - address of token's recipient.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactEthForTokens(
        address router,
        address tokenOut,
        address recipient,
        uint256 amountOutMin,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        amountOut = _swapExactEthForTokensV3(
            router,
            tokenOut,
            recipient,
            amountOutMin,
            fee
        );
    }

    /// @notice executes ERC20 -> ETH swap.
    /// @param router - address of swap router.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param recipient - address of token's recipient.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output ETH.
    function swapExactTokensForEth(
        address router,
        address tokenIn,
        uint256 amountIn,
        address recipient,
        uint256 amountOutMin,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        amountOut = _swapExactTokensForEthV3(
            router,
            tokenIn,
            amountIn,
            recipient,
            amountOutMin,
            fee
        );
    }

    /// @notice executes ERC20 -> ERC20 swap.
    /// @param router - address of swap router.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param tokenOut - address of input token.
    /// @param recipient - address of token's recipient.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactTokensForTokens(
        address router,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        address recipient,
        uint256 amountOutMin,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        amountOut = _swapExactTokensForTokensV3(
            router,
            tokenIn,
            amountIn,
            tokenOut,
            recipient,
            amountOutMin,
            fee
        );
    }

    /// @notice executes any swap with some path
    /// @param router - address of swap router
    /// @param path - encoded variant of path (for V2 - addresses, for V3 - addresses and fees)
    /// @param amountIn - amount of input token
    /// @param recipient - address of token's recipient
    /// @param amountOutMin - min amount for transaction to not be reverted
    /// @return amountOut - amount of output token
    function swapExactTokensForTokensMult(
        address router,
        bytes memory path,
        uint256 amountIn,
        address recipient,
        uint256 amountOutMin
    ) internal returns (uint256 amountOut) {
        amountOut = _swapExactTokensForTokensMultV3(
            router,
            path,
            amountIn,
            recipient,
            amountOutMin
        );
    }

    /// @notice private func for ETH -> ERC20 swap.
    /// @param router - address of swap router.
    /// @param tokenOut - address of output token.
    /// @param recipient - address of token's recipient.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function _swapExactEthForTokensV3(
        address router,
        address tokenOut,
        address recipient,
        uint256 amountOutMin,
        uint24 fee
    ) private returns (uint256 amountOut) {
        amountOut = _swapExactTokensForTokensV3(
            router,
            IUniswapV3Router(router).WETH9(),
            msg.value,
            tokenOut,
            recipient,
            amountOutMin,
            fee
        );

        IUniswapV3Router(router).refundETH();
        payable(recipient).transfer(address(this).balance);
    }

    /// @notice private func for ERC20 -> ETH swap.
    /// @param router - address of swap router.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param recipient - address of token's recipient.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output ETH.
    function _swapExactTokensForEthV3(
        address router,
        address tokenIn,
        uint256 amountIn,
        address recipient,
        uint256 amountOutMin,
        uint24 fee
    ) private returns (uint256 amountOut) {
        amountOut = _swapExactTokensForTokensV3(
            router,
            tokenIn,
            amountIn,
            IUniswapV3Router(router).WETH9(),
            router,
            amountOutMin,
            fee
        );

        IUniswapV3Router(router).unwrapWETH9(amountOut, recipient);
    }

    /// @notice private func for ERC20 -> ERC20 swap.
    /// @param router - address of swap router.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param tokenOut - address of input token.
    /// @param recipient - address of token's recipient.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function _swapExactTokensForTokensV3(
        address router,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        address recipient,
        uint256 amountOutMin,
        uint24 fee
    ) private returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid amountIn");

        if (tokenIn != IUniswapV3Router(router).WETH9() || msg.value == 0) {
            IERC20(tokenIn).approve(router, amountIn);
            IERC20(tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn
            );
        }

        amountOut = IUniswapV3Router(router).exactInputSingle{value: msg.value}(
            ISwapRouter.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                recipient,
                block.timestamp,
                amountIn,
                amountOutMin,
                0
            )
        );
    }

    /// @notice private func for swap with some path
    /// @param router - address of swap router
    /// @param path - encoded variant of path (for V2 - addresses, for V3 - addresses and fees)
    /// @param amountIn - amount of input token
    /// @param recipient - address of token's recipient
    /// @param amountOutMin - min amount for transaction to not be reverted
    /// @return amountOut - amount of output token
    function _swapExactTokensForTokensMultV3(
        address router,
        bytes memory path,
        uint256 amountIn,
        address recipient,
        uint256 amountOutMin
    ) internal returns (uint256 amountOut) {
        amountOut = IUniswapV3Router(router).exactInput{value: msg.value}(
            ISwapRouter.ExactInputParams(
                path,
                recipient,
                block.timestamp,
                amountIn,
                amountOutMin
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IGlobalAccessControl.sol";

/// @notice Bumper Access Control contract
contract BAC is AccessControl {
    bytes32 public constant LOCAL_GOVERNANCE_ROLE =
        keccak256("LOCAL_GOVERNANCE_ROLE");
    bytes32 public constant GLOBAL_GOVERNANCE_ROLE =
        keccak256("GLOBAL_GOVERNANCE_ROLE");

    IGlobalAccessControl public bac;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "!bac-admin");
        _;
    }

    modifier onlyGovernance() {
        require(
            hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender) ||
                bac.userHasRole(GLOBAL_GOVERNANCE_ROLE, msg.sender),
            "!bac-gov"
        );
        _;
    }

    modifier onlyLocalGovernance() {
        require(hasRole(LOCAL_GOVERNANCE_ROLE, msg.sender), "!bac-lgov");
        _;
    }

    modifier onlyGlobalGovernance() {
        require(
            bac.userHasRole(bac.GLOBAL_GOVERNANCE_ROLE(), msg.sender),
            "!bac-ggov"
        );
        _;
    }

    function _setGlobalAccessController(address _bac) internal {
        bac = IGlobalAccessControl(_bac);
    }

    function grantRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyAdmin
    {
        _revokeRole(role, account);
    }

    function userHasRole(bytes32 role, address account)
        public
        view
        returns (bool)
    {
        return bac.userHasRole(role, account);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title ISwap.
interface ISwap {
    /// @notice emits when ETH -> ERC20 token swap executed.
    event SwappedExactEthForTokens(
        address indexed from,
        uint ethAmountIn,
        address indexed tokenOut,
        uint amountOut
    );

    /// @notice emits when ERC20 -> ETH token swap executed.
    event SwappedExactTokensForEth(
        address indexed from,
        address indexed tokenIn,
        uint amountIn,
        uint ethAmountOut
    );

    /// @notice emits when ERC20 -> ERC20 token swap executed.
    event SwappedExactTokensForTokens(
        address indexed from,
        address indexed tokenIn,
        uint amountIn,
        address indexed tokenOut,
        uint amountOut
    );

    /// @notice should be emitted on pair fee set
    event SetFee(address indexed token0, address indexed token1, uint24 fee);

    /// @notice returns router address.
    function router() external view returns (address);

    /// @notice returns wETH token address.
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view returns (address);

    /// @notice get pool fee for V3 LP
    /// @return fee - pool fee
    function poolFee(address tokenA, address tokenB) external returns (uint24 fee);

    /// @notice set swap pool fee
    /// @dev should be implemented only for V3 adapters
    /// @param tokenA one of two pool tokens
    /// @param tokenB another pool token
    /// @param fee V3 LP fee
    function setPoolFee(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external;

    /// @notice executes ETH -> ERC20 swap.
    /// @param tokenOut - address of output token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactEthForTokens(
        address tokenOut,
        uint amountOutMin,
        uint24 fee
    ) external payable returns (uint amountOut);

    /// @notice executes ERC20 -> ETH swap.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output ETH.
    function swapExactTokensForEth(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        uint24 fee
    ) external returns (uint amountOut);

    /// @notice executes ERC20 -> ERC20 swap.
    /// @param tokenIn - address of input token.
    /// @param amountIn - amount of input token.
    /// @param tokenOut - address of input token.
    /// @param amountOutMin - min amount for transaction to not be reverted.
    /// @param fee - fee of V3 liquidity pool (for V2 - zero).
    /// @return amountOut - amount of output token.
    function swapExactTokensForTokens(
        address tokenIn,
        uint amountIn,
        address tokenOut,
        uint amountOutMin,
        uint24 fee
    ) external returns (uint amountOut);

    /// @notice executes any swap with some path
    /// @param path - encoded variant of path (for V2 - addresses, for V3 - addresses and fees)
    /// @param amountIn - amount of input token
    /// @param amountOutMin - min amount for transaction to not be reverted
    /// @return amountOut - amount of output token
    function swapExactTokensForTokensMult(
        bytes memory path,
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut);

    /// @notice executes any swap with some path
    /// @dev for v3 fees should be retrieved from adapter
    /// @param rawPath swap path
    /// @param amountIn - amount of input token
    /// @param amountOutMin - min amount for transaction to not be reverted
    /// @return amountOut - amount of output token
    function swapExactTokensForTokensMultRawPath(
        address[] memory rawPath,
        uint amountIn,
        uint amountOutMin
    ) external returns (uint amountOut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../configuration/MarketConfig.sol";

/// @notice Interface for accessing protocol configuration parameters
interface IProtocolConfig {
    /// @notice get Global access controller
    function getGAC() external view returns (address);

    /// @notice Version of the protocol
    function getVersion() external view returns (uint16);

    /// @notice Stable coin address
    function getStable() external view returns (address);

    /// @notice Configuration params of the given token market
    function getConfig(address token)
        external
        view
        returns (MarketConfig memory config);

    /// @notice Get address of NFT maker for given market
    function getNFTMaker(address token) external view returns (address);
    
    /// @notice Get address of NFT taker for given market
    function getNFTTaker(address token) external view returns (address);

    /// @notice Get address of B-token for given market
    function getBToken(address token) external view returns (address);

    /// @notice Get market contract address by token address
    function getMarket(address token) external view returns (address);

    /// @notice Get wrapped native market address
    function getWrappedNativeMarket() external view returns (address);

    /// @notice Get wrapped native token address
    function getWrappedNativeToken() external view returns (address);

    /// @notice Get BUMP token address
    function getBump() external view returns (address);

    /// @notice Get IMarketStates contract implementation address
    function getState() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @notice Interface for shared access control
interface IGlobalAccessControl {
    function GLOBAL_GOVERNANCE_ROLE() external view returns (bytes32);

    function userHasRole(bytes32 role, address account)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @notice Market configuration settings
struct MarketConfig {
    // price risk factor calculation
    int128[4] U_Lambda; // used for price risk factor calculation
    int128[4] U_Ref; // reference values
    int128 Vel_Max; // max historical velocity
    int128 Acc_Max; // max historical acceleration
    // liquidity risk factor calculation
    int128[6] W_Lambda; // used for liquidity risk factor calculation
    int128 lambdaGamma; //
    int128 lambdaDelta; //
    int128 eps; // maker debt growing speed coefficient
    // premium and yield calculation
    int128[5][5] Yield_Mul; // multiplier for conversion base yield to individual maker premium using risk and term
    // price update trigger settings:
    int128 Min_Price_Change; //  min price change (in percent)
    int128 Min_Price_Period; // min update period
    // network fee
    int128 takerFee; // fee for takers (in %)
    int128 makerFee; // fee for makers (in %)
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}