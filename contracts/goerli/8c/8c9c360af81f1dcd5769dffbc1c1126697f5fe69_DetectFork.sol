/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: None

pragma solidity 0.8.7;

contract DetectFork {

    bool isPoSChain;

    constructor() {
        if (block.difficulty > 2**64) {
            isPoSChain = true;
        }
    }

    function get_difficulty() public view returns (uint, uint, bool) {
        return (block.difficulty, block.number, isPoSChain);
    }
}