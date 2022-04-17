/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;
contract MyToken {
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = 21000000;
    }
}