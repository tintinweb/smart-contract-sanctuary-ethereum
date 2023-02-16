/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Caller {
    uint a;

    event Number(uint a);

    function test() public {
        a++;
        emit Number(a);
        this.test();
    }
}