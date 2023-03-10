// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./IWETH.sol";
import "./IWormhole.sol";

interface ITokenBridge {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct TransferWithPayload {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        bytes32 fromAddress;
        bytes payload;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;

        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

     struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;

        bytes32 newContract;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    function _parseTransferCommon(bytes memory encoded) external pure returns (Transfer memory transfer);

    function attestToken(address tokenAddress, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETHWithPayload(uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function transferTokensWithPayload(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function updateWrapped(bytes memory encodedVm) external returns (address token);

    function createWrapped(bytes memory encodedVm) external returns (address token);

    function completeTransferWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransfer(bytes memory encodedVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodedVm) external;

    function encodeAssetMeta(AssetMeta memory meta) external pure returns (bytes memory encoded);

    function encodeTransfer(Transfer memory transfer) external pure returns (bytes memory encoded);

    function encodeTransferWithPayload(TransferWithPayload memory transfer) external pure returns (bytes memory encoded);

    function parsePayloadID(bytes memory encoded) external pure returns (uint8 payloadID);

    function parseAssetMeta(bytes memory encoded) external pure returns (AssetMeta memory meta);

    function parseTransfer(bytes memory encoded) external pure returns (Transfer memory transfer);

    function parseTransferWithPayload(bytes memory encoded) external pure returns (TransferWithPayload memory transfer);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function evmChainId() external view returns (uint256);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);

    function bridgeContracts(uint16 chainId_) external view returns (bytes32);

    function tokenImplementation() external view returns (address);

    function WETH() external view returns (IWETH);

    function outstandingBridged(address token) external view returns (uint256);

    function isWrappedAsset(address token) external view returns (bool);

    function finality() external view returns (uint8);

    function implementation() external view returns (address);

    function initialize() external;

    function registerChain(bytes memory encodedVM) external;

    function upgrade(bytes memory encodedVM) external;

    function submitRecoverChainId(bytes memory encodedVM) external;

    function parseRegisterChain(bytes memory encoded) external pure returns (RegisterChain memory chain);

    function parseUpgrade(bytes memory encoded) external pure returns (UpgradeContract memory chain);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
    function balanceOf() external returns (uint256);
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";

import "../libraries/BytesLib.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TokenBridgeRelayerGovernance.sol";
import "./TokenBridgeRelayerMessages.sol";

/**
 * @title Wormhole Token Bridge Relayer
 * @notice This contract composes on Wormhole's Token Bridge contracts to faciliate
 * one-click transfers of Token Bridge supported assets cross chain.
 */
contract TokenBridgeRelayer is TokenBridgeRelayerGovernance, TokenBridgeRelayerMessages, ReentrancyGuard {
    using BytesLib for bytes;

    constructor(
        uint16 chainId,
        address wormhole,
        address tokenBridge_,
        address wethAddress,
        bool unwrapWeth_
    ) {
        require(chainId > 0, "invalid chainId");
        require(wormhole != address(0), "invalid wormhole address");
        require(tokenBridge_ != address(0), "invalid token bridge address");
        require(wethAddress != address(0), "invalid weth address");

        // set initial state
        setOwner(msg.sender);
        setChainId(chainId);
        setWormhole(wormhole);
        setTokenBridge(tokenBridge_);
        setWethAddress(wethAddress);
        setUnwrapWethFlag(unwrapWeth_);

        // set the initial swapRate/relayer precisions to 1e8
        setSwapRatePrecision(1e8);
        setRelayerFeePrecision(1e8);
    }

    /**
     * @notice Emitted when a transfer is completed by the Wormhole token bridge
     * @param emitterChainId Wormhole chain ID of emitter contract on the source chain
     * @param emitterAddress Address (bytes32 zero-left-padded) of emitter on the source chain
     * @param sequence Sequence of the Wormhole message
     */
    event TransferRedeemed(
        uint16 indexed emitterChainId,
        bytes32 indexed emitterAddress,
        uint64 indexed sequence
    );

    /**
     * @notice Emitted when a swap is executed with an off-chain relayer
     * @param recipient Address of the recipient of the native assets
     * @param relayer Address of the relayer that performed the swap
     * @param token Address of the token being swapped
     * @param tokenAmount Amount of token being swapped
     * @param nativeAmount Amount of native assets swapped for tokens
     */
    event SwapExecuted(
        address indexed recipient,
        address indexed relayer,
        address indexed token,
        uint256 tokenAmount,
        uint256 nativeAmount
    );

    /**
     * @notice Calls Wormhole's Token Bridge contract to emit a contract-controlled
     * transfer. The transfer message includes an arbitrary payload with instructions
     * for how to handle relayer payments on the target contract and the quantity of
     * tokens to convert into native assets for the user.
     * @param token ERC20 token address to transfer cross chain.
     * @param amount Quantity of tokens to be transferred.
     * @param toNativeTokenAmount Amount of tokens to swap into native assets on
     * the target chain.
     * @param targetChain Wormhole chain ID of the target blockchain.
     * @param targetRecipient User's wallet address on the target blockchain in bytes32 format
     * (zero-left-padded).
     * @param batchId ID for Wormhole message batching
     * @return messageSequence Wormhole sequence for emitted TransferTokensWithRelay message.
     */
    function transferTokensWithRelay(
        address token,
        uint256 amount,
        uint256 toNativeTokenAmount,
        uint16 targetChain,
        bytes32 targetRecipient,
        uint32 batchId
    ) public payable nonReentrant returns (uint64 messageSequence) {
        // Cache wormhole fee and confirm that the user has passed enough
        // value to cover the wormhole protocol fee.
        uint256 wormholeFee = wormhole().messageFee();
        require(msg.value == wormholeFee, "insufficient value");

        // Cache token decimals, and remove dust from the amount argument. This
        // ensures that the dust is never transferred to this contract.
        uint8 tokenDecimals = getDecimals(token);
        amount = denormalizeAmount(
            normalizeAmount(amount, tokenDecimals),
            tokenDecimals
        );

        // Transfer tokens from user to the this contract, and
        // override amount with actual amount received.
        amount = custodyTokens(token, amount);

        // call the internal _transferTokensWithRelay function
        messageSequence = _transferTokensWithRelay(
            InternalTransferParams({
                token: token,
                amount: amount,
                tokenDecimals: tokenDecimals,
                toNativeTokenAmount: toNativeTokenAmount,
                targetChain: targetChain,
                targetRecipient: targetRecipient
            }),
            batchId,
            wormholeFee
        );
    }

    /**
     * @notice Wraps Ether and calls Wormhole's Token Bridge contract to emit
     * a contract-controlled transfer. The transfer message includes an arbitrary
     * payload with instructions for how to handle relayer payments on the target
     * contract and the quantity of tokens to convert into native assets for the user.
     * @param toNativeTokenAmount Amount of tokens to swap into native assets on
     * the target chain.
     * @param targetChain Wormhole chain ID of the target blockchain.
     * @param targetRecipient User's wallet address on the target blockchain in bytes32 format
     * (zero-left-padded).
     * @param batchId ID for Wormhole message batching
     * @return messageSequence Wormhole sequence for emitted TransferTokensWithRelay message.
     */
    function wrapAndTransferEthWithRelay(
        uint256 toNativeTokenAmount,
        uint16 targetChain,
        bytes32 targetRecipient,
        uint32 batchId
    ) public payable returns (uint64 messageSequence) {
        require(unwrapWeth(), "WETH functionality not supported");

        // Cache wormhole fee and confirm that the user has passed enough
        // value to cover the wormhole protocol fee.
        uint256 wormholeFee = wormhole().messageFee();
        require(msg.value > wormholeFee, "insufficient value");

        // remove the wormhole protocol fee from the amount
        uint256 amount = msg.value - wormholeFee;

        // refund dust
        uint256 dust = amount - denormalizeAmount(normalizeAmount(amount, 18), 18);
        if (dust > 0) {
            payable(msg.sender).transfer(dust);
        }

        // remove dust from amount and cache WETH
        uint256 amountLessDust = amount - dust;
        IWETH weth = WETH();

        // deposit into the WETH contract
        weth.deposit{
            value : amountLessDust
        }();

        // call the internal _transferTokensWithRelay function
        messageSequence = _transferTokensWithRelay(
            InternalTransferParams({
                token: address(weth),
                tokenDecimals: 18,
                amount: amountLessDust,
                toNativeTokenAmount: toNativeTokenAmount,
                targetChain: targetChain,
                targetRecipient: targetRecipient
            }),
            batchId,
            wormholeFee
        );
    }

    function _transferTokensWithRelay(
        InternalTransferParams memory params,
        uint32 batchId,
        uint256 wormholeFee
    ) internal returns (uint64 messageSequence) {
        // sanity check function arguments
        require(isAcceptedToken(params.token), "token not accepted");
        require(
            params.targetRecipient != bytes32(0),
            "targetRecipient cannot be bytes32(0)"
        );

        /**
         * Cache the normalized amount and verify that it's nonzero.
         * The token bridge peforms the same operation before encoding
         * the amount in the `TransferWithPayload` message.
         */
        uint256 normalizedAmount = normalizeAmount(
            params.amount,
            params.tokenDecimals
        );
        require(normalizedAmount > 0, "normalized amount must be > 0");

        // normalized toNativeTokenAmount should be nonzero
        uint256 normalizedToNativeTokenAmount = normalizeAmount(
            params.toNativeTokenAmount,
            params.tokenDecimals
        );
        require(
            params.toNativeTokenAmount == 0 || normalizedToNativeTokenAmount > 0,
            "invalid toNativeTokenAmount"
        );

        // Cache the target contract address and verify that there
        // is a registered contract for the specified targetChain.
        bytes32 targetContract = getRegisteredContract(params.targetChain);
        require(targetContract != bytes32(0), "target not registered");

        // Confirm that the user has sent enough tokens to cover the native swap
        // on the target chain and to pay the relayer fee.
        uint256 normalizedRelayerFee = normalizeAmount(
            calculateRelayerFee(
                params.targetChain,
                params.token,
                params.tokenDecimals
            ),
            params.tokenDecimals
        );
        require(
            normalizedAmount > normalizedRelayerFee + normalizedToNativeTokenAmount,
            "insufficient amount"
        );

        /**
         * Encode instructions (TransferWithRelay) to send with the token transfer.
         * The `targetRecipient` address is in bytes32 format (zero-left-padded) to
         * support non-evm smart contracts that have addresses that are longer
         * than 20 bytes.
         *
         * We normalize the relayerFee and toNativeTokenAmount to support
         * non-evm smart contracts that can only handle uint64.max values.
         */
        bytes memory messagePayload = encodeTransferWithRelay(
            TransferWithRelay({
                payloadId: 1,
                targetRelayerFee: normalizedRelayerFee,
                toNativeTokenAmount: normalizedToNativeTokenAmount,
                targetRecipient: params.targetRecipient
            })
        );

        // cache TokenBridge instance
        ITokenBridge bridge = tokenBridge();

        // approve the token bridge to spend the specified tokens
        SafeERC20.safeApprove(
            IERC20(params.token),
            address(bridge),
            params.amount
        );

        /**
         * Call `transferTokensWithPayload` method on the token bridge and pay
         * the Wormhole network fee. The token bridge will emit a Wormhole
         * message with an encoded `TransferWithPayload` struct (see the
         * ITokenBridge.sol interface file in this repo).
         */
        messageSequence = bridge.transferTokensWithPayload{value: wormholeFee}(
            params.token,
            params.amount,
            params.targetChain,
            targetContract,
            batchId,
            messagePayload
        );
    }

    /**
     * @notice Calls Wormhole's Token Bridge contract to complete token transfers. Takes
     * custody of the wrapped (or released) tokens and sends the tokens to the target recipient.
     * It pays the relayer in the minted token denomination. If requested by the user,
     * it will perform a swap with the off-chain relayer to provide the user with native assets.
     * If the `token` being transferred is WETH, the contract will unwrap native assets and send
     * the transferred amount to the recipient and pay the relayer in native assets.
     * @dev reverts if:
     * - the transferred token is not accepted by this contract
     * - the transffered token is not attested on this blockchain's Token Bridge contract
     * - the emitter of the transfer message is not registered with this contract
     * - the relayer fails to provide enough native assets to faciliate a native swap
     * - the recipient attempts to swap native assets when performing a self redemption
     * @param encodedTransferMessage Attested `TransferWithPayload` wormhole message.
     */
    function completeTransferWithRelay(bytes calldata encodedTransferMessage) public payable {
        // complete the transfer by calling the token bridge
        (bytes memory payload, uint256 amount, address token) =
             _completeTransfer(encodedTransferMessage);

        // parse the payload into the `TransferWithRelay` struct
        TransferWithRelay memory transferWithRelay = decodeTransferWithRelay(
            payload
        );

        // cache the recipient address and unwrap weth flag
        address recipient = bytes32ToAddress(transferWithRelay.targetRecipient);
        bool unwrapWeth = unwrapWeth();

        // handle self redemptions
        if (msg.sender == recipient) {
            _completeSelfRedemption(
                token,
                recipient,
                amount,
                unwrapWeth
            );

            // bail out
            return;
        }

        // cache token decimals
        uint8 tokenDecimals = getDecimals(token);

        // denormalize the encoded relayerFee
        transferWithRelay.targetRelayerFee = denormalizeAmount(
            transferWithRelay.targetRelayerFee,
            tokenDecimals
        );

        // unwrap and transfer ETH
        if (token == address(WETH())) {
            _completeWethTransfer(
                amount,
                recipient,
                transferWithRelay.targetRelayerFee,
                unwrapWeth
            );

            // bail out
            return;
        }

        // handle native asset payments and refunds
        if (transferWithRelay.toNativeTokenAmount > 0) {
            // denormalize the toNativeTokenAmount
            transferWithRelay.toNativeTokenAmount = denormalizeAmount(
                transferWithRelay.toNativeTokenAmount,
                tokenDecimals
            );

            /**
             * Compute the maximum amount of tokens that the user is allowed
             * to swap for native assets.
             *
             * Override the toNativeTokenAmount in transferWithRelay if the
             * toNativeTokenAmount is greater than the maxToNativeAllowed.
             *
             * Compute the amount of native assets to send the recipient.
             */
            uint256 nativeAmountForRecipient;
            uint256 maxToNativeAllowed = calculateMaxSwapAmountIn(token);
            if (transferWithRelay.toNativeTokenAmount > maxToNativeAllowed) {
                transferWithRelay.toNativeTokenAmount = maxToNativeAllowed;
            }
            // compute amount of native asset to pay the recipient
            nativeAmountForRecipient = calculateNativeSwapAmountOut(
                token,
                transferWithRelay.toNativeTokenAmount
            );

            /**
             * The nativeAmountForRecipient can be zero if the user specifed
             * a toNativeTokenAmount that is too little to convert to native
             * asset. We need to override the toNativeTokenAmount to be zero
             * if that is the case, that way the user receives the full amount
             * of transferred tokens.
             */
            if (nativeAmountForRecipient > 0) {
                // check to see if the relayer sent enough value
                require(
                    msg.value >= nativeAmountForRecipient,
                    "insufficient native asset amount"
                );

                // refund excess native asset to relayer if applicable
                uint256 relayerRefund = msg.value - nativeAmountForRecipient;
                if (relayerRefund > 0) {
                    payable(msg.sender).transfer(relayerRefund);
                }

                // send requested native asset to target recipient
                payable(recipient).transfer(nativeAmountForRecipient);

                // emit swap event
                emit SwapExecuted(
                    recipient,
                    msg.sender,
                    token,
                    transferWithRelay.toNativeTokenAmount,
                    nativeAmountForRecipient
                );
            } else {
                // override the toNativeTokenAmount in transferWithRelay
                transferWithRelay.toNativeTokenAmount = 0;

                // refund the relayer any native asset sent to this contract
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
        }

        // add the token swap amount to the relayer fee
        uint256 amountForRelayer =
            transferWithRelay.targetRelayerFee + transferWithRelay.toNativeTokenAmount;

        // pay the relayer if amountForRelayer > 0
        if (amountForRelayer > 0) {
            SafeERC20.safeTransfer(
                IERC20(token),
                msg.sender,
                amountForRelayer
            );
        }

        // pay the target recipient the remaining tokens
        SafeERC20.safeTransfer(
            IERC20(token),
            recipient,
            amount - amountForRelayer
        );
    }

    function _completeTransfer(
        bytes memory encodedTransferMessage
    ) internal returns (bytes memory, uint256, address) {
        /**
         * parse the encoded Wormhole message
         *
         * SECURITY: This message not been verified by the Wormhole core layer yet.
         * The encoded payload can only be trusted once the message has been verified
         * by the Wormhole core contract. In this case, the message will be verified
         * by a call to the token bridge contract in subsequent actions.
         */
        IWormhole.VM memory parsedMessage = wormhole().parseVM(
            encodedTransferMessage
        );

        /**
         * The amount encoded in the payload could be incorrect,
         * since fee-on-transfer tokens are supported by the token bridge.
         *
         * NOTE: The token bridge truncates the encoded amount for any token
         * with decimals greater than 8. This is to support blockchains that
         * cannot handle transfer amounts exceeding max(uint64).
         */
        address localTokenAddress = fetchLocalAddressFromTransferMessage(
            parsedMessage.payload
        );
        require(isAcceptedToken(localTokenAddress), "token not registered");

        // check balance before completing the transfer
        uint256 balanceBefore = getBalance(localTokenAddress);

        // cache the token bridge instance
        ITokenBridge bridge = tokenBridge();

        /**
         * Call `completeTransferWithPayload` on the token bridge. This
         * method acts as a reentrancy protection since it does not allow
         * transfers to be redeemed more than once.
         */
        bytes memory transferPayload = bridge.completeTransferWithPayload(
            encodedTransferMessage
        );

        // compute and save the balance difference after completing the transfer
        uint256 amountReceived = getBalance(localTokenAddress) - balanceBefore;

        // parse the wormhole message payload into the `TransferWithPayload` struct
        ITokenBridge.TransferWithPayload memory transfer =
            bridge.parseTransferWithPayload(transferPayload);

        // confirm that the message sender is a registered TokenBridgeRelayer contract
        require(
            transfer.fromAddress == getRegisteredContract(parsedMessage.emitterChainId),
            "contract not registered"
        );

        // emit event with information about the TransferWithPayload message
        emit TransferRedeemed(
            parsedMessage.emitterChainId,
            parsedMessage.emitterAddress,
            parsedMessage.sequence
        );

        return (
            transfer.payload,
            amountReceived,
            localTokenAddress
        );
    }

    function _completeSelfRedemption(
        address token,
        address recipient,
        uint256 amount,
        bool unwrapWeth
    ) internal {
        // revert if the caller sends ether to this contract
        require(msg.value == 0, "recipient cannot swap native assets");

        // cache WETH instance
        IWETH weth = WETH();

        // transfer the full amount to the recipient
        if (token == address(weth) && unwrapWeth) {
            // withdraw weth and send to the recipient
            weth.withdraw(amount);
            payable(recipient).transfer(amount);
        } else {
            SafeERC20.safeTransfer(
                IERC20(token),
                recipient,
                amount
            );
        }
    }

    function _completeWethTransfer(
        uint256 amount,
        address recipient,
        uint256 relayerFee,
        bool unwrapWeth
    ) internal {
        // revert if the relayer sends ether to this contract
        require(msg.value == 0, "value must be zero");

        /**
         * Check if the weth is unwrappable. Some wrapped native assets
         * are not unwrappable (e.g. CELO) and must be transferred via
         * the ERC20 interface.
         */
        if (unwrapWeth) {
            // withdraw eth
            WETH().withdraw(amount);

            // transfer eth to recipient
            payable(recipient).transfer(amount - relayerFee);

            // transfer relayer fee to the caller
            if (relayerFee > 0) {
                payable(msg.sender).transfer(relayerFee);
            }
        } else {
            // cache WETH instance
            IWETH weth = WETH();

            // transfer the native asset to the caller
            SafeERC20.safeTransfer(
                IERC20(address(weth)),
                recipient,
                amount - relayerFee
            );

            // transfer relayer fee to the caller
            if (relayerFee > 0) {
                SafeERC20.safeTransfer(
                    IERC20(address(weth)),
                    msg.sender,
                    relayerFee
                );
            }
        }
    }

    /**
     * @notice Parses the encoded address and chainId from a `TransferWithPayload`
     * message. Finds the address of the wrapped token contract if the token is not
     * native to this chain.
     * @param payload Encoded `TransferWithPayload` message
     * @return localAddress Address of the encoded (bytes32 format) token address on
     * this chain.
     */
    function fetchLocalAddressFromTransferMessage(
        bytes memory payload
    ) public view returns (address localAddress) {
        // parse the source token address and chainId
        bytes32 sourceAddress = payload.toBytes32(33);
        uint16 tokenChain = payload.toUint16(65);

        // Fetch the wrapped address from the token bridge if the token
        // is not from this chain.
        if (tokenChain != chainId()) {
            // identify wormhole token bridge wrapper
            localAddress = tokenBridge().wrappedAsset(tokenChain, sourceAddress);
            require(localAddress != address(0), "token not attested");
        } else {
            // return the encoded address if the token is native to this chain
            localAddress = bytes32ToAddress(sourceAddress);
        }
    }

    /**
     * @notice Calculates the max amount of tokens the user can convert to
     * native assets on this chain.
     * @dev The max amount of native assets the contract will swap with the user
     * is governed by the `maxNativeSwapAmount` state variable.
     * @param token Address of token being transferred.
     * @return maxAllowed The maximum number of tokens the user is allowed to
     * swap for native assets.
     */
    function calculateMaxSwapAmountIn(
        address token
    ) public view returns (uint256 maxAllowed) {
        // fetch the decimals for the token and native token
        uint8 tokenDecimals = getDecimals(token);
        uint8 nativeDecimals = getDecimals(address(WETH()));

        if (tokenDecimals > nativeDecimals) {
            maxAllowed =
                maxNativeSwapAmount(token) * nativeSwapRate(token) *
                10 ** (tokenDecimals - nativeDecimals) / swapRatePrecision();
        } else {
            maxAllowed =
                (maxNativeSwapAmount(token) * nativeSwapRate(token)) /
                (10 ** (nativeDecimals - tokenDecimals) * swapRatePrecision());
        }
    }

    /**
     * @notice Calculates the amount of native assets that a user will receive
     * when swapping transferred tokens for native assets.
     * @param token Address of token being transferred.
     * @param toNativeAmount Quantity of tokens to be converted to native assets.
     * @return nativeAmount The exchange rate between native assets and the `toNativeAmount`
     * of transferred tokens.
     */
    function calculateNativeSwapAmountOut(
        address token,
        uint256 toNativeAmount
    ) public view returns (uint256 nativeAmount) {
        // fetch the decimals for the token and native token
        uint8 tokenDecimals = getDecimals(token);
        uint8 nativeDecimals = getDecimals(address(WETH()));

        if (tokenDecimals > nativeDecimals) {
            nativeAmount =
                swapRatePrecision() * toNativeAmount /
                (nativeSwapRate(token) * 10 ** (tokenDecimals - nativeDecimals));
        } else {
            nativeAmount =
                swapRatePrecision() * toNativeAmount *
                10 ** (nativeDecimals - tokenDecimals) /
                nativeSwapRate(token);
        }
    }

    /**
     * @notice Converts the USD denominated relayer fee into the specified token
     * denomination.
     * @param targetChainId Wormhole chain ID of the target blockchain.
     * @param token Address of token being transferred.
     * @param decimals Token decimals of token being transferred.
     * @return feeInTokenDenomination Relayer fee denominated in tokens.
     */
    function calculateRelayerFee(
        uint16 targetChainId,
        address token,
        uint8 decimals
    ) public view returns (uint256 feeInTokenDenomination) {
        // cache swap rate
        uint256 tokenSwapRate = swapRate(token);
        require(tokenSwapRate != 0, "swap rate not set");
        feeInTokenDenomination =
            10 ** decimals * relayerFee(targetChainId) * swapRatePrecision() /
            (tokenSwapRate * relayerFeePrecision());
    }

    function custodyTokens(
        address token,
        uint256 amount
    ) internal returns (uint256) {
        // query own token balance before transfer
        uint256 balanceBefore = getBalance(token);

        // deposit tokens
        SafeERC20.safeTransferFrom(
            IERC20(token),
            msg.sender,
            address(this),
            amount
        );

        // return the balance difference
        return getBalance(token) - balanceBefore;
    }

    function bytes32ToAddress(bytes32 address_) internal pure returns (address) {
        require(bytes12(address_) == 0, "invalid EVM address");
        return address(uint160(uint256(address_)));
    }

    // necessary for receiving native assets
    receive() external payable {}
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";
import {ITokenBridge} from "../interfaces/ITokenBridge.sol";
import {IWETH} from "../interfaces/IWETH.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TokenBridgeRelayerSetters.sol";

abstract contract TokenBridgeRelayerGetters is TokenBridgeRelayerSetters {
    function owner() public view returns (address) {
        return _state.owner;
    }

    function pendingOwner() public view returns (address) {
        return _state.pendingOwner;
    }

    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    function tokenBridge() public view returns (ITokenBridge) {
        return ITokenBridge(payable(_state.tokenBridge));
    }

    function WETH() public view returns (IWETH) {
        return IWETH(_state.wethAddress);
    }

    function unwrapWeth() public view returns (bool) {
        return _state.unwrapWeth;
    }

    function chainId() public view returns (uint16) {
        return _state.chainId;
    }

    function getRegisteredContract(uint16 emitterChainId) public view returns (bytes32) {
        return _state.registeredContracts[emitterChainId];
    }

    function swapRatePrecision() public view returns (uint256) {
        return _state.swapRatePrecision;
    }

    function isAcceptedToken(address token) public view returns (bool) {
        return _state.acceptedTokens[token];
    }

    function getAcceptedTokensList() public view returns (address[] memory) {
        return _state.acceptedTokensList;
    }

    function relayerFeePrecision() public view returns (uint256) {
        return _state.relayerFeePrecision;
    }

    function relayerFee(uint16 chainId_) public view returns (uint256) {
        return _state.relayerFees[chainId_];
    }

    function maxNativeSwapAmount(address token) public view returns (uint256) {
        return _state.maxNativeSwapAmount[token];
    }

    function swapRate(address token) public view returns (uint256) {
        return _state.swapRates[token];
    }

    function nativeSwapRate(address token) public view returns (uint256) {
        uint256 nativeSwapRate_ = swapRate(_state.wethAddress);
        uint256 tokenSwapRate = swapRate(token);

        require(
            nativeSwapRate_ > 0 && tokenSwapRate > 0,
            "swap rate not set"
        );

        return swapRatePrecision() * nativeSwapRate_ / tokenSwapRate;
    }

    function normalizeAmount(
        uint256 amount,
        uint8 decimals
    ) public pure returns (uint256) {
        if (decimals > 8) {
            amount /= 10 ** (decimals - 8);
        }
        return amount;
    }

    function denormalizeAmount(
        uint256 amount,
        uint8 decimals
    ) public pure returns (uint256) {
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    function getDecimals(address token) internal view returns (uint8) {
        (,bytes memory queriedDecimals) = token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        return abi.decode(queriedDecimals, (uint8));
    }

    function getBalance(address token) internal view returns (uint256 balance) {
        // fetch the specified token balance for this contract
        (, bytes memory queriedBalance) =
            token.staticcall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
            );
        balance = abi.decode(queriedBalance, (uint256));
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TokenBridgeRelayerGetters.sol";

abstract contract TokenBridgeRelayerGovernance is TokenBridgeRelayerGetters {
    event OwnershipTransfered(address indexed oldOwner, address indexed newOwner);
    event SwapRateUpdated(address indexed token, uint256 indexed swapRate);

    /**
     * @notice Starts the ownership transfer process of the contracts. It saves
     * an address in the pending owner state variable.
     * @param chainId_ Wormhole chain ID.
     * @param newOwner Address of the pending owner.
     */
    function submitOwnershipTransferRequest(
        uint16 chainId_,
        address newOwner
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(newOwner != address(0), "newOwner cannot equal address(0)");

        setPendingOwner(newOwner);
    }

    /**
     * @notice Cancels the ownership transfer process.
     * @dev Sets the pending owner state variable to the zero address.
     */
    function cancelOwnershipTransferRequest(
        uint16 chainId_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        setPendingOwner(address(0));
    }

    /**
     * @notice Finalizes the ownership transfer to the pending owner.
     * @dev It checks that the caller is the pendingOwner to validate the wallet
     * address. It updates the owner state variable with the pendingOwner state
     * variable.
     */
    function confirmOwnershipTransferRequest() public {
        // cache the new owner address
        address newOwner = pendingOwner();

        require(msg.sender == newOwner, "caller must be pendingOwner");

        // cache currentOwner for Event
        address currentOwner = owner();

        // update the owner in the contract state and reset the pending owner
        setOwner(newOwner);
        setPendingOwner(address(0));

        emit OwnershipTransfered(currentOwner, newOwner);
    }

    /**
     * @notice Updates the unwrapWeth state variable.
     * @dev This variable should only be set to true for chains that
     * support a WETH contract. Some chains (e.g. Celo, Karura, Acala)
     * do not support a WETH contract, and the address is set as a placeholder
     * for the native asset address for swapRate lookups.
     * @param chainId_ Wormhole chain ID.
     * @param unwrapWeth_ Boolean that determines if WETH is unwrapped
     * when transferred back to its native blockchain.
     */
    function updateUnwrapWethFlag(
        uint16 chainId_,
        bool unwrapWeth_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        setUnwrapWethFlag(unwrapWeth_);
    }

    /**
     * @notice Registers foreign Token Bridge Relayer contracts.
     * @param chainId_ Wormhole chain ID of the foreign contract.
     * @param contractAddress Address of the foreign contract in bytes32 format
     * (zero-left-padded address).
     */
    function registerContract(
        uint16 chainId_,
        bytes32 contractAddress
    ) public onlyOwner {
        // sanity check both input arguments
        require(
            contractAddress != bytes32(0),
            "contractAddress cannot equal bytes32(0)"
        );
        require(
            chainId_ != 0 && chainId_ != chainId(),
            "chainId_ cannot equal 0 or this chainId"
        );

        // update the registeredContracts state variable
        _registerContract(chainId_, contractAddress);
    }

    /**
     * @notice Register tokens accepted by this contract.
     * @param chainId_ Wormhole chain ID.
     * @param token Address of the token.
     */
    function registerToken(
        uint16 chainId_,
        address token
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(token != address(0), "invalid token");

        addAcceptedToken(token);
    }

    /**
     * @notice Deregister tokens accepted by this contract.
     * @dev The `removeAcceptedToken` function will revert
     * if the token is not registered.
     * @param chainId_ Wormhole chain ID.
     * @param token Address of the token.
     */
    function deregisterToken(
        uint16 chainId_,
        address token
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(token != address(0), "invalid token");

        removeAcceptedToken(token);
    }

    /**
     * @notice Updates the fee for relaying transfers to foreign contracts.
     * @param chainId_ Wormhole chain ID.
     * @param amount Amount of USD to pay the relayer upon redemption.
     * @dev The relayerFee is scaled by the relayerFeePrecision. For example,
     * if the relayerFee is $15 and the relayerFeePrecision is 1000000, the
     * relayerFee should be set to 15000000.
     */
    function updateRelayerFee(
        uint16 chainId_,
        uint256 amount
    ) public onlyOwner {
        require(chainId_ != chainId(), "invalid chain");
        require(
            getRegisteredContract(chainId_) != bytes32(0),
            "contract doesn't exist"
        );

        setRelayerFee(chainId_, amount);
    }

    /**
     * @notice Updates the precision of the relayer fee.
     * @param chainId_ Wormhole chain ID.
     * @param relayerFeePrecision_ Precision of relayer fee.
     */
    function updateRelayerFeePrecision(
        uint16 chainId_,
        uint256 relayerFeePrecision_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(relayerFeePrecision_ > 0, "precision must be > 0");

        setRelayerFeePrecision(relayerFeePrecision_);
    }

    /**
     * @notice Updates the swap rate for specified token in USD.
     * @param chainId_ Wormhole chain ID.
     * @param token Address of the token to update the conversion rate for.
     * @param swapRate The token -> USD conversion rate.
     * @dev The swapRate is the conversion rate using asset prices denominated in
     * USD multiplied by the swapRatePrecision. For example, if the conversion
     * rate is $15 and the swapRatePrecision is 1000000, the swapRate should be set
     * to 15000000.
     */
    function updateSwapRate(
        uint16 chainId_,
        address token,
        uint256 swapRate
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(isAcceptedToken(token), "token not accepted");
        require(swapRate > 0, "swap rate must be nonzero");

        setSwapRate(token, swapRate);

        emit SwapRateUpdated(token, swapRate);
    }

    /**
     * @notice Updates the precision of the swap rate.
     * @param chainId_ Wormhole chain ID.
     * @param swapRatePrecision_ Precision of swap rate.
     */
    function updateSwapRatePrecision(
        uint16 chainId_,
        uint256 swapRatePrecision_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(swapRatePrecision_ > 0, "precision must be > 0");

        setSwapRatePrecision(swapRatePrecision_);
    }

    /**
     * @notice Updates the max amount of native assets the contract will pay
     * to the target recipient.
     * @param chainId_ Wormhole chain ID.
     * @param token Address of the token to update the max native swap amount for.
     * @param maxAmount Max amount of native assets.
     */
    function updateMaxNativeSwapAmount(
        uint16 chainId_,
        address token,
        uint256 maxAmount
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(isAcceptedToken(token), "token not accepted");

        setMaxNativeSwapAmount(token, maxAmount);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller not the owner");
        _;
    }

    modifier onlyCurrentChain(uint16 chainId_) {
        require(chainId() == chainId_, "wrong chain");
        _;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "../libraries/BytesLib.sol";

import "./TokenBridgeRelayerStructs.sol";

abstract contract TokenBridgeRelayerMessages is TokenBridgeRelayerStructs {
    using BytesLib for bytes;

    /**
     * @notice Encodes the TransferWithRelay struct into bytes.
     * @param transfer TransferWithRelay struct.
     * @return encoded TransferWithRelay struct encoded into bytes.
     */
    function encodeTransferWithRelay(
        TransferWithRelay memory transfer
    ) public pure returns (bytes memory encoded) {
       require(transfer.payloadId == 1, "invalid payloadId");
        encoded = abi.encodePacked(
            transfer.payloadId,
            transfer.targetRelayerFee,
            transfer.toNativeTokenAmount,
            transfer.targetRecipient
        );
    }

    /**
     * @notice Decodes an encoded `TransferWithRelay` struct.
     * @dev reverts if:
     * - the first byte (payloadId) does not equal 1
     * - the length of the payload has an unexpected length
     * @param encoded Encoded `TransferWithRelay` struct.
     * @return transfer `TransferTokenRelay` struct.
     */
    function decodeTransferWithRelay(
        bytes memory encoded
    ) public pure returns (TransferWithRelay memory transfer) {
        uint256 index = 0;

        // parse the payloadId
        transfer.payloadId = encoded.toUint8(index);
        index += 1;

        require(transfer.payloadId == 1, "invalid payloadId");

        // target relayer fee
        transfer.targetRelayerFee = encoded.toUint256(index);
        index += 32;

        // amount of tokens to convert to native assets
        transfer.toNativeTokenAmount = encoded.toUint256(index);
        index += 32;

        // recipient of the transfered tokens and native assets
        transfer.targetRecipient = encoded.toBytes32(index);
        index += 32;

        require(index == encoded.length, "invalid message length");
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "./TokenBridgeRelayerState.sol";

abstract contract TokenBridgeRelayerSetters is TokenBridgeRelayerState {
    function setOwner(address owner_) internal {
        _state.owner = owner_;
    }

    function setPendingOwner(address pendingOwner_) internal {
        _state.pendingOwner = pendingOwner_;
    }

    function setWormhole(address wormhole_) internal {
        _state.wormhole = payable(wormhole_);
    }

    function setTokenBridge(address tokenBridge_) internal {
        _state.tokenBridge = payable(tokenBridge_);
    }

    function setUnwrapWethFlag(bool unwrapWeth_) internal {
        _state.unwrapWeth = unwrapWeth_;
    }

    function setWethAddress(address weth_) internal {
        _state.wethAddress = weth_;
    }

    function setChainId(uint16 chainId_) internal {
        _state.chainId = chainId_;
    }

    function _registerContract(uint16 chainId_, bytes32 contract_) internal {
        _state.registeredContracts[chainId_] = contract_;
    }

    function setSwapRatePrecision(uint256 precision) internal {
        _state.swapRatePrecision = precision;
    }

    function setRelayerFeePrecision(uint256 precision) internal {
        _state.relayerFeePrecision = precision;
    }

    function addAcceptedToken(address token) internal {
        require(
            _state.acceptedTokens[token] == false,
            "token already registered"
        );
        _state.acceptedTokens[token] = true;
        _state.acceptedTokensList.push(token);
    }

    function removeAcceptedToken(address token) internal {
        require(
            _state.acceptedTokens[token],
            "token not registered"
        );

        // Remove the token from the acceptedTokens mapping, and
        // clear the token's swapRate and maxNativeSwapAmount.
        _state.acceptedTokens[token] = false;
        _state.swapRates[token] = 0;
        _state.maxNativeSwapAmount[token] = 0;

        // cache array length
        uint256 length_ = _state.acceptedTokensList.length;

        // Replace `token` in the acceptedTokensList with the last
        // element in the acceptedTokensList array.
        uint256 i = 0;
        for (; i < length_;) {
            if (_state.acceptedTokensList[i] == token) {
                break;
            }
            unchecked { i += 1; }
        }

        if (i != length_) {
            if (length_ > 1) {
                _state.acceptedTokensList[i] = _state.acceptedTokensList[length_ - 1];
            }
            _state.acceptedTokensList.pop();
        }
    }

    function setRelayerFee(uint16 chainId_, uint256 fee) internal {
        _state.relayerFees[chainId_] = fee;
    }

    function setSwapRate(address token, uint256 swapRate) internal {
        _state.swapRates[token] = swapRate;
    }

    function setMaxNativeSwapAmount(address token, uint256 maximum) internal {
        _state.maxNativeSwapAmount[token] = maximum;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";

abstract contract TokenBridgeRelayerStorage {
    struct State {
        // Wormhole chain ID of this contract
        uint16 chainId;

        // boolean to determine if weth is unwrappable
        bool unwrapWeth;

        // address of WETH on this chain
        address wethAddress;

        // owner of this contract
        address owner;

        // intermediate state when transfering contract ownership
        address pendingOwner;

        // address of the Wormhole contract on this chain
        address wormhole;

        // address of the Wormhole TokenBridge contract on this chain
        address tokenBridge;

        // precision of the nativeSwapRates, this value should NEVER be set to zero
        uint256 swapRatePrecision;

        // precision of the relayerFee, this value should NEVER be set to zero
        uint256 relayerFeePrecision;

        // Wormhole chain ID to known relayer contract address mapping
        mapping(uint16 => bytes32) registeredContracts;

        // token swap rate in USD terms
        mapping(address => uint256) swapRates;

        /**
         * Mapping of source token address to maximum native asset swap amount
         * allowed.
         */
        mapping(address => uint256) maxNativeSwapAmount;

        // mapping of chainId to relayerFee in USD
        mapping(uint16 => uint256) relayerFees;

        // accepted token to bool mapping
        mapping(address => bool) acceptedTokens;

        // list of accepted token addresses
        address[] acceptedTokensList;
    }
}

abstract contract TokenBridgeRelayerState {
    TokenBridgeRelayerStorage.State _state;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

abstract contract TokenBridgeRelayerStructs {
    struct TransferWithRelay {
        uint8 payloadId; // == 1
        uint256 targetRelayerFee;
        uint256 toNativeTokenAmount;
        bytes32 targetRecipient;
    }

    struct InternalTransferParams {
        address token;
        uint8 tokenDecimals;
        uint256 amount;
        uint256 toNativeTokenAmount;
        uint16 targetChain;
        bytes32 targetRecipient;
    }
}