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

import { IAnyswapV4Router } from "../interfaces/IAnyswapV4Router.sol";
import { IAnyswapToken } from "../interfaces/IAnyswapToken.sol";
import "../lib/DataTypes.sol";
import "../core/BaseTrade.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwitchAnyswap is BaseTrade, ReentrancyGuard {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    address public anyswapRouter;

    struct TransferArgsAnyswap {
        address fromToken;
        address bridgeToken;
        address destToken;
        address payable recipient;
        uint256 amount;
        uint256 estimatedDstTokenAmount;
        uint16  dstChainId;
        bytes32 id;
        bytes32 bridge;
        address partner;
    }

    event AnyswapRouterSet(address anyswapRouter);

    constructor(
        address _switchEventAddress,
        address _anyswapRouter
    ) BaseTrade(_switchEventAddress)
        public
    {
        anyswapRouter = _anyswapRouter;
    }

    function setAnyswapRouter(address _anyswapRouter) external onlyOwner {
        anyswapRouter = _anyswapRouter;
        emit AnyswapRouterSet(_anyswapRouter);
    }

    function transferByAnyswap(
        TransferArgsAnyswap calldata transferArgs
    )
        external
        payable
        nonReentrant
    {
        require(transferArgs.recipient == msg.sender, "The recipient must be equal to caller");
        require(transferArgs.amount > 0, "The amount must be greater than zero");
        require(block.chainid != transferArgs.dstChainId, "Cannot bridge to same network");

        // Multichain (formerly Anyswap) tokens can wrap other tokens
        (address underlyingToken, bool isNative) = _getUnderlyingToken(transferArgs.bridgeToken, anyswapRouter);

        IERC20(underlyingToken).universalTransferFrom(msg.sender, address(this), transferArgs.amount);
        uint256 amountAfterFee = _getAmountAfterFee(IERC20(underlyingToken), transferArgs.amount, transferArgs.partner);

        if (isNative) {
            IAnyswapV4Router(anyswapRouter).anySwapOutNative{ value: amountAfterFee }(
                transferArgs.bridgeToken,
                transferArgs.recipient,
                transferArgs.dstChainId
            );
        } else {
            // Give Anyswap approval to bridge tokens
            uint256 approvedAmount = IERC20(underlyingToken).allowance(address(this), anyswapRouter);
            if (approvedAmount < amountAfterFee) {
                IERC20(underlyingToken).safeIncreaseAllowance(anyswapRouter, amountAfterFee - approvedAmount);
            }
            // Was the token wrapping another token?
            if (transferArgs.bridgeToken != underlyingToken) {
                IAnyswapV4Router(anyswapRouter).anySwapOutUnderlying(
                    transferArgs.bridgeToken,
                    transferArgs.recipient,
                    amountAfterFee,
                    transferArgs.dstChainId
                );
            } else {
                IAnyswapV4Router(anyswapRouter).anySwapOut(
                    transferArgs.bridgeToken,
                    transferArgs.recipient,
                    amountAfterFee,
                    transferArgs.dstChainId
                );
            }
        }

        _emitCrossChainTransferRequest(transferArgs, bytes32(0), amountAfterFee, msg.sender, DataTypes.SwapStatus.Succeeded);
    }

    function _getUnderlyingToken(
        address token,
        address router
    )
        private
        returns (address underlyingToken, bool isNative)
    {
        // Token must implement IAnyswapToken interface
        require(token != address (0), 'Token address should not be zero');
        underlyingToken = IAnyswapToken(token).underlying();
        // The native token does not use the standard null address ID
        isNative = IAnyswapV4Router(router).wNATIVE() == underlyingToken;
        // Some Multichain complying tokens may wrap nothing
        if (!isNative && underlyingToken == address(0)) {
            underlyingToken = token;
        }
    }

    function _emitCrossChainTransferRequest(TransferArgsAnyswap calldata transferArgs, bytes32 transferId, uint256 returnAmount, address sender, DataTypes.SwapStatus status) internal {
        switchEvent.emitCrosschainSwapRequest(
            transferArgs.id,
            transferId,
            transferArgs.bridge,
            sender,
            transferArgs.fromToken,
            transferArgs.bridgeToken,
            transferArgs.destToken,
            transferArgs.amount,
            returnAmount,
            transferArgs.estimatedDstTokenAmount,
            status
        );
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/UniversalERC20.sol";
import "../interfaces/ISwitchEvent.sol";

contract BaseTrade is Ownable {
    using UniversalERC20 for IERC20;
    using SafeERC20 for IERC20;
    ISwitchEvent public switchEvent;
    address public tradeFeeReceiver;
    uint256 public tradeFeeRate;
    mapping (address => uint256) public partnerFeeRates;
    uint256 public constant FEE_BASE = 10000;

    event PartnerFeeSet(address partner, uint256 feeRate);
    event TradeFeeSet(uint256 tradeFee);
    event TradeFeeReceiverSet(address tradeFeeReceiver);
    event SwitchEventSet(ISwitchEvent switchEvent);

    constructor(
        address _switchEventAddress
    )
        public
    {
        switchEvent = ISwitchEvent(_switchEventAddress);
    }

    function setSwitchEvent(ISwitchEvent _switchEvent) external onlyOwner {
        switchEvent = _switchEvent;
        emit SwitchEventSet(_switchEvent);
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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IAnyswapToken {
    function underlying() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IAnyswapV4Router{
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;

    function anySwapOut(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;

    function anySwapOutNative(
        address token,
        address to,
        uint256 toChainID
    ) external payable;

    function wNATIVE() external returns (address);
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