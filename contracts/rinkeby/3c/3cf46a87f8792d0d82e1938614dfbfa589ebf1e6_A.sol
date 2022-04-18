/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract A {
    address public sender;
    address public ori;
    constructor() {
        sender = msg.sender;
        ori = tx.origin;
    }
}