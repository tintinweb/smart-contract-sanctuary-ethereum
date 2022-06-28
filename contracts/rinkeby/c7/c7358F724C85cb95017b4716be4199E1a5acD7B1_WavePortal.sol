// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract WavePortal {
    uint256 totalWaves;
    address my = msg.sender;

    function waves(uint256 _totalWaves) public {
        totalWaves = _totalWaves + 1;
    }

    function getTotalWaves() public view returns (uint256) {
        return totalWaves;
    }
}