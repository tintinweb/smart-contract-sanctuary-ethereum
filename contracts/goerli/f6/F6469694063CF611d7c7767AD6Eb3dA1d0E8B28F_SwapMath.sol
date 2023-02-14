// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
/// @dev Code has been modified to be compatible with sol 0.8
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDivFloor(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) public pure returns (uint256 result) {
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
      require(denominator > 0, '0 denom');
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1, 'denom <= prod1');

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
    unchecked {
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
    }
    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivCeiling(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDivFloor(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      result++;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title Contains constants needed for math libraries
library MathConstants {
  uint256 internal constant TWO_FEE_UNITS = 200_000;
  uint256 internal constant TWO_POW_96 = 2**96;
  uint128 internal constant MIN_LIQUIDITY = 100000;
  uint8 internal constant RES_96 = 96;
  uint24 internal constant BPS = 10000;
  uint24 internal constant FEE_UNITS = 100000;
  // it is strictly less than 5% price movement if jumping MAX_TICK_DISTANCE ticks
  int24 internal constant MAX_TICK_DISTANCE = 480;
  // max number of tick travel when inserting if data changes
  uint256 internal constant MAX_TICK_TRAVEL = 10;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

library QuadMath {
  // our equation is ax^2 - 2bx + c = 0, where a, b and c > 0
  // the qudratic formula to obtain the smaller root is (2b - sqrt((2*b)^2 - 4ac)) / 2a
  // which can be simplified to (b - sqrt(b^2 - ac)) / a
  function getSmallerRootOfQuadEqn(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (uint256 smallerRoot) {
    smallerRoot = (b - sqrt(b * b - a * c)) / a;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    unchecked {
      if (y > 3) {
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
          z = x;
          x = (y / x + x) / 2;
        }
      } else if (y != 0) {
        z = 1;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to uint32, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint32
  function toUint32(uint256 y) internal pure returns (uint32 z) {
    require((z = uint32(y)) == y);
  }

  /// @notice Cast a uint128 to a int128, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt128(uint128 y) internal pure returns (int128 z) {
    require(y < 2**127);
    z = int128(y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y the uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a int128 to a uint128 and reverses the sign.
  /// @param y The int128 to be casted
  /// @return z = -y, now type uint128
  function revToUint128(int128 y) internal pure returns (uint128 z) {
    unchecked {
      return type(uint128).max - uint128(y) + 1;
    }
  }

  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }

  /// @notice Cast a uint256 to a int256 and reverses the sign, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z = -y, now type int256
  function revToInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = -int256(y);
  }

  /// @notice Cast a int256 to a uint256 and reverses the sign.
  /// @param y The int256 to be casted
  /// @return z = -y, now type uint256
  function revToUint256(int256 y) internal pure returns (uint256 z) {
    unchecked {
      return type(uint256).max - uint256(y) + 1;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';
import {FullMath} from './FullMath.sol';
import {QuadMath} from './QuadMath.sol';
import {SafeCast} from './SafeCast.sol';

/// @title Contains helper functions for swaps
library SwapMath {
  using SafeCast for uint256;
  using SafeCast for int256;

  /// @dev Computes the actual swap input / output amounts to be deducted or added,
  /// the swap fee to be collected and the resulting sqrtP.
  /// @notice nextSqrtP should not exceed targetSqrtP.
  /// @param liquidity active base liquidity + reinvest liquidity
  /// @param currentSqrtP current sqrt price
  /// @param targetSqrtP sqrt price limit the new sqrt price can take
  /// @param feeInFeeUnits swap fee in basis points
  /// @param specifiedAmount the amount remaining to be used for the swap
  /// @param isExactInput true if specifiedAmount refers to input amount, false if specifiedAmount refers to output amount
  /// @param isToken0 true if specifiedAmount is in token0, false if specifiedAmount is in token1
  /// @return usedAmount actual amount to be used for the swap
  /// @return returnedAmount output qty to be accumulated if isExactInput = true, input qty if isExactInput = false
  /// @return deltaL collected swap fee, to be incremented to reinvest liquidity
  /// @return nextSqrtP the new sqrt price after the computed swap step
  function computeSwapStep(
    uint256 liquidity,
    uint160 currentSqrtP,
    uint160 targetSqrtP,
    uint256 feeInFeeUnits,
    int256 specifiedAmount,
    bool isExactInput,
    bool isToken0
  )
    internal
    pure
    returns (
      int256 usedAmount,
      int256 returnedAmount,
      uint256 deltaL,
      uint160 nextSqrtP
    )
  {
    // in the event currentSqrtP == targetSqrtP because of tick movements, return
    // eg. swapped up tick where specified price limit is on an initialised tick
    // then swapping down tick will cause next tick to be the same as the current tick
    if (currentSqrtP == targetSqrtP) return (0, 0, 0, currentSqrtP);
    usedAmount = calcReachAmount(
      liquidity,
      currentSqrtP,
      targetSqrtP,
      feeInFeeUnits,
      isExactInput,
      isToken0
    );

    if (
      (isExactInput && usedAmount >= specifiedAmount) ||
      (!isExactInput && usedAmount <= specifiedAmount)
    ) {
      usedAmount = specifiedAmount;
    } else {
      nextSqrtP = targetSqrtP;
    }

    uint256 absDelta = usedAmount >= 0 ? uint256(usedAmount) : usedAmount.revToUint256();
    if (nextSqrtP == 0) {
      deltaL = estimateIncrementalLiquidity(
        absDelta,
        liquidity,
        currentSqrtP,
        feeInFeeUnits,
        isExactInput,
        isToken0
      );
      nextSqrtP = calcFinalPrice(absDelta, liquidity, deltaL, currentSqrtP, isExactInput, isToken0)
      .toUint160();
    } else {
      deltaL = calcIncrementalLiquidity(
        absDelta,
        liquidity,
        currentSqrtP,
        nextSqrtP,
        isExactInput,
        isToken0
      );
    }
    returnedAmount = calcReturnedAmount(
      liquidity,
      currentSqrtP,
      nextSqrtP,
      deltaL,
      isExactInput,
      isToken0
    );
  }

  /// @dev calculates the amount needed to reach targetSqrtP from currentSqrtP
  /// @dev we cast currentSqrtP and targetSqrtP to uint256 as they are multiplied by TWO_FEE_UNITS or feeInFeeUnits
  function calcReachAmount(
    uint256 liquidity,
    uint256 currentSqrtP,
    uint256 targetSqrtP,
    uint256 feeInFeeUnits,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (int256 reachAmount) {
    uint256 absPriceDiff;
    unchecked {
      absPriceDiff = (currentSqrtP >= targetSqrtP)
        ? (currentSqrtP - targetSqrtP)
        : (targetSqrtP - currentSqrtP);
    }
    if (isExactInput) {
      // we round down so that we avoid taking giving away too much for the specified input
      // ie. require less input qty to move ticks
      if (isToken0) {
        // numerator = 2 * liquidity * absPriceDiff
        // denominator = currentSqrtP * (2 * targetSqrtP - currentSqrtP * feeInFeeUnits / FEE_UNITS)
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * currentSqrtP;
        uint256 numerator = FullMath.mulDivFloor(
          liquidity,
          C.TWO_FEE_UNITS * absPriceDiff,
          denominator
        );
        reachAmount = FullMath.mulDivFloor(numerator, C.TWO_POW_96, currentSqrtP).toInt256();
      } else {
        // numerator = 2 * liquidity * absPriceDiff * currentSqrtP
        // denominator = 2 * currentSqrtP - targetSqrtP * feeInFeeUnits / FEE_UNITS
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * currentSqrtP - feeInFeeUnits * targetSqrtP;
        uint256 numerator = FullMath.mulDivFloor(
          liquidity,
          C.TWO_FEE_UNITS * absPriceDiff,
          denominator
        );
        reachAmount = FullMath.mulDivFloor(numerator, currentSqrtP, C.TWO_POW_96).toInt256();
      }
    } else {
      // we will perform negation as the last step
      // we round down so that we require less output qty to move ticks
      if (isToken0) {
        // numerator: (liquidity)(absPriceDiff)(2 * currentSqrtP - deltaL * (currentSqrtP + targetSqrtP))
        // denominator: (currentSqrtP * targetSqrtP) * (2 * currentSqrtP - deltaL * targetSqrtP)
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * currentSqrtP - feeInFeeUnits * targetSqrtP;
        uint256 numerator = denominator - feeInFeeUnits * currentSqrtP;
        numerator = FullMath.mulDivFloor(liquidity << C.RES_96, numerator, denominator);
        reachAmount = (FullMath.mulDivFloor(numerator, absPriceDiff, currentSqrtP) / targetSqrtP)
        .revToInt256();
      } else {
        // numerator: liquidity * absPriceDiff * (TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * (targetSqrtP + currentSqrtP))
        // denominator: (TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * currentSqrtP)
        // overflow should not happen because the absPriceDiff is capped to ~5%
        uint256 denominator = C.TWO_FEE_UNITS * targetSqrtP - feeInFeeUnits * currentSqrtP;
        uint256 numerator = denominator - feeInFeeUnits * targetSqrtP;
        numerator = FullMath.mulDivFloor(liquidity, numerator, denominator);
        reachAmount = FullMath.mulDivFloor(numerator, absPriceDiff, C.TWO_POW_96).revToInt256();
      }
    }
  }

  /// @dev estimates deltaL, the swap fee to be collected based on amount specified
  /// for the final swap step to be performed,
  /// where the next (temporary) tick will not be crossed
  function estimateIncrementalLiquidity(
    uint256 absDelta,
    uint256 liquidity,
    uint160 currentSqrtP,
    uint256 feeInFeeUnits,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (uint256 deltaL) {
    if (isExactInput) {
      if (isToken0) {
        // deltaL = feeInFeeUnits * absDelta * currentSqrtP / 2
        deltaL = FullMath.mulDivFloor(
          currentSqrtP,
          absDelta * feeInFeeUnits,
          C.TWO_FEE_UNITS << C.RES_96
        );
      } else {
        // deltaL = feeInFeeUnits * absDelta * / (currentSqrtP * 2)
        // Because nextSqrtP = (liquidity + absDelta / currentSqrtP) * currentSqrtP / (liquidity + deltaL)
        // so we round up deltaL, to round down nextSqrtP
        deltaL = FullMath.mulDivFloor(
          C.TWO_POW_96,
          absDelta * feeInFeeUnits,
          C.TWO_FEE_UNITS * currentSqrtP
        );
      }
    } else {
      // obtain the smaller root of the quadratic equation
      // ax^2 - 2bx + c = 0 such that b > 0, and x denotes deltaL
      uint256 a = feeInFeeUnits;
      uint256 b = (C.FEE_UNITS - feeInFeeUnits) * liquidity;
      uint256 c = feeInFeeUnits * liquidity * absDelta;
      if (isToken0) {
        // a = feeInFeeUnits
        // b = (FEE_UNITS - feeInFeeUnits) * liquidity - FEE_UNITS * absDelta * currentSqrtP
        // c = feeInFeeUnits * liquidity * absDelta * currentSqrtP
        b -= FullMath.mulDivFloor(C.FEE_UNITS * absDelta, currentSqrtP, C.TWO_POW_96);
        c = FullMath.mulDivFloor(c, currentSqrtP, C.TWO_POW_96);
      } else {
        // a = feeInFeeUnits
        // b = (FEE_UNITS - feeInFeeUnits) * liquidity - FEE_UNITS * absDelta / currentSqrtP
        // c = liquidity * feeInFeeUnits * absDelta / currentSqrtP
        b -= FullMath.mulDivFloor(C.FEE_UNITS * absDelta, C.TWO_POW_96, currentSqrtP);
        c = FullMath.mulDivFloor(c, C.TWO_POW_96, currentSqrtP);
      }
      deltaL = QuadMath.getSmallerRootOfQuadEqn(a, b, c);
    }
  }

  /// @dev calculates deltaL, the swap fee to be collected for an intermediate swap step,
  /// where the next (temporary) tick will be crossed
  function calcIncrementalLiquidity(
    uint256 absDelta,
    uint256 liquidity,
    uint160 currentSqrtP,
    uint160 nextSqrtP,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (uint256 deltaL) {
    if (isToken0) {
      // deltaL = nextSqrtP * (liquidity / currentSqrtP +/- absDelta)) - liquidity
      // needs to be minimum
      uint256 tmp1 = FullMath.mulDivFloor(liquidity, C.TWO_POW_96, currentSqrtP);
      uint256 tmp2 = isExactInput ? tmp1 + absDelta : tmp1 - absDelta;
      uint256 tmp3 = FullMath.mulDivFloor(nextSqrtP, tmp2, C.TWO_POW_96);
      // in edge cases where liquidity or absDelta is small
      // liquidity might be greater than nextSqrtP * ((liquidity / currentSqrtP) +/- absDelta))
      // due to rounding
      deltaL = (tmp3 > liquidity) ? tmp3 - liquidity : 0;
    } else {
      // deltaL = (liquidity * currentSqrtP +/- absDelta) / nextSqrtP - liquidity
      // needs to be minimum
      uint256 tmp1 = FullMath.mulDivFloor(liquidity, currentSqrtP, C.TWO_POW_96);
      uint256 tmp2 = isExactInput ? tmp1 + absDelta : tmp1 - absDelta;
      uint256 tmp3 = FullMath.mulDivFloor(tmp2, C.TWO_POW_96, nextSqrtP);
      // in edge cases where liquidity or absDelta is small
      // liquidity might be greater than nextSqrtP * ((liquidity / currentSqrtP) +/- absDelta))
      // due to rounding
      deltaL = (tmp3 > liquidity) ? tmp3 - liquidity : 0;
    }
  }

  /// @dev calculates the sqrt price of the final swap step
  /// where the next (temporary) tick will not be crossed
  function calcFinalPrice(
    uint256 absDelta,
    uint256 liquidity,
    uint256 deltaL,
    uint160 currentSqrtP,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (uint256) {
    if (isToken0) {
      // if isExactInput: swap 0 -> 1, sqrtP decreases, we round up
      // else swap: 1 -> 0, sqrtP increases, we round down
      uint256 tmp = FullMath.mulDivFloor(absDelta, currentSqrtP, C.TWO_POW_96);
      if (isExactInput) {
        return FullMath.mulDivCeiling(liquidity + deltaL, currentSqrtP, liquidity + tmp);
      } else {
        return FullMath.mulDivFloor(liquidity + deltaL, currentSqrtP, liquidity - tmp);
      }
    } else {
      // if isExactInput: swap 1 -> 0, sqrtP increases, we round down
      // else swap: 0 -> 1, sqrtP decreases, we round up
      if (isExactInput) {
        uint256 tmp = FullMath.mulDivFloor(absDelta, C.TWO_POW_96, currentSqrtP);
        return FullMath.mulDivFloor(liquidity + tmp, currentSqrtP, liquidity + deltaL);
      } else {
        uint256 tmp = FullMath.mulDivFloor(absDelta, C.TWO_POW_96, currentSqrtP);
        return FullMath.mulDivCeiling(liquidity - tmp, currentSqrtP, liquidity + deltaL);
      }
    }
  }

  /// @dev calculates returned output | input tokens in exchange for specified amount
  /// @dev round down when calculating returned output (isExactInput) so we avoid sending too much
  /// @dev round up when calculating returned input (!isExactInput) so we get desired output amount
  function calcReturnedAmount(
    uint256 liquidity,
    uint160 currentSqrtP,
    uint160 nextSqrtP,
    uint256 deltaL,
    bool isExactInput,
    bool isToken0
  ) internal pure returns (int256 returnedAmount) {
    if (isToken0) {
      if (isExactInput) {
        // minimise actual output (<0, make less negative) so we avoid sending too much
        // returnedAmount = deltaL * nextSqrtP - liquidity * (currentSqrtP - nextSqrtP)
        returnedAmount =
          FullMath.mulDivCeiling(deltaL, nextSqrtP, C.TWO_POW_96).toInt256() +
          FullMath.mulDivFloor(liquidity, currentSqrtP - nextSqrtP, C.TWO_POW_96).revToInt256();
      } else {
        // maximise actual input (>0) so we get desired output amount
        // returnedAmount = deltaL * nextSqrtP + liquidity * (nextSqrtP - currentSqrtP)
        returnedAmount =
          FullMath.mulDivCeiling(deltaL, nextSqrtP, C.TWO_POW_96).toInt256() +
          FullMath.mulDivCeiling(liquidity, nextSqrtP - currentSqrtP, C.TWO_POW_96).toInt256();
      }
    } else {
      // returnedAmount = (liquidity + deltaL)/nextSqrtP - (liquidity)/currentSqrtP
      // if exactInput, minimise actual output (<0, make less negative) so we avoid sending too much
      // if exactOutput, maximise actual input (>0) so we get desired output amount
      returnedAmount =
        FullMath.mulDivCeiling(liquidity + deltaL, C.TWO_POW_96, nextSqrtP).toInt256() +
        FullMath.mulDivFloor(liquidity, C.TWO_POW_96, currentSqrtP).revToInt256();
    }

    if (isExactInput && returnedAmount == 1) {
      // rounding make returnedAmount == 1
      returnedAmount = 0;
    }
  }
}