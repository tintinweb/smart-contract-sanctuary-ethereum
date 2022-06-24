/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract block_timestamp {
    function showTime() public view returns(uint256) {
        return block.timestamp;
    }
}