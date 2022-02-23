//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract XbeRewardsBotTester {
    
    uint256 public ticker;

    constructor() {
        ticker = 0;
    }

    function mintForContracts() external {
        ticker++;
    }

    function earn() external {
        ticker++;
    }


    function toVoters() external {
        ticker++;
    }


}