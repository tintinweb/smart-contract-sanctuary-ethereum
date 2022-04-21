/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract WavePortal {
    uint private totalWaves;

    constructor() {
    }

    function wave() public {
        totalWaves += 1;
    }

    function getTotalWaves() public view returns (uint) {
        return totalWaves;
    }
}