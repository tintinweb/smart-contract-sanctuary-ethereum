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
pragma solidity 0.8.17;

import { IUniswapV2RouterFacet } from "./../interfaces/facets/IUniswapV2RouterFacet.sol";
import { Constants } from "./../libraries/Constants.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { UniswapV2Library } from "./../libraries/uniswap/v2/UniswapV2Library.sol";
import { IUniswapV2Pair } from "./../interfaces/external/uniswap/v2/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "./../interfaces/external/uniswap/v2/IUniswapV2Factory.sol";


/**
 * @title UniswapV2RouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for a variety of functions involving Uniswap V2.
 *
 * Liquidity providers can add liquidity via [`uniswapV2AddLiquidity()`](#uniswapv2addliquidity) or [`uniswapV2AddLiquidityUnbalanced()`](#uniswapv2addliquidityunbalanced). Liquidity providers can remove liquidity via [`uniswapV2RemoveLiquidity()`](#uniswapv2removeliquidity).
 *
 * Traders can perform trades via [`uniswapV2SwapExactInput()`](#uniswapv2swapexactinput) or [`uniswapV2SwapExactOutput()`](#uniswapv2swapexactoutput). Traders can get quotes on their trades via [`uniswapV2Quote()`](#uniswapv2quote), [`uniswapV2GetAmountOut()`](#uniswapv2getamountout), [`uniswapV2GetAmountIn()`](#uniswapv2getamountin), [`uniswapV2GetAmountsOut()`](#uniswapv2getamountsout), or [`uniswapV2GetAmountsIn()`](#uniswapv2getamountsin).
 *
 * There are a number of benefits of using UniswapV2RouterFacet over the traditional UniswapV2Router02.
 * - Swaps can be performed across different Uniswap forks via `multicall()`. For example you might trade **UNI** for **WETH** in Uniswap then trade **WETH** for **gOHM** in Sushiswap.
 * - Liquidity providers can add liquidity in an unbalanced ratio via [`uniswapV2AddLiquidityUnbalanced()`](#uniswapv2addliquidityunbalanced).
 * - Liquidity providers can remove liquidity to a single token by `multicall()` chaining [`uniswapV2RemoveLiquidity()`](#uniswapv2removeliquidity) and [`uniswapV2SwapExactInput()`](#uniswapv2swapexactinput).
 *
 * The initial tokens must be in this contract before the add/remove/swap call is made. For security consider combining these calls with calls to [`ERC20RouterFacet`](./ERC20RouterFacet) via `multicall()`.
 */
contract UniswapV2RouterFacet is IUniswapV2RouterFacet {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Given an amount of tokenA and a pair's reserves, calculates an equivalent amount of tokenB not including swap fee.
     * @param amountA The amount of tokenA.
     * @param reserveA The reserve of tokenA.
     * @param reserveB The reserve of tokenB.
     * @return amountB The amount of tokenB.
     */
    function uniswapV2Quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure override returns (uint256 amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    /**
     * @notice Given an amount of tokenIn and a pair's reserves, calculates an amount of tokenOut including swap fee.
     * @param amountIn The amount of tokenIn.
     * @param reserveIn The reserve of tokenIn.
     * @param reserveOut The reserve of tokenOut.
     * @return amountOut The amount of tokenOut.
     */
    function uniswapV2GetAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure override returns (uint256 amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     * @notice Given an amount of tokenOut and a pair's reserves, calculates an amount of tokenIn including swap fee.
     * @param amountOut The amount of tokenOut.
     * @param reserveIn The reserve of tokenIn.
     * @param reserveOut The reserve of tokenOut.
     * @return amountIn The amount of tokenIn.
     */
    function uniswapV2GetAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure override returns (uint256 amountIn) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /**
     * @notice Given an amount of tokenIn and swap path, calculates an amount of tokenOut including swap fees.
     * @param factory The UniswapV2Factory.
     * @param amountIn The amount of tokenIn.
     * @param path The list of tokens in the swap path.
     * @return amounts The amount of tokens at each step in the swap.
     */
    function uniswapV2GetAmountsOut(address factory, uint256 amountIn, address[] memory path) external view override returns (uint256[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @notice Given an amount of tokenOut and swap path, calculates an amount of tokenIn including swap fees.
     * @param factory The UniswapV2Factory.
     * @param amountOut The amount of tokenOut.
     * @param path The list of tokens in the swap path.
     * @return amounts The amount of tokens at each step in the swap.
     */
    function uniswapV2GetAmountsIn(address factory, uint256 amountOut, address[] memory path) external view override returns (uint256[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    /***************************************
    ADD LIQUIDITY FUNCTIONS
    ***************************************/

    /**
     * @notice Adds liquidity to a pair.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to deposit or max uint for entire balance.
     * @param amountBDesired The desired amount of tokenB to deposit or max uint for entire balance.
     * @param amountAMin The minimum amount of tokenA to deposit. Reverts if less.
     * @param amountBMin The minimum amount of tokenB to deposit. Reverts if less.
     * @param receiver The address to receive the liquidity pool token.
     * @return amountA The amount of tokenA that was deposited.
     * @return amountB The amount of tokenB that was deposited.
     * @return liquidity The amount of the liquidity pool token that was minted.
     */
    function uniswapV2AddLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address receiver
    ) external payable override returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if(amountADesired == Constants.CONTRACT_BALANCE) amountADesired = IERC20(tokenA).balanceOf(address(this));
        if(amountBDesired == Constants.CONTRACT_BALANCE) amountBDesired = IERC20(tokenB).balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        address pair;
        (amountA, amountB, pair) = _addLiquidity(factory, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        SafeERC20.safeTransfer(IERC20(tokenA), pair, amountA);
        SafeERC20.safeTransfer(IERC20(tokenB), pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(receiver);
    }

    /**
     * @notice Calculates the liquidity to add to a pair.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to deposit.
     * @param amountBDesired The desired amount of tokenB to deposit.
     * @param amountAMin The minimum amount of tokenA to deposit. Reverts if less.
     * @param amountBMin The minimum amount of tokenB to deposit. Reverts if less.
     * @return amountA The amount of tokenA to deposit.
     * @return amountB The amount of tokenB to deposit.
     * @return pair The address of the Uniswap V2 pair.
     */
    function _addLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB, address pair) {
        // create the pair if it doesn't exist yet
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0x0)) {
            pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReservesFromPair(pair, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "UniswapV2RF: add insuff B");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "UniswapV2RF: add insuff A");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @notice By default Uniswap V2 only allows liquidity providers to add liquidity in the same ratio as reserves. This function allows adding liquidity in an unbalanced amount. This is possible by first performing a swap to equalize the add amount and reserve ratio if necessary then adding the new amounts to the new reserves.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to deposit or max uint for entire balance.
     * @param amountBDesired The desired amount of tokenB to deposit or max uint for entire balance.
     * @param receiver The address to receive the liquidity pool token.
     * @return amountA The amount of tokenA that was deposited.
     * @return amountB The amount of tokenB that was deposited.
     * @return liquidity The amount of the liquidity pool token that was minted.
     */
    function uniswapV2AddLiquidityUnbalanced(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address receiver
    ) external payable override returns (int256 amountA, int256 amountB, uint256 liquidity) {
        // step 1: swap math
        if(amountADesired == Constants.CONTRACT_BALANCE) amountADesired = IERC20(tokenA).balanceOf(address(this));
        if(amountBDesired == Constants.CONTRACT_BALANCE) amountBDesired = IERC20(tokenB).balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        (uint256 amountSwapIn, uint256 amountSwapOut, bool swapAForB, address pair) =
            _addLiquidityUnbalancedCalculateSwap1(factory, tokenA, tokenB, amountADesired, amountBDesired);
        if(amountSwapOut > 0) {
            // step 2: swap if necessary
            {
            uint256 amount0Out;
            uint256 amount1Out;
            if(swapAForB) {
                SafeERC20.safeTransfer(IERC20(tokenA), pair, amountSwapIn);
                if(tokenA < tokenB) amount1Out = amountSwapOut;
                else amount0Out = amountSwapOut;
                amountADesired -= amountSwapIn;
                amountBDesired += amountSwapOut;
            } else {
                SafeERC20.safeTransfer(IERC20(tokenB), pair, amountSwapIn);
                if(tokenA < tokenB) amount0Out = amountSwapOut;
                else amount1Out = amountSwapOut;
                amountADesired += amountSwapOut;
                amountBDesired -= amountSwapIn;
            }
            IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
            }
            // step 3.A.1: add liquidity math
            (uint256 amountAAdd, uint256 amountBAdd) =
                _addLiquidityUnbalancedCalculateAdd(pair, tokenA, tokenB, amountADesired, amountBDesired);
            (amountA, amountB) = (swapAForB // may be negative if swap out more than add
                ? (int256(amountAAdd) + int256(amountSwapIn), int256(amountBAdd) - int256(amountSwapOut))
                : (int256(amountAAdd) - int256(amountSwapOut), int256(amountBAdd) + int256(amountSwapIn)) );
            // step 3.A.2: add liquidity
            SafeERC20.safeTransfer(IERC20(tokenA), pair, amountAAdd);
            SafeERC20.safeTransfer(IERC20(tokenB), pair, amountBAdd);
            liquidity = IUniswapV2Pair(pair).mint(receiver);
        } else {
            // step 3.B: add liquidity in amounts desired
            amountA = int256(amountADesired);
            amountB = int256(amountBDesired);
            SafeERC20.safeTransfer(IERC20(tokenA), pair, amountADesired);
            SafeERC20.safeTransfer(IERC20(tokenB), pair, amountBDesired);
            liquidity = IUniswapV2Pair(pair).mint(receiver);
        }
    }

    /**
     * @notice Determines if a swap step is necessary while adding liquidity unbalanced, and if so calculates the swap.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to deposit.
     * @param amountBDesired The desired amount of tokenB to deposit.
     * @return amountSwapIn The amount of the input token to swap or zero to not swap.
     * @return amountSwapOut The amount of the output token to swap or zero to not swap.
     * @return swapAForB True to swap tokenA for tokenB, false to swap tokenB for tokenA.
     * @return pair The address of the Uniswap V2 pair.
     */
    function _addLiquidityUnbalancedCalculateSwap1(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (
        uint256 amountSwapIn,
        uint256 amountSwapOut,
        bool swapAForB,
        address pair
    ) {
        // create the pair if it doesn't exist yet
        pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if (pair == address(0x0)) {
            pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReservesFromPair(pair, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            // no reserves. swap unnecessary. add all
            return (0, 0, false, pair);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal == amountBDesired) {
                // adding in equal ratio. swap unnecessary. add all
                return (0, 0, false, pair);
            } else if (amountBOptimal > amountBDesired) {
                // swap excess A for B
                (amountSwapIn, amountSwapOut) = _addLiquidityUnbalancedCalculateSwap2(reserveA, reserveB, amountADesired, amountBDesired);
                return (amountSwapIn, amountSwapOut, true, pair);
            } else {
                // swap excess B for A
                (amountSwapIn, amountSwapOut) = _addLiquidityUnbalancedCalculateSwap2(reserveB, reserveA, amountBDesired, amountADesired);
                return (amountSwapIn, amountSwapOut, false, pair);
            }
        }
    }

    /**
     * @notice Calculates the swap required while adding liquidity unbalanced.
     * @dev Assumes the liquidity provider is adding excess tokenX that needs to get swapped to tokenY (dx0/dy0 > x0/y0).
     * @param x0 The initial reserve of tokenX.
     * @param y0 The initial reserve of tokenY.
     * @param dx0 The amount of tokenX to deposit unbalanced.
     * @param dy0 The amount of tokenY to deposit unbalanced.
     * @return dx12 The amount of tokenX to swap in including swap fee.
     * @return dy2 The amount of tokenY to swap out.
     */
    function _addLiquidityUnbalancedCalculateSwap2(
        uint256 x0, uint256 y0, uint256 dx0, uint256 dy0
    ) internal pure returns (
        uint256 dx12, uint256 dy2
    ) {
        /*
        TODO: This function calculates the optimal amount to swap.
        This implementation performs a binary search.
        It's cheap enough to use in production (tests showed between 1,400 and 113,000 gas)
        As the number of iterations is low (2**60 ~= 10**18)
        And it's all low level math operations performed in stack.
        However, it is very likely that a mathematical solution exists and can be performed more cheaply.
        I have tried but so far been unable to find a solution.
        This is my current work; whoever pulls the solution from the stone shall be crowned King Arthur.
        Note 'd' is short for delta not derivative.

        Goal:
          Find a dx12 that satisfies dx3/dy3 == x2/y2.
        Inputs:
          x0   // The initial reserve of tokenX.
          y0   // The initial reserve of tokenY.
          dx0  // The amount of tokenX to deposit unbalanced.
          dy0  // The amount of tokenY to deposit unbalanced.
        Outputs:
          dx12 // The amount of tokenX to swap in including swap fee.
          dy2  // The amount of tokenY to swap out.
        Assumptions:
          x0, y0, dx0 > 0
          dx0/dy0 > x0/y0  // Need to swap X for Y.
          Swap fees paid in tokenX.
        Intermediate variables:
          dx1              // Swap fee in tokenX.
          dy1 = 0          // Swap fee in tokenY.
          dx2              // TokenX swap amount after fee.
          dy2              // TokenY swap amount.
          x1 = x0 + dx1    // The reserve of tokenX after the swap fee.
          y1 = y0          // The reserve of tokenY after the swap fee.
          x2 = x0 + dx12   // The reserve of tokenX after the swap step.
          y2 = y0 - dy2    // The reserve of tokenY after the swap step.
          dx3 = dx0 - dx12 // The amount of tokenX to deposit balanced.
          dy3 = dy0 + dy2  // The amount of tokenY to deposit balanced.
        Equations:
          dx3/dy3 == x2/y2        // goal: reserves and add ratio are equal
          dx0 = dx1 + dx2 + dx3   // allocation of capital across steps
          dy0 = dy3 - dy2         // allocation of capital across steps
          dx12 = dx1 + dx2        // swap fees
          dx12 * 3 / 1000 = dx1   // swap fees
          dx12 * 997 / 1000 = dx2 // swap fees
          x1*y1 = x2*y2           // swap invariant
        */

        // solhint-disable var-name-mixedcase
        uint256 L = 1;       // left and right walls of binary search
        uint256 R = dx0 - 1; // searching in domain dx
        while(L < R) {
            dx12 = (L + R) / 2;
            // calculate swap given dx12
            uint256 dx2_1000 = dx12 * 997;
            uint256 numerator = dx2_1000 * y0;
            uint256 denominator = (x0 * 1000) + dx2_1000;
            dy2 = numerator / denominator; // dy2 = UniswapV2Library.getAmountOut(dx12, x0, y0);
            // calculate add
            /*
            uint256 dx3 = dx0 - dx12; // The amount of tokenX to deposit balanced.
            uint256 dy3 = dy0 + dy2;  // The amount of tokenY to deposit balanced.
            uint256 x2 = x0 + dx12;   // The reserve of tokenX after the swap step.
            uint256 y2 = y0 - dy2;    // The reserve of tokenY after the swap step.
            uint256 cm1 = x2 * dy3;   // cross multiply left
            uint256 cm2 = y2 * dx3;   // cross multiple right
            */
            uint256 cm1 = (x0 + dx12) * (dy0 + dy2);
            uint256 cm2 = (y0 - dy2) * (dx0 - dx12);
            // branch left or right
            if(cm1 == cm2) return (dx12, dy2);
            else if(cm1 < cm2) L = dx12 + 1;
            else R = dx12 - 1;
        }
        return (dx12, dy2);
        // solhint-enable var-name-mixedcase
    }

    /**
     * @notice Calculates the liquidity to add to a pair.
     * @dev Same as `_addLiquidity()` without redunant checks.
     * @param pair The address of the Uniswap V2 pair.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to deposit.
     * @param amountBDesired The desired amount of tokenB to deposit.
     * @return amountA The amount of tokenA to deposit.
     * @return amountB The amount of tokenB to deposit.
     */
    function _addLiquidityUnbalancedCalculateAdd(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal view returns (
        uint256 amountA,
        uint256 amountB
    ) {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReservesFromPair(pair, tokenA, tokenB);
        uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    /***************************************
    REMOVE LIQUIDITY FUNCTIONS
    ***************************************/

    /**
     * @notice Removes liquidity from a pair.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param liquidity The amount of the liquidity pool token to redeem or max uint for entire balance.
     * @param amountAMin The minimum amount of tokenA to receive. Reverts if less.
     * @param amountBMin The minimum amount of tokenB to receive. Reverts if less.
     * @param receiver The address to receive the liquidity pool token.
     * @return amountA The amount of tokenA that was received.
     * @return amountB The amount of tokenB that was received.
     */
    function uniswapV2RemoveLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address receiver
    ) external payable returns (uint256 amountA, uint256 amountB) {
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        if(liquidity == Constants.CONTRACT_BALANCE) liquidity = IUniswapV2Pair(pair).balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        IUniswapV2Pair(pair).transfer(pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(receiver);
        (amountA, amountB) = ( (tokenA < tokenB) ? (amount0, amount1) : (amount1, amount0) );
        require(amountA >= amountAMin, "UniswapV2RF: remove insuff A");
        require(amountB >= amountBMin, "UniswapV2RF: remove insuff B");
    }

    /***************************************
    SWAP FUNCTIONS
    ***************************************/

    /**
     * @notice Given an exact amount of input tokens, swaps them for the greatest possible amount of output tokens.
     * @param factory The address of the Uniswap V2 factory.
     * @param amountIn The amount of the input token to swap or max uint for entire balance.
     * @param amountOutMin The minimum amount of the output token to receive. Reverts if less.
     * @param path The list of tokens to swap against.
     * @param receiver The address to receive the output tokens.
     * @return amounts The amount of each token used in the swap.
     */
    function uniswapV2SwapExactInput(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address receiver
    ) external payable override returns (uint256[] memory amounts) {
        if(amountIn == Constants.CONTRACT_BALANCE) amountIn = IERC20(path[0]).balanceOf(address(this));
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "UniswapV2RF: swap insuff output");
        SafeERC20.safeTransfer(IERC20(path[0]), IUniswapV2Factory(factory).getPair(path[0], path[1]), amounts[0]);
        _swap(factory, amounts, path, receiver);
    }

    /**
     * @notice Given an exact amount of output tokens, swaps them using the least possible amount of input tokens.
     * @param factory The address of the Uniswap V2 factory.
     * @param amountOut The amount of the output token to swap.
     * @param amountInMax The maximum amount of the input token to spend. Reverts if greater.
     * @param path The list of tokens to swap against.
     * @param receiver The address to receive the output tokens.
     * @return amounts The amount of each token used in the swap.
     */
    function uniswapV2SwapExactOutput(
        address factory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address receiver
    ) external payable override returns (uint256[] memory amounts) {
        if(receiver == Constants.MSG_SENDER) receiver = msg.sender;
        else if(receiver == Constants.ADDRESS_THIS) receiver = address(this);
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "UniswapV2RF: swap excess input");
        SafeERC20.safeTransfer(IERC20(path[0]), IUniswapV2Factory(factory).getPair(path[0], path[1]), amounts[0]);
        _swap(factory, amounts, path, receiver);
    }

    /**
     * @notice Performs a swap.
     * @dev Requires the initial amount to have already been sent to the first pair.
     * @param factory The address of the Uniswap V2 factory.
     * @param amounts The amount of each token used in the swap.
     * @param path The list of tokens to swap against.
     * @param receiver The address to receive the output tokens.
     */
    function _swap(address factory, uint256[] memory amounts, address[] memory path, address receiver) internal {
        bytes memory b0 = new bytes(0);
        for (uint256 i; i < path.length - 1; ) {
            (address input, address output) = (path[i], path[i + 1]);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = ( (input < output) ? (uint256(0), amountOut) : (amountOut, uint256(0)) );
            address toNext = i < path.length - 2 ? IUniswapV2Factory(factory).getPair(output, path[i + 2]) : receiver;
            IUniswapV2Pair(IUniswapV2Factory(factory).getPair(input, output)).swap(amount0Out, amount1Out, toNext, b0);
            unchecked { i++; }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IUniswapV2RouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for a variety of functions involving Uniswap V2.
 *
 * Liquidity providers can add liquidity via [`uniswapV2AddLiquidity()`](#uniswapv2addliquidity) or [`uniswapV2AddLiquidityUnbalanced()`](#uniswapv2addliquidityunbalanced). Liquidity providers can remove liquidity via [`uniswapV2RemoveLiquidity()`](#uniswapv2removeliquidity).
 *
 * Traders can perform trades via [`uniswapV2SwapExactInput()`](#uniswapv2swapexactinput) or [`uniswapV2SwapExactOutput()`](#uniswapv2swapexactoutput). Traders can get quotes on their trades via [`uniswapV2Quote()`](#uniswapv2quote), [`uniswapV2GetAmountOut()`](#uniswapv2getamountout), [`uniswapV2GetAmountIn()`](#uniswapv2getamountin), [`uniswapV2GetAmountsOut()`](#uniswapv2getamountsout), or [`uniswapV2GetAmountsIn()`](#uniswapv2getamountsin).
 *
 * There are a number of benefits of using UniswapV2RouterFacet over the traditional UniswapV2Router02.
 * - Swaps can be performed across different Uniswap forks via `multicall()`. For example you might trade **UNI** for **WETH** in Uniswap then trade **WETH** for **gOHM** in Sushiswap.
 * - Liquidity providers can add liquidity in an unbalanced ratio via [`uniswapV2AddLiquidityUnbalanced()`](#uniswapv2addliquidityunbalanced).
 * - Liquidity providers can remove liquidity to a single token by `multicall()` chaining [`uniswapV2RemoveLiquidity()`](#uniswapv2removeliquidity) and [`uniswapV2SwapExactInput()`](#uniswapv2swapexactinput).
 *
 * The initial tokens must be in this contract before the add/remove/swap call is made. For security consider combining these calls with calls to [`ERC20RouterFacet`](./IERC20RouterFacet) via `multicall()`.
 */
interface IUniswapV2RouterFacet {

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Given an amount of tokenA and a pair's reserves, calculates an equivalent amount of tokenB not including swap fee.
     * @param amountA The amount of tokenA.
     * @param reserveA The reserve of tokenA.
     * @param reserveB The reserve of tokenB.
     * @return amountB The amount of tokenB.
     */
    function uniswapV2Quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    /**
     * @notice Given an amount of tokenIn and a pair's reserves, calculates an amount of tokenOut including swap fee.
     * @param amountIn The amount of tokenIn.
     * @param reserveIn The reserve of tokenIn.
     * @param reserveOut The reserve of tokenOut.
     * @return amountOut The amount of tokenOut.
     */
    function uniswapV2GetAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);

    /**
     * @notice Given an amount of tokenOut and a pair's reserves, calculates an amount of tokenIn including swap fee.
     * @param amountOut The amount of tokenOut.
     * @param reserveIn The reserve of tokenIn.
     * @param reserveOut The reserve of tokenOut.
     * @return amountIn The amount of tokenIn.
     */
    function uniswapV2GetAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);

    /**
     * @notice Given an amount of tokenIn and swap path, calculates an amount of tokenOut including swap fees.
     * @param factory The UniswapV2Factory.
     * @param amountIn The amount of tokenIn.
     * @param path The list of tokens in the swap path.
     * @return amounts The amount of tokens at each step in the swap.
     */
    function uniswapV2GetAmountsOut(address factory, uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);

    /**
     * @notice Given an amount of tokenOut and swap path, calculates an amount of tokenIn including swap fees.
     * @param factory The UniswapV2Factory.
     * @param amountOut The amount of tokenOut.
     * @param path The list of tokens in the swap path.
     * @return amounts The amount of tokens at each step in the swap.
     */
    function uniswapV2GetAmountsIn(address factory, uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);

    /***************************************
    ADD LIQUIDITY FUNCTIONS
    ***************************************/

    /**
     * @notice Adds liquidity to a pair.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to deposit or max uint for entire balance.
     * @param amountBDesired The desired amount of tokenB to deposit or max uint for entire balance.
     * @param amountAMin The minimum amount of tokenA to deposit. Reverts if less.
     * @param amountBMin The minimum amount of tokenB to deposit. Reverts if less.
     * @param receiver The address to receive the liquidity pool token.
     * @return amountA The amount of tokenA that was deposited.
     * @return amountB The amount of tokenB that was deposited.
     * @return liquidity The amount of the liquidity pool token that was minted.
     */
    function uniswapV2AddLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address receiver
    ) external payable returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice By default Uniswap V2 only allows liquidity providers to add liquidity in the same ratio as reserves. This function allows adding liquidity in an unbalanced amount. This is possible by first performing a swap to equalize the add amount and reserve ratio if necessary then adding the new amounts to the new reserves.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to deposit or max uint for entire balance.
     * @param amountBDesired The desired amount of tokenB to deposit or max uint for entire balance.
     * @param receiver The address to receive the liquidity pool token.
     * @return amountA The amount of tokenA that was deposited.
     * @return amountB The amount of tokenB that was deposited.
     * @return liquidity The amount of the liquidity pool token that was minted.
     */
    function uniswapV2AddLiquidityUnbalanced(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address receiver
    ) external payable returns (int256 amountA, int256 amountB, uint256 liquidity);

    /***************************************
    REMOVE LIQUIDITY FUNCTIONS
    ***************************************/

    /**
     * @notice Removes liquidity from a pair.
     * @param factory The address of the Uniswap V2 factory.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param liquidity The amount of the liquidity pool token to redeem or max uint for entire balance.
     * @param amountAMin The minimum amount of tokenA to receive. Reverts if less.
     * @param amountBMin The minimum amount of tokenB to receive. Reverts if less.
     * @param receiver The address to receive the liquidity pool token.
     * @return amountA The amount of tokenA that was received.
     * @return amountB The amount of tokenB that was received.
     */
    function uniswapV2RemoveLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address receiver
    ) external payable returns (uint256 amountA, uint256 amountB);

    /***************************************
    SWAP FUNCTIONS
    ***************************************/

    /**
     * @notice Given an exact amount of input tokens, swaps them for the greatest possible amount of output tokens.
     * @param factory The address of the Uniswap V2 factory.
     * @param amountIn The amount of the input token to swap or max uint for entire balance.
     * @param amountOutMin The minimum amount of the output token to receive. Reverts if less.
     * @param path The list of tokens to swap against.
     * @param receiver The address to receive the output tokens.
     * @return amounts The amount of each token used in the swap.
     */
    function uniswapV2SwapExactInput(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address receiver
    ) external payable returns (uint256[] memory amounts);

    /**
     * @notice Given an exact amount of output tokens, swaps them using the least possible amount of input tokens.
     * @param factory The address of the Uniswap V2 factory.
     * @param amountOut The amount of the output token to swap.
     * @param amountInMax The maximum amount of the input token to spend. Reverts if greater.
     * @param path The list of tokens to swap against.
     * @param receiver The address to receive the output tokens.
     * @return amounts The amount of each token used in the swap.
     */
    function uniswapV2SwapExactOutput(
        address factory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address receiver
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Constants
 * @author Hysland Finance
 * @notice A library of constant values.
 */
library Constants {
    /// @notice Used for identifying cases when this contract's balance of a token is to be used.
    uint256 internal constant CONTRACT_BALANCE = type(uint256).max;

    /// @notice Used as a flag for identifying msg.sender, saves gas by sending more 0 bytes.
    address internal constant MSG_SENDER = address(1);

    /// @notice Used as a flag for identifying address(this), saves gas by sending more 0 bytes.
    address internal constant ADDRESS_THIS = address(2);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IUniswapV2Factory } from  "./../../../interfaces/external/uniswap/v2/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from  "./../../../interfaces/external/uniswap/v2/IUniswapV2Pair.sol";


library UniswapV2Library {

    // returns true if the tokens are already sorted
    // also performs safety checks
    function areTokensSorted(address tokenA, address tokenB) internal pure returns (bool sorted) {
        require(tokenA != tokenB, "UniswapV2Lib: identical addrs");
        if(tokenA < tokenB) {
            require(tokenA != address(0), "UniswapV2Lib: zero address");
            return true;
        } else {
            require(tokenB != address(0), "UniswapV2Lib: zero address");
            return false;
        }
    }

    // fetches and sorts the reserves for a pair
    function getReservesFromFactory(address factory, address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        bool sorted = areTokensSorted(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = sorted ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // fetches and sorts the reserves for a pair
    function getReservesFromPair(address pair, address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        bool sorted = areTokensSorted(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = sorted ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Lib: insuff amount");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Lib: insuff liq");
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Lib: insuff input");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Lib: insuff liq");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Lib: insuff output");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Lib: insuff liq");
        uint256 numerator = (reserveIn * amountOut) * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Lib: invalid path");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; ) {
            (uint256 reserveIn, uint256 reserveOut) = getReservesFromFactory(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            unchecked { i++; }
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Lib: invalid path");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReservesFromFactory(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}