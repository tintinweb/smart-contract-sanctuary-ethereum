/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract CAL {

    function add(uint a, uint b) public view returns(uint) {
        return a+b;
    }

    function sub(int a, int b) public view returns(int) {
        return a-b;
    }

    function mul(uint a, uint b) public view returns(uint) {
        return a*b;
    }

    function div(uint a, uint b) public view returns(uint, uint) {
        return (a/b, a%b);
    }

    function square(uint a) public view returns(uint) {
        return a*a;
    }

    function cube(uint a) public view returns(uint) {
        return a*a*a;
    }
}