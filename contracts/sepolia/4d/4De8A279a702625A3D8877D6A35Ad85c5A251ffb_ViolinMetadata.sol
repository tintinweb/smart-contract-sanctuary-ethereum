// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
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
pragma solidity 0.8.17;

abstract contract IConnectContract {
  function getContractsForVersion(
    uint violinID_
  ) public view virtual returns (RCLib.ContractCombination memory cc);

  function violinAddress() public view virtual returns (address violinAddress);

  function getControllerContract(
    uint violinID_
  ) public view virtual returns (address controllerContract);

  function getAccessControlContract(
    uint violinID_
  ) public view virtual returns (address accessControlContract);

  function getMetadataContract(
    uint violinID_
  ) public view virtual returns (address metadataContract);

  function versionIsActive(uint version) external view virtual returns (bool);
}

abstract contract IController {
  function returnRequestByViolinId(
    uint256 request_
  ) public view virtual returns (RCLib.Request memory);

  function roleName(RCLib.Role) public view virtual returns (string memory);

  function requestByViolinId(
    uint256 id_
  ) public view virtual returns (RCLib.Request memory);
}

abstract contract IConfigurationContract {
  function getConfigForVersion(
    uint256 version_
  ) public view virtual returns (RCLib.RequestConfig[] memory);

  function checkTasks(
    RCLib.Tasks task_
  ) public pure virtual returns (RCLib.TaskCluster cluster);

  function returnRoleConfig(
    uint256 version_,
    RCLib.Tasks configId_
  ) public view virtual returns (RCLib.RequestConfig memory);

  function violinToVersion(uint256 tokenId) external view virtual returns (uint256);
}

abstract contract IViolines {
  function mintViolin(uint256 id_, address addr_) external virtual;

  function ownerOf(uint256 tokenId) public view virtual returns (address);

  function balanceOf(address owner) public view virtual returns (uint256);
}

abstract contract IViolineMetadata {
  struct EventType {
    string name;
    string description;
    string role;
    address attendee;
    uint256 eventTimestamp;
  }

  function createNewConcert(
    string memory name_,
    string memory description_,
    string memory role_,
    address attendee_,
    uint256 eventTimestamp_,
    uint256 tokenID_
  ) external virtual;

  /// @param docType_ specify the document type: PROVENANCE, DOCUMENT, SALES
  /// @param date_ timestamp of the event
  /// @param cid_ file attachments
  /// @param title_ title of the Document
  /// @param description_ description of the doc
  /// @param source_ source of the doc
  /// @param value_ amount of the object
  /// @param value_original_currency_ amount of the object
  /// @param currency_ in which currency it was sold
  /// @param tokenID_ token ID
  function createNewDocument(
    string memory docType_,
    uint256 date_,
    string memory cid_,
    string memory title_,
    string memory description_,
    string memory source_,
    uint value_,
    uint value_original_currency_,
    string memory currency_,
    uint256 tokenID_
  ) external virtual;

  function changeMetadata(
    string memory name_,
    string memory description_,
    string memory longDescription_,
    string memory image_,
    string[] memory media_,
    string[] memory model3d_,
    string[] memory attributeNames_,
    string[] memory attributeValues_,
    uint256 tokenId_
  ) external virtual;

  function readManager(uint256 tokenID_) public view virtual returns (address);

  function readLocation(uint256 tokenID_) public view virtual returns (address);

  function setTokenManager(uint256 tokenID_, address manager_) external virtual;

  function setTokenArtist(uint256 tokenID_, address artist_) external virtual;

  function setTokenOwner(uint256 tokenID_, address owner_) external virtual;

  function setExhibitor(uint256 tokenID_, address exhibitor_) external virtual;

  function setTokenViolinMaker(uint256 tokenID_, address violinMaker_) external virtual;

  function setViolinLocation(uint256 tokenID_, address violinLocation_) external virtual;

  function createNewEvent(
    string memory name_,
    string memory description_,
    RCLib.Role role_,
    address attendee_,
    uint256 eventStartTimestamp_,
    uint256 eventEndTimestamp_,
    RCLib.Tasks eventType_,
    uint256 tokenID_
  ) external virtual;
}

abstract contract IAccessControl {
  function mintRole(
    address assignee_,
    RCLib.Role role_,
    uint256 contractValidUntil_,
    uint256 violinID_,
    string memory image,
    string memory description
  ) external virtual;

  function changeMetadata(
    uint256 tokenId_,
    string memory description_,
    string memory image_
  ) public virtual;

  function checkIfAddressHasAccess(
    address addr_,
    RCLib.Role role_,
    uint256 violinID_
  ) public view virtual returns (bool);

  function setTimestamp(
    uint256 violinID_,
    uint256 timestamp_,
    address targetAccount_,
    RCLib.Role role_
  ) external virtual;

  function burnTokens(
    address targetAccount,
    RCLib.Role affectedRole,
    uint256 violinId
  ) external virtual;

  function returnCorrespondingTokenID(
    address addr_,
    RCLib.Role role_,
    uint256 violinID_
  ) public view virtual returns (uint256);

  function administrativeMove(
    address from,
    address to,
    uint256 violinId,
    uint256 tokenId
  ) public virtual;
}

library RCLib {
  enum Role {
    OWNER_ROLE,
    VOUNTAIN,
    INSTRUMENT_MANAGER_ROLE,
    MUSICIAN_ROLE,
    VIOLIN_MAKER_ROLE,
    CUSTODIAL,
    EXHIBITOR_ROLE
  }

  enum TaskCluster {
    CREATION,
    CHANGE_DURATION,
    DELISTING,
    DELEGATING,
    EVENTS,
    DOCUMENTS,
    METADATA,
    MINTING
  }

  enum Tasks {
    CREATE_INSTRUMENT_MANAGER_ROLE,
    CREATE_MUSICIAN_ROLE,
    CREATE_VIOLIN_MAKER_ROLE,
    CREATE_OWNER_ROLE,
    CREATE_EXHIBITOR_ROLE,
    CHANGE_DURATION_MUSICIAN_ROLE,
    CHANGE_DURATION_INSTRUMENT_MANAGER_ROLE,
    CHANGE_DURATION_VIOLIN_MAKER_ROLE,
    CHANGE_DURATION_OWNER_ROLE,
    CHANGE_DURATION_EXHIBITOR_ROLE,
    DELIST_INSTRUMENT_MANAGER_ROLE,
    DELIST_MUSICIAN_ROLE,
    DELIST_VIOLIN_MAKER_ROLE,
    DELIST_OWNER_ROLE,
    DELIST_EXHIBITOR_ROLE,
    DELEGATE_INSTRUMENT_MANAGER_ROLE,
    DELEGATE_MUSICIAN_ROLE,
    DELEGATE_VIOLIN_MAKER_ROLE,
    DELEGATE_EXHIBITOR_ROLE,
    ADD_CONCERT,
    ADD_EXHIBITION,
    ADD_REPAIR,
    ADD_PROVENANCE,
    ADD_DOCUMENT,
    ADD_SALES,
    MINT_NEW_VIOLIN,
    CHANGE_METADATA_VIOLIN,
    CHANGE_METADATA_ACCESSCONTROL
  }

  struct TokenAttributes {
    address owner;
    address manager;
    address artist;
    address violinMaker;
    address violinLocation;
    address exhibitor;
    RCLib.Event[] concert;
    RCLib.Event[] exhibition;
    RCLib.Event[] repair;
    RCLib.Documents[] document;
    RCLib.Metadata metadata;
  }

  struct RequestConfig {
    uint256 approvalsNeeded; //Amount of Approver
    RCLib.Role affectedRole; //z.B. MUSICIAN_ROLE
    RCLib.Role[] canApprove;
    RCLib.Role[] canInitiate;
    uint256 validity; //has to be in hours!!!
  }

  struct RoleNames {
    Role role;
    string[] names;
  }

  enum PROCESS_TYPE {
    IS_APPROVE_PROCESS,
    IS_CREATE_PROCESS
  }

  struct Request {
    uint256 violinId;
    uint256 contractValidUntil; //Timestamp
    address creator; //Initiator
    address targetAccount; //Get Role
    bool canBeApproved; //Wurde der Approval bereits ausgeführt
    RCLib.Role affectedRole; //Rolle im AccessControl Contract
    Role[] canApprove; //Rollen, die Approven können
    RCLib.Tasks approvalType; //z.B. CREATE_INSTRUMENT_MANAGER_ROLE
    uint256 approvalsNeeded; //Amount of approval needed
    uint256 approvalCount; //current approvals
    uint256 requestValidUntil; //Wie lange ist der Request gültig?
    address mintTarget; //optional
    RCLib.Event newEvent;
    RCLib.Documents newDocument;
    RCLib.Metadata newMetadata;
    RCLib.Role requesterRole;
  }

  struct AccessToken {
    string image;
    RCLib.Role role;
    uint256 violinID;
    uint256 contractValidUntil;
    string name;
    string description;
  }

  struct Event {
    string name;
    string description;
    RCLib.Role role;
    address attendee;
    uint256 eventStartTimestamp;
    uint256 eventEndTimestamp;
  }

  struct Documents {
    string docType;
    uint256 date;
    string cid;
    string title;
    string description;
    string source;
    uint value;
    uint valueOriginalCurrency;
    string originalCurrency;
  }

  struct Metadata {
    string name;
    string description;
    string longDescription;
    string image;
    string[] media;
    string[] model3d;
    string[] attributeNames;
    string[] attributeValues;
  }

  struct ContractCombination {
    address controllerContract;
    address accessControlContract;
    address metadataContract;
  }

  struct LatestMintableVersion {
    uint versionNumber;
    address controllerContract;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./TypeLibrary.sol";

/// @title Vountain – Violin
/// @notice Manage the Violins

contract ViolinMetadata is Ownable {
  using Strings for uint256;

  IConnectContract connectContract;

  mapping(uint256 => RCLib.TokenAttributes) public _tokenState;

  constructor(address connectContract_) {
    connectContract = IConnectContract(connectContract_);
  }

  //Functions to check allowed contract for state changes:
  //-----------------------------------------------------
  modifier onlyAllowedContract(uint tokenID_) {
    address controller = connectContract.getControllerContract(tokenID_);
    require(msg.sender == controller, "Ownable: caller is not the allowed contract");
    _;
  }

  function readManager(uint256 tokenID_) public view returns (address) {
    return (_tokenState[tokenID_].manager);
  }

  function readLocation(uint256 tokenID_) public view returns (address) {
    return (_tokenState[tokenID_].violinLocation);
  }

  /// @param tokenID_ token ID
  /// @param owner_ new owner address
  function setTokenOwner(
    uint256 tokenID_,
    address owner_
  ) external onlyAllowedContract(tokenID_) {
    _tokenState[tokenID_].owner = owner_;
  }

  /// @param tokenID_ token ID
  /// @param manager_ new manager address
  function setTokenManager(
    uint256 tokenID_,
    address manager_
  ) external onlyAllowedContract(tokenID_) {
    _tokenState[tokenID_].manager = manager_;
  }

  // @param tokenID_ token ID
  /// @param exhibitor_ new exhibitor address
  function setExhibitor(
    uint256 tokenID_,
    address exhibitor_
  ) external onlyAllowedContract(tokenID_) {
    _tokenState[tokenID_].exhibitor = exhibitor_;
  }

  /// @param tokenID_ token ID
  /// @param artist_ new artist address
  function setTokenArtist(
    uint256 tokenID_,
    address artist_
  ) external onlyAllowedContract(tokenID_) {
    _tokenState[tokenID_].artist = artist_;
  }

  /// @param tokenID_ token ID
  /// @param violinMaker_ new violin maker address
  function setTokenViolinMaker(
    uint256 tokenID_,
    address violinMaker_
  ) external onlyAllowedContract(tokenID_) {
    _tokenState[tokenID_].violinMaker = violinMaker_;
  }

  /// @param tokenID_ token ID
  /// @param violinLocation_ new violin location address
  function setViolinLocation(
    uint256 tokenID_,
    address violinLocation_
  ) external onlyAllowedContract(tokenID_) {
    _tokenState[tokenID_].violinLocation = violinLocation_;
  }

  function getViolinByTokenId(
    uint256 tokenID_
  ) public view returns (RCLib.TokenAttributes memory) {
    return _tokenState[tokenID_];
  }

  /// @param docType_ specify the document type: PROVENANCE, DOCUMENT, SALES
  /// @param date_ timestamp of the event
  /// @param cid_ file attachments
  /// @param title_ title of the Document
  /// @param description_ description of the doc
  /// @param source_ source of the doc
  /// @param value_ amount of the object
  /// @param valueOriginalCurrency_ in which currency it was sold
  /// @param originalCurrency_ inital currency the item was sold
  /// @param tokenID_ token ID

  function createNewDocument(
    string memory docType_,
    uint256 date_,
    string memory cid_,
    string memory title_,
    string memory description_,
    string memory source_,
    uint value_,
    uint valueOriginalCurrency_,
    string memory originalCurrency_,
    uint256 tokenID_
  ) external onlyAllowedContract(tokenID_) {
    RCLib.Documents memory createdDocument;

    createdDocument.docType = docType_;
    createdDocument.date = date_;
    createdDocument.cid = cid_;
    createdDocument.title = title_;
    createdDocument.description = description_;
    createdDocument.source = source_;
    createdDocument.value = value_;
    createdDocument.valueOriginalCurrency = valueOriginalCurrency_;
    createdDocument.originalCurrency = originalCurrency_;

    _tokenState[tokenID_].document.push(createdDocument);
  }

  /// @param name_ event name
  /// @param description_ description of event
  /// @param role_ a role which is affected by the change
  /// @param attendee_ event attendees
  /// @param eventStartTimestamp_ timestamp of the event
  /// @param eventEndTimestamp_ timestamp end of the event
  /// @param eventType_ type of the event
  /// @param tokenID_ token ID
  function createNewEvent(
    string memory name_,
    string memory description_,
    RCLib.Role role_,
    address attendee_,
    uint256 eventStartTimestamp_,
    uint256 eventEndTimestamp_,
    RCLib.Tasks eventType_,
    uint256 tokenID_
  ) external onlyAllowedContract(tokenID_) {
    RCLib.Event memory createdEvent;

    createdEvent.name = name_;
    createdEvent.description = description_;
    createdEvent.role = role_;
    createdEvent.attendee = attendee_;
    createdEvent.eventStartTimestamp = eventStartTimestamp_;
    createdEvent.eventEndTimestamp = eventEndTimestamp_;

    if (eventType_ == RCLib.Tasks.ADD_CONCERT) {
      _tokenState[tokenID_].concert.push(createdEvent);
    } else if (eventType_ == RCLib.Tasks.ADD_EXHIBITION) {
      _tokenState[tokenID_].exhibition.push(createdEvent);
    } else if (eventType_ == RCLib.Tasks.ADD_REPAIR) {
      _tokenState[tokenID_].repair.push(createdEvent);
    }
  }

  /// @param name_ violin name
  /// @param description_ description of violin
  /// @param longDescription_ long description of violin
  /// @param image_ image uri to the asset
  /// @param media_ media_ uri to the asset
  /// @param model3d_ 3D model file of the asset
  /// @param attributeNames_ array of attributes based in NFT STandard
  /// @param attributeValues_ array of values based in NFT STandard
  /// @param tokenId_ token ID
  function changeMetadata(
    string memory name_,
    string memory description_,
    string memory longDescription_,
    string memory image_,
    string[] memory media_,
    string[] memory model3d_,
    string[] memory attributeNames_,
    string[] memory attributeValues_,
    uint256 tokenId_
  ) external onlyAllowedContract(tokenId_) {
    RCLib.Metadata memory metadata;

    metadata.name = name_;
    metadata.description = description_;
    metadata.longDescription = longDescription_;
    metadata.image = image_;
    metadata.media = media_;
    metadata.model3d = model3d_;
    metadata.attributeNames = attributeNames_;
    metadata.attributeValues = attributeValues_;

    _tokenState[tokenId_].metadata = metadata;
  }

  /// @param tokenId_ token ID
  function callTokenURI(uint256 tokenId_) public view virtual returns (string memory) {
    RCLib.Metadata memory meta = _tokenState[tokenId_].metadata;
    string memory imagePath = meta.image;
    string memory description = meta.description;
    string memory violinName = meta.name;

    string memory comma = ",";
    string memory attributes = "[";
    if (meta.attributeNames.length > 0) {
      for (uint256 i = 0; i < meta.attributeNames.length; i++) {
        if (i == meta.attributeNames.length - 1) {
          comma = "";
        }
        attributes = string.concat(
          attributes,
          '{"trait_type": "',
          meta.attributeNames[i],
          '","value":"',
          meta.attributeValues[i],
          '"}',
          comma
        );
      }
    }
    attributes = string.concat(attributes, "]");

    bytes memory dataURI = abi.encodePacked(
      "{",
      '"name":"',
      violinName,
      '",'
      '"description":'
      '"',
      description,
      '",',
      '"image": "',
      imagePath,
      '",',
      '"attributes": ',
      attributes,
      "}"
    );
    return
      string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
  }
}