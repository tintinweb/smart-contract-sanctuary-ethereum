/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CounterTest {
    uint a;

    function set(uint _a) external {a = _a;}

    function test_DoesntShortcircuit() external {
        if (false || (a = 69) > 0) {
            a;    
        }
    }
    
    function test_DoesShortcircuit() external {
        if (true || (a = 69) > 0) {
            a;
        }
    }
}