// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//      _                 ____            _           _
//     / \   _ __   ___  |  _ \ _ __ ___ (_) ___  ___| |_ ___
//    / _ \ | '_ \ / _ \ | |_) | '__/ _ \| |/ _ \/ __| __/ __|
//   / ___ \| |_) |  __/ |  __/| | | (_) | |  __/ (__| |_\__ \
//  /_/   \_\ .__/ \___| |_|   |_|  \___// |\___|\___|\__|___/
//          |_|                        |__/
//
// https://apeprojects.info/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface WarmWallet {
    function balanceOf(address contractAddress, address owner) external view returns (uint256);
}

/// @title ApeProjects is a contract to record projects and possible discounts for BAYC and MAYC owners.
/// @author Darrel Herbst
/// @notice You can see the projects on the web at the _website https://apeprojects.info
contract ApeProjects is Ownable {

    address public _baycaddr;
    address public _maycaddr;
    address public _warmaddr;
    bool public _paused;

    /// @notice _website is where you can view the projects on the web
    string public _website;

    uint256 public _numProjects;
    mapping(uint256 => mapping(string => string)) public _projects;
    mapping(uint256 => address) public _projectOwner;

    /// @notice _allkeys is the list of keys needed to create a project, and the list of keys rendered in getProject.
    string[] public _allkeys;

    /// @notice _adminkeys are keys that cannot be set by users, only the contract owner can set these keys.
    mapping(string => bool) public _adminkeys;

    /// @notice ProjectCreated event is emitted from createProject holds the project id created and the address that created the project.
    event ProjectCreated(uint256 id, address creator);

    /// @notice ProjectEdited event is emitted when a project is changed.
    event ProjectEdited(uint256 id);

    /// @dev constructor with initial configuration
    constructor(address baycaddr, address maycaddr, address warmaddr, string[] memory allkeys, string[] memory adminkeys, string memory website) {
        _baycaddr = baycaddr;
        _maycaddr = maycaddr;
        _warmaddr = warmaddr;
        _website = website;
        for (uint i=0; i < allkeys.length; i++) {
            _allkeys.push(allkeys[i]);
        }
        for (uint i=0; i < adminkeys.length; i++) {
            _adminkeys[adminkeys[i]] = true;
        }
    }

    /// @notice pause will toggle the _pause variable. When false, the contract is not usable. Only the contract owner can call this.
    function pause() public onlyOwner {
        _paused = !_paused;
    }

    /// @notice setWebsite sets the _website variable, only the contract owner can call this.
    function setWebsite(string calldata website) public onlyOwner {
        _website = website;
    }

    /// @notice isAnApe returns true if the caller owns a BAYC or MAYC.
    /// @param caller is a wallet address
    /// @return true if the caller owns a BAYC or MAYC
    function isAnApe(address caller) public view returns (bool) {
        if (WarmWallet(_warmaddr).balanceOf(_baycaddr, caller) > 0) {
            return true;
        }
        if (WarmWallet(_warmaddr).balanceOf(_maycaddr, caller) > 0) {
            return true;
        }
        return false;
    }

    /// @notice keyIndex returns true and the index in _allkeys if the key exists, false if it is not an approved key.
    /// @param key is a key to check
    /// @return bool if the key is an approved key
    /// @return uint256 the index in the _allkeys array
    function keyIndex(string calldata key) public view returns (bool, uint256) {
        for (uint256 i = 0; i < _allkeys.length; i++) {
            if (keccak256(bytes(key)) == keccak256(bytes(_allkeys[i]))) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /// @notice addAdminKey adds the key into the _adminkeys map, only the contract owner can call this.
    /// @param key is the key to add
    function addAdminKey(string calldata key) public onlyOwner {
        _adminkeys[key] = true;
    }

    /// @notice delAdminKey removes the key from the _adminkeys map, only the contract owner can call this.
    /// @param key is the key to remove.
    function delAdminKey(string calldata key) public onlyOwner {
        _adminkeys[key] = false;
    }

    /// @notice addKey adds a key into the _allkeys array, only the contract owner can call this..
    /// @param key is the key to add.
    function addKey(string calldata key) public onlyOwner {
        _allkeys.push(key);
    }

    /// @notice delKey removes a key from the _allkeys array, only the contract owner can call this.
    /// @param key is the key to remove
    function delKey(string calldata key) public onlyOwner {
        uint256 idx = 0;
        bool found = false;
        (found, idx) = keyIndex(key);
        if (found) {
            for (uint256 i = idx; i < _allkeys.length; i++) {
                _allkeys[i] = _allkeys[i+1];
            }
            _allkeys.pop();
        }
    }

    /// @notice getKeys returns the _allkeys array, which is used to render the project in getProject, and needed in createProject.
    /// @return string[] is the list of keys
    function getKeys() public view returns (string[] memory) {
        string[] memory keys  = new string[](_allkeys.length);
        for (uint i = 0; i < _allkeys.length; i++) {
            keys[i] = _allkeys[i];
        }
        return keys;
    }

    /// @notice createProject takes a list of keys and the list of values to create a project entry owned by the caller.
    /// @notice Emits ProjectCreated(id, creator address) event.
    /// @param keys is the list of keys that must match order and length of the _allkeys array
    /// @param vals is the list of values that correspond with each key.
    function createProject(string[] calldata keys, string[] calldata vals) public {
        if (msg.sender != owner()) {
            require(!_paused, "paused");
        }
        require(keys.length == _allkeys.length, "keys length mismatch");
        require(keys.length == vals.length, "keys length != vals length");
        require(isAnApe(msg.sender) == true, "Only apes");
        uint256 pid = _numProjects;

        for (uint256 i = 0; i<_allkeys.length; i++) {
            require(keccak256(bytes(_allkeys[i])) == keccak256(bytes(keys[i])), "Wrong key order");
            if (_adminkeys[keys[i]]) {
                continue;
            }
            if (keccak256(bytes(_allkeys[i])) == keccak256(bytes("owner"))) {
                _projects[pid][_allkeys[i]] = Strings.toHexString(uint256(uint160(msg.sender)), 20);
            } else {
                _projects[pid][_allkeys[i]] = vals[i];
            }
        }
        _projectOwner[pid] = msg.sender;
        _numProjects++;

        emit ProjectCreated(pid, msg.sender);
    }

    /// @notice getProject returns the list of keys and values for the project.
    /// @param id is the project id.
    /// @return retkeys is the list of keys
    /// @return retvals is the corresponding list of values
    function getProject(uint256 id) public view returns (string[] memory retkeys, string[] memory retvals) {
        if (msg.sender != owner()) {
            require(!_paused, "paused");
        }
        retkeys = new string[](_allkeys.length);
        retvals = new string[](_allkeys.length);

        for (uint256 i=0; i < _allkeys.length; i++) {
            retkeys[i] = _allkeys[i];
            retvals[i] = _projects[id][_allkeys[i]];
        }

        return (retkeys, retvals);
    }

    /// @notice editProject allows the project owner (the address that created the project) to add or modify a key's value.
    /// @param id is the project id
    /// @param key is the key being modified
    /// @param value is the new value assigned to the key
    function editProject(uint256 id, string memory key, string memory value) public {
        if (msg.sender != owner()) {
            require(!_paused, "paused");
            require(msg.sender == _projectOwner[id], "Not owner.");
            require(_adminkeys[key] != true, "Not admin");
        }

        _projects[id][key] = value;

        emit ProjectEdited(id);
    }

    /// @notice editProjectOwner can be used to overwrite the project owner address if the address has been compromised or lost.
    /// @notice There will be an off-chain process to decide when this should be done.
    /// @param id is the project id.
    /// @param newOwner is the new address to overwrite as the project owner.
    function editProjectOwner(uint256 id, address newOwner) public onlyOwner {
        _projectOwner[id] = newOwner;
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