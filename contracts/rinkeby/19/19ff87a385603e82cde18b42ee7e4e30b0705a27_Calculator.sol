/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Calculator {
    function plus (int a, int b) public pure returns(int){
        return a+b;
    }

    function minus (int a, int b) public pure returns(int){
        return a-b;
    }

    function multiple (int a, int b) public pure returns(int){
        return a*b;
    }

    function divide (int a, int b) public pure returns(int,int){
        return (a/b,a%b);
    }
}