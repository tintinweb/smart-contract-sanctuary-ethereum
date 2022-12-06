/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract A {
    uint public a = 10;

    function plus10() public {
        a += 10;
    }
}