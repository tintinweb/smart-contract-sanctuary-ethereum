//SPDX-License-Identifier: MIT 
pragma solidity ~0.8.18;

library BytesUtilsXAP {
    /*
     * @dev Returns the keccak-256 hash of a byte range.
     * @param self The byte string to hash.
     * @param offset The position to start hashing at.
     * @param len The number of bytes to hash.
     * @return The hash of the byte range.
     */
    function keccak(
        bytes memory self,
        uint256 offset,
        uint256 len
    ) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /**
     * @dev Returns the ENS namehash of a DNS-encoded name.
     * @param self The DNS-encoded name to hash.
     * @param offset The offset at which to start hashing.
     * @return The namehash of the name.
     */
    function namehash(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes32)
    {
        (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
        if (labelhash == bytes32(0)) {
            require(offset == self.length - 1, "namehash: Junk at end of name");
            return bytes32(0);
        }
        return
            keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
    }

    /**
     * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
     * @param self The byte string to read a label from.
     * @param idx The index to read a label at.
     * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
     * @return newIdx The index of the start of the next label.
     */
    function readLabel(bytes memory self, uint256 idx)
        internal
        pure
        returns (bytes32 labelhash, uint256 newIdx)
    {
        require(idx < self.length, "readLabel: Index out of bounds");
        uint256 len = uint256(uint8(self[idx]));
        if (len > 0) {
            labelhash = keccak(self, idx + 1, len);
        } else {
            labelhash = bytes32(0);
        }
        newIdx = idx + len + 1;
    }

    /**
     * @dev This function takes a bytes input which represents the DNS name and
     * returns the first label of a domain name in DNS format.
     * @param domain The domain in DNS format wherein the length precedes each label
     * and is terminted with a 0x0 byte, e.g. "cb.id" => [0x02,0x63,0x62,0x02,0x69,0x64,0x00].
     * @return string memory the first label.
     */

    function getFirstLabel(bytes memory domain) internal pure returns (string memory, uint256) {

        // Get the first byte of the domain which represents the length of the first label
        uint256 labelLength = uint256(uint8(domain[0]));

        // Create a new byte array to hold the first label
        bytes memory firstLabel = new bytes(labelLength);

        // Iterate through the domain bytes to copy the first label to the new byte array
        // skipping the first byte which represents the length of the first label.
        for (uint256 i = 0; i < labelLength; ++i) {
            firstLabel[i] = domain[i+1];
        }

        // Convert the first label to string and return
        return (string(firstLabel), labelLength);
    }

    /**
     * @dev This function takes a bytes input which represents the DNS name and
     * returns the TLD (last label) of a domain name. A domain can have a maximum of 10 labels.
     * @param domain bytes memory.
     * @return string memory the TLD.
     */

    function getTLD(bytes memory domain) internal pure returns (string memory) {
        // Variable used to keep track of the level count.

        uint levels = 0;
        // Variable used to keep track of the index of each length byte.

        for (uint i = 0; i < domain.length; i++) {

            // If level count exceed 10, break the loop.
            if (levels > 10) {
                break;
            }

            // Get the label length from the current byte.
            uint labelLength = uint(uint8(domain[i]));

            // Check if the next byte after the label is a zero value byte, if so it means the label is the TLD.
            if(labelLength + i + 1 < domain.length && domain[labelLength + i + 1] == 0) {

                // Create a new byte array to hold the TLD.
                bytes memory lastLabel = new bytes(labelLength);

                // Copy the TLD from the domain array to the new byte array.
                for (uint j = 0; j < labelLength; j++) {
                    lastLabel[j] = domain[i + 1 + j];
                }

                // Convert the TLD to string and return.
                return string(lastLabel);
            }

            // Move to the next label
            i += labelLength + 1;

            // Increment the level count.
            levels++;
        }

        // Return empty string if TLD not found
        return "";
    }

    /**
     * @dev This funciton will split a bytes array into two parts, the first part will be the bytes before the
     * index and the second part will be the bytes after the index.
     * @param bytesArray bytes memory.
     * @param index uint256.
     * @return the left and rigth side of the array (the right side includes the index).
     */

    function splitBytes(bytes memory bytesArray, uint256 index) internal pure returns (bytes memory, bytes memory) {

        // Create a new byte array to hold the first part of the bytes array.
        bytes memory firstPart = new bytes(index);

        // Create a new byte array to hold the second part of the bytes array.
        bytes memory secondPart = new bytes(bytesArray.length - index);

        // Copy the first part of the bytes array to the firstPart byte array.
        for (uint i = 0; i < index; i++) {
            firstPart[i] = bytesArray[i];
        }

        // Copy the second part of the bytes array to the secondPart byte array.
        for (uint i = index; i < bytesArray.length; i++) {
            secondPart[i - index] = bytesArray[i];
        }

        // Return the first and second part of the bytes array.
        return (firstPart, secondPart);
    }

    /**
     * @dev Convert a numbers in UTF-8 format into a uint256.
     *
     * The input must contain only numeric characters (i.e., characters
     * with UTF-8 code points between 48 and 57). If the input contains
     * any non-numeric characters, the function will revert with an error message.
     *
     * @param num The input string to convert.
     * @return result The converted uint256 value.
     */

    function bytesNumberToUint(bytes memory num) public pure returns (uint256 result) {

        require(num.length > 0, "Input must not be empty");

        for (uint256 i = 0; i < num.length; i++) {
            uint256 c = uint256(uint8(num[i]));
            require(c >= 48 && c <= 57, "Input must only contain digits");
            result = result * 10 + (c - 48);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IExtendedResolver {
    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory, address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IXAPRegistry{

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed name, address owner);

    // Logged when a address is added or updated for a name.
    event NewAddress(bytes32 indexed name, uint chainId);

    function setApprovalForAll(address operator) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function approve(bytes32 name, address delegate) external;

    function isApprovedFor(address owner, bytes32 name, address delegate) external view returns (bool);

    function register(bytes32 name, address _owner, uint256 chainId, address _address) external;

    function registerWithData(bytes32 name, address _owner, uint96 accountData, uint256 chainId, address _address, uint96 addressData) external;

    function registerAddress(bytes32 name, uint256 chainId, address _address) external;

    function registerAddressWithData(bytes32 name, uint256 chainId, address _address, uint96 addressData) external;

    function setOwner(bytes32 name, address _address) external;

    function setAccountData(bytes32 name, uint96 accountData) external;

    function resolveAddress(bytes32 name, uint256 chainId) external view returns (address);

    function resolveAddressWithData(bytes32 name, uint256 chainId) external view returns (address, uint96);

    function getOwner(bytes32 name) external view returns (address);

    function getOwnerWithData(bytes32 name) external view returns (address, uint96);

    function available(bytes32 name) external view returns (bool);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IXAPRegistry} from "./IXAPRegistry.sol";

interface IXAPResolver {

    function xap() external view returns (IXAPRegistry);

    function resolve(bytes memory name, bytes memory data)
        external
        view
        returns (bytes memory, address);

}

//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.18;

import {IExtendedResolver} from "./IExtendedResolver.sol";
import {IXAPRegistry} from "./IXAPRegistry.sol";
import {IXAPResolver} from "./IXAPResolver.sol";
import {BytesUtilsXAP} from "./BytesUtilsXAP.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CannotResolve(bytes4 selector);


contract XAPResolver is ERC165, IXAPResolver, IExtendedResolver{

    // addr(bytes32 node, uint256 coinType) public view virtual override returns (bytes memory) 
    // => addr(bytes32,uint256) => 0xf1cb7e06
    // text(bytes32 node, string calldata key)external view virtual override returns (string memory)
    // => text(bytes32,string) => 0x59d1d43c
    // contenthash(bytes32 node) external virtual authorised(node) 
    // contenthash( bytes32 node) external view virtual override returns (bytes memory) 
    // => contenthash(bytes32) => 0xbc1c58d1

    // abc.xap.eth => 0x03616263037861700365746800

    using BytesUtilsXAP for bytes;

    IXAPRegistry public xap;

    constructor (IXAPRegistry _xap) {
        xap = _xap;
    }

    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        override (IExtendedResolver, IXAPResolver)
        returns (bytes memory, address)
    {

        // Read function selector from the data.
        bytes4 selector = bytes4(data[0:4]);
        // Resolve address.
        if (selector == 0xf1cb7e06) {

            // Decode the ABI encoded function call (data).
            // Save the coin type and not the function selector or node.
            ( , uint256 cointype_ChainId) = abi.decode(data[4:], (bytes32, uint256));

            // XAP only supports EVM chains. 
            // If the coin type is not ETH (60) then check to see if it is an another EVM chain, and extract the chain ID.
            if (cointype_ChainId == 60){ 
                cointype_ChainId = 1;
            } else if (cointype_ChainId > uint256(0x80000000)) {
                // if the coint type is greater than 0x80000000 then it an EVM ENS encoded chain id.
                cointype_ChainId = cointype_ChainId ^ uint256(0x80000000);
            } else {
                // If the coin type is not ETH (60) or an EVM chain then revert.
                revert CannotResolve(bytes4(selector));
            }

            // Get the label of the name
            (string memory label, ) = name.getFirstLabel();

            // Resolve the address of the label on the chain id.
            address resolvedAddress = xap.resolveAddress(bytes32(bytes(label)), cointype_ChainId);
            
            // Return the resolved address.
            return (abi.encodePacked(resolvedAddress), address(this)); 

        } else if (selector == 0x59d1d43c) {
            //Resolve text.

            // Strip off the function selector and decode the ABI encoded function call (data).
            ( ,string memory key) = abi.decode(data[4:], (bytes32, string));

            // Split the key into the key and chain id.
            (bytes memory keyBytes, bytes memory chainId) = bytes(key).splitBytes(17);

            // Convert the chain id to a uint256. 
            uint256 chainIdInt = chainId.bytesNumberToUint();

            // Check if the key is "xap-address-data-" and the chain id is greater than 0.
            if (areStringsEqual(string(keyBytes), "xap-address-data-") && chainIdInt > 0){

                // Get the label of the name
                (string memory label, ) = name.getFirstLabel();

                // Get the address data of the address of the chain id.
                ( , uint96 addressData) = xap.resolveAddressWithData(bytes32(bytes(label)),chainIdInt);

                // Return the address data.
                return (abi.encodePacked(addressData), address(this));
            } else {
                revert CannotResolve(bytes4(selector));
            }
        } else if (selector == 0xbc1c58d1) {
            //Resolve contenthash.

            // Get the label of the name
            (string memory label, ) = name.getFirstLabel();

            // Get the address data of the Ethereum L1 address.
            ( address _address, uint96 accountData) = xap.getOwnerWithData(bytes32(bytes(label)));

            // Data URL for the contenthash.
            string memory beforeData = "data:text/html,%3Cbr%3E%3Ch2%3E%3Cdiv%20style%3D%22text-align%3Acenter%3B%20font-family%3A%20Arial%2C%20sans-serif%3B%22%3EXAP%20Account%20Owner%3A%20";
            string memory delimter = "%3Cbr%3EXAP%20Account%20Data%3A%20"; 
            string memory afterData = "%3C%2Fh2%3E%3C%2Fdiv%3E";

            // Concatenate the data URL. 
            string memory outString = string.concat(beforeData,Strings.toHexString(_address));
            outString = string.concat(outString,delimter);
            outString = string.concat(outString,Strings.toString(accountData));
            outString = string.concat(outString,afterData);

            // Return the data URL.
            return (bytes(outString), address(this));

        } else { 
            revert CannotResolve(bytes4(selector));
        }
    }

    function areStringsEqual(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override 
        returns (bool)
    {
        return
            interfaceId == type(IXAPResolver).interfaceId ||
            interfaceId == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceId);
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}