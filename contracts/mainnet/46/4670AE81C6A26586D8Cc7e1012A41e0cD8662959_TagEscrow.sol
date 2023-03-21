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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface ITagNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function mintEscrowNft(
        address owningParty,
        address arbitrator,
        uint256 escrowId,
        bool isPartyA,
        string memory metadataUri
    ) external returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ITagNFT.sol";

// TODO accept multiple currencies
contract TagEscrow is
ReentrancyGuard,
Ownable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ITagNFT public NFTContract;

    mapping(uint256 => EscrowVault) public escrows;
    mapping(uint256 => DepositAsset) public escrowAssetsA;
    mapping(uint256 => DepositAsset) public escrowAssetsB;
    mapping(address => IdContainer) private walletEscrows;

    EnumerableSet.UintSet private escrowIds;
    uint256 public nextEscrowId;

    address payable public tagFeeVault;

    uint256 public tagFeeBps;
    uint256 private maxFeeBps;

    string public version = "V1";

    /**
     * @dev The asset deposited for an escrow
     * @param currency The currency deposited
     * @param amount The amount of the asset
     */
    struct DepositAsset {
        IERC20 currency;
        uint256 amount;
    }

    struct IdContainer {
        uint256[] escrowIds;
    }

    /**
     * @dev When a case is created then the escrow is created. If the sender confirms or the handler
     * confirms then the escrow is released.
     * @param escrowId id of the escrow
     * @param partyA The address that will receive the money if the escrow is released
     * @param partyB The address of the person who sent the money
     * @param partyArbitrator The address of the person who is handling the case
     * @param closed Whether the escrow has been closed
     * @param description The text describing what the escrow is
     * @param determineTime The time the escrow can be judged. This is optional if set to 0.
     * @param pendingAssetB The assets to be deposited by partyB
     */
    struct EscrowVault {
        uint256 escrowId;
        address partyA;
        address partyB;
        uint256 nftA;
        uint256 nftB;
        address partyArbitrator;
        uint256 arbitratorFeeBps;
        string description;
        uint256 createTime;
        uint256 determineTime;
        bool started;
        bool closed;
        DepositAsset pendingAssetB;
        address winner;
    }

    // -- EVENTS
    event EscrowCreated(
        uint256 escrowId,
        address partyA,
        address partyB,
        address partyArbitrator,
        uint256 arbitratorFeeBps,
        string description,
        uint256 createTime,
        uint256 determineTime,
        bool started,
        bool closed,
        DepositAsset pendingAssetB
    );
    event EscrowCancelled(uint256 escrowId);
    event EscrowStarted(uint256 escrowId);
    event EscrowDetermined(uint256 escrowId, address winner);
    event FundsReclaimed(uint256 escrowId, address depositor);
    event FundsWithdrawn(uint256 escrowId, address withdrawer);
    event FundsDeposited(
        uint256 escrowId,
        address depositor,
        IERC20 currency,
        uint256 amount,
        uint256 partyANftId,
        uint256 partyBNftId
    );

    // -- MODIFIERS
    modifier onlyCaseArbitrator(uint256 escrowId) {
        require(
            escrows[escrowId].partyArbitrator == msg.sender,
            "Caller is not the Arbitrator"
        );
        _;
    }

    modifier onlyOpenCase(uint256 escrowId) {
        require(escrowIds.contains(escrowId), "Escrow does not exist");
        require(!escrows[escrowId].closed, "Escrow has been closed");
        _;
    }

    modifier onlyParticipatingParty(uint256 escrowId) {
        require(escrows[escrowId].started, "Escrow has not started");
        require(
            NFTContract.ownerOf(escrows[escrowId].nftA) == msg.sender ||
            NFTContract.ownerOf(escrows[escrowId].nftB) == msg.sender,
            "Caller is not a participating party"
        );
        _;
    }

    modifier nftContractOnly() {
        require(msg.sender == address(NFTContract), "Caller is not the NFT Contract");
        _;
    }

    // -- FUNCTIONS
    constructor(address payable _tagFeeVault) {
        require(_tagFeeVault != address(0), "Fee Treasury wallet cannot be 0 address");
        tagFeeVault = _tagFeeVault;
        maxFeeBps = 10000;
        tagFeeBps = 100;
    }

    /**
    * @dev Create a new escrow assigning counterparty, arbitrator and amounts
    * @param partyB The counterparty
    * @param partyArbitrator The Arbitrator
    * @param description The title/description of the escrow determination
    * @param determineTime The time the arbitration can kick off
    * @param currencyToDepositA The currency for the calling party to deposit
    * @param amountToDepositA The amount for the calling party to deposit
    * @param currencyToDepositB The currency for the counterparty to deposit
    * @param amountToDepositB The amount for the counterparty to deposit
    * @return escrowId the ID of the created Escrow
    */
    function createEscrow(
        address partyB,
        address partyArbitrator,
        uint256 arbitratorFeeBps,
        string memory description,
        uint256 determineTime,
        IERC20 currencyToDepositA,
        uint256 amountToDepositA,
        IERC20 currencyToDepositB,
        uint256 amountToDepositB
    ) external payable returns (uint256) {
        require(partyB != address(0) && partyArbitrator != address(0), "Cannot set the address to 0x for other parties");
        require(msg.sender != partyArbitrator && partyB != partyArbitrator, "Cannot set as Arbitrator the parties themselves");
        require(arbitratorFeeBps <= 2000, "Cannot set the arbitrator fee higher than 20 %");
        require(msg.sender != partyB, "Parties cannot be the same account");
        require(determineTime > block.timestamp, "Time of bet should be after current time");
        require(amountToDepositB > 0 && (msg.value > 0 || amountToDepositA > 0), "You cannot request amounts less than 0");

        // ERC20 token
        if (address(currencyToDepositA) != address(0)) {
            currencyToDepositA.safeTransferFrom(msg.sender, address(this), amountToDepositA - amountToDepositA * tagFeeBps / maxFeeBps);
            currencyToDepositA.safeTransferFrom(msg.sender, tagFeeVault, amountToDepositA * tagFeeBps / maxFeeBps);
        } else {
            // GAS token
            require(msg.value == amountToDepositA, "The amount sent is not the amount determined in the call");
            (bool successA, ) = tagFeeVault.call{value: amountToDepositA * tagFeeBps / maxFeeBps}("");
            require(successA, "Something went wrong with collecting the tag fee. Gas token");
        }

        escrowAssetsA[nextEscrowId] = DepositAsset({
            currency: currencyToDepositA,
            amount: address(currencyToDepositA) == address(0) ? msg.value : amountToDepositA
        });

        escrows[nextEscrowId] = EscrowVault({
            escrowId: nextEscrowId,
            partyA: msg.sender,
            partyB: partyB,
            partyArbitrator: partyArbitrator,
            arbitratorFeeBps: arbitratorFeeBps,
            description: description,
            createTime: block.timestamp,
            determineTime: determineTime,
            started: false,
            closed: false,
            nftA: 0,
            nftB: 0,
            pendingAssetB: DepositAsset({
                currency: currencyToDepositB,
                amount: amountToDepositB
            }),
            winner: address(0)
        });

        escrowIds.add(nextEscrowId);
        addEscrowIdToAddress(nextEscrowId, msg.sender);
        addEscrowIdToAddress(nextEscrowId, partyB);
        addEscrowIdToAddress(nextEscrowId, partyArbitrator);

        emit EscrowCreated(
            nextEscrowId,
            msg.sender,
            partyB,
            partyArbitrator,
            arbitratorFeeBps,
            description,
            block.timestamp,
            determineTime,
            false,
            false,
            escrows[nextEscrowId].pendingAssetB
        );

        generateEscrowId();
        return nextEscrowId;
    }

    // TODO set the 2 NFT urls for metadata here, not the best design but easier based on what we want to achieve
    /**
    * @dev Deposits funds for partyB (counterparty) and sets the escrow as `started`
    * @param escrowId The ID to deposit the funds to.
    */
    function depositFunds(uint256 escrowId, string memory nftUrlA, string memory nftUrlB)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    {
        require(msg.sender == escrows[escrowId].partyB, "Only partyB can deposit funds after creation");

        bool valid = escrowAssetsB[escrowId].amount > 0;
        require(!valid, "You have already deposited funds");

        DepositAsset memory assetToDeposit = escrows[escrowId].pendingAssetB;
        // ERC20 token
        if (address(assetToDeposit.currency) != address(0)) {
            assetToDeposit.currency.safeTransferFrom(msg.sender, address(this), assetToDeposit.amount - assetToDeposit.amount * tagFeeBps / maxFeeBps);
            assetToDeposit.currency.safeTransferFrom(msg.sender, tagFeeVault, assetToDeposit.amount * tagFeeBps / maxFeeBps);
        } else {
            // GAS token
            (bool successA, ) = tagFeeVault.call{value: assetToDeposit.amount * tagFeeBps / maxFeeBps}("");
            require(successA, "Something went wrong with collecting the tag fee. Gas token");
            require(msg.value == assetToDeposit.amount, "The amount sent is not the amount determined in the call");
        }

        escrowAssetsB[escrowId] = assetToDeposit;

        uint256 nftId1 = NFTContract.mintEscrowNft(
            escrows[escrowId].partyA,
            escrows[escrowId].partyArbitrator,
            escrowId,
            true,
            nftUrlA
        );
        uint256 nftId2 = NFTContract.mintEscrowNft(
            escrows[escrowId].partyB,
            escrows[escrowId].partyArbitrator,
            escrowId,
            false,
            nftUrlB
        );

        escrows[escrowId].nftA = nftId1;
        escrows[escrowId].nftB = nftId2;
        escrows[escrowId].started = true;

        emit FundsDeposited(
            escrowId,
            msg.sender,
            assetToDeposit.currency,
            assetToDeposit.amount,
            nftId1,
            nftId2
        );
    }

    /**
    * @dev Withdraw for owner of partyA NFT only if 24h have passed since bet started and partyB didn't deposit.
    * There are NO NFTs issued at this point
    * @param escrowId The ID to withdraw the funds from.
    */
    function withdrawFunds(uint256 escrowId)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    {
        require(msg.sender == escrows[escrowId].partyA,
            "You are not authorized to withdraw funds from this escrow"
        );
        require(!escrows[escrowId].started, "The bet has already started, you cannot withdraw your funds");
        require(block.timestamp > (escrows[escrowId].createTime + 24 hours), "You cannot withdraw your funds yet");
        if (address(escrowAssetsA[escrowId].currency) != address(0)) {
            escrowAssetsA[escrowId].currency.safeTransfer(
                msg.sender,
                escrowAssetsA[escrowId].amount - escrowAssetsA[escrowId].amount * tagFeeBps / maxFeeBps
            );
        } else { // GAS token
            (bool successA, ) = msg.sender.call{value: escrowAssetsA[escrowId].amount}("");
            require(successA, "Something went wrong with the withdrawing transaction. Gas token");
        }
        escrows[escrowId].closed = true;
        emit FundsWithdrawn(escrowId, msg.sender);
        emit EscrowCancelled(escrowId);
    }

    /**
    * @dev Reclaim funds for a party only if the time is 72 hours after the determine time.
    * @param escrowId The ID to withdraw the funds from.
    */
    function reclaimFunds(uint256 escrowId)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    onlyParticipatingParty(escrowId)
    {
        require(block.timestamp > (escrows[escrowId].determineTime + 72 hours), "You cannot reclaim your funds yet");
        transferFundsToParty(escrowAssetsA[escrowId], NFTContract.ownerOf(escrows[escrowId].nftA), escrowId);
        transferFundsToParty(escrowAssetsB[escrowId], NFTContract.ownerOf(escrows[escrowId].nftB), escrowId);
        escrows[escrowId].closed = true;
        emit FundsReclaimed(escrowId, msg.sender);
    }

    /**
    * @dev Determines the outcome of the Escrow
    * @param escrowId The ID of the Escrow to be determined
    * @param partyAWon If true then distributes the funds to partyA else to partyB (minus fees)
    */
    function determineOutcome(uint256 escrowId, bool partyAWon)
    external
    payable
    nonReentrant
    onlyOpenCase(escrowId)
    onlyCaseArbitrator(escrowId)
    {
        require(block.timestamp >= escrows[escrowId].determineTime, "You cannot make a decision yet");
        require(escrows[escrowId].started, "Escrow has not started");
        require(block.timestamp >= escrows[escrowId].determineTime, "Escrow cannot be determined until determineTime");

        DepositAsset memory assetsA = escrowAssetsA[escrowId];
        DepositAsset memory assetsB = escrowAssetsB[escrowId];

        require(assetsA.amount > 0 && assetsB.amount > 0, "The parties have not completed their fund deposits yet");

        if (partyAWon) {
            transferFundsToParty(assetsA, NFTContract.ownerOf(escrows[escrowId].nftA), escrowId);
            transferFundsToParty(assetsB, NFTContract.ownerOf(escrows[escrowId].nftA), escrowId);
            escrows[escrowId].winner = NFTContract.ownerOf(escrows[escrowId].nftA);
        } else {
            transferFundsToParty(assetsA, NFTContract.ownerOf(escrows[escrowId].nftB), escrowId);
            transferFundsToParty(assetsB, NFTContract.ownerOf(escrows[escrowId].nftB), escrowId);
            escrows[escrowId].winner = NFTContract.ownerOf(escrows[escrowId].nftB);
        }
        collectArbitratorFee(escrowId);
        escrows[escrowId].closed = true;
    }


    /**
    * @dev Sets the address of the NFT contract
    * @param _nftContractAddress The address of the NFT contract address
    */
    function updateNftContractAddress(address _nftContractAddress) external onlyOwner {
        require(_nftContractAddress != address(0));
        NFTContract = ITagNFT(_nftContractAddress);
    }

    /**
    * @dev Changes the address of the treasury
    * @param _treasuryAddress The address of the NFT contract address
    */
    function updateTreasuryAddress(address payable _treasuryAddress) external onlyOwner {
        require(_treasuryAddress != address(0), "Treasury cannot be the 0x address");
        tagFeeVault = _treasuryAddress;
    }

    /**
    * @dev Changes the fee collected by the platform
    * @param newFeeBps new fee
    */
    function changeTagFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 2000, "Cannot set fee larger than 20%");
        tagFeeBps = newFeeBps;
    }

    /**
    * @dev Transfers the right to collect the fee. This checks what side the NFT represents
    * @param escrowId The Escrow selected
    * @param nftTokenId The NFT token
    * @param newOwner The address of the new owner
    */
    function transferRightToCollect(uint256 escrowId, uint256 nftTokenId, address newOwner)
    external
    nftContractOnly
    onlyOpenCase(escrowId)
    {
        addEscrowIdToAddress(escrowId, newOwner);
        address oldOwner;
        EscrowVault memory escrow = escrows[escrowId];

        if (escrow.nftA != 0 && escrow.nftA == nftTokenId) {
            oldOwner = escrows[escrowId].partyA;
            escrows[escrowId].partyA = newOwner;
        } else if (escrow.nftB != 0 && escrow.nftB == nftTokenId) {
            oldOwner = escrows[escrowId].partyA;
            escrows[escrowId].partyB = newOwner;
        }
        uint l = walletEscrows[oldOwner].escrowIds.length;
        uint256[] memory newWalletEscrows = new uint256[](l  - 1);
        uint j = 0;
        for(uint i = 0; i < l; i++) {
            if (walletEscrows[oldOwner].escrowIds[i] != escrowId) {
                newWalletEscrows[j] = walletEscrows[oldOwner].escrowIds[i];
                j += 1;
            }
        }
        walletEscrows[oldOwner] = IdContainer(newWalletEscrows);
    }

    // -- INTERNAL
    /**
    * Sends the funds to the arbitrator for given Escrow
    * @param escrowId The ID of the escrow in question
    */
    function collectArbitratorFee(uint256 escrowId) internal {
        DepositAsset memory assetsA = escrowAssetsA[escrowId];
        DepositAsset memory assetsB = escrowAssetsB[escrowId];
        uint256 arbitratorFeeBps = escrows[escrowId].arbitratorFeeBps;

        if (address(escrowAssetsA[escrowId].currency) != address(0)) {
            assetsA.currency.safeTransfer(msg.sender, assetsA.amount * arbitratorFeeBps / maxFeeBps);
        } else { // GAS token
            (bool successA, ) = msg.sender.call{value: assetsA.amount * arbitratorFeeBps / maxFeeBps}("");
            require(successA, "Something went wrong with collecting the Arbitrator's fee. Gas token");
        }

        if (address(assetsB.currency) != address(0)) {
            assetsB.currency.safeTransfer(msg.sender, assetsB.amount * arbitratorFeeBps / maxFeeBps);
        } else { // GAS token
            (bool successB, ) = msg.sender.call{value: assetsB.amount * arbitratorFeeBps / maxFeeBps}("");
            require(successB, "Something went wrong with collecting the Arbitrator's fee. Gas token");
        }
    }

    function addEscrowIdToAddress(uint256 escrowId, address partyAddress) internal {
        if (walletEscrows[partyAddress].escrowIds.length > 0) {
            walletEscrows[partyAddress].escrowIds.push(escrowId);
        } else {
            uint256[] memory e = new uint256[](1);
            e[0] = escrowId;
            walletEscrows[partyAddress] = IdContainer(e);
        }
    }

    /**
    * @dev Transfer asset to address
    **/
    function transferFundsToParty(DepositAsset memory asset, address winner, uint256 escrowId) internal {
        // ERC20 token
        uint256 arbitratorFeeBps = escrows[escrowId].arbitratorFeeBps;
        uint256 amountMinusFees = asset.amount - asset.amount * arbitratorFeeBps / maxFeeBps - asset.amount * tagFeeBps / maxFeeBps;
        if (address(asset.currency) != address(0)) {
            asset.currency.safeTransfer(winner, amountMinusFees);
        } else { // GAS token
            (bool success, ) = winner.call{value: amountMinusFees}("");
            require(success, "Something went wrong with the transfer to the winner of the escrow. Gas token");
        }
    }

    /**
     * @dev generate a new escrow/escrow id (iterates by 1)
     * @return the generated case id
     */
    function generateEscrowId() internal returns (uint256) {
        return nextEscrowId++;
    }

    // -- VIEWS
    function getEscrowsForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsParticipated)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        escrowsParticipated = new uint256[](length);

        for(uint i = 0; i < length; i++) {
            escrowsParticipated[i] = walletEscrows[_address].escrowIds[i];
        }
    }

    function getEscrowsPendingDepositForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsPending)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        uint nPending = 0;
        for(uint i = 0; i < length; i++) {
            if (
                !escrows[walletEscrows[_address].escrowIds[i]].closed &&
            address(escrowAssetsB[walletEscrows[_address].escrowIds[i]].currency) == address(0)
            ) {
                nPending = nPending + 1;
            }
        }

        escrowsPending = new uint256[](nPending);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            if (
                !escrows[walletEscrows[_address].escrowIds[i]].closed &&
            address(escrowAssetsB[walletEscrows[_address].escrowIds[i]].currency) == address(0)
            ) {
                escrowsPending[j] = walletEscrows[_address].escrowIds[i];
                j = j + 1;
            }
        }
        return escrowsPending;
    }

    function getEscrowsStartedForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsStarted)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        uint nStarted = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].started &&
                !escrows[walletEscrows[_address].escrowIds[i]].closed
            ) {
                nStarted = nStarted + 1;
            }
        }

        escrowsStarted = new uint256[](nStarted);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].started &&
                !escrows[walletEscrows[_address].escrowIds[i]].closed
            ) {
                escrowsStarted[j] = walletEscrows[_address].escrowIds[i];
                j = j + 1;
            }
        }
        return escrowsStarted;
    }

    function getEscrowsResolvedForAddress(address _address)
    public
    view
    returns
    (uint256[] memory escrowsResolved)
    {
        uint length = walletEscrows[_address].escrowIds.length;
        uint nClosed = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].closed &&
                escrows[walletEscrows[_address].escrowIds[i]].winner != address(0)
            ) {
                nClosed = nClosed + 1;
            }
        }

        escrowsResolved = new uint256[](nClosed);
        uint j = 0;
        for(uint i = 0; i < length; i++) {
            if (
                escrows[walletEscrows[_address].escrowIds[i]].closed &&
                escrows[walletEscrows[_address].escrowIds[i]].winner != address(0)
            ) {
                escrowsResolved[j] = walletEscrows[_address].escrowIds[i];
                j = j + 1;
            }
        }
        return escrowsResolved;
    }
}