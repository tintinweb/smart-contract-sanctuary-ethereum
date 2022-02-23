//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract XbeTestToVoters {
    
    uint256 public lastCalled;

    constructor() {
        lastCalled = 0;
    }

    function toVoters() external {
        lastCalled = block.timestamp;
    }
}