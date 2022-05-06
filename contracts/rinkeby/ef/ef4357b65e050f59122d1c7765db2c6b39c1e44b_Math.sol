/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Math{
    function add(int a, int b) public pure returns(int) {
        return a+b;
    }

    function subtract(int a, int b) public pure returns(int) {
        return a-b;
    }

    function multiply(int a, int b) public pure returns(int) {
        return a*b;
    }

    function divide(int a, int b) public pure returns(int) {
        return a/b;
    }
}