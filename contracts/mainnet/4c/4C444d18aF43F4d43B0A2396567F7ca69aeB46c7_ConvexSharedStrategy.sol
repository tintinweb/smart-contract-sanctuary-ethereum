// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 128 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }
}

// SPDX-License-Identifier: UNLICENSED
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.11;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../../../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IBaseRewardPool {
    function rewardToken() external view returns (IERC20);

    function rewards(address) external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function getReward() external;

    function extraRewardsLength() external view returns (uint256);

    function extraReward(uint256 i) external view returns (IERC20);

    function balanceOf(address account) external view returns (uint256);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);

    function withdrawAllAndUnwrap(bool claim) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 i) external view returns (PoolInfo memory);

    function withdrawAll(uint256 pid) external;

    function deposit(
        uint256 pid,
        uint256 lp,
        bool stake
    ) external;

    function withdraw(uint256 pid, uint256 lp) external;

    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function remove_liquidity_one_coin(
        uint256 lp,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 lp, int128 i) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ICurvePool.sol";

interface IStableSwap3Pool is ICurvePool {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_lp) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IV2SwapRouter.sol';
import './IV3SwapRouter.sol';

/// @title Router token swapping functionality
interface ISwapRouter02 is IV2SwapRouter, IV3SwapRouter {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";
import "./ISwapData.sol";

interface IBaseStrategy {
    function underlying() external view returns (IERC20);

    function getStrategyBalance() external view returns (uint128);

    function getStrategyUnderlyingWithRewards() external view returns(uint128);

    function process(uint256[] calldata, bool, SwapData[] calldata) external;

    function processReallocation(uint256[] calldata, ProcessReallocationData calldata) external returns(uint128);

    function processDeposit(uint256[] calldata) external;

    function fastWithdraw(uint128, uint256[] calldata, SwapData[] calldata) external returns(uint128);

    function claimRewards(SwapData[] calldata) external;

    function emergencyWithdraw(address recipient, uint256[] calldata data) external;

    function initialize() external;

    function disable() external;

    /* ========== EVENTS ========== */

    event Slippage(address strategy, IERC20 underlying, bool isDeposit, uint256 amountIn, uint256 amountOut);
}

struct ProcessReallocationData {
    uint128 sharesToWithdraw;
    uint128 optimizedShares;
    uint128 optimizedWithdrawnAmount;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IStrategyContractHelper {
    function claimRewards(address[] memory, bool executeClaim) external returns(uint256[] memory, bool);

    function deposit(uint256) external;

    function withdraw(uint256) external;

    function withdrawAll() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

/**
 * @notice Strict holding information how to swap the asset
 * @member slippage minumum output amount
 * @member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path 
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../external/@openzeppelin/utils/SafeCast.sol";


/**
 * @notice A collection of custom math ustils used throughout the system
 */
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function getProportion128(uint256 mul1, uint256 mul2, uint256 div) internal pure returns (uint128) {
        return SafeCast.toUint128(((mul1 * mul2) / div));
    }

    function getProportion128Unchecked(uint256 mul1, uint256 mul2, uint256 div) internal pure returns (uint128) {
        unchecked {
            return uint128((mul1 * mul2) / div);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/** @notice Handle setting zero value in a storage word as uint128 max value.
  *
  *  @dev
  *  The purpose of this is to avoid resetting a storage word to the zero value; 
  *  the gas cost of re-initializing the value is the same as setting the word originally.
  *  so instead, if word is to be set to zero, we set it to uint128 max.
  *
  *   - anytime a word is loaded from storage: call "get"
  *   - anytime a word is written to storage: call "set"
  *   - common operations on uints are also bundled here.
  *
  * NOTE: This library should ONLY be used when reading or writing *directly* from storage.
 */
library Max128Bit {
    uint128 internal constant ZERO = type(uint128).max;

    function get(uint128 a) internal pure returns(uint128) {
        return (a == ZERO) ? 0 : a;
    }

    function set(uint128 a) internal pure returns(uint128){
        return (a == 0) ? ZERO : a;
    }

    function add(uint128 a, uint128 b) internal pure returns(uint128 c){
        a = get(a);
        c = set(a + b);
    }
}

// SPDX-License-Identifier: BUSL-1.1

import "../interfaces/ISwapData.sol";

pragma solidity 0.8.11;

/// @notice Strategy struct for all strategies
struct Strategy {
    uint128 totalShares;

    /// @notice Denotes strategy completed index
    uint24 index;

    /// @notice Denotes whether strategy is removed
    /// @dev after removing this value can never change, hence strategy cannot be added back again
    bool isRemoved;

    /// @notice Pending geposit amount and pending shares withdrawn by all users for next index 
    Pending pendingUser;

    /// @notice Used if strategies "dohardwork" hasn't been executed yet in the current index
    Pending pendingUserNext;

    /// @dev Usually a temp variable when compounding
    mapping(address => uint256) pendingRewards;

    /// @notice Amount of lp tokens the strategy holds, NOTE: not all strategies use it
    uint256 lpTokens;

    /// @dev Usually a temp variable when compounding
    uint128 pendingDepositReward;

    // ----- REALLOCATION VARIABLES -----

    bool isInDepositPhase;

    /// @notice Used to store amount of optimized shares, so they can be substracted at the end
    /// @dev Only for temporary use, should be reset to 0 in same transaction
    uint128 optimizedSharesWithdrawn;

    /// @dev Underlying amount pending to be deposited from other strategies at reallocation 
    /// @dev Actual amount needed to be deposited and was withdrawn from others for reallocation
    /// @dev resets after the strategy reallocation DHW is finished
    uint128 pendingReallocateDeposit;

    /// @notice Stores amount of optimized underlying amount when reallocating
    /// @dev resets after the strategy reallocation DHW is finished
    /// @dev This is "virtual" amount that was matched between this strategy and others when reallocating
    uint128 pendingReallocateOptimizedDeposit;

    /// @notice Average oprimized and non-optimized deposit
    /// @dev Deposit from all strategies by taking the average of optimizedna dn non-optimized deposit
    /// @dev Used as reallocation deposit recieved
    uint128 pendingReallocateAverageDeposit;

    // ------------------------------------

    /// @notice Total underlying amoung at index
    mapping(uint256 => TotalUnderlying) totalUnderlying;

    /// @notice Batches stored after each DHW with index as a key
    /// @dev Holds information for vauls to redeem newly gained shares and withdrawn amounts belonging to users
    mapping(uint256 => Batch) batches;

    /// @notice Batches stored after each DHW reallocating (if strategy was set to reallocate)
    /// @dev Holds information for vauls to redeem newly gained shares and withdrawn shares to complete reallocation
    mapping(uint256 => BatchReallocation) reallocationBatches;

    /// @notice Vaults holding this strategy shares
    mapping(address => Vault) vaults;

    /// @notice Future proof storage
    mapping(bytes32 => AdditionalStorage) additionalStorage;

    /// @dev Make sure to reset it to 0 after emergency withdrawal
    uint256 emergencyPending;
}

/// @notice Unprocessed deposit underlying amount and strategy share amount from users
struct Pending {
    uint128 deposit;
    uint128 sharesToWithdraw;
}

/// @notice Struct storing total underlying balance of a strategy for an index, along with total shares at same index
struct TotalUnderlying {
    uint128 amount;
    uint128 totalShares;
}

/// @notice Stored after executing DHW for each index.
/// @dev This is used for vaults to redeem their deposit.
struct Batch {
    /// @notice total underlying deposited in index
    uint128 deposited;
    uint128 depositedReceived;
    uint128 depositedSharesReceived;
    uint128 withdrawnShares;
    uint128 withdrawnReceived;
}

/// @notice Stored after executing reallocation DHW each index.
struct BatchReallocation {
    /// @notice Deposited amount received from reallocation
    uint128 depositedReallocation;

    /// @notice Received shares from reallocation
    uint128 depositedReallocationSharesReceived;

    /// @notice Used to know how much tokens was received for reallocating
    uint128 withdrawnReallocationReceived;

    /// @notice Amount of shares to withdraw for reallocation
    uint128 withdrawnReallocationShares;
}

/// @notice VaultBatches could be refactored so we only have 2 structs current and next (see how Pending is working)
struct Vault {
    uint128 shares;

    /// @notice Withdrawn amount as part of the reallocation
    uint128 withdrawnReallocationShares;

    /// @notice Index to action
    mapping(uint256 => VaultBatch) vaultBatches;
}

/// @notice Stores deposited and withdrawn shares by the vault
struct VaultBatch {
    /// @notice Vault index to deposited amount mapping
    uint128 deposited;

    /// @notice Vault index to withdrawn user shares mapping
    uint128 withdrawnShares;
}

/// @notice Used for reallocation calldata
struct VaultData {
    address vault;
    uint8 strategiesCount;
    uint256 strategiesBitwise;
    uint256 newProportions;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the withdraw part of the reallocation DHW
struct ReallocationWithdrawData {
    uint256[][] reallocationTable;
    StratUnderlyingSlippage[] priceSlippages;
    RewardSlippages[] rewardSlippages;
    uint256[] stratIndexes;
    uint256[][] slippages;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the deposit part of the reallocation DHW
struct ReallocationData {
    uint256[] stratIndexes;
    uint256[][] slippages;
}

/// @notice In case some adapters need extra storage
struct AdditionalStorage {
    uint256 value;
    address addressValue;
    uint96 value96;
}

/// @notice Strategy total underlying slippage, to verify validity of the strategy state
struct StratUnderlyingSlippage {
    uint256 min;
    uint256 max;
}

/// @notice Containig information if and how to swap strategy rewards at the DHW
/// @dev Passed in by the do-hard-worker
struct RewardSlippages {
    bool doClaim;
    SwapData[] swapData;
}

/// @notice Helper struct to compare strategy share between eachother
/// @dev Used for reallocation optimization of shares (strategy matching deposits and withdrawals between eachother when reallocating)
struct PriceData {
    uint256 totalValue;
    uint256 totalShares;
}

/// @notice Strategy reallocation values after reallocation optimization of shares was calculated 
struct ReallocationShares {
    uint128[] optimizedWithdraws;
    uint128[] optimizedShares;
    uint128[] totalSharesWithdrawn;
    uint256[][] optimizedReallocationTable;
}

/// @notice Shared storage for multiple strategies
/// @dev This is used when strategies are part of the same proticil (e.g. Curve 3pool)
struct StrategiesShared {
    uint184 value;
    uint32 lastClaimBlock;
    uint32 lastUpdateBlock;
    uint8 stratsCount;
    mapping(uint256 => address) stratAddresses;
    mapping(bytes32 => uint256) bytesValues;
}

/// @notice Base storage shared betweek Spool contract and Strategies
/// @dev this way we can use same values when performing delegate call
/// to strategy implementations from the Spool contract
abstract contract BaseStorage {
    // ----- DHW VARIABLES -----

    /// @notice Force while DHW (all strategies) to be executed in only one transaction
    /// @dev This is enforced to increase the gas efficiency of the system
    /// Can be removed by the DAO if gas gost of the strategies goes over the block limit
    bool internal forceOneTxDoHardWork;

    /// @notice Global index of the system
    /// @dev Insures the correct strategy DHW execution.
    /// Every strategy in the system must be equal or one less than global index value
    /// Global index increments by 1 on every do-hard-work
    uint24 public globalIndex;

    /// @notice number of strategies unprocessed (by the do-hard-work) in the current index to be completed
    uint8 internal doHardWorksLeft;

    // ----- REALLOCATION VARIABLES -----

    /// @notice Used for offchain execution to get the new reallocation table.
    bool internal logReallocationTable;

    /// @notice number of withdrawal strategies unprocessed (by the do-hard-work) in the current index
    /// @dev only used when reallocating
    /// after it reaches 0, deposit phase of the reallocation can begin
    uint8 public withdrawalDoHardWorksLeft;

    /// @notice Index at which next reallocation is set
    uint24 public reallocationIndex;

    /// @notice 2D table hash containing information of how strategies should be reallocated between eachother
    /// @dev Created when allocation provider sets reallocation for the vaults
    /// This table is stored as a hash in the system and verified on reallocation DHW
    /// Resets to 0 after reallocation DHW is completed
    bytes32 internal reallocationTableHash;

    /// @notice Hash of all the strategies array in the system at the time when reallocation was set for index
    /// @dev this array is used for the whole reallocation period even if a strategy gets exploited when reallocating.
    /// This way we can remove the strategy from the system and not breaking the flow of the reallocaton
    /// Resets when DHW is completed
    bytes32 internal reallocationStrategiesHash;

    // -----------------------------------

    /// @notice Denoting if an address is the do-hard-worker
    mapping(address => bool) public isDoHardWorker;

    /// @notice Denoting if an address is the allocation provider
    mapping(address => bool) public isAllocationProvider;

    /// @notice Strategies shared storage
    /// @dev used as a helper storage to save common inoramation
    mapping(bytes32 => StrategiesShared) internal strategiesShared;

    /// @notice Mapping of strategy implementation address to strategy system values
    mapping(address => Strategy) public strategies;

    /// @notice Flag showing if disable was skipped when a strategy has been removed
    /// @dev If true disable can still be run 
    mapping(address => bool) internal _skippedDisable;

    /// @notice Flag showing if after removing a strategy emergency withdraw can still be executed
    /// @dev If true emergency withdraw can still be executed
    mapping(address => bool) internal _awaitingEmergencyWithdraw;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

/// @title Common Spool contracts constants
abstract contract BaseConstants {
    /// @dev 2 digits precision
    uint256 internal constant FULL_PERCENT = 100_00;

    /// @dev Accuracy when doing shares arithmetics
    uint256 internal constant ACCURACY = 10**30;
}

/// @title Contains USDC token related values
abstract contract USDC {
    /// @notice USDC token contract address
    IERC20 internal constant USDC_ADDRESS = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/GNSPS-solidity-bytes-utils/BytesLib.sol";
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../external/uniswap/interfaces/ISwapRouter02.sol";
import "../interfaces/ISwapData.sol";

/// @notice Denotes swap action mode
enum SwapAction {
    NONE,
    UNI_V2_DIRECT,
    UNI_V2_WETH,
    UNI_V2,
    UNI_V3_DIRECT,
    UNI_V3_WETH,
    UNI_V3
}

/// @title Contains logic facilitating swapping using Uniswap
abstract contract SwapHelper {
    using BytesLib for bytes;
    using SafeERC20 for IERC20;

    /// @dev The length of the bytes encoded swap action
    uint256 private constant ACTION_SIZE = 1;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;

    /// @dev Maximum V2 path length (4 swaps)
    uint256 private constant MAX_V2_PATH = ADDR_SIZE * 3;

    /// @dev V3 WETH path length
    uint256 private constant WETH_V3_PATH_SIZE = FEE_SIZE + FEE_SIZE;

    /// @dev Minimum V3 custom path length (2 swaps)
    uint256 private constant MIN_V3_PATH = FEE_SIZE + NEXT_OFFSET;

    /// @dev Maximum V3 path length (4 swaps)
    uint256 private constant MAX_V3_PATH = FEE_SIZE + NEXT_OFFSET * 3;

    /// @notice Uniswap router supporting Uniswap V2 and V3
    ISwapRouter02 internal immutable uniswapRouter;

    /// @notice Address of WETH token
    address private immutable WETH;

    /**
     * @notice Sets initial values
     * @param _uniswapRouter Uniswap router address
     * @param _WETH WETH token address
     */
    constructor(ISwapRouter02 _uniswapRouter, address _WETH) {
        uniswapRouter = _uniswapRouter;
        WETH = _WETH;
    }

    /**
     * @notice Approve reward token and swap the `amount` to a strategy underlying asset
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param swapData Swap details showing the path of the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _approveAndSwap(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        SwapData calldata swapData
    ) internal virtual returns (uint256) {

        // if there is nothing to swap, return
        if(amount == 0)
            return 0;

        // if amount is not uint256 max approve unswap router to spend tokens
        // otherwise rewards were already sent to the router
        if(amount < type(uint256).max) {
            from.safeApprove(address(uniswapRouter), amount);
        } else {
            amount = 0;
        }

        // get swap action from first byte
        SwapAction action = SwapAction(swapData.path.toUint8(0));
        uint256 result;

        if (action == SwapAction.UNI_V2_DIRECT) { // V2 Direct
            address[] memory path = new address[](2);
            result = _swapV2(from, to, amount, swapData.slippage, path);
        } else if (action == SwapAction.UNI_V2_WETH) { // V2 WETH
            address[] memory path = new address[](3);
            path[1] = WETH;
            result = _swapV2(from, to, amount, swapData.slippage, path);
        } else if (action == SwapAction.UNI_V2) { // V2 Custom
            address[] memory path = _getV2Path(swapData.path);
            result = _swapV2(from, to, amount, swapData.slippage, path);
        } else if (action == SwapAction.UNI_V3_DIRECT) { // V3 Direct
            result = _swapDirectV3(from, to, amount, swapData.slippage, swapData.path);
        } else if (action == SwapAction.UNI_V3_WETH) { // V3 WETH
            bytes memory wethPath = _getV3WethPath(swapData.path);
            result = _swapV3(from, to, amount, swapData.slippage, wethPath);
        } else if (action == SwapAction.UNI_V3) { // V3 Custom
            require(swapData.path.length > MIN_V3_PATH, "SwapHelper::_approveAndSwap: Path too short");
            uint256 actualpathSize = swapData.path.length - ACTION_SIZE;
            require((actualpathSize - FEE_SIZE) % NEXT_OFFSET == 0 &&
                actualpathSize <= MAX_V3_PATH,
                "SwapHelper::_approveAndSwap: Bad V3 path");

            result = _swapV3(from, to, amount, swapData.slippage, swapData.path[ACTION_SIZE:]);
        } else {
            revert("SwapHelper::_approveAndSwap: No action");
        }

        if (from.allowance(address(this), address(uniswapRouter)) > 0) {
            from.safeApprove(address(uniswapRouter), 0);
        }
        return result;
    }

    /**
     * @notice Swaps tokens using Uniswap V2
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param slippage Allowed slippage
     * @param path Steps to complete the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _swapV2(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        uint256 slippage,
        address[] memory path
    ) internal virtual returns (uint256) {
        path[0] = address(from);
        path[path.length - 1] = address(to);

        return uniswapRouter.swapExactTokensForTokens(
            amount,
            slippage,
            path,
            address(this)
        );
    }

    /**
     * @notice Swaps tokens using Uniswap V3
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param slippage Allowed slippage
     * @param path Steps to complete the swap
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _swapV3(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        uint256 slippage,
        bytes memory path
    ) internal virtual returns (uint256) {
        IV3SwapRouter.ExactInputParams memory params =
            IV3SwapRouter.ExactInputParams({
                path: abi.encodePacked(address(from), path, address(to)),
                recipient: address(this),
                amountIn: amount,
                amountOutMinimum: slippage
            });

        // Executes the swap.
        uint received = uniswapRouter.exactInput(params);

        return received;
    }

    /**
     * @notice Does a direct swap from `from` address to the `to` address using Uniswap V3
     * @param from Token to swap from
     * @param to Token to swap to
     * @param amount Amount of tokens to swap
     * @param slippage Allowed slippage
     * @param fee V3 direct fee configuration
     * @return result Amount of underlying (`to`) tokens recieved
     */
    function _swapDirectV3(
        IERC20 from,
        IERC20 to,
        uint256 amount,
        uint256 slippage,
        bytes memory fee
    ) internal virtual returns (uint256) {
        require(fee.length == FEE_SIZE + ACTION_SIZE, "SwapHelper::_swapDirectV3: Bad V3 direct fee");

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams(
            address(from),
            address(to),
            // ignore first byte
            fee.toUint24(ACTION_SIZE),
            address(this),
            amount,
            slippage,
            0
        );

        return uniswapRouter.exactInputSingle(params);
    }

    /**
     * @notice Converts passed bytes to V2 path
     * @param pathBytes Swap path in bytes, converted to addresses
     * @return path list of addresses in the swap path (skipping first and last element)
     */
    function _getV2Path(bytes calldata pathBytes) internal pure returns(address[] memory) {
        require(pathBytes.length > ACTION_SIZE, "SwapHelper::_getV2Path: No path provided");
        uint256 actualpathSize = pathBytes.length - ACTION_SIZE;
        require(actualpathSize % ADDR_SIZE == 0 && actualpathSize <= MAX_V2_PATH, "SwapHelper::_getV2Path: Bad V2 path");

        uint256 pathLength = actualpathSize / ADDR_SIZE;
        address[] memory path = new address[](pathLength + 2);

        // ignore first byte
        path[1] = pathBytes.toAddress(ACTION_SIZE);
        for (uint256 i = 1; i < pathLength; i++) {
            path[i + 1] = pathBytes.toAddress(i * ADDR_SIZE + ACTION_SIZE);
        }

        return path;
    }

    /**
     * @notice Get Unswap V3 path to swap tokens via WETH LP pool
     * @param pathBytes Swap path in bytes
     * @return wethPath Unswap V3 path routing via WETH pool
     */
    function _getV3WethPath(bytes calldata pathBytes) internal view returns(bytes memory) {
        require(pathBytes.length == WETH_V3_PATH_SIZE + ACTION_SIZE, "SwapHelper::_getV3WethPath: Bad V3 WETH path");
        // ignore first byte as it's used for swap action
        return abi.encodePacked(pathBytes[ACTION_SIZE:4], WETH, pathBytes[4:]);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./SwapHelper.sol";

/// @title Swap helper implementation with SwapRouter02 on Mainnet
contract SwapHelperMainnet is SwapHelper {
    constructor()
        SwapHelper(ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
    {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/IBaseStrategy.sol";
import "../shared/BaseStorage.sol";
import "../shared/Constants.sol";

import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../libraries/Math.sol";
import "../libraries/Max/128Bit.sol";

/**
 * @notice Implementation of the {IBaseStrategy} interface.
 *
 * @dev
 * This implementation of the {IBaseStrategy} is meant to operate
 * on single-collateral strategies and uses a delta system to calculate
 * whether a withdrawal or deposit needs to be performed for a particular
 * strategy.
 */
abstract contract BaseStrategy is IBaseStrategy, BaseStorage, BaseConstants {
    using SafeERC20 for IERC20;
    using Max128Bit for uint128;

    /* ========== CONSTANTS ========== */

    /// @notice Value to multiply new deposit recieved to get the share amount
    uint128 private constant SHARES_MULTIPLIER = 10**6;
    
    /// @notice number of locked shares when initial shares are added
    /// @dev This is done to prevent rounding errors and share manipulation
    uint128 private constant INITIAL_SHARES_LOCKED = 10**11;

    /// @notice minimum shares size to avoid loss of share due to computation precision
    /// @dev If total shares go unders this value, new deposit is multiplied by the `SHARES_MULTIPLIER` again
    uint256 private constant MIN_SHARES_FOR_ACCURACY = INITIAL_SHARES_LOCKED * 10;

    /* ========== STATE VARIABLES ========== */

    /// @notice The total slippage slots the strategy supports, used for validation of provided slippage
    uint256 internal immutable rewardSlippageSlots;

    /// @notice Slots for processing
    uint256 internal immutable processSlippageSlots;

    /// @notice Slots for reallocation
    uint256 internal immutable reallocationSlippageSlots;

    /// @notice Slots for deposit
    uint256 internal immutable depositSlippageSlots;

    /** 
     * @notice do force claim of rewards.
     *
     * @dev
     * Some strategies auto claim on deposit/withdraw,
     * so execute the claim actions to store the reward amounts.
     */
    bool internal immutable forceClaim;

    /// @notice flag to force balance validation before running process strategy
    /// @dev this is done so noone can manipulate the strategies before we interact with them and cause harm to the system
    bool internal immutable doValidateBalance;

    /// @notice The self address, set at initialization to allow proper share accounting
    address internal immutable self;

    /// @notice The underlying asset of the strategy
    IERC20 public immutable override underlying;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Initializes the base strategy values.
     *
     * @dev
     * It performs certain pre-conditional validations to ensure the contract
     * has been initialized properly, such as that the address argument of the
     * underlying asset is valid.
     *
     * Slippage slots for certain strategies may be zero if there is no compounding
     * work to be done.
     * 
     * @param _underlying token used for deposits
     * @param _rewardSlippageSlots slots for rewards
     * @param _processSlippageSlots slots for processing
     * @param _reallocationSlippageSlots slots for reallocation
     * @param _depositSlippageSlots slots for deposits
     * @param _forceClaim force claim of rewards
     * @param _doValidateBalance force balance validation
     */
    constructor(
        IERC20  _underlying,
        uint256 _rewardSlippageSlots,
        uint256 _processSlippageSlots,
        uint256 _reallocationSlippageSlots,
        uint256 _depositSlippageSlots,
        bool _forceClaim,
        bool _doValidateBalance,
        address _self
    ) {
        require(
            _underlying != IERC20(address(0)),
            "BaseStrategy::constructor: Underlying address cannot be 0"
        );

        self = _self == address(0) ? address(this) : _self;

        underlying = _underlying;
        rewardSlippageSlots = _rewardSlippageSlots;
        processSlippageSlots = _processSlippageSlots;
        reallocationSlippageSlots = _reallocationSlippageSlots;
        depositSlippageSlots = _depositSlippageSlots;
        forceClaim = _forceClaim;
        doValidateBalance = _doValidateBalance;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Process the latest pending action of the strategy
     *
     * @dev
     * it yields amount of funds processed as well as the reward buffer of the strategy.
     * The function will auto-compound rewards if requested and supported.
     *
     * Requirements:
     *
     * - the slippages provided must be valid in length
     * - if the redeposit flag is set to true, the strategy must support
     *   compounding of rewards
     *
     * @param slippages slippages to process
     * @param redeposit if redepositing is to occur
     * @param swapData swap data for processing
     */
    function process(uint256[] calldata slippages, bool redeposit, SwapData[] calldata swapData) external override
    {
        slippages = _validateStrategyBalance(slippages);

        if (forceClaim || redeposit) {
            _validateRewardsSlippage(swapData);
            _processRewards(swapData);
        }

        if (processSlippageSlots != 0)
            _validateProcessSlippage(slippages);
        
        _process(slippages, 0);
    }

    /**
     * @notice Process first part of the reallocation DHW
     * @dev Withdraws for reallocation, depositn and withdraww for a user
     *
     * @param slippages Parameters to apply when performing a deposit or a withdraw
     * @param processReallocationData Data containing amuont of optimized and not optimized shares to withdraw
     * @return withdrawnReallocationReceived actual amount recieveed from peforming withdraw
     */
    function processReallocation(uint256[] calldata slippages, ProcessReallocationData calldata processReallocationData) external override returns(uint128) {
        slippages = _validateStrategyBalance(slippages);

        if (reallocationSlippageSlots != 0)
            _validateReallocationSlippage(slippages);

        _process(slippages, processReallocationData.sharesToWithdraw);

        uint128 withdrawnReallocationReceived = _updateReallocationWithdraw(processReallocationData);

        return withdrawnReallocationReceived;
    }

    /**
     * @dev Update reallocation batch storage for index after withdrawing reallocated shares
     * @param processReallocationData Data containing amount of optimized and not optimized shares to withdraw
     * @return Withdrawn reallocation received
     */
    function _updateReallocationWithdraw(ProcessReallocationData calldata processReallocationData) internal virtual returns(uint128) {
        Strategy storage strategy = strategies[self];
        uint24 stratIndex = _getProcessingIndex();
        BatchReallocation storage batch = strategy.reallocationBatches[stratIndex];

        // save actual withdrawn amount, without optimized one 
        uint128 withdrawnReallocationReceived = batch.withdrawnReallocationReceived;

        strategy.optimizedSharesWithdrawn += processReallocationData.optimizedShares;
        batch.withdrawnReallocationReceived += processReallocationData.optimizedWithdrawnAmount;
        batch.withdrawnReallocationShares = processReallocationData.optimizedShares + processReallocationData.sharesToWithdraw;

        return withdrawnReallocationReceived;
    }

    /**
     * @notice Process deposit
     * @param slippages Array of slippage parameters to apply when depositing
     */
    function processDeposit(uint256[] calldata slippages)
        external
        override
    {
        slippages = _validateStrategyBalance(slippages);

        if (depositSlippageSlots != 0)
            _validateDepositSlippage(slippages);
        _processDeposit(slippages);
    }

    /**
     * @notice Returns total starategy balance includign pending rewards
     * @return strategyBalance total starategy balance includign pending rewards
     */
    function getStrategyUnderlyingWithRewards() public view override returns(uint128)
    {
        return _getStrategyUnderlyingWithRewards();
    }

    /**
     * @notice Fast withdraw
     * @param shares Shares to fast withdraw
     * @param slippages Array of slippage parameters to apply when withdrawing
     * @param swapData Swap slippage and path array
     * @return Withdrawn amount withdawn
     */
    function fastWithdraw(uint128 shares, uint256[] calldata slippages, SwapData[] calldata swapData) external override returns(uint128)
    {
        slippages = _validateStrategyBalance(slippages);

        _validateRewardsSlippage(swapData);

        if (processSlippageSlots != 0)
            _validateProcessSlippage(slippages);

        uint128 withdrawnAmount = _processFastWithdraw(shares, slippages, swapData);
        strategies[self].totalShares -= shares;
        return withdrawnAmount;
    }

    /**
     * @notice Claims and possibly compounds strategy rewards.
     *
     * @param swapData swap data for processing
     */
    function claimRewards(SwapData[] calldata swapData) external override
    {
        _validateRewardsSlippage(swapData);
        _processRewards(swapData);
    }

    /**
     * @notice Withdraws all actively deployed funds in the strategy, liquifying them in the process.
     *
     * @param recipient recipient of the withdrawn funds
     * @param data data necessary execute the emergency withdraw
     */
    function emergencyWithdraw(address recipient, uint256[] calldata data) external virtual override {
        uint256 balanceBefore = underlying.balanceOf(address(this));
        _emergencyWithdraw(recipient, data);
        uint256 balanceAfter = underlying.balanceOf(address(this));

        uint256 withdrawnAmount = 0;
        if (balanceAfter > balanceBefore) {
            withdrawnAmount = balanceAfter - balanceBefore;
        }
        
        Strategy storage strategy = strategies[self];
        if (strategy.emergencyPending > 0) {
            withdrawnAmount += strategy.emergencyPending;
            strategy.emergencyPending = 0;
        }

        // also withdraw all unprocessed deposit for a strategy
        if (strategy.pendingUser.deposit.get() > 0) {
            withdrawnAmount += strategy.pendingUser.deposit.get();
            strategy.pendingUser.deposit = 0;
        }

        if (strategy.pendingUserNext.deposit.get() > 0) {
            withdrawnAmount += strategy.pendingUserNext.deposit.get();
            strategy.pendingUserNext.deposit = 0;
        }

        // if strategy was already processed in the current index that hasn't finished yet,
        // transfer the withdrawn amount
        // reset total underlying to 0
        if (strategy.index == globalIndex && doHardWorksLeft > 0) {
            uint256 withdrawnReceived = strategy.batches[strategy.index].withdrawnReceived;
            withdrawnAmount += withdrawnReceived;
            strategy.batches[strategy.index].withdrawnReceived = 0;

            strategy.totalUnderlying[strategy.index].amount = 0;
        }

        if (withdrawnAmount > 0) {
            // check if the balance is high enough to withdraw the total withdrawnAmount
            if (balanceAfter < withdrawnAmount) {
                // if not withdraw the current balance
                withdrawnAmount = balanceAfter;
            }

            underlying.safeTransfer(recipient, withdrawnAmount);
        }
    }

    /**
     * @notice Initialize a strategy.
     * @dev Execute strategy specific one-time actions if needed.
     */
    function initialize() external virtual override {}

    /**
     * @notice Disables a strategy.
     * @dev Cleans strategy specific values if needed.
     */
    function disable() external virtual override {}

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Validate strategy balance
     * @param slippages Check if the strategy balance is within defined min and max values
     * @return slippages Same array without first 2 slippages
     */
    function _validateStrategyBalance(uint256[] calldata slippages) internal virtual returns(uint256[] calldata) {
        if (doValidateBalance) {
            require(slippages.length >= 2, "BaseStrategy:: _validateStrategyBalance: Invalid number of slippages");
            uint128 strategyBalance =  getStrategyBalance();

            require(
                slippages[0] <= strategyBalance &&
                slippages[1] >= strategyBalance,
                "BaseStrategy::_validateStrategyBalance: Bad strategy balance"
            );

            return slippages[2:];
        }

        return slippages;
    }

    /**
     * @dev Validate reards slippage
     * @param swapData Swap slippage and path array
     */
    function _validateRewardsSlippage(SwapData[] calldata swapData) internal view virtual {
        if (swapData.length > 0) {
            require(
                swapData.length == _getRewardSlippageSlots(),
                "BaseStrategy::_validateSlippage: Invalid Number of reward slippages Defined"
            );
        }
    }

    /**
     * @dev Retrieve reward slippage slots
     * @return Reward slippage slots
     */
    function _getRewardSlippageSlots() internal view virtual returns(uint256) {
        return rewardSlippageSlots;
    }

    /**
     * @dev Validate process slippage
     * @param slippages parameters to verify validity of the strategy state
     */
    function _validateProcessSlippage(uint256[] calldata slippages) internal view virtual {
        _validateSlippage(slippages.length, processSlippageSlots);
    }

    /**
     * @dev Validate reallocation slippage
     * @param slippages parameters to verify validity of the strategy state
     */
    function _validateReallocationSlippage(uint256[] calldata slippages) internal view virtual {
        _validateSlippage(slippages.length, reallocationSlippageSlots);
    }

    /**
     * @dev Validate deposit slippage
     * @param slippages parameters to verify validity of the strategy state
     */
    function _validateDepositSlippage(uint256[] calldata slippages) internal view virtual {
        _validateSlippage(slippages.length, depositSlippageSlots);
    }

    /**
     * @dev Validates the provided slippage in length.
     * @param currentLength actual slippage array length
     * @param shouldBeLength expected slippages array length
     */
    function _validateSlippage(uint256 currentLength, uint256 shouldBeLength)
        internal
        view
        virtual
    {
        require(
            currentLength == shouldBeLength,
            "BaseStrategy::_validateSlippage: Invalid Number of Slippages Defined"
        );
    }

    /**
     * @dev Retrieve processing index
     * @return Processing index
     */
    function _getProcessingIndex() internal view returns(uint24) {
        return strategies[self].index + 1;
    }

    /**
     * @dev Calculates shares before they are added to the total shares
     * @param strategyTotalShares Total shares for strategy
     * @param stratTotalUnderlying Total underlying for strategy
     * @param depositAmount Deposit amount recieved
     * @return newShares New shares calculated
     */
    function _getNewSharesAfterWithdraw(uint128 strategyTotalShares, uint128 stratTotalUnderlying, uint128 depositAmount) internal pure returns(uint128, uint128){
        uint128 oldUnderlying;
        if (stratTotalUnderlying > depositAmount) {
            unchecked {
                oldUnderlying = stratTotalUnderlying - depositAmount;
            }
        }

        return _getNewShares(strategyTotalShares, oldUnderlying, depositAmount);
    }

    /**
     * @dev Calculates shares when they are already part of the total shares
     *
     * @param strategyTotalShares Total shares
     * @param stratTotalUnderlying Total underlying
     * @param depositAmount Deposit amount recieved
     * @return newShares New shares calculated
     */
    function _getNewShares(uint128 strategyTotalShares, uint128 stratTotalUnderlying, uint128 depositAmount) internal pure returns(uint128 newShares, uint128){
        if (strategyTotalShares <= MIN_SHARES_FOR_ACCURACY || stratTotalUnderlying == 0) {
            (newShares, strategyTotalShares) = _setNewShares(strategyTotalShares, depositAmount);
        } else {
            newShares = Math.getProportion128(depositAmount, strategyTotalShares, stratTotalUnderlying);
        }

        strategyTotalShares += newShares;

        return (newShares, strategyTotalShares);
    }

    /**
     * @notice Sets new shares if strategy does not have enough locked shares and calculated new shares based on deposit recieved
     * @dev
     * This is used when a strategy is new and does not have enough shares locked.
     * Shares are locked to prevent rounding errors and to keep share to underlying amount
     * ratio correct, to ensure the normal working of the share system._awaitingEmergencyWithdraw
     * We always want to have more shares than the underlying value of the strategy.
     *
     * @param strategyTotalShares Total shares
     * @param depositAmount Deposit amount recieved
     * @return newShares New shares calculated
     */
    function _setNewShares(uint128 strategyTotalShares, uint128 depositAmount) private pure returns(uint128, uint128) {
        // Enforce minimum shares size to avoid loss of share due to computation precision
        uint128 newShares = depositAmount * SHARES_MULTIPLIER;

        if (strategyTotalShares < INITIAL_SHARES_LOCKED) {
            if (newShares + strategyTotalShares >= INITIAL_SHARES_LOCKED) {
                unchecked {
                    uint128 newLockedShares = INITIAL_SHARES_LOCKED - strategyTotalShares;
                    strategyTotalShares += newLockedShares;
                    newShares -= newLockedShares;
                }
            } else {
                newShares = 0;
            }
        }

        return (newShares, strategyTotalShares);
    }

    /**
     * @dev Reset allowance to zero if previously set to a higher value.
     * @param token Asset
     * @param spender Spender address
     */
    function _resetAllowance(IERC20 token, address spender) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
    }

    /* ========== VIRTUAL FUNCTIONS ========== */

    function getStrategyBalance()
        public
        view
        virtual
        override
        returns (uint128);

    function _processRewards(SwapData[] calldata) internal virtual;
    function _emergencyWithdraw(address recipient, uint256[] calldata data) internal virtual;
    function _process(uint256[] memory, uint128 reallocateSharesToWithdraw) internal virtual;
    function _processDeposit(uint256[] memory) internal virtual;
    function _getStrategyUnderlyingWithRewards() internal view virtual returns(uint128);
    function _processFastWithdraw(uint128, uint256[] memory, SwapData[] calldata) internal virtual returns(uint128);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./RewardStrategy.sol";
import "../shared/SwapHelperMainnet.sol";

/**
 * @notice Multiple reward strategy logic
 */
abstract contract MultipleRewardStrategy is RewardStrategy, SwapHelperMainnet {
    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Claim rewards
     * @param swapData Slippage and path array
     * @return Rewards
     */
    function _claimRewards(SwapData[] calldata swapData) internal virtual override returns(Reward[] memory) {
        return _claimMultipleRewards(type(uint128).max, swapData);
    }

    /**
     * @dev Claim fast withdraw rewards
     * @param shares Amount of shares
     * @param swapData Swap slippage and path
     * @return Rewards
     */
    function _claimFastWithdrawRewards(uint128 shares, SwapData[] calldata swapData) internal virtual override returns(Reward[] memory) {
        return _claimMultipleRewards(shares, swapData);
    }

    /* ========== VIRTUAL FUNCTIONS ========== */

    function _claimMultipleRewards(uint128 shares, SwapData[] calldata swapData) internal virtual returns(Reward[] memory rewards);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./BaseStrategy.sol";

import "../libraries/Max/128Bit.sol";
import "../libraries/Math.sol";

struct ProcessInfo {
    uint128 totalWithdrawReceived;
    uint128 userDepositReceived;
}

/**
 * @notice Process strategy logic
 */
abstract contract ProcessStrategy is BaseStrategy {
    using Max128Bit for uint128;

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Process the strategy pending deposits, withdrawals, and collected strategy rewards
     * @dev
     * Deposit amount amd withdrawal shares are matched between eachother, effecively only one of
     * those 2 is called. Shares are converted to the dollar value, based on the current strategy
     * total balance. This ensures the minimum amount of assets are moved around to lower the price
     * drift and total fees paid to the protocols the strategy is interacting with (if there are any)
     *
     * @param slippages Strategy slippage values verifying the validity of the strategy state
     * @param reallocateSharesToWithdraw Reallocation shares to withdraw (non-zero only if reallocation DHW is in progress, otherwise 0)
     */
    function _process(uint256[] memory slippages, uint128 reallocateSharesToWithdraw) internal override virtual {
        // PREPARE
        Strategy storage strategy = strategies[self];
        uint24 processingIndex = _getProcessingIndex();
        Batch storage batch = strategy.batches[processingIndex];
        uint128 strategyTotalShares = strategy.totalShares;
        uint128 pendingSharesToWithdraw = strategy.pendingUser.sharesToWithdraw.get();
        uint128 userDeposit = strategy.pendingUser.deposit.get();

        // CALCULATE THE ACTION

        // if withdrawing for reallocating, add shares to total withdraw shares
        if (reallocateSharesToWithdraw > 0) {
            pendingSharesToWithdraw += reallocateSharesToWithdraw;
        }

        // total deposit received from users + compound reward (if there are any)
        uint128 totalPendingDeposit = userDeposit;
        
        // add compound reward (pendingDepositReward) to deposit
        uint128 withdrawalReward = 0;
        if (strategy.pendingDepositReward > 0) {
            uint128 pendingDepositReward = strategy.pendingDepositReward;

            totalPendingDeposit += pendingDepositReward;

            // calculate compound reward (withdrawalReward) for users withdrawing in this batch
            if (pendingSharesToWithdraw > 0 && strategyTotalShares > 0) {
                withdrawalReward = Math.getProportion128(pendingSharesToWithdraw, pendingDepositReward, strategyTotalShares);

                // substract withdrawal reward from total deposit
                totalPendingDeposit -= withdrawalReward;
            }

            // Reset pendingDepositReward
            strategy.pendingDepositReward = 0;
        }

        // if there is no pending deposit or withdrawals, return
        if (totalPendingDeposit == 0 && pendingSharesToWithdraw == 0) {
            return;
        }

        uint128 pendingWithdrawalAmount = 0;
        if (pendingSharesToWithdraw > 0) {
            pendingWithdrawalAmount = 
                Math.getProportion128(getStrategyBalance(), pendingSharesToWithdraw, strategyTotalShares);
        }

        // ACTION: DEPOSIT OR WITHDRAW
        ProcessInfo memory processInfo;
        if (totalPendingDeposit > pendingWithdrawalAmount) { // DEPOSIT
            // uint128 amount = totalPendingDeposit - pendingWithdrawalAmount;
            uint128 depositReceived = _deposit(totalPendingDeposit - pendingWithdrawalAmount, slippages);

            processInfo.totalWithdrawReceived = pendingWithdrawalAmount + withdrawalReward;

            // pendingWithdrawalAmount is optimized deposit: totalPendingDeposit - amount;
            uint128 totalDepositReceived = depositReceived + pendingWithdrawalAmount;
            
            // calculate user deposit received, excluding compound rewards
            processInfo.userDepositReceived =  Math.getProportion128(totalDepositReceived, userDeposit, totalPendingDeposit);
        } else if (totalPendingDeposit < pendingWithdrawalAmount) { // WITHDRAW
            // uint128 amount = pendingWithdrawalAmount - totalPendingDeposit;

            uint128 withdrawReceived = _withdraw(
                // calculate back the shares from actual withdraw amount
                // NOTE: we can do unchecked calculation and casting as
                //       the multiplier is always smaller than the divisor
                Math.getProportion128Unchecked(
                    (pendingWithdrawalAmount - totalPendingDeposit),
                    pendingSharesToWithdraw,
                    pendingWithdrawalAmount
                ),
                slippages
            );

            // optimized withdraw is total pending deposit: pendingWithdrawalAmount - amount = totalPendingDeposit;
            processInfo.totalWithdrawReceived = withdrawReceived + totalPendingDeposit + withdrawalReward;
            processInfo.userDepositReceived = userDeposit;
        } else {
            processInfo.totalWithdrawReceived = pendingWithdrawalAmount + withdrawalReward;
            processInfo.userDepositReceived = userDeposit;
        }
        
        // UPDATE STORAGE AFTER
        {
            uint128 stratTotalUnderlying = getStrategyBalance();

            // Update withdraw batch
            if (pendingSharesToWithdraw > 0) {
                batch.withdrawnReceived = processInfo.totalWithdrawReceived;
                batch.withdrawnShares = pendingSharesToWithdraw;
                
                strategyTotalShares -= pendingSharesToWithdraw;

                // update reallocation batch
                if (reallocateSharesToWithdraw > 0) {
                    BatchReallocation storage reallocationBatch = strategy.reallocationBatches[processingIndex];

                    uint128 withdrawnReallocationReceived =
                        Math.getProportion128(processInfo.totalWithdrawReceived, reallocateSharesToWithdraw, pendingSharesToWithdraw);
                    reallocationBatch.withdrawnReallocationReceived = withdrawnReallocationReceived;

                    // substract reallocation values from user values
                    batch.withdrawnReceived -= withdrawnReallocationReceived;
                    batch.withdrawnShares -= reallocateSharesToWithdraw;
                }
            }

            // Update deposit batch
            if (userDeposit > 0) {
                uint128 newShares;
                (newShares, strategyTotalShares) = _getNewSharesAfterWithdraw(strategyTotalShares, stratTotalUnderlying, processInfo.userDepositReceived);

                batch.deposited = userDeposit;
                batch.depositedReceived = processInfo.userDepositReceived;
                batch.depositedSharesReceived = newShares;
            }

            // Update shares
            if (strategyTotalShares != strategy.totalShares) {
                strategy.totalShares = strategyTotalShares;
            }

            // Set underlying at index
            strategy.totalUnderlying[processingIndex].amount = stratTotalUnderlying;
            strategy.totalUnderlying[processingIndex].totalShares = strategyTotalShares;
        }
    }

    /**
     * @notice Process deposit
     * @param slippages Slippages array
     */
    function _processDeposit(uint256[] memory slippages) internal override virtual {
        Strategy storage strategy = strategies[self];
        
        uint128 depositOptimizedAmount = strategy.pendingReallocateOptimizedDeposit;
        uint128 depositAverageAmount = strategy.pendingReallocateAverageDeposit;
        uint128 optimizedSharesWithdrawn = strategy.optimizedSharesWithdrawn;
        uint128 depositAmount = strategy.pendingReallocateDeposit;

        // if a strategy is not part of reallocation return
        if (
            depositOptimizedAmount == 0 &&
            optimizedSharesWithdrawn == 0 &&
            depositAverageAmount == 0 &&
            depositAmount == 0
        ) {
            return;
        }

        uint24 processingIndex = _getProcessingIndex();
        BatchReallocation storage reallocationBatch = strategy.reallocationBatches[processingIndex];
        
        uint128 strategyTotalShares = strategy.totalShares;
        
        // add shares from optimized deposit
        if (depositOptimizedAmount > 0) {
            uint128 stratTotalUnderlying = getStrategyBalance();
            uint128 newShares;
            (newShares, strategyTotalShares) = _getNewShares(strategyTotalShares, stratTotalUnderlying, depositOptimizedAmount);

            // update reallocation batch deposit shares
            reallocationBatch.depositedReallocationSharesReceived = newShares;

            strategy.totalUnderlying[processingIndex].amount = stratTotalUnderlying;

            // reset
            strategy.pendingReallocateOptimizedDeposit = 0;
        }

        if (depositAverageAmount > 0) {
            reallocationBatch.depositedReallocation += depositAverageAmount;
            strategy.pendingReallocateAverageDeposit = 0;
        }

        // remove optimized withdraw shares
        if (optimizedSharesWithdrawn > 0) {
            strategyTotalShares -= optimizedSharesWithdrawn;

            // reset
            strategy.optimizedSharesWithdrawn = 0;
        }

        // add shares from actual deposit
        if (depositAmount > 0) {
            // deposit
            uint128 depositReceived = _deposit(depositAmount, slippages);

            // NOTE: might return it from _deposit (only certain strategies need it)
            uint128 stratTotalUnderlying = getStrategyBalance();

            if (depositReceived > 0) {
                uint128 newShares;
                (newShares, strategyTotalShares) = _getNewSharesAfterWithdraw(strategyTotalShares, stratTotalUnderlying, depositReceived);

                // update reallocation batch deposit shares
                reallocationBatch.depositedReallocationSharesReceived += newShares;
            }

            strategy.totalUnderlying[processingIndex].amount = stratTotalUnderlying;

            // reset
            strategy.pendingReallocateDeposit = 0;
        }

        // update share storage
        strategy.totalUnderlying[processingIndex].totalShares = strategyTotalShares;
        strategy.totalShares = strategyTotalShares;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice get the value of the strategy shares in the underlying tokens
     * @param shares Number of shares
     * @return amount Underling amount representing the `share` value of the strategy
     */
    function _getSharesToAmount(uint256 shares) internal virtual returns(uint128 amount) {
        amount = Math.getProportion128( getStrategyBalance(), shares, strategies[self].totalShares );
    }

    /**
     * @notice get slippage amount, and action type (withdraw/deposit).
     * @dev
     * Most significant bit represents an action, 0 for a withdrawal and 1 for deposit.
     *
     * This ensures the slippage will be used for the action intended by the do-hard-worker,
     * otherwise the transavtion will revert.
     *
     * @param slippageAction number containing the slippage action and the actual slippage amount
     * @return isDeposit Flag showing if the slippage is for the deposit action
     * @return slippage the slippage value cleaned of the most significant bit
     */
    function _getSlippageAction(uint256 slippageAction) internal pure returns (bool isDeposit, uint256 slippage) {
        // remove most significant bit
        slippage = (slippageAction << 1) >> 1;

        // if values are not the same (the removed bit was 1) set action to deposit
        if (slippageAction != slippage) {
            isDeposit = true;
        }
    }

    /* ========== VIRTUAL FUNCTIONS ========== */

    function _deposit(uint128 amount, uint256[] memory slippages) internal virtual returns(uint128 depositReceived);
    function _withdraw(uint128 shares, uint256[] memory slippages) internal virtual returns(uint128 withdrawReceived);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ProcessStrategy.sol";
import "../shared/SwapHelper.sol";

struct Reward {
    uint256 amount;
    IERC20 token;
}

/**
 * @notice Reward strategy logic
 */
abstract contract RewardStrategy is ProcessStrategy, SwapHelper {

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Gey strategy underlying asset with rewards
     * @return Total underlying
     */
    function _getStrategyUnderlyingWithRewards() internal view override virtual returns(uint128) {
        Strategy storage strategy = strategies[self];

        uint128 totalUnderlying = getStrategyBalance();
        totalUnderlying += strategy.pendingDepositReward;

        return totalUnderlying;
    }

    /**
     * @notice Process an instant withdrawal from the protocol per users request.
     *
     * @param shares Amount of shares
     * @param slippages Array of slippages
     * @param swapData Data used in processing
     * @return Withdrawn amount
     */
    function _processFastWithdraw(uint128 shares, uint256[] memory slippages, SwapData[] calldata swapData) internal override virtual returns(uint128) {
        uint128 withdrawRewards = _processFastWithdrawalRewards(shares, swapData);

        uint128 withdrawReceived = _withdraw(shares, slippages);

        return withdrawReceived + withdrawRewards;
    }

    /**
     * @notice Process rewards
     * @param swapData Data used in processing
     */
    function _processRewards(SwapData[] calldata swapData) internal override virtual {
        Strategy storage strategy = strategies[self];

        Reward[] memory rewards = _claimRewards(swapData);

        uint128 collectedAmount = _sellRewards(rewards, swapData);

        if (collectedAmount > 0) {
            strategy.pendingDepositReward += collectedAmount;
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Process fast withdrawal rewards
     * @param shares Amount of shares
     * @param swapData Values used for swapping the rewards
     * @return withdrawalRewards Withdrawal rewards
     */
    function _processFastWithdrawalRewards(uint128 shares, SwapData[] calldata swapData) internal virtual returns(uint128 withdrawalRewards) {
        Strategy storage strategy = strategies[self];

        Reward[] memory rewards = _claimFastWithdrawRewards(shares, swapData);
        
        withdrawalRewards += _sellRewards(rewards, swapData);
        
        if (strategy.pendingDepositReward > 0) {
            uint128 fastWithdrawCompound = Math.getProportion128(strategy.pendingDepositReward, shares, strategy.totalShares);
            if (fastWithdrawCompound > 0) {
                strategy.pendingDepositReward -= fastWithdrawCompound;
                withdrawalRewards += fastWithdrawCompound;
            }
        }
    }

    /**
     * @notice Sell rewards to the underlying token
     * @param rewards Rewards to sell
     * @param swapData Values used for swapping the rewards
     * @return collectedAmount Collected underlying amount
     */
    function _sellRewards(Reward[] memory rewards, SwapData[] calldata swapData) internal virtual returns(uint128 collectedAmount) {
        for (uint256 i = 0; i < rewards.length; i++) {
            // add compound amount from current batch to the fast withdraw
            if (rewards[i].amount > 0) { 
                uint128 compoundAmount = SafeCast.toUint128(
                    _approveAndSwap(
                        rewards[i].token,
                        underlying,
                        rewards[i].amount,
                        swapData[i]
                    )
                );

                // add to pending reward
                collectedAmount += compoundAmount;
            }
        }
    }

    /**
     * @notice Get reward claim amount for `shares`
     * @param shares Amount of shares
     * @param rewardAmount Total reward amount
     * @return rewardAmount Amount of reward for the shares
     */
    function _getRewardClaimAmount(uint128 shares, uint256 rewardAmount) internal virtual view returns(uint128) {
        // for do hard work claim everything
        if (shares == type(uint128).max) {
            return SafeCast.toUint128(rewardAmount);
        } else { // for fast withdrawal claim calculate user withdraw amount
            return SafeCast.toUint128((rewardAmount * shares) / strategies[self].totalShares);
        }
    }

    /* ========== VIRTUAL FUNCTIONS ========== */
    
    function _claimFastWithdrawRewards(uint128 shares, SwapData[] calldata swapData) internal virtual returns(Reward[] memory rewards);
    function _claimRewards(SwapData[] calldata swapData) internal virtual returns(Reward[] memory rewards);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../curve/base/CurveStrategy3CoinsBase.sol";
import "../MultipleRewardStrategy.sol";

import "../../external/interfaces/convex/IBooster.sol";
import "../../external/interfaces/convex/IBaseRewardPool.sol";
import "../../interfaces/IStrategyContractHelper.sol";

/**
 * @notice Convex strategy implementation
 */
contract ConvexSharedStrategy is CurveStrategy3CoinsBase, MultipleRewardStrategy {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */
    
    /// @notice There are 2 base reward tokens: CRV and CVX
    uint256 internal constant BASE_REWARDS_COUNT = 2;

    /* ========== STATE VARIABLES ========== */

    /// @notice Convex booster contract
    IBooster public immutable booster;
    /// @notice booster pool id
    uint256 public immutable pid;
    /// @notice Reward pool contract
    IBaseRewardPool public immutable crvRewards;
    /// @notice Reward token contract
    IERC20 public immutable rewardToken;
    /// @notice CVX token, reward token
    IERC20 public immutable cvxToken;
    /// @notice Booster helper contract
    IStrategyContractHelper public immutable boosterHelper;
    /// @notice Shared key
    bytes32 private immutable _sharedKey;

    /* ========== CONSTRUCTOR ========== */


    /**
     * @notice Set initial values
     * @param _booster Booster contract
     * @param _boosterPoolId Booster pool id
     * @param _pool Stable swap pool contract
     * @param _lpToken LP token contract
     * @param _underlying Underlying asset
     * @param _boosterDeposit Strategy contract helper
     */
    constructor(
        IBooster _booster,
        uint256 _boosterPoolId,
        IStableSwap3Pool _pool,
        IERC20 _lpToken,
        IERC20 _underlying,
        IStrategyContractHelper _boosterDeposit,
        address _self
    )
        BaseStrategy(_underlying, 0, 1, 1, 1, false, true, _self)
        CurveStrategyBase(_pool, _lpToken)
    {
        require(address(_booster) != address(0), "ConvexSharedStrategy::constructor: Booster address cannot be 0");
        booster = _booster;
        pid = _boosterPoolId;

        IBooster.PoolInfo memory cvxPool = _booster.poolInfo(_boosterPoolId);

        require(cvxPool.lptoken == address(_lpToken), "ConvexSharedStrategy::constructor: Booster and curve lp tokens not the same");
        
        crvRewards = IBaseRewardPool(cvxPool.crvRewards);
        rewardToken = crvRewards.rewardToken();
        cvxToken = IERC20(_booster.minter());

        boosterHelper = _boosterDeposit;
        
        _sharedKey = _calculateSharedKey();
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice Initialize strategy
     */
    function initialize() external override {
        _initialize();
    }

    /**
     * @notice Disable strategy
     */
    function disable() external override {
        _disable();
    }

    /**
     * @dev Dynamically return slippage length
     * @return Reward slippage slots
     */
    function _getRewardSlippageSlots() internal view override returns(uint256) {
        return crvRewards.extraRewardsLength() + BASE_REWARDS_COUNT;
    }

    /**
     * @dev Transfers lp tokens to helper contract, to deposit them into booster
     */
    function _handleDeposit(uint256 lp) internal override {
        lpToken.safeTransfer(address(boosterHelper), lp);

        boosterHelper.deposit(lp);
    }

    /**
     * @dev Withdraw lp tokens from helper contract
     */
    function _handleWithdrawal(uint256 lp) internal override {

        boosterHelper.withdraw(lp);
    }

    /**
     * @dev Handle emergency withdrawal
     * @param data Values to perform emergency withdraw
     */
    function _handleEmergencyWithdrawal(address, uint256[] calldata data) internal override {
        // NOTE: withdrawAll removes all lp tokens from the liquidity gauge,
        //       including the tokens from the other strategies in the same pool
        uint256 value = data.length > 0 ? data[0] : 0;

        if (value == 0) {
            boosterHelper.withdraw(_lpBalance());
            strategies[self].lpTokens = 0;
        } else {
            (bool withdrawAll, uint256 lpTokens) = _getSlippageAction(value);
            
            if (withdrawAll) {
                boosterHelper.withdrawAll();
                strategies[self].lpTokens = 0;
            } else {
                boosterHelper.withdraw(lpTokens);

                if (lpTokens >= strategies[self].lpTokens) {
                    strategies[self].lpTokens = 0;
                } else {
                    strategies[self].lpTokens -= lpTokens;
                }
            }
        }
    }

    /**
     * @dev Claim multiple rewards
     * @param shares Shares to claim
     * @param swapData Swap slippage and path array
     * @return rewards array of claimed rewards
     */
    function _claimMultipleRewards(uint128 shares, SwapData[] calldata swapData) internal override returns(Reward[] memory rewards) {
        if (swapData.length > 0) {
            uint256 extraRewardCount = crvRewards.extraRewardsLength();
            
            rewards = new Reward[](extraRewardCount + BASE_REWARDS_COUNT);

            address[] memory rewardTokens = _getRewardAddresses(extraRewardCount);
            _claimStrategyRewards(rewardTokens);

            Strategy storage strategy = strategies[self];
            for (uint256 i = 0; i < rewardTokens.length; i++) {

                if (swapData[i].slippage > 0) {
                    uint256 rewardTokenAmount = strategy.pendingRewards[rewardTokens[i]];

                    if (rewardTokenAmount > 0) {
                        uint256 claimedAmount = _getRewardClaimAmount(shares, rewardTokenAmount);

                        if (rewardTokenAmount > claimedAmount) {
                            // if we don't swap all the tokens (fast withdraw), store the amount left 
                            uint256 rewardAmountLeft = rewardTokenAmount - claimedAmount;
                            strategy.pendingRewards[rewardTokens[i]] = rewardAmountLeft;
                        } else {
                            strategy.pendingRewards[rewardTokens[i]] = 0;
                        }

                        rewards[i] = Reward(claimedAmount, IERC20(rewardTokens[i]));
                    }
                }
            }
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Claim strategy rewards
     * @param rewardTokens Reward tokens
     */
    function _claimStrategyRewards(address[] memory rewardTokens) private {
        (
            uint256[] memory rewardTokenAmounts,
            bool didClaimNewRewards
        ) = boosterHelper.claimRewards(rewardTokens, true);

        if (didClaimNewRewards) {
            Strategy storage strategy = strategies[self];

            for(uint256 i = 0; i < rewardTokens.length; i++) {
                if (rewardTokenAmounts[i] > 0) {
                    strategy.pendingRewards[rewardTokens[i]] += rewardTokenAmounts[i];
                }
            }
        }
    }

    /**
     * @dev Get reward addresses
     * @param extraRewardCount Extra reward count
     * @return Reward addresses
     */
    function _getRewardAddresses(uint256 extraRewardCount) private view returns(address[] memory) {
        address[] memory rewardAddresses = new address[](extraRewardCount + BASE_REWARDS_COUNT);
        rewardAddresses[0] = address(rewardToken);
        rewardAddresses[1] = address(cvxToken);

        for (uint256 i = 0; i < extraRewardCount; i++) {
            rewardAddresses[i + BASE_REWARDS_COUNT] = address(crvRewards.extraReward(i));
        }

        return rewardAddresses;
    }

    /**
     * @dev Calculate shared key
     * @return Shared key
     */
    function _calculateSharedKey() private view returns(bytes32) {
        return keccak256(abi.encodePacked(address(booster), pid));
    }

    /**
     * @dev Get shared key
     * @return Shared key
     */
    function _getSharedKey() internal view override returns(bytes32) {
        return _sharedKey;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./CurveStrategyBase.sol";
import "../../../external/interfaces/curve/IStableSwap3Pool.sol";

/**
 * @notice Curve 3Coins base strategy
 */
abstract contract CurveStrategy3CoinsBase is CurveStrategyBase {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    /// @notice Total number of coins
    uint256 internal constant TOTAL_COINS = 3;

    /* ========== STATE VARIABLES ========== */

    /// @notice Stable swap pool
    IStableSwap3Pool public immutable pool3Coins;

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        pool3Coins = IStableSwap3Pool(address(pool));
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @dev register a strategy as shared strategy, using shared key
     */
    function _initialize() internal virtual {
        StrategiesShared storage stratsShared = strategiesShared[_getSharedKey()];
        
        stratsShared.stratAddresses[stratsShared.stratsCount] = self;
        stratsShared.stratsCount++;
    }

    /**
     * @notice Run after strategy was removed as a breakdown function
     */
    function _disable() internal virtual {
        StrategiesShared storage stratsShared = strategiesShared[_getSharedKey()];

        uint256 sharedStratsCount = stratsShared.stratsCount;

        for(uint256 i = 0; i < sharedStratsCount; i++) {
            if (stratsShared.stratAddresses[i] == self) {
                stratsShared.stratAddresses[i] = stratsShared.stratAddresses[sharedStratsCount - 1];
                delete stratsShared.stratAddresses[sharedStratsCount - 1];
                stratsShared.stratsCount--;
                break;
            }
        }
    }

    /**
     * @notice Deposit
     * @param amount Amount
     * @param slippage Slippage
     */
    function _curveDeposit(uint256 amount, uint256 slippage) internal override {
        uint256[TOTAL_COINS] memory amounts;
        amounts[uint128(nCoin)] = amount;

        pool3Coins.add_liquidity(amounts, slippage);
    }

    /* ========== VIRTUAL FUNCTIONS ========== */

    /**
     * @notice Get shared key
     * @return Shared key
     */
    function _getSharedKey() internal virtual view returns(bytes32);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../../ProcessStrategy.sol";
import "../../../external/interfaces/curve/ICurvePool.sol";

abstract contract CurveStrategyBase is ProcessStrategy {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    uint256 internal constant ONE_LP_UNIT = 1e18;

    /* ========== STATE VARIABLES ========== */

    ICurvePool public immutable pool;
    IERC20 public immutable lpToken;
    int128 public immutable nCoin;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        ICurvePool _pool,
        IERC20 _lpToken
    ) {
        require(address(_pool) != address(0), "CurveStrategy::constructor: Curve Pool address cannot be 0");
        require(address(_lpToken) != address(0), "CurveStrategy::constructor: Token address cannot be 0");

        pool = _pool;
        lpToken = _lpToken;
        
        uint128 _nCoin = 0;
        while (_pool.coins(_nCoin) != address(underlying)) _nCoin++;
        nCoin = int128(_nCoin);
    }

    /* ========== VIEWS ========== */

    function getStrategyBalance() public view override returns(uint128) {
        return _lpToCoin(_lpBalance());
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    function _deposit(uint128 amount, uint256[] memory slippages) internal override returns(uint128) {
        (bool isDeposit, uint256 slippage) = _getSlippageAction(slippages[0]);
        require(isDeposit, "CurveStrategyBase::_deposit: Withdraw slippage provided");
        
        // deposit underlying
        underlying.safeApprove(address(pool), amount);
        
        uint256 lpBefore = lpToken.balanceOf(address(this));
        _curveDeposit(amount, slippage);
        uint256 newLp = lpToken.balanceOf(address(this)) - lpBefore;
        _resetAllowance(underlying, address(pool));

        emit Slippage(self, underlying, true, amount, newLp);

        strategies[self].lpTokens += newLp;

        _handleDeposit(newLp);
        return _lpToCoin(newLp);
    }

    function _withdraw(uint128 shares, uint256[] memory slippages) internal override returns(uint128) {
        (bool isDeposit, uint256 slippage) = _getSlippageAction(slippages[0]);
        require(!isDeposit, "CurveStrategyBase::_withdraw: Deposit slippage provided");

        uint256 totalLp = _lpBalance();

        uint256 withdrawLp = (totalLp * shares) / strategies[self].totalShares;
        strategies[self].lpTokens -= withdrawLp;

        // withdraw staked lp tokens
        _handleWithdrawal(withdrawLp);

        // withdraw fTokens from vault
        uint256 undelyingBefore = underlying.balanceOf(address(this));
        
        pool.remove_liquidity_one_coin(withdrawLp, nCoin, slippage);
        uint256 underlyingWithdrawn = underlying.balanceOf(address(this)) - undelyingBefore;

        emit Slippage(self, underlying, false, shares, underlyingWithdrawn);

        return SafeCast.toUint128(underlyingWithdrawn);
    }

    /**
     * @notice Emergency withdraw from curve pool
     */
    function _emergencyWithdraw(address recipient, uint256[] calldata data) internal override {
        uint256 slippage = data.length > 0 ? data[0] : 0;

        uint256[] calldata poolData = data.length > 0 ? data[1:] : data;

        uint256 lpBefore = lpToken.balanceOf(address(this));
        _handleEmergencyWithdrawal(recipient, poolData);
        uint256 newLp = lpToken.balanceOf(address(this)) - lpBefore;

        pool.remove_liquidity_one_coin(newLp, nCoin, slippage);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _lpBalance() internal view returns (uint256) {
        return strategies[self].lpTokens;
    }

    function _lpToCoin(uint256 lp) internal view returns (uint128) {
        if (lp == 0)
            return 0;
        
        uint256 lpToCoin = pool.calc_withdraw_one_coin(ONE_LP_UNIT, nCoin);

        uint256 result = (lp * lpToCoin) / ONE_LP_UNIT;

        return SafeCast.toUint128(result);
    }

    /* ========== VIRTUAL FUNCTIONS ========== */
    
    function _curveDeposit(uint256 amount, uint256 slippage) internal virtual;

    function _handleDeposit(uint256 lp) internal virtual;

    function _handleWithdrawal(uint256 lp) internal virtual;

    function _handleEmergencyWithdrawal(address recipient, uint256[] calldata data) internal virtual;
}