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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
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

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "./forks/BoringBatchable.sol";

interface Factory {
    function param() external view returns (address);
}

error NOT_OWNER();
error NOT_OWNER_OR_WHITELISTED();
error INVALID_ADDRESS();
error INVALID_TIME();
error PAYER_IN_DEBT();
error INACTIVE_STREAM();
error ACTIVE_STREAM();
error STREAM_ACTIVE_OR_REDEEMABLE();
error STREAM_ENDED();
error STREAM_DOES_NOT_EXIST();
error TOKEN_NOT_ADDED();
error INVALID_AMOUNT();
error ALREADY_WHITELISTED();
error NOT_WHITELISTED();

/// @title LlamaPayV2 Payer Contract
/// @author nemusona
contract LlamaPayV2Payer is ERC721, BoringBatchable {
    using SafeTransferLib for ERC20;

    struct Token {
        uint256 balance;
        uint256 totalPaidPerSec;
        uint208 divisor;
        uint48 lastUpdate; /// Overflows when we're all dead
    }

    struct Stream {
        uint208 amountPerSec; /// Can stream 4.11 x 10^42 tokens per sec
        uint48 lastPaid;
        address token;
        uint48 starts;
        uint48 ends;
    }

    address public owner;
    string public constant baseURI = "https://nft.llamapay.io/stream/";
    uint256 public nextTokenId;

    mapping(address => Token) public tokens;
    mapping(uint256 => Stream) public streams;
    mapping(address => uint256) public payerWhitelists; /// Allows other addresses to interact on owner behalf
    mapping(address => mapping(uint256 => address)) public redirects; /// Allows stream funds to be sent to another address
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public streamWhitelists; /// Whitelist for addresses authorized to withdraw from stream
    mapping(uint256 => uint256) public debts; /// Tracks debt for streams
    mapping(uint256 => uint256) public redeemables; /// Tracks redeemable amount for streams

    event Deposit(address indexed token, address indexed from, uint256 amount);
    event WithdrawPayer(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event WithdrawPayerAll(
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event Withdraw(
        uint256 id,
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event WithdrawWithRedirect(
        uint256 id,
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event WithdrawAll(
        uint256 id,
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event WithdrawAllWithRedirect(
        uint256 id,
        address indexed token,
        address indexed to,
        uint256 amount
    );
    event CreateStream(
        uint256 id,
        address indexed token,
        address indexed to,
        uint256 amountPerSec,
        uint48 starts,
        uint48 ends
    );
    event ModifyStream(uint256 id, uint208 newAmountPerSec, uint48 newEnd);
    event StopStream(uint256 id);
    event ResumeStream(uint256 id);
    event BurnStream(uint256 id);
    event AddPayerWhitelist(address indexed whitelisted);
    event RemovePayerWhitelist(address indexed removed);
    event AddRedirectStream(uint256 id, address indexed redirected);
    event RemoveRedirectStream(uint256 id);
    event AddStreamWhitelist(uint256 id, address indexed whitelisted);
    event RemoveStreamWhitelist(uint256 id, address indexed removed);
    event UpdateToken(address indexed token);
    event UpdateStream(uint256 id);
    event RepayDebt(uint256 id, address indexed token, uint256 amount);
    event RepayAllDebt(uint256 id, address indexed token, uint256 amount);

    constructor() ERC721("LlamaPay V2 Stream", "LLAMAPAY-V2-STREAM") {
        owner = Factory(msg.sender).param(); /// Call factory param to get owner address
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NOT_OWNER();
        _;
    }

    modifier onlyOwnerOrWhitelisted() {
        if (msg.sender != owner && payerWhitelists[msg.sender] != 1)
            revert NOT_OWNER_OR_WHITELISTED();
        _;
    }

    function tokenURI(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (ownerOf(_id) == address(0)) revert STREAM_DOES_NOT_EXIST();
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(block.chainid),
                    "/",
                    Strings.toHexString(uint160(address(this)), 20),
                    "/",
                    Strings.toString(_id)
                )
            );
    }

    /// @notice deposit into vault (anybody can deposit)
    /// @param _token token
    /// @param _amount amount (native token decimal)
    function deposit(address _token, uint256 _amount) external {
        /// No owner check makes it where people can deposit on behalf
        ERC20 token = ERC20(_token);
        /// Stores token divisor if it is the first time being deposited
        /// Saves on having to call decimals() for conversions afterwards
        if (tokens[_token].divisor == 0) {
            tokens[_token].divisor = uint208(10**(20 - token.decimals()));
        }
        tokens[_token].balance += _amount * uint256(tokens[_token].divisor);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    /// @notice withdraw tokens that have not been streamed yet
    /// @param _token token
    /// @param _amount amount (native token decimals)
    function withdrawPayer(address _token, uint256 _amount)
        external
        onlyOwnerOrWhitelisted
    {
        /// Update token balance
        /// Makes it where payer cannot rug payee by withdrawing tokens before payee does from stream
        _updateToken(_token);
        uint256 toDeduct = _amount * uint256(tokens[_token].divisor);
        /// Will revert if not enough after updating Token
        tokens[_token].balance -= toDeduct;
        ERC20(_token).safeTransfer(msg.sender, _amount);
        emit WithdrawPayer(_token, msg.sender, _amount);
    }

    /// @notice same as above but all available tokens
    /// @param _token token
    function withdrawPayerAll(address _token) external onlyOwnerOrWhitelisted {
        Token storage token = _updateToken(_token);
        uint256 toSend = token.balance / uint256(token.divisor);
        tokens[_token].balance = 0;
        ERC20(_token).safeTransfer(msg.sender, toSend);
        emit WithdrawPayerAll(_token, msg.sender, toSend);
    }

    /// @notice withdraw from stream
    /// @param _id token id
    /// @param _amount amount (native decimals)
    function withdraw(uint256 _id, uint256 _amount) external {
        address nftOwner = ownerOrNftOwnerOrWhitelisted(_id);

        /// Update stream to update available balances
        Stream storage stream = _updateStream(_id);

        /// Reverts if payee is going to rug
        redeemables[_id] -= _amount * uint256(tokens[stream.token].divisor);

        ERC20(stream.token).safeTransfer(nftOwner, _amount);
        emit Withdraw(_id, stream.token, nftOwner, _amount);
    }

    /// @notice withdraw all from stream
    /// @param _id token id
    function withdrawAll(uint256 _id) external {
        address nftOwner = ownerOrNftOwnerOrWhitelisted(_id);

        /// Update stream to update available balances
        Stream storage stream = _updateStream(_id);

        uint256 toRedeem = redeemables[_id] /
            uint256(tokens[stream.token].divisor);
        redeemables[_id] = 0;
        ERC20(stream.token).safeTransfer(nftOwner, toRedeem);
        emit WithdrawAll(_id, stream.token, nftOwner, toRedeem);
    }

    /// @notice withdraw from stream redirect
    /// @param _id token id
    /// @param _amount amount (native decimals)
    function withdrawWithRedirect(uint256 _id, uint256 _amount) external {
        address nftOwner = ownerOrNftOwnerOrWhitelisted(_id);

        /// Update stream to update available balances
        Stream storage stream = _updateStream(_id);

        /// Reverts if payee is going to rug
        redeemables[_id] -= _amount * uint256(tokens[stream.token].divisor);

        address to;
        address redirect = redirects[nftOwner][_id];
        if (redirect == address(0)) {
            to = nftOwner;
        } else {
            to = redirect;
        }

        ERC20(stream.token).safeTransfer(to, _amount);
        emit WithdrawWithRedirect(_id, stream.token, to, _amount);
    }

    /// @notice withdraw all from stream redirect
    /// @param _id token id
    function withdrawAllWithRedirect(uint256 _id) external {
        address nftOwner = ownerOrNftOwnerOrWhitelisted(_id);

        /// Update stream to update available balances
        Stream storage stream = _updateStream(_id);

        /// Reverts if payee is going to rug
        uint256 toRedeem = redeemables[_id] /
            uint256(tokens[stream.token].divisor);
        redeemables[_id] = 0;

        address to;
        address redirect = redirects[nftOwner][_id];
        if (redirect == address(0)) {
            to = nftOwner;
        } else {
            to = redirect;
        }

        ERC20(stream.token).safeTransfer(to, toRedeem);
        emit WithdrawAllWithRedirect(_id, stream.token, to, toRedeem);
    }

    /// @notice creates stream
    /// @param _token token
    /// @param _to recipient
    /// @param _amountPerSec amount per sec (20 decimals)
    /// @param _starts stream to start
    /// @param _ends stream to end
    function createStream(
        address _token,
        address _to,
        uint208 _amountPerSec,
        uint48 _starts,
        uint48 _ends
    ) external {
        uint256 id = _createStream(_token, _to, _amountPerSec, _starts, _ends);
        emit CreateStream(id, _token, _to, _amountPerSec, _starts, _ends);
    }

    /// @notice modifies current stream
    /// @param _id token id
    /// @param _newAmountPerSec modified amount per sec (20 decimals)
    /// @param _newEnd new end time
    function modifyStream(
        uint256 _id,
        uint208 _newAmountPerSec,
        uint48 _newEnd
    ) external onlyOwnerOrWhitelisted {
        Stream storage stream = _updateStream(_id);
        if (_newAmountPerSec == 0) revert INVALID_AMOUNT();
        /// Prevents people from setting end to time already "paid out"
        if (tokens[stream.token].lastUpdate >= _newEnd) revert INVALID_TIME();

        /// Check if stream is active
        /// Prevents miscalculation in totalPaidPerSec
        if (stream.lastPaid > 0) {
            tokens[stream.token].totalPaidPerSec += uint256(_newAmountPerSec);
            unchecked {
                tokens[stream.token].totalPaidPerSec -= uint256(
                    stream.amountPerSec
                );
            }
        }
        streams[_id].amountPerSec = _newAmountPerSec;
        streams[_id].ends = _newEnd;
        emit ModifyStream(_id, _newAmountPerSec, _newEnd);
    }

    /// @notice Stops current stream
    /// @param _id token id
    function stopStream(uint256 _id) external onlyOwnerOrWhitelisted {
        Stream storage stream = _updateStream(_id);
        if (stream.lastPaid == 0) revert INACTIVE_STREAM();
        uint256 amountPerSec = uint256(stream.amountPerSec);
        unchecked {
            /// Track owed until stopStream call
            debts[_id] +=
                (block.timestamp - uint256(tokens[stream.token].lastUpdate)) *
                amountPerSec;
            streams[_id].lastPaid = 0;
            tokens[stream.token].totalPaidPerSec -= amountPerSec;
        }
        emit StopStream(_id);
    }

    /// @notice resumes a stopped stream
    /// @param _id token id
    function resumeStream(uint256 _id) external onlyOwnerOrWhitelisted {
        Stream storage stream = _updateStream(_id);
        if (stream.lastPaid > 0) revert ACTIVE_STREAM();
        if (block.timestamp >= stream.ends) revert STREAM_ENDED();
        if (block.timestamp > tokens[stream.token].lastUpdate)
            revert PAYER_IN_DEBT();

        tokens[stream.token].totalPaidPerSec += uint256(stream.amountPerSec);
        streams[_id].lastPaid = uint48(block.timestamp);
        emit ResumeStream(_id);
    }

    /// @notice burns an inactive and withdrawn stream
    /// @param _id token id
    function burnStream(uint256 _id) external {
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        /// Prevents somebody from burning an active stream or a stream with balance in it
        if (redeemables[_id] > 0 || streams[_id].lastPaid > 0 || debts[_id] > 0)
            revert STREAM_ACTIVE_OR_REDEEMABLE();

        /// Free up storage
        delete streams[_id];
        delete debts[_id];
        delete redeemables[_id];
        _burn(_id);
        emit BurnStream(_id);
    }

    /// @notice manually update stream
    /// @param _id token id
    function updateStream(uint256 _id) external onlyOwnerOrWhitelisted {
        _updateStream(_id);
    }

    /// @notice repay debt
    /// @param _id token id
    /// @param _amount amount to repay (native decimals)
    function repayDebt(uint256 _id, uint256 _amount) external {
        ownerOrNftOwnerOrWhitelisted(_id);

        /// Update stream to update balances
        Stream storage stream = _updateStream(_id);
        uint256 toRepay;
        unchecked {
            toRepay = _amount * uint256(tokens[stream.token].divisor);
            /// Add to redeemable to payee
            redeemables[_id] += toRepay;
        }
        /// Reverts if debt cannot be paid
        tokens[stream.token].balance -= toRepay;
        /// Reverts if paying too much debt
        debts[_id] -= toRepay;
        emit RepayDebt(_id, stream.token, _amount);
    }

    /// @notice attempt to repay all debt
    /// @param _id token id
    function repayAllDebt(uint256 _id) external {
        ownerOrNftOwnerOrWhitelisted(_id);

        /// Update stream to update balances
        Stream storage stream = _updateStream(_id);
        uint256 totalDebt = debts[_id];
        uint256 balance = tokens[stream.token].balance;
        uint256 toPay;
        unchecked {
            if (balance >= totalDebt) {
                tokens[stream.token].balance -= totalDebt;
                debts[_id] = 0;
                toPay = totalDebt;
            } else {
                debts[_id] = totalDebt - balance;
                tokens[stream.token].balance = 0;
                toPay = balance;
            }
        }
        redeemables[_id] += toPay;
        emit RepayAllDebt(
            _id,
            stream.token,
            toPay / uint256(tokens[stream.token].divisor)
        );
    }

    /// @notice add address to payer whitelist
    /// @param _toAdd address to whitelist
    function addPayerWhitelist(address _toAdd) external onlyOwner {
        if (_toAdd == address(0)) revert INVALID_ADDRESS();
        if (payerWhitelists[_toAdd] == 1) revert ALREADY_WHITELISTED();
        payerWhitelists[_toAdd] = 1;
        emit AddPayerWhitelist(_toAdd);
    }

    /// @notice remove address to payer whitelist
    /// @param _toRemove address to remove from whitelist
    function removePayerWhitelist(address _toRemove) external onlyOwner {
        if (_toRemove == address(0)) revert INVALID_ADDRESS();
        if (payerWhitelists[_toRemove] == 0) revert NOT_WHITELISTED();
        payerWhitelists[_toRemove] = 0;
        emit RemovePayerWhitelist(_toRemove);
    }

    /// @notice add redirect to stream
    /// @param _id token id
    /// @param _redirectTo address to redirect funds to
    function addRedirectStream(uint256 _id, address _redirectTo) external {
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        if (_redirectTo == address(0)) revert INVALID_ADDRESS();
        redirects[msg.sender][_id] = _redirectTo;
        emit AddRedirectStream(_id, _redirectTo);
    }

    /// @notice remove redirect to stream
    /// @param _id token id
    function removeRedirectStream(uint256 _id) external {
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        delete redirects[msg.sender][_id];
        emit RemoveRedirectStream(_id);
    }

    /// @notice add whitelist to stream
    /// @param _id token id
    /// @param _toAdd address to whitelist
    function addStreamWhitelist(uint256 _id, address _toAdd) external {
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        if (_toAdd == address(0)) revert INVALID_ADDRESS();
        if (streamWhitelists[msg.sender][_id][_toAdd] == 1)
            revert ALREADY_WHITELISTED();
        streamWhitelists[msg.sender][_id][_toAdd] = 1;
        emit AddStreamWhitelist(_id, _toAdd);
    }

    /// @notice remove whitelist to stream
    /// @param _id token id
    /// @param _toRemove address to remove from whitelist
    function removeStreamWhitelist(uint256 _id, address _toRemove) external {
        if (_toRemove == address(0)) revert INVALID_ADDRESS();
        if (msg.sender != ownerOf(_id)) revert NOT_OWNER();
        if (streamWhitelists[msg.sender][_id][_toRemove] == 0)
            revert NOT_WHITELISTED();
        streamWhitelists[msg.sender][_id][_toRemove] = 0;
        emit RemoveStreamWhitelist(_id, _toRemove);
    }

    /// @notice view only function to see withdrawable
    /// @param _id token id
    /// @return lastUpdate last time Token has been updated
    /// @return debt debt owed to stream (native decimals)
    /// @return withdrawableAmount amount withdrawable by payee (native decimals)
    function withdrawable(uint256 _id)
        external
        view
        returns (
            uint256 lastUpdate,
            uint256 debt,
            uint256 withdrawableAmount
        )
    {
        Stream storage stream = streams[_id];
        Token storage token = tokens[stream.token];
        uint256 starts = uint256(stream.starts);
        uint256 ends = uint256(stream.ends);
        uint256 amountPerSec = uint256(stream.amountPerSec);
        uint256 divisor = uint256(token.divisor);
        uint256 streamed;
        unchecked {
            streamed = (block.timestamp - lastUpdate) * token.totalPaidPerSec;
        }

        if (token.balance >= streamed) {
            lastUpdate = block.timestamp;
        } else {
            lastUpdate =
                uint256(token.lastUpdate) +
                (token.balance / token.totalPaidPerSec);
        }

        /// Inactive or cancelled stream
        if (stream.lastPaid == 0 || starts > block.timestamp) {
            return (0, 0, 0);
        }

        uint256 start = max(uint256(stream.lastPaid), starts);
        uint256 stop = min(ends, lastUpdate);
        // If lastUpdate isn't block.timestamp and greater than ends, there is debt.
        if (lastUpdate != block.timestamp && ends > lastUpdate) {
            debt =
                (min(block.timestamp, ends) - max(lastUpdate, starts)) *
                amountPerSec;
        }
        withdrawableAmount = (stop - start) * amountPerSec;

        withdrawableAmount = (withdrawableAmount + redeemables[_id]) / divisor;
        debt = (debt + debts[_id]) / divisor;
    }

    /// @notice create stream
    /// @param _token token
    /// @param _to recipient
    /// @param _amountPerSec amount per sec (20 decimals)
    /// @param _starts stream to start
    /// @param _ends stream to end
    function _createStream(
        address _token,
        address _to,
        uint208 _amountPerSec,
        uint48 _starts,
        uint48 _ends
    ) private onlyOwnerOrWhitelisted returns (uint256 id) {
        if (_starts >= _ends) revert INVALID_TIME();
        if (_to == address(0)) revert INVALID_ADDRESS();
        if (_amountPerSec == 0) revert INVALID_AMOUNT();

        Token storage token = _updateToken(_token);
        if (block.timestamp > token.lastUpdate) revert PAYER_IN_DEBT();

        id = nextTokenId;

        /// calculate owed if stream already ended on creation
        uint256 owed;
        uint256 lastPaid;
        uint256 starts = uint256(_starts);
        uint256 amountPerSec = uint256(_amountPerSec);
        if (block.timestamp > _ends) {
            owed = (uint256(_ends) - starts) * amountPerSec;
        }
        /// calculated owed if start is before block.timestamp
        else if (block.timestamp > starts) {
            owed = (block.timestamp - starts) * amountPerSec;
            tokens[_token].totalPaidPerSec += amountPerSec;
            lastPaid = block.timestamp;
            /// If started at timestamp or starts in the future
        } else if (starts >= block.timestamp) {
            tokens[_token].totalPaidPerSec += amountPerSec;
            lastPaid = block.timestamp;
        }

        unchecked {
            /// If can pay owed then directly send it to payee
            if (token.balance >= owed) {
                tokens[_token].balance -= owed;
                redeemables[id] = owed;
            } else {
                /// If cannot pay debt, then add to debt and send entire balance to payee
                uint256 balance = token.balance;
                tokens[_token].balance = 0;
                debts[id] = owed - balance;
                redeemables[id] = balance;
            }
            nextTokenId++;
        }

        streams[id] = Stream({
            amountPerSec: _amountPerSec,
            token: _token,
            lastPaid: uint48(lastPaid),
            starts: _starts,
            ends: _ends
        });

        _safeMint(_to, id);
    }

    /// @notice updates token balances
    /// @param _token token to update
    function _updateToken(address _token)
        private
        returns (Token storage token)
    {
        token = tokens[_token];
        if (token.divisor == 0) revert TOKEN_NOT_ADDED();
        /// Streamed from last update to called
        unchecked {
            uint256 streamed = (block.timestamp - uint256(token.lastUpdate)) *
                token.totalPaidPerSec;
            if (token.balance >= streamed) {
                /// If enough to pay owed then deduct from balance and update to current timestamp
                tokens[_token].balance -= streamed;
                tokens[_token].lastUpdate = uint48(block.timestamp);
            } else {
                /// If not enough then get remainder paying as much as possible then calculating and adding time paid
                tokens[_token].lastUpdate += uint48(
                    token.balance / token.totalPaidPerSec
                );
                tokens[_token].balance = token.balance % token.totalPaidPerSec;
            }
        }
        emit UpdateToken(_token);
    }

    /// @notice update stream
    /// @param _id token id
    function _updateStream(uint256 _id)
        private
        returns (Stream storage stream)
    {
        if (ownerOf(_id) == address(0)) revert STREAM_DOES_NOT_EXIST();
        /// Update Token info to get last update
        stream = streams[_id];
        _updateToken(stream.token);
        unchecked {
            uint256 lastUpdate = uint256(tokens[stream.token].lastUpdate);
            uint256 amountPerSec = uint256(stream.amountPerSec);
            uint256 lastPaid = uint256(stream.lastPaid);
            uint256 starts = uint256(stream.starts);
            uint256 ends = uint256(stream.ends);
            /// If stream is inactive/cancelled
            if (lastPaid == 0) {
                /// Can only withdraw redeemable so do nothing
            }
            /// Stream not updated after start and has ended
            else if (
                /// Stream not updated after start
                starts > lastPaid &&
                /// Stream ended
                lastUpdate >= ends
            ) {
                /// Refund payer for:
                /// Stream last updated to stream start
                /// Stream ended to token last updated
                tokens[stream.token].balance +=
                    ((starts - lastPaid) + (lastUpdate - ends)) *
                    amountPerSec;
                /// Payee can redeem:
                /// Stream start to end
                redeemables[_id] = (ends - starts) * amountPerSec;
                /// Stream is now inactive
                streams[_id].lastPaid = 0;
                tokens[stream.token].totalPaidPerSec -= amountPerSec;
            }
            /// Stream started but has not been updated from after start
            else if (
                /// Stream started
                lastUpdate >= starts &&
                /// Stream not updated after start
                starts > lastPaid
            ) {
                /// Refund payer for:
                /// Stream last updated to stream start
                tokens[stream.token].balance +=
                    (starts - lastPaid) *
                    amountPerSec;
                /// Payer can redeem:
                /// Stream start to last token update
                redeemables[_id] = (lastUpdate - starts) * amountPerSec;
                streams[_id].lastPaid = uint48(lastUpdate);
            }
            /// Stream has ended
            else if (
                /// Stream ended
                lastUpdate >= ends
            ) {
                /// Refund payer for:
                /// Stream end to last token update
                tokens[stream.token].balance +=
                    (lastUpdate - ends) *
                    amountPerSec;
                /// Add redeemable for:
                /// Stream last updated to stream end
                redeemables[_id] += (ends - lastPaid) * amountPerSec;
                /// Stream is now inactive
                streams[_id].lastPaid = 0;
                tokens[stream.token].totalPaidPerSec -= amountPerSec;
            }
            /// Stream is updated before stream starts
            else if (
                /// Stream not started
                starts > lastUpdate
            ) {
                /// Refund payer:
                /// Last stream update to last token update
                tokens[stream.token].balance +=
                    (lastUpdate - lastPaid) *
                    amountPerSec;
                /// update lastpaid to last token update
                streams[_id].lastPaid = uint48(lastUpdate);
            }
            /// Updated after start, and has not ended
            else if (
                /// Stream started
                lastPaid >= starts &&
                /// Stream has not ended
                ends > lastUpdate
            ) {
                /// Add redeemable for:
                /// stream last update to last token update
                redeemables[_id] += (lastUpdate - lastPaid) * amountPerSec;
                streams[_id].lastPaid = uint48(lastUpdate);
            }
        }
        emit UpdateStream(_id);
    }

    function ownerOrNftOwnerOrWhitelisted(uint256 _id)
        internal
        view
        returns (address nftOwner)
    {
        nftOwner = ownerOf(_id);
        if (
            msg.sender != nftOwner &&
            msg.sender != owner &&
            payerWhitelists[msg.sender] != 1 &&
            streamWhitelists[nftOwner][_id][msg.sender] != 1
        ) revert NOT_OWNER_OR_WHITELISTED();
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    error BatchError(bytes innerError);

    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure{
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert BatchError(_returnData);

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                _getRevertMsg(result);
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}