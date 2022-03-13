/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract StorageCostTest_0313 {
    int8 [9][9] sudoku_grid1;
    uint64[9] sudoku_grid2;
    uint256[2] sudoku_grid3;

    function set_9x9_8bits_Array() public {
        for(uint256 i=0;i<9;i++)
            for(uint256 j=0;j<9;j++)
                sudoku_grid1[i][j]=1 ;
    } 
    function set_9_64bits_Array() public {
        for(uint256 i=0;i<9;i++)
            sudoku_grid2[i]=1;
    } 
    function set_2_256bits_Array() public {
        for(uint256 i=0;i<2;i++)
            sudoku_grid3[i]=1;
    } 
}