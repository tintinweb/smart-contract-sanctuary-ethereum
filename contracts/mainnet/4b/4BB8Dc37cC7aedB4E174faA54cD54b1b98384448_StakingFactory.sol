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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title CommonInterest
    @author iMe Lab

    @notice Base contract for interest accrual contracts
 */
abstract contract CommonInterest {
    constructor(uint64 interestRate, uint32 accrualPeriod) {
        _interestRate = interestRate;
        _accrualPeriod = accrualPeriod;
    }

    /**
        @notice Error, typically fired on attempt to withdraw over balance
     */
    error WithdrawalOverDebt();

    uint64 internal immutable _interestRate;
    uint32 internal immutable _accrualPeriod;

    /**
        @notice Make a logical deposit

        @param depositor Account who makes a deposit
        @param amount Amount of deposited tokens (integer)
        @param at Timestamp of deposit
     */
    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual;

    /**
        @notice Make a logical withdrawal

        @dev Should revert with WithdrawalOverDebt on balance exceed

        @param depositor Account who makes a withdrawal
        @param amount Amount of withdrawn tokens (integer)
        @param at Timestamp of withdrawal
     */
    function _withdrawal(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual;

    /**
        @notice Make full withdrawal (logical)

        @dev It' a gase-efficient equivalent of
        `_withdrawal(address, uint256, uint65)`, as it shouldn't care
        about previous depositor balance
     */
    function _withdrawal(address depositor) internal virtual;

    /**
        @notice Predicts debt for an investor

        @param depositor The depositor
        @param at Timestamp for debt calculation
     */
    function _debt(
        address depositor,
        uint64 at
    ) internal view virtual returns (uint256);

    /**
        @notice Predict total debt accross all investors

        @param at Timestamp to make a prediction for. Shouldn't be in the past.
     */
    function _totalDebt(uint64 at) internal view virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CommonInterest} from "./CommonInterest.sol";
import {Math} from "../lib/Math.sol";
import {Calendar} from "../lib/Calendar.sol";

/**
    @title CompoundInterest
    @author iMe Lab

    @notice Implementation of compound interest accrual
    @dev https://en.wikipedia.org/wiki/Compound_interest
 */
abstract contract CompoundInterest is CommonInterest {
    constructor(uint64 anchor) {
        _compoundAnchor = anchor;
    }

    uint64 private immutable _compoundAnchor;
    mapping(address => uint256) private _compoundDeposit;
    uint256 private _totalCompoundDeposit;

    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        uint256 effect = _converge(
            amount,
            _interestRate,
            at,
            _compoundAnchor,
            _accrualPeriod
        );

        _totalCompoundDeposit += effect;
        _compoundDeposit[depositor] += effect;
    }

    function _withdrawal(
        address recipient,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        uint256 debt = _debt(recipient, at);

        if (amount > debt) {
            revert WithdrawalOverDebt();
        } else if (amount == debt) {
            _withdrawal(recipient);
        } else {
            uint256 diff = _converge(
                amount,
                _interestRate,
                at,
                _compoundAnchor,
                _accrualPeriod
            );
            uint256 deposit = _compoundDeposit[recipient];
            if (diff > deposit) diff = deposit;
            _compoundDeposit[recipient] -= diff;
            _totalCompoundDeposit -= diff;
        }
    }

    function _withdrawal(address recipient) internal virtual override {
        uint256 deposit = _compoundDeposit[recipient];
        if (deposit != 0) {
            _totalCompoundDeposit -= deposit;
            _compoundDeposit[recipient] = 0;
        }
    }

    function _debt(
        address recipient,
        uint64 at
    ) internal view virtual override returns (uint256) {
        return
            _converge(
                _compoundDeposit[recipient],
                _interestRate,
                _compoundAnchor,
                at,
                _accrualPeriod
            );
    }

    function _totalDebt(
        uint64 at
    ) internal view virtual override returns (uint256) {
        return
            _converge(
                _totalCompoundDeposit,
                _interestRate,
                _compoundAnchor,
                at,
                _accrualPeriod
            );
    }

    /**
        @notice Yields money value, converged to specified point in time

        @return Converged amount of money [fixed]
     */
    function _converge(
        uint256 sum,
        uint256 interest,
        uint64 from,
        uint64 to,
        uint32 period
    ) private pure returns (uint256) {
        uint64 periods = Calendar.periods(from, to, period);
        if (periods == 0) return sum;
        uint256 lever = Math.powerX33(1e33 + interest * 1e15, periods) / 1e15;
        uint256 converged = to < from ? (sum * 1e36) / lever : sum * lever;
        return Math.fromX18(converged);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CommonInterest} from "./CommonInterest.sol";
import {SimpleInterest} from "./SimpleInterest.sol";
import {CompoundInterest} from "./CompoundInterest.sol";

/**
    @title FlexibleInterest
    @author iMe Lab

    @notice Contract fragment, implementing flexible interest accrual.
    "Flexible" means actual accrual strategy of an investor may change.
 */
abstract contract FlexibleInterest is SimpleInterest, CompoundInterest {
    constructor(uint256 compoundThreshold) {
        _compoundThreshold = compoundThreshold;
    }

    uint256 internal immutable _compoundThreshold;
    mapping(address => uint256) private _impact;
    uint256 private _accumulatedImpact;

    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal override(SimpleInterest, CompoundInterest) {
        uint256 impact = _impact[depositor];
        _impact[depositor] += amount;
        _accumulatedImpact += amount;

        if (impact >= _compoundThreshold) {
            CompoundInterest._deposit(depositor, amount, at);
        } else {
            if (impact + amount >= _compoundThreshold) {
                uint256 debt = SimpleInterest._debt(depositor, at);
                if (debt != 0) SimpleInterest._withdrawal(depositor);
                CompoundInterest._deposit(depositor, debt + amount, at);
            } else {
                SimpleInterest._deposit(depositor, amount, at);
            }
        }
    }

    function _withdrawal(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal override(SimpleInterest, CompoundInterest) {
        uint256 impact = _impact[depositor];
        uint256 decrease = (amount < impact) ? amount : impact;
        _impact[depositor] -= decrease;
        _accumulatedImpact -= decrease;

        if (impact > _compoundThreshold) {
            if (impact - decrease > _compoundThreshold) {
                CompoundInterest._withdrawal(depositor, amount, at);
            } else {
                uint256 debt = CompoundInterest._debt(depositor, at);
                if (debt != 0) CompoundInterest._withdrawal(depositor);
                if (amount != debt)
                    SimpleInterest._deposit(depositor, debt - amount, at);
            }
        } else {
            SimpleInterest._withdrawal(depositor, amount, at);
        }
    }

    function _withdrawal(
        address depositor
    ) internal override(SimpleInterest, CompoundInterest) {
        uint256 impact = _impact[depositor];
        if (impact >= _compoundThreshold)
            CompoundInterest._withdrawal(depositor);
        else SimpleInterest._withdrawal(depositor);
        _accumulatedImpact -= impact;
        _impact[depositor] = 0;
    }

    function _debt(
        address depositor,
        uint64 at
    )
        internal
        view
        override(SimpleInterest, CompoundInterest)
        returns (uint256)
    {
        if (_impact[depositor] >= _compoundThreshold)
            return CompoundInterest._debt(depositor, at);
        else return SimpleInterest._debt(depositor, at);
    }

    function _totalDebt(
        uint64 at
    )
        internal
        view
        override(SimpleInterest, CompoundInterest)
        returns (uint256)
    {
        return CompoundInterest._totalDebt(at) + SimpleInterest._totalDebt(at);
    }

    function _totalImpact() internal view returns (uint256) {
        return _accumulatedImpact;
    }

    function _impactOf(address investor) internal view returns (uint256) {
        return _impact[investor];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {CommonInterest} from "./CommonInterest.sol";
import {Math} from "../lib/Math.sol";
import {Calendar} from "../lib/Calendar.sol";

/**
    @title SimpleInterest
    @author iMe Lab

    @notice Implementation of simple interest accrual
    @dev https://en.wikipedia.org/wiki/Interest#Types_of_interest
 */
abstract contract SimpleInterest is CommonInterest {
    constructor(uint64 anchor) {
        _simpleAnchor = anchor;
    }

    uint64 private immutable _simpleAnchor;
    mapping(address => int256) private _simpleDeposit;
    int256 private _totalSimpleDeposit;
    mapping(address => uint256) private _simpleGrowth;
    uint256 private _totalSimpleGrowth;

    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        amount *= 1e18;
        uint256 growthIncrease = (amount * _interestRate) / 1e18;
        uint256 elapsed = Calendar.periods(_simpleAnchor, at, _accrualPeriod);
        int256 depoDiff = int256(amount) - int256(growthIncrease * elapsed);
        _simpleDeposit[depositor] += depoDiff;
        _simpleGrowth[depositor] += growthIncrease;
        _totalSimpleGrowth += growthIncrease;
        _totalSimpleDeposit += depoDiff;
    }

    function _withdrawal(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual override(CommonInterest) {
        uint256 debt = _debt(depositor, at);
        if (amount > debt) {
            revert WithdrawalOverDebt();
        } else if (amount == debt) {
            _withdrawal(depositor);
        } else {
            uint256 growth = _simpleGrowth[depositor];
            uint64 periods = Calendar.periods(
                _simpleAnchor,
                at,
                _accrualPeriod
            );
            uint256 percent = (amount * 1e36) / debt;
            if (percent > 1e18) percent = 1e18;
            uint256 growthDecrease = (growth * (1e18 - percent)) / 1e18;
            int256 depoDecrease = int256(amount * 1e18) -
                int256((growth * periods * (1e18 - percent)) / 1e18);
            _totalSimpleDeposit -= depoDecrease;
            _totalSimpleGrowth -= growthDecrease;
            _simpleDeposit[depositor] -= depoDecrease;
            _simpleGrowth[depositor] -= growthDecrease;
        }
    }

    function _withdrawal(address depositor) internal virtual override {
        int256 deposit = _simpleDeposit[depositor];
        if (deposit != 0) {
            _totalSimpleDeposit -= deposit;
            _simpleDeposit[depositor] = 0;
        }
        uint256 growth = _simpleGrowth[depositor];
        if (growth != 0) {
            _totalSimpleGrowth -= growth;
            _simpleGrowth[depositor] = 0;
        }
    }

    function _debt(
        address depositor,
        uint64 at
    ) internal view virtual override(CommonInterest) returns (uint256) {
        int256 deposit = _simpleDeposit[depositor];
        uint256 growth = _simpleGrowth[depositor];
        uint256 periods = Calendar.periods(_simpleAnchor, at, _accrualPeriod);
        int256 debt = int256(deposit) + int256(periods * growth);
        if (debt < 0) return 0;
        else return Math.fromX18(uint256(debt));
    }

    function _totalDebt(
        uint64 at
    ) internal view virtual override returns (uint256) {
        int256 deposit = _totalSimpleDeposit;
        uint256 growth = _totalSimpleGrowth;
        uint256 periods = Calendar.periods(_simpleAnchor, at, _accrualPeriod);
        int256 debt = int256(deposit) + int256(periods * growth);
        if (debt < 0) return 0;
        else return Math.fromX18(uint256(debt));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title TimeContext
    @author iMe Lab

    @notice Contract fragment, providing context of present moment
 */
abstract contract TimeContext {
    /**
        @notice Get present moment timestamp
        
        @dev It should be overridden in mock contracts
        Any implementation of this function should follow a rule:
        sequential calls of _now() should give non-decreasing sequence of numbers.
        It's forbidden to travel back in time.
     */
    function _now() internal view virtual returns (uint64) {
        // solhint-disable-next-line not-rely-on-time
        return uint64(block.timestamp);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title TransferDelayer
    @author iMe Lab

    @notice Contract fragment, responsible for token transfer delay
 */
abstract contract TransferDelayer {
    struct DelayedTransfer {
        /**
            @notice Amount of tokens to send, integer

            @dev uint192 is used in order to optimize gas costs
         */
        uint192 amount;
        /**
            @notice Timestamp to perform the transfer
         */
        uint64 notBefore;
    }

    mapping(address => DelayedTransfer[]) private _transfers;
    uint256 private _delayedValue = 0;

    function _delayTransfer(
        address recipient,
        uint256 amount,
        uint64 notBefore
    ) internal {
        assert(amount < 2 ** 192);
        _transfers[recipient].push(DelayedTransfer(uint192(amount), notBefore));
        _delayedValue += amount;
    }

    /**
        @notice Finalize transfers, which are ready, for certain user

        @dev Be sure to perform a real token transfer
     */
    function _finalizeDelayedTransfers(
        address recipient,
        uint64 moment
    ) internal returns (uint256) {
        DelayedTransfer[] memory transfers = _transfers[recipient];
        uint256 i = 0; // Index of the last transfer to perform
        uint256 tokensToSend = 0;

        for (; i < transfers.length && moment >= transfers[i].notBefore; i++)
            tokensToSend += transfers[i].amount;

        if (i == 0) {
            return 0;
        } else if (i == transfers.length) {
            delete _transfers[recipient];
        } else {
            for (uint256 k = 0; k < i; k++) {
                _transfers[recipient][k] = transfers[k + i];
                _transfers[recipient].pop();
            }
        }

        _delayedValue -= tokensToSend;
        return tokensToSend;
    }

    /**
        @notice Yields amount of delayed tokens for a certain user

        @return pending Amount of tokens, which cannot be transferred yet
        @return ready Amount of tokens, ready to be transferred
     */
    function _delayedTokensFor(
        address recipient,
        uint256 moment
    ) internal view returns (uint256 pending, uint256 ready) {
        DelayedTransfer[] memory transfers = _transfers[recipient];
        uint256 i = 0;
        for (; i < transfers.length && transfers[i].notBefore < moment; i++)
            ready += transfers[i].amount;

        for (; i < transfers.length; i++) pending += transfers[i].amount;
    }

    function _totalDelayed() internal view returns (uint256) {
        return _delayedValue;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingCore
    @author iMe Lab

    @notice General interface for iMe Staking v2
 */
interface IStakingCore {
    error TokenTransferFailed();
    error DepositIsTooEarly();
    error DepositIsTooLate();
    error DepositRankIsUntrusted();
    error DepositRankIsTooLow();
    error DepositDeadlineIsReached();
    error WithdrawalDelayIsUnwanted();
    error WithdrawalIsOffensive();
    error NoTokensReadyForClaim();
    error RewardIsTooEarly();
    error RefundIsTooEarly();

    event Deposit(address from, uint256 amount);
    event Withdrawal(address to, uint256 amount, uint256 fee);
    event DelayedWithdrawal(
        address to, uint256 amount, uint256 fee, uint64 until
    );
    event Claim(address to, uint256 amount);

    /**
        @notice Yields internal staking version

        @dev Version is needed to distinguish staking v1/v2 interfaces
     */
    function version() external pure returns (string memory);

    /**
       @notice Make a deposit

       @dev Should fire StakingDeposit event

       @param amount Amount of token to deposit. Should be approved in advance.
       @param rank Depositor's LIME rank
       @param deadline Deadline for deposit transaction
       @param v V part of the signature, proofing depositor's rank
       @param r R part of the signature, proofing depositor's rank
       @param s S part of the signature, proofing depositor's rank
     */
    function deposit(
        uint256 amount,
        uint8 rank,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
        @notice Withdraw staked and prize tokens

        @dev should fire StakingWithdrawal or StakingDelayedWithdrawal event

        @param amount Amount of tokens to withdraw
        @param delayed Whether withdrawal is delayed
     */
    function withdraw(uint256 amount, bool delayed) external;

    /**
        @notice Claim delayed withdrawn tokens

        @dev Actually doesn't matter who run this method: claimer address
        is passed as a parameter. So, anyone can pay gas to perform claim for
        a friend.

        Should fire StakingClaim event.

        @param depositor Depositor who performs claim
     */
    function claim(address depositor) external;

    /**
        @notice Force withdrawal for specified investor

        @dev Force withdrawals should be available after staking finish only.

        @param depositor Depositor to perform delay for
     */
    function reward(address depositor) external;

    /**
        @notice Take tokens which doesn't participate in staking. Should be
        available only after staking finish and only for tokens owner (partner)

        @param amount Amount of tokens to take. Should not be above free
        tokens. if amount = 0, all free tokens will be withdrawn
     */
    function refund(uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingInfo
    @author iMe Lab
    @notice Staking contract v2 extension, allowing clients to retrieve 
    staking programme information.

    Generally, needed for building better UX by allowing users to see staking
    requisites, lifespan, fees, etc.
 */
interface IStakingInfo {
    /**
        @notice General staking information
     */
    struct StakingInfo {
        /**
            @notice Staking name to be displayed everywhere
         */
        string name;
        /**
            @notice Partner name. As example, iMe Lab
         */
        string author;
        /**
            @notice Partner website. As example, https://imem.app
         */
        string website;
        /**
            @notice Address of token for staking
         */
        address token;
        /**
            @notice Interest per accrual period
            @dev Represented as fixed 2x18 number
         */
        uint64 interestRate;
        /**
            @notice Interest accrual period in seconds
         */
        uint32 accrualPeriod;
        /**
            @notice Duration of withdrawn tokens lock, in seconds
         */
        uint32 delayedWithdrawalDuration;
        /**
            @notice Impact needed to enable compound accrual
         */
        uint256 compoundAccrualThreshold;
        /**
            @notice Fee taken for delayed withdrawn tokens
            @dev Represented as fixed 2x18 number
         */
        uint64 delayedWithdrawalFee;
        /**
            @notice Fee taken for premature withdrawn tokens
            @dev Represented as fixed 2x18 number
         */
        uint64 prematureWithdrawalFee;
        /**
            @notice Minimal LIME rank needed to make deposits
         */
        uint8 minimalRank;
        /**
            @notice Staking start moment
         */
        uint64 startsAt;
        /**
            @notice Staking end moment. May change if staking stops
         */
        uint64 endsAt;
    }

    /**
        @notice Event, typically fired when staking info changes
     */
    event StakingInfoChanged();

    /**
        @notice Retrieve staking information

        @dev Information shouldn't change frequently
     */
    function info() external view returns (StakingInfo memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingPausable
    @author iMe Lab

    @notice Staking v2 extension, allowing managers to stop programmes.
 */
interface IStakingPausable {
    /**
        @notice Error, typically fired on attempt to do something during pause
     */
    error StakingIsPaused();

    /**
        @notice Temporary forbid user deposits/withdrawals
        Makes no sense after staking finish.
     */
    function pause() external;

    /**
        @notice Resume paused staking
     */
    function resume() external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingPredictable
    @author iMe Lab
    @notice Staking contract v2 extension, allowing clients to retrieve
    staking current statistics and predict debt in future.

    Generally, needed to predict staking solvency.
 */
interface IStakingPredictable {
    /**
        @notice Totals in this staking
     */
    struct StakingSummary {
        uint256 totalImpact;
        uint256 totalDebt;
        uint256 totalDelayed;
        uint256 balance;
    }

    /**
        @notice Populate staking summary for the present moment
     */
    function summary() external view returns (StakingSummary memory);

    /**
        @notice Predict total debt for a certain point in time

        @param at Unit in time to make a prediction. Shouldn't be in the past.
     */
    function totalDebt(uint64 at) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title IStakingStatistics
    @author iMe Lab
    @notice Staking contract v2 extension, allowing clients to
    see their own statistics

    Generally, needed to improve UX by showing users their staked, accrued
    and delayed token amounts.
 */
interface IStakingStatistics {
    /**
        @notice Staking stats, related to a certain investor
     */
    struct StakingStatistics {
        uint256 impact;
        uint256 debt;
        uint256 pendingWithdrawnTokens;
        uint256 readyWithdrawnTokens;
    }

    /**
        @notice Yields personal stats for a certain investor
     */
    function statsOf(address) external view returns (StakingStatistics memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title Calendar
    @author iMe Lab

    @notice Small date & time library
 */
library Calendar {
    /**
        @notice Count round periods over time interval
        
        @dev Example case, where function should return 3:
        
         duration = |-----|
        
             start               end
               |                  |
               V                  V
        -----|-----|-----|-----|-----|-----|---
    
        @param start Interval start
        @param end Interval end
        @param duration Period duration
     */
    function periods(
        uint64 start,
        uint64 end,
        uint32 duration
    ) internal pure returns (uint64 count) {
        unchecked {
            if (start > end) (start, end) = (end, start);
            count = (end - start) / duration;
            if (start % duration > end % duration) count += 1;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title LimeRank
    @author iMe Lab

    @notice Library for working with LIME ranks
 */
library LimeRank {
    /**
        @notice Yields proof for **subject** that **issuer** has LIME **rank**
        in a timespan, not later than **deadline**

        @dev "Proofs" make sense only if they are signed. Signing example:

        ```typescript
          const hash = ethers.utils.solidityKeccak256(
            ["address", "address", "uint256", "uint8"],
            [subject, issuer, deadline, rank]
          );
          const proof = ethers.utils.arrayify(hash);
          const sig = await arbiter.signMessage(proof);
          const { v, r, s } = ethers.utils.splitSignature(sig);
        ```

        @param subject Address of entity that performs check
        @param issuer Address of account who proofs his rank
        @param deadline Proof expiration timestamp
        @param rank LIME rank that being proofed
    */
    function proof(
        address subject,
        address issuer,
        uint256 deadline,
        uint8 rank
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(subject, issuer, deadline, rank))
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title Math
    @author iMe Lab

    @notice Maths library. Generally, for financial computations.
 */
library Math {
    /**
        @notice Yields integer exponent of fixed-point number

        @dev Implementation of Exponintiation by squaring algorightm.
        Highly inspired by PRBMath library. Uses x33 precision instead
        of x18 in order to make financial computations more accurate.

        @param x Exponent base, 33x33 fixed number close to 1.0
        @param y Exponentiation parameter, integer
     */
    function powerX33(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 power) {
        unchecked {
            power = y & 1 > 0 ? x : 1e33;

            for (y >>= 1; y > 0; y >>= 1) {
                x = (x * x) / 1e33;
                if (y & 1 > 0) power = (power * x) / 1e33;
            }
        }
    }

    /**
        @notice Round x18 fixed number to an integer
     */
    function fromX18(uint256 fixedX18) internal pure returns (uint256 round) {
        unchecked {
            round = fixedX18 / 1e18;
            if (fixedX18 % 1e18 > 5e17) round += 1;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferDelayer} from "./abstract/TransferDelayer.sol";
import {FlexibleInterest} from "./abstract/FlexibleInterest.sol";
import {CommonInterest} from "./abstract/CommonInterest.sol";
import {CompoundInterest} from "./abstract/CompoundInterest.sol";
import {SimpleInterest} from "./abstract/SimpleInterest.sol";
import {LimeRank} from "./lib/LimeRank.sol";
import {Math} from "./lib/Math.sol";
import {TimeContext} from "./abstract/TimeContext.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IStakingCore} from "./IStakingCore.sol";
import {IStakingInfo} from "./IStakingInfo.sol";
import {IStakingPredictable} from "./IStakingPredictable.sol";
import {IStakingStatistics} from "./IStakingStatistics.sol";
import {IStakingPausable} from "./IStakingPausable.sol";

/**
    @title Staking
    @author iMe Lab

    @notice Implementation of iMe staking version 2
 */
contract Staking is
    IStakingCore,
    IStakingInfo,
    IStakingPredictable,
    IStakingStatistics,
    IStakingPausable,
    FlexibleInterest,
    TransferDelayer,
    TimeContext,
    AccessControl
{
    constructor(
        StakingInfo memory blueprint
    )
        FlexibleInterest(blueprint.compoundAccrualThreshold)
        SimpleInterest(blueprint.startsAt - blueprint.accrualPeriod * 2)
        CompoundInterest((blueprint.startsAt + blueprint.endsAt) / 2)
        CommonInterest(blueprint.interestRate, blueprint.accrualPeriod)
    {
        require(blueprint.startsAt < blueprint.endsAt);
        require(blueprint.prematureWithdrawalFee < 1e18);
        require(blueprint.delayedWithdrawalFee < 1e18);

        _name = blueprint.name;
        _author = blueprint.author;
        _website = blueprint.website;
        _token = IERC20(blueprint.token);
        _minimalRank = blueprint.minimalRank;
        _delayedWithdrawalDuration = blueprint.delayedWithdrawalDuration;
        _startsAt = blueprint.startsAt;
        _endsAt = blueprint.endsAt;
        _delayedWithdrawalFee = blueprint.delayedWithdrawalFee;
        _prematureWithdrawalFee = blueprint.prematureWithdrawalFee;
        _isPaused = false;

        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(PARTNER_ROLE, _msgSender());

        _setRoleAdmin(MANAGER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(ARBITER_ROLE, MANAGER_ROLE);
        _setRoleAdmin(PARTNER_ROLE, PARTNER_ROLE);
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");
    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    string private _name;
    string private _author;
    string private _website;
    IERC20 private immutable _token;
    uint8 private immutable _minimalRank;
    uint32 private immutable _delayedWithdrawalDuration;
    uint64 private immutable _startsAt;
    uint64 private _endsAt;
    uint64 private immutable _delayedWithdrawalFee;
    uint64 private immutable _prematureWithdrawalFee;

    bool private _isPaused;

    function version() external pure override returns (string memory) {
        return "3";
    }

    function info() external view override returns (StakingInfo memory) {
        return
            StakingInfo(
                _name,
                _author,
                _website,
                address(_token),
                _interestRate,
                _accrualPeriod,
                _delayedWithdrawalDuration,
                _compoundThreshold,
                _delayedWithdrawalFee,
                _prematureWithdrawalFee,
                _minimalRank,
                _startsAt,
                _endsAt
            );
    }

    function summary() external view override returns (StakingSummary memory) {
        return
            StakingSummary(
                _totalImpact(),
                _totalDebt(_accrualNow()),
                _totalDelayed(),
                _token.balanceOf(address(this))
            );
    }

    function totalDebt(uint64 at) external view override returns (uint256) {
        if (at > _endsAt) at = _endsAt;
        else if (at < _now()) at = _now();
        return _totalDebt(at);
    }

    function statsOf(
        address investor
    ) external view override returns (StakingStatistics memory) {
        (uint256 pending, uint256 ready) = _delayedTokensFor(investor, _now());

        return
            StakingStatistics(
                _impactOf(investor),
                _debt(investor, _accrualNow()),
                pending,
                ready
            );
    }

    function deposit(
        uint256 amount,
        uint8 rank,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(amount > 0);
        if (_now() >= deadline) revert DepositDeadlineIsReached();
        if (_isPaused) revert StakingIsPaused();
        if (_now() < _startsAt) revert DepositIsTooEarly();
        if (_now() >= _endsAt) revert DepositIsTooLate();
        if (_minimalRank != 0) {
            address subject = address(this);
            address sender = _msgSender();
            bytes32 proof = LimeRank.proof(subject, sender, deadline, rank);
            address signer = ecrecover(proof, v, r, s);
            if (!this.hasRole(ARBITER_ROLE, signer))
                revert DepositRankIsUntrusted();
            if (rank < _minimalRank) revert DepositRankIsTooLow();
        }
        _deposit(_msgSender(), amount, _now());
        emit Deposit(_msgSender(), amount);
        _safe(_token.transferFrom(_msgSender(), address(this), amount));
    }

    function withdraw(uint256 amount, bool delayed) external override {
        require(amount > 0);
        if (_now() < _endsAt && _isPaused) revert StakingIsPaused();

        _withdrawal(_msgSender(), amount, _accrualNow());

        if (delayed) {
            if (_now() >= _endsAt) revert WithdrawalDelayIsUnwanted();
            uint256 fee = Math.fromX18(amount * _delayedWithdrawalFee);
            uint64 unlockAt = _now() + _delayedWithdrawalDuration;
            _delayTransfer(_msgSender(), amount - fee, unlockAt);
            emit DelayedWithdrawal(_msgSender(), amount, fee, unlockAt);
        } else {
            uint256 fee;
            if (_now() < _endsAt)
                fee = Math.fromX18(amount * _prematureWithdrawalFee);

            _safe(_token.transfer(_msgSender(), amount - fee));
            emit Withdrawal(_msgSender(), amount, fee);
        }

        if (!_hasEnoughFunds()) revert WithdrawalIsOffensive();
    }

    function reward(address to) external override onlyRole(MANAGER_ROLE) {
        if (_now() < _endsAt) revert RewardIsTooEarly();
        uint256 prize = _debt(to, _accrualNow());
        _withdrawal(to);
        emit Withdrawal(to, prize, 0);
        _safe(_token.transfer(to, prize));
        if (!_hasEnoughFunds()) revert WithdrawalIsOffensive();
    }

    function refund(uint256 amount) external override onlyRole(PARTNER_ROLE) {
        if (_now() < _endsAt) revert RefundIsTooEarly();
        uint256 tokensToGive = _totalDelayed() + _totalDebt(_accrualNow());
        uint256 balance = _token.balanceOf(address(this));
        if (balance < tokensToGive) revert WithdrawalIsOffensive();

        uint256 freeTokens = balance - tokensToGive;
        if (amount == 0) amount = freeTokens;
        else if (amount > freeTokens) revert WithdrawalIsOffensive();

        _safe(_token.transfer(_msgSender(), amount));
    }

    function claim(address recipient) external override {
        uint256 amount = _finalizeDelayedTransfers(recipient, _now());
        if (amount == 0) revert NoTokensReadyForClaim();
        emit Claim(recipient, amount);
        _safe(_token.transfer(recipient, amount));
    }

    function pause() external override onlyRole(MANAGER_ROLE) {
        require(!_isPaused);
        _isPaused = true;
    }

    function resume() external override onlyRole(MANAGER_ROLE) {
        require(_isPaused);
        _isPaused = false;
    }

    function stop() external onlyRole(MANAGER_ROLE) {
        require(_now() >= _startsAt);
        require(_now() < _endsAt);
        _endsAt = _now();
        emit StakingInfoChanged();
    }

    function setRequisites(
        string calldata name,
        string calldata author,
        string calldata website
    ) external onlyRole(MANAGER_ROLE) {
        require(
            keccak256(abi.encode(_name, _author, _website)) !=
                keccak256(abi.encode(name, author, website))
        );
        (_name, _author, _website) = (name, author, website);
        emit StakingInfoChanged();
    }

    function _hasEnoughFunds() private view returns (bool) {
        return
            _token.balanceOf(address(this)) >= _totalImpact() + _totalDelayed();
    }

    function _safe(bool transfer) private pure {
        if (!transfer) revert TokenTransferFailed();
    }

    function _accrualNow() internal view returns (uint64) {
        uint64 time = _now();
        return time < _endsAt ? time : _endsAt;
    }

    receive() external payable {
        revert();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LimeRank} from "./lib/LimeRank.sol";
import {Staking} from "./Staking.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
    @title StakingFactory
    @author iMe Lab

    @notice Factory for iMe Staking v2 programmes
 */
contract StakingFactory is AccessControl {
    /**
        @notice Event, typically fired when a new staking is created
     */
    event StakingCreated(address at);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
        @notice Role, typically assigned to accounts who actually
        create staking programmes
    */
    bytes32 public constant FACTORY_WORKER_ROLE =
        keccak256("FACTORY_WORKER_ROLE");

    /**
        @notice Create a new staking programme

        @dev Should fire StakingCreated event

        @param blueprint Blueprint to compose staking programme from
        @param manager Address to assign MANAGER_ROLE. Shouldn't be empty.
        @param partner Address to assign PARTNER_TOLE. Shouldn't be empty.
        @param arbiter Address to assign ARBITER_ROLE. Can be empty.
        This option is useful in cases when staking doesn't require LIME rank.
     */
    function create(
        Staking.StakingInfo calldata blueprint,
        address manager,
        address partner,
        address arbiter
    ) external onlyRole(FACTORY_WORKER_ROLE) {
        require(manager != address(0));
        require(partner != address(0));
        Staking staking = new Staking(blueprint);
        staking.grantRole(staking.MANAGER_ROLE(), manager);
        staking.grantRole(staking.PARTNER_ROLE(), partner);
        if (arbiter != address(0))
            staking.grantRole(staking.ARBITER_ROLE(), arbiter);
        staking.renounceRole(staking.MANAGER_ROLE(), address(this));
        staking.renounceRole(staking.PARTNER_ROLE(), address(this));
        emit StakingCreated(address(staking));
    }

    receive() external payable {
        revert();
    }
}