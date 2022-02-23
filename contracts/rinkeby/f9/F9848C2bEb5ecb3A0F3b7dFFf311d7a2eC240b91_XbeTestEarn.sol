//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract XbeTestEarn {
    
    uint256 public lastCalled;
    

    constructor() {
        lastCalled = 0;
    }

    function earn() external {
        lastCalled = block.timestamp;
    }
}