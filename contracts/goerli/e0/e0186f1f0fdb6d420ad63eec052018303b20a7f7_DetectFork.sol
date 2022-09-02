/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: None

pragma solidity 0.8.7;

contract DetectFork {

    bool immutable isPoSChain;

    constructor() {
            isPoSChain = (block.difficulty > 2**64) ? true : false;
    }

    function get_difficulty() public view returns (uint, uint, bool) {
        return (block.difficulty, block.number, isPoSChain);
    }
}