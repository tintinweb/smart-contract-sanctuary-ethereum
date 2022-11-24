// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../libraries/TokenHelper.sol";
import "../libraries/math/Math.sol";
import "../libraries/Errors.sol";

struct BulkSellerState {
    uint256 rateTokenToSy;
    uint256 rateSyToToken;
    uint256 totalToken;
    uint256 totalSy;
    uint256 feeRate;
}

library BulkSellerMathCore {
    using Math for uint256;

    function swapExactTokenForSy(BulkSellerState memory state, uint256 netTokenIn)
        internal
        pure
        returns (uint256 netSyOut)
    {
        netSyOut = calcSwapExactTokenForSy(state, netTokenIn);
        state.totalToken += netTokenIn;
        state.totalSy -= netSyOut;
    }

    function swapExactSyForToken(BulkSellerState memory state, uint256 netSyIn)
        internal
        pure
        returns (uint256 netTokenOut)
    {
        netTokenOut = calcSwapExactSyForToken(state, netSyIn);
        state.totalSy += netSyIn;
        state.totalToken -= netTokenOut;
    }

    function calcSwapExactTokenForSy(BulkSellerState memory state, uint256 netTokenIn)
        internal
        pure
        returns (uint256 netSyOut)
    {
        uint256 postFeeRate = state.rateTokenToSy.mulDown(Math.ONE - state.feeRate);
        assert(postFeeRate != 0);

        netSyOut = netTokenIn.mulDown(postFeeRate);
        if (netSyOut > state.totalSy)
            revert Errors.BulkInsufficientSyForTrade(state.totalSy, netSyOut);
    }

    function calcSwapExactSyForToken(BulkSellerState memory state, uint256 netSyIn)
        internal
        pure
        returns (uint256 netTokenOut)
    {
        uint256 postFeeRate = state.rateSyToToken.mulDown(Math.ONE - state.feeRate);
        assert(postFeeRate != 0);

        netTokenOut = netSyIn.mulDown(postFeeRate);
        if (netTokenOut > state.totalToken)
            revert Errors.BulkInsufficientTokenForTrade(state.totalToken, netTokenOut);
    }

    function getTokenProp(BulkSellerState memory state) internal pure returns (uint256) {
        uint256 totalToken = state.totalToken;
        uint256 totalTokenFromSy = state.totalSy.mulDown(state.rateSyToToken);
        return totalToken.divDown(totalToken + totalTokenFromSy);
    }

    function getReBalanceParams(BulkSellerState memory state, uint256 targetTokenProp)
        internal
        pure
        returns (uint256 netTokenToDeposit, uint256 netSyToRedeem)
    {
        uint256 currentTokenProp = getTokenProp(state);

        if (currentTokenProp > targetTokenProp) {
            netTokenToDeposit = state
                .totalToken
                .mulDown(currentTokenProp - targetTokenProp)
                .divDown(currentTokenProp);
        } else {
            uint256 currentSyProp = Math.ONE - currentTokenProp;
            netSyToRedeem = state.totalSy.mulDown(targetTokenProp - currentTokenProp).divDown(
                currentSyProp
            );
        }
    }

    function reBalanceTokenToSy(
        BulkSellerState memory state,
        uint256 netTokenToDeposit,
        uint256 netSyFromToken,
        uint256 maxDiff
    ) internal pure {
        uint256 rate = netSyFromToken.divDown(netTokenToDeposit);

        if (!Math.isAApproxB(rate, state.rateTokenToSy, maxDiff))
            revert Errors.BulkBadRateTokenToSy(rate, state.rateTokenToSy, maxDiff);

        state.totalToken -= netTokenToDeposit;
        state.totalSy += netSyFromToken;
    }

    function reBalanceSyToToken(
        BulkSellerState memory state,
        uint256 netSyToRedeem,
        uint256 netTokenFromSy,
        uint256 maxDiff
    ) internal pure {
        uint256 rate = netTokenFromSy.divDown(netSyToRedeem);

        if (!Math.isAApproxB(rate, state.rateSyToToken, maxDiff))
            revert Errors.BulkBadRateSyToToken(rate, state.rateSyToToken, maxDiff);

        state.totalToken += netTokenFromSy;
        state.totalSy -= netSyToRedeem;
    }

    function setRate(
        BulkSellerState memory state,
        uint256 rateSyToToken,
        uint256 rateTokenToSy,
        uint256 maxDiff
    ) internal pure {
        if (
            state.rateTokenToSy != 0 &&
            !Math.isAApproxB(rateTokenToSy, state.rateTokenToSy, maxDiff)
        ) {
            revert Errors.BulkBadRateTokenToSy(rateTokenToSy, state.rateTokenToSy, maxDiff);
        }

        if (
            state.rateSyToToken != 0 &&
            !Math.isAApproxB(rateSyToToken, state.rateSyToToken, maxDiff)
        ) {
            revert Errors.BulkBadRateSyToToken(rateSyToToken, state.rateSyToToken, maxDiff);
        }

        state.rateTokenToSy = rateTokenToSy;
        state.rateSyToToken = rateSyToToken;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// Adapted from UniswapV3's Oracle

library Errors {
    // BulkSeller
    error BulkInsufficientSyForTrade(uint256 currentAmount, uint256 requiredAmount);
    error BulkInsufficientTokenForTrade(uint256 currentAmount, uint256 requiredAmount);
    error BulkInSufficientSyOut(uint256 actualSyOut, uint256 requiredSyOut);
    error BulkInSufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);
    error BulkInsufficientSyReceived(uint256 actualBalance, uint256 requiredBalance);
    error BulkNotMaintainer();
    error BulkNotAdmin();
    error BulkSellerAlreadyExisted(address token, address SY, address bulk);
    error BulkSellerInvalidToken(address token, address SY);
    error BulkBadRateTokenToSy(uint256 actualRate, uint256 currentRate, uint256 eps);
    error BulkBadRateSyToToken(uint256 actualRate, uint256 currentRate, uint256 eps);

    // APPROX
    error ApproxFail();
    error ApproxParamsInvalid(uint256 guessMin, uint256 guessMax, uint256 eps);
    error ApproxBinarySearchInputInvalid(
        uint256 approxGuessMin,
        uint256 approxGuessMax,
        uint256 minGuessMin,
        uint256 maxGuessMax
    );

    // MARKET + MARKET MATH CORE
    error MarketExpired();
    error MarketZeroAmountsInput();
    error MarketZeroAmountsOutput();
    error MarketZeroLnImpliedRate();
    error MarketInsufficientPtForTrade(int256 currentAmount, int256 requiredAmount);
    error MarketInsufficientPtReceived(uint256 actualBalance, uint256 requiredBalance);
    error MarketInsufficientSyReceived(uint256 actualBalance, uint256 requiredBalance);
    error MarketZeroTotalPtOrTotalAsset(int256 totalPt, int256 totalAsset);
    error MarketExchangeRateBelowOne(int256 exchangeRate);
    error MarketProportionMustNotEqualOne();
    error MarketRateScalarBelowZero(int256 rateScalar);
    error MarketScalarRootBelowZero(int256 scalarRoot);
    error MarketProportionTooHigh(int256 proportion, int256 maxProportion);

    error OracleUninitialized();
    error OracleTargetTooOld(uint32 target, uint32 oldest);
    error OracleZeroCardinality();

    error MarketFactoryExpiredPt();
    error MarketFactoryInvalidPt();
    error MarketFactoryMarketExists();

    error MarketFactoryLnFeeRateRootTooHigh(uint80 lnFeeRateRoot, uint256 maxLnFeeRateRoot);
    error MarketFactoryReserveFeePercentTooHigh(
        uint8 reserveFeePercent,
        uint8 maxReserveFeePercent
    );
    error MarketFactoryZeroTreasury();
    error MarketFactoryInitialAnchorTooLow(int256 initialAnchor, int256 minInitialAnchor);

    // ROUTER
    error RouterInsufficientLpOut(uint256 actualLpOut, uint256 requiredLpOut);
    error RouterInsufficientSyOut(uint256 actualSyOut, uint256 requiredSyOut);
    error RouterInsufficientPtOut(uint256 actualPtOut, uint256 requiredPtOut);
    error RouterInsufficientYtOut(uint256 actualYtOut, uint256 requiredYtOut);
    error RouterInsufficientPYOut(uint256 actualPYOut, uint256 requiredPYOut);
    error RouterInsufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);
    error RouterExceededLimitSyIn(uint256 actualSyIn, uint256 limitSyIn);
    error RouterExceededLimitPtIn(uint256 actualPtIn, uint256 limitPtIn);
    error RouterExceededLimitYtIn(uint256 actualYtIn, uint256 limitYtIn);
    error RouterInsufficientSyRepay(uint256 actualSyRepay, uint256 requiredSyRepay);
    error RouterInsufficientPtRepay(uint256 actualPtRepay, uint256 requiredPtRepay);
    error RouterNotAllSyUsed(uint256 netSyDesired, uint256 netSyUsed);

    error RouterTimeRangeZero();
    error RouterCallbackNotPendleMarket(address caller);
    error RouterInvalidAction(bytes4 selector);

    error RouterKyberSwapDataZero();

    // YIELD CONTRACT
    error YCExpired();
    error YCNotExpired();
    error YieldContractInsufficientSy(uint256 actualSy, uint256 requiredSy);
    error YCNothingToRedeem();
    error YCPostExpiryDataNotSet();
    error YCNoFloatingSy();

    // YieldFactory
    error YCFactoryInvalidExpiry();
    error YCFactoryYieldContractExisted();
    error YCFactoryZeroExpiryDivisor();
    error YCFactoryZeroTreasury();
    error YCFactoryInterestFeeRateTooHigh(uint256 interestFeeRate, uint256 maxInterestFeeRate);
    error YCFactoryRewardFeeRateTooHigh(uint256 newRewardFeeRate, uint256 maxRewardFeeRate);

    // SY
    error SYInvalidTokenIn(address token);
    error SYInvalidTokenOut(address token);
    error SYZeroDeposit();
    error SYZeroRedeem();
    error SYInsufficientSharesOut(uint256 actualSharesOut, uint256 requiredSharesOut);
    error SYInsufficientTokenOut(uint256 actualTokenOut, uint256 requiredTokenOut);

    // SY-specific
    error SYQiTokenMintFailed(uint256 errCode);
    error SYQiTokenRedeemFailed(uint256 errCode);
    error SYQiTokenRedeemRewardsFailed(uint256 rewardAccruedType0, uint256 rewardAccruedType1);
    error SYQiTokenBorrowRateTooHigh(uint256 borrowRate, uint256 borrowRateMax);

    error SYCurveInvalidPid();
    error SYCurve3crvPoolNotFound();

    // Liquidity Mining
    error VCInactivePool(address pool);
    error VCPoolAlreadyActive(address pool);
    error VCZeroVePendle(address user);
    error VCExceededMaxWeight(uint256 totalWeight, uint256 maxWeight);
    error VCEpochNotFinalized(uint256 wTime);
    error VCPoolAlreadyAddAndRemoved(address pool);

    error VEInvalidNewExpiry(uint256 newExpiry);
    error VEExceededMaxLockTime();
    error VEInsufficientLockTime();
    error VENotAllowedReduceExpiry();
    error VEZeroAmountLocked();
    error VEPositionNotExpired();
    error VEZeroPosition();
    error VEZeroSlope(uint128 bias, uint128 slope);
    error VEReceiveOldSupply(uint256 msgTime);

    error GCNotPendleMarket(address caller);
    error GCNotVotingController(address caller);

    error InvalidWTime(uint256 wTime);
    error ExpiryInThePast(uint256 expiry);
    error ChainNotSupported(uint256 chainId);

    error FDCantFundFutureEpoch();
    error FDFactoryDistributorAlreadyExisted(address pool, address distributor);

    // Cross-Chain
    error MsgNotFromSendEndpoint(uint16 srcChainId, bytes path);
    error MsgNotFromReceiveEndpoint(address sender);
    error InsufficientFeeToSendMsg(uint256 currentFee, uint256 requiredFee);
    error ApproxDstExecutionGasNotSet();
    error InvalidRetryData();

    // GENERIC MSG
    error ArrayLengthMismatch();
    error ArrayEmpty();
    error ArrayOutOfBounds();
    error ZeroAddress();

    error OnlyLayerZeroEndpoint();
    error OnlyYT();
    error OnlyYCFactory();
    error OnlyWhitelisted();
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity 0.8.17;

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        unchecked {
            require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, "Invalid exponent");

            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, "out of bounds");
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that r`esult. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x < 2**255, "x out of bounds");
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            require(y < MILD_EXPONENT_BOUND, "y out of bounds");
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) *
                    y_int256 +
                    ((ln_36_x % ONE_18) * y_int256) /
                    ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
                "product out of bounds"
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

/* solhint-disable private-vars-leading-underscore, reason-string */

library Math {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    int256 internal constant IONE = 1e18; // 18 decimal places

    function subMax0(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a >= b ? a - b : 0);
        }
    }

    function subNoNeg(int256 a, int256 b) internal pure returns (int256) {
        require(a >= b, "negative");
        return a - b; // no unchecked since if b is very negative, a - b might overflow
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        unchecked {
            return product / ONE;
        }
    }

    function mulDown(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        unchecked {
            return product / IONE;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 aInflated = a * ONE;
        unchecked {
            return aInflated / b;
        }
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        int256 aInflated = a * IONE;
        unchecked {
            return aInflated / b;
        }
    }

    function rawDivUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }

    // @author Uniswap
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x > 0 ? x : -x);
    }

    function neg(int256 x) internal pure returns (int256) {
        return x * (-1);
    }

    function neg(uint256 x) internal pure returns (int256) {
        return Int(x) * (-1);
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y ? x : y);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return (x > y ? x : y);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x < y ? x : y);
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return (x < y ? x : y);
    }

    /*///////////////////////////////////////////////////////////////
                               SIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Int(uint256 x) internal pure returns (int256) {
        require(x <= uint256(type(int256).max));
        return int256(x);
    }

    function Int128(int256 x) internal pure returns (int128) {
        require(type(int128).min <= x && x <= type(int128).max);
        return int128(x);
    }

    function Int128(uint256 x) internal pure returns (int128) {
        return Int128(Int(x));
    }

    /*///////////////////////////////////////////////////////////////
                               UNSIGNED CASTS
    //////////////////////////////////////////////////////////////*/

    function Uint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function Uint32(uint256 x) internal pure returns (uint32) {
        require(x <= type(uint32).max);
        return uint32(x);
    }

    function Uint112(uint256 x) internal pure returns (uint112) {
        require(x <= type(uint112).max);
        return uint112(x);
    }

    function Uint96(uint256 x) internal pure returns (uint96) {
        require(x <= type(uint96).max);
        return uint96(x);
    }

    function Uint128(uint256 x) internal pure returns (uint128) {
        require(x <= type(uint128).max);
        return uint128(x);
    }

    function isAApproxB(
        uint256 a,
        uint256 b,
        uint256 eps
    ) internal pure returns (bool) {
        return mulDown(b, ONE - eps) <= a && a <= mulDown(b, ONE + eps);
    }

    function isAGreaterApproxB(
        uint256 a,
        uint256 b,
        uint256 eps
    ) internal pure returns (bool) {
        return a >= b && a <= mulDown(b, ONE + eps);
    }

    function isASmallerApproxB(
        uint256 a,
        uint256 b,
        uint256 eps
    ) internal pure returns (bool) {
        return a <= b && a >= mulDown(b, ONE - eps);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library MiniHelpers {
    function isCurrentlyExpired(uint256 expiry) internal view returns (bool) {
        return (expiry <= block.timestamp);
    }

    function isExpired(uint256 expiry, uint256 blockTime) internal pure returns (bool) {
        return (expiry <= blockTime);
    }

    function isTimeInThePast(uint256 timestamp) internal view returns (bool) {
        return (timestamp <= block.timestamp); // same definition as isCurrentlyExpired
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TokenHelper {
    using SafeERC20 for IERC20;
    address internal constant NATIVE = address(0);
    uint256 internal constant LOWER_BOUND_APPROVAL = type(uint96).max / 2; // some tokens use 96 bits for approval

    function _transferIn(
        address token,
        address from,
        uint256 amount
    ) internal {
        if (token == NATIVE) require(msg.value == amount, "eth mismatch");
        else if (amount != 0) IERC20(token).safeTransferFrom(from, address(this), amount);
    }

    function _transferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount != 0) token.safeTransferFrom(from, to, amount);
    }

    function _transferOut(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) return;
        if (token == NATIVE) {
            (bool success, ) = to.call{ value: amount }("");
            require(success, "eth send failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function _transferOut(
        address[] memory tokens,
        address to,
        uint256[] memory amounts
    ) internal {
        uint256 numTokens = tokens.length;
        require(numTokens == amounts.length, "length mismatch");
        for (uint256 i = 0; i < numTokens; ) {
            _transferOut(tokens[i], to, amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    function _selfBalance(address token) internal view returns (uint256) {
        return (token == NATIVE) ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    function _selfBalance(IERC20 token) internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev PLS PAY ATTENTION to tokens that requires the approval to be set to 0 before changing it
    function _safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Safe Approve");
    }

    function _safeApproveInf(address token, address to) internal {
        if (token == NATIVE) return;
        if (IERC20(token).allowance(address(this), to) < LOWER_BOUND_APPROVAL) {
            _safeApprove(token, to, 0);
            _safeApprove(token, to, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../libraries/math/Math.sol";
import "../libraries/math/LogExpMath.sol";

import "../StandardizedYield/PYIndex.sol";
import "../libraries/MiniHelpers.sol";
import "../libraries/Errors.sol";

struct MarketState {
    int256 totalPt;
    int256 totalSy;
    int256 totalLp;
    address treasury;
    /// immutable variables ///
    int256 scalarRoot;
    uint256 expiry;
    /// fee data ///
    uint256 lnFeeRateRoot;
    uint256 reserveFeePercent; // base 100
    /// last trade data ///
    uint256 lastLnImpliedRate;
}

// params that are expensive to compute, therefore we pre-compute them
struct MarketPreCompute {
    int256 rateScalar;
    int256 totalAsset;
    int256 rateAnchor;
    int256 feeRate;
}

// solhint-disable ordering
library MarketMathCore {
    using Math for uint256;
    using Math for int256;
    using LogExpMath for int256;
    using PYIndexLib for PYIndex;

    int256 internal constant MINIMUM_LIQUIDITY = 10**3;
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    uint256 internal constant DAY = 86400;
    uint256 internal constant IMPLIED_RATE_TIME = 365 * DAY;

    int256 internal constant MAX_MARKET_PROPORTION = (1e18 * 96) / 100;

    using Math for uint256;
    using Math for int256;

    /*///////////////////////////////////////////////////////////////
                UINT FUNCTIONS TO PROXY TO CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidity(
        MarketState memory market,
        uint256 syDesired,
        uint256 ptDesired,
        uint256 blockTime
    )
        internal
        pure
        returns (
            uint256 lpToReserve,
            uint256 lpToAccount,
            uint256 syUsed,
            uint256 ptUsed
        )
    {
        (
            int256 _lpToReserve,
            int256 _lpToAccount,
            int256 _syUsed,
            int256 _ptUsed
        ) = addLiquidityCore(market, syDesired.Int(), ptDesired.Int(), blockTime);

        lpToReserve = _lpToReserve.Uint();
        lpToAccount = _lpToAccount.Uint();
        syUsed = _syUsed.Uint();
        ptUsed = _ptUsed.Uint();
    }

    function removeLiquidity(MarketState memory market, uint256 lpToRemove)
        internal
        pure
        returns (uint256 netSyToAccount, uint256 netPtToAccount)
    {
        (int256 _syToAccount, int256 _ptToAccount) = removeLiquidityCore(market, lpToRemove.Int());

        netSyToAccount = _syToAccount.Uint();
        netPtToAccount = _ptToAccount.Uint();
    }

    function swapExactPtForSy(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToMarket,
        uint256 blockTime
    )
        internal
        pure
        returns (
            uint256 netSyToAccount,
            uint256 netSyFee,
            uint256 netSyToReserve
        )
    {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToMarket.neg(),
            blockTime
        );

        netSyToAccount = _netSyToAccount.Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    function swapSyForExactPt(
        MarketState memory market,
        PYIndex index,
        uint256 exactPtToAccount,
        uint256 blockTime
    )
        internal
        pure
        returns (
            uint256 netSyToMarket,
            uint256 netSyFee,
            uint256 netSyToReserve
        )
    {
        (int256 _netSyToAccount, int256 _netSyFee, int256 _netSyToReserve) = executeTradeCore(
            market,
            index,
            exactPtToAccount.Int(),
            blockTime
        );

        netSyToMarket = _netSyToAccount.neg().Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    /*///////////////////////////////////////////////////////////////
                    CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addLiquidityCore(
        MarketState memory market,
        int256 syDesired,
        int256 ptDesired,
        uint256 blockTime
    )
        internal
        pure
        returns (
            int256 lpToReserve,
            int256 lpToAccount,
            int256 syUsed,
            int256 ptUsed
        )
    {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (syDesired == 0 || ptDesired == 0) revert Errors.MarketZeroAmountsInput();
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        if (market.totalLp == 0) {
            lpToAccount = Math.sqrt((syDesired * ptDesired).Uint()).Int() - MINIMUM_LIQUIDITY;
            lpToReserve = MINIMUM_LIQUIDITY;
            syUsed = syDesired;
            ptUsed = ptDesired;
        } else {
            int256 netLpByPt = (ptDesired * market.totalLp) / market.totalPt;
            int256 netLpBySy = (syDesired * market.totalLp) / market.totalSy;
            if (netLpByPt < netLpBySy) {
                lpToAccount = netLpByPt;
                ptUsed = ptDesired;
                syUsed = (market.totalSy * lpToAccount) / market.totalLp;
            } else {
                lpToAccount = netLpBySy;
                syUsed = syDesired;
                ptUsed = (market.totalPt * lpToAccount) / market.totalLp;
            }
        }

        if (lpToAccount <= 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalSy += syUsed;
        market.totalPt += ptUsed;
        market.totalLp += lpToAccount + lpToReserve;
    }

    function removeLiquidityCore(MarketState memory market, int256 lpToRemove)
        internal
        pure
        returns (int256 netSyToAccount, int256 netPtToAccount)
    {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (lpToRemove == 0) revert Errors.MarketZeroAmountsInput();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        netSyToAccount = (lpToRemove * market.totalSy) / market.totalLp;
        netPtToAccount = (lpToRemove * market.totalPt) / market.totalLp;

        if (netSyToAccount == 0 && netPtToAccount == 0) revert Errors.MarketZeroAmountsOutput();

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.totalLp = market.totalLp.subNoNeg(lpToRemove);
        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount);
    }

    function executeTradeCore(
        MarketState memory market,
        PYIndex index,
        int256 netPtToAccount,
        uint256 blockTime
    )
        internal
        pure
        returns (
            int256 netSyToAccount,
            int256 netSyFee,
            int256 netSyToReserve
        )
    {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();
        if (market.totalPt <= netPtToAccount)
            revert Errors.MarketInsufficientPtForTrade(market.totalPt, netPtToAccount);

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        MarketPreCompute memory comp = getMarketPreCompute(market, index, blockTime);

        (netSyToAccount, netSyFee, netSyToReserve) = calcTrade(
            market,
            comp,
            index,
            netPtToAccount
        );

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        _setNewMarketStateTrade(
            market,
            comp,
            index,
            netPtToAccount,
            netSyToAccount,
            netSyToReserve,
            blockTime
        );
    }

    function getMarketPreCompute(
        MarketState memory market,
        PYIndex index,
        uint256 blockTime
    ) internal pure returns (MarketPreCompute memory res) {
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        uint256 timeToExpiry = market.expiry - blockTime;

        res.rateScalar = _getRateScalar(market, timeToExpiry);
        res.totalAsset = index.syToAsset(market.totalSy);

        if (market.totalPt == 0 || res.totalAsset == 0)
            revert Errors.MarketZeroTotalPtOrTotalAsset(market.totalPt, res.totalAsset);

        res.rateAnchor = _getRateAnchor(
            market.totalPt,
            market.lastLnImpliedRate,
            res.totalAsset,
            res.rateScalar,
            timeToExpiry
        );
        res.feeRate = _getExchangeRateFromImpliedRate(market.lnFeeRateRoot, timeToExpiry);
    }

    function calcTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount
    )
        internal
        pure
        returns (
            int256 netSyToAccount,
            int256 netSyFee,
            int256 netSyToReserve
        )
    {
        int256 preFeeExchangeRate = _getExchangeRate(
            market.totalPt,
            comp.totalAsset,
            comp.rateScalar,
            comp.rateAnchor,
            netPtToAccount
        );

        int256 preFeeAssetToAccount = netPtToAccount.divDown(preFeeExchangeRate).neg();
        int256 fee = comp.feeRate;

        if (netPtToAccount > 0) {
            int256 postFeeExchangeRate = preFeeExchangeRate.divDown(fee);
            if (postFeeExchangeRate < Math.IONE)
                revert Errors.MarketExchangeRateBelowOne(postFeeExchangeRate);

            fee = preFeeAssetToAccount.mulDown(Math.IONE - fee);
        } else {
            fee = ((preFeeAssetToAccount * (Math.IONE - fee)) / fee).neg();
        }

        int256 netAssetToReserve = (fee * market.reserveFeePercent.Int()) / PERCENTAGE_DECIMALS;
        int256 netAssetToAccount = preFeeAssetToAccount - fee;

        netSyToAccount = netAssetToAccount < 0
            ? index.assetToSyUp(netAssetToAccount)
            : index.assetToSy(netAssetToAccount);
        netSyFee = index.assetToSy(fee);
        netSyToReserve = index.assetToSy(netAssetToReserve);
    }

    function _setNewMarketStateTrade(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        int256 netPtToAccount,
        int256 netSyToAccount,
        int256 netSyToReserve,
        uint256 blockTime
    ) internal pure {
        uint256 timeToExpiry = market.expiry - blockTime;

        market.totalPt = market.totalPt.subNoNeg(netPtToAccount);
        market.totalSy = market.totalSy.subNoNeg(netSyToAccount + netSyToReserve);

        market.lastLnImpliedRate = _getLnImpliedRate(
            market.totalPt,
            index.syToAsset(market.totalSy),
            comp.rateScalar,
            comp.rateAnchor,
            timeToExpiry
        );

        if (market.lastLnImpliedRate == 0) revert Errors.MarketZeroLnImpliedRate();
    }

    function _getRateAnchor(
        int256 totalPt,
        uint256 lastLnImpliedRate,
        int256 totalAsset,
        int256 rateScalar,
        uint256 timeToExpiry
    ) internal pure returns (int256 rateAnchor) {
        int256 newExchangeRate = _getExchangeRateFromImpliedRate(lastLnImpliedRate, timeToExpiry);

        if (newExchangeRate < Math.IONE) revert Errors.MarketExchangeRateBelowOne(newExchangeRate);

        {
            int256 proportion = totalPt.divDown(totalPt + totalAsset);

            int256 lnProportion = _logProportion(proportion);

            rateAnchor = newExchangeRate - lnProportion.divDown(rateScalar);
        }
    }

    /// @notice Calculates the current market implied rate.
    /// @return lnImpliedRate the implied rate
    function _getLnImpliedRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        uint256 timeToExpiry
    ) internal pure returns (uint256 lnImpliedRate) {
        // This will check for exchange rates < Math.IONE
        int256 exchangeRate = _getExchangeRate(totalPt, totalAsset, rateScalar, rateAnchor, 0);

        // exchangeRate >= 1 so its ln >= 0
        uint256 lnRate = exchangeRate.ln().Uint();

        lnImpliedRate = (lnRate * IMPLIED_RATE_TIME) / timeToExpiry;
    }

    /// @notice Converts an implied rate to an exchange rate given a time to expiry. The
    /// formula is E = e^rt
    function _getExchangeRateFromImpliedRate(uint256 lnImpliedRate, uint256 timeToExpiry)
        internal
        pure
        returns (int256 exchangeRate)
    {
        uint256 rt = (lnImpliedRate * timeToExpiry) / IMPLIED_RATE_TIME;

        exchangeRate = LogExpMath.exp(rt.Int());
    }

    function _getExchangeRate(
        int256 totalPt,
        int256 totalAsset,
        int256 rateScalar,
        int256 rateAnchor,
        int256 netPtToAccount
    ) internal pure returns (int256 exchangeRate) {
        int256 numerator = totalPt.subNoNeg(netPtToAccount);

        int256 proportion = (numerator.divDown(totalPt + totalAsset));

        if (proportion > MAX_MARKET_PROPORTION)
            revert Errors.MarketProportionTooHigh(proportion, MAX_MARKET_PROPORTION);

        int256 lnProportion = _logProportion(proportion);

        exchangeRate = lnProportion.divDown(rateScalar) + rateAnchor;

        if (exchangeRate < Math.IONE) revert Errors.MarketExchangeRateBelowOne(exchangeRate);
    }

    function _logProportion(int256 proportion) internal pure returns (int256 res) {
        if (proportion == Math.IONE) revert Errors.MarketProportionMustNotEqualOne();

        int256 logitP = proportion.divDown(Math.IONE - proportion);

        res = logitP.ln();
    }

    function _getRateScalar(MarketState memory market, uint256 timeToExpiry)
        internal
        pure
        returns (int256 rateScalar)
    {
        rateScalar = (market.scalarRoot * IMPLIED_RATE_TIME.Int()) / timeToExpiry.Int();
        if (rateScalar <= 0) revert Errors.MarketRateScalarBelowZero(rateScalar);
    }

    function setInitialLnImpliedRate(
        MarketState memory market,
        PYIndex index,
        int256 initialAnchor,
        uint256 blockTime
    ) internal pure {
        /// ------------------------------------------------------------
        /// CHECKS
        /// ------------------------------------------------------------
        if (MiniHelpers.isExpired(market.expiry, blockTime)) revert Errors.MarketExpired();

        /// ------------------------------------------------------------
        /// MATH
        /// ------------------------------------------------------------
        int256 totalAsset = index.syToAsset(market.totalSy);
        uint256 timeToExpiry = market.expiry - blockTime;
        int256 rateScalar = _getRateScalar(market, timeToExpiry);

        /// ------------------------------------------------------------
        /// WRITE
        /// ------------------------------------------------------------
        market.lastLnImpliedRate = _getLnImpliedRate(
            market.totalPt,
            totalAsset,
            rateScalar,
            initialAnchor,
            timeToExpiry
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import "../../interfaces/IPYieldToken.sol";
import "../../interfaces/IPPrincipalToken.sol";

import "./SYUtils.sol";
import "../libraries/math/Math.sol";

type PYIndex is uint256;

library PYIndexLib {
    using Math for uint256;
    using Math for int256;

    function newIndex(IPYieldToken YT) internal returns (PYIndex) {
        return PYIndex.wrap(YT.pyIndexCurrent());
    }

    function syToAsset(PYIndex index, uint256 syAmount)
        internal
        pure
        returns (uint256)
    {
        return SYUtils.syToAsset(PYIndex.unwrap(index), syAmount);
    }

    function assetToSy(PYIndex index, uint256 assetAmount)
        internal
        pure
        returns (uint256)
    {
        return SYUtils.assetToSy(PYIndex.unwrap(index), assetAmount);
    }

    function assetToSyUp(PYIndex index, uint256 assetAmount)
        internal
        pure
        returns (uint256)
    {
        return SYUtils.assetToSyUp(PYIndex.unwrap(index), assetAmount);
    }

    function syToAssetUp(PYIndex index, uint256 syAmount)
        internal
        pure
        returns (uint256)
    {
        uint256 _index = PYIndex.unwrap(index);
        return SYUtils.syToAssetUp(_index, syAmount);
    }

    function syToAsset(PYIndex index, int256 syAmount)
        internal
        pure
        returns (int256)
    {
        int256 sign = syAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.syToAsset(PYIndex.unwrap(index), syAmount.abs())).Int();
    }

    function assetToSy(PYIndex index, int256 assetAmount)
        internal
        pure
        returns (int256)
    {
        int256 sign = assetAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.assetToSy(PYIndex.unwrap(index), assetAmount.abs())).Int();
    }

    function assetToSyUp(PYIndex index, int256 assetAmount)
        internal
        pure
        returns (int256)
    {
        int256 sign = assetAmount < 0 ? int256(-1) : int256(1);
        return sign * (SYUtils.assetToSyUp(PYIndex.unwrap(index), assetAmount.abs())).Int();
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library SYUtils {
    uint256 internal constant ONE = 1e18;

    function syToAsset(uint256 exchangeRate, uint256 syAmount) internal pure returns (uint256) {
        return (syAmount * exchangeRate) / ONE;
    }

    function syToAssetUp(uint256 exchangeRate, uint256 syAmount) internal pure returns (uint256) {
        return (syAmount * exchangeRate + ONE - 1) / ONE;
    }

    function assetToSy(uint256 exchangeRate, uint256 assetAmount) internal pure returns (uint256) {
        return (assetAmount * ONE) / exchangeRate;
    }

    function assetToSyUp(uint256 exchangeRate, uint256 assetAmount)
        internal
        pure
        returns (uint256)
    {
        return (assetAmount * ONE + exchangeRate - 1) / exchangeRate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../router/base/MarketApproxLib.sol";
import "../router/kyberswap/KyberSwapHelper.sol";

interface IPActionSwapYT {
    event SwapYtAndSy(
        address indexed caller,
        address indexed market,
        address indexed receiver,
        int256 netYtToAccount,
        int256 netSyToAccount
    );

    event SwapYtAndToken(
        address indexed caller,
        address indexed market,
        address indexed token,
        address receiver,
        int256 netYtToAccount,
        int256 netTokenToAccount
    );

    function swapExactSyForYt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minYtOut,
        ApproxParams memory guessYtOut
    ) external returns (uint256 netYtOut, uint256 netSyFee);

    function swapExactYtForSy(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minSyOut
    ) external returns (uint256 netSyOut, uint256 netSyFee);

    function swapSyForExactYt(
        address receiver,
        address market,
        uint256 exactYtOut,
        uint256 maxSyIn
    ) external returns (uint256 netSyIn, uint256 netSyFee);

    function swapYtForExactSy(
        address receiver,
        address market,
        uint256 exactSyOut,
        uint256 maxYtIn,
        ApproxParams memory guessYtIn
    ) external returns (uint256 netYtIn, uint256 netSyFee);

    function swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams memory guessYtOut,
        TokenInput calldata input
    ) external payable returns (uint256 netYtOut, uint256 netSyFee);

    function swapExactYtForToken(
        address receiver,
        address market,
        uint256 netYtIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../core/BulkSeller/BulkSellerMathCore.sol";

interface IPBulkSeller {
    event SwapExactTokenForSy(address receiver, uint256 netTokenIn, uint256 netSyOut);
    event SwapExactSyForToken(address receiver, uint256 netSyIn, uint256 netTokenOut);
    event RateUpdated(
        uint256 newRateTokenToSy,
        uint256 newRateSyToToken,
        uint256 oldRateTokenToSy,
        uint256 oldRateSyToToken
    );
    event ReBalanceTokenToSy(
        uint256 netTokenDeposit,
        uint256 netSyFromToken,
        uint256 newTokenProp,
        uint256 oldTokenProp
    );
    event ReBalanceSyToToken(
        uint256 netSyRedeem,
        uint256 netTokenFromSy,
        uint256 newTokenProp,
        uint256 oldTokenProp
    );
    event ReserveUpdated(uint256 totalToken, uint256 totalSy);
    event FeeRateUpdated(uint256 newFeeRate, uint256 oldFeeRate);

    function swapExactTokenForSy(
        address receiver,
        uint256 netTokenIn,
        uint256 minSyOut
    ) external payable returns (uint256 netSyOut);

    function swapExactSyForToken(
        address receiver,
        uint256 exactSyIn,
        uint256 minTokenOut,
        bool swapFromInternalBalance
    ) external returns (uint256 netTokenOut);

    function SY() external view returns (address);

    function token() external view returns (address);

    function readState() external view returns (BulkSellerState memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IPGauge {
    function totalActiveSupply() external view returns (uint256);

    function activeBalance(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IPInterestManagerYT {
    function userInterest(address user)
        external
        view
        returns (uint128 lastPYIndex, uint128 accruedInterest);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IPPrincipalToken.sol";
import "./IPYieldToken.sol";
import "./IStandardizedYield.sol";
import "./IPGauge.sol";
import "../core/Market/MarketMathCore.sol";

interface IPMarket is IERC20Metadata, IPGauge {
    event Mint(
        address indexed receiver,
        uint256 netLpMinted,
        uint256 netSyUsed,
        uint256 netPtUsed
    );

    event Burn(
        address indexed receiverSy,
        address indexed receiverPt,
        uint256 netLpBurned,
        uint256 netSyOut,
        uint256 netPtOut
    );

    event Swap(
        address indexed caller,
        address indexed receiver,
        int256 netPtOut,
        int256 netSyOut,
        uint256 netSyFee,
        uint256 netSyToReserve
    );

    event UpdateImpliedRate(uint256 indexed timestamp, uint256 lnLastImpliedRate);

    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    function mint(
        address receiver,
        uint256 netSyDesired,
        uint256 netPtDesired
    )
        external
        returns (
            uint256 netLpOut,
            uint256 netSyUsed,
            uint256 netPtUsed
        );

    function burn(
        address receiverSy,
        address receiverPt,
        uint256 netLpToBurn
    ) external returns (uint256 netSyOut, uint256 netPtOut);

    function swapExactPtForSy(
        address receiver,
        uint256 exactPtIn,
        bytes calldata data
    ) external returns (uint256 netSyOut, uint256 netSyFee);

    function swapSyForExactPt(
        address receiver,
        uint256 exactPtOut,
        bytes calldata data
    ) external returns (uint256 netSyIn, uint256 netSyFee);

    function redeemRewards(address user) external returns (uint256[] memory);

    function readState(address router) external view returns (MarketState memory market);

    function observe(uint32[] memory secondsAgos)
        external
        view
        returns (uint216[] memory lnImpliedRateCumulative);

    function increaseObservationsCardinalityNext(uint16 cardinalityNext) external;

    function readTokens()
        external
        view
        returns (
            IStandardizedYield _SY,
            IPPrincipalToken _PT,
            IPYieldToken _YT
        );

    function getRewardTokens() external view returns (address[] memory);

    function isExpired() external view returns (bool);

    function expiry() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPPrincipalToken is IERC20Metadata {
    function burnByYT(address user, uint256 amount) external;

    function mintByYT(address user, uint256 amount) external;

    function initialize(address _YT) external;

    function SY() external view returns (address);

    function YT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IRewardManager.sol";
import "./IPInterestManagerYT.sol";

interface IPYieldToken is IERC20Metadata, IRewardManager, IPInterestManagerYT {
    event NewInterestIndex(uint256 indexed newIndex);

    event Mint(
        address indexed caller,
        address indexed receiverPT,
        address indexed receiverYT,
        uint256 amountSyToMint,
        uint256 amountPYOut
    );

    event Burn(
        address indexed caller,
        address indexed receiver,
        uint256 amountPYToRedeem,
        uint256 amountSyOut
    );

    event RedeemRewards(address indexed user, uint256[] amountRewardsOut);

    event RedeemInterest(address indexed user, uint256 interestOut);

    event WithdrawFeeToTreasury(uint256[] amountRewardsOut, uint256 syOut);

    function mintPY(address receiverPT, address receiverYT) external returns (uint256 amountPYOut);

    function redeemPY(address receiver) external returns (uint256 amountSyOut);

    function redeemPYMulti(address[] calldata receivers, uint256[] calldata amountPYToRedeems)
        external
        returns (uint256[] memory amountSyOuts);

    function redeemDueInterestAndRewards(
        address user,
        bool redeemInterest,
        bool redeemRewards
    ) external returns (uint256 interestOut, uint256[] memory rewardsOut);

    function rewardIndexesCurrent() external returns (uint256[] memory);

    function pyIndexCurrent() external returns (uint256);

    function pyIndexStored() external view returns (uint256);

    function getRewardTokens() external view returns (address[] memory);

    function SY() external view returns (address);

    function PT() external view returns (address);

    function factory() external view returns (address);

    function expiry() external view returns (uint256);

    function isExpired() external view returns (bool);

    function doCacheIndexSameBlock() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IRewardManager {
    function userReward(address token, address user)
        external
        view
        returns (uint128 index, uint128 accrued);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IStandardizedYield is IERC20Metadata {
    /// @dev Emitted when any base tokens is deposited to mint shares
    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountDeposited,
        uint256 amountSyOut
    );

    /// @dev Emitted when any shares are redeemed for base tokens
    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed tokenOut,
        uint256 amountSyToRedeem,
        uint256 amountTokenOut
    );

    /// @dev check `assetInfo()` for more information
    enum AssetType {
        TOKEN,
        LIQUIDITY
    }

    /// @dev Emitted when (`user`) claims their rewards
    event ClaimRewards(address indexed user, address[] rewardTokens, uint256[] rewardAmounts);

    /**
     * @notice mints an amount of shares by depositing a base token.
     * @param receiver shares recipient address
     * @param tokenIn address of the base tokens to mint shares
     * @param amountTokenToDeposit amount of base tokens to be transferred from (`msg.sender`)
     * @param minSharesOut reverts if amount of shares minted is lower than this
     * @return amountSharesOut amount of shares minted
     * @dev Emits a {Deposit} event
     *
     * Requirements:
     * - (`baseTokenIn`) must be a valid base token.
     */
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut
    ) external payable returns (uint256 amountSharesOut);

    /**
     * @notice redeems an amount of base tokens by burning some shares
     * @param receiver recipient address
     * @param amountSharesToRedeem amount of shares to be burned
     * @param tokenOut address of the base token to be redeemed
     * @param minTokenOut reverts if amount of base token redeemed is lower than this
     * @param burnFromInternalBalance if true, burns from balance of `address(this)`, otherwise burns from `msg.sender`
     * @return amountTokenOut amount of base tokens redeemed
     * @dev Emits a {Redeem} event
     *
     * Requirements:
     * - (`tokenOut`) must be a valid base token.
     */
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external returns (uint256 amountTokenOut);

    /**
     * @notice exchangeRate * syBalance / 1e18 must return the asset balance of the account
     * @notice vice-versa, if a user uses some amount of tokens equivalent to X asset, the amount of sy
     he can mint must be X * exchangeRate / 1e18
     * @dev SYUtils's assetToSy & syToAsset should be used instead of raw multiplication
     & division
     */
    function exchangeRate() external view returns (uint256 res);

    /**
     * @notice claims reward for (`user`)
     * @param user the user receiving their rewards
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     * @dev
     * Emits a `ClaimRewards` event
     * See {getRewardTokens} for list of reward tokens
     */
    function claimRewards(address user) external returns (uint256[] memory rewardAmounts);

    /**
     * @notice get the amount of unclaimed rewards for (`user`)
     * @param user the user to check for
     * @return rewardAmounts an array of reward amounts in the same order as `getRewardTokens`
     */
    function accruedRewards(address user) external view returns (uint256[] memory rewardAmounts);

    function rewardIndexesCurrent() external returns (uint256[] memory indexes);

    function rewardIndexesStored() external view returns (uint256[] memory indexes);

    /**
     * @notice returns the list of reward token addresses
     */
    function getRewardTokens() external view returns (address[] memory);

    /**
     * @notice returns the address of the underlying yield token
     */
    function yieldToken() external view returns (address);

    /**
     * @notice returns all tokens that can mint this SY
     */
    function getTokensIn() external view returns (address[] memory res);

    /**
     * @notice returns all tokens that can be redeemed by this SY
     */
    function getTokensOut() external view returns (address[] memory res);

    function isValidTokenIn(address token) external view returns (bool);

    function isValidTokenOut(address token) external view returns (bool);

    function previewDeposit(address tokenIn, uint256 amountTokenToDeposit)
        external
        view
        returns (uint256 amountSharesOut);

    function previewRedeem(address tokenOut, uint256 amountSharesToRedeem)
        external
        view
        returns (uint256 amountTokenOut);

    /**
     * @notice This function contains information to interpret what the asset is
     * @return assetType the type of the asset (0 for ERC20 tokens, 1 for AMM liquidity tokens)
     * @return assetAddress the address of the asset
     * @return assetDecimals the decimals of the asset
     */
    function assetInfo()
        external
        view
        returns (
            AssetType assetType,
            address assetAddress,
            uint8 assetDecimals
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./base/ActionBaseMintRedeem.sol";
import "./base/CallbackHelper.sol";
import "../interfaces/IPActionSwapYT.sol";
import "../interfaces/IPMarket.sol";
import "../core/libraries/Errors.sol";

/// @dev All swap actions will revert if market is expired
contract ActionSwapYT is IPActionSwapYT, ActionBaseMintRedeem, CallbackHelper {
    using Math for uint256;
    using Math for int256;
    using MarketMathCore for MarketState;
    using MarketApproxPtInLib for MarketState;
    using MarketApproxPtOutLib for MarketState;
    using PYIndexLib for IPYieldToken;

    /// @dev since this contract will be proxied, it must not contains non-immutable variables
    constructor(address _kyberScalingLib)
        ActionBaseMintRedeem(_kyberScalingLib) //solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @notice swap exact SY to YT with the help of flashswaps & YT tokenization / redemption
     * @dev inner working of this function:
     - `exactSyIn` SY is transferred to YT contract
     - `market.swapExactPtForSy` is called, which will transfer more SY directly to YT contract &
       callback is invoked. Note that now we owe PT
     - in callback, all SY in YT contract is used to mint PT + YT, with all PT used to pay back the
       loan, and all YT transferred to the receiver
     * @param exactSyIn will always consume this amount of SY for as much YT as possible
     * @param guessYtOut approximation data for total YT output
     * @dev this function works in conjunction with ActionCallback
     */
    function swapExactSyForYt(
        address receiver,
        address market,
        uint256 exactSyIn,
        uint256 minYtOut,
        ApproxParams memory guessYtOut
    ) external returns (uint256 netYtOut, uint256 netSyFee) {
        (IStandardizedYield SY, , IPYieldToken YT) = IPMarket(market).readTokens();

        _transferFrom(IERC20(SY), msg.sender, address(YT), exactSyIn);

        (netYtOut, netSyFee) = _swapExactSyForYt(
            receiver,
            market,
            YT,
            exactSyIn,
            minYtOut,
            guessYtOut
        );

        emit SwapYtAndSy(msg.sender, market, receiver, netYtOut.Int(), exactSyIn.neg());
    }

    /**
     * @notice swap exact YT to SY with the help of flashswaps & YT tokenization / redemption
     * @dev inner working of this function:
     - `exactYtIn` YT is transferred to YT contract
     - `market.swapSyForExactPt` is called, which will transfer PT directly to YT contract &
       callback is invoked. Note that now we owe SY.
     - In callback, all PT + YT in YT contract is used to redeem SY. A portion of SY is used to
       payback the loan, the rest is transferred to the `receiver`
     * @param exactYtIn will consume exactly this much YT for as much SY as possible
     * @dev this function works in conjunction with ActionCallback
     */
    function swapExactYtForSy(
        address receiver,
        address market,
        uint256 exactYtIn,
        uint256 minSyOut
    ) external returns (uint256 netSyOut, uint256 netSyFee) {
        (IStandardizedYield SY, , IPYieldToken YT) = IPMarket(market).readTokens();

        _transferFrom(IERC20(YT), msg.sender, address(YT), exactYtIn);

        (netSyOut, netSyFee) = _swapExactYtForSy(receiver, market, SY, YT, exactYtIn, minSyOut);

        emit SwapYtAndSy(msg.sender, market, receiver, exactYtIn.neg(), netSyOut.Int());
    }

    /**
     * @notice swap SY to exact YT with the help of flashswaps & YT tokenization / redemption
     * @dev inner working of this function:
     - `market.swapExactPtForSy` is called, which will transfer SY directly to YT contract &
       callback is invoked. Note that now we owe PT
     - In callback, we will pull in more SY as needed from caller & mint all SY to PT + YT. PT is
       then used to payback the loan, while YT is transferred to `receiver`
     * @param exactYtOut will output exactly this amount of YT, no approximation is used
     * @dev this function works in conjunction with ActionCallback
     */
    function swapSyForExactYt(
        address receiver,
        address market,
        uint256 exactYtOut,
        uint256 maxSyIn
    ) external returns (uint256 netSyIn, uint256 netSyFee) {
        (IStandardizedYield SY, , IPYieldToken YT) = IPMarket(market).readTokens();

        uint256 preSyBalance = SY.balanceOf(msg.sender);

        (, netSyFee) = IPMarket(market).swapExactPtForSy(
            address(YT),
            exactYtOut, // exactPtIn = exactYtOut
            _encodeSwapSyForExactYt(msg.sender, receiver, maxSyIn)
        );

        netSyIn = preSyBalance - SY.balanceOf(msg.sender);

        emit SwapYtAndSy(msg.sender, market, receiver, exactYtOut.Int(), netSyIn.neg());
    }

    /**
     * @notice swap YT to exact SY with the help of flashswaps & YT tokenization / redemption
     * @dev inner working of this function:
     - Approximates `netYtIn` using the data from `guessYtIn`
     - Pulls `netYtIn` amount of YT from caller
     - `market.swapSyForExactPt` is called, which will transfer PT directly to YT contract &
       callback is invoked. Note that now we owe SY
     - In callback, we will redeem all PT + YT to get SY. A portion of it is used to payback the
       loan. The rest is transferred to `receiver`
     * @dev this function works in conjunction with ActionCallback
     */
    function swapYtForExactSy(
        address receiver,
        address market,
        uint256 exactSyOut,
        uint256 maxYtIn,
        ApproxParams memory guessYtIn
    ) external returns (uint256 netYtIn, uint256 netSyFee) {
        MarketState memory state = IPMarket(market).readState(address(this));
        (, , IPYieldToken YT) = IPMarket(market).readTokens();

        (netYtIn, , ) = state.approxSwapYtForExactSy(
            YT.newIndex(),
            exactSyOut,
            block.timestamp,
            guessYtIn
        );

        if (netYtIn > maxYtIn) revert Errors.RouterExceededLimitYtIn(netYtIn, maxYtIn);

        _transferFrom(IERC20(YT), msg.sender, address(YT), netYtIn);

        (, netSyFee) = IPMarket(market).swapSyForExactPt(
            address(YT),
            netYtIn, // exactPtOut = netYtIn
            _encodeSwapYtForSy(receiver, exactSyOut)
        );

        emit SwapYtAndSy(msg.sender, market, receiver, netYtIn.neg(), exactSyOut.Int());
    }

    /**
     * @notice swaps any token to YT
     * @dev this function swaps token for SY-mintable token first through Kyberswap, then mints SY
     * from such, finally swaps SY to YT (see `swapSyForExactYt()`)
     */
    function swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams memory guessYtOut,
        TokenInput calldata input
    ) external payable returns (uint256 netYtOut, uint256 netSyFee) {
        (IStandardizedYield SY, , IPYieldToken YT) = IPMarket(market).readTokens();

        uint256 netSyUsedToBuyYT = _mintSyFromToken(address(YT), address(SY), 1, input);

        (netYtOut, netSyFee) = _swapExactSyForYt(
            receiver,
            market,
            YT,
            netSyUsedToBuyYT,
            minYtOut,
            guessYtOut
        );

        emit SwapYtAndToken(
            msg.sender,
            market,
            input.tokenIn,
            receiver,
            netYtOut.Int(),
            input.netTokenIn.neg()
        );
    }

    /**
     * @notice swaps YT to a given token
     * @dev the function first swaps YT to SY (see `swapExactYtForSy()`), then redeems SY,
     * finally swaps resulting tokens to desired output token using Kyberswap
     */
    function swapExactYtForToken(
        address receiver,
        address market,
        uint256 netYtIn,
        TokenOutput calldata output
    ) external returns (uint256 netTokenOut, uint256 netSyFee) {
        (IStandardizedYield SY, , IPYieldToken YT) = IPMarket(market).readTokens();

        _transferFrom(IERC20(YT), msg.sender, address(YT), netYtIn);

        uint256 netSyOut;

        (netSyOut, netSyFee) = _swapExactYtForSy(
            _syOrBulk(address(SY), output),
            market,
            SY,
            YT,
            netYtIn,
            1
        );

        netTokenOut = _redeemSyToToken(receiver, address(SY), netSyOut, output, false);

        emit SwapYtAndToken(
            msg.sender,
            market,
            output.tokenOut,
            receiver,
            netYtIn.neg(),
            netTokenOut.Int()
        );
    }

    function _swapExactSyForYt(
        address receiver,
        address market,
        IPYieldToken YT,
        uint256 exactSyIn,
        uint256 minYtOut,
        ApproxParams memory guessYtOut
    ) internal returns (uint256 netYtOut, uint256 netSyFee) {
        MarketState memory state = IPMarket(market).readState(address(this));

        (netYtOut, ) = state.approxSwapExactSyForYt(
            YT.newIndex(),
            exactSyIn,
            block.timestamp,
            guessYtOut
        );

        // early-check
        if (netYtOut < minYtOut) revert Errors.RouterInsufficientYtOut(netYtOut, minYtOut);

        (, netSyFee) = IPMarket(market).swapExactPtForSy(
            address(YT),
            netYtOut, // exactPtIn = netYtOut
            _encodeSwapExactSyForYt(receiver, minYtOut)
        );
    }

    function _swapExactYtForSy(
        address receiver,
        address market,
        IStandardizedYield SY,
        IPYieldToken YT,
        uint256 exactYtIn,
        uint256 minSyOut
    ) internal returns (uint256 netSyOut, uint256 netSyFee) {
        uint256 preSyBalance = SY.balanceOf(receiver);

        (, netSyFee) = IPMarket(market).swapSyForExactPt(
            address(YT),
            exactYtIn, // exactPtOut = exactYtIn
            _encodeSwapYtForSy(receiver, minSyOut)
        );

        netSyOut = SY.balanceOf(receiver) - preSyBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../kyberswap/KyberSwapHelper.sol";
import "../../core/libraries/TokenHelper.sol";
import "../../interfaces/IStandardizedYield.sol";
import "../../interfaces/IPYieldToken.sol";
import "../../interfaces/IPBulkSeller.sol";
import "../../core/libraries/Errors.sol";

// solhint-disable no-empty-blocks
abstract contract ActionBaseMintRedeem is TokenHelper, KyberSwapHelper {
    bytes internal constant EMPTY_BYTES = abi.encode();

    /// @dev since this contract will be proxied, it must not contains non-immutable variables
    constructor(address _kyberScalingLib) KyberSwapHelper(_kyberScalingLib) {}

    function _mintSyFromToken(
        address receiver,
        address SY,
        uint256 minSyOut,
        TokenInput calldata input
    ) internal returns (uint256 netSyOut) {
        _transferIn(input.tokenIn, msg.sender, input.netTokenIn);

        bool requireSwap = input.tokenIn != input.tokenMintSy;

        uint256 netTokenMintSy;

        if (requireSwap) {
            _kyberswap(input.tokenIn, input.netTokenIn, input.kyberRouter, input.kybercall);
            netTokenMintSy = _selfBalance(input.tokenMintSy);
        } else {
            netTokenMintSy = input.netTokenIn;
        }

        uint256 netNative = input.tokenMintSy == NATIVE ? netTokenMintSy : 0;

        if (input.bulk != address(0)) {
            _safeApproveInf(input.tokenMintSy, input.bulk);
            netSyOut = IPBulkSeller(input.bulk).swapExactTokenForSy{ value: netNative }(
                receiver,
                netTokenMintSy,
                minSyOut
            );
        } else {
            _safeApproveInf(input.tokenMintSy, SY);
            netSyOut = IStandardizedYield(SY).deposit{ value: netNative }(
                receiver,
                input.tokenMintSy,
                netTokenMintSy,
                minSyOut
            );
        }
    }

    function _redeemSyToToken(
        address receiver,
        address SY,
        uint256 netSyIn,
        TokenOutput memory output,
        bool doPull
    ) internal returns (uint256 netTokenOut) {
        if (doPull) {
            _transferFrom(IERC20(SY), msg.sender, _syOrBulk(SY, output), netSyIn);
        }

        bool requireSwap = output.tokenRedeemSy != output.tokenOut;
        address receiverRedeemSy = requireSwap ? address(this) : receiver;
        uint256 netTokenRedeemed;

        if (output.bulk != address(0)) {
            netTokenRedeemed = IPBulkSeller(output.bulk).swapExactSyForToken(
                receiverRedeemSy,
                netSyIn,
                0,
                true
            );
        } else {
            netTokenRedeemed = IStandardizedYield(SY).redeem(
                receiverRedeemSy,
                netSyIn,
                output.tokenRedeemSy,
                0,
                true
            );
        }

        if (requireSwap) {
            _kyberswap(
                output.tokenRedeemSy,
                netTokenRedeemed,
                output.kyberRouter,
                output.kybercall
            );

            netTokenOut = _selfBalance(output.tokenOut);

            _transferOut(output.tokenOut, receiver, netTokenOut);
        } else {
            netTokenOut = netTokenRedeemed;
        }

        if (netTokenOut < output.minTokenOut) {
            revert Errors.RouterInsufficientTokenOut(netTokenOut, output.minTokenOut);
        }
    }

    function _mintPyFromSy(
        address receiver,
        address YT,
        uint256 netSyIn,
        uint256 minPyOut,
        bool doPull
    ) internal returns (uint256 netPyOut) {
        address SY = IPYieldToken(YT).SY();

        if (doPull) {
            _transferFrom(IERC20(SY), msg.sender, YT, netSyIn);
        }

        netPyOut = IPYieldToken(YT).mintPY(receiver, receiver);
        if (netPyOut < minPyOut) revert Errors.RouterInsufficientPYOut(netPyOut, minPyOut);
    }

    function _redeemPyToSy(
        address receiver,
        address YT,
        uint256 netPyIn,
        uint256 minSyOut
    ) internal returns (uint256 netSyOut) {
        address PT = IPYieldToken(YT).PT();

        _transferFrom(IERC20(PT), msg.sender, YT, netPyIn);

        bool needToBurnYt = (!IPYieldToken(YT).isExpired());
        if (needToBurnYt) _transferFrom(IERC20(YT), msg.sender, YT, netPyIn);

        netSyOut = IPYieldToken(YT).redeemPY(receiver);
        if (netSyOut < minSyOut) revert Errors.RouterInsufficientSyOut(netSyOut, minSyOut);
    }

    function _syOrBulk(address SY, TokenOutput memory output)
        internal
        pure
        returns (address addr)
    {
        return output.bulk != address(0) ? output.bulk : SY;
    }

    function _wrapTokenOutput(
        address tokenOut,
        uint256 minTokenOut,
        address bulk
    ) internal pure returns (TokenOutput memory) {
        return TokenOutput(tokenOut, minTokenOut, tokenOut, bulk, address(0), EMPTY_BYTES);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

abstract contract CallbackHelper {
    enum ActionType {
        SwapSyForExactYt,
        SwapExactSyForYt,
        SwapYtForSy,
        SwapExactYtForPt,
        SwapExactPtForYt
    }

    /// ------------------------------------------------------------
    /// SwapExactSyForYt
    /// ------------------------------------------------------------

    function _encodeSwapExactSyForYt(address receiver, uint256 minYtOut)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(ActionType.SwapExactSyForYt, receiver, minYtOut);
    }

    function _decodeSwapExactSyForYt(bytes memory data)
        internal
        pure
        returns (address receiver, uint256 minYtOut)
    {
        (, receiver, minYtOut) = abi.decode(data, (ActionType, address, uint256));
    }

    /// ------------------------------------------------------------
    /// SwapSyForExactYt
    /// ------------------------------------------------------------

    function _encodeSwapSyForExactYt(
        address payer,
        address receiver,
        uint256 maxSyIn
    ) internal pure returns (bytes memory) {
        return abi.encode(ActionType.SwapSyForExactYt, payer, receiver, maxSyIn);
    }

    function _decodeSwapSyForExactYt(bytes memory data)
        internal
        pure
        returns (
            address payer,
            address receiver,
            uint256 maxSyIn
        )
    {
        (, payer, receiver, maxSyIn) = abi.decode(data, (ActionType, address, address, uint256));
    }

    /// ------------------------------------------------------------
    /// SwapYtForSy (common encode & decode)
    /// ------------------------------------------------------------

    function _encodeSwapYtForSy(address receiver, uint256 minSyOut)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(ActionType.SwapYtForSy, receiver, minSyOut);
    }

    function _decodeSwapYtForSy(bytes memory data)
        internal
        pure
        returns (address receiver, uint256 minSyOut)
    {
        (, receiver, minSyOut) = abi.decode(data, (ActionType, address, uint256));
    }

    function _encodeSwapExactYtForPt(
        address receiver,
        uint256 exactYtIn,
        uint256 minPtOut
    ) internal pure returns (bytes memory) {
        return abi.encode(ActionType.SwapExactYtForPt, receiver, exactYtIn, minPtOut);
    }

    function _decodeSwapExactYtForPt(bytes memory data)
        internal
        pure
        returns (
            address receiver,
            uint256 exactYtIn,
            uint256 minPtOut
        )
    {
        (, receiver, exactYtIn, minPtOut) = abi.decode(
            data,
            (ActionType, address, uint256, uint256)
        );
    }

    function _encodeSwapExactPtForYt(
        address receiver,
        uint256 exactPtIn,
        uint256 minYtOut
    ) internal pure returns (bytes memory) {
        return abi.encode(ActionType.SwapExactPtForYt, receiver, exactPtIn, minYtOut);
    }

    function _decodeSwapExactPtForYt(bytes memory data)
        internal
        pure
        returns (
            address receiver,
            uint256 exactPtIn,
            uint256 minYtOut
        )
    {
        (, receiver, exactPtIn, minYtOut) = abi.decode(
            data,
            (ActionType, address, uint256, uint256)
        );
    }

    /// ------------------------------------------------------------
    /// Misc functions
    /// ------------------------------------------------------------
    function _getActionType(bytes memory data) internal pure returns (ActionType actionType) {
        actionType = abi.decode(data, (ActionType));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../../core/libraries/math/Math.sol";
import "../../core/Market/MarketMathCore.sol";

struct ApproxParams {
    uint256 guessMin;
    uint256 guessMax;
    uint256 guessOffchain; // pass 0 in to skip this variable
    uint256 maxIteration; // every iteration, the diff between guessMin and guessMax will be divided by 2
    uint256 eps; // the max eps between the returned result & the correct result, base 1e18. Normally this number will be set
    // to 1e15 (1e18/1000 = 0.1%)

    /// Further explanation of the eps. Take swapExactSyForPt for example. To calc the corresponding amount of Pt to swap out,
    /// it's necessary to run an approximation algorithm, because by default there only exists the Pt to Sy formula
    /// To approx, the 5 values above will have to be provided, and the approx process will run as follows:
    /// mid = (guessMin + guessMax) / 2 // mid here is the current guess of the amount of Pt out
    /// netSyNeed = calcSwapSyForExactPt(mid)
    /// if (netSyNeed > exactSyIn) guessMax = mid - 1 // since the maximum Sy in can't exceed the exactSyIn
    /// else guessMin = mid (1)
    /// For the (1), since netSyNeed <= exactSyIn, the result might be usable. If the netSyNeed is within eps of
    /// exactSyIn (ex eps=0.1% => we have used 99.9% the amount of Sy specified), mid will be chosen as the final guess result

    /// for guessOffchain, this is to provide a shortcut to guessing. The offchain SDK can precalculate the exact result
    /// before the tx is sent. When the tx reaches the contract, the guessOffchain will be checked first, and if it satisfies the
    /// approximation, it will be used (and save all the guessing). It's expected that this shortcut will be used in most cases
    /// except in cases that there is a trade in the same market right before the tx
}

library MarketApproxPtInLib {
    using MarketMathCore for MarketState;
    using PYIndexLib for PYIndex;
    using Math for uint256;
    using Math for int256;
    using LogExpMath for int256;

    struct ApproxParamsPtIn {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain;
        uint256 maxIteration;
        uint256 eps;
        //
        uint256 biggestGoodGuess;
    }

    struct Args1 {
        MarketState market;
        PYIndex index;
        uint256 minSyOut;
        uint256 blockTime;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swap in
        - Try swapping & get netSyOut
        - Stop when netSyOut greater & approx minSyOut
        - guess & approx is for netPtIn
     */
    function approxSwapPtForExactSy(
        MarketState memory _market,
        PYIndex _index,
        uint256 _minSyOut,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netPtIn*/
            uint256, /*netSyOut*/
            uint256 /*netSyFee*/
        )
    {
        Args1 memory a = Args1(_market, _index, _minSyOut, _blockTime);
        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        ApproxParamsPtIn memory p = newApproxParamsPtIn(_approx, 0, calcMaxPtIn(comp.totalAsset));

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            (bool isGoodSlope, uint256 guess) = nextGuess(p, comp, a.market.totalPt, iter);
            if (!isGoodSlope) {
                p.guessMax = guess;
                continue;
            }

            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(a.market, comp, a.index, guess);

            if (netSyOut >= a.minSyOut) {
                p.guessMax = guess;
                bool isAnswerAccepted = Math.isAGreaterApproxB(netSyOut, a.minSyOut, p.eps);
                if (isAnswerAccepted) {
                    return (guess, netSyOut, netSyFee);
                }
            } else {
                p.guessMin = guess;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args2 {
        MarketState market;
        PYIndex index;
        uint256 exactSyIn;
        uint256 blockTime;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swap in
        - Flashswap the corresponding amount of SY out
        - Pair those amount with exactSyIn SY to tokenize into PT & YT
        - PT to repay the flashswap, YT transferred to user
        - Stop when the amount of SY to be pulled to tokenize PT to repay loan approx the exactSyIn
        - guess & approx is for netYtOut (also netPtIn)
     */
    function approxSwapExactSyForYt(
        MarketState memory _market,
        PYIndex _index,
        uint256 _exactSyIn,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netYtOut*/
            uint256 /*netSyFee*/
        )
    {
        Args2 memory a = Args2(_market, _index, _exactSyIn, _blockTime);
        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);

        // at minimum we will flashswap exactSyIn since we have enough SY to payback the PT loan
        ApproxParamsPtIn memory p = newApproxParamsPtIn(
            _approx,
            a.index.syToAsset(a.exactSyIn),
            calcMaxPtIn(comp.totalAsset)
        );

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            (bool isGoodSlope, uint256 guess) = nextGuess(p, comp, a.market.totalPt, iter);
            if (!isGoodSlope) {
                p.guessMax = guess;
                continue;
            }

            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(a.market, comp, a.index, guess);

            uint256 netSyToTokenizePt = a.index.assetToSyUp(guess);

            // for sure netSyToTokenizePt >= netSyOut since we are swapping PT to SY
            uint256 netSyToPull = netSyToTokenizePt - netSyOut;

            if (netSyToPull <= a.exactSyIn) {
                p.guessMin = guess;
                bool isAnswerAccepted = Math.isASmallerApproxB(netSyToPull, a.exactSyIn, p.eps);
                if (isAnswerAccepted) return (guess, netSyFee);
            } else {
                p.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args6 {
        MarketState market;
        PYIndex index;
        uint256 totalPtIn;
        uint256 blockTime;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swap to SY
        - Swap PT to SY
        - Pair the remaining PT with the SY to add liquidity
        - Stop when the ratio of PT / totalPt & SY / totalSy is approx
        - guess & approx is for netPtSwap
     */
    function approxSwapPtToAddLiquidity(
        MarketState memory _market,
        PYIndex _index,
        uint256 _totalPtIn,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netPtSwap*/
            uint256, /*netSyFromSwap*/
            uint256 /*netSyFee*/
        )
    {
        Args6 memory a = Args6(_market, _index, _totalPtIn, _blockTime);
        require(a.market.totalLp != 0, "no existing lp");

        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        ApproxParamsPtIn memory p = newApproxParamsPtIn(
            _approx,
            0,
            Math.min(a.totalPtIn, calcMaxPtIn(comp.totalAsset))
        );

        p.guessMax = Math.min(p.guessMax, a.totalPtIn);

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            (bool isGoodSlope, uint256 guess) = nextGuess(p, comp, a.market.totalPt, iter);

            if (!isGoodSlope) {
                p.guessMax = guess;
                continue;
            }

            (uint256 netSyOut, uint256 netSyFee, uint256 netSyToReserve) = calcSyOut(
                a.market,
                comp,
                a.index,
                guess
            );

            uint256 syNumerator;
            uint256 ptNumerator;
            {
                uint256 newTotalPt = a.market.totalPt.Uint() + guess;
                uint256 newTotalSy = (a.market.totalSy.Uint() - netSyOut - netSyToReserve);

                // it is desired that
                // netSyOut / newTotalSy = netPtRemaining / newTotalPt
                // which is equivalent to
                // netSyOut * newTotalPt = netPtRemaining * newTotalSy

                syNumerator = netSyOut * newTotalPt;
                ptNumerator = (a.totalPtIn - guess) * newTotalSy;
            }

            if (Math.isAApproxB(syNumerator, ptNumerator, p.eps)) {
                return (guess, netSyOut, netSyFee);
            }

            if (syNumerator <= ptNumerator) {
                // needs more SY --> swap more PT
                p.guessMin = guess + 1;
            } else {
                // needs less SY --> swap less PT
                p.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args7 {
        MarketState market;
        PYIndex index;
        uint256 exactPtIn;
        uint256 blockTime;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swap to SY
        - Flashswap the corresponding amount of SY out
        - Tokenize all the SY into PT + YT
        - PT to repay the flashswap, YT transferred to user
        - Stop when the additional amount of PT to pull to repay the loan approx the exactPtIn
        - guess & approx is for totalPtToSwap
     */
    function approxSwapExactPtForYt(
        MarketState memory _market,
        PYIndex _index,
        uint256 _exactPtIn,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netYtOut*/
            uint256, /*totalPtToSwap*/
            uint256 /*netSyFee*/
        )
    {
        Args7 memory a = Args7(_market, _index, _exactPtIn, _blockTime);

        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        ApproxParamsPtIn memory p = newApproxParamsPtIn(
            _approx,
            a.exactPtIn,
            calcMaxPtIn(comp.totalAsset)
        );

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            (bool isGoodSlope, uint256 guess) = nextGuess(p, comp, a.market.totalPt, iter);

            if (!isGoodSlope) {
                p.guessMax = guess;
                continue;
            }

            (uint256 netSyOut, uint256 netSyFee, ) = calcSyOut(a.market, comp, a.index, guess);

            uint256 netAssetOut = a.index.syToAsset(netSyOut);

            // guess >= netAssetOut since we are swapping PT to SY
            uint256 netPtToPull = guess - netAssetOut;

            if (netPtToPull <= a.exactPtIn) {
                p.guessMin = guess;
                if (Math.isASmallerApproxB(netPtToPull, a.exactPtIn, p.eps)) {
                    return (netAssetOut, guess, netSyFee);
                }
            } else {
                p.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    ////////////////////////////////////////////////////////////////////////////////

    function calcSyOut(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        uint256 netPtIn
    )
        internal
        pure
        returns (
            uint256 netSyOut,
            uint256 netSyFee,
            uint256 netSyToReserve
        )
    {
        (int256 _netSyOut, int256 _netSyFee, int256 _netSyToReserve) = market.calcTrade(
            comp,
            index,
            netPtIn.neg()
        );
        netSyOut = _netSyOut.Uint();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    function newApproxParamsPtIn(
        ApproxParams memory _approx,
        uint256 minGuessMin,
        uint256 maxGuessMax
    ) internal pure returns (ApproxParamsPtIn memory res) {
        res.guessMin = Math.max(_approx.guessMin, minGuessMin);
        res.guessMax = Math.min(_approx.guessMax, maxGuessMax);

        if (res.guessMin > res.guessMax || _approx.eps > Math.ONE)
            revert Errors.ApproxParamsInvalid(_approx.guessMin, _approx.guessMax, _approx.eps);

        res.guessOffchain = _approx.guessOffchain;
        res.maxIteration = _approx.maxIteration;
        res.eps = _approx.eps;
    }

    function calcMaxPtIn(int256 totalAsset) internal pure returns (uint256) {
        return totalAsset.Uint() - 1;
    }

    function nextGuess(
        ApproxParamsPtIn memory p,
        MarketPreCompute memory comp,
        int256 totalPt,
        uint256 iter
    ) internal pure returns (bool, uint256) {
        uint256 guess = _nextGuessPrivate(p, iter);
        if (guess <= p.biggestGoodGuess) return (true, guess);

        int256 slope = calcSlope(comp, totalPt, guess.Int());
        if (slope < 0) return (false, guess);

        p.biggestGoodGuess = guess;
        return (true, guess);
    }

    /**
     * @dev it is safe to assume that p.guessMin <= p.guessMax from the initialization of p
     * So once guessMin becomes larger, it should always be the case of ApproxFail
     */
    function _nextGuessPrivate(ApproxParamsPtIn memory p, uint256 iter)
        private
        pure
        returns (uint256)
    {
        if (iter == 0 && p.guessOffchain != 0) return p.guessOffchain;
        if (p.guessMin <= p.guessMax) return (p.guessMin + p.guessMax) / 2;
        revert Errors.ApproxFail();
    }

    function calcSlope(
        MarketPreCompute memory comp,
        int256 totalPt,
        int256 ptToMarket //
    ) internal pure returns (int256) {
        int256 diffAssetPtToMarket = comp.totalAsset - ptToMarket;
        int256 sumPt = ptToMarket + totalPt; // probably can skip sumPt check

        require(diffAssetPtToMarket > 0 && sumPt > 0, "invalid ptToMarket");

        int256 part1 = (ptToMarket * (totalPt + comp.totalAsset)).divDown(
            sumPt * diffAssetPtToMarket
        );

        int256 part2 = sumPt.divDown(diffAssetPtToMarket).ln();
        int256 part3 = Math.IONE.divDown(comp.rateScalar);

        return comp.rateAnchor - (part1 - part2).mulDown(part3);
    }
}

library MarketApproxPtOutLib {
    using MarketMathCore for MarketState;
    using PYIndexLib for PYIndex;
    using Math for uint256;
    using Math for int256;
    using LogExpMath for int256;

    struct ApproxParamsPtOut {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain;
        uint256 maxIteration;
        uint256 eps;
    }

    struct Args4 {
        MarketState market;
        PYIndex index;
        uint256 exactSyIn;
        uint256 blockTime;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swapExactOut
        - Calculate the amount of SY needed
        - Stop when the netSyIn is smaller approx exactSyIn
        - guess & approx is for netSyIn
     */
    function approxSwapExactSyForPt(
        MarketState memory _market,
        PYIndex _index,
        uint256 _exactSyIn,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netPtOut*/
            uint256 /*netSyFee*/
        )
    {
        Args4 memory a = Args4(_market, _index, _exactSyIn, _blockTime);
        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        ApproxParamsPtOut memory p = newApproxParamsPtOut(
            _approx,
            0,
            calcMaxPtOut(comp, a.market.totalPt)
        );

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            uint256 guess = nextGuess(p, iter);

            (uint256 netSyIn, uint256 netSyFee, ) = calcSyIn(a.market, comp, a.index, guess);

            if (netSyIn <= a.exactSyIn) {
                p.guessMin = guess;
                bool isAnswerAccepted = Math.isASmallerApproxB(netSyIn, a.exactSyIn, p.eps);
                if (isAnswerAccepted) return (guess, netSyFee);
            } else {
                p.guessMax = guess - 1;
            }
        }

        revert Errors.ApproxFail();
    }

    struct Args5 {
        MarketState market;
        PYIndex index;
        uint256 minSyOut;
        uint256 blockTime;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swapExactOut
        - Flashswap that amount of PT & pair with YT to redeem SY
        - Use the SY to repay the flashswap debt and the remaining is transferred to user
        - Stop when the netSyOut is greater approx the minSyOut
        - guess & approx is for netSyOut
     */
    function approxSwapYtForExactSy(
        MarketState memory _market,
        PYIndex _index,
        uint256 _minSyOut,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netYtIn*/
            uint256, /*netSyOut*/
            uint256 /*netSyFee*/
        )
    {
        Args5 memory a = Args5(_market, _index, _minSyOut, _blockTime);
        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        ApproxParamsPtOut memory p = newApproxParamsPtOut(
            _approx,
            0,
            calcMaxPtOut(comp, a.market.totalPt)
        );

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            uint256 guess = nextGuess(p, iter);

            (uint256 netSyOwed, uint256 netSyFee, ) = calcSyIn(a.market, comp, a.index, guess);

            uint256 netAssetToRepay = a.index.syToAssetUp(netSyOwed);
            uint256 netSyOut = a.index.assetToSy(guess - netAssetToRepay);

            if (netSyOut >= a.minSyOut) {
                p.guessMax = guess;
                if (Math.isAGreaterApproxB(netSyOut, a.minSyOut, p.eps)) {
                    return (guess, netSyOut, netSyFee);
                }
            } else {
                p.guessMin = guess + 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args6 {
        MarketState market;
        PYIndex index;
        uint256 totalSyIn;
        uint256 blockTime;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swapExactOut
        - Swap that amount of PT out
        - Pair the remaining PT with the SY to add liquidity
        - Stop when the ratio of PT / totalPt & SY / totalSy is approx
        - guess & approx is for netPtFromSwap
     */
    function approxSwapSyToAddLiquidity(
        MarketState memory _market,
        PYIndex _index,
        uint256 _totalSyIn,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netPtFromSwap*/
            uint256, /*netSySwap*/
            uint256 /*netSyFee*/
        )
    {
        Args6 memory a = Args6(_market, _index, _totalSyIn, _blockTime);
        require(a.market.totalLp != 0, "no existing lp");

        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        ApproxParamsPtOut memory p = newApproxParamsPtOut(
            _approx,
            0,
            calcMaxPtOut(comp, a.market.totalPt)
        );

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            uint256 guess = nextGuess(p, iter);

            (uint256 netSyIn, uint256 netSyFee, uint256 netSyToReserve) = calcSyIn(
                a.market,
                comp,
                a.index,
                guess
            );

            if (netSyIn > a.totalSyIn) {
                p.guessMax = guess - 1;
                continue;
            }

            uint256 syNumerator;
            uint256 ptNumerator;

            {
                uint256 newTotalPt = a.market.totalPt.Uint() - guess;
                uint256 netTotalSy = a.market.totalSy.Uint() + netSyIn - netSyToReserve;

                // it is desired that
                // netPtFromSwap / newTotalPt = netSyRemaining / netTotalSy
                // which is equivalent to
                // netPtFromSwap * netTotalSy = netSyRemaining * newTotalPt

                ptNumerator = guess * netTotalSy;
                syNumerator = (a.totalSyIn - netSyIn) * newTotalPt;
            }

            if (Math.isAApproxB(ptNumerator, syNumerator, p.eps)) {
                return (guess, netSyIn, netSyFee);
            }

            if (ptNumerator <= syNumerator) {
                // needs more PT
                p.guessMin = guess + 1;
            } else {
                // needs less PT
                p.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    struct Args8 {
        MarketState market;
        PYIndex index;
        uint256 exactYtIn;
        uint256 blockTime;
        uint256 maxSyPayable;
    }

    /**
     * @dev algorithm:
        - Bin search the amount of PT to swapExactOut
        - Flashswap that amount of PT out
        - Pair all the PT with the YT to redeem SY
        - Use the SY to repay the flashswap debt
        - Stop when the amount of SY owed is smaller approx the amount of SY to repay the flashswap
        - guess & approx is for netPtFromSwap
     */
    function approxSwapExactYtForPt(
        MarketState memory _market,
        PYIndex _index,
        uint256 _exactYtIn,
        uint256 _blockTime,
        ApproxParams memory _approx
    )
        internal
        pure
        returns (
            uint256, /*netPtOut*/
            uint256, /*totalPtSwapped*/
            uint256 /*netSyFee*/
        )
    {
        Args8 memory a = Args8(
            _market,
            _index,
            _exactYtIn,
            _blockTime,
            _index.assetToSy(_exactYtIn)
        );
        MarketPreCompute memory comp = a.market.getMarketPreCompute(a.index, a.blockTime);
        ApproxParamsPtOut memory p = newApproxParamsPtOut(
            _approx,
            a.exactYtIn,
            calcMaxPtOut(comp, a.market.totalPt)
        );

        for (uint256 iter = 0; iter < p.maxIteration; ++iter) {
            uint256 guess = nextGuess(p, iter);

            (uint256 netSyOwed, uint256 netSyFee, ) = calcSyIn(a.market, comp, a.index, guess);

            if (netSyOwed <= a.maxSyPayable) {
                p.guessMin = guess;

                if (Math.isASmallerApproxB(netSyOwed, a.maxSyPayable, p.eps)) {
                    return (guess - a.exactYtIn, guess, netSyFee);
                }
            } else {
                p.guessMax = guess - 1;
            }
        }
        revert Errors.ApproxFail();
    }

    ////////////////////////////////////////////////////////////////////////////////

    function calcSyIn(
        MarketState memory market,
        MarketPreCompute memory comp,
        PYIndex index,
        uint256 netPtOut
    )
        internal
        pure
        returns (
            uint256 netSyIn,
            uint256 netSyFee,
            uint256 netSyToReserve
        )
    {
        (int256 _netSyIn, int256 _netSyFee, int256 _netSyToReserve) = market.calcTrade(
            comp,
            index,
            netPtOut.Int()
        );

        netSyIn = _netSyIn.abs();
        netSyFee = _netSyFee.Uint();
        netSyToReserve = _netSyToReserve.Uint();
    }

    function newApproxParamsPtOut(
        ApproxParams memory _approx,
        uint256 minGuessMin,
        uint256 maxGuessMax
    ) internal pure returns (ApproxParamsPtOut memory res) {
        if (_approx.guessMin > _approx.guessMax || _approx.eps > Math.ONE)
            revert Errors.ApproxParamsInvalid(_approx.guessMin, _approx.guessMax, _approx.eps);

        res.guessMin = Math.max(_approx.guessMin, minGuessMin);
        res.guessMax = Math.min(_approx.guessMax, maxGuessMax);

        if (res.guessMin > res.guessMax)
            revert Errors.ApproxBinarySearchInputInvalid(
                _approx.guessMin,
                _approx.guessMax,
                minGuessMin,
                maxGuessMax
            );

        res.guessOffchain = _approx.guessOffchain;
        res.maxIteration = _approx.maxIteration;
        res.eps = _approx.eps;
    }

    function calcMaxPtOut(MarketPreCompute memory comp, int256 totalPt)
        internal
        pure
        returns (uint256)
    {
        int256 logitP = (comp.feeRate - comp.rateAnchor).mulDown(comp.rateScalar).exp();
        int256 proportion = logitP.divDown(logitP + Math.IONE);
        int256 numerator = proportion.mulDown(totalPt + comp.totalAsset);
        int256 maxPtOut = totalPt - numerator;
        // only get 99.9% of the theoretical max to accommodate some precision issues
        return (maxPtOut.Uint() * 999) / 1000;
    }

    /**
     * @dev it is safe to assume that p.guessMin <= p.guessMax from the initialization of p
     * So once guessMin becomes larger, it should always be the case of ApproxFail
     */
    function nextGuess(ApproxParamsPtOut memory p, uint256 iter) private pure returns (uint256) {
        if (iter == 0 && p.guessOffchain != 0) return p.guessOffchain;
        if (p.guessMin <= p.guessMax) return (p.guessMin + p.guessMax) / 2;
        revert Errors.ApproxFail();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

interface IAggregationRouterHelper {
    function getScaledInputData(bytes calldata kybercall, uint256 newAmount)
        external
        pure
        returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../core/libraries/TokenHelper.sol";
import "./IAggregatorRouterHelper.sol";
import "../../core/libraries/Errors.sol";

struct TokenInput {
    // Token/Sy data
    address tokenIn;
    uint256 netTokenIn;
    address tokenMintSy;
    address bulk;
    // Kyber data
    address kyberRouter;
    bytes kybercall;
}

struct TokenOutput {
    // Token/Sy data
    address tokenOut;
    uint256 minTokenOut;
    address tokenRedeemSy;
    address bulk;
    // Kyber data
    address kyberRouter;
    bytes kybercall;
}

abstract contract KyberSwapHelper is TokenHelper {
    using Address for address;

    address public immutable kyberScalingLib;

    constructor(address _kyberScalingLib) {
        kyberScalingLib = _kyberScalingLib;
    }

    function _kyberswap(
        address tokenIn,
        uint256 amountIn,
        address kyberRouter,
        bytes memory rawKybercall
    ) internal {
        if (kyberRouter == address(0) || rawKybercall.length == 0)
            revert Errors.RouterKyberSwapDataZero();

        _safeApproveInf(tokenIn, kyberRouter);

        bytes memory kybercall = IAggregationRouterHelper(kyberScalingLib).getScaledInputData(
            rawKybercall,
            amountIn
        );
        kyberRouter.functionCallWithValue(kybercall, tokenIn == NATIVE ? amountIn : 0);
    }
}