/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract D {
    
    function minus(int a, int b) public view returns(int) {
        return(a-b);
    }

    function add(int a, int b) public view returns(int) {
        return(a+b);
    }

    function add2(int a, int b, int c) public view returns(int) {
        return(a+b);
    }

    function mult(int a, int b) public view returns(int) {
        return(a*b);
    }

    function div(int a, int b) public view returns(int) {
        return(a/b);
    }
}