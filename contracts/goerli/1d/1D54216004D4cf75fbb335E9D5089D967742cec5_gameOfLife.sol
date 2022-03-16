/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

//SPDX-License-Identifier: 3BSD
pragma solidity ^0.8.0;

contract events {
    event boardReset();
    event evaluated();
}


contract gameOfLife is events {
    struct Row { 
        uint8[7] row;
    }

    Row[7] grid;
    constructor() {
        reset();
    }

    function reset () public {
        // Padding to prevent under/overflows
        grid[0].row = [0,0,0,0,0,0,0];
        grid[1].row = [0,0,1,0,0,0,0];
        grid[2].row = [0,0,0,1,0,0,0];
        grid[3].row = [0,1,1,1,0,0,0];
        grid[4].row = [0,0,0,0,1,0,0];
        grid[5].row = [0,0,0,1,1,0,0];
        grid[6].row = [0,0,0,0,0,0,0];

        emit boardReset();
    }


    function isAlive (uint8 wasAlive, uint8 count) internal pure returns(uint8) {
        if (wasAlive == 1) {
            if (count < 2 || count > 3) {
                return 0;
            } else {
                return 1;
            }
        } else {
            if (count == 3) {
                return 1;
            } else {
                return 0;
            }
        }
    }
    
    function evaluate () public {
        uint8 count;
        Row[7] memory evaluationGrid;
        evaluationGrid[0].row = grid[0].row;
        evaluationGrid[1].row = grid[1].row;
        evaluationGrid[2].row = grid[2].row;
        evaluationGrid[3].row = grid[3].row;
        evaluationGrid[4].row = grid[4].row;
        evaluationGrid[5].row = grid[5].row;
        evaluationGrid[6].row = grid[6].row;

        for (uint8 x = 1; x < 6; x++) {
            for (uint8 y = 1; y < 6; y++) {
                unchecked {
                    count = evaluationGrid[x+1].row[y]+evaluationGrid[x-1].row[y]+evaluationGrid[x].row[y-1]+evaluationGrid[x].row[y-1];
                    //count +=  evaluationGrid[x+1].row[y-1]+ evaluationGrid[x+1].row[y+1]+ evaluationGrid[x-1].row[y-1]+ evaluationGrid[x-1].row[y+1];
                }
                grid[x].row[y] = isAlive(grid[x].row[y], count);
            }
        }
        emit evaluated();
    }

    function viewRow (uint8 i) view public returns(uint8[7] memory) {
        return grid[i].row;
    }
}