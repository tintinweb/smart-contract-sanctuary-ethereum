/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {

    function test() external payable returns(uint) {
        return block.timestamp;
    }
}