// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

import "./VertexData.sol";
import "./Fix64V1.sol";
import "./Trig256.sol";

struct Ellipse {
    int64 originX;
    int64 originY;
    int64 radiusX;
    int64 radiusY;
    uint32 steps;
}

library EllipseMethods {

    function circle(
        int64 originX,
        int64 originY,
        int64 radius
    ) external pure returns (Ellipse memory data) {
        return create_impl(originX, originY, radius, radius);
    }

    function create(
        int64 originX,
        int64 originY,
        int64 radiusX,
        int64 radiusY
    ) external pure returns (Ellipse memory data) {
        return create_impl(originX, originY, radiusX, radiusY);
    }

    function create_impl(int64 originX,
        int64 originY,
        int64 radiusX,
        int64 radiusY
    ) private pure returns (Ellipse memory data) {
        data.originX = originX;
        data.originY = originY;
        data.radiusX = radiusX;
        data.radiusY = radiusY;

        int64 ra = Fix64V1.div(
            Fix64V1.add(
                int64(Fix64V1.abs(int64(radiusX))),
                int64(Fix64V1.abs(int64(radiusY)))
            ),
            Fix64V1.TWO
        );

        int64 da = Fix64V1.mul(
            Trig256.acos(
                Fix64V1.div(
                    ra,
                    Fix64V1.add(
                        ra,
                        Fix64V1.div(
                            536870912, /* 0.125 */
                            Fix64V1.ONE
                        )
                    )
                )
            ),
            Fix64V1.TWO
        );

        int64 t1 = Fix64V1.mul(Fix64V1.TWO, Fix64V1.div(Fix64V1.PI, da));
        data.steps = uint32(int32(Fix64V1.round(t1) / Fix64V1.ONE));
        return data;
    }

    function vertices(Ellipse memory data)
        external
        pure
        returns (VertexData[] memory results)
    {
        results = new VertexData[](data.steps + 3);

        VertexData memory v0;
        v0.command = Command.MoveTo;
        v0.position = Vector2(
            Fix64V1.add(data.originX, data.radiusX),
            data.originY
        );
        results[0] = v0;

        int64 anglePerStep = Fix64V1.div(
            Fix64V1.TWO_PI,
            int32(data.steps) * Fix64V1.ONE
        );
        int64 angle = 0;
        
        for (uint32 i = 1; i < uint32(data.steps); i++) {

            VertexData memory v1;
            v1.command = Command.LineTo;

            angle = Fix64V1.add(angle, anglePerStep);

            int64 x = Fix64V1.add(
                data.originX,
                Fix64V1.mul(Trig256.cos(angle), data.radiusX)
            );

            int64 y = Fix64V1.add(
                data.originY,
                Fix64V1.mul(Trig256.sin(angle), data.radiusY)
            );

            v1.position = Vector2(x, y);
            results[i] = v1;
        }

        VertexData memory v2;
        v2.position = Vector2(0, 0);
        v2.command = Command.EndPoly;
        results[uint32(data.steps)] = v2;

        VertexData memory v3;
        v3.command = Command.Stop;
        results[uint32(data.steps + 1)] = v3;
    }
}

// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

import "./Command.sol";
import "./Vector2.sol";

struct VertexData {
    Command command;
    Vector2 position;
}

// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

/*
    Provides mathematical operations and representation in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath
    
    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from André Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 André Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

import "./Errors.sol";

library Fix64V1 {
    int64 public constant FRACTIONAL_PLACES = 32;
    int64 public constant ONE = 4294967296; // 1 << FRACTIONAL_PLACES
    int64 public constant TWO = ONE * 2;
    int64 public constant THREE = ONE * 3;
    int64 public constant PI = 0x3243F6A88;
    int64 public constant TWO_PI = 0x6487ED511;
    int64 public constant MAX_VALUE = type(int64).max;
    int64 public constant MIN_VALUE = type(int64).min;
    int64 public constant PI_OVER_2 = 0x1921FB544;

    function countLeadingZeros(uint64 x) internal pure returns (int64) {
        int64 result = 0;
        while ((x & 0xF000000000000000) == 0) {
            result += 4;
            x <<= 4;
        }
        while ((x & 0x8000000000000000) == 0) {
            result += 1;
            x <<= 1;
        }
        return result;
    }

    function div(int64 x, int64 y) internal pure returns (int64) {
        if (y == 0) {
            revert AttemptedToDivideByZero();
        }

        int64 xl = x;
        int64 yl = y;

        uint64 remainder = uint64(xl >= 0 ? xl : -xl);
        uint64 divider = uint64((yl >= 0 ? yl : -yl));
        uint64 quotient = 0;
        int64 bitPos = 64 / 2 + 1;

        while ((divider & 0xF) == 0 && bitPos >= 4) {
            divider >>= 4;
            bitPos -= 4;
        }

        while (remainder != 0 && bitPos >= 0) {
            int64 shift = countLeadingZeros(remainder);
            if (shift > bitPos) {
                shift = bitPos;
            }
            remainder <<= uint64(shift);
            bitPos -= shift;

            uint64 d = remainder / divider;
            remainder = remainder % divider;
            quotient += d << uint64(bitPos);

            if ((d & ~(uint64(0xFFFFFFFFFFFFFFFF) >> uint64(bitPos)) != 0)) {
                return ((xl ^ yl) & MIN_VALUE) == 0 ? MAX_VALUE : MIN_VALUE;
            }

            remainder <<= 1;
            --bitPos;
        }

        ++quotient;
        int64 result = int64(quotient >> 1);
        if (((xl ^ yl) & MIN_VALUE) != 0) {
            result = -result;
        }

        return int64(result);
    }

    function mul(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;

        uint64 xlo = (uint64)((xl & (int64)(0x00000000FFFFFFFF)));
        int64 xhi = xl >> 32; // FRACTIONAL_PLACES
        uint64 ylo = (uint64)(yl & (int64)(0x00000000FFFFFFFF));
        int64 yhi = yl >> 32; // FRACTIONAL_PLACES

        uint64 lolo = xlo * ylo;
        int64 lohi = int64(xlo) * yhi;
        int64 hilo = xhi * int64(ylo);
        int64 hihi = xhi * yhi;

        uint64 loResult = lolo >> 32; // FRACTIONAL_PLACES
        int64 midResult1 = lohi;
        int64 midResult2 = hilo;
        int64 hiResult = hihi << 32; // FRACTIONAL_PLACES

        int64 sum = int64(loResult) + midResult1 + midResult2 + hiResult;

        return int64(sum);
    }

    function mul_256(int256 x, int256 y) internal pure returns (int256) {
        int256 xl = x;
        int256 yl = y;

        uint256 xlo = uint256((xl & int256(0x00000000FFFFFFFF)));
        int256 xhi = xl >> 32; // FRACTIONAL_PLACES
        uint256 ylo = uint256(yl & int256(0x00000000FFFFFFFF));
        int256 yhi = yl >> 32; // FRACTIONAL_PLACES

        uint256 lolo = xlo * ylo;
        int256 lohi = int256(xlo) * yhi;
        int256 hilo = xhi * int256(ylo);
        int256 hihi = xhi * yhi;

        uint256 loResult = lolo >> 32; // FRACTIONAL_PLACES
        int256 midResult1 = lohi;
        int256 midResult2 = hilo;
        int256 hiResult = hihi << 32; // FRACTIONAL_PLACES

        int256 sum = int256(loResult) + midResult1 + midResult2 + hiResult;

        return sum;
    }

    function floor(int256 x) internal pure returns (int64) {
        return int64(x & 0xFFFFFFFF00000000);
    }

    function round(int256 x) internal pure returns (int256) {
        int256 fractionalPart = x & 0x00000000FFFFFFFF;
        int256 integralPart = floor(x);
        if (fractionalPart < 0x80000000) return integralPart;
        if (fractionalPart > 0x80000000) return integralPart + ONE;
        if ((integralPart & ONE) == 0) return integralPart;
        return integralPart + ONE;
    }

    function sub(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;
        int64 diff = xl - yl;
        if (((xl ^ yl) & (xl ^ diff) & MIN_VALUE) != 0)
            diff = xl < 0 ? MIN_VALUE : MAX_VALUE;
        return diff;
    }

    function add(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;
        int64 sum = xl + yl;
        if ((~(xl ^ yl) & (xl ^ sum) & MIN_VALUE) != 0)
            sum = xl > 0 ? MAX_VALUE : MIN_VALUE;
        return sum;
    }

    function sign(int64 x) internal pure returns (int8) {
        return x == int8(0) ? int8(0) : x > int8(0) ? int8(1) : int8(-1);
    }

    function abs(int64 x) internal pure returns (int64) {
        int64 mask = x >> 63;
        return (x + mask) ^ mask;
    }

    function max(int64 a, int64 b) internal pure returns (int64) {
        return a >= b ? a : b;
    }

    function min(int64 a, int64 b) internal pure returns (int64) {
        return a < b ? a : b;
    }

    function map(
        int64 n,
        int64 start1,
        int64 stop1,
        int64 start2,
        int64 stop2
    ) internal pure returns (int64) {
        int64 value = mul(
            div(sub(n, start1), sub(stop1, start1)),
            add(sub(stop2, start2), start2)
        );

        return
            start2 < stop2
                ? constrain(value, start2, stop2)
                : constrain(value, stop2, start2);
    }

    function constrain(
        int64 n,
        int64 low,
        int64 high
    ) internal pure returns (int64) {
        return max(min(n, high), low);
    }
}

// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/
pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./SinLut256.sol";

/*
    Provides trigonometric functions in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath

    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from André Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 André Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Trig256 {
    int64 private constant LARGE_PI = 7244019458077122842;
    int64 private constant LN2 = 0xB17217F7;
    int64 private constant LN_MAX = 0x157CD0E702;
    int64 private constant LN_MIN = -0x162E42FEFA;
    int64 private constant E = -0x2B7E15162;

    function sin(int64 x) internal pure returns (int64) {
        (int64 clamped, bool flipHorizontal, bool flipVertical) = clamp(x);

        int64 lutInterval = Fix64V1.div(
            ((256 - 1) * Fix64V1.ONE),
            Fix64V1.PI_OVER_2
        );
        int256 rawIndex = Fix64V1.mul_256(clamped, lutInterval);
        int64 roundedIndex = int64(Fix64V1.round(rawIndex));
        int64 indexError = Fix64V1.sub(int64(rawIndex), roundedIndex);

        roundedIndex = roundedIndex >> 32; /* FRACTIONAL_PLACES */

        int64 nearestValueIndex = flipHorizontal
            ? (256 - 1) - roundedIndex
            : roundedIndex;

        int64 nearestValue = SinLut256.sinlut(nearestValueIndex);

        int64 secondNearestValue = SinLut256.sinlut(
            flipHorizontal
                ? (256 - 1) - roundedIndex - Fix64V1.sign(indexError)
                : roundedIndex + Fix64V1.sign(indexError)
        );

        int64 delta = Fix64V1.mul(
            indexError,
            Fix64V1.abs(Fix64V1.sub(nearestValue, secondNearestValue))
        );
        int64 interpolatedValue = nearestValue +
            (flipHorizontal ? -delta : delta);
        int64 finalValue = flipVertical
            ? -interpolatedValue
            : interpolatedValue;

        return finalValue;
    }

    function cos(int64 x) internal pure returns (int64) {
        int64 xl = x;
        int64 angle;
        if (xl > 0) {
            angle = Fix64V1.add(
                xl,
                Fix64V1.sub(0 - Fix64V1.PI, Fix64V1.PI_OVER_2)
            );
        } else {
            angle = Fix64V1.add(xl, Fix64V1.PI_OVER_2);
        }
        return sin(angle);
    }

    function sqrt(int64 x) internal pure returns (int64) {
        int64 xl = x;
        if (xl < 0) revert NegativeValuePassed();

        uint64 num = uint64(xl);
        uint64 result = uint64(0);
        uint64 bit = uint64(1) << (64 - 2);

        while (bit > num) bit >>= 2;
        for (uint8 i = 0; i < 2; ++i) {
            while (bit != 0) {
                if (num >= result + bit) {
                    num -= result + bit;
                    result = (result >> 1) + bit;
                } else {
                    result = result >> 1;
                }

                bit >>= 2;
            }

            if (i == 0) {
                if (num > (uint64(1) << (64 / 2)) - 1) {
                    num -= result;
                    num = (num << (64 / 2)) - uint64(0x80000000);
                    result = (result << (64 / 2)) + uint64(0x80000000);
                } else {
                    num <<= 64 / 2;
                    result <<= 64 / 2;
                }

                bit = uint64(1) << (64 / 2 - 2);
            }
        }

        if (num > result) ++result;
        return int64(result);
    }

    function log2_256(int256 x) internal pure returns (int256) {
        if (x <= 0) {
            revert NegativeValuePassed();
        }

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int256 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int256 y = 0;

        int256 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int256 z = rawX;

        for (
            uint8 i = 0;
            i < 32; /* FRACTIONAL_PLACES */
            i++
        ) {
            z = Fix64V1.mul_256(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }
            b >>= 1;
        }

        return y;
    }

    function log_256(int256 x) internal pure returns (int256) {
        return Fix64V1.mul_256(log2_256(x), LN2);
    }

    function log2(int64 x) internal pure returns (int64) {
        if (x <= 0) revert NegativeValuePassed();

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int64 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int64 y = 0;

        int64 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int64 z = rawX;

        for (int32 i = 0; i < Fix64V1.FRACTIONAL_PLACES; i++) {
            z = Fix64V1.mul(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }

            b >>= 1;
        }

        return y;
    }

    function log(int64 x) internal pure returns (int64) {
        return Fix64V1.mul(log2(x), LN2);
    }

    function exp(int64 x) internal pure returns (int64) {
        if (x == 0) return Fix64V1.ONE;
        if (x == Fix64V1.ONE) return E;
        if (x >= LN_MAX) return Fix64V1.MAX_VALUE;
        if (x <= LN_MIN) return 0;

        /* The algorithm is based on the power series for exp(x):
         * http://en.wikipedia.org/wiki/Exponential_function#Formal_definition
         *
         * From term n, we get term n+1 by multiplying with x/n.
         * When the sum term drops to zero, we can stop summing.
         */

        // The power-series converges much faster on positive values
        // and exp(-x) = 1/exp(x).

        bool neg = (x < 0);
        if (neg) x = -x;

        int64 result = Fix64V1.add(int64(x), Fix64V1.ONE);
        int64 term = x;

        for (uint32 i = 2; i < 40; i++) {
            term = Fix64V1.mul(x, Fix64V1.div(term, int32(i) * Fix64V1.ONE));
            result = Fix64V1.add(result, int64(term));
            if (term == 0) break;
        }

        if (neg) {
            result = Fix64V1.div(Fix64V1.ONE, result);
        }

        return result;
    }

    function clamp(int64 x)
        internal
        pure
        returns (
            int64,
            bool,
            bool
        )
    {
        int64 clamped2Pi = x;
        for (uint8 i = 0; i < 29; ++i) {
            clamped2Pi %= LARGE_PI >> i;
        }
        if (x < 0) {
            clamped2Pi += Fix64V1.TWO_PI;
        }

        bool flipVertical = clamped2Pi >= Fix64V1.PI;
        int64 clampedPi = clamped2Pi;
        while (clampedPi >= Fix64V1.PI) {
            clampedPi -= Fix64V1.PI;
        }

        bool flipHorizontal = clampedPi >= Fix64V1.PI_OVER_2;

        int64 clampedPiOver2 = clampedPi;
        if (clampedPiOver2 >= Fix64V1.PI_OVER_2)
            clampedPiOver2 -= Fix64V1.PI_OVER_2;

        return (clampedPiOver2, flipHorizontal, flipVertical);
    }

    function acos(int64 x) internal pure returns (int64 result) {
        if (x < -Fix64V1.ONE || x > Fix64V1.ONE) revert("invalid range for x");
        if (x == 0) return Fix64V1.PI_OVER_2;

        int64 t1 = Fix64V1.ONE - Fix64V1.mul(x, x);
        int64 t2 = Fix64V1.div(sqrt(t1), x);

        result = atan(t2);
        return x < 0 ? result + Fix64V1.PI : result;
    }

    function atan(int64 z) internal pure returns (int64 result) {
        if (z == 0) return 0;

        bool neg = z < 0;
        if (neg) z = -z;

        int64 two = Fix64V1.TWO;
        int64 three = Fix64V1.THREE;

        bool invert = z > Fix64V1.ONE;
        if (invert) z = Fix64V1.div(Fix64V1.ONE, z);

        result = Fix64V1.ONE;
        int64 term = Fix64V1.ONE;

        int64 zSq = Fix64V1.mul(z, z);
        int64 zSq2 = Fix64V1.mul(zSq, two);
        int64 zSqPlusOne = Fix64V1.add(zSq, Fix64V1.ONE);
        int64 zSq12 = Fix64V1.mul(zSqPlusOne, two);
        int64 dividend = zSq2;
        int64 divisor = Fix64V1.mul(zSqPlusOne, three);

        for (uint8 i = 2; i < 30; ++i) {
            term = Fix64V1.mul(term, Fix64V1.div(dividend, divisor));
            result = Fix64V1.add(result, term);

            dividend = Fix64V1.add(dividend, zSq2);
            divisor = Fix64V1.add(divisor, zSq12);

            if (term == 0) break;
        }

        result = Fix64V1.mul(result, Fix64V1.div(z, zSqPlusOne));

        if (invert) {
            result = Fix64V1.sub(Fix64V1.PI_OVER_2, result);
        }

        if (neg) {
            result = -result;
        }

        return result;
    }

    function atan2(int64 y, int64 x) internal pure returns (int64 result) {
        int64 e = 1202590848; /* 0.28 */
        int64 yl = y;
        int64 xl = x;

        if (xl == 0) {
            if (yl > 0) {
                return Fix64V1.PI_OVER_2;
            }
            if (yl == 0) {
                return 0;
            }
            return -Fix64V1.PI_OVER_2;
        }

        int64 z = Fix64V1.div(y, x);

        if (
            Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z))) ==
            type(int64).max
        ) {
            return y < 0 ? -Fix64V1.PI_OVER_2 : Fix64V1.PI_OVER_2;
        }

        if (Fix64V1.abs(z) < Fix64V1.ONE) {
            result = Fix64V1.div(
                z,
                Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z)))
            );
            if (xl < 0) {
                if (yl < 0) {
                    return Fix64V1.sub(result, Fix64V1.PI);
                }

                return Fix64V1.add(result, Fix64V1.PI);
            }
        } else {
            result = Fix64V1.sub(
                Fix64V1.PI_OVER_2,
                Fix64V1.div(z, Fix64V1.add(Fix64V1.mul(z, z), e))
            );

            if (yl < 0) {
                return Fix64V1.sub(result, Fix64V1.PI);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

enum Command {
    Stop,
    MoveTo,
    LineTo,
    Curve3,
    Curve4,
    EndPoly
}

// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

struct Vector2 {
    int64 x;
    int64 y;
}

// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

error ArgumentOutOfRange();
error AttemptedToDivideByZero();
error NegativeValuePassed();

// SPDX-License-Identifier: MIT
/* Copyright (c) Kohi Art Community, Inc. All rights reserved. */

/*
/*
///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//     @@@@@@@@@@@@@@                        @@@@                                // 
//               @@@@                        @@@@ @@@@@@@@                       // 
//               @@@@    @@@@@@@@@@@@@@@@    @@@@@@@          @@@@@@@@@@@@@@@@   // 
//               @@@@                        @@@@                                // 
//     @@@@@@@@@@@@@@                        @@@@@@@@@@@@@                       // 
//               @@@@                          @@@@@@@@@@@                       // 
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////
*/

pragma solidity ^0.8.13;

library SinLut256 {
    /**
     * @notice Lookup tables for computing the sine value for a given angle.
     * @param i The clamped and rounded angle integral to index into the table.
     * @return The sine value in fixed-point (Q31.32) space.
     */
    function sinlut(int256 i) external pure returns (int64) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) {
                                        return 0;
                                    } else {
                                        return 26456769;
                                    }
                                } else {
                                    if (i == 2) {
                                        return 52912534;
                                    } else {
                                        return 79366292;
                                    }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) {
                                        return 105817038;
                                    } else {
                                        return 132263769;
                                    }
                                } else {
                                    if (i == 6) {
                                        return 158705481;
                                    } else {
                                        return 185141171;
                                    }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) {
                                        return 211569835;
                                    } else {
                                        return 237990472;
                                    }
                                } else {
                                    if (i == 10) {
                                        return 264402078;
                                    } else {
                                        return 290803651;
                                    }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) {
                                        return 317194190;
                                    } else {
                                        return 343572692;
                                    }
                                } else {
                                    if (i == 14) {
                                        return 369938158;
                                    } else {
                                        return 396289586;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) {
                                        return 422625977;
                                    } else {
                                        return 448946331;
                                    }
                                } else {
                                    if (i == 18) {
                                        return 475249649;
                                    } else {
                                        return 501534935;
                                    }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) {
                                        return 527801189;
                                    } else {
                                        return 554047416;
                                    }
                                } else {
                                    if (i == 22) {
                                        return 580272619;
                                    } else {
                                        return 606475804;
                                    }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) {
                                        return 632655975;
                                    } else {
                                        return 658812141;
                                    }
                                } else {
                                    if (i == 26) {
                                        return 684943307;
                                    } else {
                                        return 711048483;
                                    }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) {
                                        return 737126679;
                                    } else {
                                        return 763176903;
                                    }
                                } else {
                                    if (i == 30) {
                                        return 789198169;
                                    } else {
                                        return 815189489;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) {
                                        return 841149875;
                                    } else {
                                        return 867078344;
                                    }
                                } else {
                                    if (i == 34) {
                                        return 892973912;
                                    } else {
                                        return 918835595;
                                    }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) {
                                        return 944662413;
                                    } else {
                                        return 970453386;
                                    }
                                } else {
                                    if (i == 38) {
                                        return 996207534;
                                    } else {
                                        return 1021923881;
                                    }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) {
                                        return 1047601450;
                                    } else {
                                        return 1073239268;
                                    }
                                } else {
                                    if (i == 42) {
                                        return 1098836362;
                                    } else {
                                        return 1124391760;
                                    }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) {
                                        return 1149904493;
                                    } else {
                                        return 1175373592;
                                    }
                                } else {
                                    if (i == 46) {
                                        return 1200798091;
                                    } else {
                                        return 1226177026;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) {
                                        return 1251509433;
                                    } else {
                                        return 1276794351;
                                    }
                                } else {
                                    if (i == 50) {
                                        return 1302030821;
                                    } else {
                                        return 1327217884;
                                    }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) {
                                        return 1352354586;
                                    } else {
                                        return 1377439973;
                                    }
                                } else {
                                    if (i == 54) {
                                        return 1402473092;
                                    } else {
                                        return 1427452994;
                                    }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) {
                                        return 1452378731;
                                    } else {
                                        return 1477249357;
                                    }
                                } else {
                                    if (i == 58) {
                                        return 1502063928;
                                    } else {
                                        return 1526821503;
                                    }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) {
                                        return 1551521142;
                                    } else {
                                        return 1576161908;
                                    }
                                } else {
                                    if (i == 62) {
                                        return 1600742866;
                                    } else {
                                        return 1625263084;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) {
                                        return 1649721630;
                                    } else {
                                        return 1674117578;
                                    }
                                } else {
                                    if (i == 66) {
                                        return 1698450000;
                                    } else {
                                        return 1722717974;
                                    }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) {
                                        return 1746920580;
                                    } else {
                                        return 1771056897;
                                    }
                                } else {
                                    if (i == 70) {
                                        return 1795126012;
                                    } else {
                                        return 1819127010;
                                    }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) {
                                        return 1843058980;
                                    } else {
                                        return 1866921015;
                                    }
                                } else {
                                    if (i == 74) {
                                        return 1890712210;
                                    } else {
                                        return 1914431660;
                                    }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) {
                                        return 1938078467;
                                    } else {
                                        return 1961651733;
                                    }
                                } else {
                                    if (i == 78) {
                                        return 1985150563;
                                    } else {
                                        return 2008574067;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) {
                                        return 2031921354;
                                    } else {
                                        return 2055191540;
                                    }
                                } else {
                                    if (i == 82) {
                                        return 2078383740;
                                    } else {
                                        return 2101497076;
                                    }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) {
                                        return 2124530670;
                                    } else {
                                        return 2147483647;
                                    }
                                } else {
                                    if (i == 86) {
                                        return 2170355138;
                                    } else {
                                        return 2193144275;
                                    }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) {
                                        return 2215850191;
                                    } else {
                                        return 2238472027;
                                    }
                                } else {
                                    if (i == 90) {
                                        return 2261008923;
                                    } else {
                                        return 2283460024;
                                    }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) {
                                        return 2305824479;
                                    } else {
                                        return 2328101438;
                                    }
                                } else {
                                    if (i == 94) {
                                        return 2350290057;
                                    } else {
                                        return 2372389494;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) {
                                        return 2394398909;
                                    } else {
                                        return 2416317469;
                                    }
                                } else {
                                    if (i == 98) {
                                        return 2438144340;
                                    } else {
                                        return 2459878695;
                                    }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) {
                                        return 2481519710;
                                    } else {
                                        return 2503066562;
                                    }
                                } else {
                                    if (i == 102) {
                                        return 2524518435;
                                    } else {
                                        return 2545874514;
                                    }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) {
                                        return 2567133990;
                                    } else {
                                        return 2588296054;
                                    }
                                } else {
                                    if (i == 106) {
                                        return 2609359905;
                                    } else {
                                        return 2630324743;
                                    }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) {
                                        return 2651189772;
                                    } else {
                                        return 2671954202;
                                    }
                                } else {
                                    if (i == 110) {
                                        return 2692617243;
                                    } else {
                                        return 2713178112;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) {
                                        return 2733636028;
                                    } else {
                                        return 2753990216;
                                    }
                                } else {
                                    if (i == 114) {
                                        return 2774239903;
                                    } else {
                                        return 2794384321;
                                    }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) {
                                        return 2814422705;
                                    } else {
                                        return 2834354295;
                                    }
                                } else {
                                    if (i == 118) {
                                        return 2854178334;
                                    } else {
                                        return 2873894071;
                                    }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) {
                                        return 2893500756;
                                    } else {
                                        return 2912997648;
                                    }
                                } else {
                                    if (i == 122) {
                                        return 2932384004;
                                    } else {
                                        return 2951659090;
                                    }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) {
                                        return 2970822175;
                                    } else {
                                        return 2989872531;
                                    }
                                } else {
                                    if (i == 126) {
                                        return 3008809435;
                                    } else {
                                        return 3027632170;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) {
                                        return 3046340019;
                                    } else {
                                        return 3064932275;
                                    }
                                } else {
                                    if (i == 130) {
                                        return 3083408230;
                                    } else {
                                        return 3101767185;
                                    }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) {
                                        return 3120008443;
                                    } else {
                                        return 3138131310;
                                    }
                                } else {
                                    if (i == 134) {
                                        return 3156135101;
                                    } else {
                                        return 3174019130;
                                    }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) {
                                        return 3191782721;
                                    } else {
                                        return 3209425199;
                                    }
                                } else {
                                    if (i == 138) {
                                        return 3226945894;
                                    } else {
                                        return 3244344141;
                                    }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) {
                                        return 3261619281;
                                    } else {
                                        return 3278770658;
                                    }
                                } else {
                                    if (i == 142) {
                                        return 3295797620;
                                    } else {
                                        return 3312699523;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) {
                                        return 3329475725;
                                    } else {
                                        return 3346125588;
                                    }
                                } else {
                                    if (i == 146) {
                                        return 3362648482;
                                    } else {
                                        return 3379043779;
                                    }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) {
                                        return 3395310857;
                                    } else {
                                        return 3411449099;
                                    }
                                } else {
                                    if (i == 150) {
                                        return 3427457892;
                                    } else {
                                        return 3443336630;
                                    }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) {
                                        return 3459084709;
                                    } else {
                                        return 3474701532;
                                    }
                                } else {
                                    if (i == 154) {
                                        return 3490186507;
                                    } else {
                                        return 3505539045;
                                    }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) {
                                        return 3520758565;
                                    } else {
                                        return 3535844488;
                                    }
                                } else {
                                    if (i == 158) {
                                        return 3550796243;
                                    } else {
                                        return 3565613262;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) {
                                        return 3580294982;
                                    } else {
                                        return 3594840847;
                                    }
                                } else {
                                    if (i == 162) {
                                        return 3609250305;
                                    } else {
                                        return 3623522808;
                                    }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) {
                                        return 3637657816;
                                    } else {
                                        return 3651654792;
                                    }
                                } else {
                                    if (i == 166) {
                                        return 3665513205;
                                    } else {
                                        return 3679232528;
                                    }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) {
                                        return 3692812243;
                                    } else {
                                        return 3706251832;
                                    }
                                } else {
                                    if (i == 170) {
                                        return 3719550786;
                                    } else {
                                        return 3732708601;
                                    }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) {
                                        return 3745724777;
                                    } else {
                                        return 3758598821;
                                    }
                                } else {
                                    if (i == 174) {
                                        return 3771330243;
                                    } else {
                                        return 3783918561;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) {
                                        return 3796363297;
                                    } else {
                                        return 3808663979;
                                    }
                                } else {
                                    if (i == 178) {
                                        return 3820820141;
                                    } else {
                                        return 3832831319;
                                    }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) {
                                        return 3844697060;
                                    } else {
                                        return 3856416913;
                                    }
                                } else {
                                    if (i == 182) {
                                        return 3867990433;
                                    } else {
                                        return 3879417181;
                                    }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) {
                                        return 3890696723;
                                    } else {
                                        return 3901828632;
                                    }
                                } else {
                                    if (i == 186) {
                                        return 3912812484;
                                    } else {
                                        return 3923647863;
                                    }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) {
                                        return 3934334359;
                                    } else {
                                        return 3944871565;
                                    }
                                } else {
                                    if (i == 190) {
                                        return 3955259082;
                                    } else {
                                        return 3965496515;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) {
                                        return 3975583476;
                                    } else {
                                        return 3985519583;
                                    }
                                } else {
                                    if (i == 194) {
                                        return 3995304457;
                                    } else {
                                        return 4004937729;
                                    }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) {
                                        return 4014419032;
                                    } else {
                                        return 4023748007;
                                    }
                                } else {
                                    if (i == 198) {
                                        return 4032924300;
                                    } else {
                                        return 4041947562;
                                    }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) {
                                        return 4050817451;
                                    } else {
                                        return 4059533630;
                                    }
                                } else {
                                    if (i == 202) {
                                        return 4068095769;
                                    } else {
                                        return 4076503544;
                                    }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) {
                                        return 4084756634;
                                    } else {
                                        return 4092854726;
                                    }
                                } else {
                                    if (i == 206) {
                                        return 4100797514;
                                    } else {
                                        return 4108584696;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) {
                                        return 4116215977;
                                    } else {
                                        return 4123691067;
                                    }
                                } else {
                                    if (i == 210) {
                                        return 4131009681;
                                    } else {
                                        return 4138171544;
                                    }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) {
                                        return 4145176382;
                                    } else {
                                        return 4152023930;
                                    }
                                } else {
                                    if (i == 214) {
                                        return 4158713929;
                                    } else {
                                        return 4165246124;
                                    }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) {
                                        return 4171620267;
                                    } else {
                                        return 4177836117;
                                    }
                                } else {
                                    if (i == 218) {
                                        return 4183893437;
                                    } else {
                                        return 4189791999;
                                    }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) {
                                        return 4195531577;
                                    } else {
                                        return 4201111955;
                                    }
                                } else {
                                    if (i == 222) {
                                        return 4206532921;
                                    } else {
                                        return 4211794268;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) {
                                        return 4216895797;
                                    } else {
                                        return 4221837315;
                                    }
                                } else {
                                    if (i == 226) {
                                        return 4226618635;
                                    } else {
                                        return 4231239573;
                                    }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) {
                                        return 4235699957;
                                    } else {
                                        return 4239999615;
                                    }
                                } else {
                                    if (i == 230) {
                                        return 4244138385;
                                    } else {
                                        return 4248116110;
                                    }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) {
                                        return 4251932639;
                                    } else {
                                        return 4255587827;
                                    }
                                } else {
                                    if (i == 234) {
                                        return 4259081536;
                                    } else {
                                        return 4262413632;
                                    }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) {
                                        return 4265583990;
                                    } else {
                                        return 4268592489;
                                    }
                                } else {
                                    if (i == 238) {
                                        return 4271439015;
                                    } else {
                                        return 4274123460;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) {
                                        return 4276645722;
                                    } else {
                                        return 4279005706;
                                    }
                                } else {
                                    if (i == 242) {
                                        return 4281203321;
                                    } else {
                                        return 4283238485;
                                    }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) {
                                        return 4285111119;
                                    } else {
                                        return 4286821154;
                                    }
                                } else {
                                    if (i == 246) {
                                        return 4288368525;
                                    } else {
                                        return 4289753172;
                                    }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) {
                                        return 4290975043;
                                    } else {
                                        return 4292034091;
                                    }
                                } else {
                                    if (i == 250) {
                                        return 4292930277;
                                    } else {
                                        return 4293663567;
                                    }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) {
                                        return 4294233932;
                                    } else {
                                        return 4294641351;
                                    }
                                } else {
                                    if (i == 254) {
                                        return 4294885809;
                                    } else {
                                        return 4294967296;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}