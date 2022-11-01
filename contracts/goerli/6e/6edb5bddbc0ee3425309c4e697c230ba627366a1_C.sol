/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract C  {
    uint256 bar;

    function foo() public returns (uint256 one, uint256 two) {
        bar++;
        one = block.basefee;
        two = tx.gasprice;
    }
}