pragma solidity ^0.8.13;

import "../lib/ListUtils.sol";

/* 
* 
* Grid: [SHAPE SHAPE SHAPE SHAPE SHAPE] -----_-_-_---->  Partitioned Grid: [SHAPE SHAPE] [SHAPE SHAPE]
* 
* Combine adjacent pieces to form several groups of pieces that can be invididually
* "smooth unioned" and then layered in sequence.
**/

library Puzzle {
    
    using ListUtils for string[];
    using ListUtils for int8[];

    /**
    * @notice the grid is a 1-dimensional array though it really describes a 2D grid
     */
    function partitionAndCombine(string[] memory grid, uint size, int8[] memory program) public  pure returns (string[][] memory) {
        
        uint numPartitions = grid.length - program.count(-1);
        string[][] memory partitions = new string[][](numPartitions);
        // we need to figure out how many partitions there will be...
        uint pidx = 0;

        for (uint idx=0; idx < program.length; idx++) {
            int8 pieceType = program[idx % program.length];
            if (pieceType == -1) {
                // we skip this piece altogether
                continue;
            }
            uint[] memory pieceIndices = getPieceIndices(pieceType, idx, size);
            string[] memory piece = ListUtils.byIndices(grid, pieceIndices);
            partitions[pidx++] = piece;
        }
        return partitions;
    }

    /** 
    @notice Each piece has a type which specifies how it will combine the pieces
    * from the grid into a new piece.
    * This function simply returns the "new" combined indices for an index
     */
    function getPieceIndices(int8 pieceType, uint index, uint size) public pure returns (uint[]memory) {
        
        if (pieceType == 1) {
            /**  
                OO
             */
            uint [] memory piece = new uint[](2);
            piece[0] = index;
            piece[1] = index + size;
            return piece;
        } else if (pieceType == 2) {
            /**  
                0
                0
             */
            uint [] memory piece = new uint[](2);
            piece[0] = index;
            piece[1] = index + 1;
            return piece;
        } else if (pieceType == 3) {
            /**  
                0 0 
                0 0
             */
            uint [] memory piece = new uint[](4);
            piece[0] = index;
            piece[1] = index + 1;
            piece[2] = index + size;
            piece[3] = index + size + 1;
            return piece;
        } else if (pieceType == 4) {
            /**  
                0 0 
                0
             */
            uint [] memory piece = new uint[](3);
            piece[0] = index;
            piece[1] = index + 1;
            piece[2] = index + size;
            return piece;
        } else if (pieceType == 5) {
            /**  
                  0
                0 0 0
             */
            uint [] memory piece = new uint[](3);
            piece[0] = index;
            piece[1] = index + 1;
            piece[2] = index + size;
            return piece;
        } else if (pieceType == 6) {
            /**    
                0 0 0
                  0
             */
            uint [] memory piece = new uint[](3);
            piece[0] = index;
            piece[1] = index - 1;
            piece[2] = index + size;
            return piece;
        } else {
            /**
                O
             */
            uint [] memory piece = new uint[](1);
            piece[0] = index;
            return piece;
        }
    }

    
}

pragma solidity ^0.8.13;

library ListUtils {

     function prune(string[] memory list, uint256[] memory prunes) public pure returns (string [] memory) {
        string [] memory pruned = new string[](list.length - prunes.length);
        uint c = 0;
        for (uint i=0; i < list.length && c < pruned.length; i++) {
            bool found = false;
            for (uint j=0; j < prunes.length; j++) {
                if (i == prunes[j]) {
                    found = true;
                    break;
                }
            }
            // if its in the list we need to not allow it
            if (!found) {
                pruned[c++] = list[i];
            }
        }
        return pruned;
    }

    function byIndices(
        string[] memory list, 
        uint[] memory indices) 
    public pure returns (string [] memory) {
        string [] memory filtered = new string[](indices.length);
        for (uint i=0; i < indices.length; i++) {
            filtered[i] = list[indices[i] % list.length];
        }
        return filtered;
    }

    function count(
        int8[] memory list,
        int s) public pure returns (uint) {
        
        uint c = 0;
        for (uint i=0; i < list.length; i++) {
            if (list[i] == s) {
                c++;
            }
        }
        return c;
    }
    
}