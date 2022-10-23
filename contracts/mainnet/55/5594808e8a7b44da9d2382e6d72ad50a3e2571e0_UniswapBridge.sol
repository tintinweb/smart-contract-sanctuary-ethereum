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

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {AztecTypes} from "../libraries/AztecTypes.sol";

interface IDefiBridge {
    /**
     * @notice A function which converts input assets to output assets.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _totalInputValue An amount of input assets transferred to the bridge (Note: "total" is in the name
     *                         because the value can represent summed/aggregated token amounts of users actions on L2)
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @return isAsync A flag indicating if the interaction is async.
     * @dev This function is called from the RollupProcessor contract via the DefiBridgeProxy. Before this function is
     *      called _RollupProcessor_ contract will have sent you all the assets defined by the input params. This
     *      function is expected to convert input assets to output assets (e.g. on Uniswap) and return the amounts
     *      of output assets to be received by the _RollupProcessor_. If output assets are ERC20 tokens the bridge has
     *      to _RollupProcessor_ as a spender before the interaction is finished. If some of the output assets is ETH
     *      it has to be sent to _RollupProcessor_ via the `receiveEthFromBridge(uint256 _interactionNonce)` method
     *      inside before the `convert(...)` function call finishes.
     * @dev If there are two input assets, equal amounts of both assets will be transferred to the bridge before this
     *      method is called.
     * @dev **BOTH** output assets could be virtual but since their `assetId` is currently assigned as
     *      `_interactionNonce` it would simply mean that more of the same virtual asset is minted.
     * @dev If this interaction is async the function has to return `(0,0 true)`. Async interaction will be finalised at
     *      a later time and its output assets will be returned in a `IDefiBridge.finalise(...)` call.
     **/
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _totalInputValue,
        uint256 _interactionNonce,
        uint64 _auxData,
        address _rollupBeneficiary
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        );

    /**
     * @notice A function that finalises asynchronous interaction.
     * @param _inputAssetA A struct detailing the first input asset
     * @param _inputAssetB A struct detailing the second input asset
     * @param _outputAssetA A struct detailing the first output asset
     * @param _outputAssetB A struct detailing the second output asset
     * @param _interactionNonce A globally unique identifier of this interaction/`convert(...)` call.
     * @param _auxData Bridge specific data to be passed into the bridge contract (e.g. slippage, nftID etc.)
     * @return outputValueA An amount of `_outputAssetA` returned from this interaction.
     * @return outputValueB An amount of `_outputAssetB` returned from this interaction.
     * @dev This function should use the `BridgeBase.onlyRollup()` modifier to ensure it can only be called from
     *      the `RollupProcessor.processAsyncDefiInteraction(uint256 _interactionNonce)` method.
     **/
    function finalise(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata _inputAssetB,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata _outputAssetB,
        uint256 _interactionNonce,
        uint64 _auxData
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionComplete
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

// @dev For documentation of the functions within this interface see RollupProcessor contract
interface IRollupProcessor {
    /*----------------------------------------
    EVENTS
    ----------------------------------------*/
    event OffchainData(uint256 indexed rollupId, uint256 chunk, uint256 totalChunks, address sender);
    event RollupProcessed(uint256 indexed rollupId, bytes32[] nextExpectedDefiHashes, address sender);
    event DefiBridgeProcessed(
        uint256 indexed encodedBridgeCallData,
        uint256 indexed nonce,
        uint256 totalInputValue,
        uint256 totalOutputValueA,
        uint256 totalOutputValueB,
        bool result,
        bytes errorReason
    );
    event AsyncDefiBridgeProcessed(
        uint256 indexed encodedBridgeCallData,
        uint256 indexed nonce,
        uint256 totalInputValue
    );
    event Deposit(uint256 indexed assetId, address indexed depositorAddress, uint256 depositValue);
    event WithdrawError(bytes errorReason);
    event AssetAdded(uint256 indexed assetId, address indexed assetAddress, uint256 assetGasLimit);
    event BridgeAdded(uint256 indexed bridgeAddressId, address indexed bridgeAddress, uint256 bridgeGasLimit);
    event RollupProviderUpdated(address indexed providerAddress, bool valid);
    event VerifierUpdated(address indexed verifierAddress);
    event Paused(address account);
    event Unpaused(address account);

    /*----------------------------------------
      MUTATING FUNCTIONS
      ----------------------------------------*/

    function pause() external;

    function unpause() external;

    function setRollupProvider(address _provider, bool _valid) external;

    function setVerifier(address _verifier) external;

    function setAllowThirdPartyContracts(bool _allowThirdPartyContracts) external;

    function setDefiBridgeProxy(address _defiBridgeProxy) external;

    function setSupportedAsset(address _token, uint256 _gasLimit) external;

    function setSupportedBridge(address _bridge, uint256 _gasLimit) external;

    function processRollup(bytes calldata _encodedProofData, bytes calldata _signatures) external;

    function receiveEthFromBridge(uint256 _interactionNonce) external payable;

    function approveProof(bytes32 _proofHash) external;

    function depositPendingFunds(
        uint256 _assetId,
        uint256 _amount,
        address _owner,
        bytes32 _proofHash
    ) external payable;

    function offchainData(
        uint256 _rollupId,
        uint256 _chunk,
        uint256 _totalChunks,
        bytes calldata _offchainTxData
    ) external;

    function processAsyncDefiInteraction(uint256 _interactionNonce) external returns (bool);

    /*----------------------------------------
      NON-MUTATING FUNCTIONS
      ----------------------------------------*/

    function rollupStateHash() external view returns (bytes32);

    function userPendingDeposits(uint256 _assetId, address _user) external view returns (uint256);

    function defiBridgeProxy() external view returns (address);

    function prevDefiInteractionsHash() external view returns (bytes32);

    function paused() external view returns (bool);

    function verifier() external view returns (address);

    function getDataSize() external view returns (uint256);

    function getPendingDefiInteractionHashesLength() external view returns (uint256);

    function getDefiInteractionHashesLength() external view returns (uint256);

    function getAsyncDefiInteractionHashesLength() external view returns (uint256);

    function getSupportedBridge(uint256 _bridgeAddressId) external view returns (address);

    function getSupportedBridgesLength() external view returns (uint256);

    function getSupportedAssetsLength() external view returns (uint256);

    function getSupportedAsset(uint256 _assetId) external view returns (address);

    function getEscapeHatchStatus() external view returns (bool, uint256);

    function assetGasLimits(uint256 _bridgeAddressId) external view returns (uint256);

    function bridgeGasLimits(uint256 _bridgeAddressId) external view returns (uint256);

    function allowThirdPartyContracts() external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

// @dev documentation of this interface is in its implementation (Subsidy contract)
interface ISubsidy {
    /**
     * @notice Container for Subsidy related information
     * @member available Amount of ETH remaining to be paid out
     * @member gasUsage Amount of gas the interaction consumes (used to define max possible payout)
     * @member minGasPerMinute Minimum amount of gas per minute the subsidizer has to subsidize
     * @member gasPerMinute Amount of gas per minute the subsidizer is willing to subsidize
     * @member lastUpdated Last time subsidy was paid out or funded (if not subsidy was yet claimed after funding)
     */
    struct Subsidy {
        uint128 available;
        uint32 gasUsage;
        uint32 minGasPerMinute;
        uint32 gasPerMinute;
        uint32 lastUpdated;
    }

    function setGasUsageAndMinGasPerMinute(
        uint256 _criteria,
        uint32 _gasUsage,
        uint32 _minGasPerMinute
    ) external;

    function setGasUsageAndMinGasPerMinute(
        uint256[] calldata _criteria,
        uint32[] calldata _gasUsage,
        uint32[] calldata _minGasPerMinute
    ) external;

    function registerBeneficiary(address _beneficiary) external;

    function subsidize(
        address _bridge,
        uint256 _criteria,
        uint32 _gasPerMinute
    ) external payable;

    function topUp(address _bridge, uint256 _criteria) external payable;

    function claimSubsidy(uint256 _criteria, address _beneficiary) external returns (uint256);

    function withdraw(address _beneficiary) external returns (uint256);

    // solhint-disable-next-line
    function MIN_SUBSIDY_VALUE() external view returns (uint256);

    function claimableAmount(address _beneficiary) external view returns (uint256);

    function isRegistered(address _beneficiary) external view returns (bool);

    function getSubsidy(address _bridge, uint256 _criteria) external view returns (Subsidy memory);

    function getAccumulatedSubsidyAmount(address _bridge, uint256 _criteria) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

library AztecTypes {
    enum AztecAssetType {
        NOT_USED,
        ETH,
        ERC20,
        VIRTUAL
    }

    struct AztecAsset {
        uint256 id;
        address erc20Address;
        AztecAssetType assetType;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IDefiBridge} from "../../aztec/interfaces/IDefiBridge.sol";
import {ISubsidy} from "../../aztec/interfaces/ISubsidy.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";
import {ErrorLib} from "./ErrorLib.sol";

/**
 * @title BridgeBase
 * @notice A base that bridges can be built upon which imports a limited set of features
 * @dev Reverts `convert` with missing implementation, and `finalise` with async disabled
 * @author Lasse Herskind
 */
abstract contract BridgeBase is IDefiBridge {
    error MissingImplementation();

    ISubsidy public constant SUBSIDY = ISubsidy(0xABc30E831B5Cc173A9Ed5941714A7845c909e7fA);
    address public immutable ROLLUP_PROCESSOR;

    constructor(address _rollupProcessor) {
        ROLLUP_PROCESSOR = _rollupProcessor;
    }

    modifier onlyRollup() {
        if (msg.sender != ROLLUP_PROCESSOR) {
            revert ErrorLib.InvalidCaller();
        }
        _;
    }

    function convert(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint256,
        uint64,
        address
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert MissingImplementation();
    }

    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint256,
        uint64
    )
        external
        payable
        virtual
        override(IDefiBridge)
        returns (
            uint256,
            uint256,
            bool
        )
    {
        revert ErrorLib.AsyncDisabled();
    }

    /**
     * @notice Computes the criteria that is passed on to the subsidy contract when claiming
     * @dev Should be overridden by bridge implementation if intended to limit subsidy.
     * @return The criteria to be passed along
     */
    function computeCriteria(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        uint64
    ) public view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

library ErrorLib {
    error InvalidCaller();

    error InvalidInput();
    error InvalidInputA();
    error InvalidInputB();
    error InvalidOutputA();
    error InvalidOutputB();
    error InvalidInputAmount();
    error InvalidAuxData();

    error ApproveFailed(address token);
    error TransferFailed(address token);

    error InvalidNonce();
    error AsyncDisabled();
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AztecTypes} from "../../aztec/libraries/AztecTypes.sol";
import {IRollupProcessor} from "../../aztec/interfaces/IRollupProcessor.sol";
import {ErrorLib} from "../base/ErrorLib.sol";
import {BridgeBase} from "../base/BridgeBase.sol";
import {ISwapRouter} from "../../interfaces/uniswapv3/ISwapRouter.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {IQuoter} from "../../interfaces/uniswapv3/IQuoter.sol";

/**
 * @title Aztec Connect Bridge for swapping on Uniswap v3
 * @author Jan Benes (@benesjan on Github and Telegram)
 * @notice You can use this contract to swap tokens on Uniswap v3 along complex paths.
 * @dev Encoding of a path allows for up to 2 split paths (see the definition bellow) and up to 3 pools (2 middle
 *      tokens) in each split path. A path is encoded in _auxData parameter passed to the convert method. _auxData
 *      carry 64 bits of information. Along with split paths there is a minimum price encoded in auxData.
 *
 *      Each split path takes 19 bits. Minimum price is encoded in 26 bits. Values are placed in the data as follows:
 *          |26 bits minimum price| |19 bits split path 2| |19 bits split path 1|
 *
 *      Encoding of a split path is:
 *          |7 bits percentage| |2 bits fee| |3 bits middle token| |2 bits fee| |3 bits middle token| |2 bits fee|
 *      The meaning of percentage is how much of input amount will be routed through the corresponding split path.
 *      Fee bits are mapped to specific fee tiers as follows:
 *          00 is 0.01%, 01 is 0.05%, 10 is 0.3%, 11 is 1%
 *      Middle tokens use the following mapping:
 *          001 is ETH, 010 is USDC, 011 is USDT, 100 is DAI, 101 is WBTC, 110 is FRAX, 111 is BUSD.
 *          000 means the middle token is unused.
 *
 *      Min price is encoded as a floating point number. First 21 bits are used for significand, last 5 bits for
 *      exponent: |21 bits significand| |5 bits exponent|
 *      To convert minimum price to this format call encodeMinPrice(...) function on this contract.
 *      Minimum amount out is computed with the following formula:
 *          (inputValue * (significand * 10**exponent)) / (10 ** inputAssetDecimals)
 *      Here are 2 examples.
 *      1) If I want to receive 10k Dai for 1 ETH I would set significand to 1 and exponent to 22.
 *         _totalInputValue = 1e18, asset = ETH (18 decimals), outputAssetA: Dai (18 decimals)
 *         (1e18 * (1 * 10**22)) / (10**18) = 1e22 --> 10k Dai
 *      2) If I want to receive 2000 USDC for 1 ETH, I set significand to 2 and exponent to 9.
 *         _totalInputValue = 1e18, asset = ETH (18 decimals), outputAssetA: USDC (6 decimals)
 *         (1e18 * (2 * 10**9)) / (10**18) = 2e9 --> 2000 USDC
 *
 *      Definition of split path: Split path is a term we use when there are multiple (in this case 2) paths between
 *      which the input amount of tokens is split. As an example we can consider swapping 100 ETH to DAI. In this case
 *      there could be 2 split paths. 1st split path going through ETH-USDC 500 bps fee pool and USDC-DAI 100 bps fee
 *      pool and 2nd split path going directly to DAI using the ETH-DAI 500 bps pool. First split path could for
 *      example consume 80% of input (80 ETH) and the second split path the remaining 20% (20 ETH).
 */
contract UniswapBridge is BridgeBase {
    using SafeERC20 for IERC20;

    error InvalidFeeTierEncoding();
    error InvalidFeeTier();
    error InvalidTokenEncoding();
    error InvalidToken();
    error InvalidPercentageAmounts();
    error InsufficientAmountOut();
    error Overflow();

    // @notice A struct representing a path with 2 split paths.
    struct Path {
        uint256 percentage1; // Percentage of input to swap through splitPath1
        bytes splitPath1; // A path encoded in a format used by Uniswap's v3 router
        uint256 percentage2; // Percentage of input to swap through splitPath2
        bytes splitPath2; // A path encoded in a format used by Uniswap's v3 router
        uint256 minPrice; // Minimum acceptable price
    }

    struct SplitPath {
        uint256 percentage; // Percentage of swap amount to send through this split path
        uint256 fee1; // 1st pool fee
        address token1; // Address of the 1st pool's output token
        uint256 fee2; // 2nd pool fee
        address token2; // Address of the 2nd pool's output token
        uint256 fee3; // 3rd pool fee
    }

    // @dev Event which is emitted when the output token doesn't implement decimals().
    event DefaultDecimalsWarning();

    ISwapRouter public constant ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public constant QUOTER = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    // Addresses of middle tokens
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

    uint64 public constant SPLIT_PATH_BIT_LENGTH = 19;
    uint64 public constant SPLIT_PATHS_BIT_LENGTH = 38; // SPLIT_PATH_BIT_LENGTH * 2
    uint64 public constant PRICE_BIT_LENGTH = 26; // 64 - SPLIT_PATHS_BIT_LENGTH

    // @dev The following masks are used to decode 2 split paths and minimum acceptable price from 1 uint64.
    // Binary number 0000000000000000000000000000000000000000000001111111111111111111 (last 19 bits)
    uint64 public constant SPLIT_PATH_MASK = 0x7FFFF;

    // Binary number 0000000000000000000000000000000000000011111111111111111111111111 (last 26 bits)
    uint64 public constant PRICE_MASK = 0x3FFFFFF;

    // Binary number 0000000000000000000000000000000000000000000000000000000000011111 (last 5 bits)
    uint64 public constant EXPONENT_MASK = 0x1F;

    // Binary number 11
    uint64 public constant FEE_MASK = 0x3;
    // Binary number 111
    uint64 public constant TOKEN_MASK = 0x7;

    /**
     * @notice Set the address of rollup processor.
     * @param _rollupProcessor Address of rollup processor
     */
    constructor(address _rollupProcessor) BridgeBase(_rollupProcessor) {}

    // @dev Empty method which is present here in order to be able to receive ETH when unwrapping WETH.
    receive() external payable {}

    /**
     * @notice Sets all the important approvals.
     * @param _tokensIn - An array of address of input tokens (tokens to later swap in the convert(...) function)
     * @param _tokensOut - An array of address of output tokens (tokens to later return to rollup processor)
     * @dev SwapBridge never holds any ERC20 tokens after or before an invocation of any of its functions. For this
     * reason the following is not a security risk and makes convert(...) function more gas efficient.
     */
    function preApproveTokens(address[] calldata _tokensIn, address[] calldata _tokensOut) external {
        uint256 tokensLength = _tokensIn.length;
        for (uint256 i; i < tokensLength; ) {
            address tokenIn = _tokensIn[i];
            // Using safeApprove(...) instead of approve(...) and first setting the allowance to 0 because underlying
            // can be Tether
            IERC20(tokenIn).safeApprove(address(ROUTER), 0);
            IERC20(tokenIn).safeApprove(address(ROUTER), type(uint256).max);
            unchecked {
                ++i;
            }
        }
        tokensLength = _tokensOut.length;
        for (uint256 i; i < tokensLength; ) {
            address tokenOut = _tokensOut[i];
            // Using safeApprove(...) instead of approve(...) and first setting the allowance to 0 because underlying
            // can be Tether
            IERC20(tokenOut).safeApprove(address(ROLLUP_PROCESSOR), 0);
            IERC20(tokenOut).safeApprove(address(ROLLUP_PROCESSOR), type(uint256).max);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice A function which swaps input token for output token along the path encoded in _auxData.
     * @param _inputAssetA - Input ERC20 token
     * @param _outputAssetA - Output ERC20 token
     * @param _totalInputValue - Amount of input token to swap
     * @param _interactionNonce - Interaction nonce
     * @param _auxData - Encoded path (gets decoded to Path struct)
     * @return outputValueA - The amount of output token received
     */
    function convert(
        AztecTypes.AztecAsset calldata _inputAssetA,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata _outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 _totalInputValue,
        uint256 _interactionNonce,
        uint64 _auxData,
        address
    )
        external
        payable
        override(BridgeBase)
        onlyRollup
        returns (
            uint256 outputValueA,
            uint256,
            bool
        )
    {
        bool inputIsEth = _inputAssetA.assetType == AztecTypes.AztecAssetType.ETH;
        bool outputIsEth = _outputAssetA.assetType == AztecTypes.AztecAssetType.ETH;

        if (_inputAssetA.assetType != AztecTypes.AztecAssetType.ERC20 && !inputIsEth) {
            revert ErrorLib.InvalidInputA();
        }
        if (_outputAssetA.assetType != AztecTypes.AztecAssetType.ERC20 && !outputIsEth) {
            revert ErrorLib.InvalidOutputA();
        }

        Path memory path = _decodePath(
            inputIsEth ? WETH : _inputAssetA.erc20Address,
            _auxData,
            outputIsEth ? WETH : _outputAssetA.erc20Address
        );

        uint256 inputValueSplitPath1 = (_totalInputValue * path.percentage1) / 100;

        if (path.percentage1 != 0) {
            // Swap using the first swap path
            outputValueA = ROUTER.exactInput{value: inputIsEth ? inputValueSplitPath1 : 0}(
                ISwapRouter.ExactInputParams({
                    path: path.splitPath1,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: inputValueSplitPath1,
                    amountOutMinimum: 0
                })
            );
        }

        if (path.percentage2 != 0) {
            // Swap using the second swap path
            uint256 inputValueSplitPath2 = _totalInputValue - inputValueSplitPath1;
            outputValueA += ROUTER.exactInput{value: inputIsEth ? inputValueSplitPath2 : 0}(
                ISwapRouter.ExactInputParams({
                    path: path.splitPath2,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: inputValueSplitPath2,
                    amountOutMinimum: 0
                })
            );
        }

        uint256 tokenInDecimals = 18;
        if (!inputIsEth) {
            try IERC20Metadata(_inputAssetA.erc20Address).decimals() returns (uint8 decimals) {
                tokenInDecimals = decimals;
            } catch (bytes memory) {
                emit DefaultDecimalsWarning();
            }
        }
        uint256 amountOutMinimum = (_totalInputValue * path.minPrice) / 10**tokenInDecimals;
        if (outputValueA < amountOutMinimum) revert InsufficientAmountOut();

        if (outputIsEth) {
            IWETH(WETH).withdraw(outputValueA);
            IRollupProcessor(ROLLUP_PROCESSOR).receiveEthFromBridge{value: outputValueA}(_interactionNonce);
        }
    }

    /**
     * @notice A function which encodes path to a format expected in _auxData of this.convert(...)
     * @param _amountIn - Amount of tokenIn to swap
     * @param _minAmountOut - Amount of tokenOut to receive
     * @param _tokenIn - Address of _tokenIn (@dev used only to fetch decimals)
     * @param _splitPath1 - Split path to encode
     * @param _splitPath2 - Split path to encode
     * @return Path encoded in a format expected in _auxData of this.convert(...)
     * @dev This function is not optimized and is expected to be used on frontend and in tests.
     * @dev Reverts when min price is bigger than max encodeable value.
     */
    function encodePath(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _tokenIn,
        SplitPath calldata _splitPath1,
        SplitPath calldata _splitPath2
    ) external view returns (uint64) {
        if (_splitPath1.percentage + _splitPath2.percentage != 100) revert InvalidPercentageAmounts();

        return
            uint64(
                (_computeEncodedMinPrice(_amountIn, _minAmountOut, IERC20Metadata(_tokenIn).decimals()) <<
                    SPLIT_PATHS_BIT_LENGTH) +
                    (_encodeSplitPath(_splitPath1) << SPLIT_PATH_BIT_LENGTH) +
                    _encodeSplitPath(_splitPath2)
            );
    }

    /**
     * @notice A function which encodes path to a format expected in _auxData of this.convert(...)
     * @param _amountIn - Amount of tokenIn to swap
     * @param _tokenIn - Address of _tokenIn (@dev used only to fetch decimals)
     * @param _path - Split path to encode
     * @param _tokenOut - Address of _tokenIn (@dev used only to fetch decimals)
     * @return amountOut -
     */
    function quote(
        uint256 _amountIn,
        address _tokenIn,
        uint64 _path,
        address _tokenOut
    ) external returns (uint256 amountOut) {
        Path memory path = _decodePath(_tokenIn, _path, _tokenOut);
        uint256 inputValueSplitPath1 = (_amountIn * path.percentage1) / 100;

        if (path.percentage1 != 0) {
            // Swap using the first swap path
            amountOut += QUOTER.quoteExactInput(path.splitPath1, inputValueSplitPath1);
        }

        if (path.percentage2 != 0) {
            // Swap using the second swap path
            amountOut += QUOTER.quoteExactInput(path.splitPath2, _amountIn - inputValueSplitPath1);
        }
    }

    /**
     * @notice A function which computes min price and encodes it in the format used in this bridge.
     * @param _amountIn - Amount of tokenIn to swap
     * @param _minAmountOut - Amount of tokenOut to receive
     * @param _tokenInDecimals - Number of decimals of tokenIn
     * @return encodedMinPrice - Min acceptable encoded in a format used in this bridge.
     * @dev This function is not optimized and is expected to be used on frontend and in tests.
     * @dev Reverts when min price is bigger than max encodeable value.
     */
    function _computeEncodedMinPrice(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _tokenInDecimals
    ) internal pure returns (uint256 encodedMinPrice) {
        uint256 minPrice = (_minAmountOut * 10**_tokenInDecimals) / _amountIn;
        // 2097151 = 2**21 - 1 --> this number and its multiples of 10 can be encoded without precision loss
        if (minPrice <= 2097151) {
            // minPrice is smaller than the boundary of significand --> significand = _x, exponent = 0
            encodedMinPrice = minPrice << 5;
        } else {
            uint256 exponent = 0;
            while (minPrice > 2097151) {
                minPrice /= 10;
                ++exponent;
                // 31 = 2**5 - 1 --> max exponent
                if (exponent > 31) revert Overflow();
            }
            encodedMinPrice = (minPrice << 5) + exponent;
        }
    }

    /**
     * @notice A function which encodes a split path.
     * @param _path - Split path to encode
     * @return Encoded split path (in the last 19 bits of uint)
     * @dev In place of unused middle tokens and address(0). When fee tier is unused place there any valid value. This
     *      value gets ignored.
     */
    function _encodeSplitPath(SplitPath calldata _path) internal pure returns (uint256) {
        if (_path.percentage == 0) return 0;
        return
            (_path.percentage << 12) +
            (_encodeFeeTier(_path.fee1) << 10) +
            (_encodeMiddleToken(_path.token1) << 7) +
            (_encodeFeeTier(_path.fee2) << 5) +
            (_encodeMiddleToken(_path.token2) << 2) +
            (_encodeFeeTier(_path.fee3));
    }

    /**
     * @notice A function which encodes fee tier.
     * @param _feeTier - Fee tier in bps
     * @return Encoded fee tier (in the last 2 bits of uint)
     */
    function _encodeFeeTier(uint256 _feeTier) internal pure returns (uint256) {
        if (_feeTier == 100) {
            // Binary number 00
            return 0;
        }
        if (_feeTier == 500) {
            // Binary number 01
            return 1;
        }
        if (_feeTier == 3000) {
            // Binary number 10
            return 2;
        }
        if (_feeTier == 10000) {
            // Binary number 11
            return 3;
        }
        revert InvalidFeeTier();
    }

    /**
     * @notice A function which returns token encoding for a given token address.
     * @param _token - Token address
     * @return encodedToken - Encoded token (in the last 3 bits of uint256)
     */
    function _encodeMiddleToken(address _token) internal pure returns (uint256 encodedToken) {
        if (_token == address(0)) {
            // unused token
            return 0;
        }
        if (_token == WETH) {
            // binary number 001
            return 1;
        }
        if (_token == USDC) {
            // binary number 010
            return 2;
        }
        if (_token == USDT) {
            // binary number 011
            return 3;
        }
        if (_token == DAI) {
            // binary number 100
            return 4;
        }
        if (_token == WBTC) {
            // binary number 101
            return 5;
        }
        if (_token == FRAX) {
            // binary number 110
            return 6;
        }
        if (_token == BUSD) {
            // binary number 111
            return 7;
        }
        revert InvalidToken();
    }

    /**
     * @notice A function which deserializes encoded path to Path struct.
     * @param _tokenIn - Input ERC20 token
     * @param _encodedPath - Encoded path
     * @param _tokenOut - Output ERC20 token
     * @return path - Decoded/deserialized path struct
     */
    function _decodePath(
        address _tokenIn,
        uint256 _encodedPath,
        address _tokenOut
    ) internal pure returns (Path memory path) {
        (uint256 percentage1, bytes memory splitPath1) = _decodeSplitPath(
            _tokenIn,
            _encodedPath & SPLIT_PATH_MASK,
            _tokenOut
        );
        path.percentage1 = percentage1;
        path.splitPath1 = splitPath1;

        (uint256 percentage2, bytes memory splitPath2) = _decodeSplitPath(
            _tokenIn,
            (_encodedPath >> SPLIT_PATH_BIT_LENGTH) & SPLIT_PATH_MASK,
            _tokenOut
        );

        if (percentage1 + percentage2 != 100) revert InvalidPercentageAmounts();

        path.percentage2 = percentage2;
        path.splitPath2 = splitPath2;
        path.minPrice = _decodeMinPrice(_encodedPath >> SPLIT_PATHS_BIT_LENGTH);
    }

    /**
     * @notice A function which returns a percentage of input going through the split path and the split path encoded
     *         in a format compatible with Uniswap router.
     * @param _tokenIn - Input ERC20 token
     * @param _encodedSplitPath - Encoded split path (in the last 19 bits of uint256)
     * @param _tokenOut - Output ERC20 token
     * @return percentage - A percentage of input going through the corresponding split path
     * @return splitPath - A split path encoded in a format compatible with Uniswap router
     */
    function _decodeSplitPath(
        address _tokenIn,
        uint256 _encodedSplitPath,
        address _tokenOut
    ) internal pure returns (uint256 percentage, bytes memory splitPath) {
        uint256 fee3 = _encodedSplitPath & FEE_MASK;
        uint256 middleToken2 = (_encodedSplitPath >> 2) & TOKEN_MASK;
        uint256 fee2 = (_encodedSplitPath >> 5) & FEE_MASK;
        uint256 middleToken1 = (_encodedSplitPath >> 7) & TOKEN_MASK;
        uint256 fee1 = (_encodedSplitPath >> 10) & FEE_MASK;
        percentage = _encodedSplitPath >> 12;

        if (middleToken1 != 0 && middleToken2 != 0) {
            splitPath = abi.encodePacked(
                _tokenIn,
                _decodeFeeTier(fee1),
                _decodeMiddleToken(middleToken1),
                _decodeFeeTier(fee2),
                _decodeMiddleToken(middleToken2),
                _decodeFeeTier(fee3),
                _tokenOut
            );
        } else if (middleToken1 != 0) {
            splitPath = abi.encodePacked(
                _tokenIn,
                _decodeFeeTier(fee1),
                _decodeMiddleToken(middleToken1),
                _decodeFeeTier(fee3),
                _tokenOut
            );
        } else if (middleToken2 != 0) {
            splitPath = abi.encodePacked(
                _tokenIn,
                _decodeFeeTier(fee2),
                _decodeMiddleToken(middleToken2),
                _decodeFeeTier(fee3),
                _tokenOut
            );
        } else {
            splitPath = abi.encodePacked(_tokenIn, _decodeFeeTier(fee3), _tokenOut);
        }
    }

    /**
     * @notice A function which converts minimum price in a floating point format to integer.
     * @param _encodedMinPrice - Encoded minimum price (in the last 26 bits of uint256)
     * @return minPrice - Minimum acceptable price represented as an integer
     */
    function _decodeMinPrice(uint256 _encodedMinPrice) internal pure returns (uint256 minPrice) {
        // 21 bits significand, 5 bits exponent
        uint256 significand = _encodedMinPrice >> 5;
        uint256 exponent = _encodedMinPrice & EXPONENT_MASK;
        minPrice = significand * 10**exponent;
    }

    /**
     * @notice A function which converts encoded fee tier to a fee tier in an integer format.
     * @param _encodedFeeTier - Encoded fee tier (in the last 2 bits of uint256)
     * @return feeTier - Decoded fee tier in an integer format
     */
    function _decodeFeeTier(uint256 _encodedFeeTier) internal pure returns (uint24 feeTier) {
        if (_encodedFeeTier == 0) {
            // Binary number 00
            return uint24(100);
        }
        if (_encodedFeeTier == 1) {
            // Binary number 01
            return uint24(500);
        }
        if (_encodedFeeTier == 2) {
            // Binary number 10
            return uint24(3000);
        }
        if (_encodedFeeTier == 3) {
            // Binary number 11
            return uint24(10000);
        }
        revert InvalidFeeTierEncoding();
    }

    /**
     * @notice A function which returns token address for an encoded token.
     * @param _encodedToken - Encoded token (in the last 3 bits of uint256)
     * @return token - Token address
     */
    function _decodeMiddleToken(uint256 _encodedToken) internal pure returns (address token) {
        if (_encodedToken == 1) {
            // binary number 001
            return WETH;
        }
        if (_encodedToken == 2) {
            // binary number 010
            return USDC;
        }
        if (_encodedToken == 3) {
            // binary number 011
            return USDT;
        }
        if (_encodedToken == 4) {
            // binary number 100
            return DAI;
        }
        if (_encodedToken == 5) {
            // binary number 101
            return WBTC;
        }
        if (_encodedToken == 6) {
            // binary number 110
            return FRAX;
        }
        if (_encodedToken == 7) {
            // binary number 111
            return BUSD;
        }
        revert InvalidTokenEncoding();
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec.
pragma solidity >=0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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