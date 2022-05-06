/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Math{
    function multiply(int v, int b) public pure returns(int){
        return v*b;
    }

    function add(int v, int b) public pure returns(int){
        return v+b;
    }

    function sub(int v, int b) public pure returns(int){
        return v-b;
    }

    function division(int v, int b) public pure returns(int){
        return v/b;
    }
}