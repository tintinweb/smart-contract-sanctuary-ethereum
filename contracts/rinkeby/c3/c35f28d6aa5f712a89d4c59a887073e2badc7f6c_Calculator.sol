/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


contract Calculator {
    function add(uint a, uint b) public view returns(uint) {
        return a + b;
    }

    function subtract(int a, int b) public view returns(int) {
        return a - b;
    }
    
    function multiple(uint a, uint b) public view returns(uint) {
        return a * b;
    }

    function divide(uint a, uint b) public view returns(uint, uint) {
        return (a / b, a & b);
    }

}