/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract corl{
    int private result;

    function add(int a,int b) public returns (int) {
        result = a + b;
        return result;
    }

    function div(int a,int b) public  returns(int) {
        result = a / b;
        return result;
    }

    function sub(int a,int b) public returns(int){
        result = a-b;
        return result;
    }

    function mul(int a,int b) public returns(int) {
        result = a * b;
        return result;
    }

    function get() public view returns(int){
        return result;
    }
}