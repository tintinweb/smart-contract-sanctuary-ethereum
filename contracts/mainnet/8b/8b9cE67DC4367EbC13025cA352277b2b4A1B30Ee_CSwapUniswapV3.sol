// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.6;

import "ICSwapUniswapV3.sol";
import "ISwapRouter.sol";
import "CSwapBase.sol";

contract CSwapUniswapV3 is CSwapBase, ICSwapUniswapV3 {
    function _getContractName() internal pure override returns (string memory) {
        return "CSwapUniswapV3";
    }

    /** @notice Use this function to SELL a fixed amount of an asset.
        @dev This function sells an EXACT amount of `tokenIn` to receive `tokenOut`.
        If the price is worse than a threshold, the transaction will revert.
        @param amountIn The exact amount of `tokenIn` to sell.
        @param tokenIn The token to sell. Note: This must be an ERC20 token.
        @param tokenOut The token that the user wishes to receive. Note: This must be an ERC20 token.
        @param minAmountOut The minimum amount of `tokenOut` the user wishes to receive.
        @param params Additional parameters to specify UniswapV3 specific parameters. See ICSwapUniswapV3.sol
     */
    function sell(
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        UniswapV3SwapParams calldata params
    ) external payable {
        address receiver = params.receiver == address(0) ? address(this) : params.receiver;

        uint256 balanceBefore = _preSwap(
            tokenIn,
            tokenOut,
            address(params.router),
            amountIn,
            receiver
        );

        //solhint-disable-next-line not-rely-on-time
        uint256 deadline = params.deadline == 0 ? block.timestamp + 1 : params.deadline;

        ISwapRouter(params.router).exactInput(
            ISwapRouter.ExactInputParams({
                path: params.path,
                recipient: receiver,
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            })
        );

        _postSwap(balanceBefore, tokenOut, minAmountOut, receiver);
    }

    /** @notice Use this function to perform BUY a fixed amount of an asset.
        @dev This function buys an EXACT amount of `tokenOut` by spending `tokenIn`.
        If the price is worse than a threshold, the transaction will revert.
        @param amountOut The exact amount of `tokenOut` to buy.
        @param tokenOut The token to buy. Note: This must be an ERC20 token.
        @param tokenIn The token that the user wishes to spend. Note: This must be an ERC20 token.
        @param maxAmountIn The maximum amount of `tokenIn` that the user wishes to spend.
        @param params Additional parameters to specify UniswapV3 specific parameters. See ICSwapUniswapV3.sol
     */
    function buy(
        uint256 amountOut,
        IERC20 tokenOut,
        IERC20 tokenIn,
        uint256 maxAmountIn,
        UniswapV3SwapParams calldata params
    ) external payable {
        address receiver = params.receiver == address(0) ? address(this) : params.receiver;

        uint256 balanceBefore = _preSwap(
            tokenIn,
            tokenOut,
            address(params.router),
            maxAmountIn,
            receiver
        );

        //solhint-disable-next-line not-rely-on-time
        uint256 deadline = params.deadline == 0 ? block.timestamp + 1 : params.deadline;

        ISwapRouter(params.router).exactOutput(
            ISwapRouter.ExactOutputParams({
                path: params.path,
                recipient: receiver,
                deadline: deadline,
                amountOut: amountOut,
                amountInMaximum: maxAmountIn
            })
        );

        _postSwap(balanceBefore, tokenOut, amountOut, receiver);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICSwapUniswapV3 {
    /** @notice Used to specify UniswapV3 specific parameters for CSwap.
        @param router The address of the UniswapV3 router.
        @param path The path taken to perform the swap. This is encoded according to specification by Uniswap V3. This can be 
            obtained by performing abi.encodePacked(tokenIn, fee, intermediateToken, fee, outputToken). Examples for how to perform
            this off-chain can be found within the github repository.
        @param receiver The address where the swapped tokens will be sent to. This is an optional argument, and users can enter
            the zero address instead. In this case, the tokens will be sent to the invoker and must then be sweeped back to the user.
        @param deadline The unix timestamp at which point the swap no longer becomes valid. This must be in seconds. If the
            order has no expiry, then use parameter 0.
     */
    struct UniswapV3SwapParams {
        address router;
        bytes path;
        address receiver;
        uint256 deadline;
    }
}

// https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface ISwapRouter {
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
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

import "SafeERC20.sol";

abstract contract CSwapBase {
    using SafeERC20 for IERC20;

    function _getContractName() internal pure virtual returns (string memory);

    function _revertMsg(string memory message) internal {
        revert(string(abi.encodePacked(_getContractName(), ":", message)));
    }

    function _requireMsg(bool condition, string memory message) internal {
        if (!condition) {
            revert(string(abi.encodePacked(_getContractName(), ":", message)));
        }
    }

    function _tokenApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.safeApprove(spender, 0);
        }
        token.safeApprove(spender, amount);
    }

    function _preSwap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        address router,
        uint256 amount,
        address receiver
    ) internal virtual returns (uint256 balanceBefore) {
        balanceBefore = tokenOut.balanceOf(receiver);
        _tokenApprove(tokenIn, router, amount);
    }

    function _postSwap(
        uint256 balanceBefore,
        IERC20 tokenOut,
        uint256 minReceived,
        address receiver
    ) internal virtual {
        uint256 balanceAfter = tokenOut.balanceOf(address(receiver));
        _requireMsg(balanceAfter >= balanceBefore + minReceived, "Slippage in");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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