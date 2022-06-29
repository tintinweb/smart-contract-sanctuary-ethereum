// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./RenderArgs.sol";
import "./Texture5.sol";

struct RenderStar {
    uint32[] colors;
    Matrix m;
}

library UniverseMachineStarsFactory {
    function create(Parameters calldata p, Matrix calldata t)
        external
        pure
        returns (RenderStar[] memory stars)
    {
        stars = new RenderStar[](150);
        
        for (uint256 i = 0; i < 150; ++i) {
            int64 x = Fix64V1.mul(
                p.starPositions[i].x * Fix64V1.ONE,
                2992558336 /* 0.6967592592592593 */
            );

            int64 y = Fix64V1.mul(
                -p.starPositions[i].y * Fix64V1.ONE,
                2992558336 /* 0.6967592592592593 */
            );

            int64 s = Fix64V1.div(
                Fix64V1.mul(
                    2992558336, /* 0.6967592592592593 */
                    (p.starPositions[i].s / 1000) * Fix64V1.ONE
                ),
                Fix64V1.TWO
            );

            uint8 r = p.myColorsR[uint32(p.starPositions[i].c % p.cLen)];
            uint8 g = p.myColorsG[uint32(p.starPositions[i].c % p.cLen)];
            uint8 b = p.myColorsB[uint32(p.starPositions[i].c % p.cLen)];
            
            uint32 tint = ColorMath.toColor(255, r, g, b);

            stars[i].colors = new uint32[](2);
            stars[i].colors[0] = ColorMath.tint(436207615, tint);
            stars[i].colors[1] = ColorMath.tint(3439329279, tint);

            stars[i].m = TextureMethods.rectify(x, y, 0, s, t);
        }
    }
}

library UniverseMachineStars {
    function renderStars(
        Graphics2D memory g,
        DrawContext memory f,
        VertexData[][] calldata d,
        RenderStar[] calldata stars
    ) external pure returns (uint8[] memory) {
        for (uint256 i = 0; i < 150; ++i) {
            for (uint32 j = 0; j < 2; j++) {

                f.color = stars[i].colors[j];
                f.t = stars[i].m;

                Graphics2DMethods.renderWithTransform(
                    g,
                    f,
                    d[j],
                    true
                );
            }
        }

        return g.buffer;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../Kohi/Graphics2D.sol";
import "./Parameters.sol";

struct RenderArgs {
    Graphics2D g;
    Parameters p;
    Matrix m;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/Graphics2D.sol";
import "../Kohi/Matrix.sol";
import "../Kohi/Ellipse.sol";
import "../Kohi/ColorMath.sol";

import "./Textures.sol";

library Texture5Factory {
    function createTexture() external pure returns (VertexData[][] memory t) {        
        VertexData[] memory c1 = EllipseMethods.vertices(EllipseMethods.create(
            4767413698560,
            4776003633152,
            66743791616,
            66743791616
        ));
        VertexData[] memory c2 = EllipseMethods.vertices(EllipseMethods.create(
            4767413698560,
            4776003633152,
            28604481536,
            28604481536
        ));        
        t = new VertexData[][](2);
        t[0] = c1;
        t[1] = c2;
        return t;
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

import "./Vector2.sol";
import "./Fix64V1.sol";
import "./AntiAlias.sol";
import "./SubpixelScale.sol";
import "./RectangleInt.sol";
import "./Matrix.sol";
import "./ScanlineData.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./Clipping.sol";
import "./PixelClipping.sol";
import "./ColorMath.sol";
import "./ApplyTransform.sol";
import "./ScanlineRasterizer.sol";
import "./DrawContext.sol";

struct Graphics2D {
    uint32 width;
    uint32 height;
    uint8[] buffer;
    AntiAlias aa;
    SubpixelScale ss;
    ScanlineData scanlineData;
    ClippingData clippingData;
    CellData cellData;    
}

library Graphics2DMethods {
    // int32 public constant OrderB = 0;
    int32 public constant OrderG = 1;
    int32 public constant OrderR = 2;
    int32 public constant OrderA = 3;

    function create(uint32 width, uint32 height)
        external
        pure
        returns (Graphics2D memory g)
    {
        g.width = width;
        g.height = height;

        g.aa = AntiAliasMethods.create(8);
        g.ss = SubpixelScaleMethods.create(8);
        g.scanlineData = ScanlineDataMethods.create(width);
        g.clippingData = ClippingDataMethods.create(width, height, g.ss);
        g.cellData = CellDataMethods.create();
        g.buffer = new uint8[](width * 4 * height);
    }

    function clear(Graphics2D memory g, uint32 color)
        internal
        pure
    {
        int32 scale = int32(g.ss.scale);

        RectangleInt memory clippingRect = RectangleInt(
            g.clippingData.clipBox.left / scale,
            g.clippingData.clipBox.bottom / scale,
            g.clippingData.clipBox.right / scale,
            g.clippingData.clipBox.top / scale
        );

        for (int32 y = clippingRect.bottom; y < clippingRect.top; y++) {
            int32 bufferOffset = getBufferOffsetXy(g, clippingRect.left, y);

            for (int32 x = 0; x < clippingRect.right - clippingRect.left; x++) {
                g.buffer[uint32(bufferOffset /*+ OrderB */)] = uint8(color >> 0);
                g.buffer[uint32(bufferOffset + OrderG)] = uint8(color >> 8);
                g.buffer[uint32(bufferOffset + OrderR)] = uint8(color >> 16);
                g.buffer[uint32(bufferOffset + OrderA)] = uint8(color >> 24);
                bufferOffset += 4;
            }
        }
    }

    function renderWithTransform(
        Graphics2D memory g,
        DrawContext memory f,
        VertexData[] memory vertices,        
        bool blend
    ) internal pure {
        if (!MatrixMethods.isIdentity(f.t)) {
            ApplyTransform.applyTransform(vertices, f.t, f.transformed);
        }

        addPath(g, f.transformed, f);
        ScanlineRasterizer.renderSolid(g, f, blend);

        if (!MatrixMethods.isIdentity(f.t)) {
            uint i;
            while(f.transformed[i].command != Command.Stop) {
                f.transformed[i].command = Command.Stop;
                f.transformed[i].position.x = 0;
                f.transformed[i].position.y = 0;
                i++;
            }
        }
    }

    function render(
        Graphics2D memory g,
        DrawContext memory f,
        VertexData[] memory vertices,
        bool blend
    ) internal pure {
        addPath(g, vertices, f);
        ScanlineRasterizer.renderSolid(g, f, blend);
    }

    function getBufferOffsetY(Graphics2D memory g, int32 y)
        internal
        pure
        returns (int32)
    {
        return y * int32(g.width) * 4;
    }

    function getBufferOffsetXy(
        Graphics2D memory g,
        int32 x,
        int32 y
    ) internal pure returns (int32) {
        if (x < 0 || x >= int32(g.width) || y < 0 || y >= int32(g.height))
            return -1;
        return y * int32(g.width) * 4 + x * 4;
    }

    function copyPixels(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor,
        int32 count
        //, PixelClipping memory clipping
    ) internal pure {
        int32 i = 0;
        do {
            /*
            if (
                clipping.area.length > 0 &&
                !PixelClippingMethods.isPointInPolygon(
                    clipping,
                    clipping.x + i,
                    clipping.y
                )
            ) {
                i++;
                bufferOffset += 4;
                continue;
            }
            */

            buffer[uint32(bufferOffset + OrderR)] = uint8(sourceColor >> 16);
            buffer[uint32(bufferOffset + OrderG)] = uint8(sourceColor >> 8);
            buffer[uint32(bufferOffset /*+ OrderB */)] = uint8(sourceColor >> 0);
            buffer[uint32(bufferOffset + OrderA)] = uint8(sourceColor >> 24);
            bufferOffset += 4;
            i++;
        } while (--count != 0);
    }

    function blendPixel(
        uint8[] memory buffer,
        int32 bufferOffset,
        uint32 sourceColor
        //, PixelClipping memory clipping
    ) internal pure {
        if (bufferOffset == -1) return;

        /*
        if (
            clipping.area.length > 0 &&
            !PixelClippingMethods.isPointInPolygon(
                clipping,
                clipping.x,
                clipping.y
            )
        ) {
            return;
        }
        */

        {
            uint8 sr = uint8(sourceColor >> 16);
            uint8 sg = uint8(sourceColor >> 8);
            uint8 sb = uint8(sourceColor >> 0);
            uint8 sa = uint8(sourceColor >> 24);

            unchecked
            {
                if (sourceColor >> 24 == 255)
                {
                    buffer[uint32(bufferOffset + OrderR)] = sr;
                    buffer[uint32(bufferOffset + OrderG)] = sg;
                    buffer[uint32(bufferOffset /*+ OrderB */)] = sb;
                    buffer[uint32(bufferOffset + OrderA)] = sa;
                }
                else
                {
                    uint8 r = buffer[uint32(bufferOffset + OrderR)];
                    uint8 g = buffer[uint32(bufferOffset + OrderG)];
                    uint8 b = buffer[uint32(bufferOffset /*+ OrderB */)];
                    uint8 a = buffer[uint32(bufferOffset + OrderA)];

                    buffer[uint32(bufferOffset + OrderR)] = uint8(int8(int32((((int32(uint32(sr)) - int32(uint32(r))) * int32(uint32(sa))) + (int32(uint32(r)) << 8)) >> 8)));
                    buffer[uint32(bufferOffset + OrderG)] = uint8(int8(int32((((int32(uint32(sg)) - int32(uint32(g))) * int32(uint32(sa))) + (int32(uint32(g)) << 8)) >> 8)));
                    buffer[uint32(bufferOffset /*+ OrderB */)] = uint8(int8(int32((((int32(uint32(sb)) - int32(uint32(b))) * int32(uint32(sa))) + (int32(uint32(b)) << 8)) >> 8)));
                    buffer[uint32(bufferOffset + OrderA)] = uint8(uint32((uint32(sa)) + a - (((uint32(sa)) * a + 255) >> 8)));
                }
            }
        }
    }

    function addPath(Graphics2D memory g, VertexData[] memory vertices, DrawContext memory f)
        private
        pure
    {
        if (g.cellData.sorted) {
            CellRasterizer.resetCells(g.cellData);
            g.scanlineData.status = ScanlineStatus.Initial;
        }

        for (uint32 i = 0; i < vertices.length; i++) {
            
            if (vertices[i].command == Command.Stop) break;
            if (vertices[i].command == Command.MoveTo) {
                g.scanlineData.startX = ClippingDataMethods.upscale(vertices[i].position.x, g.ss);
                g.scanlineData.startY = ClippingDataMethods.upscale(vertices[i].position.y, g.ss);
                Clipping.moveToClip(g.scanlineData.startX, g.scanlineData.startY, g.clippingData);
                g.scanlineData.status = ScanlineStatus.MoveTo;
            } else {
                if (vertices[i].command != Command.Stop && vertices[i].command != Command.EndPoly) {
                    Clipping.lineToClip(g, f, ClippingDataMethods.upscale(vertices[i].position.x, g.ss), ClippingDataMethods.upscale(vertices[i].position.y, g.ss));
                    g.scanlineData.status = ScanlineStatus.LineTo;
                } else {
                    if (vertices[i].command == Command.EndPoly) closePolygon(g, f);
                }
            }
        }
    }

    function closePolygon(Graphics2D memory g, DrawContext memory f) internal pure {
        if (g.scanlineData.status != ScanlineStatus.LineTo) {
            return;
        }
        Clipping.lineToClip(g, f, g.scanlineData.startX, g.scanlineData.startY);
        g.scanlineData.status = ScanlineStatus.Closed;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Bezier.sol";
import "./Star.sol";

struct Parameters {

    uint32 whichMasterSet;
    int32 whichColor;
    int32 endIdx;
    int32 cLen;

    uint8[] myColorsR;
    uint8[] myColorsG;
    uint8[] myColorsB;

    int32[] whichTex;
    int32[] whichColorFlow;
    int32[] whichRot;
    int32[] whichRotDir;       
    
    Vector2[] gridPoints;

    Bezier[] paths;
    uint32 numPaths;

    Star[] starPositions;
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

struct AntiAlias {
    uint32 value;
    uint32 scale;
    uint32 mask;
}

library AntiAliasMethods {
    function create(uint32 sampling)
        external
        pure
        returns (AntiAlias memory aa)
    {
        aa.value = sampling;
        aa.scale = uint32(1) << aa.value;
        aa.mask = aa.scale - 1;
        return aa;
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

struct SubpixelScale {
    uint32 value;
    uint32 scale;
    uint32 mask;
    uint32 dxLimit;
}

library SubpixelScaleMethods {
    function create(uint32 sampling)
        external
        pure
        returns (SubpixelScale memory ss)
    {
        ss.value = sampling;
        ss.scale = uint32(1) << ss.value;
        ss.mask = ss.scale - 1;
        ss.dxLimit = uint32(16384) << ss.value;
        return ss;
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

struct RectangleInt {
    int32 left;
    int32 bottom;
    int32 right;
    int32 top;
}

library RectangleIntMethods {
    function normalize(RectangleInt memory rect) internal pure {
        int32 t;

        if (rect.left > rect.right) {
            t = rect.left;
            rect.left = rect.right;
            rect.right = t;
        }

        if (rect.bottom > rect.top) {
            t = rect.bottom;
            rect.bottom = rect.top;
            rect.top = t;
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

import "./Fix64V1.sol";
import "./Trig256.sol";
import "./MathUtils.sol";
import "./Vector2.sol";

struct Matrix {
    int64 sx;
    int64 shy;
    int64 shx;
    int64 sy;
    int64 tlx;
    int64 tly;
}

library MatrixMethods {
    function newIdentity() internal pure returns (Matrix memory value) {
        value.sx = Fix64V1.ONE;
        value.shy = 0;
        value.shx = 0;
        value.sy = Fix64V1.ONE;
        value.tlx = 0;
        value.tly = 0;
    }

    function newRotation(int64 radians) internal pure returns (Matrix memory) {
        int64 v0 = Trig256.cos(radians);
        int64 v1 = Trig256.sin(radians);
        int64 v2 = -Trig256.sin(radians);
        int64 v3 = Trig256.cos(radians);

        return Matrix(v0, v1, v2, v3, 0, 0);
    }

    function newScale(int64 scale) internal pure returns (Matrix memory) {
        return Matrix(scale, 0, 0, scale, 0, 0);
    }

    function newScale(int64 scaleX, int64 scaleY)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(scaleX, 0, 0, scaleY, 0, 0);
    }

    function newTranslation(int64 x, int64 y)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(Fix64V1.ONE, 0, 0, Fix64V1.ONE, x, y);
    }

    function transform(
        Matrix memory self,
        int64 x,
        int64 y
    ) internal pure returns (int64, int64) {
        int64 tmp = x;
        x = Fix64V1.add(
            Fix64V1.mul(tmp, self.sx),
            Fix64V1.add(Fix64V1.mul(y, self.shx), self.tlx)
        );
        y = Fix64V1.add(
            Fix64V1.mul(tmp, self.shy),
            Fix64V1.add(Fix64V1.mul(y, self.sy), self.tly)
        );
        return (x, y);
    }

    function transform(Matrix memory self, Vector2 memory v)
        internal
        pure
        returns (Vector2 memory result)
    {
        result = v;
        transform(self, result.x, result.y);
        return result;
    }

    function invert(Matrix memory self) internal pure {
        int64 d = Fix64V1.div(
            Fix64V1.ONE,
            Fix64V1.sub(
                Fix64V1.mul(self.sx, self.sy),
                Fix64V1.mul(self.shy, self.shx)
            )
        );

        self.sy = Fix64V1.mul(self.sx, d);
        self.shy = Fix64V1.mul(-self.shy, d);
        self.shx = Fix64V1.mul(-self.shx, d);

        self.tly = Fix64V1.sub(
            Fix64V1.mul(-self.tlx, self.shy),
            Fix64V1.mul(self.tly, self.sy)
        );
        self.sx = Fix64V1.mul(self.sy, d);
        self.tlx = Fix64V1.sub(
            Fix64V1.mul(-self.tlx, Fix64V1.mul(self.sy, d)),
            Fix64V1.mul(self.tly, self.shx)
        );
    }

    function isIdentity(Matrix memory self) internal pure returns (bool) {
        return
            isEqual(self.sx, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.shy, 0, MathUtils.Epsilon) &&
            isEqual(self.shx, 0, MathUtils.Epsilon) &&
            isEqual(self.sy, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.tlx, 0, MathUtils.Epsilon) &&
            isEqual(self.tly, 0, MathUtils.Epsilon);
    }

    function isEqual(
        int64 v1,
        int64 v2,
        int64 epsilon
    ) internal pure returns (bool) {
        return Fix64V1.abs(Fix64V1.sub(v1, v2)) <= epsilon;
    }

    function mul(Matrix memory self, Matrix memory other)
        internal
        pure
        returns (Matrix memory)
    {
        int64 t0 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.sx),
            Fix64V1.mul(self.shy, other.shx)
        );
        int64 t1 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.sx),
            Fix64V1.mul(self.sy, other.shx)
        );
        int64 t2 = Fix64V1.add(
            Fix64V1.mul(self.tlx, other.sx),
            Fix64V1.add(Fix64V1.mul(self.tly, other.shx), other.tlx)
        );
        int64 t3 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.shy),
            Fix64V1.mul(self.shy, other.sy)
        );
        int64 t4 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.shy),
            Fix64V1.mul(self.sy, other.sy)
        );
        int64 t5 = Fix64V1.add(
            Fix64V1.mul(self.tlx, other.shy),
            Fix64V1.add(Fix64V1.mul(self.tly, other.sy), other.tly)
        );

        self.shy = t3;
        self.sy = t4;
        self.tly = t5;
        self.sx = t0;
        self.shx = t1;
        self.tlx = t2;

        return self;
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

import "./ScanlineStatus.sol";
import "./ScanlineSpan.sol";
import "./AntiAlias.sol";

struct ScanlineData {
    int32 scanY;
    int32 startX;
    int32 startY;
    ScanlineStatus status;
    int32 coverIndex;
    uint8[] covers;
    int32 spanIndex;
    ScanlineSpan[] spans;
    int32 current;
    int32 lastX;
    int32 y;
}

library ScanlineDataMethods {
    function create(uint32 width)
        external
        pure
        returns (ScanlineData memory scanlineData)
    {
        scanlineData.startX = 0;
        scanlineData.startY = 0;
        scanlineData.status = ScanlineStatus.Initial;        
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.covers = new uint8[](width + 3);
        scanlineData.spans = new ScanlineSpan[](width + 3);
        return scanlineData;
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

import "./Matrix.sol";
import "./RectangleInt.sol";
import "./SubpixelScale.sol";

struct ClippingData {
    int32 f1;
    int32 x1;
    int32 y1;
    Matrix clipTransform;    
    RectangleInt clipBox;
    bool clipping;
    // Vector2[] clipPoly;
}

library ClippingDataMethods {
    function create(
        uint32 width,
        uint32 height,
        SubpixelScale calldata ss
    ) external pure returns (ClippingData memory clippingData) {
        clippingData.x1 = 0;
        clippingData.y1 = 0;
        clippingData.f1 = 0;
        clippingData.clipBox = RectangleInt(
            0,
            0,
            upscale(int64(int32(width) * Fix64V1.ONE), ss),
            upscale(int64(int32(height) * Fix64V1.ONE), ss)
        );
        RectangleIntMethods.normalize(clippingData.clipBox);
        clippingData.clipping = true;
        return clippingData;
    }

    function upscale(int64 v, SubpixelScale memory ss)
        internal
        pure
        returns (int32)
    {
        return
            int32(
                Fix64V1.round(Fix64V1.mul(v, int32(ss.scale) * Fix64V1.ONE)) /
                    Fix64V1.ONE
            );
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

import "./SortedY.sol"; 
import "./Cell.sol";
import "./CellBlock.sol";

struct CellData {
    CellBlock cb;
    Cell[] cells;
    Cell current;
    uint32 used;
    SortedY[] sortedY;
    Cell[] sortedCells;
    bool sorted;
    Cell style;
    int32 minX;
    int32 maxX;
    int32 minY;
    int32 maxY;
}

library CellDataMethods {
    function create() external pure returns (CellData memory cellData) {
        cellData.cb = CellBlockMethods.create(12);
        cellData.cells = new Cell[](cellData.cb.limit);
        cellData.sortedCells = new Cell[](cellData.cb.limit);
        cellData.sortedY = new SortedY[](2401);
        cellData.sorted = false;
        cellData.style = CellMethods.create();
        cellData.current = CellMethods.create();
        cellData.minX = 0x7FFFFFFF;
        cellData.minY = 0x7FFFFFFF;
        cellData.maxX = -0x7FFFFFFF;
        cellData.maxY = -0x7FFFFFFF;
        return cellData;
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
import "./RectangleInt.sol";
import "./SubpixelScale.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./CellRasterizer.sol";
import "./Graphics2D.sol";
import "./DrawContext.sol";

library Clipping {
    // function noClippingBox(ClippingData memory clippingData) internal pure {
    //     clippingData.clipPoly = new Vector2[](0);
    // }

    function setClippingBox(
        ClippingData memory clippingData
        // ,int32 left,
        // int32 top,
        // int32 right,
        // int32 bottom,
        , Matrix memory transform
        //,int32 height
    ) internal pure {

        /*
        Vector2 memory tl = MatrixMethods.transform(
            transform,
            Vector2(left * Fix64V1.ONE, top * Fix64V1.ONE)
        );
        Vector2 memory tr = MatrixMethods.transform(
            transform,
            Vector2(right * Fix64V1.ONE, top * Fix64V1.ONE)
        );
        Vector2 memory br = MatrixMethods.transform(
            transform,
            Vector2(right * Fix64V1.ONE, bottom * Fix64V1.ONE)
        );
        Vector2 memory bl = MatrixMethods.transform(
            transform,
            Vector2(left * Fix64V1.ONE, bottom * Fix64V1.ONE)
        );
        */

        clippingData.clipTransform = transform;

        // clippingData.clipPoly = new Vector2[](4);
        // clippingData.clipPoly[0] = Vector2(
        //     tl.x,
        //     Fix64V1.sub(height * Fix64V1.ONE, tl.y)
        // );
        // clippingData.clipPoly[1] = Vector2(
        //     tr.x,
        //     Fix64V1.sub(height * Fix64V1.ONE, tr.y)
        // );
        // clippingData.clipPoly[2] = Vector2(
        //     br.x,
        //     Fix64V1.sub(height * Fix64V1.ONE, br.y)
        // );
        // clippingData.clipPoly[3] = Vector2(
        //     bl.x,
        //     Fix64V1.sub(height * Fix64V1.ONE, bl.y)
        // );
    }

    function moveToClip(
        int32 x1,
        int32 y1,
        ClippingData memory clippingData
    ) internal pure {
        clippingData.x1 = x1;
        clippingData.y1 = y1;
        if (clippingData.clipping) {
            clippingData.f1 = clippingFlags(x1, y1, clippingData.clipBox);        
        }
    }

    function lineToClip(
        Graphics2D memory g,
        DrawContext memory f,
        int32 x2,
        int32 y2
    ) internal pure {
        if (g.clippingData.clipping) {
            int32 f2 = clippingFlags(x2, y2, g.clippingData.clipBox);

            if (
                (g.clippingData.f1 & 10) == (f2 & 10) &&
                (g.clippingData.f1 & 10) != 0
            ) {
                g.clippingData.x1 = x2;
                g.clippingData.y1 = y2;
                g.clippingData.f1 = f2;
                return;
            }

            int32 x1 = g.clippingData.x1;
            int32 y1 = g.clippingData.y1;
            int32 f1 = g.clippingData.f1;
            int32 y3;
            int32 y4;
            int32 f3;
            int32 f4;

            if ((((f1 & 5) << 1) | (f2 & 5)) == 0) {
                setLineClipY(f.lineClipY, x1, y1, x2, y2, f1, f2);
                lineClipY(g, f);
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 1) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);

                setLineClipY(f.lineClipY, x1, y1, g.clippingData.clipBox.right, y3, f1, f3);
                lineClipY(g, f);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.right, y3, g.clippingData.clipBox.right, y2, f3, f2);
                lineClipY(g, f);

            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 2) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.right, y1, g.clippingData.clipBox.right, y3, f1, f3);
                lineClipY(g, f);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.right, y3, x2, y2, f3, f2);
                lineClipY(g, f);

            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 3) {

                setLineClipY(f.lineClipY, g.clippingData.clipBox.right, y1, g.clippingData.clipBox.right, y2, f1, f2);
                lineClipY(g, f);
                
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 4) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);

                setLineClipY(f.lineClipY, x1, y1, g.clippingData.clipBox.left, y3, f1, f3);
                lineClipY(g, f);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.left, y3, g.clippingData.clipBox.left, y2, f3, f2);
                lineClipY(g, f);
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 6) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                y4 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                f4 = clippingFlagsY(y4, g.clippingData.clipBox);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.right, y1, g.clippingData.clipBox.right, y3, f1, f3);
                lineClipY(g, f);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.right, y3, g.clippingData.clipBox.left, y4, f3, f4);
                lineClipY(g, f);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.left, y4, g.clippingData.clipBox.left, y2, f4, f2);
                lineClipY(g, f);
                
            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 8) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                f3 = clippingFlagsY(y3, g.clippingData.clipBox);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.left, y1, g.clippingData.clipBox.left, y3, f1, f3);
                lineClipY(g, f);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.left, y3, x2, y2, f3, f2);
                lineClipY(g, f);

            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 9) {
                y3 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.left - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );

                y4 =
                    y1 +
                    mulDiv(
                        (g.clippingData.clipBox.right - x1) * Fix64V1.ONE,
                        (y2 - y1) * Fix64V1.ONE,
                        (x2 - x1) * Fix64V1.ONE
                    );
                f3 = clippingFlagsY(y3, g.clippingData.clipBox);
                f4 = clippingFlagsY(y4, g.clippingData.clipBox);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.left, y1, g.clippingData.clipBox.left, y3, f1, f3);
                lineClipY(g, f);
                
                setLineClipY(f.lineClipY, g.clippingData.clipBox.left, y3, g.clippingData.clipBox.right, y4, f3, f4);
                lineClipY(g, f);

                setLineClipY(f.lineClipY, g.clippingData.clipBox.right, y4, g.clippingData.clipBox.right, y2, f4, f2);
                lineClipY(g, f);

            } else if ((((f1 & 5) << 1) | (f2 & 5)) == 12) {
                
                setLineClipY(f.lineClipY, g.clippingData.clipBox.left, y1, g.clippingData.clipBox.left, y2, f1, f2);
                lineClipY(g, f);
            }

            g.clippingData.f1 = f2;
        } else {
            f.line.x1 = g.clippingData.x1;
            f.line.y1 =  g.clippingData.y1;
            f.line.x2 = x2;
            f.line.y2 = y2;
            CellRasterizer.line(f, f.line, g.cellData, g.ss);
        }

        g.clippingData.x1 = x2;
        g.clippingData.y1 = y2;
    }

    function setLineClipY(LineClipY memory l, int32 x1, int32 y1, int32 x2, int32 y2, int32 f1, int32 f2) private pure {
        l.x1 = x1;
        l.y1 = y1;
        l.x2 = x2;
        l.y2 = y2;
        l.f1 = f1;
        l.f2 = f2;
    }

    function lineClipY(Graphics2D memory g, DrawContext memory f) private pure {
        f.lineClipY.f1 &= 10;
        f.lineClipY.f2 &= 10;
        if ((f.lineClipY.f1 | f.lineClipY.f2) == 0) {
            f.line.x1 = f.lineClipY.x1;
            f.line.y1 = f.lineClipY.y1;
            f.line.x2 = f.lineClipY.x2;
            f.line.y2 = f.lineClipY.y2;
            CellRasterizer.line(f, f.line, g.cellData, g.ss);
        } else {
            if (f.lineClipY.f1 == f.lineClipY.f2)
                return;

            int32 tx1 = f.lineClipY.x1;
            int32 ty1 = f.lineClipY.y1;
            int32 tx2 = f.lineClipY.x2;
            int32 ty2 = f.lineClipY.y2;

            if ((f.lineClipY.f1 & 8) != 0)
            {
                tx1 =
                    f.lineClipY.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.bottom - f.lineClipY.y1) * Fix64V1.ONE,
                        (f.lineClipY.x2 - f.lineClipY.x1) * Fix64V1.ONE,
                        (f.lineClipY.y2 - f.lineClipY.y1) * Fix64V1.ONE
                    );

                ty1 = g.clippingData.clipBox.bottom;
            }

            if ((f.lineClipY.f1 & 2) != 0)
            {
                tx1 =
                    f.lineClipY.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.top - f.lineClipY.y1) * Fix64V1.ONE,
                        (f.lineClipY.x2 - f.lineClipY.x1) * Fix64V1.ONE,
                        (f.lineClipY.y2 - f.lineClipY.y1) * Fix64V1.ONE
                    );

                ty1 = g.clippingData.clipBox.top;
            }

            if ((f.lineClipY.f2 & 8) != 0)
            {
                tx2 =
                    f.lineClipY.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.bottom - f.lineClipY.y1) * Fix64V1.ONE,
                        (f.lineClipY.x2 - f.lineClipY.x1) * Fix64V1.ONE,
                        (f.lineClipY.y2 - f.lineClipY.y1) * Fix64V1.ONE
                    );

                ty2 = g.clippingData.clipBox.bottom;
            }

            if ((f.lineClipY.f2 & 2) != 0)
            {
                tx2 =
                    f.lineClipY.x1 +
                    mulDiv(
                        (g.clippingData.clipBox.top - f.lineClipY.y1) * Fix64V1.ONE,
                        (f.lineClipY.x2 - f.lineClipY.x1) * Fix64V1.ONE,
                        (f.lineClipY.y2 - f.lineClipY.y1) * Fix64V1.ONE
                    );

                ty2 = g.clippingData.clipBox.top;
            }

            f.line.x1 = tx1;
            f.line.y1 = ty1;
            f.line.x2 = tx2;
            f.line.y2 = ty2;
            CellRasterizer.line(f, f.line, g.cellData, g.ss);
        }
    }

    function clippingFlags(
        int32 x,
        int32 y,
        RectangleInt memory clipBox
    ) private pure returns (int32) {
        return
            (x > clipBox.right ? int32(1) : int32(0)) |
            (y > clipBox.top ? int32(1) << 1 : int32(0)) |
            (x < clipBox.left ? int32(1) << 2 : int32(0)) |
            (y < clipBox.bottom ? int32(1) << 3 : int32(0));
    }

    function clippingFlagsY(int32 y, RectangleInt memory clipBox)
        private
        pure
        returns (int32)
    {
        return
            ((y > clipBox.top ? int32(1) : int32(0)) << 1) |
            ((y < clipBox.bottom ? int32(1) : int32(0)) << 3);
    }

    function mulDiv(
        int64 a,
        int64 b,
        int64 c
    ) private pure returns (int32) {
        int64 div = Fix64V1.div(b, c);
        int64 muldiv = Fix64V1.mul(a, div);
        return (int32)(Fix64V1.round(muldiv) / Fix64V1.ONE);
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

import "./Vector2.sol";
import "./Fix64V1.sol";

struct PixelClipping {
    Vector2[] area;
    int32 x;
    int32 y;
}

library PixelClippingMethods {
    function isPointInPolygon(
        PixelClipping memory self,
        int32 px,
        int32 py
    ) internal pure returns (bool) {
        if (self.area.length < 3) {
            return false;
        }

        Vector2 memory oldPoint = self.area[self.area.length - 1];

        bool inside = false;

        for (uint256 i = 0; i < self.area.length; i++) {
            Vector2 memory newPoint = self.area[i];

            Vector2 memory p2;
            Vector2 memory p1;

            if (newPoint.x > oldPoint.x) {
                p1 = oldPoint;
                p2 = newPoint;
            } else {
                p1 = newPoint;
                p2 = oldPoint;
            }

            int64 pxF = px * Fix64V1.ONE;
            int64 pyF = py * Fix64V1.ONE;

            int64 t1 = Fix64V1.sub(pyF, p1.y);
            int64 t2 = Fix64V1.sub(p2.x, p1.x);
            int64 t3 = Fix64V1.sub(p2.y, p1.y);
            int64 t4 = Fix64V1.sub(pxF, p1.x);

            if (
                newPoint.x < pxF == pxF <= oldPoint.x &&
                Fix64V1.mul(t1, t2) < Fix64V1.mul(t3, t4)
            ) inside = !inside;

            oldPoint = newPoint;
        }

        return inside;
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

library ColorMath {
    function toColor(
        uint8 a,
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint32) {
        uint32 c;
        c |= uint32(a) << 24;
        c |= uint32(r) << 16;
        c |= uint32(g) << 8;
        c |= uint32(b) << 0;
        return c & 0xffffffff;
    }

    function lerp(
        uint32 s,
        uint32 t,
        int64 k
    ) internal pure returns (uint32) {
        int64 bk = Fix64V1.sub(Fix64V1.ONE, k);

        int64 a = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 24))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 24))) * Fix64V1.ONE, k)
        );
        int64 r = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 16))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 16))) * Fix64V1.ONE, k)
        );
        int64 g = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 8))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 8))) * Fix64V1.ONE, k)
        );
        int64 b = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 0))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 0))) * Fix64V1.ONE, k)
        );

        int32 ra = (int32(a / Fix64V1.ONE) << 24);
        int32 rr = (int32(r / Fix64V1.ONE) << 16);
        int32 rg = (int32(g / Fix64V1.ONE) << 8);
        int32 rb = (int32(b / Fix64V1.ONE));

        int32 x = ra | rr | rg | rb;
        return uint32(x) & 0xffffffff;
    }

    function tint(uint32 targetColor, uint32 tintColor)
        internal
        pure
        returns (uint32 newColor)
    {
        uint8 a = (uint8)(targetColor >> 24);
        uint8 r = (uint8)(targetColor >> 16);
        uint8 g = (uint8)(targetColor >> 8);
        uint8 b = (uint8)(targetColor >> 0);

        if (a != 0 && r == 0 && g == 0 && b == 0) {
            return targetColor;
        }

        uint8 tr = (uint8)(tintColor >> 16);
        uint8 tg = (uint8)(tintColor >> 8);
        uint8 tb = (uint8)(tintColor >> 0);

        uint32 tinted = toColor(a, tr, tg, tb);
        return tinted;
    }
}

// SPDX-License-Identifier: MIT
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

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
import "./Matrix.sol";

library ApplyTransform {
    function applyTransform(
        VertexData[] memory vertices,
        Matrix memory transform,
        VertexData[] memory transformed
    ) internal pure  {
        for (uint32 i = 0; i < vertices.length; i++) {            
            if (
                vertices[i].command != Command.Stop &&
                vertices[i].command != Command.EndPoly
            ) {
                (int64 x, int64 y) = MatrixMethods.transform(
                    transform,
                    vertices[i].position.x,
                    vertices[i].position.y
                );                
                transformed[i].command = vertices[i].command;
                transformed[i].position.x = x;
                transformed[i].position.y = y;
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

import "./SubpixelScale.sol";
import "./ScanlineData.sol";
import "./ClippingData.sol";
import "./CellData.sol";
import "./Graphics2D.sol";
import "./CellRasterizer.sol";
import "./ColorMath.sol";
import "./PixelClipping.sol";
import "./Clipping.sol";
import "./DrawContext.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

library ScanlineRasterizer {
    function renderSolid(
        Graphics2D memory g,
        DrawContext memory f,
        bool blend
    ) internal pure {

        Graphics2DMethods.closePolygon(g, f);        
        CellRasterizer.sortCells(g.cellData);
        if (g.cellData.used == 0) return;
        g.scanlineData.scanY = g.cellData.minY;

        resetScanline(g.scanlineData);
      
        while (sweepScanline(g, f.current)) {
            int32 y = g.scanlineData.y;
            int32 spanCount = g.scanlineData.spanIndex;

            g.scanlineData.current = 1;
            g.scanlineData.current++;
            f.scanlineSpan = g.scanlineData.spans[uint32(g.scanlineData.current - 1)];

            for (;;) {
                int32 x = f.scanlineSpan.x;
                if (f.scanlineSpan.length > 0) {

                    f.blendSolidHorizontalSpan.x = x;
                    f.blendSolidHorizontalSpan.y = y;
                    f.blendSolidHorizontalSpan.len = f.scanlineSpan.length;
                    f.blendSolidHorizontalSpan.sourceColor = f.color;
                    f.blendSolidHorizontalSpan.covers = g.scanlineData.covers;
                    f.blendSolidHorizontalSpan.coversIndex = f.scanlineSpan.coverIndex;
                    f.blendSolidHorizontalSpan.blend = blend;
                    blendSolidHorizontalSpan(g, f.blendSolidHorizontalSpan);

                } else {
                    int32 x2 = x - f.scanlineSpan.length - 1;

                    f.blendHorizontalLine.x1 = x;
                    f.blendHorizontalLine.y = y;
                    f.blendHorizontalLine.x2 = x2;
                    f.blendHorizontalLine.sourceColor = f.color;
                    f.blendHorizontalLine.cover = g.scanlineData.covers[uint32(f.scanlineSpan.coverIndex)];
                    f.blendHorizontalLine.blend = blend;                    
                    blendHorizontalLine(g, f.blendHorizontalLine);
                }

                if (--spanCount == 0) break;
                g.scanlineData.current++;
                f.scanlineSpan = g.scanlineData.spans[uint32(g.scanlineData.current - 1)];
            }
        }
    }

    function sweepScanline(Graphics2D memory g, Cell memory current) private pure returns (bool) {
        for (;;) {
            if (g.scanlineData.scanY > g.cellData.maxY) return false;

            resetSpans(g.scanlineData);
            int32 cellCount = g
                .cellData
                .sortedY[uint32(g.scanlineData.scanY - g.cellData.minY)]
                .count;

            int32 offset = g
                .cellData
                .sortedY[uint32(g.scanlineData.scanY - g.cellData.minY)]
                .start;
            int32 cover = 0;

            while (cellCount != 0) {
                current = g.cellData.sortedCells[uint32(offset)];
                int32 x = current.x;
                int32 area = current.area;
                int32 alpha;

                cover += current.cover;

                while (--cellCount != 0) {
                    offset++;
                    current = g.cellData.sortedCells[uint32(offset)];
                    if (current.x != x) break;

                    area += current.area;
                    cover += current.cover;
                }

                if (area != 0) {
                    alpha = calculateAlpha(
                        g,
                        (cover << (g.ss.value + 1)) - area
                    );
                    if (alpha != 0) {
                        addCell(g.scanlineData, x, alpha);
                    }
                    x++;
                }

                if (cellCount != 0 && current.x > x) {
                    alpha = calculateAlpha(g, cover << (g.ss.value + 1));
                    if (alpha != 0) {
                        addSpan(g.scanlineData, x, current.x - x, alpha);
                    }
                }
            }

            if (g.scanlineData.spanIndex != 0) break;
            ++g.scanlineData.scanY;
        }

        g.scanlineData.y = g.scanlineData.scanY;
        ++g.scanlineData.scanY;
        return true;
    }

    function calculateAlpha(Graphics2D memory g, int32 area)
        private
        pure
        returns (int32)
    {
        int32 cover = area >> (g.ss.value * 2 + 1 - g.aa.value);
        if (cover < 0) cover = -cover;
        if (cover > int32(g.aa.mask)) cover = int32(g.aa.mask);
        return cover;
    }

    function addSpan(
        ScanlineData memory scanlineData,
        int32 x,
        int32 len,
        int32 cover
    ) private pure {
        if (
            x == scanlineData.lastX + 1 &&
            scanlineData.spans[uint32(scanlineData.spanIndex)].length < 0 &&
            cover ==
            scanlineData.spans[uint32(scanlineData.spanIndex)].coverIndex
        ) {
            scanlineData.spans[uint32(scanlineData.spanIndex)].length -= int16(
                len
            );
        } else {
            scanlineData.covers[uint32(scanlineData.coverIndex)] = uint8(
                uint32(cover)
            );
            scanlineData.spanIndex++;
            scanlineData
                .spans[uint32(scanlineData.spanIndex)]
                .coverIndex = scanlineData.coverIndex++;
            scanlineData.spans[uint32(scanlineData.spanIndex)].x = int16(x);
            scanlineData.spans[uint32(scanlineData.spanIndex)].length = int16(
                -len
            );
        }

        scanlineData.lastX = x + len - 1;
    }

    function addCell(
        ScanlineData memory scanlineData,
        int32 x,
        int32 cover
    ) private pure {
        scanlineData.covers[uint32(scanlineData.coverIndex)] = uint8(
            uint32(cover)
        );
        if (
            x == scanlineData.lastX + 1 &&
            scanlineData.spans[uint32(scanlineData.spanIndex)].length > 0
        ) {
            scanlineData.spans[uint32(scanlineData.spanIndex)].length++;
        } else {
            scanlineData.spanIndex++;
            scanlineData
                .spans[uint32(scanlineData.spanIndex)]
                .coverIndex = scanlineData.coverIndex;
            scanlineData.spans[uint32(scanlineData.spanIndex)].x = int16(x);
            scanlineData.spans[uint32(scanlineData.spanIndex)].length = 1;
        }
        scanlineData.lastX = x;
        scanlineData.coverIndex++;
    }

    function resetSpans(ScanlineData memory scanlineData) private pure {
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.coverIndex = 0;
        scanlineData.spanIndex = 0;
        scanlineData.spans[uint32(scanlineData.spanIndex)].length = 0;
    }

    function resetScanline(
        ScanlineData memory scanlineData
    ) private pure {
        scanlineData.lastX = 0x7FFFFFF0;
        scanlineData.coverIndex = 0;
        scanlineData.spanIndex = 0;
        scanlineData.spans[uint32(scanlineData.spanIndex)].length = 0;
    }

    function blendSolidHorizontalSpan(
        Graphics2D memory g,
        BlendSolidHorizontalSpan memory f
    ) private pure {
        int32 colorAlpha = (int32)(f.sourceColor >> 24);

        if (colorAlpha != 0) {
            unchecked {
                int32 bufferOffset = Graphics2DMethods.getBufferOffsetXy(
                    g,
                    f.x,
                    f.y
                );
                if (bufferOffset == -1) return;

                int32 i = 0;
                do {
                    int32 alpha = !f.blend
                        ? colorAlpha
                        : (colorAlpha *
                            (
                                int32(
                                    uint32(f.covers[uint32(f.coversIndex)]) + 1
                                )
                            )) >> 8;

                    if (alpha == 255) {
                        Graphics2DMethods.copyPixels(
                            g.buffer,
                            bufferOffset,
                            f.sourceColor,
                            1
                            // , g.clippingData.clipPoly.length == 0
                            //     ? PixelClipping(new Vector2[](0), 0, 0)
                            //     : PixelClipping(
                            //         g.clippingData.clipPoly,
                            //         f.x + i,
                            //         f.y
                            //     )
                        );
                    } else {
                        uint32 targetColor = ColorMath.toColor(
                            uint8(uint32(alpha)),
                            uint8(f.sourceColor >> 16),
                            uint8(f.sourceColor >> 8),
                            uint8(f.sourceColor >> 0)
                        );

                        Graphics2DMethods.blendPixel(
                            g.buffer,
                            bufferOffset,
                            targetColor
                            // , g.clippingData.clipPoly.length == 0
                            //     ? PixelClipping(new Vector2[](0), 0, 0)
                            //     : PixelClipping(
                            //         g.clippingData.clipPoly,
                            //         f.x + i,
                            //         f.y
                            //     )
                        );
                    }

                    bufferOffset += 4;
                    f.coversIndex++;
                    i++;
                } while (--f.len != 0);
            }
        }
    }

    function blendHorizontalLine(
        Graphics2D memory g,
        BlendHorizontalLine memory f
    ) private pure {
        int32 colorAlpha = (int32)(f.sourceColor >> 24);

        if (colorAlpha != 0) {
            int32 len = f.x2 - f.x1 + 1;
            int32 bufferOffset = Graphics2DMethods.getBufferOffsetXy(
                g,
                f.x1,
                f.y
            );
            int32 alpha = !f.blend
                ? colorAlpha
                : (colorAlpha * (int32(uint32(f.cover)) + 1)) >> 8;

            if (alpha == 255) {
                Graphics2DMethods.copyPixels(
                    g.buffer,
                    bufferOffset,
                    f.sourceColor,
                    len
                    // , g.clippingData.clipPoly.length == 0
                    //     ? PixelClipping(new Vector2[](0), 0, 0)
                    //     : PixelClipping(g.clippingData.clipPoly, f.x1, f.y)
                );
            } else {
                int32 i = 0;

                uint32 targetColor = ColorMath.toColor(
                    uint8(uint32(alpha)),
                    uint8(f.sourceColor >> 16),
                    uint8(f.sourceColor >> 8),
                    uint8(f.sourceColor >> 0)
                );

                do {
                    Graphics2DMethods.blendPixel(
                        g.buffer,
                        bufferOffset,
                        targetColor
                        // , g.clippingData.clipPoly.length == 0
                        //     ? PixelClipping(new Vector2[](0), 0, 0)
                        //     : PixelClipping(
                        //         g.clippingData.clipPoly,
                        //         f.x1 + i,
                        //         f.y
                        //     )
                    );

                    bufferOffset += 4;
                    i++;
                } while (--len != 0);
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

import "./LineClipY.sol";
import "./Line.sol";
import "./LineArgs.sol";
import "./RenderHorizontalLine.sol";
import "./RenderHorizontalLineArgs.sol";
import "./VertexData.sol";
import "./Matrix.sol";
import "./ScanlineSpan.sol";
import "./Cell.sol";
import "./BlendSolidHorizontalSpan.sol";
import "./BlendHorizontalLine.sol";

struct DrawContext
{
    LineClipY lineClipY;
    Line line;
    Line lineRecursive;
    LineArgs lineArgs;
    RenderHorizontalLine horizontalLine;
    RenderHorizontalLineArgs horizontalLineArgs;    
    BlendHorizontalLine blendHorizontalLine;
    BlendSolidHorizontalSpan blendSolidHorizontalSpan;
    Matrix t;
    VertexData[] transformed;
    uint32 color;
    uint32 tint;
    ScanlineSpan scanlineSpan;
    Cell current;
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

import "./Fix64V1.sol";
import "./Trig256.sol";

library MathUtils {
    int32 public constant RecursionLimit = 32;
    int64 public constant AngleTolerance = 42949672; /* 0.01 */
    int64 public constant Epsilon = 4; /* 0.000000001 */

    function calcSquareDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        return Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy));
    }

    function calcDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        int64 distance = Trig256.sqrt(
            Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy))
        );
        return distance;
    }

    function crossProduct(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2,
        int64 x,
        int64 y
    ) internal pure returns (int64) {
        return
            Fix64V1.sub(
                Fix64V1.mul(Fix64V1.sub(x, x2), Fix64V1.sub(y2, y1)),
                Fix64V1.mul(Fix64V1.sub(y, y2), Fix64V1.sub(x2, x1))
            );
    }

    struct CalcIntersection {
        int64 aX1;
        int64 aY1;
        int64 aX2;
        int64 aY2;
        int64 bX1;
        int64 bY1;
        int64 bX2;
        int64 bY2;
    }

    function calcIntersection(CalcIntersection memory f)
        internal
        pure
        returns (
            int64 x,
            int64 y,
            bool
        )
    {
        int64 num = Fix64V1.mul(
            Fix64V1.sub(f.aY1, f.bY1),
            Fix64V1.sub(f.bX2, f.bX1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aX1, f.bX1), Fix64V1.sub(f.bY2, f.bY1));
        int64 den = Fix64V1.mul(
            Fix64V1.sub(f.aX2, f.aX1),
            Fix64V1.sub(f.bY2, f.bY1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aY2, f.aY1), Fix64V1.sub(f.bX2, f.bX1));

        if (Fix64V1.abs(den) < Epsilon) {
            x = 0;
            y = 0;
            return (x, y, false);
        }

        int64 r = Fix64V1.div(num, den);
        x = Fix64V1.add(f.aX1, Fix64V1.mul(r, Fix64V1.sub(f.aX2, f.aX1)));
        y = Fix64V1.add(f.aY1, Fix64V1.mul(r, Fix64V1.sub(f.aY2, f.aY1)));
        return (x, y, true);
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

enum ScanlineStatus {
    Initial,
    MoveTo,
    LineTo,
    Closed
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

struct ScanlineSpan {
    int32 x;
    int32 length;
    int32 coverIndex;
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

struct SortedY {
    int32 start;
    int32 count;
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

struct Cell {
    int32 x;
    int32 y;
    int32 cover;
    int32 area;
    int32 left;
    int32 right;
}

library CellMethods {
    function create() internal pure returns (Cell memory cell) {
        reset(cell);        
    }

    function reset(Cell memory cell) internal pure {
        cell.x = 0x7FFFFFFF;
        cell.y = 0x7FFFFFFF;
        cell.cover = 0;
        cell.area = 0;
        cell.left = -1;
        cell.right = -1;
    }    

    function set(Cell memory cell, Cell memory other) internal pure {
        cell.x = other.x;
        cell.y = other.y;
        cell.cover = other.cover;
        cell.area = other.area;
        cell.left = other.left;
        cell.right = other.right;
    }

    function style(Cell memory self, Cell memory other) internal pure {
        self.left = other.left;
        self.right = other.right;
    }

    function notEqual(
        Cell memory self,
        int32 ex,
        int32 ey,
        Cell memory other
    ) internal pure returns (bool) {
        unchecked {
            return
                ((ex - self.x) |
                    (ey - self.y) |
                    (self.left - other.left) |
                    (self.right - other.right)) != 0;
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

struct CellBlock {
    uint32 shift;
    uint32 size;
    uint32 mask;
    uint32 limit;
}

library CellBlockMethods {
    function create(uint32 sampling)
        external
        pure
        returns (CellBlock memory cb)
    {
        cb.shift = sampling;
        cb.size = uint32(1) << cb.shift;
        cb.mask = cb.size - 1;
        cb.limit = cb.size * 2;
        return cb;
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

import "./CellData.sol";
import "./SubpixelScale.sol";
import "./Graphics2D.sol";

library CellRasterizer {
    function resetCells(CellData memory cellData)
        internal
        pure
    {
        cellData.used = 0;
        CellMethods.reset(cellData.style);
        CellMethods.reset(cellData.current);
        cellData.sorted = false;

        cellData.minX = cellData.minY = type(int32).max;
        cellData.maxX = cellData.maxY = type(int32).min;
    }
    
    function line(DrawContext memory c, Line memory f, CellData memory cellData, SubpixelScale memory ss) internal pure {

        c.lineArgs.dx = f.x2 - f.x1;

        if (c.lineArgs.dx >= int32(ss.dxLimit) || c.lineArgs.dx <= -int32(ss.dxLimit)) {
            int32 cx = (f.x1 + f.x2) >> 1;
            int32 cy = (f.y1 + f.y2) >> 1;

            c.lineRecursive.x1 = f.x1;
            c.lineRecursive.y1 = f.y1;
            c.lineRecursive.x2 = cx;
            c.lineRecursive.y2 = cy;
            line(c, c.lineRecursive, cellData, ss);

            c.lineRecursive.x1 = cx;
            c.lineRecursive.y1 = cy;
            c.lineRecursive.x2 = f.x2;
            c.lineRecursive.y2 = f.y2;
            line(c, c.lineRecursive, cellData, ss);
        }

        c.lineArgs.dy = f.y2 - f.y1;
        c.lineArgs.ex1 = f.x1 >> ss.value;
        c.lineArgs.ex2 = f.x2 >> ss.value;
        c.lineArgs.ey1 = f.y1 >> ss.value;
        c.lineArgs.ey2 = f.y2 >> ss.value;
        c.lineArgs.fy1 = f.y1 & int32(ss.mask);
        c.lineArgs.fy2 = f.y2 & int32(ss.mask);

        {
            if (c.lineArgs.ex1 < cellData.minX) cellData.minX = c.lineArgs.ex1;
            if (c.lineArgs.ex1 > cellData.maxX) cellData.maxX = c.lineArgs.ex1;
            if (c.lineArgs.ey1 < cellData.minY) cellData.minY = c.lineArgs.ey1;
            if (c.lineArgs.ey1 > cellData.maxY) cellData.maxY = c.lineArgs.ey1;
            if (c.lineArgs.ex2 < cellData.minX) cellData.minX = c.lineArgs.ex2;
            if (c.lineArgs.ex2 > cellData.maxX) cellData.maxX = c.lineArgs.ex2;
            if (c.lineArgs.ey2 < cellData.minY) cellData.minY = c.lineArgs.ey2;
            if (c.lineArgs.ey2 > cellData.maxY) cellData.maxY = c.lineArgs.ey2;

            setCurrentCell(c.lineArgs.ex1, c.lineArgs.ey1, cellData);

            if (c.lineArgs.ey1 == c.lineArgs.ey2) {
                
                c.horizontalLine.ey = c.lineArgs.ey1;
                c.horizontalLine.x1 = f.x1;
                c.horizontalLine.y1 = c.lineArgs.fy1;
                c.horizontalLine.x2 = f.x2;
                c.horizontalLine.y2 = c.lineArgs.fy2;

                renderHorizontalLine(c.horizontalLine, c.horizontalLineArgs, cellData, ss);
                return;
            }
        }

        c.lineArgs.incr = 1;

        if (c.lineArgs.dx == 0) {
            int32 ex = f.x1 >> ss.value;
            int32 twoFx = (f.x1 - (ex << ss.value)) << 1;

            c.lineArgs.first = int32(ss.scale);
            if (c.lineArgs.dy < 0) {
                c.lineArgs.first = 0;
                c.lineArgs.incr = -1;
            }

            c.lineArgs.delta = c.lineArgs.first - c.lineArgs.fy1;
            cellData.current.cover += c.lineArgs.delta;
            cellData.current.area += twoFx * c.lineArgs.delta;

            c.lineArgs.ey1 += c.lineArgs.incr;
            setCurrentCell(ex, c.lineArgs.ey1, cellData);

            c.lineArgs.delta = c.lineArgs.first + c.lineArgs.first - int32(ss.scale);
            int32 area = twoFx * c.lineArgs.delta;
            while (c.lineArgs.ey1 != c.lineArgs.ey2) {
                cellData.current.cover = c.lineArgs.delta;
                cellData.current.area = area;
                c.lineArgs.ey1 += c.lineArgs.incr;
                setCurrentCell(ex, c.lineArgs.ey1, cellData);
            }

            c.lineArgs.delta = c.lineArgs.fy2 - int32(ss.scale) + c.lineArgs.first;
            cellData.current.cover += c.lineArgs.delta;
            cellData.current.area += twoFx * c.lineArgs.delta;
            return;
        }

        int32 p = (int32(ss.scale) - c.lineArgs.fy1) * c.lineArgs.dx;
        c.lineArgs.first = int32(ss.scale);

        if (c.lineArgs.dy < 0) {
            p = c.lineArgs.fy1 * c.lineArgs.dx;
            c.lineArgs.first = 0;
            c.lineArgs.incr = -1;
            c.lineArgs.dy = -c.lineArgs.dy;
        }

        c.lineArgs.delta = p / c.lineArgs.dy;
        int32 mod = p % c.lineArgs.dy;

        if (mod < 0) {
            c.lineArgs.delta--;
            mod += c.lineArgs.dy;
        }

        int32 xFrom = f.x1 + c.lineArgs.delta;

        c.horizontalLine.ey = c.lineArgs.ey1;
        c.horizontalLine.x1 = f.x1;
        c.horizontalLine.y1 = c.lineArgs.fy1;
        c.horizontalLine.x2 = xFrom;
        c.horizontalLine.y2 = c.lineArgs.first;
        renderHorizontalLine(c.horizontalLine, c.horizontalLineArgs, cellData, ss);

        c.lineArgs.ey1 += c.lineArgs.incr;
        setCurrentCell(xFrom >> ss.value, c.lineArgs.ey1, cellData);

        if (c.lineArgs.ey1 != c.lineArgs.ey2) {
            p = int32(ss.scale) * c.lineArgs.dx;
            int32 lift = p / c.lineArgs.dy;
            int32 rem = p % c.lineArgs.dy;

            if (rem < 0) {
                lift--;
                rem += c.lineArgs.dy;
            }

            mod -= c.lineArgs.dy;

            while (c.lineArgs.ey1 != c.lineArgs.ey2) {
                c.lineArgs.delta = lift;
                mod += rem;
                if (mod >= 0) {
                    mod -= c.lineArgs.dy;
                    c.lineArgs.delta++;
                }

                int32 xTo = xFrom + c.lineArgs.delta;

                c.horizontalLine.ey = c.lineArgs.ey1;
                c.horizontalLine.x1 = xFrom;
                c.horizontalLine.y1 = int32(ss.scale) - c.lineArgs.first;
                c.horizontalLine.x2 = xTo;
                c.horizontalLine.y2 = c.lineArgs.first;

                renderHorizontalLine(c.horizontalLine, c.horizontalLineArgs, cellData, ss);
                xFrom = xTo;

                c.lineArgs.ey1 += c.lineArgs.incr;
                setCurrentCell(xFrom >> ss.value, c.lineArgs.ey1, cellData);
            }
        }

        c.horizontalLine.ey = c.lineArgs.ey1;
        c.horizontalLine.x1 = xFrom;
        c.horizontalLine.y1 = int32(ss.scale) - c.lineArgs.first;
        c.horizontalLine.x2 = f.x2;
        c.horizontalLine.y2 = c.lineArgs.fy2;
        renderHorizontalLine(c.horizontalLine, c.horizontalLineArgs, cellData, ss);
    }

    function sortCells(CellData memory cellData) internal pure {
        if (cellData.sorted) return;

        addCurrentCell(cellData);

        cellData.current.x = 0x7FFFFFFF;
        cellData.current.y = 0x7FFFFFFF;
        cellData.current.cover = 0;
        cellData.current.area = 0;

        if (cellData.used == 0) return;

        uint32 sortedYSize = uint32(uint32(cellData.maxY) - uint32(cellData.minY) + 1);

        for (uint32 i = 0; i < sortedYSize; i++) {
            cellData.sortedY[i].start = 0;
            cellData.sortedY[i].count = 0;
        }

        for (uint32 i = 0; i < cellData.used; i++)
        {
            int32 index = cellData.cells[i].y - cellData.minY;
            cellData.sortedY[uint32(index)].start++;
        }

        int32 start = 0;
        for (uint32 i = 0; i < sortedYSize; i++)
        {
            int32 v = cellData.sortedY[i].start;
            cellData.sortedY[i].start = start;
            start += v;
        }

        for (uint32 i = 0; i < cellData.used; i++)
        {
            int32 index = cellData.cells[i].y - cellData.minY;
            int32 currentYStart = cellData.sortedY[uint32(index)].start;
            int32 currentYCount = cellData.sortedY[uint32(index)].count;
            cellData.sortedCells[uint32(currentYStart) + uint32(currentYCount)] = cellData.cells[i];
            ++cellData.sortedY[uint32(index)].count;
        }

        for (uint32 i = 0; i < sortedYSize; i++)
            if (cellData.sortedY[i].count != 0)
                sort(cellData.sortedCells, cellData.sortedY[i].start,
                    cellData.sortedY[i].start + cellData.sortedY[i].count - 1);

        cellData.sorted = true;
    }

    function renderHorizontalLine(        
        RenderHorizontalLine memory f,
        RenderHorizontalLineArgs memory a,
        CellData memory cellData,
        SubpixelScale memory ss
    ) private pure {
        
        a.ex1 = f.x1 >> ss.value;
        a.ex2 = f.x2 >> ss.value;
        a.fx1 = f.x1 & int32(ss.mask);
        a.fx2 = f.x2 & int32(ss.mask);
        a.delta = 0;

        if (f.y1 == f.y2) {
            setCurrentCell(a.ex2, f.ey, cellData);
            return;
        }

        if (a.ex1 == a.ex2) {
            a.delta = f.y2 - f.y1;
            cellData.current.cover += a.delta;
            cellData.current.area += (a.fx1 + a.fx2) * a.delta;
            return;
        }

        int32 p = (int32(ss.scale) - a.fx1) * (f.y2 - f.y1);
        int32 first = int32(ss.scale);
        int32 incr = 1;
        int32 dx = f.x2 - f.x1;

        if (dx < 0) {
            p = a.fx1 * (f.y2 - f.y1);
            first = 0;
            incr = -1;
            dx = -dx;
        }

        a.delta = p / dx;
        int32 mod = p % dx;

        if (mod < 0) {
            a.delta--;
            mod += dx;
        }

        cellData.current.cover += a.delta;
        cellData.current.area += (a.fx1 + first) * a.delta;

        a.ex1 += incr;
        setCurrentCell(a.ex1, f.ey, cellData);
        f.y1 += a.delta;

        if (a.ex1 != a.ex2) {
            p = int32(ss.scale) * (f.y2 - f.y1 + a.delta);
            int32 lift = p / dx;
            int32 rem = p % dx;

            if (rem < 0) {
                lift--;
                rem += dx;
            }

            mod -= dx;

            while (a.ex1 != a.ex2) {
                a.delta = lift;
                mod += rem;
                if (mod >= 0) {
                    mod -= dx;
                    a.delta++;
                }

                cellData.current.cover += a.delta;
                cellData.current.area += int32(ss.scale) * a.delta;
                f.y1 += a.delta;
                a.ex1 += incr;
                setCurrentCell(a.ex1, f.ey, cellData);
            }
        }

        a.delta = f.y2 - f.y1;
        cellData.current.cover += a.delta;
        cellData.current.area +=
            (a.fx2 + int32(ss.scale) - first) *
            a.delta;
    }

    function setCurrentCell(
        int32 x,
        int32 y,
        CellData memory cellData
    ) private pure {
        if (CellMethods.notEqual(cellData.current, x, y, cellData.style)) {
            addCurrentCell(cellData);
            CellMethods.style(cellData.current, cellData.style);
            cellData.current.x = x;
            cellData.current.y = y;
            cellData.current.cover = 0;
            cellData.current.area = 0;
        }
    }

    function addCurrentCell(CellData memory cellData) private pure {
        if ((cellData.current.area | cellData.current.cover) != 0) {
            if (cellData.used >= cellData.cb.limit) return;
            CellMethods.set(cellData.cells[cellData.used], cellData.current);
            cellData.used++;
        }
    }

    function sort(
        Cell[] memory cells,
        int32 start,
        int32 stop
    ) private pure {
        while (true) {
            if (stop == start) return;

            int32 pivot;
            {
                int32 m = start + 1;
                int32 n = stop;
                while (m < stop && cells[uint32(start)].x >= cells[uint32(m)].x) m++;

                while (n > start && cells[uint32(start)].x <= cells[uint32(n)].x) n--;
                while (m < n) {
                    (cells[uint32(m)], cells[uint32(n)]) = (
                        cells[uint32(n)],
                        cells[uint32(m)]
                    );
                    while (m < stop && cells[uint32(start)].x >= cells[uint32(m)].x)
                        m++;
                    while (n > start && cells[uint32(start)].x <= cells[uint32(n)].x)
                        n--;
                }

                if (start != n) {
                    (cells[uint32(n)], cells[uint32(start)]) = (
                        cells[uint32(start)],
                        cells[uint32(n)]
                    );
                }
                pivot = n;
            }

            if (pivot > start) sort(cells, start, pivot - 1);

            if (pivot < stop) {
                start = pivot + 1;
                continue;
            }

            break;
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

enum Command {
    Stop,
    MoveTo,
    LineTo,
    Curve3,
    Curve4,
    EndPoly
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

struct LineClipY {
    int32 x1;
    int32 y1;
    int32 x2;
    int32 y2;
    int32 f1;
    int32 f2;
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

struct Line {
    int32 x1;
    int32 y1;
    int32 x2;
    int32 y2;
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

struct LineArgs {
    int32 dx;
    int32 dy;
    int32 ex1;
    int32 ex2;
    int32 ey1;
    int32 ey2;
    int32 fy1;
    int32 fy2;
    int32 delta;
    int32 first;
    int32 incr;
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

struct RenderHorizontalLine { 
    int32 ey;
    int32 x1;
    int32 y1;
    int32 x2;
    int32 y2;
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
 
struct RenderHorizontalLineArgs {
    int32 ex1;
    int32 ex2;
    int32 fx1;
    int32 fx2;
    int32 delta;
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

struct BlendSolidHorizontalSpan {
    int32 x;
    int32 y;
    int32 len;
    uint32 sourceColor;
    uint8[] covers;
    int32 coversIndex;
    bool blend;
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

struct BlendHorizontalLine {
    int32 x1;
    int32 y;
    int32 x2;
    uint32 sourceColor;
    uint8 cover;
    bool blend;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/Vector2.sol";
import "../Kohi/Fix64V1.sol";
import "../Kohi/Trig256.sol";

struct Bezier
{
    Vector2 a;
    Vector2 b;
    Vector2 c;
    Vector2 d;
    int32 len;
    int64[] arcLengths;
}

library BezierMethods { 

    function create(Vector2 memory t, Vector2 memory h, Vector2 memory s, Vector2 memory i) internal pure returns (Bezier memory result) {
        result.a = t;
        result.b = h;
        result.c = s;
        result.d = i;
        result.len = 100;
        result.arcLengths = new int64[](uint32(result.len + 1));
        result.arcLengths[0] = 0;

        int64 n = xFunc(result, 0);
        int64 r = yFunc(result, 0);
        int64 e = 0;

        for (int32 ax = 1; ax <= result.len; ax += 1)
        {
            int64 z = Fix64V1.mul(42949672 /* 0.01 */, ax * Fix64V1.ONE);
            int64 c = xFunc(result, z);
            int64 u = yFunc(result, z);

            int64 y = Fix64V1.sub(n, c);
            int64 o = Fix64V1.sub(r, u);

            int64 t0 = Fix64V1.mul(y, y);
            int64 t1 = Fix64V1.mul(o, o);

            int64 sqrt = Fix64V1.add(t0, t1);
            e = Fix64V1.add(e, Trig256.sqrt(sqrt));
            result.arcLengths[uint32(ax)] = e;
            n = c;
            r = u;
        }
    }

    function xFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.x)));
        int64 t2 = Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(t0, t0), 3 * Fix64V1.ONE), t), self.b.x);
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.x)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.x)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));
    }

    function yFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.y)));
        int64 t2 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t, self.b.y))));
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.y)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.y)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));        
    }

    function mx(Bezier memory self,int64 t) internal pure returns (int64) {
        return xFunc(self, map(self, t));
    }

    function my(Bezier memory self,int64 t) internal pure returns (int64) {
        return yFunc(self, map(self, t));
    }

    function map(Bezier memory self, int64 t) private pure returns (int64) {
        int64 h = Fix64V1.mul(t, self.arcLengths[uint32(self.len)]);
        int32 n = 0;
        int32 s = 0;
        for (int32 i = self.len; s < i;)
        {
            n = s + ((i - s) / 2 | 0);
            if (self.arcLengths[uint32(n)] < h)
            {
                s = n + 1;
            }
            else
            {
                i = n;
            }
        }
        if (self.arcLengths[uint32(n)] > h)
        {
            n--;
        }
        int64 r = self.arcLengths[uint32(n)];
        return r == h ? Fix64V1.div(n * Fix64V1.ONE, self.len * Fix64V1.ONE) :
            Fix64V1.div(
                Fix64V1.add(n * Fix64V1.ONE, Fix64V1.div(Fix64V1.sub(h, r), Fix64V1.sub(self.arcLengths[uint32(n + 1)], r))),
                self.len * Fix64V1.ONE);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Star {
    int32 x;
    int32 y;
    int32 s;
    int32 c;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/Graphics2D.sol";
import "../Kohi/DrawContext.sol";
import "../Kohi/Matrix.sol";
import "../Kohi/VertexData.sol";

import "./RenderUniverseArgs.sol";
import "./TextureData.sol";

library TextureMethods {

    function draw(
        Graphics2D memory g,
        TextureData memory texture,
        DrawContext memory f
    ) internal pure {
        
        for (uint256 i = 0; i < texture.vertices.length; i++) {
            f.color = ColorMath.tint(texture.colors[i], f.tint);
            Graphics2DMethods.renderWithTransform(
                g,
                f,
                texture.vertices[i],               
                true
            );
        }
    }

    function rectify(int64 x, int64 y, int64 r, int64 s, Matrix memory t) internal pure returns (Matrix memory transform) {
        int64 dx = x;
        int64 dy = y;

        if (!MatrixMethods.isIdentity(t)) {
            (dx, dy) = MatrixMethods.transform(t, dx, dy);
        }

        dx = Fix64V1.add(dx, Fix64V1.ONE);
        dy = Fix64V1.sub(dy, Fix64V1.ONE);

        transform = MatrixMethods.newIdentity();
        transform = MatrixMethods.mul(transform, MatrixMethods.newTranslation(-4771708665856 /* -1111 */, -4771708665856 /* -1111 */));
        transform = MatrixMethods.mul(transform, MatrixMethods.newScale(s, s));

        if (r != 0) {
            transform = MatrixMethods.mul(transform, MatrixMethods.newRotation(r));
        }

        transform = MatrixMethods.mul(transform, MatrixMethods.newTranslation(dx, dy));
        return transform;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../Kohi/VertexData.sol";
import "../Kohi/Matrix.sol";

struct RenderUniverseArgs {
    int64 x;
    int64 y;
    int64 angle;
    int64 size;
    uint32 tint;    
    Matrix rectify;
    VertexData[] path;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/VertexData.sol";

struct TextureData {
    VertexData[][] vertices;
    uint32[] colors;
}