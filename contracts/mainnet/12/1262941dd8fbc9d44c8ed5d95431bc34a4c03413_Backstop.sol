// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IBackstop, Terms, TermsProposal} from "crate/interfaces/IBackstop.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ISeniorPool} from "crate/interfaces/ISeniorPool.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {Ownable} from "crate/Ownable.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMathExt} from "crate/library/SafeMathExt.sol";
import {IFiduLense} from "crate/interfaces/IFiduLense.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

using SafeERC20 for IERC20;
using SafeMathExt for uint256;
using Math for uint256;
using TermsLib for Terms;
using TermsProposalLib for TermsProposal;

/**
 * @title Backstop
 * @author Warbler Labs Engineering
 * @notice This contract provides a "liquidity buffer" to the senior pool that allows an address
 *         agreed on by the "owner" and the governor to swap their FIDU to USDC using the buffer,
 *         provided they have enough FIDU.
 */
contract Backstop is Ownable, IBackstop {
  /// @inheritdoc IBackstop
  IERC20 public immutable fidu;

  /// @inheritdoc IBackstop
  IERC20 public immutable usdc;

  /// @inheritdoc IBackstop
  address public governor;

  /// @notice Currently active backstop terms
  Terms internal _activeTerms;

  /// @notice Proposed terms
  TermsProposal internal _proposedTerms;

  /**
   * @notice Constructor
   * @param _owner owner of contract
   * @param _governor owner of governor role
   * @param _usdc USDC contract
   * @param _fidu FIDU contract
   */
  constructor(address _owner, address _governor, IERC20 _usdc, IERC20 _fidu) Ownable(_owner) {
    governor = _governor;
    usdc = _usdc;
    fidu = _fidu;
  }

  /* ================================================================================
                                View Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function isActive() public view returns (bool) {
    return block.timestamp < _activeTerms.endTime;
  }

  /// @inheritdoc IBackstop
  function activeTerms() external view returns (Terms memory) {
    return _activeTerms;
  }

  /// @inheritdoc IBackstop
  function proposedTerms() external view returns (TermsProposal memory) {
    return _proposedTerms;
  }

  /// @inheritdoc IBackstop
  function swapper() public view returns (address) {
    return _activeTerms.swapper;
  }

  /// @inheritdoc IBackstop
  function backstopUsed() public view returns (uint256) {
    return _activeTerms.backstopUsed;
  }

  /// @inheritdoc IBackstop
  function backstopAvailable() public view returns (uint256) {
    if (!isActive()) {
      return 0;
    }

    uint256 swapperPositionValue = _activeTerms.lense.fiduPositionValue(_activeTerms.swapper);
    uint256 percentOfPosition = swapperPositionValue.decMul(_activeTerms.backstopPercentage);

    uint256 upperBound = percentOfPosition.min(_activeTerms.maxBackstopAmount);

    return upperBound.saturatingSub(_activeTerms.backstopUsed);
  }

  /* ================================================================================
                                Owner Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function proposeTerms(TermsProposal calldata terms) external onlyOwner {
    terms.validate();

    _proposedTerms = terms;
    emit TermsProposed({
      from: msg.sender,
      swapper: _proposedTerms.swapper,
      endTime: _proposedTerms.endTime,
      lense: _proposedTerms.lense,
      backstopPercentage: _proposedTerms.backstopPercentage,
      maxBackstopAmount: _proposedTerms.maxBackstopAmount
    });
  }

  // @inheritdoc IBackstop
  function previewSweep() public view returns (uint256, uint256) {
    uint256 usdcAvailable = isActive()
      ? usdc.balanceOf(address(this)).saturatingSub(_activeTerms.maxBackstopAmount)
      : usdc.balanceOf(address(this));
    uint256 fiduAvailable = isActive() ? 0 : fidu.balanceOf(address(this));
    return (usdcAvailable, fiduAvailable);
  }

  /// @inheritdoc IBackstop
  function sweep() external onlyOwner returns (uint256, uint256) {
    (uint256 usdcAmount, uint256 fiduAmount) = previewSweep();

    // early return to avoid gas
    if (usdcAmount == 0 && fiduAmount == 0) {
      return (0, 0);
    }

    usdc.safeTransfer(msg.sender, usdcAmount);
    fidu.safeTransfer(msg.sender, fiduAmount);

    emit FundsSwept({from: msg.sender, usdcAmount: usdcAmount, fiduAmount: fiduAmount});

    return (usdcAmount, fiduAmount);
  }

  /* ================================================================================
                                Governor Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function transferGovernor(address newGovernor) external onlyGovernor {
    address oldGovernor = governor;
    governor = newGovernor;
    emit GovernorTransferred(oldGovernor, governor);
  }

  function acceptTerms(
    uint64 _endTime,
    IFiduLense _lense,
    address _swapper,
    uint256 _maxBackstopAmount,
    uint64 _backstopPercentage
  ) external {
    TermsProposal memory t = TermsProposal({
      endTime: _endTime,
      lense: _lense,
      swapper: _swapper,
      maxBackstopAmount: _maxBackstopAmount,
      backstopPercentage: _backstopPercentage
    });

    if (!_proposedTerms.eq(t)) {
      revert ProposedTermsDontMatch();
    }

    return _acceptTerms();
  }

  /// @inheritdoc IBackstop
  function acceptTerms() external {
    return _acceptTerms();
  }

  function _acceptTerms() internal onlyGovernor {
    if (_proposedTerms.isEmpty()) {
      revert NoProposedTerms();
    }

    _proposedTerms.validate();

    _activeTerms.initFromTermsProposal(_proposedTerms);
    // clear it so that you can't re-accept the same terms
    // without the owner proposing them
    _proposedTerms.clear();

    emit TermsAccepted({
      from: msg.sender,
      swapper: _activeTerms.swapper,
      endTime: _activeTerms.endTime,
      lense: _activeTerms.lense,
      backstopPercentage: _activeTerms.backstopPercentage,
      maxBackstopAmount: _activeTerms.maxBackstopAmount
    });
  }

  /* ================================================================================
                                Swapper Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function previewSwapUsdcForFidu(uint256 usdcAmount)
    external
    view
    whileActive
    onlySwapper
    returns (uint256)
  {
    uint256 asFidu = _usdcToFidu(usdcAmount);
    if (usdcAmount > _activeTerms.backstopUsed || asFidu > fidu.balanceOf(address(this))) {
      revert InsufficientBalanceToSwap();
    }

    return asFidu;
  }

  /// @inheritdoc IBackstop
  function swapUsdcForFidu(uint256 usdcAmount) external onlySwapper whileActive returns (uint256) {
    if (usdcAmount == 0) {
      revert ZeroValueSwap();
    }

    uint256 fiduAmount = _usdcToFidu(usdcAmount);

    _activeTerms.backstopUsed -= usdcAmount;

    usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);
    fidu.safeTransfer(msg.sender, fiduAmount);

    emit SwapUsdcForFidu({from: msg.sender, usdcAmount: usdcAmount, fiduReceived: fiduAmount});

    return fiduAmount;
  }

  /// @inheritdoc IBackstop
  function previewSwapFiduForUsdc(uint256 fiduAmount)
    external
    view
    onlySwapper
    whileActive
    returns (uint256)
  {
    uint256 asUsdc = _fiduToUsdc(fiduAmount);
    if (asUsdc > backstopAvailable()) {
      revert InsufficientBalanceToSwap();
    }

    return asUsdc;
  }

  /// @inheritdoc IBackstop
  function swapFiduForUsdc(uint256 fiduAmount) external onlySwapper whileActive returns (uint256) {
    if (fiduAmount == 0) {
      revert ZeroValueSwap();
    }

    uint256 usdcAmount = _fiduToUsdc(fiduAmount);
    uint256 available = backstopAvailable();

    // If the amount received is 0 there's no point in doing the swap
    if (usdcAmount == 0) {
      revert ZeroValueSwap();
    }

    if (usdcAmount > available || available == 0) {
      revert InsufficientBalanceToSwap();
    }

    _activeTerms.backstopUsed += usdcAmount;

    fidu.safeTransferFrom(msg.sender, address(this), fiduAmount);
    usdc.safeTransfer(msg.sender, usdcAmount);

    emit SwapFiduForUsdc({from: msg.sender, fiduAmount: fiduAmount, usdcReceived: usdcAmount});
    return usdcAmount;
  }

  /* ================================================================================
                            Internal Functions
  ================================================================================ */

  function _usdcToFidu(uint256 fiduAmount) internal view returns (uint256) {
    return _activeTerms.lense.usdcToFidu(fiduAmount);
  }

  function _fiduToUsdc(uint256 usdcAmount) internal view returns (uint256) {
    return _activeTerms.lense.fiduToUsdc(usdcAmount);
  }

  /* ================================================================================
                                   Modifiers
  ================================================================================ */

  modifier onlyGovernor() {
    if (msg.sender != governor) {
      revert NotGovernor();
    }
    _;
  }

  modifier onlySwapper() {
    if (msg.sender != _activeTerms.swapper) {
      revert NotSwapper();
    }
    _;
  }

  modifier whileActive() {
    if (block.timestamp >= _activeTerms.endTime) {
      revert TermOver();
    }
    _;
  }

  /* ================================================================================
                                     Errors
  ================================================================================ */
  /// @notice Thrown when the governor is trying to accept a set of proposed terms that does not match what they expect
  error ProposedTermsDontMatch();
  /// @notice Thrown when the governor is trying to accept terms where none exist
  error NoProposedTerms();
  /// @notice Thrown when a function only callable by the governor is called by somebody else
  error NotGovernor();
  /// @notice Thrown when a function only callable by the swapper is called by somebody else
  error NotSwapper();
  /// @notice Thrown when a function is called that only applies during the term
  error TermOver();
  /// @notice Thrown when the swapper is attempting to swap fidu for USDC but does not have fidu holdings
  error InsufficientBalanceToSwap();
  /// @notice Thrown when a swap would result in
  error ZeroValueSwap();
}

library TermsLib {
  /// @notice Initialize a Terms struct using a TermsProposal struct
  function initFromTermsProposal(Terms storage t, TermsProposal storage p) internal {
    t.endTime = p.endTime;
    t.backstopPercentage = p.backstopPercentage;
    t.lense = p.lense;
    t.swapper = p.swapper;
    t.maxBackstopAmount = p.maxBackstopAmount;
    t.backstopUsed = 0;
  }
}

library TermsProposalLib {
  /// @notice Validate that a given TermsProposal struct has legal values. Revert if not
  function validate(TermsProposal memory t) internal view {
    bool endTimeIsInPast = t.endTime < block.timestamp;
    if (endTimeIsInPast) {
      revert ProposedEndTimeIsInPast();
    }

    bool lensIsNotAContract = !Address.isContract(address(t.lense));
    if (lensIsNotAContract) {
      revert LenseIsNotAContract();
    }

    bool swapperIsNull = t.swapper == address(0);
    if (swapperIsNull) {
      revert SwapperIsNullAddress();
    }

    bool backstopPercentageIsInvalid = t.backstopPercentage > 1e18 || t.backstopPercentage == 0;
    if (backstopPercentageIsInvalid) {
      revert InvalidBackstopPercentage();
    }
  }

  /// @notice Returns true if all of the fields of a TermsProposal are zero
  function isEmpty(TermsProposal storage t) internal view returns (bool) {
    return t.endTime == 0 && t.lense == IFiduLense(address(0)) && t.swapper == address(0)
      && t.backstopPercentage == 0 && t.maxBackstopAmount == 0;
  }

  /// @notice Returns true if two terms proposals are equal
  function eq(TermsProposal memory a, TermsProposal memory b) internal pure returns (bool) {
    return a.endTime == b.endTime && a.lense == b.lense && a.swapper == b.swapper
      && a.maxBackstopAmount == b.maxBackstopAmount && a.backstopPercentage == b.backstopPercentage;
  }

  /// @notice Zero out the storage variables of a terms proposal
  function clear(TermsProposal storage t) internal {
    t.endTime = 0;
    t.backstopPercentage = 0;
    t.lense = IFiduLense(address(0));
    t.swapper = address(0);
    t.maxBackstopAmount = 0;
  }

  error ProposedEndTimeIsInPast();
  error LenseIsNotAContract();
  error SwapperIsNullAddress();
  error InvalidBackstopPercentage();
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IERC165} from "./interfaces/IERC165.sol";
import {IERC173} from "./interfaces/IERC173.sol";

// NOTE: can we use the openzeppelin Ownable

contract Ownable is IERC173 {
  address public owner;

  constructor(address _owner) {
    owner = _owner;
  }

  /// @inheritdoc IERC173
  function transferOwnership(address _newOwner) external onlyOwner {
    address previousOwner = owner;
    owner = _newOwner;

    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return interfaceId == 0x7f5828d0;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert NotOwner();
    }
    _;
  }

  error NotOwner();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {IERC173} from "./IERC173.sol";
import {IFiduLense} from "./IFiduLense.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface IBackstop is IERC173 {
  /// @notice Returns the FIDU token contract address
  function fidu() external view returns (IERC20);

  /// @notice Returns the USDC token contract address
  function usdc() external view returns (IERC20);

  /* ================================================================================
                                     Terms
                               -----------------
  updating the terms of the backstop
  ================================================================================ */

  /**
   * @notice Propose new terms for the governor to accept
   * @dev only owner
   */
  function proposeTerms(TermsProposal calldata terms) external;

  /**
   * @notice Accept proposed terms and make them the active terms. Resets the proposed terms
   * @dev only governor
   */
  function acceptTerms() external;

  /**
   * @notice Returns the terms that are active. These terms control the parameters of the backstop
   */
  function activeTerms() external view returns (Terms memory);

  /**
   * @notice Returns the terms that are currently being proposed by the owner
   */
  function proposedTerms() external view returns (TermsProposal memory);

  /**
   * @notice Returns true if the backstop can still be swapped against
   */
  function isActive() external view returns (bool);

  /// @notice Returns the amount of backstop used
  function backstopUsed() external view returns (uint256);

  /// @notice Returns the amount of backstop available to the swapper,
  ///         accounting for their current position size.
  function backstopAvailable() external view returns (uint256);

  /* ================================================================================
                               Exchange functions
                               -----------------
  exchanging assets using the backstop
  ================================================================================ */

  /**
   * @notice Swap Usdc for Fidu using the current senior pool share price
   * @dev only swapper
   */
  function swapUsdcForFidu(uint256 usdcAmount) external returns (uint256);

  /**
   * @notice Returns the amount of FIDU received given a usdc amount
   */
  function previewSwapUsdcForFidu(uint256 usdcAmount) external returns (uint256);

  /**
   * @notice Swap Fidu for USDC using the current senior pool share price
   * @dev only swapper
   */
  function swapFiduForUsdc(uint256 fiduAmount) external returns (uint256);

  /**
   * @notice Returns the amount of usdc the received given a FIDU amount
   */
  function previewSwapFiduForUsdc(uint256 fiduAmount) external returns (uint256);

  /* ================================================================================
                               Funding functions
                               -----------------
  increasing or decreasing the balance of the backstop
  ================================================================================ */

  /**
   * @notice Withdraw any free FIDU and USDC. Only USDC above the backstop amount can be withdrawn
   * before the term end time. Fidu cannot be withdrawn before term end time.
   * @dev only owner
   */
  function sweep() external returns (uint256 amountUsdc, uint256 amountFidu);

  /**
   * @notice Returns the expected amount of FIDU and USDC that will be sent to
   * the caller of the sweep function
   */
  function previewSweep() external view returns (uint256 amountUsdc, uint256 amountFidu);

  /* ================================================================================
                            Access control functions
                            ------------------------
  Determining who has what role and transferring roles
  ================================================================================*/

  /**
   * @notice Returns the address that is permitted to exchange FIDU/USDC
   */
  function swapper() external view returns (address);

  /// @notice Returns the address that can set who the exchanger is
  function governor() external view returns (address);

  /**
   * @notice Transfer the governor role to another address
   */
  function transferGovernor(address addr) external;

  /* ================================================================================
                                     Events
  ================================================================================ */
  event GovernorTransferred(address indexed oldGovernor, address indexed newGovernor);

  /// @notice Emitted when USDC is swapped for FIDU
  /// @param usdcAmount amount of USDC swapped
  /// @param fiduReceived amount of FIDU received
  event SwapUsdcForFidu(address indexed from, uint256 usdcAmount, uint256 fiduReceived);

  /// @notice Emitted when FIDU for USDC is swapped
  /// @param from address that swapped
  /// @param fiduAmount amount of fidu that was swapped
  /// @param usdcReceived amount of usdc that was received
  event SwapFiduForUsdc(address indexed from, uint256 fiduAmount, uint256 usdcReceived);

  /// @notice Emitted when new terms are proposed
  /// @param from address that proposed the terms
  /// @param endTime term end time
  /// @param backstopPercentage value of swappers position needed to swap
  /// @param lense lense used for determining
  /// @param maxBackstopAmount backstop limit
  event TermsProposed(
    address indexed from,
    address swapper,
    uint64 endTime,
    uint64 backstopPercentage,
    IFiduLense lense,
    uint256 maxBackstopAmount
  );

  /// @notice Emitted when terms are accepted
  /// @param from address that accepted the terms
  /// @param endTime accepted end time
  /// @param backstopPercentage value of swappers position needed to swap
  /// @param lense lense contract
  /// @param maxBackstopAmount amount of backstop available
  event TermsAccepted(
    address indexed from,
    address swapper,
    uint64 endTime,
    uint64 backstopPercentage,
    IFiduLense lense,
    uint256 maxBackstopAmount
  );

  /// @notice Emitted when USDC is deposited into the contract
  event Deposit(address indexed from, uint256 amount);
  /// @notice Emitted when funds are swept from the contract
  event FundsSwept(address indexed from, uint256 usdcAmount, uint256 fiduAmount);
}

struct TermsProposal {
  /// @notice end of term. After the term end
  uint64 endTime;
  /// @notice lense contract for
  IFiduLense lense;
  /// @notice the address that can swap against the backstop
  address swapper;
  /// @notice Percentage of current position that will be backstopped
  uint64 backstopPercentage;
  /// @notice amount of backstop available
  uint256 maxBackstopAmount;
}

struct Terms {
  /// @notice end of term. After the term end
  uint64 endTime;
  /// @notice lense contract for
  IFiduLense lense;
  /// @notice the address that can swap against the backstop
  address swapper;
  /// @notice Percentage of current position that will be backstopped
  uint64 backstopPercentage;
  /// @notice amount of backstop that has been withdrawn
  uint256 backstopUsed;
  /// @notice amount of backstop available
  uint256 maxBackstopAmount;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {IERC165} from "./IERC165.sol";

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 is IERC165 {
  /// @dev This emits when ownership of a contract changes.
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @notice Get the address of the owner
  /// @return The address of the owner.
  function owner() external view returns (address);

  /// @notice Set the address of the new owner of the contract
  /// @dev Set _newOwner to address(0) to renounce any ownership.
  /// @param _newOwner The address of the new owner of the contract
  function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IFiduLense {
  /// @notice Returns the value of a given addresses FIDU holdings denominated in USDC
  ///           uses staked fidu and fidu held in wallet to determine position value.
  function fiduPositionValue(address addr) external view returns (uint256 usdcAmount);

  /// @notice Converts a given USDC amount to FIDU using the current FIDU share price
  function usdcToFidu(uint256 usdcAmount) external view returns (uint256 fiduAmount);

  /// @notice Converts a given amount of FIDU to USDC using the current FIDU share price
  function fiduToUsdc(uint256 fiduAmount) external view returns (uint256 usdcAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISeniorPool {
  function sharePrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

library SafeMathExt {
  uint256 private constant FP_DECIMALS = 1e18;

  /**
   * @notice Subtract, respecting numerical bounds of the type
   */
  function saturatingSub(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a - b : 0;
  }

  /// @notice Multiply two fixed point numbers, base 1e18
  function decMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / FP_DECIMALS;
  }

  function decDiv(uint256 divisor, uint256 dividend) internal pure returns (uint256) {
    uint256 preRound = (divisor * (FP_DECIMALS ** 2) / dividend);
    uint256 subPrecisionComponent = preRound % FP_DECIMALS;
    uint256 correction = subPrecisionComponent >= (FP_DECIMALS / 2) ? 1 : 0;
    return (preRound / FP_DECIMALS) + correction;
  }
}