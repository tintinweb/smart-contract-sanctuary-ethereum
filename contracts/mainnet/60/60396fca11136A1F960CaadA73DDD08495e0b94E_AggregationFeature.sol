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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../interfaces/IBKFees.sol";
import "../interfaces/IBKRegistry.sol";
import "../utils/TransferHelper.sol";

import {
    BasicParams,
    AggregationParams,
    SwapType,
    OrderInfo
} from "../interfaces/IBKStructsAndEnums.sol";

import { 
    IBKErrors
} from "../interfaces/IBKErrors.sol";

library AggregationFeature {
    string public constant FEATURE_NAME = "BitKeep SOR: Aggregation Feature";
    string public constant FEATURE_VERSION = "1.0";

    address public constant BK_FEES = 0xE4DA6f981a78b8b9edEfE4D7a955C04bA7e67D8D;
    address public constant BK_REGISTRY = 0x9aFD2948F573DD8684347924eBcE1847D50621eD;

    bytes4 public constant FUNC_SWAP = bytes4(keccak256(bytes("swap(AggregationFeature.SwapDetail)"))); // 0x6a2b69f0
   
    event BKSwapV2(
        SwapType indexed swapType,
        address indexed receiver,
        uint feeAmount,
        string featureName,
        string featureVersion
    );

    event OrderInfoEvent(
        bytes transferId,
        uint dstChainId,
        address sender,
        address bridgeReceiver,
        address tokenIn,
        address desireToken,
        uint amount
    );

    struct SwapDetail {
        BasicParams basicParams;
        AggregationParams aggregationParams;
        OrderInfo orderInfo;
    }

    function swap(SwapDetail calldata swapDetail) public {
        if(!IBKRegistry(BK_REGISTRY).isCallTarget(FUNC_SWAP, swapDetail.aggregationParams.callTarget)) {
            revert IBKErrors.IllegalCallTarget();
        }

        if(!IBKRegistry(BK_REGISTRY).isApproveTarget(FUNC_SWAP, swapDetail.aggregationParams.approveTarget)) {
            revert IBKErrors.IllegalApproveTarget();
        }

       (address feeTo, address altcoinFeeTo, uint feeRate) = IBKFees(BK_FEES).getFeeTo();

        if(swapDetail.basicParams.swapType > SwapType.WHITE_TO_TOKEN) {
            revert IBKErrors.SwapTypeNotAvailable();
        }

        if(swapDetail.basicParams.swapType == SwapType.FREE) {
            _swapForFree(swapDetail);
        } else if(swapDetail.basicParams.swapType == SwapType.ETH_TOKEN) {
            if(msg.value < swapDetail.basicParams.amountInForSwap) {
                revert IBKErrors.SwapEthBalanceNotEnough();
            }
            _swapEth2Token(swapDetail, payable(feeTo), feeRate);
        } else {
            _swapToken2Others(swapDetail, payable(feeTo), altcoinFeeTo, feeRate);
        }
    }

    function _swapForFree(SwapDetail calldata swapDetail) internal {
        IBKFees(BK_FEES).checkIsSigner(
            swapDetail.basicParams.signParams.nonceHash,
            swapDetail.basicParams.signParams.signature
        );

        IERC20 fromToken = IERC20(swapDetail.basicParams.fromTokenAddress);

        bool toTokenIsETH = TransferHelper.isETH(swapDetail.basicParams.toTokenAddress);

        if(TransferHelper.isETH(swapDetail.basicParams.fromTokenAddress)) {
            if(msg.value < swapDetail.basicParams.amountInForSwap) {
                revert IBKErrors.SwapEthBalanceNotEnough();
            }
        } else {
            uint fromBalanceOfThis = fromToken.balanceOf(address(this));

            if(fromBalanceOfThis < swapDetail.basicParams.amountInTotal) {
                revert IBKErrors.BurnToMuch();
            }

            TransferHelper.approveMax(
                fromToken,
                swapDetail.aggregationParams.approveTarget,
                swapDetail.basicParams.amountInTotal
            );
        }

        uint balanceOfThis = 
            toTokenIsETH ?
            address(this).balance : IERC20(swapDetail.basicParams.toTokenAddress).balanceOf(address(this));

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: msg.value}(swapDetail.aggregationParams.data);
        _checkCallResult(success);

        uint balanceNow = 
            toTokenIsETH ?
            address(this).balance : IERC20(swapDetail.basicParams.toTokenAddress).balanceOf(address(this));

        if(toTokenIsETH) {
            TransferHelper.safeTransferETH(swapDetail.basicParams.receiver, balanceNow - balanceOfThis);
        } else {
            TransferHelper.safeTransfer(swapDetail.basicParams.toTokenAddress, swapDetail.basicParams.receiver, balanceNow - balanceOfThis);
        }

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            0,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            balanceNow - balanceOfThis
        );
    }

    function _swapEth2Token(SwapDetail calldata swapDetail, address payable _feeTo, uint _feeRate) internal {
        IERC20 toToken = IERC20(swapDetail.basicParams.toTokenAddress);

        uint beforeBalanceOfToken = toToken.balanceOf(address(this));

        uint feeAmount = swapDetail.basicParams.amountInTotal * _feeRate / 1e4;
        TransferHelper.safeTransferETH(_feeTo, feeAmount);

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: swapDetail.basicParams.amountInForSwap}(swapDetail.aggregationParams.data);

        _checkCallResult(success);

        uint afterBalanceOfToken = toToken.balanceOf(address(this));

        TransferHelper.safeTransfer(
            swapDetail.basicParams.toTokenAddress,
            swapDetail.basicParams.receiver,
            afterBalanceOfToken - beforeBalanceOfToken
        );

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            afterBalanceOfToken - beforeBalanceOfToken
        );
    }

    function _swapToken2Others(SwapDetail calldata swapDetail, address feeTo, address altcoinFeeTo, uint feeRate) internal {
        IERC20 fromToken = IERC20(swapDetail.basicParams.fromTokenAddress);

        uint balanceOfThis = fromToken.balanceOf(address(this));

        if(balanceOfThis < swapDetail.basicParams.amountInTotal) {
            revert IBKErrors.BurnToMuch();
        }

        TransferHelper.approveMax(
            fromToken,
            swapDetail.aggregationParams.approveTarget,
            swapDetail.basicParams.amountInTotal
        );

        if(swapDetail.basicParams.swapType == SwapType.TOKEN_ETH) {
            _swapToken2ETH(swapDetail, payable(feeTo), feeRate);
        } else if(swapDetail.basicParams.swapType == SwapType.TOKEN_TO_WHITE) {
            _swapToken2white(swapDetail, feeTo, feeRate);
        } else {
            _swapToken2token(
                swapDetail,
                swapDetail.basicParams.swapType == SwapType.TOKEN_TOKEN ? altcoinFeeTo : feeTo,
                feeRate
            );
        }
    }

    function _swapToken2ETH(SwapDetail calldata swapDetail, address payable _feeTo, uint _feeRate) internal {
        uint balanceBefore = address(this).balance;
        uint feeAmount;
        uint swappedAmount;

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: 0}(swapDetail.aggregationParams.data);
        _checkCallResult(success);
        
        swappedAmount = address(this).balance - balanceBefore;

        feeAmount = swappedAmount * _feeRate / 1e4;
        TransferHelper.safeTransferETH(_feeTo, feeAmount);

        TransferHelper.safeTransferETH(swapDetail.basicParams.receiver, swappedAmount - feeAmount);
        
        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            swappedAmount - feeAmount
        );
    }

    function _swapToken2token(SwapDetail calldata swapDetail, address _feeTo, uint _feeRate) internal {
        IERC20 toToken = IERC20(swapDetail.basicParams.toTokenAddress);
        uint balanceBefore = toToken.balanceOf(address(this));
        uint feeAmount;

        feeAmount = swapDetail.basicParams.amountInTotal * _feeRate / 1e4;
        TransferHelper.safeTransfer(swapDetail.basicParams.fromTokenAddress, _feeTo, feeAmount);

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: 0}(swapDetail.aggregationParams.data);
        _checkCallResult(success);

        uint balanceAfter = toToken.balanceOf(address(this));
        
        TransferHelper.safeTransfer(
            swapDetail.basicParams.toTokenAddress,
            swapDetail.basicParams.receiver,
            balanceAfter- balanceBefore
        );

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );

        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            balanceAfter- balanceBefore
        );
    }

    function _swapToken2white(SwapDetail calldata swapDetail, address _feeTo, uint _feeRate) internal {
        IERC20 toToken = IERC20(swapDetail.basicParams.toTokenAddress);

        uint balanceBefore = toToken.balanceOf(address(this));
        uint swappedAmount;
        uint feeAmount;

        (bool success, ) = swapDetail.aggregationParams.callTarget.call{value: 0}(swapDetail.aggregationParams.data);
        _checkCallResult(success);

        swappedAmount = toToken.balanceOf(address(this)) - balanceBefore;

        feeAmount = swappedAmount * _feeRate / 1e4;
        TransferHelper.safeTransfer(swapDetail.basicParams.toTokenAddress, _feeTo, feeAmount);

        TransferHelper.safeTransfer(swapDetail.basicParams.toTokenAddress, swapDetail.basicParams.receiver, swappedAmount - feeAmount);

        emit BKSwapV2(
            swapDetail.basicParams.swapType,
            swapDetail.basicParams.receiver,
            feeAmount,
            FEATURE_NAME,
            FEATURE_VERSION
        );
        
        emit OrderInfoEvent(
            swapDetail.orderInfo.transferId,
            swapDetail.orderInfo.dstChainId,
            msg.sender,
            swapDetail.orderInfo.bridgeReceiver,
            swapDetail.basicParams.fromTokenAddress,
            swapDetail.orderInfo.desireToken,
            swappedAmount - feeAmount
        );
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IBKErrors {
    error InvalidMsgSig();
    error InsufficientEtherSupplied();
    error FeatureNotExist();
    error FeatureInActive();
    error InvalidCaller();
    error InvalidSigner();
    error InvalidNonce(bytes32 signMsg);
    error InvalidZeroAddress();  
    error InvalidFeeRate(uint256 feeRate);
    error SwapEthBalanceNotEnough();
    error SwapTokenBalanceNotEnough();
    error SwapTokenApproveNotEnough();
    error SwapInsuffenceOutPut();
    error SwapTypeNotAvailable();
    error BurnToMuch();
    error IllegalCallTarget();
    error IllegalApproveTarget(); 
    error InvalidSwapAddress(address);
    error CallException(address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IBKFees {
    function checkIsSigner(bytes32 _nonceHash, bytes calldata _signature) external;

    function setSigner(address _signer) external;
    
    function getSigner() external view returns(address);
  
    function setFeeTo (
        address payable _feeTo,
        address payable _altcoinsFeeTo,
        uint _feeRate
    )  external;

    function getFeeTo () external view returns(
        address payable _feeTo,
        address payable _altcoinsFeeTo,
        uint _feeRate
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IBKRegistry {    
    function setFeature( bytes4 _methodId, address _proxy, bool _isLib, bool _isActive) external;

    function getFeature(bytes4 _methodId) external view returns(address proxy, bool isLib);

    function setCallTarget(bytes4 _methodId, address [] memory _targets, bool _isEnable) external;

    function isCallTarget(bytes4 _methodId, address _target) external view returns(bool);

    function setApproveTarget(bytes4 _methodId, address [] memory _targets, bool _isEnable) external;

    function isApproveTarget(bytes4 _methodId, address _target) external view returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

struct OrderInfo{
    bytes transferId;
    uint dstChainId;
    address desireToken;
    address bridgeReceiver;
}

enum SwapType {
    FREE,
    ETH_TOKEN,
    TOKEN_ETH,
    TOKEN_TOKEN,
    TOKEN_TO_WHITE,
    WHITE_TO_TOKEN
}

struct SignParams {
    bytes32 nonceHash;
    bytes signature;
}

struct BasicParams {
    SignParams signParams;
    SwapType swapType;
    address fromTokenAddress;
    address toTokenAddress;
    uint amountInTotal;
    uint amountInForSwap;
    address receiver;
    uint minAmountOut;
}

struct AggregationParams {
    address approveTarget;
    address callTarget;
    bytes data;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TransferHelper {
    using SafeERC20 for IERC20;

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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
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
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
       (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }

    function approveMax(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) internal {
        uint256 allowance = _token.allowance(address(this), address(_spender));
        if (allowance < _amount) {
            if (allowance > 0) {
                _token.safeApprove(address(_spender), 0);
            }
            _token.safeApprove(address(_spender), type(uint256).max);
        }
    }

    function isETH(address _tokenAddress) internal pure returns (bool) {
        return
            (_tokenAddress == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) ||
            (_tokenAddress == 0x0000000000000000000000000000000000000000);
    }
}