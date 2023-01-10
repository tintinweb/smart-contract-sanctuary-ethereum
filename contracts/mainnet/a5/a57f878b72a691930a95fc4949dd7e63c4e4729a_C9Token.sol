/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
// File: Helpers.sol


pragma solidity >=0.8.17;

library Helpers {
    function addressToB32B8(address x)
        internal pure
        returns(bytes32 _a1, bytes8 _a2) {
            bytes memory _address = toAsciiString(x);
            assembly {
                _a1 := mload(add(_address, 32))
                _a2 := mload(add(_address, 64))
            }
    }

    function bpsToPercent(uint256 input)
        internal pure
        returns(bytes4) {
            bytes32 _input = uintToBytes(input);
            bytes memory tmp = "X.XX";
            bytes1 e0 = _input[0];
            bytes1 e1 = _input[1];
            bytes1 e2 = _input[2];
            assembly {
                let dst := add(tmp, 32)
                mstore(dst, or(and(mload(dst), not(shl(248, 0xFF))), e0))
                dst := add(tmp, 34)
                mstore(dst, or(and(mload(dst), not(shl(248, 0xFF))), e1))
                dst := add(tmp, 35)
                mstore(dst, or(and(mload(dst), not(shl(248, 0xFF))), e2))
            }
            return bytes4(tmp);
    }

    // https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function char(bytes1 b)
        internal pure
        returns (bytes1 c) {
            return (uint8(b) < 10) ? bytes1(uint8(b) + 0x30) : bytes1(uint8(b) + 0x57);
    }

    function concatTilSpace(bytes memory entry, uint256 offset)
        internal pure
        returns(bytes memory output) {
            bytes1 e0;
            for (uint256 j; j<entry.length; j++) {
                e0 = entry[j+offset];
                if (e0 == 0x20) { //space
                    break;
                }
                output = bytes.concat(output, e0);
            }
    }

    function flipSpace(bytes memory input, uint256 o0)
        internal pure {
            uint256 o1 = 1+o0;
            if (input[o1] == 0x00) {
                input[o1] = input[o0];
                input[o0] = 0x20;
            }
    }

    function flip2Space(bytes2 input)
        internal pure
        returns (bytes2) {
            bytes memory output = new bytes(2);
            if (input[1] == 0x20) {
                output[0] = input[1];
                output[1] = input[0];
            }
            else {
                output[0] = input[0];
                output[1] = input[1];
            }
            return bytes2(output);
    }

    function flip4Space(bytes4 input)
        internal pure
        returns (bytes4) {
            bytes memory output = new bytes(4);
            for (uint256 i; i<4; i++) {
                if (input[i] == 0x00) {
                    output[i] = 0x20;
                }
                else {
                    output[i] = input[i];
                }
            }
            return bytes4(output);
    }

    function remove2Null(bytes2 input)
        internal pure
        returns (bytes2) {
            bytes memory output = new bytes(2);
            for (uint256 i; i<2; i++) {
                if (input[i] == 0x00) {
                    output[i] = 0x20;
                }
                else {
                    output[i] = input[i];
                }
            }
            return bytes2(output);
    }

    function stringEqual(string memory _a, string memory _b)
        internal pure
        returns (bool) {
            return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }

    // https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function toAsciiString(address x)
        internal pure
        returns (bytes memory) {
            bytes memory s = new bytes(40);
            for (uint256 i; i < 20; i++) {
                bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
                bytes1 hi = bytes1(uint8(b) / 16);
                bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
                s[2*i] = char(hi);
                s[2*i+1] = char(lo);            
            }
            return s;
    }

    function tokenIdToBytes(uint256 _id)
        internal pure
        returns (bytes6) {
            bytes memory output = new bytes(6);
            output[0] = bytes1("0");
            bytes32 _bid = uintToBytes(_id);
            uint256 _offset = _bid[5] == 0x00 ? 1 : 0;
            for (uint256 j=0; j<6-_offset; j++) {
                output[j+_offset] = _bid[j];
            }
            return bytes6(output);
    }

    function uintToBool(uint256 v)
        internal pure
        returns(bool) {
            return v == 1 ? true : false;
    }

    // https://ethereum.stackexchange.com/questions/6591/conversion-of-uint-to-string
    function uintToBytes(uint256 v)
        internal pure
        returns (bytes32 ret) {
            if (v == 0) {
                ret = '0';
            }
            else {
                while (v > 0) {
                    ret = bytes32(uint256(ret) / (2 ** 8));
                    ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                    v /= 10;
                }
            }
            return ret;
    }

    function uintToOrdinal(uint256 _input)
        internal pure
        returns (bytes3) {
            if (_input == 0) {
                return "PRE";
            }
            if (_input == 254) {
                return "TYR";
            }
            if (_input == 255) {
                return "PAX";
            }
            bytes32[4] memory ends = [bytes32("TH"), "ST", "ND", "RD"];
            if(((_input % 100) >= 11) && ((_input % 100) <= 13)) {
                return bytes3(
                    bytes.concat(
                        bytes1(uintToBytes(_input)),
                        "TH"
                    )
                );
            }
            else {
                return bytes3(
                    bytes.concat(
                        bytes1(uintToBytes(_input)),
                        bytes2(ends[_input % 10])
                    )
                );
            }
    }
}
// File: C9Errors.sol


pragma solidity >=0.8.17;

// C9ERC721
error ApproveToCaller(); //0xb06307db
error BatchSizeTooLarge(uint256 maxSize, uint256 received); //0x01df19f6
error CallerNotOwnerOrApproved(); //0x8c11f105
error InvalidToken(uint256 tokenId); //0x925d6b18
error NonERC721Receiver(); //0x80526d0c
error OwnerAlreadyApproved(); //0x08fb3828
error OwnerIndexOOB(uint256 maxIndex, uint256 received); //0xc643a750
error TokenAlreadyMinted(uint256 tokenId); //0x8b474e54
error TokenEnumIndexOOB(uint256 maxIndex, uint256 received); //0x25601f6d
error TransferFromToSame(); //0x2f2bdfd9
error TransferFromIncorrectOwner(address expected, address received); //0xc0eeaa61
error TransferSizeMismatch(uint256 addressBookSize, uint256 batchSize);
error ZeroAddressInvalid(); //0x14c880ca

// C9OwnerControl
error ActionNotConfirmed(); //0xacdb9fab
error BoolAlreadySet(); //0xf04e4fd9
error ContractFrozen(); //0x4051e961
error NoRoleOnAccount(); //0xb1a60829
error NoTransferPending(); //0x9c6b0866
error C9Unauthorized(); //0xa020ddad
error C9ZeroAddressInvalid(); //0x7c7fa4fb

// Market contract
error InputSizeMismatch(uint256 tokenIdSize, uint256 listingPriceSize, uint256 sigSize);
error InvalidSigner(address expected, address received);

// Redeemer
error AddressToFarInProcess(uint256 minStep, uint256 received); //0xb078ecc8
error CancelRemainder(uint256 remainingBatch); //0x2c9f7f1d
error RedeemerBatchSizeTooLarge(uint256 maxSize, uint256 received);
error SizeMismatch(uint256 maxSize, uint256 received); //0x97ce59d2

// Registrar
error AddressAlreadyRegistered(); //0x2d42c772
error AddressNotInProcess(); //0x286d0071
error CodeMismatch(); //0x179708c0
error WrongProcessStep(uint256 expected, uint256 received); //0x58f6fd94

// Price Feed
error InvalidPaymentAmount(uint256 expected, uint256 received); //0x05dbe7d3
error PaymentFailure(); //0x29292fa2
error PriceFeedDated(uint256 maxDelay, uint256 received); //0xb8875fad

// Token
error AddressAlreadySet(); //0xf62c2d82
error CallerNotContract(); //0xa85366a7
error EditionOverflow(uint256 received); //0x5723b5d1
error IncorrectTokenValidity(uint256 expected, uint256 received); //0xe8c07318
error Input2SizeMismatch(uint256 inputSize1, uint256 inputSize2);
error InvalidVId(uint256 received); //0xcf8cffb0
error NoOwnerSupply(address sender); //0x973d81af
error PeriodTooLong(uint256 maxPeriod, uint256 received); //0xd36b55de
error RoyaltiesAlreadySet(); //0xe258016d
error RoyaltyTooHigh(); //0xc2b03beb
error ValueAlreadySet(); //0x30a4fcdc
error URIAlreadySet(); //0x82ccdaca
error URIMissingEndSlash(); //0x21edfe88
error TokenAlreadyUpgraded(uint256 tokenId); //0xb4aab4a3
error TokenIsDead(uint256 tokenId); //0xf87e5785
error TokenIsLocked(uint256 tokenId); //0xdc8fb341
error TokenNotLocked(uint256 tokenId); //0x5ef77436
error TokenNotUpgraded(uint256 tokenId); //0x14388074
error TokenPreRedeemable(uint256 tokenId); //0x04df46e6
error Unauthorized(); //0x82b42900
error ZeroEdition(); //0x2c0dcd39
error ZeroMintId(); //0x1ed046c6
error ZeroValue(); //0x7c946ed7
error ZeroTokenId(); //0x1fed7fc5

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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: Base64.sol


pragma solidity >=0.8.17;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
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

// File: C9OwnerControl.sol


pragma solidity >=0.8.17;



/**
* This contract is meant to act as a combination of 
* AccessControl and Ownable (2 step).
*
* onlyRole(DEFAULT_ADMIN_ROLE) is the equivalent of 
* onlyOwner in Ownable. Though note that since it possible 
* to grant more users DEFAULT_ADMIN_ROLE, it is recommended 
* that when giving others access, one one create a lower 
* level of access below the ADMIN i.e, MOD_ROLE.

* The admin renouncing role is the equivalent of 
* renouncing ownership in Ownable.
*
* The admin transferring ownership is the equivalent of 
* 2 step transfer in Ownable. The address accepting ownership 
* is made owner and granted DEFAULT_ADMIN_ROLE.
*
* NOTE: If multiple addresses are granted DEFAULT_ADMIN_ROLE, 
* they cannot revoke owner. Only owner can renounce itself.
*/

abstract contract C9OwnerControl is AccessControl {
    address public owner;
    address public pendingOwner;
    bool _frozen = false;

    event OwnershipTransferCancel(
        address indexed previousOwner
    );
    event OwnershipTransferComplete(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferInit(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    modifier notFrozen() { 
        if (_frozen) {
            revert ContractFrozen();
        }
        _;
    }

    /**
     * @dev It will not be possible to call `onlyRole(DEFAULT_ADMIN_ROLE)` 
     * functions anymore, unless there are other accounts with that role.
     *
     * NOTE: If the renouncer is the original contract owner, the contract 
     * is left without an owner.
     */
    function renounceRole(bytes32 role, address account)
        public override {
            if (account != msg.sender) revert C9Unauthorized();
            if (!hasRole(role, account)) revert NoRoleOnAccount();
            _revokeRole(role, account);
    }

    /**
     * @dev Override that makes it impossible for other admins 
     * to revoke the admin rights of the original contract deployer.
     * As a result admin also cannot revoke itself either.
     * But it can still renounce.
     */
    function revokeRole(bytes32 role, address account)
        public override
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (account == owner) revert C9Unauthorized();
            if (!hasRole(role, account)) revert NoRoleOnAccount();
            _revokeRole(role, account);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction. This is meant to make AccessControl 
     * functionally equivalent to 2-step Ownable.
     */
    function _transferOwnership(address _newOwner)
        private {
            delete pendingOwner;
            address _oldOwner = owner;
            owner = _newOwner;
            _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
            _revokeRole(DEFAULT_ADMIN_ROLE, _oldOwner);
            emit OwnershipTransferComplete(_oldOwner, _newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner. This is meant to make AccessControl 
     * functionally equivalent to Ownable.
     */
    function transferOwnership(address _newOwner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        notFrozen() {
            if (_newOwner == address(0)) revert C9ZeroAddressInvalid();
            pendingOwner = _newOwner;
            emit OwnershipTransferInit(owner, _newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer. The original owner will
     * still need to renounceRole DEFAULT_ADMIN_ROLE to fully complete 
     * this process, unless original owner wishes to remain in that role.
     */
    function acceptOwnership()
        external
        notFrozen() {
            if (pendingOwner != msg.sender) revert C9Unauthorized();
            if (pendingOwner == address(0)) revert NoTransferPending();
            _transferOwnership(msg.sender);
    }

    /**
     * @dev Cancels a transfer initiated. Although it may make sense to let
     * pending owner do this as well, we're keeping it ADMIN only.
     */
    function cancelTransferOwnership()
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (pendingOwner == address(0)) revert NoTransferPending();
            delete pendingOwner;
            emit OwnershipTransferCancel(owner);
    }

    /**
     * @dev Flag that sets global toggle to freeze redemption. 
     * Users may still cancel redemption and unlock their 
     * token if in the process.
     */
    function toggleFreeze(bool _toggle)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (_frozen == _toggle) {
                revert BoolAlreadySet();
            }
            _frozen = _toggle;
    }

    function __destroy(address _receiver, bool confirm)
        public virtual
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (!confirm) {
                revert ActionNotConfirmed();
            }
    		selfdestruct(payable(_receiver));
        }
}
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: IC9ERC721.sol


pragma solidity >=0.8.17;




interface IC9ERC721 is IERC721, IERC721Enumerable, IERC721Metadata {
    function clearApproved(uint256 tokenId) external;
    function getTokenParamsERC(uint256 _tokenId) external view returns(uint256[4] memory params);
    function safeTransferFrom(address from, address to, uint256[] calldata tokenId) external;
    function safeTransferFrom(address from, address[] calldata to, uint256[] calldata tokenId) external;
    function setReservedERC(uint256[2][] calldata _data) external;
    function transferFrom(address from, address to, uint256[] calldata tokenId) external;
}
// File: C9ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)
pragma solidity >=0.8.17;









/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IC9ERC721, C9OwnerControl {
    using Address for address;
    using Strings for uint256;

    uint256 constant EPOS_OWNER = 0;
    uint256 constant EPOS_OWNED_IDX = 160;
    uint256 constant EPOS_ALL_IDX = 184;
    uint256 constant EPOS_TRANSFER_COUNTER = 208;
    uint256 constant EPOS_RESERVED = 232;
    uint256 constant MAX_TRANSFER_BATCH_SIZE = 64;

    bytes32 public constant RESERVED_ROLE = keccak256("RESERVED_ROLE");

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    /* @dev
     * Collect9: optimized to be packed into a single uint256. There is a little 
     * overhead in packing and unpacking, but overall a good chunk of gas is saved 
     * on both minting and transfers as storage space is reduced to 1/3 the original 
     * by packing these./
     */
    mapping(uint256 => uint256) private _owners; // _owner(address), _ownedTokensIndex (u24), _allTokensIndex (u24), _transferCount(u24), _reserved (u24)

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /* @dev Collect9:
     * Copied from ERC721Enumerable
     */
    // Mapping from owner to list of owned token IDs
    /* This could theoretically be lowered to uint16 and store the index within _allTokens
     * but would come at the cost of extra read operations in transfer.
     */
    mapping(address => uint32[]) private _ownedTokens;

    // Array with all token ids, used for enumeration
    uint32[] private _allTokens;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _setTokenParam(uint256 _packedToken, uint256 _pos, uint256 _val, uint256 _mask)
        internal pure virtual
        returns(uint256) {
            _packedToken &= ~(_mask<<_pos); //zero out only its portion
            _packedToken |= _val<<_pos; //write value back in
            return _packedToken;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) {
            revert ZeroAddressInvalid();
        }
        return _ownedTokens[owner].length;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert InvalidToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * @dev Collect9: copied from ERC721Enumerable
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        uint256 _length = _ownedTokens[owner].length;
        if (index >= _length) {
            revert OwnerIndexOOB(_length, index);
        }
        return uint256(_ownedTokens[owner][index]);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     * @dev Collect9: copied from ERC721Enumerable
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * @dev Collect9: copied from ERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (index >= _totalSupply) {
            revert TokenEnumIndexOOB(_totalSupply, index);
        }
        return uint256(_allTokens[index]);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenIndex uint256 ID index the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenIndex) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex =  _ownedTokens[from].length - 1;

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = uint32(lastTokenId); // Move the last token to the slot of the to-delete token
            _owners[lastTokenId] = _setTokenParam(
                _owners[lastTokenId],
                EPOS_OWNED_IDX,
                tokenIndex,
                type(uint24).max
            );
        }

        // Deletes the contents at the last position of the array
        _ownedTokens[from].pop();
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenIndex index of token to remove
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenIndex) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = _allTokens.length - 1;

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = uint32(lastTokenId); // Move the last token to the slot of the to-delete token

        // Update the moved token's index
        _owners[lastTokenId] = _setTokenParam(
            _owners[lastTokenId],
            EPOS_ALL_IDX,
            tokenIndex,
            type(uint24).max
        );

        // This also deletes the contents at the last position of the array
        _allTokens.pop();
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        if (to == owner) {
            revert OwnerAlreadyApproved();
        }
        if (_msgSender() != owner) {
            if (!isApprovedForAll(owner, _msgSender())) {
                revert CallerNotOwnerOrApproved();
            }
        }
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Should be possible to clear this without having to transfer.
     */
    function clearApproved(uint256 tokenId) external {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert CallerNotOwnerOrApproved();
        }
        delete _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert NonERC721Receiver();
        }
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return address(uint160(_owners[tokenId]));
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert NonERC721Receiver();
        }
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        if (_exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }
        // Transfer
        _xfer(address(0), to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        uint256 _tokenData = _owners[tokenId];

        // Remove from enumerations
        _removeTokenFromOwnerEnumeration(
            owner,
            uint256(uint24(_tokenData>>EPOS_OWNED_IDX))
        );
        _removeTokenFromAllTokensEnumeration(
            uint256(uint24(_tokenData>>EPOS_ALL_IDX))
        );

        // Clear approvals
        // Tiny gas savings when most users won't have a single token set
        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }

        // Clear tokenID data
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _xfer(address from, address to, uint256 tokenId)
        private {

        uint256 _tokenData = _owners[tokenId];

        uint256 length;
        // If coming from minter
        if (from == address(0)) {
            length = _allTokens.length;
            _allTokens.push(uint32(tokenId));
            _tokenData = _setTokenParam(
                _tokenData,
                EPOS_ALL_IDX,
                length,
                type(uint24).max
            );
        } else {
            // Else coming from prior owner
            uint256 _tokenIndex = uint256(uint24(_tokenData>>EPOS_OWNED_IDX));
            _removeTokenFromOwnerEnumeration(
                from,
                _tokenIndex
            );

            /*
            Transfer counter can be stored for about ~600 more gas.
             */
            uint256 _xferCounter = uint256(uint24(_tokenData>>EPOS_TRANSFER_COUNTER));
            unchecked {++_xferCounter;}
            _tokenData = _setTokenParam(
                _tokenData,
                EPOS_TRANSFER_COUNTER,
                _xferCounter,
                type(uint24).max
            );
        }

        // Set owned token index
        length = _ownedTokens[to].length; //ERC721.balanceOf(to);
        _ownedTokens[to].push(uint32(tokenId));
        _tokenData = _setTokenParam(
            _tokenData,
            EPOS_OWNED_IDX,
            length,
            type(uint24).max
        );

        // Set new owner
        _tokenData = _setTokenParam(
            _tokenData,
            EPOS_OWNER,
            uint256(uint160(to)),
            type(uint160).max
        );

        // Write back to storage
        _owners[tokenId] = _tokenData;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        address _owner = ownerOf(tokenId);
        if (_owner != from) {
            revert TransferFromIncorrectOwner(_owner, from);
        }
        if (_msgSender() != _owner) {
            if (!isApprovedForAll(_owner, _msgSender())) {
                revert CallerNotOwnerOrApproved();
            }
        }
        if (to == address(0)) {
            revert ZeroAddressInvalid();
        }
        if (to == from) {
            revert TransferFromToSame();
        }
        
        _beforeTokenTransfer(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        // Saves about ~100 gas when not set (most cases)
        if (_tokenApprovals[tokenId] != address(0)) {
            delete _tokenApprovals[tokenId];
        }

        // Transfer
        _xfer(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (operator == owner) {
            revert ApproveToCaller();
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) {
            revert InvalidToken(tokenId);
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NonERC721Receiver();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Collect9 - custom batch functions
     */
    function _transferBatch(address from, address to, uint256[] calldata _tokenId)
        private {
            uint256 _batchSize = _tokenId.length;
            if (_batchSize > MAX_TRANSFER_BATCH_SIZE) {
                revert BatchSizeTooLarge(MAX_TRANSFER_BATCH_SIZE, _batchSize);
            }
            for (uint256 i; i<_batchSize;) {
                transferFrom(from, to, _tokenId[i]);
                unchecked {++i;}
            }
    }

    /**
     * @dev Allows safe batch transfer to make is cheaper to move multiple NFTs 
     * between two addresses. Max batch size is 64.
     */
    function safeTransferFrom(address from, address to, uint256[] calldata tokenId)
        external {
            _transferBatch(from, to, tokenId);
            // Only need to check one time
            if (!_checkOnERC721Received(from, to, tokenId[0], "")) {
                revert NonERC721Receiver();
            }
    }

    /**
     * @dev Allows batch transfer to many addresses at once. This will save
     * around ~20-25% gas with 4 or more addresses sent to at once. This only has a 
     * safe transfer version to prevent accidents of sending to a 
     * non-ERC721 receiver.
     */
    function safeTransferFrom(address from, address[] calldata to, uint256[] calldata tokenId)
        external {
            uint256 _batchSize = tokenId.length;
            if (_batchSize > MAX_TRANSFER_BATCH_SIZE) {
                revert BatchSizeTooLarge(MAX_TRANSFER_BATCH_SIZE, _batchSize);
            }
            uint256 _addressBookSize = to.length;
            if (_addressBookSize != _batchSize) {
                revert TransferSizeMismatch(_addressBookSize, _batchSize);
            }
            for (uint256 i; i<_batchSize;) {
                _safeTransfer(from, to[i], tokenId[i], "");
                unchecked {++i;}
            }
    }

    /**
     * @dev Allows batch transfer to make is cheaper to move multiple NFTs 
     * between two addresses. Max batch size is 64.
     */
    function transferFrom(address from, address to, uint256[] calldata tokenId)
        external {
            _transferBatch(from, to, tokenId);
    }

    /**
     * @dev Get all params stored for tokenId.
     */
    function getTokenParamsERC(uint256 _tokenId)
        external view
        returns(uint256[4] memory params) {
            uint256 _packedToken = _owners[_tokenId];
            params[0] = uint256(uint24(_packedToken>>EPOS_OWNED_IDX));
            params[1] = uint256(uint24(_packedToken>>EPOS_ALL_IDX));
            params[2] = uint256(uint24(_packedToken>>EPOS_TRANSFER_COUNTER));
            params[3] = uint256(uint24(_packedToken>>EPOS_RESERVED));
    }

    function _setReservedERC(uint256 _tokenId, uint256 _data)
        private {
            _requireMinted(_tokenId);
            _owners[_tokenId] = _setTokenParam(
                _owners[_tokenId],
                EPOS_RESERVED,
                _data,
                type(uint24).max
            );
    }

    /**
     * @dev The cost to set/update should be comparable 
     * to updating insured values.
     */
    function setReservedERC(uint256[2][] calldata _data)
        external override
        onlyRole(RESERVED_ROLE) {
            uint256 _batchSize = _data.length;
            for (uint256 i; i<_batchSize;) {
                _setReservedERC(_data[i][0], _data[i][1]);
                unchecked {++i;}
            }
    }
}
// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: IC9Token.sol


pragma solidity >=0.8.17;



interface IC9Token is IC9ERC721, IERC2981 {

    function getTokenParams(uint256 _tokenId) external view returns(uint256[19] memory params);

    function redeemAdd(uint256[] calldata _tokenIds) external;

    function redeemCancel() external;

    function redeemFinish(uint256 _redeemerData) external;

    function redeemRemove(uint256[] calldata _tokenIds) external;

    function redeemStart(uint256[] calldata _tokenIds) external;

    function preRedeemable(uint256 _tokenId) external view returns(bool);

    function setReserved(uint256[2][] calldata _data) external;

    function setTokenUpgraded(uint256 _tokenId) external;

    function setTokenValidity(uint256 _tokenId, uint256 _vId) external;
}
// File: IC9Redeemer24.sol


pragma solidity >=0.8.17;

uint256 constant RPOS_STEP = 0;
uint256 constant RPOS_CODE = 8;
uint256 constant RPOS_BATCHSIZE = 24;
uint256 constant RPOS_TOKEN1 = 32;
uint256 constant UINT_SIZE = 24;
uint256 constant MAX_BATCH_SIZE = 9;

interface IC9Redeemer {

    function add(address _tokenOwner, uint256[] calldata _tokenId) external;

    function cancel(address _tokenOwner) external returns(uint256 _data);

    function getMinRedeemUSD(uint256 _batchSize) external view returns(uint256);

    function getRedeemerInfo(address _tokenOwner) external view returns(uint256[] memory _info);

    function remove(address _tokenOwner, uint256[] calldata _tokenId) external;

    function start(address _tokenOwner, uint256[] calldata _tokenId) external;
    
}

// File: IC9SVG.sol


pragma solidity >=0.8.17;

interface IC9SVG {
    function returnSVG(address _address, uint256 _tokenId, uint256 _uTokenData, string calldata _sTokenData) external view returns(string memory);
}
// File: IC9MetaData.sol


pragma solidity >=0.8.17;

interface IC9MetaData {
    function metaNameDesc(uint256 _tokenId, uint256 _uTokenData, string calldata _name) external view returns(bytes memory);
    function metaAttributes(uint256 _uTokenData) external view returns (bytes memory b);
}
// File: C9Struct.sol


pragma solidity >=0.8.17;

abstract contract C9Struct {
    uint256 constant BOOL_MASK = 1;

    // Validity
    uint256 constant VALID = 0;
    uint256 constant ROYALTIES = 1;
    uint256 constant INACTIVE = 2;
    uint256 constant OTHER = 3;
    uint256 constant REDEEMED = 4;

    // Upgraded
    uint256 constant UPGRADED = 1;

    // Locked
    uint256 constant UNLOCKED = 0;
    uint256 constant LOCKED = 1;

    // Displays
    uint256 constant ONCHAIN_SVG = 0;
    uint256 constant EXTERNAL_IMG = 1;

    // URIs
    uint256 constant URI0 = 0;
    uint256 constant URI1 = 1;

    struct TokenData {
        uint256 upgraded;
        uint256 display;
        uint256 locked;
        uint256 validity; // Validity flag to show whether not token is redeemable
        uint256 edition; // Physical edition
        uint256 cntrytag; // Hang tag country id
        uint256 cntrytush; // Tush tag country id
        uint256 gentag; // Hang tag generation
        uint256 gentush; // Tush tag generation
        uint256 markertush; // Tush tag special marker id
        uint256 special; // Special id
        uint256 raritytier; // Rarity tier id
        uint256 mintid; // Mint id for the physical edition id
        uint256 royalty; // Royalty amount
        uint256 royaltiesdue;
        uint256 tokenid; // Physical authentication id
        uint256 validitystamp; // Needed if validity invalid
        uint256 mintstamp; // Minting timestamp
        uint256 insurance; // Insured value
        string sData;
    }

    struct TokenSData {
        uint256 tokenId; // Physical authentication id
        string sData;
    }

    uint256 constant POS_UPGRADED = 0;
    uint256 constant POS_DISPLAY = 1;
    uint256 constant POS_LOCKED = 2;
    uint256 constant POS_VALIDITY = 3;
    uint256 constant POS_EDITION = 11;
    uint256 constant POS_CNTRYTAG = 19;
    uint256 constant POS_CNTRYTUSH = 27;
    uint256 constant POS_GENTAG = 35;
    uint256 constant POS_GENTUSH = 43;
    uint256 constant POS_MARKERTUSH = 51;
    uint256 constant POS_SPECIAL = 59;
    uint256 constant POS_RARITYTIER = 67;
    uint256 constant POS_MINTID = 75;
    uint256 constant POS_ROYALTY = 91;
    uint256 constant POS_ROYALTIESDUE = 107;
    uint256 constant POS_VALIDITYSTAMP = 123;
    uint256 constant POS_MINTSTAMP = 163;
    uint256 constant POS_INSURANCE = 203;
    uint256 constant POS_RESERVED = 227;

    /*
     * @dev Returns the indices that split sTokenData into 
     * name, qrData, barCodeData.
     */
    function _getSliceIndices(string calldata _sTokenData)
        internal pure
        returns (uint256 _sliceIndex1, uint256 _sliceIndex2) {
            bytes memory _bData = bytes(_sTokenData);
            for (_sliceIndex1; _sliceIndex1<32;) {
                if (_bData[_sliceIndex1] == 0x3d) {
                    break;
                }
                unchecked {++_sliceIndex1;}
            }
            uint256 _bDataLen = _bData.length;
            _sliceIndex2 = _sliceIndex1 + 50;
            for (_sliceIndex2; _sliceIndex2<_bDataLen;) {
                if (_bData[_sliceIndex2] == 0x3d) {
                    break;
                }
                unchecked {++_sliceIndex2;}
            }
    }
}
// File: C9Token.sol


pragma solidity >=0.8.17;









contract C9Token is C9Struct, ERC721, IC9Token {
    /**
     * @dev Contract access roles.
     */
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant UPDATER_ROLE  = keccak256("UPDATER_ROLE");
    bytes32 public constant VALIDITY_ROLE = keccak256("VALIDITY_ROLE");

    /**
     * @dev Default royalty. These should be packed into one slot.
     * These are part of the custom EIP-2981.
     */
    address private royaltyDefaultReceiver;
    uint96 private royaltyDefaultValue;

    /**
     * @dev Contracts this token contract interacts with.
     */
    address private contractMeta;
    address private contractRedeemer;
    address private contractSVG;
    address private contractUpgrader;
    address private contractVH;

    /**
     * @dev Flag that may enable external (IPFS) artwork 
     * versions to be displayed in the future. The _baseURI
     * is a string[2]: index 0 is active and index 1 is 
     * for inactive.
     */
    bool public svgOnly = true;
    string[2] public _baseURI;

    /**
     * @dev Contract-level meta data for OpenSea.
     * OpenSea: https://docs.opensea.io/docs/contract-level-metadata
     */
    string private _contractURI = "collect9.io/metadata/C9T";

    /**
     * @dev Redemption definitions and events. preRedeemablePeriod 
     * defines how long a token must exist before it can be 
     * redeemed.
     */
    uint256 private preRedeemablePeriod = 31556926; //seconds
    event RedemptionAdd(
        address indexed tokenOwner,
        uint256[] indexed tokenId
    );
    event RedemptionCancel(
        address indexed tokenOwner,
        uint256 indexed batchSize
    );
    event RedemptionFinish(
        address indexed tokenOwner,
        uint256 indexed batchSize
    );
    event RedemptionRemove(
        address indexed tokenOwner,
        uint256[] indexed tokenId
    );
    event RedemptionStart(
        address indexed tokenOwner,
        uint256[] indexed tokenId
    );
    event TokenUpgraded(
        address indexed tokenOwner,
        uint256 indexed tokenId
    );
    
    /**
     * @dev Mappings that hold all of the token info required to 
     * construct the 100% on chain SVG.
     * Many properties within _uTokenData that define 
     * the physical collectible are immutable by design.
     */
    mapping(uint256 => address) private _rTokenData;
    mapping(uint256 => string) private _sTokenData;
    mapping(uint256 => uint256) private _uTokenData;
    
    /**
     * @dev Mapping that checks whether or not some combination of 
     * TokenData has already been minted. The boolean determines
     * whether or not to increment the editionID.
     */
    mapping(bytes32 => bool) private _tokenComboExists;

    /**
     * @dev _mintId stores the edition minting for up to 99 editions.
     * This means that 99 of some physical collectible, differentiated 
     * only by authentication certificate id can be minted. The limit 
     * is 99 due to the SVG only being able to display 2 digits.
     */
    uint16[99] private _mintId;

    /**
     * @dev The constructor sets the default royalty of the tokens.
     * Default receiver is set to owner. Both can be 
     * updated after deployment.
     */
    constructor()
        ERC721("Collect9 NFTs", "C9T") {
            royaltyDefaultValue = uint96(500);
            royaltyDefaultReceiver = owner;
    }

    /*
     * @dev Checks if address is the same before update. There are 
     * a few functions that update addresses where this is used.
     */ 
    modifier addressNotSame(address _old, address _new) {
        if (_old == _new) {
            revert AddressAlreadySet();
        }
        _;
    }

    /*
     * @dev Checks if caller is a smart contract (except from 
     * a constructor).
     */ 
    modifier isContract() {
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        if (size == 0) {
            revert CallerNotContract();
        }
        _;
    }

    /*
     * @dev Checks to see if caller is the token owner.
     */ 
    modifier isOwner(uint256 _tokenId) {
        address _tokenOwner = _ownerOf(_tokenId);
        if (msg.sender != _tokenOwner) {
            revert Unauthorized();
        }
        _;
    }

    /*
     * @dev Limits royalty inputs and updates to 10%.
     */ 
    modifier limitRoyalty(uint256 _royalty) {
        if (_royalty > 999) {
            revert RoyaltyTooHigh();
        }
        _;
    }

    /*
     * @dev Checks to see the token is not dead. Any status redeemed 
     * or greater is a dead status, meaning the token is forever 
     * locked.
     */
    modifier notDead(uint256 _tokenId) {
        if (uint256(uint8(_uTokenData[_tokenId]>>POS_VALIDITY)) >= REDEEMED) {
            revert TokenIsDead(_tokenId);
        }
        _;
    }

    /*
     * @dev Checks to see if the tokenId exists.
     */
    modifier tokenExists(uint256 _tokenId) {
        _requireMinted(_tokenId);
        _;
    }

    /**
     * @dev Required overrides from imported contracts.
     * This one checks to make sure the token is not locked 
     * either in the redemption process, or locked due to a 
     * dead status. Frozen is a long-term fail-safe migration 
     * mechanism in case Ethereum becomes too expensive to 
     * continue transacting on.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
        )
        internal
        override(ERC721)
        notFrozen() {
            uint256 _tokenData = _uTokenData[tokenId];
            if (_tokenData>>POS_LOCKED & BOOL_MASK == LOCKED) {
                revert TokenIsLocked(tokenId);
            }
            // Adds ~3K extra gas to tx if true
            if (uint256(uint8(_tokenData>>POS_VALIDITY)) == INACTIVE) {
                _setTokenValidity(tokenId, VALID);
            }
            super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev IERC2981 for marketplaces to see EIP-2981.
     */
    function supportsInterface(bytes4 interfaceId)
        public view
        override(IERC165, ERC721)
        returns (bool) {
            return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    //>>>>>>> CUSTOM ERC2981 START

    /*
     * @dev Since royalty info is already stored in the uTokenData,
     * we don't need a new slots for per token royalties, and can 
     * use the already existing uTokenData instead.
     */
    function _setTokenRoyalty(uint256 _tokenId, address _receiver, uint256 _royalty)
        private {
            (address _royaltyAddress, uint256 _royaltyAmt) = royaltyInfo(_tokenId, 10000);
            bool _newReceiver = _receiver != _royaltyAddress;
            bool _newRoyalty = _royalty != _royaltyAmt;
            if (!_newReceiver && !_newRoyalty) {
                revert RoyaltiesAlreadySet();
            }

            if (_newReceiver && _receiver != address(0)) {
                if (_receiver == royaltyDefaultReceiver) {
                    if (_rTokenData[_tokenId] != address(0)) {
                        delete _rTokenData[_tokenId];
                    }
                }
                else {
                    _rTokenData[_tokenId] = _receiver;
                }
            }
            
            if (_newRoyalty) {
                _uTokenData[_tokenId] = _setTokenParam(
                    _uTokenData[_tokenId],
                    POS_ROYALTY,
                    _royalty,
                    type(uint16).max
                );
            }
    }

    /**
     * @dev Resets royalty information for the token id back to the 
     * global defaults.
     */
    function resetTokenRoyalty(uint256 _tokenId)
        onlyRole(DEFAULT_ADMIN_ROLE)
        tokenExists(_tokenId)
        notDead(_tokenId)
        external {
            _setTokenRoyalty(_tokenId, royaltyDefaultReceiver, royaltyDefaultValue);
    }

    /**
     * @dev Custom EIP-2981.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public view override
        returns (address, uint256) {
            address receiver = _rTokenData[_tokenId];
            if (receiver == address(0)) {
                receiver = royaltyDefaultReceiver;
            }
            uint256 _fraction = royaltyDefaultValue;
            if (_exists(_tokenId)) {
                _fraction = uint256(uint16(_uTokenData[_tokenId]>>POS_ROYALTY));
            }
            uint256 royaltyAmount = (_salePrice * _fraction) / 10000;
            return (receiver, royaltyAmount);
    }

    /**
     * @dev Set royalties due if token validity status 
     * is ROYALTIES. This is admin role instead of VALIDITY_ROLE 
     * to reduce gas costs. VALIDITY_ROLE will need to set 
     * validity status ROYALTIES beforehand.
     */
    function setRoyaltiesDue(uint256 _tokenId, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        tokenExists(_tokenId) {
            if (_amount == 0) {
                revert ZeroValue();
            }
            uint256 _tokenData = _uTokenData[_tokenId];
            uint256 _tokenValidity = uint256(uint8(_tokenData>>POS_VALIDITY));
            if (_tokenValidity != ROYALTIES) {
                revert IncorrectTokenValidity(ROYALTIES, _tokenValidity);
            }
            if (uint256(uint16(_tokenData>>POS_ROYALTIESDUE)) == _amount) {
                revert RoyaltiesAlreadySet();
            }
            _uTokenData[_tokenId] = _setTokenParam(
                _tokenData,
                POS_ROYALTIESDUE,
                _amount,
                type(uint16).max
            );
    }

    /**
     * @dev Allows contract to have a separate royalties receiver 
     * address from owner. The default receiver is owner.
     */
    function setRoyaltyDefaultReceiver(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        addressNotSame(royaltyDefaultReceiver, _address) {
            if (_address == address(0)) {
                revert ZeroAddressInvalid();
            }
            royaltyDefaultReceiver = _address;
    }

    /**
     * @dev Sets the default royalties amount.
     */
    function setRoyaltyDefaultValue(uint256 _royaltyDefaultValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        limitRoyalty(_royaltyDefaultValue) {
            if (_royaltyDefaultValue == royaltyDefaultValue) {
                revert ValueAlreadySet();
            }
            royaltyDefaultValue = uint96(_royaltyDefaultValue);
    }

    /**
     * @dev Allows the contract owner to set royalties 
     * on a per token basis, within limits.
     * Note: set _receiver address to the null address 
     * to ignore it and use the already default set royalty address.
     * Note: Updating the receiver the first time is nearly as
     * expensive as updating both together the first time.
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        uint256 _newRoyalty,
        address _receiver
        )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        tokenExists(_tokenId)
        notDead(_tokenId)
        limitRoyalty(_newRoyalty) {
            _setTokenRoyalty(_tokenId, _receiver, _newRoyalty);
    }

    //>>>>>>> CUSTOM ERC2981 END

    /**
     * @dev Returns a unique hash depending on certain token `_input` attributes. 
     * This helps keep track the `_edition` number of a particular set of attributes. 
     * Note that if the token is burned, the edition cannot be replaced but 
     * instead will keep incrementing.
     */
    function _getPhysicalHash(TokenData calldata _input, uint256 _edition)
        private pure
        returns (bytes32) {
            bytes memory _bData = bytes(_input.sData);
            uint256 _splitIndex;
            for (_splitIndex; _splitIndex<32;) {
                if (_bData[_splitIndex] == 0x3d) {
                    break;
                }
                unchecked {++_splitIndex;}
            }
            return keccak256(
                abi.encodePacked(
                    _edition,
                    _input.cntrytag,
                    _input.cntrytush,
                    _input.gentag,
                    _input.gentush,
                    _input.markertush,
                    _input.special,
                    _input.sData[:_splitIndex]
                )
            );
    }

    /**
     * @dev Minting function. This checks and sets the `_edition` based on 
     * the `TokenData` input attributes, sets the `__mintId` based on 
     * the `_edition`, sets the royalty, and then stores all of the 
     * attributes required to construct the SVG in the tightly packed 
     * `TokenData` structure.
     */
    function _mint1(TokenData calldata _input)
        private
        limitRoyalty(_input.royalty) {
            // Get physical edition id
            uint256 _edition = _input.edition;
            bytes32 _data;
            if (_edition == 0) {
                for (_edition; _edition<98;) {
                    unchecked {
                        ++_edition;
                        _data = _getPhysicalHash(_input, _edition);
                    }
                    if (!_tokenComboExists[_data]) {
                        // Store token attribute combo
                        _tokenComboExists[_data] = true;
                        break;
                    }
                }
            }

            // Get the edition mint id
            uint256 __mintId;
            unchecked {__mintId = _mintId[_edition]+1;}
            if (_input.mintid != 0) {
                __mintId = _input.mintid;
            }
            else {
                _mintId[_edition] = uint16(__mintId);
            }

            // Checks
            uint256 _tokenId = _input.tokenid;
            if (_tokenId == 0) {
                revert ZeroTokenId();
            }
            if (_edition == 0) {
                revert ZeroEdition();
            }
            if (_edition >= 99) {
                revert EditionOverflow(_edition);
            }
            if (__mintId == 0) {
                revert ZeroMintId();
            }

            // Store token uint data
            uint256 _packedToken;
            uint256 _timestamp = block.timestamp;
            _packedToken |= _input.upgraded<<POS_UPGRADED;
            _packedToken |= _input.display<<POS_DISPLAY;
            _packedToken |= _input.locked<<POS_LOCKED;
            _packedToken |= _input.validity<<POS_VALIDITY;
            _packedToken |= _edition<<POS_EDITION;
            _packedToken |= _input.cntrytag<<POS_CNTRYTAG;
            _packedToken |= _input.cntrytush<<POS_CNTRYTUSH;
            _packedToken |= _input.gentag<<POS_GENTAG;
            _packedToken |= _input.gentush<<POS_GENTUSH;
            _packedToken |= _input.markertush<<POS_MARKERTUSH;
            _packedToken |= _input.special<<POS_SPECIAL;
            _packedToken |= _input.raritytier<<POS_RARITYTIER;
            _packedToken |= __mintId<<POS_MINTID;
            _packedToken |= _input.royalty<<POS_ROYALTY;
            _packedToken |= _input.royaltiesdue<<POS_ROYALTIESDUE;
            _packedToken |= _timestamp<<POS_VALIDITYSTAMP;
            _packedToken |= _timestamp<<POS_MINTSTAMP;
            _packedToken |= _input.insurance<<POS_INSURANCE;
            _uTokenData[_tokenId] = _packedToken;

            // Store token string data
            _sTokenData[_tokenId] = _input.sData;

            // Mint token
            _mint(msg.sender, _tokenId);
    }

    /**
     * @dev Internal function that returns if the token is
     * preredeemable or not.
     */
    function _preRedeemable(uint256 _tokenData)
        private view
        returns (bool) {
            uint256 _ds = block.timestamp-uint256(uint40(_tokenData>>POS_MINTSTAMP));
            return _ds < preRedeemablePeriod;
    }

    /**
     * @dev Updates the token validity status.
     */
    function _setTokenValidity(uint256 _tokenId, uint256 _vId)
        private {
            uint256 _tokenData = _uTokenData[_tokenId];
            _tokenData = _setTokenParam(
                _tokenData,
                POS_VALIDITY,
                _vId,
                type(uint8).max
            );
            _tokenData = _setTokenParam(
                _tokenData,
                POS_VALIDITYSTAMP,
                block.timestamp,
                type(uint40).max
            );
            // Lock if changing to a dead status (forever lock)
            if (_vId >= REDEEMED) {
                _tokenData = _setTokenParam(
                    _tokenData,
                    POS_LOCKED,
                    LOCKED,
                    BOOL_MASK
                );
            }
            _uTokenData[_tokenId] = _tokenData;
    }

    /**
     * @dev Unlocks the token. The Redeem cancel functions 
     * call this to unlock the token.
     * Modifiers are placed here as it makes it simpler
     * to enforce their conditions.
     */
    function _unlockToken(uint256 _tokenId)
        private {
            uint256 _tokenData = _uTokenData[_tokenId];
            if (_tokenData>>POS_LOCKED & BOOL_MASK == UNLOCKED) {
                revert TokenNotLocked(_tokenId);
            }
            _tokenData = _setTokenParam(
                _tokenData,
                POS_LOCKED,
                UNLOCKED,
                BOOL_MASK
            );
            _uTokenData[_tokenId] = _tokenData;
    }

    /**
     * @dev Fail-safe function that can unlock an active token.
     * This is for any edge cases that may have been missed 
     * during redeemer testing. Dead tokens are still not 
     * possible to unlock.
     */
    function adminUnlock(uint256 _tokenId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        tokenExists(_tokenId)
        notDead(_tokenId) {
            _unlockToken(_tokenId);
    }

    /**
     * @dev The token burning required for the redemption process.
     * Require statement is the same as in ERC721Burnable.
     * Note the `tokenComboExists` of the token is not removed, thus 
     * once the `edition` of any burned token cannot be replaced, but 
     * instead will keep incrementing.
     */
    function burn(uint256 _tokenId)
        public
        isOwner(_tokenId) {
            _burn(_tokenId);
            delete _uTokenData[_tokenId];
            delete _sTokenData[_tokenId];
            if (_rTokenData[_tokenId] != address(0)) {
                delete _rTokenData[_tokenId];
            }
    }

    /**
     * @dev Bulk burn function for convenience.
     */
    function burnAll(bool confirm)
        external {
            if (!confirm) {
                revert ActionNotConfirmed();
            }
            uint256 ownerSupply = balanceOf(msg.sender);
            if (ownerSupply == 0) {
                revert NoOwnerSupply(msg.sender);
            }
            for (uint256 i; i<ownerSupply;) {
                burn(tokenOfOwnerByIndex(msg.sender, 0));
                unchecked {++i;}
            }
    }

    /**
     * @dev When a single burn is too expensive but you
     * don't want to burn all.
     */
    function burnBatch(bool confirm, uint256[] calldata _tokenId)
        external {
            if (!confirm) {
                revert ActionNotConfirmed();
            }
            uint256 _batchSize = _tokenId.length;
            if (_batchSize == 0) {
                revert NoOwnerSupply(msg.sender);
            }
            for (uint256 i; i<_batchSize;) {
                burn(_tokenId[i]);
                unchecked {++i;}
            }
    }

    /**
     * @dev Contract-level meta data for OpenSea.
     * OpenSea: https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI()
        external view
        returns (string memory) {
            return string(abi.encodePacked(
                "https://", _contractURI, ".json"
            ));
    }

    /**
     * @dev Returns list of contracts this contract is linked to.
     */
    function getContracts()
        external view
        returns(
            address meta, 
            address redeemer, 
            address svg, 
            address upgrader,
            address vH
        ) {
            meta = contractMeta;
            redeemer = contractRedeemer;
            svg = contractSVG;
            upgrader = contractUpgrader;
            vH = contractVH;
    }

    /**
     * @dev uTokenData is packed into a single uint256. This function
     * returns an unpacked array. It overrides the C9Struct defintion 
     * so only the _tokenId needs to be passed in.
     */
    function getTokenParams(uint256 _tokenId)
        external view override
        returns(uint256[19] memory params) {
            uint256 _packedToken = _uTokenData[_tokenId];
            params[0] = _packedToken>>POS_UPGRADED & BOOL_MASK;
            params[1] = _packedToken>>POS_DISPLAY & BOOL_MASK;
            params[2] = _packedToken>>POS_LOCKED & BOOL_MASK;
            params[3] = uint256(uint8(_packedToken>>POS_VALIDITY));
            params[4] = uint256(uint8(_packedToken>>POS_EDITION));
            params[5] = uint256(uint8(_packedToken>>POS_CNTRYTAG));
            params[6] = uint256(uint8(_packedToken>>POS_CNTRYTUSH));
            params[7] = uint256(uint8(_packedToken>>POS_GENTAG));
            params[8] = uint256(uint8(_packedToken>>POS_GENTUSH));
            params[9] = uint256(uint8(_packedToken>>POS_MARKERTUSH));
            params[10] = uint256(uint8(_packedToken>>POS_SPECIAL));
            params[11] = uint256(uint8(_packedToken>>POS_RARITYTIER));
            params[12] = uint256(uint16(_packedToken>>POS_MINTID));
            params[13] = uint256(uint16(_packedToken>>POS_ROYALTY));
            params[14] = uint256(uint16(_packedToken>>POS_ROYALTIESDUE));
            params[15] = uint256(uint40(_packedToken>>POS_VALIDITYSTAMP));
            params[16] = uint256(uint40(_packedToken>>POS_MINTSTAMP));
            params[17] = uint256(uint24(_packedToken>>POS_INSURANCE));
            params[18] = uint256(_packedToken>>POS_RESERVED);
    }

    /**
     * @dev Batch mint. Makes the overall minting process faster and cheaper 
     * on average per mint.
     */
    function mintBatch(TokenData[] calldata _input)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
            uint256 _batchSize = _input.length;
            for (uint256 i; i<_batchSize;) {
                _mint1(_input[i]);
                unchecked {++i;}
            }
    }

    //>>>>>>> REDEEMER FUNCTIONS START

    /*
     * @dev A lot of code has been repeated (inlined) here to minimize 
     * storage reads to reduce gas cost.
     */
    function _redeemLockTokens(uint256[] calldata _tokenIds)
        private {
            uint256 _batchSize = _tokenIds.length;
            address _tokenOwner;
            uint256 _tokenId;
            uint256 _tokenData;
            for (uint256 i; i<_batchSize;) {
                _tokenId = _tokenIds[i];
                _tokenOwner = _ownerOf(_tokenId);
                if (msg.sender != _tokenOwner) {
                    revert Unauthorized();
                }

                _tokenData = _uTokenData[_tokenId];
                if (_preRedeemable(_tokenData)) {
                    revert TokenPreRedeemable(_tokenId);
                }
                
                uint256 _validity = uint256(uint8(_tokenData>>POS_VALIDITY));
                if (_validity != VALID) {
                    if (_validity == INACTIVE) {
                        /* Inactive tokens can still be redeemed and 
                        will be changed to valid as user activity 
                        will automatically fix this status. */
                        _tokenData = _setTokenParam(
                            _tokenData,
                            POS_VALIDITY,
                            VALID,
                            type(uint8).max
                        );
                        _tokenData = _setTokenParam(
                            _tokenData,
                            POS_VALIDITYSTAMP,
                            block.timestamp,
                            type(uint40).max
                        );
                    }
                    else {
                        revert IncorrectTokenValidity(VALID, _validity);
                    }
                }

                // If valid and locked, can only be in redeemer.
                if (_tokenData>>POS_LOCKED & BOOL_MASK == LOCKED) {
                    revert TokenIsLocked(_tokenId);
                }
                
                // Lock the token.
                _tokenData = _setTokenParam(
                   _tokenData,
                    POS_LOCKED,
                    LOCKED,
                    BOOL_MASK
                );

                // Save token data back to storage.
                _uTokenData[_tokenId] = _tokenData;
                unchecked {++i;}
            }
    }

    /**
     * @dev Returns whether or not the token pre-release period 
     * has ended.
     */
    function preRedeemable(uint256 _tokenId)
        public view override
        tokenExists(_tokenId)
        returns (bool) {
            return _preRedeemable(_uTokenData[_tokenId]);
    }

    /**
     * @dev Add tokens to an existing redemption process.
     * Once added, the token is locked from further exchange until 
     * either canceled or removed.
     */
    function redeemAdd(uint256[] calldata _tokenIds)
        external override {
            _redeemLockTokens(_tokenIds);
            IC9Redeemer(contractRedeemer).add(msg.sender, _tokenIds);
            emit RedemptionAdd(msg.sender, _tokenIds);
    }

    /**
     * @dev Allows user to cancel redemption process and 
     * unlock tokens.
     */
    function redeemCancel()
        external override {
            uint256 _redeemerData = IC9Redeemer(contractRedeemer).cancel(msg.sender);
            uint256 _batchSize = uint256(uint8(_redeemerData>>RPOS_BATCHSIZE));
            uint256 _tokenOffset = RPOS_TOKEN1;
            uint256 _tokenId;
            for (uint256 i; i<_batchSize;) {
                _tokenId = uint256(uint24(_redeemerData>>_tokenOffset));
                if (msg.sender != _ownerOf(_tokenId)) {
                    revert Unauthorized();
                }
                _unlockToken(_tokenId);
                unchecked {
                    _tokenOffset += UINT_SIZE;
                    ++i;
                }
            }
            emit RedemptionCancel(msg.sender, _batchSize);
    }

    /**
     * @dev Finishes redemption. Called by the redeemer contract.
     */
    function redeemFinish(uint256 _redeemerData)
        external override
        onlyRole(REDEEMER_ROLE)
        isContract() {
            uint256 _batchSize = uint256(uint8(_redeemerData>>RPOS_BATCHSIZE));
            uint256 _tokenOffset = RPOS_TOKEN1;
            uint256 _tokenId;
            for (uint256 i; i<_batchSize;) {
                _tokenId = uint256(uint24(_redeemerData>>_tokenOffset));
                _setTokenValidity(_tokenId, REDEEMED);
                unchecked {
                    _tokenOffset += UINT_SIZE;
                    ++i;
                }
            }
            emit RedemptionFinish(
                _ownerOf(uint256(uint24(_redeemerData>>RPOS_TOKEN1))),
                _batchSize
            );
    }

    /**
     * @dev Allows user to remove tokens from 
     * an existing redemption process.
     */
    function redeemRemove(uint256[] calldata _tokenIds)
        external override {
            IC9Redeemer(contractRedeemer).remove(msg.sender, _tokenIds);
            uint256 _batchSize = _tokenIds.length;
            uint256 _tokenId;
            for (uint256 i; i<_batchSize;) {
                _tokenId = _tokenIds[i];
                if (msg.sender != _ownerOf(_tokenId)) {
                    revert Unauthorized();
                }
                _unlockToken(_tokenId);
                unchecked {++i;}
            }
            emit RedemptionRemove(msg.sender, _tokenIds);
    }

    /**
     * @dev Starts the redemption process.
     * Once started, the token is locked from further exchange 
     * unless canceled.
     */
    function redeemStart(uint256[] calldata _tokenIds)
        external override {
            _redeemLockTokens(_tokenIds);
            IC9Redeemer(contractRedeemer).start(msg.sender, _tokenIds);
            emit RedemptionStart(msg.sender, _tokenIds);
    }

    /**
     * @dev Gets or sets the global token redeemable period.
     * Limit hardcoded.
     */
    function setPreRedeemPeriod(uint256 _period)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (preRedeemablePeriod == _period) {
                revert ValueAlreadySet();
            }
            if (_period > 63113852) { // 2 years max
                revert PeriodTooLong(63113852, _period);
            }
            preRedeemablePeriod = _period;
    }

    //>>>>>>> REDEEMER FUNCTIONS END

    //>>>>>>> SETTER FUNCTIONS START

    /**
     * @dev Updates the baseURI.
     * By default this contract will load SVGs from another contract, 
     * but if a future upgrade allows for artwork (i.e, on ipfs), the 
     * contract will need to set the IPFS location.
     */
    function setBaseUri(string calldata _newBaseURI, uint256 _idx)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (Helpers.stringEqual(_baseURI[_idx], _newBaseURI)) {
                revert URIAlreadySet();
                
            }
            bytes calldata _bBaseURI = bytes(_newBaseURI);
            uint256 len = _bBaseURI.length;
            if (bytes1(_bBaseURI[len-1]) != 0x2f) {
                revert URIMissingEndSlash();
            }
            _baseURI[_idx] = _newBaseURI;
    }

    /**
     * @dev Sets the meta data contract address.
     */
    function setContractMeta(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        addressNotSame(contractMeta, _address) {
            contractMeta = _address;
    }

    /**
     * @dev Sets the redemption contract address.
     */
    function setContractRedeemer(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        addressNotSame(contractRedeemer, _address) {
            contractRedeemer = _address;
            _grantRole(REDEEMER_ROLE, contractRedeemer);
    }

    /**
     * @dev Sets the SVG display contract address.
     */
    function setContractSVG(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        addressNotSame(contractSVG, _address) {
            contractSVG = _address;
    }

    /**
     * @dev Sets the upgrader contract address.
     */
    function setContractUpgrader(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        addressNotSame(contractUpgrader, _address) {
            contractUpgrader = _address;
            _grantRole(UPGRADER_ROLE, contractUpgrader);
    }

    /**
     * @dev Sets the contractURI.
     */
    function setContractURI(string calldata _newContractURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (Helpers.stringEqual(_contractURI, _newContractURI)) {
                revert URIAlreadySet();
            }
            _contractURI = _newContractURI;
    }

    /**
     * @dev Sets the validity handler contract address.
     */
    function setContractVH(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        addressNotSame(contractVH, _address) {
            contractVH = _address;
            _grantRole(VALIDITY_ROLE, contractVH);
    }

    /**
     * @dev Set SVG flag to either display on-chain SVG (true) or  
     * external version (false). If set to true, it is still possible 
     * to retrieve the SVG image by calling svgImage(_tokenId).
     */
    function setSvgOnly(bool _flag)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
            if (svgOnly == _flag) {
                revert BoolAlreadySet();
            }
            svgOnly = _flag;
    }

    /**
     * @dev Allows holder toggle display flag.
     * Flag must be set to true for upgraded / external 
     * view to show. Metadata needs to be refershed 
     * on exchanges for changes to show.
     */
    function setTokenDisplay(uint256 _tokenId, bool _flag)
        external
        isOwner(_tokenId) {
            uint256 _tokenData = _uTokenData[_tokenId];
            uint256 _val = _tokenData>>POS_UPGRADED & BOOL_MASK;
            if (_val != UPGRADED) {
                revert TokenNotUpgraded(_tokenId);
            }
            _val = _tokenData>>POS_DISPLAY & BOOL_MASK;
            if (Helpers.uintToBool(_val) == _flag) {
                revert BoolAlreadySet();
            }
            uint256 _display = _flag ? EXTERNAL_IMG : ONCHAIN_SVG;
            _uTokenData[_tokenId] = _setTokenParam(
                _tokenData,
                POS_DISPLAY,
                _display,
                BOOL_MASK
            );
    }

    /**
     * @dev Sets/updates the insured value of the physical collectible.
     * Cost is around ~8650 gas / token batched 96.
     * Tested to also handle 272 at once (~8475 / token).
     * A once a year full update should be viable even at 
     * $3K ETH and 50GWEI gas ($350 est).
     */
    function _setTokenInsuredValue(uint256 _tokenId, uint256 _insuredValue)
        private
        tokenExists(_tokenId)
        notDead(_tokenId) {
            uint256 _tokenData = _uTokenData[_tokenId];
            uint256 _val = uint256(uint24(_tokenData>>POS_INSURANCE));
            if (_val != _insuredValue) {
                _tokenData = _setTokenParam(
                    _tokenData,
                    POS_INSURANCE,
                    _insuredValue,
                    type(uint24).max
                );
                _uTokenData[_tokenId] = _tokenData;
            }
    }

    function setTokenInsuredValue(uint256[2][] calldata _data)
        external 
        onlyRole(UPDATER_ROLE) {
            uint256 _batchSize = _data.length;
            for (uint256 i; i<_batchSize;) {
                _setTokenInsuredValue(_data[i][0], _data[i][1]);
                unchecked {++i;}
            }
    }

    /**
     * @dev Allows the compressed data that is used to display the 
     * micro QR code on the SVG to be updated.
     */
    function _setTokenSData(uint256 _tokenId, string calldata _sData)
        private
        tokenExists(_tokenId)
        notDead(_tokenId) {
            _sTokenData[_tokenId] = _sData;
    }

    function setTokenSData(TokenSData[] calldata _data)
        external 
        onlyRole(UPDATER_ROLE) {
            uint256 _batchSize = _data.length;
            for (uint256 i; i<_batchSize;) {
                _setTokenSData(_data[i].tokenId, _data[i].sData);
                unchecked {++i;}
            }
    }

    /*
     * @dev Sets the token validity.
     */
    function setTokenValidity(uint256 _tokenId, uint256 _vId)
        external override
        onlyRole(VALIDITY_ROLE)
        isContract()
        tokenExists(_tokenId)
        notDead(_tokenId) {
            if (_vId == REDEEMED) {
                // 6, 7, 8 are dead ids for invalid active ids 1, 2, 3
                revert InvalidVId(_vId);
            }
            uint256 _currentVId = uint256(uint8(_uTokenData[_tokenId]>>POS_VALIDITY));
            if (_vId == _currentVId) {
                revert ValueAlreadySet();
            }
            _setTokenValidity(_tokenId, _vId);
    }

    /**
     * @dev Sets the token as upgraded.
     */
    function setTokenUpgraded(uint256 _tokenId)
        external override
        onlyRole(UPGRADER_ROLE)
        isContract()
        tokenExists(_tokenId)
        notDead(_tokenId) {
            uint256 _tokenData = _uTokenData[_tokenId];
            if (_tokenData>>POS_UPGRADED & BOOL_MASK == UPGRADED) {
                revert TokenAlreadyUpgraded(_tokenId);
            }
            _uTokenData[_tokenId] = _setTokenParam(
                _tokenData,
                POS_UPGRADED,
                UPGRADED,
                BOOL_MASK
            );
            emit TokenUpgraded(_ownerOf(_tokenId), _tokenId);
    }

    /**
     * @dev Returns the base64 representation of the SVG string. 
     * This is desired when including the string in json data which 
     * does not allow special characters found in hmtl/xml code.
     */
    function svgImage(uint256 _tokenId)
        public view
        tokenExists(_tokenId)
        returns (string memory) {
            return IC9SVG(contractSVG).returnSVG(
                _ownerOf(_tokenId),
                _tokenId,
                _uTokenData[_tokenId],
                _sTokenData[_tokenId]
            );
    }

    /**
     * @dev Required override that returns fully onchain constructed 
     * json output that includes the SVG image. If a baseURI is set and 
     * the token has been upgraded and the svgOnly flag is false, call 
     * the baseURI.
     *
     * Notes:
     * It seems like if the baseURI method fails after upgrade, OpenSea
     * still displays the cached on-chain version.
     */
    function tokenURI(uint256 _tokenId)
        public view override(ERC721, IERC721Metadata)
        tokenExists(_tokenId)
        returns (string memory) {
            uint256 _tokenData = _uTokenData[_tokenId];
            bool _externalView = _tokenData>>POS_DISPLAY & BOOL_MASK == EXTERNAL_IMG;
            bytes memory image;
            if (svgOnly || !_externalView) {
                // Onchain SVG
                image = abi.encodePacked(
                    ',"image":"data:image/svg+xml;base64,',
                    Base64.encode(bytes(svgImage(_tokenId)))
                );
            }
            else {
                // Token upgraded, get view URI based on if redeemed or not
                uint256 _viewIdx = uint256(uint8(_tokenData>>POS_VALIDITY)) >= REDEEMED ? URI1 : URI0;
                image = abi.encodePacked(
                    ',"image":"',
                    _baseURI[_viewIdx],
                    Helpers.tokenIdToBytes(_tokenId),
                    '.png'
                );
            }
            return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            IC9MetaData(contractMeta).metaNameDesc(_tokenId, _tokenData, _sTokenData[_tokenId]),
                            image,
                            IC9MetaData(contractMeta).metaAttributes(_tokenData)
                        )
                    )
                )
            );
    }

    /**
     * @dev Disables self-destruct functionality.
     * Note: even if admin gets through the confirm 
     * is hardcoded to false.
     */
    function __destroy(address _receiver, bool confirm)
        public override
        onlyRole(DEFAULT_ADMIN_ROLE) {
            confirm = false;
            super.__destroy(_receiver, confirm);
    }

    /**
     * @dev Sets the data for the reserved (unused at mint) 
     * space. Since this storage is already paid for, it may
     * be used for expansion features that may be available 
     * later. Such features will only be available to 
     * external contracts, as this contract will have no
     * built-in parsing.
     * 29 bits remain in the reserved storage space.
     */
    function _setReserved(uint256 _tokenId, uint256 _data)
        private
        tokenExists(_tokenId)
        notDead(_tokenId) {
            _uTokenData[_tokenId] = _setTokenParam(
                _uTokenData[_tokenId],
                POS_RESERVED,
                _data,
                536870911
            );
    }

    /**
     * @dev The cost to set/update should be comparable 
     * to updating insured values.
     */
    function setReserved(uint256[2][] calldata _data)
        external override
        onlyRole(RESERVED_ROLE) {
            uint256 _batchSize = _data.length;
            for (uint256 i; i<_batchSize;) {
                _setReserved(_data[i][0], _data[i][1]);
                unchecked {++i;}
            }
    }
}