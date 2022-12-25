// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "base64/base64.sol";

import {NounishERC721} from "./base/NounishERC721.sol";
import {NounishDescriptors} from "./libraries/NounishDescriptors.sol";
import {ICharacterSVGRenderer} from "./interfaces/ICharacterSVGRenderer.sol";

contract NounishChristmasMetadata {
    using Strings for uint256;

    ICharacterSVGRenderer characterRenderHelper1;
    ICharacterSVGRenderer characterRenderHelper2;
    ICharacterSVGRenderer characterRenderHelper3;

    constructor(
        ICharacterSVGRenderer renderHelper1,
        ICharacterSVGRenderer renderHelper2,
        ICharacterSVGRenderer renderHelper3
    ) {
        characterRenderHelper1 = renderHelper1;
        characterRenderHelper2 = renderHelper2;
        characterRenderHelper3 = renderHelper3;
    }

    function tokenURI(uint256 id, bytes32 gameID, NounishERC721.Info calldata info)
        external
        view
        returns (string memory)
    {
        return string(
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"' "#",
                            id.toString(),
                            " - ",
                            NounishDescriptors.tintColorName(info.tint),
                            " ",
                            NounishDescriptors.characterName(info.character),
                            '", "description":"',
                            "Nounish Christmas NFTs are created by playing the Nounish White Elephant game, where players can open new NFTs by minting and steal opened NFTs from others.",
                            '", "attributes": ',
                            attributes(gameID, info),
                            ', "image": "' "data:image/svg+xml;base64,",
                            Base64.encode(bytes(svg(info))),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function svg(NounishERC721.Info calldata info) public view returns (string memory) {
        return string.concat(
            '<svg width="500" height="500" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" style="background-color:#',
            NounishDescriptors.backgroundColorHex(info.backgroundColor),
            '" >',
            '<style type="text/css">',
            ".noggles{fill:#",
            NounishDescriptors.noggleColorHex(info.noggleColor),
            ";}",
            ".tintable{fill:#",
            NounishDescriptors.tintColorHex(info.tint),
            ";}",
            "</style>",
            characterSVG(info.character),
            NounishDescriptors.noggleTypeSVG(info.noggleType),
            "</svg>"
        );
    }

    function attributes(bytes32 gameID, NounishERC721.Info calldata info) public view returns (string memory) {
        return string.concat(
            "[",
            _traitTypeString("game ID", uint256(gameID).toString()),
            ",",
            _traitTypeString("character", NounishDescriptors.characterName(info.character)),
            ",",
            _traitTypeString("tint", NounishDescriptors.tintColorName(info.tint)),
            ",",
            _traitTypeString("noggle", NounishDescriptors.noggleTypeName(info.noggleType)),
            ",",
            _traitTypeString("noggle color", NounishDescriptors.noggleColorName(info.noggleColor)),
            ",",
            _traitTypeString("background color", NounishDescriptors.backgroundColorName(info.backgroundColor)),
            "]"
        );
    }

    function characterSVG(uint8 character) public view returns (string memory) {
        if (character < 7) {
            return NounishDescriptors.characterSVG(character);
        } else if (character < 20) {
            return characterRenderHelper1.characterSVG(character);
        } else if (character < 29) {
            return characterRenderHelper2.characterSVG(character);
        } else {
            return characterRenderHelper3.characterSVG(character);
        }
    }

    function _traitTypeString(string memory t, string memory v) internal pure returns (string memory) {
        return string.concat("{", '"trait_type": "', t, '",', '"value": "', v, '"}');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {WhiteElephantNFT, ERC721} from "./base/WhiteElephantNFT.sol";
import {WhiteElephant} from "./base/WhiteElephant.sol";

import {NounishChristmasMetadata} from "./NounishChristmasMetadata.sol";

contract NounishChristmasNFT is WhiteElephantNFT {
    uint256 private _nonce;
    WhiteElephant public whiteElephant;
    NounishChristmasMetadata public metadata;

    constructor(NounishChristmasMetadata _metadata) ERC721("Nounish White Elephant Christmas", "NWEC") {
        whiteElephant = WhiteElephant(msg.sender);
        metadata = _metadata;
    }

    function mint(address to) external override returns (uint256 id) {
        require(msg.sender == address(whiteElephant), "FORBIDDEN");

        _mint(to, (id = _nonce++));
        require(id < 1 << 64, "MAX_MINT");

        bytes32 h = keccak256(abi.encode(id, to, block.timestamp));
        _nftInfo[id].character = uint8(h[0]) % 32 + 1;
        _nftInfo[id].tint = uint8(h[1]) % 12 + 1;
        _nftInfo[id].backgroundColor = uint8(h[2]) % 4 + 1;
        _nftInfo[id].noggleType = uint8(h[3]) % 3 + 1;
        _nftInfo[id].noggleColor = uint8(h[4]) % 4 + 1;
    }

    /// @dev steal should be guarded as an owner/admin function
    function steal(address from, address to, uint256 id) external override {
        require(msg.sender == address(whiteElephant), "FORBIDDEN");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _nftInfo[id].owner = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function transferFrom(address from, address to, uint256 id) public override {
        require(whiteElephant.state(whiteElephant.tokenGameID(id)).gameOver, "GAME_IN_PROGRESS");
        super.transferFrom(from, to, id);
    }

    function updateMetadata(NounishChristmasMetadata _metadata) external {
        require(msg.sender == address(whiteElephant), "FORBIDDEN");

        metadata = _metadata;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return metadata.tokenURI(id, whiteElephant.tokenGameID(id), _nftInfo[id]);
    }

    function nftInfo(uint256 id) public view returns (Info memory) {
        return _nftInfo[id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";

abstract contract NounishERC721 is ERC721 {
    struct Info {
        uint8 character;
        uint8 tint;
        uint8 backgroundColor;
        uint8 noggleType;
        uint8 noggleColor;
        address owner;
    }

    mapping(uint256 => Info) public _nftInfo;

    function transferFrom(address from, address to, uint256 id) public virtual override {
        require(from == _nftInfo[id].owner, "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _nftInfo[id].owner = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function approve(address spender, uint256 id) public override {
        address owner = _nftInfo[id].owner;

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    // function tokenURI(uint256 id) public view override returns (string memory) {
    //     return "";
    // }

    function ownerOf(uint256 id) public view override returns (address owner) {
        require((owner = _nftInfo[id].owner) != address(0), "NOT_MINTED");
    }

    function _mint(address to, uint256 id) internal override {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_nftInfo[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _nftInfo[id].owner = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal override {
        address owner = _nftInfo[id].owner;

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _nftInfo[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {WhiteElephantNFT} from "./WhiteElephantNFT.sol";

contract WhiteElephant {
    /// @dev when game already Exists
    error GameExists();
    /// @dev when msg.sender is not `currentParticipantTurn`
    error NotTurn();
    /// @dev when tokenID was not minted in game
    error InvalidTokenIDForGame();
    /// @dev when tokenID has already been stolen twice
    error MaxSteals();
    /// @dev when tokenID was just stolen
    error JustStolen();
    /// @dev when game is over
    error GameOver();

    event StartGame(bytes32 indexed gameID, Game game);
    event Open(bytes32 indexed gameID, address indexed player, uint256 indexed tokenId);
    event Steal(bytes32 indexed gameID, address indexed stealer, uint256 indexed tokenId, address stolenFrom);

    struct Game {
        /// @dev the addresses in this game, ordered how they should have turns
        address[] participants;
        /// @dev any unique value, probably timestamp best
        uint256 nonce;
    }

    // used to prevent stealing back immediately
    // cannot be stollen if curRound == round
    // and trying to steal lastStolenID
    struct LastStealInfo {
        // which NFT was last stole
        uint64 lastStolenID;
        uint8 round;
    }

    struct GameState {
        // starts at 0
        // for whose turn, use participants[round - 1]
        uint8 round;
        bool gameOver;
        // used to track who goes next after a steal
        address nextToGo;
        LastStealInfo lastStealInfo;
    }

    WhiteElephantNFT public nft;

    /// @notice how many times has a tokenID been stolen
    mapping(uint256 => uint256) public timesStolen;
    /// @notice what game a given tokenID was minted in
    mapping(uint256 => bytes32) public tokenGameID;
    mapping(bytes32 => GameState) internal _state;

    /// @notice starts a game
    /// @dev does not check participant addresses, address(0) or other incorrect
    /// address could render game unable to progress
    /// @dev reverts if `game` exists
    /// @param game Game specification, {participants: address[], nonce: uint256}
    /// @return _gameID the unique identifier for the game
    function startGame(Game calldata game) public payable virtual returns (bytes32 _gameID) {
        _gameID = gameID(game);

        if (_state[_gameID].round != 0) {
            revert GameExists();
        }

        _state[_gameID].round = 1;

        emit StartGame(_gameID, game);
    }

    /// @notice open a new gift
    /// @param game the game the participant caller is in and wishes to open in
    /// game = {participants: address[], nonce: uint256}
    function open(Game calldata game) public virtual {
        bytes32 _gameID = gameID(game);

        _checkGameOver(_gameID);

        _checkTurn(_gameID, game);

        uint8 newRoundCount = _state[_gameID].round + 1;
        _state[_gameID].round = newRoundCount;
        if (newRoundCount > game.participants.length) {
            _state[_gameID].gameOver = true;
        }

        _state[_gameID].nextToGo = address(0);

        uint256 tokenID = nft.mint(msg.sender);
        tokenGameID[tokenID] = _gameID;

        emit Open(_gameID, msg.sender, tokenID);
    }

    /// @notice Steals NFT from another participant
    /// @dev reverts if tokenID not minted in `game`
    /// @dev reverts if token has been stolen twice already
    /// @dev reverts if tokenID was just stolen
    /// @param game the game the participant is in and wishes to steal in
    /// game = {participants: address[], nonce: uint256}
    /// @param tokenID that token they wish to steal, must have been minted by another participant in same game
    function steal(Game calldata game, uint256 tokenID) public virtual {
        bytes32 _gameID = gameID(game);

        _checkGameOver(_gameID);

        _checkTurn(_gameID, game);

        if (_gameID != tokenGameID[tokenID]) {
            revert InvalidTokenIDForGame();
        }

        if (timesStolen[tokenID] == 2) {
            revert MaxSteals();
        }

        uint8 currentRound = _state[_gameID].round;
        if (_state[_gameID].round == _state[_gameID].lastStealInfo.round) {
            if (_state[_gameID].lastStealInfo.lastStolenID == tokenID) {
                revert JustStolen();
            }
        }

        timesStolen[tokenID] += 1;
        _state[_gameID].lastStealInfo = LastStealInfo({lastStolenID: uint64(tokenID), round: currentRound});

        address currentOwner = nft.ownerOf(tokenID);
        _state[_gameID].nextToGo = currentOwner;

        nft.steal(currentOwner, msg.sender, tokenID);

        emit Steal(_gameID, msg.sender, tokenID, currentOwner);
    }

    /// @notice returns the state of the given game ID
    /// @param _gameID the game identifier, from gameID(game)
    /// @return state the state of the game
    /// struct GameState {
    ///   uint8 round;
    ///   bool gameOver;
    ///   address nextToGo;
    ///    LastStealInfo lastStealInfo;
    /// }
    /// struct LastStealInfo {
    ///     uint64 lastStolenID;
    ///     uint8 round;
    /// }
    function state(bytes32 _gameID) public view virtual returns (GameState memory) {
        return _state[_gameID];
    }

    /// @notice returns which address can call open or steal next in a given game
    /// @param _gameID the id of the game
    /// @param game the game
    /// game = {participants: address[], nonce: uint256}
    /// @return participant the address that is up to go next
    function currentParticipantTurn(bytes32 _gameID, Game calldata game) public view virtual returns (address) {
        if (_state[_gameID].gameOver) {
            return address(0);
        }
        
        address next = _state[_gameID].nextToGo;
        if (next != address(0)) return next;

        return game.participants[_state[_gameID].round - 1];
    }

    /// @notice returns the unique identifier for a given game
    /// @param game, {participants: address[], nonce: uint256}
    /// @return gameID the id of the game
    function gameID(Game calldata game) public pure virtual returns (bytes32) {
        return keccak256(abi.encode(game));
    }

    function _checkTurn(bytes32 _gameID, Game calldata game) internal view {
        if (currentParticipantTurn(_gameID, game) != msg.sender) {
            revert NotTurn();
        }
    }

    function _checkGameOver(bytes32 _gameID) internal view {
        if (_state[_gameID].gameOver) {
            revert GameOver();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {NounishERC721, ERC721} from "./NounishERC721.sol";

abstract contract WhiteElephantNFT is NounishERC721 {
    /// @dev mint should be guarded as an owner/admin function
    function mint(address to) external virtual returns (uint256);
    /// @dev steal should be guarded as an owner/admin function
    function steal(address from, address to, uint256 id) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICharacterSVGRenderer {
    function characterSVG(uint8 character) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library NoggleSVGs {
    function basic() internal pure returns (string memory) {
        return '<rect x="6" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="8" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="13" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="16" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="11" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="7" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="12" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="9" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="9" width="2" height="1" class="noggles"/>'
        '<rect x="9" y="9" width="2" height="1" class="noggles"/>'
        '<rect x="15" y="7" width="1" height="2" fill="black"/>'
        '<rect x="10" y="7" width="1" height="2" fill="black"/>'
        '<rect x="14" y="7" width="1" height="2" fill="white"/>' '<rect x="9" y="7" width="1" height="2" fill="white"/>';
    }

    function cool() internal pure returns (string memory) {
        return '<rect x="6" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="8" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="13" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="16" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="11" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="7" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="12" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="9" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="7" width="1" height="3" class="noggles"/>'
        '<rect x="9" y="7" width="1" height="3" class="noggles"/>'
        '<rect x="10" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="15" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="15" y="7" width="1" height="1" fill="white"/>'
        '<rect x="10" y="7" width="1" height="1" fill="white"/>';
    }

    function large() internal pure returns (string memory) {
        return '<rect x="3" y="8" width="1" height="3" class="noggles"/>'
        '<rect x="4" y="8" width="2" height="1" class="noggles"/>'
        '<rect x="6" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="7" y="11" width="4" height="1" class="noggles"/>'
        '<rect x="7" y="6" width="4" height="1" class="noggles"/>'
        '<rect x="11" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="12" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="13" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="18" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="14" y="6" width="4" height="1" class="noggles"/>'
        '<rect x="14" y="11" width="4" height="1" class="noggles"/>'
        '<rect x="16" y="7" width="2" height="4" fill="black"/>' '<rect x="9" y="7" width="2" height="4" fill="black"/>'
        '<rect x="14" y="7" width="2" height="4" fill="white"/>' '<rect x="7" y="7" width="2" height="4" fill="white"/>';
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {NoggleSVGs} from "./NoggleSVGs.sol";
import {OneThroughSixCharacterSVGs} from "./OneThroughSixCharacterSVGs.sol";

library NounishDescriptors {
    function characterName(uint8 character) internal pure returns (string memory) {
        if (character == 1) {
            return "Cardinal";
        } else if (character == 2) {
            return "Swan";
        } else if (character == 3) {
            return "Blockhead";
        } else if (character == 4) {
            return "Dad";
        } else if (character == 5) {
            return "Trout Sniffer";
        } else if (character == 6) {
            return "Elf";
        } else if (character == 7) {
            return "Mothertrucker";
        } else if (character == 8) {
            return "Girl";
        } else if (character == 9) {
            return "Lamp";
        } else if (character == 10) {
            return "Mean One";
        } else if (character == 11) {
            return "Miner";
        } else if (character == 12) {
            return "Mrs. Claus";
        } else if (character == 13) {
            return "Noggleman";
        } else if (character == 14) {
            return "Noggle Tree";
        } else if (character == 15) {
            return "Nutcracker";
        } else if (character == 16) {
            return "Partridge in a Pear Tree";
        } else if (character == 17) {
            return "Rat King";
        } else if (character == 18) {
            return "Reindeer S";
        } else if (character == 19) {
            return "Reindeer Pro Max";
        } else if (character == 20) {
            return "Santa S";
        } else if (character == 21) {
            return "Santa Max Pro";
        } else if (character == 22) {
            return "Skeleton";
        } else if (character == 23) {
            return "Chunky Snowman";
        } else if (character == 24) {
            return "Slender Snowman";
        } else if (character == 25) {
            return "Snowman Pro Max";
        } else if (character == 26) {
            return "Sugar Plum Fairy";
        } else if (character == 27) {
            return "Short Thief";
        } else if (character == 28) {
            return "Tall Thief";
        } else if (character == 29) {
            return "Train";
        } else if (character == 30) {
            return "Christmas Tree";
        } else if (character == 31) {
            return "Yeti S";
        } else if (character == 32) {
            return "Yeti Pro Max";
        }
        return "";
    }

    /// @dev wanted to make the most of contract space, only renders through character 6
    function characterSVG(uint8 character) internal pure returns (string memory) {
        if (character == 1) {
            return OneThroughSixCharacterSVGs.cardinal();
        } else if (character == 2) {
            return OneThroughSixCharacterSVGs.swan();
        } else if (character == 3) {
            return OneThroughSixCharacterSVGs.blockhead();
        } else if (character == 4) {
            return OneThroughSixCharacterSVGs.dad();
        } else if (character == 5) {
            return OneThroughSixCharacterSVGs.troutSniffer();
        } else if (character == 6) {
            return OneThroughSixCharacterSVGs.elf();
        }
        return "";
    }

    function noggleTypeName(uint8 noggleType) internal pure returns (string memory) {
        if (noggleType == 1) {
            return "Noggles S";
        } else if (noggleType == 2) {
            return "Cool Noggles";
        } else if (noggleType == 3) {
            return "Noggles Pro Max";
        }
        return "";
    }

    function noggleTypeSVG(uint8 noggleType) internal pure returns (string memory) {
        if (noggleType == 1) {
            return NoggleSVGs.basic();
        } else if (noggleType == 2) {
            return NoggleSVGs.cool();
        } else if (noggleType == 3) {
            return NoggleSVGs.large();
        }
        return "";
    }

    function noggleColorName(uint8 noggleColor) internal pure returns (string memory) {
        if (noggleColor == 1) {
            return "Dark Plum";
        } else if (noggleColor == 2) {
            return "Warm Red";
        } else if (noggleColor == 3) {
            return "Peppermint";
        } else if (noggleColor == 4) {
            return "Cold Blue";
        } else if (noggleColor == 5) {
            return "Ring-a-Ding";
        }
        return "";
    }

    function noggleColorHex(uint8 noggleColor) internal pure returns (string memory) {
        if (noggleColor == 1) {
            return "513340";
        } else if (noggleColor == 2) {
            return "bd2d24";
        } else if (noggleColor == 3) {
            return "4ab49a";
        } else if (noggleColor == 4) {
            return "0827f5";
        } else if (noggleColor == 5) {
            return "f0c14d";
        }
        return "";
    }

    function backgroundColorName(uint8 background) internal pure returns (string memory) {
        if (background == 1) {
            return "Douglas Fir";
        } else if (background == 2) {
            return "Night";
        } else if (background == 3) {
            return "Rooftop";
        } else if (background == 4) {
            return "Mistletoe";
        } else if (background == 5) {
            return "Spice";
        }
        return "";
    }

    function backgroundColorHex(uint8 background) internal pure returns (string memory) {
        if (background == 1) {
            return "3e5d25";
        } else if (background == 2) {
            return "100d98";
        } else if (background == 3) {
            return "403037";
        } else if (background == 4) {
            return "326849";
        } else if (background == 5) {
            return "651d19";
        }
        return "";
    }

    function tintColorName(uint8 tint) internal pure returns (string memory) {
        if (tint == 1) {
            return "Boot Black";
        } else if (tint == 2) {
            return "Fairydust";
        } else if (tint == 3) {
            return "Elf";
        } else if (tint == 4) {
            return "Plum";
        } else if (tint == 5) {
            return "Explorer";
        } else if (tint == 6) {
            return "Hot Cocoa";
        } else if (tint == 7) {
            return "Carrot";
        } else if (tint == 8) {
            return "Spruce";
        } else if (tint == 9) {
            return "Holly";
        } else if (tint == 10) {
            return "Sleigh";
        } else if (tint == 11) {
            return "Jolly";
        } else if (tint == 12) {
            return "Coal";
        } else if (tint == 13) {
            return "Snow White";
        }
        return "";
    }

    function tintColorHex(uint8 tint) internal pure returns (string memory) {
        if (tint == 1) {
            return "000000";
        } else if (tint == 2) {
            return "2a46ff";
        } else if (tint == 3) {
            return "f38b7c";
        } else if (tint == 4) {
            return "7c3c58";
        } else if (tint == 5) {
            return "16786c";
        } else if (tint == 6) {
            return "36262d";
        } else if (tint == 7) {
            return "cb7300";
        } else if (tint == 8) {
            return "06534a";
        } else if (tint == 9) {
            return "369f49";
        } else if (tint == 10) {
            return "ff0e0e";
        } else if (tint == 11) {
            return "fd5442";
        } else if (tint == 12) {
            return "453f41";
        } else if (tint == 13) {
            return "ffffff";
        }
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library OneThroughSixCharacterSVGs {
    function cardinal() internal pure returns (string memory) {
        return '<rect x="11" y="1" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="15" width="1" height="1" class="tintable"/>'
        '<rect x="12" y="15" width="1" height="1" class="tintable"/>'
        '<rect x="2" y="6" width="1" height="1" class="tintable"/>'
        '<rect x="10" y="2" width="3" height="1" class="tintable"/>'
        '<rect x="3" y="9" width="3" height="1" class="tintable"/>'
        '<rect x="2" y="8" width="3" height="1" class="tintable"/>'
        '<rect x="1" y="7" width="3" height="1" class="tintable"/>'
        '<rect x="11" y="3" width="3" height="1" class="tintable"/>'
        '<rect x="11" y="5" width="4" height="1" class="tintable"/>'
        '<rect x="10" y="6" width="4" height="1" class="tintable"/>'
        '<rect x="11" y="7" width="2" height="1" class="tintable"/>'
        '<rect x="10" y="8" width="3" height="1" class="tintable"/>'
        '<rect x="9" y="9" width="5" height="1" class="tintable"/>'
        '<rect x="4" y="10" width="11" height="1" class="tintable"/>'
        '<rect x="5" y="11" width="11" height="1" class="tintable"/>'
        '<rect x="6" y="12" width="10" height="1" class="tintable"/>'
        '<rect x="7" y="13" width="8" height="1" class="tintable"/>'
        '<rect x="8" y="14" width="6" height="1" class="tintable"/>'
        '<rect x="10" y="4" width="5" height="1" class="tintable"/>'
        '<rect x="9" y="16" width="1" height="5" fill="white"/>'
        '<rect x="12" y="16" width="1" height="5" fill="white"/>'
        '<rect x="9" y="21" width="2" height="1" fill="white"/>'
        '<rect x="12" y="21" width="2" height="1" fill="white"/>'
        '<rect x="13" y="7" width="1" height="2" fill="black"/>'
        '<rect x="16" y="7" width="2" height="3" fill="#CB7300"/>'
        '<rect x="18" y="8" width="1" height="1" fill="#CB7300"/>'
        '<rect x="14" y="6" width="1" height="4" fill="black"/>'
        '<rect x="15" y="5" width="1" height="6" fill="black"/>';
    }

    function swan() internal pure returns (string memory) {
        return '<rect y="14" width="24" height="10" class="tintable"/>'
        '<rect x="1" y="8" width="1" height="1" fill="white"/>' '<rect x="6" y="9" width="1" height="1" fill="white"/>'
        '<rect x="2" y="9" width="1" height="1" fill="white"/>' '<rect x="3" y="10" width="1" height="1" fill="white"/>'
        '<rect x="4" y="11" width="1" height="1" fill="white"/>'
        '<rect x="5" y="10" width="1" height="3" fill="white"/>'
        '<rect x="6" y="11" width="1" height="3" fill="white"/>' '<rect x="7" y="8" width="1" height="3" fill="white"/>'
        '<rect x="13" y="7" width="1" height="4" fill="white"/>'
        '<rect x="7" y="12" width="1" height="2" fill="white"/>'
        '<rect x="13" y="12" width="1" height="2" fill="white"/>'
        '<rect x="8" y="7" width="5" height="5" fill="white"/>' '<rect x="8" y="13" width="5" height="1" fill="white"/>'
        '<rect x="14" y="7" width="1" height="7" fill="white"/>'
        '<rect x="15" y="8" width="1" height="6" fill="white"/>'
        '<rect x="16" y="9" width="1" height="5" fill="white"/>'
        '<rect x="17" y="3" width="1" height="10" fill="white"/>'
        '<rect x="18" y="3" width="1" height="1" fill="white"/>'
        '<rect x="19" y="4" width="1" height="5" fill="white"/>'
        '<rect x="21" y="7" width="1" height="2" fill="white"/>'
        '<rect x="20" y="7" width="1" height="1" fill="white"/>'
        '<rect x="19" y="9" width="3" height="1" fill="black"/>'
        '<rect x="20" y="8" width="1" height="1" fill="black"/>'
        '<rect x="20" y="10" width="1" height="1" fill="#CB7300"/>';
    }

    function blockhead() internal pure returns (string memory) {
        return '<rect x="6" y="2" width="10" height="1" fill="#CB7300"/>'
        '<rect x="11" y="3" width="5" height="1" fill="#CB7300"/>'
        '<rect x="11" y="4" width="7" height="1" fill="#CB7300"/>'
        '<rect x="6" y="4" width="4" height="1" fill="#CB7300"/>'
        '<rect x="6" y="21" width="5" height="1" fill="#CB7300"/>'
        '<rect x="12" y="21" width="5" height="1" fill="#CB7300"/>'
        '<rect x="6" y="5" width="10" height="3" fill="#F38B7C"/>'
        '<rect x="5" y="8" width="13" height="2" fill="#F38B7C"/>'
        '<rect x="15" y="10" width="3" height="1" fill="#F38B7C"/>'
        '<rect x="13" y="10" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="17" y="17" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="5" y="17" width="2" height="1" fill="#F38B7C"/>'
        '<rect x="12" y="11" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="14" y="11" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="11" y="10" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="11" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="6" y="10" width="4" height="1" fill="#F38B7C"/>'
        '<rect x="6" y="11" width="3" height="1" fill="#F38B7C"/>'
        '<rect x="6" y="12" width="10" height="1" fill="#F38B7C"/>'
        '<rect x="9" y="11" width="1" height="1" fill="black"/>'
        '<rect x="7" y="18" width="4" height="3" fill="black"/>'
        '<rect x="12" y="18" width="4" height="3" fill="black"/>'
        '<rect x="10" y="10" width="1" height="1" fill="black"/>'
        '<rect x="11" y="11" width="1" height="1" fill="black"/>'
        '<rect x="12" y="10" width="1" height="1" fill="black"/>'
        '<rect x="13" y="11" width="1" height="1" fill="black"/>'
        '<rect x="16" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="14" width="1" height="3" class="tintable"/>'
        '<rect x="15" y="14" width="1" height="4" class="tintable"/>'
        '<rect x="13" y="13" width="2" height="5" class="tintable"/>'
        '<rect x="8" y="13" width="4" height="5" class="tintable"/>'
        '<rect x="5" y="13" width="2" height="4" class="tintable"/>'
        '<rect x="14" y="10" width="1" height="1" fill="black"/>'
        '<rect x="15" y="11" width="1" height="1" fill="black"/>';
    }

    function dad() internal pure returns (string memory) {
        return 'return <rect x="11" y="1" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="9" y="3" width="1" height="2" fill="#FF0E0E"/>'
        '<rect x="10" y="2" width="3" height="1" fill="#FF0E0E"/>'
        '<rect x="10" y="4" width="3" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="6" width="3" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="3" width="3" height="1" fill="white"/>' '<rect x="8" y="5" width="1" height="1" fill="white"/>'
        '<rect x="11" y="12" width="1" height="1" fill="white"/>'
        '<rect x="12" y="5" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="10" y="5" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="11" y="5" width="1" height="1" fill="black"/>'
        '<rect x="7" y="7" width="1" height="1" fill="#36262D"/>'
        '<rect x="9" y="8" width="1" height="1" fill="#36262D"/>'
        '<rect x="15" y="7" width="1" height="1" fill="#36262D"/>'
        '<rect x="15" y="9" width="1" height="1" fill="#36262D"/>'
        '<rect x="15" y="13" width="1" height="1" fill="#36262D"/>'
        '<rect x="15" y="11" width="1" height="1" fill="#36262D"/>'
        '<rect x="13" y="8" width="1" height="1" fill="#36262D"/>'
        '<rect x="9" y="8" width="1" height="1" fill="#36262D"/>'
        '<rect x="9" y="10" width="1" height="1" fill="#36262D"/>'
        '<rect x="9" y="12" width="1" height="1" fill="#36262D"/>'
        '<rect x="9" y="14" width="1" height="1" fill="#36262D"/>'
        '<rect x="7" y="9" width="1" height="1" fill="#36262D"/>'
        '<rect x="7" y="9" width="1" height="1" fill="#36262D"/>'
        '<rect x="7" y="13" width="1" height="1" fill="#36262D"/>'
        '<rect x="13" y="10" width="1" height="1" fill="#36262D"/>'
        '<rect x="13" y="12" width="1" height="1" fill="#36262D"/>'
        '<rect x="13" y="14" width="1" height="1" fill="#36262D"/>'
        '<rect x="9" y="7" width="1" height="1" fill="#453F41"/>'
        '<rect x="7" y="8" width="1" height="1" fill="#453F41"/>'
        '<rect x="13" y="7" width="1" height="1" fill="#453F41"/>'
        '<rect x="9" y="7" width="1" height="1" fill="#453F41"/>'
        '<rect x="9" y="9" width="1" height="1" fill="#453F41"/>'
        '<rect x="9" y="11" width="1" height="1" fill="#453F41"/>'
        '<rect x="9" y="13" width="1" height="1" fill="#453F41"/>'
        '<rect x="7" y="10" width="1" height="1" fill="#453F41"/>'
        '<rect x="7" y="14" width="1" height="1" fill="#453F41"/>'
        '<rect x="7" y="15" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="15" y="15" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="7" y="12" width="1" height="1" fill="#453F41"/>'
        '<rect x="13" y="9" width="1" height="1" fill="#453F41"/>'
        '<rect x="13" y="11" width="1" height="1" fill="#453F41"/>'
        '<rect x="13" y="13" width="1" height="1" fill="#453F41"/>'
        '<rect x="15" y="8" width="1" height="1" fill="#453F41"/>'
        '<rect x="15" y="10" width="1" height="1" fill="#453F41"/>'
        '<rect x="15" y="12" width="1" height="1" fill="#453F41"/>'
        '<rect x="10" y="13" width="3" height="1" fill="black"/>'
        '<rect x="10" y="14" width="1" height="1" fill="black"/>'
        '<rect x="12" y="14" width="1" height="1" fill="black"/>'
        '<rect x="12" y="15" width="2" height="4" fill="black"/>'
        '<rect x="9" y="16" width="2" height="4" fill="black"/>'
        '<rect x="10" y="20" width="1" height="2" fill="black"/>'
        '<rect x="9" y="21" width="1" height="1" fill="black"/>'
        '<rect x="12" y="20" width="1" height="1" fill="black"/>'
        '<rect x="12" y="21" width="2" height="1" fill="black"/>'
        '<rect x="14" y="11" width="1" height="1" fill="#06534A"/>'
        '<rect x="15" y="14" width="1" height="1" fill="#06534A"/>'
        '<rect x="11" y="15" width="1" height="1" fill="#06534A"/>'
        '<rect x="14" y="16" width="1" height="1" fill="#06534A"/>'
        '<rect x="15" y="17" width="1" height="1" fill="#06534A"/>'
        '<rect x="14" y="18" width="1" height="1" fill="#06534A"/>'
        '<rect x="11" y="18" width="1" height="1" fill="#06534A"/>'
        '<rect x="8" y="17" width="1" height="1" fill="#06534A"/>'
        '<rect x="7" y="18" width="1" height="1" fill="#06534A"/>'
        '<rect x="6" y="19" width="1" height="1" fill="#06534A"/>'
        '<rect x="7" y="20" width="1" height="1" fill="#06534A"/>'
        '<rect x="8" y="19" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="16" y="18" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="17" y="11" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="5" y="13" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="5" y="11" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="8" y="12" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="17" y="14" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="14" y="15" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="6" y="17" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="11" y="20" width="1" height="1" fill="#2A46FF"/>'
        '<rect x="12" y="19" width="2" height="1" fill="#06534A"/>'
        '<rect x="8" y="10" width="1" height="1" fill="#06534A"/>'
        '<rect x="7" y="11" width="1" height="1" fill="#06534A"/>'
        '<rect x="6" y="12" width="1" height="1" fill="#06534A"/>'
        '<rect x="8" y="13" width="1" height="1" fill="#06534A"/>'
        '<rect x="16" y="12" width="1" height="2" fill="#06534A"/>'
        '<rect x="10" y="7" width="1" height="6" fill="white"/>'
        '<rect x="12" y="7" width="1" height="6" fill="white"/>'
        '<rect x="11" y="7" width="1" height="5" class="tintable"/>';
    }

    function troutSniffer() internal pure returns (string memory) {
        return '<rect x="8" y="7" width="7" height="7" class="tintable"/>'
        '<rect x="10" y="4" width="3" height="3" fill="#F38B7C"/>'
        '<rect x="10" y="3" width="3" height="1" fill="#CB7300"/>'
        '<rect x="11" y="4" width="2" height="1" fill="#CB7300"/>'
        '<rect x="9" y="5" width="1" height="1" fill="#FD5442"/>'
        '<rect x="5" y="7" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="7" width="1" height="1" class="tintable"/>'
        '<rect x="5" y="9" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="9" width="1" height="1" class="tintable"/>'
        '<rect x="5" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="11" width="1" height="1" class="tintable"/>'
        '<rect x="5" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="13" width="1" height="1" class="tintable"/>'
        '<rect x="5" y="15" width="1" height="1" class="tintable"/>'
        '<rect x="17" y="15" width="1" height="1" class="tintable"/>'
        '<rect x="13" y="5" width="1" height="1" fill="#FD5442"/>'
        '<rect x="16" y="16" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="6" y="16" width="1" height="1" fill="#F38B7C"/>'
        '<rect x="8" y="7" width="1" height="1" fill="#06534A"/>'
        '<rect x="9" y="8" width="1" height="1" fill="#06534A"/>'
        '<rect x="10" y="9" width="1" height="1" fill="#06534A"/>'
        '<rect x="11" y="10" width="1" height="1" fill="#06534A"/>'
        '<rect x="12" y="11" width="1" height="1" fill="#06534A"/>'
        '<rect x="13" y="12" width="1" height="1" fill="#06534A"/>'
        '<rect x="12" y="14" width="2" height="6" fill="#06534A"/>'
        '<rect x="9" y="14" width="2" height="6" fill="#06534A"/>'
        '<rect width="2" height="1" transform="matrix(1 0 0 -1 9 21)" fill="#CB7300"/>'
        '<rect width="2" height="1" transform="matrix(1 0 0 -1 12 21)" fill="#CB7300"/>'
        '<rect width="3" height="1" transform="matrix(1 0 0 -1 12 22)" fill="#08030D"/>'
        '<rect width="3" height="1" transform="matrix(1 0 0 -1 8 22)" fill="#08030D"/>'
        '<rect x="9" y="13" width="6" height="1" fill="#06534A"/>'
        '<rect x="16" y="7" width="1" height="9" class="tintable"/>'
        '<rect x="6" y="7" width="1" height="9" class="tintable"/>';
    }

    function elf() internal pure returns (string memory) {
        return '<rect x="9" y="11" width="5" height="3" fill="black"/>'
        '<rect x="12" y="21" width="4" height="1" fill="black"/>'
        '<rect x="7" y="21" width="4" height="1" fill="black"/>'
        '<rect x="7" y="20" width="1" height="1" fill="black"/>'
        '<rect x="15" y="20" width="1" height="1" fill="black"/>'
        '<rect x="12" y="14" width="2" height="7" fill="#CB7300"/>'
        '<rect x="9" y="14" width="2" height="7" fill="#CB7300"/>'
        '<rect x="9" y="6" width="5" height="5" class="tintable"/>'
        '<rect x="8" y="3" width="1" height="1" fill="#FF0E0E"/>'
        '<rect x="9" y="2" width="1" height="1" class="tintable"/>'
        '<rect x="9" y="14" width="1" height="1" class="tintable"/>'
        '<rect x="13" y="14" width="1" height="1" class="tintable"/>'
        '<rect x="7" y="9" width="1" height="7" class="tintable"/>'
        '<rect x="15" y="9" width="1" height="7" class="tintable"/>'
        '<rect x="9" y="3" width="2" height="1" class="tintable"/>'
        '<rect x="9" y="5" width="4" height="1" class="tintable"/>'
        '<rect x="9" y="6" width="5" height="1" fill="white"/>' '<rect x="9" y="7" width="2" height="1" fill="white"/>'
        '<rect x="9" y="8" width="1" height="1" fill="white"/>' '<rect x="7" y="16" width="1" height="1" fill="white"/>'
        '<rect width="1" height="1" transform="matrix(1 0 0 -1 15 17)" fill="white"/>'
        '<rect width="1" height="1" transform="matrix(1 0 0 -1 15 18)" fill="#F38B7C"/>'
        '<rect width="1" height="1" transform="matrix(1 0 0 -1 7 18)" fill="#F38B7C"/>'
        '<rect x="13" y="8" width="1" height="1" fill="white"/>'
        '<rect x="12" y="7" width="2" height="1" fill="white"/>'
        '<rect x="9" y="4" width="3" height="1" fill="#F0C14D"/>'
        '<rect x="10" y="11" width="3" height="1" fill="#F0C14D"/>'
        '<rect x="10" y="13" width="3" height="1" fill="#F0C14D"/>'
        '<rect x="10" y="12" width="1" height="1" fill="#F0C14D"/>'
        '<rect x="12" y="12" width="1" height="1" fill="#F0C14D"/>';
    }
}