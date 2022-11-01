/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract C  {
    function foo() public view returns (uint256 price) {
        price = tx.gasprice;
    }
}