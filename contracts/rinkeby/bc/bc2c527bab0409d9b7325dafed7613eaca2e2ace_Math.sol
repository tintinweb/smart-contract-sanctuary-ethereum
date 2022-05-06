/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Math{
    /*function multiplyBy20(uint v) public pure returns(uint){
        return v*20;
    }*/

    function addition(int a, int b) public pure returns(int){
        return a+b;
    }

    function subtraktion(int a, int b) public pure returns(int){
        return a-b;
    }

    function division(int a, int b) public pure returns(int){
        return a/b;
    }

    function multiplikation(int a, int b) public pure returns(int){
        return a*b;
    }
}