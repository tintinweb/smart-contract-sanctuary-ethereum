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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {D3Liquidation} from "contracts/DODOV3MM/pool/D3Liquidation.sol";
import {D3Funding, Types, Errors} from "contracts/DODOV3MM/pool/D3Funding.sol";
import {D3Trading} from "contracts/DODOV3MM/pool/D3Trading.sol";
import {D3Maker} from "contracts/DODOV3MM/rangeOrder/Maker.sol";

contract D3MM is D3Funding, D3Liquidation, D3Trading, D3Maker {
    /// @notice init D3MM pool
    /// @param creator the pool creator address
    /// @param factory the D3MMFactory contract address
    /// @param oracle the oracle address
    /// @param epochStartTime the epoch start timestamp
    /// @param epochDuration the epoch duration
    /// @param tokens token list
    /// @param d3Tokens token list's corresponding d3Token list
    /// @param mixData other initialization data, including IM, MM, maintainer address, feeModel contract address
    function init(
        address creator,
        address factory,
        address oracle,
        uint256 epochStartTime,
        uint256 epochDuration,
        address[] calldata tokens,
        address[] calldata d3Tokens,
        bytes calldata mixData     
    ) external {
        require(epochDuration >= 1 days && epochDuration <= 30 days, Errors.WRONG_EPOCH_DURATION);
        require(tokens.length == d3Tokens.length, Errors.ARRAY_NOT_MATCH);
        initOwner(creator);
        state._CREATOR_ = creator;
        state._D3_FACTORY_ = factory;
        state._ORACLE_ = oracle;
        state.tokenList = tokens;
        state._EPOCH_START_TIME_ = epochStartTime;
        state._EPOCH_DURATION_ = epochDuration;
        (
            state._INITIAL_MARGIN_RATIO_, 
            state._MAINTENANCE_MARGIN_RATIO_, 
            state._MAINTAINER_, 
            state._MT_FEE_RATE_MODEL_
        ) = abi.decode(mixData, (uint256, uint256, address, address)); // IM, MM, maintainer,feeModel
        require(state._MAINTENANCE_MARGIN_RATIO_ < Types.ONE && state._MAINTENANCE_MARGIN_RATIO_ > 0, Errors.WRONG_MM_RATIO);
        require(state._INITIAL_MARGIN_RATIO_ < Types.ONE && state._INITIAL_MARGIN_RATIO_ > state._MAINTENANCE_MARGIN_RATIO_, Errors.WRONG_IM_RATIO);
        for (uint256 i; i < tokens.length; i++) {
            state.assetInfo[tokens[i]].d3Token = d3Tokens[i];
            state.assetInfo[tokens[i]].accruedInterest = Types.ONE;
        }
    }

    // ============= View =================
    /// @notice return the pool creator address
    /// @dev we can use creator as key to query pools from D3MMFactory's pool registry
    function getCreator() external view returns (address) {
        return state._CREATOR_;
    }

    /// @notice get basic pool info
    function getD3MMInfo()
        external
        view
        returns (
            address creator,
            address oracle,
            uint256 epochStartTime,
            uint256 epochDuration,
            uint256 IM,
            uint256 MM
        )
    {
        creator = state._CREATOR_;
        oracle = state._ORACLE_;
        epochStartTime = state._EPOCH_START_TIME_;
        epochDuration = state._EPOCH_DURATION_;
        IM = state._INITIAL_MARGIN_RATIO_;
        MM = state._MAINTENANCE_MARGIN_RATIO_;
    }

    /// @notice get a token's reserve in pool
    function getTokenReserve(address token) external view returns (uint256) {
        return state.assetInfo[token].reserve;
    }

    /// @notice get pool status
    function getStatus() external view returns (Types.PoolStatus) {
        return state._POOL_STATUS_;
    }

    /// @notice get liquidation target for a token
    function getLiquidationTarget(address token) external view returns (uint256) {
        return state.liquidationTarget[token];
    }

    /// @notice get all pending withdraw requests
    function getPendingWithdrawList() external view returns (Types.WithdrawInfo[] memory) {
        return state.pendingWithdrawList;
    }

    /// @notice get asset info
    function getAssetInfo(address token) external view returns (Types.AssetInfo memory) {
        return state.assetInfo[token];
    }

    /// @notice get withdrawl info at specific index
    function getWithdrawInfo(uint256 index) external view returns (Types.WithdrawInfo memory) {
        return state.pendingWithdrawList[index];
    }

    /// @notice get UserQuota contract address
    function getUserQuota() external view returns (address) {
        return state._USER_QUOTA_;
    }

    /// @notice get a list of tokens in pool
    function getTokenList() external view returns (address[] memory) {
        return state.tokenList;
    }

    /// @notice get interest rate for token
    function getInterestRate(address token) external view returns (uint256) {
        return state.interestRate[token];
    }

    /// @notice get next epoch start time and interest rate
    /// @param token the token we want to query for next interest rate
    function getNextEpoch(address token) external view returns (uint256 timestamp, uint256 interestRate) {
        timestamp = state.nextEpoch.timestamp;
        interestRate = state.nextEpoch.interestRate[token];
    }

    /// @notice get the owner left balance after pool closed
    /// @param token the token we want to query
    function getOwnerLeftBalance(address token) external view returns (uint256) {
        return state.ownerBalanceAfterPoolEnd[token];
    }
    
    /// @notice get D3MM contract version
    function version() virtual external pure returns (string memory) {
        return "D3MM 1.0.0";
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.16;

import "./lib/Types.sol";
import "./lib/Errors.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/lib/InitializableOwnable.sol";

contract D3Storage is ReentrancyGuard, InitializableOwnable {
    Types.D3MMState internal state;

    // ============= Events ==========
    event SetUserQuota(address indexed userQuota);
    event SetMaxDeposit(address indexed token, uint256 amount);
    event LpDeposit(address indexed lp, address indexed token, uint256 amount);
    event OwnerDeposit(address indexed token, uint256 amount);
    event OwnerWithdraw(address indexed to, address indexed token, uint256 amount);

    // sellOrNot = 0 means sell, 1 means buy.
    event Swap(
        address to,
        address fromToken,
        address toToken,
        uint256 payFromAmount,
        uint256 receiveToAmount,
        uint256 sellOrNot
    );
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/DODOV3MM/lib/Types.sol";
import "contracts/DODOV3MM/lib/Errors.sol";
import "contracts/intf/ID3Token.sol";
import "contracts/intf/ID3Oracle.sol";
import "contracts/intf/ID3Factory.sol";
import "contracts/intf/IUserQuotaV3.sol";
import "contracts/lib/DecimalMath.sol";

/**
 * @author  DODO
 * @title   D3Common
 * @dev     This contract contains common code for D3MM.
 */
 
library D3Common {

    /// @notice update accrued interests
    /// @param state pool state
    function accrueInterests(Types.D3MMState storage state) internal {
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp == state.accrualTimestamp) {
            return;
        }

        uint256 timeDelta = currentTimestamp - state.accrualTimestamp;
        for (uint256 i = 0; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            uint256 interestRate = state.interestRate[token];
            if (interestRate > 0) {
                state.assetInfo[token].accruedInterest = DecimalMath.mul(
                    state.assetInfo[token].accruedInterest, 
                    timeDelta * interestRate / Types.SECONDS_PER_YEAR + Types.ONE
                );
            }
        }

        state.accrualTimestamp = currentTimestamp;
    }

    /// @notice Return the total USD value of the tokens in pool
    /// @param state pool state
    /// @return totalValue the total asset value in USD
    function getTotalAssetsValue(Types.D3MMState storage state) internal view returns (uint256 totalValue) {
        for (uint8 i = 0; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            uint256 price = ID3Oracle(state._ORACLE_).getPrice(token);
            totalValue += DecimalMath.mul(
                IERC20(token).balanceOf(address(this)),
                price
            );
        }
    }

    /// @notice Return the total USD value of the debts
    /// @param state pool state
    /// @return totalDebt the total debt value in USD
    function getTotalDebtValue(Types.D3MMState storage state) internal view returns (uint256 totalDebt) {
        uint256 timeDelta = block.timestamp - state.accrualTimestamp;
        for (uint8 i = 0; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            uint256 interestRate = state.interestRate[token];
            totalDebt += DecimalMath.mul(
                DecimalMath.mul(
                    ID3Token(state.assetInfo[token].d3Token).totalSupply(),
                    state.assetInfo[token].accruedInterest +
                        (timeDelta * interestRate) /
                        Types.SECONDS_PER_YEAR
                ),
                ID3Oracle(state._ORACLE_).getPrice(token)
            );
        }
    }

    /// @notice Return the collateral ratio
    /// @dev if totalAsset >= totalDebt, collateral ratio = (totalAsset - totalDebt) / totalAsset
    /// @dev if totalAsset < totalDebt, collateral ratio = 0
    /// @param state pool state
    /// @return collateralRatio the current collateral ratio
    function getCollateralRatio(Types.D3MMState storage state)
        internal
        view
        returns (uint256 collateralRatio)
    {
        uint256 totalValue;
        uint256 totalDebt;
        uint256 timeDelta = block.timestamp - state.accrualTimestamp;
        for (uint8 i = 0; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            uint256 interestRate = state.interestRate[token];
            uint256 price = ID3Oracle(state._ORACLE_).getPrice(token);
            totalValue += DecimalMath.mul(
                IERC20(token).balanceOf(address(this)),
                price
            );
            totalDebt += DecimalMath.mul(
                DecimalMath.mul(
                    ID3Token(state.assetInfo[token].d3Token).totalSupply(),
                    state.assetInfo[token].accruedInterest +
                        (timeDelta * interestRate) /
                        Types.SECONDS_PER_YEAR
                ),
                price
            );
        }
        if (totalValue <= totalDebt) {
            collateralRatio = 0;
        } else {
            collateralRatio =
                Types.ONE -
                DecimalMath.div(totalDebt, totalValue);
        }
    }

    /// @notice update token reserve
    /// @param token the token address
    /// @param state pool state
    function updateReserve(address token, Types.D3MMState storage state)
        internal
        returns (uint256 balance)
    {
        balance = IERC20(token).balanceOf(address(this));
        state.assetInfo[token].reserve = balance;
    }

    /// @notice Return current epoch number
    /// @param state pool state
    /// @return epoch the current epoch number
    function currentEpoch(Types.D3MMState storage state)
        internal
        view
        returns (uint256 epoch)
    {
        epoch =
            (block.timestamp - state._EPOCH_START_TIME_) /
            state._EPOCH_DURATION_;
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

library Errors {
    string public constant NOT_ALLOWED_LIQUIDATOR = "D3MM_NOT_ALLOWED_LIQUIDATOR";
    string public constant NOT_ALLOWED_ROUTER = "D3MM_NOT_ALLOWED_ROUTER";
    string public constant POOL_NOT_ONGOING = "D3MM_POOL_NOT_ONGOING";
    string public constant POOL_NOT_LIQUIDATING = "D3MM_POOL_NOT_LIQUIDATING";
    string public constant POOL_NOT_END = "D3MM_POOL_NOT_END";
    string public constant TOKEN_NOT_EXIST = "D3MM_TOKEN_NOT_EXIST";
    string public constant TOKEN_ALREADY_EXIST = "D3MM_TOKEN_ALREADY_EXIST";
    string public constant EXCEED_DEPOSIT_LIMIT = "D3MM_EXCEED_DEPOSIT_LIMIT";
    string public constant EXCEED_QUOTA = "D3MM_EXCEED_QUOTA";
    string public constant BELOW_IM_RATIO = "D3MM_BELOW_IM_RATIO";
    string public constant TOKEN_NOT_ON_WHITELIST = "D3MM_TOKEN_NOT_ON_WHITELIST";
    string public constant LATE_TO_CHANGE_EPOCH = "D3MM_LATE_TO_CHANGE_EPOCH";
    string public constant POOL_ALREADY_CLOSED = "D3MM_POOL_ALREADY_CLOSED";
    string public constant BALANCE_NOT_ENOUGH = "D3MM_BALANCE_NOT_ENOUGH";
    string public constant TOKEN_IS_OFFLIST = "D3MM_TOKEN_IS_OFFLIST";
    string public constant ABOVE_MM_RATIO = "D3MM_ABOVE_MM_RATIO";
    string public constant WRONG_MM_RATIO = "D3MM_WRONG_MM_RATIO";
    string public constant WRONG_IM_RATIO = "D3MM_WRONG_IM_RATIO";
    string public constant NOT_IN_LIQUIDATING = "D3MM_NOT_IN_LIQUIDATING";
    string public constant NOT_PASS_DEADLINE = "D3MM_NOT_PASS_DEADLINE";
    string public constant DISCOUNT_EXCEED_5 = "D3MM_DISCOUNT_EXCEED_5";
    string public constant MINRES_NOT_ENOUGH = "D3MM_MINRESERVE_NOT_ENOUGH";
    string public constant MAXPAY_NOT_ENOUGH = "D3MM_MAXPAYAMOUNT_NOT_ENOUGH";
    string public constant LIQUIDATION_NOT_DONE = "D3MM_LIQUIDATION_NOT_DONE";
    string public constant ROUTE_FAILED = "D3MM_ROUTE_FAILED";
    string public constant TOKEN_NOT_MATCH = "D3MM_TOKEN_NOT_MATCH";
    string public constant ASK_AMOUNT_EXCEED = "D3MM_ASK_AMOUTN_EXCEED";
    string public constant K_LIMIT = "D3MM_K_LIMIT_ERROR";
    string public constant ARRAY_NOT_MATCH = "D3MM_ARRAY_NOT_MATCH";
    string public constant WRONG_EPOCH_DURATION = "D3MM_WRONG_EPOCH_DURATION";
    string public constant WRONG_EXCUTE_EPOCH_UPDATE_TIME = "D3MM_WRONG_EXCUTE_EPOCH_UPDATE_TIME";
    string public constant INVALID_EPOCH_STARTTIME = "D3MM_INVALID_EPOCH_STARTTIME";
    string public constant PRICE_UP_BELOW_PRICE_DOWN = "D3MM_PRICE_UP_BELOW_PRICE_DOWN";
    string public constant AMOUNT_TOO_SMALL = "D3MM_AMOUNT_TOO_SMALL";
    string public constant FROMAMOUNT_NOT_ENOUGH = "D3MM_FROMAMOUNT_NOT_ENOUGH";
    string public constant HEARTBEAT_CHECK_FAIL = "D3MM_HEARTBEAT_CHECK_FAIL";
    
    string public constant RO_ORACLE_PROTECTION = "PMMRO_ORACLE_PRICE_PROTECTION";
    string public constant RO_VAULT_RESERVE = "PMMRO_VAULT_RESERVE_NOT_ENOUGH";
    string public constant RO_AMOUNT_ZERO = "PMMRO_AMOUNT_ZERO";
    string public constant RO_PRICE_ZERO = "PMMRO_PRICE_ZERO";
    
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/DODOV3MM/lib/Types.sol";
import "contracts/DODOV3MM/lib/Errors.sol";
import "contracts/intf/ID3Token.sol";
import "contracts/intf/ID3Oracle.sol";
import "contracts/intf/ID3Factory.sol";
import "contracts/intf/IUserQuotaV3.sol";
import "contracts/lib/DecimalMath.sol";
import "./D3Common.sol";

/**
 * @author  DODO
 * @title   FundingLibrary
 * @dev     This contract contains the real code implementations for D3Funding.
 */
 
library FundingLibrary {
    using SafeERC20 for IERC20;

    event AddNewToken(address indexed token, uint256 interestRate, uint256 maxDepositAmount);
    event SetNextEpoch(uint256 indexed nextEpochStart, address[] tokenList, uint256[] interestRates);
    event ExecuteEpochUpdate();
    event LpDeposit(address indexed lp, address indexed token, uint256 amount);
    event LpRequestWithdrawal(bytes32 indexed requestId, address indexed lp, address indexed token, uint256 d3TokenAmount);
    event RefundWithdrawal(bytes32 indexed requestId, address indexed lp, address indexed token, uint256 amount);
    event Refund(address indexed lp, address indexed token, uint256 amount);
    event OwnerWithdraw(address indexed to, address indexed token, uint256 amount);
    event OwnerClosePool();

    // --------- LP Functions ---------

    /// @notice When LPs deposit token, they will receive the corresponding d3Token. 
    /// @param lp the LP account address
    /// @param token the token address
    /// @param state pool state
    function lpDeposit(
        address lp,
        address token,
        Types.D3MMState storage state
    ) external {
        D3Common.accrueInterests(state);
        Types.AssetInfo storage info = state.assetInfo[token];

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 amount = balance - info.reserve;
        D3Common.updateReserve(token, state);

        uint256 d3TokenAmount = DecimalMath.div(
            amount,
            info.accruedInterest
        );
        ID3Token(info.d3Token).mint(lp, d3TokenAmount);

        if (state._USER_QUOTA_ != address(0)) {
            uint256 quota = IUserQuotaV3(state._USER_QUOTA_).getUserQuota(
                lp,
                token
            );
            uint256 lpBalance = DecimalMath.mul(
                ID3Token(info.d3Token).balanceOf(lp),
                info.accruedInterest
            );
            require(lpBalance <= quota, Errors.EXCEED_QUOTA);
        }

        uint256 totalDeposit = DecimalMath.mul(
            ID3Token(info.d3Token).totalSupply(),
            info.accruedInterest
        );
        require(
            totalDeposit <= info.maxDepositAmount,
            Errors.EXCEED_DEPOSIT_LIMIT
        );

        require(
            D3Common.getCollateralRatio(state) >= state._INITIAL_MARGIN_RATIO_,
            Errors.BELOW_IM_RATIO
        );
        emit LpDeposit(lp, token, amount);
    }

    /// @notice LP can submit a withdraw request by locking some amount of the corresponding dToken.
    /// @dev The locked d3Token will still generate interest during withdraw pending time.
    /// @param token the token LP wants to withdraw
    /// @param d3TokenAmount the amount of d3Token going to lock
    /// @param state pool state
    function lpRequestWithdraw(
        address lp,
        address token,
        uint256 d3TokenAmount,
        Types.D3MMState storage state
    ) external {
        Types.AssetInfo storage info = state.assetInfo[token];
        ID3Token d3Token = ID3Token(info.d3Token);
        uint256 withdrawable = d3Token.balanceOf(lp) - d3Token.lockedOf(lp);
        require(withdrawable >= d3TokenAmount, Errors.BALANCE_NOT_ENOUGH);
        bytes32 requestId = keccak256(abi.encode(lp, block.timestamp + state._EPOCH_DURATION_));
        state.pendingWithdrawList.push(
            Types.WithdrawInfo(
                requestId,
                block.timestamp + state._EPOCH_DURATION_,
                lp,
                token,
                d3TokenAmount
            )
        );
        d3Token.lock(lp, d3TokenAmount);
        emit LpRequestWithdrawal(requestId, lp, token, d3TokenAmount);
    }

    /// @notice LPs can withdraw their tokens after pool is closed, either by liquidation or pool owner.
    /// @notice LPs can get their tokens back immediately, whether or not they have pending withdraw request before pool closed.
    /// @notice If pool is closed by liquidation, under some extreme conditions, the total pool assets value might be less than total debts, 
    /// @notice which means LP will suffer a loss. The returned token amount might be less than the deposit amount.
    /// @dev After pool closed, all tokens' interest rates are set to 0, and will no longer call `function accrueInterests()` to accrue interests.
    /// @param token the token requested to withdraw
    /// @param state pool state
    function lpWithdrawAfterPoolEnd(
        address lp,
        address token,
        Types.D3MMState storage state
    ) external {
        Types.AssetInfo storage assetInfo = state.assetInfo[token];
        uint256 d3Balance = ID3Token(assetInfo.d3Token).balanceOf(lp);
        uint256 originBalance = DecimalMath.mul(
            d3Balance,
            assetInfo.accruedInterest
        );
        ID3Token(assetInfo.d3Token).burn(lp, d3Balance);
        IERC20(token).safeTransfer(lp, originBalance);
        emit Refund(lp, token, originBalance);
    }

    // --------- Owner Functions ---------

    /// @notice Owner add a new token
    /// @param token the token address
    /// @param interestRate the token interestRate
    /// @param maxDepositAmount the max deposit amount for the token
    /// @param state pool state
    function addNewToken(
        address token,
        uint256 interestRate,
        uint256 maxDepositAmount,
        Types.D3MMState storage state
    ) external {
        require(
            ID3Oracle(state._ORACLE_).isFeasible(token),
            Errors.TOKEN_NOT_ON_WHITELIST
        );
        address d3Token = ID3Factory(state._D3_FACTORY_).createDToken(
            token,
            address(this)
        );
        state.assetInfo[token].d3Token = d3Token;
        state.assetInfo[token].accruedInterest = Types.ONE; // the base accrued interest is 1
        state.assetInfo[token].maxDepositAmount = maxDepositAmount;

        D3Common.accrueInterests(state);
        state.interestRate[token] = interestRate;
        state.nextEpoch.interestRate[token] = interestRate;

        state.tokenList.push(token);
        emit AddNewToken(token, interestRate, maxDepositAmount);
    }

    /// @notice Pool owner set the interest rates for next epoch. The time to next epoch must be larger than half epoch duration.
    /// @param tokenList Tokens to be set.
    /// @param interestRates The interest rates correspond to the token list.
    /// @param state Pool state.
    function setNextEpoch(
        address[] calldata tokenList,
        uint256[] calldata interestRates,
        Types.D3MMState storage state
    ) external {
        uint256 epoch = D3Common.currentEpoch(state);
        uint256 nextEpochStart = state._EPOCH_START_TIME_ +
            state._EPOCH_DURATION_ *
            (epoch + 1);
        require(
            nextEpochStart - block.timestamp > (state._EPOCH_DURATION_ / 2),
            Errors.LATE_TO_CHANGE_EPOCH
        ); // to set next epoch, the time to next epoch must be larger than half epoch duration  
        state.nextEpoch.timestamp = nextEpochStart;
        for (uint8 i = 0; i < tokenList.length; i++) {
            state.nextEpoch.interestRate[tokenList[i]] = interestRates[i];
        }
        emit SetNextEpoch(nextEpochStart, tokenList, interestRates);
    }
    
    /// @notice Apply new interest rates setting.
    /// @param state  Pool state.
    function executeEpochUpdate(Types.D3MMState storage state) external {
        require(
            block.timestamp >= state.nextEpoch.timestamp &&
                state.nextEpoch.timestamp != 0,
            Errors.WRONG_EXCUTE_EPOCH_UPDATE_TIME
        );
        D3Common.accrueInterests(state);

        for (uint8 i = 0; i < state.tokenList.length; i++) {
            state.interestRate[state.tokenList[i]] = state
                .nextEpoch
                .interestRate[state.tokenList[i]];
        }
        emit ExecuteEpochUpdate();
    }

    /// @notice Owner refund LP. The LP must have submit a withdraw request before.
    /// @param index the index of the withdraw request in the pending request list
    /// @param state pool state
    function refund(uint256 index, Types.D3MMState storage state) external {
        D3Common.accrueInterests(state);
        Types.WithdrawInfo storage withdrawInfo = state.pendingWithdrawList[
            index
        ];
        Types.AssetInfo storage assetInfo = state.assetInfo[withdrawInfo.token];
        uint256 originTokenAmount = DecimalMath.mul(
            withdrawInfo.d3TokenAmount,
            assetInfo.accruedInterest
        );

        ID3Token(assetInfo.d3Token).unlock(
            withdrawInfo.user,
            withdrawInfo.d3TokenAmount
        );
        ID3Token(assetInfo.d3Token).burn(
            withdrawInfo.user,
            withdrawInfo.d3TokenAmount
        );
        IERC20(withdrawInfo.token).safeTransfer(
            withdrawInfo.user,
            originTokenAmount
        );
        D3Common.updateReserve(withdrawInfo.token, state);

        // replace with last withdraw request
        state.pendingWithdrawList[index] = state.pendingWithdrawList[
            state.pendingWithdrawList.length - 1
        ];
        state.pendingWithdrawList.pop();
        emit RefundWithdrawal(withdrawInfo.requestId, withdrawInfo.user, withdrawInfo.token, originTokenAmount);
    }

    /// @notice Owner withdraw token from pool.
    /// @param to  Asset receiver.
    /// @param token  Token to withdraw.
    /// @param amount  Amount to Withdraw.
    /// @param state  Pool state.
    function ownerWithdraw(
        address to,
        address token,
        uint256 amount,
        Types.D3MMState storage state
    ) external {
        IERC20(token).safeTransfer(to, amount);
        D3Common.updateReserve(token, state);
        uint256 ratio = D3Common.getCollateralRatio(state);
        require(ratio >= state._INITIAL_MARGIN_RATIO_, Errors.BELOW_IM_RATIO);
        emit OwnerWithdraw(to, token, amount);
    }

    /// @notice Owner withdraw token when pool is end(closed).
    /// @param to Asset receiver.
    /// @param token Token to withdraw.
    /// @param amount Amount to Withdraw.
    /// @param state Pool state.
    function ownerWithdrawAfterPoolEnd(
        address to,
        address token,
        uint256 amount,
        Types.D3MMState storage state
    ) external {
        uint256 balance = state.ownerBalanceAfterPoolEnd[token];
        require(balance >= amount, Errors.BALANCE_NOT_ENOUGH);
        state.ownerBalanceAfterPoolEnd[token] -= amount;
        IERC20(token).safeTransfer(to, amount);
        emit OwnerWithdraw(to, token, amount);
    }

    /// @notice Owner closes pool.
    /// @param state Pool state.
    function ownerClosePool(Types.D3MMState storage state) external {
        D3Common.accrueInterests(state);
        for (uint256 i; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            Types.AssetInfo storage info = state.assetInfo[token];
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 d3TokenSupply = IERC20(info.d3Token).totalSupply();
            uint256 debtAmount = DecimalMath.mul(
                d3TokenSupply,
                info.accruedInterest
            );
            require(balance >= debtAmount, Errors.BALANCE_NOT_ENOUGH);
            state.ownerBalanceAfterPoolEnd[token] = balance - debtAmount;
            state.interestRate[token] = 0;
            info.maxDepositAmount = 0;
        }
        state._POOL_STATUS_ = Types.PoolStatus.End;
        emit OwnerClosePool();
    }

    // ---------- Pool Status ----------

    /// @notice Return the total USD value of the tokens in pool
    /// @param state pool state
    /// @return totalValue the total asset value in USD
    function getTotalAssetsValue(Types.D3MMState storage state) public view returns (uint256 totalValue) {
        return D3Common.getTotalAssetsValue(state);
    }

    /// @notice Return the total USD value of the debts
    /// @param state pool state
    /// @return totalDebt the total debt value in USD
    function getTotalDebtValue(Types.D3MMState storage state) public view returns (uint256 totalDebt) {
        return D3Common.getTotalDebtValue(state);
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/DODOV3MM/lib/Types.sol";
import "contracts/DODOV3MM/lib/Errors.sol";
import "contracts/intf/ID3Token.sol";
import "contracts/intf/ID3Oracle.sol";
import "contracts/intf/ID3Factory.sol";
import "contracts/intf/IUserQuotaV3.sol";
import "contracts/lib/DecimalMath.sol";
import "./D3Common.sol";

/**
 * @author  DODO
 * @title   LiquidationLibrary
 * @dev     This contract contains the real code implementations for D3Liquidation.
 */
 
library LiquidationLibrary {
    using SafeERC20 for IERC20;

    event StartLiquidation();
    event FinishLiquidation();
    event RefundWithdrawal(bytes32 indexed requestId, address indexed lp, address indexed token, uint256 amount);

    /// @notice If collateral ratio is less than MM, liquiator can trigger liquidation
    /// @param state pool state
    function startLiquidation(Types.D3MMState storage state) external {
        uint256 collateralRatio = D3Common.getCollateralRatio(state);
        require(
            collateralRatio < state._MAINTENANCE_MARGIN_RATIO_,
            Errors.ABOVE_MM_RATIO
        );
        D3Common.accrueInterests(state); // accrue interests for the last time
        state._POOL_STATUS_ = Types.PoolStatus.Liquidating;

        uint256 ratio;
        if (collateralRatio == 0) {
            uint256 totalValue = D3Common.getTotalAssetsValue(state);
            uint256 totalDebt = D3Common.getTotalDebtValue(state);
            ratio = DecimalMath.div(totalValue, totalDebt);
        } else {
            ratio = Types.ONE;
        }

        for (uint256 i; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            uint256 debt = DecimalMath.mul(
                DecimalMath.mul(
                    IERC20(state.assetInfo[token].d3Token).totalSupply(),
                    state.assetInfo[token].accruedInterest
                ),
                ratio
            );
            state.liquidationTarget[token] = debt; // record the token amount we would like to achieve after liquidation
            state.interestRate[token] = 0;
            state.assetInfo[token].maxDepositAmount = 0;
        }
        emit StartLiquidation();
    }
    
    /// @notice Liquidator pass in route data to swap tokens for liquidation.
    /// @param order the swap infomation
    /// @param routeData the swap route data
    /// @param router the route contract which will swap tokens
    /// @param state pool state
    function liquidate(
        Types.LiquidationOrder calldata order,
        bytes calldata routeData,
        address router,
        Types.D3MMState storage state
    ) external {
        uint256 toTokenReserve = IERC20(order.toToken).balanceOf(address(this));
        uint256 fromTokenValue = DecimalMath.mul(
            ID3Oracle(state._ORACLE_).getPrice(order.fromToken),
            order.fromAmount
        );

        // swap using Route
        {
            IERC20(order.fromToken).transfer(router, order.fromAmount);
            (bool success, ) = router.call(routeData);
            require(success, Errors.ROUTE_FAILED);
        }

        // the transferred-in toToken USD value should not be less than 95% of the transferred-out fromToken
        uint256 receivedToToken = IERC20(order.toToken).balanceOf(
            address(this)
        ) - toTokenReserve;
        uint256 toTokenValue = DecimalMath.mul(
            ID3Oracle(state._ORACLE_).getPrice(order.toToken),
            receivedToToken
        );

        require(
            toTokenValue * 100 >= fromTokenValue * 95,
            Errors.DISCOUNT_EXCEED_5
        );
    }

    /// @notice Liquidator call this function to finish liquidation
    /// @dev The goal is to make all tokens' balance be larger than target amount, 
    /// @dev or all tokens' balance be smaller than target amount
    /// @param state pool state
    function finishLiquidation(Types.D3MMState storage state) external {
        bool hasPositiveBalance;
        bool hasNegativeBalance;
        for (uint256 i; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            uint256 debt = state.liquidationTarget[token];
            int256 difference = int256(balance) - int256(debt);
            if (difference > 0) {
                require(!hasNegativeBalance, Errors.LIQUIDATION_NOT_DONE);
                hasPositiveBalance = true;
                // if balance is larger than target amount, the extra amount is credited to owner
                state.ownerBalanceAfterPoolEnd[token] = uint256(difference);
            } else if (difference < 0) {
                require(!hasPositiveBalance, Errors.LIQUIDATION_NOT_DONE);
                hasNegativeBalance = true;
                debt = balance; // if balance is less than target amount, just repay with balance
            }
            uint256 dSupply = IERC20(state.assetInfo[token].d3Token)
                .totalSupply();
            if (dSupply == 0) { continue; }
            uint256 ratio = DecimalMath.div(debt, dSupply); // calculate new d3Token redeem rate
            state.assetInfo[token].accruedInterest = ratio;
        }

        state._POOL_STATUS_ = Types.PoolStatus.End; // mark pool as closed, LPs can withdraw tokens now
        emit FinishLiquidation();
    }

    /// @notice If owner hasn't refund LP after deadline, liquidator can call this to force refund.
    /// @param index the withdraw request's index in pending request list
    /// @param order the swap infomation
    /// @param routeData the swap route data
    /// @param router the route contract which will swap tokens
    /// @param state pool state
    function forceRefund(
        uint256 index,
        Types.LiquidationOrder calldata order,
        bytes calldata routeData,
        address router,
        Types.D3MMState storage state
    ) external {
        Types.WithdrawInfo storage wInfo = state.pendingWithdrawList[index];
        Types.AssetInfo storage assetInfo = state.assetInfo[wInfo.token];

        require(wInfo.deadline < block.timestamp, Errors.NOT_PASS_DEADLINE);
        require(wInfo.token == order.toToken, Errors.TOKEN_NOT_MATCH);

        D3Common.accrueInterests(state);

        uint256 toTokenReserve = IERC20(order.toToken).balanceOf(address(this));
        uint256 originTokenAmount = DecimalMath.mul(
            wInfo.d3TokenAmount,
            assetInfo.accruedInterest
        );

        // if current reserve is less than the withdrawal amount, need swap other token to get more target token
        if (toTokenReserve < originTokenAmount) {
            uint256 fromTokenValue = DecimalMath.mul(
                ID3Oracle(state._ORACLE_).getPrice(order.fromToken),
                order.fromAmount
            );

            IERC20(order.fromToken).transfer(router, order.fromAmount);
            (bool success, ) = router.call(routeData);
            require(success, Errors.ROUTE_FAILED);

            // the transferred-in toToken USD value should not be less than 95% of the transferred-out fromToken
            uint256 toTokenBalance = IERC20(order.toToken).balanceOf(
                address(this)
            );
            uint256 toTokenValue = DecimalMath.mul(
                ID3Oracle(state._ORACLE_).getPrice(order.toToken),
                toTokenBalance - toTokenReserve
            );
            require(
                toTokenValue * 100 >= fromTokenValue * 95,
                Errors.DISCOUNT_EXCEED_5
            );
            toTokenReserve = toTokenBalance;
        }

        // force refund could be called multiple times, if swap result still cannot fulfill the withdraw amount
        uint256 refundAmount = originTokenAmount;
        uint256 d3RefundAmount = wInfo.d3TokenAmount;
        if (toTokenReserve < originTokenAmount) {
            refundAmount = toTokenReserve;
            d3RefundAmount = DecimalMath.div(
                refundAmount,
                assetInfo.accruedInterest
            );
        }

        ID3Token(assetInfo.d3Token).unlock(wInfo.user, d3RefundAmount);
        ID3Token(assetInfo.d3Token).burn(wInfo.user, d3RefundAmount);
        IERC20(wInfo.token).safeTransfer(wInfo.user, refundAmount);
        wInfo.d3TokenAmount -= d3RefundAmount;
        D3Common.updateReserve(wInfo.token, state);

        // if all withdrawal amount has been paid, this request can be removed
        // moving the last request to this index
        if (wInfo.d3TokenAmount == 0) {
            state.pendingWithdrawList[index] = state.pendingWithdrawList[
                state.pendingWithdrawList.length - 1
            ];
            state.pendingWithdrawList.pop();
        }

        emit RefundWithdrawal(wInfo.requestId, wInfo.user, wInfo.token, refundAmount);
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import { DecimalMath } from "../../lib/DecimalMath.sol";
import { DODOMath } from "../../lib/DODOMath.sol";

/**
 * @title PMMPricing
 * @author DODO Breeder
 *
 * @notice DODO Pricing model
 */
library PMMPricing {

    struct PMMState {
        uint256 i;
        uint256 K;
        uint256 B;
        uint256 B0;
        uint256 BMaxAmount;
    }

    function _queryBuyBaseToken(PMMState memory state, uint256 amount)
        internal
        pure
        returns (uint256 payQuote)
    {
        payQuote = _RAboveBuyBaseToken(state, amount, state.B, state.B0);
    }

    function _querySellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (uint256 receiveBaseAmount)
    {
        receiveBaseAmount = _RAboveSellQuoteToken(state, payQuoteAmount);
    }


    // ============ R > 1 cases ============

    function _RAboveBuyBaseToken(
        PMMState memory state,
        uint256 amount,
        uint256 baseBalance,
        uint256 targetBaseAmount
    ) internal pure returns (uint256 payQuoteToken) {
        require(amount < baseBalance, "DODOstate.BNOT_ENOUGH");
        uint256 B2 = baseBalance - amount;
        return 
            DODOMath._GeneralIntegrate(
                targetBaseAmount, 
                baseBalance, 
                B2, 
                state.i, 
                state.K
            );
    }

    function _RAboveSellQuoteToken(PMMState memory state, uint256 payQuoteAmount)
        internal
        pure
        returns (
            uint256 receiveBaseToken
        )
    {
        return
            DODOMath._SolveQuadraticFunctionForTrade(
                state.B0,
                state.B,
                payQuoteAmount,
                DecimalMath.reciprocalFloor(state.i),
                state.K
            );
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

library Types {
    struct D3MMState {
        // tokens in the pool
        address[] tokenList;
        // token => AssetInfo, including dToken, reserve, max deposit, accrued interest
        mapping(address => AssetInfo) assetInfo;
        // token => interest rate
        mapping(address => uint256) interestRate;
        // token => liquidation target amount
        mapping(address => uint256) liquidationTarget;
        // token => amount, how many token can owner withdraw after pool end
        mapping(address => uint256) ownerBalanceAfterPoolEnd;
        // the last time of updating accrual of interest
        uint256 accrualTimestamp;
        // the D3Factory contract
        address _D3_FACTORY_;
        // the UserQuota contract
        address _USER_QUOTA_;
        // the creator of pool
        address _CREATOR_;
        // the start time of first epoch
        uint256 _EPOCH_START_TIME_;
        // the epoch duration
        uint256 _EPOCH_DURATION_;
        // use oracle to get token price
        address _ORACLE_;
        // when collateral ratio below IM, owner cannot withdraw, LPs cannot deposit
        uint256 _INITIAL_MARGIN_RATIO_;
        // when collateral ratio below MM, pool is going to be liquidated
        uint256 _MAINTENANCE_MARGIN_RATIO_;
        // swap maintainer
        address _MAINTAINER_;
        // swap fee model
        address _MT_FEE_RATE_MODEL_;
        // all pending LP withdraw requests
        WithdrawInfo[] pendingWithdrawList;
        // record next epoch interest rates and timestamp
        Epoch nextEpoch;
        // the current status of pool, including Ongoing, Liquidating, End
        PoolStatus _POOL_STATUS_;
        // record market maker last time updating pool
        HeartBeat heartBeat;

        // =============== Swap Storage =================
        
        mapping(address => TokenMMInfo) tokenMMInfoMap;
    }

    struct AssetInfo {
        address d3Token;
        uint256 reserve;
        uint256 maxDepositAmount;
        uint256 accruedInterest;
    }

    // epoch info
    struct Epoch {
        // epoch start time
        uint256 timestamp;
        // token => interest rate
        mapping(address => uint256) interestRate;
    }

    // LP withdraw request
    struct WithdrawInfo {
        // request id, a hash of lp address + deadline timestamp
        bytes32 requestId;
        // refund deadline, if owner hasn't refunded after this time, liquidator can force refund
        uint256 deadline;
        // user who requests withdrawing
        address user;
        // the token to be withdrawn
        address token;
        // this amount of D3Token will be locked after user submit withdraw request,
        // but will still generate interest during pending time
        uint256 d3TokenAmount;
    }

    // liquidation swap info
    struct LiquidationOrder {
        address fromToken;
        address toToken;
        uint256 fromAmount;
    }

    struct TokenMMInfo {
        // [ask price down(16) | ask price down decimal (8) | ask price up(16) | ask price up decimal(8) | bid price down(16) | bid price down decimal(8) | bid price up(16) | bid price up decimal(8)]
        uint96 priceInfo;
        // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
        uint64 amountInfo;
        // k is [0, 10000]
        uint16 kAsk;
        uint16 kBid;
        // [timeStamp | cumulativeflag = 0 or 1(1 bit)]
        uint64 updateTimestamp;
        uint256 cumulativeBid;
        uint256 cumulativeAsk;
    }

    struct HeartBeat {
        uint256 lastHeartBeat;
        uint256 maxInterval;
    }

    uint16 internal constant ONE_PRICE_BIT = 24;
    uint16 internal constant ONE_AMOUNT_BIT = 24;
    uint256 internal constant SECONDS_PER_YEAR = 31536000;
    uint256 internal constant ONE = 10 ** 18;

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function parseAskAmount(uint64 amountSet) internal pure returns (uint256 amountWithDecimal) {
        uint256 askAmount = (amountSet >> (ONE_AMOUNT_BIT + 8)) & 0xffff;
        uint256 askAmountDecimal = (amountSet >> ONE_AMOUNT_BIT) & 255;
        amountWithDecimal = askAmount * (10 ** askAmountDecimal);
    }

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function parseBidAmount(uint64 amountSet) internal pure returns (uint256 amountWithDecimal) {
        uint256 bidAmount = (amountSet >> 8) & 0xffff;
        uint256 bidAmountDecimal = amountSet & 255;
        amountWithDecimal = bidAmount * (10 ** bidAmountDecimal);
    }

    // [ask price down(16) | ask price down decimal (8) | ask price up(16) | ask price up decimal(8) | bid price down(16) | bid price down decimal(8) | bid price up(16) | bid price up decimal(8)]
    function parseAskPrice(uint96 priceSet)
        internal
        pure
        returns (uint256 askDownPriceWithDecimal, uint256 askUpPriceWithDecimal)
    {
        uint256 askDownPrice = (priceSet >> (ONE_PRICE_BIT * 3 + 8)) & 0xffff;
        uint256 askDownPriceDecimal = (priceSet >> (ONE_PRICE_BIT * 3)) & 255;
        uint256 askUpPrice = (priceSet >> (ONE_PRICE_BIT * 2 + 8)) & 0xffff;
        uint256 askUpPriceDecimal = (priceSet >> (ONE_PRICE_BIT * 2)) & 255;
        askDownPriceWithDecimal = askDownPrice * (10 ** askDownPriceDecimal);
        askUpPriceWithDecimal = askUpPrice * (10 ** askUpPriceDecimal);
    }

    // [ask price down(16) | ask price down decimal (8) | ask price up(16) | ask price up decimal(8) | bid price down(16) | bid price down decimal(8) | bid price up(16) | bid price up decimal(8)]
    function parseBidPrice(uint96 priceSet)
        internal
        pure
        returns (uint256 bidDownPriceWithDecimal, uint256 bidUpPriceWithDecimal)
    {
        uint256 bidDownPrice = (priceSet >> (ONE_PRICE_BIT + 8)) & 0xffff;
        uint256 bidDownPriceDecimal = (priceSet >> ONE_PRICE_BIT) & 255;
        uint256 bidUpPrice = (priceSet >> 8) & 0xffff;
        uint256 bidUpPriceDecimal = priceSet & 255;
        bidDownPriceWithDecimal = bidDownPrice * (10 ** bidDownPriceDecimal);
        bidUpPriceWithDecimal = bidUpPrice * (10 ** bidUpPriceDecimal);
    }

    function parseK(uint16 originK) internal pure returns (uint256) {
        return uint256(originK) * (10 ** 14);
    }

    struct RangeOrderState {
        address oracle;
        TokenMMInfo fromTokenMMInfo;
        TokenMMInfo toTokenMMInfo;
    }

    enum PoolStatus {
        Ongoing,
        Liquidating,
        End
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ID3Oracle} from "../../intf/ID3Oracle.sol";
import {DecimalMath} from "contracts/lib/DecimalMath.sol";
import {ID3Token} from "contracts/intf/ID3Token.sol";
import {IUserQuotaV3} from "contracts/intf/IUserQuotaV3.sol";
import {ID3Factory} from "contracts/intf/ID3Factory.sol";
import "../D3MMStorage.sol";
import "contracts/DODOV3MM/lib/FundingLibrary.sol";

/**
 * @author  DODO
 * @title   D3Funding
 * @dev     To save contract size, most of the function implements are moved to FundingLibrary.
 * @notice  This contract manages LP deposit/withdraw, owner deposit/withdraw.
 */

contract D3Funding is D3Storage {
    using SafeERC20 for IERC20;

    modifier poolOngoing() {
        require(state._POOL_STATUS_ == Types.PoolStatus.Ongoing, Errors.POOL_NOT_ONGOING);
        _;
    }

    modifier poolLiquidating() {
        require(state._POOL_STATUS_ == Types.PoolStatus.Liquidating, Errors.POOL_NOT_LIQUIDATING);
        _;
    }

    modifier poolEnd() {
        require(state._POOL_STATUS_ == Types.PoolStatus.End, Errors.POOL_NOT_END);
        _;
    }

    modifier tokenExist(address token) {
        require(state.assetInfo[token].d3Token != address(0), Errors.TOKEN_NOT_EXIST);
        _;
    }

    modifier tokenNotExist(address token) {
        require(state.assetInfo[token].d3Token == address(0), Errors.TOKEN_ALREADY_EXIST);
        _;
    }

    /// @notice Return current epoch number
    /// @return epoch the current epoch number
    function currentEpoch() public view returns (uint256 epoch) {
        epoch = (block.timestamp - state._EPOCH_START_TIME_) / state._EPOCH_DURATION_;
    }

    /// @notice Return the total USD value of the tokens in pool
    /// @return totalValue the total asset value in USD
    function getTotalAssetsValue() public view returns (uint256 totalValue) {
        totalValue = FundingLibrary.getTotalAssetsValue(state);
    }

    /// @notice Return the total USD value of the debts
    /// @return totalDebt the total debt value in USD
    function getTotalDebtValue() public view returns (uint256 totalDebt) {
        totalDebt = FundingLibrary.getTotalDebtValue(state);
    }

    /// @notice Return the collateral ratio
    /// @dev if totalAsset >= totalDebt, collateral ratio = (totalAsset - totalDebt) / totalAsset
    /// @dev if totalAsset < totalDebt, collateral ratio = 0
    /// @return collateralRatio the current collateral ratio
    function getCollateralRatio() public view returns (uint256 collateralRatio) {
        uint256 totalValue;
        uint256 totalDebt;
        uint256 timeDelta = block.timestamp - state.accrualTimestamp;
        for (uint8 i = 0; i < state.tokenList.length; i++) {
            address token = state.tokenList[i];
            uint256 interestRate = state.interestRate[token];
            uint256 price = ID3Oracle(state._ORACLE_).getPrice(token);
            totalValue += DecimalMath.mul(IERC20(token).balanceOf(address(this)), price);
            totalDebt += DecimalMath.mul(
                DecimalMath.mul(
                    ID3Token(state.assetInfo[token].d3Token).totalSupply(),
                    state.assetInfo[token].accruedInterest + (timeDelta * interestRate) / Types.SECONDS_PER_YEAR
                ),
                price
            );
        }
        if (totalValue <= totalDebt) {
            collateralRatio = 0;
        } else {
            collateralRatio = Types.ONE - DecimalMath.div(totalDebt, totalValue);
        }
    }

    // =========== LP Functions ==========

    /// @notice When LPs deposit token, they will receive the corresponding d3Token.
    /// @param lp the LP account address
    /// @param token the token address
    function lpDeposit(address lp, address token) public nonReentrant poolOngoing tokenExist(token) {
        FundingLibrary.lpDeposit(lp, token, state);
    }

    /// @notice LP can submit a withdraw request by locking some amount of the corresponding dToken.
    /// @dev The locked d3Token will still generate interest during withdraw pending time.
    /// @param token the token LP wants to withdraw
    /// @param d3TokenAmount the amount of d3Token going to lock
    function lpRequestWithdraw(address token, uint256 d3TokenAmount)
        public
        nonReentrant
        poolOngoing
        tokenExist(token)
    {
        FundingLibrary.lpRequestWithdraw(msg.sender, token, d3TokenAmount, state);
    }

    /// @notice LPs can withdraw their tokens after pool is closed, either by liquidation or pool owner.
    /// @notice LPs can get their tokens back immediately, whether or not they have pending withdraw request before pool closed.
    /// @notice If pool is closed by liquidation, under some extreme conditions, the total pool assets value might be less than total debts,
    /// @notice which means LP will suffer a loss. The returned token amount might be less than the deposit amount.
    /// @dev After pool closed, all tokens' interest rates are set to 0, and will no longer call `function accrueInterests()` to accrue interests.
    /// @param token the token requested to withdraw
    function lpWithdrawAfterPoolEnd(address token) public nonReentrant poolEnd tokenExist(token) {
        FundingLibrary.lpWithdrawAfterPoolEnd(msg.sender, token, state);
    }

    // =========== Pool Owner Functions ==========

    /// @notice Owner set max heartbeat interval
    /// @param interval the max heartbeat interval
    function setBeatInterval(uint256 interval) external onlyOwner {
        state.heartBeat.maxInterval = interval;
    }

    /// @notice Owner can set a UserQuota contract to limit LP deposit amount
    function setUserQuota(address userQuota) external onlyOwner {
        state._USER_QUOTA_ = userQuota;
        emit SetUserQuota(userQuota);
    }

    /// @notice Owner add a new token
    /// @param token the token address
    /// @param interestRate the token interestRate
    /// @param maxDepositAmount the max deposit amount for the token
    function addNewToken(address token, uint256 interestRate, uint256 maxDepositAmount)
        external
        onlyOwner
        poolOngoing
        tokenNotExist(token)
    {
        FundingLibrary.addNewToken(token, interestRate, maxDepositAmount, state);
    }

    /// @notice Owner set max deposit amount for a token
    /// @param token the token address
    /// @param maxDepositAmount the max deposit amount for the token
    function setMaxDeposit(address token, uint256 maxDepositAmount) external onlyOwner poolOngoing tokenExist(token) {
        state.assetInfo[token].maxDepositAmount = maxDepositAmount;
        emit SetMaxDeposit(token, maxDepositAmount);
    }

    /// @notice Owner set new interest rate for next epoch.
    /// @param tokenList an array of tokens going to be updated
    /// @param interestRates an array of new interest rates
    function setNextEpoch(address[] calldata tokenList, uint256[] calldata interestRates)
        external
        poolOngoing
        onlyOwner
    {
        FundingLibrary.setNextEpoch(tokenList, interestRates, state);
    }

    /// @notice The new interest rates will only be effective by calling this function
    function executeEpochUpdate() external poolOngoing {
        FundingLibrary.executeEpochUpdate(state);
    }

    /// @notice Owner refund LP. The LP must have submit a withdraw request before.
    /// @param index the index of the withdraw request in the pending request list
    function refund(uint256 index) public onlyOwner nonReentrant poolOngoing {
        FundingLibrary.refund(index, state);
    }

    /// @notice Owner deposit token
    /// @param token the token going to be deposited
    function ownerDeposit(address token) external poolOngoing tokenExist(token) {
        emit OwnerDeposit(token, IERC20(token).balanceOf(address(this)) - state.assetInfo[token].reserve);
        updateReserve(token);
    }

    /// @notice Owner withdraw token
    /// @param to the address where token will be tranferred to
    /// @param token the token address
    /// @param amount the amount going to be withdrawn
    function ownerWithdraw(address to, address token, uint256 amount)
        external
        onlyOwner
        nonReentrant
        poolOngoing
        tokenExist(token)
    {
        FundingLibrary.ownerWithdraw(to, token, amount, state);
    }

    /// @notice Owner withdraw assets after pool is closed
    /// @param to the address where token will be tranferred to
    /// @param token the token address
    /// @param amount the amount going to be withdrawn
    function ownerWithdrawAfterPoolEnd(address to, address token, uint256 amount)
        external
        onlyOwner
        nonReentrant
        poolEnd
        tokenExist(token)
    {
        FundingLibrary.ownerWithdrawAfterPoolEnd(to, token, amount, state);
    }

    /// @notice Owner cannot close pool if pool is under liquidating process
    function ownerClosePool() external onlyOwner poolOngoing {
        FundingLibrary.ownerClosePool(state);
    }

    // =========== Pool Status ===========

    /// @notice update token reserve
    /// @param token the token address
    function updateReserve(address token) internal returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));
        state.assetInfo[token].reserve = balance;
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IWETH} from "contracts/intf/IWETH.sol";
import {ID3Token} from "contracts/intf/ID3Token.sol";
import {IUserQuotaV3} from "contracts/intf/IUserQuotaV3.sol";
import {ID3Oracle} from "contracts/intf/ID3Oracle.sol";
import {ID3Factory} from "contracts/intf/ID3Factory.sol";
import "contracts/DODOV3MM/lib/LiquidationLibrary.sol";
import "./D3Funding.sol";

/**
 * @author  DODO
 * @title   D3Liquidation
 * @dev     To save contract size, most of the function implements are moved to LiquidationLibrary.
 * @notice  This contract manages pool liquidation and force refund.
 */

contract D3Liquidation is D3Funding {
    using SafeERC20 for IERC20;

    modifier onlyLiquidator() {
        require(
            ID3Factory(state._D3_FACTORY_)._LIQUIDATOR_WHITELIST_(msg.sender),
            Errors.NOT_ALLOWED_LIQUIDATOR
        );
        _;
    }

    modifier onlyRouter(address router) {
        require(
            ID3Factory(state._D3_FACTORY_)._ROUTER_WHITELIST_(router),
            Errors.NOT_ALLOWED_ROUTER
        );
        _;
    }

    // =========== Liquidation ===========
    /*
        1. calculate total asset value: A
        2. calculate total debt value: D
        3. calculate ratio: R = A / D
        4. if R > 1, for each token, calculate delta = (balance - debt), 
           if delta > 0, means we need sell this token, 
           if delta < 0, means we need to buy this token
        5. if R < 1, debt = debt * R, then calculate delta = (balance - debt)
        6. the delta array is like [100, -50, 200, -100], 
           the swapping goal is to make this array contains only positve (zero included) or only negative number (zero included)
        7. based on the new balance and debt, calculate the amounts each LP and owner can withdraw
    */

    /// @notice If collateral ratio is less than MM, liquiator can trigger liquidation
    function startLiquidation() external onlyLiquidator poolOngoing {
        LiquidationLibrary.startLiquidation(state);
    }

    /// @notice Liquidator pass in route data to swap tokens for liquidation.
    /// @dev This function can be called multiple times if liquidation not finished
    /// @param order the swap infomation
    /// @param routeData the swap route data
    /// @param router the route contract which will swap tokens
    function liquidate(
        Types.LiquidationOrder calldata order,
        bytes calldata routeData,
        address router
    ) external nonReentrant onlyLiquidator onlyRouter(router) poolLiquidating {
        LiquidationLibrary.liquidate(order, routeData, router, state);
    }

    /// @notice Liquidator call this function to finish liquidation
    /// @dev The goal is to make all tokens' balance be larger than target amount, 
    /// @dev or all tokens' balance be smaller than target amount
    function finishLiquidation() external onlyLiquidator poolLiquidating {
        LiquidationLibrary.finishLiquidation(state);
    }

    /// @notice If owner hasn't refund LP after deadline, liquidator can call this to force refund.
    /// @dev call be called multiple times if withdrawal amount not fully paid
    /// @param index the withdraw request's index in pending request list
    /// @param order the swap infomation
    /// @param routeData the swap route data
    /// @param router the route contract which will swap tokens
    function forceRefund(
        uint256 index,
        Types.LiquidationOrder calldata order,
        bytes calldata routeData,
        address router
    ) external onlyLiquidator onlyRouter(router) poolOngoing {
        LiquidationLibrary.forceRefund(index, order, routeData, router, state);
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import "../rangeOrder/PMMRangeOrder.sol";
import "../lib/Errors.sol";
import {IFeeRateModel} from "contracts/intf/IFeeRateModel.sol";
import {D3Funding} from "./D3Funding.sol";
import {IDODOSwapCallback} from "../../intf/IDODOSwapCallback.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract D3Trading is D3Funding {
    using SafeERC20 for IERC20;

    // =========== Read ==============
    /// @notice for external users to read tokenMMInfo
    function getTokenMMInfoForRead(address token)
        external
        view
        returns (
            uint96 priceInfo,
            uint256 askAmount,
            uint256 bidAmount, 
            uint16 kAsk,
            uint16 kBid,
            uint64 updateTimeStamp,
            uint256 updateFlag,
            uint256 cumulativeAsk,
            uint256 cumulativeBid
        )
    {
        priceInfo = state.tokenMMInfoMap[token].priceInfo;
        askAmount = Types.parseAskAmount(state.tokenMMInfoMap[token].amountInfo);
        bidAmount = Types.parseBidAmount(state.tokenMMInfoMap[token].amountInfo);
        kAsk = state.tokenMMInfoMap[token].kAsk;
        kBid = state.tokenMMInfoMap[token].kBid;
        updateTimeStamp = state.tokenMMInfoMap[token].updateTimestamp >> 1;
        updateFlag = state.tokenMMInfoMap[token].updateTimestamp & 1;
        cumulativeAsk = updateFlag == 1 ? state.tokenMMInfoMap[token].cumulativeAsk : 0;
        cumulativeBid = updateFlag == 1 ? state.tokenMMInfoMap[token].cumulativeBid : 0;
    }

    // ============ Swap =============
    /// @notice get swap status for internal swap 
    function getRangeOrderState(address fromToken, address toToken)
        public
        view
        returns (Types.RangeOrderState memory roState)
    {
        roState.oracle = state._ORACLE_;
        roState.fromTokenMMInfo = state.tokenMMInfoMap[fromToken];
        roState.toTokenMMInfo = state.tokenMMInfoMap[toToken];

        // deal with update flag
        if(roState.fromTokenMMInfo.updateTimestamp & 1 == 0) {
            roState.fromTokenMMInfo.cumulativeAsk = 0;
            roState.fromTokenMMInfo.cumulativeBid = 0;
        }

        if(roState.toTokenMMInfo.updateTimestamp & 1 == 0) {
            roState.toTokenMMInfo.cumulativeAsk = 0;
            roState.toTokenMMInfo.cumulativeBid = 0;
        }
    }

    function sellToken(
        address to,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minReceiveAmount,
        bytes calldata data
    ) public poolOngoing returns(uint256) {
        require(block.timestamp - state.heartBeat.lastHeartBeat <= state.heartBeat.maxInterval, Errors.HEARTBEAT_CHECK_FAIL);
        _updateCumulative(fromToken);
        _updateCumulative(toToken);

        (uint256 payFromAmount, uint256 receiveToAmount, uint256 vusdAmount, uint256 mtFee) = querySellTokens(fromToken, toToken, fromAmount);
        require(receiveToAmount >= minReceiveAmount, Errors.MINRES_NOT_ENOUGH);

        _transferOut(to, toToken, receiveToAmount);
        _transferOut(state._MAINTAINER_, toToken, mtFee);

        // external call & swap callback
        IDODOSwapCallback(msg.sender).d3MMSwapCallBack(
            fromToken,
            fromAmount,
            data
        );

        require(
            IERC20(fromToken).balanceOf(address(this)) -
                state.assetInfo[fromToken].reserve >=
                fromAmount,
            Errors.FROMAMOUNT_NOT_ENOUGH
        );

        require(
            getCollateralRatio() >= state._INITIAL_MARGIN_RATIO_,
            Errors.BELOW_IM_RATIO
        );

        // record swap
        _recordSwap(fromToken, toToken, vusdAmount, receiveToAmount + mtFee);

        emit Swap(to, fromToken, toToken, payFromAmount, receiveToAmount, 0);
        return receiveToAmount;
    }

    function buyToken(
        address to,
        address fromToken,
        address toToken,
        uint256 quoteAmount,
        uint256 maxPayAmount,
        bytes calldata data
    ) public poolOngoing returns(uint256) {
        require(block.timestamp - state.heartBeat.lastHeartBeat <= state.heartBeat.maxInterval, Errors.HEARTBEAT_CHECK_FAIL);
        require(quoteAmount <= state.assetInfo[toToken].reserve, Errors.BALANCE_NOT_ENOUGH);

        _updateCumulative(fromToken);
        _updateCumulative(toToken);

        // query amount and transfer out
        (uint256 payFromAmount, uint256 receiveToAmount, uint256 vusdAmount, uint256 mtFee) = queryBuyTokens(fromToken, toToken, quoteAmount);
        require(
            payFromAmount <= maxPayAmount,
            Errors.MAXPAY_NOT_ENOUGH
        );

        _transferOut(to, toToken, receiveToAmount);
        _transferOut(state._MAINTAINER_, toToken, mtFee);

        // external call & swap callback
        IDODOSwapCallback(msg.sender).d3MMSwapCallBack(
            fromToken,
            payFromAmount,
            data
        );

        require(
            IERC20(fromToken).balanceOf(address(this)) -
                state.assetInfo[fromToken].reserve >=
                payFromAmount,
            Errors.FROMAMOUNT_NOT_ENOUGH
        );

        require(
            getCollateralRatio() >= state._INITIAL_MARGIN_RATIO_,
            Errors.BELOW_IM_RATIO
        );

        // record swap
        _recordSwap(fromToken, toToken, vusdAmount, receiveToAmount + mtFee);

        emit Swap(to, fromToken, toToken, payFromAmount, receiveToAmount, 1);
        return payFromAmount;
    }

    function querySellTokens(address fromToken, address toToken, uint256 fromAmount) public view returns(uint256, uint256, uint256, uint256) {
        require(fromAmount > 1000, Errors.AMOUNT_TOO_SMALL);
        Types.RangeOrderState memory D3State = getRangeOrderState(
            fromToken,
            toToken
        );

        (uint256 payFromAmount, uint256 receiveToAmount, uint256 vusdAmount) = PMMRangeOrder
            .querySellTokens(D3State, fromToken, toToken, fromAmount);

        uint256 mtFeeRate = IFeeRateModel(state._MT_FEE_RATE_MODEL_).getFeeRate(msg.sender);
        uint256 mtFee = DecimalMath.mulFloor(receiveToAmount, mtFeeRate);

        return (payFromAmount, receiveToAmount - mtFee, vusdAmount, mtFee);
    }

    function queryBuyTokens(address fromToken, address toToken, uint256 toAmount) public view returns(uint256, uint256, uint256, uint256) {
        require(toAmount > 1000, Errors.AMOUNT_TOO_SMALL);
        Types.RangeOrderState memory D3State = getRangeOrderState(
            fromToken,
            toToken
        );

        // query amount and transfer out
        uint256 mtFeeRate = IFeeRateModel(state._MT_FEE_RATE_MODEL_).getFeeRate(msg.sender);
        uint256 mtFee = DecimalMath.mulFloor(toAmount, mtFeeRate);
        toAmount += mtFee;

        (uint256 payFromAmount, uint256 receiveToAmountWithFee, uint256 vusdAmount) = PMMRangeOrder
            .queryBuyTokens(D3State, fromToken, toToken, toAmount);

        return (payFromAmount, receiveToAmountWithFee - mtFee, vusdAmount, mtFee);
    }

    // ================ internal ==========================

    function _recordSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount
    ) internal {
        state.tokenMMInfoMap[fromToken].cumulativeBid += fromAmount;
        state.tokenMMInfoMap[toToken].cumulativeAsk += toAmount;

        updateReserve(fromToken);
        updateReserve(toToken);
    }

    function _updateCumulative(address token) internal {
        uint256 timeStamp = state.tokenMMInfoMap[token].updateTimestamp;
        uint256 tokenFlag = timeStamp & 1;
        if (tokenFlag == 0) {
            state.tokenMMInfoMap[token].cumulativeAsk = 0;
            state.tokenMMInfoMap[token].cumulativeBid = 0;
            state.tokenMMInfoMap[token].updateTimestamp = uint64(timeStamp | 1);
        }
    }

    function _transferOut(
        address to,
        address token,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(to, amount);
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

import "./PMMRangeOrder.sol";
import "../D3MMStorage.sol";
import "../lib/Types.sol";

/// @dev maker won't provide delete token function
contract D3Maker is D3Storage {

    /// @notice maker set a new token info
    /// @param priceSet describe ask and bid price, [ask price down(16) | ask price down decimal (8) | ask price up(16) | ask price up decimal(8) | bid price down(16) | bid price down decimal(8) | bid price up(16) | bid price up decimal(8)] = one slot could contains 2 token info
    /// @param amountSet describe ask and bid amount and K, [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ] = one slot could contains 4 token info
    function setNewToken(
        address token, 
        uint96 priceSet,
        uint64 amountSet,
        uint16 kAsk,
        uint16 kBid
    ) public onlyOwner {
        // check amount
        _checkAskAmount(token, amountSet);
        require(kAsk >= 0 && kAsk <= 10000,  Errors.K_LIMIT);
        require(kBid >=0 && kBid <= 10000, Errors.K_LIMIT);

        // set new token info
        state.tokenMMInfoMap[token].priceInfo = priceSet;
        state.tokenMMInfoMap[token].amountInfo = amountSet;
        state.tokenMMInfoMap[token].kAsk = kAsk;
        state.tokenMMInfoMap[token].kBid = kBid;
        state.tokenMMInfoMap[token].updateTimestamp = uint64(block.timestamp) << 1;
        state.heartBeat.lastHeartBeat = block.timestamp;
    }

    /// @notice set token prices
    /// @param tokens token address set
    /// @param tokenPrices token prices set, each number pack one token all price.Each format is the same with priceSet
    /// [ask price down(16) | ask price down decimal (8) | ask price up(16) | ask price up decimal(8) | bid price down(16) | bid price down decimal(8) | bid price up(16) | bid price up decimal(8)] = one slot could contains 2 token info
    function setTokensPrice(
        address[] calldata tokens, 
        uint96[] calldata tokenPrices
    ) public onlyOwner {
        for(uint i = 0; i < tokens.length; ++i) {
            address curToken = tokens[i];
            uint96 curTokenPriceSet = tokenPrices[i];
            _checkUpAndDownPrice(curTokenPriceSet);

            state.tokenMMInfoMap[curToken].priceInfo = curTokenPriceSet;
        }
        state.heartBeat.lastHeartBeat = block.timestamp;
    }

    /// @notice set token Amounts
    /// @param tokens token address set
    /// @param tokenAmounts token amounts set, each number pack one token all amounts.Each format is the same with amountSetAndK
    /// [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ] = one slot could contains 4 token info
    function setTokensAmounts(
        address[] calldata tokens,
        uint64[] calldata tokenAmounts
    ) public onlyOwner {
        for(uint i = 0; i < tokens.length; ++i) {
            address curToken = tokens[i];
            uint64 curTokenAmountSet = tokenAmounts[i];

            _checkAskAmount(curToken, curTokenAmountSet);
            state.tokenMMInfoMap[curToken].amountInfo = curTokenAmountSet;
            state.tokenMMInfoMap[curToken].updateTimestamp = uint64(block.timestamp) << 1;
        }
        state.heartBeat.lastHeartBeat = block.timestamp;
    }

    /// @notice set token Ks
    /// @param tokens token address set
    /// @param tokenKs token k_ask and k_bid, structure like [kAsk(16) | kBid(16)]
    function setTokensKs(
        address[] calldata tokens,
        uint32[] calldata tokenKs
    ) public onlyOwner {
        for(uint i = 0; i < tokens.length; ++i) {
            address curToken = tokens[i];
            uint32 curTokenK = tokenKs[i];
            uint16 kAsk = uint16(curTokenK >> 16);
            uint16 kBid = uint16(curTokenK & 0xffff);

            require(kAsk >= 0 && kAsk <= 10000,  Errors.K_LIMIT);
            require(kBid >=0 && kBid <= 10000, Errors.K_LIMIT);
            
            state.tokenMMInfoMap[curToken].kAsk = kAsk;
            state.tokenMMInfoMap[curToken].kBid = kBid;
        }
        state.heartBeat.lastHeartBeat = block.timestamp;
    } 
    
    function setTokenAmountsAndPrices(
        address[] calldata tokens,
        uint96[] calldata tokenPrices,
        uint64[] calldata tokenAmounts
    ) public onlyOwner {
        for(uint i = 0; i < tokens.length; ++i) {
            address curToken = tokens[i];
            uint64 curTokenAmountSet = tokenAmounts[i];
            uint96 curTokenPriceSet = tokenPrices[i];

            _checkAskAmount(curToken, curTokenAmountSet);
            _checkUpAndDownPrice(curTokenPriceSet);
            state.tokenMMInfoMap[curToken].amountInfo = curTokenAmountSet;
            state.tokenMMInfoMap[curToken].updateTimestamp = uint64(block.timestamp) << 1;
            state.tokenMMInfoMap[curToken].priceInfo = curTokenPriceSet;
        }
        state.heartBeat.lastHeartBeat = block.timestamp;
    }

    // =========== internal ==========

    function _checkAskAmount(address token, uint64 amountSet) internal view {
        uint256 amountWithDecimal = Types.parseAskAmount(amountSet);
        require(amountWithDecimal >= 0 && amountWithDecimal <= state.assetInfo[token].reserve, Errors.ASK_AMOUNT_EXCEED);
    }

    function _checkUpAndDownPrice(uint96 priceSet) internal pure {
        (uint256 askDownPrice, uint256 askUpPrice) = Types.parseAskPrice(priceSet);
        require(askUpPrice >= askDownPrice && askDownPrice >= 0, Errors.PRICE_UP_BELOW_PRICE_DOWN);
        (uint256 bidDownPrice, uint256 bidUpPrice) = Types.parseBidPrice(priceSet);
        require(bidUpPrice >= bidDownPrice && bidDownPrice >= 0, Errors.PRICE_UP_BELOW_PRICE_DOWN);
    }
}

/*

    Copyright 2022 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/


pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import "../lib/PMMPricing.sol";
import "../lib/Errors.sol";
import "../lib/Types.sol";
import {ID3Oracle} from "../../intf/ID3Oracle.sol";


library PMMRangeOrder {

    uint256 internal constant ONE = 10 ** 18;

    // use fromToken bid curve and toToken ask curve
    function querySellTokens(
        Types.RangeOrderState memory roState, 
        address fromToken, 
        address toToken, 
        uint256 fromTokenAmount) internal view returns(uint256 fromAmount, uint256 receiveToToken, uint256 vusdAmount)
    { 
        // contruct fromToken state and swap to vUSD
        uint256 receiveVUSD;
        {
            PMMPricing.PMMState memory fromTokenState = _contructTokenState(roState, true, false);
            receiveVUSD = PMMPricing._querySellQuoteToken(fromTokenState, fromTokenAmount);
        }

        // construct toToken state and swap from vUSD to toToken
        {
            PMMPricing.PMMState memory toTokenState = _contructTokenState(roState, false, true);
            receiveToToken = PMMPricing._querySellQuoteToken(toTokenState, receiveVUSD);
        }

        // oracle protect 
        {
            uint256 oracleToAmount = ID3Oracle(roState.oracle).getMaxReceive(fromToken, toToken, fromTokenAmount);
            require(oracleToAmount >= receiveToToken, Errors.RO_ORACLE_PROTECTION);
        }
        return (fromTokenAmount, receiveToToken, receiveVUSD);
    }

    // use fromToken bid curve and toToken ask curve
    function queryBuyTokens( 
        Types.RangeOrderState memory roState, 
        address fromToken, address toToken, 
        uint256 toTokenAmount) internal view returns(uint256 payFromToken, uint256 toAmount, uint256 vusdAmount)
    {
        // contruct fromToken to vUSD
        uint256 payVUSD;
        {
            PMMPricing.PMMState memory toTokenState = _contructTokenState(roState, false, true);
            // vault reserve protect
            require(toTokenAmount <= toTokenState.BMaxAmount - roState.toTokenMMInfo.cumulativeAsk, Errors.RO_VAULT_RESERVE);
            payVUSD = PMMPricing._queryBuyBaseToken(toTokenState, toTokenAmount);
        }

        // construct vUSD to toToken
        {
            PMMPricing.PMMState memory fromTokenState = _contructTokenState(roState, true, false);
            payFromToken = PMMPricing._queryBuyBaseToken(fromTokenState, payVUSD);
        }

        // oracle protect 
        {
            uint256 oracleToAmount = ID3Oracle(roState.oracle).getMaxReceive(fromToken, toToken, payFromToken);
            require(oracleToAmount >= toTokenAmount, Errors.RO_ORACLE_PROTECTION);
        }

        return (payFromToken, toTokenAmount, payVUSD);
    }

    // ========= internal ==========
    function _contructTokenState(Types.RangeOrderState memory roState, bool fromTokenOrNot, bool askOrNot) internal pure returns(PMMPricing.PMMState memory tokenState) {
        Types.TokenMMInfo memory tokenMMInfo = fromTokenOrNot ? roState.fromTokenMMInfo : roState.toTokenMMInfo;
        
        // bMax,k
        tokenState.BMaxAmount = _calSlotAmountInfo(tokenMMInfo.amountInfo, askOrNot);
        // amount = 0 protection
        require(tokenState.BMaxAmount > 0, Errors.RO_AMOUNT_ZERO);
        tokenState.K = askOrNot ? Types.parseK(tokenMMInfo.kAsk) : Types.parseK(tokenMMInfo.kBid);
            
        // i, B0
        uint256 upPrice;
        (tokenState.i, upPrice) = _calSlotPriceInfo(tokenMMInfo.priceInfo, askOrNot);
        // price = 0 protection
        require(tokenState.i > 0, Errors.RO_PRICE_ZERO);
        tokenState.B0 = _calB0WithPriceLimit(upPrice, tokenState.K, tokenState.i, tokenState.BMaxAmount);
        // B
        tokenState.B = askOrNot ? tokenState.B0 - tokenMMInfo.cumulativeAsk : tokenState.B0 - tokenMMInfo.cumulativeBid;

        return tokenState;
    }

    // P_up = i(1 - k + k*(B0 / B0 - amount)^2), record amount = A
    // (P_up + i*k - 1) / i*k = (B0 / B0 - A)^2
    // B0 = A + A / (sqrt((P_up + i*k - i) / i*k) - 1)
    // i = priceDown
    function _calB0WithPriceLimit(uint256 priceUp, uint256 k, uint256 i, uint256 amount) internal pure returns(uint256 baseTarget){

        // (P_up + i*k - i)
        // temp1 = PriceUp + DecimalMath.mul(i, k) - i
        // temp1 price

        // i*k
        // temp2 = DecimalMath.mul(i, k)
        // temp2 price

        // (P_up + i*k - i)/i*k
        // temp3 = DecimalMath(temp1, temp2)
        // temp3 ONE

        // temp4 = sqrt(temp3 * ONE)
        // temp4 ONE
        
        // temp5 = temp4 - ONE
        // temp5 ONE

        // B0 = amount + DecimalMath.div(amount, temp5)
        // B0 amount
        if(k == 0) baseTarget = amount;
        else {
            uint256 temp1 = priceUp + DecimalMath.mul(i, k) - i;
            uint256 temp3 = DecimalMath.div(temp1, DecimalMath.mul(i, k));
            uint256 temp5 = DecimalMath.sqrt(temp3) - ONE;
            baseTarget = amount + DecimalMath.div(amount, temp5);
        }
    }

    // [ask amounts(16) | ask amounts decimal(8) | bid amounts(16) | bid amounts decimal(8) ]
    function _calSlotAmountInfo(uint64 amountSet, bool askOrNot) internal pure returns(uint256 amountWithDecimal){
        amountWithDecimal = askOrNot ? Types.parseAskAmount(amountSet) : Types.parseBidAmount(amountSet);
    }

    // [ask price down(16) | ask price down decimal (8) | ask price up(16) | ask price up decimal(8) | bid price down(16) | bid price down decimal(8) | bid price up(16) | bid price up decimal(8)]
    function _calSlotPriceInfo(uint96 priceSet, bool askOrNot) internal pure returns(uint256 , uint256 ) {
        return askOrNot ? Types.parseAskPrice(priceSet) : Types.parseBidPrice(priceSet);
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Factory {
    function createDToken(address, address) external returns (address);
    function addLiquidator(address) external;
    function _LIQUIDATOR_WHITELIST_(address) external returns (bool);
    function _ROUTER_WHITELIST_(address) external returns (bool);
    function _POOL_WHITELIST_(address) external returns (bool);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Oracle {
    function getMaxReceive(address fromToken, address toToken, uint256 fromAmount) external view returns(uint256);
    function getPrice(address base) external view returns (uint256);  
    function isFeasible(address base) external view returns (bool); 
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Token {
    function init(address, address) external;
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function lock(address, uint256) external;
    function unlock(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function lockedOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/*
    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

interface IDODOSwapCallback {
    function d3MMSwapCallBack(
        address token,
        uint256 value,
        bytes calldata data
    ) external ;
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface IFeeRateModel {
    function getFeeRate(address trader) external view returns (uint256);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface IUserQuotaV3 {
    function getUserQuota(address user, address token) external view returns (uint);
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;


interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;


import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */

library DecimalMath {

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * d / (10**18);
    }

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * d / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return _divCeil(target * d, 10**18);
    }

    function div(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * (10**18) / d;
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * (10**18) / d;
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return _divCeil(target * (10**18), d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36) / target;
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return _divCeil(uint256(10**36), target);
    }

    function sqrt(uint256 target) internal pure returns (uint256) {
        return Math.sqrt(target * ONE);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e / 2);
            p = p * p / (10**18);
            if (e % 2 == 1) {
                p = p * target / (10**18);
            }
            return p;
        }
    }

    function _divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import { DecimalMath } from "./DecimalMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DODOMath
 * @author DODO Breeder
 *
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library DODOMath {

    /*
        Integrate dodo curve from V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))

        i is the price of V-res trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _GeneralIntegrate(
        uint256 V0,
        uint256 V1,
        uint256 V2,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        uint256 fairAmount = i * (V1 - V2); // i*delta
        if (k == 0) {
            return fairAmount / DecimalMath.ONE;
        }
        uint256 V0V0V1V2 = DecimalMath.divFloor(V0 * V0 / V1, V2);
        uint256 penalty = DecimalMath.mulFloor(k, V0V0V1V2); // k(V0^2/V1/V2)
        return (DecimalMath.ONE - k + penalty) * fairAmount / DecimalMath.ONE2;
    }

    /*
        Follow the integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2 
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan

        if deltaBSig=true, then Q2>Q1, user sell Q and receive B
        if deltaBSig=false, then Q2<Q1, user sell B and receive Q
        return |Q1-Q2|

        as we only support sell amount as delta, the deltaB is always negative
        the input ideltaB is actually -ideltaB in the equation

        i is the price of delta-V trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTrade(
        uint256 V0,
        uint256 V1,
        uint256 delta,
        uint256 i,
        uint256 k
    ) internal pure returns (uint256) {
        require(V0 > 0, "TARGET_IS_ZERO");
        if (delta == 0) {
            return 0;
        }

        if (k == 0) {
            // why v1
            return DecimalMath.mulFloor(i, delta) > V1 ? V1 : DecimalMath.mulFloor(i, delta);
        }

        if (k == DecimalMath.ONE) {
            // if k==1
            // Q2=Q1/(1+ideltaBQ1/Q0/Q0)
            // temp = ideltaBQ1/Q0/Q0
            // Q2 = Q1/(1+temp)
            // Q1-Q2 = Q1*(1-1/(1+temp)) = Q1*(temp/(1+temp))
            // uint256 temp = i.mul(delta).mul(V1).div(V0.mul(V0));
            uint256 temp;
            uint256 idelta = i * (delta);
            if (idelta == 0) {
                temp = 0;
            } else if ((idelta * V1) / idelta == V1) {
                temp = (idelta * V1) / (V0*(V0));
            } else {
                temp = delta * (V1) / (V0)* (i) / (V0);
            }
            return V1 * (temp) / (temp + (DecimalMath.ONE));
        }

        // calculate -b value and sig
        // b = kQ0^2/Q1-i*deltaB-(1-k)Q1
        // part1 = (1-k)Q1 >=0
        // part2 = kQ0^2/Q1-i*deltaB >=0
        // bAbs = abs(part1-part2)
        // if part1>part2 => b is negative => bSig is false
        // if part2>part1 => b is positive => bSig is true
        uint256 part2 = k*(V0)/(V1)*(V0) + (i* (delta)); // kQ0^2/Q1-i*deltaB 
        // todo why * v0 *v0 /v1
        uint256 bAbs = (DecimalMath.ONE-k) * (V1); // (1-k)Q1

        bool bSig;
        if (bAbs >= part2) {
            bAbs = bAbs - part2;
            bSig = false;
        } else {
            bAbs = part2 - bAbs;
            bSig = true;
        }
        bAbs = bAbs / (DecimalMath.ONE);

        // calculate sqrt
        uint256 squareRoot =
            DecimalMath.mulFloor(
                (DecimalMath.ONE - k) * (4),
                DecimalMath.mulFloor(k, V0) * (V0)
            ); // 4(1-k)kQ0^2
        squareRoot = Math.sqrt((bAbs * bAbs) + squareRoot); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = (DecimalMath.ONE - k) * 2; // 2(1-k)
        uint256 numerator;
        if (bSig) {
            numerator = squareRoot - bAbs;
        } else {
            numerator = bAbs + squareRoot;
        }

        uint256 V2 = DecimalMath.divCeil(numerator, denominator);
        if (V2 > V1) {
            return 0;
        } else {
            return V1 - V2;
        }
    }

}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}