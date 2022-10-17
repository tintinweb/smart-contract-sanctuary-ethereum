/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract WavePortal {
    uint256 totalWaves;

    function wave() public {
        totalWaves += 1;
    }

    function getTotalWaves() public view returns (uint256) {
        return totalWaves;
    }
}