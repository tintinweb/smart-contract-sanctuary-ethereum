/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract first_contract {
    uint256 cost = 10000000000000000;

    function cost_view() external view returns(uint256) {
        return cost;
    }
}