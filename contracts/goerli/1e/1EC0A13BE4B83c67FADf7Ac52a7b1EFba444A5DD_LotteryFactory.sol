// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

pragma solidity ^0.8.7; 

interface  ILotteryNFT {

    function safeMint(address to, uint256 tokenId, string memory uri) external;

    function burnByMinter(uint256[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Error {
    //contract specific errors
    string public constant INSUFFICIENT_BALANCE= "0"; // user mint lottery but insufficient supply of ether
    string public constant CREATE_WITH_TIME_INVALID= "1"; // user creates NFT with expired time
    string public constant INITIALIZED_LOTTERYDAILY= "2"; // daily lottery has been created
    string public constant MINT_WITH_AMOUNT_INVALID= "3"; // minting tokens with too small amount
    string public constant INVALID_OWNER_OF_TOKEN= "4"; // the owner of the token is not valid
    string public constant YOU_HAVE_NO_REWARD= "5"; // player has no reward
    string public constant INVALID_TIME_GENERATE_NUMBER_WINNING= "6"; // invalid lottery result generation time
    string public constant INVALID_ADDRESS_ZERO= "7"; // argument not is a 0x00000000000000000000000000
    string public constant FORGET_INIT_LOTTERY_DAILY= "8"; // the creator has not created a daily lottery
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Lottery {
    struct LotteryDaily {
        uint256 timeStart;
        uint256 timeEnd;
        uint256 totalReward;
        uint256 remainingReward;
        uint256 lotteryDailyId;
        uint256[] tokenIds;
        uint256[] tokenIdsWin;
        uint256[] tokensGold;          
        uint256[] tokensSilver;          
        uint256[] tokensBronze;          
        uint8 numberWin;
        uint32 timeValid;
    }

    struct LotteryTickets {
        uint256 startTime;
        uint256 endTime;
        uint256 luckyNumber;
        uint256 tokenId; 
        uint256 rank; 
        address owner;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library Random {
    uint256 constant PRECISION = 1e20;

    function getLatestPrice(address _addr) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_addr);
        (, int256 _price, , , ) = priceFeed.latestRoundData();
        return uint256(_price);
    }

    function computerSeed(uint256 salt, address _aggregatorBNB, address _aggregatorETH, address _aggregatorMATIC) internal view returns (uint256) {
        uint256 seed =
        uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp)
                    + block.gaslimit
                    + uint256(keccak256(abi.encodePacked(blockhash(block.number)))) / (block.timestamp)
                    + uint256(keccak256(abi.encodePacked(block.coinbase))) / (block.timestamp)
                    + (uint256(keccak256(abi.encodePacked(tx.origin)))) / (block.timestamp)
                    + block.number * block.timestamp
                )
            )
        );
        seed = (seed % PRECISION) * getLatestPrice(_aggregatorBNB);
        seed = (seed % PRECISION) * getLatestPrice(_aggregatorETH);
        seed = (seed % PRECISION) * getLatestPrice(_aggregatorMATIC);
        if (salt > 0) {
            seed = seed % PRECISION * salt;
        }
        return seed;
    }

    function generateNumber(uint _nonce) internal view returns(uint256) {
        uint256 numberX =
        uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp)
                    + block.gaslimit
                    + uint256(keccak256(abi.encodePacked(blockhash(block.number)))) / (block.timestamp)
                    + uint256(keccak256(abi.encodePacked(block.coinbase))) / (block.timestamp)
                    + (uint256(keccak256(abi.encodePacked(tx.origin)))) / (block.timestamp)
                    + block.number * block.timestamp
                    + _nonce
                )
            )
        );
       
        return numberX;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import { Lottery } from "./library/Lottery.sol";
import { Random } from "./library/Random.sol";
import { Error } from "./library/helpers/Errors.sol";
import { ILotteryNFT } from "./interfaces/ILotteryNFT.sol";
// import { ILotteryPool } from "./interfaces/ILotteryPool.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
contract LotteryFactory is AccessControl {
    /**
     * NOTE
     * Description: factory contract to issue daily lottery
     * The publisher will build the prize pool at 0:00 every day
     * From 0 -19h daily everyone can create NFT lottery tickets
     * From 9pm, the issuer dials a lottery with a random 2 digit number
     * after 21:30 the publisher announces the winning number and NFT
     * 90% of the revenue goes to NFT winning users, the remaining 10% is used to maintain the project.
     */
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _lotteryIdCounter;
    uint256 constant RANK_GOLD = 3;
    uint256 constant RANK_SILVER = 2;
    uint256 constant RANK_BRONZE = 1;
    ILotteryNFT lotteryNFT;
    address lotteryPool;
    address currentAggregator = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526; // BNB Chain test net
    // MATIC/USD price provider on the polygon network
    address aggregatorMATIC = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada; // munbai
    // ETH/USD price provider on the ethereum network
    address aggregatorETH = 0x0715A7794a1dc8e42615F059dD6e406A6594651A; // munbai
    // BNB/USD price provider on the binance smart chain network
    address aggregatorBNB = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada; // munbai
    // 100 %
    uint256 constant hundredPercent = 1000; 
    // number of seconds in one day
    uint32 constant DAY = 1 days;

    // The time period allows players to mint NFT lottery tickets
    uint32 constant hoursValid = 19 hours;
    // number of wei in one ether
    uint oneEth =  1 ether;
    // the valid time that the player can mint the token
    uint256 public timeValid = block.timestamp;
    // Check if there are any winners that day
    bool public noWinner = false;
    // Check if the creator created a daily lottery
    bool isInit = false;

    // Random number sequence for NFT
    uint8[] numberLottery = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99
    ];


    constructor(address _aggregatorMATIC, address _aggregatorETH, address _aggregatorBNB, address _currentAggregator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        aggregatorMATIC = _aggregatorMATIC;
        aggregatorETH = _aggregatorETH;
        aggregatorBNB = _aggregatorBNB;
        currentAggregator = _currentAggregator;
    }

    // Mapping the prize demon container parameters by day 
    mapping(uint256 => Lottery.LotteryDaily) public lotteryToday;

    //Mapping each user's lottery ticket information
    mapping(address => mapping(uint256 => Lottery.LotteryTickets[])) public lotteryOfUser;

    // Information mapping of each lottery ticket
    mapping(uint256 => Lottery.LotteryTickets) public lotteryTicket;

    event MintLotteryTicket(address owner, uint256 numberLucky, uint256 tokenId);
    event InitLotteryDaily(Lottery.LotteryDaily lotteryDaily);
    event GenerateWinningNumber(Lottery.LotteryDaily lotteryDaily, uint256 winNumber, uint256[] tokensWin);

    modifier hasMintRunning() {
        uint256 currentTime = block.timestamp;
        require(currentTime <= timeValid, Error.CREATE_WITH_TIME_INVALID);
        _;
    }

    /**
     * @dev Public function to update dependent contracts.
     * The call is made when the creator deploys the contract.
     * @param _lotteryNFT contract address generate lottery ticket token
     * @param _lotteryPool reward storage contract address
     */
    function initDependencies(ILotteryNFT _lotteryNFT, address _lotteryPool) public onlyRole(MINTER_ROLE) {
        lotteryNFT  = _lotteryNFT;
        lotteryPool = _lotteryPool;
        _grantRole(MINTER_ROLE, _lotteryPool);
    }

    /**
     * @notice The publisher will build the prize pool at 0:00 every day
     */
    function initLotteryDaily() external onlyRole(MINTER_ROLE) {
        require(!isInit, Error.INITIALIZED_LOTTERYDAILY);
        _lotteryIdCounter.increment();
        uint256 lotteryId = _lotteryIdCounter.current();
        uint256[] memory tokenlist;
        uint256 remainingReward = int(lotteryId) - 7 < 0 ? 0 : lotteryToday[lotteryId - 7].remainingReward ; 
        uint256 totalReward = noWinner ? lotteryToday[lotteryId - 1].totalReward + remainingReward :  remainingReward;
        lotteryToday[lotteryId] = Lottery.LotteryDaily(
            block.timestamp,  // time start
            block.timestamp + 8 * DAY, // time and
            totalReward, // total rewward
            totalReward, // remaining reward
            lotteryId, // lottery daily Id
            tokenlist, // list token
            tokenlist, // list token win
            tokenlist, // list token gold
            tokenlist, // list token silver
            tokenlist, // list token bronze
            0, // number win
            uint32(block.timestamp + hoursValid)
        );
        noWinner = false;
        isInit   = true;
        timeValid = block.timestamp + hoursValid;
        emit InitLotteryDaily(lotteryToday[lotteryId]);
    }
    /**
     * @notice Get lottery id today
     */
    function getCurrentLotteryDailyId() public view returns(uint256) {
        return _lotteryIdCounter.current();
    }

    /**
     * @notice User can mint multiple lottery tickets, Lottery tickets will be random numbers.
     * @param  _amountTicket the number of tokens the user wants to mint.
     * Requiment: 
     *      '_amountTicket' greater than 0 and less than 10
     */
    function mintBatchLotteryTicket(uint256 _amountTicket) external payable hasMintRunning {
        require(_amountTicket <= 10, Error.MINT_WITH_AMOUNT_INVALID);
        uint256 currentPrice = Random.getLatestPrice(currentAggregator) / 10 ** 8; // vd: 24856000000 /  10 ** 8 = 248$ => 1$ = 1 ether / 248$ = 4032258100000000 wei
        uint256 userNeedDeposit = oneEth / currentPrice * _amountTicket; 
        require(userNeedDeposit <= msg.value, Error.INSUFFICIENT_BALANCE);

        for (uint i = 0; i < _amountTicket ; i++) {
            _mintLotteryTicket(_msgSender());
        }
        lotteryToday[_lotteryIdCounter.current()].totalReward += userNeedDeposit / hundredPercent * 900;
        lotteryToday[_lotteryIdCounter.current()].remainingReward += userNeedDeposit / hundredPercent * 900;
        payable(lotteryPool).transfer(userNeedDeposit / hundredPercent * 900);
        if (msg.value > userNeedDeposit) {
            payable(_msgSender()).transfer(msg.value - userNeedDeposit);
        }
    }

    /**
     * @dev Inner function to generate a certain amount of lottery tickets.
     * A call is made every time a user mints a token.
     *
     * @param _owner the address will receive the token
     */
    function _mintLotteryTicket(address _owner) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        uint256 seed = Random.computerSeed(0, aggregatorBNB, aggregatorETH, aggregatorMATIC);
        uint256 numberLucky = Random.generateNumber(seed / (tokenId + 1)) % 100;
        uint256 rank;
        uint256 randRank = Random.generateNumber(seed / (tokenId + 1) * numberLucky) % 10000; // >= 9999
        if (randRank <= 6000) {
            rank = RANK_BRONZE;
            lotteryToday[_lotteryIdCounter.current()].tokensBronze.push(tokenId);
        } else if (randRank > 6000 && randRank <= 9000 ) {
            rank = RANK_SILVER;
            lotteryToday[_lotteryIdCounter.current()].tokensSilver.push(tokenId);
        } else {
            rank = RANK_GOLD;
            lotteryToday[_lotteryIdCounter.current()].tokensGold.push(tokenId);
        }
        lotteryOfUser[_owner][_lotteryIdCounter.current()].push(Lottery.LotteryTickets(block.timestamp, block.timestamp + 7 days, numberLucky, tokenId, rank, _owner));
        lotteryTicket[tokenId] = Lottery.LotteryTickets(block.timestamp, block.timestamp + 7 days, numberLucky, tokenId, rank, _owner); 
        lotteryNFT.safeMint(_owner, tokenId, "ipfs://");
        lotteryToday[_lotteryIdCounter.current()].tokenIds.push(tokenId); 
        emit MintLotteryTicket(_msgSender(), numberLucky, tokenId);
      
    } 

    /**
     * @dev External function to generate a certain amount of lottery tickets.
     * A call is made every time a user receives a reward.
     *
     * @param _owner     owner address will be burned token
     * @param _lotteryId identifier of the daily lottery
     * @param _tokensWin owner's token array will be burned
     */
    function burnByMinter(uint256[] memory _tokensWin, address _owner, uint256 _lotteryId) external onlyRole(MINTER_ROLE) {
        Lottery.LotteryTickets[] storage listTicket = lotteryOfUser[_owner][_lotteryId];
        for (uint i = 0; i < listTicket.length; i++) {
            for (uint j = 0; j < _tokensWin.length; j++) {
                if (listTicket[i].tokenId == _tokensWin[j]) {
                    delete listTicket[i];
                }
            }
        }
    }

    /**
     * @dev An external function so that the creator can reduce the total reward of a certain daily lottery.
     * A call is made every time a user receives a reward.
     *
     * @param _amount owner address will be burned token
     * @param _lotteryDailyId identifier of the daily lottery
     * @notice Remaining reward after 7 days will be included in the next day's total reward
     */
    function decreaseRemainingReward(uint256 _amount, uint256 _lotteryDailyId) external onlyRole(MINTER_ROLE)  {
        lotteryToday[_lotteryDailyId].remainingReward -= _amount;
    }

    /**
     * @notice Get latest price of native token in network
     */
    function getConverPrice() public view returns (uint256) {
        return Random.getLatestPrice(currentAggregator) / 10 ** 8;
    } 

    /**
    * @dev An external function so that the creator can update the current aggregator.
    * @param _aggregator new aggregator
    */
    function setCurrentAggregator(address _aggregator) external onlyRole(MINTER_ROLE) {
        currentAggregator = _aggregator;
    }

    /**
     * @dev An external function so that the creator can update the matic aggregator.
     * @param _aggregator new aggregator matic
     */
    function setAggregatorMatic(address _aggregator) external onlyRole(MINTER_ROLE) {
        aggregatorMATIC = _aggregator;
    }

    /**
     * @dev An external function so that the creator can update the matic aggregator.
     * @param _aggregator new aggregator binance smart chain
     */
    function setAggregatorBnb(address _aggregator) external onlyRole(MINTER_ROLE) {
        aggregatorBNB = _aggregator;
    }

    /**
     * @dev An external function so that the creator can update the matic aggregator.
     * @param _aggregator new aggregator ethereum
     */
    function setAggregatorEth(address _aggregator) external onlyRole(MINTER_ROLE) {
        aggregatorETH = _aggregator;
    }

    /**
     * @dev An external function so that the creator can update the valid time that the player can mint the token.
     * @param _time new time valid
     */
    function setTimeValid(uint256 _time) external onlyRole(MINTER_ROLE) {
        timeValid = _time;
    }

    /**
    * @dev An external function for the creator to spin the lottery.
    * Calls are made daily at 9pm.
    */
    function generateWinningNumber() external onlyRole(MINTER_ROLE)  { 
        require(isInit, Error.FORGET_INIT_LOTTERY_DAILY);
        require(block.timestamp >= timeValid + 2 hours, Error.INVALID_TIME_GENERATE_NUMBER_WINNING);
        uint256 seed  = Random.computerSeed(0, aggregatorBNB, aggregatorETH, aggregatorMATIC);
        uint256 win = Random.generateNumber(seed / block.number / block.timestamp) % 100;
        Lottery.LotteryDaily storage lotteryCurrent = lotteryToday[_lotteryIdCounter.current()]; 
        lotteryCurrent.numberWin = uint8(win);

        for (uint i = 0; i < lotteryCurrent.tokenIds.length; i++) {
            if (lotteryTicket[lotteryCurrent.tokenIds[i]].luckyNumber == win) {

                lotteryCurrent.tokenIdsWin.push(lotteryCurrent.tokenIds[i]);
                if (lotteryTicket[lotteryCurrent.tokenIds[i]].rank == RANK_BRONZE) {
                    lotteryCurrent.tokensBronze.push(lotteryCurrent.tokenIds[i]);
                    continue;
                }
                if (lotteryTicket[lotteryCurrent.tokenIds[i]].rank == RANK_SILVER) {
                    lotteryCurrent.tokensSilver.push(lotteryCurrent.tokenIds[i]);
                    continue;
                }
                if (lotteryTicket[lotteryCurrent.tokenIds[i]].rank == RANK_GOLD) {
                    lotteryCurrent.tokensGold.push(lotteryCurrent.tokenIds[i]);
                }
            }
            
        }
        if (lotteryCurrent.tokenIdsWin.length == 0) {
            noWinner = true;
        }
        isInit = false;
        emit GenerateWinningNumber(lotteryCurrent, win, lotteryCurrent.tokenIdsWin);

    }

    /**
    * @dev An external function for people to get information of a certain daily lottery.
    * @return Lottery.LotteryDaily 
    */
    function getLotteryDaily(uint256 _lotteryDailyId) external view returns(Lottery.LotteryDaily memory) {
        return lotteryToday[_lotteryDailyId];
    }

    /**
    * @dev An external function for people to get information of a certain lottery ticket every day.
    * @return Lottery.LotteryTickets
    */
    function getLotteryTicket(uint256 _lotteryTicketId) external view returns(Lottery.LotteryTickets memory) {
        return lotteryTicket[_lotteryTicketId];
    }

    /**
    * @dev An external function for anyone to get information of a lot of player lottery tickets.
    * @return array Lottery.LotteryTickets
    */
    function getLotteryTicketOfOwner(address _owner, uint256 _lotteryId) external view returns(Lottery.LotteryTickets[] memory) {
        return lotteryOfUser[_owner][_lotteryId];
    }

    /**
     * @notice creators get 10% back to maintain the project
     */
    function withdraw() external onlyRole(MINTER_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

}