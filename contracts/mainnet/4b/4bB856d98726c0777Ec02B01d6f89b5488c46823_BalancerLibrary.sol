pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

library BalancerLibrary {
    uint256 private constant MAX_LOOP_LIMIT = 256;
    uint256 private constant DERIVATIVE_MULTIPLIER = 1000000;

    function balanceLiquidityCP(
        uint256[4] memory r,
        uint256 feeNumerator,
        uint256 maxFee
    ) public pure returns (uint256[4] memory) {
        {
            uint256 balanced0 = (r[3] * r[0]) / r[1];
            if (balanced0 == r[2]) {
                uint[4] memory _result;
                return _result;
            } else if (balanced0 > r[2]) {
                return inverse(balanceLiquidityCP(inverse(r), feeNumerator, maxFee));
            }
        }
        uint256[4] memory result;
        result[0] = 0;
        result[3] = getYCP(r[0], r[1], result[0], feeNumerator, maxFee);
        uint256 prevX;
        uint256 yDerivative;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            prevX = result[0];
            yDerivative = getYDerivativeCP(
                r[0],
                r[1],
                result[0],
                result[3],
                feeNumerator,
                maxFee,
                DERIVATIVE_MULTIPLIER
            );
            result[0] = getX(r, result[0], result[3], yDerivative);
            if (result[0] != prevX) {
                result[3] = getYCP(r[0], r[1], result[0], feeNumerator, maxFee);
            }
            if (within1(result[0], prevX)) {
                break;
            }
        }
        return result;
    }

    function balanceLiquiditySS(
        uint256[4] memory r,
        uint256 feeNumerator,
        uint256 maxFee,
        uint256 A,
        uint256 A_PRECISION
    ) public pure returns (uint256[4] memory) {
        {
            uint256 balanced0 = (r[3] * r[0]) / r[1];
            if (balanced0 == r[2]) {
                uint[4] memory _result;
                return _result;
            } else if (balanced0 > r[2]) {
                return inverse(balanceLiquiditySS(inverse(r), feeNumerator, maxFee, A, A_PRECISION));
            }
        }
        uint256[4] memory result;
        uint256 d = getD(r[0], r[1], A, A_PRECISION);
        result[0] = 0;
        result[3] = getYSS(r[0], r[1], result[0], d, feeNumerator, maxFee, A, A_PRECISION);
        uint256 prevX;
        uint256 yDerivative;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            prevX = result[0];
            uint256[5] memory derivativeR = [r[0], r[1], result[0], result[3], d];
            yDerivative = getYDerivativeSS(derivativeR, feeNumerator, maxFee, A, A_PRECISION, DERIVATIVE_MULTIPLIER);
            result[0] = getX(r, result[0], result[3], yDerivative);
            if (result[0] != prevX) {
                result[3] = getYSS(r[0], r[1], result[0], d, feeNumerator, maxFee, A, A_PRECISION);
            }
            if (within1(result[0], prevX)) {
                break;
            }
        }
        return result;
    }

    function inverse(uint256[4] memory values) internal pure returns (uint256[4] memory) {
        uint256 temp = values[0];
        values[0] = values[1];
        values[1] = temp;
        temp = values[2];
        values[2] = values[3];
        values[3] = temp;
        return values;
    }

    function getX(
        uint256[4] memory r,
        uint256 x,
        uint256 y,
        uint256 yDerivative
    ) private pure returns (uint256) {
        int256 numerator = int256((r[2] - x) * (r[1] - y)) - int256((r[3] + y) * (r[0] + x));
        numerator = numerator * int256(DERIVATIVE_MULTIPLIER);
        uint256 denominator = yDerivative * (r[0] + r[2]) + r[1] * DERIVATIVE_MULTIPLIER;
        return uint256(int256(x) + numerator / int256(denominator));
    }

    function getYCP(
        uint256 r0,
        uint256 r1,
        uint256 x,
        uint256 feeNumerator,
        uint256 feeDenominator
    ) private pure returns (uint256) {
        uint256 numerator = r0 * r1 * feeDenominator;
        uint256 denominator = r0 * feeDenominator + x * feeNumerator;
        return (r1 * denominator - numerator) / denominator;
    }

    function getYDerivativeCP(
        uint256 r0,
        uint256 r1,
        uint256 x,
        uint256 y,
        uint256 feeNumerator,
        uint256 feeDenominator,
        uint256 resultMultiplier
    ) private pure returns (uint256) {
        uint256 numerator = (r1 - y) * feeNumerator * resultMultiplier;
        uint256 denominator = r0 * feeDenominator + x * feeNumerator;
        return numerator / denominator;
    }

    function getYSS(
        uint256 r0,
        uint256 r1,
        uint256 x,
        uint256 d,
        uint256 feeNumerator,
        uint256 feeDenominator,
        uint256 A,
        uint256 A_PRECISION
    ) private pure returns (uint256) {
        x = x * feeNumerator / feeDenominator;
        return r1 - getY(r0 + x, d, A, A_PRECISION);
    }

    function getYDerivativeSS(
        uint256[5] memory r, // r0, r1, x, y, d
        uint256 feeNumerator,
        uint256 feeDenominator,
        uint256 A,
        uint256 A_PRECISION,
        uint256 resultMultiplier
    ) private pure returns (uint256) {
        uint256 val1 = (r[0] * feeDenominator + feeNumerator * r[2]) / feeDenominator;
        uint256 val2 = r[1] - r[3];
        uint256 denominator = 4 * A * 16 * val1 * val2;
        uint256 dP = (((A_PRECISION * r[4] * r[4]) / val1) * r[4]) / val2;
        uint256 numerator = (denominator * feeNumerator) / feeDenominator + dP;
        numerator = numerator * resultMultiplier;
        return numerator / denominator;
    }

    function getD(
        uint256 xp0,
        uint256 xp1,
        uint256 A,
        uint256 A_PRECISION
    ) public pure returns (uint256 d) {
        uint256 x = xp0 < xp1 ? xp0 : xp1;
        uint256 y = xp0 < xp1 ? xp1 : xp0;
        uint256 s = x + y;
        if (s == 0) {
            return 0;
        }

        uint256 N_A = 16 * A;
        uint256 numeratorP = N_A * s * y;
        uint256 denominatorP = (N_A - 4 * A_PRECISION) * y;

        uint256 prevD;
        d = s;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            prevD = d;
            uint256 N_D = (A_PRECISION * d * d) / x;
            d = (2 * d * N_D + numeratorP) / (3 * N_D + denominatorP);
            if (within1(d, prevD)) {
                break;
            }
        }
    }

    function getY(
        uint256 x,
        uint256 d,
        uint256 A,
        uint256 A_PRECISION
    ) private pure returns (uint256 y) {
        uint256 yPrev;
        y = d;
        uint256 N_A = A * 4;
        uint256 numeratorP = (((A_PRECISION * d * d) / x) * d) / 4;
        unchecked {
            uint256 denominatorP = N_A * (x - d) + d * A_PRECISION; // underflow is possible and desired

            // @dev Iterative approximation.
            for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
                yPrev = y;
                uint256 N_Y = N_A * y;
                y = divRoundUp(N_Y * y + numeratorP, 2 * N_Y + denominatorP);
                if (within1(y, yPrev)) {
                    break;
                }
            }
        }
    }

    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        if (a > b) {
            return a - b <= 1;
        }
        return b - a <= 1;
    }

    function divRoundUp(uint numerator, uint denumerator) private pure returns (uint) {
        return (numerator + denumerator - 1) / denumerator;
    }
}