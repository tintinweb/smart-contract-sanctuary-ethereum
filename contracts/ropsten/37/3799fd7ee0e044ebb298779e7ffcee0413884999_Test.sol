/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    
    uint public c;

    function sum(uint a, uint b) public {
        c = a + b;
    }
}