/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.12.5 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]

  
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


// File @openzeppelin/contracts/utils/[email protected]

  
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

  
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

  
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


// File @openzeppelin/contracts/utils/math/[email protected]

  
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


// File @openzeppelin/contracts/utils/[email protected]

  
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


// File @openzeppelin/contracts/access/[email protected]

  
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


// File contracts/ticketaddresslist.sol

  
pragma solidity ^0.8.6;

contract ticketaddresslist is AccessControl {

    bytes32 TICKET_ROLE = keccak256('TICKET_ROLE');

    mapping(address => bool) premiumPassAcceptAddress;
    mapping(address => uint256) regularPassAcceptAddress;

    mapping(address => bool) premiumPassUsed;
    mapping(address => uint256) regularPassUsedAmount;

    uint256 premiumPassAccessAmount;
    uint256 regularPassAccessAmount;

    uint256 premiumPassMaxAmount = 10;
    uint256 regularPassMaxAmount = 190;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TICKET_ROLE, DEFAULT_ADMIN_ROLE);
        premiumPassAcceptAddress[0x85ab567d13086cd03976765a2c9a49e8E1DA9187] = true;
        premiumPassAcceptAddress[0x97eC8b90856649a0B61d09E2151b869635012724] = true;
        premiumPassAcceptAddress[0x57B27fC6EfF1c5DbDeC4a615cC88D43A583772d8] = true;
        premiumPassAcceptAddress[0x55fA6481A31f1963d5d6ab16d16E72d7225c3E8b] = true;
        premiumPassAcceptAddress[0xbD57dE27Eb6b422350c262f0e451d31a65e3EFe5] = true;
        premiumPassAcceptAddress[0x24379F6561726956fF440f72713cc31Bf5F6d34a] = true;
        premiumPassAcceptAddress[0x0B15d768985d35039CfaBFCE8680AfD535fD1556] = true;
        premiumPassAcceptAddress[0x5F1A688C94971e2b7Da2b1a030947DeF4D7172e7] = true;
        premiumPassAcceptAddress[0x5Edb7A2a7067Cc95c58C073d0c9a8B999dCa3b29] = true;
        premiumPassAcceptAddress[0x378651A77E0aD4Dc853B57434E7cA08BD93df501] = true;
        regularPassAcceptAddress[0x97eC8b90856649a0B61d09E2151b869635012724] = 0;
        regularPassAcceptAddress[0x0B15d768985d35039CfaBFCE8680AfD535fD1556] = 0;
        regularPassAcceptAddress[0x5F1A688C94971e2b7Da2b1a030947DeF4D7172e7] = 0;
        regularPassAcceptAddress[0x85ab567d13086cd03976765a2c9a49e8E1DA9187] = 1;
        regularPassAcceptAddress[0x55fA6481A31f1963d5d6ab16d16E72d7225c3E8b] = 1;
        regularPassAcceptAddress[0xbD57dE27Eb6b422350c262f0e451d31a65e3EFe5] = 1;
        regularPassAcceptAddress[0x5Edb7A2a7067Cc95c58C073d0c9a8B999dCa3b29] = 1;
        regularPassAcceptAddress[0xBE849cE1A292A47fb14a8a60119FE85fde2aBD62] = 1;
        regularPassAcceptAddress[0x54105EA638e900f80f3444a1562A92D1a29DB1Aa] = 1;
        regularPassAcceptAddress[0xB6e458E460BE970Aa5cA3fEA1857E28aD3874619] = 1;
        regularPassAcceptAddress[0x5eC0f7103c93cbAd1A5Ce240D691f47566233134] = 1;
        regularPassAcceptAddress[0xC264b4a5fb07202721eAaF13E756a91A34C409C5] = 1;
        regularPassAcceptAddress[0xddF21318ca81F9dcB3f143b40B95C72328c46892] = 1;
        regularPassAcceptAddress[0x5f2952fF0E30f272554CC1f74884261D561ae979] = 1;
        regularPassAcceptAddress[0x44FaA42Da632DEcbdC7D40231Eb115DE6CB60f06] = 1;
        regularPassAcceptAddress[0xA8eb2ea3A233bC7Af4043DF453191a0939Bcb286] = 1;
        regularPassAcceptAddress[0x20519E6e6864cB74822d102FF60FA7fF98520159] = 1;
        regularPassAcceptAddress[0xB4a4b42081Ca39F07c62F0A3f4bee9687559d7A9] = 1;
        regularPassAcceptAddress[0x7b2bCD514Eb7C68288041386fB06FAee267C350f] = 1;
        regularPassAcceptAddress[0xa8E035f1D0Ef3f9EeA02688D1D64e7FDaA91970A] = 1;
        regularPassAcceptAddress[0xF4548503Dd51De15e8D0E6fB559f6062d38667e7] = 1;
        regularPassAcceptAddress[0x149435d8E44B7f0bd12EC849678Ae55c4951027E] = 1;
        regularPassAcceptAddress[0xbdBEb6dFA570705ddbc09c1830dF2285B54eA67A] = 1;
        regularPassAcceptAddress[0x4CaE8F1F7A5CFcc82b5123872ef3B9fAc395c210] = 1;
        regularPassAcceptAddress[0x4e9A80Ce5E4B0dF0d324aCaFebbbB2332Cb38Ff8] = 1;
        regularPassAcceptAddress[0x6b3b5eEe8a7096110E8Cb63Be91bD6F37Ad3b219] = 1;
        regularPassAcceptAddress[0x25251ECcD6b806fa4e8E017E816a28b8a9D2BeDa] = 1;
        regularPassAcceptAddress[0x97F5E4dcEf753df248479d5150Df177355453d00] = 1;
        regularPassAcceptAddress[0x9f3A6dF7bC869B77Fe3e5e050f305d9835D9192d] = 1;
        regularPassAcceptAddress[0x0Dc1949E3a7282c293A491b1b66756aa65DE7e55] = 1;
        regularPassAcceptAddress[0x7E01CCb7a89dc5417C3F87cc738ae4db2c219173] = 1;
        regularPassAcceptAddress[0xA79CaAbAf320A8Fe645C1C7290f14276c2a477d2] = 1;
        regularPassAcceptAddress[0x04e45DC9785ceCd1a2CcFb40ad70ad70B3f10D45] = 1;
        regularPassAcceptAddress[0xEAbB8945bf334c05144A13DF75eB76d047a7eebD] = 1;
        regularPassAcceptAddress[0xd239815bfCC6C70358927437429789Bcf0ac810D] = 1;
        regularPassAcceptAddress[0x5D1661F7Bc1CC45224AeB20ea634A8381d965286] = 1;
        regularPassAcceptAddress[0xFE4bE01Da4fBfD47650EB2c7bd37d09607d1337F] = 1;
        regularPassAcceptAddress[0xb0F026A67C66c931Ae55c1c00fa22c9e004037f0] = 1;
        regularPassAcceptAddress[0xf15b2D971B9b320d931B5264Df47af3B4DB82981] = 1;
        regularPassAcceptAddress[0x5e93303aEadccf996bd77EB91A9FaB241880334f] = 1;
        regularPassAcceptAddress[0x0ea975d47160AAD0f82A6e43C1e4B8379944D0E0] = 1;
        regularPassAcceptAddress[0xa0751827DA7a5cE235D85694164382Ee8920648D] = 1;
        regularPassAcceptAddress[0x9cE48E518b1A4fCBC9eadC7E35121DC50F6e3530] = 1;
        regularPassAcceptAddress[0xf6B521a205424Bd5f29Ab48Ccb30D4F5e7b82757] = 1;
        regularPassAcceptAddress[0x408C64De7C55c945976026b1bC1B1C2D5d0c46CD] = 1;
        regularPassAcceptAddress[0xe96d02E01A27F116afB42Ed468929d2D2e1cb3C2] = 1;
        regularPassAcceptAddress[0xa961a6375dBE7B14Df4f0cD426552C5a7709eFb9] = 1;
        regularPassAcceptAddress[0x703d4517b35d47418E9f03EeA2e41FDc36f179fb] = 1;
        regularPassAcceptAddress[0xCf3223ca96C4a3cbb50E40eE376b0a5d86E829E2] = 1;
        regularPassAcceptAddress[0xb47e5fA8ccAc66F0817a15C966e4F1Cc1fc8bEE8] = 1;
        regularPassAcceptAddress[0xf88A42F08c86bDd84Db4D8af3EBB7859AE654E5a] = 1;
        regularPassAcceptAddress[0x4B52AD066877867A162FAB6BE346ED5f92030A77] = 1;
        regularPassAcceptAddress[0x9Ee6B94b4Fd48A75178D57bF5eb263DA709b8dbb] = 1;
        regularPassAcceptAddress[0x47659CAf77A8822F477887657Dfb34EC2F448852] = 1;
        regularPassAcceptAddress[0x1F5705e882b7B190538508bF83485564fF9a0e6a] = 1;
        regularPassAcceptAddress[0x2664d2b96bd52b0E3eB08DE99C726D694f23D34F] = 1;
        regularPassAcceptAddress[0xFb2520759E6Dbc4696111a8Ef18bE569fe6b0E3E] = 1;
        regularPassAcceptAddress[0xc8Ba8bBd50D10E3078BDf8f475516C5b02175D2C] = 1;
        regularPassAcceptAddress[0xccC44a3A336236c0C3b424dE86C8A0055e65757f] = 1;
        regularPassAcceptAddress[0x6A899f5Bd2ea49E615DFD754eEf6E1f81e3b346e] = 1;
        regularPassAcceptAddress[0x3Ca943819538F07ea6F2022996D44eA852563270] = 1;
        regularPassAcceptAddress[0x3d9fd60AEC344C20Fc0ef161f59225181730f47B] = 1;
        regularPassAcceptAddress[0x83e958aa52023ec40dE1dC30276adDEea6de4028] = 1;
        regularPassAcceptAddress[0x5687e44feb0401d6FA56a26D01b253cec63276De] = 1;
        regularPassAcceptAddress[0xAea31abFAdfb9c8B885c54e751C0d99CB0662137] = 1;
        regularPassAcceptAddress[0xb9B48fC6b6bCedeb0532CF548435620a9cFef511] = 1;
        regularPassAcceptAddress[0x4fedb138A7D7f1427768EF5747Bb8556b352e764] = 1;
        regularPassAcceptAddress[0x54c6AaABa8D60a85338c5f96A208a06925202de8] = 1;
        regularPassAcceptAddress[0x129E323327059Be441A27dd72751EcaD48b2cB40] = 1;
        regularPassAcceptAddress[0x5411Cf794c9cE7d956F47074A85411d597C83CD9] = 1;
        regularPassAcceptAddress[0x80691e067a086A767A833a3a9c77F8Dd404551e8] = 1;
        regularPassAcceptAddress[0xD50F019BA11c350c2495133ec74A4aAcc3C673d6] = 1;
        regularPassAcceptAddress[0xAf41939181902e68865186ae1f61e42338ddD754] = 1;
        regularPassAcceptAddress[0x6a652E70e81DCE37aBbb09FeA54a3a3bc2f023dF] = 1;
        regularPassAcceptAddress[0x52e030bCc69161e1A1f420485F6AEa6Eb0D97733] = 1;
        regularPassAcceptAddress[0xEd44CA68bA2375A29492A860DDd5d41B4Db46e56] = 1;
        regularPassAcceptAddress[0xC8B51A47b7eDD0681276444770Bff117957A180a] = 2;
        regularPassAcceptAddress[0x44dDF488f6Abd98F153Ad478566C572043E8ffaB] = 2;
        regularPassAcceptAddress[0xaD29F6dD5a03105813Ad0d879383f818c6B5FB99] = 2;
        regularPassAcceptAddress[0xEe50ab320e99c3a291A16E52EBF5409f122CBD67] = 2;
        regularPassAcceptAddress[0x4AA41136AD53FfB0f028dcA371D7B3c87305423D] = 2;
        regularPassAcceptAddress[0xd18c458D756b8F6eD3742cc6a594D3A2B576Fa8F] = 2;
        regularPassAcceptAddress[0x4841F5A8b9b15E77cBD4f152cF61bc22866E7B73] = 2;
        regularPassAcceptAddress[0xdf06b9cC49D99c6F1D1A3E664CEfC52613195Adf] = 2;
        regularPassAcceptAddress[0x3a182839c982457D77Ed45A1649783F2A342e3be] = 2;
        regularPassAcceptAddress[0xFd26373e6dBCb3e5BD49DFB44578a18Bf4878B48] = 2;
        regularPassAcceptAddress[0xa24bae25595E860D415817bE1680885386AAA682] = 2;
        regularPassAcceptAddress[0xc92D2c2375a2FCd145CAA8B056753c7128f0d444] = 2;
        regularPassAcceptAddress[0xC8710C9ca16c5804BB49Bf2999645AAf9E97D862] = 2;
        regularPassAcceptAddress[0x13c9b8215E03f4554fD066468700bf6a496912Bf] = 2;
        regularPassAcceptAddress[0x221a11F813e30CEf5399F3D584c4f3E00f5C0486] = 2;
        regularPassAcceptAddress[0x847A643AD8d71569329E8B133a68291696D9ac4B] = 2;
        regularPassAcceptAddress[0x221995e6B982a5a9023df2fc4E4e00EdDC54010b] = 2;
        regularPassAcceptAddress[0x1a2842D14B59C6EeaFeA82b0037451848B719F68] = 2;
        regularPassAcceptAddress[0x6C197F3fd570501dE2f3090be03fd2A819A7DeC5] = 2;
        regularPassAcceptAddress[0x35cCEd5CdF2483848EFc48Dbf6c5C4fdE225522D] = 2;
        regularPassAcceptAddress[0xdA8Eca8F379A52917d8074ab9ce40b8968E68af8] = 2;
        regularPassAcceptAddress[0x86573536Ab37E0dea5b2D37247aD68fb3C668803] = 2;
        regularPassAcceptAddress[0x6ce0DB14A58c81aaa13Cf0764199D206BD25312F] = 2;
        regularPassAcceptAddress[0x4aAA5F273Cb5A841b8374A86E9d2f15A4e8D2959] = 2;
        regularPassAcceptAddress[0xFE6739ba9eb8dC27eF8B623da42bA2f8A5902d1d] = 3;
        regularPassAcceptAddress[0x130f994E85B9c81Aa8AA63e25fc05fF27f16Ef20] = 3;
        regularPassAcceptAddress[0x378651A77E0aD4Dc853B57434E7cA08BD93df501] = 4;
        regularPassAcceptAddress[0x5d61f268EEF978c27d56fc2722111481e6Ae21Ef] = 4;
        regularPassAcceptAddress[0xd99694fD205Cc2c9d5EBFFc5fD5ca5cb5416Ed03] = 5;
        regularPassAcceptAddress[0xB7D994657d400D434e84B11d02c935BE69957657] = 6;
        regularPassAcceptAddress[0x24379F6561726956fF440f72713cc31Bf5F6d34a] = 9;
        regularPassAcceptAddress[0x57B27fC6EfF1c5DbDeC4a615cC88D43A583772d8] = 19;
        premiumPassAcceptAddress[0x5A3b919496358098ED6549b235D578914a7Cc90b] = true;
        premiumPassAcceptAddress[0x354678BDDb1c60071287853da0Ec6D2832a33aFa] = true;
        regularPassAcceptAddress[0x5A3b919496358098ED6549b235D578914a7Cc90b] = 9;
        regularPassAcceptAddress[0x354678BDDb1c60071287853da0Ec6D2832a33aFa] = 19;
    }

    function addPremiumPass(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(premiumPassAcceptAddress[to] == false);
        require(premiumPassAccessAmount < premiumPassMaxAmount);
        premiumPassAcceptAddress[to] = true;
        premiumPassAccessAmount++;
    }

    function addRegularPass(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(regularPassAcceptAddress[to] == 0);
        require((regularPassAccessAmount + amount) <= regularPassMaxAmount);
        regularPassAcceptAddress[to] = amount;
        regularPassAccessAmount + amount;
    }

    function changeRegularPassAmount(address to, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(regularPassAcceptAddress[to] != 0);
        require((regularPassAccessAmount - regularPassAcceptAddress[to] + amount) <= regularPassMaxAmount);
        regularPassAcceptAddress[to] = amount;
        regularPassAccessAmount = regularPassAccessAmount - regularPassAcceptAddress[to] + amount;
    }

    function revokePremiumPass(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(premiumPassAcceptAddress[to] == true);
        premiumPassAcceptAddress[to] == false;
        premiumPassAccessAmount--;
    }

    function revokeRegularPassAmount(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(regularPassAcceptAddress[to] != 0);
        regularPassAccessAmount -= regularPassAcceptAddress[to];
        regularPassAcceptAddress[to] == 0;
    }

    function usePremiumPass(address to) public onlyRole(TICKET_ROLE) {
        premiumPassUsed[to] = true;
    }

    function useRegularPass(address to) public onlyRole(TICKET_ROLE) {
        regularPassUsedAmount[to] ++;
    }

    function premiumPassAcceptCheck(address to) public view returns(bool) {
        return premiumPassAcceptAddress[to];
    }

    function premiumPassUseCheck(address to) public view returns(bool) {
        return premiumPassUsed[to];
    }

    function regularPassAceeptCheck(address to) public view returns(uint256) {
        return regularPassAcceptAddress[to] - regularPassUsedAmount[to];
    }

}