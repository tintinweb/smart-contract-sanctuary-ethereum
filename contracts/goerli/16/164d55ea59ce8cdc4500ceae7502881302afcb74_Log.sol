/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract Log {
    event testEvent(address addr, uint timestamp);
    
    function test() public {
        emit testEvent(msg.sender, block.timestamp);
    }

    constructor() {
        test();
    }
}