/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: Whoops

pragma solidity ^0.8.7;

interface DreamCash {
    function claim() external returns (bool);
}

contract FreeDreamCash {

    address constant dreamcash = address(0xe00a182284098e9c2ba89634544d51B0179c4C92);

    constructor() payable {}

    function getManyDreamCash(uint numIterations) external {
        for(uint i=0; i<numIterations; i++) {
            DreamCash(dreamcash).claim();
        }
    }
}