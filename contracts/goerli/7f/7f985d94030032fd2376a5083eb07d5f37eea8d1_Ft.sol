// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract Ft {
    uint256 public theWaves;

    function wave(uint256 aNumWaves) external {
        theWaves += aNumWaves;
    } 
}