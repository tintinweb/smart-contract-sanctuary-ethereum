/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Calc{
    int private result;
    function add(int a,int b) public returns (int){
        result = a+b;
        return result;
    }

    function min(int a,int b) public returns (int){
        result = a-b;
        return result;
    }

    function mul(int a,int b) public returns (int){
        result = a*b;
        return result;
    }

    function div(int a,int b) public returns (int){
        result = a/b;
        return result;
    }

    function get_result() public view returns (int){
        return result;
    }

}