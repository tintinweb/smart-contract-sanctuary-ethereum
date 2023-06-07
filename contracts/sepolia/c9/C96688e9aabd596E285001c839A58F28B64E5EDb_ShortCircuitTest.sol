/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ShortCircuitTest {
    uint public a;

    function set(uint _a) external {a = _a;}

    function test_DoesntShortcircuit() external {
        if (false || (a = 16) > 0) {
            a;    
        }
    }
    
    function test_DoesShortcircuit() external {
        if (true || (a = 256) > 0) {
            a;
        }
    }
}