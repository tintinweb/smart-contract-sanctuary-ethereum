//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract WavePortal {
    uint256 public totalWaves;

    function wave() public {
        totalWaves += 1;
    }
}