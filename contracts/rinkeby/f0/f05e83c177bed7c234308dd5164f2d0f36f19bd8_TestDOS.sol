/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TestDOS {
    uint x;
    function test() external {
        uint i = 0;
        while (gasleft() > 600) {
            x = ++i;
        }
        revert();
    }
}