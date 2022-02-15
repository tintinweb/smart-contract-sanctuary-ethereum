/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Calculator{
    int result;

    function add(int a, int b) public returns (int){
        return result = a + b;
    }

    function min(int a, int b) public returns(int c){
        result = a - b;
        c = result;
    }

    function mul(int a, int b) public{
        result = a * b;
    }

    function div(int a, int b) public{
        result = a / b;
    }

    function getResult() public view returns(int){
        return result;
    }
}