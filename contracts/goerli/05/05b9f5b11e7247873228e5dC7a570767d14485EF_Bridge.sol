/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// File: @openzeppelin/contracts/access/IAccessControl.sol
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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/utils/math/Math.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol

// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/interfaces/IDepositExecute.sol

pragma solidity 0.8.17;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IDepositExecute {
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param resourceID ID of the resource that is being bridged.
        @param destinationChainID Chain ID deposit is expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of additional data needed for a specific deposit.
     */
    function deposit(bytes32 resourceID, uint8 destinationChainID, uint64 depositNonce, address depositer, bytes calldata data) external payable;

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
        @param resourceID ID of the resource that is being bridged.
        @param data Consists of additional data needed for a specific deposit execution.
     */
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}

// File: contracts/interfaces/IBridge.sol

pragma solidity 0.8.17;

/**
    @title Interface for Bridge contract.
    @author ChainSafe Systems.
 */
interface IBridge {
    /**
        @notice Exposing getter for {_chainID} instead of forcing the use of call.
        @return uint8 The {_chainID} that is currently set for the Bridge contract.
     */
    function _chainID() external returns (uint8);

    /**
        @notice Exposing getter for {_fee} instead of forcing the use of call.
        @return uint256 The {_fee} that is currently set for the Bridge contract.
     */
    function _fee() external returns (uint256);
}

// File: contracts/interfaces/IERCHandler.sol

pragma solidity 0.8.17;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author ChainSafe Systems.
 */
interface IERCHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;
    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external;
    /**
        @notice Used to manually release funds {native tokens} from Native safes.
        @param recipient Address to release tokens to.
        @param amount The amount of native token to release.
     */
    function withdraw(address recipient, uint256 amount) external;
    /**
        @notice Used to manually release funds {erc20 tokens, nft} from ERC safes.
        @param tokenAddress Address of token contract to release
        @param recipient Address to release tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
     */
    function withdrawToken(address tokenAddress, address recipient, uint256 amountOrTokenID) external;
}

// File: contracts/interfaces/IGenericHandler.sol

pragma solidity 0.8.17;

/**
    @title Interface for handler that handles generic deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IGenericHandler {
    /**
        @notice Correlates {resourceID} with {contractAddress}, {depositFunctionSig}, and {executeFunctionSig}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
        @param depositFunctionSig Function signature of method to be called in {contractAddress} when a deposit is made.
        @param executeFunctionSig Function signature of method to be called in {contractAddress} when a deposit is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress, bytes4 depositFunctionSig, bytes4 executeFunctionSig) external;
}

// File: contracts/Bridge.sol

pragma solidity 0.8.17;







/**
    @title Facilitates deposits, creation and votiing of deposit proposals, and deposit executions.
    @author ChainSafe Systems.
 */
contract Bridge is Pausable, AccessControl, ReentrancyGuard {
    uint8   public _chainID;
    uint256 public _totalRelayers;
    uint256 public _totalProposals;
    uint256 public _fee;
    uint256 public _maxFee;
    uint256 public _expiry;

    enum Vote {No, Yes}

    enum ProposalStatus {Inactive, Active, Passed, Executed, Cancelled}

    struct Proposal {
        bytes32 _resourceID;
        bytes32 _dataHash;
        address[] _yesVotes;
        address[] _noVotes;
        ProposalStatus _status;
        uint256 _proposedBlock;
    }

    // destinationChainID => number of deposits
    mapping(uint8 => uint64) public _depositCounts;
    // resourceID => handler address
    mapping(bytes32 => address) public _resourceIDToHandlerAddress;
    // depositNonce => destinationChainID => bytes
    mapping(uint64 => mapping(uint8 => bytes)) public _depositRecords;
    // destinationChainID + depositNonce => dataHash => Proposal
    mapping(uint72 => mapping(bytes32 => Proposal)) public _proposals;
    // destinationChainID + depositNonce => dataHash => relayerAddress => bool
    mapping(uint72 => mapping(bytes32 => mapping(address => bool))) public _hasVotedOnProposal;
    // chainID => bool
    mapping(uint8 => bool) public _chainIDWhitelist;

    event RelayerThresholdChanged(uint indexed newThreshold);
    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);
    event ChainIDWhitelisted(uint8 indexed chainID);
    event ChainIDUnwhitelisted(uint8 indexed chainID);
    event Deposit(
        uint8   indexed destinationChainID,
        bytes32 indexed resourceID,
        uint64  indexed depositNonce
    );
    event ProposalEvent(
        uint8           indexed originChainID,
        uint64          indexed depositNonce,
        ProposalStatus  indexed status,
        bytes32 resourceID,
        bytes32 dataHash
    );

    event ProposalVote(
        uint8   indexed originChainID,
        uint64  indexed depositNonce,
        ProposalStatus indexed status,
        bytes32 resourceID
    );

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyAdminOrRelayer() {
        _onlyAdminOrRelayer();
        _;
    }

    modifier onlyRelayers() {
        _onlyRelayers();
        _;
    }

    function _onlyAdminOrRelayer() private {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(RELAYER_ROLE, msg.sender),
            "sender is not relayer or admin");
    }

    function _onlyAdmin() private {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sender doesn't have admin role");
    }

    function _onlyRelayers() private {
        require(hasRole(RELAYER_ROLE, msg.sender), "sender doesn't have relayer role");
    }

    /**
        @notice Initializes Bridge, creates and grants {msg.sender} the admin role,
        creates and grants {initialRelayers} the relayer role.
        @param chainID ID of chain the Bridge contract exists on.
        @param initialRelayers Addresses that should be initially granted the relayer role.
        @param fee Amount in wei to pay to deposit.
        @param maxFee Max. value for fee.
        @param expiry Number of blocks max before a deposit proposal is considered expired
        @param initialChainIDWhitelist List of Chain Ids that user can bridge their funds to
     */
    constructor (uint8 chainID, address[] memory initialRelayers, uint256 fee, uint256 maxFee, uint256 expiry, uint8[] memory initialChainIDWhitelist) {
        require(fee <= maxFee, "Fee exceeds max fee");
        _chainID = chainID;
        _fee = fee;
        _maxFee = maxFee;
        _expiry = expiry;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(RELAYER_ROLE, DEFAULT_ADMIN_ROLE);

        for (uint i; i < initialRelayers.length; i++) {
            grantRole(RELAYER_ROLE, initialRelayers[i]);
            _totalRelayers++;
        }

        for (uint8 i; i < initialChainIDWhitelist.length; i++) {
            require(initialChainIDWhitelist[i] != chainID, "Initial whitelisted chainID cannot be Id of chain the Bridge exists on");
            _chainIDWhitelist[initialChainIDWhitelist[i]] = true;
            emit ChainIDWhitelisted(initialChainIDWhitelist[i]);
        }
    }

    /**
        @notice Returns true if {relayer} has the relayer role.
        @param relayer Address to check.
     */
    function isRelayer(address relayer) external view returns (bool) {
        return hasRole(RELAYER_ROLE, relayer);
    }

    /**
        @notice Removes admin role from {msg.sender} and grants it to {newAdmin}.
        @notice Only callable by an address that currently has the admin role.
        @param newAdmin Address that admin role will be granted to.
     */
    function renounceAdmin(address newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @notice Pauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminPauseTransfers() external onlyAdmin {
        _pause();
    }

    /**
        @notice Unpauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminUnpauseTransfers() external onlyAdmin {
        _unpause();
    }

    /**
        @notice Adds a new chainID to the whitelist
        @notice Only callable by an address that currently has the admin role.
        @param chainID New chain ID to add to whitelist
        @notice Emits {ChainIDWhitelisted} event.
     */
    function adminWhitelistChainID(uint8 chainID) external onlyAdmin {
        require(_chainID != chainID, "chainID cannot be ID of chain the Bridge exists on");
        require(!_chainIDWhitelist[chainID], "Chain ID already whitelisted");
        _chainIDWhitelist[chainID] = true;
        emit ChainIDWhitelisted(chainID);
    }

    /**
        @notice Removes existing chainID from the whitelist
        @notice Only callable by an address that currently has the admin role.
        @param chainID Chain ID to remove from whitelist
        @notice Emits {ChainIDUnwhitelisted} event.
     */
    function adminUnwhitelistChainID(uint8 chainID) external onlyAdmin {
        require(_chainIDWhitelist[chainID], "Chain ID not whitelisted");
        _chainIDWhitelist[chainID] = false;
        emit ChainIDUnwhitelisted(chainID);
    }

    /**
        @notice Returns true if {chainID} is whitelisted
        @param chainID chain ID to check.
     */
    function isChainIDWhitelisted(uint8 chainID) external view returns (bool) {
        return _chainIDWhitelist[chainID];
    }

    /**
        @notice Grants {relayerAddress} the relayer role and increases {_totalRelayer} count.
        @notice Only callable by an address that currently has the admin role.
        @param relayerAddress Address of relayer to be added.
        @notice Emits {RelayerAdded} event.
     */
    function adminAddRelayer(address relayerAddress) external onlyAdmin {
        require(!hasRole(RELAYER_ROLE, relayerAddress), "addr already has relayer role!");
        grantRole(RELAYER_ROLE, relayerAddress);
        emit RelayerAdded(relayerAddress);
        _totalRelayers++;
    }

    /**
        @notice Removes relayer role for {relayerAddress} and decreases {_totalRelayer} count.
        @notice Only callable by an address that currently has the admin role.
        @param relayerAddress Address of relayer to be removed.
        @notice Emits {RelayerRemoved} event.
     */
    function adminRemoveRelayer(address relayerAddress) external onlyAdmin {
        require(hasRole(RELAYER_ROLE, relayerAddress), "addr doesn't have relayer role!");
        revokeRole(RELAYER_ROLE, relayerAddress);
        emit RelayerRemoved(relayerAddress);
        _totalRelayers--;
    }

    /**
        @notice Sets a new resource for handler contracts that use the IERCHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function adminSetResource(address handlerAddress, bytes32 resourceID, address tokenAddress) external onlyAdmin {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setResource(resourceID, tokenAddress);
    }

    /**
        @notice Sets a new resource for handler contracts that use the IGenericHandler interface,
        and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function adminSetGenericResource(
        address handlerAddress,
        bytes32 resourceID,
        address contractAddress,
        bytes4 depositFunctionSig,
        bytes4 executeFunctionSig
    ) external onlyAdmin {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IGenericHandler handler = IGenericHandler(handlerAddress);
        handler.setResource(resourceID, contractAddress, depositFunctionSig, executeFunctionSig);
    }

    /**
        @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
        @notice Only callable by an address that currently has the admin role.
        @param handlerAddress Address of handler resource will be set for.
        @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function adminSetBurnable(address handlerAddress, address tokenAddress) external onlyAdmin {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setBurnable(tokenAddress);
    }

    /**
        @notice Returns a proposal.
        @param originChainID Chain ID deposit originated from.
        @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param dataHash Hash of data to be provided when deposit proposal is executed.
        @return Proposal which consists of:
        - _dataHash Hash of data to be provided when deposit proposal is executed.
        - _yesVotes Number of votes in favor of proposal.
        - _noVotes Number of votes against proposal.
        - _status Current status of proposal.
     */
    function getProposal(uint8 originChainID, uint64 depositNonce, bytes32 dataHash) external view returns (Proposal memory) {
        uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(originChainID);
        return _proposals[nonceAndID][dataHash];
    }

    /**
        @notice Changes deposit fee.
        @notice Only callable by admin.
        @param newFee Value {_fee} will be updated to.
     */
    function adminChangeFee(uint newFee) external onlyAdmin {
        require(_fee != newFee, "Current fee is equal to new fee");
        require(newFee <= _maxFee, "New fee exceeds max fee");
        _fee = newFee;
    }

    /**
        @notice Used to manually withdraw funds(native token) from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param recipient Address to withdraw tokens to.
        @param amount The amount of native token to release.
     */
    function adminWithdraw(
        address handlerAddress,
        address recipient,
        uint256 amount
    ) external onlyAdmin nonReentrant {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdraw(recipient, amount);
    }

    /**
        @notice Used to manually withdraw funds(ERC20 & ERC721) from ERC safes.
        @param handlerAddress Address of handler to withdraw from.
        @param tokenAddress Address of token to withdraw.
        @param recipient Address to withdraw tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to withdraw.
     */
    function adminWithdrawToken(
        address handlerAddress,
        address tokenAddress,
        address recipient,
        uint256 amountOrTokenID
    ) external onlyAdmin nonReentrant {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdrawToken(tokenAddress, recipient, amountOrTokenID);
    }

    /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param destinationChainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of handler to be used for deposit.
        @param data Additional data to be passed to specified handler.
        @notice Emits {Deposit} event.
     */
    function deposit(uint8 destinationChainID, bytes32 resourceID, bytes calldata data) external payable whenNotPaused {
        require(destinationChainID != _chainID, "DestinationChainID cannot be the same as current Bridge chainID");
        require(_chainIDWhitelist[destinationChainID], "DestinationChainID not whitelisted");
        require(msg.value >= _fee, "Value too small to pay Fee");

        address handler = _resourceIDToHandlerAddress[resourceID];
        require(handler != address(0), "ResourceID not mapped to handler");

        uint64 depositNonce = ++_depositCounts[destinationChainID];
        _depositRecords[depositNonce][destinationChainID] = data;

        IDepositExecute depositHandler = IDepositExecute(handler);

        depositHandler.deposit{value: msg.value - _fee}(resourceID, destinationChainID, depositNonce, msg.sender, data);

        emit Deposit(destinationChainID, resourceID, depositNonce);
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(uint8 chainID, uint64 depositNonce, bytes32 resourceID, bytes32 dataHash) external onlyRelayers whenNotPaused {

        uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(chainID);
        Proposal storage proposal = _proposals[nonceAndID][dataHash];

        require(_resourceIDToHandlerAddress[resourceID] != address(0), "no handler for resourceID");
        require(uint(proposal._status) <= 1, "proposal already passed/executed/cancelled");
        require(!_hasVotedOnProposal[nonceAndID][dataHash][msg.sender], "relayer already voted");

        if (uint(proposal._status) == 0) {
            ++_totalProposals;
            _proposals[nonceAndID][dataHash] = Proposal({
                _resourceID : resourceID,
                _dataHash : dataHash,
                _yesVotes : new address[](1),
                _noVotes : new address[](0),
                _status : ProposalStatus.Active,
                _proposedBlock : block.number
                });

            proposal._yesVotes[0] = msg.sender;
            emit ProposalEvent(chainID, depositNonce, ProposalStatus.Active, resourceID, dataHash);
        } else {
            if ((block.number - proposal._proposedBlock) > _expiry) {
                // if the number of blocks that has passed since this proposal was
                // submitted exceeds the expiry threshold set, cancel the proposal
                proposal._status = ProposalStatus.Cancelled;
                emit ProposalEvent(chainID, depositNonce, ProposalStatus.Cancelled, resourceID, dataHash);
            } else {
                require(dataHash == proposal._dataHash, "datahash mismatch");
                proposal._yesVotes.push(msg.sender);


            }

        }
        if (proposal._status != ProposalStatus.Cancelled) {
            _hasVotedOnProposal[nonceAndID][dataHash][msg.sender] = true;
            emit ProposalVote(chainID, depositNonce, proposal._status, resourceID);

            // If _totalRelayers is 1, then auto finalize
            // or if quorum() has been reached
            if (_totalRelayers == 1 || proposal._yesVotes.length >= quorum()) {
                proposal._status = ProposalStatus.Passed;

                emit ProposalEvent(chainID, depositNonce, ProposalStatus.Passed, resourceID, dataHash);
            }
        }

    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param dataHash Hash of data originally provided when deposit was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(uint8 chainID, uint64 depositNonce, bytes32 dataHash) external onlyAdminOrRelayer {
        uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(chainID);
        Proposal storage proposal = _proposals[nonceAndID][dataHash];

        require(proposal._status != ProposalStatus.Cancelled, "Proposal already cancelled");
        require((block.number - proposal._proposedBlock) > _expiry, "Proposal not at expiry threshold");

        proposal._status = ProposalStatus.Cancelled;
        emit ProposalEvent(chainID, depositNonce, ProposalStatus.Cancelled, proposal._resourceID, proposal._dataHash);

    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param chainID ID of chain deposit originated from.
        @param resourceID ResourceID to be used when making deposits.
        @param depositNonce ID of deposited generated by origin Bridge contract.
        @param data Data originally provided when deposit was made.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(uint8 chainID, uint64 depositNonce, bytes calldata data, bytes32 resourceID) external onlyRelayers whenNotPaused {
        address handler = _resourceIDToHandlerAddress[resourceID];
        uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(chainID);
        bytes32 dataHash = keccak256(abi.encodePacked(handler, data));
        Proposal storage proposal = _proposals[nonceAndID][dataHash];

        require(proposal._status != ProposalStatus.Inactive, "proposal is not active");
        require(proposal._status == ProposalStatus.Passed, "proposal already transferred");
        require(dataHash == proposal._dataHash, "data doesn't match datahash");

        proposal._status = ProposalStatus.Executed;

        IDepositExecute depositHandler = IDepositExecute(_resourceIDToHandlerAddress[proposal._resourceID]);
        depositHandler.executeProposal(proposal._resourceID, data);

        emit ProposalEvent(chainID, depositNonce, proposal._status, proposal._resourceID, proposal._dataHash);
    }

    /**
        @notice Transfers eth in the contract to the specified addresses. The parameters addrs and amounts are mapped 1-1.
        This means that the address at index 0 for addrs will receive the amount (in WEI) from amounts at index 0.
        @param addrs Array of addresses to transfer {amounts} to.
        @param amounts Array of amonuts to transfer to {addrs}.
     */
    function transferFunds(address payable[] calldata addrs, uint[] calldata amounts) external onlyAdmin {
        for (uint i = 0; i < addrs.length; i++) {
            addrs[i].call{value: amounts[i]}("");
        }
    }

    /**
        @notice Returns quorum necessary to pass a proposal
     */
    function quorum() public view returns (uint256) {
        return _totalRelayers * 2 / 3;
    }

    /**
        @notice Used for "locking" native tokens.
     */
    receive() external payable onlyAdmin { }

}