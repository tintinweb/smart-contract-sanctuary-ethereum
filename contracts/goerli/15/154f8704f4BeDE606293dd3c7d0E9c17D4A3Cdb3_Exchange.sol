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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

import { Address } from '@openzeppelin/contracts/utils/Address.sol';
import { ECDSA } from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import { Validations } from './libraries/Validations.sol';
import { AssetRegistry } from './libraries/AssetRegistry.sol';
import { NonceInvalidations } from './libraries/NonceInvalidations.sol';
import { AssetTransfers } from './libraries/AssetTransfers.sol';
import { AssetUnitConversions } from './libraries/AssetUnitConversions.sol';
import { Owned } from './Owned.sol';
import { Signatures } from './libraries/Signatures.sol';
import { Enums, ICustodian, IERC20, IExchange, Structs } from './libraries/Interfaces.sol';
import { UUID } from './libraries/UUID.sol';

/**
 * @notice The Exchange contract. Implements all deposit, trade, and withdrawal logic and associated balance tracking
 *
 * @dev The term `asset` refers collectively to ETH and ERC-20 tokens, the term `token` refers only to the latter
 * @dev Events with indexed string parameters (Deposited and TradeExecuted) only log the hash values for those
 * parameters, from which the original raw string values cannot be retrieved. For convenience these events contain
 * the un-indexed string parameter values in addition to the indexed values
 */
contract Exchange is IExchange, Owned {
  using AssetRegistry for AssetRegistry.Storage;
  using NonceInvalidations for mapping(address => Structs.NonceInvalidation);

  // Events //

  /**
   * @notice Emitted when an admin changes the Chain Propagation Period tunable parameter with `setChainPropagationPeriod`
   */
  event ChainPropagationPeriodChanged(uint256 previousValue, uint256 newValue);
  /**
   * @notice Emitted when a user deposits ETH with `depositEther` or a token with `depositAsset` or `depositAssetBySymbol`
   */
  event Deposited(
    uint64 index,
    address indexed wallet,
    address indexed assetAddress,
    string indexed assetSymbolIndex,
    string assetSymbol,
    uint64 quantityInPips,
    uint64 newExchangeBalanceInPips,
    uint256 newExchangeBalanceInAssetUnits
  );
  /**
   * @notice Emitted when an admin changes the Dispatch Wallet tunable parameter with `setDispatcher`
   */
  event DispatcherChanged(address previousValue, address newValue);

  /**
   * @notice Emitted when an admin changes the Fee Wallet tunable parameter with `setFeeWallet`
   */
  event FeeWalletChanged(address previousValue, address newValue);

  /**
   * @notice Emitted when a user invalidates an order nonce with `invalidateOrderNonce`
   */
  event OrderNonceInvalidated(
    address indexed wallet,
    uint128 nonce,
    uint128 timestampInMs,
    uint256 effectiveBlockNumber
  );
  /**
   * @notice Emitted when an admin initiates the token registration process with `registerToken`
   */
  event TokenRegistered(
    IERC20 indexed assetAddress,
    string assetSymbol,
    uint8 decimals
  );
  /**
   * @notice Emitted when an admin finalizes the token registration process with `confirmAssetRegistration`, after
   * which it can be deposited, traded, or withdrawn
   */
  event TokenRegistrationConfirmed(
    IERC20 indexed assetAddress,
    string assetSymbol,
    uint8 decimals
  );
  /**
   * @notice Emitted when an admin adds a symbol to a previously registered and confirmed token
   * via `addTokenSymbol`
   */
  event TokenSymbolAdded(IERC20 indexed assetAddress, string assetSymbol);
  /**
   * @notice Emitted when the Dispatcher Wallet submits a trade for execution with `executeTrade`
   */
  event TradeExecuted(
    address buyWallet,
    address sellWallet,
    string indexed baseAssetSymbolIndex,
    string indexed quoteAssetSymbolIndex,
    string baseAssetSymbol,
    string quoteAssetSymbol,
    uint64 baseQuantityInPips,
    uint64 quoteQuantityInPips,
    uint64 tradePriceInPips,
    bytes32 buyOrderHash,
    bytes32 sellOrderHash
  );
  /**
   * @notice Emitted when a user invokes the Exit Wallet mechanism with `exitWallet`
   */
  event WalletExited(address indexed wallet, uint256 effectiveBlockNumber);
  /**
   * @notice Emitted when a user withdraws an asset balance through the Exit Wallet mechanism with `withdrawExit`
   */
  event WalletExitWithdrawn(
    address indexed wallet,
    address indexed assetAddress,
    string assetSymbol,
    uint64 quantityInPips,
    uint64 newExchangeBalanceInPips,
    uint256 newExchangeBalanceInAssetUnits
  );
  /**
   * @notice Emitted when a user clears the exited status of a wallet previously exited with `exitWallet`
   */
  event WalletExitCleared(address indexed wallet);
  /**
   * @notice Emitted when the Dispatcher Wallet submits a withdrawal with `withdraw`
   */
  event Withdrawn(
    address indexed wallet,
    address indexed assetAddress,
    string assetSymbol,
    uint64 quantityInPips,
    uint64 newExchangeBalanceInPips,
    uint256 newExchangeBalanceInAssetUnits
  );

  // Internally used structs //

  struct WalletExit {
    bool exists;
    uint256 effectiveBlockNumber;
  }

  // Storage //

  // Asset registry data
  AssetRegistry.Storage _assetRegistry;
  // Mapping of order wallet hash => isComplete
  mapping(bytes32 => bool) _completedOrderHashes;
  // Mapping of withdrawal wallet hash => isComplete
  mapping(bytes32 => bool) _completedWithdrawalHashes;
  address payable _custodian;
  uint64 _depositIndex;
  // Mapping of wallet => asset => balance
  mapping(address => mapping(address => uint64)) _balancesInPips;
  // Mapping of wallet => last invalidated timestampInMs
  mapping(address => Structs.NonceInvalidation) _nonceInvalidations;
  // Mapping of order hash => filled quantity in pips
  mapping(bytes32 => uint64) _partiallyFilledOrderQuantitiesInPips;
  mapping(address => WalletExit) _walletExits;
  // Tunable parameters
  uint256 _chainPropagationPeriod;
  address _dispatcherWallet;
  address _feeWallet;

  // Constant values //

  uint256 constant _maxChainPropagationPeriod = (7 * 24 * 60 * 60) / 15; // 1 week at 15s/block
  uint64 constant _maxWithdrawalFeeBasisPoints = 20 * 100; // 20%;

  /**
   * @notice Instantiate a new `Exchange` contract
   *
   * @dev Sets `_owner` and `_admin` to `msg.sender` */
  constructor() Owned() {}

  /**
   * @notice Sets the address of the `Custodian` contract
   *
   * @dev The `Custodian` accepts `Exchange` and `Governance` addresses in its constructor, after
   * which they can only be changed by the `Governance` contract itself. Therefore the `Custodian`
   * must be deployed last and its address set here on an existing `Exchange` contract. This value
   * is immutable once set and cannot be changed again
   *
   * @param newCustodian The address of the `Custodian` contract deployed against this `Exchange`
   * contract's address
   */
  function setCustodian(address payable newCustodian) external onlyAdmin {
    require(_custodian == address(0x0), 'Custodian can only be set once');
    require(Address.isContract(newCustodian), 'Invalid address');

    _custodian = newCustodian;
  }

  /*** Tunable parameters ***/

  /**
   * @notice Sets a new Chain Propagation Period - the block delay after which order nonce invalidations
   * are respected by `executeTrade` and wallet exits are respected by `executeTrade` and `withdraw`
   *
   * @param newChainPropagationPeriod The new Chain Propagation Period expressed as a number of blocks. Must
   * be less than `_maxChainPropagationPeriod`
   */
  function setChainPropagationPeriod(
    uint256 newChainPropagationPeriod
  ) external onlyAdmin {
    require(
      newChainPropagationPeriod < _maxChainPropagationPeriod,
      'Must be less than 1 week'
    );

    uint256 oldChainPropagationPeriod = _chainPropagationPeriod;
    _chainPropagationPeriod = newChainPropagationPeriod;

    emit ChainPropagationPeriodChanged(
      oldChainPropagationPeriod,
      newChainPropagationPeriod
    );
  }

  /**
   * @notice Sets the address of the Fee wallet
   *
   * @dev Trade and Withdraw fees will accrue in the `_balancesInPips` mappings for this wallet
   *
   * @param newFeeWallet The new Fee wallet. Must be different from the current one
   */
  function setFeeWallet(address newFeeWallet) external onlyAdmin {
    require(newFeeWallet != address(0x0), 'Invalid wallet address');
    require(
      newFeeWallet != _feeWallet,
      'Must be different from current fee wallet'
    );

    address oldFeeWallet = _feeWallet;
    _feeWallet = newFeeWallet;

    emit FeeWalletChanged(oldFeeWallet, newFeeWallet);
  }

  // Accessors //

  /**
   * @notice Load a wallet's balance by asset address, in asset units
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetAddress The asset address to load the wallet's balance for
   *
   * @return The quantity denominated in asset units of asset at `assetAddress` currently
   * deposited by `wallet`
   */
  function loadBalanceInAssetUnitsByAddress(
    address wallet,
    address assetAddress
  ) external view returns (uint256) {
    require(wallet != address(0x0), 'Invalid wallet address');

    Structs.Asset memory asset = _assetRegistry.loadAssetByAddress(
      assetAddress
    );
    return
      AssetUnitConversions.pipsToAssetUnits(
        _balancesInPips[wallet][assetAddress],
        asset.decimals
      );
  }

  /**
   * @notice Load a wallet's balance by asset address, in asset units
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetSymbol The asset symbol to load the wallet's balance for
   *
   * @return The quantity denominated in asset units of asset `assetSymbol` currently deposited
   * by `wallet`
   */
  function loadBalanceInAssetUnitsBySymbol(
    address wallet,
    string calldata assetSymbol
  ) external view returns (uint256) {
    require(wallet != address(0x0), 'Invalid wallet address');

    Structs.Asset memory asset = _assetRegistry.loadAssetBySymbol(
      assetSymbol,
      getCurrentTimestampInMs()
    );
    return
      AssetUnitConversions.pipsToAssetUnits(
        _balancesInPips[wallet][asset.assetAddress],
        asset.decimals
      );
  }

  /**
   * @notice Load a wallet's balance by asset address, in pips
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetAddress The asset address to load the wallet's balance for
   *
   * @return The quantity denominated in pips of asset at `assetAddress` currently deposited by `wallet`
   */
  function loadBalanceInPipsByAddress(
    address wallet,
    address assetAddress
  ) external view returns (uint64) {
    require(wallet != address(0x0), 'Invalid wallet address');

    return _balancesInPips[wallet][assetAddress];
  }

  /**
   * @notice Load a wallet's balance by asset symbol, in pips
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetSymbol The asset symbol to load the wallet's balance for
   *
   * @return The quantity denominated in pips of asset with `assetSymbol` currently deposited by `wallet`
   */
  function loadBalanceInPipsBySymbol(
    address wallet,
    string calldata assetSymbol
  ) external view returns (uint64) {
    require(wallet != address(0x0), 'Invalid wallet address');

    address assetAddress = _assetRegistry
      .loadAssetBySymbol(assetSymbol, getCurrentTimestampInMs())
      .assetAddress;
    return _balancesInPips[wallet][assetAddress];
  }

  /**
   * @notice Load the address of the Fee wallet
   *
   * @return The address of the Fee wallet
   */
  function loadFeeWallet() external view returns (address) {
    return _feeWallet;
  }

  /**
   * @notice Load the quantity filled so far for a partially filled orders

   * @dev Invalidating an order nonce will not clear partial fill quantities for earlier orders because
   * the gas cost would potentially be unbound
   *
   * @param orderHash The order hash as originally signed by placing wallet that uniquely identifies an order
   *
   * @return For partially filled orders, the amount filled so far in pips. For orders in all other states, 0
   */
  function loadPartiallyFilledOrderQuantityInPips(
    bytes32 orderHash
  ) external view returns (uint64) {
    return _partiallyFilledOrderQuantitiesInPips[orderHash];
  }

  // Depositing //

  /**
   * @notice Deposit ETH
   */
  function depositEther() external payable {
    deposit(payable(msg.sender), address(0x0), msg.value);
  }

  /**
   * @notice Deposit `IERC20` compliant tokens
   *
   * @param tokenAddress The token contract address
   * @param quantityInAssetUnits The quantity to deposit. The sending wallet must first call the `approve` method on
   * the token contract for at least this quantity first
   */
  function depositTokenByAddress(
    IERC20 tokenAddress,
    uint256 quantityInAssetUnits
  ) external {
    require(
      address(tokenAddress) != address(0x0),
      'Use depositEther to deposit Ether'
    );
    deposit(payable(msg.sender), address(tokenAddress), quantityInAssetUnits);
  }

  /**
   * @notice Deposit `IERC20` compliant tokens
   *
   * @param assetSymbol The case-sensitive symbol string for the token
   * @param quantityInAssetUnits The quantity to deposit. The sending wallet must first call the `approve` method on
   * the token contract for at least this quantity first
   */
  function depositTokenBySymbol(
    string calldata assetSymbol,
    uint256 quantityInAssetUnits
  ) external {
    IERC20 tokenAddress = IERC20(
      _assetRegistry
        .loadAssetBySymbol(assetSymbol, getCurrentTimestampInMs())
        .assetAddress
    );
    require(
      address(tokenAddress) != address(0x0),
      'Use depositEther to deposit ETH'
    );

    deposit(payable(msg.sender), address(tokenAddress), quantityInAssetUnits);
  }

  function deposit(
    address payable wallet,
    address assetAddress,
    uint256 quantityInAssetUnits
  ) private {
    // Calling exitWallet disables deposits immediately on mining, in contrast to withdrawals and
    // trades which respect the Chain Propagation Period given by `effectiveBlockNumber` via
    // `isWalletExitFinalized`
    require(!_walletExits[wallet].exists, 'Wallet exited');

    Structs.Asset memory asset = _assetRegistry.loadAssetByAddress(
      assetAddress
    );
    uint64 quantityInPips = AssetUnitConversions.assetUnitsToPips(
      quantityInAssetUnits,
      asset.decimals
    );
    require(quantityInPips > 0, 'Quantity is too low');

    // Convert from pips back into asset units to remove any fractional amount that is too small
    // to express in pips. If the asset is ETH, this leftover fractional amount accumulates as dust
    // in the `Exchange` contract. If the asset is a token the `Exchange` will call `transferFrom`
    // without this fractional amount and there will be no dust
    uint256 quantityInAssetUnitsWithoutFractionalPips = AssetUnitConversions
      .pipsToAssetUnits(quantityInPips, asset.decimals);

    // If the asset is ETH then the funds were already assigned to this contract via msg.value. If
    // the asset is a token, additionally call the transferFrom function on the token contract for
    // the pre-approved asset quantity
    if (assetAddress != address(0x0)) {
      AssetTransfers.transferFrom(
        wallet,
        IERC20(assetAddress),
        quantityInAssetUnitsWithoutFractionalPips
      );
    }
    // Forward the funds to the `Custodian`
    AssetTransfers.transferTo(
      _custodian,
      assetAddress,
      quantityInAssetUnitsWithoutFractionalPips
    );

    uint64 newExchangeBalanceInPips = _balancesInPips[wallet][assetAddress] +
      quantityInPips;
    uint256 newExchangeBalanceInAssetUnits = AssetUnitConversions
      .pipsToAssetUnits(newExchangeBalanceInPips, asset.decimals);

    // Update balance with actual transferred quantity
    _balancesInPips[wallet][assetAddress] = newExchangeBalanceInPips;
    _depositIndex++;

    emit Deposited(
      _depositIndex,
      wallet,
      assetAddress,
      asset.symbol,
      asset.symbol,
      quantityInPips,
      newExchangeBalanceInPips,
      newExchangeBalanceInAssetUnits
    );
  }

  // Invalidation //

  /**
   * @notice Invalidate all order nonces with a timestampInMs lower than the one provided
   *
   * @param nonce A Version 1 UUID. After calling and once the Chain Propagation Period has
   * elapsed, `executeOrderBookTrade` will reject order nonces from this wallet with a
   * timestampInMs component lower than the one provided
   */
  function invalidateOrderNonce(uint128 nonce) external {
    (uint64 timestampInMs, uint256 effectiveBlockNumber) = _nonceInvalidations
      .invalidateOrderNonce(nonce, _chainPropagationPeriod);

    emit OrderNonceInvalidated(
      msg.sender,
      nonce,
      timestampInMs,
      effectiveBlockNumber
    );
  }

  // Withdrawing //

  /**
   * @notice Settles a user withdrawal submitted off-chain. Calls restricted to currently whitelisted Dispatcher wallet
   *
   * @param withdrawal A `Structs.Withdrawal` struct encoding the parameters of the withdrawal
   */
  function withdraw(
    Structs.Withdrawal memory withdrawal
  ) public override onlyDispatcher {
    // Validations
    require(!isWalletExitFinalized(withdrawal.walletAddress), 'Wallet exited');
    require(
      Validations.getFeeBasisPoints(
        withdrawal.gasFeeInPips,
        withdrawal.quantityInPips
      ) <= _maxWithdrawalFeeBasisPoints,
      'Excessive withdrawal fee'
    );
    bytes32 withdrawalHash = Validations.validateWithdrawalSignature(
      withdrawal
    );
    require(
      !_completedWithdrawalHashes[withdrawalHash],
      'Hash already withdrawn'
    );

    // If withdrawal is by asset symbol (most common) then resolve to asset address
    Structs.Asset memory asset = withdrawal.withdrawalType ==
      Enums.WithdrawalType.BySymbol
      ? _assetRegistry.loadAssetBySymbol(
        withdrawal.assetSymbol,
        UUID.getTimestampInMsFromUuidV1(withdrawal.nonce)
      )
      : _assetRegistry.loadAssetByAddress(withdrawal.assetAddress);

    // SafeMath reverts if balance is overdrawn
    uint64 netAssetQuantityInPips = withdrawal.quantityInPips - withdrawal.gasFeeInPips;
    uint256 netAssetQuantityInAssetUnits = AssetUnitConversions
      .pipsToAssetUnits(netAssetQuantityInPips, asset.decimals);
    uint64 newExchangeBalanceInPips = _balancesInPips[withdrawal.walletAddress][
      asset.assetAddress
    ] - withdrawal.quantityInPips;
    uint256 newExchangeBalanceInAssetUnits = AssetUnitConversions
      .pipsToAssetUnits(newExchangeBalanceInPips, asset.decimals);

    _balancesInPips[withdrawal.walletAddress][
      asset.assetAddress
    ] = newExchangeBalanceInPips;
    _balancesInPips[_feeWallet][asset.assetAddress] =
      _balancesInPips[_feeWallet][asset.assetAddress] +
      withdrawal.gasFeeInPips;

    ICustodian(_custodian).withdraw(
      withdrawal.walletAddress,
      asset.assetAddress,
      netAssetQuantityInAssetUnits
    );

    _completedWithdrawalHashes[withdrawalHash] = true;

    emit Withdrawn(
      withdrawal.walletAddress,
      asset.assetAddress,
      asset.symbol,
      withdrawal.quantityInPips,
      newExchangeBalanceInPips,
      newExchangeBalanceInAssetUnits
    );
  }

  // Wallet exits //

  /**
   * @notice Flags the sending wallet as exited, immediately disabling deposits upon mining.
   * After the Chain Propagation Period passes trades and withdrawals are also disabled for the wallet,
   * and assets may then be withdrawn one at a time via `withdrawExit`
   */
  function exitWallet() external {
    require(!_walletExits[msg.sender].exists, 'Wallet already exited');

    _walletExits[msg.sender] = WalletExit(
      true,
      block.number + _chainPropagationPeriod
    );

    emit WalletExited(msg.sender, block.number + _chainPropagationPeriod);
  }

  /**
   * @notice Withdraw the entire balance of an asset for an exited wallet. The Chain Propagation Period must
   * have already passed since calling `exitWallet` on `assetAddress`
   *
   * @param assetAddress The address of the asset to withdraw
   */
  function withdrawExit(address assetAddress) external {
    require(isWalletExitFinalized(msg.sender), 'Wallet exit not finalized');

    Structs.Asset memory asset = _assetRegistry.loadAssetByAddress(
      assetAddress
    );
    uint64 balanceInPips = _balancesInPips[msg.sender][assetAddress];
    uint256 balanceInAssetUnits = AssetUnitConversions.pipsToAssetUnits(
      balanceInPips,
      asset.decimals
    );

    require(balanceInAssetUnits > 0, 'No balance for asset');
    _balancesInPips[msg.sender][assetAddress] = 0;
    ICustodian(_custodian).withdraw(
      payable(msg.sender),
      assetAddress,
      balanceInAssetUnits
    );

    emit WalletExitWithdrawn(
      msg.sender,
      assetAddress,
      asset.symbol,
      balanceInPips,
      0,
      0
    );
  }

  /**
   * @notice Clears exited status of sending wallet. Upon mining immediately enables
   * deposits, trades, and withdrawals by sending wallet
   */
  function clearWalletExit() external {
    require(_walletExits[msg.sender].exists, 'Wallet not exited');

    delete _walletExits[msg.sender];

    emit WalletExitCleared(msg.sender);
  }

  function isWalletExitFinalized(address wallet) internal view returns (bool) {
    WalletExit storage exit = _walletExits[wallet];
    return exit.exists && exit.effectiveBlockNumber <= block.number;
  }

  // Trades //

  /**
   * @notice Settles a trade between two orders submitted and matched off-chain
   *
   * @dev As a gas optimization, base and quote symbols are passed in separately and combined to verify
   * the wallet hash, since this is cheaper than splitting the market symbol into its two constituent asset symbols
   * @dev Stack level too deep if declared external
   *
   * @param buy A `Structs.Order` struct encoding the parameters of the buy-side order (receiving base, giving quote)
   * @param sell A `Structs.Order` struct encoding the parameters of the sell-side order (giving base, receiving quote)
   * @param trade A `Structs.Trade` struct encoding the parameters of this trade execution of the counterparty orders
   */
  function executeTrade(
    Structs.Order memory buy,
    Structs.Order memory sell,
    Structs.Trade memory trade
  ) public override onlyDispatcher {
    require(
      !isWalletExitFinalized(buy.walletAddress),
      'Buy wallet exit finalized'
    );
    require(
      !isWalletExitFinalized(sell.walletAddress),
      'Sell wallet exit finalized'
    );
    require(
      buy.walletAddress != sell.walletAddress,
      'Self-trading not allowed'
    );

    validateAssetPair(buy, sell, trade);
    Validations.validateLimitPrices(buy, sell, trade);
    Validations.validateOrderNonces(buy, sell, _nonceInvalidations);
    (bytes32 buyHash, bytes32 sellHash) = Validations.validateOrderSignatures(
      buy,
      sell,
      trade
    );
    Validations.validateTradeFees(trade);

    updateOrderFilledQuantities(buy, buyHash, sell, sellHash, trade);
    updateBalancesForTrade(buy, sell, trade);

    emit TradeExecuted(
      buy.walletAddress,
      sell.walletAddress,
      trade.baseAssetSymbol,
      trade.quoteAssetSymbol,
      trade.baseAssetSymbol,
      trade.quoteAssetSymbol,
      trade.grossBaseQuantityInPips,
      trade.grossQuoteQuantityInPips,
      trade.priceInPips,
      buyHash,
      sellHash
    );
  }

  // Updates buyer, seller, and fee wallet balances for both assets in trade pair according to trade parameters
  function updateBalancesForTrade(
    Structs.Order memory buy,
    Structs.Order memory sell,
    Structs.Trade memory trade
  ) private {
    // Seller gives base asset including fees
    _balancesInPips[sell.walletAddress][
      trade.baseAssetAddress
    ] = _balancesInPips[sell.walletAddress][trade.baseAssetAddress] - trade.grossBaseQuantityInPips;
    // Buyer receives base asset minus fees
    _balancesInPips[buy.walletAddress][
      trade.baseAssetAddress
    ] = _balancesInPips[buy.walletAddress][trade.baseAssetAddress] + trade.netBaseQuantityInPips;

    // Buyer gives quote asset including fees
    _balancesInPips[buy.walletAddress][
      trade.quoteAssetAddress
    ] = _balancesInPips[buy.walletAddress][trade.quoteAssetAddress] - trade.grossQuoteQuantityInPips;
    // Seller receives quote asset minus fees
    _balancesInPips[sell.walletAddress][
      trade.quoteAssetAddress
    ] = _balancesInPips[sell.walletAddress][trade.quoteAssetAddress] + trade.netQuoteQuantityInPips;

    // Maker and taker fees to fee wallet
    _balancesInPips[_feeWallet][trade.makerFeeAssetAddress] = _balancesInPips[_feeWallet][trade.makerFeeAssetAddress] + trade.makerFeeQuantityInPips;
    _balancesInPips[_feeWallet][trade.takerFeeAssetAddress] = _balancesInPips[_feeWallet][trade.takerFeeAssetAddress] + trade.takerFeeQuantityInPips;
  }

  function updateOrderFilledQuantities(
    Structs.Order memory buyOrder,
    bytes32 buyOrderHash,
    Structs.Order memory sellOrder,
    bytes32 sellOrderHash,
    Structs.Trade memory trade
  ) private {
    updateOrderFilledQuantity(buyOrder, buyOrderHash, trade);
    updateOrderFilledQuantity(sellOrder, sellOrderHash, trade);
  }

  // Update filled quantities tracking for order to prevent over- or double-filling orders
  function updateOrderFilledQuantity(
    Structs.Order memory order,
    bytes32 orderHash,
    Structs.Trade memory trade
  ) private {
    require(!_completedOrderHashes[orderHash], 'Order double filled');

    // Total quantity of above filled as a result of all trade executions, including this one
    uint64 newFilledQuantityInPips;

    // Market orders can express quantity in quote terms, and can be partially filled by multiple
    // limit maker orders necessitating tracking partially filled amounts in quote terms to
    // determine completion
    if (order.isQuantityInQuote) {
      require(
        Validations.isMarketOrderType(order.orderType),
        'Order quote quantity only valid for market orders'
      );
      newFilledQuantityInPips = trade.grossQuoteQuantityInPips + _partiallyFilledOrderQuantitiesInPips[orderHash];
    } else {
      // All other orders track partially filled quantities in base terms
      newFilledQuantityInPips = trade.grossBaseQuantityInPips + _partiallyFilledOrderQuantitiesInPips[orderHash];
    }

    require(
      newFilledQuantityInPips <= order.quantityInPips,
      'Order overfilled'
    );

    if (newFilledQuantityInPips < order.quantityInPips) {
      // If the order was partially filled, track the new filled quantity
      _partiallyFilledOrderQuantitiesInPips[
        orderHash
      ] = newFilledQuantityInPips;
    } else {
      // If the order was completed, delete any partial fill tracking and instead track its completion
      // to prevent future double fills
      delete _partiallyFilledOrderQuantitiesInPips[orderHash];
      _completedOrderHashes[orderHash] = true;
    }
  }

  // Validations //

  function validateAssetPair(
    Structs.Order memory buy,
    Structs.Order memory sell,
    Structs.Trade memory trade
  ) private view {
    require(
      trade.baseAssetAddress != trade.quoteAssetAddress,
      'Base and quote assets must be different'
    );

    // Buy order market pair
    Structs.Asset memory buyBaseAsset = _assetRegistry.loadAssetBySymbol(
      trade.baseAssetSymbol,
      UUID.getTimestampInMsFromUuidV1(buy.nonce)
    );
    Structs.Asset memory buyQuoteAsset = _assetRegistry.loadAssetBySymbol(
      trade.quoteAssetSymbol,
      UUID.getTimestampInMsFromUuidV1(buy.nonce)
    );
    require(
      buyBaseAsset.assetAddress == trade.baseAssetAddress &&
        buyQuoteAsset.assetAddress == trade.quoteAssetAddress,
      'Buy order market symbol address resolution mismatch'
    );

    // Sell order market pair
    Structs.Asset memory sellBaseAsset = _assetRegistry.loadAssetBySymbol(
      trade.baseAssetSymbol,
      UUID.getTimestampInMsFromUuidV1(sell.nonce)
    );
    Structs.Asset memory sellQuoteAsset = _assetRegistry.loadAssetBySymbol(
      trade.quoteAssetSymbol,
      UUID.getTimestampInMsFromUuidV1(sell.nonce)
    );
    require(
      sellBaseAsset.assetAddress == trade.baseAssetAddress &&
        sellQuoteAsset.assetAddress == trade.quoteAssetAddress,
      'Sell order market symbol address resolution mismatch'
    );

    // Fee asset validation
    require(
      trade.makerFeeAssetAddress == trade.baseAssetAddress ||
        trade.makerFeeAssetAddress == trade.quoteAssetAddress,
      'Maker fee asset is not in trade pair'
    );
    require(
      trade.takerFeeAssetAddress == trade.baseAssetAddress ||
        trade.takerFeeAssetAddress == trade.quoteAssetAddress,
      'Taker fee asset is not in trade pair'
    );
    require(
      trade.makerFeeAssetAddress != trade.takerFeeAssetAddress,
      'Maker and taker fee assets must be different'
    );
  }

  // Asset registry //

  /**
   * @notice Initiate registration process for a token asset. Only `IERC20` compliant tokens can be
   * added - ETH is hardcoded in the registry
   *
   * @param tokenAddress The address of the `IERC20` compliant token contract to add
   * @param symbol The symbol identifying the token asset
   * @param decimals The decimal precision of the token
   */
  function registerToken(
    IERC20 tokenAddress,
    string calldata symbol,
    uint8 decimals
  ) external onlyAdmin {
    _assetRegistry.registerToken(tokenAddress, symbol, decimals);
    emit TokenRegistered(tokenAddress, symbol, decimals);
  }

  /**
   * @notice Finalize registration process for a token asset. All parameters must exactly match a previous
   * call to `registerToken`
   *
   * @param tokenAddress The address of the `IERC20` compliant token contract to add
   * @param symbol The symbol identifying the token asset
   * @param decimals The decimal precision of the token
   */
  function confirmTokenRegistration(
    IERC20 tokenAddress,
    string calldata symbol,
    uint8 decimals
  ) external onlyAdmin {
    _assetRegistry.confirmTokenRegistration(tokenAddress, symbol, decimals);
    emit TokenRegistrationConfirmed(tokenAddress, symbol, decimals);
  }

  /**
   * @notice Add a symbol to a token that has already been registered and confirmed
   *
   * @param tokenAddress The address of the `IERC20` compliant token contract the symbol will identify
   * @param symbol The symbol identifying the token asset
   */
  function addTokenSymbol(
    IERC20 tokenAddress,
    string calldata symbol
  ) external onlyAdmin {
    _assetRegistry.addTokenSymbol(tokenAddress, symbol);
    emit TokenSymbolAdded(tokenAddress, symbol);
  }

  /**
   * @notice Loads an asset descriptor struct by its symbol and timestamp
   *
   * @dev Since multiple token addresses can potentially share the same symbol (in case of a token
   * swap/contract upgrade) the provided `timestampInMs` is compared against each asset's
   * `confirmedTimestampInMs` to uniquely determine the newest asset for the symbol at that point in time
   *
   * @param assetSymbol The asset's symbol
   * @param timestampInMs Point in time used to disambiguate multiple tokens with same symbol
   *
   * @return A `Structs.Asset` record describing the asset
   */
  function loadAssetBySymbol(
    string calldata assetSymbol,
    uint64 timestampInMs
  ) external view returns (Structs.Asset memory) {
    return _assetRegistry.loadAssetBySymbol(assetSymbol, timestampInMs);
  }

  // Dispatcher whitelisting //

  /**
   * @notice Sets the wallet whitelisted to dispatch transactions calling the `executeTrade` and `withdraw` functions
   *
   * @param newDispatcherWallet The new whitelisted dispatcher wallet. Must be different from the current one
   */
  function setDispatcher(address newDispatcherWallet) external onlyAdmin {
    require(newDispatcherWallet != address(0x0), 'Invalid wallet address');
    require(
      newDispatcherWallet != _dispatcherWallet,
      'Must be different from current dispatcher'
    );
    address oldDispatcherWallet = _dispatcherWallet;
    _dispatcherWallet = newDispatcherWallet;

    emit DispatcherChanged(oldDispatcherWallet, newDispatcherWallet);
  }

  /**
   * @notice Clears the currently set whitelisted dispatcher wallet, effectively disabling calling the
   * `executeTrade` and `withdraw` functions until a new wallet is set with `setDispatcher`
   */
  function removeDispatcher() external onlyAdmin {
    emit DispatcherChanged(_dispatcherWallet, address(0x0));
    _dispatcherWallet = address(0x0);
  }

  modifier onlyDispatcher() {
    require(msg.sender == _dispatcherWallet, 'Caller is not dispatcher');
    _;
  }

  // Utils //

  function getCurrentTimestampInMs() private view returns (uint64) {
    uint64 msInOneSecond = 1000;

    return uint64(block.timestamp) * msInOneSecond;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

import { Address } from '@openzeppelin/contracts/utils/Address.sol';

import { IERC20, Structs } from './Interfaces.sol';


/**
 * @notice Library helper functions for managing a registry of asset descriptors indexed by address and symbol
 */
library AssetRegistry {
  struct Storage {
    mapping(address => Structs.Asset) assetsByAddress;
    // Mapping value is array since the same symbol can be re-used for a different address
    // (usually as a result of a token swap or upgrade)
    mapping(string => Structs.Asset[]) assetsBySymbol;
  }

  function registerToken(
    Storage storage self,
    IERC20 tokenAddress,
    string memory symbol,
    uint8 decimals
  ) internal {
    require(decimals <= 32, 'Token cannot have more than 32 decimals');
    require(
      tokenAddress != IERC20(address(0x0)) && Address.isContract(address(tokenAddress)),
      'Invalid token address'
    );
    // The string type does not have a length property so cast to bytes to check for empty string
    require(bytes(symbol).length > 0, 'Invalid token symbol');
    require(
      !self.assetsByAddress[address(tokenAddress)].isConfirmed,
      'Token already finalized'
    );

    self.assetsByAddress[address(tokenAddress)] = Structs.Asset({
      exists: true,
      assetAddress: address(tokenAddress),
      symbol: symbol,
      decimals: decimals,
      isConfirmed: false,
      confirmedTimestampInMs: 0
    });
  }

  function confirmTokenRegistration(
    Storage storage self,
    IERC20 tokenAddress,
    string memory symbol,
    uint8 decimals
  ) internal {
    Structs.Asset memory asset = self.assetsByAddress[address(tokenAddress)];
    require(asset.exists, 'Unknown token');
    require(!asset.isConfirmed, 'Token already finalized');
    require(isStringEqual(asset.symbol, symbol), 'Symbols do not match');
    require(asset.decimals == decimals, 'Decimals do not match');

    asset.isConfirmed = true;
    asset.confirmedTimestampInMs = uint64(block.timestamp * 1000); // Block timestamp is in seconds, store ms
    self.assetsByAddress[address(tokenAddress)] = asset;
    self.assetsBySymbol[symbol].push(asset);
  }

  function addTokenSymbol(
    Storage storage self,
    IERC20 tokenAddress,
    string memory symbol
  ) internal {
    Structs.Asset memory asset = self.assetsByAddress[address(tokenAddress)];
    require(
      asset.exists && asset.isConfirmed,
      'Registration of token not finalized'
    );
    require(!isStringEqual(symbol, 'ETH'), 'ETH symbol reserved for Ether');

    // This will prevent swapping assets for previously existing orders
    uint64 msInOneSecond = 1000;
    asset.confirmedTimestampInMs = uint64(block.timestamp * msInOneSecond);

    self.assetsBySymbol[symbol].push(asset);
  }

  /**
   * @dev Resolves an asset address into corresponding Asset struct
   *
   * @param assetAddress Ethereum address of asset
   */
  function loadAssetByAddress(Storage storage self, address assetAddress)
    internal
    view
    returns (Structs.Asset memory)
  {
    if (assetAddress == address(0x0)) {
      return getEthAsset();
    }

    Structs.Asset memory asset = self.assetsByAddress[assetAddress];
    require(
      asset.exists && asset.isConfirmed,
      'No confirmed asset found for address'
    );

    return asset;
  }

  /**
   * @dev Resolves a asset symbol into corresponding Asset struct
   *
   * @param symbol Asset symbol, e.g. 'IDEX'
   * @param timestampInMs Milliseconds since Unix epoch, usually parsed from a UUID v1 order nonce.
   * Constrains symbol resolution to the asset most recently confirmed prior to timestampInMs. Reverts
   * if no such asset exists
   */
  function loadAssetBySymbol(
    Storage storage self,
    string memory symbol,
    uint64 timestampInMs
  ) internal view returns (Structs.Asset memory) {
    if (isStringEqual('ETH', symbol)) {
      return getEthAsset();
    }

    Structs.Asset memory asset;
    if (self.assetsBySymbol[symbol].length > 0) {
      for (uint8 i = 0; i < self.assetsBySymbol[symbol].length; i++) {
        if (
          self.assetsBySymbol[symbol][i].confirmedTimestampInMs <= timestampInMs
        ) {
          asset = self.assetsBySymbol[symbol][i];
        }
      }
    }
    require(
      asset.exists && asset.isConfirmed,
      'No confirmed asset found for symbol'
    );

    return asset;
  }

  /**
   * @dev ETH is modeled as an always-confirmed Asset struct for programmatic consistency
   */
  function getEthAsset() private pure returns (Structs.Asset memory) {
    return Structs.Asset(true, address(0x0), 'ETH', 18, true, 0);
  }

  // See https://solidity.readthedocs.io/en/latest/types.html#bytes-and-strings-as-arrays
  function isStringEqual(string memory a, string memory b)
    private
    pure
    returns (bool)
  {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

import { IERC20 } from './Interfaces.sol';


/**
 * @notice This library provides helper utilities for transfering assets in and out of contracts.
 * It further validates ERC-20 compliant balance updates in the case of token assets
 */
library AssetTransfers {
  /**
   * @dev Transfers tokens from a wallet into a contract during deposits. `wallet` must already
   * have called `approve` on the token contract for at least `tokenQuantity`. Note this only
   * applies to tokens since ETH is sent in the deposit transaction via `msg.value`
   */
  function transferFrom(
    address wallet,
    IERC20 tokenAddress,
    uint256 quantityInAssetUnits
  ) internal {
    uint256 balanceBefore = tokenAddress.balanceOf(address(this));

    // Because we check for the expected balance change we can safely ignore the return value of transferFrom
    tokenAddress.transferFrom(wallet, address(this), quantityInAssetUnits);

    uint256 balanceAfter = tokenAddress.balanceOf(address(this));
    require(
      balanceAfter - balanceBefore == quantityInAssetUnits,
      'Token contract returned transferFrom success without expected balance change'
    );
  }

  /**
   * @dev Transfers ETH or token assets from a contract to 1) another contract, when `Exchange`
   * forwards funds to `Custodian` during deposit or 2) a wallet, when withdrawing
   */
  function transferTo(
    address payable walletOrContract,
    address asset,
    uint256 quantityInAssetUnits
  ) internal {
    if (asset == address(0x0)) {
      require(
        walletOrContract.send(quantityInAssetUnits),
        'ETH transfer failed'
      );
    } else {
      uint256 balanceBefore = IERC20(asset).balanceOf(walletOrContract);

      // Because we check for the expected balance change we can safely ignore the return value of transfer
      IERC20(asset).transfer(walletOrContract, quantityInAssetUnits);

      uint256 balanceAfter = IERC20(asset).balanceOf(walletOrContract);
      require(
        balanceAfter - balanceBefore == quantityInAssetUnits,
        'Token contract returned transfer success without expected balance change'
      );
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

/**
 * @notice Library helpers for converting asset quantities between asset units and pips
 */
library AssetUnitConversions {

  function pipsToAssetUnits(uint64 quantityInPips, uint8 assetDecimals)
    internal
    pure
    returns (uint256)
  {
    require(assetDecimals <= 32, 'Asset cannot have more than 32 decimals');

    // Exponents cannot be negative, so divide or multiply based on exponent signedness
    if (assetDecimals > 8) {
      return uint256(quantityInPips) * (uint256(10)**(assetDecimals - 8));
    }
    return uint256(quantityInPips) / (uint256(10)**(8 - assetDecimals));
  }

  function assetUnitsToPips(uint256 quantityInAssetUnits, uint8 assetDecimals)
    internal
    pure
    returns (uint64)
  {
    require(assetDecimals <= 32, 'Asset cannot have more than 32 decimals');

    uint256 quantityInPips;
    // Exponents cannot be negative, so divide or multiply based on exponent signedness
    if (assetDecimals > 8) {
      quantityInPips = quantityInAssetUnits / (uint256(10)**(assetDecimals - 8));
    } else {
      quantityInPips = quantityInAssetUnits * (uint256(10)**(8 - assetDecimals));
    }
    require(quantityInPips < 2**64, 'Pip quantity overflows uint64');

    return uint64(quantityInPips);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

/**
 * @notice Enums used in `Order` and `Withdrawal` structs
 */
contract Enums {
  enum OrderSelfTradePrevention {
    // Decrement and cancel
    dc,
    // Cancel oldest
    co,
    // Cancel newest
    cn,
    // Cancel both
    cb
  }
  enum OrderSide {
    Buy,
    Sell
  }
  enum OrderTimeInForce {
    // Good until cancelled
    gtc,
    // Good until time
    gtt,
    // Immediate or cancel
    ioc,
    // Fill or kill
    fok
  }
  enum OrderType {
    Market,
    Limit,
    LimitMaker,
    StopLoss,
    StopLossLimit,
    TakeProfit,
    TakeProfitLimit
  }
  enum WithdrawalType {
    BySymbol,
    ByAddress
  }
}

/**
 * @notice Struct definitions
 */
contract Structs {
  /**
   * @notice Argument type for `Exchange.executeTrade` and `Signatures.getOrderWalletHash`
   */
  struct Order {
    // Not currently used but reserved for future use. Must be 1
    uint8 signatureHashVersion;
    // UUIDv1 unique to wallet
    uint128 nonce;
    // Wallet address that placed order and signed hash
    address walletAddress;
    // Type of order
    Enums.OrderType orderType;
    // Order side wallet is on
    Enums.OrderSide side;
    // Order quantity in base or quote asset terms depending on isQuantityInQuote flag
    uint64 quantityInPips;
    // Is quantityInPips in quote terms
    bool isQuantityInQuote;
    // For limit orders, price in decimal pips * 10^8 in quote terms
    uint64 limitPriceInPips;
    // For stop orders, stop loss or take profit price in decimal pips * 10^8 in quote terms
    uint64 stopPriceInPips;
    // Optional custom client order ID
    string clientOrderId;
    // TIF option specified by wallet for order
    Enums.OrderTimeInForce timeInForce;
    // STP behavior specified by wallet for order
    Enums.OrderSelfTradePrevention selfTradePrevention;
    // Cancellation time specified by wallet for GTT TIF order
    uint64 cancelAfter;
    // The ECDSA signature of the order hash as produced by Signatures.getOrderWalletHash
    bytes walletSignature;
  }

  /**
   * @notice Return type for `Exchange.loadAssetBySymbol`, and `Exchange.loadAssetByAddress`; also
   * used internally by `AssetRegistry`
   */
  struct Asset {
    // Flag to distinguish from empty struct
    bool exists;
    // The asset's address
    address assetAddress;
    // The asset's symbol
    string symbol;
    // The asset's decimal precision
    uint8 decimals;
    // Flag set when asset registration confirmed. Asset deposits, trades, or withdrawals only allowed if true
    bool isConfirmed;
    // Timestamp as ms since Unix epoch when isConfirmed was asserted
    uint64 confirmedTimestampInMs;
  }

  /**
   * @notice Internally used struct capturing wallet order nonce invalidations created via `invalidateOrderNonce`
   */
  struct NonceInvalidation {
    bool exists;
    uint64 timestampInMs;
    uint256 effectiveBlockNumber;
  }

  /**
   * @notice Argument type for `Exchange.executeTrade` specifying execution parameters for matching orders
   */
  struct Trade {
    // Base asset symbol
    string baseAssetSymbol;
    // Quote asset symbol
    string quoteAssetSymbol;
    // Base asset address
    address baseAssetAddress;
    // Quote asset address
    address quoteAssetAddress;
    // Gross amount including fees of base asset executed
    uint64 grossBaseQuantityInPips;
    // Gross amount including fees of quote asset executed
    uint64 grossQuoteQuantityInPips;
    // Net amount of base asset received by buy side wallet after fees
    uint64 netBaseQuantityInPips;
    // Net amount of quote asset received by sell side wallet after fees
    uint64 netQuoteQuantityInPips;
    // Asset address for liquidity maker's fee
    address makerFeeAssetAddress;
    // Asset address for liquidity taker's fee
    address takerFeeAssetAddress;
    // Fee paid by liquidity maker
    uint64 makerFeeQuantityInPips;
    // Fee paid by liquidity taker
    uint64 takerFeeQuantityInPips;
    // Execution price of trade in decimal pips * 10^8 in quote terms
    uint64 priceInPips;
    // Which side of the order (buy or sell) the liquidity maker was on
    Enums.OrderSide makerSide;
  }

  /**
   * @notice Argument type for `Exchange.withdraw` and `Signatures.getWithdrawalWalletHash`
   */
  struct Withdrawal {
    // Distinguishes between withdrawals by asset symbol or address
    Enums.WithdrawalType withdrawalType;
    // UUIDv1 unique to wallet
    uint128 nonce;
    // Address of wallet to which funds will be returned
    address payable walletAddress;
    // Asset symbol
    string assetSymbol;
    // Asset address
    address assetAddress; // Used when assetSymbol not specified
    // Withdrawal quantity
    uint64 quantityInPips;
    // Gas fee deducted from withdrawn quantity to cover dispatcher tx costs
    uint64 gasFeeInPips;
    // Not currently used but reserved for future use. Must be true
    bool autoDispatchEnabled;
    // The ECDSA signature of the withdrawal hash as produced by Signatures.getWithdrawalWalletHash
    bytes walletSignature;
  }
}

/**
 * @notice Interface of the ERC20 standard as defined in the EIP, but with no return values for
 * transfer and transferFrom. By asserting expected balance changes when calling these two methods
 * we can safely ignore their return values. This allows support of non-compliant tokens that do not
 * return a boolean. See https://github.com/ethereum/solidity/issues/4116
 */
interface IERC20 {
  /**
   * @notice Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @notice Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external;

  /**
   * @notice Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
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
   * @notice Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @notice Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @notice Interface to Custodian contract. Used by Exchange and Governance contracts for internal
 * delegate calls
 */
interface ICustodian {
  /**
   * @notice ETH can only be sent by the Exchange
   */
  receive() external payable;

  /**
   * @notice Withdraw any asset and amount to a target wallet
   *
   * @dev No balance checking performed
   *
   * @param wallet The wallet to which assets will be returned
   * @param asset The address of the asset to withdraw (ETH or ERC-20 contract)
   * @param quantityInAssetUnits The quantity in asset units to withdraw
   */
  function withdraw(
    address payable wallet,
    address asset,
    uint256 quantityInAssetUnits
  ) external;

  /**
   * @notice Load address of the currently whitelisted Exchange contract
   *
   * @return The address of the currently whitelisted Exchange contract
   */
  function loadExchange() external view returns (address);

  /**
   * @notice Sets a new Exchange contract address
   *
   * @param newExchange The address of the new whitelisted Exchange contract
   */
  function setExchange(address newExchange) external;

  /**
   * @notice Load address of the currently whitelisted Governance contract
   *
   * @return The address of the currently whitelisted Governance contract
   */
  function loadGovernance() external view returns (address);

  /**
   * @notice Sets a new Governance contract address
   *
   * @param newGovernance The address of the new whitelisted Governance contract
   */
  function setGovernance(address newGovernance) external;
}

/**
 * @notice Interface to Exchange contract. Provided only to document struct usage
 */
interface IExchange {
  /**
   * @notice Settles a trade between two orders submitted and matched off-chain
   *
   * @param buy A `Structs.Order` struct encoding the parameters of the buy-side order (receiving base, giving quote)
   * @param sell A `Structs.Order` struct encoding the parameters of the sell-side order (giving base, receiving quote)
   * @param trade A `Structs.Trade` struct encoding the parameters of this trade execution of the counterparty orders
   */
  function executeTrade(
    Structs.Order calldata buy,
    Structs.Order calldata sell,
    Structs.Trade calldata trade
  ) external;

  /**
   * @notice Settles a user withdrawal submitted off-chain. Calls restricted to currently whitelisted Dispatcher wallet
   *
   * @param withdrawal A `Structs.Withdrawal` struct encoding the parameters of the withdrawal
   */
  function withdraw(Structs.Withdrawal calldata withdrawal) external;
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

import { Structs } from './Interfaces.sol';
import { UUID } from './UUID.sol';

library NonceInvalidations {
  function invalidateOrderNonce(
    mapping(address => Structs.NonceInvalidation) storage self,
    uint128 nonce,
    uint256 chainPropagationPeriod
  ) external returns (uint64 timestampInMs, uint256 effectiveBlockNumber) {
    timestampInMs = UUID.getTimestampInMsFromUuidV1(nonce);
    // Enforce a maximum skew for invalidating nonce timestamps in the future so the user doesn't
    // lock their wallet from trades indefinitely
    require(timestampInMs < getOneDayFromNowInMs(), 'Nonce timestamp too high');

    if (self[msg.sender].exists) {
      require(
        self[msg.sender].timestampInMs < timestampInMs,
        'Nonce timestamp invalidated'
      );
      require(
        self[msg.sender].effectiveBlockNumber <= block.number,
        'Last invalidation not finalized'
      );
    }

    // Changing the Chain Propagation Period will not affect the effectiveBlockNumber for this invalidation
    effectiveBlockNumber = block.number + chainPropagationPeriod;
    self[msg.sender] = Structs.NonceInvalidation(
      true,
      timestampInMs,
      effectiveBlockNumber
    );
  }

  function getOneDayFromNowInMs() private view returns (uint64) {
    uint64 secondsInOneDay = 24 * 60 * 60; // 24 hours/day * 60 min/hour * 60 seconds/min
    uint64 msInOneSecond = 1000;

    return (uint64(block.timestamp) + secondsInOneDay) * msInOneSecond;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

import { ECDSA } from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import { Enums, Structs } from './Interfaces.sol';


/**
 * Library helpers for building hashes and verifying wallet signatures on `Order` and `Withdrawal` structs
 */
library Signatures {
  function isSignatureValid(
    bytes32 hash,
    bytes memory signature,
    address signer
  ) internal pure returns (bool) {
    return
      ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) == signer;
  }

  function getOrderWalletHash(
    Structs.Order memory order,
    string memory baseSymbol,
    string memory quoteSymbol
  ) internal pure returns (bytes32) {
    require(
      order.signatureHashVersion == 1,
      'Signature hash version must be 1'
    );
    return
      keccak256(
        // Placing all the fields in a single `abi.encodePacked` call causes a `stack too deep` error
        abi.encodePacked(
          abi.encodePacked(
            order.signatureHashVersion,
            order.nonce,
            order.walletAddress,
            getMarketSymbol(baseSymbol, quoteSymbol),
            uint8(order.orderType),
            uint8(order.side),
            // Ledger qtys and prices are in pip, but order was signed by wallet owner with decimal values
            pipToDecimal(order.quantityInPips)
          ),
          abi.encodePacked(
            order.isQuantityInQuote,
            order.limitPriceInPips > 0
              ? pipToDecimal(order.limitPriceInPips)
              : '',
            order.stopPriceInPips > 0
              ? pipToDecimal(order.stopPriceInPips)
              : '',
            order.clientOrderId,
            uint8(order.timeInForce),
            uint8(order.selfTradePrevention),
            order.cancelAfter
          )
        )
      );
  }

  function getWithdrawalWalletHash(Structs.Withdrawal memory withdrawal)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked(
          withdrawal.nonce,
          withdrawal.walletAddress,
          // Ternary branches must resolve to the same type, so wrap in idempotent encodePacked
          withdrawal.withdrawalType == Enums.WithdrawalType.BySymbol
            ? abi.encodePacked(withdrawal.assetSymbol)
            : abi.encodePacked(withdrawal.assetAddress),
          pipToDecimal(withdrawal.quantityInPips),
          withdrawal.autoDispatchEnabled
        )
      );
  }

  /**
   * @dev Combines base and quote asset symbols into the market symbol originally signed by the
   * wallet. For example if base is 'IDEX' and quote is 'ETH', the resulting market symbol is
   * 'IDEX-ETH'. This approach is used rather than passing in the market symbol and splitting it
   * since the latter incurs a higher gas cost
   */
  function getMarketSymbol(string memory baseSymbol, string memory quoteSymbol)
    private
    pure
    returns (string memory)
  {
    bytes memory baseSymbolBytes = bytes(baseSymbol);
    bytes memory hyphenBytes = bytes('-');
    bytes memory quoteSymbolBytes = bytes(quoteSymbol);

    bytes memory marketSymbolBytes = bytes(
      new string(
        baseSymbolBytes.length + quoteSymbolBytes.length + hyphenBytes.length
      )
    );

    uint256 i;
    uint256 j;

    for (i = 0; i < baseSymbolBytes.length; i++) {
      marketSymbolBytes[j++] = baseSymbolBytes[i];
    }

    // Hyphen is one byte
    marketSymbolBytes[j++] = hyphenBytes[0];

    for (i = 0; i < quoteSymbolBytes.length; i++) {
      marketSymbolBytes[j++] = quoteSymbolBytes[i];
    }

    return string(marketSymbolBytes);
  }

  /**
   * @dev Converts an integer pip quantity back into the fixed-precision decimal pip string
   * originally signed by the wallet. For example, 1234567890 becomes '12.34567890'
   */
  function pipToDecimal(uint256 pips) private pure returns (string memory) {
    // Inspired by https://github.com/provable-things/ethereum-api/blob/831f4123816f7a3e57ebea171a3cdcf3b528e475/oraclizeAPI_0.5.sol#L1045-L1062
    uint256 copy = pips;
    uint256 length;
    while (copy != 0) {
      length++;
      copy /= 10;
    }
    if (length < 9) {
      length = 9; // a zero before the decimal point plus 8 decimals
    }
    length++; // for the decimal point

    bytes memory decimal = new bytes(length);
    for (uint256 i = length; i > 0; i--) {
      if (length - i == 8) {
        decimal[i - 1] = bytes1(uint8(46)); // period
      } else {
        decimal[i - 1] = bytes1(uint8(48 + (pips % 10)));
        pips /= 10;
      }
    }
    return string(decimal);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;


/**
 * Library helper for extracting timestamp component of Version 1 UUIDs
 */
library UUID {

  /**
   * Extracts the timestamp component of a Version 1 UUID. Used to make time-based assertions
   * against a wallet-privided nonce
   */
  function getTimestampInMsFromUuidV1(uint128 uuid)
    internal
    pure
    returns (uint64 msSinceUnixEpoch)
  {
    // https://tools.ietf.org/html/rfc4122#section-4.1.2
    uint128 version = (uuid >> 76) & 0x0000000000000000000000000000000F;
    require(version == 1, 'Must be v1 UUID');

    // Time components are in reverse order so shift+mask each to reassemble
    uint128 timeHigh = (uuid >> 16) & 0x00000000000000000FFF000000000000;
    uint128 timeMid = (uuid >> 48) & 0x00000000000000000000FFFF00000000;
    uint128 timeLow = (uuid >> 96) & 0x000000000000000000000000FFFFFFFF;
    uint128 nsSinceGregorianEpoch = (timeHigh | timeMid | timeLow);
    // Gregorian offset given in seconds by https://www.wolframalpha.com/input/?i=convert+1582-10-15+UTC+to+unix+time
    msSinceUnixEpoch = uint64(nsSinceGregorianEpoch / 10000) - 12219292800000;

    return msSinceUnixEpoch;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;

import { Enums, Structs } from './Interfaces.sol';
import { UUID } from './UUID.sol';
import { Signatures } from './Signatures.sol';
import { AssetRegistry } from './AssetRegistry.sol';

library Validations {

  uint64 constant _maxTradeFeeBasisPoints = 20 * 100; // 20%;

  function validateOrderNonce(
    Structs.Order memory order,
    mapping(address => Structs.NonceInvalidation) storage nonceInvalidations
  ) internal view {
    require(
      UUID.getTimestampInMsFromUuidV1(order.nonce) >
        loadLastInvalidatedTimestamp(order.walletAddress, nonceInvalidations),
      'Order nonce timestamp too low'
    );
  }

  function validateOrderNonces(
    Structs.Order memory buy,
    Structs.Order memory sell,
    mapping(address => Structs.NonceInvalidation) storage nonceInvalidations
  ) internal view {
    require(
      UUID.getTimestampInMsFromUuidV1(buy.nonce) >
        loadLastInvalidatedTimestamp(buy.walletAddress, nonceInvalidations),
      'Buy order nonce timestamp too low'
    );
    require(
      UUID.getTimestampInMsFromUuidV1(sell.nonce) >
        loadLastInvalidatedTimestamp(sell.walletAddress, nonceInvalidations),
      'Sell order nonce timestamp too low'
    );
  }

  function validateWithdrawalSignature(Structs.Withdrawal memory withdrawal)
    internal
    pure
    returns (bytes32)
  {
    bytes32 withdrawalHash = Signatures.getWithdrawalWalletHash(withdrawal);

    require(
      Signatures.isSignatureValid(
        withdrawalHash,
        withdrawal.walletSignature,
        withdrawal.walletAddress
      ),
      'Invalid wallet signature'
    );

    return withdrawalHash;
  }

  function validateOrderSignatures(
    Structs.Order memory buy,
    Structs.Order memory sell,
    Structs.Trade memory trade
  ) internal pure returns (bytes32, bytes32) {
    bytes32 buyOrderHash = validateOrderSignature(buy, trade);
    bytes32 sellOrderHash = validateOrderSignature(sell, trade);

    return (buyOrderHash, sellOrderHash);
  }

  function validateOrderSignature(
    Structs.Order memory order,
    Structs.Trade memory trade
  ) private pure returns (bytes32) {
    bytes32 orderHash = Signatures.getOrderWalletHash(
      order,
      trade.baseAssetSymbol,
      trade.quoteAssetSymbol
    );

    require(
      Signatures.isSignatureValid(
        orderHash,
        order.walletSignature,
        order.walletAddress
      ),
      order.side == Enums.OrderSide.Buy
        ? 'Invalid wallet signature for buy order'
        : 'Invalid wallet signature for sell order'
    );

    return orderHash;
  }

  function validateLimitPrices(
    Structs.Order memory buy,
    Structs.Order memory sell,
    Structs.Trade memory trade
  ) internal pure {
    require(
      trade.grossBaseQuantityInPips > 0,
      'Base quantity must be greater than zero'
    );
    require(
      trade.grossQuoteQuantityInPips > 0,
      'Quote quantity must be greater than zero'
    );

    if (isLimitOrderType(buy.orderType)) {
      require(
        getImpliedQuoteQuantityInPips(
          trade.grossBaseQuantityInPips,
          buy.limitPriceInPips
        ) >= trade.grossQuoteQuantityInPips,
        'Buy order limit price exceeded'
      );
    }

    if (isLimitOrderType(sell.orderType)) {
      require(
        getImpliedQuoteQuantityInPips(
          trade.grossBaseQuantityInPips,
          sell.limitPriceInPips
        ) <= trade.grossQuoteQuantityInPips,
        'Sell order limit price exceeded'
      );
    }
  }

  function validateTradeFees(Structs.Trade memory trade) internal pure {
    uint64 makerTotalQuantityInPips = trade.makerFeeAssetAddress ==
      trade.baseAssetAddress
      ? trade.grossBaseQuantityInPips
      : trade.grossQuoteQuantityInPips;
    require(
      getFeeBasisPoints(
        trade.makerFeeQuantityInPips,
        makerTotalQuantityInPips
      ) <= _maxTradeFeeBasisPoints,
      'Excessive maker fee'
    );

    uint64 takerTotalQuantityInPips = trade.takerFeeAssetAddress ==
      trade.baseAssetAddress
      ? trade.grossBaseQuantityInPips
      : trade.grossQuoteQuantityInPips;
    require(
      getFeeBasisPoints(
        trade.takerFeeQuantityInPips,
        takerTotalQuantityInPips
      ) <= _maxTradeFeeBasisPoints,
      'Excessive taker fee'
    );

    require(
      trade.netBaseQuantityInPips + (
        trade.makerFeeAssetAddress == trade.baseAssetAddress
          ? trade.makerFeeQuantityInPips
          : trade.takerFeeQuantityInPips
      ) == trade.grossBaseQuantityInPips,
      'Net base plus fee is not equal to gross'
    );
    require(
      trade.netQuoteQuantityInPips + (
        trade.makerFeeAssetAddress == trade.quoteAssetAddress
          ? trade.makerFeeQuantityInPips
          : trade.takerFeeQuantityInPips
      ) == trade.grossQuoteQuantityInPips,
      'Net quote plus fee is not equal to gross'
    );
  }

  // Utils //

  function loadLastInvalidatedTimestamp(
    address walletAddress,
    mapping(address => Structs.NonceInvalidation) storage nonceInvalidations
  ) private view returns (uint64) {
    if (
      nonceInvalidations[walletAddress].exists &&
      nonceInvalidations[walletAddress].effectiveBlockNumber <= block.number
    ) {
      return nonceInvalidations[walletAddress].timestampInMs;
    }

    return 0;
  }

  function isLimitOrderType(Enums.OrderType orderType)
    private
    pure
    returns (bool)
  {
    return
      orderType == Enums.OrderType.Limit ||
      orderType == Enums.OrderType.LimitMaker ||
      orderType == Enums.OrderType.StopLossLimit ||
      orderType == Enums.OrderType.TakeProfitLimit;
  }

  function isMarketOrderType(Enums.OrderType orderType)
    internal
    pure
    returns (bool)
  {
    return
      orderType == Enums.OrderType.Market ||
      orderType == Enums.OrderType.StopLoss ||
      orderType == Enums.OrderType.TakeProfit;
  }

  function getFeeBasisPoints(uint64 fee, uint64 total)
    internal
    pure
    returns (uint64)
  {
    uint64 basisPointsInTotal = 100 * 100; // 100 basis points/percent * 100 percent/total
    return fee * basisPointsInTotal / total;
  }

  function getImpliedQuoteQuantityInPips(
    uint64 baseQuantityInPips,
    uint64 limitPriceInPips
  ) private pure returns (uint64) {
    // To convert a fractional price to integer pips, shift right by the pip precision of 8 decimals
    uint256 pipsMultiplier = 10**8;

    uint256 impliedQuoteQuantityInPips = uint256(baseQuantityInPips)
      * (uint256(limitPriceInPips))
      / pipsMultiplier;
    require(
      impliedQuoteQuantityInPips < 2**64,
      'Implied quote pip quantity overflows uint64'
    );

    return uint64(impliedQuoteQuantityInPips);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.10;


/**
 * @notice Mixin that provide separate owner and admin roles for RBAC
 */
abstract contract Owned {
  address immutable _owner;
  address _admin;

  modifier onlyOwner {
    require(msg.sender == _owner, 'Caller must be owner');
    _;
  }
  modifier onlyAdmin {
    require(msg.sender == _admin, 'Caller must be admin');
    _;
  }

  /**
   * @notice Sets both the owner and admin roles to the contract creator
   */
  constructor() {
    _owner = msg.sender;
    _admin = msg.sender;
  }

  /**
   * @notice Sets a new whitelisted admin wallet
   *
   * @param newAdmin The new whitelisted admin wallet. Must be different from the current one
   */
  function setAdmin(address newAdmin) external onlyOwner {
    require(newAdmin != address(0x0), 'Invalid wallet address');
    require(newAdmin != _admin, 'Must be different from current admin');

    _admin = newAdmin;
  }

  /**
   * @notice Clears the currently whitelisted admin wallet, effectively disabling any functions requiring
   * the admin role
   */
  function removeAdmin() external onlyOwner {
    _admin = address(0x0);
  }
}