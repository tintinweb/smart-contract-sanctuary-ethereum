/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;

contract Calc {
    //Calc the sum of a and b
    function sum(int a, int b) public pure returns (int){
        return a + b;
    }

    function mul(int a, int b) public pure returns (int){
        return a * b;
    }
}