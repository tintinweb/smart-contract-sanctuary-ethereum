/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Calc{
    int private r;
    
    function add(int a, int b) public returns(int c) {
        r = a + b;
        c = r;
    }
    
    function min(int a, int b) public returns(int) {
        r = a - b;
        return r;
    }
    
    function mul(int a, int b) public returns(int) {
        r = a * b;
        return r;
    }

    function div(int a, int b) public returns(int) {
        r = a / b;
        return r;
    }
    
    function getR() public view returns(int) {
        return r;
    }
}