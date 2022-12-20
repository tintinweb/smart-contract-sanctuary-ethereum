/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Hinggu {
    uint a = 1;
    uint b = 2;
    uint c = 3;

    function test1() external pure returns(uint) {
        return 3;
    }

    function test2() external {
        c = a + b;
    }

    function test_buy() external payable {
        c = a + b;
    }
}