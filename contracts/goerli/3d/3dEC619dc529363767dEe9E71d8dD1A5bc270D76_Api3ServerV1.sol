// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/SelfMulticall.sol";
import "./RoleDeriver.sol";
import "./interfaces/IAccessControlRegistryAdminned.sol";
import "./interfaces/IAccessControlRegistry.sol";

/// @title Contract to be inherited by contracts whose adminship functionality
/// will be implemented using AccessControlRegistry
contract AccessControlRegistryAdminned is
    SelfMulticall,
    RoleDeriver,
    IAccessControlRegistryAdminned
{
    /// @notice AccessControlRegistry contract address
    address public immutable override accessControlRegistry;

    /// @notice Admin role description
    string public override adminRoleDescription;

    bytes32 internal immutable adminRoleDescriptionHash;

    /// @dev Contracts deployed with the same admin role descriptions will have
    /// the same roles, meaning that granting an account a role will authorize
    /// it in multiple contracts. Unless you want your deployed contract to
    /// share the role configuration of another contract, use a unique admin
    /// role description.
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription
    ) {
        require(_accessControlRegistry != address(0), "ACR address zero");
        require(
            bytes(_adminRoleDescription).length > 0,
            "Admin role description empty"
        );
        accessControlRegistry = _accessControlRegistry;
        adminRoleDescription = _adminRoleDescription;
        adminRoleDescriptionHash = keccak256(
            abi.encodePacked(_adminRoleDescription)
        );
    }

    /// @notice Derives the admin role for the specific manager address
    /// @param manager Manager address
    /// @return adminRole Admin role
    function _deriveAdminRole(
        address manager
    ) internal view returns (bytes32 adminRole) {
        adminRole = _deriveRole(
            _deriveRootRole(manager),
            adminRoleDescriptionHash
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlRegistryAdminned.sol";
import "./interfaces/IAccessControlRegistryAdminnedWithManager.sol";

/// @title Contract to be inherited by contracts with manager whose adminship
/// functionality will be implemented using AccessControlRegistry
/// @notice The manager address here is expected to belong to an
/// AccessControlRegistry user that is a multisig/DAO
contract AccessControlRegistryAdminnedWithManager is
    AccessControlRegistryAdminned,
    IAccessControlRegistryAdminnedWithManager
{
    /// @notice Address of the manager that manages the related
    /// AccessControlRegistry roles
    /// @dev The mutability of the manager role can be implemented by
    /// designating an OwnableCallForwarder contract as the manager. The
    /// ownership of this contract can then be transferred, effectively
    /// transferring managership.
    address public immutable override manager;

    /// @notice Admin role
    /// @dev Since `manager` is immutable, so is `adminRole`
    bytes32 public immutable override adminRole;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    )
        AccessControlRegistryAdminned(
            _accessControlRegistry,
            _adminRoleDescription
        )
    {
        require(_manager != address(0), "Manager address zero");
        manager = _manager;
        adminRole = _deriveAdminRole(_manager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../../utils/interfaces/IExpiringMetaTxForwarder.sol";
import "../../utils/interfaces/ISelfMulticall.sol";

interface IAccessControlRegistry is
    IAccessControl,
    IExpiringMetaTxForwarder,
    ISelfMulticall
{
    event InitializedManager(
        bytes32 indexed rootRole,
        address indexed manager,
        address sender
    );

    event InitializedRole(
        bytes32 indexed role,
        bytes32 indexed adminRole,
        string description,
        address sender
    );

    function initializeManager(address manager) external;

    function initializeRoleAndGrantToSender(
        bytes32 adminRole,
        string calldata description
    ) external returns (bytes32 role);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/ISelfMulticall.sol";

interface IAccessControlRegistryAdminned is ISelfMulticall {
    function accessControlRegistry() external view returns (address);

    function adminRoleDescription() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAccessControlRegistryAdminned.sol";

interface IAccessControlRegistryAdminnedWithManager is
    IAccessControlRegistryAdminned
{
    function manager() external view returns (address);

    function adminRole() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contract to be inherited by contracts that will derive
/// AccessControlRegistry roles
/// @notice If a contract interfaces with AccessControlRegistry and needs to
/// derive roles, it should inherit this contract instead of re-implementing
/// the logic
contract RoleDeriver {
    /// @notice Derives the root role of the manager
    /// @param manager Manager address
    /// @return rootRole Root role
    function _deriveRootRole(
        address manager
    ) internal pure returns (bytes32 rootRole) {
        rootRole = keccak256(abi.encodePacked(manager));
    }

    /// @notice Derives the role using its admin role and description
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param description Human-readable description of the role
    /// @return role Role
    function _deriveRole(
        bytes32 adminRole,
        string memory description
    ) internal pure returns (bytes32 role) {
        role = _deriveRole(adminRole, keccak256(abi.encodePacked(description)));
    }

    /// @notice Derives the role using its admin role and description hash
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param descriptionHash Hash of the human-readable description of the
    /// role
    /// @return role Role
    function _deriveRole(
        bytes32 adminRole,
        bytes32 descriptionHash
    ) internal pure returns (bytes32 role) {
        role = keccak256(abi.encodePacked(adminRole, descriptionHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Sort.sol";
import "./QuickSelect.sol";

/// @title Contract to be inherited by contracts that will calculate the median
/// of an array
/// @notice The operation will be in-place, i.e., the array provided as the
/// argument will be modified.
contract Median is Sort, Quickselect {
    /// @notice Returns the median of the array
    /// @dev Uses an unrolled sorting implementation for shorter arrays and
    /// quickselect for longer arrays for gas cost efficiency
    /// @param array Array whose median is to be calculated
    /// @return Median of the array
    function median(int256[] memory array) internal pure returns (int256) {
        uint256 arrayLength = array.length;
        if (arrayLength <= MAX_SORT_LENGTH) {
            sort(array);
            if (arrayLength % 2 == 1) {
                return array[arrayLength / 2];
            } else {
                assert(arrayLength != 0);
                unchecked {
                    return
                        average(
                            array[arrayLength / 2 - 1],
                            array[arrayLength / 2]
                        );
                }
            }
        } else {
            if (arrayLength % 2 == 1) {
                return array[quickselectK(array, arrayLength / 2)];
            } else {
                uint256 mid1;
                uint256 mid2;
                unchecked {
                    (mid1, mid2) = quickselectKPlusOne(
                        array,
                        arrayLength / 2 - 1
                    );
                }
                return average(array[mid1], array[mid2]);
            }
        }
    }

    /// @notice Averages two signed integers without overflowing
    /// @param x Integer x
    /// @param y Integer y
    /// @return Average of integers x and y
    function average(int256 x, int256 y) private pure returns (int256) {
        unchecked {
            int256 averageRoundedDownToNegativeInfinity = (x >> 1) +
                (y >> 1) +
                (x & y & 1);
            // If the average rounded down to negative infinity is negative
            // (i.e., its 256th sign bit is set), and one of (x, y) is even and
            // the other one is odd (i.e., the 1st bit of their xor is set),
            // add 1 to round the average down to zero instead.
            // We will typecast the signed integer to unsigned to logical-shift
            // int256(uint256(signedInt)) >> 255 ~= signedInt >>> 255
            return
                averageRoundedDownToNegativeInfinity +
                (int256(
                    (uint256(averageRoundedDownToNegativeInfinity) >> 255)
                ) & (x ^ y));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contract to be inherited by contracts that will calculate the index
/// of the k-th and optionally (k+1)-th largest elements in the array
/// @notice Uses quickselect, which operates in-place, i.e., the array provided
/// as the argument will be modified.
contract Quickselect {
    /// @notice Returns the index of the k-th largest element in the array
    /// @param array Array in which k-th largest element will be searched
    /// @param k K
    /// @return indK Index of the k-th largest element
    function quickselectK(
        int256[] memory array,
        uint256 k
    ) internal pure returns (uint256 indK) {
        uint256 arrayLength = array.length;
        assert(arrayLength > 0);
        unchecked {
            (indK, ) = quickselect(array, 0, arrayLength - 1, k, false);
        }
    }

    /// @notice Returns the index of the k-th and (k+1)-th largest elements in
    /// the array
    /// @param array Array in which k-th and (k+1)-th largest elements will be
    /// searched
    /// @param k K
    /// @return indK Index of the k-th largest element
    /// @return indKPlusOne Index of the (k+1)-th largest element
    function quickselectKPlusOne(
        int256[] memory array,
        uint256 k
    ) internal pure returns (uint256 indK, uint256 indKPlusOne) {
        uint256 arrayLength = array.length;
        assert(arrayLength > 1);
        unchecked {
            (indK, indKPlusOne) = quickselect(
                array,
                0,
                arrayLength - 1,
                k,
                true
            );
        }
    }

    /// @notice Returns the index of the k-th largest element in the specified
    /// section of the (potentially unsorted) array
    /// @param array Array in which K will be searched for
    /// @param lo Starting index of the section of the array that K will be
    /// searched in
    /// @param hi Last index of the section of the array that K will be
    /// searched in
    /// @param k K
    /// @param selectKPlusOne If the index of the (k+1)-th largest element is
    /// to be returned
    /// @return indK Index of the k-th largest element
    /// @return indKPlusOne Index of the (k+1)-th largest element (only set if
    /// `selectKPlusOne` is `true`)
    function quickselect(
        int256[] memory array,
        uint256 lo,
        uint256 hi,
        uint256 k,
        bool selectKPlusOne
    ) private pure returns (uint256 indK, uint256 indKPlusOne) {
        if (lo == hi) {
            return (k, 0);
        }
        uint256 indPivot = partition(array, lo, hi);
        if (k < indPivot) {
            unchecked {
                (indK, ) = quickselect(array, lo, indPivot - 1, k, false);
            }
        } else if (k > indPivot) {
            unchecked {
                (indK, ) = quickselect(array, indPivot + 1, hi, k, false);
            }
        } else {
            indK = indPivot;
        }
        // Since Quickselect ends in the array being partitioned around the
        // k-th largest element, we can continue searching towards right for
        // the (k+1)-th largest element, which is useful in calculating the
        // median of an array with even length
        if (selectKPlusOne) {
            unchecked {
                indKPlusOne = indK + 1;
            }
            uint256 i;
            unchecked {
                i = indKPlusOne + 1;
            }
            uint256 arrayLength = array.length;
            for (; i < arrayLength; ) {
                if (array[i] < array[indKPlusOne]) {
                    indKPlusOne = i;
                }
                unchecked {
                    i++;
                }
            }
        }
    }

    /// @notice Partitions the array into two around a pivot
    /// @param array Array that will be partitioned
    /// @param lo Starting index of the section of the array that will be
    /// partitioned
    /// @param hi Last index of the section of the array that will be
    /// partitioned
    /// @return pivotInd Pivot index
    function partition(
        int256[] memory array,
        uint256 lo,
        uint256 hi
    ) private pure returns (uint256 pivotInd) {
        if (lo == hi) {
            return lo;
        }
        int256 pivot = array[lo];
        uint256 i = lo;
        unchecked {
            pivotInd = hi + 1;
        }
        while (true) {
            do {
                unchecked {
                    i++;
                }
            } while (i < array.length && array[i] < pivot);
            do {
                unchecked {
                    pivotInd--;
                }
            } while (array[pivotInd] > pivot);
            if (i >= pivotInd) {
                (array[lo], array[pivotInd]) = (array[pivotInd], array[lo]);
                return pivotInd;
            }
            (array[i], array[pivotInd]) = (array[pivotInd], array[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contract to be inherited by contracts that will sort an array using
/// an unrolled implementation
/// @notice The operation will be in-place, i.e., the array provided as the
/// argument will be modified.
contract Sort {
    uint256 internal constant MAX_SORT_LENGTH = 9;

    /// @notice Sorts the array
    /// @param array Array to be sorted
    function sort(int256[] memory array) internal pure {
        uint256 arrayLength = array.length;
        require(arrayLength <= MAX_SORT_LENGTH, "Array too long to sort");
        // Do a binary search
        if (arrayLength < 6) {
            // Possible lengths: 1, 2, 3, 4, 5
            if (arrayLength < 4) {
                // Possible lengths: 1, 2, 3
                if (arrayLength == 3) {
                    // Length: 3
                    swapIfFirstIsLarger(array, 0, 1);
                    swapIfFirstIsLarger(array, 1, 2);
                    swapIfFirstIsLarger(array, 0, 1);
                } else if (arrayLength == 2) {
                    // Length: 2
                    swapIfFirstIsLarger(array, 0, 1);
                }
                // Do nothing for Length: 1
            } else {
                // Possible lengths: 4, 5
                if (arrayLength == 5) {
                    // Length: 5
                    swapIfFirstIsLarger(array, 1, 2);
                    swapIfFirstIsLarger(array, 3, 4);
                    swapIfFirstIsLarger(array, 1, 3);
                    swapIfFirstIsLarger(array, 0, 2);
                    swapIfFirstIsLarger(array, 2, 4);
                    swapIfFirstIsLarger(array, 0, 3);
                    swapIfFirstIsLarger(array, 0, 1);
                    swapIfFirstIsLarger(array, 2, 3);
                    swapIfFirstIsLarger(array, 1, 2);
                } else {
                    // Length: 4
                    swapIfFirstIsLarger(array, 0, 1);
                    swapIfFirstIsLarger(array, 2, 3);
                    swapIfFirstIsLarger(array, 1, 3);
                    swapIfFirstIsLarger(array, 0, 2);
                    swapIfFirstIsLarger(array, 1, 2);
                }
            }
        } else {
            // Possible lengths: 6, 7, 8, 9
            if (arrayLength < 8) {
                // Possible lengths: 6, 7
                if (arrayLength == 7) {
                    // Length: 7
                    swapIfFirstIsLarger(array, 1, 2);
                    swapIfFirstIsLarger(array, 3, 4);
                    swapIfFirstIsLarger(array, 5, 6);
                    swapIfFirstIsLarger(array, 0, 2);
                    swapIfFirstIsLarger(array, 4, 6);
                    swapIfFirstIsLarger(array, 3, 5);
                    swapIfFirstIsLarger(array, 2, 6);
                    swapIfFirstIsLarger(array, 1, 5);
                    swapIfFirstIsLarger(array, 0, 4);
                    swapIfFirstIsLarger(array, 2, 5);
                    swapIfFirstIsLarger(array, 0, 3);
                    swapIfFirstIsLarger(array, 2, 4);
                    swapIfFirstIsLarger(array, 1, 3);
                    swapIfFirstIsLarger(array, 0, 1);
                    swapIfFirstIsLarger(array, 2, 3);
                    swapIfFirstIsLarger(array, 4, 5);
                } else {
                    // Length: 6
                    swapIfFirstIsLarger(array, 0, 1);
                    swapIfFirstIsLarger(array, 2, 3);
                    swapIfFirstIsLarger(array, 4, 5);
                    swapIfFirstIsLarger(array, 1, 3);
                    swapIfFirstIsLarger(array, 3, 5);
                    swapIfFirstIsLarger(array, 1, 3);
                    swapIfFirstIsLarger(array, 2, 4);
                    swapIfFirstIsLarger(array, 0, 2);
                    swapIfFirstIsLarger(array, 2, 4);
                    swapIfFirstIsLarger(array, 3, 4);
                    swapIfFirstIsLarger(array, 1, 2);
                    swapIfFirstIsLarger(array, 2, 3);
                }
            } else {
                // Possible lengths: 8, 9
                if (arrayLength == 9) {
                    // Length: 9
                    swapIfFirstIsLarger(array, 1, 8);
                    swapIfFirstIsLarger(array, 2, 7);
                    swapIfFirstIsLarger(array, 3, 6);
                    swapIfFirstIsLarger(array, 4, 5);
                    swapIfFirstIsLarger(array, 1, 4);
                    swapIfFirstIsLarger(array, 5, 8);
                    swapIfFirstIsLarger(array, 0, 2);
                    swapIfFirstIsLarger(array, 6, 7);
                    swapIfFirstIsLarger(array, 2, 6);
                    swapIfFirstIsLarger(array, 7, 8);
                    swapIfFirstIsLarger(array, 0, 3);
                    swapIfFirstIsLarger(array, 4, 5);
                    swapIfFirstIsLarger(array, 0, 1);
                    swapIfFirstIsLarger(array, 3, 5);
                    swapIfFirstIsLarger(array, 6, 7);
                    swapIfFirstIsLarger(array, 2, 4);
                    swapIfFirstIsLarger(array, 1, 3);
                    swapIfFirstIsLarger(array, 5, 7);
                    swapIfFirstIsLarger(array, 4, 6);
                    swapIfFirstIsLarger(array, 1, 2);
                    swapIfFirstIsLarger(array, 3, 4);
                    swapIfFirstIsLarger(array, 5, 6);
                    swapIfFirstIsLarger(array, 7, 8);
                    swapIfFirstIsLarger(array, 2, 3);
                    swapIfFirstIsLarger(array, 4, 5);
                } else {
                    // Length: 8
                    swapIfFirstIsLarger(array, 0, 7);
                    swapIfFirstIsLarger(array, 1, 6);
                    swapIfFirstIsLarger(array, 2, 5);
                    swapIfFirstIsLarger(array, 3, 4);
                    swapIfFirstIsLarger(array, 0, 3);
                    swapIfFirstIsLarger(array, 4, 7);
                    swapIfFirstIsLarger(array, 1, 2);
                    swapIfFirstIsLarger(array, 5, 6);
                    swapIfFirstIsLarger(array, 0, 1);
                    swapIfFirstIsLarger(array, 2, 3);
                    swapIfFirstIsLarger(array, 4, 5);
                    swapIfFirstIsLarger(array, 6, 7);
                    swapIfFirstIsLarger(array, 3, 5);
                    swapIfFirstIsLarger(array, 2, 4);
                    swapIfFirstIsLarger(array, 1, 2);
                    swapIfFirstIsLarger(array, 3, 4);
                    swapIfFirstIsLarger(array, 5, 6);
                    swapIfFirstIsLarger(array, 2, 3);
                    swapIfFirstIsLarger(array, 4, 5);
                    swapIfFirstIsLarger(array, 3, 4);
                }
            }
        }
    }

    /// @notice Swaps two elements of an array if the first element is greater
    /// than the second
    /// @param array Array whose elements are to be swapped
    /// @param ind1 Index of the first element
    /// @param ind2 Index of the second element
    function swapIfFirstIsLarger(
        int256[] memory array,
        uint256 ind1,
        uint256 ind2
    ) private pure {
        if (array[ind1] > array[ind2]) {
            (array[ind1], array[ind2]) = (array[ind2], array[ind1]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./OevDapiServer.sol";
import "./BeaconUpdatesWithSignedData.sol";
import "./interfaces/IApi3ServerV1.sol";

/// @title First version of the contract that API3 uses to serve data feeds
/// @notice Api3ServerV1 serves data feeds in the form of Beacons, Beacon sets,
/// dAPIs, with optional OEV support for all of these.
/// The base Beacons are only updateable using signed data, and the Beacon sets
/// are updateable based on the Beacons, optionally using PSP. OEV proxy
/// Beacons and Beacon sets are updateable using OEV-signed data.
/// Api3ServerV1 does not support Beacons to be updated using RRP or PSP.
contract Api3ServerV1 is
    OevDapiServer,
    BeaconUpdatesWithSignedData,
    IApi3ServerV1
{
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    ) OevDapiServer(_accessControlRegistry, _adminRoleDescription, _manager) {}

    /// @notice Reads the data feed with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithId(
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithId(dataFeedId);
    }

    /// @notice Reads the data feed with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithDapiNameHash(dapiNameHash);
    }

    /// @notice Reads the data feed as the OEV proxy with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithIdAsOevProxy(dataFeedId);
    }

    /// @notice Reads the data feed as the OEV proxy with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) external view override returns (int224 value, uint32 timestamp) {
        return _readDataFeedWithDapiNameHashAsOevProxy(dapiNameHash);
    }

    function dataFeeds(
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
    }

    function oevProxyToIdToDataFeed(
        address proxy,
        bytes32 dataFeedId
    ) external view override returns (int224 value, uint32 timestamp) {
        DataFeed storage dataFeed = _oevProxyToIdToDataFeed[proxy][dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataFeedServer.sol";
import "./interfaces/IBeaconUpdatesWithSignedData.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Contract that updates Beacons using signed data
contract BeaconUpdatesWithSignedData is
    DataFeedServer,
    IBeaconUpdatesWithSignedData
{
    using ECDSA for bytes32;

    /// @notice Updates a Beacon using data signed by the Airnode
    /// @dev The signed data here is intentionally very general for practical
    /// reasons. It is less demanding on the signer to have data signed once
    /// and use that everywhere.
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @param timestamp Signature timestamp
    /// @param data Update data (an `int256` encoded in contract ABI)
    /// @param signature Template ID, timestamp and the update data signed by
    /// the Airnode
    /// @return beaconId Updated Beacon ID
    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override returns (bytes32 beaconId) {
        require(
            (
                keccak256(abi.encodePacked(templateId, timestamp, data))
                    .toEthSignedMessageHash()
            ).recover(signature) == airnode,
            "Signature mismatch"
        );
        beaconId = deriveBeaconId(airnode, templateId);
        int224 updatedValue = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithSignedData(
            beaconId,
            updatedValue,
            uint32(timestamp)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../access-control-registry/AccessControlRegistryAdminnedWithManager.sol";
import "./DataFeedServer.sol";
import "./interfaces/IDapiServer.sol";

/// @title Contract that serves dAPIs mapped to Beacons and Beacon sets
/// @notice Beacons and Beacon sets are addressed by immutable IDs. Although
/// this is trust-minimized, it requires users to manage the ID of the data
/// feed they are using. For when the user does not want to do this, dAPIs can
/// be used as an abstraction layer. By using a dAPI, the user delegates this
/// responsibility to dAPI management. It is important for dAPI management to
/// be restricted by consensus rules (by using a multisig or a DAO) and similar
/// trustless security mechanisms.
contract DapiServer is
    AccessControlRegistryAdminnedWithManager,
    DataFeedServer,
    IDapiServer
{
    /// @notice dAPI name setter role description
    string public constant override DAPI_NAME_SETTER_ROLE_DESCRIPTION =
        "dAPI name setter";

    /// @notice dAPI name setter role
    bytes32 public immutable override dapiNameSetterRole;

    /// @notice dAPI name hash mapped to the data feed ID
    mapping(bytes32 => bytes32) public override dapiNameHashToDataFeedId;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    )
        AccessControlRegistryAdminnedWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
    {
        dapiNameSetterRole = _deriveRole(
            _deriveAdminRole(manager),
            DAPI_NAME_SETTER_ROLE_DESCRIPTION
        );
    }

    /// @notice Sets the data feed ID the dAPI name points to
    /// @dev While a data feed ID refers to a specific Beacon or Beacon set,
    /// dAPI names provide a more abstract interface for convenience. This
    /// means a dAPI name that was pointing to a Beacon can be pointed to a
    /// Beacon set, then another Beacon set, etc.
    /// @param dapiName Human-readable dAPI name
    /// @param dataFeedId Data feed ID the dAPI name will point to
    function setDapiName(
        bytes32 dapiName,
        bytes32 dataFeedId
    ) external override {
        require(dapiName != bytes32(0), "dAPI name zero");
        require(
            msg.sender == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    dapiNameSetterRole,
                    msg.sender
                ),
            "Sender cannot set dAPI name"
        );
        dapiNameHashToDataFeedId[
            keccak256(abi.encodePacked(dapiName))
        ] = dataFeedId;
        emit SetDapiName(dataFeedId, dapiName, msg.sender);
    }

    /// @notice Returns the data feed ID the dAPI name is set to
    /// @param dapiName dAPI name
    /// @return Data feed ID
    function dapiNameToDataFeedId(
        bytes32 dapiName
    ) external view override returns (bytes32) {
        return dapiNameHashToDataFeedId[keccak256(abi.encodePacked(dapiName))];
    }

    /// @notice Reads the data feed with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) internal view returns (int224 value, uint32 timestamp) {
        bytes32 dataFeedId = dapiNameHashToDataFeedId[dapiNameHash];
        require(dataFeedId != bytes32(0), "dAPI name not set");
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        require(timestamp > 0, "Data feed not initialized");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../utils/ExtendedSelfMulticall.sol";
import "./aggregation/Median.sol";
import "./interfaces/IDataFeedServer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Contract that serves Beacons and Beacon sets
/// @notice A Beacon is a live data feed addressed by an ID, which is derived
/// from an Airnode address and a template ID. This is suitable where the more
/// recent data point is always more favorable, e.g., in the context of an
/// asset price data feed. Beacons can also be seen as one-Airnode data feeds
/// that can be used individually or combined to build Beacon sets.
contract DataFeedServer is ExtendedSelfMulticall, Median, IDataFeedServer {
    using ECDSA for bytes32;

    // Airnodes serve their fulfillment data along with timestamps. This
    // contract casts the reported data to `int224` and the timestamp to
    // `uint32`, which works until year 2106.
    struct DataFeed {
        int224 value;
        uint32 timestamp;
    }

    /// @notice Data feed with ID
    mapping(bytes32 => DataFeed) internal _dataFeeds;

    /// @dev Reverts if the timestamp is from more than 1 hour in the future
    modifier onlyValidTimestamp(uint256 timestamp) virtual {
        unchecked {
            require(
                timestamp < block.timestamp + 1 hours,
                "Timestamp not valid"
            );
        }
        _;
    }

    /// @notice Updates the Beacon set using the current values of its Beacons
    /// @dev As an oddity, this function still works if some of the IDs in
    /// `beaconIds` belong to Beacon sets rather than Beacons. This can be used
    /// to implement hierarchical Beacon sets.
    /// @param beaconIds Beacon IDs
    /// @return beaconSetId Beacon set ID
    function updateBeaconSetWithBeacons(
        bytes32[] memory beaconIds
    ) public override returns (bytes32 beaconSetId) {
        (int224 updatedValue, uint32 updatedTimestamp) = aggregateBeacons(
            beaconIds
        );
        beaconSetId = deriveBeaconSetId(beaconIds);
        DataFeed storage beaconSet = _dataFeeds[beaconSetId];
        if (beaconSet.timestamp == updatedTimestamp) {
            require(
                beaconSet.value != updatedValue,
                "Does not update Beacon set"
            );
        }
        _dataFeeds[beaconSetId] = DataFeed({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        emit UpdatedBeaconSetWithBeacons(
            beaconSetId,
            updatedValue,
            updatedTimestamp
        );
    }

    /// @notice Reads the data feed with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithId(
        bytes32 dataFeedId
    ) internal view returns (int224 value, uint32 timestamp) {
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        require(timestamp > 0, "Data feed not initialized");
    }

    /// @notice Derives the Beacon ID from the Airnode address and template ID
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @return beaconId Beacon ID
    function deriveBeaconId(
        address airnode,
        bytes32 templateId
    ) internal pure returns (bytes32 beaconId) {
        beaconId = keccak256(abi.encodePacked(airnode, templateId));
    }

    /// @notice Derives the Beacon set ID from the Beacon IDs
    /// @dev Notice that `abi.encode()` is used over `abi.encodePacked()`
    /// @param beaconIds Beacon IDs
    /// @return beaconSetId Beacon set ID
    function deriveBeaconSetId(
        bytes32[] memory beaconIds
    ) internal pure returns (bytes32 beaconSetId) {
        beaconSetId = keccak256(abi.encode(beaconIds));
    }

    /// @notice Called privately to process the Beacon update
    /// @param beaconId Beacon ID
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @return updatedBeaconValue Updated Beacon value
    function processBeaconUpdate(
        bytes32 beaconId,
        uint256 timestamp,
        bytes calldata data
    )
        internal
        onlyValidTimestamp(timestamp)
        returns (int224 updatedBeaconValue)
    {
        updatedBeaconValue = decodeFulfillmentData(data);
        require(
            timestamp > _dataFeeds[beaconId].timestamp,
            "Does not update timestamp"
        );
        _dataFeeds[beaconId] = DataFeed({
            value: updatedBeaconValue,
            timestamp: uint32(timestamp)
        });
    }

    /// @notice Called privately to decode the fulfillment data
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @return decodedData Decoded fulfillment data
    function decodeFulfillmentData(
        bytes memory data
    ) internal pure returns (int224) {
        require(data.length == 32, "Data length not correct");
        int256 decodedData = abi.decode(data, (int256));
        require(
            decodedData >= type(int224).min && decodedData <= type(int224).max,
            "Value typecasting error"
        );
        return int224(decodedData);
    }

    /// @notice Called privately to aggregate the Beacons and return the result
    /// @param beaconIds Beacon IDs
    /// @return value Aggregation value
    /// @return timestamp Aggregation timestamp
    function aggregateBeacons(
        bytes32[] memory beaconIds
    ) internal view returns (int224 value, uint32 timestamp) {
        uint256 beaconCount = beaconIds.length;
        require(beaconCount > 1, "Specified less than two Beacons");
        int256[] memory values = new int256[](beaconCount);
        int256[] memory timestamps = new int256[](beaconCount);
        for (uint256 ind = 0; ind < beaconCount; ) {
            DataFeed storage dataFeed = _dataFeeds[beaconIds[ind]];
            values[ind] = dataFeed.value;
            timestamps[ind] = int256(uint256(dataFeed.timestamp));
            unchecked {
                ind++;
            }
        }
        value = int224(median(values));
        timestamp = uint32(uint256(median(timestamps)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDapiServer.sol";
import "./IBeaconUpdatesWithSignedData.sol";

interface IApi3ServerV1 is IOevDapiServer, IBeaconUpdatesWithSignedData {
    function readDataFeedWithId(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHash(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) external view returns (int224 value, uint32 timestamp);

    function dataFeeds(
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);

    function oevProxyToIdToDataFeed(
        address proxy,
        bytes32 dataFeedId
    ) external view returns (int224 value, uint32 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IBeaconUpdatesWithSignedData is IDataFeedServer {
    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bytes32 beaconId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../access-control-registry/interfaces/IAccessControlRegistryAdminnedWithManager.sol";
import "./IDataFeedServer.sol";

interface IDapiServer is
    IAccessControlRegistryAdminnedWithManager,
    IDataFeedServer
{
    event SetDapiName(
        bytes32 indexed dataFeedId,
        bytes32 indexed dapiName,
        address sender
    );

    function setDapiName(bytes32 dapiName, bytes32 dataFeedId) external;

    function dapiNameToDataFeedId(
        bytes32 dapiName
    ) external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function DAPI_NAME_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    function dapiNameSetterRole() external view returns (bytes32);

    function dapiNameHashToDataFeedId(
        bytes32 dapiNameHash
    ) external view returns (bytes32 dataFeedId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/IExtendedSelfMulticall.sol";

interface IDataFeedServer is IExtendedSelfMulticall {
    event UpdatedBeaconWithSignedData(
        bytes32 indexed beaconId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconSetWithBeacons(
        bytes32 indexed beaconSetId,
        int224 value,
        uint32 timestamp
    );

    function updateBeaconSetWithBeacons(
        bytes32[] memory beaconIds
    ) external returns (bytes32 beaconSetId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOevDataFeedServer.sol";
import "./IDapiServer.sol";

interface IOevDapiServer is IOevDataFeedServer, IDapiServer {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDataFeedServer.sol";

interface IOevDataFeedServer is IDataFeedServer {
    event UpdatedOevProxyBeaconWithSignedData(
        bytes32 indexed beaconId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedOevProxyBeaconSetWithSignedData(
        bytes32 indexed beaconSetId,
        address indexed proxy,
        bytes32 indexed updateId,
        int224 value,
        uint32 timestamp
    );

    event Withdrew(
        address indexed oevProxy,
        address oevBeneficiary,
        uint256 amount
    );

    function updateOevProxyDataFeedWithSignedData(
        address oevProxy,
        bytes32 dataFeedId,
        bytes32 updateId,
        uint256 timestamp,
        bytes calldata data,
        bytes[] calldata packedOevUpdateSignatures
    ) external payable;

    function withdraw(address oevProxy) external;

    function oevProxyToBalance(
        address oevProxy
    ) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./OevDataFeedServer.sol";
import "./DapiServer.sol";
import "./interfaces/IOevDapiServer.sol";

/// @title Contract that serves OEV dAPIs
contract OevDapiServer is OevDataFeedServer, DapiServer, IOevDapiServer {
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager
    ) DapiServer(_accessControlRegistry, _adminRoleDescription, _manager) {}

    /// @notice Reads the data feed as the OEV proxy with dAPI name hash
    /// @param dapiNameHash dAPI name hash
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithDapiNameHashAsOevProxy(
        bytes32 dapiNameHash
    ) internal view returns (int224 value, uint32 timestamp) {
        bytes32 dataFeedId = dapiNameHashToDataFeedId[dapiNameHash];
        require(dataFeedId != bytes32(0), "dAPI name not set");
        DataFeed storage oevDataFeed = _oevProxyToIdToDataFeed[msg.sender][
            dataFeedId
        ];
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        if (oevDataFeed.timestamp > dataFeed.timestamp) {
            (value, timestamp) = (oevDataFeed.value, oevDataFeed.timestamp);
        } else {
            (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        }
        require(timestamp > 0, "Data feed not initialized");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./DataFeedServer.sol";
import "./interfaces/IOevDataFeedServer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./proxies/interfaces/IOevProxy.sol";

/// @title Contract that serves OEV Beacons and Beacon sets
/// @notice OEV Beacons and Beacon sets can be updated by the winner of the
/// respective OEV auctions. The beneficiary can withdraw the proceeds from
/// this contract.
contract OevDataFeedServer is DataFeedServer, IOevDataFeedServer {
    using ECDSA for bytes32;

    /// @notice Data feed with ID specific to the OEV proxy
    /// @dev This implies that an update as a result of an OEV auction only
    /// affects contracts that read through the respective proxy that the
    /// auction was being held for
    mapping(address => mapping(bytes32 => DataFeed))
        internal _oevProxyToIdToDataFeed;

    /// @notice Accumulated OEV auction proceeds for the specific proxy
    mapping(address => uint256) public override oevProxyToBalance;

    /// @notice Updates a data feed that the OEV proxy reads using the
    /// aggregation signed by the absolute majority of the respective Airnodes
    /// for the specific bid
    /// @dev For when the data feed being updated is a Beacon set, an absolute
    /// majority of the Airnodes that power the respective Beacons must sign
    /// the aggregated value and timestamp. While doing so, the Airnodes should
    /// refer to data signed to update an absolute majority of the respective
    /// Beacons. The Airnodes should require the data to be fresh enough (e.g.,
    /// at most 2 minutes-old), and tightly distributed around the resulting
    /// aggregation (e.g., within 1% deviation), and reject to provide an OEV
    /// proxy data feed update signature if these are not satisfied.
    /// @param oevProxy OEV proxy that reads the data feed
    /// @param dataFeedId Data feed ID
    /// @param updateId Update ID
    /// @param timestamp Signature timestamp
    /// @param data Update data (an `int256` encoded in contract ABI)
    /// @param packedOevUpdateSignatures Packed OEV update signatures, which
    /// include the Airnode address, template ID and these signed with the OEV
    /// update hash
    function updateOevProxyDataFeedWithSignedData(
        address oevProxy,
        bytes32 dataFeedId,
        bytes32 updateId,
        uint256 timestamp,
        bytes calldata data,
        bytes[] calldata packedOevUpdateSignatures
    ) external payable override onlyValidTimestamp(timestamp) {
        require(
            timestamp > _oevProxyToIdToDataFeed[oevProxy][dataFeedId].timestamp,
            "Does not update timestamp"
        );
        bytes32 oevUpdateHash = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                oevProxy,
                dataFeedId,
                updateId,
                timestamp,
                data,
                msg.sender,
                msg.value
            )
        );
        int224 updatedValue = decodeFulfillmentData(data);
        uint32 updatedTimestamp = uint32(timestamp);
        uint256 beaconCount = packedOevUpdateSignatures.length;
        if (beaconCount > 1) {
            bytes32[] memory beaconIds = new bytes32[](beaconCount);
            uint256 validSignatureCount;
            for (uint256 ind = 0; ind < beaconCount; ) {
                bool signatureIsNotOmitted;
                (
                    signatureIsNotOmitted,
                    beaconIds[ind]
                ) = unpackAndValidateOevUpdateSignature(
                    oevUpdateHash,
                    packedOevUpdateSignatures[ind]
                );
                if (signatureIsNotOmitted) {
                    unchecked {
                        validSignatureCount++;
                    }
                }
                unchecked {
                    ind++;
                }
            }
            // "Greater than or equal to" is not enough because full control
            // of aggregation requires an absolute majority
            require(
                validSignatureCount > beaconCount / 2,
                "Not enough signatures"
            );
            require(
                dataFeedId == deriveBeaconSetId(beaconIds),
                "Beacon set ID mismatch"
            );
            emit UpdatedOevProxyBeaconSetWithSignedData(
                dataFeedId,
                oevProxy,
                updateId,
                updatedValue,
                updatedTimestamp
            );
        } else if (beaconCount == 1) {
            {
                (
                    bool signatureIsNotOmitted,
                    bytes32 beaconId
                ) = unpackAndValidateOevUpdateSignature(
                        oevUpdateHash,
                        packedOevUpdateSignatures[0]
                    );
                require(signatureIsNotOmitted, "Missing signature");
                require(dataFeedId == beaconId, "Beacon ID mismatch");
            }
            emit UpdatedOevProxyBeaconWithSignedData(
                dataFeedId,
                oevProxy,
                updateId,
                updatedValue,
                updatedTimestamp
            );
        } else {
            revert("Did not specify any Beacons");
        }
        _oevProxyToIdToDataFeed[oevProxy][dataFeedId] = DataFeed({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        oevProxyToBalance[oevProxy] += msg.value;
    }

    /// @notice Withdraws the balance of the OEV proxy to the respective
    /// beneficiary account
    /// @dev This does not require the caller to be the beneficiary because we
    /// expect that in most cases, the OEV beneficiary will be a contract that
    /// will not be able to make arbitrary calls. Our choice can be worked
    /// around by implementing a beneficiary proxy.
    /// @param oevProxy OEV proxy
    function withdraw(address oevProxy) external override {
        address oevBeneficiary = IOevProxy(oevProxy).oevBeneficiary();
        require(oevBeneficiary != address(0), "Beneficiary address zero");
        uint256 balance = oevProxyToBalance[oevProxy];
        require(balance != 0, "OEV proxy balance zero");
        oevProxyToBalance[oevProxy] = 0;
        emit Withdrew(oevProxy, oevBeneficiary, balance);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = oevBeneficiary.call{value: balance}("");
        require(success, "Withdrawal reverted");
    }

    /// @notice Reads the data feed as the OEV proxy with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function _readDataFeedWithIdAsOevProxy(
        bytes32 dataFeedId
    ) internal view returns (int224 value, uint32 timestamp) {
        DataFeed storage oevDataFeed = _oevProxyToIdToDataFeed[msg.sender][
            dataFeedId
        ];
        DataFeed storage dataFeed = _dataFeeds[dataFeedId];
        if (oevDataFeed.timestamp > dataFeed.timestamp) {
            (value, timestamp) = (oevDataFeed.value, oevDataFeed.timestamp);
        } else {
            (value, timestamp) = (dataFeed.value, dataFeed.timestamp);
        }
        require(timestamp > 0, "Data feed not initialized");
    }

    /// @notice Called privately to unpack and validate the OEV update
    /// signature
    /// @param oevUpdateHash OEV update hash
    /// @param packedOevUpdateSignature Packed OEV update signature, which
    /// includes the Airnode address, template ID and these signed with the OEV
    /// update hash
    /// @return signatureIsNotOmitted If the signature is omitted in
    /// `packedOevUpdateSignature`
    /// @return beaconId Beacon ID
    function unpackAndValidateOevUpdateSignature(
        bytes32 oevUpdateHash,
        bytes calldata packedOevUpdateSignature
    ) private pure returns (bool signatureIsNotOmitted, bytes32 beaconId) {
        (address airnode, bytes32 templateId, bytes memory signature) = abi
            .decode(packedOevUpdateSignature, (address, bytes32, bytes));
        beaconId = deriveBeaconId(airnode, templateId);
        if (signature.length != 0) {
            require(
                (
                    keccak256(abi.encodePacked(oevUpdateHash, templateId))
                        .toEthSignedMessageHash()
                ).recover(signature) == airnode,
                "Signature mismatch"
            );
            signatureIsNotOmitted = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOevProxy {
    function oevBeneficiary() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SelfMulticall.sol";
import "./interfaces/IExtendedSelfMulticall.sol";

/// @title Contract that extends SelfMulticall to fetch some of the global
/// variables
/// @notice Available global variables are limited to the ones that Airnode
/// tends to need
contract ExtendedSelfMulticall is SelfMulticall, IExtendedSelfMulticall {
    /// @notice Returns the chain ID
    /// @return Chain ID
    function getChainId() external view override returns (uint256) {
        return block.chainid;
    }

    /// @notice Returns the account balance
    /// @param account Account address
    /// @return Account balance
    function getBalance(
        address account
    ) external view override returns (uint256) {
        return account.balance;
    }

    /// @notice Returns if the account contains bytecode
    /// @dev An account not containing any bytecode does not indicate that it
    /// is an EOA or it will not contain any bytecode in the future.
    /// Contract construction and `SELFDESTRUCT` updates the bytecode at the
    /// end of the transaction.
    /// @return If the account contains bytecode
    function containsBytecode(
        address account
    ) external view override returns (bool) {
        return account.code.length > 0;
    }

    /// @notice Returns the current block number
    /// @return Current block number
    function getBlockNumber() external view override returns (uint256) {
        return block.number;
    }

    /// @notice Returns the current block timestamp
    /// @return Current block timestamp
    function getBlockTimestamp() external view override returns (uint256) {
        return block.timestamp;
    }

    /// @notice Returns the current block basefee
    /// @return Current block basefee
    function getBlockBasefee() external view override returns (uint256) {
        return block.basefee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExpiringMetaTxForwarder {
    event ExecutedMetaTx(bytes32 indexed metaTxHash);

    event CanceledMetaTx(bytes32 indexed metaTxHash);

    struct ExpiringMetaTx {
        address from;
        address to;
        bytes data;
        uint256 expirationTimestamp;
    }

    function execute(
        ExpiringMetaTx calldata metaTx,
        bytes calldata signature
    ) external returns (bytes memory returndata);

    function cancel(ExpiringMetaTx calldata metaTx) external;

    function metaTxWithHashIsExecutedOrCanceled(
        bytes32 metaTxHash
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISelfMulticall.sol";

interface IExtendedSelfMulticall is ISelfMulticall {
    function getChainId() external view returns (uint256);

    function getBalance(address account) external view returns (uint256);

    function containsBytecode(address account) external view returns (bool);

    function getBlockNumber() external view returns (uint256);

    function getBlockTimestamp() external view returns (uint256);

    function getBlockBasefee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISelfMulticall {
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory returndata);

    function tryMulticall(
        bytes[] calldata data
    ) external returns (bool[] memory successes, bytes[] memory returndata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISelfMulticall.sol";

/// @title Contract that enables calls to the inheriting contract to be batched
/// @notice Implements two ways of batching, one requires none of the calls to
/// revert and the other tolerates individual calls reverting
/// @dev This implementation uses delegatecall for individual function calls.
/// Since delegatecall is a message call, it can only be made to functions that
/// are externally visible. This means that a contract cannot multicall its own
/// functions that use internal/private visibility modifiers.
/// Refer to OpenZeppelin's Multicall.sol for a similar implementation.
contract SelfMulticall is ISelfMulticall {
    /// @notice Batches calls to the inheriting contract and reverts as soon as
    /// one of the batched calls reverts
    /// @param data Array of calldata of batched calls
    /// @return returndata Array of returndata of batched calls
    function multicall(
        bytes[] calldata data
    ) external override returns (bytes[] memory returndata) {
        uint256 callCount = data.length;
        returndata = new bytes[](callCount);
        for (uint256 ind = 0; ind < callCount; ) {
            bool success;
            // solhint-disable-next-line avoid-low-level-calls
            (success, returndata[ind]) = address(this).delegatecall(data[ind]);
            if (!success) {
                bytes memory returndataWithRevertData = returndata[ind];
                if (returndataWithRevertData.length > 0) {
                    // Adapted from OpenZeppelin's Address.sol
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        let returndata_size := mload(returndataWithRevertData)
                        revert(
                            add(32, returndataWithRevertData),
                            returndata_size
                        )
                    }
                } else {
                    revert("Multicall: No revert string");
                }
            }
            unchecked {
                ind++;
            }
        }
    }

    /// @notice Batches calls to the inheriting contract but does not revert if
    /// any of the batched calls reverts
    /// @param data Array of calldata of batched calls
    /// @return successes Array of success conditions of batched calls
    /// @return returndata Array of returndata of batched calls
    function tryMulticall(
        bytes[] calldata data
    )
        external
        override
        returns (bool[] memory successes, bytes[] memory returndata)
    {
        uint256 callCount = data.length;
        successes = new bool[](callCount);
        returndata = new bytes[](callCount);
        for (uint256 ind = 0; ind < callCount; ) {
            // solhint-disable-next-line avoid-low-level-calls
            (successes[ind], returndata[ind]) = address(this).delegatecall(
                data[ind]
            );
            unchecked {
                ind++;
            }
        }
    }
}