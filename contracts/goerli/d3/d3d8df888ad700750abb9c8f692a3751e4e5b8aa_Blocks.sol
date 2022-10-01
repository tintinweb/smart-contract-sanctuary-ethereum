/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Blocks {

    uint public blockNumber;

    function getBlockNow() view external returns (uint) {
        return block.number;
    }
}