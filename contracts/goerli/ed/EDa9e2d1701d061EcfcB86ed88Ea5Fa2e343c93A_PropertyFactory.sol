/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT

// Copyright 2022 KeyLynx Team

pragma solidity 0.8.17;

// The following code is from flattening this import statement in: PropertyFactory.sol
// import { Ownable } from './helpers/Ownable.sol';
// The following code is from flattening this file: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/helpers/Ownable.sol

// based on OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.17;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, 'Ownable: caller is not the owner');
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// The following code is from flattening this import statement in: PropertyFactory.sol
// import { Property } from './Property.sol';
// The following code is from flattening this file: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/Property.sol

// Copyright 2022 KeyLynx Team

pragma solidity 0.8.17;

// The following code is from flattening this import statement in: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/Property.sol
// import { IERC20 } from './interfaces/IERC20.sol';
// The following code is from flattening this file: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/interfaces/IERC20.sol

// based on OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// The following code is from flattening this import statement in: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/Property.sol
// import { Strings } from './libraries/Strings.sol';
// The following code is from flattening this file: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/libraries/Strings.sol

// based on OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity 0.8.17;

// The following code is from flattening this import statement in: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/libraries/Strings.sol
// import { Math } from './Math.sol';
// The following code is from flattening this file: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/libraries/Math.sol

// based on OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity 0.8.17;

/**
 * @title Standard math utilities missing in the Solidity language.
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}


/**
 * @title String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = '0123456789abcdef';
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
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// The following code is from flattening this import statement in: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/Property.sol
// import { AccessControl } from './helpers/AccessControl.sol';
// The following code is from flattening this file: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/helpers/AccessControl.sol

// based on OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity 0.8.17;

// The following code is from flattening this import statement in: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/helpers/AccessControl.sol
// import { IAccessControl } from '../interfaces/IAccessControl.sol';
// The following code is from flattening this file: /Users/tkr/Code/KeyLynx/SEC-Token/contracts/interfaces/IAccessControl.sol

// based on OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.17;

/**
 * @title AccessControl Interface.
 */
interface IAccessControl {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// Skipping this already resolved import statement found in /Users/tkr/Code/KeyLynx/SEC-Token/contracts/helpers/AccessControl.sol 
// import { Strings } from '../libraries/Strings.sol';

/**
 * @title Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier.
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 */
abstract contract AccessControl is IAccessControl {
    mapping(bytes32 => address) private _roles; // role hash => EOA
    mapping(bytes32 => bytes32) private _adminRoles; // role hash => role hash
    bytes4 private constant INTERFACE_ID_ACCESS_CONTROL = 0xbc9a529f;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return interfaceId == INTERFACE_ID_ACCESS_CONTROL;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role] == account;
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _adminRoles[role];
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public onlyRole(getRoleAdmin(role)) {
        _setRoleAdmin(role, adminRole);
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
     * Emits a {RoleGranted} event.
     */
    function grantRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
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
     * Emits a {RoleRevoked} event.
     */
    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        require(
            getRoleAdmin(role) != role,
            'AccessControl::revokeRole: role admin can not revoke own role'
        );
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
     * Emits a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(
            account == msg.sender,
            'AccessControl::renounceRole: can only renounce roles for self'
        );
        require(
            getRoleAdmin(role) != role,
            'AccessControl::renounceRole: role admin can not renounce own role'
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as `role`'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _adminRoles[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * Emits a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role] = account;
            emit RoleGranted(role, account, msg.sender);
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
            _roles[role] = address(0);
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /**
     * @dev Revert with a standard message if `msg.sender` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        require(
            hasRole(role, account),
            string(
                abi.encodePacked(
                    'AccessControl::_checkRole: account ',
                    Strings.toHexString(account),
                    ' is missing role ',
                    Strings.toHexString(uint256(role), 32)
                )
            )
        );
    }
}


/**
 * @title Implementation of a token that allows for SEC compliant
 * real estate ownership and transfer while ensuring royalties
 * payout at all times.
 */
contract Property is AccessControl {
    using Strings for uint256;

    //============================================================================
    // Events
    //============================================================================

    event RoyaltiesSet(address indexed beneficiary, uint256 bps, bytes32 role);
    event AskingPriceUpdate(address indexed token, uint256 value);
    event OfferUpdate(address indexed bidder, address indexed token, uint256 value);
    event RoyaltiesPaid(
        address indexed beneficiary,
        address indexed token,
        uint256 value,
        bytes32 role
    );
    event ClosingTable(
        address indexed seller,
        address indexed buyer,
        address indexed token,
        uint256 received,
        uint256 paid
    );

    //============================================================================
    // Type Definitions
    //============================================================================

    struct Royalty {
        address payable beneficiary;
        uint256 bps; // basepoints (0 - 10,000)
    }

    struct Offer {
        address token;
        uint256 value;
        bool fundsVerified;
    }

    //============================================================================
    // Roles for Access Control
    //============================================================================

    // 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
    bytes32 private constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    // 0x18d9ff454de989bd126b06bd404b47ede75f9e65543e94e8d212f89d7dcbb87c
    bytes32 private constant PROVIDER_ROLE = keccak256('PROVIDER_ROLE');
    // 0xfeb983a7695463ef5b6eb7089f94f157c3c925417d08e4762b54797793ffd028
    bytes32 private constant PROPERTY_OWNER_ROLE = keccak256('PROPERTY_OWNER_ROLE');
    // 0x7395af2ec1d18e55ecb857fa7e8cbc9c78ce136fa91d614cd0954d357a2e75e1
    bytes32 private constant LISTING_BROKER_ROLE = keccak256('LISTING_BROKER_ROLE');
    // 0x428e5e535f46211464eefb943d7766ec44e7643776b0bd8c9cb3cd7a616ea97b
    bytes32 private constant PROPERTY_BUYER_ROLE = keccak256('PROPERTY_BUYER_ROLE');
    // 0xea53f3f4335c0e97dcbcb027b53f0824c6587837e0192917c8f81e4a7a90b698
    bytes32 private constant REGULATED_TRANSFER_AGENT_ROLE =
        keccak256('REGULATED_TRANSFER_AGENT_ROLE');

    //============================================================================
    // Private State Variables
    //============================================================================

    bool private _royaltiesReceiverAddressSet;
    address private _propertyOwnerAtContractDeployment;
    address[] private biddersToClean;
    address[] private tokensToClean;

    //============================================================================
    // Public State Variables
    //============================================================================

    bool public offerAccepted;
    address public tokenAcceptedForClosing;
    string public streetAddress;
    string public legalDescription;
    string public documentationURI;
    Royalty[3] public Royalties; // [0] for property owner; [1] for listing broker; [2] for provider
    mapping(address => uint256) public AskingPrices; // managed by property owner: token => value
    mapping(address => Offer) public Offers; // managed by bidders: bidder => Offer

    //============================================================================
    // Constructor
    //============================================================================

    // The property owner can choose a smart contract to receive their
    // royalties. This RoyaltiesReceiver contract then becomes a tradable token with
    // real value that the owner can either keep and collect royalties over time
    // or sell for profit. The owner should pass a contract address if they plan on
    // trading those royalties rights, if not they should pass their EOA
    constructor(
        string memory _streetAddress,
        string memory _legalDescription,
        string memory _documentationURI,
        address _propertyOwner,
        address _listingBroker,
        address _transferAgent,
        address _provider,
        uint256 _ownerRoyaltiesBps,
        uint256 _listingBrokerRoyaltiesBps,
        uint256 _providerRoyaltiesBps
    ) {
        // allow no empty strings, no smart contract or zero addresses and restrict sum of royalties to max 5%
        require(
            keccak256(abi.encodePacked(_streetAddress)) != keccak256(abi.encodePacked('')) &&
                keccak256(abi.encodePacked(_legalDescription)) != keccak256(abi.encodePacked('')) &&
                keccak256(abi.encodePacked(_documentationURI)) != keccak256(abi.encodePacked('')) &&
                !_isContract(_propertyOwner) &&
                _propertyOwner != address(0) &&
                !_isContract(_listingBroker) &&
                _listingBroker != address(0) &&
                !_isContract(_transferAgent) &&
                _transferAgent != address(0) &&
                !_isContract(_provider) &&
                _provider != address(0) &&
                (_ownerRoyaltiesBps + _listingBrokerRoyaltiesBps + _providerRoyaltiesBps) <= 500
        ); // require statements in the constructor don't revert, but fail and don't pass an error message

        streetAddress = _streetAddress;
        legalDescription = _legalDescription;
        documentationURI = _documentationURI;

        // initialize owner and their royalties
        _propertyOwnerAtContractDeployment = _propertyOwner;
        _grantRole(PROPERTY_OWNER_ROLE, _propertyOwner);
        Royalties[0].beneficiary = payable(_propertyOwner);
        Royalties[0].bps = _ownerRoyaltiesBps;
        emit RoyaltiesSet(_propertyOwner, _ownerRoyaltiesBps, PROPERTY_OWNER_ROLE);

        // Set RTA
        _grantRole(REGULATED_TRANSFER_AGENT_ROLE, _transferAgent);

        // Set role administration: only the adminRole can reassign these roles.
        _grantRole(ADMIN_ROLE, _transferAgent);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PROPERTY_OWNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(REGULATED_TRANSFER_AGENT_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PROPERTY_BUYER_ROLE, PROPERTY_OWNER_ROLE);

        // Set royalties for listing broker and provider
        Royalties[1].beneficiary = payable(_listingBroker);
        Royalties[1].bps = _listingBrokerRoyaltiesBps;
        emit RoyaltiesSet(_listingBroker, _listingBrokerRoyaltiesBps, LISTING_BROKER_ROLE);
        Royalties[2].beneficiary = payable(_provider);
        Royalties[2].bps = _providerRoyaltiesBps;
        emit RoyaltiesSet(_provider, _providerRoyaltiesBps, PROVIDER_ROLE);
    }

    //============================================================================
    // Mutative Functions
    //============================================================================

    receive() external payable {}

    // Reserved for RTA
    function transferCOIN(
        address to,
        uint256 amount
    ) public onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        require(to != address(0), 'Property::transferCOIN: zero address not allowed');
        require(amount != 0, 'Property::transferCOIN: amount can not be zero');
        require(
            address(this).balance >= amount,
            'Property::transferCOIN: insufficient balance on the contract'
        );
        (bool success, bytes memory data) = to.call{ value: amount }('');
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'Property::transferCOIN: failed'
        );
    }

    // Reserved for RTA
    function safeTransferERC20(
        address token,
        address to,
        uint256 amount
    ) public onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        require(token != address(0), 'Property::safeTransferERC20: use transferCOIN() instead');
        require(to != address(0), 'Property::safeTransferERC20: zero address not allowed');
        require(amount != 0, 'Property::safeTransferERC20: amount can not be zero');
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            'Property::safeTransferERC20: insufficient contract balance'
        );
        require(
            IERC20(token).transfer(to, amount),
            string(
                abi.encodePacked(
                    'Property::safeTransferERC20: safe transfer of ERC20 token ',
                    Strings.toHexString(token),
                    ' to ',
                    Strings.toHexString(to),
                    ' in the amount of ',
                    Strings.toHexString(uint256(amount), 32),
                    ' failed.'
                )
            )
        );
    }

    // Reserved for property owner
    function setAskingPrices(
        address[] calldata tokens,
        uint256[] calldata values
    ) public virtual onlyRole(PROPERTY_OWNER_ROLE) {
        uint256 arrayLength = tokens.length;
        require(arrayLength == values.length, 'Property::setAskingPrices: array length mismatch');
        require(arrayLength != 0, 'Property::setAskingPrices: arrays can not be empty');
        for (uint256 i = 0; i < arrayLength; i++) {
            require(
                _isContract(tokens[i]) || tokens[i] == address(0),
                string(
                    abi.encodePacked(
                        'Property::setAskingPrices: address ',
                        Strings.toHexString(tokens[i]),
                        ' is neither a smart contract address nor the zero address'
                    )
                )
            );
            require(
                values[i] != 0,
                string(
                    abi.encodePacked(
                        'Property::setAskingPrices: can not set asking price for ',
                        Strings.toHexString(tokens[i]),
                        ' due to 0 value'
                    )
                )
            );
            AskingPrices[tokens[i]] = values[i];

            // store tokens so they can be cleaned after closing
            tokensToClean.push(tokens[i]);
            emit AskingPriceUpdate(tokens[i], values[i]);
        }
    }

    // Anyone (except for the property owner and the RTA) can make an offer
    function makeOffer(address token, uint256 value, bool verify) external virtual {
        require(
            !hasRole(PROPERTY_OWNER_ROLE, msg.sender) &&
                !hasRole(REGULATED_TRANSFER_AGENT_ROLE, msg.sender),
            'Property::makeOffer: property owner and RTA can not make an offer'
        );
        require(
            !_isContract(msg.sender),
            'Property::makeOffer: a smart contract address is not allowed to make an offer'
        );
        require(
            AskingPrices[token] != 0,
            string(
                abi.encodePacked(
                    'Property::makeOffer: no asking price set for ',
                    Strings.toHexString(token)
                )
            )
        );
        require(value != 0, 'Property::makeOffer: value needs to be greater than 0');
        Offers[msg.sender].token = token;
        Offers[msg.sender].value = value;
        if (verify) {
            Offers[msg.sender].fundsVerified = (
                token == address(0)
                    ? msg.sender.balance >= value
                    : IERC20(token).balanceOf(msg.sender) >= value
            );
        }

        // store bidder for reset after closing
        biddersToClean.push(msg.sender);

        emit OfferUpdate(msg.sender, token, value);
    }

    // The property owner can accept any offer. It doesn't have to be the highest
    // as other factors play a role in real estate that are negotiated outside of the smart contract.
    function acceptOffer(
        address winningBidder,
        address token
    ) external virtual onlyRole(PROPERTY_OWNER_ROLE) {
        // This eliminates testing if 'winningBidder' is a smart contract as that is done in makeOffer()
        require(Offers[winningBidder].value != 0, 'Property::acceptOffer: no offer recorded');
        require(!offerAccepted, 'Property::acceptOffer: offer was already accepted');
        offerAccepted = true;
        tokenAcceptedForClosing = token;
        grantRole(PROPERTY_BUYER_ROLE, winningBidder);
    }

    // The RTA is given the ability to cancel an accepted offer.
    // This allows the seller to accept a new offer
    function resetOfferAcceptance() external virtual onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        require(offerAccepted, 'Property::resetOfferAcceptance: no accepted offer to reset');
        offerAccepted = false;
        tokenAcceptedForClosing = address(0);
    }

    // To be called by RTA to execute the closing table.
    // The buyer must have sent the full offer amount to address(this) before the function can be executed.
    function closeTheTable(
        address from,
        address to
    ) external virtual onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        _checkRole(PROPERTY_OWNER_ROLE, from);
        _checkRole(PROPERTY_BUYER_ROLE, to);
        uint256 royaltiesBps;
        uint256 amount;
        bytes32[3] memory roles = [PROPERTY_OWNER_ROLE, LISTING_BROKER_ROLE, PROVIDER_ROLE];
        if (tokenAcceptedForClosing == address(0)) {
            // transfer coin
            require(
                address(this).balance >= Offers[to].value && Offers[to].token == address(0),
                'Property::closeTheTable: insufficient coin to close the transaction'
            );
            // transfer royalties
            for (uint256 i = 0; i < Royalties.length; i++) {
                amount = (Offers[to].value * Royalties[i].bps) / 10000;
                transferCOIN(Royalties[i].beneficiary, amount);
                royaltiesBps += Royalties[i].bps;
                emit RoyaltiesPaid(Royalties[i].beneficiary, address(0), amount, roles[i]);
            }
            // transfer remaining funds to seller
            transferCOIN(from, (Offers[to].value * (10000 - royaltiesBps)) / 10000);
        } else {
            // transfer ERC20
            require(
                IERC20(tokenAcceptedForClosing).balanceOf(address(this)) >= Offers[to].value &&
                    Offers[to].token == tokenAcceptedForClosing,
                'Property::closeTheTable: insufficient token balance to close the transaction'
            );
            // transfer royalties
            for (uint256 i = 0; i < Royalties.length; i++) {
                amount = (Offers[to].value * Royalties[i].bps) / 10000;
                safeTransferERC20(tokenAcceptedForClosing, Royalties[i].beneficiary, amount);
                royaltiesBps += Royalties[i].bps;
                emit RoyaltiesPaid(
                    Royalties[i].beneficiary,
                    tokenAcceptedForClosing,
                    amount,
                    roles[i]
                );
            }
            // transfer remaining funds to seller
            safeTransferERC20(
                tokenAcceptedForClosing,
                from,
                (Offers[to].value * (10000 - royaltiesBps)) / 10000
            );
        }

        // We must account for the first sale where Royalties[0].beneficiary is the current owner
        if (from == Royalties[0].beneficiary) {
            emit ClosingTable(
                from,
                to,
                tokenAcceptedForClosing,
                (Offers[to].value * (10000 - (Royalties[1].bps + Royalties[2].bps))) / 10000,
                Offers[to].value
            );
        } else {
            emit ClosingTable(
                from,
                to,
                tokenAcceptedForClosing,
                (Offers[to].value * (10000 - royaltiesBps)) / 10000,
                Offers[to].value
            );
        }

        _transferOwnership(to); // transfer real estate token to buyer
        // the new owner should change this again once they have a new listing broker by calling
        // setListingBrokerForRoyalties()
        // if no new broker, funds will go to the new owner
        Royalties[1].beneficiary = payable(to);

        // reset asking prices and offers
        for (uint256 i = 0; i < tokensToClean.length; i++) {
            AskingPrices[tokensToClean[i]] = 0;
        }
        tokensToClean = new address[](0);

        for (uint256 i = 0; i < biddersToClean.length; i++) {
            Offers[biddersToClean[i]].token = address(0);
            Offers[biddersToClean[i]].value = 0;
            Offers[biddersToClean[i]].fundsVerified = false;
        }
        biddersToClean = new address[](0);

        emit RoyaltiesSet(Royalties[1].beneficiary, Royalties[1].bps, LISTING_BROKER_ROLE);
        _revokeRole(PROPERTY_BUYER_ROLE, to);
    }

    // The RTA has the option to destroy the current smart contract
    // and deploy a new one to the rightful property owner.
    // This should only be done if the owner lost their private keys to the address
    // stored in this contract or when a court of law decided that the true property owner is not
    // the one stored here.
    // Any ERC20 token balances must be transferred to an escrow wallet managed by the RTA
    // before calling this function. The coin balance will automatically be sent to msg.sender.
    function destroy() external virtual onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        selfdestruct(payable(msg.sender));
    }

    // The RTA is given the ability to modify the street address if there are any errors discovered.
    function setNewStreetAddress(
        string calldata newAddress
    ) external virtual onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        require(
            keccak256(abi.encodePacked(newAddress)) != keccak256(abi.encodePacked('')),
            'Property::setNewStreetAddress: please pass the correct address'
        );
        require(
            keccak256(abi.encodePacked(newAddress)) != keccak256(abi.encodePacked(streetAddress)),
            'Property::setNewStreetAddress: new address same as existing address'
        );
        streetAddress = newAddress;
    }

    // The RTA is given the ability to modify the legal description if there are any errors discovered.
    function setNewLegalDescription(
        string calldata newDescription
    ) external virtual onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        require(
            keccak256(abi.encodePacked(newDescription)) != keccak256(abi.encodePacked('')),
            'Property::setNewLegalDescription: please pass the correct description'
        );
        require(
            keccak256(abi.encodePacked(newDescription)) !=
                keccak256(abi.encodePacked(legalDescription)),
            'Property::setNewLegalDescription: new description same as existing description'
        );
        legalDescription = newDescription;
    }

    // The RTA is given the ability to modify the URI with the documentation if there are any errors discovered.
    function setNewDocumentationURI(
        string calldata newURI
    ) external virtual onlyRole(REGULATED_TRANSFER_AGENT_ROLE) {
        require(
            keccak256(abi.encodePacked(newURI)) != keccak256(abi.encodePacked('')),
            'Property::setNewDocumentationURI: please pass the correct URI'
        );
        require(
            keccak256(abi.encodePacked(newURI)) != keccak256(abi.encodePacked(documentationURI)),
            'Property::setNewDocumentationURI: new URI same as existing URI'
        );
        documentationURI = newURI;
    }

    // The RoyaltiesReceiver contract is deployed first and has to be manually added.
    // This can only be done once.
    function setOwnerRoyaltiesReceiverSmartContract(
        address _ownerRoyaltiesReceiverSmartContract
    ) external virtual onlyRole(PROPERTY_OWNER_ROLE) {
        require(
            !_royaltiesReceiverAddressSet,
            'Property::setOwnerRoyaltiesReceiverSmartContract: the royalties receiver address can only be set once'
        );
        require(
            msg.sender == _propertyOwnerAtContractDeployment,
            'Property::setOwnerRoyaltiesReceiverSmartContract: only the initial property owner can set'
        );
        require(
            _isContract(_ownerRoyaltiesReceiverSmartContract),
            'Property::setOwnerRoyaltiesReceiverSmartContract: must be a smart contract address'
        );
        Royalties[0].beneficiary = payable(_ownerRoyaltiesReceiverSmartContract);
        _royaltiesReceiverAddressSet = true;
        emit RoyaltiesSet(Royalties[0].beneficiary, Royalties[0].bps, PROPERTY_OWNER_ROLE);
    }

    // To be called by the property owner when they have a new listing broker
    function setListingBrokerForRoyalties(
        address newListingBroker
    ) external virtual onlyRole(PROPERTY_OWNER_ROLE) {
        require(
            !_isContract(newListingBroker),
            'Property::setListingBrokerForRoyalties: smart contract address is not allowed'
        );
        Royalties[1].beneficiary = payable(newListingBroker);
        emit RoyaltiesSet(newListingBroker, Royalties[1].bps, LISTING_BROKER_ROLE);
    }

    // To be called by the provider to change their wallet address
    function setProviderForRoyalties(address newProvider) external virtual onlyRole(ADMIN_ROLE) {
        require(
            !_isContract(newProvider),
            'Property::setProviderForRoyalties: smart contract address is not allowed'
        );
        Royalties[2].beneficiary = payable(newProvider);
        emit RoyaltiesSet(newProvider, Royalties[2].bps, PROVIDER_ROLE);
    }

    //============================================================================
    // Private Functions
    //============================================================================

    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }

    function _transferOwnership(address _to) private {
        // set new owner
        grantRole(PROPERTY_OWNER_ROLE, _to);

        // reset status for the next sale
        offerAccepted = false;
        tokenAcceptedForClosing = address(0);
    }
}


/**
 * @title Minimalistic Factory contract to allow for centralized event detection.
 */
contract PropertyFactory is Ownable {
    //============================================================================
    // Event
    //============================================================================

    event PropertyCreated(
        address property,
        string streetAddress,
        string legalDescription,
        string documentationURI,
        address indexed owner,
        address indexed broker,
        address indexed agent,
        uint256 ownerRoyalties,
        uint256 brokerRoyalties,
        uint256 providerRoyalties
    );

    //============================================================================
    // State Variable
    //============================================================================

    address[] public allProperties;

    //============================================================================
    // Constructor
    //============================================================================

    constructor() Ownable() {}

    //============================================================================
    // Mutative Function
    //============================================================================

    function createProperty(
        string memory _streetAddress,
        string memory _legalDescription,
        string memory _documentationURI,
        address _propertyOwner,
        address _listingBroker,
        address _transferAgent,
        address _provider,
        uint256 _ownerRoyaltiesBps,
        uint256 _listingBrokerRoyaltiesBps,
        uint256 _providerRoyaltiesBps
    ) external onlyOwner {
        // This syntax is a newer way to invoke create2 without assembly, just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        address newProperty = address(
            new Property{ salt: keccak256(bytes(_streetAddress)) }(
                _streetAddress,
                _legalDescription,
                _documentationURI,
                _propertyOwner,
                _listingBroker,
                _transferAgent,
                _provider,
                _ownerRoyaltiesBps,
                _listingBrokerRoyaltiesBps,
                _providerRoyaltiesBps
            )
        );
        allProperties.push(newProperty);

        emit PropertyCreated(
            newProperty,
            _streetAddress,
            _legalDescription,
            _documentationURI,
            _propertyOwner,
            _listingBroker,
            _transferAgent,
            _ownerRoyaltiesBps,
            _listingBrokerRoyaltiesBps,
            _providerRoyaltiesBps
        );
    }

    //============================================================================
    // View Function
    //============================================================================

    function allPropertiesLength() external view returns (uint256) {
        return allProperties.length;
    }
}