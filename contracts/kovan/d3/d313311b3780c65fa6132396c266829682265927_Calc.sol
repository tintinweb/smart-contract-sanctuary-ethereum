/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calc{
    int private result; //设为private，那么result值将不会被外部看到

    //设为public，则函数可以被外部合约调用
    function add(int a,int b) public returns(int c){
        result = a+b;
        c = result;
    }
    function min(int a,int b) public returns(int){
        result = a-b;
        return result;
    }
    function mul(int a,int b) public returns(int){
        result = a*b;
        return result;
    }
    function div(int a,int b) public returns(int){
        result = a/b;
        return result;
    }
    function getResult() public view returns(int){
        return result;
    }
}