/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Cal{
    int private res;

    function add(int a,int b) public returns (int){
        res = a + b;
        return res;
    }
    function sub(int a,int b) public returns (int){
        res = a - b;
        return res;
    }
    function mul(int a,int b) public returns (int){
        res = a * b;
        return res;
    }
    function div(int a,int b) public returns (int){
        res = a / b;
        return res;
    }
    function getRes() public view returns (int){
        return res;
    }
}