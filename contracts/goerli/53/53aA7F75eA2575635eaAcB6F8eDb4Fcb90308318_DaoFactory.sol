// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/IOuterCircleApp.sol";
import "../interfaces/IDaoController.sol";
import "./OuterCircleApp.sol";
import "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "../../lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

contract DaoController is OuterCircleApp, AccessControl, IDaoController {
    // ==================== EVENTS ====================

    event OCDaoControllerCreated(address indexed parentAddress);
    event OCProposalCreated(uint256 indexed propId);
    event OCProposalAccepted(uint256 indexed propId);
    event OCProposalRejected(uint256 indexed propId);
    event OCProposalExecuted(uint256 indexed propId);
    event OCVetoCasted(uint256 indexed propId);
    event OCChildApproved(address indexed daoController);
    event OCChildRemoved(address indexed daoController);
    event OCParentChanged(address indexed oldParent, address indexed newParent);
    event OCProposalExpirationTimeChanged(uint256 oldTime, uint256 newTime);
    event OCQuorumRequiredChanged(uint256 oldQuorum, uint256 newQuorum);

    // ==================== STORAGE ====================

    mapping(address => mapping(uint256 => VoteType)) private voted; // to track users previous votes for proposals by proposal id
    mapping(IDaoController => bool) public isChildDaoController; // dict of sub-DAOs
    uint256 private proposalCounter; // to change proposal IDs
    mapping(uint256 => Proposal) private proposals; // dict of all proposals by id
    uint256 public proposalExpirationTime; // time proposal to be able to vote for
    uint256 public quorumRequired; // minimal total number of votes to accept proposal
    IDaoController public immutable parentDaoController; // address of parrent dao controller (of which current dao controller is child of)

    mapping(string => bytes32) private _roleByName; // get role ID by string role name
    // all roles set to 0x00 (DEFAULT_ADMIM_ROLE) by default

    // ==================== CONSTRUCTOR ====================

    constructor(
        address _defaultAdminAddress,
        uint256 _proposalExpirationTime,
        uint256 _quorumRequired,
        IDaoController _parentDaoController
    )
        OuterCircleApp(
            "Default DAO Controller",
            "Default DAO Controller made from DAO Controller template. Do not use it in prodiction."
        )
    {
        proposalExpirationTime = _proposalExpirationTime;
        parentDaoController = _parentDaoController;
        quorumRequired = _quorumRequired;

        // set roles here or add special logic to add them
        // all unseted roles will be set to 0x00 (DEFAULT_ADMIN_ROLE)
        _roleByName["DEFAULT_ADMIN_ROLE"] = 0x00;
        _grantRole(_roleByName["DEFAULT_ADMIN_ROLE"], _defaultAdminAddress);

        // _roleByName["VETO_CASTER"] = keccak256("VETO_CASTER");
        // _grantRole(_roleByName["VETO_CASTER"], someAddress);

        emit OCDaoControllerCreated(address(_parentDaoController));
    }

    // ==================== PUBLIC FUNCTIONS ====================

    /**
     * @notice ERC165 interface support
     * @dev Need to identify DaoController
     * @param interfaceId unique id of the interface
     * @return Support or not
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC165, AccessControl, OuterCircleApp)
        returns (bool)
    {
        return interfaceId == type(IDaoController).interfaceId || interfaceId == type(IAccessControl).interfaceId
            || interfaceId == type(IOuterCircleApp).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Voting power of a member
     * @dev If DAO has a governance token, this function should return the token balances
     * @param _who Address to check power of
     * @return Voting power
     */
    function votingPowerOf(address _who) public pure returns (uint256) {
        return 10; // zero for all by default
    }

    // ==================== DAO FUNCTIONS ====================

    /**
     * @notice Create proposal
     * @dev Can be called only by PROPOSAL_CREATOR role
     * @param _pipeline List of Action proposed to execute
     */
    function createProposal(Action[] calldata _pipeline) external virtual onlyRole(_roleByName["PROPOSAL_CREATOR"]) {
        uint256 propId_ = proposalCounter++;

        Proposal storage prop = proposals[propId_];

        require(prop.status == ProposalStatus.NONE, "Proposal with this ID already exists");

        prop.status = ProposalStatus.EXISTS;
        prop.creationBlock = block.number;
        prop.creationTime = block.timestamp;

        // check for IRouter interface supporting
        for (uint256 i = 0; i < _pipeline.length; ++i) {
            Action calldata action = _pipeline[i];

            // if (trans.transType == ActionType.ROUTER) {
            //     require(
            //         IERC165(trans.to).supportsInterface(type(IRouter).interfaceId),
            //         "Router doesn't correspond IRouter interface"
            //     );
            // }

            prop.pipeline.push(action);
        }

        emit OCProposalCreated(propId_);
    }

    /**
     * @notice Vote for proposal
     * @dev Can be called only by PROPOSAL_VOTER role
     * @param _propId id of proposal
     * @param _decision vote decision (1 - yes, 2 - no, 3 - neutral)
     * @param _data list of transactions calldata
     */
    function voteProposal(uint256 _propId, VoteType _decision, bytes[] calldata _data)
        external
        virtual
        onlyRole(_roleByName["PROPOSAL_VOTER"])
    {
        require(!proposalExpired(_propId), "Proposal expired");

        Proposal storage proposal = proposals[_propId];

        require(proposal.status == ProposalStatus.EXISTS, "Proposal must exist");

        uint256 votingPower_ = votingPowerOf(msg.sender);

        require(votingPower_ > 0, "You have no voting power for this proposal");

        if (voted[msg.sender][_propId] == VoteType.FOR) {
            proposal.forVp -= votingPower_;
        }

        if (voted[msg.sender][_propId] == VoteType.AGAINST) {
            proposal.againstVp -= votingPower_;
        }

        if (voted[msg.sender][_propId] == VoteType.ABSTAIN) {
            proposal.abstainVp -= votingPower_;
        }

        voted[msg.sender][_propId] = _decision;

        if (_decision == VoteType.FOR) {
            proposal.forVp += votingPower_;
        } else if (_decision == VoteType.AGAINST) {
            proposal.againstVp += votingPower_;
        } else if (_decision == VoteType.ABSTAIN) {
            proposal.abstainVp += votingPower_;
        }

        // // updating router-transactions states
        // uint256 routerIndex_;
        // for (uint256 i = 0; i < proposal.pipeline.length; ++i) {
        //     Action storage trans = proposal.pipeline[i];
        //     if (trans.transType == TransType.ROUTER) {
        //         trans.data = IRouter(trans.to).onVote(_propId, i, _decision, votingPower_, _data[routerIndex_]);
        //         routerIndex_ += 1;
        //     }
        // }

        bool result = proposalAccepted(_propId);
        if (result) {
            proposal.status = ProposalStatus.ACCEPTED;
            emit OCProposalAccepted(_propId);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit OCProposalRejected(_propId);
        }
    }

    /**
     * @notice Result of proposal voting
     * @dev Logic of the acceptance might be changed
     * @param _propId proposal ID
     * @return Accepted or not
     */
    function proposalAccepted(uint256 _propId) public view virtual returns (bool) {
        Proposal storage proposal = proposals[_propId];

        uint256 totalVotes_ = proposal.forVp + proposal.againstVp + proposal.abstainVp;
        return proposal.forVp > proposal.againstVp && totalVotes_ >= quorumRequired;
    }

    /**
     * @notice Execute all transactions in accepted proposal
     * @dev Can be called only by PROPOSAL_EXECUTER role
     * @param _propId proposal ID
     */
    function executeProposal(uint256 _propId) external virtual onlyRole(_roleByName["PROPOSAL_EXECUTER"]) {
        require(!proposalExpired(_propId), "Proposal expired");

        Proposal storage proposal = proposals[_propId];

        require(proposal.status == ProposalStatus.ACCEPTED, "Proposal must be accepted");

        proposal.status = ProposalStatus.EXECUTED;

        for (uint256 i = 0; i < proposal.pipeline.length; ++i) {
            Action storage action = proposal.pipeline[i];
            (bool success_, bytes memory response_) = action.to.call{value: action.value}(action.data);

            require(success_, "Transaction failed");
        }

        emit OCProposalExecuted(_propId);
    }

    /**
     * @notice Forcibly decline proposal
     * @dev Can be called only by VETO_CASTER role
     * @param _propId proposal ID
     */
    function castVeto(uint256 _propId) external virtual onlyRole(_roleByName["VETO_CASTER"]) {
        emit OCVetoCasted(_propId);

        proposals[_propId].status = ProposalStatus.REJECTED;
    }

    /**
     * @notice Check expiration of proposal
     * @dev Expired proposals cannot be executed or voted for
     * @param _propId Proposal ID
     * @return Expired or not
     */
    function proposalExpired(uint256 _propId) public view virtual returns (bool) {
        return proposals[_propId].creationTime + proposalExpirationTime < block.timestamp;
    }

    /**
     * @notice Get proposal by its id
     * @dev This is necessary because getter for "proposals" cannot be created automatically
     * @param _propId Proposal ID
     * @return Struct of the proposal
     */
    function getProposal(uint256 _propId) public view virtual returns (Proposal memory) {
        return proposals[_propId];
    }

    /**
     * @notice Appropve another DaoController as a sub-DAO
     * @dev Can be called only by CHILD_DAO_APPROVER role
     * @param _daoController Address of the DaoController (sub-DAO)
     */
    function approveChildDaoController(IDaoController _daoController)
        external
        virtual
        onlyRole(_roleByName["CHILD_DAO_APPROVER"])
    {
        require(
            address(_daoController.parentDaoController()) == address(this),
            "This dao controller must be parent dao controller of the child"
        );
        require(!isChildDaoController[_daoController], "The dao controller is already a child");

        emit OCChildApproved(address(_daoController));

        isChildDaoController[_daoController] = true;
    }

    /**
     * @notice Remove sub-DAO
     * @dev Can be called only by CHILD_DAO_REMOVER role
     * @param _daoController Address of the sub-DAO to remove
     */
    function removeChildDaoController(IDaoController _daoController)
        external
        virtual
        onlyRole(_roleByName["CHILD_DAO_REMOVER"])
    {
        require(isChildDaoController[_daoController], "The dao controller is not a child");

        emit OCChildRemoved(address(_daoController));

        isChildDaoController[_daoController] = false;
    }

    /**
     * @notice Change proposal expiration time
     * @dev Can be called only by PROPOSAL_EXPIRATION_TIME_CHANGER role
     * @param _newTime New proposal exporation time
     */
    function changeProposalExpirationTime(uint256 _newTime)
        external
        virtual
        onlyRole(_roleByName["PROPOSAL_EXPIRATION_TIME_CHANGER"])
    {
        emit OCProposalExpirationTimeChanged(proposalExpirationTime, _newTime);

        proposalExpirationTime = _newTime;
    }

    /**
     * @notice Change quorum required for a proposal acceptance
     * @dev Can be called only by PROPOSAL_EXPIRATION_TIME_CHANGER role
     * @param _newQuorumRequired New proposal exporation time
     */
    function changeQuorumRequired(uint256 _newQuorumRequired)
        external
        virtual
        onlyRole(_roleByName["QUORUM_REQUIRED_CHANGER"])
    {
        emit OCQuorumRequiredChanged(quorumRequired, _newQuorumRequired);

        quorumRequired = _newQuorumRequired;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./DaoController.sol";

/**
 * @title This contract created just for simple DAO creation for OuterCictle MVP.
 * You can perceive it as mock contract for test purposes.
 */
contract DaoFactory {
    // ==================== PUBLIC FUNCTIONS ====================

    /**
     * @notice Deploy the most simple DAO ever
     * @dev Base contracts will be deployed
     * @param _proposalExpirationTime Time of proposals life in the DAO in sec
     * @param _quorumRequired Quorum required to accept proposals in the DAO
     * @param _parentRegistry Parent DaoController (of which the DAO will be sub-DAO of) or address(0) if none
     * @return daoController Created DaoController
     */
    function deployDao(uint256 _proposalExpirationTime, uint256 _quorumRequired, address _parentRegistry)
        external
        returns (DaoController daoController)
    {
        daoController =
            new DaoController(msg.sender, _proposalExpirationTime, _quorumRequired, IDaoController(_parentRegistry));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../interfaces/IOuterCircleApp.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

contract OuterCircleApp is ERC165, IOuterCircleApp {
    bytes32 public appId;

    event NewOuterCircleApp(address indexed appAddress, string name, string description);
    event AppUserFunctions(address indexed appAddress, uint8 numberOfUserFunctions, string[]);

    constructor(string memory name, string memory description) {
        // uint8 numberOfUserFunctions_ = 0; // change value to actual user functions number
        // string[] memory userFunctionsNames = new string[](numberOfUserFunctions_);
        // pass user functions names like below if there are any
        // userFunctionsNames[0] = "myFirstUserFunctionName"
        // userFunctionsNames[1] = "mySecondUserFunctionName"
        // ...

        emit NewOuterCircleApp(address(this), name, description);
        //emit AppUserFunctions(address(this), userFunctionsNames);
    }

    /**
     * @notice ERC165 interface support
     * @dev Need to identify OuterCircleApp
     * @param interfaceId unique id of the interface
     * @return Support or not
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC165, IOuterCircleApp)
        returns (bool)
    {
        return interfaceId == type(IOuterCircleApp).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";

struct Action {
    ActionType actionType;
    address to;
    bytes data;
    uint256 value;
}

enum ActionType {
    REGULAR,
    APP
}

enum ProposalStatus {
    NONE, // for uncreated proposals
    EXISTS,
    ACCEPTED,
    EXECUTED,
    REJECTED
}

struct Proposal {
    ProposalStatus status;
    Action[] pipeline;
    uint256 creationBlock;
    uint256 creationTime;
    uint256 forVp;
    uint256 againstVp;
    uint256 abstainVp;
}

enum VoteType {
    NONE,
    FOR,
    AGAINST,
    ABSTAIN
}

interface IDaoController is IERC165 {
    // Proposals functions
    function voteProposal(uint256 propId, VoteType decision, bytes[] calldata data) external;
    function createProposal(Action[] calldata _pipeline) external;
    function executeProposal(uint256 propId) external;
    function castVeto(uint256 propId) external;
    // Special functions
    function approveChildDaoController(IDaoController controller) external;
    function removeChildDaoController(IDaoController controller) external;
    function changeProposalExpirationTime(uint256 newTime) external;
    // View functions
    function proposalAccepted(uint256 propId) external view returns (bool);
    function proposalExpired(uint256 propId) external view returns (bool);
    function getProposal(uint256 propId) external view returns (Proposal memory);
    function votingPowerOf(address user) external view returns (uint256);
    // State view functions
    function proposalExpirationTime() external view returns (uint256);
    function parentDaoController() external view returns (IDaoController);
    function isChildDaoController(IDaoController controller) external view returns (bool);
    function quorumRequired() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../../lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "./IDaoController.sol";

interface IOuterCircleApp is IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}