/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Cal{
    int private result;

    function add(int a,int b) public returns (int c){
        result=a+b;
        c=result;
    }

    function minus(int a,int b) public returns(int){
        result=a-b;
        return result;
    }

    function mul(int a, int b) public returns(int){
        result=a*b;
        return result;
    }

    function div(int a, int b) public returns(int){
        result=a/b;
        return result;
    }

    function getResult() public view returns(int){
        return result;
    }
}