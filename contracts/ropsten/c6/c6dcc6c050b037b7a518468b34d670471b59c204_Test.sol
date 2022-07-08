/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Test {
    uint x = 10;
    function check(uint i) public  {
        assert(i < 10);
        x = 87;
    }
}