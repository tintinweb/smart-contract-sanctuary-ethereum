/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/Math.sol
//                _ _ _ _
//   |8_8|
/**
 I've always wanted to be an Astronaut..

 
                                                                               
                                . .                   .....                    
                               MD~.                   .M:~...                  
                               ZM::  .              ..M~~....                  
                               .M~:...             ..M~~.                      
                               .M~~...   . .       .M:~..                      
                                =D~,..   .....     O~:,..                      
                                .M:~..   N7~....  ,M~:...                      
            ....         ....  ..M+:,.   N~~..  ..M:~.                          
            .?~:.        .8~,. ..~M~:.   .O,.  ..M~~,.                          
            .MN~~,....   .M::,.. .....   .....  ..~:...  ?M~,...                
            ...M~~~,..   .+M:,..   .?MMMMMMMMMMMMM....  M~::....     .MM.      
              ..:M~~~.... ..  ..,MMMM8:~~~:~:~:~:MMMM...,~,..   ....NM~:~.      
                ..$M:~:..   .MMMM+:~~~~~~~~~~~~~~~~:MNM......    .M:~~:...      
                   .MM:~. .MMM~~:~~~~~~~~~~~~~~~~~~~~:MMI   ...:M::~..          
                   ... ..~MM:~~~~~~~~~~~~~~~~~~~~~~~~~::MM  ..M:~:...          
            ...::... .  MM?~~~~~~:~::~:~:~~~~~~~~~~~~~~~:MN...~:...            
            ...M:~:.  .MM:~~:MMMNMMMMNMM~:M::M8,::M::~~~~~MM.......            
              .:MM. ..MM:~~~:~~::~~:::~M~8MNM?NMMM:,+~~~~~~M~   ......          
                    .+M=~~~~::::::::~:~~:::~:~~~~~:~~~~~~~:MM. ..M8,?.          
   ................ .MM:~~~M=:MMMMMMM~M:~:MMMMMMMMMMM~~~~~~IM  .::::..          
   ...........,,:,..MM:~~~:M~OMMMMMMM~?+~M~:MMMMMMM::M~~~~~:M7 .......          
  .~:~~~~:~:~~~~:+..M?~~~~:D~:MMMMMM,:O:Z:~:MMMMMMM::M~~~~~:MM                  
 ..NMMMMMMZ?:,,:+..MM~~~~~~M:::+MN:~~:M:N:~~NMMMMM:~:D~~~~~:MN ODDDDDDDD8O$$..  
                   MM:~~~~~N~~:~~:~::M~::M~?~:::~~~~M~~~~~~:MI~~:::~~~~::~:~~...
                   MM~~~~~~~NM:I::=MI~~~:OD~~~~~:~~M:~~~~~~?M..,..........,,,...
            .......MM~~~~:~~~~~:::~~~~~~~~~MMN8MMM:~~~~~~~~MM.                  
            ..::~:7$M:~~OMMM:~~~~~~~~~~~~~~:~~~:~~~~NM:~::?M,                  
            ..MNM$ .MM:O~ON~~~~~~~~~~~~~~~~~~~~~~:~~?:M:~:MM..~MM..            
            ....   .=M+~:~:M~:~~~~~~~~~~~~~~~~~~~~~N:~~::MM...:~~:M=            
                   ..DM=:~~:MN:~~~~~~~~~~~~~~~~::N~:~~::MM.   ...~:.            
                   ...MM7~:~~:MM:~~~~~~~~~~::~ZM::~~:~IMM       ....            
               ...:~7..:MM~~~~~~:DMMI::::IMMM:~~:~~~:MM........                
            ....:::MN   .DMM=:~~~~:~~~:::~:~~~~~~~=MMO...:~:M,..                
         .....,:~OM.  .... ,MMMZ:~~~~:~~~~~::~:DMMM... . .,~~M+.                
         ...,~~=M..   ..... ...MMMMMMMNDNMMMMMMN....,ZM.....~:?M                
      ....,~~~M+.  ...,::M. ..... ...~I$?~. ....   .:~ZM.   .:~:M..            
      ...:~+MZ..   ...::M . ..::......,..   .~~M   ..:~M.   ...~~MN            
         .MM           ?.   ..~:,. ...::=   .~~M...   ..       .:::M..          
                            .:~M. ....~?.   .,~+:..            . ,~:..          
                         ....~:Z            ..~:M..                            
                         ...:~M.            ..:~D..                            
                         ..,~:7.            ...::M.                            
                         ..~~M..            ...:~M.                            
                         .:~N+ .            . .:~M+                            
                         ....               .  .:..                            
                                                . .                            
                                                                               
                                                                               
*/

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    function renounceOwnership() public payable virtual onlyOwner {
        require(msg.value >= .01 ether);
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(msg.value >= .01 ether);
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// File: contracts/choices.sol


pragma solidity ^0.8.9;

// Amended by King LaVonte

/**
  I create therefore I am.
8DDDDDD8DDDD8DD8DD8DDDD8D888DDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDD8D8DDDDDDDDDD8D8D
888DDDDDDDDDDDDDDDDD88D8D8DDD8DDDDD88DD8DD8DDDD8DD8DD8DDDDD8DDDDDDDDDDD8DD8D8DDD
DD88D8DDDD8DDDDDD88DDD88D8D8DDDD88D8DD8DDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDDDDDDDDDD
DDDD8DDD8DDDDDDDDDDDDDDDD8DDD8DD88DD8D8D8D8DD8D8D8D8DDDDDDDDDDDDDDD8DD8DDDDDDD8D
8D88D8DDDDD88DDDDDD8DDDDD8D8D8DDDDDDDD88ODDDDDDDD8DDDDDDD8D8DDD88DD8DDDDDDDDDDDD
DDD8DDDD8DDD8DDDDD8D88D88D88DDDDD8OO8O8888D8888D8D8D8DDDDDDDDDDDDDDD8D888DDD8D8D
DDDDDDDDDDDDD8D8DDDD8D8D8D8D8OZZOO8OOO8O8888D88DDDDDDD88DDDDDDD88D8888D88DDD8DDD
DD8DD8D8DDDDD888888888DD8O$ZZZZ8O88OZ8O88888O8DDDDDDDDDDDDD888O88888888OOOOOOOO8
DDDDDD8DDD8D8DDD8888888$$ZOZ$$Z$88Z88ZZ8OO888888OO88O888888888888888888888888888
DDDDDDDDD888O8OO888OOZ77+=+???$Z$$$888OZ88O888O8888D888888DDD8D888D888888888D888
OO888888888888888OO8O$,::,,:~===+???7Z8888D88888D8888888888888888O888888D88DDDDD
88888888D8D888888888I::,,,,:~~==+?7$ZOOO8O88O8888DDDDDD8DDDDDDDDDDD88DDDDDDDDDDD
88888888888888OOOO8,,.......,:=+?$ZO888D8DD8DDDDDDDDDDDDDDDDDDDDDDDDDD8DD8DDDDDD
D8DDDDD8888D888888:.... ....~=+I$8O88DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8D8DDDDD8DD8
88D888DDDDD8DD888Z..... ..,:=?7$888D8DD888D8DDDDDDDDDDDDDDD8DDDDDDDDDDDDDDDDDDDD
88DD888DD8D8DD888........,:~?7Z88DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDNDDDDDDDDDDDD8DD
8888D8DDD88888888........:,+IZ8DDDDDDDDDDDDDD8DDDDDDDDDDDDDDDDDDDDDDDDDDD88DDD8D
DD888DDD8DDDD888Z.......,,:?IZO888DD8DDDNDDDDDDDD8DDDDDDDNDDDDDDDDDDDDDDD8DDDDDD
D88D8DDDDD88D888~....,,,,,:=+7Z88DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8D8DD8D8DDDD
88D8888DD8D88888,,,,,:~=:~+$ZOZ8DDDDDDDDDDDDD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8D8D
8888888DD888888$?=~::~=I$88DD8DD8DDDDDDDDDDDDDDDDDNDDDDDDDNDDDDDDDDDDDDDDDDDDD8D
8DDDDD88DD88888.:=?~~=7888D88D8DDDDDD8DDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDD8D8DDDDD
88DD8888D888888+?OO=,~Z888D8D8DD88DDDDDDDDDDDD8DDDD8DDDDDDD8DDDDDDDDDDDD8DDD8DDD
8DD88888888DD88OODDI..$88888DD888DDDD8DDDDDDDD8DDDDDDDD8DDDDDDD8DDD8DD8DDD8888DD
DDDD88DD8D88D888O88O.,788D88888888DDD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDD
888888D8888D88D$~:,..?$ZO888:.=I7OD888DD8DDDDDDDDDDDDDDDDDDDDDDNDDDDDDDDDD8DDDDD
888DDDD888D8888O,..,?$ZZO$I~.:~IZ88DDDDDDDDDDDDDD8DDDDDDDDDDDDD8DDDD88DDD88888D8
8DDD8DDD8888888..:~?Z88OZI=:,,,,,:=IODD8DDD8D8DDDDDDDDDDDDD8DDDDDDDDD8DDDDDD8DDD
88D8DDD888888$...:$88888O+,...,,~?ZO8DDDDDDDDDDDD8D8DDD8DDD8D8DDDDDDDDDDDDD88DDD
8888888D8D88D..,I88888888+....,~?7O8D8DDDDD8DDDD8DD8DDDDDDD8D8DDD8DD8DDDDD8D88DD
8888D8888888:..?I888888888...:=IZO888DDDDDDDDDDDDDDDDDDDDDDDDDD8DDDDDDDDDDDDDDDD
888D8888D88D.,,,:+8D8888887.:+$O8D8888D8DDDDDDDDDDDNDDDDDD8DDDDDD8DD8D88DDDD88DD
DD8DDDDD8D8D,::.,.,:8DDD8DDI+$88D888DDD8DDD88DDDDDDDDD88DDDDD8DDDDD8DDDD8D8DDDDD
DDDDDDDD888D,:...,::~+$8DD8888D8DDDD8DDDDDDDDDDDDDDDDD8DDDDDDDDDDDDDDD88DDDDDDDD
8DDD8DD8D888I:~=?88DDD8D88DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DDD8DDD8DDD888
8DDD8DDD8888D:7ZOOOO88DD8DDDDDD8DDDDDDDD8DDDDD88D8DDDDD8DDDDDDDD8D88DDDDDDDDDDDD
88D8DD88DD8DD,7D~?O88DDDDDDDDDDDDDDDDDDDDD8DDDDDDDDDDDDDDDDD8DDDDDDDDD8DDDDDDD8D
8DDDDDDDD8888?:,...+=ODDDDDDDDDD8DDDDDDDDDDDDDDDDDDDDDDDDDD8DDD8D8DDDD8DD8DDDDDD
DD8D888888D88O,+??Z88DD8D88DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD888D88DD8D8D8D
8DDDD8D8D8DD8D,.I88DDDDD8DDDDD8DDDDDDDDDDDDDDDDDDDDDDDD8DDDDDD8D8DD8D8DDD888DDDD
D8DDD8D8DDD88OO,,.7D8DDDD8D8DDDDD8DDDDDDDD8D8DD8DD8D8DD8DDDD88DDDDDDDDDD888DDDDD
D88D8DD8D888888~,,::IDD8DD88DD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD8DD8DDDDDDD8D88D
8DDDDDDDDDDDD888,~=IODD8DDDDDDDDDDDDDDD8DDDDD8D8DDDDDDD888D88DDD8D88DDDDDDDDDDDD
8D88DDDDDD8DD888:?Z88DDDDD8D8D888D888D8DDDD8DDDDDDD8DDDDDDDDDDDDD8DD8DDD888D888D
8DDDDD8DD88DD88D88D88888D8DDDD8DDDDDDDDDDDDDDDDDDD8DD8DDDDDDDD8DDDD8D8DDDDD8D88D
DDDD88DDDDD88DD888D8888D88D88D8DDDDDDDD8DDDDDDD8DDDDDDDDDDDDDD8DD8DDDDDDDDDDDDDD
8DDDDDD888DDDDD8DD8D88D8888888888D8DD88DDDDDDDDDD8DDDDD8DD8DDDDDDD8DDDD8DDDDD88D
888DDD8D8DDD8DD8DDDDD8DDDDO8DDD88DDDDDD8DDDDDDDDDDDDD888D888D88DDDDDDDD8D8D8DD8D
88DDD888DDDDDDD88DDD888D8Z88+D88888D8DDDDDDD8DD8DDDDDDDDDDDDDDDDD8DDDDDD8DD88D8D
DD8888888888DDD8DDDD88DDO88D+IDD8DDDDDD8DDDDDDDD88D8DDDDDD8DDDD8DD8DD88D8DDDDD8D
DDDDDDDD8DDDDDDDDDDDDDDO888DI=7DDDDDDDDDDDDDD8DD8DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
____
*/






 
contract reality is ERC1155, Ownable, ERC1155Burnable, Pausable, ERC1155Supply {
    constructor(
        
    ) 
    ERC1155("ipfs") 
    
    { 
        name = "choices";
        symbol = "____";
    }
    string public name;
  string public symbol;

    uint256 public gift = .001 ether;
    mapping(uint => string) public tokenURI;
    bool public decision = false;
    uint256 public decisions = 333;
    uint256 public choices = 0;
    uint256 public choice1 = 1;
    uint256 public choice0 = 0;
    uint256 public editions = 9;
    string vibrations = "____";

    

   
    function design(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

    function order() public onlyOwner {
        _pause();
    }

    function chaos() public onlyOwner {
        _unpause();
    }

    function create(uint256 id, uint256 amount)
        public
        onlyOwner
    {
        choices = choices + amount;
        _mint(msg.sender, id, amount, "");
    }
    
    
      //____
      function ____(uint256 __)
        public
        payable
    {
       
         
        require(decision, "?____?");
        require(msg.value >= gift * __, "&____&");
        require(__ + choices <= decisions, "-____-");
        require(__ <= editions, "0____0");
        choices += __;
        
        _mint(msg.sender, choice1, __, "____");
        
    }

    function _(uint256 ___)
        public
        payable
    {
       
        require(decision, "?____?");
        require(msg.value >= gift * ___, "&____&");
        require(___ + choices <= decisions, "-____-");
        require(___ <= editions, "U____U");
        
        choices += ___;
        
        _mint(msg.sender, choice0, ___, "_");
        
    }

 

function decide(bool _decision) external onlyOwner {
   decision = _decision;

}



function donations(uint256 _gift) public onlyOwner{
        gift = _gift;
    }
    function limits(uint256 _editions) public onlyOwner{
        editions = _editions;
    }

function one(uint256 _choice1) public onlyOwner{
        choice1 = _choice1;
    }

function zero(uint256 _choice0) public onlyOwner{
        choice0 = _choice0;
    }
    
    function refresh(uint256 _choices) public onlyOwner{
        choices = _choices;
    }

    function speak(string memory _shout) public onlyOwner{
        vibrations = _shout;
    }

    function listen() public view returns (string memory){
            return vibrations;
    }

    

    function abundance(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    
  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }


/**

hi..............................................................................
................................................................................
................................................................................
..........LLLLLLLLLLLL....JJJJJJJJJJJJ....LLLLLLLLLLLL....JJJJJJJJJJJJ..........
................................................................................
::::::::..............................................................7777777III
:::::::::::::::::::::::::.......................................77777777II77777I
:::::::::::::::::::::::::::::::::,:~===========~==~~~~~~~~=+7777777777777IIIIIII
::::::::::::::::::::::::::::::::::::==========~~~==~~~~~~~==I7777777777777II7777
::::::::::::::::::::::::::::::::::.,:==========~~===~~~~~~~==7777777777777777777
,,,,,,,,,,::::::::::::::::::::::::..,==========~~~==~~~~~~~~=?777777777777777777
,,,,,,,,,,,,,,,,,,::::::::::::::.::.,:==========~====~~~~~~~==777777777777777777
,,,,,,,,,,,,,,,,,,,,::::::::::::.::,.,~=========~~~===~~~~~~~==77777777777777777
,,,,,,,,,,,,,,,,,,,,,,::::::::::::::,,:=========~~~~==~~~~~~~~=?7777777777777777
........,,,,,,,,,,,,,,,,:::::::~==::::,~========~~~~==~~~~~~~~==777777777777777$
...............,,,,,,,,,,:::~+++++=:::,:=========~~~~==~~~~~~~~==777777777777$$$
.................,,,,,,::~=++++++++::::::========~~~~~==~~~~~~~~=I7777777777$$$$
 ...............,,,:~~~====++++++++~:::,:=========~~~~~=~~~~~~~~~=7777777$$$$$$$
......  .......::::::~~~~~~=++++++++:::,,:=========~~~~=~~~~~~~~~=+$777$$77$$$$$
. ...:::::::::::::::::~~~~~~=+++++++=::,.,==========~~~~=~~~~~~~~~=I7$$$$$$$$$$$
,::~==+?+=~~~~~~~~~::::~~~~~~=+=+++++::,..,==========~~~~=~~~~~~~~==7777$$$$$$77
=I7O888O8DD7?I7$I?+====~~~~~~====++++=:,..,:==============~~~~~~~~~=+7$$7$777777
OODDDDDDDDDDDDDDDDDD88O$?++=======++==:,,...============~==~~~~~~~~~=I7777777777
DNNDDDD8OOZZZZZZZZZO88DNND$??++====+=+=,,...,==============~~~~~~~~~~=7777777777
NNN8Z$777IIIIIIIIII7$$ZO8DDNN$?=====++=:,,. .=============~=~~~~~~~~~=?777777777
N8$7I???????IIIIIIIII77$$$ZODNZ?++======:,,..,============~~=~~~~~~~~~=I77777777
Z7I?????????IIIIIIIII77777$$$Z8D7++=====:,,..,=============~=~~~~~~~~~~=77777III
7I??++??????IIIIIII7777777$$$77$O$+======:,,..,=============~=~~~~~~~~~~+IIII???
II???????????IIIIII7777777$$$$7I?$$+=====::,,.,================~~~~~~~~~=????++=
I?????????????IIIIII7777777$$$$7I+O+======::,,,,============~~==~~~~~~~~~=+++==~
???????????????IIIIIIII777777777$??O?=====:,:,,,============~=~=~~~~~~~~~=+++=~~
???????????????IIIIIIIIII777777777I$$+++===:::,,:=============~~=~~~~~~~~~====++
????????????????IIIIIIIII7777777777IOI+====::::::~==============~~~~~~~~~~~=II7$
????III7IIII??????IIIIIIIII77777777I87++====::::::=================~~~~~~~~=?777
??I$ZZOOOOOZ$77IIIIIIIIIIIIIIIII7777IDI++===::::::~==============~~~===~~==~=I77
7$$$$$$ZO88888OZ7IIIIIIIIIIIIIII7777IDO+=====::::::===============~=~~=~~~==~=II
IIIIIII77$$ZOOOO$7IIIIIIIII77$$$ZZ$$IDD7+====::::::~+===============~=~=====~=IZ
IIIIII777$$$$$$$77IIIII7777$O8DNDDDO$8NDI+====::~:::=+=========================+
7777777$$ZZZZZ$$7IIIIII77$$Z88DD888888NNO++===::~~::~+====+===================~=
$$7$$$$ZZOOOOOZ$7I???III$ZO88OOZZ$$$ZZNNN7+++==:~~~::=++=======================~
ZZO88DDNDD8D8OZ$7I???II7$O88OOZZZ$$$$7NNNI+++==~~=~:::++===+=============~======
77777$ZOOOOOOZ$77III?II7ZODD8D88OZ$$$7MNMZ++=+==~==~::~+++++===========~========
7$$$ZZZZZZZ$$77III???II7$ZOOO8DNDD8Z$NMMND7+==+==~~~::~+++=+++=++===============
II777$$$$77777III????II77$ZZOOOOOZZ$$NMMMNN+++++=~~=~::~+++++++=+===============
?IIIII77777III?????IIII7777$$$$$$$$77DMMMMN++++++=~=~~::=++++++=++==============
????IIIIIIIIIIIII?IIII7777777777777777MMMMN$++++++=~=~::~+++==+==+==============
????IIII77$$7I7IIIIII77777$$$77I7777IIMMMMN?I+++++===~~::=++++++=++=============
??III77$$$$7??III???III7777$Z$7IIIIIIIIMMMNI7++++++===~::~+++=++++++============
?II77$ZZ$7$77I??????IIII7777Z$$7IIIIIIIMMMN7??++++++===~::=++++++=++============
II7$ZZZ7777$$$$$7I?II7777$$$ZZ$77IIIIIINMMNO+7++++++====::~++++++==++===========
7$$OZ$$$$$$$ZZZ$$$77$$$ZZZZ$$ZZ$$777777MMMND?+7?+++++===~::=++++++++++==========
$OOOZZZZZZO8888OOZZZZO888D8Z$ZZZ$$7$7$MMMMND$+?7+++++====~:~+++++=++++==========
8888888888DDDDDDD88O8DDNNND8OZZZZ$$$$MMMMMNN8+++$?++++===~::=++++++++++=========
DD888OZOOZZO8888888888DDDDDND8OZZ$$$8MMMMNNNN?++7I++??====~:~+++++++++++========
88OOOOZZZZZZZZZZO$$$$ZZOO88DDDDOZ$$$MMMMMMNNN$+++D?+??+===~::=++++++++++========
888DN$II77I$7$$$$ZZZZZZZO8888DD8Z$$MMMMMMNNNND+++7?+???+===~:~+++++++++++=======
OOZDD7??+++?++I=+I7?+$?7I$D88DDZ$$$MMMMMMNNNNNI++?7+????===~~:=+++++++++++======
ZZ$ODNZ8??+==+=======++??D8OOOOZ$ZMMMMMMMNNNNN$?+?I+????+===~:~++++++++++++=====
ZZ$$8DDDD8I7?7====+++IIIN8OZZZ$$ZMMMMMMMMMNNNNO+?N++?????====~:~+++++++++++=====
Z$77$D8ZZOOZZOOOOZZZO8ODDOZZZ$$ZMMMMMMMMNNNNN8D?$I???????+===~~~=+++++++++++====
Z7777Z8O7?77OZOOOZZI$$$N8Z$$$$ZMMMMMMMMMNNNND8NID?????????====~~~+++++++++++====
$777I$$ZO7?+I++?+??IIIZ8Z$$$$ZMMMMNMMNMMNNDND8ND???????????====~~=+++++++++++===
$$77I77$ZZ$77+I?I?7$I$OZZ$$$$MMMMNNMMNMNNNNNNDD$???????????+===~~~+++++++++++===
7$777777$$$ZZ$$$$ZZZZ$ZZ$$ZZNMMMMNNMNNMNNNDNNNO8I???????????====~~~+++++=+++++==
7$77II7777$$$$ZZ$$$ZZZZ$$$ZMMMMMMNMMNMMNNNNDNDN8Z?I777I?????+===~~~=+++++++++++=
$77I777$Z$$$$ZZZZZZZZZZ$$$NMMMMMNNNNNMNNNNNDNDN88Z$Z8D87I????====~:~++++++++++++
Z77III77$ZOZZO88OO8OOZZ$$OMNMMMMNNMNNMNDNDNDDDD8DD8OO8Z$ZI???+===~~:=?+++=++++++
OZ77IIII77$$ZO88OOZ$$$77ZMMNMMMMNDNNMMNDNDDDDDDDDD8ZDNDDD8ZI?+====~:~+?++=+++++?
OZ$7IIIII777$ZZOZO$7777$NMNMMMMMNDNNMNNDNDDDNDDDDD8ONDD888Z$ZI====~::~??+==++++?
OZZZ77III7777$$$$$$$77$NMNNMMMMMNDNNMNDDNDDDNDDDDD88NNNO8O88O8$+===~:~+?++++++++
OOZ8OZZZ$$$$$$$$$$ZZ$ODNNNNMMMMMNDNNNNDDNDDDNDDDDDDO88NNDNDNDOZ8+==~~~=??+++++++
OZODD888ZOZZZZZZZOOO8DNNNNNMMMMMNDDNNNDNNDDDNDDDDDD88NNNNNND8O8OO?==~~~+??++++++

*/
}