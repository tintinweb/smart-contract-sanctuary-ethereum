/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract Calculator{
    int private result;

    function Add(int a, int b) public returns (int c){
        result = a + b;
        c = result;
    }
    function Sub(int a, int b) public returns (int){
        result = a - b;
        return result;
    }
    function Mul(int a, int b) public returns (int){
        result = a * b;
        return result;
    }
    function Div(int a, int b) public returns (int){
        result = a / b;
        return result;
    }

    function get_result() public view returns (int){
        return result;
    }
}