/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract cal {
    uint index_1 = 1000;
        function add(int a, int b) public view returns(int) {
        return a+b;
    }
    function sub(int a, int b) public view returns(int) {
        return a-b;
    }
    function multi(int a, int b) public view returns(int) {
        return a*b;
    }
    function div(int a, int b) public view returns(int,int) {
        return (a/b,a%b);
    }


}