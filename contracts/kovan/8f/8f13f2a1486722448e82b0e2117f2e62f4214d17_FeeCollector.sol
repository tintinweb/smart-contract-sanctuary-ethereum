/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract FeeCollector {

    address public owner;

    constructor(){
        owner = msg.sender;
    }

}