/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: None

pragma solidity 0.8.7;

contract DetectFork {
    function get_difficulty() public view returns (uint, uint) {
        return (block.difficulty, block.number);
    }
}