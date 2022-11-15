// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title GOO (Gradual Ownership Optimization) Issuance
/// @author transmissions11 <[email protected]>
/// @author FrankieIsLost <[email protected]>
/// @notice Implementation of the GOO Issuance mechanism.
library LibGOO {
    using FixedPointMathLib for uint256;

    /// @notice Compute goo balance based on emission multiple, last balance, and time elapsed.
    /// @param emissionMultiple The multiple on emissions to consider when computing the balance.
    /// @param lastBalanceWad The last checkpointed balance to apply the emission multiple over time to, scaled by 1e18.
    /// @param timeElapsedWad The time elapsed since the last checkpoint, scaled by 1e18.
    function computeGOOBalance(
        uint256 emissionMultiple,
        uint256 lastBalanceWad,
        uint256 timeElapsedWad
    ) internal pure returns (uint256) {
        unchecked {
            // We use wad math here because timeElapsedWad is, as the name indicates, a wad.
            uint256 timeElapsedSquaredWad = timeElapsedWad.mulWadDown(timeElapsedWad);

            // prettier-ignore
            return lastBalanceWad + // The last recorded balance.

            // Don't need to do wad multiplication since we're
            // multiplying by a plain integer with no decimals.
            // Shift right by 2 is equivalent to division by 4.
            ((emissionMultiple * timeElapsedSquaredWad) >> 2) +

            timeElapsedWad.mulWadDown( // Terms are wads, so must mulWad.
                // No wad multiplication for emissionMultiple * lastBalance
                // because emissionMultiple is a plain integer with no decimals.
                // We multiply the sqrt's radicand by 1e18 because it expects ints.
                (emissionMultiple * lastBalanceWad * 1e18).sqrt()
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*


                                                                                                     /=O
                                                                                                   \ =
                                                                                                 O  /
                                                                                                /  \  [[/
                                                                                              /  ,\\       [O
                                                                                            O   =/   /OooO   //
                                                                                          O       ]OoooO/  ,\
                                                                                        O^     ,OoooooO   /
                                                                                       /  ,    =OoooooO  =
                                                                                     O  ,/  //   OooooO  =
                                                                                   \   /^  /  ^  OooooO  =
                                                                                 O   / ^  O   ^  OooooO  =
                                                                               //  ,OO  ,=    ^  OooooO  =
                                                                              /  ,OOO  ,O     ^  OooooO  =
                                                                            O   OOOO  =O/[[[[[   OooooO  =O
                                                                          O   /OoO/  /\          Oooooo        O
                                                                         /  =OooO^  /\   oooooooooooooooooooo^  /
                                                                       /  ,O ++O   \/  , ++++++++++++++++++++,\  \
                                                                     O   O ++,O  ,O/  ,++++++++++++++++++++++++\  =
                                                                   \   //+++,O  ,O^  ,++++++  =O++++++=O[\^+++++\  ,
                                                                 O^  =/+++.=/  =O    ++++.,   =/++++++=O  =^.++++=  ,O                                                        OO  OOO
                                                                /  ,O ....=/  =\              O^......=O   =\]]]]]/  ,O                                                       ^     =
                                                              /   O ...../^  /O]]]]]]]]       O^......=O               O                                                     O  O=^ =
     \                            O                         \   //......O   o        \    =^ ,O.......=O^[\    [/                                                              =^=^ =
      O    ]]]]]]]]]]]]]]]]]]]]]   O                      O   =/......,O   \        O  =^ =  =O.......=O^...,\]   ,\/                                 OO                    /  O.=^ =
        \   \\..................=^ ,                    O/  ,O ......,O  ,\        O  =O\    =^.......=O^.......[\    ,O                 \\O            =\                 O  =^.=^ =
         O^   O^.................=  =                  /  ,O .......=/  ,         \  =/.O    O^.......=O^..........,\\    \/           O    /            ,O                ^  O..=^ =
           /   ,O ................O  \               \   //........//  =         /  =/..O    O^.......=O^..............[O    ,\       /  ,\  =O            \              O  = ..=^ =
             \   \\................\  O            O   //.........O^  /         /  =/...=^  ,O........=O^.................,\\    [O /   / .\   /         ,  \             ^ ,/...=^ =
              O^  ,O^..............=^  O         O^  ,O ........,O   /         /  =/....=^  =O........=O^.....................[O      //....,\  \        =O  ,O          O  / ...=^ =
                O   ,O .............=  ,        /  ,O .........,O   \         /  =/......O  =^........=O^........OOO\ ............\\]/........\  ,/      =^=^  /           ,^....=  =
                  \   \\.............O  =     /   //..........=O  ,O         /  //.......O  O^........=O^........OOOO[.........../OO ..........=^  \     =^..\  \       /  O.....=  =
                   O   =^.           .\  \  \   //.         ./O^  =         /  //.       =^ O         =O^        O/.           ,OO              ,O  ,/   =^  .\  =O    O  =^     =  =
                     \  =^            =^  O   ,O            // =\  =O      /  //         =^,O         =O^                    .OO/                 \   \  =^    =^ ,O   ^  O      =  =
                      ^  =^            =    ,O             O/   ,\  ,O    /  //           O=O         =O^                   /O/          ]         ,\    =^      \  \ O  =^      =  =
                       ^  \             O  //            ,O      ,O  ,   /  //            OO^         =O^                 ,OO          =OOO          \   =^       \  =^  /       =  =
                       O^  \             O/             ,O         O  ,O^  /O            OOO^         =O^               ,OO           OO  OO          =\ =^        ,    =        =  =
                        /   O                          =O           \     /O           =OOOO          =O^              /O/          /OOOOO  O\          O=^          \ ,^        =  =
                         O   O                        //      O      \   /O          ,OOOOOO          =O^               OO        ,OOOO     OOO          O^           \/         =  =
                          O   O                      O^      OOO^     \^/O          /OOO OO/          =O^                OO^       ,OO  O    O/        ,O\^                      =  =
                           O  ,O                   ,O      ,OO O \     =O         ,OOOOO  O^          =O^       =         \O\        \O    OO         /^ =^                      =  =
                            \  ,\                 , =\     =OOOOO^    ,O         /O       O^          =O^       ,O.        \OO        ,O  O/        =O   =^     /                =  =
                             ^  =\               =   ,O     ,OOO     ,O.       ,OOOOOOOOOOO.          =O^       .OO.        =OO\.      .OO.       .O^    =^    = \               =  =
                              ^  =\............./  ,   O ....,O ....=O ......./OOO/[[[...,O...........=O^........OOO.........=OOO .............../O  ,O  =^...=^  =^............./  =
                               ^  =\..........,/  / O   \\.........=O .................../O...........=O^........OOO\.........,OOO\............,O^  / O  =^..,^    ,\............O  =
                                   \\++++++++,^  O    ^  =O+++++++=O +++++++++++++++++++=O/+++++++++++=O^++++++++OOOO\+++++++++,OOOO^+++++++++/O  ,O  O  =^+,/  / ^  O+++++++++++O  =
                                O   \\++++++/  ,O      \  ,O ++++/O^++++++++++++++++++++OO^+++++++++++=O^++++++++OOOOO^+++++++++,OOOOO++++++,O^  /    O  =^+O  =   \  \ +++++++++O  =
                                 O   O\++++O  ,O        O   O\++/O^++++++++++++++++++++=OO^+++++++++++/O\++++++++OOOOOO^++++++++++OO  O\+++O/  ,O     O  =oO  ,O    O  =\++++++++O  =
                                  O   OoooO  ,           O   \OoOOOOOOOOOOOOOOOOOOOOOOOOOOooooooooooooOOOooooooooOO    OoooooooooooOO  OOoO   /       O  =O^ ,O      O  ,Ooooooooo  =
                                   \   OO/  /              ^  =/                         OooooooooooooO[[[[[[[[[[[[[[[[   ,  [[[[[[[[[[ ,   ,\        O      O            Ooooooo/  =
                                    \  ,^  \                \                           =OooooooooooooO   ,]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]//         OOOOOO\           \  \ooooo^  =
                                     ^   ,O                  O  =                       =OooooooooooooO   =                                                              ^  =Oooo^  =
                                     \^ ,O                    O/                     \   \OoooOOOOOOOOO   =                                                               O  ,OoO^  =
                                       //                                             /   =OOOOOOOOOOOO   =                                                                    OO^  =
                                                                                       O   ,OOOOOOOOOOO   /                                                                  ^  \^  =
                                                                                        \^  ,OOOOOOOOO   /                                                                    \     =
                                                                                          \   OOOOOOO   O                                                                      O    =
                                                                                           O   \OOOO   O                                                                        O   =
                                                                                            O   =OO  ,O                                                                          \^ =
                                                                                              ^  ,  ,O                                                                             \=
                                                                                               \   ,
                                                                                                / =/


*/

import { Owned } from "solmate/auth/Owned.sol";
import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { IArtGobblers } from "src/utils/IArtGobblers.sol";
import { IGOO } from "src/utils/IGOO.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";
import { toWadUnsafe, toDaysWadUnsafe } from "solmate/utils/SignedWadMath.sol";
import { LibGOO } from "goo-issuance/LibGOO.sol";

contract VoltronGobblers is ReentrancyGuard, Owned {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public immutable artGobblers;
    address public immutable goo;

    /*//////////////////////////////////////////////////////////////
                                USER DATA
    //////////////////////////////////////////////////////////////*/

    // gobblerId => user
    mapping(uint256 => address) public getUserByGobblerId;

    /// @notice Struct holding data relevant to each user's account.
    struct UserData {
        // The total number of gobblers currently owned by the user.
        uint32 gobblersOwned;
        // The sum of the multiples of all gobblers the user holds.
        uint32 emissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 virtualBalance;
        // claimed pool's gobbler number
        uint16 claimedNum;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
        // Timestamp of the last goo deposit.
        uint48 lastGooDepositedTimestamp;
    }

    /// @notice Maps user addresses to their account data.
    mapping(address => UserData) public getUserData;

    /*//////////////////////////////////////////////////////////////
                                POOL DATA
    //////////////////////////////////////////////////////////////*/

    struct GlobalData {
        // The total number of gobblers currently deposited by the user.
        uint32 totalGobblersDeposited;
        // The sum of the multiples of all gobblers the user holds.
        uint32 totalEmissionMultiple;
        // User's goo balance at time of last checkpointing.
        uint128 totalVirtualBalance;
        // Timestamp of the last goo balance checkpoint.
        uint48 lastTimestamp;
    }

    GlobalData public globalData;

    /// @notice Maps voltron gobbler IDs to claimable
    mapping(uint256 => bool) public gobblerClaimable;
    uint256[] public claimableGobblers;
    uint256 public claimableGobblersNum;

    /*//////////////////////////////////////////////////////////////
                                admin
    //////////////////////////////////////////////////////////////*/

    bool public mintLock;
    bool public claimGobblerLock;

    // must stake timeLockDuration time to withdraw
    // Avoid directly claiming the cheaper gobbler after the user deposits goo
    uint256 public timeLockDuration;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event GobblerDeposited(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblerWithdrawn(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);
    event GobblerMinted(uint256 indexed num, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event GobblersClaimed(address indexed user, uint256[] indexed IndexedGobblerIds, uint256[] gobblerIds);
    event VoltronGooClaimed(address indexed to, uint256 indexed amount);

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier canMint() {
        require(!mintLock, "MINT_LOCK");
        _;
    }

    modifier canClaimGobbler() {
        require(!claimGobblerLock, "CLAIM_GOBBLER_LOCK");
        _;
    }

    constructor(address admin_, address artGobblers_, address goo_, uint256 timeLockDuration_) Owned(admin_) {
        artGobblers = artGobblers_;
        goo = goo_;
        timeLockDuration = timeLockDuration_;
    }

    function depositGobblers(uint256[] calldata gobblerIds, uint256 gooAmount) external nonReentrant {
        if (gooAmount > 0) _addGoo(gooAmount);

        // update user virtual balance of GOO
        _updateGlobalBalance(gooAmount);
        _updateUserGooBalance(msg.sender, gooAmount);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 sumEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(holder == msg.sender, "WRONG_OWNER");
            require(emissionMultiple > 0, "GOBBLER_MUST_BE_REVEALED");

            sumEmissionMultiple += emissionMultiple;

            getUserByGobblerId[id] = msg.sender;

            IArtGobblers(artGobblers).transferFrom(msg.sender, address(this), id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned += totalNumber;
        getUserData[msg.sender].emissionMultiple += sumEmissionMultiple;

        // update global data
        globalData.totalGobblersDeposited += totalNumber;
        globalData.totalEmissionMultiple += sumEmissionMultiple;

        emit GobblerDeposited(msg.sender, gobblerIds, gobblerIds);
    }

    function withdrawGobblers(uint256[] calldata gobblerIds) external nonReentrant {
        // update user virtual balance of GOO
        _updateGlobalBalance(0);
        _updateUserGooBalance(msg.sender, 0);

        uint256 id;
        address holder;
        uint32 emissionMultiple;
        uint32 deltaEmissionMultiple;

        uint32 totalNumber = uint32(gobblerIds.length);
        for (uint256 i = 0; i < totalNumber; ++i) {
            id = gobblerIds[i];
            (holder,, emissionMultiple) = IArtGobblers(artGobblers).getGobblerData(id);
            require(getUserByGobblerId[id] == msg.sender, "WRONG_OWNER");

            deltaEmissionMultiple += emissionMultiple;

            delete getUserByGobblerId[id];

            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        // update user data
        getUserData[msg.sender].gobblersOwned -= totalNumber;
        getUserData[msg.sender].emissionMultiple -= deltaEmissionMultiple;

        // update global data
        globalData.totalGobblersDeposited -= totalNumber;
        globalData.totalEmissionMultiple -= deltaEmissionMultiple;

        emit GobblerWithdrawn(msg.sender, gobblerIds, gobblerIds);
    }

    function mintVoltronGobblers(uint256 maxPrice, uint256 num) external nonReentrant canMint {
        uint256[] memory gobblerIds = new uint256[](num);
        claimableGobblersNum += num;
        for (uint256 i = 0; i < num; i++) {
            uint256 gobblerId = IArtGobblers(artGobblers).mintFromGoo(maxPrice, true);
            gobblerIds[i] = gobblerId;
            claimableGobblers.push(gobblerId);
            gobblerClaimable[gobblerId] = true;
        }
        emit GobblerMinted(num, gobblerIds, gobblerIds);
    }

    function claimVoltronGobblers(uint256[] calldata gobblerIds) external nonReentrant canClaimGobbler {
        // Avoid directly claiming the cheaper gobbler after the user deposits goo
        require(getUserData[msg.sender].lastGooDepositedTimestamp + timeLockDuration <= block.timestamp, "CANT_CLAIM_NOW");

        uint256 globalBalance = _updateGlobalBalance(0);
        uint256 userVirtualBalance = _updateUserGooBalance(msg.sender, 0);

        // (user's virtual goo / global virtual goo) * total claimable num - claimed num
        uint256 claimableNum =
            userVirtualBalance.divWadDown(globalBalance).mulWadDown(claimableGobblers.length) - uint256(getUserData[msg.sender].claimedNum);

        uint256 claimNum = gobblerIds.length;
        require(claimableNum >= claimNum, "CLAIM_TOO_MUCH");

        getUserData[msg.sender].claimedNum += uint16(claimNum);
        claimableGobblersNum -= claimNum;

        // claim gobblers
        uint256 id;
        for (uint256 i = 0; i < claimNum; i++) {
            id = gobblerIds[i];
            require(gobblerClaimable[id], "GOBBLER_NOT_CLAIMABLE");
            gobblerClaimable[id] = false;
            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        emit GobblersClaimed(msg.sender, gobblerIds, gobblerIds);
    }

    function addGoo(uint256 amount) external nonReentrant {
        require(amount > 0, "INVALID_AMOUNT");
        _addGoo(amount);
        _updateGlobalBalance(amount);
        _updateUserGooBalance(msg.sender, amount);
    }

    function _addGoo(uint256 amount) internal {
        uint256 poolBalanceBefore = IArtGobblers(artGobblers).gooBalance(address(this));
        IGOO(goo).transferFrom(msg.sender, address(this), amount);
        IArtGobblers(artGobblers).addGoo(amount);
        require(IArtGobblers(artGobblers).gooBalance(address(this)) - poolBalanceBefore >= amount, "ADDGOO_FAILD");
    }

    /*//////////////////////////////////////////////////////////////
                            UTILS FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _updateGlobalBalance(uint256 gooAmount) internal returns (uint256) {
        uint256 updatedBalance = globalGooBalance() + gooAmount;
        // update global balance
        globalData.totalVirtualBalance = uint128(updatedBalance);
        globalData.lastTimestamp = uint48(block.timestamp);
        return updatedBalance;
    }


    /// @notice Calculate global virtual goo balance.
    function globalGooBalance() public view returns (uint256) {
        // Compute the user's virtual goo balance by leveraging LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            globalData.totalEmissionMultiple,
            globalData.totalVirtualBalance,
            uint256(toDaysWadUnsafe(block.timestamp - globalData.lastTimestamp))
        );
    }

    /// @notice Update a user's virtual goo balance.
    /// @param user The user whose virtual goo balance we should update.
    /// @param gooAmount The amount of goo to add the user's virtual balance by.
    function _updateUserGooBalance(address user, uint256 gooAmount) internal returns (uint256) {
        // Don't need to do checked addition in the increase case, but we do it anyway for convenience.
        uint256 updatedBalance = gooBalance(user) + gooAmount;

        // Snapshot the user's new goo balance with the current timestamp.
        getUserData[user].virtualBalance = uint128(updatedBalance);
        getUserData[user].lastTimestamp = uint48(block.timestamp);
        if (gooAmount != 0) getUserData[user].lastGooDepositedTimestamp = uint48(block.timestamp);

        emit GooBalanceUpdated(user, updatedBalance);
        return updatedBalance;
    }

    /// @notice Calculate a user's virtual goo balance.
    /// @param user The user to query balance for.
    function gooBalance(address user) public view returns (uint256) {
        // Compute the user's virtual goo balance by leveraging LibGOO.
        // prettier-ignore
        return LibGOO.computeGOOBalance(
            getUserData[user].emissionMultiple,
            getUserData[user].virtualBalance,
            uint256(toDaysWadUnsafe(block.timestamp - getUserData[user].lastTimestamp))
        );
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice admin claim voltron gobblers and goo remained in pool, only used when all user withdrawn their gobblers
    function adminClaimGobblersAndGoo(uint256[] calldata gobblerIds) external onlyOwner nonReentrant {
        _updateGlobalBalance(0);

        // require all user has withdraw their gobblers
        require(globalData.totalGobblersDeposited == 0, "ADMIN_CANT_CLAIM");

        // goo in gobblers
        IArtGobblers(artGobblers).removeGoo(IArtGobblers(artGobblers).gooBalance(address(this)));

        uint256 claimableGoo = IGOO(goo).balanceOf(address(this));
        IGOO(goo).transfer(msg.sender, claimableGoo);

        emit VoltronGooClaimed(msg.sender, claimableGoo);

        // claim gobblers
        uint256 claimNum = gobblerIds.length;
        claimableGobblersNum -= claimNum;
        for (uint256 i = 0; i < claimNum; i++) {
            uint256 id = gobblerIds[i];
            require(gobblerClaimable[id], "GOBBLER_NOT_CLAIMABLE");
            gobblerClaimable[id] = false;
            IArtGobblers(artGobblers).transferFrom(address(this), msg.sender, id);
        }

        emit GobblersClaimed(msg.sender, gobblerIds, gobblerIds);
    }

    function setMintLock(bool isLock) external onlyOwner {
        mintLock = isLock;
    }

    function setClaimGobblerLock(bool isLock) external onlyOwner {
        claimGobblerLock = isLock;
    }

    function setTimeLockDuration(uint256 timeLockDuration_) external onlyOwner {
        timeLockDuration = timeLockDuration_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IArtGobblers {
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ArtGobbled(address indexed user, uint256 indexed gobblerId, address indexed nft, uint256 id);
    event GobblerClaimed(address indexed user, uint256 indexed gobblerId);
    event GobblerPurchased(address indexed user, uint256 indexed gobblerId, uint256 price);
    event GobblersRevealed(address indexed user, uint256 numGobblers, uint256 lastRevealedId);
    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);
    event LegendaryGobblerMinted(address indexed user, uint256 indexed gobblerId, uint256[] burnedGobblerIds);
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event RandProviderUpgraded(address indexed user, address indexed newRandProvider);
    event RandomnessFulfilled(uint256 randomness);
    event RandomnessRequested(address indexed user, uint256 toBeRevealed);
    event ReservedGobblersMinted(address indexed user, uint256 lastMintedGobblerId, uint256 numGobblersEach);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function BASE_URI() external view returns (string memory);
    function FIRST_LEGENDARY_GOBBLER_ID() external view returns (uint256);
    function LEGENDARY_AUCTION_INTERVAL() external view returns (uint256);
    function LEGENDARY_GOBBLER_INITIAL_START_PRICE() external view returns (uint256);
    function LEGENDARY_SUPPLY() external view returns (uint256);
    function MAX_MINTABLE() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);
    function MINTLIST_SUPPLY() external view returns (uint256);
    function PROVENANCE_HASH() external view returns (bytes32);
    function RESERVED_SUPPLY() external view returns (uint256);
    function UNREVEALED_URI() external view returns (string memory);
    function acceptRandomSeed(bytes32, uint256 randomness) external;
    function addGoo(uint256 gooAmount) external;
    function approve(address spender, uint256 id) external;
    function balanceOf(address owner) external view returns (uint256);
    function burnGooForPages(address user, uint256 gooAmount) external;
    function claimGobbler(bytes32[] memory proof) external returns (uint256 gobblerId);
    function community() external view returns (address);
    function currentNonLegendaryId() external view returns (uint128);
    function getApproved(uint256) external view returns (address);
    function getCopiesOfArtGobbledByGobbler(uint256, address, uint256) external view returns (uint256);
    function getGobblerData(uint256) external view returns (address owner, uint64 idx, uint32 emissionMultiple);
    function getGobblerEmissionMultiple(uint256 gobblerId) external view returns (uint256);
    function getTargetSaleTime(int256 sold) external view returns (int256);
    function getUserData(address)
        external
        view
        returns (uint32 gobblersOwned, uint32 emissionMultiple, uint128 lastBalance, uint64 lastTimestamp);
    function getUserEmissionMultiple(address user) external view returns (uint256);
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) external view returns (uint256);
    function gobble(uint256 gobblerId, address nft, uint256 id, bool isERC1155) external;
    function gobblerPrice() external view returns (uint256);
    function gobblerRevealsData()
        external
        view
        returns (uint64 randomSeed, uint64 nextRevealTimestamp, uint64 lastRevealedId, uint56 toBeRevealed, bool waitingForSeed);
    function goo() external view returns (address);
    function gooBalance(address user) external view returns (uint256);
    function hasClaimedMintlistGobbler(address) external view returns (bool);
    function isApprovedForAll(address, address) external view returns (bool);
    function legendaryGobblerAuctionData() external view returns (uint128 startPrice, uint128 numSold);
    function legendaryGobblerPrice() external view returns (uint256);
    function merkleRoot() external view returns (bytes32);
    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 gobblerId);
    function mintLegendaryGobbler(uint256[] memory gobblerIds) external returns (uint256 gobblerId);
    function mintReservedGobblers(uint256 numGobblersEach) external returns (uint256 lastMintedGobblerId);
    function mintStart() external view returns (uint256);
    function name() external view returns (string memory);
    function numMintedForReserves() external view returns (uint256);
    function numMintedFromGoo() external view returns (uint128);
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
    function owner() external view returns (address);
    function ownerOf(uint256 id) external view returns (address owner);
    function pages() external view returns (address);
    function randProvider() external view returns (address);
    function removeGoo(uint256 gooAmount) external;
    function requestRandomSeed() external returns (bytes32);
    function revealGobblers(uint256 numGobblers) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
    function symbol() external view returns (string memory);
    function targetPrice() external view returns (int256);
    function team() external view returns (address);
    function tokenURI(uint256 gobblerId) external view returns (string memory);
    function transferFrom(address from, address to, uint256 id) external;
    function transferOwnership(address newOwner) external;
    function upgradeRandProvider(address newRandProvider) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGOO {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function allowance(address, address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function artGobblers() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function burnForGobblers(address from, uint256 amount) external;
    function burnForPages(address from, uint256 amount) external;
    function decimals() external view returns (uint8);
    function mintForGobblers(address to, uint256 amount) external;
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function pages() external view returns (address);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}