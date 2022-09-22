/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract C {

    function add(int a, int b) public view returns(int) {
        return a + b;
    }

    function sub(int a, int b) public view returns(int) {
        return a - b;
    }

    function mul(int a, int b) public view returns(int) {
        return a * b;
    }

    function div(int a, int b) public view returns(int) {
        return a / b;
    }

    function remain(int a, int b) public view returns(int) {
        return a % b;
    }
}