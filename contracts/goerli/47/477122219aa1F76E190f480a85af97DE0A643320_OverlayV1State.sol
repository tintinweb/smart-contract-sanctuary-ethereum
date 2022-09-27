/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
// File: @overlay-protocol/v1-core/contracts/libraries/FixedCast.sol


pragma solidity 0.8.10;

library FixedCast {
    uint256 internal constant ONE_256 = 1e18; // 18 decimal places
    uint256 internal constant ONE_16 = 1e4; // 4 decimal places

    /// @dev casts a uint16 to a FixedPoint uint256 with 18 decimals
    function toUint256Fixed(uint16 value) internal pure returns (uint256) {
        uint256 multiplier = ONE_256 / ONE_16;
        return (uint256(value) * multiplier);
    }

    /// @dev casts a FixedPoint uint256 to a uint16 with 4 decimals
    function toUint16Fixed(uint256 value) internal pure returns (uint16) {
        uint256 divisor = ONE_256 / ONE_16;
        uint256 ret256 = value / divisor;
        require(ret256 <= type(uint16).max, "OVLV1: FixedCast out of bounds");
        return uint16(ret256);
    }
}

// File: @overlay-protocol/v1-core/contracts/libraries/uniswap/v3-core/FullMath.sol


pragma solidity ^0.8.0;

/// COPIED FROM:
/// https://github.com/Uniswap/v3-core/blob/0.8/contracts/libraries/FullMath.sol

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of
/// @notice an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division
/// @dev where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision.
    /// @notice Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision.
    /// @notice Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
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
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
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

// File: @overlay-protocol/v1-core/contracts/interfaces/IOverlayV1Deployer.sol


pragma solidity 0.8.10;

interface IOverlayV1Deployer {
    function factory() external view returns (address);

    function ovl() external view returns (address);

    function deploy(address feed) external returns (address);

    function parameters()
        external
        view
        returns (
            address ovl_,
            address feed_,
            address factory_
        );
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


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

// File: @openzeppelin/contracts/access/IAccessControlEnumerable.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @overlay-protocol/v1-core/contracts/interfaces/IOverlayV1Token.sol


pragma solidity 0.8.10;



bytes32 constant MINTER_ROLE = keccak256("MINTER");
bytes32 constant BURNER_ROLE = keccak256("BURNER");
bytes32 constant GOVERNOR_ROLE = keccak256("GOVERNOR");
bytes32 constant GUARDIAN_ROLE = keccak256("GUARDIAN");

interface IOverlayV1Token is IAccessControlEnumerable, IERC20 {
    // mint/burn
    function mint(address _recipient, uint256 _amount) external;

    function burn(uint256 _amount) external;
}

// File: @overlay-protocol/v1-core/contracts/utils/Errors.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.10;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(
            200,
            add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds)))
        )

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant UNAUTHORIZED_OPERATION = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// File: @overlay-protocol/v1-core/contracts/libraries/LogExpMath.sol


// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the “Software”), to deal in the
// Software without restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// COPIED AND MODIFIED FROM:
// @balancer-v2-monorepo/pkg/solidity-utils/contracts/math/LogExpMath.sol
// XXX for changes

// XXX: 0.8.10; unchecked functions
pragma solidity 0.8.10;


/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            _require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) *
                    y_int256 +
                    ((ln_36_x % ONE_18) * y_int256) /
                    ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            _require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
                Errors.PRODUCT_OUT_OF_BOUNDS
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        unchecked {
            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        unchecked {
            // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
            // upscaling.

            int256 logBase;
            if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
                logBase = _ln_36(base);
            } else {
                logBase = _ln(base) * ONE_18;
            }

            int256 logArg;
            if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
                logArg = _ln_36(arg);
            } else {
                logArg = _ln(arg) * ONE_18;
            }

            // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
            return (logArg * ONE_18) / logBase;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Errors.OUT_OF_BOUNDS);

        unchecked {
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }
}

// File: @overlay-protocol/v1-core/contracts/libraries/FixedPoint.sol


// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// COPIED AND MODIFIED FROM:
// @balancer-v2-monorepo/pkg/solidity-utils/contracts/math/FixedPoint.sol
// XXX for changes

// XXX: 0.8.10; removed requires for overflow checks
pragma solidity 0.8.10;


/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant TWO = 2 * ONE;
    uint256 internal constant FOUR = 4 * ONE;
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition
        uint256 c = a + b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition
        uint256 c = a - b;
        return c;
    }

    /// @notice a - b but floors to zero if a <= b
    /// XXX: subFloor implementation
    function subFloor(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a > b ? a - b : 0;
        return c;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.
            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.
            return ((aInflated - 1) / b) + 1;
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down.
     * The result is guaranteed to not be above the true value (that is,
     * the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple
        // to implement and occur often in 50/50 and 80/20 Weighted Pools
        // XXX: checks for y == 0, x == ONE, x == 0
        if (0 == y || x == ONE) {
            return ONE;
        } else if (x == 0) {
            return 0;
        } else if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulDown(x, x);
        } else if (y == FOUR) {
            uint256 square = mulDown(x, x);
            return mulDown(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            if (raw < maxError) {
                return 0;
            } else {
                return sub(raw, maxError);
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up.
     * The result is guaranteed to not be below the true value (that is,
     * the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple
        // to implement and occur often in 50/50 and 80/20 Weighted Pools
        // XXX: checks for y == 0, x == ONE, x == 0
        if (0 == y || x == ONE) {
            return ONE;
        } else if (x == 0) {
            return 0;
        } else if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulUp(x, x);
        } else if (y == FOUR) {
            uint256 square = mulUp(x, x);
            return mulUp(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            return add(raw, maxError);
        }
    }

    /**
     * @dev Returns e^x, assuming x is a fixed point number, rounding down.
     * The result is guaranteed to not be above the true value (that is,
     * the error function expected - actual is always positive).
     * XXX: expDown implementation
     */
    function expDown(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return ONE;
        }
        require(x < 2**255, "FixedPoint: x out of bounds");

        int256 x_int256 = int256(x);
        uint256 raw = uint256(LogExpMath.exp(x_int256));
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        if (raw < maxError) {
            return 0;
        } else {
            return sub(raw, maxError);
        }
    }

    /**
     * @dev Returns e^x, assuming x is a fixed point number, rounding up.
     * The result is guaranteed to not be below the true value (that is,
     * the error function expected - actual is always negative).
     * XXX: expUp implementation
     */
    function expUp(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return ONE;
        }
        require(x < 2**255, "FixedPoint: x out of bounds");

        int256 x_int256 = int256(x);
        uint256 raw = uint256(LogExpMath.exp(x_int256));
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        return add(raw, maxError);
    }

    /**
     * @dev Returns log_b(a), assuming a, b are fixed point numbers, rounding down.
     * The result is guaranteed to not be above the true value (that is,
     * the error function expected - actual is always positive).
     * XXX: logDown implementation
     */
    function logDown(uint256 a, uint256 b) internal pure returns (int256) {
        require(a > 0 && a < 2**255, "FixedPoint: a out of bounds");
        require(b > 0 && b < 2**255, "FixedPoint: b out of bounds");

        int256 arg = int256(a);
        int256 base = int256(b);
        int256 raw = LogExpMath.log(arg, base);

        // NOTE: see @openzeppelin/contracts/utils/math/SignedMath.sol#L37
        uint256 rawAbs;
        unchecked {
            rawAbs = uint256(raw >= 0 ? raw : -raw);
        }
        uint256 maxError = add(mulUp(rawAbs, MAX_POW_RELATIVE_ERROR), 1);
        return raw - int256(maxError);
    }

    /**
     * @dev Returns log_b(a), assuming a, b are fixed point numbers, rounding up.
     * The result is guaranteed to not be below the true value (that is,
     * the error function expected - actual is always negative).
     * XXX: logUp implementation
     */
    function logUp(uint256 a, uint256 b) internal pure returns (int256) {
        require(a > 0 && a < 2**255, "FixedPoint: a out of bounds");
        require(b > 0 && b < 2**255, "FixedPoint: b out of bounds");

        int256 arg = int256(a);
        int256 base = int256(b);
        int256 raw = LogExpMath.log(arg, base);

        // NOTE: see @openzeppelin/contracts/utils/math/SignedMath.sol#L37
        uint256 rawAbs;
        unchecked {
            rawAbs = uint256(raw >= 0 ? raw : -raw);
        }
        uint256 maxError = add(mulUp(rawAbs, MAX_POW_RELATIVE_ERROR), 1);
        return raw + int256(maxError);
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error,
     * as it strips this error and prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

// File: @overlay-protocol/v1-core/contracts/libraries/Cast.sol


pragma solidity 0.8.10;

library Cast {
    /// @dev casts an uint256 to an uint32 bounded by uint32 range of values
    /// @dev to avoid reverts and overflows
    function toUint32Bounded(uint256 value) internal pure returns (uint32) {
        uint32 value32 = (value <= type(uint32).max) ? uint32(value) : type(uint32).max;
        return value32;
    }

    /// @dev casts an int256 to an int192 bounded by int192 range of values
    /// @dev to avoid reverts and overflows
    function toInt192Bounded(int256 value) internal pure returns (int192) {
        int192 value192 = value < type(int192).min
            ? type(int192).min
            : (value > type(int192).max ? type(int192).max : int192(value));
        return value192;
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @overlay-protocol/v1-core/contracts/libraries/Tick.sol


pragma solidity 0.8.10;



library Tick {
    using FixedPoint for uint256;
    using SignedMath for int256;

    uint256 internal constant ONE = 1e18;
    uint256 internal constant PRICE_BASE = 1.0001e18;
    int256 internal constant MAX_TICK_256 = 120e22;
    int256 internal constant MIN_TICK_256 = -41e22;

    /// @notice Computes the tick associated with the given price
    /// @notice where price = 1.0001 ** tick
    /// @dev FixedPoint lib constraints on min/max natural exponent of
    /// @dev -41e18, 130e18 respectively, means min/max tick will be
    /// @dev -41e18/ln(1.0001), 130e18/ln(1.0001), respectively (w some buffer)
    function priceToTick(uint256 price) internal pure returns (int24) {
        int256 tick256 = price.logDown(PRICE_BASE);
        require(tick256 >= MIN_TICK_256 && tick256 <= MAX_TICK_256, "OVLV1: tick out of bounds");

        // tick256 is FixedPoint format with 18 decimals. Divide by ONE
        // then truncate to int24
        return int24(tick256 / int256(ONE));
    }

    /// @notice Computes the price associated with the given tick
    /// @notice where price = 1.0001 ** tick
    /// @dev FixedPoint lib constraints on min/max natural exponent of
    /// @dev -41e18, 130e18 respectively, means min/max tick will be
    /// @dev -41e18/ln(1.0001), 130e18/ln(1.0001), respectively (w some buffer)
    function tickToPrice(int24 tick) internal pure returns (uint256) {
        // tick needs to be converted to Fixed point format with 18 decimals
        // to use FixedPoint powUp
        int256 tick256 = int256(tick) * int256(ONE);
        require(tick256 >= MIN_TICK_256 && tick256 <= MAX_TICK_256, "OVLV1: tick out of bounds");

        uint256 pow = uint256(tick256.abs());
        return (tick256 >= 0 ? PRICE_BASE.powDown(pow) : ONE.divDown(PRICE_BASE.powUp(pow)));
    }
}

// File: @overlay-protocol/v1-core/contracts/libraries/Position.sol


pragma solidity 0.8.10;






library Position {
    using FixedCast for uint16;
    using FixedCast for uint256;
    using FixedPoint for uint256;

    uint256 internal constant ONE = 1e18;

    /// @dev immutables: notionalInitial, debtInitial, midTick, entryTick, isLong
    /// @dev mutables: liquidated, oiShares, fractionRemaining
    struct Info {
        uint96 notionalInitial; // initial notional = collateral * leverage
        uint96 debtInitial; // initial debt = notional - collateral
        int24 midTick; // midPrice = 1.0001 ** midTick at build
        int24 entryTick; // entryPrice = 1.0001 ** entryTick at build
        bool isLong; // whether long or short
        bool liquidated; // whether has been liquidated (mutable)
        uint240 oiShares; // current shares of aggregate open interest on side (mutable)
        uint16 fractionRemaining; // fraction of initial position remaining (mutable)
    }

    /*///////////////////////////////////////////////////////////////
                        POSITIONS MAPPING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieves a position from positions mapping
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        uint256 id
    ) internal view returns (Info memory position_) {
        position_ = self[keccak256(abi.encodePacked(owner, id))];
    }

    /// @notice Stores a position in positions mapping
    function set(
        mapping(bytes32 => Info) storage self,
        address owner,
        uint256 id,
        Info memory position
    ) internal {
        self[keccak256(abi.encodePacked(owner, id))] = position;
    }

    /*///////////////////////////////////////////////////////////////
                    POSITION CAST GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes the position's initial notional cast to uint256
    function _notionalInitial(Info memory self) private pure returns (uint256) {
        return uint256(self.notionalInitial);
    }

    /// @notice Computes the position's initial debt cast to uint256
    function _debtInitial(Info memory self) private pure returns (uint256) {
        return uint256(self.debtInitial);
    }

    /// @notice Computes the position's current shares of open interest
    /// @notice cast to uint256
    function _oiShares(Info memory self) private pure returns (uint256) {
        return uint256(self.oiShares);
    }

    /// @notice Computes the fraction remaining of the position cast to uint256
    function _fractionRemaining(Info memory self) private pure returns (uint256) {
        return self.fractionRemaining.toUint256Fixed();
    }

    /*///////////////////////////////////////////////////////////////
                     POSITION EXISTENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether the position exists
    /// @dev Is false if position has been liquidated or fraction remaining == 0
    function exists(Info memory self) internal pure returns (bool exists_) {
        return (!self.liquidated && self.fractionRemaining > 0);
    }

    /*///////////////////////////////////////////////////////////////
                 POSITION FRACTION REMAINING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the current fraction remaining of the initial position
    function getFractionRemaining(Info memory self) internal pure returns (uint256) {
        return _fractionRemaining(self);
    }

    /// @notice Computes an updated fraction remaining of the initial position
    /// @notice given fractionRemoved unwound/liquidated from remaining position
    function updatedFractionRemaining(Info memory self, uint256 fractionRemoved)
        internal
        pure
        returns (uint16)
    {
        require(fractionRemoved <= ONE, "OVLV1:fraction>max");
        uint256 fractionRemaining = _fractionRemaining(self).mulDown(ONE - fractionRemoved);
        return fractionRemaining.toUint16Fixed();
    }

    /*///////////////////////////////////////////////////////////////
                      POSITION PRICE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes the midPrice of the position at entry cast to uint256
    /// @dev Will be slightly different (tol of 1bps) vs actual
    /// @dev midPrice at build given tick resolution limited to 1bps
    /// @dev Only affects value() calc below and thus PnL slightly
    function midPriceAtEntry(Info memory self) internal pure returns (uint256 midPrice_) {
        midPrice_ = Tick.tickToPrice(self.midTick);
    }

    /// @notice Computes the entryPrice of the position cast to uint256
    /// @dev Will be slightly different (tol of 1bps) vs actual
    /// @dev entryPrice at build given tick resolution limited to 1bps
    /// @dev Only affects value() calc below and thus PnL slightly
    function entryPrice(Info memory self) internal pure returns (uint256 entryPrice_) {
        entryPrice_ = Tick.tickToPrice(self.entryTick);
    }

    /*///////////////////////////////////////////////////////////////
                         POSITION OI FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes the amount of shares of open interest to issue
    /// @notice a newly built position
    /// @dev use mulDiv
    function calcOiShares(
        uint256 oi,
        uint256 oiTotalOnSide,
        uint256 oiTotalSharesOnSide
    ) internal pure returns (uint256 oiShares_) {
        oiShares_ = (oiTotalOnSide == 0 || oiTotalSharesOnSide == 0)
            ? oi
            : FullMath.mulDiv(oi, oiTotalSharesOnSide, oiTotalOnSide);
    }

    /// @notice Computes the position's initial open interest cast to uint256
    /// @dev oiInitial = Q / midPriceAtEntry
    /// @dev Will be slightly different (tol of 1bps) vs actual oi at build
    /// @dev given midTick resolution limited to 1bps
    /// @dev Only affects value() calc below and thus PnL slightly
    function _oiInitial(Info memory self) private pure returns (uint256) {
        uint256 q = _notionalInitial(self);
        uint256 mid = midPriceAtEntry(self);
        return q.divDown(mid);
    }

    /*///////////////////////////////////////////////////////////////
                POSITION FRACTIONAL GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes the initial notional of position when built
    /// @notice accounting for amount of position remaining
    /// @dev use mulUp to avoid rounding leftovers on unwind
    function notionalInitial(Info memory self, uint256 fraction) internal pure returns (uint256) {
        uint256 fractionRemaining = _fractionRemaining(self);
        uint256 notionalForRemaining = _notionalInitial(self).mulUp(fractionRemaining);
        return notionalForRemaining.mulUp(fraction);
    }

    /// @notice Computes the initial open interest of position when built
    /// @notice accounting for amount of position remaining
    /// @dev use mulUp to avoid rounding leftovers on unwind
    function oiInitial(Info memory self, uint256 fraction) internal pure returns (uint256) {
        uint256 fractionRemaining = _fractionRemaining(self);
        uint256 oiInitialForRemaining = _oiInitial(self).mulUp(fractionRemaining);
        return oiInitialForRemaining.mulUp(fraction);
    }

    /// @notice Computes the current shares of open interest position holds
    /// @notice on pos.isLong side of the market
    /// @dev use mulDown to avoid giving excess shares to pos owner on unwind
    function oiSharesCurrent(Info memory self, uint256 fraction) internal pure returns (uint256) {
        uint256 oiSharesForRemaining = _oiShares(self);
        // WARNING: must mulDown to avoid giving excess oi shares
        return oiSharesForRemaining.mulDown(fraction);
    }

    /// @notice Computes the current debt position holds accounting
    /// @notice for amount of position remaining
    /// @dev use mulUp to avoid rounding leftovers on unwind
    function debtInitial(Info memory self, uint256 fraction) internal pure returns (uint256) {
        uint256 fractionRemaining = _fractionRemaining(self);
        uint256 debtForRemaining = _debtInitial(self).mulUp(fractionRemaining);
        return debtForRemaining.mulUp(fraction);
    }

    /// @notice Computes the current open interest of remaining position accounting for
    /// @notice potential funding payments between long/short sides
    /// @dev returns zero when oiShares = oiTotalOnSide = oiTotalSharesOnSide = 0 to avoid
    /// @dev div by zero errors
    /// @dev use mulDiv
    function oiCurrent(
        Info memory self,
        uint256 fraction,
        uint256 oiTotalOnSide,
        uint256 oiTotalSharesOnSide
    ) internal pure returns (uint256) {
        uint256 oiShares = oiSharesCurrent(self, fraction);
        if (oiShares == 0 || oiTotalOnSide == 0 || oiTotalSharesOnSide == 0) return 0;
        return FullMath.mulDiv(oiShares, oiTotalOnSide, oiTotalSharesOnSide);
    }

    /// @notice Computes the remaining position's cost cast to uint256
    function cost(Info memory self, uint256 fraction) internal pure returns (uint256) {
        uint256 posNotionalInitial = notionalInitial(self, fraction);
        uint256 posDebt = debtInitial(self, fraction);

        // should always be > 0 but use subFloor to be safe w reverts
        uint256 posCost = posNotionalInitial;
        posCost = posCost.subFloor(posDebt);
        return posCost;
    }

    /*///////////////////////////////////////////////////////////////
                        POSITION CALC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Computes the value of remaining position
    /// @dev Floors to zero, so won't properly compute if self is underwater
    function value(
        Info memory self,
        uint256 fraction,
        uint256 oiTotalOnSide,
        uint256 oiTotalSharesOnSide,
        uint256 currentPrice,
        uint256 capPayoff
    ) internal pure returns (uint256 val_) {
        uint256 posOiInitial = oiInitial(self, fraction);
        uint256 posNotionalInitial = notionalInitial(self, fraction);
        uint256 posDebt = debtInitial(self, fraction);

        uint256 posOiCurrent = oiCurrent(self, fraction, oiTotalOnSide, oiTotalSharesOnSide);
        uint256 posEntryPrice = entryPrice(self);

        // NOTE: PnL = +/- oiCurrent * [currentPrice - entryPrice]; ... (w/o capPayoff)
        // NOTE: fundingPayments = notionalInitial * ( oiCurrent / oiInitial - 1 )
        // NOTE: value = collateralInitial + PnL + fundingPayments
        // NOTE:       = notionalInitial - debt + PnL + fundingPayments
        if (self.isLong) {
            // val = notionalInitial * oiCurrent / oiInitial
            //       + oiCurrent * min[currentPrice, entryPrice * (1 + capPayoff)]
            //       - oiCurrent * entryPrice - debt
            val_ =
                posNotionalInitial.mulUp(posOiCurrent).divUp(posOiInitial) +
                Math.min(
                    posOiCurrent.mulUp(currentPrice),
                    posOiCurrent.mulUp(posEntryPrice).mulUp(ONE + capPayoff)
                );
            // floor to 0
            val_ = val_.subFloor(posDebt + posOiCurrent.mulUp(posEntryPrice));
        } else {
            // NOTE: capPayoff >= 1, so no need to include w short
            // val = notionalInitial * oiCurrent / oiInitial + oiCurrent * entryPrice
            //       - oiCurrent * currentPrice - debt
            val_ =
                posNotionalInitial.mulUp(posOiCurrent).divUp(posOiInitial) +
                posOiCurrent.mulUp(posEntryPrice);
            // floor to 0
            val_ = val_.subFloor(posDebt + posOiCurrent.mulUp(currentPrice));
        }
    }

    /// @notice Computes the current notional of remaining position including PnL
    /// @dev Floors to debt if value <= 0
    function notionalWithPnl(
        Info memory self,
        uint256 fraction,
        uint256 oiTotalOnSide,
        uint256 oiTotalSharesOnSide,
        uint256 currentPrice,
        uint256 capPayoff
    ) internal pure returns (uint256 notionalWithPnl_) {
        uint256 posValue = value(
            self,
            fraction,
            oiTotalOnSide,
            oiTotalSharesOnSide,
            currentPrice,
            capPayoff
        );
        uint256 posDebt = debtInitial(self, fraction);
        notionalWithPnl_ = posValue + posDebt;
    }

    /// @notice Computes the trading fees to be imposed on remaining position
    /// @notice for build/unwind
    function tradingFee(
        Info memory self,
        uint256 fraction,
        uint256 oiTotalOnSide,
        uint256 oiTotalSharesOnSide,
        uint256 currentPrice,
        uint256 capPayoff,
        uint256 tradingFeeRate
    ) internal pure returns (uint256 tradingFee_) {
        uint256 posNotional = notionalWithPnl(
            self,
            fraction,
            oiTotalOnSide,
            oiTotalSharesOnSide,
            currentPrice,
            capPayoff
        );
        tradingFee_ = posNotional.mulUp(tradingFeeRate);
    }

    /// @notice Whether a position can be liquidated
    /// @dev is true when value * (1 - liq fee rate) < maintenance margin
    /// @dev liq fees are reward given to liquidator
    function liquidatable(
        Info memory self,
        uint256 oiTotalOnSide,
        uint256 oiTotalSharesOnSide,
        uint256 currentPrice,
        uint256 capPayoff,
        uint256 maintenanceMarginFraction,
        uint256 liquidationFeeRate
    ) internal pure returns (bool can_) {
        uint256 fraction = ONE;
        uint256 posNotionalInitial = notionalInitial(self, fraction);

        if (self.liquidated || self.fractionRemaining == 0) {
            // already been liquidated or doesn't exist
            // latter covers edge case of val == 0 and MM + liq fee == 0
            return false;
        }

        uint256 val = value(
            self,
            fraction,
            oiTotalOnSide,
            oiTotalSharesOnSide,
            currentPrice,
            capPayoff
        );
        uint256 maintenanceMargin = posNotionalInitial.mulUp(maintenanceMarginFraction);
        uint256 liquidationFee = val.mulDown(liquidationFeeRate);
        can_ = val < maintenanceMargin + liquidationFee;
    }
}

// File: @overlay-protocol/v1-core/contracts/libraries/Roller.sol


pragma solidity 0.8.10;




library Roller {
    using Cast for uint256;
    using Cast for int256;
    using FixedPoint for uint256;
    using SignedMath for int256;

    struct Snapshot {
        uint32 timestamp; // time last snapshot was taken
        uint32 window; // window (length of time) over which will decay
        int192 accumulator; // accumulator value which will decay to zero over window
    }

    /// @dev returns the stored accumulator value as an int256
    function cumulative(Snapshot memory self) internal view returns (int256) {
        return int256(self.accumulator);
    }

    /// @dev adjusts accumulator value downward linearly over time.
    /// @dev accumulator should go to zero as one window passes
    function transform(
        Snapshot memory self,
        uint256 timestamp,
        uint256 window,
        int256 value
    ) internal view returns (Snapshot memory) {
        uint32 timestamp32 = uint32(timestamp); // truncated by compiler

        // int/uint256 values to use in calculations
        uint256 dt = timestamp32 >= self.timestamp
            ? uint256(timestamp32 - self.timestamp)
            : uint256(2**32) + uint256(timestamp32) - uint256(self.timestamp);
        uint256 snapWindow = uint256(self.window);
        int256 snapAccumulator = cumulative(self);

        if (dt >= snapWindow || snapWindow == 0) {
            // if one window has passed, prior value has decayed to zero
            return
                Snapshot({
                    timestamp: timestamp32,
                    window: window.toUint32Bounded(),
                    accumulator: value.toInt192Bounded()
                });
        }

        // otherwise, calculate fraction of value remaining given linear decay.
        // fraction of value to take off due to decay (linear drift toward zero)
        // is fraction of windowLast that has elapsed since timestampLast
        snapAccumulator = (snapAccumulator * int256(snapWindow - dt)) / int256(snapWindow);

        // add in the new value for accumulator now
        int256 accumulatorNow = snapAccumulator + value;
        if (accumulatorNow == 0) {
            // if accumulator now is zero, windowNow is simply window
            return
                Snapshot({
                    timestamp: timestamp32,
                    window: window.toUint32Bounded(),
                    accumulator: 0
                });
        }

        // recalculate windowNow_ for future decay as a value weighted average time
        // of time left in windowLast for accumulatorLast and window for value
        // vwat = (|accumulatorLastWithDecay| * (windowLast - dt) + |value| * window) /
        //        (|accumulatorLastWithDecay| + |value|)
        uint256 w1 = snapAccumulator.abs();
        uint256 w2 = value.abs();
        uint256 windowNow = (w1 * (snapWindow - dt) + w2 * window) / (w1 + w2);
        return
            Snapshot({
                timestamp: timestamp32,
                window: windowNow.toUint32Bounded(),
                accumulator: accumulatorNow.toInt192Bounded()
            });
    }
}

// File: @overlay-protocol/v1-core/contracts/libraries/Risk.sol


pragma solidity 0.8.10;

library Risk {
    enum Parameters {
        K, // funding constant
        Lmbda, // market impact constant
        Delta, // bid-ask static spread constant
        CapPayoff, // payoff cap
        CapNotional, // initial notional cap
        CapLeverage, // initial leverage cap
        CircuitBreakerWindow, // trailing window for circuit breaker
        CircuitBreakerMintTarget, // target worst case inflation rate over trailing window
        MaintenanceMarginFraction, // maintenance margin (mm) constant
        MaintenanceMarginBurnRate, // burn rate for mm constant
        LiquidationFeeRate, // liquidation fee charged on liquidate
        TradingFeeRate, // trading fee charged on build/unwind
        MinCollateral, // minimum ovl collateral to open position
        PriceDriftUpperLimit, // upper limit for feed price changes since last update
        AverageBlockTime // average block time of the respective chain
    }

    /// @notice Gets the value associated with the given parameter type
    function get(uint256[15] storage self, Parameters name) internal view returns (uint256) {
        return self[uint256(name)];
    }

    /// @notice Sets the value associated with the given parameter type
    function set(
        uint256[15] storage self,
        Parameters name,
        uint256 value
    ) internal {
        self[uint256(name)] = value;
    }
}

// File: @overlay-protocol/v1-core/contracts/interfaces/IOverlayV1Factory.sol


pragma solidity 0.8.10;




interface IOverlayV1Factory {
    // risk param bounds
    function PARAMS_MIN(uint256 idx) external view returns (uint256);

    function PARAMS_MAX(uint256 idx) external view returns (uint256);

    // immutables
    function ovl() external view returns (IOverlayV1Token);

    function deployer() external view returns (IOverlayV1Deployer);

    // global parameter
    function feeRecipient() external view returns (address);

    // registry of supported feed factories
    function isFeedFactory(address feedFactory) external view returns (bool);

    // registry of markets; for a given feed address, returns associated market
    function getMarket(address feed) external view returns (address market_);

    // registry of deployed markets by factory
    function isMarket(address market) external view returns (bool);

    // adding feed factory to allowed feed types
    function addFeedFactory(address feedFactory) external;

    // removing feed factory from allowed feed types
    function removeFeedFactory(address feedFactory) external;

    // deploy new market
    function deployMarket(
        address feedFactory,
        address feed,
        uint256[15] calldata params
    ) external returns (address market_);

    // per-market risk parameter setters
    function setRiskParam(
        address feed,
        Risk.Parameters name,
        uint256 value
    ) external;

    // fee repository setter
    function setFeeRecipient(address _feeRecipient) external;
}

// File: @overlay-protocol/v1-core/contracts/libraries/Oracle.sol


pragma solidity 0.8.10;

library Oracle {
    struct Data {
        uint256 timestamp;
        uint256 microWindow;
        uint256 macroWindow;
        uint256 priceOverMicroWindow; // p(now) averaged over micro
        uint256 priceOverMacroWindow; // p(now) averaged over macro
        uint256 priceOneMacroWindowAgo; // p(now - macro) avg over macro
        uint256 reserveOverMicroWindow; // r(now) in ovl averaged over micro
        bool hasReserve; // whether oracle has manipulable reserve pool
    }
}

// File: @overlay-protocol/v1-core/contracts/interfaces/feeds/IOverlayV1Feed.sol


pragma solidity 0.8.10;


interface IOverlayV1Feed {
    // immutables
    function feedFactory() external view returns (address);

    function microWindow() external view returns (uint256);

    function macroWindow() external view returns (uint256);

    // returns freshest possible data from oracle
    function latest() external view returns (Oracle.Data memory);
}

// File: @overlay-protocol/v1-core/contracts/interfaces/IOverlayV1Market.sol


pragma solidity 0.8.10;





interface IOverlayV1Market {
    // immutables
    function ovl() external view returns (IOverlayV1Token);

    function feed() external view returns (address);

    function factory() external view returns (address);

    // risk params
    function params(uint256 idx) external view returns (uint256);

    // oi related quantities
    function oiLong() external view returns (uint256);

    function oiShort() external view returns (uint256);

    function oiLongShares() external view returns (uint256);

    function oiShortShares() external view returns (uint256);

    // rollers
    function snapshotVolumeBid()
        external
        view
        returns (
            uint32 timestamp_,
            uint32 window_,
            int192 accumulator_
        );

    function snapshotVolumeAsk()
        external
        view
        returns (
            uint32 timestamp_,
            uint32 window_,
            int192 accumulator_
        );

    function snapshotMinted()
        external
        view
        returns (
            uint32 timestamp_,
            uint32 window_,
            int192 accumulator_
        );

    // positions
    function positions(bytes32 key)
        external
        view
        returns (
            uint96 notionalInitial_,
            uint96 debtInitial_,
            int24 midTick_,
            int24 entryTick_,
            bool isLong_,
            bool liquidated_,
            uint240 oiShares_,
            uint16 fractionRemaining_
        );

    // update related quantities
    function timestampUpdateLast() external view returns (uint256);

    // cached risk calcs
    function dpUpperLimit() external view returns (uint256);

    // emergency shutdown
    function isShutdown() external view returns (bool);

    // initializes market
    function initialize(uint256[15] memory params) external;

    // position altering functions
    function build(
        uint256 collateral,
        uint256 leverage,
        bool isLong,
        uint256 priceLimit
    ) external returns (uint256 positionId_);

    function unwind(
        uint256 positionId,
        uint256 fraction,
        uint256 priceLimit
    ) external;

    function liquidate(address owner, uint256 positionId) external;

    // updates market
    function update() external returns (Oracle.Data memory);

    // sanity check on data fetched from oracle in case of manipulation
    function dataIsValid(Oracle.Data memory) external view returns (bool);

    // current open interest after funding payments transferred
    function oiAfterFunding(
        uint256 oiOverweight,
        uint256 oiUnderweight,
        uint256 timeElapsed
    ) external view returns (uint256 oiOverweight_, uint256 oiUnderweight_);

    // current open interest cap with adjustments for circuit breaker if market has
    // printed a lot in recent past
    function capOiAdjustedForCircuitBreaker(uint256 cap) external view returns (uint256);

    // bound on open interest cap from circuit breaker
    function circuitBreaker(Roller.Snapshot memory snapshot, uint256 cap)
        external
        view
        returns (uint256);

    // current notional cap with adjustments to prevent front-running
    // trade and back-running trade
    function capNotionalAdjustedForBounds(Oracle.Data memory data, uint256 cap)
        external
        view
        returns (uint256);

    // bound on open interest cap to mitigate front-running attack
    function frontRunBound(Oracle.Data memory data) external view returns (uint256);

    // bound on open interest cap to mitigate back-running attack
    function backRunBound(Oracle.Data memory data) external view returns (uint256);

    // transforms notional into number of contracts (open interest)
    function oiFromNotional(uint256 notional, uint256 midPrice) external view returns (uint256);

    // bid price given oracle data and recent volume
    function bid(Oracle.Data memory data, uint256 volume) external view returns (uint256 bid_);

    // ask price given oracle data and recent volume
    function ask(Oracle.Data memory data, uint256 volume) external view returns (uint256 ask_);

    // risk parameter setter
    function setRiskParam(Risk.Parameters name, uint256 value) external;

    // emergency shutdown market
    function shutdown() external;

    // emergency withdraw collateral after shutdown
    function emergencyWithdraw(uint256 positionId) external;
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/interfaces/state/IOverlayV1BaseState.sol


pragma solidity 0.8.10;




interface IOverlayV1BaseState {
    // immutables
    function factory() external view returns (IOverlayV1Factory);

    // market associated with given feed
    function market(address feed) external view returns (IOverlayV1Market market_);

    // latest oracle data associated with given feed
    function data(address feed) external view returns (Oracle.Data memory data_);
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/state/OverlayV1BaseState.sol


pragma solidity 0.8.10;






abstract contract OverlayV1BaseState is IOverlayV1BaseState {
    // immutables
    IOverlayV1Factory public immutable factory;

    constructor(IOverlayV1Factory _factory) {
        factory = _factory;
    }

    /// @notice Gets the Overlay market address for the given feed
    /// @dev reverts if market doesn't exist
    function _getMarket(address feed) internal view returns (IOverlayV1Market market_) {
        address marketAddress = factory.getMarket(feed);
        require(marketAddress != address(0), "OVLV1:!market");
        market_ = IOverlayV1Market(marketAddress);
    }

    /// @notice Gets the oracle data from the given feed
    function _getOracleData(address feed) internal view returns (Oracle.Data memory data_) {
        data_ = IOverlayV1Feed(feed).latest();
    }

    /// @notice Gets the Overlay market address for the given feed
    /// @dev reverts if market doesn't exist
    function market(address feed) external view returns (IOverlayV1Market market_) {
        market_ = _getMarket(feed);
    }

    /// @notice Gets the oracle data from the given feed
    function data(address feed) external view returns (Oracle.Data memory data_) {
        data_ = _getOracleData(feed);
    }
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/interfaces/state/IOverlayV1PriceState.sol


pragma solidity 0.8.10;



interface IOverlayV1PriceState is IOverlayV1BaseState {
    // bid on the market given new volume from fractionOfCapOi
    function bid(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 bid_);

    // ask on the market given new volume from fractionOfCapOi
    function ask(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 ask_);

    // mid on the market
    function mid(IOverlayV1Market market) external view returns (uint256 mid_);

    // volume on the bid of the market given new volume from fractionOfCapOi
    function volumeBid(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 volumeBid_);

    // volume on the ask of the market given new volume from fractionOfCapOi
    function volumeAsk(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 volumeAsk_);

    // bid, ask, mid prices of the market
    function prices(IOverlayV1Market market)
        external
        view
        returns (
            uint256 bid_,
            uint256 ask_,
            uint256 mid_
        );

    // bid, ask volumes of the market
    function volumes(IOverlayV1Market market)
        external
        view
        returns (uint256 volumeBid_, uint256 volumeAsk_);
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/state/OverlayV1PriceState.sol


pragma solidity 0.8.10;







abstract contract OverlayV1PriceState is IOverlayV1PriceState, OverlayV1BaseState {
    using Roller for Roller.Snapshot;

    function _bid(
        IOverlayV1Market market,
        Oracle.Data memory data,
        uint256 fractionOfCapOi
    ) internal view returns (uint256 bid_) {
        // get the rolling volume on the bid
        uint256 volume = _volumeBid(market, data, fractionOfCapOi);

        // get the bid price for market
        bid_ = market.bid(data, volume);
    }

    function _ask(
        IOverlayV1Market market,
        Oracle.Data memory data,
        uint256 fractionOfCapOi
    ) internal view returns (uint256 ask_) {
        // get the rolling volume on the ask
        uint256 volume = _volumeAsk(market, data, fractionOfCapOi);

        // get the ask price for market
        ask_ = market.ask(data, volume);
    }

    function _mid(Oracle.Data memory data) internal view returns (uint256 mid_) {
        mid_ = Math.average(data.priceOverMicroWindow, data.priceOverMacroWindow);
    }

    function _volumeBid(
        IOverlayV1Market market,
        Oracle.Data memory data,
        uint256 fractionOfCapOi
    ) internal view returns (uint256 volume_) {
        // assemble the rolling volume snapshot
        (uint32 timestamp, uint32 window, int192 accumulator) = market.snapshotVolumeBid();
        Roller.Snapshot memory snapshot = Roller.Snapshot({
            timestamp: timestamp,
            window: window,
            accumulator: accumulator
        });
        int256 value = int256(fractionOfCapOi);

        // calculate the decay in rolling volume since last snapshot
        snapshot = snapshot.transform(block.timestamp, data.microWindow, value);
        volume_ = uint256(snapshot.cumulative());
    }

    function _volumeAsk(
        IOverlayV1Market market,
        Oracle.Data memory data,
        uint256 fractionOfCapOi
    ) internal view returns (uint256 volume_) {
        // assemble the rolling volume snapshot
        (uint32 timestamp, uint32 window, int192 accumulator) = market.snapshotVolumeAsk();
        Roller.Snapshot memory snapshot = Roller.Snapshot({
            timestamp: timestamp,
            window: window,
            accumulator: accumulator
        });
        int256 value = int256(fractionOfCapOi);

        // calculate the decay in rolling volume since last snapshot
        snapshot = snapshot.transform(block.timestamp, data.microWindow, value);
        volume_ = uint256(snapshot.cumulative());
    }

    /// @notice Gets the bid price trader will receive on the Overlay market
    /// @notice given fraction of cap on open interest trade represents
    /// @dev fractionOfCapOi (i.e. oi / capOi) is FixedPoint
    /// @return bid_ as the received bid price
    function bid(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 bid_)
    {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        bid_ = _bid(market, data, fractionOfCapOi);
    }

    /// @notice Gets the ask price trader will receive on the Overlay market
    /// @notice given fraction of cap on open interest trade represents
    /// @dev fractionOfCapOi (i.e. oi / capOi) is FixedPoint
    /// @return ask_ as the received ask price
    function ask(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 ask_)
    {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        ask_ = _ask(market, data, fractionOfCapOi);
    }

    /// @notice Gets the mid price from feed used for liquidations
    /// @notice on the Overlay market
    /// @return mid_ as the received mid price
    function mid(IOverlayV1Market market) external view returns (uint256 mid_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        mid_ = _mid(data);
    }

    /// @notice Gets the rolling volume on the bid after the trader places
    /// @notice trade on the Overlay market given fraction of cap on
    /// @notice open interest trade represents
    /// @dev fractionOfCapOi (i.e. oi / capOi) is FixedPoint
    /// @return volumeBid_ as the volume on the bid
    function volumeBid(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 volumeBid_)
    {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        volumeBid_ = _volumeBid(market, data, fractionOfCapOi);
    }

    /// @notice Gets the rolling volume on the ask after the trader places
    /// @notice trade on the Overlay market given fraction of cap on
    /// @notice open interest trade represents
    /// @dev fractionOfCapOi (i.e. oi / capOi) is FixedPoint
    /// @return volumeAsk_ as the volume on the ask
    function volumeAsk(IOverlayV1Market market, uint256 fractionOfCapOi)
        external
        view
        returns (uint256 volumeAsk_)
    {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        volumeAsk_ = _volumeAsk(market, data, fractionOfCapOi);
    }

    /// @notice Gets the current bid, ask, and mid price values on the
    /// @notice Overlay market accounting for recent volume
    /// @return bid_ as the current bid price
    /// @return ask_ as the current ask price
    /// @return mid_ as the current mid price from feed
    function prices(IOverlayV1Market market)
        external
        view
        returns (
            uint256 bid_,
            uint256 ask_,
            uint256 mid_
        )
    {
        // cache feed data
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);

        // use the bid, ask prices assuming zero oi being traded
        // for current prices
        bid_ = _bid(market, data, 0);
        ask_ = _ask(market, data, 0);

        // mid excludes volume (manipulation resistant)
        mid_ = _mid(data);
    }

    /// @notice Gets the current rolling volume on the bid and ask sides
    /// @notice of the Overlay market
    /// @return volumeBid_ as the current rolling volume on the bid
    /// @return volumeAsk_ as the current rolling volume on the ask
    function volumes(IOverlayV1Market market)
        external
        view
        returns (uint256 volumeBid_, uint256 volumeAsk_)
    {
        // cache feed data
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);

        // use the bid, ask rolling volumes assuming zero oi being traded
        // for current volumes
        volumeBid_ = _volumeBid(market, data, 0);
        volumeAsk_ = _volumeAsk(market, data, 0);
    }
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/interfaces/state/IOverlayV1OIState.sol


pragma solidity 0.8.10;




interface IOverlayV1OIState is IOverlayV1BaseState, IOverlayV1PriceState {
    // aggregate open interest values on market
    function ois(IOverlayV1Market market)
        external
        view
        returns (uint256 oiLong_, uint256 oiShort_);

    // cap on aggregate open interest on market
    function capOi(IOverlayV1Market market) external view returns (uint256 capOi_);

    // fraction of cap on aggregate open interest given oi amount
    function fractionOfCapOi(IOverlayV1Market market, uint256 oi)
        external
        view
        returns (uint256 fractionOfCapOi_);

    // funding rate on market
    function fundingRate(IOverlayV1Market market) external view returns (int256 fundingRate_);

    // circuit breaker level on market
    function circuitBreakerLevel(IOverlayV1Market market)
        external
        view
        returns (uint256 circuitBreakerLevel_);

    // rolling minted amount on market
    function minted(IOverlayV1Market market) external view returns (int256 minted_);
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/state/OverlayV1OIState.sol


pragma solidity 0.8.10;









abstract contract OverlayV1OIState is IOverlayV1OIState, OverlayV1BaseState, OverlayV1PriceState {
    using FixedPoint for uint256;
    using Roller for Roller.Snapshot;

    /// @notice Computes the number of contracts (open interest) for the given
    /// @notice amount of notional in OVL at the current mid from Oracle data
    /// @dev OI = Q / MP; where Q = notional, MP = mid price, OI = open interest
    /// @dev Q = N * L; where N = collateral, L = leverage
    function _oiFromNotional(Oracle.Data memory data, uint256 notional)
        internal
        view
        returns (uint256 oi_)
    {
        uint256 midPrice = _mid(data);
        require(midPrice > 0, "OVLV1:mid==0");
        oi_ = notional.divDown(midPrice);
    }

    function _ois(IOverlayV1Market market)
        internal
        view
        returns (uint256 oiLong_, uint256 oiShort_)
    {
        // oiLong/Short values before funding adjustments
        oiLong_ = market.oiLong();
        oiShort_ = market.oiShort();

        // time elapsed since funding last paid
        // if > 0, adjust for funding
        uint256 timeElapsed = block.timestamp - market.timestampUpdateLast();
        if (timeElapsed > 0) {
            // determine overweight vs underweight side
            bool isLongOverweight = oiLong_ > oiShort_;
            uint256 oiOverweight = isLongOverweight ? oiLong_ : oiShort_;
            uint256 oiUnderweight = isLongOverweight ? oiShort_ : oiLong_;

            // adjust for funding
            (oiOverweight, oiUnderweight) = market.oiAfterFunding(
                oiOverweight,
                oiUnderweight,
                timeElapsed
            );

            // values after funding adjustment
            oiLong_ = isLongOverweight ? oiOverweight : oiUnderweight;
            oiShort_ = isLongOverweight ? oiUnderweight : oiOverweight;
        }
    }

    function _capOi(IOverlayV1Market market, Oracle.Data memory data)
        internal
        view
        returns (uint256 capOi_)
    {
        // get cap notional from risk params
        uint256 capNotional = market.params(uint256(Risk.Parameters.CapNotional));

        // adjust for bounds on cap oi from front + back-running attacks
        capNotional = market.capNotionalAdjustedForBounds(data, capNotional);

        // convert to a cap on number of contracts (open interest)
        capOi_ = _oiFromNotional(data, capNotional);
    }

    /// @dev fractionOfCapOi = oi / capOi as FixedPoint
    /// @dev handles capOi == 0 edge case by returning type(uint256).max
    function _fractionOfCapOi(
        IOverlayV1Market market,
        Oracle.Data memory data,
        uint256 oi
    ) internal view returns (uint256) {
        // simply oi / capOi
        uint256 cap = _capOi(market, data);
        if (cap == 0) {
            // handle the edge case
            return type(uint256).max;
        }
        return oi.divDown(cap);
    }

    /// @dev f = 2 * k * ( oiLong - oiShort ) / (oiLong + oiShort)
    /// @dev such that long > short then positive
    function _fundingRate(IOverlayV1Market market) internal view returns (int256 fundingRate_) {
        (uint256 oiLong, uint256 oiShort) = _ois(market);

        // determine overweight vs underweight side
        bool isLongOverweight = oiLong > oiShort;
        uint256 oiOverweight = isLongOverweight ? oiLong : oiShort;
        uint256 oiUnderweight = isLongOverweight ? oiShort : oiLong;

        // determine total oi and imbalance in oi
        uint256 oiTotal = oiOverweight + oiUnderweight;
        uint256 oiImbalance = oiOverweight - oiUnderweight;
        if (oiTotal == 0 || oiImbalance == 0) {
            return int256(0);
        }

        // Get the k risk param for the market and then calculate funding rate
        uint256 k = market.params(uint256(Risk.Parameters.K));
        uint256 rate = oiImbalance.divDown(oiTotal).mulDown(2 * k);

        // return mag + sign for funding rate
        fundingRate_ = isLongOverweight ? int256(rate) : -int256(rate);
    }

    /// @dev circuit breaker level is reported as fraction of capOi in FixedPoint
    function _circuitBreakerLevel(IOverlayV1Market market)
        internal
        view
        returns (uint256 circuitBreakerLevel_)
    {
        // set cap to ONE as reporting level in terms of % of capOi
        // = market.capNotionalAdjustedForCircuitBreaker(cap) / cap
        circuitBreakerLevel_ = market.capOiAdjustedForCircuitBreaker(FixedPoint.ONE);
    }

    /// @notice Gets the current open interest values on the Overlay market
    /// @notice accounting for funding
    /// @return oiLong_ as the current open interest long
    /// @return oiShort_ as the current open interest short
    function ois(IOverlayV1Market market)
        external
        view
        returns (uint256 oiLong_, uint256 oiShort_)
    {
        (oiLong_, oiShort_) = _ois(market);
    }

    /// @notice Gets the current cap on open interest on the Overlay market
    /// @notice accounting for front and back-running bounds
    /// @return capOi_ as the current open interest cap
    function capOi(IOverlayV1Market market) external view returns (uint256 capOi_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        capOi_ = _capOi(market, data);
    }

    /// @notice Gets the fraction of the current open interest cap the
    /// @notice given oi contracts represents on the Overlay market
    /// @dev fractionOfCapOi = oi / capOi is FixedPoint
    /// @return fractionOfCapOi_ as fraction of open interest cap given oi is
    function fractionOfCapOi(IOverlayV1Market market, uint256 oi)
        external
        view
        returns (uint256 fractionOfCapOi_)
    {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        fractionOfCapOi_ = _fractionOfCapOi(market, data, oi);
    }

    /// @notice Gets the current funding rate on the Overlay market
    /// @dev f = 2 * k * ( oiLong - oiShort ) / (oiLong + oiShort)
    /// @dev such that long > short then positive
    /// @return fundingRate_ as the current funding rate
    function fundingRate(IOverlayV1Market market) external view returns (int256 fundingRate_) {
        fundingRate_ = _fundingRate(market);
    }

    /// @notice Gets the current level of the circuit breaker for the
    /// @notice open interest cap on the Overlay market
    /// @dev circuit breaker level is reported as fraction of capOi in FixedPoint
    /// @return circuitBreakerLevel_ as the current circuit breaker level
    function circuitBreakerLevel(IOverlayV1Market market)
        external
        view
        returns (uint256 circuitBreakerLevel_)
    {
        circuitBreakerLevel_ = _circuitBreakerLevel(market);
    }

    /// @notice Gets the current rolling amount minted (+) or burned (-)
    /// @notice by the Overlay market
    /// @dev minted_ > 0 means more OVL has been minted than burned recently
    /// @return minted_ as the current rolling amount minted
    function minted(IOverlayV1Market market) external view returns (int256 minted_) {
        // assemble the rolling amount minted snapshot
        (uint32 timestamp, uint32 window, int192 accumulator) = market.snapshotMinted();
        Roller.Snapshot memory snapshot = Roller.Snapshot({
            timestamp: timestamp,
            window: window,
            accumulator: accumulator
        });

        // Get the circuit breaker window risk param for the market
        // and set value to zero to prep for transform
        uint256 circuitBreakerWindow = market.params(
            uint256(Risk.Parameters.CircuitBreakerWindow)
        );
        int256 value = int256(0);

        // calculate the decay in rolling amount minted since last snapshot
        snapshot = snapshot.transform(block.timestamp, circuitBreakerWindow, value);
        minted_ = int256(snapshot.cumulative());
    }
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/interfaces/state/IOverlayV1EstimateState.sol


pragma solidity 0.8.10;






interface IOverlayV1EstimateState is IOverlayV1BaseState, IOverlayV1PriceState, IOverlayV1OIState {
    // estimated position to be built on the market
    function positionEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (Position.Info memory position_);

    // estimated debt of position on the market
    function debtEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 debt_);

    // estimated cost basis of position on the market
    function costEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 cost_);

    // estimated open interest of position on the market
    function oiEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 oi_);

    // estimated maintenance margin requirement for position on market
    function maintenanceMarginEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 maintenanceMargin_);

    // estimated liquidation price for position on market
    function liquidationPriceEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 liquidationPrice_);
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/state/OverlayV1EstimateState.sol


pragma solidity 0.8.10;











abstract contract OverlayV1EstimateState is
    IOverlayV1EstimateState,
    OverlayV1BaseState,
    OverlayV1PriceState,
    OverlayV1OIState
{
    using FixedCast for uint256;
    using FixedPoint for uint256;
    using Position for Position.Info;

    /// @notice Gets the position that would be built on the given market
    /// @notice for the given (collateral, leverage, isLong) attributes
    function _estimatePosition(
        IOverlayV1Market market,
        Oracle.Data memory data,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) internal view returns (Position.Info memory position_) {
        // notional, debt, oi
        uint256 notional = collateral.mulUp(leverage);
        uint256 debt = notional - collateral;
        uint256 oi = _oiFromNotional(data, notional);
        uint256 fractionOfCapOi = _fractionOfCapOi(market, data, oi);

        // get the attributes needed to calculate position oiShares:
        // oiLong/Short, oiLongShares/oiShortShares
        (uint256 oiLong, uint256 oiShort) = _ois(market);
        uint256 oiShares = Position.calcOiShares(
            oi,
            isLong ? oiLong : oiShort,
            isLong ? market.oiLongShares() : market.oiShortShares()
        );

        // prices
        uint256 midPrice = _mid(data);
        uint256 price = isLong
            ? _ask(market, data, fractionOfCapOi)
            : _bid(market, data, fractionOfCapOi);

        // TODO: test
        position_ = Position.Info({
            notionalInitial: uint96(notional),
            debtInitial: uint96(debt),
            midTick: Tick.priceToTick(midPrice),
            entryTick: Tick.priceToTick(price),
            isLong: isLong,
            liquidated: false,
            oiShares: uint240(oiShares),
            fractionRemaining: FixedPoint.ONE.toUint16Fixed()
        });
    }

    function _debtEstimate(Position.Info memory position) internal view returns (uint256 debt_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // debt estimate is simply initial debt of position
        debt_ = Position.debtInitial(position, fraction);
    }

    function _costEstimate(Position.Info memory position) internal view returns (uint256 cost_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // cost estimate is simply initial cost of position
        cost_ = position.cost(fraction);
    }

    function _oiEstimate(Position.Info memory position) internal view returns (uint256 oi_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // oi estimate is simply initial oi of position
        oi_ = position.oiInitial(fraction);
    }

    function _maintenanceMarginEstimate(IOverlayV1Market market, Position.Info memory position)
        internal
        view
        returns (uint256 maintenanceMargin_)
    {
        uint256 maintenanceMarginFraction = market.params(
            uint256(Risk.Parameters.MaintenanceMarginFraction)
        );
        uint256 q = Position.notionalInitial(position, FixedPoint.ONE);
        maintenanceMargin_ = q.mulUp(maintenanceMarginFraction);
    }

    function _liquidationPriceEstimate(IOverlayV1Market market, Position.Info memory position)
        internal
        view
        returns (uint256 liquidationPrice_)
    {
        // get position attributes independent of funding
        uint256 entryPrice = position.entryPrice();
        uint256 liquidationFeeRate = market.params(uint256(Risk.Parameters.LiquidationFeeRate));
        uint256 maintenanceMargin = _maintenanceMarginEstimate(market, position);

        // get position attributes
        // NOTE: cost is same as initial collateral
        uint256 oi = _oiEstimate(position);
        uint256 collateral = _costEstimate(position);
        require(oi > 0, "OVLV1: oi == 0");

        // get price delta from entry price: dp = | liqPrice - entryPrice |
        uint256 dp = collateral
            .subFloor(maintenanceMargin.divUp(FixedPoint.ONE - liquidationFeeRate))
            .divUp(oi);
        liquidationPrice_ = position.isLong ? entryPrice.subFloor(dp) : entryPrice + dp;
    }

    /// @notice Gets the estimated position to be built on the Overlay market
    /// @notice for the given (collateral, leverage, isLong) attributes
    function positionEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (Position.Info memory position_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        position_ = _estimatePosition(market, data, collateral, leverage, isLong);
    }

    /// @notice Gets the estimated debt of the position to be built
    /// @notice on the Overlay market for the given (collateral, leverage,
    /// @notice isLong) attributes
    function debtEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 debt_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _estimatePosition(
            market,
            data,
            collateral,
            leverage,
            isLong
        );
        debt_ = _debtEstimate(position);
    }

    /// @notice Gets the estimated cost of the position to be built
    /// @notice on the Overlay market for the given (collateral, leverage,
    /// @notice isLong) attributes
    function costEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 cost_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _estimatePosition(
            market,
            data,
            collateral,
            leverage,
            isLong
        );
        cost_ = _costEstimate(position);
    }

    /// @notice Gets the estimated open interest of the position to be built
    /// @notice on the Overlay market for the given (collateral, leverage,
    /// @notice isLong) attributes
    function oiEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 oi_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _estimatePosition(
            market,
            data,
            collateral,
            leverage,
            isLong
        );
        oi_ = _oiEstimate(position);
    }

    /// @notice Gets the estimated maintenance margin of the position to be built
    /// @notice on the Overlay market for the given (collateral, leverage, isLong)
    /// @notice attributes
    function maintenanceMarginEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 maintenanceMargin_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _estimatePosition(
            market,
            data,
            collateral,
            leverage,
            isLong
        );
        maintenanceMargin_ = _maintenanceMarginEstimate(market, position);
    }

    /// @notice Gets the estimated liquidation price of the position to be built
    /// @notice on the Overlay market for the given (collateral, leverage, isLong)
    /// @notice attributes
    function liquidationPriceEstimate(
        IOverlayV1Market market,
        uint256 collateral,
        uint256 leverage,
        bool isLong
    ) external view returns (uint256 liquidationPrice_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _estimatePosition(
            market,
            data,
            collateral,
            leverage,
            isLong
        );
        liquidationPrice_ = _liquidationPriceEstimate(market, position);
    }
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/interfaces/state/IOverlayV1PositionState.sol


pragma solidity 0.8.10;






interface IOverlayV1PositionState is IOverlayV1BaseState, IOverlayV1PriceState, IOverlayV1OIState {
    // position on the market
    function position(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (Position.Info memory position_);

    // debt of position on the market
    function debt(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 debt_);

    // cost basis of position on the market
    function cost(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 cost_);

    // open interest of position on the market
    function oi(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 oi_);

    // collateral backing position on the market
    function collateral(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 collateral_);

    // value of position on the market
    function value(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 value_);

    // notional of position on the market
    function notional(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 notional_);

    // trading fee charged to unwind position on the market
    function tradingFee(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 tradingFee_);

    // whether position is liquidatable on the market
    function liquidatable(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (bool liquidatable_);

    // liquidation fee rewarded to liquidator for position on market
    function liquidationFee(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 liquidationFee_);

    // maintenance margin requirement for position on market
    function maintenanceMargin(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 maintenanceMargin_);

    // remaining margin before liquidation for position on market
    function marginExcessBeforeLiquidation(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (int256 excess_);

    // liquidation price for position on market
    function liquidationPrice(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 liquidationPrice_);
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/state/OverlayV1PositionState.sol


pragma solidity 0.8.10;










abstract contract OverlayV1PositionState is
    IOverlayV1PositionState,
    OverlayV1BaseState,
    OverlayV1PriceState,
    OverlayV1OIState
{
    using FixedPoint for uint256;
    using Position for Position.Info;

    /// @notice Gets the position from the given market for the
    /// @notice position owner and position id
    function _getPosition(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) internal view returns (Position.Info memory position_) {
        bytes32 key = keccak256(abi.encodePacked(owner, id));
        (
            uint96 notionalInitial,
            uint96 debtInitial,
            int24 midTick,
            int24 entryTick,
            bool isLong,
            bool liquidated,
            uint240 oiShares,
            uint16 fractionRemaining
        ) = market.positions(key);

        // assemble the position info struct
        position_ = Position.Info({
            notionalInitial: notionalInitial,
            debtInitial: debtInitial,
            midTick: midTick,
            entryTick: entryTick,
            isLong: isLong,
            liquidated: liquidated,
            oiShares: oiShares,
            fractionRemaining: fractionRemaining
        });
    }

    /// @dev current debt owed by individual position
    function _debt(Position.Info memory position) internal view returns (uint256 debt_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // return the debt
        debt_ = Position.debtInitial(position, fraction);
    }

    /// @dev current cost basis of individual position
    function _cost(Position.Info memory position) internal view returns (uint256 cost_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // return the cost
        cost_ = position.cost(fraction);
    }

    /// @dev current oi occupied by individual position
    function _oi(IOverlayV1Market market, Position.Info memory position)
        internal
        view
        returns (uint256 oi_)
    {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // get the attributes needed to calculate position oi:
        // oiLong/Short, oiLongShares/oiShortShares
        (uint256 oiLong, uint256 oiShort) = _ois(market);

        // aggregate oi values on market
        uint256 oiTotalOnSide = position.isLong ? oiLong : oiShort;
        uint256 oiTotalSharesOnSide = position.isLong
            ? market.oiLongShares()
            : market.oiShortShares();

        // return the current oi
        oi_ = position.oiCurrent(fraction, oiTotalOnSide, oiTotalSharesOnSide);
    }

    /// @dev current collateral backing the individual position
    function _collateral(IOverlayV1Market market, Position.Info memory position)
        internal
        view
        returns (uint256 collateral_)
    {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // get attributes needed to calculate current collateral amount:
        // notionalInitial, debtInitial, oiInitial, oiCurrent
        uint256 q = Position.notionalInitial(position, fraction);
        uint256 d = Position.debtInitial(position, fraction);
        uint256 oiInitial = position.oiInitial(fraction);

        // calculate oiCurrent from aggregate oi values
        (uint256 oiLong, uint256 oiShort) = _ois(market);

        // aggregate oi values on market
        uint256 oiTotalOnSide = position.isLong ? oiLong : oiShort;
        uint256 oiTotalSharesOnSide = position.isLong
            ? market.oiLongShares()
            : market.oiShortShares();

        // position's current oi factoring in funding
        uint256 oiCurrent = position.oiCurrent(fraction, oiTotalOnSide, oiTotalSharesOnSide);

        // return the collateral
        collateral_ = q.mulUp(oiCurrent).divUp(oiInitial).subFloor(d);
    }

    /// @dev current value of the individual position
    function _value(
        IOverlayV1Market market,
        Oracle.Data memory data,
        Position.Info memory position
    ) internal view returns (uint256 value_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // get the attributes needed to calculate position value:
        // oiLong/Short, oiLongShares/oiShortShares, price, capPayoff
        (uint256 oiLong, uint256 oiShort) = _ois(market);

        // aggregate oi values on market
        uint256 oiTotalOnSide = position.isLong ? oiLong : oiShort;
        uint256 oiTotalSharesOnSide = position.isLong
            ? market.oiLongShares()
            : market.oiShortShares();

        // position's current oi factoring in funding
        uint256 oi = position.oiCurrent(fraction, oiTotalOnSide, oiTotalSharesOnSide);

        // current price is price position would receive if unwound
        // longs get the bid on unwind, shorts get the ask
        uint256 currentPrice = position.isLong
            ? _bid(market, data, _fractionOfCapOi(market, data, oi))
            : _ask(market, data, _fractionOfCapOi(market, data, oi));

        // get cap payoff from risk params
        uint256 capPayoff = market.params(uint256(Risk.Parameters.CapPayoff));

        // return current value
        value_ = position.value(
            fraction,
            oiTotalOnSide,
            oiTotalSharesOnSide,
            currentPrice,
            capPayoff
        );
    }

    /// @dev current notional (including PnL) of the individual position
    function _notional(
        IOverlayV1Market market,
        Oracle.Data memory data,
        Position.Info memory position
    ) internal view returns (uint256 notional_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // get the attributes needed to calculate position notional:
        // oiLong/Short, oiLongShares/oiShortShares, price, capPayoff
        (uint256 oiLong, uint256 oiShort) = _ois(market);

        // aggregate oi values on market
        uint256 oiTotalOnSide = position.isLong ? oiLong : oiShort;
        uint256 oiTotalSharesOnSide = position.isLong
            ? market.oiLongShares()
            : market.oiShortShares();

        // position's current oi factoring in funding
        uint256 oi = position.oiCurrent(fraction, oiTotalOnSide, oiTotalSharesOnSide);

        // current price is price position would receive if unwound
        // longs get the bid on unwind, shorts get the ask
        uint256 currentPrice = position.isLong
            ? _bid(market, data, _fractionOfCapOi(market, data, oi))
            : _ask(market, data, _fractionOfCapOi(market, data, oi));

        // get cap payoff from risk params
        uint256 capPayoff = market.params(uint256(Risk.Parameters.CapPayoff));

        // return current notional with PnL
        notional_ = position.notionalWithPnl(
            fraction,
            oiTotalOnSide,
            oiTotalSharesOnSide,
            currentPrice,
            capPayoff
        );
    }

    /// @dev current value of the individual position used on liquidations
    /// @dev currentPrice == midPrice on liquidations to be manipulation
    /// @dev resistant against price slippage manipulators
    /// @dev will always be greater than _value()
    function _valueForLiquidations(
        IOverlayV1Market market,
        Oracle.Data memory data,
        Position.Info memory position
    ) internal view returns (uint256 value_) {
        // assume entire position value such that fraction = ONE
        uint256 fraction = FixedPoint.ONE;

        // get the attributes needed to calculate position value:
        // oiLong/Short, oiLongShares/oiShortShares, price, capPayoff
        (uint256 oiLong, uint256 oiShort) = _ois(market);

        // aggregate oi values on market
        uint256 oiTotalOnSide = position.isLong ? oiLong : oiShort;
        uint256 oiTotalSharesOnSide = position.isLong
            ? market.oiLongShares()
            : market.oiShortShares();

        // position's current oi factoring in funding
        uint256 oi = position.oiCurrent(fraction, oiTotalOnSide, oiTotalSharesOnSide);

        // current price is the price position receives upon liquidation
        // which is the mid price (manipulation resistant)
        uint256 currentPrice = _mid(data);

        // get cap payoff from risk params
        uint256 capPayoff = market.params(uint256(Risk.Parameters.CapPayoff));

        // return current value
        value_ = position.value(
            fraction,
            oiTotalOnSide,
            oiTotalSharesOnSide,
            currentPrice,
            capPayoff
        );
    }

    /// @dev current liquidation state of an individual position
    function _liquidatable(
        IOverlayV1Market market,
        Oracle.Data memory data,
        Position.Info memory position
    ) internal view returns (bool liquidatable_) {
        // get the attributes needed to calculate position notional:
        // oiLong/Short, oiLongShares/oiShortShares, price, capPayoff
        (uint256 oiLong, uint256 oiShort) = _ois(market);

        // aggregate oi values on market
        uint256 oiTotalOnSide = position.isLong ? oiLong : oiShort;
        uint256 oiTotalSharesOnSide = position.isLong
            ? market.oiLongShares()
            : market.oiShortShares();

        // current price is the price position receives upon liquidation
        // which is the mid price (manipulation resistant)
        uint256 currentPrice = _mid(data);

        // get liquidation fee rate from risk params
        uint256 liquidationFeeRate = market.params(uint256(Risk.Parameters.LiquidationFeeRate));

        // get whether liquidatable
        liquidatable_ = position.liquidatable(
            oiTotalOnSide,
            oiTotalSharesOnSide,
            currentPrice,
            market.params(uint256(Risk.Parameters.CapPayoff)),
            market.params(uint256(Risk.Parameters.MaintenanceMarginFraction)),
            liquidationFeeRate
        );
    }

    /// @dev current liquidation fee rewarded to liquidator of position
    function _liquidationFee(
        IOverlayV1Market market,
        Oracle.Data memory data,
        Position.Info memory position
    ) internal view returns (uint256 liquidationFee_) {
        bool liquidatable = _liquidatable(market, data, position);
        if (liquidatable) {
            uint256 liquidationFeeRate = market.params(
                uint256(Risk.Parameters.LiquidationFeeRate)
            );
            uint256 value = _valueForLiquidations(market, data, position);
            liquidationFee_ = value.mulDown(liquidationFeeRate);
        }
    }

    /// @dev maintenance margin required to keep position open
    function _maintenanceMargin(IOverlayV1Market market, Position.Info memory position)
        internal
        view
        returns (uint256 maintenanceMargin_)
    {
        uint256 maintenanceMarginFraction = market.params(
            uint256(Risk.Parameters.MaintenanceMarginFraction)
        );
        uint256 q = Position.notionalInitial(position, FixedPoint.ONE);
        maintenanceMargin_ = q.mulUp(maintenanceMarginFraction);
    }

    /// @notice Gets the position from the Overlay market or the given
    /// @notice position owner and position id
    function position(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (Position.Info memory position_) {
        position_ = _getPosition(market, owner, id);
    }

    /// @notice Gets the current debt of the position on the Overlay
    /// @notice market for the given position owner, id
    /// @return debt_ as the current debt taken on by the position
    function debt(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 debt_) {
        Position.Info memory position = _getPosition(market, owner, id);
        debt_ = _debt(position);
    }

    /// @notice Gets the current cost of the position on the Overlay
    /// @notice market for the given position owner, id
    /// @return cost_ as the cost to build the position
    function cost(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 cost_) {
        Position.Info memory position = _getPosition(market, owner, id);
        cost_ = _cost(position);
    }

    /// @notice Gets the current open interest of the position on the Overlay
    /// @notice market for the given position owner, id
    /// @return oi_ as the current open interest occupied by the position
    function oi(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 oi_) {
        Position.Info memory position = _getPosition(market, owner, id);
        oi_ = _oi(market, position);
    }

    /// @notice Gets the current collateral backing the position on the
    /// @notice Overlay market for the given position owner, id
    /// @dev N(t) = Q * (OI(t) / OI(0)) - D; where Q = notional at build,
    /// @dev OI(t) = current open interest, OI(0) = open interest at build,
    /// @dev D = debt at build
    /// @return collateral_ as the current collateral backing the position
    function collateral(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 collateral_) {
        Position.Info memory position = _getPosition(market, owner, id);
        collateral_ = _collateral(market, position);
    }

    /// @notice Gets the current value of the position on the Overlay market
    /// @notice for the given position owner, id
    /// @return value_ as the current value of the position
    function value(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 value_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _getPosition(market, owner, id);
        value_ = _value(market, data, position);
    }

    /// @notice Gets the current notional of the position on the Overlay market
    /// @notice for the given position owner, id (accounts for PnL)
    /// @return notional_ as the current notional of the position
    function notional(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 notional_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _getPosition(market, owner, id);
        notional_ = _notional(market, data, position);
    }

    /// @notice Gets the trading fee charged to unwind the position on the
    /// @notice Overlay market for the given position owner, id
    /// @dev tradingFee = notional * tradingFeeRate
    /// @return tradingFee_ as the current trading fee charged
    function tradingFee(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 tradingFee_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _getPosition(market, owner, id);
        uint256 notional = _notional(market, data, position);

        // get the trading fee rate from risk params
        uint256 tradingFeeRate = market.params(uint256(Risk.Parameters.TradingFeeRate));
        tradingFee_ = notional.mulUp(tradingFeeRate);
    }

    /// @notice Gets whether the position is currently liquidatable on the Overlay
    /// @notice market for the given position owner, id
    /// @return liquidatable_ as whether the position is liquidatable
    function liquidatable(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (bool liquidatable_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _getPosition(market, owner, id);
        liquidatable_ = _liquidatable(market, data, position);
    }

    /// @notice Gets the liquidation fee rewarded to the liquidator if
    /// @notice position currently liquidatable on the Overlay market
    /// @notice for the given position owner, id
    /// @dev liquidationFee_ == 0 if not liquidatable
    /// @return liquidationFee_ as the current liquidation fee reward
    function liquidationFee(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 liquidationFee_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _getPosition(market, owner, id);
        liquidationFee_ = _liquidationFee(market, data, position);
    }

    /// @notice Gets the maintenance margin required to keep the position
    /// @notice open on the Overlay market for the given position owner, id
    /// @return maintenanceMargin_ as the maintenance margin
    function maintenanceMargin(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 maintenanceMargin_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _getPosition(market, owner, id);
        maintenanceMargin_ = _maintenanceMargin(market, position);
    }

    /// @notice Gets the current position remaining margin to eat through
    /// @notice before liquidation occurs on the Overlay market
    /// @notice for the given position owner, id
    /// @dev excess_ > 0: returns excess margin before liquidation
    /// @dev excess_ < 0, returns margin lost due to delayed liquidation
    /// @return excess_ as the current value less maintenance and liq fees
    function marginExcessBeforeLiquidation(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (int256 excess_) {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);
        Position.Info memory position = _getPosition(market, owner, id);

        // liquidation uses mid price
        uint256 value = _valueForLiquidations(market, data, position);
        uint256 maintenanceMargin = _maintenanceMargin(market, position);
        uint256 liquidationFee = _liquidationFee(market, data, position);
        excess_ = int256(value) - int256(maintenanceMargin) - int256(liquidationFee);
    }

    /// @notice Gets the current liquidation price of the position on the
    /// @notice Overlay market for the given position owner, id
    /// @return liquidationPrice_ as the current liquidation price
    function liquidationPrice(
        IOverlayV1Market market,
        address owner,
        uint256 id
    ) external view returns (uint256 liquidationPrice_) {
        address feed = market.feed();
        Position.Info memory position = _getPosition(market, owner, id);

        // get position attributes independent of funding
        uint256 entryPrice = position.entryPrice();
        uint256 liquidationFeeRate = market.params(uint256(Risk.Parameters.LiquidationFeeRate));
        uint256 maintenanceMargin = _maintenanceMargin(market, position);

        // get position attributes dependent on funding
        uint256 oi = _oi(market, position);
        uint256 collateral = _collateral(market, position);
        require(oi > 0, "OVLV1: oi == 0");

        // get price delta from entry price: dp = | liqPrice - entryPrice |
        uint256 dp = collateral
            .subFloor(maintenanceMargin.divUp(FixedPoint.ONE - liquidationFeeRate))
            .divUp(oi);
        liquidationPrice_ = position.isLong ? entryPrice.subFloor(dp) : entryPrice + dp;
    }
}

// File: https://github.com/overlay-market/v1-periphery/blob/main/contracts/interfaces/IOverlayV1State.sol


pragma solidity 0.8.10;






interface IOverlayV1State is
    IOverlayV1BaseState,
    IOverlayV1PriceState,
    IOverlayV1OIState,
    IOverlayV1PositionState
{
    struct MarketState {
        uint256 bid;
        uint256 ask;
        uint256 mid;
        uint256 volumeBid;
        uint256 volumeAsk;
        uint256 oiLong;
        uint256 oiShort;
        uint256 capOi;
        uint256 circuitBreakerLevel;
        int256 fundingRate;
    }

    function marketState(IOverlayV1Market market)
        external
        view
        returns (MarketState memory state_);
}

// File: github/overlay-market/v1-periphery/contracts/OverlayV1State.sol


pragma solidity 0.8.10;







/// @title A market state contract to view the current state of
/// @title an Overlay market
contract OverlayV1State is
    IOverlayV1State,
    OverlayV1BaseState,
    OverlayV1PriceState,
    OverlayV1OIState,
    OverlayV1EstimateState,
    OverlayV1PositionState
{
    constructor(IOverlayV1Factory _factory) OverlayV1BaseState(_factory) {}

    /// @notice Gets relevant market info to aggregate calls into a
    /// @notice single function
    /// @dev WARNING: makes many calls to market
    /// @return state_ as the current aggregate market state
    function marketState(IOverlayV1Market market)
        external
        view
        returns (MarketState memory state_)
    {
        address feed = market.feed();
        Oracle.Data memory data = _getOracleData(feed);

        (uint256 oiLong, uint256 oiShort) = _ois(market);
        state_ = MarketState({
            bid: _bid(market, data, 0),
            ask: _ask(market, data, 0),
            mid: _mid(data),
            volumeBid: _volumeBid(market, data, 0),
            volumeAsk: _volumeAsk(market, data, 0),
            oiLong: oiLong,
            oiShort: oiShort,
            capOi: _capOi(market, data),
            circuitBreakerLevel: _circuitBreakerLevel(market),
            fundingRate: _fundingRate(market)
        });
    }
}