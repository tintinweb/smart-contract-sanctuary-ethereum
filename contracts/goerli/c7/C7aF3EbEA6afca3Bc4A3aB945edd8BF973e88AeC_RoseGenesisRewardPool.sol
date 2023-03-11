/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
     function fromInt(int256 x) internal pure returns (int128) {
         unchecked {
             require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
             return int128(x << 64);
         }
     }
 
     /**
      * Convert signed 64.64 fixed point number into signed 64-bit integer number
      * rounding down.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64-bit integer number
      */
     function toInt(int128 x) internal pure returns (int64) {
         unchecked {
             return int64(x >> 64);
         }
     }
 
     /**
      * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
      * number.  Revert on overflow.
      *
      * @param x unsigned 256-bit integer number
      * @return signed 64.64-bit fixed point number
      */
     function fromUInt(uint256 x) internal pure returns (int128) {
         unchecked {
             require(x <= 0x7FFFFFFFFFFFFFFF);
             return int128(int256(x << 64));
         }
     }
 
     /**
      * Convert signed 64.64 fixed point number into unsigned 64-bit integer
      * number rounding down.  Revert on underflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @return unsigned 64-bit integer number
      */
     function toUInt(int128 x) internal pure returns (uint64) {
         unchecked {
             require(x >= 0);
             return uint64(uint128(x >> 64));
         }
     }
 
     /**
      * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
      * number rounding down.  Revert on overflow.
      *
      * @param x signed 128.128-bin fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function from128x128(int256 x) internal pure returns (int128) {
         unchecked {
             int256 result = x >> 64;
             require(result >= MIN_64x64 && result <= MAX_64x64);
             return int128(result);
         }
     }
 
     /**
      * Convert signed 64.64 fixed point number into signed 128.128 fixed point
      * number.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 128.128 fixed point number
      */
     function to128x128(int128 x) internal pure returns (int256) {
         unchecked {
             return int256(x) << 64;
         }
     }
 
     /**
      * Calculate x + y.  Revert on overflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @param y signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function add(int128 x, int128 y) internal pure returns (int128) {
         unchecked {
             int256 result = int256(x) + y;
             require(result >= MIN_64x64 && result <= MAX_64x64);
             return int128(result);
         }
     }
 
     /**
      * Calculate x - y.  Revert on overflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @param y signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function sub(int128 x, int128 y) internal pure returns (int128) {
         unchecked {
             int256 result = int256(x) - y;
             require(result >= MIN_64x64 && result <= MAX_64x64);
             return int128(result);
         }
     }
 
     /**
      * Calculate x * y rounding down.  Revert on overflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @param y signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function mul(int128 x, int128 y) internal pure returns (int128) {
         unchecked {
             int256 result = (int256(x) * y) >> 64;
             require(result >= MIN_64x64 && result <= MAX_64x64);
             return int128(result);
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
     function muli(int128 x, int256 y) internal pure returns (int256) {
         unchecked {
             if (x == MIN_64x64) {
                 require(
                     y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                         y <= 0x1000000000000000000000000000000000000000000000000
                 );
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
                 uint256 absoluteResult = mulu(x, uint256(y));
                 if (negativeResult) {
                     require(
                         absoluteResult <=
                             0x8000000000000000000000000000000000000000000000000000000000000000
                     );
                     return -int256(absoluteResult); // We rely on overflow behavior here
                 } else {
                     require(
                         absoluteResult <=
                             0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                     );
                     return int256(absoluteResult);
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
     function mulu(int128 x, uint256 y) internal pure returns (uint256) {
         unchecked {
             if (y == 0) return 0;
 
             require(x >= 0);
 
             uint256 lo = (uint256(int256(x)) *
                 (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
             uint256 hi = uint256(int256(x)) * (y >> 128);
 
             require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
             hi <<= 64;
 
             require(
                 hi <=
                     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF -
                         lo
             );
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
     function div(int128 x, int128 y) internal pure returns (int128) {
         unchecked {
             require(y != 0);
             int256 result = (int256(x) << 64) / y;
             require(result >= MIN_64x64 && result <= MAX_64x64);
             return int128(result);
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
     function divi(int256 x, int256 y) internal pure returns (int128) {
         unchecked {
             require(y != 0);
 
             bool negativeResult = false;
             if (x < 0) {
                 x = -x; // We rely on overflow behavior here
                 negativeResult = true;
             }
             if (y < 0) {
                 y = -y; // We rely on overflow behavior here
                 negativeResult = !negativeResult;
             }
             uint128 absoluteResult = divuu(uint256(x), uint256(y));
             if (negativeResult) {
                 require(absoluteResult <= 0x80000000000000000000000000000000);
                 return -int128(absoluteResult); // We rely on overflow behavior here
             } else {
                 require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                 return int128(absoluteResult); // We rely on overflow behavior here
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
     function divu(uint256 x, uint256 y) internal pure returns (int128) {
         unchecked {
             require(y != 0);
             uint128 result = divuu(x, y);
             require(result <= uint128(MAX_64x64));
             return int128(result);
         }
     }
 
     /**
      * Calculate -x.  Revert on overflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function neg(int128 x) internal pure returns (int128) {
         unchecked {
             require(x != MIN_64x64);
             return -x;
         }
     }
 
     /**
      * Calculate |x|.  Revert on overflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function abs(int128 x) internal pure returns (int128) {
         unchecked {
             require(x != MIN_64x64);
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
     function inv(int128 x) internal pure returns (int128) {
         unchecked {
             require(x != 0);
             int256 result = int256(0x100000000000000000000000000000000) / x;
             require(result >= MIN_64x64 && result <= MAX_64x64);
             return int128(result);
         }
     }
 
     /**
      * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
      *
      * @param x signed 64.64-bit fixed point number
      * @param y signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function avg(int128 x, int128 y) internal pure returns (int128) {
         unchecked {
             return int128((int256(x) + int256(y)) >> 1);
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
     function gavg(int128 x, int128 y) internal pure returns (int128) {
         unchecked {
             int256 m = int256(x) * int256(y);
             require(m >= 0);
             require(
                 m <
                     0x4000000000000000000000000000000000000000000000000000000000000000
             );
             return int128(sqrtu(uint256(m)));
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
     function pow(int128 x, uint256 y) internal pure returns (int128) {
         unchecked {
             bool negative = x < 0 && y & 1 == 1;
 
             uint256 absX = uint128(x < 0 ? -x : x);
             uint256 absResult;
             absResult = 0x100000000000000000000000000000000;
 
             if (absX <= 0x10000000000000000) {
                 absX <<= 63;
                 while (y != 0) {
                     if (y & 0x1 != 0) {
                         absResult = (absResult * absX) >> 127;
                     }
                     absX = (absX * absX) >> 127;
 
                     if (y & 0x2 != 0) {
                         absResult = (absResult * absX) >> 127;
                     }
                     absX = (absX * absX) >> 127;
 
                     if (y & 0x4 != 0) {
                         absResult = (absResult * absX) >> 127;
                     }
                     absX = (absX * absX) >> 127;
 
                     if (y & 0x8 != 0) {
                         absResult = (absResult * absX) >> 127;
                     }
                     absX = (absX * absX) >> 127;
 
                     y >>= 4;
                 }
 
                 absResult >>= 64;
             } else {
                 uint256 absXShift = 63;
                 if (absX < 0x1000000000000000000000000) {
                     absX <<= 32;
                     absXShift -= 32;
                 }
                 if (absX < 0x10000000000000000000000000000) {
                     absX <<= 16;
                     absXShift -= 16;
                 }
                 if (absX < 0x1000000000000000000000000000000) {
                     absX <<= 8;
                     absXShift -= 8;
                 }
                 if (absX < 0x10000000000000000000000000000000) {
                     absX <<= 4;
                     absXShift -= 4;
                 }
                 if (absX < 0x40000000000000000000000000000000) {
                     absX <<= 2;
                     absXShift -= 2;
                 }
                 if (absX < 0x80000000000000000000000000000000) {
                     absX <<= 1;
                     absXShift -= 1;
                 }
 
                 uint256 resultShift = 0;
                 while (y != 0) {
                     require(absXShift < 64);
 
                     if (y & 0x1 != 0) {
                         absResult = (absResult * absX) >> 127;
                         resultShift += absXShift;
                         if (absResult > 0x100000000000000000000000000000000) {
                             absResult >>= 1;
                             resultShift += 1;
                         }
                     }
                     absX = (absX * absX) >> 127;
                     absXShift <<= 1;
                     if (absX >= 0x100000000000000000000000000000000) {
                         absX >>= 1;
                         absXShift += 1;
                     }
 
                     y >>= 1;
                 }
 
                 require(resultShift < 64);
                 absResult >>= 64 - resultShift;
             }
             int256 result = negative ? -int256(absResult) : int256(absResult);
             require(result >= MIN_64x64 && result <= MAX_64x64);
             return int128(result);
         }
     }
 
     /**
      * Calculate sqrt (x) rounding down.  Revert if x < 0.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function sqrt(int128 x) internal pure returns (int128) {
         unchecked {
             require(x >= 0);
             return int128(sqrtu(uint256(int256(x)) << 64));
         }
     }
 
     /**
      * Calculate binary logarithm of x.  Revert if x <= 0.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function log_2(int128 x) internal pure returns (int128) {
         unchecked {
             require(x > 0);
 
             int256 msb = 0;
             int256 xc = x;
             if (xc >= 0x10000000000000000) {
                 xc >>= 64;
                 msb += 64;
             }
             if (xc >= 0x100000000) {
                 xc >>= 32;
                 msb += 32;
             }
             if (xc >= 0x10000) {
                 xc >>= 16;
                 msb += 16;
             }
             if (xc >= 0x100) {
                 xc >>= 8;
                 msb += 8;
             }
             if (xc >= 0x10) {
                 xc >>= 4;
                 msb += 4;
             }
             if (xc >= 0x4) {
                 xc >>= 2;
                 msb += 2;
             }
             if (xc >= 0x2) msb += 1; // No need to shift xc anymore
 
             int256 result = (msb - 64) << 64;
             uint256 ux = uint256(int256(x)) << uint256(127 - msb);
             for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                 ux *= ux;
                 uint256 b = ux >> 255;
                 ux >>= 127 + b;
                 result += bit * int256(b);
             }
 
             return int128(result);
         }
     }
 
     /**
      * Calculate natural logarithm of x.  Revert if x <= 0.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function ln(int128 x) internal pure returns (int128) {
         unchecked {
             require(x > 0);
 
             return
                 int128(
                     int256(
                         (uint256(int256(log_2(x))) *
                             0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                     )
                 );
         }
     }
 
     /**
      * Calculate binary exponent of x.  Revert on overflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function exp_2(int128 x) internal pure returns (int128) {
         unchecked {
             require(x < 0x400000000000000000); // Overflow
 
             if (x < -0x400000000000000000) return 0; // Underflow
 
             uint256 result = 0x80000000000000000000000000000000;
 
             if (x & 0x8000000000000000 > 0)
                 result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
             if (x & 0x4000000000000000 > 0)
                 result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
             if (x & 0x2000000000000000 > 0)
                 result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
             if (x & 0x1000000000000000 > 0)
                 result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
             if (x & 0x800000000000000 > 0)
                 result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
             if (x & 0x400000000000000 > 0)
                 result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
             if (x & 0x200000000000000 > 0)
                 result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
             if (x & 0x100000000000000 > 0)
                 result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
             if (x & 0x80000000000000 > 0)
                 result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
             if (x & 0x40000000000000 > 0)
                 result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
             if (x & 0x20000000000000 > 0)
                 result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
             if (x & 0x10000000000000 > 0)
                 result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
             if (x & 0x8000000000000 > 0)
                 result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
             if (x & 0x4000000000000 > 0)
                 result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
             if (x & 0x2000000000000 > 0)
                 result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
             if (x & 0x1000000000000 > 0)
                 result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
             if (x & 0x800000000000 > 0)
                 result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
             if (x & 0x400000000000 > 0)
                 result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
             if (x & 0x200000000000 > 0)
                 result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
             if (x & 0x100000000000 > 0)
                 result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
             if (x & 0x80000000000 > 0)
                 result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
             if (x & 0x40000000000 > 0)
                 result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
             if (x & 0x20000000000 > 0)
                 result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
             if (x & 0x10000000000 > 0)
                 result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
             if (x & 0x8000000000 > 0)
                 result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
             if (x & 0x4000000000 > 0)
                 result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
             if (x & 0x2000000000 > 0)
                 result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
             if (x & 0x1000000000 > 0)
                 result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
             if (x & 0x800000000 > 0)
                 result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
             if (x & 0x400000000 > 0)
                 result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
             if (x & 0x200000000 > 0)
                 result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
             if (x & 0x100000000 > 0)
                 result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
             if (x & 0x80000000 > 0)
                 result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
             if (x & 0x40000000 > 0)
                 result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
             if (x & 0x20000000 > 0)
                 result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
             if (x & 0x10000000 > 0)
                 result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
             if (x & 0x8000000 > 0)
                 result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
             if (x & 0x4000000 > 0)
                 result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
             if (x & 0x2000000 > 0)
                 result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
             if (x & 0x1000000 > 0)
                 result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
             if (x & 0x800000 > 0)
                 result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
             if (x & 0x400000 > 0)
                 result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
             if (x & 0x200000 > 0)
                 result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
             if (x & 0x100000 > 0)
                 result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
             if (x & 0x80000 > 0)
                 result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
             if (x & 0x40000 > 0)
                 result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
             if (x & 0x20000 > 0)
                 result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
             if (x & 0x10000 > 0)
                 result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
             if (x & 0x8000 > 0)
                 result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
             if (x & 0x4000 > 0)
                 result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
             if (x & 0x2000 > 0)
                 result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
             if (x & 0x1000 > 0)
                 result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
             if (x & 0x800 > 0)
                 result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
             if (x & 0x400 > 0)
                 result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
             if (x & 0x200 > 0)
                 result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
             if (x & 0x100 > 0)
                 result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
             if (x & 0x80 > 0)
                 result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
             if (x & 0x40 > 0)
                 result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
             if (x & 0x20 > 0)
                 result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
             if (x & 0x10 > 0)
                 result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
             if (x & 0x8 > 0)
                 result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
             if (x & 0x4 > 0)
                 result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
             if (x & 0x2 > 0)
                 result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
             if (x & 0x1 > 0)
                 result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;
 
             result >>= uint256(int256(63 - (x >> 64)));
             require(result <= uint256(int256(MAX_64x64)));
 
             return int128(int256(result));
         }
     }
 
     /**
      * Calculate natural exponent of x.  Revert on overflow.
      *
      * @param x signed 64.64-bit fixed point number
      * @return signed 64.64-bit fixed point number
      */
     function exp(int128 x) internal pure returns (int128) {
         unchecked {
             require(x < 0x400000000000000000); // Overflow
 
             if (x < -0x400000000000000000) return 0; // Underflow
 
             return
                 exp_2(
                     int128(
                         (int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128
                     )
                 );
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
     function divuu(uint256 x, uint256 y) private pure returns (uint128) {
         unchecked {
             require(y != 0);
 
             uint256 result;
 
             if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                 result = (x << 64) / y;
             else {
                 uint256 msb = 192;
                 uint256 xc = x >> 192;
                 if (xc >= 0x100000000) {
                     xc >>= 32;
                     msb += 32;
                 }
                 if (xc >= 0x10000) {
                     xc >>= 16;
                     msb += 16;
                 }
                 if (xc >= 0x100) {
                     xc >>= 8;
                     msb += 8;
                 }
                 if (xc >= 0x10) {
                     xc >>= 4;
                     msb += 4;
                 }
                 if (xc >= 0x4) {
                     xc >>= 2;
                     msb += 2;
                 }
                 if (xc >= 0x2) msb += 1; // No need to shift xc anymore
 
                 result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                 require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
 
                 uint256 hi = result * (y >> 128);
                 uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
 
                 uint256 xh = x >> 192;
                 uint256 xl = x << 64;
 
                 if (xl < lo) xh -= 1;
                 xl -= lo; // We rely on overflow behavior here
                 lo = hi << 128;
                 if (xl < lo) xh -= 1;
                 xl -= lo; // We rely on overflow behavior here
 
                 assert(xh == hi >> 128);
 
                 result += xl / y;
             }
 
             require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
             return uint128(result);
         }
     }
 
     /**
      * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
      * number.
      *
      * @param x unsigned 256-bit integer number
      * @return unsigned 128-bit integer number
      */
     function sqrtu(uint256 x) private pure returns (uint128) {
         unchecked {
             if (x == 0) return 0;
             else {
                 uint256 xx = x;
                 uint256 r = 1;
                 if (xx >= 0x100000000000000000000000000000000) {
                     xx >>= 128;
                     r <<= 64;
                 }
                 if (xx >= 0x10000000000000000) {
                     xx >>= 64;
                     r <<= 32;
                 }
                 if (xx >= 0x100000000) {
                     xx >>= 32;
                     r <<= 16;
                 }
                 if (xx >= 0x10000) {
                     xx >>= 16;
                     r <<= 8;
                 }
                 if (xx >= 0x100) {
                     xx >>= 8;
                     r <<= 4;
                 }
                 if (xx >= 0x10) {
                     xx >>= 4;
                     r <<= 2;
                 }
                 if (xx >= 0x8) {
                     r <<= 1;
                 }
                 r = (r + x / r) >> 1;
                 r = (r + x / r) >> 1;
                 r = (r + x / r) >> 1;
                 r = (r + x / r) >> 1;
                 r = (r + x / r) >> 1;
                 r = (r + x / r) >> 1;
                 r = (r + x / r) >> 1; // Seven iterations should be enough
                 uint256 r1 = x / r;
                 return uint128(r < r1 ? r : r1);
             }
         }
     }
 }
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapPair {
    event Sync(uint112 reserve0, uint112 reserve1);

    function sync() external;
}

interface IRoseToken {
    function mint(address to, uint256 amount) external;

    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) external returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferUnderlying(address to, uint256 value)
        external
        returns (bool);

    function fragmentToRose(uint256 value) external view returns (uint256);

    function roseToFragment(uint256 rose) external view returns (uint256);

    function balanceOfUnderlying(address who) external view returns (uint256);
}

interface IReferral {
    /**
     * @dev Record referral.
     */
     function recordReferral(address user, address referrer) external;

     /**
      * @dev Record referral commission.
      */
     function recordReferralCommission(address referrer, uint256 commission) external;
 
     /**
      * @dev Get the referrer address that referred the user.
      */
     function getReferrer(address user) external view returns (address);
}

// Note that this pool has no minter key of ROSE (rewards).
// Instead, the governance will call ROSE distributeReward method and send reward to this pool at the beginning.
contract RoseGenesisRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IRoseToken;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ROSE to distribute.
        uint256 lastRewardTime; // Last time that ROSE distribution occurs.
        uint256 accRosePerShare; // Accumulated ROSE per share, times 1e18. See below.
        bool isStarted; // if lastRewardBlock has passed
        uint256 depositFeeBP; // deposit fee
    }

    IReferral public referral;
    uint256 public referralCommissionRate = 20; // 2%

    IRoseToken public rose;
    // ROSE LP address
    IUniswapPair public roseLp;

    // Compound ratio which is 0.00008% per second = 7% per day (will be used to decrease supply)
    uint256 public compoundRatio = 8e11;
    // last rebase timestamp
    uint256 public lastRebaseTime;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when ROSE mining starts.
    uint256 public poolStartTime;

    // The time when ROSE mining ends.
    uint256 public poolEndTime;

    uint256 public rosePerSecond = 0.11574074074 ether; // 20000 ROSE / (2day * 60min * 60s)
    uint256 public runningTime = 2 days; // 2 days
    uint256 public constant TOTAL_REWARDS = 20000 ether;

    address public feeWallet;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor(
        IRoseToken _rose,
        uint256 _poolStartTime,
        IUniswapPair _roseLp,
        IReferral _referral
    ) {
        require(block.timestamp < _poolStartTime, "late");
        require(address(_rose) != address(0), "wrong rose address");
        rose = _rose;
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        operator = msg.sender;
        feeWallet = msg.sender;
        roseLp = _roseLp;
        lastRebaseTime = poolStartTime;
        referral = _referral;
    }

    function pow(int128 x, uint256 n) public pure returns (int128 r) {
        r = ABDKMath64x64.fromUInt(1);
        while (n > 0) {
            if (n % 2 == 1) {
                r = ABDKMath64x64.mul(r, x);
                n -= 1;
            } else {
                x = ABDKMath64x64.mul(x, x);
                n /= 2;
            }
        }
    }

    function compound(
        uint256 principal,
        uint256 ratio,
        uint256 n
    ) public pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(ratio, 10**18)
                    ),
                    n
                ),
                principal
            );
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "RoseGenesisPool: caller is not the operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "RoseGenesisPool: existing pool?");
        }
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFeeBP
    ) public onlyOperator {
        require(address(_token) != address(rose), "Deposit token can't be Rose");
        require(_depositFeeBP <= 10, "10 is 1%");
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({token: _token, allocPoint: _allocPoint, lastRewardTime: _lastRewardTime, accRosePerShare: 0, isStarted: _isStarted, depositFeeBP: _depositFeeBP}));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's ROSE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
        }
        pool.allocPoint = _allocPoint;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(rosePerSecond);
            return poolEndTime.sub(_fromTime).mul(rosePerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(rosePerSecond);
            return _toTime.sub(_fromTime).mul(rosePerSecond);
        }
    }

    // View function to see pending ROSE on frontend.
    function pendingRose(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRosePerShare = pool.accRosePerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _roseReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accRosePerShare = accRosePerShare.add(_roseReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accRosePerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _roseReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accRosePerShare = pool.accRosePerShare.add(_roseReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
        }
        if (user.amount > 0) {
            claim(_pid);
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            if (pool.depositFeeBP != 0) {
                uint256 fee = _amount.mul(pool.depositFeeBP).div(1000);
                pool.token.safeTransfer(feeWallet, fee);
                _amount = _amount.sub(fee);
            }
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRosePerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        claim(_pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRosePerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }


    // claim and debase ROSE
    function claim(uint256 _pid) internal {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        uint256 _pending = user.amount.mul(pool.accRosePerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            rose.mint(_sender, _pending);
            payReferralCommission(_sender, _pending);
            emit RewardPaid(_sender, _pending);
            if (lastRebaseTime != block.timestamp && block.timestamp < poolEndTime) {
                rose.rebase(
                    block.timestamp,
                    compound(1e18, compoundRatio, block.timestamp - lastRebaseTime) - 1e18,
                    false
                );
                lastRebaseTime = block.timestamp;
                roseLp.sync();
            }
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setFeeWallet(address _feeWallet) external {
        require(msg.sender == feeWallet, "!feeWallet");
        require(_feeWallet != address(0), "zero");
        feeWallet = _feeWallet;
    }

    // Set referral contract address
    function setReferral(IReferral _referral) public onlyOperator {
        require(address(_referral) != address(0), "can't set 0 address");
        referral = _referral;
    }

    // Update referral commission rate by the operator
    function setReferralCommissionRate(uint256 _referralCommissionRate) public onlyOperator {
        require(_referralCommissionRate <= 1000, "max is 100%");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(1000);

            if (referrer != address(0) && commissionAmount > 0) {
                rose.mint(referrer, commissionAmount);
                referral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }
}