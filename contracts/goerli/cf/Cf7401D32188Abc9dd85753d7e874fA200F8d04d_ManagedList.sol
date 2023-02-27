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

pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ManagedList is ReentrancyGuard, Ownable {
    using Strings for uint256;
    bool public contractPaused = false;
    uint256 public batchCounter = 0;
    uint256 public priceToCreateBatch = 0.05 ether;
    uint256 public defaultOwnerPercentage = 10;
    mapping (uint256 => Batch) public batchesList;
    mapping (uint => mapping (address => bool)) public managers;
    mapping (uint => mapping (address => string)) public notes;
    mapping (uint => mapping (address => uint256)) public whitelist;

    struct Batch {
        uint256 id;
        address creator; // msg.sender
        address paymentAddress; // address to receive payments
        bool paused; // this can pause and unpause the addition of whitelist spots to this batch
        string name; // name of the batch
        uint256 fee; // % of whitelist sale amount that gets paid to this contract
        uint256 price; // cost to be added to whitelist
        uint256 maxSpots; // max number of spots available on this collab
        uint256 spotsTaken; // number of spots taken on this collab
        uint256 spotsPerWallet; // number of whitelist spots available per wallet
        string externalId; // provided by the external system
    }

    struct Spot {
        uint256 batchId;
        address whitelistedAddress;
        uint8 quantity;
        uint256 spotsTakenTotal; // The new value of taken spots after this spot is added
        uint256 spotsTakenByWallet; // The new value of taken spots by this address after this spot is added
        string externalId; // same value as the batch external id
    }

    event BatchCreated(Batch batch);
    event SpotReserved(Spot spot);

    constructor() {

    }

    modifier isManager(uint256 _collabId) {
        require(managers[_collabId][msg.sender] == true || batchesList[_collabId].creator == msg.sender || msg.sender == owner(), "You are not a manager of this batch");
        _;
    }

    function unpauseContract() public onlyOwner {
        contractPaused = false;
    }

    function pauseContract() public onlyOwner {
        contractPaused = true;
    }

    function updateDefaultOwnerPercentage(uint256 _newPercentage) public onlyOwner {
        require(_newPercentage <= 100, "Percentage cannot be greater than 100");
        require(_newPercentage >= 0, "Percentage cannot be less than 0");
        defaultOwnerPercentage = _newPercentage;
    }

    function updatePriceToCreateBatch(uint256 _price) public onlyOwner {
        priceToCreateBatch = _price;
    }

    function createBatch(string memory _externalId, string memory _name, uint256 _price, uint256 _maxSpots, uint256 _spotsPerWallet, address _paymentAddress) public onlyOwner nonReentrant {
        require(contractPaused == false, "Contract is paused");
        require(_spotsPerWallet > 0, "You must allow at least 1 spot per wallet");
        require(_maxSpots > 0, "You must allow at least 1 spot");
        require(_paymentAddress != address(0), "You must provide a payment address");

        batchesList[batchCounter] = Batch({
            id: batchCounter,
            externalId: _externalId,
            creator: msg.sender,
            paymentAddress: _paymentAddress,
            paused: true,
            name: _name,
            fee: defaultOwnerPercentage,
            price: _price,
            maxSpots: _maxSpots,
            spotsTaken: 0,
            spotsPerWallet: _spotsPerWallet
        });
        emit BatchCreated(batchesList[batchCounter]);
        batchCounter++;
    }

    function deleteBatch(uint256 _collabId) public nonReentrant onlyOwner {
        delete batchesList[_collabId];
    }

    function addManager(uint256 _collabId, address _manager) public nonReentrant isManager(_collabId) {
        managers[_collabId][_manager] = true;
    }

    function removeManager(uint256 _collabId, address _manager) public nonReentrant isManager(_collabId) {
        delete managers[_collabId][_manager];
    }

    function addNote(uint256 _collabId, string memory _note) public nonReentrant isManager(_collabId) {
        notes[_collabId][msg.sender] = _note;
    }

    function updatePaymentAddress(uint256 _collabId, address _paymentAddress) public {
        require(_paymentAddress != address(0), "Payment address cannot be 0");
        require(batchesList[_collabId].creator == msg.sender || msg.sender == owner(), "You must be the creator of this batch to add a payment address");
        batchesList[_collabId].paymentAddress = _paymentAddress;
    }

    function pauseBatch(uint256 _collabId) public isManager(_collabId) {
        batchesList[_collabId].paused = true;
    }

    function unpauseBatch(uint256 _collabId) public isManager(_collabId) {
        batchesList[_collabId].paused = false;
    }

    function getBatchById(uint256 _collabId) public view returns (Batch memory) {
        return batchesList[_collabId];
    }

//    function getWhitelistByBatchId(uint256 _collabId) public view returns (string[]) {
//        string[] memory whitelistArray = new string[](batchesList[_collabId].spotsTaken);
//        uint256 counter = 0;
//        for (uint256 i = 0; i <= batchesList[_collabId].spotsTaken; i++) {
//            whitelistArray[counter] = whitelist[_collabId][i];
//            counter++;
//        }
//    }
//
//    function getNotesByBatchId(uint256 _collabId) public view returns (mapping (address => string) memory) {
//        return notes[_collabId];
//    }

    // TODO if they own 20+ OGs, make it free (flexible) (to work out deals with partners)
    // TODO fetch number of spots taken for a batch
    // TODO fetch number of unique wallets on a batch whitelist
    // TODO fetch all collabs and return them as an array, include the name and id at least
    function fetchBatchNamesAndIDs() public view returns (string[] memory) {
        string[] memory collabNames = new string[](batchCounter);
        for (uint256 i = 0; i < batchCounter; i++) {
            collabNames[i] = string.concat(Strings.toString(batchesList[i].id), " : ", batchesList[i].name);
        }
        return collabNames;
    }

    function getMyBatchIDs() public view returns (uint256[] memory) {
        uint256[] memory batches = new uint256[](batchCounter);
        uint256 counter = 0;
        for (uint256 i = 0; i < batchCounter; i++) {
            if (managers[i][msg.sender] == true) {
                batches[counter] = i;
                counter++;
            }else if(batchesList[i].creator == msg.sender) {
                batches[counter] = i;
                counter++;
            }
        }
        return batches;
    }

    function getBatchesManagedByAddress(address _manager) public view returns (uint256[] memory) {
        uint256[] memory batches = new uint256[](batchCounter);
        uint256 counter = 0;
        for (uint256 i = 0; i < batchCounter; i++) {
            if (managers[i][_manager] == true) {
                batches[counter] = i;
                counter++;
            }else if(batchesList[i].creator == _manager) {
                batches[counter] = i;
                counter++;
            }
        }
        return batches;
    }

    function reserveSpot(uint256 _collabId, uint8 _requestedSpotQuantity) public payable nonReentrant {
        uint256 ownedAndRequested = whitelist[_collabId][msg.sender] + _requestedSpotQuantity;
        require(batchesList[_collabId].paused == false, "This batch is paused");
        require(msg.value >= batchesList[_collabId].price * _requestedSpotQuantity, "Not enough ETH sent");
        require(ownedAndRequested <= batchesList[_collabId].spotsPerWallet, "You cannot own more than the max spots per wallet");
        require(batchesList[_collabId].maxSpots >= batchesList[_collabId].spotsTaken + _requestedSpotQuantity, "No more spots available");
        whitelist[_collabId][msg.sender] += _requestedSpotQuantity;
        batchesList[_collabId].spotsTaken += _requestedSpotQuantity;
        address payable _to = payable(batchesList[_collabId].paymentAddress);
        uint256 amount = msg.value * (100 - batchesList[_collabId].fee) / 100;
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to complete transaction");
        emit SpotReserved(Spot({
            batchId: _collabId,
            whitelistedAddress: msg.sender,
            quantity: _requestedSpotQuantity,
            spotsTakenTotal: batchesList[_collabId].spotsTaken,
            spotsTakenByWallet: whitelist[_collabId][msg.sender],
            externalId: batchesList[_collabId].externalId
        }));
    }

    function addFreeSpots(uint _batchId, address [] memory _addresses, uint8 _quantity) public nonReentrant isManager(_batchId) {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelist[_batchId][_addresses[i]] += _quantity;
            batchesList[_batchId].spotsTaken += _quantity;
        }
    }

    function checkMyWhitelistSpots(uint256 _collabId) public view returns (uint256) {
        return whitelist[_collabId][msg.sender];
    }

    function checkWhitelistSpotsForAddress(uint256 _collabId, address _address) public view returns (uint256) {
        return whitelist[_collabId][_address];
    }

    function withdraw() public onlyOwner nonReentrant{
        (bool owner, ) = payable(owner()).call{value: address(this).balance}("");
        require(owner);
    }
}