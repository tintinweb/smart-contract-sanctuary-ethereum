/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract sudokutest {
    uint8[9][9] sudoku_grid;
    function set() public {
        for(uint8 i=0;i<9;i++)
            for(uint8 j=0;j<9;j++)
                sudoku_grid[i][j]=i+j;
    } 
}