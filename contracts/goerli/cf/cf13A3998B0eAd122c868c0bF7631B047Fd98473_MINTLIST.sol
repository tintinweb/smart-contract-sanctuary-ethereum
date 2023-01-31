// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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

import '@openzeppelin/contracts/access/AccessControl.sol';

contract MINTLIST is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        monsterMintValue[1000] = mintValue(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        monsterMintValue[1001] = mintValue(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        monsterMintValue[1010] = mintValue(0, 1, 0, 1, 0, 0, 1, 0, 0, 0);
        monsterMintValue[1011] = mintValue(1, 2, 1, 2, 1, 0, 2, 0, 0, 0);
        monsterMintValue[1020] = mintValue(1, 1, 1, 1, 0, 1, 0, 0, 0, 0);
        monsterMintValue[1021] = mintValue(2, 2, 2, 2, 1, 2, 0, 0, 0, 0);
        monsterMintValue[1030] = mintValue(0, 1, 0, 1, 0, 0, 0, 0, 1, 0);
        monsterMintValue[1031] = mintValue(1, 2, 1, 2, 1, 0, 0, 0, 2, 0);
        monsterMintValue[1040] = mintValue(1, 0, 1, 1, 0, 0, 0, 1, 0, 0);
        monsterMintValue[1041] = mintValue(2, 1, 2, 2, 1, 0, 0, 2, 0, 0);
        monsterMintValue[1050] = mintValue(1, 0, 1, 0, 1, 0, 0, 0, 0, 1);
        monsterMintValue[1051] = mintValue(2, 1, 2, 1, 2, 0, 0, 0, 0, 2);
        monsterMintValue[1060] = mintValue(0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
        monsterMintValue[1061] = mintValue(2, 2, 2, 5, 5, 2, 2, 2, 2, 2);
        monsterMintValue[1062] = mintValue(5, 5, 5, 5, 5, 2, 2, 2, 2, 2);
        monsterMintValue[1070] = mintValue(2, 2, 3, 3, 2, 0, 0, 1, 0, 0);
        monsterMintValue[1071] = mintValue(3, 3, 4, 4, 3, 0, 0, 1, 0, 0);
        monsterMintValue[1080] = mintValue(2, 2, 3, 2, 3, 0, 0, 0, 0, 1);
        monsterMintValue[1081] = mintValue(3, 3, 4, 3, 4, 0, 0, 0, 0, 1);
        monsterMintValue[1090] = mintValue(1, 2, 2, 3, 2, 0, 0, 0, 1, 0);
        monsterMintValue[1091] = mintValue(2, 3, 3, 4, 3, 0, 0, 0, 1, 0);
        monsterMintValue[1100] = mintValue(1, 3, 2, 0, 4, 1, 1, 1, 1, 1);
        monsterMintValue[1101] = mintValue(2, 4, 3, 1, 5, 1, 1, 1, 1, 1);
        monsterMintValue[1110] = mintValue(3, 3, 2, 1, 0, 1, 0, 0, 0, 0);
        monsterMintValue[1111] = mintValue(4, 4, 3, 2, 1, 1, 0, 0, 0, 0);
        monsterMintValue[1120] = mintValue(3, 3, 2, 2, 2, 1, 0, 0, 0, 0);
        monsterMintValue[1121] = mintValue(4, 4, 3, 3, 3, 1, 0, 0, 0, 0);
        monsterMintValue[1130] = mintValue(2, 2, 2, 1, 3, 0, 0, 0, 0, 1);
        monsterMintValue[1131] = mintValue(3, 3, 3, 2, 4, 0, 0, 0, 0, 1);
        monsterMintValue[1140] = mintValue(2, 2, 1, 3, 2, 0, 0, 0, 1, 0);
        monsterMintValue[1141] = mintValue(3, 3, 2, 4, 3, 0, 0, 0, 1, 0);
        monsterMintValue[1150] = mintValue(2, 2, 3, 3, 2, 0, 0, 0, 1, 0);
        monsterMintValue[1151] = mintValue(3, 3, 4, 4, 3, 0, 0, 0, 1, 0);
        monsterMintValue[1160] = mintValue(2, 3, 3, 2, 2, 1, 1, 1, 1, 1);
        monsterMintValue[1161] = mintValue(3, 4, 4, 3, 3, 1, 1, 1, 1, 1);
        monsterMintValue[1170] = mintValue(6, 5, 4, 6, 3, 4, 4, 4, 4, 4);
        monsterMintValue[1171] = mintValue(7, 6, 5, 1, 0, 5, 5, 5, 5, 5);
        monsterMintValue[1180] = mintValue(5, 3, 7, 0, 0, 0, 0, 0, 0, 3);
        monsterMintValue[1181] = mintValue(6, 4, 8, 1, 1, 0, 0, 0, 0, 4);
        monsterMintValue[1190] = mintValue(3, 3, 2, 4, 4, 0, 0, 0, 2, 0);
        monsterMintValue[1191] = mintValue(4, 4, 3, 5, 5, 0, 0, 0, 3, 0);
        monsterMintValue[1200] = mintValue(6, 3, 2, 2, 4, 0, 0, 4, 0, 0);
        monsterMintValue[1201] = mintValue(7, 4, 3, 3, 5, 0, 0, 5, 0, 0);
        monsterMintValue[1210] = mintValue(1, 5, 5, 1, 5, 4, 4, 4, 4, 4);
        monsterMintValue[1211] = mintValue(2, 6, 6, 2, 6, 5, 5, 5, 5, 5);
        monsterMintValue[1220] = mintValue(1, 6, 1, 6, 0, 0, 0, 0, 3, 0);
        monsterMintValue[1221] = mintValue(2, 7, 2, 7, 1, 0, 0, 0, 4, 0);
        monsterMintValue[1230] = mintValue(6, 5, 3, 1, 0, 0, 0, 0, 3, 0);
        monsterMintValue[1231] = mintValue(7, 6, 4, 2, 1, 0, 0, 0, 4, 0);
        monsterMintValue[1240] = mintValue(1, 4, 4, 1, 7, 0, 0, 4, 0, 0);
        monsterMintValue[1241] = mintValue(2, 5, 5, 2, 8, 0, 0, 5, 0, 0);
        monsterMintValue[1250] = mintValue(3, 3, 3, 6, 1, 3, 3, 3, 3, 3);
        monsterMintValue[1251] = mintValue(4, 4, 4, 7, 2, 4, 4, 4, 4, 4);
        monsterMintValue[1260] = mintValue(0, 4, 3, 3, 3, 0, 0, 0, 0, 2);
        monsterMintValue[1261] = mintValue(1, 5, 4, 4, 4, 0, 0, 0, 0, 3);
        monsterMintValue[1270] = mintValue(4, 4, 3, 1, 1, 0, 0, 0, 2, 0);
        monsterMintValue[1271] = mintValue(5, 5, 4, 2, 2, 0, 0, 0, 3, 0);
        monsterMintValue[1280] = mintValue(1, 10, 1, 1, 4, 3, 3, 3, 3, 3);
        monsterMintValue[1281] = mintValue(2, 11, 2, 2, 5, 4, 4, 4, 4, 4);
        monsterMintValue[1290] = mintValue(11, 0, 0, 0, 3, 0, 0, 0, 0, 3);
        monsterMintValue[1291] = mintValue(12, 1, 1, 1, 4, 0, 0, 0, 0, 4);
        monsterMintValue[1300] = mintValue(4, 4, 1, 4, 4, 4, 0, 0, 0, 0);
        monsterMintValue[1301] = mintValue(5, 5, 2, 5, 5, 5, 0, 0, 0, 0);
        monsterMintValue[1310] = mintValue(1, 4, 3, 2, 3, 0, 0, 0, 2, 0);
        monsterMintValue[1311] = mintValue(2, 5, 4, 3, 4, 0, 0, 0, 3, 0);
        monsterMintValue[1320] = mintValue(5, 2, 2, 5, 2, 0, 0, 0, 2, 0);
        monsterMintValue[1321] = mintValue(6, 3, 3, 6, 3, 0, 0, 0, 3, 0);
        monsterMintValue[1330] = mintValue(5, 0, 4, 6, 0, 0, 0, 0, 4, 0);
        monsterMintValue[1331] = mintValue(6, 1, 5, 7, 1, 0, 0, 0, 5, 0);
        monsterMintValue[1340] = mintValue(1, 1, 6, 5, 4, 3, 3, 3, 3, 3);
        monsterMintValue[1341] = mintValue(2, 2, 7, 6, 5, 4, 4, 4, 4, 4);
        monsterMintValue[1350] = mintValue(2, 6, 1, 1, 6, 0, 0, 0, 4, 0);
        monsterMintValue[1351] = mintValue(3, 7, 2, 2, 7, 0, 0, 0, 5, 0);
        monsterMintValue[1360] = mintValue(5, 4, 3, 3, 1, 4, 0, 0, 0, 0);
        monsterMintValue[1361] = mintValue(6, 5, 4, 4, 2, 5, 0, 0, 0, 0);
        monsterMintValue[1370] = mintValue(5, 5, 3, 0, 1, 3, 0, 0, 0, 0);
        monsterMintValue[1371] = mintValue(6, 6, 4, 1, 2, 4, 0, 0, 0, 0);
        monsterMintValue[1380] = mintValue(2, 6, 2, 6, 2, 0, 0, 4, 0, 0);
        monsterMintValue[1381] = mintValue(3, 7, 3, 7, 3, 0, 0, 5, 0, 0);
        monsterMintValue[1390] = mintValue(1, 6, 1, 2, 6, 0, 0, 0, 0, 3);
        monsterMintValue[1391] = mintValue(2, 7, 2, 3, 7, 0, 0, 0, 0, 4);
        monsterMintValue[1400] = mintValue(4, 3, 3, 2, 2, 2, 0, 0, 0, 0);
        monsterMintValue[1401] = mintValue(5, 4, 4, 3, 3, 3, 0, 0, 0, 0);
        monsterMintValue[1410] = mintValue(3, 3, 3, 3, 3, 4, 4, 4, 4, 4);
        monsterMintValue[1411] = mintValue(4, 4, 4, 4, 4, 5, 5, 5, 5, 5);
        monsterMintValue[1420] = mintValue(2, 2, 3, 3, 4, 2, 0, 0, 0, 0);
        monsterMintValue[1421] = mintValue(3, 3, 4, 4, 5, 3, 0, 0, 0, 0);
        monsterMintValue[1430] = mintValue(4, 4, 2, 4, 1, 0, 0, 3, 0, 0);
        monsterMintValue[1431] = mintValue(5, 5, 3, 5, 2, 0, 0, 4, 0, 0);
        monsterMintValue[1440] = mintValue(3, 3, 3, 2, 3, 0, 0, 0, 0, 2);
        monsterMintValue[1441] = mintValue(4, 4, 4, 3, 4, 0, 0, 0, 0, 3);
        monsterMintValue[1450] = mintValue(6, 3, 3, 1, 0, 0, 0, 0, 2, 0);
        monsterMintValue[1451] = mintValue(7, 4, 4, 2, 1, 0, 0, 0, 3, 0);
        monsterMintValue[1460] = mintValue(1, 3, 3, 4, 3, 0, 0, 0, 2, 0);
        monsterMintValue[1461] = mintValue(2, 4, 4, 5, 4, 0, 0, 0, 3, 0);
        monsterMintValue[1470] = mintValue(2, 6, 1, 2, 1, 3, 3, 3, 3, 3);
        monsterMintValue[1471] = mintValue(3, 7, 2, 3, 2, 4, 4, 4, 4, 4);
        monsterMintValue[1480] = mintValue(3, 1, 1, 5, 2, 3, 0, 0, 0, 0);
        monsterMintValue[1481] = mintValue(4, 2, 2, 6, 3, 4, 0, 0, 0, 0);
        monsterMintValue[1490] = mintValue(4, 4, 3, 6, 6, 0, 0, 0, 4, 0);
        monsterMintValue[1491] = mintValue(5, 5, 4, 7, 7, 0, 0, 0, 5, 0);
        monsterMintValue[1500] = mintValue(0, 0, 0, 15, 7, 0, 0, 0, 0, 4);
        monsterMintValue[1501] = mintValue(1, 1, 1, 16, 8, 0, 0, 0, 0, 5);
        monsterMintValue[1510] = mintValue(15, 8, 0, 12, 7, 5, 0, 0, 0, 0);
        monsterMintValue[1511] = mintValue(16, 9, 1, 13, 8, 6, 0, 0, 0, 0);
        monsterMintValue[1520] = mintValue(10, 4, 2, 15, 10, 0, 0, 0, 0, 5);
        monsterMintValue[1521] = mintValue(11, 5, 3, 16, 11, 0, 0, 0, 0, 6);
        monsterMintValue[1530] = mintValue(28, 2, 10, 1, 1, 0, 0, 5, 0, 0);
        monsterMintValue[1531] = mintValue(29, 3, 11, 2, 2, 0, 0, 6, 0, 0);
        monsterMintValue[1540] = mintValue(4, 21, 2, 7, 7, 5, 5, 5, 5, 5);
        monsterMintValue[1541] = mintValue(5, 22, 3, 8, 8, 6, 6, 6, 6, 6);
        monsterMintValue[1550] = mintValue(0, 0, 41, 0, 0, 0, 0, 0, 0, 5);
        monsterMintValue[1551] = mintValue(1, 1, 42, 1, 1, 0, 0, 0, 0, 6);
        monsterMintValue[1560] = mintValue(0, 13, 0, 26, 1, 0, 0, 0, 0, 5);
        monsterMintValue[1561] = mintValue(1, 14, 1, 27, 2, 0, 0, 0, 0, 6);
        monsterMintValue[1570] = mintValue(10, 6, 6, 10, 10, 5, 0, 0, 0, 0);
        monsterMintValue[1571] = mintValue(11, 7, 7, 11, 11, 6, 0, 0, 0, 0);
        monsterMintValue[1580] = mintValue(10, 10, 10, 1, 10, 0, 0, 5, 0, 0);
        monsterMintValue[1581] = mintValue(11, 11, 11, 2, 11, 0, 0, 6, 0, 0);
        monsterMintValue[1590] = mintValue(0, 0, 5, 29, 7, 0, 0, 0, 5, 0);
        monsterMintValue[1591] = mintValue(1, 1, 6, 30, 8, 0, 0, 0, 6, 0);
        monsterMintValue[1600] = mintValue(0, 20, 0, 1, 0, 4, 4, 4, 4, 4);
        monsterMintValue[1601] = mintValue(1, 21, 1, 2, 1, 5, 5, 5, 5, 5);
        monsterMintValue[1610] = mintValue(13, 13, 13, 13, 13, 7, 7, 7, 7, 7);
        monsterMintValue[1621] = mintValue(19, 19, 19, 19, 19, 9, 9, 9, 9, 9);
        monsterMintValue[1631] = mintValue(4, 8, 13, 17, 22, 7, 7, 7, 7, 7);
        monsterMintValue[1641] = mintValue(5, 5, 5, 5, 45, 7, 7, 7, 7, 7);
        monsterMintValue[1650] = mintValue(17, 17, 17, 17, 17, 88, 88, 88, 88, 88);
        monsterMintValue[1660] = mintValue(19, 19, 19, 19, 19, 9, 9, 9, 9, 9);
        monsterMintValue[1670] = mintValue(0, 0, 0, 0, 0, 7, 7, 7, 7, 7);
    }

    struct mintValue{
        uint256 psValue;
        uint256 wdValue;
        uint256 biValue;
        uint256 fcValue;
        uint256 hwValue;
        uint256 psGuarantee;
        uint256 wdGuarantee;
        uint256 biGuarantee;
        uint256 fcGuarantee;
        uint256 hwGuarantee;
    }

    mapping (uint256 => mintValue) public monsterMintValue;
    mapping (uint256 => bytes32) public monsterGalanteeItem;
    mapping (uint256 => uint256) public monsterGalanteeValue;
    
    function addGalantee(uint256 _evoMode, bytes32 _garantee, uint256 _galanteeValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _garantee == bytes32("ALL") ||
            _garantee == bytes32("PS") ||
            _garantee == bytes32("WD") ||
            _garantee == bytes32("BI") ||
            _garantee == bytes32("FC") ||
            _garantee == bytes32("HW") ||
            _garantee == bytes32("NONE")
        );
        monsterGalanteeItem[_evoMode] = _garantee;
        monsterGalanteeValue[_evoMode] = _galanteeValue;
    }

    function addEvoMode(
        uint256 _evoMode,
        uint256 _psValue,
        uint256 _wdValue,
        uint256 _biValue,
        uint256 _fcValue,
        uint256 _hwValue
    ) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(monsterGalanteeItem[_evoMode] != bytes32(0));
        if(monsterGalanteeItem[_evoMode] == bytes32("ALL")) {
            monsterMintValue[_evoMode] =  mintValue(_psValue, _wdValue, _biValue, _fcValue, _hwValue, monsterGalanteeValue[_evoMode], monsterGalanteeValue[_evoMode], monsterGalanteeValue[_evoMode], monsterGalanteeValue[_evoMode], monsterGalanteeValue[_evoMode]);
        } else if(monsterGalanteeItem[_evoMode] == bytes32("PS")) {
            monsterMintValue[_evoMode] =  mintValue(_psValue, _wdValue, _biValue, _fcValue, _hwValue, monsterGalanteeValue[_evoMode], 0, 0, 0, 0);
        } else if(monsterGalanteeItem[_evoMode] == bytes32("WD")) {
            monsterMintValue[_evoMode] =  mintValue(_psValue, _wdValue, _biValue, _fcValue, _hwValue, 0, monsterGalanteeValue[_evoMode], 0, 0, 0);
        } else if(monsterGalanteeItem[_evoMode] == bytes32("BI")) {
            monsterMintValue[_evoMode] =  mintValue(_psValue, _wdValue, _biValue, _fcValue, _hwValue, 0, 0, monsterGalanteeValue[_evoMode], 0, 0);
        } else if(monsterGalanteeItem[_evoMode] == bytes32("FC")) {
            monsterMintValue[_evoMode] =  mintValue(_psValue, _wdValue, _biValue, _fcValue, _hwValue, 0, 0, 0, monsterGalanteeValue[_evoMode], 0);
        } else if(monsterGalanteeItem[_evoMode] == bytes32("HW")) {
            monsterMintValue[_evoMode] =  mintValue(_psValue, _wdValue, _biValue, _fcValue, _hwValue, 0, 0, 0, 0, monsterGalanteeValue[_evoMode]);
        } else if(monsterGalanteeItem[_evoMode] == bytes32("NONE")) {
            monsterMintValue[_evoMode] =  mintValue(_psValue, _wdValue, _biValue, _fcValue, _hwValue, 0, 0, 0, 0, 0);
        }
    }

    function checkPSValue(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].psValue;
    }

    function checkPSGuarantee(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].psGuarantee;
    }
    
    function checkWDValue(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].wdValue;
    }

    function checkWDGuarantee(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].wdGuarantee;
    }

    function checkBIValue(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].biValue;
    }

    function checkBIGuarantee(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].biGuarantee;
    }

    function checkFCValue(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].fcValue;
    }

    function checkFCGuarantee(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].fcGuarantee;
    }

    function checkHWValue(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].hwValue;
    }

    function checkHWGuarantee(uint256 evoMode) public view returns(uint256) {
        return monsterMintValue[evoMode].hwGuarantee;
    }

}