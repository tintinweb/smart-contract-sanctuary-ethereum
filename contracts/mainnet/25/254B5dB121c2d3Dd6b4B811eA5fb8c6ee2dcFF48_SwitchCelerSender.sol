// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
pragma solidity >=0.8.9;

import "../dexs/Switch.sol";
import "sgn-v2-contracts/contracts/message/libraries/MessageSenderLib.sol";
import "sgn-v2-contracts/contracts/message/libraries/MsgDataTypes.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "../lib/DataTypes.sol";
import { IPriceTracker } from "../interfaces/IPriceTracker.sol";
import { ICBridge } from "../interfaces/ICBridge.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwitchCelerSender is Switch {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public celerMessageBus;
    address public cBridge;
    address public priceTracker;
    uint256 executorFee;
    uint256 claimableExecutionFee;

    struct CelerSwapRequest {
        bytes32 id;
        bytes32 bridge;
        address srcToken;
        address bridgeToken;
        address dstToken;
        address recipient;
        uint256 srcAmount;
        uint256 bridgeDstAmount;
        uint256 estimatedDstAmount;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        uint256[] dstDistribution;
        bytes dstParaswapData;
    }

    struct CelerDepositRequest {
        bytes32 id;
        bytes32 bridge;
        address srcToken;
        address bridgeToken;
        address depositToken;
        address recipient;
        address depositContract;
        address toApprovalAddress; // the approval address for deposit
        uint256 srcAmount;
        uint256 bridgeDstAmount;
        uint256 estimatedDepositAmount;
        uint32 toContractGasLimit;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        bytes toContractCallData;
        bytes dstParaswapData;
    }

    struct TransferArgsCeler {
        address fromToken;
        address destToken;
        address recipient;
        address partner;
        uint256 amount;
        uint256 bridgeDstAmount;
        uint64 dstChainId;
        uint64 nonce;
        uint32 bridgeSlippage;
        bytes32 id;
        bytes32 bridge;
    }

    struct SwapArgsCeler {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        address recipient;
        address callTo; // The address of the destination app contract.
        address partner;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedDstTokenAmount; // estimated dest token amount on receiving chain
        uint256[] srcDistribution;
        uint256[] dstDistribution;
        uint64 dstChainId;
        uint64 nonce;
        uint32 bridgeSlippage;
        bytes32 id;
        bytes32 bridge;
        bytes srcParaswapData;
        bytes dstParaswapData;
    }

    struct DepositArgsCeler {
        DataTypes.SwapInfo srcSwap;
        DataTypes.SwapInfo dstSwap;
        DataTypes.ParaswapUsageStatus paraswapUsageStatus;
        address recipient;
        address callTo; // The address of the destination app contract.
        address partner;
        address depositContract;
        address toApprovalAddress; // The approval address for deposit
        uint256 amount;
        uint256 expectedReturn; // expected bridge token amount on sending chain
        uint256 minReturn; // minimum amount of bridge token
        uint256 bridgeDstAmount; // estimated token amount of bridgeToken
        uint256 estimatedDepositAmount; // estimated deposit token amount on receiving chain
        uint64 dstChainId;
        uint64 nonce;
        uint32 bridgeSlippage;
        uint32 toContractGasLimit;
        bytes32 id;
        bytes32 bridge;
        bytes toContractCallData;
        bytes srcParaswapData;
        bytes dstParaswapData;
    }

    event ExecutorFeeClaimed(uint256 amount, address receiver);
    event CelerMessageBusSet(address celerMessageBus);
    event CBridgeSet(address cBridge);
    event PriceTrackerSet(address priceTracker);
    event ExecutorFeeSet(uint256 executorFee);

    constructor(
        address _weth,
        address _otherToken,
        uint256[] memory _pathCountAndSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _celerMessageBus,
        address _cBridge,
        address _paraswapProxy,
        address _augustusSwapper,
        address _priceTracker
    ) Switch(_weth, _otherToken, _pathCountAndSplit[0], _pathCountAndSplit[1], _factories, _switchViewAddress, _switchEventAddress, _paraswapProxy, _augustusSwapper)
        public
    {
        celerMessageBus = _celerMessageBus;
        cBridge = _cBridge;
        priceTracker = _priceTracker;
    }

    modifier onlyMessageBus() {
        require(msg.sender == celerMessageBus, "caller is not message bus");
        _;
    }

    function setCelerMessageBus(address _celerMessageBus) external onlyOwner {
        celerMessageBus = _celerMessageBus;
        emit CelerMessageBusSet(celerMessageBus);
    }

    function cBridgeSet(address _cBridge) external onlyOwner {
        cBridge = _cBridge;
        emit CelerMessageBusSet(cBridge);
    }

    function setPriceTracker(address _priceTracker) external onlyOwner {
        priceTracker = _priceTracker;
        emit PriceTrackerSet(priceTracker);
    }

    function setExecutorFee(uint256 _executorFee) external onlyOwner {
        require(_executorFee > 0, "price cannot be 0");
        executorFee = _executorFee;
        emit ExecutorFeeSet(_executorFee);
    }

    function claimExecutorFee(address feeReceiver) external onlyOwner {
        payable(feeReceiver).transfer(claimableExecutionFee);
        emit ExecutorFeeClaimed(claimableExecutionFee, feeReceiver);
        claimableExecutionFee = 0;
    }

    function getAdjustedExecutorFee(uint256 dstChainId) public view returns(uint256) {
        return IPriceTracker(priceTracker).getPrice(block.chainid, dstChainId) * executorFee / 1e18;
    }

    function getSgnFeeByMessage(bytes memory message) public view returns(uint256) {
        return IMessageBus(celerMessageBus).calcFee(message);
    }

    function getSgnFee(
        bytes32 id,
        bytes32 bridge,
        address srcToken, // source token of sending chain
        address bridgeToken, // bridge token of receiving chain
        address dstToken, // destination token of receiving chain
        address recipient,
        uint256 srcAmount,
        uint256 bridgeDstAmount,
        uint256 estimatedDstAmount,
        DataTypes.ParaswapUsageStatus paraswapUsageStatus,
        uint256[] memory dstDistribution,
        bytes memory dstParaswapData // calldata from paraswap on destination chain
    )
        external
        view
        returns (uint256 sgnFee)
    {

        bytes memory message = abi.encode(
            CelerSwapRequest({
                id: id,
                bridge: bridge,
                srcToken: srcToken,
                bridgeToken: bridgeToken,
                dstToken: dstToken,
                recipient: recipient,
                srcAmount: srcAmount,
                dstDistribution: dstDistribution,
                bridgeDstAmount: bridgeDstAmount,
                estimatedDstAmount: estimatedDstAmount,
                paraswapUsageStatus: paraswapUsageStatus,
                dstParaswapData: dstParaswapData
            })
        );

        sgnFee = IMessageBus(celerMessageBus).calcFee(message);
    }

    function transferByCeler(
        TransferArgsCeler calldata transferArgs
    )
        external
        payable
        nonReentrant
        returns (bytes32 transferId)
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(transferArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != transferArgs.dstChainId, "Cannot bridge to same network");

        IERC20(transferArgs.fromToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.fromToken), transferArgs.amount, transferArgs.partner);

        bool isNative = IERC20(transferArgs.fromToken).isETH();
        if (isNative) {
            ICBridge(cBridge).sendNative{ value: amountAfterFee }(
                transferArgs.recipient,
                amountAfterFee,
                transferArgs.dstChainId,
                transferArgs.nonce,
                transferArgs.bridgeSlippage
            );
        } else {
            // Give cbridge approval
            uint256 approvedAmount = IERC20(transferArgs.fromToken).allowance(address(this), cBridge);
            if (approvedAmount < amountAfterFee) {
                IERC20(transferArgs.fromToken).safeIncreaseAllowance(cBridge, amountAfterFee - approvedAmount);
            }

            ICBridge(cBridge).send(
                transferArgs.recipient,
                transferArgs.fromToken,
                amountAfterFee,
                transferArgs.dstChainId,
                transferArgs.nonce,
                transferArgs.bridgeSlippage
            );
        }

        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                transferArgs.recipient,
                transferArgs.fromToken,
                amountAfterFee,
                transferArgs.dstChainId,
                transferArgs.nonce,
                uint64(block.chainid)
            )
        );
        _emitCrossChainTransferRequest(transferArgs, transferId, amountAfterFee, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function swapByCeler(
        SwapArgsCeler calldata transferArgs
    )
        external
        payable
        nonReentrant
        returns (bytes32 transferId)
    {
        require(transferArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(transferArgs.expectedReturn >= transferArgs.minReturn, "expectedReturn must be equal or larger than minReturn");
        IERC20(transferArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(transferArgs.srcSwap.srcToken), transferArgs.amount, transferArgs.partner);

        bytes memory message = abi.encode(
            CelerSwapRequest({
                id: transferArgs.id,
                bridge: transferArgs.bridge,
                srcToken: transferArgs.srcSwap.srcToken,
                bridgeToken: transferArgs.dstSwap.srcToken,
                dstToken: transferArgs.dstSwap.dstToken,
                recipient: transferArgs.recipient,
                srcAmount: amountAfterFee,
                dstDistribution: transferArgs.dstDistribution,
                dstParaswapData: transferArgs.dstParaswapData,
                paraswapUsageStatus: transferArgs.paraswapUsageStatus,
                bridgeDstAmount: transferArgs.bridgeDstAmount,
                estimatedDstAmount: transferArgs.estimatedDstTokenAmount
            })
        );

        uint256 adjustedExecutionFee = getAdjustedExecutorFee(transferArgs.dstChainId);
        uint256 sgnFee = getSgnFeeByMessage(message);
        if (IERC20(transferArgs.srcSwap.srcToken).isETH()) {
            require(msg.value >= transferArgs.amount + sgnFee + adjustedExecutionFee, 'native token is not enough');
        } else {
            require(msg.value >= sgnFee + adjustedExecutionFee, 'native token is not enough');
        }

        payable(address(this)).transfer(adjustedExecutionFee);
        claimableExecutionFee += adjustedExecutionFee;

        if (transferArgs.srcSwap.srcToken == transferArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            if ((transferArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.OnSrcChain) || (transferArgs.paraswapUsageStatus == DataTypes.ParaswapUsageStatus.Both)) {
                returnAmount = _swapFromParaswap(transferArgs, amountAfterFee);
            } else {
                (returnAmount, ) = _swapBeforeCeler(transferArgs, amountAfterFee);
            }
        }

        require(returnAmount > 0, 'The amount too small');

        //MessageSenderLib is your swiss army knife of sending messages
        transferId = MessageSenderLib.sendMessageWithTransfer(
            transferArgs.callTo,
            transferArgs.srcSwap.dstToken,
            returnAmount,
            transferArgs.dstChainId,
            transferArgs.nonce,
            transferArgs.bridgeSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            celerMessageBus,
            sgnFee
        );

        _emitCrossChainSwapRequest(transferArgs, transferId, returnAmount, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function depositByCeler(
        DepositArgsCeler calldata depositArgs
    )
        external
        payable
        returns (bytes32 transferId)
    {
        require(depositArgs.recipient == msg.sender, "recipient must be equal to caller");
        require(depositArgs.expectedReturn >= depositArgs.minReturn, "expectedReturn must be equal or larger than minReturn");
        require(depositArgs.toApprovalAddress != address(0), "The approval address shouldn't be zero");
        IERC20(depositArgs.srcSwap.srcToken).universalTransferFrom(msg.sender, address(this), depositArgs.amount);

        uint256 returnAmount = 0;
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(depositArgs.srcSwap.srcToken), depositArgs.amount, depositArgs.partner);

        bytes memory message = abi.encode(
            CelerDepositRequest({
                id: depositArgs.id,
                bridge: depositArgs.bridge,
                srcToken: depositArgs.srcSwap.srcToken,
                bridgeToken: depositArgs.dstSwap.srcToken,
                depositToken: depositArgs.dstSwap.dstToken,
                recipient: depositArgs.recipient,
                srcAmount: amountAfterFee,
                dstParaswapData: depositArgs.dstParaswapData,
                paraswapUsageStatus: depositArgs.paraswapUsageStatus,
                bridgeDstAmount: depositArgs.bridgeDstAmount,
                estimatedDepositAmount: depositArgs.estimatedDepositAmount,
                depositContract: depositArgs.depositContract,
                toContractCallData: depositArgs.toContractCallData,
                toContractGasLimit: depositArgs.toContractGasLimit,
                toApprovalAddress: depositArgs.toApprovalAddress // if the approval address is different than the contractTo address
            })
        );

        uint256 adjustedExecutionFee = getAdjustedExecutorFee(depositArgs.dstChainId);
        uint256 sgnFee = getSgnFeeByMessage(message);
        if (IERC20(depositArgs.srcSwap.srcToken).isETH()) {
            require(msg.value >= depositArgs.amount + sgnFee + adjustedExecutionFee, 'native token is not enough');
        } else {
            require(msg.value >= sgnFee + adjustedExecutionFee, 'native token is not enough');
        }

        payable(address(this)).transfer(adjustedExecutionFee);
        claimableExecutionFee += adjustedExecutionFee;

        if (depositArgs.srcSwap.srcToken == depositArgs.srcSwap.dstToken) {
            returnAmount = amountAfterFee;
        } else {
            returnAmount = _swapFromParaswap(depositArgs, amountAfterFee);
        }

        require(returnAmount > 0, 'The amount too small');
        //MessageSenderLib is your swiss army knife of sending messages
        transferId = MessageSenderLib.sendMessageWithTransfer(
            depositArgs.callTo,
            depositArgs.srcSwap.dstToken,
            returnAmount,
            depositArgs.dstChainId,
            depositArgs.nonce,
            depositArgs.bridgeSlippage,
            message,
            MsgDataTypes.BridgeSendType.Liquidity,
            celerMessageBus,
            sgnFee
        );

        _emitCrossChainDepositRequest(depositArgs, transferId, returnAmount, msg.sender, DataTypes.DepositStatus.Succeeded);
    }

    function _swapFromParaswap(
        SwapArgsCeler calldata swapArgs,
        uint256 amount
    )
        private
        returns (uint256 returnAmount)
    {
        // break function to avoid stack too deep error
        returnAmount = _swapInternalWithParaSwap(IERC20(swapArgs.srcSwap.srcToken), IERC20(swapArgs.srcSwap.dstToken), amount, swapArgs.srcParaswapData);
    }

    function _swapFromParaswap(
        DepositArgsCeler calldata depositArgs,
        uint256 amount
    )
        private
        returns (uint256 returnAmount)
    {
        // break function to avoid stack too deep error
        returnAmount = _swapInternalWithParaSwap(IERC20(depositArgs.srcSwap.srcToken), IERC20(depositArgs.srcSwap.dstToken), amount, depositArgs.srcParaswapData);
    }

    function _swapBeforeCeler(SwapArgsCeler calldata transferArgs, uint256 amount) private returns (uint256 returnAmount, uint256 parts) {
        parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < transferArgs.srcDistribution.length; i++) {
            if (transferArgs.srcDistribution[i] > 0) {
                parts += transferArgs.srcDistribution[i];
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "invalid distribution param");

        // break function to avoid stack too deep error
        returnAmount = _swapInternalForSingleSwap(transferArgs.srcDistribution, amount, parts, lastNonZeroIndex, IERC20(transferArgs.srcSwap.srcToken), IERC20(transferArgs.srcSwap.dstToken));
        require(returnAmount > 0, "Swap failed from dex");

        switchEvent.emitSwapped(msg.sender, address(this), IERC20(transferArgs.srcSwap.srcToken), IERC20(transferArgs.srcSwap.dstToken), amount, returnAmount, 0);
    }

    function _emitCrossChainSwapRequest(SwapArgsCeler calldata transferArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.SwapStatus status) internal {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.srcSwap.srcToken,
            transferArgs.srcSwap.dstToken,
            transferArgs.dstSwap.dstToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.estimatedDstTokenAmount,
            status
        );
    }

    function _emitCrossChainDepositRequest(DepositArgsCeler calldata depositArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.DepositStatus status) internal {
        switchEvent.emitCrosschainDepositRequest(
            depositArgs.id,
            transferId,
            depositArgs.bridge,
            sender,
            depositArgs.depositContract,
            depositArgs.toApprovalAddress,
            depositArgs.srcSwap.srcToken,
            depositArgs.dstSwap.dstToken,
            depositArgs.amount,
            depositArgs.estimatedDepositAmount,
            status
        );
    }

    function _emitCrossChainTransferRequest(TransferArgsCeler calldata transferArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.SwapStatus status) internal {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.fromToken,
            transferArgs.fromToken,
            transferArgs.destToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.bridgeDstAmount,
            status
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../interfaces/IUniswapFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ISwitchView {

    struct ReturnArgs {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
    }

    struct CalculateArgs {
        IERC20 fromToken;
        IERC20 destToken;
        IUniswapFactory factory;
        uint256 amount;
        uint256 parts;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        virtual
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) virtual external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./ISwitchView.sol";
import "./IWETH.sol";
import "../lib/DisableFlags.sol";
import "../lib/UniversalERC20.sol";
import "../interfaces/IUniswapFactory.sol";
import "../lib/UniswapExchangeLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SwitchRoot is Ownable, ISwitchView {
    using DisableFlags for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapExchangeLib for IUniswapExchange;

    address public ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public ZERO_ADDRESS = address(0);

    uint256 public dexCount;
    uint256 public pathCount;
    uint256 public pathSplit;
    IWETH public weth; // chain's native token
    IWETH public otherToken; //could be weth on a non-eth chain or other mid token(like busd)

    address[] public factories;

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    constructor(address _weth, address _otherToken, uint256 _pathCount, uint256 _pathSplit, address[] memory _factories) {
        weth = IWETH(_weth);
        otherToken = IWETH(_otherToken);
        pathCount = _pathCount;
        pathSplit = _pathSplit;
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
    }

    event WETHSet(address _weth);
    event OtherTokenSet(address _otherToken);
    event PathCountSet(uint256 _pathCount);
    event PathSplitSet(uint256 _pathSplit);
    event FactoriesSet(address[] _factories);

    function setWETH(address _weth) external onlyOwner {
        weth = IWETH(_weth);
        emit WETHSet(_weth);
    }

    function setOtherToken(address _otherToken) external onlyOwner {
        otherToken = IWETH(_otherToken);
        emit OtherTokenSet(_otherToken);
    }

    function setPathCount(uint256 _pathCount) external onlyOwner {
        pathCount = _pathCount;
        emit PathCountSet(_pathCount);
    }

    function setPathSplit(uint256 _pathSplit) external onlyOwner {
        pathSplit = _pathSplit;
        emit PathSplitSet(_pathSplit);
    }

    function setFactories(address[] memory _factories) external onlyOwner {
        dexCount = _factories.length;
        for (uint256 i = 0; i < _factories.length; i++) {
            factories.push(_factories[i]);
        }
        emit FactoriesSet(_factories);
    }

    function _findBestDistribution(
        uint256 s,                // parts
        int256[][] memory amounts // exchangesReturns
    )
        internal
        view
        returns (
            int256 returnAmount,
            uint256[] memory distribution
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](dexCount*pathCount*pathSplit);

        uint256 partsLeft = s;
        unchecked {
            for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
                distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
                partsLeft = parent[curExchange][partsLeft];
            }
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? int256(0) : answer[n - 1][s];
    }

    function _linearInterpolation(
        uint256 value,
        uint256 parts
    )
        internal
        pure
        returns (uint256[] memory rets)
    {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value * (i + 1) / parts;
        }
    }

    function _tokensEqual(
        IERC20 tokenA,
        IERC20 tokenB
    )
        internal
        pure
        returns (bool)
    {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../core/ISwitchView.sol";
import "../core/SwitchRoot.sol";
import "../interfaces/ISwitchEvent.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Switch is SwitchRoot, ReentrancyGuard {
    using UniswapExchangeLib for IUniswapExchange;
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;

    ISwitchView public switchView;
    ISwitchEvent public switchEvent;
    address public reward;
    address private paraswapProxy;
    address private augustusSwapper;
    address public tradeFeeReceiver;
    uint256 public tradeFeeRate;
    mapping (address => uint256) public partnerFeeRates;

    uint256 public constant FEE_BASE = 10000;

    event RewardSet(address reward);
    event SwitchEventSet(address switchEvent);
    event SwitchViewSet(address switchView);
    event PartnerFeeSet(address partner, uint256 feeRate);
    event TradeFeeSet(uint256 tradeFee);
    event TradeFeeReceiverSet(address tradeFeeReceiver);
    event ParaswapProxySet(address paraswapProxy);
    event AugustusSwapperSet(address augustusSwapper);

    constructor(
        address _weth,
        address _otherToken,
        uint256 _pathCount,
        uint256 _pathSplit,
        address[] memory _factories,
        address _switchViewAddress,
        address _switchEventAddress,
        address _paraswapProxy,
        address _augustusSwapper
    ) SwitchRoot(_weth, _otherToken, _pathCount, _pathSplit, _factories)
        public
    {
        switchView = ISwitchView(_switchViewAddress);
        switchEvent = ISwitchEvent(_switchEventAddress);
        paraswapProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;
        reward = msg.sender;
    }

    fallback() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function setReward(address _reward) external onlyOwner {
        reward = _reward;
        emit RewardSet(_reward);
    }

    function setSwitchEvent(address _switchEvent) external onlyOwner {
        switchEvent = ISwitchEvent(_switchEvent);
        emit SwitchEventSet(_switchEvent);
    }

    function setSwitchView(address _switchView) external onlyOwner {
        switchView = ISwitchView(_switchView);
        emit SwitchViewSet(_switchView);
    }

    function setParaswapProxy(address _paraswapProxy) external onlyOwner {
        paraswapProxy = _paraswapProxy;
        emit ParaswapProxySet(_paraswapProxy);
    }

    function setAugustusSwapper(address _augustusSwapper) external onlyOwner {
        augustusSwapper = _augustusSwapper;
        emit AugustusSwapperSet(_augustusSwapper);
    }

    function setPartnerFeeRate(address _partner, uint256 _feeRate) external onlyOwner {
        partnerFeeRates[_partner] = _feeRate;
        emit PartnerFeeSet(_partner, _feeRate);
    }

    function setTradeFeeRate(uint256 _tradeFeeRate) external onlyOwner {
        tradeFeeRate = _tradeFeeRate;
        emit TradeFeeSet(_tradeFeeRate);
    }

    function setTradeFeeReceiver(address _tradeFeeReceiver) external onlyOwner {
        tradeFeeReceiver = _tradeFeeReceiver;
        emit TradeFeeReceiverSet(_tradeFeeReceiver);
    }

    function getTokenBalance(address token) external view onlyOwner returns(uint256 amount) {
        amount = IERC20(token).universalBalanceOf(address(this));
    }

    function transferToken(address token, uint256 amount, address recipient) external onlyOwner {
        IERC20(token).universalTransfer(recipient, amount);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        override
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, distribution) = switchView.getExpectedReturn(fromToken, destToken, amount, parts);
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 expectedReturn,
        uint256 minReturn,
        address recipient,
        uint256[] memory distribution
    )
        public
        payable
        nonReentrant
        returns (uint256 returnAmount)
    {
        require(expectedReturn >= minReturn, "expectedReturn must be equal or larger than minReturn");
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts += distribution[i];
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (fromToken.isETH()) {
                payable(msg.sender).transfer(msg.value);
                return msg.value;
            }
            return amount;
        }

        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        returnAmount = _swapInternalForSingleSwap(distribution, amount, parts, lastNonZeroIndex, fromToken, destToken);
        if (returnAmount > 0) {
            require(returnAmount >= minReturn, "Switch: Return amount was not enough");

            if (returnAmount > expectedReturn) {
                destToken.universalTransfer(recipient, expectedReturn);
                destToken.universalTransfer(reward, returnAmount - expectedReturn);
                switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, expectedReturn, returnAmount - expectedReturn);
            } else {
                destToken.universalTransfer(recipient, returnAmount);
                switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, returnAmount, 0);
            }
        } else {
            if (fromToken.universalBalanceOf(address(this)) > amount) {
                fromToken.universalTransfer(msg.sender, amount);
            } else {
                fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
            }
        }
    }

    function swapWithParaswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 destAmount,
        address recipient,
        bytes memory callData
    )
        public
        payable
        nonReentrant
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }
        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        _callParaswap(fromToken, amount, callData);
        switchEvent.emitSwapped(msg.sender, recipient, fromToken, destToken, amount, destAmount, 0);
    }

    function getFeeInfo(
        uint256 amount,
        address partner
    )
        public
        view
        returns (
            uint256 tradeRate,
            uint256 partnerFeeRate,
            uint256 tradeFee,
            uint256 partnerFee,
            uint256 remainAmount
        )
    {
        tradeRate = tradeFeeRate;
        tradeFee = 0;
        partnerFeeRate = partnerFeeRates[partner];
        partnerFee = 0;
        if (tradeFeeRate > 0) {
            tradeFee = tradeFeeRate * amount / FEE_BASE;
        }
        if (partnerFeeRates[partner] > 0) {
            partnerFee = partnerFeeRates[partner] * amount / FEE_BASE;
        }
        remainAmount = amount - tradeFee - partnerFee;
    }

    function getTradeFee(
        uint256 amount
    )
        public
        view
        returns (
            uint256 feeRate,
            uint256 tradeFee,
            uint256 remainAmount
        )
    {
        feeRate = tradeFeeRate;
        tradeFee = 0;
        if (tradeFeeRate > 0) {
            tradeFee = tradeFeeRate * amount / FEE_BASE;
        }
        remainAmount = amount - tradeFee;
    }

    function getPartnerFee(
        uint256 amount,
        address partner
    )
        public
        view
        returns (
            uint256 feeRate,
            uint256 partnerFee,
            uint256 remainAmount
        )
    {
        feeRate = partnerFeeRates[partner];
        partnerFee = 0;
        if (partnerFeeRates[partner] > 0) {
            partnerFee = partnerFeeRates[partner] * amount / FEE_BASE;
        }
        remainAmount = amount - partnerFee;
    }

    function _swapInternalWithParaSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        bytes memory callData
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        if (fromToken == destToken) {
            revert("it's not allowed to swap with same token");
        }

        _callParaswap(fromToken, amount, callData);
        totalAmount = destToken.universalBalanceOf(address(this));
        switchEvent.emitSwapped(msg.sender, address(this), fromToken, destToken, amount, totalAmount, 0);
    }

    function _callParaswap(
        IERC20 token,
        uint256 amount,
        bytes memory callData
    )
        internal
    {
        uint256 ethAmountToTransfert = 0;
        if (token.isETH()) {
            require(address(this).balance >= amount, "ETH balance is insufficient");
            ethAmountToTransfert = amount;
        } else {
            token.universalApprove(paraswapProxy, amount);
        }

        (bool success,) = augustusSwapper.call{ value: ethAmountToTransfert }(callData);
        require(success, "Paraswap execution failed");
    }

    function _swapInternalForSingleSwap(
        uint256[] memory distribution,
        uint256 amount,
        uint256 parts,
        uint256 lastNonZeroIndex,
        IERC20 fromToken,
        IERC20 destToken
    )
        internal
        returns (
            uint256 totalAmount
        )
    {
        require(distribution.length <= dexCount*pathCount, "Switch: Distribution array should not exceed factories array size");

        uint256 remainingAmount = amount;
        uint256 swappedAmount = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }
            uint256 swapAmount = amount * distribution[i] / parts;
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            if (i % pathCount == 0) {
                swappedAmount = _swap(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else if (i % pathCount == 1) {
                swappedAmount = _swapETH(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            } else {
                swappedAmount = _swapOtherToken(fromToken, destToken, swapAmount, IUniswapFactory(factories[i/pathCount]));
            }
            totalAmount += swappedAmount;
        }
    }

    function _getAmountAfterFee(
        IERC20 token,
        uint256 amount,
        address partner
    )
        internal
        returns (
            uint256 amountAfterFee
        )
    {
        amountAfterFee = amount;
        if (tradeFeeRate > 0) {
            token.universalTransfer(tradeFeeReceiver, tradeFeeRate * amount / FEE_BASE);
            amountAfterFee = amount - tradeFeeRate * amount / FEE_BASE;
        }
        if (partnerFeeRates[partner] > 0) {
            token.universalTransfer(partner, partnerFeeRates[partner] * amount / FEE_BASE);
            amountAfterFee = amount - partnerFeeRates[partner] * amount / FEE_BASE;
        }
    }

    // Swap helpers
    function _swapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        if (fromToken.isETH()) {
            weth.deposit{value: amount}();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(0x46Fd07da395799F113a7584563b8cB886F33c2bc);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint160(address(fromTokenReal)) < uint160(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            midToken,
            destToken,
            _swapInternal(
                fromToken,
                midToken,
                amount,
                factory
            ),
            factory
        );
    }

    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapInternal(
            fromToken,
            destToken,
            amount,
            factory
        );
    }

    function _swapETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            weth,
            destToken,
            amount,
            factory
        );
    }

    function _swapOtherToken(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        IUniswapFactory factory
    )
        internal
        returns (
            uint256 returnAmount
        )
    {
        returnAmount = _swapOverMid(
            fromToken,
            otherToken,
            destToken,
            amount,
            factory
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface ICBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;
}

pragma solidity ^0.8.0;

interface IPriceTracker {
    function getPrice(uint256 _srcChainId, uint256 _dstChainId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/DataTypes.sol";

interface ISwitchEvent {
    function emitSwapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    ) external;

    function emitParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    ) external;

    function emitCrosschainSwapRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address fromToken, // source token on sending chain
        address bridgeToken, // bridge token on sending chain
        address destToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 bridgeAmount, // swapped amount on sending chain
        uint256 dstAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainDepositRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address depositContract, // contract address for deposit
        address toApprovalAddress, // the approval address for deposit
        address fromToken, // source token on sending chain
        address depositToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 depositAmount, // estimated amount of dest token on receiving chain
        DataTypes.DepositStatus status
    ) external;

    function emitCrosschainSwapDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    ) external;

    function emitCrosschainDepositDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address depositContract, // contract address for deposit
        address toApprovalAddress, // the approval address for deposit
        address bridgeToken, // source token on receiving chain
        address depositToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 depositAmount, //dest token amount on receiving chain
        DataTypes.DepositStatus status
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IUniswapExchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapExchange.sol";

interface IUniswapFactory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapExchange pair);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/**
 * @title DataTypes
 * @dev Definition of shared types
 */
library DataTypes {
    /// @notice Type for representing a swapping status type
    enum SwapStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    enum DepositStatus {
        Null,
        Succeeded,
        Failed,
        Fallback
    }

    /// @notice Type for representing a paraswap usage status
    enum ParaswapUsageStatus {
        None,
        OnSrcChain,
        OnDestChain,
        Both
    }

    /// @notice Swap params
    struct SwapInfo {
        address srcToken;
        address dstToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

library DisableFlags {
    function check(
        uint256 flags,
        uint256 flag
    )
        internal
        pure
        returns (bool)
    {
        return (flags & flag) != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "../interfaces/IUniswapExchange.sol";
import "./Math.sol";
import "./UniversalERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library UniswapExchangeLib {
    using Math for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapExchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    )
        internal
        view
        returns (uint256 result, bool needSync, bool needSkim)
    {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserveIn < reserve0 || reserveOut < reserve1);
        needSkim = !needSync && (reserveIn > reserve0 || reserveOut > reserve1);

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * Math.min(reserveOut, reserve1);
        uint256 denominator = Math.min(reserveIn, reserve0) * 1000 + amountInWithFee;
        result = (denominator == 0) ? 0 : numerator / denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniversalERC20 {

    using SafeERC20 for IERC20;

    address private constant ZERO_ADDRESS = address(0x0000000000000000000000000000000000000000);
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
        returns (bool)
    {
        if (amount == 0) {
            return true;
        }
        if (isETH(token)) {
            payable(to).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                payable(to).transfer(amount);
            }
            // commented following lines for passing celer fee properly.
//            if (msg.value > amount) {
//                payable(msg.sender).transfer(msg.value - amount);
//            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(
        IERC20 token,
        uint256 amount
    )
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value - amount);
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    )
        internal
    {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 approvedAmount = token.allowance(address(this), to);

            if (approvedAmount < amount) {
                token.safeIncreaseAllowance(to, amount - approvedAmount);
            } else if (approvedAmount > amount) {
                token.safeDecreaseAllowance(to, approvedAmount - amount);
            }
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    // function notExist(IERC20 token) internal pure returns(bool) {
    //     return (address(token) == address(-1));
    // }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVault {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVaultV2 {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridge {
    /**
     * @notice Burn tokens to trigger withdrawal at a remote chain's OriginalTokenVault
     * @param _token local token address
     * @param _amount locked token amount
     * @param _withdrawAccount account who withdraw original tokens on the remote chain
     * @param _nonce user input to guarantee unique depositId
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridgeV2 {
    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault, or mint at another remote chain
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _toChainId If zero, withdraw from original vault; otherwise, the remote chain to mint tokens.
     * @param _toAccount The account to receive tokens on the remote chain
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    // same with `burn` above, use openzeppelin ERC20Burnable interface
    function burnFrom(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../libraries/MsgDataTypes.sol";

interface IMessageBus {
    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Sends a message associated with a transfer to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../interfaces/IMessageBus.sol";
import "./MsgDataTypes.sol";

library MessageSenderLib {
    using SafeERC20 for IERC20;

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal {
        IMessageBus(_messageBus).sendMessage{value: _fee}(_receiver, _dstChainId, _message);
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded. Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.Liquidity) {
            return
                sendMessageWithLiquidityBridgeTransfer(
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _maxSlippage,
                    _message,
                    _messageBus,
                    _fee
                );
        } else if (
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit ||
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Deposit
        ) {
            return
                sendMessageWithPegVaultDeposit(
                    _bridgeSendType,
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _message,
                    _messageBus,
                    _fee
                );
        } else if (
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn ||
            _bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Burn
        ) {
            return
                sendMessageWithPegBridgeBurn(
                    _bridgeSendType,
                    _receiver,
                    _token,
                    _amount,
                    _dstChainId,
                    _nonce,
                    _message,
                    _messageBus,
                    _fee
                );
        } else {
            revert("bridge type not supported");
        }
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated liquidity bridge transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithLiquidityBridgeTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address bridge = IMessageBus(_messageBus).liquidityBridge();
        IERC20(_token).safeIncreaseAllowance(bridge, _amount);
        IBridge(bridge).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
        );
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            bridge,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated OriginalTokenVault deposit.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithPegVaultDeposit(
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address pegVault;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            pegVault = IMessageBus(_messageBus).pegVault();
        } else {
            pegVault = IMessageBus(_messageBus).pegVaultV2();
        }
        IERC20(_token).safeIncreaseAllowance(pegVault, _amount);
        bytes32 transferId;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            IOriginalTokenVault(pegVault).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _dstChainId, _receiver, _nonce, uint64(block.chainid))
            );
        } else {
            transferId = IOriginalTokenVaultV2(pegVault).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        }
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            pegVault,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated PeggedTokenBridge burn.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithPegBridgeBurn(
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        address pegBridge;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            pegBridge = IMessageBus(_messageBus).pegBridge();
        } else {
            pegBridge = IMessageBus(_messageBus).pegBridgeV2();
        }
        IERC20(_token).safeIncreaseAllowance(pegBridge, _amount);
        bytes32 transferId;
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            IPeggedTokenBridge(pegBridge).burn(_token, _amount, _receiver, _nonce);
            transferId = keccak256(
                abi.encodePacked(address(this), _token, _amount, _receiver, _nonce, uint64(block.chainid))
            );
        } else {
            transferId = IPeggedTokenBridgeV2(pegBridge).burn(_token, _amount, _dstChainId, _receiver, _nonce);
        }
        // handle cases where certain tokens do not spend allowance for role-based burn
        IERC20(_token).safeApprove(pegBridge, 0);
        IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
            _receiver,
            _dstChainId,
            pegBridge,
            transferId,
            _message
        );
        return transferId;
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _bridge
    ) internal {
        IERC20(_token).safeIncreaseAllowance(_bridge, _amount);
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.Liquidity) {
            IBridge(_bridge).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            IOriginalTokenVault(_bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            IPeggedTokenBridge(_bridge).burn(_token, _amount, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridge, 0);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Deposit) {
            IOriginalTokenVaultV2(_bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Burn) {
            IPeggedTokenBridgeV2(_bridge).burn(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridge, 0);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2BurnFrom) {
            IPeggedTokenBridgeV2(_bridge).burnFrom(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(_bridge, 0);
        } else {
            revert("bridge type not supported");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

library MsgDataTypes {
    // bridge operation type at the sender side (src chain)
    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    // bridge operation type at the receiver side (dst chain)
    enum TransferType {
        Null,
        LqRelay, // relay through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegV2Mint, // mint through pegged token bridge v2
        PegV2Withdraw // withdraw from original token vault v2
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending // transient state within a transaction
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 wdseq; // only needed for LqWithdraw (refund)
        uint64 srcChainId;
        bytes32 refId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct MsgWithTransferExecutionParams {
        bytes message;
        TransferInfo transfer;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }

    struct BridgeTransferParams {
        bytes request;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }
}