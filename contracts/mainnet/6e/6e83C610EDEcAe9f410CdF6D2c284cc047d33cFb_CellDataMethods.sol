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