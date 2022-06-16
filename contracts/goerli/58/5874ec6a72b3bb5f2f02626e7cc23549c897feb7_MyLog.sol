/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyLog {
    event Test1(uint test1);

    constructor() payable {
        emit Test1(1111 + msg.value);
    }

    receive() external payable {
        emit Test1(msg.value);
    }
}