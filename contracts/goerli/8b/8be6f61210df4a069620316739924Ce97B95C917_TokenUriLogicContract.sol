/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// File: @openzeppelin/contracts/utils/Base64.sol


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

// File: Interfaces.sol


pragma solidity ^0.8.17;


interface IMainContract {
    function getNickName(uint256 tokenId) external view returns (string memory );    
	function balanceOf(address account) external view returns(uint256);
    function getRewardContract() external view returns(address); 
}

interface ITraitChangeCost {
    struct TraitChangeCost {
        uint8 minValue;
        uint8 maxValue;        
        bool allowed;
        uint32 changeCostEthMillis;
        uint32 increaseStepCostEthMillis;
        uint32 decreaseStepCostEthMillis;
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

// File: TokenUriLogicContract.sol


pragma solidity ^0.8.17;






contract TokenUriLogicContract is Ownable, ITraitChangeCost{

    using Strings for uint256;

    IMainContract public MainContract;

	//bool _revealed = false;
	//string private _contractUri = "https://rubykitties.tk/MBBcontractUri";
    //string private _baseRevealedUri = "https://rubykitties.tk/kitties/";
	//string private _baseNotRevealedUri = "https://rubykitties.tk/kitties/";
    mapping(uint256 => uint64) public TokenIdDNA;
    mapping(uint8 => TraitChangeCost) public TraitChangeCosts;    

    constructor(address maincontract)  {
	MainContract = IMainContract(maincontract);
        // setChageTraitPrice(uint8 traitId,
        //      bool allowed, uint32 changeCostEthMillis, 
        //      uint32 increaseStepCostEthMillis, uint32 decreaseStepCostEthMillis, 
        //      uint8 minValue, uint8 maxValue)
        //setChageTraitPrice(0, true, 100, 0, 0, 0, 255); // undef
        setChageTraitPrice(1, true, 0, 0, 100*1000, 0, 4); // type
        setChageTraitPrice(2, true, 0, 50*1000, 0, 0, 2); // eyes
        setChageTraitPrice(3, true, 0, 20*1000, 0, 0, 3); // beak
        setChageTraitPrice(4, true, 1*1000, 0, 0, 0, 255); // throat
        setChageTraitPrice(5, true, 1*1000, 0, 0, 0, 255); // head 
        setChageTraitPrice(6, true, 0, 1*1000, 0, 0, 255); // level
        setChageTraitPrice(7, true, 0, 1*1000, 0, 0, 255); // stamina        
	}

	function setChageTraitPrice(uint8 traitId, bool allowed, uint32 changeCostEthMillis, uint32 increaseStepCostEthMillis, uint32 decreaseStepCostEthMillis, uint8 minValue, uint8 maxValue) internal  {
        require (msg.sender == address(MainContract) || msg.sender == owner());
        require (traitId < 8, "trait err");
        TraitChangeCost memory tc = TraitChangeCost(minValue, maxValue, allowed, changeCostEthMillis, increaseStepCostEthMillis, decreaseStepCostEthMillis);
		TraitChangeCosts[traitId] = tc;
	} 

    function randInitTokenDNA(uint256 tokenId) external {
        require (msg.sender == address(MainContract));
        uint64 dnaeye = uint64((block.timestamp * tokenId) % 1000);
        if (dnaeye <= 47)
            dnaeye = uint64(((block.timestamp * tokenId) % 1000)<<2*8);
        else
            dnaeye = 0;
        uint64 dnabeak = uint64((block.timestamp * tokenId) % 1000);
        if (dnabeak <= 7)
            dnabeak = ((3)<<3*8);
        else if (dnabeak <= 47)
            dnabeak = ((2)<<3*8);       
        else if (dnabeak <= 500)
            dnabeak = ((1)<<3*8);      
        else
            dnabeak = 0;                           
        uint64 dnathroat = uint64(((block.timestamp + tokenId) % 255)<<4*8);
        uint64 dnahead = uint64(((block.timestamp + block.difficulty + tokenId) % 255)<<5*8);
        TokenIdDNA[tokenId] = (dnaeye + dnabeak + dnathroat + dnahead);
    }   

	function getTraitValues(uint256 tokenId) internal view returns (uint8[] memory ) {
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        uint8[] memory traits = new uint8[](8);
        for (uint i = 0; i < 8; i++) 
        {
            uint64 shift = uint64(8 * i);
            uint64 bitMask = (TRAIT_MASK << shift);
            uint64 value = ((oldvalue & bitMask) >> shift); 
            traits[i] = uint8(value);           
        }     
        return traits;   
    }

	function getTraitValue(uint256 tokenId, uint8 traitId) public view returns (uint8 ) {
        require (traitId < 8, "trait err");
		return getTraitValues(tokenId)[traitId];
	}   

    function getTraitCost(uint8 traitId) public view returns (TraitChangeCost memory) {
        require(traitId < 8, "trait err");
        return TraitChangeCosts[traitId];
	}   

	function setTraitValue(uint256 tokenId, uint8 traitId, uint8 traitValue) public {
        require (msg.sender == address(MainContract));
        require(traitId < 8, "trait err");
        uint64 newvalue = traitValue;
        newvalue = newvalue << (8 *traitId);
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        for (uint i = 0; i < 8; i++) 
        {
            if (i != traitId)
            {
                uint64 shift = uint64(8 * i);
                uint64 bitMask = TRAIT_MASK << shift;
                uint64 value = (oldvalue & bitMask); 
                newvalue |= value;
            }
        }
        TokenIdDNA[tokenId] = newvalue;        
	}	         

    function getRgbFromTraitVal(uint8 traitval) internal pure returns (bytes memory) {
        uint r = (traitval >> 5);
        r = (r * 255) / 7;
        uint gmask = 7; // 0x07
        uint g = (traitval >> 2);
        g = (g & gmask);
        g = (g * 255) / 7;
        uint bmask = 3; // 0x03
        uint b = (traitval & bmask);
        b = (b * 255) / 3;
        return bytes.concat(
                                'rgb(',
                                bytes(Strings.toString(r & 255)), 
                                ',', 
                                bytes(Strings.toString(g & 255)), 
                                ',', 
                                bytes(Strings.toString(b & 255)), 
                                ')');
    }

    function getBirdEyes(/*bool crazy*/) internal pure returns (bytes memory) {
        return bytes.concat("<rect class=\"ew\" x=\"275\" y=\"200\" width=\"40\" height=\"40\" rx=\"3\" stroke-width=\"0.25%\" />",
                "<rect class=\"ey\" x=\"275\" y=\"220\" width=\"20\" height=\"20\" rx=\"3\" stroke-width=\"0.25%\" />",
                "<rect class=\"ew\" x=\"215\" y=\"200\" width=\"40\" height=\"40\" rx=\"3\" stroke-width=\"0.25%\" />",
                "<rect class=\"ey\" x=\"215\" y=\"220\" width=\"20\" height=\"20\" rx=\"3\" stroke-width=\"0.25%\" />");
    }  


    function getBirdLayout(uint8 shapetype) internal pure returns (bytes memory) {
        if (shapetype == 0) { // basic 
            return  bytes.concat("<path class=\"hd\" d=\"M170,480l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65\" stroke-width=\"2%\" stroke-linejoin=\"round\" />",
                    "<path class=\"th\" d=\"M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66\" stroke-width=\"0.15%\" stroke-linejoin=\"round\" />",
                    "<path class=\"bk\" d=\"M235,275l110,0l20,25l0,80l-10,-25l-120,0\" stroke-width=\"2%\" />");

        }
        else if (shapetype == 1) { // jay
            return  bytes.concat("<path class=\"hd\" d=\"M170,480 l0,-90l-35,-50l0,-155l-60,-120l140,0l20,5l80,80l6,10l0,176l-5,0l0,40l-40,40l0,65\" stroke-width=\"2%\" stroke-linejoin=\"round\" />",
                    "<path class=\"th\" d=\"M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66\" stroke-width=\"0.15%\" stroke-linejoin=\"round\" />",
                    "<path class=\"bk\" d=\"M235,275l110,0l20,25l0,80l-10,-25l-120,0\" stroke-width=\"2%\" />");
        }
        else if (shapetype == 2) { // whoodpecker
            return  bytes.concat("<path class=\"hd\" d=\"M170,480 l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65\" stroke-width=\"2%\" stroke-linejoin=\"round\" />",
                    "<path class=\"th\" d=\"M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66\" stroke-width=\"0.15%\" stroke-linejoin=\"round\" />",
                    "<path class=\"bk\" d=\"M245,285l225,0l-20,25l-75,35l-130,0\" stroke-width=\"2%\" />");

        }
        else if (shapetype == 3) { // eagle
            return  bytes.concat("<path class=\"hd\" d=\"M170,480 l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65\" stroke-width=\"2%\" stroke-linejoin=\"round\" />",
                    "<path class=\"th\" d=\"M172,480l0,-70l102,20l0,51\" stroke-width=\"0.15%\" stroke-linejoin=\"round\" />",
                    "<path class=\"bk\" d=\"M235,270l100,0l40,35l0,80l-20,-25l-120,0\" stroke-width=\"2%\" />");
        }
        else /*if (shapetype == 4)*/ { // cockatoo
            return  bytes.concat("<path class=\"hd\" d=\"M170,480l0,-90l-35,-50l0,-115l25,-49l60,-25l60,0l41,30l0,155l-5,0l0,40l-40,40l0,65\" stroke-width=\"0.15%\" stroke-linejoin=\"round\" />",
                    "<path class=\"cr\" d=\"M321,181l0,-50l5,-50l10,-50l10,-20l0-5l-5,0l-30,10l-30,30l-12,30l-10,30l-2,25l1,-15l-30,-30l0,-50l3,-20l-10,0l-10,5l-25,35l0,70l5,20l-5,-20l-30,-10l-10,-10l-10,-30l0,-20l-10,0l-15,20l-5,30l0,20l10,20l40,40l-10,-10l-40,0l-40,-10l-5,0l0,10l20,25l20,10l20,10l14,55l20,-60l50,-45l60,-10l29,0l15,11z\" stroke-width=\"0.15%\" stroke-linejoin=\"round\" />",
                    "<path class=\"th\" d=\"M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66\" stroke-width=\"0.15%\" stroke-linejoin=\"round\" />",
                    "<path class=\"ol\" d=\"M275,481l0,-65l40,-40l0,-40l5,0l0,-205l5,-50l10,-50l10,-20l0-5l-5,0l-30,10l-30,30l-12,30l-10,30l-2,25l1,-15l-30,-30l0,-50l3,-20l-10,0l-10,5l-25,35l0,70l5,20l-5,-20l-30,-10l-10,-10l-10,-30l0,-20l-10,0l-15,20l-5,30l0,20l10,20l40,40l-10,-10l-40,0l-40,-10l-5,0l0,10l20,25l20,10l20,10l14,55l0,63l35,50l0,91M118,220l10,5\" stroke-width=\"2%\" stroke-linejoin=\"round\" />",
                    "<path class=\"bk\" d=\"M235,275l110,0l20,25l0,60l-10,-25l-20,0l-15,25l-85,0\" stroke-width=\"2%\" />");
        }                        
        
    }

   function generateCharacterFilter(uint256 ownedcount) internal pure returns (bytes memory) {
       uint256 irr = 10 + ((ownedcount > 50) ? 50 : ownedcount);
       return bytes.concat(
                "<filter id=\"sofGlow\" height=\"300%\" width=\"300%\" x=\"-75%\" y=\"-75%\">", // <!--Thicken out the original shape-->
                "<feMorphology operator=\"dilate\" radius=\"4\" in=\"SourceAlpha\" result=\"thicken\"/>", // <!--Use a gaussian blur to create the soft blurriness of the glow-->
                "<feGaussianBlur in=\"thicken\" stdDeviation=\"",
                bytes(irr.toString()),
                "\" result=\"blurred\"/>", // <!--Change the colour-->
                "<feFlood flood-color=\"rgb(0,186,255)\" result=\"glowColor\"/>", // <!--Color in the glows-->
                "<feComposite in=\"glowColor\" in2=\"blurred\" operator=\"in\" result=\"softGlow_colored\"/>", //<!--Layer the effects together-->
                "<feMerge><feMergeNode in=\"softGlow_colored\"/> <feMergeNode in=\"SourceGraphic\"/></feMerge>",
                "</filter>"); 
   }

   function generateCharacterStyles(bool nightly, bytes memory eycolor, bytes memory ewcolor, bytes memory beakColor, bytes memory throatColor, bytes memory headColor) internal pure returns (bytes memory) {
        bytes memory filterRef = '';
        if (nightly) {
            filterRef = bytes(";filter=\"url(#sofGlow)\"");       
        }
        bytes memory p1 = bytes.concat(
        //<style type="text/css">.hd{fill:rgb(138,28,94);}.ew{fill:rgb(240,248,255);}.th, .cr {fill:rgb(8,32,220);}.bk{fill:rgb(152,152,152);}.ol{fill:rgba(0,0,0,0);}</style>
        "<style type=\"text/css\">.hd{fill:", headColor,
        ";stroke:", (nightly ? headColor : bytes("black")), 
        filterRef,
        ";}.ey{fill:", eycolor,
        ";stroke:", /*nightly ? getRgbFromTraitVal(traits[5]) :*/ bytes("black"),
        filterRef,
        ";}.ew{fill:", ewcolor,
        ";stroke:", /*(nightly ? ewcolor : bytes("black")*/ bytes("black"),
        filterRef);
        bytes memory p2 = bytes.concat(
        ";}.th, .cr {fill:", throatColor,
        ";stroke:", (nightly ? throatColor : bytes("black")),
        filterRef,
        ";}.bk{fill:", beakColor,
        ";stroke:", (nightly ? beakColor : bytes("black")),
        filterRef,
        ";}.ol{fill:rgba(0,0,0,0);}</style>");   
        return bytes.concat(p1, p2);    
   }    

   function generateCharacterSvg(uint256 tokenId, bool nightly, uint256 ownedcount) internal view returns (bytes memory) {
       uint8[] memory traits = getTraitValues(tokenId);        
        bytes memory eycolor = "rgb(0, 0, 0)";
        bytes memory ewcolor = "rgb(240,248,255)";
        if (traits[2] == 1) {
            eycolor = "rgb(154, 0, 0)";
            ewcolor = getRgbFromTraitVal(traits[2]);
        }
        bytes memory beakColor = 'grey';
        if (traits[3] == 1) beakColor = 'gold';
        else if (traits[3] == 2) beakColor = 'red';
        else if (traits[3] == 3) beakColor = 'black';       
        return bytes.concat(
            generateCharacterStyles(nightly, eycolor, ewcolor, beakColor, getRgbFromTraitVal(traits[4]), getRgbFromTraitVal(traits[5])),
            (nightly ? generateCharacterFilter(ownedcount) : bytes(" ")),
            getBirdLayout(getTraitValue(tokenId, 1)),
            getBirdEyes()
        );
    }              

	function generateCharacter(uint256 tokenId, uint256 ownedcount) internal view returns(bytes memory) {
        uint256 dayHour = (block.timestamp%86400)/3600;
        bool isNight = ((dayHour >= 20) || (dayHour <= 4));
 		bytes memory svg = bytes.concat(
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<svg x="0px" y="0px" viewBox="0 0 480 480" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" preserveAspectRatio="xMinYMin meet">',
        '<rect x="0" y="0" width="480" height="480" fill="',
        (isNight ? bytes('rgb(8,42,97)') : bytes('rgb(238,238,238)')),
        '" />',
        generateCharacterSvg(tokenId, isNight, ownedcount),
        '</svg>'
		);
		return bytes.concat(
				"data:image/svg+xml;base64,",
				bytes(Base64.encode(svg))
                );
	}

    function getTraitAttributesTType(uint8 traitId, uint8 traitVal) internal pure returns (bytes memory) {
        bytes memory traitName;
        if (traitId == 0)
        traitName = "tr-0";
        else if (traitId == 1)
        traitName = "type";
        else if (traitId == 2)
        traitName = "eyes";
        else if (traitId == 3)
        traitName = "beak";
        else if (traitId == 4)
        traitName = "throat";
        else if (traitId == 5)
        traitName = "head";  
        else if (traitId == 6)
        traitName = "level";
        else if (traitId == 7)
        traitName = "stamina"; 
        bytes memory display; 
        if (traitId == 7)
        display = "\"display_type\": \"boost_number\",";
        else if (traitId == 6)
        display = "\"display_type\": \"number\",";
        else
        display = "";                                                   
        return bytes.concat("{", display, "\"trait_type\": \"", traitName, "\",\"value\": \"", bytes(Strings.toString(traitVal)), "\"}");
    }

	function getTraitAttributes(uint256 tokenId) internal view returns(bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);     
        /*string memory attribs;
        for (uint8 i = 0; i < 8; i++) 
        {
            attribs = string.concat(attribs, getTraitAttributesTType(i, traits[i]));                        
        }
        return attribs;*/
        return 
			bytes.concat(
				getTraitAttributesTType(0, traits[0]),',',
				getTraitAttributesTType(1, traits[1]),',',
                getTraitAttributesTType(2, traits[2]),',',
                getTraitAttributesTType(3, traits[3]),',',
                getTraitAttributesTType(4, traits[4]),',',
                getTraitAttributesTType(5, traits[5]),',',
                getTraitAttributesTType(6, traits[6]),',',
                getTraitAttributesTType(7, traits[7])
			);	        
    }    

    function tokenURI(address tokenOwner, uint256 tokenId) external view returns (string memory) {
		bytes memory dataURI = bytes.concat(
			'{'
				'"name": "MBB ', 
                bytes(MainContract.getNickName(tokenId)),     
                ' #',                           
                bytes(tokenId.toString()),
                ' owned: ',   
                bytes(MainContract.balanceOf(tokenOwner).toString()),
                '",'
				'"description": "MutantBitBirds, Earn and Mutate",'
				'"image": "', 
                generateCharacter(tokenId, MainContract.balanceOf(tokenOwner)), 
                '",'
				'"attributes": [', 
                    getTraitAttributes(tokenId),
                ']'
			'}'
		);
        return string(
			bytes.concat(
				"data:application/json;base64,",
				bytes(Base64.encode(dataURI))
		));
    }	   

    // Opensea json metadata format interface
    function contractURI() external view returns (string memory) {       
        bytes memory dataURI = bytes.concat(
        '{',
            '"name": "MutantBitBirds",',
            '"description": "Earn MutantCawSeeds (MCS) and customize your MutantBitBirds !",',
            //'"image": "', 
            //bytes(_contractUri), 
            //'/image.png",',
            //'"external_link": "',
            //bytes(_contractUri),
            '"',
            '"fee_recipient": "',
            abi.encodePacked(MainContract.getRewardContract()),
            '"'
        '}');
        return string(
			    bytes.concat(
			    "data:application/json;base64,",
				bytes(Base64.encode(dataURI)))
            //dataURI
        );
    }     

    /*function getTraitTextTSpan(uint8 traitId, uint8 traitVal) internal view returns (bytes memory) {
        return bytes.concat("<tspan x=\"50%\" dy=\"15\">", bytes(_traitNames[traitId]), ": ", bytes(Strings.toString(traitVal)), "</tspan>");
    }*/

	/*
    function getTraitText(uint256 tokenId) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);        
        return 
			bytes.concat(
				getTraitTextTSpan(0, traits[0]),
				getTraitTextTSpan(1, traits[1]),
                getTraitTextTSpan(2, traits[2]),
                getTraitTextTSpan(3, traits[3]),
                getTraitTextTSpan(4, traits[4]),
                getTraitTextTSpan(5, traits[5]),
                getTraitTextTSpan(6, traits[6]),
            getTraitTextTSpan(7, traits[7])
			);	                     
    }
    */        
}