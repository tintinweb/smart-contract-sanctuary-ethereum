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
import "./VertexDistance.sol";
import "./VertexStatus.sol";
import "./StrokeStatus.sol";
import "./LineCap.sol";
import "./LineJoin.sol";
import "./Command.sol";
import "./MathUtils.sol";

import "./Errors.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

struct Stroke {
    int64 startX;
    int64 startY;
    int64 width;
    int64 widthAbs;
    int64 widthEps;
    int64 widthSign;
    int32 srcVertex;
    int32 outVertexCount;
    int32 outVerticesCount;
    int32 distanceCount;
    bool closed;
    Vector2[] outVertices;
    VertexDistance[] distances;
    VertexData[] vertexSource;
    VertexStatus vertexStatus;
    StrokeStatus status;
    StrokeStatus previousStatus;
    LineCap lineCap;
    LineJoin lineJoin;
    Command lastCommand;
}

library StrokeMethods {
    function create(
        VertexData[] memory v,
        int64 width,
        uint32 maxDistanceCount,
        uint32 maxVertexCount
    ) external pure returns (Stroke memory stroke) {
        stroke.vertexSource = v;
        stroke.vertexStatus = VertexStatus.Initial;

        stroke.distances = new VertexDistance[](maxDistanceCount);
        stroke.outVertices = new Vector2[](maxVertexCount);
        stroke.status = StrokeStatus.Initial;

        stroke.lineCap = LineCap.Butt;
        stroke.lineJoin = LineJoin.Miter;

        stroke.width = Fix64V1.mul(
            width,
            2147483648 /* 0.5 */
        );
        if (stroke.width < 0) {
            stroke.widthAbs = -stroke.width;
            stroke.widthSign = -Fix64V1.ONE;
        } else {
            stroke.widthAbs = stroke.width;
            stroke.widthSign = Fix64V1.ONE;
        }
        stroke.widthEps = Fix64V1.div(
            stroke.width,
            4398046511104 /* 1024 */
        );
    }

    function vertices(Stroke memory self)
        external
        pure
        returns (VertexData[] memory results)
    {
        self.vertexStatus = VertexStatus.Initial;

        uint32 count = 0;
        {
            Command command;
            uint32 i = 0;
            do {
                (command, i, , ) = vertex(self, i, self.vertexSource);
                count++;
            } while (command != Command.Stop);
        }

        self.vertexStatus = VertexStatus.Initial;

        results = new VertexData[](count);
        {
            Command command;
            uint32 i = 0;
            count = 0;
            do {
                int64 x;
                int64 y;
                (command, i, x, y) = vertex(self, i, self.vertexSource);
                results[count++] = VertexData(command, Vector2(x, y));
            } while (command != Command.Stop);
        }

        return results;
    }

    function vertex(
        Stroke memory self,
        uint32 i,
        VertexData[] memory v
    )
        private
        pure
        returns (
            Command,
            uint32,
            int64,
            int64
        )
    {
        int64 x = 0;
        int64 y = 0;

        Command command = Command.Stop;
        bool done = false;

        while (!done) {
            VertexData memory c;

            if (self.vertexStatus == VertexStatus.Initial) {
                c = v[i++];
                self.lastCommand = c.command;
                self.startX = c.position.x;
                self.startY = c.position.y;
                self.vertexStatus = VertexStatus.Accumulate;
            } else if (self.vertexStatus == VertexStatus.Accumulate) {
                if (self.lastCommand == Command.Stop)
                    return (Command.Stop, i, x, y);

                clear(self);
                addVertex(self, self.startX, self.startY, Command.MoveTo);

                for (;;) {
                    c = v[i++];

                    self.lastCommand = c.command;
                    x = c.position.x;
                    y = c.position.y;

                    command = c.command;

                    if (command != Command.Stop && command != Command.EndPoly) {
                        self.lastCommand = command;
                        if (command == Command.MoveTo) {
                            self.startX = x;
                            self.startY = y;
                            break;
                        }

                        addVertex(self, x, y, command);
                    } else {
                        if (command == Command.Stop) {
                            self.lastCommand = Command.Stop;
                            break;
                        }

                        addVertex(self, x, y, command);
                        break;
                    }
                }

                rewind(self);
                self.vertexStatus = VertexStatus.Generate;
            } else if (self.vertexStatus == VertexStatus.Generate) {
                (command, x, y) = strokeVertex(self);

                if (command == Command.Stop) {
                    self.vertexStatus = VertexStatus.Accumulate;
                } else {
                    done = true;
                }
            } else {
                revert ArgumentOutOfRange();
            }
        }

        return (command, i, x, y);
    }

    function addVertex(
        Stroke memory self,
        int64 x,
        int64 y,
        Command command
    ) private pure {
        self.status = StrokeStatus.Initial;
        if (command == Command.MoveTo) {
            if (self.distanceCount != 0) self.distanceCount--;
            add(self, VertexDistance(x, y, 0));
        } else {
            if (command != Command.Stop && command != Command.EndPoly)
                add(self, VertexDistance(x, y, 0));
            else self.closed = command == Command.EndPoly;
        }
    }

    function strokeVertex(Stroke memory self)
        private
        pure
        returns (
            Command,
            int64 x,
            int64 y
        )
    {
        x = 0;
        y = 0;

        Command command = Command.LineTo;
        while (command != Command.Stop) {
            if (self.status == StrokeStatus.Initial) {
                rewind(self);
            } else if (self.status == StrokeStatus.Ready) {
                if (
                    self.distanceCount < 2 + (self.closed ? int8(1) : int8(0))
                ) {
                    command = Command.Stop;
                } else {
                    self.status = self.closed
                        ? StrokeStatus.Outline1
                        : StrokeStatus.Cap1;
                    command = Command.MoveTo;
                    self.srcVertex = 0;
                    self.outVertexCount = 0;
                }
            } else if (self.status == StrokeStatus.Cap1) {
                calcCap(
                    self,
                    self.distances[0],
                    self.distances[1],
                    self.distances[0].distance
                );

                self.srcVertex = 1;
                self.previousStatus = StrokeStatus.Outline1;
                self.status = StrokeStatus.OutVertices;
                self.outVertexCount = 0;
            } else if (self.status == StrokeStatus.Cap2) {
                calcCap(
                    self,
                    self.distances[uint32(self.distanceCount - 1)],
                    self.distances[uint32(self.distanceCount - 2)],
                    self.distances[uint32(self.distanceCount - 2)].distance
                );

                self.previousStatus = StrokeStatus.Outline2;
                self.status = StrokeStatus.OutVertices;
                self.outVertexCount = 0;
            } else if (self.status == StrokeStatus.Outline1) {
                bool join = true;
                if (self.closed) {
                    if (self.srcVertex >= self.distanceCount) {
                        self.previousStatus = StrokeStatus.CloseFirst;
                        self.status = StrokeStatus.EndPoly1;
                        join = false;
                    }
                } else {
                    if (self.srcVertex >= self.distanceCount - 1) {
                        self.status = StrokeStatus.Cap2;
                        join = false;
                    }
                }

                if (join) {
                    calcJoin(
                        self,
                        previous(self, self.srcVertex),
                        current(self, self.srcVertex),
                        next(self, self.srcVertex),
                        previous(self, self.srcVertex).distance,
                        current(self, self.srcVertex).distance
                    );

                    ++self.srcVertex;
                    self.previousStatus = self.status;
                    self.status = StrokeStatus.OutVertices;
                    self.outVertexCount = 0;
                }
            } else if (self.status == StrokeStatus.CloseFirst) {
                self.status = StrokeStatus.Outline2;
                command = Command.MoveTo;
            } else if (self.status == StrokeStatus.Outline2) {
                bool join = true;
                if (self.srcVertex <= (!self.closed ? int8(1) : int8(0))) {
                    self.status = StrokeStatus.EndPoly2;
                    self.previousStatus = StrokeStatus.Stop;
                    join = false;
                }

                if (join) {
                    --self.srcVertex;

                    calcJoin(
                        self,
                        next(self, self.srcVertex),
                        current(self, self.srcVertex),
                        previous(self, self.srcVertex),
                        current(self, self.srcVertex).distance,
                        previous(self, self.srcVertex).distance
                    );

                    self.previousStatus = self.status;
                    self.status = StrokeStatus.OutVertices;
                    self.outVertexCount = 0;
                }
            } else if (self.status == StrokeStatus.OutVertices) {
                if (self.outVertexCount >= self.outVerticesCount) {
                    self.status = self.previousStatus;
                } else {
                    Vector2 memory c = self.outVertices[
                        uint32(self.outVertexCount++)
                    ];
                    x = c.x;
                    y = c.y;
                    return (command, c.x, y);
                }
            } else if (self.status == StrokeStatus.EndPoly1) {
                self.status = self.previousStatus;
                return (Command.EndPoly, x, y);
            } else if (self.status == StrokeStatus.EndPoly2) {
                self.status = self.previousStatus;
                return (Command.EndPoly, x, y);
            } else if (self.status == StrokeStatus.Stop) {
                command = Command.Stop;
            } else {
                revert ArgumentOutOfRange();
            }
        }

        return (command, x, y);
    }

    function rewind(Stroke memory self) private pure {
        if (self.status == StrokeStatus.Initial) {
            while (self.distanceCount > 1) {
                if (
                    VertexDistanceMethods.isEqual(
                        self.distances[uint32(self.distanceCount - 2)],
                        self.distances[uint32(self.distanceCount - 1)]
                    )
                ) break;
                VertexDistance memory t = self.distances[
                    uint32(self.distanceCount - 1)
                ];
                if (self.distanceCount != 0) self.distanceCount--;
                if (self.distanceCount != 0) self.distanceCount--;
                add(self, t);
            }

            if (self.closed)
                while (self.distanceCount > 1) {
                    if (
                        VertexDistanceMethods.isEqual(
                            self.distances[uint32(self.distanceCount - 1)],
                            self.distances[0]
                        )
                    ) break;
                    if (self.distanceCount != 0) self.distanceCount--;
                }

            if (self.distanceCount < 3) self.closed = false;
        }

        self.status = StrokeStatus.Ready;
        self.srcVertex = 0;
        self.outVertexCount = 0;
    }

    function add(Stroke memory self, VertexDistance memory value) private pure {
        if (self.distanceCount > 1)
            if (
                !VertexDistanceMethods.isEqual(
                    self.distances[uint32(self.distanceCount - 2)],
                    self.distances[uint32(self.distanceCount - 1)]
                )
            )
                if (self.distanceCount != 0) self.distanceCount--;
        self.distances[uint32(self.distanceCount++)] = value;
    }

    struct CalcCapArgs {
        uint32 vertexCount;
        int64 dx1;
        int64 dy1;
        int64 dx2;
        int64 dy2;
        int64 da;
        int64 a1;
        int32 i;
        int32 n;
    }

    function calcCap(
        Stroke memory self,
        VertexDistance memory v0,
        VertexDistance memory v1,
        int64 len
    ) private pure {
        self.outVerticesCount = 0;

        CalcCapArgs memory a;

        a.dx1 = Fix64V1.div(Fix64V1.sub(v1.y, v0.y), len);
        a.dy1 = Fix64V1.div(Fix64V1.sub(v1.x, v0.x), len);
        a.dx2 = 0;
        a.dy2 = 0;

        a.dx1 = Fix64V1.mul(a.dx1, self.width);
        a.dy1 = Fix64V1.mul(a.dy1, self.width);

        if (self.lineCap != LineCap.Round) {
            if (self.lineCap == LineCap.Square) {
                a.dx2 = a.dy1 * self.widthSign;
                a.dy2 = a.dx1 * self.widthSign;
            }

            self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                Fix64V1.sub(v0.x, Fix64V1.sub(a.dx1, a.dx2)),
                Fix64V1.add(v0.y, Fix64V1.sub(a.dy1, a.dy2))
            );
            self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                Fix64V1.add(v0.x, Fix64V1.sub(a.dx1, a.dx2)),
                Fix64V1.sub(v0.y, Fix64V1.sub(a.dy1, a.dy2))
            );
        } else {
            a.da = Fix64V1.mul(
                Trig256.acos(
                    Fix64V1.div(
                        self.widthAbs,
                        Fix64V1.add(
                            self.widthAbs,
                            Fix64V1.div(
                                536870912, /* 0.125 */
                                Fix64V1.ONE
                            )
                        )
                    )
                ),
                Fix64V1.TWO
            );

            a.n = (int32)(Fix64V1.div(Fix64V1.PI, a.da) / Fix64V1.ONE);

            a.da = Fix64V1.div(Fix64V1.PI, (a.n + 1) * Fix64V1.ONE);

            self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                Fix64V1.sub(v0.x, a.dx1),
                Fix64V1.add(v0.y, a.dy1)
            );

            if (self.widthSign > 0) {
                a.a1 = Trig256.atan2(a.dy1, -a.dx1);
                a.a1 = Fix64V1.add(a.a1, a.da);
                for (a.i = 0; a.i < a.n; a.i++) {
                    self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                        Fix64V1.add(
                            v0.x,
                            Fix64V1.mul(Trig256.cos(a.a1), self.width)
                        ),
                        Fix64V1.add(
                            v0.y,
                            Fix64V1.mul(Trig256.sin(a.a1), self.width)
                        )
                    );
                    a.a1 += a.da;
                }
            } else {
                a.a1 = Trig256.atan2(-a.dy1, a.dx1);
                a.a1 = Fix64V1.sub(a.a1, a.da);
                for (a.i = 0; a.i < a.n; a.i++) {
                    self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                        Fix64V1.add(
                            v0.x,
                            Fix64V1.mul(Trig256.cos(a.a1), self.width)
                        ),
                        Fix64V1.add(
                            v0.y,
                            Fix64V1.mul(Trig256.sin(a.a1), self.width)
                        )
                    );

                    a.a1 = Fix64V1.sub(a.a1, a.da);
                }
            }

            self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                Fix64V1.add(v0.x, a.dx1),
                Fix64V1.sub(v0.y, a.dy1)
            );
        }
    }

    struct CalcJoinArgs {
        int64 dx1;
        int64 dy1;
        int64 dx2;
        int64 dy2;
        int64 cp;
        int64 dx;
        int64 dy;
        int64 bevelDistance;
        bool intersects;
    }

    function calcJoin(
        Stroke memory self,
        VertexDistance memory v0,
        VertexDistance memory v1,
        VertexDistance memory v2,
        int64 len1,
        int64 len2
    ) private pure {
        self.outVerticesCount = 0;

        CalcJoinArgs memory a;

        a.dx1 = Fix64V1.mul(
            self.width,
            Fix64V1.div(Fix64V1.sub(v1.y, v0.y), len1)
        );
        a.dy1 = Fix64V1.mul(
            self.width,
            Fix64V1.div(Fix64V1.sub(v1.x, v0.x), len1)
        );
        a.dx2 = Fix64V1.mul(
            self.width,
            Fix64V1.div(Fix64V1.sub(v2.y, v1.y), len2)
        );
        a.dy2 = Fix64V1.mul(
            self.width,
            Fix64V1.div(Fix64V1.sub(v2.x, v1.x), len2)
        );
        a.cp = MathUtils.crossProduct(v0.x, v0.y, v1.x, v1.y, v2.x, v2.y);

        if (a.cp != 0 && a.cp > 0 == self.width > 0) {
            int64 limit = 0;
            if (self.widthAbs != 0) {
                limit = Fix64V1.div((len1 < len2 ? len1 : len2), self.widthAbs);
            }

            if (
                limit < 4337916928 /* 1.01 */
            ) {
                limit = 4337916928; /* 1.01 */
            }

            calcMiter(
                self,
                CalcMiter(
                    v0,
                    v1,
                    v2,
                    a.dx1,
                    a.dy1,
                    a.dx2,
                    a.dy2,
                    LineJoin.MiterRevert,
                    limit,
                    0
                )
            );
        } else {
            a.dx = Fix64V1.div(Fix64V1.add(a.dx1, a.dx2), Fix64V1.TWO);
            a.dy = Fix64V1.div(Fix64V1.add(a.dy1, a.dy2), Fix64V1.TWO);
            a.bevelDistance = Trig256.sqrt(
                Fix64V1.add(Fix64V1.mul(a.dx, a.dx), Fix64V1.mul(a.dy, a.dy))
            );

            if (
                self.lineJoin == LineJoin.Round ||
                self.lineJoin == LineJoin.Bevel
            ) {
                if (
                    Fix64V1.mul(
                        Fix64V1.ONE,
                        Fix64V1.sub(self.widthAbs, a.bevelDistance)
                    ) < self.widthEps
                ) {
                    (a.dx, a.dy, a.intersects) = MathUtils.calcIntersection(
                        MathUtils.CalcIntersection(
                            Fix64V1.add(v0.x, a.dx1),
                            Fix64V1.sub(v0.y, a.dy1),
                            Fix64V1.add(v1.x, a.dx1),
                            Fix64V1.sub(v1.y, a.dy1),
                            Fix64V1.add(v1.x, a.dx2),
                            Fix64V1.sub(v1.y, a.dy2),
                            Fix64V1.add(v2.x, a.dx2),
                            Fix64V1.sub(v2.y, a.dy2)
                        )
                    );

                    if (a.intersects) {
                        self.outVertices[
                            uint32(self.outVerticesCount++)
                        ] = Vector2(a.dx, a.dy);
                    } else {
                        self.outVertices[
                            uint32(self.outVerticesCount++)
                        ] = Vector2(
                            Fix64V1.add(v1.x, a.dx1),
                            Fix64V1.sub(v1.y, a.dy1)
                        );
                    }

                    return;
                }
            }

            if (
                self.lineJoin == LineJoin.Miter ||
                self.lineJoin == LineJoin.MiterRevert ||
                self.lineJoin == LineJoin.MiterRound
            ) {
                calcMiter(
                    self,
                    CalcMiter(
                        v0,
                        v1,
                        v2,
                        a.dx1,
                        a.dy1,
                        a.dx2,
                        a.dy2,
                        self.lineJoin,
                        17179869184, /* 4 */
                        a.bevelDistance
                    )
                );
            } else if (self.lineJoin == LineJoin.Round) {
                calcArc(
                    self,
                    CalcArc(v1.x, v1.y, a.dx1, -a.dy1, a.dx2, -a.dy2)
                );
            } else if (self.lineJoin == LineJoin.Bevel) {
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    Fix64V1.add(v1.x, a.dx1),
                    Fix64V1.sub(v1.y, a.dy1)
                );
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    Fix64V1.add(v1.x, a.dx2),
                    Fix64V1.sub(v1.y, a.dy2)
                );
            } else {
                revert ArgumentOutOfRange();
            }
        }
    }

    struct CalcArc {
        int64 x;
        int64 y;
        int64 dx1;
        int64 dy1;
        int64 dx2;
        int64 dy2;
    }

    function calcArc(Stroke memory self, CalcArc memory f) private pure {
        int64 a1 = Trig256.atan2(
            Fix64V1.mul(f.dy1, self.widthSign),
            Fix64V1.mul(f.dx1, self.widthSign)
        );

        int64 a2 = Trig256.atan2(
            Fix64V1.mul(f.dy2, self.widthSign),
            Fix64V1.mul(f.dx2, self.widthSign)
        );

        int32 n;

        int64 da = Fix64V1.mul(
            Trig256.acos(
                Fix64V1.div(
                    self.widthAbs,
                    Fix64V1.add(
                        self.widthAbs,
                        Fix64V1.div(
                            536870912, /* 0.125 */
                            Fix64V1.ONE
                        )
                    )
                )
            ),
            Fix64V1.TWO
        );

        self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
            Fix64V1.add(f.x, f.dx1),
            Fix64V1.add(f.y, f.dy1)
        );

        if (self.widthSign > 0) {
            if (a1 > a2) {
                a2 = Fix64V1.add(a2, Fix64V1.TWO_PI);
            }

            int64 t1 = Fix64V1.div(Fix64V1.sub(a2, a1), da);
            n = (int32)(t1 / Fix64V1.ONE);

            da = Fix64V1.div(Fix64V1.sub(a2, a1), (n + 1) * Fix64V1.ONE);
            a1 = Fix64V1.add(a1, da);

            for (int32 i = 0; i < n; i++) {
                int64 vx = Fix64V1.add(
                    f.x,
                    Fix64V1.mul(Trig256.cos(a1), self.width)
                );
                int64 vy = Fix64V1.add(
                    f.y,
                    Fix64V1.mul(Trig256.sin(a1), self.width)
                );
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    vx,
                    vy
                );
                a1 = Fix64V1.add(a1, da);
            }
        } else {
            if (a1 < a2) {
                a2 = Fix64V1.sub(a2, Fix64V1.TWO_PI);
            }

            int64 t1 = Fix64V1.div(Fix64V1.sub(a1, a2), da);
            n = (int32)(t1 / Fix64V1.ONE);

            da = Fix64V1.div(Fix64V1.sub(a1, a2), (n + 1) * Fix64V1.ONE);
            a1 = Fix64V1.sub(a1, da);

            for (int32 i = 0; i < n; i++) {
                int64 vx = Fix64V1.add(
                    f.x,
                    Fix64V1.mul(Trig256.cos(a1), self.width)
                );
                int64 vy = Fix64V1.add(
                    f.y,
                    Fix64V1.mul(Trig256.sin(a1), self.width)
                );
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    vx,
                    vy
                );
                a1 = Fix64V1.sub(a1, da);
            }
        }

        self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
            Fix64V1.add(f.x, f.dx2),
            Fix64V1.add(f.y, f.dy2)
        );
    }

    struct CalcMiter {
        VertexDistance v0;
        VertexDistance v1;
        VertexDistance v2;
        int64 dx1;
        int64 dy1;
        int64 dx2;
        int64 dy2;
        LineJoin lj;
        int64 miterLimit;
        int64 distanceBevel;
    }

    struct CalcMiterArgs {
        int64 di;
        int64 lim;
        bool miterLimitExceeded;
        bool intersectionFailed;
    }

    function calcMiter(Stroke memory self, CalcMiter memory f) private pure {
        CalcMiterArgs memory a;

        a.di = Fix64V1.ONE;
        a.lim = Fix64V1.mul(self.widthAbs, f.miterLimit);
        a.miterLimitExceeded = true;
        a.intersectionFailed = true;

        (int64 xi, int64 yi, bool intersects) = MathUtils.calcIntersection(
            MathUtils.CalcIntersection(
                Fix64V1.add(f.v0.x, f.dx1),
                Fix64V1.sub(f.v0.y, f.dy1),
                Fix64V1.add(f.v1.x, f.dx1),
                Fix64V1.sub(f.v1.y, f.dy1),
                Fix64V1.add(f.v1.x, f.dx2),
                Fix64V1.sub(f.v1.y, f.dy2),
                Fix64V1.add(f.v2.x, f.dx2),
                Fix64V1.sub(f.v2.y, f.dy2)
            )
        );

        if (intersects) {
            a.di = MathUtils.calcDistance(f.v1.x, f.v1.y, xi, yi);

            if (a.di <= a.lim) {
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    xi,
                    yi
                );
                a.miterLimitExceeded = false;
            }

            a.intersectionFailed = false;
        } else {
            int64 x2 = Fix64V1.add(f.v1.x, f.dx1);
            int64 y2 = Fix64V1.sub(f.v1.y, f.dy1);

            if (
                MathUtils.crossProduct(f.v0.x, f.v0.y, f.v1.x, f.v1.y, x2, y2) <
                0 ==
                MathUtils.crossProduct(f.v1.x, f.v1.y, f.v2.x, f.v2.y, x2, y2) <
                0
            ) {
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    Fix64V1.add(f.v1.x, f.dx1),
                    Fix64V1.sub(f.v1.y, f.dy1)
                );
                a.miterLimitExceeded = false;
            }
        }

        if (!a.miterLimitExceeded) return;

        {
            if (f.lj == LineJoin.MiterRevert) {
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    Fix64V1.add(f.v1.x, f.dx1),
                    Fix64V1.sub(f.v1.y, f.dy1)
                );
                self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                    Fix64V1.add(f.v1.x, f.dx2),
                    Fix64V1.sub(f.v1.y, f.dy2)
                );
            } else if (f.lj == LineJoin.MiterRound) {
                calcArc(
                    self,
                    CalcArc(f.v1.x, f.v1.y, f.dx1, -f.dy1, f.dx2, -f.dy2)
                );
            } else if (f.lj == LineJoin.Miter) {} else if (
                f.lj == LineJoin.Round
            ) {} else if (f.lj == LineJoin.Bevel) {} else {
                if (a.intersectionFailed) {
                    f.miterLimit = Fix64V1.mul(f.miterLimit, self.widthSign);

                    self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                        Fix64V1.add(
                            f.v1.x,
                            Fix64V1.add(f.dx1, Fix64V1.mul(f.dy1, f.miterLimit))
                        ),
                        Fix64V1.sub(
                            f.v1.y,
                            Fix64V1.add(f.dy1, Fix64V1.mul(f.dx1, f.miterLimit))
                        )
                    );

                    self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                        Fix64V1.add(
                            f.v1.x,
                            Fix64V1.sub(f.dx2, Fix64V1.mul(f.dy2, f.miterLimit))
                        ),
                        Fix64V1.sub(
                            f.v1.y,
                            Fix64V1.sub(f.dy2, Fix64V1.mul(f.dx2, f.miterLimit))
                        )
                    );
                } else {
                    int64 x1 = Fix64V1.add(f.v1.x, f.dx1);
                    int64 y1 = Fix64V1.sub(f.v1.y, f.dy1);
                    int64 x2 = Fix64V1.add(f.v1.x, f.dx2);
                    int64 y2 = Fix64V1.sub(f.v1.y, f.dy2);

                    a.di = Fix64V1.div(
                        Fix64V1.sub(a.lim, f.distanceBevel),
                        Fix64V1.sub(a.di, f.distanceBevel)
                    );

                    self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                        Fix64V1.add(x1, Fix64V1.mul(Fix64V1.sub(xi, x1), a.di)),
                        Fix64V1.add(y1, Fix64V1.mul(Fix64V1.sub(yi, y1), a.di))
                    );

                    self.outVertices[uint32(self.outVerticesCount++)] = Vector2(
                        Fix64V1.add(x2, Fix64V1.mul(Fix64V1.sub(xi, x2), a.di)),
                        Fix64V1.add(y2, Fix64V1.mul(Fix64V1.sub(yi, y2), a.di))
                    );
                }
            }
        }
    }

    function previous(Stroke memory self, int32 i)
        private
        pure
        returns (VertexDistance memory)
    {
        return
            self.distances[
                uint32((i + self.distanceCount - 1) % self.distanceCount)
            ];
    }

    function current(Stroke memory self, int32 i)
        private
        pure
        returns (VertexDistance memory)
    {
        return self.distances[uint32(i)];
    }

    function next(Stroke memory self, int32 i)
        private
        pure
        returns (VertexDistance memory)
    {
        return self.distances[uint32((i + 1) % self.distanceCount)];
    }

    function clear(Stroke memory self) private pure {
        self.distanceCount = 0;
        self.closed = false;
        self.status = StrokeStatus.Initial;
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

import "./Fix64V1.sol";
import "./Trig256.sol";
import "./MathUtils.sol";

struct VertexDistance {
    int64 x;
    int64 y;
    int64 distance;
}

library VertexDistanceMethods {
    function isEqual(VertexDistance memory self, VertexDistance memory other)
        internal
        pure
        returns (bool)
    {
        int64 d = self.distance = MathUtils.calcDistance(
            self.x,
            self.y,
            other.x,
            other.y
        );
        bool r = d > MathUtils.Epsilon;
        if (!r) {
            self.distance = Fix64V1.div(Fix64V1.ONE, MathUtils.Epsilon);
        }
        return r;
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

enum VertexStatus {
    Initial,
    Accumulate,
    Generate
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

enum StrokeStatus {
    Initial,
    Ready,
    Cap1,
    Cap2,
    Outline1,
    CloseFirst,
    Outline2,
    OutVertices,
    EndPoly1,
    EndPoly2,
    Stop
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

enum LineCap {
    Butt,
    Square,
    Round
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

enum LineJoin {
    Miter,
    MiterRevert,
    Round,
    Bevel,
    MiterRound
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

error ArgumentOutOfRange();
error AttemptedToDivideByZero();
error NegativeValuePassed();

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