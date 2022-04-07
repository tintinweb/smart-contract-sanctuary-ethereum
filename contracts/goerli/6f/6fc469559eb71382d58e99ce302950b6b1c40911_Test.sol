/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Test {
    event Search(uint val);

    function TestSearch(uint val) external {
        emit Search(val);
    }
}