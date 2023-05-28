// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        result += xh == hi >> 128 ? xl / y : 1;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x4) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
// solhint-disable-next-line
import {SignedSafeMath} from "openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {Base64} from "base64/base64.sol";

// solhint-disable-next-line
// import "forge-std/Test.sol";

/// @author hashrunner.eth
/// @title  Upgradeable renderer interface and contract
contract Renderer is Ownable {
    using SignedSafeMath for int16;

    struct InitInstructions {
        bytes1 sym1;
        uint256 nCol;
        bytes1 sym2;
        uint256 mCol;
        string title;
    }

    struct ShapeInstructions {
        bytes1 sym;
        uint8 arr;
        int16 row;
        int16 col;
        int16 nR;
        int16 nC;
        int16[] repeatRows;
        int16[] repeatCols;
    }

    string public description;

    constructor() Ownable() {
        description = "ART0x1 is an ethereum runtime art program based on"
        " ART1, developed by Richard Williams in 1968 for the IBM 360"
        " mainframe computer.";
    }

    /* --------------------------------------------------------------------- */
    /*                              TOKEN URI                                */
    /* --------------------------------------------------------------------- */

    function tokenURI(
        uint256 _tokenId,
        bytes[11] memory _instructions
    ) external view returns (string memory) {
        string[6] memory palettes = [
            // color
            "#EEEEEE",
            "#303030",
            "#303030",
            // bgColor
            "#303030",
            "#EEEEEE",
            "#FFF5E6"
        ];

        uint256 paletteIndex = uint256(
            keccak256(abi.encodePacked("colors", _tokenId))
        ) % 3;

        string memory color = palettes[paletteIndex];
        string memory bgColor = palettes[3 + paletteIndex];

        string memory json;
        json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"id": "',
                        uintToString(_tokenId),
                        '", "name: "ART0x1 #',
                        uintToString(_tokenId),
                        '", "description": "',
                        description,
                        '", "attributes": [{"trait_type": "Program", "value": ',
                        noInstructions(_instructions)
                            ? '"Un-instructed"'
                            : '"Instructed"',
                        '}, {"trait_type": "Era", "value": ',
                        _tokenId < 10000 ? '"Genesis"' : '"Hyperstructure"',
                        '}], "image": "data:image/svg+xml;base64,',
                        noInstructions(_instructions)
                            ? idle(color, bgColor)
                            : run(_instructions, color, bgColor),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /* --------------------------------------------------------------------- */
    /*                                CORE                                   */
    /* --------------------------------------------------------------------- */

    /* ------------------------------- IDLE -------------------------------- */

    function idle(
        string memory _color,
        string memory _bgColor
    ) public pure returns (string memory) {
        return
            Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            // solhint-disable-next-line
                            '<svg width="1096" height="772" viewBox="0 0 1096 772" xmlns="http://www.w3.org/2000/svg">',
                            // solhint-disable-next-line
                            '<style>.t{font:12px "Source Code Pro",monospace;text-anchor:middle;fill:',
                            _color,
                            // solhint-disable-next-line
                            '</style><rect x="0" y="0" width="1096" height="772" style="fill:',
                            _bgColor,
                            // solhint-disable-next-line
                            '" /><text class="t" x="50%" y="50%" xml:space="preserve">Un-instructed ART0x1 Token.</text></svg>'
                        )
                    )
                )
            );
    }

    /* ------------------------------- RUN --------------------------------- */

    function run(
        bytes[11] memory _instructions,
        string memory _color,
        string memory _bgColor
    ) public view returns (string memory) {
        // Define 2x two-dimensional dynamic arrays
        bytes1[][] memory array1 = new bytes1[][](50);
        bytes1[][] memory array2 = new bytes1[][](50);

        // workaround two-dimensional array instantiation
        for (uint256 i = 0; i < 50; ) {
            array1[i] = new bytes1[](105);
            array2[i] = new bytes1[](105);
            unchecked {
                ++i;
            }
        }

        // Define title string
        string memory title;
        // initialize arrays based on first instruction set
        (array1, array2, title) = init(array1, array2, _instructions[0]);

        // define lookup table for figure functions
        function(bytes1[][] memory, bytes1[][] memory, bytes memory)
            view
            returns (bytes1[][] memory, bytes1[][] memory)[]
            memory subPrograms = new function(
                bytes1[][] memory,
                bytes1[][] memory,
                bytes memory
            ) view returns (bytes1[][] memory, bytes1[][] memory)[](5);

        subPrograms[0] = line;
        subPrograms[1] = solidRect;
        subPrograms[2] = openRect;
        subPrograms[3] = triangle;
        subPrograms[4] = ellipse;
        // subPrograms[5] = exponential;

        // iterate over remaining instruction strings and call figure functions
        for (uint256 i = 1; i < _instructions.length; ) {
            if (_instructions[i].length == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }
            // convert ASCII digit to uint
            uint256 func = uint256(uint8(_instructions[i][0])) - 48;

            bytes memory instr = new bytes(_instructions[i].length);
            for (uint256 j = 0; j < _instructions[i].length; j++) {
                instr[j] = _instructions[i][j];
            }

            // call figure function based on first digit of instruction string
            if (func < subPrograms.length) {
                (array1, array2) = subPrograms[func](array1, array2, instr);
            } else {
                revert("Invalid sub program: id does not exist.");
            }
            unchecked {
                ++i;
            }
        }

        // return data in SVG format
        return print(array1, array2, title, _color, _bgColor);
    }

    /* ------------------------------- INIT ------------------------------- */

    function init(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    )
        internal
        pure
        returns (bytes1[][] memory, bytes1[][] memory, string memory)
    {
        InitInstructions memory initInstr = getInitInstr(_instructions);

        // Fill array1 and array2
        for (uint256 i = 0; i < 50; ) {
            for (uint256 j = 0; j < 105; ) {
                if (initInstr.nCol > 0 && j % initInstr.nCol == 0) {
                    _array1[i][j] = initInstr.sym1;
                } else {
                    _array1[i][j] = " ";
                }
                if (initInstr.mCol > 0 && j % initInstr.mCol == 0) {
                    _array2[i][j] = initInstr.sym2;
                } else {
                    _array2[i][j] = " ";
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2, initInstr.title);
    }

    /* ------------------------------- LINE ------------------------------- */

    function line(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ShapeInstructions memory lineInstr = getShapeInstr(_instructions);

        require(
            lineInstr.nC != 0 || lineInstr.nR != 0,
            "Invalid line: nC and NR cannot be zero."
        );

        uint16 maxRows = uint16(_array1.length);
        uint16 maxCols = uint16(_array1[0].length);

        // Draw the base line
        drawLine(_array1, _array2, lineInstr, lineInstr.arr, maxRows, maxCols);

        // Draw repeated lines
        for (uint256 i = 0; i < lineInstr.repeatRows.length; ) {
            ShapeInstructions memory repeatedLineInstr = lineInstr;
            // override row / col vals with repeat vals
            repeatedLineInstr.row = lineInstr.repeatRows[i];
            repeatedLineInstr.col = lineInstr.repeatCols[i];

            drawLine(
                _array1,
                _array2,
                repeatedLineInstr,
                lineInstr.arr,
                maxRows,
                maxCols
            );
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawLine(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        ShapeInstructions memory instr,
        uint8 arr,
        uint16 maxRows,
        uint16 maxCols
    ) internal pure {
        if (instr.nR == 1 && instr.nC > 0) {
            if (arr == 1) {
                drawHorizontalLine(
                    _array1,
                    instr.row,
                    instr.col,
                    instr.nC,
                    instr.sym
                );
            } else {
                drawHorizontalLine(
                    _array2,
                    instr.row,
                    instr.col,
                    instr.nC,
                    instr.sym
                );
            }
        } else if (instr.nC == 1 && instr.nR > 0) {
            if (arr == 1) {
                drawVerticalLine(
                    _array1,
                    instr.row,
                    instr.col,
                    instr.nR,
                    instr.sym
                );
            } else {
                drawVerticalLine(
                    _array2,
                    instr.row,
                    instr.col,
                    instr.nR,
                    instr.sym
                );
            }
        } else {
            if (arr == 1) {
                drawDiagonalLine(_array1, instr, maxRows, maxCols);
            } else {
                drawDiagonalLine(_array2, instr, maxRows, maxCols);
            }
        }
    }

    function drawHorizontalLine(
        bytes1[][] memory _array,
        int16 row,
        int16 col,
        int16 nC,
        bytes1 sym
    ) public pure {
        uint16 maxRows = uint16(_array.length);
        uint16 maxCols = uint16(_array[0].length);

        for (int16 i = 0; i < nC; ) {
            int16 newCol = col + i;
            if (
                row >= 0 &&
                newCol >= 0 &&
                uint16(row) < maxRows &&
                uint16(newCol) < maxCols
            ) {
                _array[uint16(row)][uint16(newCol)] = sym;
            }
            unchecked {
                ++i;
            }
        }
    }

    function drawVerticalLine(
        bytes1[][] memory _array,
        int16 row,
        int16 col,
        int16 nR,
        bytes1 sym
    ) internal pure {
        uint16 maxRows = uint16(_array.length);
        uint16 maxCols = uint16(_array[0].length);

        for (int16 i = 0; i < nR; ) {
            int16 newRow = row + i;
            if (
                newRow >= 0 &&
                col >= 0 &&
                uint16(newRow) < maxRows &&
                uint16(col) < maxCols
            ) {
                _array[uint16(newRow)][uint16(col)] = sym;
            }
            unchecked {
                ++i;
            }
        }
    }

    function drawDiagonalLine(
        bytes1[][] memory _array,
        ShapeInstructions memory lineInstr,
        uint16 maxRows,
        uint16 maxCols
    ) internal pure {
        // Define vars for Bresenham's line algorithm
        (int16 sx, int16 sy) = (
            lineInstr.col < lineInstr.col + lineInstr.nC ? int16(1) : int16(-1),
            lineInstr.row < lineInstr.row + lineInstr.nR ? int16(1) : int16(-1)
        );

        int16 err = (
            lineInstr.nC > lineInstr.nR ? lineInstr.nC : -lineInstr.nR
        ) / 2;

        int16 e2;

        int16 finalCol = int16(lineInstr.col) + int16(lineInstr.nC);
        int16 finalRow = int16(lineInstr.row) + int16(lineInstr.nR);

        // Execute Bresenham's line algorithm
        while (true) {
            if (
                uint16(lineInstr.row) < maxRows &&
                uint16(lineInstr.col) < maxCols
            ) {
                _array[uint16(lineInstr.row)][uint16(lineInstr.col)] = lineInstr
                    .sym;
            }

            if (lineInstr.col == finalCol && lineInstr.row == finalRow) {
                break;
            }

            e2 = err;

            if (e2 > -lineInstr.nC) {
                err += (lineInstr.nR > 0 && err >= -lineInstr.nR)
                    ? -lineInstr.nR
                    : lineInstr.nR;
                lineInstr.col += sx;
            }

            if (e2 < lineInstr.nR) {
                err += (lineInstr.nC > 0 && err <= lineInstr.nC)
                    ? lineInstr.nC
                    : -lineInstr.nC;
                lineInstr.row += sy;
            }
        }
    }

    /* -------------------------- SOLID RECTANGLE -------------------------- */

    function solidRect(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ShapeInstructions memory rectInstr = getShapeInstr(_instructions);

        require(
            rectInstr.nC != 0 || rectInstr.nR != 0,
            "Invalid solid rectangle: nC and nR cannot be zero."
        );
        require(
            int16(rectInstr.row) >= 0,
            "Invalid solid rectangle: row must be greater than zero."
        );
        require(
            int16(rectInstr.col) >= 0,
            "Invalid solid rectangle: col must be greater than zero."
        );

        // Draw the base rectangle
        if (rectInstr.arr == 1) {
            drawSolidRect(_array1, rectInstr.row, rectInstr.col, rectInstr);
        } else {
            drawSolidRect(_array2, rectInstr.row, rectInstr.col, rectInstr);
        }

        // Draw repeated rectangles
        for (uint256 i = 0; i < rectInstr.repeatRows.length; ) {
            if (rectInstr.arr == 1) {
                drawSolidRect(
                    _array1,
                    rectInstr.repeatRows[i],
                    rectInstr.repeatCols[i],
                    rectInstr
                );
            } else {
                drawSolidRect(
                    _array2,
                    rectInstr.repeatRows[i],
                    rectInstr.repeatCols[i],
                    rectInstr
                );
            }
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawSolidRect(
        bytes1[][] memory _arr,
        int16 _row,
        int16 _col,
        ShapeInstructions memory rectInstr
    ) internal pure {
        for (int16 i = 0; i < rectInstr.nR; ) {
            int16 newRow = _row + i;
            drawHorizontalLine(_arr, newRow, _col, rectInstr.nC, rectInstr.sym);
            unchecked {
                ++i;
            }
        }
    }

    /* --------------------------- OPEN RECTANGLE -------------------------- */

    function openRect(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ShapeInstructions memory rectInstr = getShapeInstr(_instructions);

        require(
            rectInstr.nC != 0 || rectInstr.nR != 0,
            "Invalid open rectangle: nC and nR cannot be zero."
        );
        require(
            int16(rectInstr.row) >= 0,
            "Invalid open rectangle: row must be greater than zero."
        );
        require(
            int16(rectInstr.col) >= 0,
            "Invalid open rectangle: col must be greater than zero."
        );

        // Draw the base rectangle
        if (rectInstr.arr == 1) {
            drawOpenRect(_array1, rectInstr.row, rectInstr.col, rectInstr);
        } else {
            drawOpenRect(_array2, rectInstr.row, rectInstr.col, rectInstr);
        }

        // Draw repeated rectangles
        uint256 repeatRowsLength = rectInstr.repeatRows.length;
        for (uint256 i = 0; i < repeatRowsLength; ) {
            if (rectInstr.arr == 1) {
                drawOpenRect(
                    _array1,
                    rectInstr.repeatRows[i],
                    rectInstr.repeatCols[i],
                    rectInstr
                );
            } else {
                drawOpenRect(
                    _array2,
                    rectInstr.repeatRows[i],
                    rectInstr.repeatCols[i],
                    rectInstr
                );
            }
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawOpenRect(
        bytes1[][] memory _arr,
        int16 _row,
        int16 _col,
        ShapeInstructions memory rectInstr
    ) internal pure {
        // Draw top and bottom horizontal lines
        for (int16 i = 0; i < rectInstr.nC; ) {
            int16 newCol = _col + i;
            if (_row >= 0) {
                drawHorizontalLine(_arr, _row, newCol, 1, rectInstr.sym);
            }
            if (_row + rectInstr.nR - 1 >= 0) {
                drawHorizontalLine(
                    _arr,
                    _row + rectInstr.nR - 1,
                    newCol,
                    1,
                    rectInstr.sym
                );
            }
            unchecked {
                ++i;
            }
        }

        // Draw left and right vertical lines
        for (int16 i = 1; i < rectInstr.nR - 1; ) {
            int16 newRow = _row + i;
            if (_col >= 0) {
                drawVerticalLine(_arr, newRow, _col, 1, rectInstr.sym);
            }
            if (_col + rectInstr.nC - 1 >= 0) {
                drawVerticalLine(
                    _arr,
                    newRow,
                    _col + rectInstr.nC - 1,
                    1,
                    rectInstr.sym
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    /* ------------------------------ TRIANGLE ----------------------------- */

    function triangle(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ShapeInstructions memory triInstr = getShapeInstr(_instructions);

        require(
            (triInstr.nR == 0 && triInstr.nC != 0) ||
                (triInstr.nR != 0 && triInstr.nC == 0),
            "Invalid triangle: either nR or nC must be zero."
        );
        require(
            int16(triInstr.row) >= 0,
            "Invalid triangle: row must be greater than zero."
        );
        require(
            int16(triInstr.col) >= 0,
            "Invalid triangle: col must be greater than zero."
        );

        // Draw the base triangle
        if (triInstr.arr == 1) {
            drawTriangle(
                _array1,
                triInstr.row,
                triInstr.col,
                triInstr.nR,
                triInstr.nC,
                triInstr.sym
            );
        } else {
            drawTriangle(
                _array2,
                triInstr.row,
                triInstr.col,
                triInstr.nR,
                triInstr.nC,
                triInstr.sym
            );
        }

        // Draw repeated triangles
        uint256 repeatRowsLength = triInstr.repeatRows.length;
        for (uint256 i = 0; i < repeatRowsLength; ) {
            if (triInstr.arr == 1) {
                drawTriangle(
                    _array1,
                    triInstr.repeatRows[i],
                    triInstr.repeatCols[i],
                    triInstr.nR,
                    triInstr.nC,
                    triInstr.sym
                );
            } else {
                drawTriangle(
                    _array2,
                    triInstr.repeatRows[i],
                    triInstr.repeatCols[i],
                    triInstr.nR,
                    triInstr.nC,
                    triInstr.sym
                );
            }
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    function drawTriangle(
        bytes1[][] memory _array,
        int16 _row,
        int16 _col,
        int16 _nR,
        int16 _nC,
        bytes1 _sym
    ) internal pure {
        int16 absNR = _nR > 0 ? _nR : -_nR;
        int16 absNC = _nC > 0 ? _nC : -_nC;
        int16 arrayWidth = int16(uint16(_array[0].length));
        int16 arrayHeight = int16(uint16(_array.length));

        if (_nR != 0) {
            for (int16 i = 0; i < absNR; i++) {
                for (int16 j = -i; j <= i; ) {
                    int16 x = _col + j;
                    int16 y = _row + (_nR > 0 ? i : -i);
                    if (x >= 0 && y >= 0 && x < arrayWidth && y < arrayHeight) {
                        _array[uint16(y)][uint16(x)] = _sym;
                    }
                    unchecked {
                        ++j;
                    }
                }
            }
        } else if (_nC != 0) {
            for (int16 i = 0; i < absNC; i++) {
                for (int16 j = -i; j <= i; ) {
                    int16 x = _col + (_nC > 0 ? i : -i);
                    int16 y = _row + j;
                    if (x >= 0 && y >= 0 && x < arrayWidth && y < arrayHeight) {
                        _array[uint16(y)][uint16(x)] = _sym;
                    }
                    unchecked {
                        ++j;
                    }
                }
            }
        }
    }

    /* ------------------------------- ELLIPSE ----------------------------- */

    function ellipse(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        bytes memory _instructions
    ) internal pure returns (bytes1[][] memory, bytes1[][] memory) {
        ShapeInstructions memory ellipseInstr = getShapeInstr(_instructions);

        require(
            ellipseInstr.row >= 0 &&
                ellipseInstr.col >= 0 &&
                ellipseInstr.nR >= 0 &&
                ellipseInstr.nC >= 0,
            "Invalid ellipse: row, col, nR and nC cannot be negative."
        );

        // Draw the base ellipse
        if (ellipseInstr.arr == 1) {
            drawEllipse(
                _array1,
                ellipseInstr.sym,
                ellipseInstr.row,
                ellipseInstr.col,
                ellipseInstr.nR,
                ellipseInstr.nC
            );
        } else {
            drawEllipse(
                _array2,
                ellipseInstr.sym,
                ellipseInstr.row,
                ellipseInstr.col,
                ellipseInstr.nR,
                ellipseInstr.nC
            );
        }

        // Draw repeated ellipses
        uint256 repeatRowsLength = ellipseInstr.repeatRows.length;
        for (uint256 i = 0; i < repeatRowsLength; ) {
            if (ellipseInstr.arr == 1) {
                drawEllipse(
                    _array1,
                    ellipseInstr.sym,
                    ellipseInstr.repeatRows[i],
                    ellipseInstr.repeatCols[i],
                    ellipseInstr.nR,
                    ellipseInstr.nC
                );
            } else {
                drawEllipse(
                    _array2,
                    ellipseInstr.sym,
                    ellipseInstr.repeatRows[i],
                    ellipseInstr.repeatCols[i],
                    ellipseInstr.nR,
                    ellipseInstr.nC
                );
            }
            unchecked {
                ++i;
            }
        }

        return (_array1, _array2);
    }

    /**
     * @dev Draws an ellipse on a 2D array using the provided symbol. The
     * ellipse is defined by its center point (row, col) and the lengths of its
     * semi-major and semi-minor axes (nR, nC).
     *
     * @param _array The 2D array on which to draw the ellipse.
     * @param _sym The symbol (byte) used to draw the ellipse.
     * @param _row The row index of the center of the ellipse.
     * @param _col The column index of the center of the ellipse.
     * @param _nR The length of the semi-major axis of the ellipse.
     * @param _nC The length of the semi-minor axis of the ellipse.
     *
     * Requirements:
     * - The center point of the ellipse and the lengths of its axes must be
     *   non-negative.
     */
    function drawEllipse(
        bytes1[][] memory _array,
        bytes1 _sym,
        int16 _row,
        int16 _col,
        int16 _nR,
        int16 _nC
    ) internal pure {
        // Convert all to int16 for calculation
        int16 height = _nR * 2 + 1;
        int16 width = _nC * 2 + 1;

        // Adjustment factor based on average radius and eccentricity (scaled)
        int16 adjustment = ((height + width) / 10) +
            ((abs(height - width) * 50) / ((height + width) * 100));

        for (int16 i = -_nR; i <= _nR; i++) {
            // Calculate the number of characters to print on this line
            int16 nChars;
            if (i != 0) {
                nChars = getEllipseRowLength(i, _nR, _nC);
                if (i == -_nR || i == _nR) {
                    nChars += adjustment;
                }
            } else {
                nChars = 2 * _nC + 1;
            }

            // Adjustment first and last rows
            if (i == -_nR || i == _nR) {
                nChars += 2;
            }

            // Calculate the start and end columns for row
            int16 startCol = _col - nChars / 2;
            int16 endCol = startCol + nChars;

            // Draw row
            for (int16 j = startCol; j < endCol; j++) {
                if (j >= 0 && j < 105 && _row + i >= 0 && _row + i < 50) {
                    _array[uint256(int256(_row + i))][
                        uint256(int256(j))
                    ] = _sym;
                }
            }
        }
    }

    /**
     * @dev Returns the y-coordinate (row) of a point on the edge of an ellipse.
     * The ellipse is defined by its semi-major and semi-minor axes (maxRow and
     * maxCol).
     *
     * @param rowIndex The x-coordinate (column) for which we want to calculate
     * the y-coordinate.
     * @param maxRow The semi-major axis of the ellipse.
     * @param maxCol The semi-minor axis of the ellipse.
     *
     * @return int16 The y-coordinate (row) of the point on the edge of the
     * ellipse for the given x-coordinate.
     */
    function getEllipseRowLength(
        int16 rowIndex,
        int16 maxRow,
        int16 maxCol
    ) internal pure returns (int16) {
        int128 rowIndexSquared = ABDKMath64x64.mul(
            ABDKMath64x64.fromInt(rowIndex),
            ABDKMath64x64.fromInt(rowIndex)
        );
        int128 maxRowSquared = ABDKMath64x64.mul(
            ABDKMath64x64.fromInt(maxRow),
            ABDKMath64x64.fromInt(maxRow)
        );
        int128 rowIndexSquaredOverMaxRowSquared = ABDKMath64x64.div(
            rowIndexSquared,
            maxRowSquared
        );
        int128 oneMinusRowIndexSquaredOverMaxRowSquared = ABDKMath64x64.sub(
            ABDKMath64x64.fromInt(1),
            rowIndexSquaredOverMaxRowSquared
        );
        int128 maxColSquared = ABDKMath64x64.mul(
            ABDKMath64x64.fromInt(maxCol),
            ABDKMath64x64.fromInt(maxCol)
        );
        return
            int16(
                ABDKMath64x64.toInt(
                    ABDKMath64x64.sqrt(
                        ABDKMath64x64.mul(
                            oneMinusRowIndexSquaredOverMaxRowSquared,
                            maxColSquared
                        )
                    )
                ) *
                    2 +
                    1
            );
    }

    /* -------------------------------- PRINT ------------------------------ */

    function print(
        bytes1[][] memory _array1,
        bytes1[][] memory _array2,
        string memory _title,
        string memory _color,
        string memory _bgColor
    ) internal pure returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                // solhint-disable-next-line
                '<svg width="1096" height="811" viewBox="0 0 1096 811" xmlns="http://www.w3.org/2000/svg">',
                // solhint-disable-next-line
                '<style>.t{font:12px "Source Code Pro",monospace;text-anchor:middle;fill:',
                _color,
                // solhint-disable-next-line
                '</style><rect x="0" y="0" width="1096" height="811" style="fill:',
                _bgColor,
                '" />'
            )
        );

        string memory row1Content;
        string memory row2Content;
        string memory svgRow1;
        string memory svgRow2;
        uint yPos = 112;

        // Iterate through the arrays to create the SVG text elements
        for (uint i = 0; i < 50; i++) {
            row1Content = "";
            row2Content = "";
            for (uint j = 0; j < 105; j++) {
                row1Content = string(
                    abi.encodePacked(row1Content, _array1[i][j])
                );
                row2Content = string(
                    abi.encodePacked(row2Content, _array2[i][j])
                );
            }

            // Add sym1 row to the SVG content
            svgRow1 = string(
                abi.encodePacked(
                    '<text class="t" x="50%" y="',
                    uintToString(yPos),
                    '" xml:space="preserve">',
                    row1Content,
                    "</text>"
                )
            );
            svg = string(abi.encodePacked(svg, svgRow1));

            // Add sym2 row to the SVG content
            svgRow2 = string(
                abi.encodePacked(
                    '<text class="t" x="50%" y="',
                    uintToString(yPos),
                    '" xml:space="preserve">',
                    row2Content,
                    "</text>"
                )
            );
            svg = string(abi.encodePacked(svg, svgRow2));

            // Add the title to the last row of the SVG
            if (i == 49) {
                svg = string(
                    abi.encodePacked(
                        svg,
                        '<text class="t" x="50%" y="',
                        uintToString(yPos + 36),
                        '" xml:space="preserve">',
                        _title,
                        "</text>"
                    )
                );
            }

            yPos += 12; // Increment yPos by the height of each row
        }

        return Base64.encode(bytes(string(abi.encodePacked(svg, "</svg>"))));
    }

    /* --------------------------------------------------------------------- */
    /*                               PARSING                                 */
    /* --------------------------------------------------------------------- */

    function getInitInstr(
        bytes memory _instructions
    ) public pure returns (InitInstructions memory parsed) {
        // Skip "sym1" and a whitespace
        uint256 currentIndex = 5;
        // Get sym1
        parsed.sym1 = _instructions[currentIndex++];
        // Skip a whitespace, "nCol" character and a white space
        currentIndex += 6;
        // Get nCol
        uint256 n = 0;
        while (
            currentIndex < _instructions.length &&
            uint8(_instructions[currentIndex]) >= 48 &&
            uint8(_instructions[currentIndex]) <= 57
        ) {
            n = n * 10 + uint256(uint8(_instructions[currentIndex]) - 48);
            currentIndex++;
        }
        parsed.nCol = n;
        // Skip a whitespace, "sym2" and a whitspace
        currentIndex += 6;
        // Get sym2
        parsed.sym2 = _instructions[currentIndex++];
        // Skip a whitespace, "mCol" and a whitespace
        currentIndex += 6;
        // Get mCol
        uint256 m = 0;
        while (
            currentIndex < _instructions.length &&
            uint8(_instructions[currentIndex]) >= 48 &&
            uint8(_instructions[currentIndex]) <= 57
        ) {
            m = m * 10 + uint256(uint8(_instructions[currentIndex]) - 48);
            currentIndex++;
        }
        parsed.mCol = m;
        // Skip a whitespace, "title" and a whitespace
        currentIndex += 7;
        // Initialize an empty bytes array for the title
        bytes memory title = new bytes(_instructions.length - currentIndex);

        // Loop through the remaining characters and append them to the title
        uint256 titleIndex = 0;
        while (currentIndex < _instructions.length) {
            title[titleIndex++] = _instructions[currentIndex++];
        }

        // Set the title in the parsed struct
        parsed.title = string(title);

        return parsed;
    }

    function getShapeInstr(
        bytes memory _instructions
    ) public pure returns (ShapeInstructions memory shapeInstr) {
        // Get base shape attrs and store on shapeInstr
        uint256 currentIndex = getBaseShape(_instructions, shapeInstr);

        // Count number of repeat rows and cols
        (uint256 repeatRowCount, uint256 repeatColCount) = getRepeatCounts(
            _instructions,
            currentIndex
        );

        // Get repeat coords and store on shapeInstr
        getRepeatCoords(
            _instructions,
            currentIndex,
            repeatRowCount,
            repeatColCount,
            shapeInstr
        );

        return shapeInstr;
    }

    function getBaseShape(
        bytes memory _instructions,
        ShapeInstructions memory shapeInstr
    ) internal pure returns (uint256 currentIndex) {
        // skip shade id, a whitespace, "sym" and a whitespace
        currentIndex = 6;

        // Get sym
        shapeInstr.sym = _instructions[currentIndex];

        // Skip a whitespace, "arr" and  whitespace
        currentIndex += 6;

        // Get arr
        shapeInstr.arr = uint8(_instructions[currentIndex++]) - 48;

        // Parsing loop for row, col, nR, and nC values
        for (uint8 i = 0; i < 4; ) {
            // Skip index based on key lengths
            currentIndex += (i == 0 || i == 1) ? 5 : 4;

            // Parse the value using parseInt16 function
            (int16 parsedValue, uint256 nextIndex) = parseInt16(
                _instructions,
                currentIndex
            );
            currentIndex = nextIndex;

            // Assign the parsed value to the corresponding field
            if (i == 0) {
                shapeInstr.row = parsedValue;
            } else if (i == 1) {
                shapeInstr.col = parsedValue;
            } else if (i == 2) {
                shapeInstr.nR = parsedValue;
            } else {
                shapeInstr.nC = parsedValue;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getRepeatCounts(
        bytes memory _instructions,
        uint256 currentIndex
    ) internal pure returns (uint256 repeatRowCount, uint256 repeatColCount) {
        // Loop through _instructions and count number of repeat rows and cols
        for (uint256 i = currentIndex; i < _instructions.length; ) {
            if (_instructions[i] == "r") {
                repeatRowCount++;
            } else if (_instructions[i] == "c") {
                repeatColCount++;
            }

            unchecked {
                ++i;
            }
        }
    }

    function getRepeatCoords(
        bytes memory _instructions,
        uint256 currentIndex,
        uint256 repeatRowCount,
        uint256 repeatColCount,
        ShapeInstructions memory shapeInstr
    ) internal pure {
        shapeInstr.repeatRows = new int16[](repeatRowCount);
        shapeInstr.repeatCols = new int16[](repeatColCount);

        repeatRowCount = 0;
        repeatColCount = 0;

        uint256 startIndex;

        while (currentIndex < _instructions.length) {
            currentIndex += 4;
            startIndex = currentIndex - 3; // whitespace, 1 and "r"

            if (currentIndex < _instructions.length) {
                (int16 parsedValue, uint256 nextIndex) = parseInt16(
                    _instructions,
                    currentIndex
                );

                currentIndex = nextIndex;

                if (uint8(_instructions[startIndex]) == 114) {
                    shapeInstr.repeatRows[repeatRowCount] = parsedValue;
                    repeatRowCount += 1;
                } else {
                    shapeInstr.repeatCols[repeatColCount] = parsedValue;
                    repeatColCount += 1;
                }
            }
        }
    }

    /* ---------------------------- PARSING UTILS -------------------------- */

    function parseInt16(
        bytes memory _instructions,
        uint256 start
    ) internal pure returns (int16, uint256) {
        int16 n = 0;
        bool isNegative = false;

        if (_instructions[start] == bytes1("-")) {
            isNegative = true;
            start++;
        }

        while (
            start < _instructions.length &&
            uint8(_instructions[start]) >= 48 &&
            uint8(_instructions[start]) <= 57
        ) {
            uint8 currentChar = uint8(_instructions[start]);

            n = n * 10 + int16(int256(uint256(currentChar) - 48));
            start++;
        }

        if (isNegative) {
            n = -n;
        }

        return (n, start);
    }

    /* --------------------------------------------------------------------- */
    /*                                UTILS                                  */
    /* --------------------------------------------------------------------- */

    function noInstructions(
        bytes[11] memory _data
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < 11; ) {
            if (bytes1(_data[i]) != 0x00) {
                return false;
            }

            unchecked {
                ++i;
            }
        }
        return true;
    }

    function uintToString(
        uint256 _value
    ) internal pure returns (string memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function intToString(int256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        bool isNegative = _i < 0;
        uint256 absValue = uint256(isNegative ? -_i : _i);
        string memory uintStr = uintToString(absValue);
        if (!isNegative) {
            return uintStr;
        }
        return string(abi.encodePacked("-", uintStr));
    }

    function abs(int16 a) internal pure returns (int16) {
        return a >= 0 ? a : -a;
    }
}