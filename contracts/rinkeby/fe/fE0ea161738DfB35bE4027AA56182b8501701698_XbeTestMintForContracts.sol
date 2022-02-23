//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract XbeTestMintForContracts {
    
    uint256 public lastCalled;

    constructor() {
        lastCalled = 0;
    }

    function mintForContracts() external {
        lastCalled = block.timestamp;
    }

}