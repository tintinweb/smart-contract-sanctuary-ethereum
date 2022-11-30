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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


library AMOCommon {
    error NotOperator();
    error NotOperatorOrOwner();
    error ZeroSwapLimit();
    error OnlyAMO();
    error AboveCappedAmount(uint256 amountIn);
    error InsufficientBPTAmount(uint256 amount);
    error InvalidBPSValue(uint256 value);
    error InsufficientAmountOutPostcall(uint256 expectedAmount, uint256 actualAmount);
    error InvalidMaxAmounts(uint256 bptMaxAmount, uint256 stableMaxAmount, uint256 templeMaxAmount);
    error InvalidBalancerVaultRequest();
    error NotEnoughCooldown();
    error NoRebalanceUp();
    error NoRebalanceDown();
    error HighSlippage();
    error Paused();
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/AMO__IBalancerVault.sol";
import "../helpers/AMOCommon.sol";


interface IWeightPool2Tokens {
    function getNormalizedWeights() external view returns (uint256[] memory);
}

contract PoolHelper {
    using SafeERC20 for IERC20;

    AMO__IBalancerVault public immutable balancerVault;
    IERC20 public immutable bptToken;
    IERC20 public immutable temple;
    IERC20 public immutable stable;
    address public immutable amo;
    // @notice Temple price floor denominator
    uint256 public constant TPF_PRECISION = 10_000;

    // @notice temple index in balancer pool
    uint64 public immutable templeIndexInBalancerPool;

    bytes32 public immutable balancerPoolId;

    constructor(
      address _balancerVault,
      address _temple,
      address _stable,
      address _bptToken,
      address _amo,
      uint64 _templeIndexInPool,
      bytes32 _balancerPoolId
    ) {
      balancerPoolId = _balancerPoolId;
      balancerVault = AMO__IBalancerVault(_balancerVault);
      temple = IERC20(_temple);
      stable = IERC20(_stable);
      bptToken = IERC20(_bptToken);
      amo = _amo;
      templeIndexInBalancerPool = _templeIndexInPool;
    }

    function getBalances() public view returns (uint256[] memory balances) {
      (, balances,) = balancerVault.getPoolTokens(balancerPoolId);
    }

    function getTempleStableBalances() public view returns (uint256 templeBalance, uint256 stableBalance) {
      uint256[] memory balances = getBalances();
      (templeBalance, stableBalance) = (templeIndexInBalancerPool == 0) 
        ? (balances[0], balances[1]) 
        : (balances[1], balances[0]);
    }

    function getSpotPriceScaled() public view returns (uint256 spotPriceScaled) {
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();
        spotPriceScaled = (TPF_PRECISION * stableBalance) / templeBalance;
    }

    function isSpotPriceBelowTPF(uint256 templePriceFloorNumerator) external view returns (bool) {
        return getSpotPriceScaled() < templePriceFloorNumerator;
    }

    // below TPF by a given slippage percentage
    function isSpotPriceBelowTPF(uint256 slippage, uint256 templePriceFloorNumerator) public view returns (bool) {
        uint256 slippageTPF = (slippage * templePriceFloorNumerator) / TPF_PRECISION;
        return getSpotPriceScaled() < (templePriceFloorNumerator - slippageTPF);
    }

    function isSpotPriceBelowTPFLowerBound(uint256 rebalancePercentageBoundLow, uint256 templePriceFloorNumerator) public view returns (bool) {
        return isSpotPriceBelowTPF(rebalancePercentageBoundLow, templePriceFloorNumerator);
    }

    function isSpotPriceAboveTPFUpperBound(uint256 rebalancePercentageBoundUp, uint256 templePriceFloorNumerator) public view returns (bool) {
        return isSpotPriceAboveTPF(rebalancePercentageBoundUp, templePriceFloorNumerator);
    }

    // slippage in bps
    // above TPF by a given slippage percentage
    function isSpotPriceAboveTPF(uint256 slippage, uint256 templePriceFloorNumerator) public view returns (bool) {
      uint256 slippageTPF = (slippage * templePriceFloorNumerator) / TPF_PRECISION;
      return getSpotPriceScaled() > (templePriceFloorNumerator + slippageTPF);
    }

    function isSpotPriceAboveTPF(uint256 templePriceFloorNumerator) external view returns (bool) {
        return getSpotPriceScaled() > templePriceFloorNumerator;
    }

    // @notice will exit take price above tpf by a percentage
    // percentage in bps
    // tokensOut: expected min amounts out. for rebalance this is expected Temple tokens out
    function willExitTakePriceAboveTPFUpperBound(
        uint256 tokensOut,
        uint256 rebalancePercentageBoundUp,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageIncrease = (templePriceFloorNumerator * rebalancePercentageBoundUp) / TPF_PRECISION;
        uint256 maxNewTpf = percentageIncrease + templePriceFloorNumerator;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        // a ratio of stable balances aginst temple balances
        uint256 newTempleBalance = templeBalance - tokensOut;
        uint256 spot = (stableBalance * TPF_PRECISION ) / newTempleBalance;
        return spot > maxNewTpf;
    }

    function willStableJoinTakePriceAboveTPFUpperBound(
        uint256 tokensIn,
        uint256 rebalancePercentageBoundUp,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageIncrease = (templePriceFloorNumerator * rebalancePercentageBoundUp) / TPF_PRECISION;
        uint256 maxNewTpf = percentageIncrease + templePriceFloorNumerator;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        uint256 newStableBalance = stableBalance + tokensIn;
        uint256 spot = (newStableBalance * TPF_PRECISION ) / templeBalance;
        return spot > maxNewTpf;
    }

    function willStableExitTakePriceBelowTPFLowerBound(
        uint256 tokensOut,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageDecrease = (templePriceFloorNumerator * rebalancePercentageBoundLow) / TPF_PRECISION;
        uint256 minNewTpf = templePriceFloorNumerator - percentageDecrease;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        uint256 newStableBalance = stableBalance - tokensOut;
        uint256 spot = (newStableBalance * TPF_PRECISION) / templeBalance;
        return spot < minNewTpf;
    }

    function willJoinTakePriceBelowTPFLowerBound(
        uint256 tokensIn,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) public view returns (bool) {
        uint256 percentageDecrease = (templePriceFloorNumerator * rebalancePercentageBoundLow) / TPF_PRECISION;
        uint256 minNewTpf = templePriceFloorNumerator - percentageDecrease;
        (uint256 templeBalance, uint256 stableBalance) = getTempleStableBalances();

        // a ratio of stable balances against temple balances
        uint256 newTempleBalance = templeBalance + tokensIn;
        uint256 spot = (stableBalance * TPF_PRECISION) / newTempleBalance;
        return spot < minNewTpf;
    }

    // get slippage between spot price before and spot price now
    function getSlippage(uint256 spotPriceBeforeScaled) public view returns (uint256) {
        uint256 spotPriceNowScaled = getSpotPriceScaled();
        // taking into account both rebalance up or down
        uint256 slippageDifference;
        unchecked {
            slippageDifference = (spotPriceNowScaled > spotPriceBeforeScaled)
                ? spotPriceNowScaled - spotPriceBeforeScaled
                : spotPriceBeforeScaled - spotPriceNowScaled;
        }
        return (slippageDifference * TPF_PRECISION) / spotPriceBeforeScaled;
    }

    function createPoolExitRequest(
        uint256 bptAmountIn,
        uint256 minAmountOut,
        uint256 exitTokenIndex
    ) internal view returns (AMO__IBalancerVault.ExitPoolRequest memory request) {
        address[] memory assets = new address[](2);
        uint256[] memory minAmountsOut = new uint256[](2);

        (assets[0], assets[1]) = templeIndexInBalancerPool == 0 ? (address(temple), address(stable)) : (address(stable), address(temple));
        (minAmountsOut[0], minAmountsOut[1]) = exitTokenIndex == uint256(0) ? (minAmountOut, uint256(0)) : (uint256(0), minAmountOut); 
        // EXACT_BPT_IN_FOR_ONE_TOKEN_OUT index is 0 for exitKind
        bytes memory encodedUserdata = abi.encode(uint256(0), bptAmountIn, exitTokenIndex);
        request.assets = assets;
        request.minAmountsOut = minAmountsOut;
        request.userData = encodedUserdata;
        request.toInternalBalance = false;
    }

    function createPoolJoinRequest(
        uint256 amountIn,
        uint256 tokenIndex,
        uint256 minTokenOut
    ) internal view returns (AMO__IBalancerVault.JoinPoolRequest memory request) {
        IERC20[] memory assets = new IERC20[](2);
        uint256[] memory maxAmountsIn = new uint256[](2);
    
        (assets[0], assets[1]) = templeIndexInBalancerPool == 0 ? (temple, stable) : (stable, temple);
        (maxAmountsIn[0], maxAmountsIn[1]) = tokenIndex == uint256(0) ? (amountIn, uint256(0)) : (uint256(0), amountIn);
        //uint256 joinKind = 1; //EXACT_TOKENS_IN_FOR_BPT_OUT
        bytes memory encodedUserdata = abi.encode(uint256(1), maxAmountsIn, minTokenOut);
        request.assets = assets;
        request.maxAmountsIn = maxAmountsIn;
        request.userData = encodedUserdata;
        request.fromInternalBalance = false;
    }

    function exitPool(
        uint256 bptAmountIn,
        uint256 minAmountOut,
        uint256 rebalancePercentageBoundLow,
        uint256 rebalancePercentageBoundUp,
        uint256 postRebalanceSlippage,
        uint256 exitTokenIndex,
        uint256 templePriceFloorNumerator,
        IERC20 exitPoolToken
    ) external onlyAmo returns (uint256 amountOut) {
        exitPoolToken == temple ? 
            validateTempleExit(minAmountOut, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator) :
            validateStableExit(minAmountOut, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator);

        // create request
        AMO__IBalancerVault.ExitPoolRequest memory exitPoolRequest = createPoolExitRequest(bptAmountIn,
            minAmountOut, exitTokenIndex);

        // execute call and check for sanity
        uint256 exitTokenBalanceBefore = exitPoolToken.balanceOf(msg.sender);
        uint256 spotPriceScaledBefore = getSpotPriceScaled();
        balancerVault.exitPool(balancerPoolId, address(this), msg.sender, exitPoolRequest);
        uint256 exitTokenBalanceAfter = exitPoolToken.balanceOf(msg.sender);

        unchecked {
            amountOut = exitTokenBalanceAfter - exitTokenBalanceBefore;
        }

        if (uint64(getSlippage(spotPriceScaledBefore)) > postRebalanceSlippage) {
            revert AMOCommon.HighSlippage();
        }
    }

    function joinPool(
        uint256 amountIn,
        uint256 minBptOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator,
        uint256 postRebalanceSlippage,
        uint256 joinTokenIndex,
        IERC20 joinPoolToken
    ) external onlyAmo returns (uint256 bptOut) {
        joinPoolToken == temple ? 
            validateTempleJoin(amountIn, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator) :
            validateStableJoin(amountIn, rebalancePercentageBoundUp, rebalancePercentageBoundLow, templePriceFloorNumerator);

        // create request
        AMO__IBalancerVault.JoinPoolRequest memory joinPoolRequest = createPoolJoinRequest(amountIn, joinTokenIndex, minBptOut);

        // approve
        if (joinPoolToken == temple) {
            joinPoolToken.safeIncreaseAllowance(address(balancerVault), amountIn);
        }

        // execute and sanity check
        uint256 bptAmountBefore = bptToken.balanceOf(msg.sender);
        uint256 spotPriceScaledBefore = getSpotPriceScaled();
        balancerVault.joinPool(balancerPoolId, address(this), msg.sender, joinPoolRequest);
        uint256 bptAmountAfter = bptToken.balanceOf(msg.sender);

        unchecked {
            bptOut = bptAmountAfter - bptAmountBefore;
        }

        // revert if high slippage after pool join
        if (uint64(getSlippage(spotPriceScaledBefore)) > postRebalanceSlippage) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateTempleJoin(
        uint256 amountIn,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        if (!isSpotPriceAboveTPFUpperBound(rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceDown();
        }
        // should rarely be the case, but a sanity check nonetheless
        if (willJoinTakePriceBelowTPFLowerBound(amountIn, rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateTempleExit(
        uint256 amountOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        // check spot price is below TPF by lower bound
        if (!isSpotPriceBelowTPFLowerBound(rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceUp();
        }

        // will exit take price above tpf + upper bound
        // should rarely be the case, but a sanity check nonetheless
        if (willExitTakePriceAboveTPFUpperBound(amountOut, rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateStableJoin(
        uint256 amountIn,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        if (!isSpotPriceBelowTPFLowerBound(rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceUp();
        }
        // should rarely be the case, but a sanity check nonetheless
        if (willStableJoinTakePriceAboveTPFUpperBound(amountIn, rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    function validateStableExit(
        uint256 amountOut,
        uint256 rebalancePercentageBoundUp,
        uint256 rebalancePercentageBoundLow,
        uint256 templePriceFloorNumerator
    ) internal view {
        if (!isSpotPriceAboveTPFUpperBound(rebalancePercentageBoundUp, templePriceFloorNumerator)) {
            revert AMOCommon.NoRebalanceDown();
        }
        // should rarely be the case, but a sanity check nonetheless
        if (willStableExitTakePriceBelowTPFLowerBound(amountOut, rebalancePercentageBoundLow, templePriceFloorNumerator)) {
            revert AMOCommon.HighSlippage();
        }
    }

    modifier onlyAmo() {
        if (msg.sender != amo) {
            revert AMOCommon.OnlyAMO();
        }
        _;
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AMO__IBalancerVault {

  struct JoinPoolRequest {
    IERC20[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  enum JoinKind { 
    INIT, 
    EXACT_TOKENS_IN_FOR_BPT_OUT, 
    TOKEN_IN_FOR_EXACT_BPT_OUT, 
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT 
  }

  enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
  }

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    address[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external returns (int256[] memory assetDeltas);

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external payable;

  function exitPool( 
    bytes32 poolId, 
    address sender, 
    address recipient, 
    ExitPoolRequest memory request 
  ) external;

  function getPoolTokens(
    bytes32 poolId
  ) external view
    returns (
      address[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
  );
}