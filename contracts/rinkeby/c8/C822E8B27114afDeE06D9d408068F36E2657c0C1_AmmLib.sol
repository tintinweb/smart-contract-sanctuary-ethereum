// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { SigmaMath } from "./SigmaMath.sol";

library AmmLib {
    struct InternalNewtonYAstp {
        uint256 x_j;
        uint256 y;
        uint256 K0_i;
        uint256 convergence_limit;
        uint256 y_prev;
        uint256 K0;
        uint256 S;
        uint256 _g1k0;
    }

    struct GlobalInitializeParams {
        uint256 initialAGamma;
        uint256 initialAGammaTime;
        uint256 adjustmentStep;
        uint256 maHalfTime;
    }

    struct GlobalFutureParams {
        uint256 futureAGamma;
        uint256 futureAGammaTime;
        uint256 futureAdjustmentStep;
        uint256 futureMAHalfTime;
    }

    struct PriceSnapshort {
        uint256 roundId;
        uint256 price;
        uint256 timestamp;
    }

    uint256 internal constant N_COINS = 2;
    uint256 internal constant EXP_PRECISION = 10**10;
    uint256 internal constant A_MULTIPLIER = 10000;
    uint256 internal constant MIN_GAMMA = 10**10;
    uint256 internal constant MAX_GAMMA = 2 * 10**16;
    uint256 internal constant MIN_A = (N_COINS**N_COINS * A_MULTIPLIER) / 10;
    uint256 internal constant MAX_A = N_COINS**N_COINS * A_MULTIPLIER * 100000;

    /**
     * Math functions
     */
    function geometric_mean(uint256[N_COINS] memory unsorted_x, bool sort) internal pure returns (uint256) {
        // (x[0] * x[1] * ...) ** (1/N)
        uint256[N_COINS] memory x = SigmaMath.copy(unsorted_x);
        if (sort && x[0] < x[1]) {
            x = [unsorted_x[1], unsorted_x[0]];
        }
        uint256 D = x[0];
        uint256 diff = 0;
        for (uint8 i = 0; i < 255; i++) {
            uint256 D_prev = D;

            // uint256 tmp = 10**18
            // for _x in x:
            //     tmp = tmp * _x / D
            // D = D * ((N_COINS - 1) * 10**18 + tmp) / (N_COINS * 10**18)
            // line below makes it for 2 coins
            D = (D + (x[0] * x[1]) / D) / N_COINS;
            if (D > D_prev) {
                diff = D - D_prev;
            } else {
                diff = D_prev - D;
            }
            if (diff <= 1 || diff * 10**18 < D) {
                return D;
            }
        }
        revert("Did not converge");
    }

    function newton_D(
        uint256 ANN,
        uint256 gamma,
        uint256[N_COINS] memory x_unsorted
    ) internal pure returns (uint256) {
        // Finding the invariant using Newton method.
        // ANN is higher by the factor A_MULTIPLIER
        // ANN is already A * N**N
        // Currently uses 60k gas

        // AW_USVA: unsafe A
        require((ANN > MIN_A - 1) && (ANN < MAX_A + 1), "AW_USA");
        // AW_USG: unsafe gamma
        require((gamma > MIN_GAMMA - 1) && (gamma < MAX_GAMMA + 1), "AW_USG");

        // Initial value of invariant D is that for constant-product invariant
        uint256[N_COINS] memory x = SigmaMath.copy(x_unsorted);
        if (x[0] < x[1]) {
            x = [x_unsorted[1], x_unsorted[0]];
        }

        // AW_USQM: unsafe quote token amount
        require((x[0] > 10**9 - 1) && (x[0] < 10**15 * 10**18 + 1), "AW_USQM");
        // AW_USBM: unsafe base token amount
        require(((x[1] * 10**18) / x[0]) > (10**14 - 1), "AW_USBM");

        uint256 D = N_COINS * geometric_mean(x, false);
        uint256 S = x[0] + x[1];

        for (uint8 i = 0; i < 255; i++) {
            uint256 D_prev = D;

            // uint256 K0 = 10**18
            // for _x in x:
            //     K0 = K0 * _x * N_COINS / D
            // collapsed for 2 coins
            // uint256 K0 = ((((10**18 * N_COINS**2) * x[0]) / D) * x[1]) / D;
            uint256 K0 = (10**18 * N_COINS**2 * x[0] * x[1]) / (D * D);
            uint256 _g1k0 = gamma + 10**18;
            if (_g1k0 > K0) {
                _g1k0 = _g1k0 - K0 + 1;
            } else {
                _g1k0 = K0 - _g1k0 + 1;
            }

            // D / (A * N**N) * _g1k0**2 / gamma**2
            // uint256 mul1 = (10**18 * D * _g1k0 * _g1k0 * A_MULTIPLIER) / (ANN * gamma * gamma);
            uint256 mul1 = (((((10**18 * D) / gamma) * _g1k0) / gamma) * _g1k0 * A_MULTIPLIER) / ANN;

            // 2*N*K0 / _g1k0
            uint256 mul2 = ((2 * 10**18) * N_COINS * K0) / _g1k0;
            uint256 neg_fprime = (S + (S * mul2) / 10**18) + (mul1 * N_COINS) / K0 - (mul2 * D) / 10**18;

            // D -= f / fprime
            uint256 D_plus = (D * (neg_fprime + S)) / neg_fprime;
            uint256 D_minus = (D * D) / neg_fprime;

            if (10**18 > K0) {
                D_minus += (((D * (mul1 / neg_fprime)) / 10**18) * (10**18 - K0)) / K0;
            } else {
                D_minus -= (((D * (mul1 / neg_fprime)) / 10**18) * (K0 - 10**18)) / K0;
            }

            if (D_plus > D_minus) {
                D = D_plus - D_minus;
            } else {
                D = (D_minus - D_plus) / 2;
            }

            uint256 diff = 0;
            if (D > D_prev) {
                diff = D - D_prev;
            } else {
                diff = D_prev - D;
            }
            if (diff * 10**14 < SigmaMath.max(10**16, D)) {
                // Could reduce precision for gas efficiency here
                // Test that we are safe with the next newton_y
                for (uint8 k = 0; k < N_COINS; k++) {
                    uint256 _x = x[k];
                    uint256 frac = (_x * 10**18) / D;
                    // AW_USX: unsafe value x[i]
                    require((frac > 10**16 - 1) && (frac < 10**20 + 1), "AW_USX");
                }
                return D;
            }
        }
        revert("Did not converge");
    }

    function newton_y(
        uint256 ANN,
        uint256 gamma,
        uint256[N_COINS] memory x,
        uint256 D,
        uint256 i
    ) internal pure returns (uint256) {
        // Calculating x[i] given other balances x[0..N_COINS-1] and invariant D
        // ANN = A * N**N
        // AW_USA: unsafe values A
        require((ANN > MIN_A - 1) && (ANN < MAX_A + 1), "AW_USA");
        // AW_USG: unsafe values gamma
        require((gamma > MIN_GAMMA - 1) && (gamma < MAX_GAMMA + 1), "AW_USG");
        // AW_USD: unsafe values D
        require((D > 10**17 - 1) && (D < 10**15 * 10**18 + 1), "AW_USD");

        InternalNewtonYAstp memory nty;
        nty.x_j = x[1 - i];
        nty.y = D**2 / (nty.x_j * N_COINS**2);
        nty.K0_i = ((10**18 * N_COINS) * nty.x_j) / D;

        // S_i = nty.x_j
        // frac = nty.x_j * 1e18 / D => frac = nty.K0_i / N_COINS
        // AW_USX: unsafe values x[i]
        require((nty.K0_i > 10**16 * N_COINS - 1) && (nty.K0_i < 10**20 * N_COINS + 1), "AW_USX");

        // uint256[N_COINS] memory x_sorted = x
        // x_sorted[i] = 0
        // x_sorted = self.sort(x_sorted)  // From high to low
        // x[not i] instead of x_sorted since x_soted has only 1 element
        nty.convergence_limit = SigmaMath.max(SigmaMath.max(nty.x_j / 10**14, D / 10**14), 100);

        for (uint8 j = 0; j < 255; j++) {
            nty.y_prev = nty.y;
            nty.K0 = (nty.K0_i * nty.y * N_COINS) / D;
            nty.S = nty.x_j + nty.y;
            nty._g1k0 = gamma + 10**18;

            if (nty._g1k0 > nty.K0) {
                nty._g1k0 = nty._g1k0 - nty.K0 + 1;
            } else {
                nty._g1k0 = nty.K0 - nty._g1k0 + 1;
            }

            // D / (A * N**N) * nty._g1k0**2 / gamma**2
            uint256 mul1 = (((((10**18 * D) / gamma) * nty._g1k0) / gamma) * nty._g1k0 * A_MULTIPLIER) / ANN;

            // 2*nty.K0 / nty._g1k0
            uint256 mul2 = 10**18 + ((2 * 10**18) * nty.K0) / nty._g1k0;
            uint256 yfprime = 10**18 * nty.y + nty.S * mul2 + mul1;
            uint256 _dyfprime = D * mul2;

            if (yfprime < _dyfprime) {
                nty.y = nty.y_prev / 2;
                continue;
            } else {
                yfprime -= _dyfprime;
            }
            uint256 fprime = yfprime / nty.y;

            // y -= f / f_prime;  y = (y * fprime - f) / fprime
            // y = (yfprime + 10**18 * D - 10**18 * nty.S) // fprime + mul1 // fprime * (10**18 - nty.K0) // nty.K0
            uint256 y_minus = mul1 / fprime;
            uint256 y_plus = (yfprime + 10**18 * D) / fprime + (y_minus * 10**18) / nty.K0;
            y_minus += (10**18 * nty.S) / fprime;

            if (y_plus < y_minus) {
                nty.y = nty.y_prev / 2;
            } else {
                nty.y = y_plus - y_minus;
            }

            uint256 diff = 0;
            if (nty.y > nty.y_prev) {
                diff = nty.y - nty.y_prev;
            } else {
                diff = nty.y_prev - nty.y;
            }
            if (diff < SigmaMath.max(nty.convergence_limit, nty.y / 10**14)) {
                uint256 frac = (nty.y * 10**18) / D;
                // AW_USY: unsafe value for y
                require((frac > 10**16 - 1) && (frac < 10**20 + 1), "AW_USY");

                return nty.y;
            }
        }
        revert("Did not converge");
    }

    function halfpow(uint256 power) external pure returns (uint256) {
        // 1e18 * 0.5 ** (power/1e18)
        // Inspired by: https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol//L128
        uint256 intpow = power / 10**18;
        uint256 otherpow = power - intpow * 10**18;

        if (intpow > 59) {
            return 0;
        }

        uint256 result = 10**18 / (2**intpow);
        if (otherpow == 0) {
            return result;
        }

        uint256 term = 10**18;
        uint256 x = 5 * 10**17;
        uint256 S = 10**18;
        bool neg = false;

        for (uint256 i = 1; i < 256; i++) {
            uint256 K = i * (10**18);
            uint256 c = K - 10**18;
            if (otherpow > c) {
                c = otherpow - c;
                neg = !neg;
            } else {
                c -= otherpow;
            }

            term = (term * ((c * x) / 10**18)) / K;

            if (neg) {
                S -= term;
            } else {
                S += term;
            }
            if (term < EXP_PRECISION) {
                return (result * S) / 10**18;
            }
        }
        revert("Did not converge");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.0;
pragma abicoder v2;

import { FullMath } from "./FullMath.sol";
import { Constant } from "./Constant.sol";

library SigmaMath {
    function copy(uint256[2] memory data) internal pure returns (uint256[2] memory) {
        uint256[2] memory result;
        for (uint8 i = 0; i < 2; i++) {
            result[i] = data[i];
        }
        return result;
    }

    function shift(uint256 x, int256 _shift) internal pure returns (uint256) {
        if (_shift > 0) {
            return x << abs(_shift);
        } else if (_shift < 0) {
            return x >> abs(_shift);
        }

        return x;
    }

    function bitwise_or(uint256 x, uint256 y) internal pure returns (uint256) {
        return x | y;
    }

    function bitwise_and(uint256 x, uint256 y) internal pure returns (uint256) {
        return x & y;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? toUint256(value) : toUint256(neg256(value));
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "SigmaMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -toInt256(a);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, Constant.IQ96, 1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : toInt256(unsignedResult);

        return result;
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        // uint256 twos = -denominator & denominator;
        uint256 twos = denominator & (~denominator + 1);

        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

library Constant {
    address internal constant INVALID_ADDRESS = address(0);
    uint256 internal constant DECIMAL_ONE = 1e18;
    int256 internal constant DECIMAL_ONE_SIGNED = 1e18;
    uint256 internal constant IQ96 = 0x1000000000000000000000000;
    int256 internal constant IQ96_SIGNED = 0x1000000000000000000000000;
}