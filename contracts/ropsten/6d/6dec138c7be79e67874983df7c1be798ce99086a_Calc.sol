/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Calc {
    int private result;

    function add(int a, int b) public returns(int c) {
        result = a + b;
        c = result;
    }

    function sub(int a, int b) public returns(int) {
        result = a - b;
        return result;
    }

}