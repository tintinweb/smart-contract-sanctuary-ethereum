/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract ArrayTester1 {
    int8 [9][9] grid;

    function setgrid(int8[9][9] calldata array)  external  {
         for (uint  i=0;i<9;i++)
            for (uint  j=0;j<9;i++)
                grid[i][j]=array[i][j];
    } 
}