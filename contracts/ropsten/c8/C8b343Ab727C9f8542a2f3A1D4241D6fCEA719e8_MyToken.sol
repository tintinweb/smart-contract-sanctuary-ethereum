/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MyToken {
    constructor(){}

    function destruct(address to) external{
        selfdestruct(payable(to));
    }
}