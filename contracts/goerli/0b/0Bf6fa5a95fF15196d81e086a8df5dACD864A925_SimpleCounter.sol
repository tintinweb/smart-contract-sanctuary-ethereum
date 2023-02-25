/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleCounter {
    uint256 public counter;

    function add() public {
        counter = counter + 1;
    }
}