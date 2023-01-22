// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.15;

/// @title ImmutableArgs
/// @author zefram.eth, Saw-mon & Natalie
/// @notice Provides helper functions for reading immutable args from calldata
library ImmutableArgs {
    function addr() internal pure returns (address arg) {
        assembly {
            arg := shr(0x60, calldataload(sub(calldatasize(), 22)))
        }
    }

    /// @notice Reads an immutable arg with type address
    /// @param offset The offset of the arg in the packed data
    /// @return arg The arg value
    function addressAt(uint256 offset) internal pure returns (address arg) {
        uint256 start = _startOfImmutableArgs();
        assembly {
            arg := shr(0x60, calldataload(add(start, offset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param offset The offset of the arg in the packed data
    /// @return arg The arg value
    function uint256At(uint256 offset) internal pure returns (uint256 arg) {
        uint256 start = _startOfImmutableArgs();
        assembly {
            arg := calldataload(add(start, offset))
        }
    }

    function all() internal pure returns (bytes memory args) {
        uint256 start = _startOfImmutableArgs();
        unchecked {
            args = msg.data[start:msg.data.length - 2];
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _startOfImmutableArgs() private pure returns (uint256 offset) {
        assembly {
            //                                      read final 2 bytes of calldata, i.e. `extraLength`
            offset := sub(calldatasize(), shr(0xf0, calldataload(sub(calldatasize(), 2))))
        }
    }
}

// SPDX-License-Identifier: MIT
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

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ImmutableArgs} from "clones-with-immutable-args/ImmutableArgs.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {Q112} from "./libraries/constants/Q.sol";

import {RateModel} from "./RateModel.sol";

contract Ledger {
    using FixedPointMathLib for uint256;

    uint256 internal constant ONE = 1e12;

    uint256 internal constant BORROWS_SCALER = type(uint72).max * ONE; // uint72 is from borrowIndex type

    address public immutable FACTORY;

    address public immutable RESERVE;

    struct Cache {
        uint256 totalSupply;
        uint256 lastBalance;
        uint256 lastAccrualTime;
        uint256 borrowBase;
        uint256 borrowIndex;
    }

    /*//////////////////////////////////////////////////////////////
                             LENDER STORAGE
    //////////////////////////////////////////////////////////////*/

    uint112 public totalSupply;

    uint112 public lastBalance;

    uint32 public lastAccrualTime;

    uint184 public borrowBase;

    uint72 public borrowIndex;

    mapping(address => uint256) public borrows;

    /*//////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Highest 32 bits are the referral code, next 112 are the principle, lowest 112 are the shares.
    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            ERC2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 internal initialDomainSeparator;

    uint256 internal initialChainId;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                           INCENTIVE STORAGE
    //////////////////////////////////////////////////////////////*/

    struct Courier {
        address wallet;
        uint16 cut;
    }

    mapping(uint32 => Courier) public couriers;

    /*//////////////////////////////////////////////////////////////
                         GOVERNABLE PARAMETERS
    //////////////////////////////////////////////////////////////*/

    RateModel public rateModel;

    uint8 public reserveFactor;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address reserve) {
        FACTORY = msg.sender;
        RESERVE = reserve;
    }

    /// @notice The name of the banknote.
    function name() external view returns (string memory) {
        return string.concat("Aloe II ", asset().name());
    }

    /// @notice The symbol of the banknote.
    function symbol() external view returns (string memory) {
        return string.concat(asset().symbol(), "+");
    }

    /// @notice The number of decimals the banknote uses. Matches the underlying token.
    function decimals() external view returns (uint8) {
        return asset().decimals();
    }

    /// @notice The address of the underlying token.
    function asset() public pure returns (ERC20) {
        return ERC20(ImmutableArgs.addr());
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == initialChainId ? initialDomainSeparator : _computeDomainSeparator();
    }

    /**
     * @notice Gets basic lending statistics.
     * @return The sum of all banknote balances
     * @return The sum of all banknote balances, in underlying units (increases as interest accrues)
     * @return The sum of all outstanding debts, in underlying units (increases as interest accrues)
     */
    function stats() external view returns (uint256, uint256, uint256) {
        (Cache memory cache, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());

        unchecked {
            return (newTotalSupply, inventory, (cache.borrowBase * cache.borrowIndex) / BORROWS_SCALER);
        }
    }

    function courierOf(address account) external view returns (uint32) {
        return uint32(balances[account] >> 224);
    }

    function principleOf(address account) external view returns (uint256) {
        return (balances[account] >> 112) % Q112;
    }

    /// @notice The number of shares held by `account`
    function balanceOf(address account) external view returns (uint256) {
        return balances[account] % Q112;
    }

    function underlyingBalance(address account) external view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _nominalAssets(account, inventory, newTotalSupply);
    }

    function underlyingBalanceStored(address account) external view returns (uint256) {
        unchecked {
            return
                _nominalAssets({
                    account: account,
                    inventory: lastBalance + (uint256(borrowBase) * borrowIndex) / BORROWS_SCALER,
                    totalSupply_: totalSupply
                });
        }
    }

    function borrowBalance(address account) external view returns (uint256) {
        uint256 b = borrows[account];
        if (b == 0) return 0;

        (Cache memory cache, , ) = _previewInterest(_getCache());
        unchecked {
            return (b - 1).mulDivUp(cache.borrowIndex, BORROWS_SCALER);
        }
    }

    function borrowBalanceStored(address account) external view returns (uint256) {
        uint256 b = borrows[account];
        if (b == 0) return 0;

        unchecked {
            return (b - 1).mulDivUp(borrowIndex, BORROWS_SCALER);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           ERC4626 ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view returns (uint256) {
        (, uint256 inventory, ) = _previewInterest(_getCache());
        return inventory;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToShares(assets, inventory, newTotalSupply, /* roundUp: */ false);
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToAssets(shares, inventory, newTotalSupply, /* roundUp: */ false);
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToAssets(shares, inventory, newTotalSupply, /* roundUp: */ true);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToShares(assets, inventory, newTotalSupply, /* roundUp: */ true);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC4626 DEPOSIT/WITHDRAWAL LIMITS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns a conservative estimate of the maximum amount of `asset()` that can be deposited into the
     * Vault for `receiver`, through a deposit call.
     * @return The maximum amount of `asset()` that can be deposited
     *
     * @dev Should return the *precise* maximum. In this case that'd be on the order of 2**112 with weird constraints
     * coming from both `lastBalance` and `totalSupply`, which changes during interest accrual. Instead of doing
     * complicated math, we provide a constant conservative estimate of 2**96.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address) external pure returns (uint256) {
        return 1 << 96;
    }

    /**
     * @notice Returns a conservative estimate of the maximum number of Vault shares that can be minted for `receiver`,
     * through a mint call.
     * @return The maximum number of Vault shares that can be minted
     *
     * @dev Should return the *precise* maximum. In this case that'd be on the order of 2**112 with weird constraints
     * coming from both `lastBalance` and `totalSupply`, which changes during interest accrual. Instead of doing
     * complicated math, we provide a constant conservative estimate of 2**96.
     *
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum number of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address) external pure returns (uint256) {
        return 1 << 96;
    }

    /**
     * @notice Returns the maximum amount of `asset()` that can be withdrawn from the Vault by `owner`, through a
     * withdraw call.
     * @param owner The address that would burn Vault shares when withdrawing
     * @return The maximum amount of `asset()` that can be withdrawn
     *
     * @dev
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256) {
        (Cache memory cache, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());

        uint256 a = _nominalAssets(owner, inventory, newTotalSupply);
        uint256 b = cache.lastBalance;

        return a < b ? a : b;
    }

    /**
     * @notice Returns the maximum number of Vault shares that can be redeemed in the Vault by `owner`, through a
     * redeem call.
     * @param owner The address that would burn Vault shares when redeeming
     * @return The maximum number of Vault shares that can be redeemed
     *
     * @dev
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256) {
        (Cache memory cache, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());

        uint256 a = _nominalShares(owner, inventory, newTotalSupply);
        uint256 b = _convertToShares(cache.lastBalance, inventory, newTotalSupply, false);

        return a < b ? a : b;
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function _computeDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string version,uint256 chainId,address verifyingContract)"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _previewInterest(Cache memory cache) internal view returns (Cache memory, uint256, uint256) {
        unchecked {
            uint256 oldBorrows = (cache.borrowBase * cache.borrowIndex) / BORROWS_SCALER;
            uint256 oldInventory = cache.lastBalance + oldBorrows;

            if (cache.lastAccrualTime == block.timestamp || oldBorrows == 0) {
                return (cache, oldInventory, cache.totalSupply);
            }

            uint8 rf = reserveFactor;
            uint256 accrualFactor = rateModel.getAccrualFactor({
                elapsedTime: block.timestamp - cache.lastAccrualTime,
                utilization: Math.mulDiv(1e18, oldBorrows, oldInventory)
            });

            cache.borrowIndex = (cache.borrowIndex * accrualFactor) / ONE;
            cache.lastAccrualTime = 0; // 0 in storage means locked to reentrancy; 0 in `cache` means `borrowIndex` was updated

            uint256 newInventory = cache.lastBalance + (cache.borrowBase * cache.borrowIndex) / BORROWS_SCALER;
            uint256 newTotalSupply = Math.mulDiv(
                cache.totalSupply,
                newInventory,
                newInventory - (newInventory - oldInventory) / rf
            );
            return (cache, newInventory, newTotalSupply);
        }
    }

    function _convertToShares(
        uint256 assets,
        uint256 inventory,
        uint256 totalSupply_,
        bool roundUp
    ) internal pure returns (uint256) {
        if (totalSupply_ == 0) return assets;
        return roundUp ? assets.mulDivUp(totalSupply_, inventory) : assets.mulDivDown(totalSupply_, inventory);
    }

    function _convertToAssets(
        uint256 shares,
        uint256 inventory,
        uint256 totalSupply_,
        bool roundUp
    ) internal pure returns (uint256) {
        if (totalSupply_ == 0) return shares;
        return roundUp ? shares.mulDivUp(inventory, totalSupply_) : shares.mulDivDown(inventory, totalSupply_);
    }

    function _nominalShares(
        address account,
        uint256 inventory,
        uint256 totalSupply_
    ) private view returns (uint256 shares) {
        unchecked {
            uint256 data = balances[account];
            shares = data % Q112;

            uint32 id = uint32(data >> 224);
            if (id != 0) {
                uint256 principle = _convertToShares((data >> 112) % Q112, inventory, totalSupply_, true);

                if (shares > principle) {
                    shares -= ((shares - principle) * couriers[id].cut) / 10_000;
                }
            }
        }
    }

    function _nominalAssets(
        address account,
        uint256 inventory,
        uint256 totalSupply_
    ) private view returns (uint256 assets) {
        unchecked {
            uint256 data = balances[account];
            assets = _convertToAssets(data % Q112, inventory, totalSupply_, false);

            uint32 id = uint32(data >> 224);
            if (id != 0) {
                uint256 principle = (data >> 112) % Q112;

                if (assets > principle) {
                    assets -= ((assets - principle) * couriers[id].cut) / 10_000;
                }
            }
        }
    }

    function _getCache() private view returns (Cache memory) {
        return Cache(totalSupply, lastBalance, lastAccrualTime, borrowBase, borrowIndex);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {MIN_RESERVE_FACTOR, MAX_RESERVE_FACTOR} from "./libraries/constants/Constants.sol";
import {Q112} from "./libraries/constants/Q.sol";
import {SafeCastLib} from "./libraries/SafeCastLib.sol";

import {Ledger} from "./Ledger.sol";
import {RateModel} from "./RateModel.sol";

interface IFlashBorrower {
    function onFlashLoan(address initiator, uint256 amount, bytes calldata data) external;
}

contract Lender is Ledger {
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;
    using SafeTransferLib for ERC20;

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Borrow(address indexed caller, address indexed recipient, uint256 amount, uint256 units);

    event Repay(address indexed caller, address indexed beneficiary, uint256 amount, uint256 units);

    event EnrollCourier(uint32 indexed id, address indexed wallet, uint16 cut);

    event CreditCourier(uint32 indexed id, address indexed account);

    /*//////////////////////////////////////////////////////////////
                       CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor(address reserve) Ledger(reserve) {}

    function initialize(RateModel rateModel_, uint8 reserveFactor_) external {
        require(borrowIndex == 0);
        borrowIndex = uint72(ONE);
        lastAccrualTime = uint32(block.timestamp);

        initialDomainSeparator = _computeDomainSeparator();
        initialChainId = block.chainid;

        rateModel = rateModel_;
        require(MIN_RESERVE_FACTOR <= reserveFactor_ && reserveFactor_ <= MAX_RESERVE_FACTOR);
        reserveFactor = reserveFactor_;
    }

    function whitelist(address borrower) external {
        // Requirements:
        // - `msg.sender == FACTORY` so that only the factory can whitelist borrowers
        // - `borrows[borrower] == 0` ensures we don't accidentally erase debt
        require(msg.sender == FACTORY && borrows[borrower] == 0);

        // `borrow` and `repay` have to read the `borrows` mapping anyway, so setting this to 1
        // allows them to efficiently check whether a given borrower is whitelisted. This extra
        // unit of debt won't accrue interest or impact solvency calculations.
        borrows[borrower] = 1;
    }

    function enrollCourier(uint32 id, address wallet, uint16 cut) external {
        // Requirements:
        // - `id != 0` because 0 is reserved as the no-courier case
        // - `cut != 0 && cut < 10_000` just means between 0 and 100%
        require(id != 0 && cut != 0 && cut < 10_000);
        // Once an `id` has been enrolled, its info can't be changed
        require(couriers[id].cut == 0);

        couriers[id] = Courier(wallet, cut);

        emit EnrollCourier(id, wallet, cut);
    }

    function creditCourier(uint32 id, address account) external {
        // Callers are free to set their own courier, but they need permission to mess with others'
        require(msg.sender == account || allowance[account][msg.sender] != 0);

        // Payout logic can't handle self-reference, so don't let accounts credit themselves
        Courier memory courier = couriers[id];
        require(courier.cut != 0 && courier.wallet != account);

        // Only set courier if account balance is 0. Otherwise a previous courier may
        // be cheated out of their fees.
        require(balances[account] % Q112 == 0);
        balances[account] = uint256(id) << 224;

        emit CreditCourier(id, account);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount, address beneficiary) external returns (uint256 shares) {
        // Guard against reentrancy, accrue interest, and update reserves
        (Cache memory cache, uint256 inventory) = _load();

        shares = _convertToShares(amount, inventory, cache.totalSupply, /* roundUp: */ false);
        require(shares != 0, "Aloe: zero impact");

        // Ensure tokens were transferred
        cache.lastBalance += amount;
        require(cache.lastBalance <= asset().balanceOf(address(this)), "Aloe: insufficient pre-pay");

        // Mint shares and (if applicable) handle courier accounting
        _unsafeMint(beneficiary, shares, amount);
        cache.totalSupply += shares;

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ false);

        emit Deposit(msg.sender, beneficiary, amount, shares);
    }

    function redeem(uint256 shares, address recipient, address owner) external returns (uint256 amount) {
        // Guard against reentrancy, accrue interest, and update reserves
        (Cache memory cache, uint256 inventory) = _load();

        amount = _convertToAssets(shares, inventory, cache.totalSupply, /* roundUp: */ false);
        require(amount != 0, "Aloe: zero impact");

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Burn shares and (if applicable) handle courier accounting
        _unsafeBurn(owner, shares, inventory, cache.totalSupply);
        unchecked {
            cache.totalSupply -= shares;
        }

        // Transfer tokens
        cache.lastBalance -= amount;
        asset().safeTransfer(recipient, amount);

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ false);

        emit Withdraw(msg.sender, recipient, owner, amount, shares);
    }

    function mint(uint256 shares, address beneficiary) external returns (uint256 amount) {
        amount = previewMint(shares);
        require(shares == this.deposit(amount, beneficiary));
    }

    function withdraw(uint256 amount, address recipient, address owner) external returns (uint256 shares) {
        shares = previewWithdraw(amount);
        require(amount == this.redeem(shares, recipient, owner));
    }

    /*//////////////////////////////////////////////////////////////
                           BORROW/REPAY LOGIC
    //////////////////////////////////////////////////////////////*/

    function borrow(uint256 amount, address recipient) external returns (uint256 units) {
        uint256 b = borrows[msg.sender];
        require(b != 0, "Aloe: not a borrower");

        // Guard against reentrancy, accrue interest, and update reserves
        (Cache memory cache, ) = _load();

        units = amount.mulDivUp(BORROWS_SCALER, cache.borrowIndex);
        cache.borrowBase += units;
        borrows[msg.sender] = b + units;

        // Transfer tokens
        cache.lastBalance -= amount;
        asset().safeTransfer(recipient, amount);

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ true);

        emit Borrow(msg.sender, recipient, amount, units);
    }

    function repay(uint256 amount, address beneficiary) external returns (uint256 units) {
        uint256 b = borrows[beneficiary];
        require(b != 0, "Aloe: not a borrower");

        // Guard against reentrancy, accrue interest, and update reserves
        (Cache memory cache, ) = _load();

        unchecked {
            units = (amount * BORROWS_SCALER) / cache.borrowIndex;
            require(units < b, "Aloe: repay too much");

            borrows[beneficiary] = b - units;
            cache.borrowBase -= units;
        }

        // Ensure tokens were transferred
        cache.lastBalance += amount;
        require(cache.lastBalance <= asset().balanceOf(address(this)), "Aloe: insufficient pre-pay");

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ true);

        emit Repay(msg.sender, beneficiary, amount, units);
    }

    /// @dev Reentrancy guard is critical here! Without it, one could use a flash loan to repay a normal loan.
    function flash(uint256 amount, address to, bytes calldata data) external {
        // Guard against reentrancy
        uint32 _lastAccrualTime = lastAccrualTime;
        require(_lastAccrualTime != 0, "Aloe: locked");
        lastAccrualTime = 0;

        ERC20 asset_ = asset();

        uint256 balance = asset_.balanceOf(address(this));
        asset_.safeTransfer(to, amount);
        IFlashBorrower(to).onFlashLoan(msg.sender, amount, data);
        require(balance <= asset_.balanceOf(address(this)), "Aloe: insufficient pre-pay");

        lastAccrualTime = _lastAccrualTime;
    }

    function accrueInterest() external {
        (Cache memory cache, ) = _load();
        _save(cache, /* didChangeBorrowBase: */ false);
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 shares) external returns (bool) {
        allowance[msg.sender][spender] = shares;

        emit Approval(msg.sender, spender, shares);

        return true;
    }

    function transfer(address to, uint256 shares) external returns (bool) {
        _transfer(msg.sender, to, shares);

        return true;
    }

    function transferFrom(address from, address to, uint256 shares) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - shares;

        _transfer(from, to, shares);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             ERC2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Aloe: permit expired");

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

            require(recoveredAddress != address(0) && recoveredAddress == owner, "Aloe: permit invalid");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 shares) private {
        unchecked {
            // From most to least significant...
            // -------------------------------
            // | courier id       | 32 bits  |
            // | user's principle | 112 bits |
            // | user's balance   | 112 bits |
            // -------------------------------
            uint256 data;

            data = balances[from];
            require(data >> 224 == 0 && shares <= data % Q112);
            balances[from] = data - shares;

            data = balances[to];
            require(data >> 224 == 0);
            balances[to] = data + shares;
        }

        emit Transfer(from, to, shares);
    }

    /// @dev You must do `totalSupply += shares` separately. Do so in a checked context.
    function _unsafeMint(address to, uint256 shares, uint256 amount) private {
        unchecked {
            // From most to least significant...
            // -------------------------------
            // | courier id       | 32 bits  |
            // | user's principle | 112 bits |
            // | user's balance   | 112 bits |
            // -------------------------------
            uint256 data = balances[to];

            if (data >> 224 != 0) {
                // Keep track of principle iff courier deserves credit
                require(amount + ((data >> 112) % Q112) < Q112);
                data += amount << 112;
            }

            // Keep track of balance regardless of courier.
            // Since `totalSupply` fits in uint112, the user's balance will too. No need to check here.
            balances[to] = data + shares;
        }

        emit Transfer(address(0), to, shares);
    }

    /// @dev You must do `totalSupply -= shares` separately. Do so in an unchecked context.
    function _unsafeBurn(address from, uint256 shares, uint256 inventory, uint256 totalSupply_) private {
        unchecked {
            // From most to least significant...
            // -------------------------------
            // | courier id       | 32 bits  |
            // | user's principle | 112 bits |
            // | user's balance   | 112 bits |
            // -------------------------------
            uint256 data = balances[from];
            uint256 balance = data % Q112;

            uint32 id = uint32(data >> 224);
            if (id != 0) {
                uint256 principleAssets = (data >> 112) % Q112;
                uint256 principleShares = principleAssets.mulDivUp(totalSupply_, inventory);

                if (balance > principleShares) {
                    Courier memory courier = couriers[id];

                    // Compute total fee owed to courier. Take it out of balance so that
                    // comparison is correct (`shares <= balance`)
                    uint256 fee = ((balance - principleShares) * courier.cut) / 10_000;
                    balance -= fee;

                    // Compute portion of fee to pay out during this burn.
                    fee = (fee * shares) / balance;

                    // Send `fee` from `from` to `courier.wallet`. NOTE: We skip principle
                    // update on courier, so if couriers credit each other, 100% of `fee`
                    // is treated as profit.
                    data -= fee;
                    balances[courier.wallet] += fee;
                    emit Transfer(from, courier.wallet, fee);
                }

                // Update principle
                data -= ((principleAssets * shares) / balance) << 112;
            }

            require(shares <= balance);
            balances[from] = data - shares;
        }

        emit Transfer(from, address(0), shares);
    }

    /// @dev Note that if `RESERVE` ever gives credit to a courier, its principle won't be tracked properly.
    function _load() private returns (Cache memory cache, uint256 inventory) {
        cache = Cache(totalSupply, lastBalance, lastAccrualTime, borrowBase, borrowIndex);
        // Guard against reentrancy
        require(cache.lastAccrualTime != 0, "Aloe: locked");
        lastAccrualTime = 0;

        // Accrue interest (only in memory)
        uint256 newTotalSupply;
        (cache, inventory, newTotalSupply) = _previewInterest(cache);

        // Update reserves (new `totalSupply` is only in memory, but `balanceOf` is updated in storage)
        if (newTotalSupply != cache.totalSupply) {
            _unsafeMint(RESERVE, newTotalSupply - cache.totalSupply, 0);
            cache.totalSupply = newTotalSupply;
        }
    }

    function _save(Cache memory cache, bool didChangeBorrowBase) private {
        if (cache.lastAccrualTime == 0) {
            // `cache.lastAccrualTime == 0` implies that `cache.borrowIndex` was updated.
            // `cache.borrowBase` MAY also have been updated, so we store both components of the slot.
            borrowBase = cache.borrowBase.safeCastTo184();
            borrowIndex = cache.borrowIndex.safeCastTo72();
            // Now that we've read the flag, we can update `cache.lastAccrualTime` to the real, appropriate value
            cache.lastAccrualTime = block.timestamp;
        } else if (didChangeBorrowBase) {
            // Here, `cache.lastAccrualTime` is a real timestamp (could be `block.timestamp` or older). We can infer
            // that `cache.borrowIndex` was *not* updated. So we only have to store `cache.borrowBase`.
            borrowBase = cache.borrowBase.safeCastTo184();
        }

        totalSupply = cache.totalSupply.safeCastTo112();
        lastBalance = cache.lastBalance.safeCastTo112();
        lastAccrualTime = cache.lastAccrualTime.safeCastTo32(); // Disables reentrancy guard
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

contract RateModel {
    uint256 private constant A = 6.1010463348e20;

    uint256 private constant B = 1e12 - A / 1e18;

    function getAccrualFactor(uint256 elapsedTime, uint256 utilization) external pure returns (uint256) {
        unchecked {
            uint256 rate = computeYieldPerSecond(utilization);

            if (elapsedTime > 1 weeks) elapsedTime = 1 weeks;

            return FixedPointMathLib.rpow(rate, elapsedTime, 1e12);
        }
    }

    function computeYieldPerSecond(uint256 utilization) public pure returns (uint256) {
        unchecked {
            return (utilization < 0.99e18) ? B + A / (1e18 - utilization) : 1000000060400;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Aloe Labs, Inc.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

uint256 constant MIN_SIGMA = 0.02e18;

uint256 constant MAX_SIGMA = 0.15e18;

uint256 constant MIN_RESERVE_FACTOR = 4; // Expressed as reciprocal, e.g. 4 --> 25%

uint256 constant MAX_RESERVE_FACTOR = 20; // Expressed as reciprocal, e.g. 20 --> 5%

// 1 + 1 / MAX_LEVERAGE should correspond to the maximum feasible single-block accrualFactor so that liquidators have time to respond to interest updates
uint256 constant MAX_LEVERAGE = 200;

uint256 constant LIQUIDATION_INCENTIVE = 20; // Expressed as reciprocal, e.g. 20 --> 5%

uint256 constant LIQUIDATION_GRACE_PERIOD = 2 minutes;

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

uint256 constant Q8 = 1 << 8;

uint256 constant Q16 = 1 << 16;

uint256 constant Q24 = 1 << 24;

uint256 constant Q32 = 1 << 32;

uint256 constant Q40 = 1 << 40;

uint256 constant Q48 = 1 << 48;

uint256 constant Q56 = 1 << 56;

uint256 constant Q64 = 1 << 64;

uint256 constant Q72 = 1 << 72;

uint256 constant Q80 = 1 << 80;

uint256 constant Q88 = 1 << 88;

uint256 constant Q96 = 1 << 96;

uint256 constant Q104 = 1 << 104;

uint256 constant Q112 = 1 << 112;

uint256 constant Q120 = 1 << 120;

uint256 constant Q128 = 1 << 128;