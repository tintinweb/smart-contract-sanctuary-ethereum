// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BoxV4 {
    uint public val;
    uint public val2;


    function sustVal() external {
        val -= 1;
    }
    function incVal() external {
        val += 1;
    }
    function sustVal2() external{
        val2 -= 1;
    }
    function incVal2() external {
        val2 += 1;
    }
}