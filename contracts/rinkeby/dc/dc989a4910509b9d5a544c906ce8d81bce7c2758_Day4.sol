/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Day4 {
    int private result;

    function add(int a, int b) public returns (int c){
        result = a + b;
        c= result;
    }

    function min(int a, int b) public returns (int c){
        result = a - b;
        c= result;
    }

    function mul(int a, int b) public returns (int c){
        result = a * b;
        c= result;
    }

    function div(int a, int b) public returns (int c){
        result = a / b;
        c= result;
    }

    function getResult() public view returns (int){
        return result;
    }

}