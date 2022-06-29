/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;


contract Sandbox{
    int test1 = 0;
    function Test(int a) public returns(int){
        require(a != 0, "test error");
        a += 10;
        test1 += 10;
        return a;
    }
}