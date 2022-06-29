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

struct CustomPath {
    int32 numVertices;
    VertexData[] vertexData;
}

library CustomPathMethods {
    function create(uint maxVertices) external pure returns (CustomPath memory data) {
        data.numVertices = 0;
        data.vertexData = new VertexData[](maxVertices);
    }

    function vertices(CustomPath memory self)
        external
        pure
        returns (VertexData[] memory results)
    {
        results = new VertexData[](uint32(self.numVertices) + 1);
        for (uint32 i = 0; i < uint32(self.numVertices); i++) {
            (Command command, int64 x, int64 y) = vertex(self, int32(i));
            results[i] = VertexData(command, Vector2(x, y));
        }
        results[uint32(self.numVertices)] = VertexData(
            Command.Stop,
            Vector2(0, 0)
        );
        return results;
    }

    function add(
        CustomPath memory self,
        int64 x,
        int64 y,
        Command command
    ) internal pure {
        self.vertexData[uint32(self.numVertices++)] = VertexData(
            command,
            Vector2(x, y)
        );
    }

    function endPoly(CustomPath memory self) internal pure {
        Command command = lastCommand(self);
        if (command != Command.Stop && command != Command.EndPoly) {
            self.vertexData[uint32(self.numVertices++)] = VertexData(
                Command.MoveTo,
                Vector2(0, 0)
            );
        }
    }

    function moveTo(
        CustomPath memory self,
        int64 x,
        int64 y
    ) internal pure {
        self.vertexData[uint32(self.numVertices++)] = VertexData(
            Command.MoveTo,
            Vector2(x, y)
        );
    }

    function lineTo(
        CustomPath memory self,
        int64 x,
        int64 y
    ) internal pure {
        self.vertexData[uint32(self.numVertices++)] = VertexData(
            Command.LineTo,
            Vector2(x, y)
        );
    }

    function lastCommand(CustomPath memory self)
        internal
        pure
        returns (Command)
    {
        return
            self.numVertices != 0
                ? self.vertexData[uint32(self.numVertices - 1)].command
                : Command.Stop;
    }

    function lastX(CustomPath memory self) internal pure returns (int64) {
        if (self.numVertices > 0) {
            int32 index = self.numVertices - 1;
            return self.vertexData[uint32(index)].position.x;
        }

        return 0;
    }

    function lastY(CustomPath memory self) internal pure returns (int64) {
        if (self.numVertices > 0) {
            int32 index = self.numVertices - 1;
            return self.vertexData[uint32(index)].position.y;
        }
        return 0;
    }

    function previousVertex(CustomPath memory self)
        internal
        pure
        returns (
            Command,
            int64 x,
            int64 y
        )
    {
        if (self.numVertices > 1) {
            return vertex(self, self.numVertices - 2);
        }
        x = 0;
        y = 0;
        return (Command.Stop, x, y);
    }

    function vertex(CustomPath memory self, int32 index)
        internal
        pure
        returns (
            Command,
            int64 x,
            int64 y
        )
    {
        x = self.vertexData[uint32(index)].position.x;
        y = self.vertexData[uint32(index)].position.y;
        return (self.vertexData[uint32(index)].command, x, y);
    }

    function commandAt(CustomPath memory self, int32 index)
        internal
        pure
        returns (Command)
    {
        return self.vertexData[uint32(index)].command;
    }

    function lastVertex(CustomPath memory self)
        internal
        pure
        returns (
            Command,
            int64 x,
            int64 y
        )
    {
        if (self.numVertices != 0) {
            return vertex(self, self.numVertices - 1);
        }
        x = 0;
        y = 0;
        return (Command.Stop, x, y);
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